import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_state.dart';
import '../models/room.dart';
import '../models/player.dart';
import '../models/card.dart';
import '../services/websocket_service.dart';
import 'auth_provider.dart';
import 'connection_provider.dart';
import 'room_provider.dart';

/// 遊戲狀態管理器
class GameStateNotifier extends StateNotifier<GameState?> {
  final WebSocketMessageSender _wsSender;
  String? _currentPlayerId;

  GameStateNotifier(this._wsSender) : super(null);

  /// 設定當前玩家 ID
  void setCurrentPlayerId(String playerId) {
    _currentPlayerId = playerId;
  }

  /// 初始化遊戲狀態
  void initializeGame(Room room) {
    final gameState = GameStateFactory.createInitialState(
      room: room,
      currentPlayerId: _currentPlayerId,
    );
    state = gameState;
  }

  /// 處理遊戲開始
  void handleGameStarted(GamePhase phase, int durationSecs) {
    if (state == null) return;

    state = state!.copyWith(
      phase: phase,
      remainingSeconds: durationSecs,
    );
  }

  /// 處理階段變更
  void handlePhaseChanged(GamePhase newPhase, int durationSecs, int round) {
    if (state == null) return;

    state = state!.copyWith(
      phase: newPhase,
      remainingSeconds: durationSecs,
      round: round,
      currentSpeakerId: null, // 重置發言者
    );
  }

  /// 處理聊天訊息
  void handleChatMessage(ChatMessage message) {
    if (state == null) return;

    final updatedMessages = [...state!.chatMessages, message];
    
    // 保持最新 100 條訊息
    if (updatedMessages.length > 100) {
      updatedMessages.removeRange(0, updatedMessages.length - 100);
    }

    state = state!.copyWith(chatMessages: updatedMessages);
  }

  /// 處理遊戲事件
  void handleGameEvent(GameEvent event) {
    if (state == null) return;

    final updatedEvents = [...state!.gameEvents, event];
    
    // 保持最新 50 個事件
    if (updatedEvents.length > 50) {
      updatedEvents.removeRange(0, updatedEvents.length - 50);
    }

    state = state!.copyWith(gameEvents: updatedEvents);
  }

  /// 處理房間狀態更新
  void handleRoomUpdate(Room updatedRoom) {
    if (state == null) return;

    state = state!.copyWith(room: updatedRoom);
  }

  /// 處理手牌更新
  void handleHandUpdate(List<GameCard> newHand) {
    if (state == null) return;

    state = state!.copyWith(hand: newHand);
  }

  /// 處理投票
  void handleVote(String playerId, VoteChoice choice) {
    if (state == null) return;

    final updatedVotes = Map<String, VoteChoice>.from(state!.votes);
    updatedVotes[playerId] = choice;

    state = state!.copyWith(votes: updatedVotes);
  }

  /// 處理遊戲結果
  void handleGameResult(GameResult result) {
    if (state == null) return;

    state = state!.copyWith(result: result);
  }

  /// 處理計時器更新
  void handleTimerUpdate(int remainingSecs) {
    if (state == null) return;

    state = state!.copyWith(remainingSeconds: remainingSecs);
  }

  /// 發送聊天訊息
  void sendChatMessage(String content) {
    if (content.trim().isEmpty) return;
    
    _wsSender.sendChatMessage(content);
  }

  /// 發送私訊
  void sendPrivateMessage(String targetId, String content) {
    if (content.trim().isEmpty) return;
    
    _wsSender.sendPrivateMessage(targetId, content);
  }

  /// 使用卡牌
  void useCard(String cardId, {String? targetId}) {
    if (state == null) return;

    // 檢查是否擁有該卡牌
    final hasCard = state!.hand.any((card) => card.id == cardId);
    if (!hasCard) return;

    // 發送使用卡牌請求
    final success = _wsSender.sendMessage(ClientMessage.useCard(
      cardId: cardId,
      targetId: targetId,
    ));

    if (!success) {
      // TODO: 處理發送失敗
      print('Failed to use card: $cardId');
    }
  }

  /// 投票
  void vote(VoteChoice choice) {
    if (state == null) return;
    if (state!.phase != GamePhase.voting) return;
    if (state!.hasPlayerVoted(_currentPlayerId ?? '')) return;

    final success = _wsSender.sendMessage(ClientMessage.vote(choice: choice));

    if (!success) {
      // TODO: 處理發送失敗
      print('Failed to vote: $choice');
    }
  }

