// 1812 國會風雲 - 遊戲狀態模型

import 'player.dart';
import 'bill.dart';
import 'action.dart';

/// 遊戲階段
enum GamePhase {
  waiting,     // 等待玩家加入
  preparing,   // 準備階段（分配角色、展示任務）
  conspiracy,  // 密謀階段（私訊、結盟）
  debate,      // 辯論階段（質詢、反駁、技能）
  event,       // 突發事件階段
  voting,      // 投票階段
  result,      // 結算階段
}

/// 遊戲模式
enum GameMode {
  quick,     // 快速局 - 15 分鐘
  standard,  // 標準局 - 30 分鐘
  full,      // 完整局 - 60 分鐘
}

/// 遊戲狀態模型
class GameState {
  /// 房間 ID
  final String roomId;

  /// 房間代碼（6 位英數字）
  final String roomCode;

  /// 遊戲模式
  final GameMode mode;

  /// 當前階段
  final GamePhase phase;

  /// 當前回合數
  final int currentRound;

  /// 總回合數
  final int totalRounds;

  /// 當前階段剩餘時間（秒）
  final int timeRemaining;

  /// 玩家列表
  final List<Player> players;

  /// 當前議案
  final Bill? currentBill;

  /// 動作日誌
  final List<GameAction> actionLog;

  /// 當前發言者 ID（辯論階段）
  final String? currentSpeakerId;

  /// 發言順序（玩家 ID 列表）
  final List<String> speakingOrder;

  /// 遊戲開始時間
  final DateTime? startTime;

  /// 遊戲結束時間
  final DateTime? endTime;

  /// 獲勝陣營（遊戲結束後）
  final String? winningFaction;

  const GameState({
    required this.roomId,
    required this.roomCode,
    this.mode = GameMode.quick,
    this.phase = GamePhase.waiting,
    this.currentRound = 0,
    this.totalRounds = 3,
    this.timeRemaining = 0,
    this.players = const [],
    this.currentBill,
    this.actionLog = const [],
    this.currentSpeakerId,
    this.speakingOrder = const [],
    this.startTime,
    this.endTime,
    this.winningFaction,
  });

  /// 是否遊戲已開始
  bool get isGameStarted => phase != GamePhase.waiting;

  /// 是否遊戲已結束
  bool get isGameEnded => phase == GamePhase.result && endTime != null;

  /// 存活玩家數
  int get alivePlayerCount => players.where((p) => p.isAlive).length;

  /// 玩家數量
  int get playerCount => players.length;

  /// 是否可以開始遊戲
  bool get canStartGame {
    if (players.length < 4) return false;
    return players.every((p) => p.isReady || p.isHost);
  }

  /// 取得玩家
  Player? getPlayerById(String playerId) {
    try {
      return players.firstWhere((p) => p.id == playerId);
    } catch (e) {
      return null;
    }
  }

  /// 取得房主
  Player? get host {
    try {
      return players.firstWhere((p) => p.isHost);
    } catch (e) {
      return null;
    }
  }

  /// 當前發言者
  Player? get currentSpeaker {
    if (currentSpeakerId == null) return null;
    return getPlayerById(currentSpeakerId!);
  }

  /// 下一個發言者
  String? get nextSpeakerId {
    if (speakingOrder.isEmpty || currentSpeakerId == null) return null;
    final currentIndex = speakingOrder.indexOf(currentSpeakerId!);
    if (currentIndex < 0 || currentIndex >= speakingOrder.length - 1) {
      return null;
    }
    return speakingOrder[currentIndex + 1];
  }

  /// 階段名稱
  String get phaseName {
    switch (phase) {
      case GamePhase.waiting:
        return '等待中';
      case GamePhase.preparing:
        return '準備階段';
      case GamePhase.conspiracy:
        return '密謀階段';
      case GamePhase.debate:
        return '辯論階段';
      case GamePhase.event:
        return '突發事件';
      case GamePhase.voting:
        return '投票階段';
      case GamePhase.result:
        return '結算階段';
    }
  }

  /// 階段持續時間（秒）
  int getPhaseDuration(GamePhase phase) {
    switch (phase) {
      case GamePhase.waiting:
        return 0;
      case GamePhase.preparing:
        return 60;
      case GamePhase.conspiracy:
        return mode == GameMode.quick ? 120 : 180;
      case GamePhase.debate:
        return mode == GameMode.quick ? 240 : 300;
      case GamePhase.event:
        return 60;
      case GamePhase.voting:
        return 60;
      case GamePhase.result:
        return 0;
    }
  }

