import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';

/// 認證 Token 儲存鍵
class _AuthKeys {
  static const String accessToken = 'auth_access_token';
  static const String refreshToken = 'auth_refresh_token';
  static const String userId = 'auth_user_id';
  static const String username = 'auth_username';
  static const String email = 'auth_email';
  static const String displayName = 'auth_display_name';
  static const String avatarUrl = 'auth_avatar_url';
  static const String loginMethod = 'auth_login_method';
}

/// 使用者資訊
class AuthUser {
  final String id;
  final String username;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final int? eloRating;

  const AuthUser({
    required this.id,
    required this.username,
    this.email,
    this.displayName,
    this.avatarUrl,
    this.eloRating,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      eloRating: json['elo_rating'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'elo_rating': eloRating,
      };
}

/// Token 回應
class TokenResponse {
  final String accessToken;
  final String? refreshToken;
  final int expiresIn;
  final AuthUser? user;

  const TokenResponse({
    required this.accessToken,
    this.refreshToken,
    required this.expiresIn,
    this.user,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
      expiresIn: json['expires_in'] as int,
      user: json['user'] != null
          ? AuthUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// 已綁定的 OAuth 帳號
class LinkedAccount {
  final String provider;
  final String? email;
  final String linkedAt;

  const LinkedAccount({
    required this.provider,
    this.email,
    required this.linkedAt,
  });

  factory LinkedAccount.fromJson(Map<String, dynamic> json) {
    return LinkedAccount(
      provider: json['provider'] as String,
      email: json['email'] as String?,
      linkedAt: json['linked_at'] as String,
    );
  }
}

/// 認證服務
///
/// 負責所有認證相關的 API 呼叫和 token 管理
class AuthService {
  final SharedPreferences _prefs;
  late final HttpClient _httpClient;

  String? _accessToken;
  String? _refreshToken;

  AuthService(this._prefs) {
    _httpClient = HttpClient();
    _httpClient.connectionTimeout = AppConstants.connectionTimeout;
    // 載入已儲存的 token
    _accessToken = _prefs.getString(_AuthKeys.accessToken);
    _refreshToken = _prefs.getString(_AuthKeys.refreshToken);
  }

  /// 是否有已儲存的 token
  bool get hasStoredTokens => _accessToken != null && _refreshToken != null;

  /// 取得當前 access token
  String? get accessToken => _accessToken;

  /// API base URL
  String get _baseUrl => AppConstants.baseUrl;

  // ============================================================
  // 公開 API
  // ============================================================

  /// 註冊
  Future<AuthResult<TokenResponse>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final result = await _post('/api/v1/auth/register', {
      'username': username,
      'email': email,
      'password': password,
    });

    if (result.success && result.data != null) {
      final tokenResponse = TokenResponse.fromJson(result.data!);
      await _storeTokens(tokenResponse);
      return AuthResult.success(tokenResponse);
    }
    return AuthResult.error(result.error ?? '註冊失敗');
  }

  /// 登入（email 或 username + password）
  Future<AuthResult<TokenResponse>> login({
    required String emailOrUsername,
    required String password,
  }) async {
    final result = await _post('/api/v1/auth/login', {
      'username': emailOrUsername,
      'password': password,
    });

    if (result.success && result.data != null) {
      final tokenResponse = TokenResponse.fromJson(result.data!);
      await _storeTokens(tokenResponse);
      await saveLoginMethod('password');
      return AuthResult.success(tokenResponse);
    }
    return AuthResult.error(result.error ?? '登入失敗');
  }

  /// Google OAuth 登入
  Future<AuthResult<TokenResponse>> loginWithGoogle(String idToken) async {
    final result = await _post('/api/v1/auth/oauth/google', {
      'token': idToken,
    });

    if (result.success && result.data != null) {
      final tokenResponse = TokenResponse.fromJson(result.data!);
      await _storeTokens(tokenResponse);
      await saveLoginMethod('google');
      return AuthResult.success(tokenResponse);
    }
    return AuthResult.error(result.error ?? 'Google 登入失敗');
  }

  /// Apple Sign-In 登入
  Future<AuthResult<TokenResponse>> loginWithApple({
    required String identityToken,
    String? displayName,
  }) async {
    final result = await _post('/api/v1/auth/oauth/apple', {
      'token': identityToken,
      if (displayName != null) 'display_name': displayName,
    });

    if (result.success && result.data != null) {
      final tokenResponse = TokenResponse.fromJson(result.data!);
      await _storeTokens(tokenResponse);
      await saveLoginMethod('apple');
      return AuthResult.success(tokenResponse);
    }
    final errorMsg = result.error ?? 'Apple 登入失敗';
    debugPrint('Apple login failed: $errorMsg');
    return AuthResult.error('Apple 登入失敗: $errorMsg');
  }

  /// 重新整理 Token
  Future<AuthResult<TokenResponse>> refreshTokens() async {
    if (_refreshToken == null) {
      return AuthResult.error('沒有 refresh token');
    }

    final result = await _post('/api/v1/auth/refresh', {
      'refresh_token': _refreshToken!,
    });

    if (result.success && result.data != null) {
      final tokenResponse = TokenResponse.fromJson(result.data!);
      await _storeTokens(tokenResponse);
      return AuthResult.success(tokenResponse);
    }
    // refresh 失敗，清除 token
    await logout();
    return AuthResult.error(result.error ?? 'Token 重新整理失敗');
  }

  /// 取得當前使用者資訊
  Future<AuthResult<AuthUser>> getMe() async {
    final result = await _get('/api/v1/auth/me');

    if (result.success && result.data != null) {
      final user = AuthUser.fromJson(result.data!);
      return AuthResult.success(user);
    }
    return AuthResult.error(result.error ?? '取得使用者資訊失敗');
  }

  /// 忘記密碼
  Future<AuthResult<String>> forgotPassword(String email) async {
    final result = await _post('/api/v1/auth/forgot-password', {
      'email': email,
    });

    if (result.success && result.data != null) {
      return AuthResult.success(result.data!['message'] as String);
    }
    return AuthResult.error(result.error ?? '忘記密碼請求失敗');
  }

  /// 重設密碼
  Future<AuthResult<String>> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    final result = await _post('/api/v1/auth/reset-password', {
      'reset_token': resetToken,
      'new_password': newPassword,
    });

    if (result.success && result.data != null) {
      return AuthResult.success(result.data!['message'] as String);
    }
    return AuthResult.error(result.error ?? '密碼重設失敗');
  }

  /// 更新個人檔案
  Future<AuthResult<AuthUser>> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['display_name'] = displayName;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;

    final result = await _put('/api/v1/auth/profile', body);

    if (result.success && result.data != null) {
      final user = AuthUser.fromJson(result.data!);
      // 更新本地儲存
      if (user.displayName != null) {
        await _prefs.setString(_AuthKeys.displayName, user.displayName!);
      }
      if (user.avatarUrl != null) {
        await _prefs.setString(_AuthKeys.avatarUrl, user.avatarUrl!);
      }
      return AuthResult.success(user);
    }
    return AuthResult.error(result.error ?? '更新個人檔案失敗');
  }

  // ============================================================
  // OAuth 帳號綁定
  // ============================================================

  /// 綁定 Google 帳號
  Future<AuthResult<String>> linkGoogle(String idToken) async {
    final result = await _post('/api/v1/auth/link/google', {
      'token': idToken,
    });

    if (result.success && result.data != null) {
      return AuthResult.success(result.data!['message'] as String);
    }
    return AuthResult.error(result.error ?? 'Google 帳號綁定失敗');
  }

  /// 綁定 Apple 帳號
  Future<AuthResult<String>> linkApple(String identityToken) async {
    final result = await _post('/api/v1/auth/link/apple', {
      'token': identityToken,
    });

    if (result.success && result.data != null) {
      return AuthResult.success(result.data!['message'] as String);
    }
    return AuthResult.error(result.error ?? 'Apple 帳號綁定失敗');
  }

  /// 解綁 OAuth 帳號
  Future<AuthResult<String>> unlinkProvider(String provider) async {
    final result = await _delete('/api/v1/auth/link/$provider');

    if (result.success && result.data != null) {
      return AuthResult.success(result.data!['message'] as String);
    }
    return AuthResult.error(result.error ?? '帳號解綁失敗');
  }

  /// 取得已綁定帳號列表
  Future<AuthResult<List<LinkedAccount>>> getLinkedAccounts() async {
    final result = await _get('/api/v1/auth/links');

    if (result.success && result.data != null) {
      final accountsJson = result.data!['accounts'] as List<dynamic>;
      final accounts = accountsJson
          .map((e) => LinkedAccount.fromJson(e as Map<String, dynamic>))
          .toList();
      return AuthResult.success(accounts);
    }
    return AuthResult.error(result.error ?? '取得綁定帳號列表失敗');
  }

  /// 刪除帳號
  Future<AuthResult<String>> deleteAccount() async {
    final result = await _delete('/api/v1/auth/account');

    if (result.success && result.data != null) {
      await logout();
      return AuthResult.success(result.data!['message'] as String);
    }
    return AuthResult.error(result.error ?? '帳號刪除失敗');
  }

  // ============================================================
  // 登入方式記憶
  // ============================================================

  /// 儲存登入方式
  Future<void> saveLoginMethod(String method) async {
    await _prefs.setString(_AuthKeys.loginMethod, method);
  }

  /// 取得上次登入方式
  String? getLoginMethod() {
    return _prefs.getString(_AuthKeys.loginMethod);
  }

  /// 清除登入方式記憶
  Future<void> clearLoginMethod() async {
    await _prefs.remove(_AuthKeys.loginMethod);
  }

  /// 登出
  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    await _prefs.remove(_AuthKeys.accessToken);
    await _prefs.remove(_AuthKeys.refreshToken);
    await _prefs.remove(_AuthKeys.userId);
    await _prefs.remove(_AuthKeys.username);
    await _prefs.remove(_AuthKeys.email);
    await _prefs.remove(_AuthKeys.displayName);
    await _prefs.remove(_AuthKeys.avatarUrl);
  }

  /// 嘗試自動登入（用已儲存的 token）
  Future<bool> tryAutoLogin() async {
    if (!hasStoredTokens) return false;

    // 先嘗試取得 /me
    final meResult = await getMe();
    if (meResult.success) return true;

    // access token 過期，嘗試 refresh
    final refreshResult = await refreshTokens();
    return refreshResult.success;
  }

  // ============================================================
  // 內部方法
  // ============================================================

  Future<void> _storeTokens(TokenResponse response) async {
    _accessToken = response.accessToken;
    if (response.refreshToken != null) {
      _refreshToken = response.refreshToken;
      await _prefs.setString(_AuthKeys.refreshToken, response.refreshToken!);
    }
    await _prefs.setString(_AuthKeys.accessToken, response.accessToken);

    if (response.user != null) {
      await _prefs.setString(_AuthKeys.userId, response.user!.id);
      await _prefs.setString(_AuthKeys.username, response.user!.username);
      if (response.user!.email != null) {
        await _prefs.setString(_AuthKeys.email, response.user!.email!);
      }
      if (response.user!.displayName != null) {
        await _prefs.setString(
            _AuthKeys.displayName, response.user!.displayName!);
      }
    }
  }

  Future<_ApiResponse> _get(String path) async {
    return _makeRequest('GET', path);
  }

  Future<_ApiResponse> _post(String path, Map<String, dynamic> body) async {
    return _makeRequest('POST', path, body: body);
  }

  Future<_ApiResponse> _put(String path, Map<String, dynamic> body) async {
    return _makeRequest('PUT', path, body: body);
  }

  Future<_ApiResponse> _delete(String path) async {
    return _makeRequest('DELETE', path);
  }

  Future<_ApiResponse> _makeRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$path');
      final request = await _httpClient.openUrl(method, uri);

      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      if (_accessToken != null) {
        request.headers.set('Authorization', 'Bearer $_accessToken');
      }

      if (body != null) {
        request.add(utf8.encode(jsonEncode(body)));
      }

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = responseBody.isNotEmpty
            ? jsonDecode(responseBody) as Map<String, dynamic>
            : <String, dynamic>{};
        return _ApiResponse.success(data);
      } else {
        final errorData = responseBody.isNotEmpty
            ? jsonDecode(responseBody) as Map<String, dynamic>
            : <String, dynamic>{};
        final errorMsg = errorData['message'] ?? 'HTTP ${response.statusCode}';
        return _ApiResponse.error(errorMsg as String);
      }
    } catch (e) {
      debugPrint('AuthService request error: $e');
      return _ApiResponse.error('網路請求失敗: $e');
    }
  }

  void dispose() {
    _httpClient.close();
  }
}

/// API 回應內部類
class _ApiResponse {
  final bool success;
  final Map<String, dynamic>? data;
  final String? error;

  const _ApiResponse._({required this.success, this.data, this.error});

  factory _ApiResponse.success(Map<String, dynamic> data) =>
      _ApiResponse._(success: true, data: data);

  factory _ApiResponse.error(String error) =>
      _ApiResponse._(success: false, error: error);
}

/// 認證操作結果
class AuthResult<T> {
  final bool success;
  final T? data;
  final String? error;

  const AuthResult._({required this.success, this.data, this.error});

  factory AuthResult.success(T data) =>
      AuthResult._(success: true, data: data);

  factory AuthResult.error(String error) =>
      AuthResult._(success: false, error: error);
}

// AuthService provider is defined in providers/auth_provider.dart
