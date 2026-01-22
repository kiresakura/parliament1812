import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/game_constants.dart';

/// 遊戲階段
enum GamePhase {
  waiting,     // 等待玩家加入
  preparing,   // 準備階段
  conspiracy,  // 密謀階段
  debate,      // 辯論階段
  event,       // 突發事件
  voting,      // 投票階段
  result,      // 結算階段
}

/// 玩家狀態
class PlayerState {
  final String id;
  final String name;
  final String? roleId;
  final int reputation;
  final int gold;
  final bool isAlive;
  final bool isReady;
  final bool isHost;

  const PlayerState({
    required this.id,
    required this.name,
    this.roleId,
    this.reputation = 50,
    this.gold = 0,
    this.isAlive = true,
    this.isReady = false,
    this.isHost = false,
  });

  PlayerState copyWith({
    String? id,
    String? name,
    String? roleId,
    int? reputation,
    int? gold,
    bool? isAlive,
    bool? isReady,
    bool? isHost,
  }) {
    return PlayerState(
      id: id ?? this.id,
      name: name ?? this.name,
      roleId: roleId ?? this.roleId,
      reputation: reputation ?? this.reputation,
      gold: gold ?? this.gold,
      isAlive: isAlive ?? this.isAlive,
      isReady: isReady ?? this.isReady,
      isHost: isHost ?? this.isHost,
    );
  }
}

/// 房間狀態
class RoomState {
  final String roomId;
  final String roomCode;
  final List<PlayerState> players;
  final GamePhase phase;
  final int timeRemaining;
  final Map<String, String> votes;  // playerId -> option (A/B/C)
  final String? currentBillId;

  const RoomState({
    required this.roomId,
    required this.roomCode,
    this.players = const [],
    this.phase = GamePhase.waiting,
    this.timeRemaining = 0,
    this.votes = const {},
    this.currentBillId,
  });

  RoomState copyWith({
    String? roomId,
    String? roomCode,
    List<PlayerState>? players,
    GamePhase? phase,
    int? timeRemaining,
    Map<String, String>? votes,
    String? currentBillId,
  }) {
    return RoomState(
      roomId: roomId ?? this.roomId,
      roomCode: roomCode ?? this.roomCode,
      players: players ?? this.players,
      phase: phase ?? this.phase,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      votes: votes ?? this.votes,
      currentBillId: currentBillId ?? this.currentBillId,
    );
  }

  /// 是否可以開始遊戲
  bool get canStart {
    if (players.length < GameConstants.minPlayers) return false;
    return players.every((p) => p.isReady || p.isHost);
  }
}

/// 遊戲狀態 Notifier
class GameNotifier extends StateNotifier<RoomState?> {
  GameNotifier() : super(null);

  /// 創建房間
  void createRoom(String roomId, String roomCode, PlayerState host) {
    state = RoomState(
      roomId: roomId,
      roomCode: roomCode,
      players: [host.copyWith(isHost: true)],
    );
  }

  /// 加入房間
  void joinRoom(RoomState room) {
    state = room;
  }

  /// 離開房間
  void leaveRoom() {
    state = null;
  }

  /// 新增玩家
  void addPlayer(PlayerState player) {
    if (state == null) return;
    state = state!.copyWith(
      players: [...state!.players, player],
    );
  }

  /// 移除玩家
  void removePlayer(String playerId) {
    if (state == null) return;
    state = state!.copyWith(
      players: state!.players.where((p) => p.id != playerId).toList(),
    );
  }

  /// 更新玩家準備狀態
  void setPlayerReady(String playerId, bool isReady) {
    if (state == null) return;
    state = state!.copyWith(
      players: state!.players.map((p) {
        if (p.id == playerId) {
          return p.copyWith(isReady: isReady);
        }
        return p;
      }).toList(),
    );
  }

  /// 更新遊戲階段
  void setPhase(GamePhase phase, int timeRemaining) {
    if (state == null) return;
    state = state!.copyWith(
      phase: phase,
      timeRemaining: timeRemaining,
    );
  }

  /// 更新倒數時間
  void setTimeRemaining(int seconds) {
    if (state == null) return;
    state = state!.copyWith(timeRemaining: seconds);
  }

  /// 更新玩家聲望
  void updateReputation(String playerId, int change) {
    if (state == null) return;
    state = state!.copyWith(
      players: state!.players.map((p) {
        if (p.id == playerId) {
          final newReputation = (p.reputation + change).clamp(0, 100);
          return p.copyWith(
            reputation: newReputation,
            isAlive: newReputation > 0,
          );
        }
        return p;
      }).toList(),
    );
  }

  /// 記錄投票
  void recordVote(String playerId, String option) {
    if (state == null) return;
    state = state!.copyWith(
      votes: {...state!.votes, playerId: option},
    );
  }

  /// 分配角色
  void assignRole(String playerId, String roleId) {
    if (state == null) return;
    final role = RoleDatabase.getRoleById(roleId);
    if (role == null) return;

    state = state!.copyWith(
      players: state!.players.map((p) {
        if (p.id == playerId) {
          return p.copyWith(
            roleId: roleId,
            reputation: role.initialReputation,
            gold: role.initialGold,
          );
        }
        return p;
      }).toList(),
    );
  }
}

/// 本地玩家狀態
class LocalPlayerNotifier extends StateNotifier<PlayerState?> {
  LocalPlayerNotifier() : super(null);

  void setPlayer(PlayerState player) {
    state = player;
  }

  void updateName(String name) {
    if (state != null) {
      state = state!.copyWith(name: name);
    }
  }

  void clear() {
    state = null;
  }
}

// ===== Providers =====

/// 遊戲房間狀態 Provider
final gameProvider = StateNotifierProvider<GameNotifier, RoomState?>((ref) {
  return GameNotifier();
});

/// 本地玩家狀態 Provider
final localPlayerProvider = StateNotifierProvider<LocalPlayerNotifier, PlayerState?>((ref) {
  return LocalPlayerNotifier();
});

/// 是否已連接房間
final isInRoomProvider = Provider<bool>((ref) {
  return ref.watch(gameProvider) != null;
});

/// 當前階段
final currentPhaseProvider = Provider<GamePhase?>((ref) {
  return ref.watch(gameProvider)?.phase;
});

/// 剩餘時間
final timeRemainingProvider = Provider<int>((ref) {
  return ref.watch(gameProvider)?.timeRemaining ?? 0;
});

/// 玩家列表
final playersProvider = Provider<List<PlayerState>>((ref) {
  return ref.watch(gameProvider)?.players ?? [];
});

/// 是否可以開始遊戲
final canStartGameProvider = Provider<bool>((ref) {
  return ref.watch(gameProvider)?.canStart ?? false;
});
