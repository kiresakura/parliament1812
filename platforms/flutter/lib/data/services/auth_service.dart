import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import '../../domain/models/user_account.dart';

/// 認證服務 - 處理社群帳號登入與訪客模式
/// 
/// 目前為 Mock 實作，實際 OAuth 連接需要 API Key
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // 內部狀態
  UserAccount? _currentUser;
  String? _accessToken;
  String? _refreshToken;

  // Getters
  UserAccount? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _currentUser != null && _accessToken != null;
  bool get isGuest => _currentUser?.isGuest ?? true;

  // 儲存 Key
  static const _keyUserData = 'auth_user_data';
  static const _keyAccessToken = 'auth_access_token';
  static const _keyRefreshToken = 'auth_refresh_token';

  /// 初始化 - 嘗試自動登入，若無帳號則自動建立訪客帳號
  Future<AuthResult> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_keyUserData);
      final accessToken = prefs.getString(_keyAccessToken);

      if (userData != null && accessToken != null) {
        final user = UserAccount.fromJson(json.decode(userData));
        _currentUser = user;
        _accessToken = accessToken;
        _refreshToken = prefs.getString(_keyRefreshToken);

        debugPrint('AuthService: 自動登入成功 - ${user.effectiveDisplayName}');
        return AuthResult.success(
          user: user,
          accessToken: accessToken,
          refreshToken: _refreshToken,
        );
      }

      // 沒有已存的登入狀態，自動建立訪客帳號
      debugPrint('AuthService: 沒有已存的登入狀態，自動建立訪客帳號');
      return await signInAsGuest();
    } catch (e) {
      debugPrint('AuthService: 初始化失敗 - $e');
      // 初始化失敗時也嘗試建立訪客帳號
      try {
        return await signInAsGuest();
      } catch (guestError) {
        return AuthResult.failure(
          message: '初始化失敗: $e',
          errorType: AuthErrorType.unknown,
        );
      }
    }
  }

  /// Google 登入
  Future<AuthResult> signInWithGoogle() async {
    debugPrint('AuthService: 開始 Google 登入...');

    // TODO: 實際實作 - 使用 google_sign_in 套件
    // final GoogleSignIn googleSignIn = GoogleSignIn();
    // final GoogleSignInAccount? account = await googleSignIn.signIn();
    // if (account == null) return AuthResult.failure(message: '用戶取消登入');
    // final auth = await account.authentication;
    // 將 auth.idToken 發送到後端驗證

    // Mock 實作
    await Future.delayed(const Duration(milliseconds: 800));

    final user = _createMockUser(
      provider: AuthProvider.google,
      displayName: 'Google 用戶',
      email: 'user@gmail.com',
    );

    return _completeSignIn(user);
  }

  /// Apple 登入
  Future<AuthResult> signInWithApple() async {
    debugPrint('AuthService: 開始 Apple 登入...');

    // TODO: 實際實作 - 使用 sign_in_with_apple 套件
    // final credential = await SignInWithApple.getAppleIDCredential(
    //   scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    // );
    // 將 credential.identityToken 發送到後端驗證

    // Mock 實作
    await Future.delayed(const Duration(milliseconds: 800));

    final user = _createMockUser(
      provider: AuthProvider.apple,
      displayName: 'Apple 用戶',
      email: 'user@icloud.com',
    );

    return _completeSignIn(user);
  }

  /// Discord 登入
  Future<AuthResult> signInWithDiscord() async {
    debugPrint('AuthService: 開始 Discord 登入...');

    // TODO: 實際實作 - 使用 OAuth2 手動實作
    // 1. 開啟 Discord OAuth2 授權頁面
    // 2. 用戶授權後獲取 authorization code
    // 3. 用 code 換取 access token
    // 4. 用 access token 獲取用戶資訊
    // 5. 將資訊發送到後端驗證

    // Mock 實作
    await Future.delayed(const Duration(milliseconds: 800));

    final user = _createMockUser(
      provider: AuthProvider.discord,
      displayName: 'Discord 用戶',
      email: 'user@discord.com',
    );

    return _completeSignIn(user);
  }

  /// 訪客登入 - 調用後端 API 創建真正的訪客帳號
  Future<AuthResult> signInAsGuest() async {
    debugPrint('AuthService: 開始訪客登入...');

    final random = Random();
    final guestId = random.nextInt(100000).toString().padLeft(5, '0');
    final username = 'guest_$guestId';
    final password = 'guest_password_${random.nextInt(1000000)}';

    try {
      // 1. 嘗試註冊新訪客帳號
      final registerResult = await _registerOnBackend(username, password);
      
      if (registerResult != null) {
        debugPrint('AuthService: 訪客帳號註冊成功');
      } else {
        debugPrint('AuthService: 訪客帳號可能已存在，嘗試登入');
      }

      // 2. 登入獲取 JWT token
      final loginResult = await _loginOnBackend(username, password);
      
      if (loginResult != null) {
        final user = UserAccount(
          odUserId: loginResult['userId'] ?? username,
          displayName: '訪客 #$guestId',
          provider: AuthProvider.guest,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        _currentUser = user;
        _accessToken = loginResult['accessToken'];
        _refreshToken = loginResult['refreshToken'];

        // 同時保存帳號密碼用於下次自動登入
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('guest_username', username);
        await prefs.setString('guest_password', password);

        await _saveUserData();

        debugPrint('AuthService: 訪客登入成功，獲得真正的 JWT token');

        return AuthResult.success(
          user: user,
          accessToken: _accessToken!,
          refreshToken: _refreshToken,
        );
      }
    } catch (e) {
      debugPrint('AuthService: 後端認證失敗 - $e');
    }

    // 後端認證失敗時，使用 Mock 模式（僅限單人模式）
    debugPrint('AuthService: 後端不可用，使用離線訪客模式');
    
    final user = UserAccount(
      odUserId: 'offline_guest_$guestId',
      displayName: '離線訪客 #$guestId',
      provider: AuthProvider.guest,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );

    return _completeSignIn(user);
  }

  /// 向後端註冊帳號
  Future<Map<String, dynamic>?> _registerOnBackend(String username, String password) async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10)
        ..badCertificateCallback = (cert, host, port) => true;

      final request = await client.postUrl(
        Uri.parse('${ApiConstants.baseUrl}/api/v1/auth/register'),
      );
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Accept', 'application/json');
      request.write(json.encode({
        'username': username,
        'password': password,
      }));

      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );

      final body = await response.transform(utf8.decoder).join();
      client.close(force: true);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(body) as Map<String, dynamic>;
      } else {
        debugPrint('Register failed: ${response.statusCode} - $body');
        return null;
      }
    } catch (e) {
      debugPrint('Register error: $e');
      return null;
    }
  }

  /// 向後端登入
  Future<Map<String, dynamic>?> _loginOnBackend(String username, String password) async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10)
        ..badCertificateCallback = (cert, host, port) => true;

      final request = await client.postUrl(
        Uri.parse('${ApiConstants.baseUrl}/api/v1/auth/login'),
      );
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Accept', 'application/json');
      request.write(json.encode({
        'username': username,
        'password': password,
      }));

      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );

      final body = await response.transform(utf8.decoder).join();
      client.close(force: true);

      if (response.statusCode == 200) {
        final data = json.decode(body) as Map<String, dynamic>;
        return {
          'userId': data['user']?['id'] ?? username,
          'accessToken': data['access_token'] ?? data['token'],
          'refreshToken': data['refresh_token'],
        };
      } else {
        debugPrint('Login failed: ${response.statusCode} - $body');
        return null;
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return null;
    }
  }

  /// 登出
  Future<void> signOut() async {
    debugPrint('AuthService: 登出...');

    _currentUser = null;
    _accessToken = null;
    _refreshToken = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserData);
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);

    debugPrint('AuthService: 登出完成');
  }

  /// 綁定社群帳號（訪客升級）
  Future<AuthResult> linkAccount(AuthProvider provider) async {
    if (_currentUser == null) {
      return AuthResult.failure(
        message: '請先登入',
        errorType: AuthErrorType.accountNotFound,
      );
    }

    if (!_currentUser!.isGuest) {
      return AuthResult.failure(
        message: '只有訪客帳號可以綁定社群帳號',
        errorType: AuthErrorType.accountExists,
      );
    }

    debugPrint('AuthService: 開始綁定 ${provider.displayName} 帳號...');

    // TODO: 實際實作 - 根據 provider 呼叫對應的 OAuth
    // 然後將 OAuth token + 當前訪客 ID 發送到後端進行帳號升級

    // Mock 實作
    await Future.delayed(const Duration(milliseconds: 800));

    final linkedAccount = LinkedAccount(
      provider: provider,
      providerUserId: 'mock_${provider.name}_${Random().nextInt(10000)}',
      displayName: '${provider.displayName} 用戶',
      email: 'user@${provider.name}.com',
      linkedAt: DateTime.now(),
    );

    final upgradedUser = _currentUser!.copyWith(
      provider: provider,
      providerUserId: linkedAccount.providerUserId,
      displayName: linkedAccount.displayName,
      email: linkedAccount.email,
      linkedAccounts: [..._currentUser!.linkedAccounts, linkedAccount],
    );

    return _completeSignIn(upgradedUser);
  }

  /// 取得當前用戶
  Future<UserAccount?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;

    final result = await initialize();
    return result.user;
  }

  /// 刷新 Token
  Future<AuthResult> refreshAccessToken() async {
    if (_refreshToken == null) {
      return AuthResult.failure(
        message: '沒有 refresh token',
        errorType: AuthErrorType.invalidToken,
      );
    }

    // TODO: 實際實作 - 發送 refresh token 到後端換取新的 access token

    // Mock 實作
    await Future.delayed(const Duration(milliseconds: 500));

    _accessToken = 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, _accessToken!);

    return AuthResult.success(
      user: _currentUser!,
      accessToken: _accessToken!,
      refreshToken: _refreshToken,
    );
  }

  /// 更新用戶資料
  Future<AuthResult> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) {
      return AuthResult.failure(
        message: '請先登入',
        errorType: AuthErrorType.accountNotFound,
      );
    }

    // TODO: 實際實作 - 發送更新請求到後端

    // Mock 實作
    await Future.delayed(const Duration(milliseconds: 500));

    final updatedUser = _currentUser!.copyWith(
      displayName: displayName ?? _currentUser!.displayName,
      avatarUrl: avatarUrl ?? _currentUser!.avatarUrl,
    );

    _currentUser = updatedUser;
    await _saveUserData();

    return AuthResult.success(
      user: updatedUser,
      accessToken: _accessToken!,
      refreshToken: _refreshToken,
    );
  }

  // ===== Private Methods =====

  /// 建立 Mock 用戶
  UserAccount _createMockUser({
    required AuthProvider provider,
    required String displayName,
    String? email,
  }) {
    final random = Random();
    final odUserId = '${provider.name}_${random.nextInt(100000)}';

    return UserAccount(
      odUserId: odUserId,
      displayName: displayName,
      provider: provider,
      providerUserId: 'mock_${provider.name}_${random.nextInt(10000)}',
      email: email,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
  }

  /// 完成登入流程
  Future<AuthResult> _completeSignIn(UserAccount user) async {
    _currentUser = user;
    _accessToken = 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}';
    _refreshToken = 'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}';

    await _saveUserData();

    debugPrint('AuthService: 登入成功 - ${user.effectiveDisplayName}');

    return AuthResult.success(
      user: user,
      accessToken: _accessToken!,
      refreshToken: _refreshToken,
    );
  }

  /// 儲存用戶資料到本地
  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();

    if (_currentUser != null) {
      await prefs.setString(_keyUserData, json.encode(_currentUser!.toJson()));
    }
    if (_accessToken != null) {
      await prefs.setString(_keyAccessToken, _accessToken!);
    }
    if (_refreshToken != null) {
      await prefs.setString(_keyRefreshToken, _refreshToken!);
    }
  }
}
