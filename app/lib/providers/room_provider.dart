import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../models/room.dart';
import '../models/player.dart';
import 'auth_provider.dart';
import 'connection_provider.dart';

/// 房間列表狀態
class RoomListState {
  final List<Room> rooms;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final DateTime? lastUpdated;

  const RoomListState({
    this.rooms = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.lastUpdated,
  });

  RoomListState copyWith({
    List<Room>? rooms,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    DateTime? lastUpdated,
  }) {
    return RoomListState(
      rooms: rooms ?? this.rooms,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// 房間列表管理器
class RoomListNotifier extends StateNotifier<RoomListState> {
  final ApiService _apiService;

  RoomListNotifier(this._apiService) : super(const RoomListState());

  /// 載入房間列表
  Future<void> loadRooms({
    bool forceRefresh = false,
    RoomStatus? statusFilter,
    String? searchQuery,
  }) async {
    // 如果已經在載入且不是強制刷新，則跳過
    if (state.isLoading && !forceRefresh) return;

    state = state.copyWith(
      isLoading: !forceRefresh,
      isRefreshing: forceRefresh,
      error: null,
    );

    try {
      final result = await _apiService.getRooms(
        limit: 50,
        status: statusFilter,
        search: searchQuery,
      );

      if (result.success && result.data != null) {
        state = state.copyWith(
          rooms: result.data!,
          isLoading: false,
          isRefreshing: false,
          lastUpdated: DateTime.now(),
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          error: result.error ?? '載入房間列表失敗',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: '載入房間列表失敗: $e',
      );
    }
  }

  /// 刷新房間列表
  Future<void> refreshRooms() async {
    await loadRooms(forceRefresh: true);
  }

  /// 清除錯誤
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 根據房間代碼查找房間
  Room? findRoomByCode(String roomCode) {
    try {
      return state.rooms.firstWhere((room) => room.code == roomCode);
    } catch (e) {
      return null;
    }
  }
}

/// 當前房間狀態
class CurrentRoomState {
  final Room? room;
  final bool isLoading;
  final bool isJoining;
  final bool isLeaving;
  final String? error;
  final String? currentPlayerId;

  const CurrentRoomState({
    this.room,
    this.isLoading = false,
    this.isJoining = false,
    this.isLeaving = false,
    this.error,
    this.currentPlayerId,
  });

  CurrentRoomState copyWith({
    Room? room,
    bool? isLoading,
    bool? isJoining,
    bool? isLeaving,
    String? error,
    String? currentPlayerId,
  }) {
    return CurrentRoomState(
      room: room ?? this.room,
      isLoading: isLoading ?? this.isLoading,
      isJoining: isJoining ?? this.isJoining,
      isLeaving: isLeaving ?? this.isLeaving,
      error: error ?? this.error,
      currentPlayerId: currentPlayerId ?? this.currentPlayerId,
    );
  }

  bool get isInRoom => room != null;
  bool get isHost => room != null && currentPlayerId != null && room!.isHost(currentPlayerId!);
  Player? get currentPlayer => room?.findPlayer(currentPlayerId ?? '');
}

/// 當前房間管理器
class CurrentRoomNotifier extends StateNotifier<CurrentRoomState> {
  final ApiService _apiService;
  final WebSocketMessageSender _wsSender;

  CurrentRoomNotifier(this._apiService, this._wsSender) : super(const CurrentRoomState());

  /// 設定當前玩家 ID
  void setCurrentPlayerId(String playerId) {
    state = state.copyWith(currentPlayerId: playerId);
  }

  /// 載入房間詳情
  Future<bool> loadRoomDetails(String roomCode) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _apiService.getRoomDetails(roomCode);

      if (result.success && result.data != null) {
        state = state.copyWith(
          room: result.data!,
          isLoading: false,
          error: null,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error ?? '載入房間失敗',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '載入房間失敗: $e',
      );
      return false;
    }
  }

  /// 加入房間
  Future<bool> joinRoom(String roomCode, String playerName, {String? password}) async {
    state = state.copyWith(isJoining: true, error: null);

    try {
      // 先通過 REST API 檢查房間狀態
      final result = await _apiService.joinRoom(
        roomCode: roomCode,
        playerName: playerName,
        password: password,
      );

      if (!result.success) {
        state = state.copyWith(
          isJoining: false,
          error: result.error ?? '加入房間失敗',
        );
        return false;
      }

      // 通過 WebSocket 實際加入
      final wsSuccess = _wsSender.joinRoom(roomCode, playerName);
      if (!wsSuccess) {
        state = state.copyWith(
          isJoining: false,
          error: 'WebSocket 連接失敗',
        );
        return false;
      }

      state = state.copyWith(
        room: result.data,
        isJoining: false,
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isJoining: false,
        error: '加入房間失敗: $e',
      );
      return false;
    }
  }

  /// 離開房間
  Future<bool> leaveRoom() async {
    if (!state.isInRoom) return true;

    state = state.copyWith(isLeaving: true, error: null);

    try {
      final success = _wsSender.leaveRoom();
      
      if (success) {
        state = const CurrentRoomState();
        return true;
      } else {
        state = state.copyWith(
          isLeaving: false,
          error: '離開房間失敗',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLeaving: false,
        error: '離開房間失敗: $e',
      );
      return false;
    }
  }

  /// 創建房間
  Future<bool> createRoom({
    required String roomName,
    required String hostPlayerName,
    RoomSettings? settings,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _apiService.createRoom(
        name: roomName,
        hostPlayerName: hostPlayerName,
        settings: settings,
      );

      if (result.success && result.data != null) {
        // 自動加入創建的房間
        final room = result.data!;
        final joinSuccess = await joinRoom(room.code, hostPlayerName);
        
        if (joinSuccess) {
          state = state.copyWith(
            room: room,
            isLoading: false,
            error: null,
          );
          return true;
        } else {
          state = state.copyWith(
            isLoading: false,
            error: '創建房間成功但加入失敗',
          );
          return false;
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error ?? '創建房間失敗',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '創建房間失敗: $e',
      );
      return false;
    }
  }

  /// 準備/取消準備
  void toggleReady() {
    final currentPlayer = state.currentPlayer;
    if (currentPlayer == null) return;

    final success = _wsSender.toggleReady(!currentPlayer.isReady);
    if (!success) {
      state = state.copyWith(error: '切換準備狀態失敗');
    }
  }

  /// 開始遊戲
  void startGame() {
    if (!state.isHost) {
      state = state.copyWith(error: '只有房主可以開始遊戲');
      return;
    }

    if (state.room?.canStartGame != true) {
      state = state.copyWith(error: '遊戲無法開始：請確保所有玩家都已準備');
      return;
    }

    final success = _wsSender.startGame();
    if (!success) {
      state = state.copyWith(error: '開始遊戲失敗');
    }
  }

  /// 處理 WebSocket 房間狀態更新
  void handleRoomStateUpdate(Room updatedRoom, List<Player> players) {
    if (state.room?.id == updatedRoom.id) {
      state = state.copyWith(
        room: updatedRoom.copyWith(players: players),
        error: null,
      );
    }
  }

  /// 處理玩家加入事件
  void handlePlayerJoined(Player newPlayer) {
    final room = state.room;
    if (room == null) return;

    final updatedPlayers = [...room.players, newPlayer];
    state = state.copyWith(
      room: room.copyWith(players: updatedPlayers),
    );
  }

  /// 處理玩家離開事件
  void handlePlayerLeft(String playerId) {
    final room = state.room;
    if (room == null) return;

    final updatedPlayers = room.players.where((p) => p.id != playerId).toList();
    state = state.copyWith(
      room: room.copyWith(players: updatedPlayers),
    );
  }

  /// 清除錯誤
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// 房間列表提供者
final roomListProvider = StateNotifierProvider<RoomListNotifier, RoomListState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return RoomListNotifier(apiService);
});

/// 當前房間提供者
final currentRoomProvider = StateNotifierProvider<CurrentRoomNotifier, CurrentRoomState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final wsSender = ref.watch(webSocketSenderProvider);
  final notifier = CurrentRoomNotifier(apiService, wsSender);
  
  // 設定當前玩家 ID
  final currentPlayerId = ref.watch(currentPlayerIdProvider);
  if (currentPlayerId != null) {
    notifier.setCurrentPlayerId(currentPlayerId);
  }
  
  return notifier;
});

/// WebSocket 房間事件處理提供者
final roomWebSocketHandlerProvider = Provider<void>((ref) {
  final currentRoomNotifier = ref.watch(currentRoomProvider.notifier);
  final wsService = ref.watch(webSocketServiceProvider);

  // 監聽 WebSocket 訊息
  ref.listen(
    StreamProvider((ref) => wsService.messageStream),
    (previous, next) {
      next.when(
        data: (message) {
          _handleWebSocketMessage(message, currentRoomNotifier);
        },
        loading: () {},
        error: (error, _) {
          debugPrint('WebSocket message error: $error');
        },
      );
    },
  );
});

/// 處理 WebSocket 訊息
void _handleWebSocketMessage(ServerMessage message, CurrentRoomNotifier notifier) {
  switch (message) {
    case RoomStateMessage():
      try {
        final room = Room.fromJson(message.roomData);
        final players = message.playersData.map((data) => Player.fromJson(data)).toList();
        notifier.handleRoomStateUpdate(room, players);
      } catch (e) {
        // ignore: avoid_print
        debugPrint('Failed to parse room state: $e');
      }
      break;

    case PlayerJoinedMessage():
      try {
        final player = Player.fromJson(message.playerData);
        notifier.handlePlayerJoined(player);
      } catch (e) {
        // ignore: avoid_print
        debugPrint('Failed to parse player joined: $e');
      }
      break;

    case PlayerLeftMessage():
      notifier.handlePlayerLeft(message.playerId);
      break;

    case ErrorMessage():
      // ignore: avoid_print
      debugPrint('Server error: ${message.code} - ${message.message}');
      break;

    default:
      // 其他訊息類型由其他 provider 處理
      break;
  }
}

/// 房間篩選選項
enum RoomFilterType {
  all,
  waiting,
  playing,
  canJoin,
}

/// 房間篩選狀態
class RoomFilterState {
  final RoomFilterType filterType;
  final String searchQuery;

  const RoomFilterState({
    this.filterType = RoomFilterType.all,
    this.searchQuery = '',
  });

  RoomFilterState copyWith({
    RoomFilterType? filterType,
    String? searchQuery,
  }) {
    return RoomFilterState(
      filterType: filterType ?? this.filterType,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// 房間篩選提供者
final roomFilterProvider = StateProvider<RoomFilterState>((ref) {
  return const RoomFilterState();
});

/// 已篩選的房間列表提供者
final filteredRoomsProvider = Provider<List<Room>>((ref) {
  final roomList = ref.watch(roomListProvider);
  final filter = ref.watch(roomFilterProvider);

  List<Room> rooms = roomList.rooms;

  // 根據狀態篩選
  switch (filter.filterType) {
    case RoomFilterType.waiting:
      rooms = rooms.where((room) => room.status == RoomStatus.waiting).toList();
      break;
    case RoomFilterType.playing:
      rooms = rooms.where((room) => room.status == RoomStatus.playing).toList();
      break;
    case RoomFilterType.canJoin:
      rooms = rooms.where((room) => room.status.canJoin && !room.isFull).toList();
      break;
    case RoomFilterType.all:
      break;
  }

  // 根據搜尋查詢篩選
  if (filter.searchQuery.isNotEmpty) {
    final query = filter.searchQuery.toLowerCase();
    rooms = rooms.where((room) {
      return room.name.toLowerCase().contains(query) ||
             room.code.toLowerCase().contains(query);
    }).toList();
  }

  return rooms;
});

/// 自動載入房間列表提供者
final autoLoadRoomsProvider = Provider<void>((ref) {
  final roomListNotifier = ref.watch(roomListProvider.notifier);
  
  // 當認證狀態改變時自動載入
  ref.listen(isAuthenticatedProvider, (previous, next) {
    if (next && (previous != true)) {
      roomListNotifier.loadRooms();
    }
  });
});