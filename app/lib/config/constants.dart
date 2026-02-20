class AppConstants {
  // 應用資訊
  static const String appName = 'Parliament 1812';
  static const String appVersion = '1.0.0';

  // 後端 URL 配置
  static const String _flyBaseUrl = 'https://parliament1812-api.fly.dev';
  static const String _flyWsUrl = 'wss://parliament1812-api.fly.dev/ws';

  static String get baseUrl {
    const fromEnv = String.fromEnvironment('PARLIAMENT_API_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    // 預設連 Fly.io（Tokyo）
    return _flyBaseUrl;
  }

  static String get websocketUrl {
    const fromEnv = String.fromEnvironment('PARLIAMENT_WS_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    return _flyWsUrl;
  }

  // 本地開發用（需手動切換或傳環境變數）
  // flutter run --dart-define=PARLIAMENT_API_URL=http://192.168.8.190:8080

  // 生產環境 URL（自訂域名）
  static const String prodBaseUrl = 'https://api.parliament1812.com';
  static const String prodWebsocketUrl = 'wss://api.parliament1812.com/ws';

  // API 端點
  static const String authEndpoint = '/api/auth';
  static const String roomsEndpoint = '/api/rooms';
  static const String gameEndpoint = '/api/game';
  static const String codexEndpoint = '/api/codex';
  static const String websocketEndpoint = '/ws';

  // 遊戲常數
  static const int maxPlayersPerRoom = 7;
  static const int minPlayersPerRoom = 3;
  static const int roomCodeLength = 6;
  
  // 資源限制
  static const int maxReputation = 100;
  static const int maxInfluence = 15;
  static const int maxGold = 150;
  static const int initialInfluence = 10;
  
  // 卡牌系統
  static const int handsizeLimit = 8;
  static const int universalCardsPerPlayer = 5;
  static const int characterCardsPerPlayer = 3;
  static const int negativeTraitsPerPlayer = 2;
  
  // 回合時間（秒）
  static const int preparationPhaseDuration = 60;  // 1 分鐘
  static const int conspiracyPhaseDuration = 180;  // 3 分鐘
  static const int debatePhaseDuration = 360;      // 6 分鐘
  static const int eventPhaseDuration = 60;        // 1 分鐘
  static const int finalSpeechDuration = 120;      // 2 分鐘
  static const int votingPhaseDuration = 60;       // 1 分鐘
  
  // 發言時間限制
  static const int speakingTimeLimitPerPlayer = 45; // 45 秒
  static const int freeDebateSlotDuration = 15;     // 15 秒
  
  // 影響力經濟
  static const int influenceRecoveryPerRound = 3;
  
  // 卡牌稀有度機率（用於顯示）
  static const Map<String, double> cardRarityProbability = {
    'N': 0.53,   // 53%
    'R': 0.25,   // 25%
    'SR': 0.17,  // 17%
    'SSR': 0.05, // 5%
  };
  
  // 角色列表
  static const List<String> characterTypes = [
    'thomas_worker',     // 工人湯瑪斯
    'richard_factory',   // 工廠主理查
    'george_luddite',    // 盧德派喬治
    'robert_reformer',   // 改革者羅伯特
    'edward_journalist', // 記者愛德華
    'william_mp',        // 議員威廉
    'george_king',       // 喬治三世
  ];
  
  // 陣營類型
  static const List<String> factionTypes = [
    'labor',    // 勞工派
    'capital',  // 資方派
    'reform',   // 改革派
    'neutral',  // 中立派
  ];
  
  // WebSocket 心跳間隔
  static const Duration heartbeatInterval = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration reconnectDelay = Duration(seconds: 5);
  static const int maxReconnectAttempts = 3;
  
  // 儲存鍵
  static const String playerNameKey = 'player_name';
  static const String playerIdKey = 'player_id';
  static const String preferredCharacterKey = 'preferred_character';
  static const String soundEnabledKey = 'sound_enabled';
  static const String notificationsEnabledKey = 'notifications_enabled';
  
  // 系統訊息類型
  static const Map<String, String> systemMessageTypes = {
    'info': 'info',
    'warning': 'warning', 
    'success': 'success',
    'error': 'error',
  };

  // Debug 模式（開發用）
  static const bool isDebugMode = bool.fromEnvironment('DEBUG_MODE', defaultValue: false);
  
  // 日誌等級
  static const bool enableVerboseLogging = bool.fromEnvironment('VERBOSE_LOGGING', defaultValue: false);

  // 實用方法：取得投票選項顯示文字
  static const Map<String, String> voteChoiceDisplayNames = {
    'a': 'A. 勞工權益優先',
    'b': 'B. 工業發展優先',
    'c': 'C. 漸進式改革',
    'abstain': 'D. 棄權',
  };

  // 實用方法：取得卡牌類型圖標
  static const Map<String, String> cardTypeIcons = {
    'attack': '⚔️',
    'defense': '🛡️',
    'control': '🔒',
    'buff': '⬆️',
    'intel': '🔍',
    'healing': '💚',
    'social': '🤝',
    'special': '⭐',
  };
}