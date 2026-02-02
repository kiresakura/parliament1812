// 1812 國會風雲 - 用戶設定模型
//
// 管理用戶偏好設定

/// 語言選項
enum GameLanguage {
  zhTW,   // 繁體中文
  zhCN,   // 簡體中文
  en,     // English
  ja,     // 日本語
}

extension GameLanguageConfig on GameLanguage {
  String get displayName {
    switch (this) {
      case GameLanguage.zhTW:
        return '繁體中文';
      case GameLanguage.zhCN:
        return '简体中文';
      case GameLanguage.en:
        return 'English';
      case GameLanguage.ja:
        return '日本語';
    }
  }

  String get languageCode {
    switch (this) {
      case GameLanguage.zhTW:
        return 'zh-TW';
      case GameLanguage.zhCN:
        return 'zh-CN';
      case GameLanguage.en:
        return 'en';
      case GameLanguage.ja:
        return 'ja';
    }
  }
}

/// 音效設定
class AudioSettings {
  /// 主音量 (0.0 - 1.0)
  final double masterVolume;

  /// 背景音樂音量
  final double musicVolume;

  /// 音效音量
  final double sfxVolume;

  /// 語音音量
  final double voiceVolume;

  /// 是否開啟震動
  final bool vibrationEnabled;

  const AudioSettings({
    this.masterVolume = 1.0,
    this.musicVolume = 0.8,
    this.sfxVolume = 1.0,
    this.voiceVolume = 1.0,
    this.vibrationEnabled = true,
  });

