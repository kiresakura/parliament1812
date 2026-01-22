/// API 常數配置
class ApiConstants {
  // 開發環境
  static const String devBaseUrl = 'http://localhost:3000';

  // 生產環境（部署後更新這裡）
  static const String prodBaseUrl =
      'https://parliament1812-production.up.railway.app';

  static String get baseUrl {
    // 可透過編譯參數切換
    // flutter run --dart-define=ENV=prod
    const String env = String.fromEnvironment('ENV', defaultValue: 'dev');
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
