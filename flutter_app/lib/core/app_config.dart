class AppConfig {
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://ais-dev-kwoa5kr2snbo2k4x27lkaa-164967912406.europe-west3.run.app',
  );

  /// مرّر GOOGLE_CLIENT_ID عبر --dart-define عند إرفاق مفاتيح جوجل لاحقًا
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );
}
