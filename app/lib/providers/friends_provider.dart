import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/constants.dart';
import '../services/auth_service.dart';
import 'auth_provider.dart';

// ============================================================
// Models
// ============================================================

/// 好友資訊
class FriendInfo {
  final String userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final int? eloRating;
  final bool isOnline;
  final DateTime? lastSeenAt;
  final DateTime? friendSince;

  const FriendInfo({
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.eloRating,
    this.isOnline = false,
    this.lastSeenAt,
    this.friendSince,
  });

  String get displayLabel => displayName ?? username;

  factory FriendInfo.fromJson(Map<String, dynamic> json) {
    return FriendInfo(
      userId: json['user_id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      eloRating: json['elo_rating'] as int?,
      isOnline: json['is_online'] as bool? ?? false,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.tryParse(json['last_seen_at'] as String)
          : null,
      friendSince: json['friend_since'] != null
          ? DateTime.tryParse(json['friend_since'] as String)
          : null,
    );
  }
}

/// 好友請求
class FriendRequest {
  final String userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final int? eloRating;
  final DateTime? requestedAt;

  const FriendRequest({
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.eloRating,
    this.requestedAt,
  });

  String get displayLabel => displayName ?? username;

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      userId: json['user_id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      eloRating: json['elo_rating'] as int?,
      requestedAt: json['requested_at'] != null
          ? DateTime.tryParse(json['requested_at'] as String)
          : null,
    );
  }
}

/// 用戶搜尋結果
class UserSearchResult {
  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final int? eloRating;
  final bool isOnline;
  final String? friendStatus; // null, "pending", "accepted", "blocked"

  const UserSearchResult({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.eloRating,
    this.isOnline = false,
    this.friendStatus,
  });

  String get displayLabel => displayName ?? username;

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      eloRating: json['elo_rating'] as int?,
      isOnline: json['is_online'] as bool? ?? false,
      friendStatus: json['friend_status'] as String?,
    );
  }
}

// ============================================================
// State
// ============================================================

class FriendsState {
  final List<FriendInfo> friends;
  final List<FriendRequest> pendingRequests;
  final List<UserSearchResult> searchResults;
  final bool isLoading;
  final bool isSearching;
  final String? error;
  final String? successMessage;

  const FriendsState({
    this.friends = const [],
    this.pendingRequests = const [],
    this.searchResults = const [],
    this.isLoading = false,
    this.isSearching = false,
    this.error,
    this.successMessage,
  });

  int get pendingCount => pendingRequests.length;
  int get onlineCount => friends.where((f) => f.isOnline).length;

