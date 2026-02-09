import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'providers/auth_provider.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  
  // 建立 AuthService
  final authService = AuthService(sharedPreferences);

  runApp(
    ProviderScope(
      overrides: [
        // 提供 SharedPreferences 實例
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        // 提供 AuthService 實例
        authServiceProvider.overrideWithValue(authService),
      ],
      child: const Parliament1812App(),
    ),
  );
}
