/// 認證提供者類型
enum AuthProvider {
  google('Google', 'assets/images/auth/google.png'),
  apple('Apple', 'assets/images/auth/apple.png'),
  discord('Discord', 'assets/images/auth/discord.png'),
  guest('訪客', null);

  final String displayName;
  final String? iconPath;

  const AuthProvider(this.displayName, this.iconPath);

  /// 從字串轉換
  static AuthProvider fromString(String value) {
    return AuthProvider.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AuthProvider.guest,
    );
  }
}

/// 用戶帳號模型
class UserAccount {
  /// 唯一用戶 ID（系統內部 ID）
  final String odUserId;

  /// 顯示名稱
  final String? displayName;

  /// 頭像 URL
  final String? avatarUrl;

  /// 登入方式
  final AuthProvider provider;

  /// 社群帳號 ID（Google/Apple/Discord 的原始 ID）
  final String? providerUserId;

  /// 電子郵件
  final String? email;

  /// 帳號建立時間
  final DateTime createdAt;

  /// 最後登入時間
  final DateTime lastLoginAt;

  /// 是否為訪客帳號
  bool get isGuest => provider == AuthProvider.guest;

  /// 綁定的社群帳號列表
  final List<LinkedAccount> linkedAccounts;

  const UserAccount({
    required this.odUserId,
    this.displayName,
    this.avatarUrl,
    required this.provider,
    this.providerUserId,
    this.email,
    required this.createdAt,
    required this.lastLoginAt,
    this.linkedAccounts = const [],
  });

  /// 取得顯示名稱（優先使用設定的名稱，否則使用 Provider 名稱）
  String get effectiveDisplayName =>
      displayName ?? '${provider.displayName} 用戶';

  /// 複製並修改
  UserAccount copyWith({
    String? odUserId,
    String? displayName,
    String? avatarUrl,
    AuthProvider? provider,
    String? providerUserId,
    String? email,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    List<LinkedAccount>? linkedAccounts,
  }) {
    return UserAccount(
      odUserId: odUserId ?? this.odUserId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      provider: provider ?? this.provider,
      providerUserId: providerUserId ?? this.providerUserId,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      linkedAccounts: linkedAccounts ?? this.linkedAccounts,
    );
  }

  /// 從 JSON 轉換
  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      odUserId: json['od_user_id'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      provider: AuthProvider.fromString(json['provider'] as String),
      providerUserId: json['provider_user_id'] as String?,
      email: json['email'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastLoginAt: DateTime.parse(json['last_login_at'] as String),
      linkedAccounts: (json['linked_accounts'] as List<dynamic>?)
              ?.map((e) => LinkedAccount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'od_user_id': odUserId,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'provider': provider.name,
      'provider_user_id': providerUserId,
      'email': email,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt.toIso8601String(),
      'linked_accounts': linkedAccounts.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'UserAccount(odUserId: $odUserId, displayName: $displayName, '
        'provider: ${provider.name}, isGuest: $isGuest)';
  }
}

/// 已綁定的社群帳號
class LinkedAccount {
  final AuthProvider provider;
  final String providerUserId;
  final String? displayName;
  final String? email;
  final DateTime linkedAt;

  const LinkedAccount({
    required this.provider,
    required this.providerUserId,
    this.displayName,
    this.email,
    required this.linkedAt,
  });

  factory LinkedAccount.fromJson(Map<String, dynamic> json) {
    return LinkedAccount(
      provider: AuthProvider.fromString(json['provider'] as String),
      providerUserId: json['provider_user_id'] as String,
      displayName: json['display_name'] as String?,
      email: json['email'] as String?,
      linkedAt: DateTime.parse(json['linked_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider.name,
      'provider_user_id': providerUserId,
      'display_name': displayName,
      'email': email,
      'linked_at': linkedAt.toIso8601String(),
    };
  }
}

/// 認證結果
class AuthResult {
  final bool success;
  final UserAccount? user;
  final String? accessToken;
  final String? refreshToken;
  final String? errorMessage;
  final AuthErrorType? errorType;

  const AuthResult({
    required this.success,
    this.user,
    this.accessToken,
    this.refreshToken,
    this.errorMessage,
    this.errorType,
  });

  factory AuthResult.success({
    required UserAccount user,
    required String accessToken,
    String? refreshToken,
  }) {
    return AuthResult(
      success: true,
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  factory AuthResult.failure({
    required String message,
    AuthErrorType? errorType,
  }) {
    return AuthResult(
      success: false,
      errorMessage: message,
      errorType: errorType,
    );
  }
}

/// 認證錯誤類型
enum AuthErrorType {
  cancelled,       // 用戶取消
  networkError,    // 網路錯誤
  serverError,     // 伺服器錯誤
  invalidToken,    // 無效的 Token
  accountExists,   // 帳號已存在（無法綁定）
  accountNotFound, // 帳號不存在
  unknown,         // 未知錯誤
}
