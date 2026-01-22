import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/lobby_screen.dart';
import '../presentation/screens/game_screen.dart';

/// 路由配置
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/lobby/:roomId',
        name: 'lobby',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          return LobbyScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/game/:roomId',
        name: 'game',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          return GameScreen(roomId: roomId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('頁面不存在: ${state.uri.path}'),
      ),
    ),
  );
});

/// 主應用程式
class Parliament1812App extends ConsumerWidget {
  const Parliament1812App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: '1812 國會風雲',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
