import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../data/services/auth_service.dart';
import '../providers/socket_provider.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/lobby_screen.dart';
import '../presentation/screens/game_screen.dart';
import '../presentation/screens/join_room_screen.dart';
import '../presentation/pages/solo_mode_page.dart';
import '../presentation/pages/solo_game_setup_page.dart';
import '../presentation/pages/solo_game_page.dart';
import '../presentation/pages/solo_game_result_page.dart';

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
        path: '/join',
        name: 'join',
        builder: (context, state) => const JoinRoomScreen(),
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
      // 單人模式路由
      GoRoute(
        path: '/solo',
        name: 'solo',
        builder: (context, state) => const SoloModePage(),
      ),
      GoRoute(
        path: '/solo/setup',
        name: 'solo-setup',
        builder: (context, state) => const SoloGameSetupPage(),
      ),
      GoRoute(
        path: '/solo/game',
        name: 'solo-game',
        builder: (context, state) => const SoloGamePage(),
      ),
      GoRoute(
        path: '/solo/result',
        name: 'solo-result',
        builder: (context, state) => const SoloGameResultPage(),
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
class Parliament1812App extends ConsumerStatefulWidget {
  const Parliament1812App({super.key});

  @override
  ConsumerState<Parliament1812App> createState() => _Parliament1812AppState();
}

class _Parliament1812AppState extends ConsumerState<Parliament1812App> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 初始化認證服務（自動建立訪客帳號如果沒有登入）
      final authService = AuthService();
      await authService.initialize();

      // 嘗試連接伺服器（非阻塞，允許失敗）
      final socketService = ref.read(socketServiceProvider);
      // 使用 unawaited 或在背景執行，不阻塞初始化
      socketService.connect().then((connected) {
        if (!connected) {
          debugPrint('Initial connection failed, will retry automatically');
        }
      }).catchError((e) {
        debugPrint('Connection error: $e');
      });
    } catch (e) {
      debugPrint('Initialization error: $e');
    } finally {
      // 無論連接成功與否，都允許進入主畫面
      if (mounted) {
        setState(() => _initialized = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: '1812 國會風雲',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
      builder: (context, child) {
        if (!_initialized) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            home: const _SplashScreen(),
          );
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

/// 啟動畫面
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryDark, AppTheme.primaryMid],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.accent),
              SizedBox(height: 24),
              Text(
                '連接伺服器中...',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
