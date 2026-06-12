import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/websocket_service.dart';
import '../widgets/connection_indicator.dart';

/// WebSocket 服務提供者
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService();
});

/// 連線狀態提供者
final connectionStatusProvider = StreamProvider<ConnectionStatus>((ref) {
  final wsService = ref.watch(webSocketServiceProvider);
  
  return wsService.connectionStateStream.map((state) {
    switch (state) {
      case ConnectionState.connected:
        return ConnectionStatus.connected;
      case ConnectionState.connecting:
        return ConnectionStatus.connecting;
      case ConnectionState.disconnected:
        return ConnectionStatus.disconnected;
      case ConnectionState.error:
        return ConnectionStatus.error;
      case ConnectionState.reconnecting:
        return ConnectionStatus.connecting;
    }
  });
});

/// 連線延遲提供者（模擬）
final connectionLatencyProvider = StateProvider<int?>((ref) {
  final connectionStatus = ref.watch(connectionStatusProvider);
  
  return connectionStatus.when(
    data: (status) {
      if (status == ConnectionStatus.connected) {
        // TODO: 實際計算 ping 延遲
        return 45; // 模擬延遲
      }
      return null;
    },
    loading: () => null,
    error: (_, _) => null,
  );
});

/// WebSocket 錯誤訊息流提供者
final webSocketErrorProvider = StreamProvider<String>((ref) {
  final wsService = ref.watch(webSocketServiceProvider);
  return wsService.errorStream;
});

/// 連線管理器
class ConnectionManager extends StateNotifier<ConnectionManagerState> {
  final WebSocketService _wsService;

  ConnectionManager(this._wsService) : super(const ConnectionManagerState());

  /// 連接到 WebSocket
  Future<bool> connect({String? customUrl}) async {
    state = state.copyWith(isConnecting: true, lastError: null);
    
    try {
      final success = await _wsService.connect(customUrl: customUrl);
      state = state.copyWith(
        isConnecting: false,
        isConnected: success,
        lastError: success ? null : '連接失敗',
        lastConnectAttempt: DateTime.now(),
      );
      return success;
    } catch (e) {
      state = state.copyWith(
        isConnecting: false,
        isConnected: false,
        lastError: '連接失敗: $e',
        lastConnectAttempt: DateTime.now(),
      );
      return false;
    }
  }

  /// 斷開連接
  void disconnect() {
    _wsService.disconnect();
    state = state.copyWith(
      isConnected: false,
      lastError: null,
    );
  }

  /// 重新連接
  Future<bool> reconnect() async {
    if (state.isConnecting) return false;
    return connect();
  }

  /// 清除錯誤狀態
  void clearError() {
    state = state.copyWith(lastError: null);
  }
}

/// 連線管理器狀態
class ConnectionManagerState {
  final bool isConnecting;
  final bool isConnected;
  final String? lastError;
  final DateTime? lastConnectAttempt;

  const ConnectionManagerState({
    this.isConnecting = false,
    this.isConnected = false,
    this.lastError,
    this.lastConnectAttempt,
  });

  ConnectionManagerState copyWith({
    bool? isConnecting,
    bool? isConnected,
    String? lastError,
    DateTime? lastConnectAttempt,
  }) {
    return ConnectionManagerState(
      isConnecting: isConnecting ?? this.isConnecting,
      isConnected: isConnected ?? this.isConnected,
      lastError: lastError ?? this.lastError,
      lastConnectAttempt: lastConnectAttempt ?? this.lastConnectAttempt,
    );
  }
}

/// 連線管理器提供者
final connectionManagerProvider = StateNotifierProvider<ConnectionManager, ConnectionManagerState>((ref) {
  final wsService = ref.watch(webSocketServiceProvider);
  return ConnectionManager(wsService);
});

/// 自動連接提供者
final autoConnectProvider = Provider<void>((ref) {
  final connectionManager = ref.watch(connectionManagerProvider.notifier);

  // 監聽連線狀態，在需要時自動重連
  ref.listen(connectionStatusProvider, (previous, next) {
    next.when(
      data: (status) {
        if (status == ConnectionStatus.disconnected) {
          // 斷線時自動重連（可以加入重試邏輯）
          Future.delayed(const Duration(seconds: 3), () {
            connectionManager.reconnect();
          });
        }
      },
      loading: () {},
      error: (error, _) {
        // 連線錯誤時記錄
        // ignore: avoid_print
        debugPrint('Connection error: $error');
      },
    );
  });
});

/// WebSocket 訊息發送幫助類
class WebSocketMessageSender {
  final WebSocketService _wsService;

  WebSocketMessageSender(this._wsService);

  /// 發送訊息，檢查連線狀態
  bool sendMessage(ClientMessage message) {
    if (_wsService.connectionState != ConnectionState.connected) {
      debugPrint('Cannot send message: not connected');
      return false;
    }
    
    return _wsService.sendMessage(message);
  }

  /// 加入房間
  bool joinRoom(String roomCode, String playerName) {
    return sendMessage(ClientMessage.joinRoom(
      roomCode: roomCode,
      playerName: playerName,
    ));
  }

  /// 離開房間
  bool leaveRoom() {
    return sendMessage(const ClientMessage.leaveRoom());
  }

  /// 準備/取消準備
  bool toggleReady(bool isReady) {
    return isReady 
        ? sendMessage(const ClientMessage.ready())
        : sendMessage(const ClientMessage.unready());
  }

  /// 開始遊戲
  bool startGame() {
    return sendMessage(const ClientMessage.startGame());
  }

  /// 發送聊天訊息
  bool sendChatMessage(String content) {
    return sendMessage(ClientMessage.sendChat(content: content));
  }

  /// 發送私訊
  bool sendPrivateMessage(String targetId, String content) {
    return sendMessage(ClientMessage.sendPrivateChat(
      targetId: targetId,
      content: content,
    ));
  }
}

/// WebSocket 訊息發送器提供者
final webSocketSenderProvider = Provider<WebSocketMessageSender>((ref) {
  final wsService = ref.watch(webSocketServiceProvider);
  return WebSocketMessageSender(wsService);
});