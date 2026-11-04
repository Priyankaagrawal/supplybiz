import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';

import '../../features/auth/session_controller.dart';

final _version =
    RegExp(r'^(0|[1-9]\d{0,5})\.(0|[1-9]\d{0,5})\.(0|[1-9]\d{0,5})$');
bool isOlderVersion(String current, String minimum) {
  if (!_version.hasMatch(current) || !_version.hasMatch(minimum)) {
    throw const FormatException('Invalid app version');
  }
  final a = current.split('.').map(int.parse).toList();
  final b = minimum.split('.').map(int.parse).toList();
  for (var i = 0; i < 3; i++) {
    if (a[i] != b[i]) return a[i] < b[i];
  }
  return false;
}

class AppConfig {
  AppConfig(this.minVersionAndroid, Map<String, bool> flags)
      : flags = Map.unmodifiable(flags) {
    isOlderVersion(minVersionAndroid, minVersionAndroid);
  }
  final String minVersionAndroid;
  final Map<String, bool> flags;
  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final flags = (json['flags'] as Map<String, dynamic>)
        .map((key, value) => MapEntry(key, value as bool));
    return AppConfig(json['minVersionAndroid'] as String, flags);
  }
  Map<String, dynamic> toJson() => {
        'minVersionAndroid': minVersionAndroid,
        'flags': flags,
      };
  // Flags are presentation configuration, never authorization or entitlements.
  bool enabled(String key) => flags[key] ?? false;
}

abstract interface class ConfigCache {
  Future<AppConfig?> read(String origin);
  Future<void> write(String origin, AppConfig config);
}

class FileConfigCache implements ConfigCache {
  FileConfigCache({Future<Directory> Function()? directory})
      : _directory = directory ?? getApplicationSupportDirectory;
  final Future<Directory> Function() _directory;
  Future<File> get _file async =>
      File('${(await _directory()).path}/mobile-config.json');
  @override
  Future<AppConfig?> read(String origin) async {
    try {
      final json = jsonDecode(await (await _file).readAsString())
          as Map<String, dynamic>;
      if (json['origin'] != origin) return null;
      return AppConfig.fromJson(json['config'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String origin, AppConfig config) async {
    final file = await _file;
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(
        jsonEncode({'origin': origin, 'config': config.toJson()}),
        flush: true);
    await temporary.rename(file.path);
  }
}

class AndroidAppInfo {
  static const channel = MethodChannel('in.supplybiz/app');
  Future<String> version() async =>
      (await channel.invokeMethod<String>('version'))!;
  Future<bool> openStore() async =>
      await channel.invokeMethod<bool>('openStore') ?? false;
}

final androidAppInfoProvider = Provider((ref) => AndroidAppInfo());
final configCacheProvider = Provider<ConfigCache>((ref) => FileConfigCache());
final configAdapterProvider = Provider<HttpClientAdapter?>((ref) => null);
final configProvider =
    NotifierProvider<ConfigController, ConfigState>(ConfigController.new);

class ConfigState {
  const ConfigState(
      {this.value,
      this.version,
      this.loading = true,
      this.offline = false,
      this.serverBlocked = false});
  final AppConfig? value;
  final String? version;
  final bool loading, offline, serverBlocked;
  bool get ready => value != null && version != null;
  bool get forceUpdate =>
      serverBlocked ||
      ready && isOlderVersion(version!, value!.minVersionAndroid);
}

class ConfigController extends Notifier<ConfigState> {
  bool _busy = false, _disposed = false;
  @override
  ConfigState build() {
    ref.onDispose(() => _disposed = true);
    return const ConfigState();
  }

  Future<void> requireUpdate() {
    state = ConfigState(
        value: state.value,
        version: state.version,
        loading: false,
        serverBlocked: true);
    return load();
  }

  Future<void> load() async {
    if (_busy) return;
    _busy = true;
    final baseUrl = ref.read(authConfigProvider).baseUrl;
    final cache = ref.read(configCacheProvider);
    final info = ref.read(androidAppInfoProvider);
    final dio = Dio(BaseOptions(
        baseUrl: Uri.parse(baseUrl).origin,
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
        followRedirects: false));
    final adapter = ref.read(configAdapterProvider);
    if (adapter != null) dio.httpClientAdapter = adapter;
    AppConfig? cached = state.value;
    String? version = state.version;
    try {
      cached ??= await cache.read(baseUrl);
      final installed =
          version ?? await info.version().timeout(const Duration(seconds: 1));
      isOlderVersion(installed, installed);
      version = installed;
      if (!_disposed) {
        state = ConfigState(
            value: cached,
            version: version,
            serverBlocked: state.serverBlocked);
      }
      final response = await ConfigurationApi(dio)
          .appConfigControllerRead()
          .timeout(const Duration(seconds: 4));
      final data = response.data!;
      final config = AppConfig(data.minVersionAndroid, data.flags);
      if (!_disposed) {
        state = ConfigState(value: config, version: version, loading: false);
      }
      try {
        await cache.write(baseUrl, config);
      } catch (_) {/* Live policy still applies. */}
    } catch (_) {
      if (!_disposed) {
        state = ConfigState(
            value: cached,
            version: version,
            loading: false,
            offline: true,
            serverBlocked: state.serverBlocked);
      }
    } finally {
      dio.close(force: true);
      _busy = false;
    }
  }
}
