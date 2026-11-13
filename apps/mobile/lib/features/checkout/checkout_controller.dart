// T-046: server quotes and encrypted, permanent same-key order recovery.
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:uuid/uuid.dart';
import '../../core/network/app_failure.dart';
import '../auth/session_controller.dart';
import '../home/home_controller.dart';
import '../onboarding/onboarding_controller.dart';
import '../discovery/cart_controller.dart';

final checkoutProvider = ChangeNotifierProvider<CheckoutController>((ref) {
  final identity = ref.watch(
      sessionProvider.select((s) => (s.user?.id, s.user?.activeRole?.value)));
  final client = homeClient(ref);
  final model = CheckoutController(
      CustomerOrdersApi(client.dio),
      CustomerAddressesApi(client.dio),
      ref.read(cartProvider),
      ref.read(onboardingDraftsProvider),
      '${ref.read(authConfigProvider).baseUrl}:${identity.$1}:checkout');
  ref.onDispose(client.close);
  if (identity.$1 != null && identity.$2 == 'CUSTOMER') {
    Future.microtask(model.load);
  }
  return model;
});

class CheckoutController extends ChangeNotifier {
  CheckoutController(
      this.api, this.addressApi, this.cart, this.store, this.owner) {
    signature = _signature;
    cart.addListener(_cartChanged);
  }
  final CustomerOrdersApi api;
  final CustomerAddressesApi addressApi;
  final CartController cart;
  final OnboardingDrafts store;
  final String owner;
  List<AddressResponse> addresses = [];
  CheckoutOptions? options;
  OrderQuote? quote;
  OrderResult? result;
  Map<String, dynamic>? pending;
  AppFailure? failure;
  String? productErrorId;
  String? addressId, date, slot;
  String payment = 'POD_CASH';
  late String signature;
  bool busy = false,
      ready = false,
      _restored = false,
      _disposed = false,
      priceChanged = false;
  String get _signature =>
      jsonEncode(cart.lines.map((l) => l.toJson()).toList());
  bool get canChoose => ready && !busy && pending == null && result == null;
  bool get canQuote =>
      canChoose &&
      cart.ready &&
      cart.lines.isNotEmpty &&
      addressId != null &&
      options?.availableDates.contains(date) == true &&
      options?.timeSlots.contains(slot) == true;
  bool get canPlace => canQuote && quote != null;
  @override
  void dispose() {
    _disposed = true;
    cart.removeListener(_cartChanged);
    super.dispose();
  }

  void _cartChanged() {
    final next = _signature;
    if (next == signature || _disposed) return;
    signature = next;
    quote = null;
    options = null;
    notifyListeners();
  }