  FriendsState copyWith({
    List<FriendInfo>? friends,
    List<FriendRequest>? pendingRequests,
    List<UserSearchResult>? searchResults,
    bool? isLoading,
    bool? isSearching,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return FriendsState(
      friends: friends ?? this.friends,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      searchResults: searchResults ?? this.searchResults,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

// ============================================================
// Notifier
// ============================================================

class FriendsNotifier extends StateNotifier<FriendsState> {
  final AuthService _authService;
  Timer? _refreshTimer;

  FriendsNotifier(this._authService) : super(const FriendsState()) {
    // 自動重新整理（每 30 秒）
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (state.friends.isNotEmpty) {
        loadFriends(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  // API Helpers
  // ============================================================

  Future<Map<String, dynamic>?> _apiGet(String path) async {
    final token = _authService.accessToken;
    if (token == null) return null;

    try {
      final client = HttpClient();
      client.connectionTimeout = AppConstants.connectionTimeout;
      final uri = Uri.parse('${AppConstants.baseUrl}$path');
      final request = await client.getUrl(uri);
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.set('Content-Type', 'application/json');

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(body) as Map<String, dynamic>;
      } else {
        final errorData = jsonDecode(body) as Map<String, dynamic>;
        throw Exception(errorData['message'] ?? 'HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('網路請求失敗: $e');
    }
  }

  Future<Map<String, dynamic>?> _apiPost(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final token = _authService.accessToken;
    if (token == null) return null;

    try {
      final client = HttpClient();
      client.connectionTimeout = AppConstants.connectionTimeout;
      final uri = Uri.parse('${AppConstants.baseUrl}$path');
      final request = await client.openUrl('POST', uri);
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.set('Content-Type', 'application/json');
      if (body != null) request.write(jsonEncode(body));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody.isNotEmpty
            ? jsonDecode(responseBody) as Map<String, dynamic>
            : {};
      } else {
        final errorData = jsonDecode(responseBody) as Map<String, dynamic>;
        throw Exception(errorData['message'] ?? 'HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('網路請求失敗: $e');
    }
  }

  Future<Map<String, dynamic>?> _apiDelete(String path) async {
    final token = _authService.accessToken;
    if (token == null) return null;

    try {
      final client = HttpClient();
      client.connectionTimeout = AppConstants.connectionTimeout;
      final uri = Uri.parse('${AppConstants.baseUrl}$path');
      final request = await client.deleteUrl(uri);
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.set('Content-Type', 'application/json');

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody.isNotEmpty
            ? jsonDecode(responseBody) as Map<String, dynamic>
            : {};
      } else {
        final errorData = jsonDecode(responseBody) as Map<String, dynamic>;
        throw Exception(errorData['message'] ?? 'HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('網路請求失敗: $e');
    }
  }

  // ============================================================
  // 好友列表
  // ============================================================

  Future<void> loadFriends({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final data = await _apiGet('/api/v1/friends');
      if (data != null) {
        final friends = (data['friends'] as List<dynamic>)
            .map((j) => FriendInfo.fromJson(j as Map<String, dynamic>))
            .toList();
        state = state.copyWith(friends: friends, isLoading: false);
      }
    } catch (e) {
      if (!silent) {
        state = state.copyWith(isLoading: false, error: '$e');
      }
    }
  }

  // ============================================================
  // 待處理請求
  // ============================================================

  Future<void> loadPendingRequests() async {
    try {
      final data = await _apiGet('/api/v1/friends/pending');
      if (data != null) {
        final requests = (data['requests'] as List<dynamic>)
            .map((j) => FriendRequest.fromJson(j as Map<String, dynamic>))
            .toList();
        state = state.copyWith(pendingRequests: requests);
      }
    } catch (e) {
      state = state.copyWith(error: '$e');
    }
  }

  // ============================================================
  // 發送好友請求
  // ============================================================

  Future<bool> sendFriendRequest(String targetUserId) async {
    try {
      await _apiPost(
        '/api/v1/friends/request',
        body: {'target_user_id': targetUserId},
      );
      state = state.copyWith(
        successMessage: '好友請求已發送',
        clearError: true,
      );
      // 重新搜尋以更新狀態
      return true;
    } catch (e) {
      state = state.copyWith(error: '$e');
      return false;
    }
  }

  // ============================================================
  // 接受好友請求
  // ============================================================

  Future<bool> acceptFriendRequest(String userId) async {
    try {
      await _apiPost(
        '/api/v1/friends/accept',
        body: {'user_id': userId},
      );
      // 更新本地狀態
      state = state.copyWith(
        pendingRequests:
            state.pendingRequests.where((r) => r.userId != userId).toList(),
        successMessage: '已接受好友請求',
        clearError: true,
      );
      // 重新載入好友列表
      await loadFriends(silent: true);
      return true;
    } catch (e) {
      state = state.copyWith(error: '$e');
      return false;
    }
  }

  // ============================================================
  // 拒絕好友請求
  // ============================================================

  Future<bool> rejectFriendRequest(String userId) async {
    try {
      await _apiPost(
        '/api/v1/friends/reject',
        body: {'user_id': userId},
      );
      state = state.copyWith(
        pendingRequests:
            state.pendingRequests.where((r) => r.userId != userId).toList(),
        successMessage: '已拒絕好友請求',
        clearError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: '$e');
      return false;
    }
  }

  // ============================================================
  // 刪除好友
  // ============================================================

  Future<bool> removeFriend(String friendId) async {
    try {
      await _apiDelete('/api/v1/friends/$friendId');
      state = state.copyWith(
        friends: state.friends.where((f) => f.userId != friendId).toList(),
        successMessage: '已刪除好友',
        clearError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: '$e');
      return false;
    }
  }

  // ============================================================
  // 封鎖
  // ============================================================

  Future<bool> blockUser(String targetId) async {
    try {
      await _apiPost(
        '/api/v1/friends/block',
        body: {'target_user_id': targetId},
      );
      state = state.copyWith(
        friends: state.friends.where((f) => f.userId != targetId).toList(),
        successMessage: '已封鎖用戶',
        clearError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: '$e');
      return false;
    }
  }

  // ============================================================
  // 搜尋
  // ============================================================

  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(searchResults: [], isSearching: false);
      return;
    }

    state = state.copyWith(isSearching: true, clearError: true);

    try {
      final encoded = Uri.encodeQueryComponent(query);
      final data = await _apiGet('/api/v1/users/search?q=$encoded&limit=20');
      if (data != null) {
        final users = (data['users'] as List<dynamic>)
            .map((j) => UserSearchResult.fromJson(j as Map<String, dynamic>))
            .toList();
        state = state.copyWith(searchResults: users, isSearching: false);
      }
    } catch (e) {
      state = state.copyWith(isSearching: false, error: '$e');
    }
  }

  // ============================================================
  // 邀請對戰
  // ============================================================

  Future<String?> inviteToGame(String friendId) async {
    try {
      final data = await _apiPost(
        '/api/v1/friends/invite-game',
        body: {'target_user_id': friendId},
      );
      if (data != null) {
        final roomCode = data['room_code'] as String?;
        state = state.copyWith(
          successMessage: '對戰邀請已發送',
          clearError: true,
        );
        return roomCode;
      }
      return null;
    } catch (e) {
      state = state.copyWith(error: '$e');
      return null;
    }
  }

  // ============================================================
  // 全部重新載入
  // ============================================================

  Future<void> refresh() async {
    await Future.wait([
      loadFriends(),
      loadPendingRequests(),
    ]);
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

// ============================================================
// Providers
// ============================================================

final friendsProvider =
    StateNotifierProvider<FriendsNotifier, FriendsState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return FriendsNotifier(authService);
});

/// 待處理請求數量
final pendingFriendCountProvider = Provider<int>((ref) {
  return ref.watch(friendsProvider).pendingCount;
});

/// 在線好友數量
final onlineFriendCountProvider = Provider<int>((ref) {
  return ref.watch(friendsProvider).onlineCount;
});
