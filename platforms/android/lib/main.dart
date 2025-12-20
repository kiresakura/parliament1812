import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'config/theme.dart';
import 'providers/room_provider.dart';
import 'providers/player_provider.dart';
import 'providers/game_provider.dart';
import 'providers/message_provider.dart';
import 'providers/accessibility_provider.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 創建 Provider，延遲初始化（完全非阻塞啟動）
  final accessibilityProvider = AccessibilityProvider();

  // 先啟動 App，然後在背景初始化設定
  runApp(Parliament1812App(accessibilityProvider: accessibilityProvider));

  // 背景初始化，不阻塞 UI
  _initializeInBackground(accessibilityProvider);
}

/// 背景初始化，失敗也不影響 App 運行
Future<void> _initializeInBackground(AccessibilityProvider provider) async {
  try {
    await provider.init().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        // 超時使用預設值，這是正常行為
        debugPrint('AccessibilityProvider: 使用預設設定 (載入超時)');
      },
    );
  } catch (e) {
    // 錯誤時使用預設值
    debugPrint('AccessibilityProvider: 使用預設設定 (錯誤: $e)');
  }
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
