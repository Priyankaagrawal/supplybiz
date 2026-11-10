import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:uuid/uuid.dart';

import '../../core/network/app_failure.dart';
import '../../core/config/app_config.dart';
import '../../core/network/network_client.dart';
import '../../core/storage/app_storage.dart';
import '../auth/session_controller.dart';

abstract interface class OnboardingDrafts {
  Future<Map<String, String>> read(String owner);
  Future<void> write(String owner, Map<String, String> values);
}

class EncryptedOnboardingDrafts implements OnboardingDrafts {
  EncryptedOnboardingDrafts({AppStorage? storage})
      : storage = storage ?? AppStorage.instance;
  final AppStorage storage;
  @override
  Future<Map<String, String>> read(String owner) async {
    final row = await storage.database.customSelect(
        'SELECT payload FROM onboarding_drafts WHERE owner = ?',
        variables: [Variable(owner)]).getSingleOrNull();
    return row == null
        ? {}
        : Map<String, String>.from(
            jsonDecode(row.read<String>('payload')) as Map);
  }

  @override
  Future<void> write(String owner, Map<String, String> values) =>
      storage.database.customStatement(
          'INSERT INTO onboarding_drafts(owner, payload) VALUES (?, ?) ON CONFLICT(owner) DO UPDATE SET payload=excluded.payload',
          [owner, jsonEncode(values)]);
}

final onboardingDraftsProvider =
    Provider<OnboardingDrafts>((ref) => EncryptedOnboardingDrafts());
final onboardingProvider =
    ChangeNotifierProvider.autoDispose<OnboardingController>((ref) {
  final identity = ref.watch(
      sessionProvider.select((s) => (s.user?.id, s.user?.activeRole?.value)));
  final session = ref.read(sessionProvider.notifier);
  final client = NetworkClient(
    baseUrl: Uri.parse(ref.read(authConfigProvider).baseUrl)
        .replace(path: '')
        .toString(),
    session: session,
    adapter: ref.read(authAdapterProvider),
    appVersion: () => ref.read(configProvider).version,
  );
  final controller = OnboardingController(
      client,
      ref.read(onboardingDraftsProvider),
      '${ref.read(authConfigProvider).baseUrl}:${identity.$1}');
  ref.onDispose(client.close);
  if (identity.$1 != null && identity.$2 == 'VENDOR') {
    Future.microtask(controller.load);
  }
  return controller;
});

/// Encrypted local drafts contain fields and opaque attachment IDs, never raw documents.
/// Serialized snapshots and identity-scoped lifetime prevent late requests leaking across accounts.
class OnboardingController extends ChangeNotifier {
  OnboardingController(NetworkClient client, this.drafts, this.owner)
      : vendors = VendorOnboardingApi(client.dio),
        kyc = KycApi(client.dio),
        media = MediaApi(client.dio);
  final VendorOnboardingApi vendors;
  final KycApi kyc;
  final MediaApi media;
  final OnboardingDrafts drafts;
  final String owner;
  final values = <String, String>{};
  List<VendorCategoryResponse> categories = [];
  VendorProfileResponse? profile;
  KycResponse? submission;
  AppFailure? failure;
  bool ready = false, busy = false, _disposed = false;
  Future<void> _writes = Future.value();
  int get step => profile?.onboardingStep.toInt() ?? 1;
  bool get complete => step >= 4;
  bool get canSubmit =>
      submission == null ||
      {'REJECTED', 'PENDING', 'NOT_VERIFIED'}.contains(submission!.status);
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void edit(String key, String value) {
    if (_disposed) return;
    values[key] = value;
    _persist();
  }

  void _persist() {
    final snapshot = Map<String, String>.of(values);
    _writes = _writes.then((_) async {
      if (!_disposed) await drafts.write(owner, snapshot);
    }).catchError((Object _) {
      if (!_disposed) {
        failure = const UnknownFailure(code: 'DRAFT_SAVE_FAILED');
        _notify();
      }
    });
  }

