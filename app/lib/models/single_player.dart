// 單人模式資料模型

/// AI 行動記錄（用於逐步展示 AI 回合）
class AiActionRecord {
  final String actorId;
  final String actorName;
  final String actionType; // 'play_card', 'challenge', 'alliance', 'heal', 'buff', 'draw', etc.
  final String description;
  final String? targetId;
  final String? targetName;
  final int? valueChange; // 聲望變化值（正/負）

  const AiActionRecord({
    required this.actorId,
    required this.actorName,
    required this.actionType,
    required this.description,
    this.targetId,
    this.targetName,
    this.valueChange,
  });
}

/// AI 難度
enum AiDifficulty {
  easy,
  normal,
  hard,
  expert;

  String get displayName {
    switch (this) {
      case AiDifficulty.easy:
        return '簡單';
      case AiDifficulty.normal:
        return '普通';
      case AiDifficulty.hard:
        return '困難';
      case AiDifficulty.expert:
        return '專家';
    }
  }

  String get displayNameEn {
    switch (this) {
      case AiDifficulty.easy:
        return 'Easy';
      case AiDifficulty.normal:
        return 'Normal';
      case AiDifficulty.hard:
        return 'Hard';
      case AiDifficulty.expert:
        return 'Expert';
    }
  }

  String toJson() => name;

  static AiDifficulty fromJson(String value) {
    return AiDifficulty.values.firstWhere(
      (d) => d.name == value,
      orElse: () => AiDifficulty.easy,
    );
  }
}

/// 單人遊戲狀態
class SinglePlayerState {
  final String sessionId;
  final String phase;
  final int currentRound;
  final String currentBill;
  final List<SinglePlayerInfo> players;
  final List<Map<String, dynamic>> hand;
  final int phaseTimeRemaining;
  final List<String> aiActionsLog;
  final bool isGameOver;
  final SinglePlayerResult? result;
  /// 回合制：剩餘行動點數
  final int actionPointsRemaining;
  /// 回合制：當前行動玩家 ID
  final String? currentTurnPlayerId;
  /// AI 回合待展示的行動列表
  final List<AiActionRecord> pendingAiActions;
  /// 當前正在展示行動的 AI ID（用於高亮）
  final String? aiTurnActorId;

  SinglePlayerState({
    required this.sessionId,
    required this.phase,
    required this.currentRound,
    required this.currentBill,
    required this.players,
    required this.hand,
    required this.phaseTimeRemaining,
    required this.aiActionsLog,
    required this.isGameOver,
    this.result,
    this.actionPointsRemaining = 3,
    this.currentTurnPlayerId,
    this.pendingAiActions = const [],
    this.aiTurnActorId,
  });

  /// 複製並修改部分欄位
  SinglePlayerState copyWith({
    String? phase,
    List<String>? aiActionsLog,
    List<AiActionRecord>? pendingAiActions,
    String? aiTurnActorId,
    bool clearAiTurnActorId = false,
  }) {
    return SinglePlayerState(
      sessionId: sessionId,
      phase: phase ?? this.phase,
      currentRound: currentRound,
      currentBill: currentBill,
      players: players,
      hand: hand,
      phaseTimeRemaining: phaseTimeRemaining,
      aiActionsLog: aiActionsLog ?? this.aiActionsLog,
      isGameOver: isGameOver,
      result: result,
      actionPointsRemaining: actionPointsRemaining,
      currentTurnPlayerId: currentTurnPlayerId,
      pendingAiActions: pendingAiActions ?? this.pendingAiActions,
      aiTurnActorId: clearAiTurnActorId ? null : (aiTurnActorId ?? this.aiTurnActorId),
    );
  }

  factory SinglePlayerState.fromJson(Map<String, dynamic> json) {
    return SinglePlayerState(
      sessionId: json['session_id'] ?? '',
      phase: json['phase'] ?? 'waiting',
      currentRound: json['current_round'] ?? 0,
      currentBill: json['current_bill'] ?? '',
      players: (json['players'] as List<dynamic>?)
              ?.map((p) => SinglePlayerInfo.fromJson(p))
              .toList() ??
          [],
      hand: (json['hand'] as List<dynamic>?)
              ?.map((c) => c as Map<String, dynamic>)
              .toList() ??
          [],
      phaseTimeRemaining: json['phase_time_remaining'] ?? 0,
      aiActionsLog: (json['ai_actions_log'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toList() ??
          [],
      isGameOver: json['is_game_over'] ?? false,
      result: json['result'] != null
          ? SinglePlayerResult.fromJson(json['result'])
          : null,
      actionPointsRemaining: json['action_points_remaining'] ?? 3,
      currentTurnPlayerId: json['current_turn_player_id'],
    );
  }
}

/// 單一玩家資訊
class SinglePlayerInfo {
  final String id;
  final String name;
  final String character;
  final int reputation;
  final int gold;
  final bool isAi;
  final bool isPoliticallyDead;
  final int handCount;

  SinglePlayerInfo({
    required this.id,
    required this.name,
    required this.character,
    required this.reputation,
    required this.gold,
    required this.isAi,
    required this.isPoliticallyDead,
    required this.handCount,
  });

  factory SinglePlayerInfo.fromJson(Map<String, dynamic> json) {
    return SinglePlayerInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      character: json['character'] ?? '',
      reputation: json['reputation'] ?? 0,
      gold: json['gold'] ?? 0,
      isAi: json['is_ai'] ?? false,
      isPoliticallyDead: json['is_politically_dead'] ?? false,
      handCount: json['hand_count'] ?? 0,
    );
  }
}

/// 單人遊戲結果
class SinglePlayerResult {
  final bool won;
  final int rank;
  final int score;
  final List<PlayerFinalScore> rankings;

