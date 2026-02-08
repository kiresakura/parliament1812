import 'package:freezed_annotation/freezed_annotation.dart';
import 'room.dart';
import 'player.dart';
import 'card.dart';

part 'game_state.freezed.dart';
part 'game_state.g.dart';

@freezed
class GameState with _$GameState {
  const factory GameState({
    required Room room,
    required String? currentPlayerId,
    required List<GameCard> hand,
    required GamePhase phase,
    required int round,
    required int remainingSeconds,
    @Default([]) List<ChatMessage> chatMessages,
    @Default([]) List<GameEvent> gameEvents,
    @Default({}) Map<String, VoteChoice> votes,
    String? currentSpeakerId,
    String? currentBill,
    GameResult? result,
  }) = _GameState;

  factory GameState.fromJson(Map<String, Object?> json) => _$GameStateFromJson(json);
}

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String fromId,
    required String fromName,
    required String content,
    required bool isPrivate,
    required DateTime timestamp,
    String? toId,  // 私訊目標
    ChatMessageType? type,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, Object?> json) => _$ChatMessageFromJson(json);
}

@freezed
class GameEvent with _$GameEvent {
  const factory GameEvent({
    required String id,
    required GameEventType type,
    required String description,
    required DateTime timestamp,
    @Default({}) Map<String, dynamic> data,
    String? playerId,
    String? playerName,
  }) = _GameEvent;

  factory GameEvent.fromJson(Map<String, Object?> json) => _$GameEventFromJson(json);
}

@freezed
class GameResult with _$GameResult {
  const factory GameResult({
    required String winnerFaction,
    required Map<String, double> votes,
    required List<PlayerRanking> rankings,
    DateTime? endTime,
  }) = _GameResult;

  factory GameResult.fromJson(Map<String, Object?> json) => _$GameResultFromJson(json);
}

@freezed
class PlayerRanking with _$PlayerRanking {
  const factory PlayerRanking({
    required String playerId,
    required String playerName,
    required CharacterType character,
    required int finalReputation,
    required int rank,
    required int score,
  }) = _PlayerRanking;

  factory PlayerRanking.fromJson(Map<String, Object?> json) => _$PlayerRankingFromJson(json);
}

enum ChatMessageType {
  normal,       // 普通聊天
  system,       // 系統訊息
  action,       // 行動訊息（使用卡牌等）
  event,        // 事件訊息
  whisper,      // 私訊
}

enum GameEventType {
  @JsonValue('player_joined')
  playerJoined,
  
  @JsonValue('player_left')
  playerLeft,
  
  @JsonValue('game_started')
  gameStarted,
  
  @JsonValue('phase_changed')
  phaseChanged,
  
  @JsonValue('card_used')
  cardUsed,
  
  @JsonValue('challenge')
  challenge,
  
  @JsonValue('counter')
  counter,
  
  @JsonValue('reputation_changed')
  reputationChanged,
  
  @JsonValue('gold_changed')
  goldChanged,
  
  @JsonValue('vote_cast')
  voteCast,
  
  @JsonValue('vote_result')
  voteResult,
  
  @JsonValue('player_death')
  playerDeath,
  
  @JsonValue('random_event')
  randomEvent,
}

// 遊戲狀態擴展方法
extension GameStateExtension on GameState {
  // 獲取當前玩家
  Player? get currentPlayer {
    if (currentPlayerId == null) return null;
    return room.findPlayer(currentPlayerId!);
  }

  // 檢查是否為當前玩家的回合
  bool get isMyTurn {
    return currentPlayerId != null && 
           room.findPlayer(currentPlayerId!) != null;
  }

  // 獲取可用的手牌（考慮狀態限制）
  List<GameCard> get playableCards {
    final player = currentPlayer;
    if (player == null || !player.isAlive) return [];
    
    return hand.where((card) {
      // 檢查資源是否足夠
      if (card.influenceCost > 10) return false;
      if (card.goldCost > player.gold) return false;
      
      // 檢查階段限制
      if (!isCardPlayableInPhase(card, phase)) return false;
      
      // 檢查狀態限制（沉默、封印等）
      if (player.status.containsKey('sealed') && phase == GamePhase.debate) return false;
      
      return true;
    }).toList();
  }

