/// API 常數配置
class ApiConstants {
  // 開發環境
  static const String devBaseUrl = 'http://localhost:3000';

  // 生產環境 (Fly.io - Rust 後端)
  static const String prodBaseUrl =
      'https://parliament1812-api.fly.dev';

  static String get baseUrl {
    // 可透過編譯參數切換
    // flutter run --dart-define=ENV=dev (使用本地)
    // 預設使用生產環境
    const String env = String.fromEnvironment('ENV', defaultValue: 'prod');
    return env == 'prod' ? prodBaseUrl : devBaseUrl;
  }

  static String get wsUrl {
    return baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
  }

  // API 端點
  static const String healthEndpoint = '/health';
  static const String roomsCountEndpoint = '/api/rooms/count';
}
