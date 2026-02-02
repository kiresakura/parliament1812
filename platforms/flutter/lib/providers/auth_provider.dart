import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/auth_service.dart';
import '../domain/models/user_account.dart';

/// 認證狀態
enum AuthStatus {
  initial,      // 初始狀態
  loading,      // 載入中
  authenticated, // 已登入
  unauthenticated, // 未登入
  error,        // 錯誤
}

/// 認證狀態模型
class AuthState {
  final AuthStatus status;
  final UserAccount? user;
  final String? accessToken;
  final String? errorMessage;
  final AuthErrorType? errorType;
  final bool isLinking; // 是否正在綁定帳號

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.accessToken,
    this.errorMessage,
    this.errorType,
    this.isLinking = false,
  });

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isGuest => user?.isGuest ?? true;

  AuthState copyWith({
    AuthStatus? status,
    UserAccount? user,
    String? accessToken,
    String? errorMessage,
    AuthErrorType? errorType,
    bool? isLinking,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      errorMessage: errorMessage ?? this.errorMessage,
      errorType: errorType ?? this.errorType,
      isLinking: isLinking ?? this.isLinking,
    );
  }

  /// 載入中狀態
  factory AuthState.loading() {
    return const AuthState(status: AuthStatus.loading);
  }

  /// 已登入狀態
  factory AuthState.authenticated({
    required UserAccount user,
    required String accessToken,
  }) {
    return AuthState(
      status: AuthStatus.authenticated,
      user: user,
      accessToken: accessToken,
    );
  }

  /// 未登入狀態
  factory AuthState.unauthenticated() {
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  /// 錯誤狀態
  factory AuthState.error({
    required String message,
    AuthErrorType? errorType,
  }) {
    return AuthState(
      status: AuthStatus.error,
      errorMessage: message,
      errorType: errorType,
    );
  }

  @override
  String toString() {
    return 'AuthState(status: $status, user: ${user?.effectiveDisplayName}, '
        'isGuest: $isGuest, error: $errorMessage)';
  }
}

/// 認證 Provider
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState());

  /// 初始化 - 自動登入
  Future<void> initialize() async {
    debugPrint('AuthNotifier: 初始化...');
    state = AuthState.loading();

    final result = await _authService.initialize();

    if (result.success && result.user != null) {
      state = AuthState.authenticated(
        user: result.user!,
        accessToken: result.accessToken!,
      );
      debugPrint('AuthNotifier: 自動登入成功');
    } else {
      state = AuthState.unauthenticated();
      debugPrint('AuthNotifier: 沒有已存的登入狀態');
    }
  }

  /// Google 登入
  Future<bool> signInWithGoogle() async {
    return _signIn(() => _authService.signInWithGoogle());
  }

  /// Apple 登入
  Future<bool> signInWithApple() async {
    return _signIn(() => _authService.signInWithApple());
  }

  /// Discord 登入
  Future<bool> signInWithDiscord() async {
    return _signIn(() => _authService.signInWithDiscord());
  }

  /// 訪客登入
  Future<bool> signInAsGuest() async {
    return _signIn(() => _authService.signInAsGuest());
  }

  /// 登出
  Future<void> signOut() async {
    debugPrint('AuthNotifier: 登出...');
    state = AuthState.loading();

    await _authService.signOut();

    state = AuthState.unauthenticated();
    debugPrint('AuthNotifier: 登出完成');
  }

  /// 綁定社群帳號（訪客升級）
  Future<bool> linkAccount(AuthProvider provider) async {
    if (!state.isAuthenticated || !state.isGuest) {
      debugPrint('AuthNotifier: 無法綁定帳號 - 未登入或不是訪客');
      return false;
    }

    debugPrint('AuthNotifier: 開始綁定 ${provider.displayName}...');
    state = state.copyWith(isLinking: true);

    final result = await _authService.linkAccount(provider);

    if (result.success && result.user != null) {
      state = AuthState.authenticated(
        user: result.user!,
        accessToken: result.accessToken!,
      );
      debugPrint('AuthNotifier: 綁定成功');
      return true;
    } else {
      state = state.copyWith(
        isLinking: false,
        errorMessage: result.errorMessage,
        errorType: result.errorType,
      );
      debugPrint('AuthNotifier: 綁定失敗 - ${result.errorMessage}');
      return false;
    }
  }

  /// 更新用戶資料
  Future<bool> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    if (!state.isAuthenticated) return false;

    final result = await _authService.updateProfile(
      displayName: displayName,
      avatarUrl: avatarUrl,
    );

    if (result.success && result.user != null) {
      state = AuthState.authenticated(
        user: result.user!,
        accessToken: result.accessToken!,
      );
      return true;
    }
    return false;
  }

  /// 清除錯誤
  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(
        errorMessage: null,
        errorType: null,
      );
    }
  }

  // ===== Private Methods =====

  Future<bool> _signIn(Future<AuthResult> Function() signInMethod) async {
    debugPrint('AuthNotifier: 開始登入...');
    state = AuthState.loading();

    final result = await signInMethod();

    if (result.success && result.user != null) {
      state = AuthState.authenticated(
        user: result.user!,
        accessToken: result.accessToken!,
      );
      debugPrint('AuthNotifier: 登入成功');
      return true;
    } else {
      state = AuthState.error(
        message: result.errorMessage ?? '登入失敗',
        errorType: result.errorType,
      );
      debugPrint('AuthNotifier: 登入失敗 - ${result.errorMessage}');
      return false;
    }
  }
}

// ===== Riverpod Providers =====

/// AuthService Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// AuthNotifier Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

/// 當前用戶 Provider
final currentUserProvider = Provider<UserAccount?>((ref) {
  return ref.watch(authProvider).user;
});

/// 是否已登入 Provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

/// 是否為訪客 Provider
final isGuestProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isGuest;
});

/// 認證狀態 Provider
final authStatusProvider = Provider<AuthStatus>((ref) {
  return ref.watch(authProvider).status;
});
