// 1812 國會風雲 - AI 玩家模型

import 'player.dart';

/// AI 難度等級
enum AIDifficulty {
  beginner,      // 初學者 - 等級 1
  intermediate,  // 中級 - 等級 2
  advanced,      // 進階 - 等級 3
  expert,        // 專家 - 等級 4
  master,        // 大師 - 等級 5
}

/// AIDifficulty 擴展方法
extension AIDifficultyExtension on AIDifficulty {
  /// 難度等級數值 (1-5)
  int get level {
    switch (this) {
      case AIDifficulty.beginner:
        return 1;
      case AIDifficulty.intermediate:
        return 2;
      case AIDifficulty.advanced:
        return 3;
      case AIDifficulty.expert:
        return 4;
      case AIDifficulty.master:
        return 5;
    }
  }

  /// 難度名稱
  String get displayName {
    switch (this) {
      case AIDifficulty.beginner:
        return '初學者';
      case AIDifficulty.intermediate:
        return '中級';
      case AIDifficulty.advanced:
        return '進階';
      case AIDifficulty.expert:
        return '專家';
      case AIDifficulty.master:
        return '大師';
    }
  }

  /// 難度描述
  String get description {
    switch (this) {
      case AIDifficulty.beginner:
        return '適合新手，AI 會犯一些明顯的錯誤';
      case AIDifficulty.intermediate:
        return '基本策略，偶爾會做出非最優選擇';
      case AIDifficulty.advanced:
        return '較強的策略思維，會嘗試結盟和背叛';
      case AIDifficulty.expert:
        return '精通遊戲機制，善於分析局勢';
      case AIDifficulty.master:
        return '頂尖水準，具有深度策略和心理戰術';
    }
  }

  /// 思考深度（影響 AI 評估的細緻程度）
  int get thinkingDepth => level;

  /// 錯誤率（百分比，低難度 AI 會有隨機錯誤）
  double get errorRate {
    switch (this) {
      case AIDifficulty.beginner:
        return 0.30;  // 30% 錯誤率
      case AIDifficulty.intermediate:
        return 0.15;  // 15% 錯誤率
      case AIDifficulty.advanced:
        return 0.08;  // 8% 錯誤率
      case AIDifficulty.expert:
        return 0.03;  // 3% 錯誤率
      case AIDifficulty.master:
        return 0.01;  // 1% 錯誤率
    }
  }
}

/// AI 個性類型
enum AIPersonality {
  aggressive,   // 激進型 - 偏好攻擊、質詢
  defensive,    // 防守型 - 偏好反駁、保護聲望
  diplomatic,   // 外交型 - 偏好結盟、交易
  cunning,      // 狡詐型 - 善於背叛、使用情報
}

/// AIPersonality 擴展方法
extension AIPersonalityExtension on AIPersonality {
  /// 個性名稱
  String get displayName {
    switch (this) {
      case AIPersonality.aggressive:
        return '激進派';
      case AIPersonality.defensive:
        return '保守派';
      case AIPersonality.diplomatic:
        return '外交家';
      case AIPersonality.cunning:
        return '陰謀家';
    }
  }

  /// 個性描述
  String get description {
    switch (this) {
      case AIPersonality.aggressive:
        return '積極主動，喜歡發起質詢並壓制對手';
      case AIPersonality.defensive:
        return '謹慎保守，注重保護自己的聲望';
      case AIPersonality.diplomatic:
        return '善於社交，傾向於建立盟友關係';
      case AIPersonality.cunning:
        return '深謀遠慮，善於利用情報和時機';
    }
  }

  /// 個性圖標
  String get icon {
    switch (this) {
      case AIPersonality.aggressive:
        return '⚔️';
      case AIPersonality.defensive:
        return '🛡️';
      case AIPersonality.diplomatic:
        return '🤝';
      case AIPersonality.cunning:
        return '🎭';
    }
  }

  /// 攻擊傾向權重 (0.0 - 1.0)
  double get attackWeight {
    switch (this) {
      case AIPersonality.aggressive:
        return 0.8;
      case AIPersonality.defensive:
        return 0.3;
      case AIPersonality.diplomatic:
        return 0.4;
      case AIPersonality.cunning:
        return 0.6;
    }
  }

  /// 防禦傾向權重 (0.0 - 1.0)
  double get defenseWeight {
    switch (this) {
      case AIPersonality.aggressive:
        return 0.3;
      case AIPersonality.defensive:
        return 0.8;
      case AIPersonality.diplomatic:
        return 0.5;
      case AIPersonality.cunning:
        return 0.5;
    }
  }

  /// 結盟傾向權重 (0.0 - 1.0)
  double get allyWeight {
    switch (this) {
      case AIPersonality.aggressive:
        return 0.2;
      case AIPersonality.defensive:
        return 0.5;
      case AIPersonality.diplomatic:
        return 0.9;
      case AIPersonality.cunning:
        return 0.4;
    }
  }

  /// 背叛傾向權重 (0.0 - 1.0)
  double get betrayWeight {
    switch (this) {
      case AIPersonality.aggressive:
        return 0.4;
      case AIPersonality.defensive:
        return 0.1;
      case AIPersonality.diplomatic:
        return 0.2;
      case AIPersonality.cunning:
        return 0.7;
    }
  }
}

/// AI 玩家模型
/// 繼承自基礎 Player，增加 AI 特有屬性
class AIPlayer {
  /// 基礎玩家資料
  final Player player;

  /// AI 難度
  final AIDifficulty difficulty;

  /// AI 個性
  final AIPersonality personality;

  /// AI 名稱（顯示用，不同於內部 ID）
  final String displayName;

  /// AI 頭像索引
  final int avatarIndex;

