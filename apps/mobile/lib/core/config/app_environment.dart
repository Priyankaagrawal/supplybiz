enum AppEnvironment {
  dev,
  staging,
  prod;

  String get displayName => switch (this) {
        AppEnvironment.dev => 'Development',
        AppEnvironment.staging => 'Staging',
        AppEnvironment.prod => 'Production',
      };

  String get apiBaseUrl => const String.fromEnvironment('API_BASE_URL');

  bool get firebaseEnabled =>
      const bool.fromEnvironment('FIREBASE_ENABLED', defaultValue: false);

  void validateCompileTimeConfig({
    String? configuredName,
    String? configuredApiBaseUrl,
    String? nativeFlavor,
  }) {
    final environmentName =
        configuredName ?? const String.fromEnvironment('ENV_NAME');
    final baseUrl = configuredApiBaseUrl ?? apiBaseUrl;
    if (environmentName != name) {
      throw StateError(
        'Set ENV_NAME to match the $name entrypoint.',
      );
    }
    if (nativeFlavor != null && nativeFlavor != name) {
      throw StateError('The native flavor must match the $name entrypoint.');
    }

    final apiUri = Uri.tryParse(baseUrl);
    if (apiUri == null ||
        !apiUri.hasAuthority ||
        apiUri.host.isEmpty ||
        !{'http', 'https'}.contains(apiUri.scheme)) {
      throw StateError(
        'Set API_BASE_URL to an absolute HTTP(S) URL for the $name flavor.',
      );
    }
  }
}