  AudioSettings copyWith({
    double? masterVolume,
    double? musicVolume,
    double? sfxVolume,
    double? voiceVolume,
    bool? vibrationEnabled,
  }) {
    return AudioSettings(
      masterVolume: masterVolume ?? this.masterVolume,
      musicVolume: musicVolume ?? this.musicVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      voiceVolume: voiceVolume ?? this.voiceVolume,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }

  factory AudioSettings.fromJson(Map<String, dynamic> json) {
    return AudioSettings(
      masterVolume: (json['master_volume'] as num?)?.toDouble() ?? 1.0,
      musicVolume: (json['music_volume'] as num?)?.toDouble() ?? 0.8,
      sfxVolume: (json['sfx_volume'] as num?)?.toDouble() ?? 1.0,
      voiceVolume: (json['voice_volume'] as num?)?.toDouble() ?? 1.0,
      vibrationEnabled: json['vibration_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'master_volume': masterVolume,
      'music_volume': musicVolume,
      'sfx_volume': sfxVolume,
      'voice_volume': voiceVolume,
      'vibration_enabled': vibrationEnabled,
    };
  }
}

/// 畫質設定
enum GraphicsQuality {
  low,
  medium,
  high,
  ultra,
}

extension GraphicsQualityConfig on GraphicsQuality {
  String get displayName {
    switch (this) {
      case GraphicsQuality.low:
        return '低';
      case GraphicsQuality.medium:
        return '中';
      case GraphicsQuality.high:
        return '高';
      case GraphicsQuality.ultra:
        return '極致';
    }
  }
}

/// 畫面設定
class GraphicsSettings {
  /// 畫質
  final GraphicsQuality quality;

  /// FPS 上限
  final int targetFps;

  /// 是否開啟特效
  final bool effectsEnabled;

  /// 是否開啟動畫
  final bool animationsEnabled;

  /// 省電模式
  final bool powerSavingMode;

  const GraphicsSettings({
    this.quality = GraphicsQuality.high,
    this.targetFps = 60,
    this.effectsEnabled = true,
    this.animationsEnabled = true,
    this.powerSavingMode = false,
  });

  GraphicsSettings copyWith({
    GraphicsQuality? quality,
    int? targetFps,
    bool? effectsEnabled,
    bool? animationsEnabled,
    bool? powerSavingMode,
  }) {
    return GraphicsSettings(
      quality: quality ?? this.quality,
      targetFps: targetFps ?? this.targetFps,
      effectsEnabled: effectsEnabled ?? this.effectsEnabled,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      powerSavingMode: powerSavingMode ?? this.powerSavingMode,
    );
  }

  factory GraphicsSettings.fromJson(Map<String, dynamic> json) {
    return GraphicsSettings(
      quality: GraphicsQuality.values.firstWhere(
        (e) => e.name == json['quality'],
        orElse: () => GraphicsQuality.high,
      ),
      targetFps: json['target_fps'] as int? ?? 60,
      effectsEnabled: json['effects_enabled'] as bool? ?? true,
      animationsEnabled: json['animations_enabled'] as bool? ?? true,
      powerSavingMode: json['power_saving_mode'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quality': quality.name,
      'target_fps': targetFps,
      'effects_enabled': effectsEnabled,
      'animations_enabled': animationsEnabled,
      'power_saving_mode': powerSavingMode,
    };
  }
}

/// 通知設定
class NotificationSettings {
  /// 遊戲內通知
  final bool inGameNotifications;

  /// 推播通知
  final bool pushNotifications;

  /// 好友上線通知
  final bool friendOnlineNotifications;

  /// 每日獎勵提醒
  final bool dailyRewardReminder;

  /// Battle Pass 進度提醒
  final bool battlePassReminder;

  /// 活動通知
  final bool eventNotifications;

  /// 免打擾時段開始（小時，24制）
  final int doNotDisturbStart;

  /// 免打擾時段結束
  final int doNotDisturbEnd;

  /// 是否開啟免打擾
  final bool doNotDisturbEnabled;

  const NotificationSettings({
    this.inGameNotifications = true,
    this.pushNotifications = true,
    this.friendOnlineNotifications = true,
    this.dailyRewardReminder = true,
    this.battlePassReminder = true,
    this.eventNotifications = true,
    this.doNotDisturbStart = 23,
    this.doNotDisturbEnd = 8,
    this.doNotDisturbEnabled = false,
  });

  NotificationSettings copyWith({
    bool? inGameNotifications,
    bool? pushNotifications,
    bool? friendOnlineNotifications,
    bool? dailyRewardReminder,
    bool? battlePassReminder,
    bool? eventNotifications,
    int? doNotDisturbStart,
    int? doNotDisturbEnd,
    bool? doNotDisturbEnabled,
  }) {
    return NotificationSettings(
      inGameNotifications: inGameNotifications ?? this.inGameNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      friendOnlineNotifications:
          friendOnlineNotifications ?? this.friendOnlineNotifications,
      dailyRewardReminder: dailyRewardReminder ?? this.dailyRewardReminder,
      battlePassReminder: battlePassReminder ?? this.battlePassReminder,
      eventNotifications: eventNotifications ?? this.eventNotifications,
      doNotDisturbStart: doNotDisturbStart ?? this.doNotDisturbStart,
      doNotDisturbEnd: doNotDisturbEnd ?? this.doNotDisturbEnd,
      doNotDisturbEnabled: doNotDisturbEnabled ?? this.doNotDisturbEnabled,
    );
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      inGameNotifications: json['in_game_notifications'] as bool? ?? true,
      pushNotifications: json['push_notifications'] as bool? ?? true,
      friendOnlineNotifications:
          json['friend_online_notifications'] as bool? ?? true,
      dailyRewardReminder: json['daily_reward_reminder'] as bool? ?? true,
      battlePassReminder: json['battle_pass_reminder'] as bool? ?? true,
      eventNotifications: json['event_notifications'] as bool? ?? true,
      doNotDisturbStart: json['do_not_disturb_start'] as int? ?? 23,
      doNotDisturbEnd: json['do_not_disturb_end'] as int? ?? 8,
      doNotDisturbEnabled: json['do_not_disturb_enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'in_game_notifications': inGameNotifications,
      'push_notifications': pushNotifications,
      'friend_online_notifications': friendOnlineNotifications,
      'daily_reward_reminder': dailyRewardReminder,
      'battle_pass_reminder': battlePassReminder,
      'event_notifications': eventNotifications,
      'do_not_disturb_start': doNotDisturbStart,
      'do_not_disturb_end': doNotDisturbEnd,
      'do_not_disturb_enabled': doNotDisturbEnabled,
    };
  }
}

/// 遊戲設定
class GameplaySettings {
  /// 自動確認出牌
  final bool autoConfirmPlay;

  /// 顯示對手思考時間
  final bool showOpponentTimer;

  /// 顯示傷害數字
  final bool showDamageNumbers;

  /// 快速模式（跳過動畫）
  final bool fastMode;

  /// 自動表情回應
  final bool autoEmoteReply;

  /// 屏蔽他人表情
  final bool muteEmotes;

  const GameplaySettings({
    this.autoConfirmPlay = false,
    this.showOpponentTimer = true,
    this.showDamageNumbers = true,
    this.fastMode = false,
    this.autoEmoteReply = false,
    this.muteEmotes = false,
  });

  GameplaySettings copyWith({
    bool? autoConfirmPlay,
    bool? showOpponentTimer,
    bool? showDamageNumbers,
    bool? fastMode,
    bool? autoEmoteReply,
    bool? muteEmotes,
  }) {
    return GameplaySettings(
      autoConfirmPlay: autoConfirmPlay ?? this.autoConfirmPlay,
      showOpponentTimer: showOpponentTimer ?? this.showOpponentTimer,
      showDamageNumbers: showDamageNumbers ?? this.showDamageNumbers,
      fastMode: fastMode ?? this.fastMode,
      autoEmoteReply: autoEmoteReply ?? this.autoEmoteReply,
      muteEmotes: muteEmotes ?? this.muteEmotes,
    );
  }

  factory GameplaySettings.fromJson(Map<String, dynamic> json) {
    return GameplaySettings(
      autoConfirmPlay: json['auto_confirm_play'] as bool? ?? false,
      showOpponentTimer: json['show_opponent_timer'] as bool? ?? true,
      showDamageNumbers: json['show_damage_numbers'] as bool? ?? true,
      fastMode: json['fast_mode'] as bool? ?? false,
      autoEmoteReply: json['auto_emote_reply'] as bool? ?? false,
      muteEmotes: json['mute_emotes'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'auto_confirm_play': autoConfirmPlay,
      'show_opponent_timer': showOpponentTimer,
      'show_damage_numbers': showDamageNumbers,
      'fast_mode': fastMode,
      'auto_emote_reply': autoEmoteReply,
      'mute_emotes': muteEmotes,
    };
  }
}

/// 隱私設定
class PrivacySettings {
  /// 允許陌生人查看戰績
  final bool publicProfile;

  /// 允許好友邀請
  final bool allowFriendRequests;

  /// 允許被搜尋
  final bool allowSearchByName;

  /// 顯示在線狀態
  final bool showOnlineStatus;

  /// 顯示最近遊戲
  final bool showRecentGames;

  const PrivacySettings({
    this.publicProfile = true,
    this.allowFriendRequests = true,
    this.allowSearchByName = true,
    this.showOnlineStatus = true,
    this.showRecentGames = true,
  });

  PrivacySettings copyWith({
    bool? publicProfile,
    bool? allowFriendRequests,
    bool? allowSearchByName,
    bool? showOnlineStatus,
    bool? showRecentGames,
  }) {
    return PrivacySettings(
      publicProfile: publicProfile ?? this.publicProfile,
      allowFriendRequests: allowFriendRequests ?? this.allowFriendRequests,
      allowSearchByName: allowSearchByName ?? this.allowSearchByName,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      showRecentGames: showRecentGames ?? this.showRecentGames,
    );
  }

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      publicProfile: json['public_profile'] as bool? ?? true,
      allowFriendRequests: json['allow_friend_requests'] as bool? ?? true,
      allowSearchByName: json['allow_search_by_name'] as bool? ?? true,
      showOnlineStatus: json['show_online_status'] as bool? ?? true,
      showRecentGames: json['show_recent_games'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'public_profile': publicProfile,
      'allow_friend_requests': allowFriendRequests,
      'allow_search_by_name': allowSearchByName,
      'show_online_status': showOnlineStatus,
      'show_recent_games': showRecentGames,
    };
  }
}

/// 用戶設定
class UserSettings {
  /// 用戶 ID
  final String userId;

  /// 語言
  final GameLanguage language;

  /// 音效設定
  final AudioSettings audio;

  /// 畫面設定
  final GraphicsSettings graphics;

  /// 通知設定
  final NotificationSettings notifications;

  /// 遊戲設定
  final GameplaySettings gameplay;

  /// 隱私設定
  final PrivacySettings privacy;

  /// 最後更新時間
  final DateTime updatedAt;

  const UserSettings({
    required this.userId,
    this.language = GameLanguage.zhTW,
    this.audio = const AudioSettings(),
    this.graphics = const GraphicsSettings(),
    this.notifications = const NotificationSettings(),
    this.gameplay = const GameplaySettings(),
    this.privacy = const PrivacySettings(),
    required this.updatedAt,
  });

  UserSettings copyWith({
    GameLanguage? language,
    AudioSettings? audio,
    GraphicsSettings? graphics,
    NotificationSettings? notifications,
    GameplaySettings? gameplay,
    PrivacySettings? privacy,
    DateTime? updatedAt,
  }) {
    return UserSettings(
      userId: userId,
      language: language ?? this.language,
      audio: audio ?? this.audio,
      graphics: graphics ?? this.graphics,
      notifications: notifications ?? this.notifications,
      gameplay: gameplay ?? this.gameplay,
      privacy: privacy ?? this.privacy,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      userId: json['user_id'] as String,
      language: GameLanguage.values.firstWhere(
        (e) => e.name == json['language'],
        orElse: () => GameLanguage.zhTW,
      ),
      audio: json['audio'] != null
          ? AudioSettings.fromJson(json['audio'] as Map<String, dynamic>)
          : const AudioSettings(),
      graphics: json['graphics'] != null
          ? GraphicsSettings.fromJson(json['graphics'] as Map<String, dynamic>)
          : const GraphicsSettings(),
      notifications: json['notifications'] != null
          ? NotificationSettings.fromJson(
              json['notifications'] as Map<String, dynamic>)
          : const NotificationSettings(),
      gameplay: json['gameplay'] != null
          ? GameplaySettings.fromJson(json['gameplay'] as Map<String, dynamic>)
          : const GameplaySettings(),
      privacy: json['privacy'] != null
          ? PrivacySettings.fromJson(json['privacy'] as Map<String, dynamic>)
          : const PrivacySettings(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'language': language.name,
      'audio': audio.toJson(),
      'graphics': graphics.toJson(),
      'notifications': notifications.toJson(),
      'gameplay': gameplay.toJson(),
      'privacy': privacy.toJson(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserSettings.initial(String userId) {
    return UserSettings(
      userId: userId,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'UserSettings(userId: $userId, language: ${language.displayName})';
  }
}