  // 檢查卡牌在當前階段是否可用
  bool isCardPlayableInPhase(GameCard card, GamePhase phase) {
    switch (phase) {
      case GamePhase.waiting:
      case GamePhase.preparation:
        return false;
        
      case GamePhase.conspiracy:
        // 密謀階段：可使用結盟、調查、賄賂等
        return [CardType.social, CardType.intel, CardType.special].contains(card.type);
        
      case GamePhase.debate:
        // 辯論階段：可使用攻擊、防禦、控制、增益等
        return [
          CardType.attack, 
          CardType.defense, 
          CardType.control, 
          CardType.buff,
          CardType.healing,
        ].contains(card.type);
        
      case GamePhase.event:
        return false;
        
      case GamePhase.finalSpeech:
        // 最終發言：可使用剩餘卡牌
        return [
          CardType.attack, 
          CardType.defense, 
          CardType.healing,
        ].contains(card.type);
        
      case GamePhase.voting:
      case GamePhase.result:
        return false;
    }
  }

  // 獲取最新的聊天訊息
  List<ChatMessage> get recentChatMessages {
    return chatMessages
        .where((msg) => msg.type != ChatMessageType.whisper)
        .take(50)
        .toList();
  }

  // 獲取最新的遊戲事件
  List<GameEvent> get recentGameEvents {
    return gameEvents
        .take(20)
        .toList();
  }

  // 檢查投票是否完成
  bool get isVotingComplete {
    if (phase != GamePhase.voting) return false;
    final aliveCount = room.alivePlayers.length;
    return votes.length >= aliveCount;
  }

  // 獲取投票進度
  double get votingProgress {
    if (phase != GamePhase.voting) return 0.0;
    final aliveCount = room.alivePlayers.length;
    if (aliveCount == 0) return 1.0;
    return (votes.length / aliveCount).clamp(0.0, 1.0);
  }

  // 檢查玩家是否已投票
  bool hasPlayerVoted(String playerId) {
    return votes.containsKey(playerId);
  }

  // 獲取階段顯示名稱
  String get phaseDisplayName {
    switch (phase) {
      case GamePhase.waiting:
        return '等待玩家';
      case GamePhase.preparation:
        return '準備階段';
      case GamePhase.conspiracy:
        return '密謀階段';
      case GamePhase.debate:
        return '辯論階段';
      case GamePhase.event:
        return '突發事件';
      case GamePhase.finalSpeech:
        return '最終發言';
      case GamePhase.voting:
        return '投票表決';
      case GamePhase.result:
        return '結果公佈';
    }
  }

  // 獲取階段進度百分比
  double get phaseProgress {
    return room.phaseProgress;
  }

  // 格式化剩餘時間
  String get formattedTimeRemaining {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

// 工廠方法
class GameStateFactory {
  static GameState createInitialState({
    required Room room,
    String? currentPlayerId,
  }) {
    return GameState(
      room: room,
      currentPlayerId: currentPlayerId,
      hand: [],
      phase: room.phase,
      round: room.round,
      remainingSeconds: room.remainingSeconds,
    );
  }

  static ChatMessage createChatMessage({
    required String fromId,
    required String fromName,
    required String content,
    bool isPrivate = false,
    String? toId,
    ChatMessageType? type,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fromId: fromId,
      fromName: fromName,
      content: content,
      isPrivate: isPrivate,
      timestamp: DateTime.now(),
      toId: toId,
      type: type ?? ChatMessageType.normal,
    );
  }

  static GameEvent createGameEvent({
    required GameEventType type,
    required String description,
    Map<String, dynamic>? data,
    String? playerId,
    String? playerName,
  }) {
    return GameEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      description: description,
      timestamp: DateTime.now(),
      data: data ?? {},
      playerId: playerId,
      playerName: playerName,
    );
  }
}