import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/constants/api_constants.dart';
import 'auth_service.dart';

/// 房間資訊
class RoomListItem {
  final String id;
  final String code;
  final String hostName;
  final int playerCount;
  final int maxPlayers;
  final String status; // waiting, playing, finished
  final DateTime createdAt;

  RoomListItem({
    required this.id,
    required this.code,
    required this.hostName,
    required this.playerCount,
    required this.maxPlayers,
    required this.status,
    required this.createdAt,
  });

  factory RoomListItem.fromJson(Map<String, dynamic> json) {
    // 後端 RoomDetailResponse 格式
    // { id, code, host_id, status, max_players, player_count, created_at, players: [...] }

    // 從 players 陣列中找到房主名稱
    String hostName = '未知';
    final players = json['players'] as List<dynamic>?;
    if (players != null && players.isNotEmpty) {
      // 找到 is_host 為 true 的玩家
      final host = players.firstWhere(
        (p) => p['is_host'] == true,
        orElse: () => players.first,
      );
      hostName = host['name'] ?? host['player_name'] ?? '未知';
    }

    return RoomListItem(
      id: json['id']?.toString() ?? '',
      code: json['code'] ?? '',
      hostName: hostName,
      playerCount: json['player_count'] ?? json['playerCount'] ?? players?.length ?? 0,
      maxPlayers: json['max_players'] ?? json['maxPlayers'] ?? 4,
      status: json['status'] ?? 'waiting',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get canJoin => status == 'waiting' && playerCount < maxPlayers;
}

/// 房間列表服務
class RoomService {
  static final RoomService _instance = RoomService._internal();
  factory RoomService() => _instance;
  RoomService._internal();

  /// 取得可加入的房間列表
  Future<List<RoomListItem>> getAvailableRooms() async {
    try {
      final authService = AuthService();
      if (!authService.isAuthenticated) {
        await authService.initialize();
      }

      final url = '${ApiConstants.baseUrl}/api/v1/rooms';
      debugPrint('Fetching available rooms: $url');

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);

      final request = await client.getUrl(Uri.parse(url));
      if (authService.accessToken != null) {
        request.headers.add('Authorization', 'Bearer ${authService.accessToken}');
      }

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode == 200) {
        final data = json.decode(body);
        if (data is List) {
          return data.map((item) => RoomListItem.fromJson(item)).toList();
        } else if (data is Map && data['rooms'] is List) {
          return (data['rooms'] as List)
              .map((item) => RoomListItem.fromJson(item))
              .toList();
        }
      }

      debugPrint('Get rooms failed: ${response.statusCode} - $body');
      return [];
    } catch (e) {
      debugPrint('Get rooms error: $e');
      return [];
    }
  }

  /// 隨機加入一個房間
  Future<RoomListItem?> getRandomRoom() async {
    final rooms = await getAvailableRooms();
    if (rooms.isEmpty) return null;

    // 過濾可加入的房間
    final joinableRooms = rooms.where((r) => r.canJoin).toList();
    if (joinableRooms.isEmpty) return null;

    // 隨機選擇
    joinableRooms.shuffle();
    return joinableRooms.first;
  }

  /// 透過房間代碼查詢房間
  Future<RoomListItem?> getRoomByCode(String code) async {
    try {
      final authService = AuthService();
      if (!authService.isAuthenticated) {
        await authService.initialize();
      }

      final url = '${ApiConstants.baseUrl}/api/v1/rooms/$code';
      debugPrint('Looking up room: $url');

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);

      final request = await client.getUrl(Uri.parse(url));
      if (authService.accessToken != null) {
        request.headers.add('Authorization', 'Bearer ${authService.accessToken}');
      }

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode == 200) {
        final data = json.decode(body);
        return RoomListItem.fromJson(data);
      }

      return null;
    } catch (e) {
      debugPrint('Get room by code error: $e');
      return null;
    }
  }
}
