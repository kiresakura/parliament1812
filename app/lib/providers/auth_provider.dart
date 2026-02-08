import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../config/constants.dart';

/// 認證狀態
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final AuthInfo? authInfo;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.authInfo,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    AuthInfo? authInfo,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      authInfo: authInfo ?? this.authInfo,
      error: error ?? this.error,
    );
  }

  String? get playerId => authInfo?.playerId;
  String? get playerName => authInfo?.playerName;
  String? get token => authInfo?.token;
}

/// 認證狀態通知器
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final SharedPreferences _prefs;

  AuthNotifier(this._apiService, this._prefs) : super(const AuthState()) {
    _loadSavedAuth();
  }

  /// 載入已保存的認證資訊
  Future<void> _loadSavedAuth() async {
    try {
      final playerName = _prefs.getString(AppConstants.playerNameKey);
      final playerId = _prefs.getString(AppConstants.playerIdKey);
      
      if (playerName != null && playerId != null) {
        // 嘗試自動登入
        await authenticate(playerName, silent: true);
      }
    } catch (e) {
      print('Failed to load saved auth: $e');
    }
  }

  /// 認證（登入）
  Future<bool> authenticate(String playerName, {bool silent = false}) async {
    if (playerName.trim().isEmpty) {
      state = state.copyWith(error: '請輸入玩家名稱');
      return false;
    }

    if (!silent) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final result = await _apiService.authenticate(playerName);
      
      if (result.success && result.data != null) {
        final authInfo = result.data!;
        
        // 檢查 token 是否過期
        if (authInfo.isExpired) {
          state = state.copyWith(
            isLoading: false,
            error: '認證已過期，請重新登入',
          );
          await logout();
          return false;
        }

        // 保存認證資訊
        await _saveAuthInfo(authInfo);
        
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          authInfo: authInfo,
          error: null,
        );
        
        return true;
      } else {
        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
          error: result.error ?? '認證失敗',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        error: '認證失敗: $e',
      );
      return false;
    }
  }

  /// 登出
  Future<void> logout() async {
    try {
      // 清除保存的認證資訊
      await _prefs.remove(AppConstants.playerNameKey);
      await _prefs.remove(AppConstants.playerIdKey);
      
      // 清除 API 服務的 token
      _apiService.setAuthToken(null);
      
      state = const AuthState();
    } catch (e) {
      print('Failed to logout: $e');
    }
  }

  /// 更新玩家名稱
  Future<bool> updatePlayerName(String newName) async {
    if (newName.trim().isEmpty) {
      state = state.copyWith(error: '玩家名稱不能為空');
      return false;
    }

    // 使用新名稱重新認證
    return authenticate(newName);
  }

  /// 檢查認證狀態
  bool checkAuthStatus() {
    final authInfo = state.authInfo;
    if (authInfo == null) return false;
    
    if (authInfo.isExpired) {
      // Token 已過期，需要重新登入
      logout();
      return false;
    }
    
    return state.isAuthenticated;
  }

  /// 清除錯誤
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 保存認證資訊到本地
  Future<void> _saveAuthInfo(AuthInfo authInfo) async {
    await _prefs.setString(AppConstants.playerNameKey, authInfo.playerName);
    await _prefs.setString(AppConstants.playerIdKey, authInfo.playerId);
    
    // 設定 API 服務的 token
    _apiService.setAuthToken(authInfo.token);
  }
}

/// SharedPreferences 提供者
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden');
});

/// API 服務提供者
final apiServiceProvider = Provider<ApiService>((ref) {
  final apiService = ApiService();
  apiService.init();
  return apiService;
});

/// 認證狀態提供者
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthNotifier(apiService, prefs);
});

/// 便捷提供者：是否已登入
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

/// 便捷提供者：當前玩家名稱
final currentPlayerNameProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).playerName;
});

/// 便捷提供者：當前玩家 ID
final currentPlayerIdProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).playerId;
});

/// 玩家偏好設定管理器
class PlayerPreferencesNotifier extends StateNotifier<PlayerPreferences> {
  final SharedPreferences _prefs;

  PlayerPreferencesNotifier(this._prefs) : super(PlayerPreferences()) {
    _loadPreferences();
  }

  void _loadPreferences() {
    final soundEnabled = _prefs.getBool(AppConstants.soundEnabledKey) ?? true;
    final notificationsEnabled = _prefs.getBool(AppConstants.notificationsEnabledKey) ?? true;
    final preferredCharacter = _prefs.getString(AppConstants.preferredCharacterKey);

    state = PlayerPreferences(
      soundEnabled: soundEnabled,
      notificationsEnabled: notificationsEnabled,
      preferredCharacter: preferredCharacter,
    );
  }

  Future<void> setSoundEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.soundEnabledKey, enabled);
    state = state.copyWith(soundEnabled: enabled);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.notificationsEnabledKey, enabled);
    state = state.copyWith(notificationsEnabled: enabled);
  }

  Future<void> setPreferredCharacter(String? character) async {
    if (character != null) {
      await _prefs.setString(AppConstants.preferredCharacterKey, character);
    } else {
      await _prefs.remove(AppConstants.preferredCharacterKey);
    }
    state = state.copyWith(preferredCharacter: character);
  }
}

/// 玩家偏好設定
class PlayerPreferences {
  final bool soundEnabled;
  final bool notificationsEnabled;
  final String? preferredCharacter;

  const PlayerPreferences({
    this.soundEnabled = true,
    this.notificationsEnabled = true,
    this.preferredCharacter,
  });

  PlayerPreferences copyWith({
    bool? soundEnabled,
    bool? notificationsEnabled,
    String? preferredCharacter,
  }) {
    return PlayerPreferences(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      preferredCharacter: preferredCharacter ?? this.preferredCharacter,
    );
  }
}

/// 玩家偏好設定提供者
final playerPreferencesProvider = StateNotifierProvider<PlayerPreferencesNotifier, PlayerPreferences>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PlayerPreferencesNotifier(prefs);
});

/// 認證守衛 - 檢查是否需要登入
final authGuardProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  
  // 如果正在載入或已認證，則通過
  if (authState.isLoading || authState.isAuthenticated) {
    return true;
  }
  
  // 需要登入
  return false;
});