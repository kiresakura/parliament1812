import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/matchmaking_service.dart';
import 'socket_provider.dart';

/// 配對狀態
enum MatchmakingStatus {
  idle,           // 閒置
  searching,      // 搜尋中
  found,          // 找到對手
  joining,        // 正在加入房間
  cancelled,      // 已取消
  error,          // 錯誤
}

/// 遊戲模式
enum GameMode {
  casual,         // 休閒模式
  ranked,         // 排位模式
  custom,         // 自訂房間
}

extension GameModeConfig on GameMode {
  String get displayName {
    switch (this) {
      case GameMode.casual:
        return '休閒對戰';
      case GameMode.ranked:
        return '排位賽';
      case GameMode.custom:
        return '自訂房間';
    }
  }

  String get description {
    switch (this) {
      case GameMode.casual:
        return '輕鬆遊玩，不影響段位';
      case GameMode.ranked:
        return '正式比賽，影響段位積分';
      case GameMode.custom:
        return '創建或加入私人房間';
    }
  }

  int get minPlayers {
    switch (this) {
      case GameMode.casual:
        return 2;
      case GameMode.ranked:
        return 4;
      case GameMode.custom:
        return 2;
    }
  }

  int get maxPlayers {
    switch (this) {
      case GameMode.casual:
        return 4;
      case GameMode.ranked:
        return 4;
      case GameMode.custom:
        return 6;
    }
  }
}

/// 配對資訊
class MatchInfo {
  /// 房間代碼
  final String roomCode;

  /// 遊戲模式
  final GameMode mode;

  /// 已配對玩家數
  final int playerCount;

  /// 需要的玩家數
  final int requiredPlayers;

  /// 預估等待時間（秒）
  final int estimatedWaitTime;

  const MatchInfo({
    required this.roomCode,
    required this.mode,
    required this.playerCount,
    required this.requiredPlayers,
    this.estimatedWaitTime = 0,
  });

  bool get isReady => playerCount >= requiredPlayers;

  factory MatchInfo.fromJson(Map<String, dynamic> json) {
    return MatchInfo(
      roomCode: json['room_code'] as String,
      mode: GameMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => GameMode.casual,
      ),
      playerCount: json['player_count'] as int? ?? 0,
      requiredPlayers: json['required_players'] as int? ?? 4,
      estimatedWaitTime: json['estimated_wait_time'] as int? ?? 30,
    );
  }
}

/// 配對狀態
class MatchmakingState {
  /// 當前狀態
  final MatchmakingStatus status;

  /// 選擇的遊戲模式
  final GameMode selectedMode;

  /// 搜尋開始時間
  final DateTime? searchStartTime;

  /// 已等待時間（秒）
  final int waitingTime;

  /// 預估等待時間（秒）
  final int estimatedWaitTime;

  /// 目前佇列中的玩家數
  final int playersInQueue;

  /// 找到的配對資訊
  final MatchInfo? matchInfo;

  /// 錯誤訊息
  final String? errorMessage;

  const MatchmakingState({
    this.status = MatchmakingStatus.idle,
    this.selectedMode = GameMode.casual,
    this.searchStartTime,
    this.waitingTime = 0,
    this.estimatedWaitTime = 30,
    this.playersInQueue = 0,
    this.matchInfo,
    this.errorMessage,
  });

  bool get isSearching => status == MatchmakingStatus.searching;
  bool get isMatchFound => status == MatchmakingStatus.found;

  MatchmakingState copyWith({
    MatchmakingStatus? status,
    GameMode? selectedMode,
    DateTime? searchStartTime,
    int? waitingTime,
    int? estimatedWaitTime,
    int? playersInQueue,
    MatchInfo? matchInfo,
    String? errorMessage,
  }) {
    return MatchmakingState(
      status: status ?? this.status,
      selectedMode: selectedMode ?? this.selectedMode,
      searchStartTime: searchStartTime ?? this.searchStartTime,
      waitingTime: waitingTime ?? this.waitingTime,
      estimatedWaitTime: estimatedWaitTime ?? this.estimatedWaitTime,
      playersInQueue: playersInQueue ?? this.playersInQueue,
      matchInfo: matchInfo ?? this.matchInfo,
      errorMessage: errorMessage,
    );
  }
}

/// 配對 Notifier
class MatchmakingNotifier extends StateNotifier<MatchmakingState> {
  final MatchmakingService _service;
  final Ref _ref;
  Timer? _waitingTimer;
  StreamSubscription? _matchSubscription;

