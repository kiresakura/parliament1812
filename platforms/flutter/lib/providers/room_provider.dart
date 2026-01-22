import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/game_service.dart';
import 'socket_provider.dart';
import 'game_provider.dart';

/// 房間狀態
class RoomInfo {
  final String roomId;
  final String roomCode;
  final String hostId;
  final String localPlayerId;
  final List<PlayerState> players;
  final bool isGameStarted;

  const RoomInfo({
    required this.roomId,
    required this.roomCode,
    required this.hostId,
    required this.localPlayerId,
    this.players = const [],
    this.isGameStarted = false,
  });

  RoomInfo copyWith({
    String? roomId,
    String? roomCode,
    String? hostId,
    String? localPlayerId,
    List<PlayerState>? players,
    bool? isGameStarted,
  }) {
    return RoomInfo(
      roomId: roomId ?? this.roomId,
      roomCode: roomCode ?? this.roomCode,
      hostId: hostId ?? this.hostId,
      localPlayerId: localPlayerId ?? this.localPlayerId,
      players: players ?? this.players,
      isGameStarted: isGameStarted ?? this.isGameStarted,
    );
  }

  bool get isHost => localPlayerId == hostId;

  PlayerState? get localPlayer {
    try {
      return players.firstWhere((p) => p.id == localPlayerId);
    } catch (_) {
      return null;
    }
  }
}

/// 房間 Notifier
class RoomNotifier extends StateNotifier<RoomInfo?> {
  final GameService _gameService;
  final Ref _ref;
  final List<StreamSubscription> _subscriptions = [];

  RoomNotifier(this._gameService, this._ref) : super(null) {
    _setupListeners();
  }

  void _setupListeners() {
    // 監聽玩家加入
    _subscriptions.add(_gameService.onPlayerJoined.listen((data) {
      debugPrint('RoomNotifier: Player joined $data');
      if (state == null) return;

      final playerData = data['player'] as Map<String, dynamic>?;
      if (playerData != null) {
        final newPlayer = _parsePlayer(playerData);
        if (!state!.players.any((p) => p.id == newPlayer.id)) {
          state = state!.copyWith(
            players: [...state!.players, newPlayer],
          );
        }
      }
    }));

    // 監聽玩家離開
    _subscriptions.add(_gameService.onPlayerLeft.listen((data) {
      debugPrint('RoomNotifier: Player left $data');
      if (state == null) return;

      final playerId = data['playerId'] as String?;
      final newHostId = data['newHostId'] as String?;

      if (playerId != null) {
        state = state!.copyWith(
          players: state!.players.where((p) => p.id != playerId).toList(),
          hostId: newHostId ?? state!.hostId,
        );
      }
    }));

    // 監聽玩家準備狀態變化
    _subscriptions.add(_gameService.onPlayerReadyChanged.listen((data) {
      debugPrint('RoomNotifier: Player ready changed $data');
      if (state == null) return;

      final playerId = data['playerId'] as String?;
      final ready = data['ready'] as bool? ?? false;

      if (playerId != null) {
        state = state!.copyWith(
          players: state!.players.map((p) {
            if (p.id == playerId) {
              return p.copyWith(isReady: ready);
            }
            return p;
          }).toList(),
        );
      }
    }));

    // 監聽遊戲開始
    _subscriptions.add(_gameService.onGameStarted.listen((data) {
      debugPrint('RoomNotifier: Game started $data');
      if (state == null) return;

      state = state!.copyWith(isGameStarted: true);

      // 更新遊戲狀態
      _updateGameState(data);
    }));
  }

  void _updateGameState(Map<String, dynamic> data) {
    // 更新本地玩家角色
    final playerData = data['player'] as Map<String, dynamic>?;
    // final roleData = data['role'] as Map<String, dynamic>?; // 角色資料已包含在 playerData 中
    final gameStateData = data['gameState'] as Map<String, dynamic>?;

    if (playerData != null && state != null) {
      final localPlayerId = state!.localPlayerId;
      state = state!.copyWith(
        players: state!.players.map((p) {
          if (p.id == localPlayerId) {
            return _parsePlayer(playerData);
          }
          return p;
        }).toList(),
      );
    }

    // 更新遊戲 Provider
    final gameNotifier = _ref.read(gameProvider.notifier);
    if (gameStateData != null) {
      final phase = _parsePhase(gameStateData['phase'] as String?);
      final timeRemaining = gameStateData['timeRemaining'] as int? ?? 0;
      gameNotifier.setPhase(phase, timeRemaining);
    }

    // 更新本地玩家 Provider
    if (playerData != null) {
      final localPlayerNotifier = _ref.read(localPlayerProvider.notifier);
      localPlayerNotifier.setPlayer(_parsePlayer(playerData));
    }
  }

