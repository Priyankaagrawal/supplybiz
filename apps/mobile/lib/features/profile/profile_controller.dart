// T-126 / S-C-27/33. Private account cache, explicit saved writes, owned media only.
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

NetworkClient profileClient(Ref ref) => NetworkClient(
    baseUrl: Uri.parse(ref.read(authConfigProvider).baseUrl)
        .replace(path: '')
        .toString(),
    session: ref.read(sessionProvider.notifier),
    adapter: ref.read(authAdapterProvider),
    appVersion: () => ref.read(configProvider).version);
final profileProvider =
    ChangeNotifierProvider.autoDispose<ProfileController>((ref) {
  final id = ref.watch(sessionProvider
          .select((s) => (s.user?.id, s.user?.activeRole?.value))),
      config = ref.read(authConfigProvider),
      client = profileClient(ref);
  ref.onDispose(client.close);
  return ProfileController(client, ref.read(onboardingDraftsProvider),
      '${config.baseUrl}:${id.$1}:${id.$2}:profile');
});

class ProfileController extends ChangeNotifier {
  ProfileController(NetworkClient client, this.store, this.owner)
      : api = ProfileApi(client.dio),
        media = MediaApi(client.dio);
  final ProfileApi api;
  final MediaApi media;
  final OnboardingDrafts store;
  final String owner;
  ProfileResponse? profile;
  Uint8List? photo;
  AppFailure? failure;
  bool busy = false,
      stale = true,
      cacheUnavailable = false,
      photoUnavailable = false,
      terminal = false,
      _disposed = false,
      _restored = false,
      _storageReady = false;
  Map<String, String> _saved = {};
  Uint8List? _uploadBytes;
  String? _uploadKey;
  bool get pending => _saved.containsKey('key');
  String? get pendingKey => _saved['key'];
  Map<String, dynamic>? get pendingBody => _saved['body'] == null
      ? null
      : Map<String, dynamic>.from(jsonDecode(_saved['body']!) as Map);
  String? get selectedPhoto => _saved.containsKey('draftPhoto')
      ? (_saved['draftPhoto']!.isEmpty ? null : _saved['draftPhoto'])
      : profile?.photoMediaId;
  bool get photoStaged => _saved.containsKey('draftPhoto');
  @override
  void dispose() {
    _disposed = true;
    _uploadBytes = null;
    photo = null;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _persist() async {
    if (!_storageReady) throw StateError('Profile cache unavailable');
    if (!_disposed) await store.write(owner, Map.of(_saved));
  }

  AppFailure _error(Object e) => e is DioException
      ? mapDioFailure(e)
      : e is AppFailure
          ? e
          : const UnknownFailure();
  Future<void> _fail(Object e) async {
    if (_disposed) return;
    failure = _error(e);
    terminal = e is DioException &&
        [400, 404, 409, 422].contains(e.response?.statusCode);
    if (failure is UnauthorizedFailure || failure is ForbiddenFailure) {
      profile = null;
      photo = null;
      stale = true;
      _saved = {};
      try {
        await _persist();
      } catch (_) {
        cacheUnavailable = true;
      }
    }
  }

  Future<void> _image() async {
    final id = selectedPhoto;
    photoUnavailable = false;
    if (id == null) {
      photo = null;
      _saved.remove('photo');
      _saved.remove('photoId');
      return;
    }
    try {
      final bytes = (await media.mediaControllerContent(id: id)).data!;
      if (_disposed) return;
      if (bytes.isEmpty || bytes.length > 5242880) throw const UnknownFailure();
      photo = bytes;
      _saved['photo'] = base64Encode(bytes);
      _saved['photoId'] = id;
    } catch (e) {
      if (_disposed) return;
      photoUnavailable = true;
      if (_saved['photoId'] != id) photo = null;
      if (e is DioException && [401, 403].contains(e.response?.statusCode)) {
        await _fail(e);
      }
    }
  }

  Future<void> load() async {
    if (_disposed || busy) return;
    busy = true;
    failure = null;
    stale = true;
    _notify();
    try {
      if (!_restored) {
        try {
          _saved = await store.read(owner);
          if (_disposed) return;
          _storageReady = true;
          _restored = true;
          if (_saved['profile'] != null) {
            profile = ProfileResponse.fromJson(Map<String, dynamic>.from(
                jsonDecode(_saved['profile']!) as Map));
          }
          final encoded = _saved['photo'];
          if (encoded != null &&
              encoded.length <= 6990508 &&
              _saved['photoId'] == selectedPhoto) {
            photo = base64Decode(encoded);
          }
        } catch (_) {
          cacheUnavailable = true;
          _storageReady = false;
          _restored = false;
          profile = null;
          photo = null;
        }
      }
      final value = (await api.profileControllerGet()).data!;
      if (_disposed) return;
      profile = value;
      stale = false;
      _saved['profile'] = jsonEncode(value.toJson());
      await _image();
      try {
        await _persist();
      } catch (_) {
        cacheUnavailable = true;
      }
    } catch (e) {
      await _fail(e);
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> save(String name, String email) async {
    if (_disposed || busy || stale || profile == null) return;
    busy = true;
    failure = null;
    terminal = false;
    _notify();
    try {
      if (!pending) {
        _saved.addAll({
          'key': const Uuid().v4(),
          'body': jsonEncode(ProfileInput(
                  expectedUpdatedAt:
                      profile!.updatedAt.toUtc().toIso8601String(),
                  name: name.trim(),
                  email: email.trim().isEmpty ? null : email.trim(),
                  photoMediaId: selectedPhoto)
              .toJson())
        });
      }
      await _persist();
      if (_disposed) return;
      final result = (await api.profileControllerSave(
              idempotencyKey: _saved['key']!,
              profileInput: ProfileInput.fromJson(pendingBody!)))
          .data!;
      if (_disposed) return;
      profile = result;
      stale = false;
      final before = Map<String, String>.of(_saved);
      _saved['profile'] = jsonEncode(result.toJson());
      for (final k in ['key', 'body', 'draftPhoto']) {
        _saved.remove(k);
      }
      try {
        await _persist();
      } catch (_) {
        _saved = before;
        cacheUnavailable = true;
        throw const UnknownFailure();
      }
    } catch (e) {
      await _fail(e);
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> retry() async => save('', '');
  Future<void> review() async {
    if (_disposed || busy || !terminal) return;
    final before = Map<String, String>.of(_saved);
    for (final k in ['key', 'body', 'draftPhoto']) {
      _saved.remove(k);
    }
    try {
      await _persist();
      terminal = false;
      await load();
    } catch (_) {
      _saved = before;
      cacheUnavailable = true;
      _notify();
    }
  }

  Future<void> upload(Uint8List bytes) async {
    if (_disposed || busy || pending || stale) return;
    busy = true;
    failure = null;
    _notify();
    try {
      if (bytes.isEmpty || bytes.length > 5242880) {
        throw const BusinessRuleFailure(code: 'FILE_INVALID');
      }
      if (_uploadBytes == null || !listEquals(_uploadBytes, bytes)) {
        _uploadBytes = bytes;
        _uploadKey = const Uuid().v4();
      }
      final result = (await media.mediaControllerUpload(
              idempotencyKey: _uploadKey!,
              purpose: 'PROFILE',
              file: MultipartFile.fromBytes(_uploadBytes!,
                  filename: bytes.first == 137 ? 'profile.png' : 'profile.jpg',
                  contentType: DioMediaType.parse(
                      bytes.first == 137 ? 'image/png' : 'image/jpeg'))))
          .data!;
      if (_disposed) return;
      _saved['draftPhoto'] = result.mediaId;
      await _persist();
      await _image();
      await _persist();
      _uploadBytes = null;
      _uploadKey = null;
    } catch (e) {
      await _fail(e);
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> removePhoto() async {
    if (_disposed || busy || pending || stale) return;
    _saved['draftPhoto'] = '';
    photo = null;
    try {
      await _persist();
    } catch (_) {
      cacheUnavailable = true;
      failure = const UnknownFailure();
    }
    _notify();
  }

  Future<void> clearCache() async {
    if (_disposed || busy) return;
    final before = Map<String, String>.of(_saved);
    for (final k in ['profile', 'photo', 'photoId']) {
      _saved.remove(k);
    }
    try {
      await _persist();
      profile = null;
      photo = null;
      stale = true;
    } catch (_) {
      _saved = before;
      cacheUnavailable = true;
      failure = const UnknownFailure();
    }
    _notify();
  }
}

final profileLegalProvider = ChangeNotifierProvider.autoDispose
    .family<ProfileLegalController, String>((ref, type) {
  final client = profileClient(ref);
  ref.onDispose(client.close);
  return ProfileLegalController(ContentApi(client.dio), type);
});

class ProfileLegalController extends ChangeNotifier {
  ProfileLegalController(this.api, this.type);
  final ContentApi api;
  final String type;
  LegalRow? value;
  AppFailure? failure;
  bool busy = false, stale = true, _disposed = false;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    if (_disposed || busy) return;
    busy = true;
    failure = null;
    stale = true;
    notifyListeners();
    try {
      final result = (await api.contentControllerLegal(type: type)).data!;
      if (_disposed) return;
      value = result;
      stale = false;
    } catch (e) {
      if (!_disposed) {
        failure = e is DioException ? mapDioFailure(e) : const UnknownFailure();
      }
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }
}
