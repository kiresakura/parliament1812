import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/constants/api_constants.dart';
import '../../providers/matchmaking_provider.dart';
import 'socket_service.dart';

/// 配對服務
class MatchmakingService {
  final SocketService _socketService;

  // 事件流控制器
  final _matchStatusController = StreamController<Map<String, dynamic>>.broadcast();

  // 事件流
  Stream<Map<String, dynamic>> get onMatchStatusUpdate => _matchStatusController.stream;

  MatchmakingService(this._socketService) {
    _setupListeners();
  }

  void _setupListeners() {
    // 監聽配對相關訊息
    _socketService.on('matchmaking_status', (data) {
      debugPrint('Matchmaking status: $data');
      if (data is Map<String, dynamic>) {
        _matchStatusController.add(data);
      }
    });

    _socketService.on('match_found', (data) {
      debugPrint('Match found: $data');
      if (data is Map<String, dynamic>) {
        _matchStatusController.add({...data, 'status': 'found'});
      }
    });

    _socketService.on('queue_update', (data) {
      debugPrint('Queue update: $data');
      if (data is Map<String, dynamic>) {
        _matchStatusController.add({...data, 'status': 'searching'});
      }
    });

    _socketService.on('matchmaking_error', (data) {
      debugPrint('Matchmaking error: $data');
      if (data is Map<String, dynamic>) {
        _matchStatusController.add({...data, 'status': 'error'});
      }
    });
  }

  /// 加入配對佇列
  Future<void> joinQueue({
    required String playerName,
    required GameMode mode,
  }) async {
    // 確保已連線
    if (!_socketService.isConnected) {
      final connected = await _socketService.connect();
      if (!connected) {
        throw Exception('無法連接到伺服器');
      }
    }

    // 透過 WebSocket 發送加入佇列請求
    _socketService.send({
      'type': 'join_matchmaking',
      'player_name': playerName,
      'mode': mode.name,
    });
  }

  /// 離開配對佇列
  Future<void> leaveQueue() async {
    _socketService.send({
      'type': 'leave_matchmaking',
    });
  }

  /// 取得佇列狀態（HTTP API）
  Future<Map<String, dynamic>?> getQueueStatus(GameMode mode) async {
    try {
      final url = '${ApiConstants.baseUrl}/api/matchmaking/status?mode=${mode.name}';
      debugPrint('Getting queue status: $url');

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);

      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      client.close();

      if (response.statusCode == 200) {
        return json.decode(body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Get queue status error: $e');
      return null;
    }
  }

  /// 清理資源
  void dispose() {
    _matchStatusController.close();
  }
}
