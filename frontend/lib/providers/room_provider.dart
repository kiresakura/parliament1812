import 'package:flutter/foundation.dart';
import '../models/room.dart';
import '../models/player.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

/// 房間狀態管理
class RoomProvider with ChangeNotifier {
  final _api = ApiService();
  final _ws = WebSocketService();

  Room? _room;
  List<Player> _players = [];
  bool _isLoading = false;
  String? _error;

  Room? get room => _room;
  List<Player> get players => _players;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isInRoom => _room != null;
  String? get roomCode => _room?.code;

  /// 建立房間
  Future<Room?> createRoom(String hostNickname) async {
    _setLoading(true);
    _clearError();

    try {
      _room = await _api.createRoom(hostNickname: hostNickname);
      notifyListeners();
      return _room;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// 加入房間
  Future<Player?> joinRoom(String roomCode, String nickname) async {
    _setLoading(true);
    _clearError();

    try {
      final player = await _api.joinRoom(
        roomCode: roomCode,
        nickname: nickname,
      );

      _room = await _api.getRoom(roomCode);
      await loadPlayers();

      notifyListeners();
      return player;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// 取得房間資訊
  Future<void> loadRoom(String roomCode) async {
    _setLoading(true);
    _clearError();

    try {
      _room = await _api.getRoom(roomCode);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// 載入玩家列表
  Future<void> loadPlayers() async {
    if (_room == null) return;

    try {
      _players = await _api.getRoomPlayers(_room!.code);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// 連接 WebSocket
  Future<void> connectWebSocket(String playerId) async {
    if (_room == null) return;

    await _ws.connect(
      roomCode: _room!.code,
      playerId: playerId,
    );

    // 監聽 WebSocket 事件
    _ws.eventStream.listen(_handleWSEvent);
  }

  /// 斷開 WebSocket
  void disconnectWebSocket() {
    _ws.disconnect();
  }

  /// 處理 WebSocket 事件
  void _handleWSEvent(WSEvent event) {
    switch (event.type) {
      case WSEventType.playerJoin:
        _onPlayerJoin(event.data);
        break;
      case WSEventType.playerLeave:
        _onPlayerLeave(event.data);
        break;
      case WSEventType.phaseChange:
        _onPhaseChange(event.data);
        break;
      case WSEventType.timerSync:
        _onTimerSync(event.data);
        break;
      default:
        break;
    }
  }

  void _onPlayerJoin(Map<String, dynamic> data) {
    final player = Player.fromJson(data['player']);
    if (!_players.any((p) => p.id == player.id)) {
      _players.add(player);
      notifyListeners();
    }
  }

  void _onPlayerLeave(Map<String, dynamic> data) {
    final playerId = data['player_id'] as String;
    _players.removeWhere((p) => p.id == playerId);
    notifyListeners();
  }

  void _onPhaseChange(Map<String, dynamic> data) {
    if (_room != null) {
      _room = Room(
        id: _room!.id,
        code: _room!.code,
        status: _room!.status,
        phase: data['phase'] as int,
        phaseName: data['phase_name'] as String,
        currentRound: _room!.currentRound,
        timerEndAt: _room!.timerEndAt,
        playerCount: _room!.playerCount,
        createdAt: _room!.createdAt,
      );
      notifyListeners();
    }
  }

  void _onTimerSync(Map<String, dynamic> data) {
    if (_room != null && data['end_at'] != null) {
      _room = Room(
        id: _room!.id,
        code: _room!.code,
        status: _room!.status,
        phase: _room!.phase,
        phaseName: _room!.phaseName,
        currentRound: _room!.currentRound,
        timerEndAt: DateTime.parse(data['end_at']),
        playerCount: _room!.playerCount,
        createdAt: _room!.createdAt,
      );
      notifyListeners();
    }
  }

  /// 離開房間
  void leaveRoom() {
    disconnectWebSocket();
    _room = null;
    _players = [];
    notifyListeners();
  }

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
}
