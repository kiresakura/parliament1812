/// 應用程式配置
class AppConfig {
  static const String appName = '1812 國會風雲';
  static const String appVersion = '1.0.0';

  // API 配置 - 開發環境 (本地)
  static const String apiBaseUrl = 'http://localhost:8000';
  static const String wsBaseUrl = 'ws://localhost:8000';

  // 生產環境 (Railway)
  static const String prodApiBaseUrl = 'https://1812-production.up.railway.app';
  static const String prodWsBaseUrl = 'wss://1812-production.up.railway.app';

  // ⚠️ 改這裡切換環境！
  // true = localhost (模擬器用)
  // false = Railway production (真機用)
  static const bool isDevelopment = false;

  // 取得當前 API URL
  static String get currentApiUrl => isDevelopment ? apiBaseUrl : prodApiBaseUrl;
  static String get currentWsUrl => isDevelopment ? wsBaseUrl : prodWsBaseUrl;

  // WebSocket 配置
  static const int wsReconnectDelay = 3000; // 毫秒
  static const int wsHeartbeatInterval = 30000; // 毫秒

  // 遊戲配置
  static const int maxPlayersPerRoom = 20;
  static const int minPlayersToStart = 5;
  static const int roomCodeLength = 6;

  // NFC 配置
  static const String nfcUrlScheme = 'parliament1812';
}
