import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'l10n/app_localizations.dart';

import 'config/theme.dart';
import 'providers/locale_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/main_menu_screen.dart';
import 'screens/room_list_screen.dart';
import 'screens/room_screen.dart';
import 'screens/game_screen.dart';
import 'screens/game_result_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/codex/codex_screen.dart';
import 'screens/quests/daily_quests_screen.dart';
import 'screens/friends/friends_screen.dart';
import 'screens/rankings/leaderboard_screen.dart';
import 'screens/tutorial/tutorial_screen.dart';
import 'screens/campaign/campaign_screen.dart';
import 'screens/single_player/difficulty_select_screen.dart';
import 'screens/single_player/single_player_game_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'providers/game_provider.dart';

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
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot_password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/menu',
        name: 'menu',
        builder: (context, state) => const MainMenuScreen(),
      ),
      GoRoute(
        path: '/quests',
        name: 'quests',
        builder: (context, state) => const DailyQuestsScreen(),
      ),
      GoRoute(
        path: '/rankings',
        name: 'rankings',
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/codex',
        name: 'codex',
        builder: (context, state) => const CodexScreen(),
      ),
      GoRoute(
        path: '/friends',
        name: 'friends',
        builder: (context, state) => const FriendsScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/tutorial',
        name: 'tutorial',
        builder: (context, state) => TutorialScreen(
          onComplete: () => GoRouter.of(context).go('/menu'),
        ),
      ),
      GoRoute(
        path: '/campaign',
        name: 'campaign',
        builder: (context, state) => const CampaignScreen(),
      ),
      GoRoute(
        path: '/single-player/difficulty',
        name: 'difficulty_select',
        builder: (context, state) => const DifficultySelectScreen(),
      ),
      GoRoute(
        path: '/single-player/game',
        name: 'single_player_game',
        builder: (context, state) => const SinglePlayerGameScreen(),
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
      GoRoute(
        path: '/game/:code/result',
        name: 'game_result',
        builder: (context, state) {
          final code = state.pathParameters['code']!;
          // GameResult will be passed via ref.read(gameStateProvider)
          return Consumer(
            builder: (context, ref, _) {
              final gameState = ref.watch(gameStateProvider);
              if (gameState?.result == null) {
                // 如果沒有結果，返回房間
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.go('/room/$code');
                });
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return GameResultScreen(
                roomCode: code,
                gameResult: gameState!.result!,
              );
            },
          );
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
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Parliament 1812',
      theme: Parliament1812Theme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,

      // i18n 設定
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
    );
  }
}
