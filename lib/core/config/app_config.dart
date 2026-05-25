class AppConfig {
  // DEV:  --dart-define=API_BASE_URL=http://10.0.2.2:3000
  // PROD: default (https://api.quantixtechnology.in)
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.quantixtechnology.in',
  );
  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'https://api.quantixtechnology.in',
  );
  static const String appName = 'Quantix';
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
}
