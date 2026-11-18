// T-083: customer-owned readers/CRUD; financial attempts survive lost responses.
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
import 'upi_device.dart';
import '../subscriptions/vendor_subscriptions_controller.dart'
    show subscriptionDate;

final customerKhataProvider = ChangeNotifierProvider.autoDispose
    .family<CustomerKhataController, String>((ref, scope) {
  final identity = ref.watch(
      sessionProvider.select((s) => (s.user?.id, s.user?.activeRole?.value)));
  final config = ref.read(authConfigProvider);
  final client = NetworkClient(
      baseUrl: Uri.parse(config.baseUrl).replace(path: '').toString(),
      session: ref.read(sessionProvider.notifier),
      adapter: ref.read(authAdapterProvider),
      appVersion: () => ref.read(configProvider).version);
  ref.onDispose(client.close);
  return CustomerKhataController(
      client,
      ref.read(onboardingDraftsProvider),
      '${config.baseUrl}:${identity.$1}:${identity.$2}:customer-khata:$scope',
      scope);
});

class CustomerKhataController extends ChangeNotifier {
  CustomerKhataController(this.client, this.store, this.owner, this.scope,
      {UpiDevice? device})
      : api = CustomerKhataApi(client.dio),
        device = device ?? UpiDevice();
  final NetworkClient client;
  final OnboardingDrafts store;
  final String owner, scope;
  final CustomerKhataApi api;
  final UpiDevice device;
  String? get vendorId =>
      scope.startsWith('vendor:') ? scope.substring(7) : null;
  String? get contactId =>
      scope.startsWith('personal:') ? scope.substring(9) : null;
  KhataSummary? summary;
  List<KhataAccount> accounts = [];
  KhataVendorEntries? entries;
  PersonalContactRecord? contact;
  List<PersonalEntryRecord> personal = [];
  List<PaymentClaimRecord> claims = [];
  CustomerSettlementOptions? options;
  int personalTotal = 0, claimTotal = 0, shown = 20;
  String tab = 'ALL', query = '', claimStatus = 'PENDING';
  String? month;
  // launch is a review draft, never a server mutation or a reason to relaunch.
  Map<String, dynamic>? launch, pending;
  AppFailure? failure;
  bool busy = false, stale = true, completed = false, deleted = false;
  bool _restored = false, _disposed = false;
  bool get canWrite =>
      summary != null &&
      !busy &&
      !stale &&
      pending == null &&
      launch == null &&
      !deleted &&
      !_disposed;
  bool get canReview =>
      launch != null &&
      pending == null &&
      summary != null &&
      !busy &&
      !stale &&
      !_disposed;
  List<KhataAccount> get filtered => accounts
      .where((a) =>
          (tab == 'ALL' ||
              tab == 'VENDORS' && a.kind.value == 'VENDOR' ||
              tab == 'CUSTOMERS' && a.kind.value == 'PERSONAL') &&
          a.name.toLowerCase().contains(query.toLowerCase()))
      .toList();
  List<KhataAccount> get visible => filtered.take(shown).toList();
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