  Future<void> _persist() => store.write(owner, {
        if (pending != null) 'pending': jsonEncode(pending),
        if (result != null) 'result': jsonEncode(result!.toJson()),
      });
  Future<void> _run(Future<void> Function() action) async {
    if (busy || _disposed) return;
    busy = true;
    failure = null;
    productErrorId = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      if (_disposed) return;
      failure = error is DioException
          ? mapDioFailure(error)
          : error is AppFailure
              ? error
              : const UnknownFailure();
      if (failure is UnauthorizedFailure || failure is ForbiddenFailure) {
        options = null;
        quote = null;
        addresses = [];
        ready = false;
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
          pending = saved['pending'] == null
              ? null
              : Map<String, dynamic>.from(jsonDecode(saved['pending']!) as Map);
          result = saved['result'] == null
              ? null
              : OrderResult.fromJson(Map<String, dynamic>.from(
                  jsonDecode(saved['result']!) as Map));
          _restored = true;
          cart.lockCheckout(pending != null || result != null);
        }
        final rows = (await addressApi.addressesControllerList()).data!.items;
        if (_disposed) return;
        addresses = rows;
        ready = true;
        if (!rows.any((a) => a.id == addressId)) {
          addressId = rows.where((a) => a.isDefault).firstOrNull?.id ??
              rows.firstOrNull?.id;
        }
        if (pending == null && result == null) await _options();
      });
  Future<void> chooseAddress(String id) => _run(() async {
        if (pending != null || result != null) return;
        addressId = id;
        await _options();
      });
  void choose({String? deliveryDate, String? timeSlot, String? mode}) {
    if (!canChoose) return;
    if (deliveryDate != null &&
        options?.availableDates.contains(deliveryDate) != true) {
      return;
    }
    if (timeSlot != null && options?.timeSlots.contains(timeSlot) != true) {
      return;
    }
    if (mode != null && !['POD_CASH', 'POD_UPI'].contains(mode)) return;
    date = deliveryDate ?? date;
    slot = timeSlot ?? slot;
    payment = mode ?? payment;
    quote = null;
    priceChanged = false;
    notifyListeners();
  }

  Future<void> _options() async {
    quote = null;
    options = null;
    priceChanged = false;
    if (addressId == null || cart.lines.isEmpty) return;
    final snapshot = _signature;
    final data = (await api.customerOrdersControllerOptions(
            vendorId: cart.lines.first.vendorId, addressId: addressId!))
        .data!;
    if (_disposed || snapshot != _signature) return;
    options = data;
    if (!data.availableDates.contains(date)) {
      date = data.availableDates.firstOrNull;
    }
    if (!data.timeSlots.contains(slot)) slot = data.timeSlots.firstOrNull;
  }

  Map<String, dynamic> _body() => {
        'vendorId': cart.lines.first.vendorId,
        'addressId': addressId,
        'deliveryDate': date,
        'timeSlot': slot,
        'paymentMode': payment,
        'items': cart.lines
            .map((l) => {'productId': l.product.id, 'qty': l.qty})
            .toList(),
      };
  Future<void> refreshQuote() async {
    if (!canQuote) return;
    await _run(() async {
      quote = null;
      priceChanged = false;
      final snapshot = _signature, body = _body();
      final data = (await api.customerOrdersControllerQuote(
              orderQuoteInput: OrderQuoteInput.fromJson(body)))
          .data!;
      if (!_disposed && snapshot == _signature) quote = data;
    });
  }

  Future<void> place() async {
    if (!canPlace) return;
    await _run(() async {
      pending = {
        'key': const Uuid().v4(),
        'body': {..._body(), 'expectedTotalPaise': quote!.totalPaise}
      };
      cart.lockCheckout(true);
      // Persist before sending. Disk failure must never create an untracked order.
      await _persist();
      if (_disposed) return;
      await _send();
    });
  }

  Future<void> retry() => _run(() async {
        if (pending != null) {
          await _persist();
          if (!_disposed) await _send();
        }
      });
  Future<void> _send() async {
    final saved = pending;
    if (saved == null || _disposed) return;
    OrderResult accepted;
    try {
      accepted = (await api.customerOrdersControllerPlace(
              idempotencyKey: saved['key'] as String,
              orderPlaceInput: OrderPlaceInput.fromJson(
                  Map<String, dynamic>.from(saved['body'] as Map))))
          .data!;
    } on DioException catch (error) {
      if (_disposed) rethrow;
      final status = error.response?.statusCode;
      final data = error.response?.data;
      if (data is Map) {
        productErrorId =
            data['productId'] is String ? data['productId'] as String : null;
        if (data['code'] == 'PRICE_CHANGED' && data['quote'] is Map) {
          quote = OrderQuote.fromJson(
              Map<String, dynamic>.from(data['quote'] as Map));
          priceChanged = true;
        } else {
          quote = null;
        }
      }
      if ([400, 404, 409, 422].contains(status)) {
        pending = null;
        try {
          await _persist();
        } catch (_) {
          pending = saved;
          rethrow;
        }
        cart.lockCheckout(false);
      }
      rethrow;
    }
    if (_disposed) return;
    result = accepted;
    pending = null;
    quote = null;
    try {
      await _persist();
    } catch (_) {
      pending = saved;
      rethrow;
    }
    await cart.clearPurchased();
  }

  Future<void> finish() => _run(() async {
        if (result == null || pending != null) return;
        if (!await cart.clearPurchased()) throw const UnknownFailure();
        final prior = result;
        result = null;
        try {
          await _persist();
        } catch (_) {
          result = prior;
          rethrow;
        }
        cart.lockCheckout(false);
        options = null;
        quote = null;
      });
}