  /// 質詢（攻擊）
  void challenge(String targetId) {
    if (state == null) return;
    if (state!.phase != GamePhase.debate) return;

    final success = _wsSender.sendMessage(ClientMessage.challenge(targetId: targetId));

    if (!success) {
      // TODO: 處理發送失敗
      print('Failed to challenge: $targetId');
    }
  }

  /// 反駁（防禦）
  void counter() {
    if (state == null) return;

    final success = _wsSender.sendMessage(const ClientMessage.counter());

    if (!success) {
      // TODO: 處理發送失敗
      print('Failed to counter');
    }
  }

  /// 清除遊戲狀態
  void clearGame() {
    state = null;
  }
}

/// 遊戲狀態提供者
final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState?>((ref) {
  final wsSender = ref.watch(webSocketSenderProvider);
  final notifier = GameStateNotifier(wsSender);

  // 設定當前玩家 ID
  final currentPlayerId = ref.watch(currentPlayerIdProvider);
  if (currentPlayerId != null) {
    notifier.setCurrentPlayerId(currentPlayerId);
  }

  return notifier;
});

/// 當前遊戲房間提供者
final currentGameRoomProvider = Provider<Room?>((ref) {
  final gameState = ref.watch(gameStateProvider);
  return gameState?.room;
});

/// 當前玩家提供者
final currentGamePlayerProvider = Provider<Player?>((ref) {
  final gameState = ref.watch(gameStateProvider);
  return gameState?.currentPlayer;
});

/// 當前手牌提供者
final currentHandProvider = Provider<List<GameCard>>((ref) {
  final gameState = ref.watch(gameStateProvider);
  return gameState?.hand ?? [];
});

/// 可用手牌提供者
final playableCardsProvider = Provider<List<GameCard>>((ref) {
  final gameState = ref.watch(gameStateProvider);
  return gameState?.playableCards ?? [];
});

/// 聊天訊息提供者
final chatMessagesProvider = Provider<List<ChatMessage>>((ref) {
  final gameState = ref.watch(gameStateProvider);
  return gameState?.recentChatMessages ?? [];
});

/// 遊戲事件提供者
final gameEventsProvider = Provider<List<GameEvent>>((ref) {
  final gameState = ref.watch(gameStateProvider);
  return gameState?.recentGameEvents ?? [];
});

/// 投票狀態提供者
final votingStateProvider = Provider<VotingState>((ref) {
  final gameState = ref.watch(gameStateProvider);
  final currentPlayerId = ref.watch(currentPlayerIdProvider);

  if (gameState == null) {
    return const VotingState();
  }

  return VotingState(
    isVotingPhase: gameState.phase == GamePhase.voting,
    hasVoted: gameState.hasPlayerVoted(currentPlayerId ?? ''),
    votes: gameState.votes,
    progress: gameState.votingProgress,
    isComplete: gameState.isVotingComplete,
  );
});

/// 投票狀態數據類
class VotingState {
  final bool isVotingPhase;
  final bool hasVoted;
  final Map<String, VoteChoice> votes;
  final double progress;
  final bool isComplete;

  const VotingState({
    this.isVotingPhase = false,
    this.hasVoted = false,
    this.votes = const {},
    this.progress = 0.0,
    this.isComplete = false,
  });
}

/// 階段時間提供者
final phaseTimerProvider = Provider<PhaseTimer>((ref) {
  final gameState = ref.watch(gameStateProvider);

  if (gameState == null) {
    return const PhaseTimer();
  }

  return PhaseTimer(
    phase: gameState.phase,
    remainingSeconds: gameState.remainingSeconds,
    progress: gameState.phaseProgress,
    formattedTime: gameState.formattedTimeRemaining,
  );
});

/// 階段計時器數據類
class PhaseTimer {
  final GamePhase phase;
  final int remainingSeconds;
  final double progress;
  final String formattedTime;

  const PhaseTimer({
    this.phase = GamePhase.waiting,
    this.remainingSeconds = 0,
    this.progress = 0.0,
    this.formattedTime = '00:00',
  });
}