  Future<void> flush() => _writes;
  Future<void> _run(Future<void> Function() action) async {
    if (busy || _disposed) return;
    busy = true;
    failure = null;
    _notify();
    try {
      await action();
    } catch (error) {
      if (!_disposed) {
        failure = error is DioException
            ? mapDioFailure(error)
            : error is AppFailure
                ? error
                : const UnknownFailure();
      }
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> load() => _run(() async {
        await flush();
        final saved = await drafts.read(owner);
        if (_disposed) return;
        values.addAll(saved);
        categories = (await vendors.vendorsControllerCategories()).data!;
        try {
          profile = (await vendors.vendorsControllerProfile()).data!;
        } on DioException catch (e) {
          if (e.response?.statusCode != 404 ||
              (e.response?.data as Map?)?['code'] != 'ONBOARDING_NOT_STARTED') {
            rethrow;
          }
        }
        if (_disposed) return;
        final p = profile;
        if (p != null) {
          final server = <String, String>{
            'categoryId': p.categoryId,
            'businessName': p.businessName ?? '',
            'gstin': p.gstin ?? '',
            'addressLine': p.addressLine ?? '',
            'city': p.city ?? '',
            'state': p.state ?? '',
            'pincode': p.pincode ?? '',
            'latitude': p.latitude?.toString() ?? '',
            'longitude': p.longitude?.toString() ?? '',
            'shopPhotoMediaId': p.shopPhotoMediaId ?? ''
          };
          for (final entry in server.entries) {
            values.putIfAbsent(entry.key, () => entry.value);
          }
          try {
            submission = (await kyc.kycControllerStatus()).data!;
          } on DioException catch (e) {
            if (e.response?.statusCode != 404 ||
                (e.response?.data as Map?)?['code'] != 'KYC_NOT_SUBMITTED') {
              rethrow;
            }
          }
          if (submission != null && submission!.status != 'REJECTED') {
            _clearBankDraft();
          }
        }
        ready = true;
      });
  Future<String> _key(String action, Map<String, dynamic> payload) async {
    final encoded = jsonEncode(payload);
    if (values['${action}Payload'] != encoded) {
      values['${action}Payload'] = encoded;
      values['${action}Key'] = const Uuid().v4();
    }
    _persist();
    await flush();
    if (failure != null) throw failure!;
    if (_disposed) throw const UnauthorizedFailure();
    return values['${action}Key']!;
  }

  Future<void> saveCategory(String id) => _run(() async {
        final payload = VendorCategoryDto(categoryId: id);
        final key = await _key('category', payload.toJson());
        final result = (await vendors.vendorsControllerCategory(
                idempotencyKey: key, vendorCategoryDto: payload))
            .data!;
        if (_disposed) return;
        profile = result;
        edit('categoryId', id);
      });
  Future<void> saveBusiness() => _run(() async {
        final payload = VendorBusinessDto(
            businessName: values['businessName']!.trim(),
            gstin: values['gstin']?.trim().toUpperCase(),
            addressLine: values['addressLine']!.trim(),
            city: values['city']!.trim(),
            state: values['state']!.trim(),
            pincode: values['pincode']!.trim(),
            latitude: num.parse(values['latitude']!),
            longitude: num.parse(values['longitude']!),
            shopPhotoMediaId: values['shopPhotoMediaId']?.isNotEmpty == true
                ? values['shopPhotoMediaId']
                : null);
        final key = await _key('business', payload.toJson());
        final result = (await vendors.vendorsControllerBusiness(
                idempotencyKey: key, vendorBusinessDto: payload))
            .data!;
        if (!_disposed) profile = result;
      });
  Future<void> submit() => _run(() async {
        final payload = KycSubmissionDto(
            aadhaarFrontMediaId: values['aadhaarFrontMediaId']!,
            aadhaarBackMediaId: values['aadhaarBackMediaId']!,
            panMediaId: values['panMediaId']!,
            pan: values['pan']!.trim().toUpperCase(),
            holderName: values['holderName']!.trim(),
            bankName: values['bankName']!.trim(),
            accountNumber: values['accountNumber']!.trim(),
            accountNumberConfirmation:
                values['accountNumberConfirmation']!.trim(),
            ifsc: values['ifsc']!.trim().toUpperCase(),
            upiId: values['upiId']?.trim().isNotEmpty == true
                ? values['upiId']!.trim()
                : null);
        final key = await _key('submit', payload.toJson());
        final result = (await kyc.kycControllerSubmit(
                idempotencyKey: key, kycSubmissionDto: payload))
            .data!;
        if (_disposed) return;
        submission = result;
        _clearBankDraft();
        profile = (await vendors.vendorsControllerProfile()).data!;
      });
  void _clearBankDraft() {
    for (final key in [
      'pan',
      'accountNumber',
      'accountNumberConfirmation',
      'submitPayload',
      'submitKey'
    ]) {
      values.remove(key);
    }
    _persist();
  }

  Future<void> upload(String field, Uint8List bytes,
          {required bool pdf, required String key}) =>
      _run(() async {
        if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
          throw const BusinessRuleFailure(code: 'FILE_INVALID');
        }
        final response = await media.mediaControllerUpload(
            idempotencyKey: key,
            purpose: field == 'shopPhotoMediaId' ? 'SHOP_PHOTO' : 'KYC_DOC',
            file: MultipartFile.fromBytes(bytes,
                filename: pdf
                    ? 'attachment.pdf'
                    : bytes.first == 137
                        ? 'attachment.png'
                        : 'attachment.jpg',
                contentType: DioMediaType.parse(pdf
                    ? 'application/pdf'
                    : bytes.first == 137
                        ? 'image/png'
                        : 'image/jpeg')));
        if (!_disposed) edit(field, response.data!.mediaId);
      });
  Future<Uint8List> content(String id) async =>
      (await media.mediaControllerContent(id: id)).data!;
}
