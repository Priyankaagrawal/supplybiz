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
  }) {
    final environmentName =
        configuredName ?? const String.fromEnvironment('ENV_NAME');
    final baseUrl = configuredApiBaseUrl ?? apiBaseUrl;
    if (environmentName.isNotEmpty && environmentName != name) {
      throw StateError(
        'The $name flavor cannot start with ENV_NAME=$environmentName.',
      );
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