  /// 上次動作時間
  final DateTime? lastActionTime;

  /// 記憶：對其他玩家的關係評價 (-100 到 +100)
  final Map<String, int> relationshipScores;

  /// 記憶：已知的情報
  final List<String> knownIntel;

  /// 當前目標（玩家 ID）
  final String? currentTargetId;

  /// 是否處於危險狀態（需要優先保護自己）
  final bool isInDanger;

  const AIPlayer({
    required this.player,
    required this.difficulty,
    required this.personality,
    required this.displayName,
    this.avatarIndex = 0,
    this.lastActionTime,
    this.relationshipScores = const {},
    this.knownIntel = const [],
    this.currentTargetId,
    this.isInDanger = false,
  });

  /// 從難度創建隨機 AI
  factory AIPlayer.createRandom({
    required String id,
    required String name,
    required AIDifficulty difficulty,
    int avatarIndex = 0,
    String? roleId,
    int reputation = 50,
  }) {
    // 根據難度分配個性（高難度更容易獲得狡詐個性）
    const personalities = AIPersonality.values;
    final personalityIndex = (id.hashCode + difficulty.level) % personalities.length;
    final personality = personalities[personalityIndex];

    return AIPlayer(
      player: Player(
        id: id,
        name: name,
        roleId: roleId,
        reputation: reputation,
        isReady: true,  // AI 總是準備好的
      ),
      difficulty: difficulty,
      personality: personality,
      displayName: name,
      avatarIndex: avatarIndex,
    );
  }

  /// 便捷訪問器：玩家 ID
  String get id => player.id;

  /// 便捷訪問器：玩家名稱
  String get name => player.name;

  /// 便捷訪問器：角色 ID
  String? get roleId => player.roleId;

  /// 便捷訪問器：聲望
  int get reputation => player.reputation;

  /// 便捷訪問器：是否存活
  bool get isAlive => player.isAlive;

  /// 便捷訪問器：金幣
  int get gold => player.gold;

  /// 便捷訪問器：情報
  int get intel => player.intel;

  /// 便捷訪問器：人情
  int get favor => player.favor;

  /// 便捷訪問器：盟友列表
  List<String> get allies => player.allies;

  /// 檢查是否應該進入防守模式
  bool shouldDefend() {
    if (reputation <= 30) return true;
    if (isInDanger) return true;
    return false;
  }

  /// 計算對某玩家的關係分數
  int getRelationshipScore(String playerId) {
    return relationshipScores[playerId] ?? 0;
  }

  /// 檢查是否為盟友
  bool isAllyWith(String playerId) {
    return allies.contains(playerId);
  }

  /// 檢查是否為敵人（關係分數 < -30）
  bool isEnemyWith(String playerId) {
    return getRelationshipScore(playerId) < -30;
  }

  AIPlayer copyWith({
    Player? player,
    AIDifficulty? difficulty,
    AIPersonality? personality,
    String? displayName,
    int? avatarIndex,
    DateTime? lastActionTime,
    Map<String, int>? relationshipScores,
    List<String>? knownIntel,
    String? currentTargetId,
    bool? isInDanger,
  }) {
    return AIPlayer(
      player: player ?? this.player,
      difficulty: difficulty ?? this.difficulty,
      personality: personality ?? this.personality,
      displayName: displayName ?? this.displayName,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      lastActionTime: lastActionTime ?? this.lastActionTime,
      relationshipScores: relationshipScores ?? this.relationshipScores,
      knownIntel: knownIntel ?? this.knownIntel,
      currentTargetId: currentTargetId ?? this.currentTargetId,
      isInDanger: isInDanger ?? this.isInDanger,
    );
  }

  /// 更新基礎玩家資料
  AIPlayer updatePlayer(Player Function(Player) updater) {
    return copyWith(player: updater(player));
  }

  /// 更新關係分數
  AIPlayer updateRelationship(String playerId, int delta) {
    final newScores = Map<String, int>.from(relationshipScores);
    final currentScore = newScores[playerId] ?? 0;
    final newScore = (currentScore + delta).clamp(-100, 100);
    newScores[playerId] = newScore;
    return copyWith(relationshipScores: newScores);
  }

  /// 添加已知情報
  AIPlayer addKnownIntel(String intel) {
    if (knownIntel.contains(intel)) return this;
    return copyWith(knownIntel: [...knownIntel, intel]);
  }

  factory AIPlayer.fromJson(Map<String, dynamic> json) {
    return AIPlayer(
      player: Player.fromJson(json['player'] as Map<String, dynamic>),
      difficulty: AIDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => AIDifficulty.intermediate,
      ),
      personality: AIPersonality.values.firstWhere(
        (e) => e.name == json['personality'],
        orElse: () => AIPersonality.diplomatic,
      ),
      displayName: json['displayName'] as String,
      avatarIndex: json['avatarIndex'] as int? ?? 0,
      lastActionTime: json['lastActionTime'] != null
          ? DateTime.parse(json['lastActionTime'] as String)
          : null,
      relationshipScores: (json['relationshipScores'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
      knownIntel: (json['knownIntel'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      currentTargetId: json['currentTargetId'] as String?,
      isInDanger: json['isInDanger'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'player': player.toJson(),
      'difficulty': difficulty.name,
      'personality': personality.name,
      'displayName': displayName,
      'avatarIndex': avatarIndex,
      'lastActionTime': lastActionTime?.toIso8601String(),
      'relationshipScores': relationshipScores,
      'knownIntel': knownIntel,
      'currentTargetId': currentTargetId,
      'isInDanger': isInDanger,
    };
  }

  @override
  String toString() {
    return 'AIPlayer(id: $id, name: $displayName, difficulty: ${difficulty.displayName}, personality: ${personality.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AIPlayer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