  MatchmakingNotifier(this._service, this._ref) : super(const MatchmakingState()) {
    _setupListeners();
  }

  void _setupListeners() {
    // 監聽配對狀態更新
    _matchSubscription = _service.onMatchStatusUpdate.listen((data) {
      _handleMatchStatusUpdate(data);
    });
  }

  void _handleMatchStatusUpdate(Map<String, dynamic> data) {
    final statusStr = data['status'] as String?;
    final playersInQueue = data['players_in_queue'] as int? ?? 0;
    final estimatedWait = data['estimated_wait_time'] as int? ?? 30;

    if (statusStr == 'found') {
      // 配對成功
      final matchInfo = MatchInfo.fromJson(data);
      state = state.copyWith(
        status: MatchmakingStatus.found,
        matchInfo: matchInfo,
        playersInQueue: playersInQueue,
      );
      _stopWaitingTimer();
    } else if (statusStr == 'searching') {
      state = state.copyWith(
        playersInQueue: playersInQueue,
        estimatedWaitTime: estimatedWait,
      );
    } else if (statusStr == 'error') {
      state = state.copyWith(
        status: MatchmakingStatus.error,
        errorMessage: data['message'] as String?,
      );
      _stopWaitingTimer();
    }
  }

  /// 選擇遊戲模式
  void selectMode(GameMode mode) {
    if (!state.isSearching) {
      state = state.copyWith(selectedMode: mode);
    }
  }

  /// 開始配對
  Future<void> startMatchmaking(String playerName) async {
    if (state.isSearching) return;

    state = state.copyWith(
      status: MatchmakingStatus.searching,
      searchStartTime: DateTime.now(),
      waitingTime: 0,
      errorMessage: null,
    );

    _startWaitingTimer();

    try {
      await _service.joinQueue(
        playerName: playerName,
        mode: state.selectedMode,
      );
    } catch (e) {
      state = state.copyWith(
        status: MatchmakingStatus.error,
        errorMessage: e.toString(),
      );
      _stopWaitingTimer();
    }
  }

  /// 取消配對
  Future<void> cancelMatchmaking() async {
    if (!state.isSearching) return;

    _stopWaitingTimer();

    try {
      await _service.leaveQueue();
      state = state.copyWith(
        status: MatchmakingStatus.cancelled,
      );
    } catch (e) {
      state = state.copyWith(
        status: MatchmakingStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// 確認加入配對的房間
  Future<String?> confirmMatch() async {
    if (!state.isMatchFound || state.matchInfo == null) return null;

    state = state.copyWith(status: MatchmakingStatus.joining);

    try {
      final roomCode = state.matchInfo!.roomCode;
      // 重置狀態
      state = const MatchmakingState();
      return roomCode;
    } catch (e) {
      state = state.copyWith(
        status: MatchmakingStatus.error,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// 重置狀態
  void reset() {
    _stopWaitingTimer();
    state = const MatchmakingState();
  }

  void _startWaitingTimer() {
    _waitingTimer?.cancel();
    _waitingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isSearching) {
        state = state.copyWith(waitingTime: state.waitingTime + 1);
      }
    });
  }

  void _stopWaitingTimer() {
    _waitingTimer?.cancel();
    _waitingTimer = null;
  }

  @override
  void dispose() {
    _stopWaitingTimer();
    _matchSubscription?.cancel();
    super.dispose();
  }
}

// ===== Riverpod Providers =====

/// MatchmakingService Provider
final matchmakingServiceProvider = Provider<MatchmakingService>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return MatchmakingService(socketService);
});

/// Matchmaking Provider
final matchmakingProvider =
    StateNotifierProvider<MatchmakingNotifier, MatchmakingState>((ref) {
  final service = ref.watch(matchmakingServiceProvider);
  return MatchmakingNotifier(service, ref);
});

/// 配對狀態 Provider
final matchmakingStatusProvider = Provider<MatchmakingStatus>((ref) {
  return ref.watch(matchmakingProvider).status;
});

/// 是否正在搜尋 Provider
final isSearchingProvider = Provider<bool>((ref) {
  return ref.watch(matchmakingProvider).isSearching;
});

/// 等待時間 Provider
final waitingTimeProvider = Provider<int>((ref) {
  return ref.watch(matchmakingProvider).waitingTime;
});

/// 佇列玩家數 Provider
final playersInQueueProvider = Provider<int>((ref) {
  return ref.watch(matchmakingProvider).playersInQueue;
});