  Future<void> _save(
      {bool clearPending = false, bool clearLaunch = false}) async {
    if (_disposed) return;
    await store.write(owner, {
      if (summary != null) 'summary': jsonEncode(summary!.toJson()),
      'accounts': jsonEncode(accounts.map((e) => e.toJson()).toList()),
      if (entries != null) 'entries': jsonEncode(entries!.toJson()),
      if (contact != null) 'contact': jsonEncode(contact!.toJson()),
      'personal': jsonEncode(personal.map((e) => e.toJson()).toList()),
      'claims': jsonEncode(claims.map((e) => e.toJson()).toList()),
      if (month != null) 'month': month!,
      if (!clearPending && pending != null) 'pending': jsonEncode(pending),
      if (!clearLaunch && launch != null) 'launch': jsonEncode(launch),
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_disposed || busy) return;
    busy = true;
    failure = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      if (_disposed) return;
      failure = e is DioException
          ? mapDioFailure(e)
          : e is AppFailure
              ? e
              : const UnknownFailure();
      stale = true;
      options = null;
      if (failure is UnauthorizedFailure ||
          failure is ForbiddenFailure ||
          failure is NotFoundFailure) {
        summary = null;
        accounts = [];
        entries = null;
        contact = null;
        personal = [];
        claims = [];
        // Keep uncertain keys privately until authorized retry or logout wipe.
        try {
          await _save();
        } catch (_) {/* No private cache on screen. */}
      }
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> load() => _run(() async {
        if (!_restored) {
          final saved = await store.read(owner);
          if (_disposed) return;
          Map<String, dynamic> obj(String k) =>
              Map<String, dynamic>.from(jsonDecode(saved[k]!) as Map);
          List<Map<String, dynamic>> rows(String k) =>
              (jsonDecode(saved[k] ?? '[]') as List)
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();
          if (saved['summary'] != null) {
            summary = KhataSummary.fromJson(obj('summary'));
          }
          accounts = rows('accounts').map(KhataAccount.fromJson).toList();
          if (saved['entries'] != null) {
            entries = KhataVendorEntries.fromJson(obj('entries'));
          }
          if (saved['contact'] != null) {
            contact = PersonalContactRecord.fromJson(obj('contact'));
          }
          personal =
              rows('personal').map(PersonalEntryRecord.fromJson).toList();
          claims = rows('claims').map(PaymentClaimRecord.fromJson).toList();
          if (saved['pending'] != null) pending = obj('pending');
          if (saved['launch'] != null) launch = obj('launch');
          month = saved['month'];
          _restored = true;
          stale = true;
          notifyListeners();
        }
        await _refresh();
      });
  Future<void> _refresh() async {
    final rows = <KhataAccount>[];
    KhataSummary? first;
    for (var offset = 0;;) {
      final page =
          (await api.customerKhataControllerSummary(limit: 50, offset: offset))
              .data!;
      if (_disposed) return;
      first ??= page;
      rows.addAll(page.items);
      offset += page.items.length;
      if (offset >= page.total) break;
      if (page.items.isEmpty) throw const ServerFailure(code: 'KHATA_CHANGED');
    }
    summary = first;
    accounts = rows;
    month ??= subscriptionDate(first.businessDate).substring(0, 7);
    options = null;
    if (vendorId != null) {
      await _entries();
      await _claims();
    }
    if (contactId != null && !deleted) {
      contact =
          (await api.customerKhataControllerContactGet(id: contactId!)).data!;
      await _personal();
    }
    await _save();
    if (!_disposed) stale = false;
  }

  Future<void> _entries({bool more = false}) async {
    final old = more ? entries : null;
    final page = (await api.customerKhataControllerEntries(
            id: vendorId!,
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
              ...old.items.map((e) => e.toJson()),
              ...page.items.map((e) => e.toJson())
            ]
          });
  }

  Future<void> _personal({bool more = false}) async {
    final page = (await api.customerKhataControllerPersonalEntries(
            contactId: contactId,
            month: month,
            limit: 50,
            offset: more ? personal.length : 0))
        .data!;
    if (_disposed) return;
    personal = more ? [...personal, ...page.items] : page.items;
    personalTotal = page.total;
  }

  Future<void> _claims({bool more = false}) async {
    final page = (await api.customerKhataControllerClaimList(
            id: vendorId!,
            status: claimStatus,
            limit: 50,
            offset: more ? claims.length : 0))
        .data!;
    if (_disposed) return;
    claims = more ? [...claims, ...page.items] : page.items;
    claimTotal = page.total;
  }

  Future<void> moreEntries() => _run(() => _entries(more: true));
  Future<void> morePersonal() => _run(() => _personal(more: true));
  Future<void> moreClaims() => _run(() => _claims(more: true));
  Future<void> selectClaims(String v) => _run(() async {
        claimStatus = v;
        await _claims();
      });
  Future<void> selectMonth(String v) => _run(() async {
        month = v;
        if (vendorId != null) await _entries();
        if (contactId != null) await _personal();
        await _save();
      });
  Future<void> settlementOptions() => _run(() async {
        options = null;
        if (!stale && pending == null && launch == null && vendorId != null) {
          options =
              (await api.customerKhataControllerOptions(id: vendorId!)).data;
        }
      });
  bool _allowed(CustomerSettlementOptions o, String account, BigInt amount,
      String method) {
    final a =
        o.accounts.where((a) => a.vendorCustomerId == account).firstOrNull;
    return a != null &&
        a.canClaim &&
        amount > BigInt.zero &&
        amount <= BigInt.parse(a.maxClaimPaise) &&
        amount <= BigInt.parse(a.duePaise) &&
        amount <= BigInt.parse(o.duePaise) &&
        (method == 'CASH' && o.cashAvailable ||
            method == 'UPI' && o.upiAvailable && o.upiId != null);
  }

  // Refetch at the last user action. Changed payee/due requires fresh review.
  Future<void> pay(String account, BigInt amount, String method) async {
    final reviewed = options;
    if (!canWrite ||
        reviewed == null ||
        !_allowed(reviewed, account, amount, method)) {
      return;
    }
    await _run(() async {
      final fresh =
          (await api.customerKhataControllerOptions(id: vendorId!)).data!;
      if (_disposed) return;
      options = fresh;
      if (jsonEncode(fresh.toJson()) != jsonEncode(reviewed.toJson()) ||
          !_allowed(fresh, account, amount, method)) {
        throw const ConflictFailure(code: 'PAYMENT_DETAILS_CHANGED');
      }
      completed = false;
      if (method == 'CASH') {
        pending = {
          'action': 'CLAIM',
          'id': vendorId,
          'key': const Uuid().v4(),
          'body': {
            'vendorCustomerId': account,
            'amountPaise': amount.toString(),
            'method': 'CASH'
          }
        };
        await _send();
      } else {
        final uri = khataUpiUri(fresh.upiId!, fresh.payeeName, amount);
        launch = {
          'vendorId': vendorId,
          'vendorCustomerId': account,
          'amountPaise': amount.toString(),
          'vpa': fresh.upiId,
          'payee': fresh.payeeName,
          'uri': uri.toString(),
          'fallback': false
        };
        await _save(); // Abort launch if encryption/storage failed.
        if (_disposed) return;
        final handled = await device.open(uri);
        if (_disposed) return;
        launch!['fallback'] = !handled;
        await _save(); // Review survives process/activity recreation.
      }
    });
  }

  Future<void> dismissPayment() => _run(() async {
        if (pending != null) return;
        await _save(clearLaunch: true);
        if (!_disposed) launch = null;
      });
  Future<void> confirmPaid() async {
    if (!canReview) return;
    await _run(() async {
      final draft = launch!;
      // This is only the customer's assertion. API rechecks ownership/current due.
      pending = {
        'action': 'CLAIM',
        'id': draft['vendorId'],
        'key': const Uuid().v4(),
        'body': {
          'vendorCustomerId': draft['vendorCustomerId'],
          'amountPaise': draft['amountPaise'],
          'method': 'UPI'
        }
      };
      await _send();
    });
  }

  Future<void> submit(String action, Map<String, dynamic> body,
      {String? id}) async {
    if (!canWrite ||
        !{
          'CONTACT_CREATE',
          'CONTACT_PATCH',
          'CONTACT_DELETE',
          'ENTRY_CREATE',
          'ENTRY_PATCH',
          'ENTRY_DELETE'
        }.contains(action)) {
      return;
    }
    await _run(() async {
      completed = false;
      pending = {
        'action': action,
        'id': id,
        'key': const Uuid().v4(),
        'body': jsonDecode(jsonEncode(body))
      };
      await _send();
    });
  }

  Future<void> retry() => _run(_send);
  Future<void> _send() async {
    final p = pending;
    if (p == null || _disposed) return;
    await _save();
    if (_disposed) return;
    final key = p['key'] as String, id = p['id'] as String?;
    final body = Map<String, dynamic>.from(p['body'] as Map);
    try {
      switch (p['action']) {
        case 'CLAIM':
          await api.customerKhataControllerClaim(
              id: id!,
              idempotencyKey: key,
              paymentClaimInput: PaymentClaimInput.fromJson(body));
        case 'CONTACT_CREATE':
          await api.customerKhataControllerContactCreate(
              idempotencyKey: key,
              personalContactInput: PersonalContactInput.fromJson(body));
        case 'CONTACT_PATCH':
          await api.customerKhataControllerContactPatch(
              id: id!,
              idempotencyKey: key,
              personalContactPatch: PersonalContactPatch.fromJson(body));
        case 'CONTACT_DELETE':
          await api.customerKhataControllerContactDelete(
              id: id!,
              idempotencyKey: key,
              khataVersion: KhataVersion.fromJson(body));
        case 'ENTRY_CREATE':
          await api.customerKhataControllerEntryCreate(
              idempotencyKey: key,
              personalEntryInput: PersonalEntryInput.fromJson(body));
        case 'ENTRY_PATCH':
          await api.customerKhataControllerEntryPatch(
              id: id!,
              idempotencyKey: key,
              personalEntryPatch: PersonalEntryPatch.fromJson(body));
        case 'ENTRY_DELETE':
          await api.customerKhataControllerEntryDelete(
              id: id!,
              idempotencyKey: key,
              khataVersion: KhataVersion.fromJson(body));
        default:
          throw const UnknownFailure(code: 'INVALID_SAVED_REQUEST');
      }
    } catch (e) {
      final f = e is DioException ? mapDioFailure(e) : e;
      if (f is ValidationFailure ||
          f is ConflictFailure ||
          f is NotFoundFailure ||
          f is BusinessRuleFailure && f.code != 'RATE_LIMITED') {
        await _save(clearPending: true, clearLaunch: p['action'] == 'CLAIM');
        if (!_disposed) {
          pending = null;
          if (p['action'] == 'CLAIM') launch = null;
        }
      }
      rethrow;
    }
    if (_disposed) return;
    await _save(clearPending: true, clearLaunch: p['action'] == 'CLAIM');
    if (_disposed) return;
    pending = null;
    if (p['action'] == 'CLAIM') launch = null;
    if (p['action'] == 'CONTACT_DELETE') {
      deleted = true;
      contact = null;
      personal = [];
    }
    completed = true;
    stale = true;
    await _refresh();
  }
}
