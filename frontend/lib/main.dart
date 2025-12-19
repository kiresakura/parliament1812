import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'config/theme.dart';
import 'providers/room_provider.dart';
import 'providers/player_provider.dart';
import 'providers/game_provider.dart';
import 'providers/message_provider.dart';
import 'providers/accessibility_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化無障礙設定
  final accessibilityProvider = AccessibilityProvider();
  await accessibilityProvider.init();

  runApp(Parliament1812App(accessibilityProvider: accessibilityProvider));
}

class Parliament1812App extends StatelessWidget {
  final AccessibilityProvider accessibilityProvider;

  const Parliament1812App({
    super.key,
    required this.accessibilityProvider,
  });

  /// 建立帶有 iOS 頁面轉場效果的主題
  ThemeData _buildTheme(ThemeData baseTheme) {
    return baseTheme.copyWith(
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          // iOS 使用 Cupertino 風格滑動返回
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          // Android 保持原有 Material 風格
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          // 其他平台
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RoomProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider.value(value: accessibilityProvider),
      ],
      child: Consumer<AccessibilityProvider>(
        builder: (context, accessibility, child) {
          return MaterialApp(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(AppTheme.lightTheme),
            darkTheme: _buildTheme(AppTheme.darkTheme),
            themeMode: ThemeMode.dark,
            builder: (context, child) {
              // 應用字體縮放
              final mediaQuery = MediaQuery.of(context);
              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: TextScaler.linear(accessibility.fontScale),
                ),
                child: child!,
              );
            },
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
