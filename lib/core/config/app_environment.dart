enum AppEnvironment { demo, development, production }

class AppConfig {
  final AppEnvironment environment;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String fcmVapidKey;

  const AppConfig({required this.environment, this.supabaseUrl = '',
    this.supabaseAnonKey = '', this.fcmVapidKey = ''});

  factory AppConfig.fromDefines({AppEnvironment? fallback}) {
    const raw = String.fromEnvironment('APP_ENV');
    final environment = switch (raw) {
      'demo' => AppEnvironment.demo,
      'production' => AppEnvironment.production,
      'development' => AppEnvironment.development,
      _ => fallback ?? AppEnvironment.development,
    };
    return AppConfig(
      environment: environment,
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
      fcmVapidKey: const String.fromEnvironment('FCM_VAPID_KEY'),
    );
  }

  bool get isDemo => environment == AppEnvironment.demo;
  bool get hasSupabase => supabaseUrl.startsWith('https://') && supabaseAnonKey.isNotEmpty;

  void validate() {
    if (!isDemo && !hasSupabase) {
      throw const AppConfigurationException(
        'إعداد Supabase غير مكتمل. أضف SUPABASE_URL وSUPABASE_ANON_KEY عند البناء.',
      );
    }
  }
}

class AppConfigurationException implements Exception {
  final String message;
  const AppConfigurationException(this.message);
  @override String toString() => message;
}