/// WebSocket 遊戲訊息處理提供者
final gameWebSocketHandlerProvider = Provider<void>((ref) {
  final gameStateNotifier = ref.watch(gameStateProvider.notifier);
  final wsService = ref.watch(webSocketServiceProvider);

  // 監聽 WebSocket 訊息
  ref.listen(
    StreamProvider((ref) => wsService.messageStream),
    (previous, next) {
      next.when(
        data: (message) {
          _handleGameWebSocketMessage(message, gameStateNotifier);
        },
        loading: () {},
        error: (error, _) {
          print('Game WebSocket message error: $error');
        },
      );
    },
  );

  // 監聽當前房間變化，初始化遊戲狀態
  ref.listen(currentRoomProvider, (previous, next) {
    if (next.room != null && next.room!.status == RoomStatus.playing) {
      gameStateNotifier.initializeGame(next.room!);
    } else if (next.room == null) {
      gameStateNotifier.clearGame();
    }
  });
});

/// 處理遊戲相關的 WebSocket 訊息
void _handleGameWebSocketMessage(ServerMessage message, GameStateNotifier notifier) {
  switch (message) {
    case GameStartedMessage():
      final phase = _parseGamePhase(message.phase);
      notifier.handleGameStarted(phase, message.durationSecs);
      break;

    case PhaseChangedMessage():
      final phase = _parseGamePhase(message.phase);
      notifier.handlePhaseChanged(phase, message.durationSecs, message.round);
      break;

    case ChatMessageMessage():
      final chatMessage = GameStateFactory.createChatMessage(
        fromId: message.fromId,
        fromName: message.fromName,
        content: message.content,
        isPrivate: message.isPrivate,
        type: message.isPrivate ? ChatMessageType.whisper : ChatMessageType.normal,
      );
      notifier.handleChatMessage(chatMessage);
      break;

    case RoomStateMessage():
      try {
        final room = Room.fromJson(message.roomData);
        notifier.handleRoomUpdate(room);
      } catch (e) {
        // ignore: avoid_print
        print('Failed to parse room state in game: $e');
      }
      break;

    // TODO: 處理其他遊戲相關訊息
    default:
      break;
  }
}

/// 解析遊戲階段字串
GamePhase _parseGamePhase(String phaseStr) {
  switch (phaseStr) {
    case 'waiting':
      return GamePhase.waiting;
    case 'preparation':
      return GamePhase.preparation;
    case 'conspiracy':
      return GamePhase.conspiracy;
    case 'debate':
      return GamePhase.debate;
    case 'event':
      return GamePhase.event;
    case 'final_speech':
      return GamePhase.finalSpeech;
    case 'voting':
      return GamePhase.voting;
    case 'result':
      return GamePhase.result;
    default:
      print('Unknown game phase: $phaseStr');
      return GamePhase.waiting;
  }
}

/// 遊戲操作幫助類
class GameActions {
  final GameStateNotifier _notifier;

  GameActions(this._notifier);

  /// 發送聊天訊息
  void sendChat(String message) {
    _notifier.sendChatMessage(message);
  }

  /// 發送私訊
  void sendPrivateMessage(String targetId, String message) {
    _notifier.sendPrivateMessage(targetId, message);
  }

  /// 使用卡牌
  void useCard(GameCard card, {Player? target}) {
    _notifier.useCard(card.id, targetId: target?.id);
  }

  /// 質詢玩家
  void challengePlayer(Player target) {
    _notifier.challenge(target.id);
  }

  /// 反駁
  void counter() {
    _notifier.counter();
  }

  /// 投票
  void vote(VoteChoice choice) {
    _notifier.vote(choice);
  }
}

/// 遊戲操作提供者
final gameActionsProvider = Provider<GameActions>((ref) {
  final notifier = ref.watch(gameStateProvider.notifier);
  return GameActions(notifier);
});

/// 當前遊戲是否進行中提供者
final isGameActiveProvider = Provider<bool>((ref) {
  final room = ref.watch(currentGameRoomProvider);
  return room?.status == RoomStatus.playing;
});

/// 當前是否為我的回合提供者
final isMyTurnProvider = Provider<bool>((ref) {
  final gameState = ref.watch(gameStateProvider);
  return gameState?.isMyTurn ?? false;
});