  /// 創建房間
  Future<bool> createRoom(String roomId, String roomCode, String playerId, PlayerState host) async {
    state = RoomInfo(
      roomId: roomId,
      roomCode: roomCode,
      hostId: playerId,
      localPlayerId: playerId,
      players: [host.copyWith(isHost: true, id: playerId)],
    );

    // 同步到 gameProvider
    _ref.read(gameProvider.notifier).createRoom(roomId, roomCode, host.copyWith(isHost: true, id: playerId));

    return true;
  }

  /// 加入房間
  Future<bool> joinRoom(Map<String, dynamic> data) async {
    final roomId = data['roomId'] as String? ?? '';
    final roomCode = data['roomCode'] as String? ?? '';
    final playerData = data['player'] as Map<String, dynamic>?;
    final playersData = data['players'] as List<dynamic>? ?? [];

    if (playerData == null) return false;

    final localPlayerId = playerData['id'] as String? ?? '';
    final players = playersData
        .map((p) => _parsePlayer(p as Map<String, dynamic>))
        .toList();

    // 找出房主
    final hostId = players.firstWhere((p) => p.isHost, orElse: () => players.first).id;

    state = RoomInfo(
      roomId: roomId,
      roomCode: roomCode,
      hostId: hostId,
      localPlayerId: localPlayerId,
      players: players,
    );

    // 同步到 gameProvider
    _ref.read(gameProvider.notifier).joinRoom(RoomState(
      roomId: roomId,
      roomCode: roomCode,
      players: players,
    ));

    // 設置本地玩家
    _ref.read(localPlayerProvider.notifier).setPlayer(_parsePlayer(playerData));

    return true;
  }

  /// 離開房間
  void leaveRoom() {
    state = null;
    _ref.read(gameProvider.notifier).leaveRoom();
    _ref.read(localPlayerProvider.notifier).clear();
  }

  /// 更新玩家準備狀態
  void setPlayerReady(String playerId, bool ready) {
    if (state == null) return;

    state = state!.copyWith(
      players: state!.players.map((p) {
        if (p.id == playerId) {
          return p.copyWith(isReady: ready);
        }
        return p;
      }).toList(),
    );

    // 同步到 gameProvider
    _ref.read(gameProvider.notifier).setPlayerReady(playerId, ready);
  }

  PlayerState _parsePlayer(Map<String, dynamic> data) {
    return PlayerState(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      roleId: data['roleId'] as String?,
      reputation: data['reputation'] as int? ?? 50,
      gold: data['gold'] as int? ?? 0,
      isAlive: data['isAlive'] as bool? ?? true,
      isReady: data['isReady'] as bool? ?? false,
      isHost: data['isHost'] as bool? ?? false,
    );
  }

  GamePhase _parsePhase(String? phase) {
    switch (phase) {
      case 'waiting':
        return GamePhase.waiting;
      case 'conspiracy':
        return GamePhase.conspiracy;
      case 'debate':
        return GamePhase.debate;
      case 'event':
        return GamePhase.event;
      case 'voting':
        return GamePhase.voting;
      case 'result':
        return GamePhase.result;
      default:
        return GamePhase.waiting;
    }
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}

/// 房間狀態 Provider
final roomProvider = StateNotifierProvider<RoomNotifier, RoomInfo?>((ref) {
  final gameService = ref.watch(gameServiceProvider);
  return RoomNotifier(gameService, ref);
});

/// 是否在房間中 Provider
final isInRoomProvider2 = Provider<bool>((ref) {
  return ref.watch(roomProvider) != null;
});

/// 是否是房主 Provider
final isHostProvider = Provider<bool>((ref) {
  return ref.watch(roomProvider)?.isHost ?? false;
});

/// 房間代碼 Provider
final roomCodeProvider = Provider<String?>((ref) {
  return ref.watch(roomProvider)?.roomCode;
});

/// 是否可以開始遊戲 Provider
final canStartGameProvider2 = Provider<bool>((ref) {
  final room = ref.watch(roomProvider);
  if (room == null) return false;
  if (room.players.length < 4) return false;

  // 所有非房主玩家都準備好了
  return room.players.every((p) => p.isReady || p.isHost);
});
