import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/vote.dart';
import '../models/event.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../utils/constants.dart' hide VoteOption;

/// 遊戲狀態管理
class GameProvider with ChangeNotifier {
  final _api = ApiService();
  final _ws = WebSocketService();

  // 遊戲階段相關
  int _currentPhase = 1;
  String _phaseName = '等待中';

  // 投票相關
  List<VoteOption> _voteOptions = [];
  Vote? _myVote;
  Round1Result? _round1Result;
  Round2Result? _round2Result;
  double _voteProgress = 0;
  Map<String, int> _voteResults = {};

  // 事件相關
  List<GameEvent> _availableEvents = [];
  List<TriggeredEvent> _eventHistory = [];
  TriggeredEvent? _currentEvent;

  // 計時器
  DateTime? _timerEndAt;
  Timer? _timerUpdateTimer;

  // 載入狀態
  bool _isLoading = false;
  String? _error;

  // 房間與玩家資訊（用於 API 調用）
  String? _roomCode;
  String? _playerId;
  bool _isHost = false;

  // Getter for isHost
  bool get isHost => _isHost;

  // Getters
  int get currentPhase => _currentPhase;
  String get phaseName => _phaseName;

  List<VoteOption> get voteOptions => _voteOptions;
  Vote? get myVote => _myVote;
  Round1Result? get round1Result => _round1Result;
  Round2Result? get round2Result => _round2Result;
  double get voteProgress => _voteProgress;
  Map<String, int> get voteResults => _voteResults;

  List<GameEvent> get availableEvents => _availableEvents;
  List<TriggeredEvent> get eventHistory => _eventHistory;
  TriggeredEvent? get currentEvent => _currentEvent;

