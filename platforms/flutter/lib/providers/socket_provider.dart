import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/socket_service.dart';
import '../data/services/game_service.dart';

/// Socket 連接狀態 Provider
final socketConnectionProvider = StateProvider<ConnectionState>((ref) {
  return ConnectionState.disconnected;
});

/// Socket 服務實例 Provider (單例)
final socketServiceProvider = Provider<SocketService>((ref) {
  final socketService = SocketService();

  // 監聽連接狀態變化並更新 Provider
  socketService.connectionStateStream.listen((state) {
    ref.read(socketConnectionProvider.notifier).state = state;
  });

  // 當 Provider 被銷毀時清理資源
  ref.onDispose(() {
    socketService.dispose();
  });

  return socketService;
});

/// 遊戲服務實例 Provider
final gameServiceProvider = Provider<GameService>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  final gameService = GameService(socketService);

  ref.onDispose(() {
    gameService.dispose();
  });

  return gameService;
});

/// Socket 錯誤訊息 Provider
final socketErrorProvider = StateProvider<String?>((ref) => null);

/// 是否已連接 Provider
final isSocketConnectedProvider = Provider<bool>((ref) {
  final state = ref.watch(socketConnectionProvider);
  return state == ConnectionState.connected;
});

/// 是否正在連接 Provider
final isSocketConnectingProvider = Provider<bool>((ref) {
  final state = ref.watch(socketConnectionProvider);
  return state == ConnectionState.connecting || state == ConnectionState.reconnecting;
});

/// 連接錯誤監聽器 Provider
final socketErrorListenerProvider = Provider<void>((ref) {
  final socketService = ref.watch(socketServiceProvider);

  socketService.errorStream.listen((error) {
    ref.read(socketErrorProvider.notifier).state = error;
  });
});
