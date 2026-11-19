// T-107 / S-V-29 / S-C-34. Public published FAQ reads; five bounded cached pages.
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import '../../core/network/app_failure.dart';
import '../../core/network/network_client.dart';
import '../auth/session_controller.dart';
import '../onboarding/onboarding_controller.dart';
import '../profile/profile_controller.dart' show profileClient;

final helpProvider = ChangeNotifierProvider.autoDispose<HelpController>((ref) {
  final identity = ref.watch(sessionProvider
          .select((s) => (s.user?.id, s.user?.activeRole?.value))),
      config = ref.read(authConfigProvider),
      client = profileClient(ref);
  ref.onDispose(client.close);
  return HelpController(
      ContentApi(client.dio),
      ref.read(onboardingDraftsProvider),
      '${config.baseUrl}:${identity.$1}:${identity.$2}:help');
});

class HelpController extends ChangeNotifier {
  HelpController(this.api, this.store, this.owner);
  final ContentApi api;
  final OnboardingDrafts store;
  final String owner;
  FaqList? value;
  DateTime? downloadedAt;
  String? topic;
  int offset = 0;
  AppFailure? failure;
  bool busy = false,
      stale = true,
      cacheUnavailable = false,
      _disposed = false,
      _restored = false,
      _storageReady = false;
  final _pages = <String, String>{};
  String _key(String? topic, int offset) => '${topic ?? '*'}:$offset';
  List<String> get topics => ({
        ...['orders', 'payments', 'delivery', 'account', 'kyc', 'general'],
        if (topic != null) topic!,
        ...?value?.items.map((r) => r.topic)
      }).toList();
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _restore() async {
    if (_restored) return;
    try {
      final saved = await store.read(owner);
      if (_disposed) return;
      final memory = Map<String, String>.of(_pages);
      _pages
        ..clear()
        ..addAll(Map.fromEntries(saved.entries.take(5)));
      for (final entry in memory.entries) {
        _pages.remove(entry.key);
        _pages[entry.key] = entry.value;
      }
      while (_pages.length > 5) {
        _pages.remove(_pages.keys.first);
      }
      _restored = true;
      _storageReady = true;
    } catch (_) {
      cacheUnavailable = true;
    }
  }

  void _cached(String key) {
    value = null;
    downloadedAt = null;
    try {
      if (_pages[key] case final raw?) {
        final body = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        value =
            FaqList.fromJson(Map<String, dynamic>.from(body['value'] as Map));
        downloadedAt = DateTime.parse(body['downloadedAt'] as String);
      }
    } catch (_) {
      _pages.remove(key);
      cacheUnavailable = true;
    }
  }

  Future<void> _persist() async {
    if (!_disposed && _storageReady) {
      try {
        await store.write(owner, Map.of(_pages));
        cacheUnavailable = false;
      } catch (_) {
        cacheUnavailable = true;
      }
    }
  }

  Future<void> load({String? topic, int? offset, bool all = false}) async {
    if (_disposed || busy) return;
    if (topic != null && !RegExp(r'^[a-z][a-z0-9-]{0,39}$').hasMatch(topic) ||
        offset != null && (offset < 0 || offset > 100000)) {
      return;
    }
    busy = true;
    failure = null;
    stale = true;
    _notify();
    try {
      await _restore();
      if (_disposed) return;
      this.topic = all ? null : topic ?? this.topic;
      this.offset = all ? 0 : offset ?? this.offset;
      final key = _key(this.topic, this.offset);
      _cached(key);
      _notify();
      try {
        final result = (await api.contentControllerFaqs(
                topic: this.topic,
                offset: this.offset,
                extra: {NetworkClient.publicRequest: true}))
            .data!;
        if (_disposed) return;
        if (result.items.any((r) => !r.published)) throw const UnknownFailure();
        value = result;
        downloadedAt = DateTime.now().toUtc();
        stale = false;
        _pages.remove(key);
        _pages[key] = jsonEncode({
          'value': result.toJson(),
          'downloadedAt': downloadedAt!.toIso8601String()
        });
        while (_pages.length > 5) {
          _pages.remove(_pages.keys.first);
        }
        await _persist();
      } catch (e) {
        if (_disposed) return;
        failure = e is DioException
            ? mapDioFailure(e)
            : e is AppFailure
                ? e
                : const UnknownFailure();
        if (e is DioException &&
            [401, 403, 404].contains(e.response?.statusCode)) {
          value = null;
          downloadedAt = null;
          _pages.remove(key);
          await _persist();
        }
      }
    } finally {
      busy = false;
      _notify();
    }
  }
}
