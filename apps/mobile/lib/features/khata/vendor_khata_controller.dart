// T-081: owned financial APIs, fresh-write fencing and encrypted exact replay.
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:uuid/uuid.dart';
import '../../core/config/app_config.dart';
import '../../core/network/app_failure.dart';
import '../../core/network/network_client.dart';
import '../auth/session_controller.dart';
import '../onboarding/onboarding_controller.dart';

final vendorKhataProvider =
    ChangeNotifierProvider.autoDispose<VendorKhataController>((ref) {
  final identity = ref.watch(sessionProvider
          .select((s) => (s.user?.id, s.user?.activeRole?.value))),
      config = ref.read(authConfigProvider);
  final client = NetworkClient(
      baseUrl: Uri.parse(config.baseUrl).replace(path: '').toString(),
      session: ref.read(sessionProvider.notifier),
      adapter: ref.read(authAdapterProvider),
      appVersion: () => ref.read(configProvider).version);
  ref.onDispose(client.close);
  return VendorKhataController(client, ref.read(onboardingDraftsProvider),
      '${config.baseUrl}:${identity.$1}:vendor-khata');
});

class VendorKhataController extends ChangeNotifier {
  VendorKhataController(this.client, this.store, this.owner)
      : api = VendorKhataApi(client.dio),
        payments = VendorPaymentsApi(client.dio) {
    client.dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      if (o.method == 'POST' && o.uri.path == '/api/v1/vendor/payments') {
        final raw = o.data,
            body = Map<String, dynamic>.from(
                raw is String ? jsonDecode(raw) as Map : raw as Map),
            day = body['receivedOn'];
        if (day is String &&
            RegExp(r'^\d{4}-\d{2}-\d{2}T00:00:00(?:\.0+)?Z?$').hasMatch(day)) {
          body['receivedOn'] = day.substring(0, 10);
        }
        o.data = raw is String ? jsonEncode(body) : body;
      }
      h.next(o);
    }));
  }
  final NetworkClient client;
  final OnboardingDrafts store;
  final String owner;
  final VendorKhataApi api;
  final VendorPaymentsApi payments;
  VendorKhataList? summary;
  List<VendorKhataAccount> accounts = [];
  KhataVendorEntries? entries;
  List<VendorCollection> collections = [];
  List<PaymentClaimRecord> claims = [];
  int collectionTotal = 0, claimTotal = 0, shown = 20;
  String? selectedId, month;
  String claimStatus = 'PENDING', query = '', tab = 'ALL';
  Map<String, dynamic>? pending;
  AppFailure? failure;
  bool busy = false,
      stale = false,
      completed = false,
      _disposed = false,
      _restored = false;
  bool get canWrite =>
      summary != null && !busy && !stale && pending == null && !_disposed;
  bool get canAdjust => canWrite && summary!.canAdjust;
  bool get canPay => canWrite && summary!.canRecordPayment;
  VendorKhataAccount? find(String id) =>
      accounts.where((a) => a.id == id).firstOrNull;
  List<VendorKhataAccount> get filtered => accounts.where((a) {
        final due = BigInt.parse(a.duePaise);
        return (tab == 'ALL' ||
                tab == 'RECEIVABLE' && due > BigInt.zero ||
                tab == 'PAID' && due == BigInt.zero) &&
            '${a.name} ${a.mobile}'.toLowerCase().contains(query.toLowerCase());
      }).toList();
  List<VendorKhataAccount> get visible => filtered.take(shown).toList();
  void filter(String q, String t) {
    query = q;
    tab = t;
    shown = 20;
    notifyListeners();
  }

  void moreAccounts() {
    shown += 20;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _persist(Map<String, dynamic>? request) async {
    if (_disposed) return;
    await store.write(owner, {
      'accounts': jsonEncode(accounts.map((a) => a.toJson()).toList()),
      if (summary != null) 'summary': jsonEncode(summary!.toJson()),
      if (entries != null) 'entries': jsonEncode(entries!.toJson()),
      'collections': jsonEncode(collections.map((c) => c.toJson()).toList()),
      'claims': jsonEncode(claims.map((c) => c.toJson()).toList()),
      'claimStatus': claimStatus,
      if (month != null) 'month': month!,
      if (request != null) 'pending': jsonEncode(request)
    });
  }

  Future<void> _run(Future<void> Function() f) async {
    if (_disposed || busy) return;
    busy = true;
    failure = null;
    notifyListeners();
    try {
      await f();
    } catch (e) {
      if (_disposed) return;
      failure = e is DioException
          ? mapDioFailure(e)
          : e is AppFailure
              ? e
              : const UnknownFailure();
      stale = true;
      if (failure is UnauthorizedFailure ||
          failure is ForbiddenFailure &&
              failure!.code != 'PLAN_FEATURE_LOCKED') {
        summary = null;
        accounts = [];
        entries = null;
        collections = [];
        claims = [];
        completed = false;
        // An uncertain financial action retains its private key/body for explicit
        // authorized replay. Session logout still wipes the encrypted store.
        try {
          await _persist(pending);
        } catch (_) {
          failure = const UnknownFailure(code: 'CACHE_CLEAR_FAILED');
        }
      }
      if (failure is NotFoundFailure && selectedId != null) {
        entries = null;
      }
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> load({String? id}) => _run(() async {
        if (selectedId != id) {
          selectedId = id;
          entries = null;
        }
        if (!_restored) {
          final saved = await store.read(owner);
          if (_disposed) return;
          accounts = (jsonDecode(saved['accounts'] ?? '[]') as List)
              .map((a) => VendorKhataAccount.fromJson(
                  Map<String, dynamic>.from(a as Map)))
              .toList();
          if (saved['summary'] != null) {
            summary = VendorKhataList.fromJson(Map<String, dynamic>.from(
                jsonDecode(saved['summary']!) as Map));
          }
          if (saved['entries'] != null) {
            entries = KhataVendorEntries.fromJson(Map<String, dynamic>.from(
                jsonDecode(saved['entries']!) as Map));
          }
          if (selectedId == null ||
              entries?.accounts.any((a) => a.vendorCustomerId == selectedId) !=
                  true) {
            entries = null;
          }
          collections = (jsonDecode(saved['collections'] ?? '[]') as List)
              .map((c) => VendorCollection.fromJson(
                  Map<String, dynamic>.from(c as Map)))
              .toList();
          claims = (jsonDecode(saved['claims'] ?? '[]') as List)
              .map((c) => PaymentClaimRecord.fromJson(
                  Map<String, dynamic>.from(c as Map)))
              .toList();
          pending = saved['pending'] == null
              ? null
              : Map<String, dynamic>.from(jsonDecode(saved['pending']!) as Map);
          month = saved['month'];
          claimStatus = saved['claimStatus'] ?? 'PENDING';
          stale = summary != null;
          _restored = true;
          notifyListeners();
        }
        await _refresh();
      });
  Future<void> _refresh() async {
    final rows = <VendorKhataAccount>[];
    VendorKhataList? first;
    for (var offset = 0;;) {
      final page =
          (await api.vendorKhataControllerAccounts(limit: 50, offset: offset))
              .data!;
      if (_disposed) return;
      first ??= page;
      rows.addAll(page.items);
      offset += page.items.length;
      if (offset >= page.total) break;
      if (page.items.isEmpty) throw const ServerFailure(code: 'KHATA_CHANGED');
    }
    if (_disposed) return;
    summary = first;
    accounts = rows;
    month ??= first.businessDate.substring(0, 7);
    if (selectedId != null) await _entries();
    await _collections();
    await _claims();
    await _persist(pending);
    if (!_disposed) stale = false;
  }

  Future<void> _entries({bool more = false}) async {
    final id = selectedId;
    if (id == null) return;
    final old = more ? entries : null,
        page = (await api.vendorKhataControllerEntries(
                id: id,
                month: month,
                limit: 50,
                offset: old?.items.length ?? 0))
            .data!;
    if (_disposed) return;
    entries = old == null
        ? page
        : KhataVendorEntries.fromJson({
            ...page.toJson(),
            'items': [
              ...old.items.map((i) => i.toJson()),
              ...page.items.map((i) => i.toJson())
            ]
          });
  }

  Future<void> _collections({bool more = false}) async {
    final page = (await api.vendorKhataControllerCollections(
            month: month, limit: 50, offset: more ? collections.length : 0))
        .data!;
    if (_disposed) return;
    collections = more ? [...collections, ...page.items] : page.items;
    collectionTotal = page.total;
  }

  Future<void> _claims({bool more = false}) async {
    final page = (await api.vendorKhataControllerList(
            status: claimStatus, limit: 50, offset: more ? claims.length : 0))
        .data!;
    if (_disposed) return;
    claims = more ? [...claims, ...page.items] : page.items;
    claimTotal = page.total;
  }

  Future<void> moreEntries() => _run(() => _entries(more: true));
  Future<void> moreCollections() => _run(() => _collections(more: true));
  Future<void> moreClaims() => _run(() => _claims(more: true));
  Future<void> selectMonth(String value) => _run(() async {
        month = value;
        await _entries();
        await _collections();
        await _persist(pending);
      });
  Future<void> selectClaims(String value) => _run(() async {
        claimStatus = value;
        await _claims();
      });
  Future<void> submit(String action, Map<String, dynamic> body,
      {String? id}) async {
    if (!canWrite ||
        ['OPENING', 'REVERSE'].contains(action) && !summary!.canAdjust ||
        ['PAYMENT', 'CONFIRM', 'REJECT'].contains(action) &&
            !summary!.canRecordPayment) {
      return;
    }
    await _run(() async {
      completed = false;
      pending = {
        'action': action,
        'body': jsonDecode(jsonEncode(body)),
        'id': id,
        'key': const Uuid().v4()
      };
      await _send();
    });
  }

  Future<void> retry() => _run(_send);
  Future<void> _send() async {
    final p = pending;
    if (p == null || _disposed) return;
    await _persist(p);
    if (_disposed) return;
    final key = p['key'] as String,
        id = p['id'] as String?,
        body = Map<String, dynamic>.from(p['body'] as Map);
    try {
      switch (p['action']) {
        case 'PAYMENT':
          await payments.paymentsControllerRecord(
              idempotencyKey: key,
              recordPaymentInput: RecordPaymentInput.fromJson(body));
        case 'OPENING':
          await api.vendorKhataControllerOpening(
              id: id!,
              idempotencyKey: key,
              ledgerOpeningInput: LedgerOpeningInput.fromJson(body));
        case 'REVERSE':
          await api.vendorKhataControllerReverse(
              id: id!,
              idempotencyKey: key,
              ledgerReversalInput: LedgerReversalInput.fromJson(body));
        case 'CONFIRM':
          await api.vendorKhataControllerConfirm(
              id: id!,
              idempotencyKey: key,
              khataVersion: KhataVersion.fromJson(body));
        case 'REJECT':
          await api.vendorKhataControllerReject(
              id: id!,
              idempotencyKey: key,
              claimRejection: ClaimRejection.fromJson(body));
        default:
          throw const UnknownFailure(code: 'INVALID_SAVED_REQUEST');
      }
    } catch (e) {
      final f = e is DioException ? mapDioFailure(e) : e;
      if (f is ValidationFailure ||
          f is ConflictFailure ||
          f is NotFoundFailure ||
          f is ForbiddenFailure && f.code == 'PLAN_FEATURE_LOCKED' ||
          f is BusinessRuleFailure && f.code != 'RATE_LIMITED') {
        await _persist(null);
        if (!_disposed) {
          pending = null;
          stale = true;
        }
      }
      rethrow;
    }
    if (_disposed) return;
    await _persist(null);
    if (_disposed) return;
    pending = null;
    completed = true;
    stale = true;
    await _refresh();
  }
}
