// T-044 / RULE-05/06: local intent only. T-046 must obtain a server quote before ordering.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import '../../core/network/app_failure.dart';
import '../auth/session_controller.dart';
import '../onboarding/onboarding_controller.dart';

final cartProvider = ChangeNotifierProvider<CartController>((ref) {
  final identity = ref.watch(
      sessionProvider.select((s) => (s.user?.id, s.user?.activeRole?.value)));
  final model = CartController(ref.read(onboardingDraftsProvider),
      '${ref.read(authConfigProvider).baseUrl}:${identity.$1}:cart');
  if (identity.$1 != null && identity.$2 == 'CUSTOMER') {
    Future.microtask(model.load);
  }
  return model;
});

class CartLine {
  const CartLine(this.vendorId, this.vendorName, this.product, this.qty);
  final String vendorId, vendorName;
  final ProductResponse product;
  final int qty;
  Map<String, dynamic> toJson() => {
        'vendorId': vendorId,
        'vendorName': vendorName,
        'product': product.toJson(),
        'qty': qty
      };
  factory CartLine.fromJson(Map<String, dynamic> j) => CartLine(
      j['vendorId'] as String,
      j['vendorName'] as String,
      ProductResponse.fromJson(Map<String, dynamic>.from(j['product'] as Map)),
      j['qty'] as int);
}

enum CartChange { saved, replaceVendor, invalid, unavailable }

class CartController extends ChangeNotifier {
  CartController(this.store, this.owner);
  final OnboardingDrafts store;
  final String owner;
  List<CartLine> lines = [];
  AppFailure? failure;
  bool busy = false, ready = false, checkoutLocked = false, _disposed = false;
  int get count => lines.fold(0, (n, l) => n + l.qty);
  bool get canEdit => ready && !busy && !checkoutLocked && !_disposed;
  void lockCheckout(bool locked) {
    checkoutLocked = locked;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    if (busy || _disposed) return;
    busy = true;
    failure = null;
    notifyListeners();
    try {
      final saved = await store.read(owner);
      final checkoutOwner = owner.endsWith(':cart')
          ? '${owner.substring(0, owner.length - 5)}:checkout'
          : '$owner:checkout';
      final checkout = await store.read(checkoutOwner);
      if (_disposed) return;
      checkoutLocked =
          checkout.containsKey('pending') || checkout.containsKey('result');
      final next = (jsonDecode(saved['lines'] ?? '[]') as List)
          .map((r) => CartLine.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
      if (next.map((l) => l.vendorId).toSet().length > 1 ||
          next.any((l) =>
              l.qty < l.product.moq ||
              l.qty <= 0 ||
              l.qty > l.product.stockQty ||
              l.product.sellingPricePaise < 0)) {
        throw const UnknownFailure();
      }
      lines = next;
      ready = true;
    } catch (_) {
      if (!_disposed) {
        lines = [];
        failure = const UnknownFailure();
      }
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> _write(List<CartLine> next, {bool purchased = false}) async {
    if (!ready || busy || _disposed || checkoutLocked && !purchased) {
      return false;
    }
    busy = true;
    failure = null;
    notifyListeners();
    try {
      await store.write(
          owner, {'lines': jsonEncode(next.map((l) => l.toJson()).toList())});
      if (_disposed) return false;
      lines = next;
      return true;
    } catch (_) {
      failure = const UnknownFailure();
      return false;
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<CartChange> add(
      String vendorId, String vendorName, ProductResponse p, int qty,
      {bool replace = false}) async {
    if (!canEdit) return CartChange.unavailable;
    if (!p.isActive || qty < p.moq || qty <= 0 || qty > p.stockQty) {
      return CartChange.invalid;
    }
    final mixed = lines.isNotEmpty && lines.first.vendorId != vendorId;
    if (mixed && !replace) return CartChange.replaceVendor;
    final next = mixed ? <CartLine>[] : List<CartLine>.of(lines);
    final index = next.indexWhere((l) => l.product.id == p.id);
    final quantity = qty + (index < 0 ? 0 : next[index].qty);
    if (quantity > p.stockQty) return CartChange.invalid;
    final row = CartLine(vendorId, vendorName, p, quantity);
    if (index < 0) {
      next.add(row);
    } else {
      next[index] = row;
    }
    return await _write(next) ? CartChange.saved : CartChange.unavailable;
  }

  Future<void> clear() => _write([]);
  Future<bool> clearPurchased() => _write([], purchased: true);
  Future<bool> quantity(String id, int qty) async {
    final next = List<CartLine>.of(lines),
        index = lines.indexWhere((l) => l.product.id == id);
    if (index < 0) return false;
    final row = next[index];
    if (qty == 0) {
      next.removeAt(index);
    } else {
      if (qty < row.product.moq || qty > row.product.stockQty) return false;
      next[index] = CartLine(row.vendorId, row.vendorName, row.product, qty);
    }
    return _write(next);
  }
}
