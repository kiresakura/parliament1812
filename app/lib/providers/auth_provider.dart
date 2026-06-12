import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  /// 同步 auth token 到 ApiService（供 rooms/single player/campaign 等使用）
  void _syncTokenToApiService() {
    final token = _authService.accessToken;
    ApiService().setAuthToken(token);
  }

  /// 嘗試自動登入
  Future<void> _tryAutoLogin() async {
    final hasTokens = _authService.hasStoredTokens;
    final loginMethod = _authService.getLoginMethod();

    if (!hasTokens && loginMethod == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    // 1. 先嘗試用已儲存的 token 自動登入
    if (hasTokens) {
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
            _syncTokenToApiService();
            return;
          }
        }
      } catch (e) {
        // Token 自動登入失敗，繼續嘗試 OAuth
      }
    }

    // 2. Token 失敗，嘗試用記憶的登入方式重新登入
    if (loginMethod == 'google') {
      try {
        final googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
          serverClientId:
              '1071586546991-0v65rkt7ud4jsp77jk121ta9prjvl6ti.apps.googleusercontent.com',
        );
        final account = await googleSignIn.signInSilently();
        if (account != null) {
          final auth = await account.authentication;
          final idToken = auth.idToken;
          if (idToken != null) {
            final result = await _authService.loginWithGoogle(idToken);
            if (result.success && result.data != null) {
              state = state.copyWith(
                isAuthenticated: true,
                isLoading: false,
                isGuest: false,
                user: result.data!.user,
                clearError: true,
              );
              _syncTokenToApiService();
              return;
            }
          }
        }
      } catch (e) {
        debugPrint('Google silent sign-in failed: $e');
      }
    }
    // Apple 和 password 無法在背景靜默登入，留給登入畫面處理

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
      _syncTokenToApiService();
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
      _syncTokenToApiService();
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
      _syncTokenToApiService();
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
      _syncTokenToApiService();
      return true;
    }

    state = state.copyWith(
      isLoading: false,
      error: result.error ?? 'Apple 登入失敗',
    );
    return false;
  }

  /// 更新個人檔案
  Future<bool> updateProfile({String? displayName, String? avatarUrl}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _authService.updateProfile(
      displayName: displayName,
      avatarUrl: avatarUrl,
    );

    if (result.success && result.data != null) {
      state = state.copyWith(
        isLoading: false,
        user: result.data,
        clearError: true,
      );
      _syncTokenToApiService();
      return true;
    }

    state = state.copyWith(
      isLoading: false,
      error: result.error ?? '更新個人檔案失敗',
    );
    return false;
  }

  // ============================================================
  // OAuth 帳號綁定
  // ============================================================

  /// 綁定 Google 帳號
  Future<bool> linkGoogleAccount(String idToken) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _authService.linkGoogle(idToken);

    if (result.success) {
      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    }

    state = state.copyWith(
      isLoading: false,
      error: result.error ?? 'Google 帳號綁定失敗',
    );
    return false;
  }

  /// 綁定 Apple 帳號
  Future<bool> linkAppleAccount(String identityToken) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _authService.linkApple(identityToken);

    if (result.success) {
      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    }

    state = state.copyWith(
      isLoading: false,
      error: result.error ?? 'Apple 帳號綁定失敗',
    );
    return false;
  }

  /// 解綁 OAuth 帳號
  Future<bool> unlinkAccount(String provider) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _authService.unlinkProvider(provider);

    if (result.success) {
      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    }

    state = state.copyWith(
      isLoading: false,
      error: result.error ?? '帳號解綁失敗',
    );
    return false;
  }

  /// 取得已綁定帳號列表
  Future<List<LinkedAccount>> fetchLinkedAccounts() async {
    final result = await _authService.getLinkedAccounts();

    if (result.success && result.data != null) {
      return result.data!;
    }

    return [];
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
