import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../config/constants.dart';

/// 認證狀態
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final bool isGuest;
  final AuthUser? user;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.isGuest = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    bool? isGuest,
    AuthUser? user,
    String? error,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      isGuest: isGuest ?? this.isGuest,
      user: clearUser ? null : (user ?? this.user),
      error: clearError ? null : (error ?? this.error),
    );
  }

  // 向後兼容
  String? get playerId => user?.id;
  String? get playerName => user?.displayName ?? user?.username;
  String? get token => null; // 由 AuthService 管理
}

/// 認證狀態通知器
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final SharedPreferences _prefs;

  AuthNotifier(this._authService, this._prefs) : super(const AuthState()) {
    _tryAutoLogin();
  }

  /// 嘗試自動登入
  Future<void> _tryAutoLogin() async {
    if (!_authService.hasStoredTokens) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final success = await _authService.tryAutoLogin();
      if (success) {
        final meResult = await _authService.getMe();
        if (meResult.success && meResult.data != null) {
          state = state.copyWith(
            isAuthenticated: true,
            isLoading: false,
            user: meResult.data,
            clearError: true,
          );
          return;
        }
      }
    } catch (e) {
      // 自動登入失敗，靜默處理
    }

    state = state.copyWith(isLoading: false);
  }

  /// Email + Password 登入
  Future<bool> loginWithEmailPassword({
    required String emailOrUsername,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _authService.login(
      emailOrUsername: emailOrUsername,
      password: password,
    );

    if (result.success && result.data != null) {
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        isGuest: false,
        user: result.data!.user,
        clearError: true,
      );
      return true;
    }

    state = state.copyWith(
      isLoading: false,
      error: result.error ?? '登入失敗',
    );
    return false;
  }

  /// 註冊
  Future<bool> registerAccount({
    required String username,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _authService.register(
      username: username,
      email: email,
      password: password,
    );

    if (result.success && result.data != null) {
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        isGuest: false,
        user: result.data!.user,
        clearError: true,
      );
      return true;
    }

    state = state.copyWith(
      isLoading: false,
      error: result.error ?? '註冊失敗',
    );
    return false;
  }

  /// Google OAuth 登入
  Future<bool> loginWithGoogleToken(String idToken) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _authService.loginWithGoogle(idToken);

    if (result.success && result.data != null) {
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        isGuest: false,
        user: result.data!.user,
        clearError: true,
      );
      return true;
    }

    state = state.copyWith(
      isLoading: false,
      error: result.error ?? 'Google 登入失敗',
    );
    return false;
  }

  /// Apple Sign-In 登入
  Future<bool> loginWithAppleToken(String identityToken,
      {String? displayName}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _authService.loginWithApple(
      identityToken: identityToken,
      displayName: displayName,
    );

    if (result.success && result.data != null) {
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        isGuest: false,
        user: result.data!.user,
        clearError: true,
      );
      return true;
    }

    state = state.copyWith(
      isLoading: false,
      error: result.error ?? 'Apple 登入失敗',
    );
    return false;
  }

  /// 忘記密碼
  Future<bool> forgotPassword(String email) async {
    final result = await _authService.forgotPassword(email);
    return result.success;
  }

  /// 登出
  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState();
  }

  /// 清除錯誤
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// 向後兼容：簡單玩家名稱認證
  Future<bool> authenticate(String playerName, {bool silent = false}) async {
    if (playerName.trim().isEmpty) {
      state = state.copyWith(error: '請輸入玩家名稱');
      return false;
    }
    // 在 guest 模式下，只設定名稱，不走後端
    state = state.copyWith(
      isAuthenticated: false,
      isGuest: true,
      clearError: true,
    );
    await _prefs.setString(AppConstants.playerNameKey, playerName);
    return true;
  }

  /// 檢查認證狀態
  bool checkAuthStatus() {
    return state.isAuthenticated;
  }
}

/// SharedPreferences 提供者
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden');
});

/// AuthService 提供者
final authServiceProvider = Provider<AuthService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthService(prefs);
});

/// API 服務提供者（向後兼容，供 room_provider 等使用）
final apiServiceProvider = Provider<ApiService>((ref) {
  final apiService = ApiService();
  apiService.init();
  return apiService;
});

/// 認證狀態提供者
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthNotifier(authService, prefs);
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
    final notificationsEnabled =
        _prefs.getBool(AppConstants.notificationsEnabledKey) ?? true;
    final preferredCharacter =
        _prefs.getString(AppConstants.preferredCharacterKey);

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
final playerPreferencesProvider =
    StateNotifierProvider<PlayerPreferencesNotifier, PlayerPreferences>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PlayerPreferencesNotifier(prefs);
});

/// 認證守衛 - 檢查是否需要登入
final authGuardProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);

  // 如果正在載入、已認證或 guest 模式，則通過
  if (authState.isLoading || authState.isAuthenticated || authState.isGuest) {
    return true;
  }

  // 需要登入
  return false;
});