  DateTime? get timerEndAt => _timerEndAt;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 取得剩餘時間（秒）
  int get remainingSeconds {
    if (_timerEndAt == null) return 0;
    final diff = _timerEndAt!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  /// 初始化遊戲監聽
  void initGameListeners() {
    _ws.eventStream.listen(_handleWSEvent);
  }

  /// 處理 WebSocket 事件
  void _handleWSEvent(WSEvent event) {
    switch (event.type) {
      case WSEventType.voteUpdate:
        _onVoteUpdate(event.data);
        break;
      case WSEventType.voteResult:
        _onVoteResult(event.data);
        break;
      case WSEventType.eventTrigger:
        _onEventTrigger(event.data);
        break;
      case WSEventType.timerSync:
      case WSEventType.timerStart:
        _onTimerSync(event.data);
        break;
      case WSEventType.timerStop:
        _onTimerStop();
        break;
      default:
        break;
    }
  }

  // ==================== 投票功能 ====================

  /// 載入投票選項
  Future<void> loadVoteOptions(String roomCode) async {
    try {
      _voteOptions = await _api.getVoteOptions(roomCode);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// 投票
  Future<bool> castVote({
    required String roomCode,
    required String playerId,
    required int round,
    required String choice,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _myVote = await _api.castVote(
        roomCode: roomCode,
        playerId: playerId,
        round: round,
        choice: choice,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 載入投票進度
  Future<void> loadVoteProgress({
    required String roomCode,
    required int round,
  }) async {
    try {
      final progress = await _api.getVoteProgress(
        roomCode: roomCode,
        round: round,
      );
      _voteProgress = (progress['progress'] as num).toDouble();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// 載入投票結果
  Future<void> loadVoteResult({
    required String roomCode,
    required int round,
  }) async {
    try {
      final result = await _api.getVoteResult(
        roomCode: roomCode,
        round: round,
      );

      if (round == 1) {
        _round1Result = result as Round1Result;
      } else {
        _round2Result = result as Round2Result;
      }
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  void _onVoteUpdate(Map<String, dynamic> data) {
    _voteProgress = (data['progress'] as num).toDouble();
    notifyListeners();
  }

  void _onVoteResult(Map<String, dynamic> data) {
    final round = data['round'] as int;
    if (round == 1) {
      _round1Result = Round1Result.fromJson(data);
    } else {
      _round2Result = Round2Result.fromJson(data);
    }
    notifyListeners();
  }

  // ==================== 事件功能 ====================

  /// 載入可用事件（僅主持人）
  Future<void> loadAvailableEvents({
    required String roomCode,
    required String hostId,
  }) async {
    try {
      _availableEvents = await _api.getAvailableEvents(
        roomCode: roomCode,
        hostId: hostId,
      );
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// 觸發事件（僅主持人）
  Future<bool> triggerEvent({
    required String roomCode,
    required String hostId,
    required String eventId,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final triggered = await _api.triggerEvent(
        roomCode: roomCode,
        hostId: hostId,
        eventId: eventId,
      );
      _currentEvent = triggered;
      _eventHistory.add(triggered);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 隨機觸發事件（僅主持人）
  Future<bool> randomTriggerEvent({
    required String roomCode,
    required String hostId,
    int? minSeverity,
    int? maxSeverity,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final triggered = await _api.randomTriggerEvent(
        roomCode: roomCode,
        hostId: hostId,
        minSeverity: minSeverity,
        maxSeverity: maxSeverity,
      );
      _currentEvent = triggered;
      _eventHistory.add(triggered);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 載入事件歷史
  Future<void> loadEventHistory(String roomCode) async {
    try {
      _eventHistory = await _api.getEventHistory(roomCode);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  void _onEventTrigger(Map<String, dynamic> data) {
    _currentEvent = TriggeredEvent.fromJson(data);
    notifyListeners();
  }

  /// 清除當前事件
  void clearCurrentEvent() {
    _currentEvent = null;
    notifyListeners();
  }

  // ==================== 主持人控制功能 ====================

  /// 設置房間資訊
  void setRoomInfo({
    required String roomCode,
    required String playerId,
    required bool isHost,
  }) {
    _roomCode = roomCode;
    _playerId = playerId;
    _isHost = isHost;
  }

  /// 切換遊戲階段（僅主持人）
  Future<bool> changePhase(int phase) async {
    if (_roomCode == null || _playerId == null) return false;

    _setLoading(true);
    _clearError();

    try {
      await _api.changePhase(
        roomCode: _roomCode!,
        hostId: _playerId!,
        phase: phase,
      );
      _currentPhase = phase;
      _phaseName = _getPhaseName(phase);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 開始計時器（僅主持人）
  Future<bool> startTimer(int minutes) async {
    if (_roomCode == null || _playerId == null) return false;

    _setLoading(true);
    _clearError();

    try {
      final endAt = await _api.startTimer(
        roomCode: _roomCode!,
        hostId: _playerId!,
        minutes: minutes,
      );
      _timerEndAt = endAt;
      _startTimerUpdate();
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 停止計時器（僅主持人）
  Future<bool> stopTimer() async {
    if (_roomCode == null || _playerId == null) return false;

    _setLoading(true);
    _clearError();

    try {
      await _api.stopTimer(
        roomCode: _roomCode!,
        hostId: _playerId!,
      );
      _timerEndAt = null;
      _stopTimerUpdate();
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 隨機觸發事件（僅主持人）- 快捷方法
  Future<bool> triggerRandomEvent() async {
    if (_roomCode == null || _playerId == null) return false;

    return randomTriggerEvent(
      roomCode: _roomCode!,
      hostId: _playerId!,
    );
  }

  /// 開始投票（僅主持人）
  Future<bool> startVoting(int round) async {
    if (_roomCode == null || _playerId == null) return false;

    _setLoading(true);
    _clearError();

    try {
      await _api.startVoting(
        roomCode: _roomCode!,
        hostId: _playerId!,
        round: round,
      );
      // 切換到對應的投票階段
      if (round == 1) {
        _currentPhase = 8;
        _phaseName = '第一輪投票';
      } else {
        _currentPhase = 10;
        _phaseName = '第二輪投票';
      }
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 更新階段資訊（來自 WebSocket）
  void updatePhase(int phase, String phaseName) {
    _currentPhase = phase;
    _phaseName = phaseName;
    notifyListeners();
  }

  /// 獲取階段名稱
  String _getPhaseName(int phase) {
    if (phase < 0 || phase >= GamePhase.values.length) {
      return '未知';
    }
    return GamePhase.values[phase].name;
  }

  // ==================== 計時器功能 ====================

  void _onTimerSync(Map<String, dynamic> data) {
    if (data['end_at'] != null) {
      _timerEndAt = DateTime.parse(data['end_at']);
      _startTimerUpdate();
      notifyListeners();
    }
  }

  void _onTimerStop() {
    _timerEndAt = null;
    _stopTimerUpdate();
    notifyListeners();
  }

  void _startTimerUpdate() {
    _stopTimerUpdate();
    _timerUpdateTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => notifyListeners(),
    );
  }

  void _stopTimerUpdate() {
    _timerUpdateTimer?.cancel();
    _timerUpdateTimer = null;
  }

  // ==================== 通用功能 ====================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// 重置遊戲狀態
  void resetGame() {
    _currentPhase = 1;
    _phaseName = '等待中';
    _voteOptions = [];
    _myVote = null;
    _round1Result = null;
    _round2Result = null;
    _voteProgress = 0;
    _voteResults = {};
    _availableEvents = [];
    _eventHistory = [];
    _currentEvent = null;
    _timerEndAt = null;
    _roomCode = null;
    _playerId = null;
    _isHost = false;
    _stopTimerUpdate();
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTimerUpdate();
    super.dispose();
  }
}