  SinglePlayerResult({
    required this.won,
    required this.rank,
    required this.score,
    required this.rankings,
  });

  factory SinglePlayerResult.fromJson(Map<String, dynamic> json) {
    return SinglePlayerResult(
      won: json['won'] ?? false,
      rank: json['rank'] ?? 0,
      score: json['score'] ?? 0,
      rankings: (json['rankings'] as List<dynamic>?)
              ?.map((r) => PlayerFinalScore.fromJson(r))
              .toList() ??
          [],
    );
  }
}

class PlayerFinalScore {
  final String name;
  final int score;
  final bool isAi;

  PlayerFinalScore({
    required this.name,
    required this.score,
    required this.isAi,
  });

  factory PlayerFinalScore.fromJson(Map<String, dynamic> json) {
    return PlayerFinalScore(
      name: json['name'] ?? '',
      score: json['score'] ?? 0,
      isAi: json['is_ai'] ?? false,
    );
  }
}

/// 戰役章節資訊
class CampaignChapter {
  final int chapter;
  final String title;
  final String titleEn;
  final String description;
  final String descriptionEn;
  final bool isUnlocked;
  final bool isFree;
  final int gemCost;
  final int stagesCompleted;
  final int totalStages;
  final int stars;
  final int maxStars;

  CampaignChapter({
    required this.chapter,
    required this.title,
    required this.titleEn,
    required this.description,
    required this.descriptionEn,
    required this.isUnlocked,
    required this.isFree,
    required this.gemCost,
    required this.stagesCompleted,
    required this.totalStages,
    required this.stars,
    required this.maxStars,
  });

  factory CampaignChapter.fromJson(Map<String, dynamic> json) {
    return CampaignChapter(
      chapter: json['chapter'] ?? 0,
      title: json['title'] ?? '',
      titleEn: json['title_en'] ?? '',
      description: json['description'] ?? '',
      descriptionEn: json['description_en'] ?? '',
      isUnlocked: json['is_unlocked'] ?? false,
      isFree: json['is_free'] ?? false,
      gemCost: json['gem_cost'] ?? 0,
      stagesCompleted: json['stages_completed'] ?? 0,
      totalStages: json['total_stages'] ?? 5,
      stars: json['stars'] ?? 0,
      maxStars: json['max_stars'] ?? 15,
    );
  }
}

/// 教學步驟
class TutorialStep {
  final int step;
  final String title;
  final String titleEn;
  final String description;
  final String descriptionEn;
  final String actionType;
  final String? highlightTarget;
  final List<TutorialDialogue> dialogue;
  final bool completed;

  TutorialStep({
    required this.step,
    required this.title,
    required this.titleEn,
    required this.description,
    required this.descriptionEn,
    required this.actionType,
    this.highlightTarget,
    required this.dialogue,
    this.completed = false,
  });

  factory TutorialStep.fromJson(Map<String, dynamic> json) {
    return TutorialStep(
      step: json['step'] ?? 0,
      title: json['title'] ?? '',
      titleEn: json['title_en'] ?? '',
      description: json['description'] ?? '',
      descriptionEn: json['description_en'] ?? '',
      actionType: json['action_type'] ?? '',
      highlightTarget: json['highlight_target'],
      dialogue: (json['dialogue'] as List<dynamic>?)
              ?.map((d) => TutorialDialogue.fromJson(d))
              .toList() ??
          [],
      completed: json['completed'] ?? false,
    );
  }
}

class TutorialDialogue {
  final String speaker;
  final String text;
  final String textEn;

  TutorialDialogue({
    required this.speaker,
    required this.text,
    required this.textEn,
  });

  factory TutorialDialogue.fromJson(Map<String, dynamic> json) {
    return TutorialDialogue(
      speaker: json['speaker'] ?? '',
      text: json['text'] ?? '',
      textEn: json['text_en'] ?? '',
    );
  }
}