  /// 格式化剩餘時間
  String get formattedTimeRemaining {
    final minutes = timeRemaining ~/ 60;
    final seconds = timeRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  GameState copyWith({
    String? roomId,
    String? roomCode,
    GameMode? mode,
    GamePhase? phase,
    int? currentRound,
    int? totalRounds,
    int? timeRemaining,
    List<Player>? players,
    Bill? currentBill,
    List<GameAction>? actionLog,
    String? currentSpeakerId,
    List<String>? speakingOrder,
    DateTime? startTime,
    DateTime? endTime,
    String? winningFaction,
  }) {
    return GameState(
      roomId: roomId ?? this.roomId,
      roomCode: roomCode ?? this.roomCode,
      mode: mode ?? this.mode,
      phase: phase ?? this.phase,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      players: players ?? this.players,
      currentBill: currentBill ?? this.currentBill,
      actionLog: actionLog ?? this.actionLog,
      currentSpeakerId: currentSpeakerId ?? this.currentSpeakerId,
      speakingOrder: speakingOrder ?? this.speakingOrder,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      winningFaction: winningFaction ?? this.winningFaction,
    );
  }

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      roomId: json['roomId'] as String,
      roomCode: json['roomCode'] as String,
      mode: GameMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => GameMode.quick,
      ),
      phase: GamePhase.values.firstWhere(
        (e) => e.name == json['phase'],
        orElse: () => GamePhase.waiting,
      ),
      currentRound: json['currentRound'] as int? ?? 0,
      totalRounds: json['totalRounds'] as int? ?? 3,
      timeRemaining: json['timeRemaining'] as int? ?? 0,
      players: (json['players'] as List<dynamic>?)
              ?.map((e) => Player.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      currentBill: json['currentBill'] != null
          ? Bill.fromJson(json['currentBill'] as Map<String, dynamic>)
          : null,
      actionLog: (json['actionLog'] as List<dynamic>?)
              ?.map((e) => GameAction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      currentSpeakerId: json['currentSpeakerId'] as String?,
      speakingOrder: (json['speakingOrder'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      winningFaction: json['winningFaction'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'roomCode': roomCode,
      'mode': mode.name,
      'phase': phase.name,
      'currentRound': currentRound,
      'totalRounds': totalRounds,
      'timeRemaining': timeRemaining,
      'players': players.map((e) => e.toJson()).toList(),
      'currentBill': currentBill?.toJson(),
      'actionLog': actionLog.map((e) => e.toJson()).toList(),
      'currentSpeakerId': currentSpeakerId,
      'speakingOrder': speakingOrder,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'winningFaction': winningFaction,
    };
  }
}

/// 遊戲結果
class GameResult {
  /// 獲勝選項
  final String winningOption;

  /// 獲勝陣營
  final String? winningFaction;

  /// 玩家得分列表
  final Map<String, int> playerScores;

  /// MVP 玩家 ID
  final String? mvpPlayerId;

  /// 成就列表
  final List<Achievement> achievements;

  const GameResult({
    required this.winningOption,
    this.winningFaction,
    required this.playerScores,
    this.mvpPlayerId,
    this.achievements = const [],
  });

  factory GameResult.fromJson(Map<String, dynamic> json) {
    return GameResult(
      winningOption: json['winningOption'] as String,
      winningFaction: json['winningFaction'] as String?,
      playerScores: Map<String, int>.from(json['playerScores'] as Map),
      mvpPlayerId: json['mvpPlayerId'] as String?,
      achievements: (json['achievements'] as List<dynamic>?)
              ?.map((e) => Achievement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'winningOption': winningOption,
      'winningFaction': winningFaction,
      'playerScores': playerScores,
      'mvpPlayerId': mvpPlayerId,
      'achievements': achievements.map((e) => e.toJson()).toList(),
    };
  }
}

/// 成就
class Achievement {
  /// 成就 ID
  final String id;

  /// 成就名稱
  final String name;

  /// 成就描述
  final String description;

  /// 獲得玩家 ID
  final String playerId;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.playerId,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      playerId: json['playerId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'playerId': playerId,
    };
  }
}
