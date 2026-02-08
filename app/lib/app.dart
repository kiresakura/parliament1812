import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'config/theme.dart';
import 'screens/splash_screen.dart';
import 'screens/main_menu_screen.dart';
import 'screens/room_list_screen.dart';
import 'screens/room_screen.dart';
import 'screens/game_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/menu',
        name: 'menu',
        builder: (context, state) => const MainMenuScreen(),
      ),
      GoRoute(
        path: '/rooms',
        name: 'rooms',
        builder: (context, state) => const RoomListScreen(),
      ),
      GoRoute(
        path: '/room/:code',
        name: 'room',
        builder: (context, state) {
          final code = state.pathParameters['code']!;
          return RoomScreen(roomCode: code);
        },
      ),
      GoRoute(
        path: '/game/:code',
        name: 'game',
        builder: (context, state) {
          final code = state.pathParameters['code']!;
          return GameScreen(roomCode: code);
        },
      ),
    ],
  );
});

class Parliament1812App extends ConsumerWidget {
  const Parliament1812App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Parliament 1812',
      theme: Parliament1812Theme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}