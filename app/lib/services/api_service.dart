import 'dart:convert';
import 'dart:io';

import '../config/constants.dart';
import '../models/room.dart';
import '../models/player.dart';

/// REST API 服務
/// 負責與後端的 HTTP API 通訊（認證、房間管理等）
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final HttpClient _httpClient;
  String? _authToken;

  void init() {
    _httpClient = HttpClient();
    _httpClient.connectionTimeout = AppConstants.connectionTimeout;
  }

  /// 設定認證 Token
  void setAuthToken(String? token) {
    _authToken = token;
  }

  /// 獲取房間列表
  Future<ApiResult<List<Room>>> getRooms({
    int? limit,
    RoomStatus? status,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (status != null) queryParams['status'] = status.name;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.roomsEndpoint}')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await _makeRequest('GET', uri);
      
      if (response.success && response.data != null) {
        final List<dynamic> roomsJson = response.data!['rooms'] as List<dynamic>;
        final rooms = roomsJson
            .map((json) => Room.fromJson(json as Map<String, dynamic>))
            .toList();
        
        return ApiResult.success(rooms);
      } else {
        return ApiResult.error(response.error!);
      }
    } catch (e) {
      return ApiResult.error('載入房間列表失敗: $e');
    }
  }

  /// 創建房間
  Future<ApiResult<Room>> createRoom({
    required String name,
    required String hostPlayerName,
    RoomSettings? settings,
  }) async {
    try {
      final body = {
        'name': name,
        'host_player_name': hostPlayerName,
        'settings': (settings ?? const RoomSettings()).toJson(),
      };

      final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.roomsEndpoint}');
      final response = await _makeRequest('POST', uri, body: body);
      
      if (response.success && response.data != null) {
        final room = Room.fromJson(response.data!['room'] as Map<String, dynamic>);
        return ApiResult.success(room);
      } else {
        return ApiResult.error(response.error!);
      }
    } catch (e) {
      return ApiResult.error('創建房間失敗: $e');
    }
  }

  /// 快速匹配房間
  Future<ApiResult<Room>> quickMatch({
    required String playerName,
    int? preferredMaxPlayers,
    bool? allowAi,
  }) async {
    try {
      final body = <String, dynamic>{
        'player_name': playerName,
      };
      if (preferredMaxPlayers != null) {
        body['preferred_max_players'] = preferredMaxPlayers;
      }
      if (allowAi != null) {
        body['allow_ai'] = allowAi;
      }

      final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.roomsEndpoint}/quickmatch');
      final response = await _makeRequest('POST', uri, body: body);
      
      if (response.success && response.data != null) {
        final room = Room.fromJson(response.data!['room'] as Map<String, dynamic>);
        return ApiResult.success(room);
      } else {
        return ApiResult.error(response.error!);
      }
    } catch (e) {
      return ApiResult.error('快速匹配失敗: $e');
    }
  }

  /// 獲取房間詳情
  Future<ApiResult<Room>> getRoomDetails(String roomCode) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.roomsEndpoint}/$roomCode');
      final response = await _makeRequest('GET', uri);
      
      if (response.success && response.data != null) {
        final room = Room.fromJson(response.data!['room'] as Map<String, dynamic>);
        return ApiResult.success(room);
      } else {
        return ApiResult.error(response.error!);
      }
    } catch (e) {
      return ApiResult.error('載入房間詳情失敗: $e');
    }
  }

  /// 觀戰房間
  Future<ApiResult<Player>> spectateRoom({
    required String roomCode,
    required String spectatorName,
  }) async {
    try {
      final body = {
        'spectator_name': spectatorName,
      };

      final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.roomsEndpoint}/$roomCode/spectate');
      final response = await _makeRequest('POST', uri, body: body);
      
      if (response.success && response.data != null) {
        final player = Player.fromJson(response.data!);
        return ApiResult.success(player);
      } else {
        return ApiResult.error(response.error!);
      }
    } catch (e) {
      return ApiResult.error('觀戰失敗: $e');
    }
  }

  /// 加入房間（REST API 預檢查，實際加入通過 WebSocket）
  Future<ApiResult<Room>> joinRoom({
    required String roomCode,
    required String playerName,
    String? password,
  }) async {
    try {
      final body = {
        'player_name': playerName,
        if (password?.isNotEmpty == true) 'password': password,
      };

      final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.roomsEndpoint}/$roomCode/join');
      final response = await _makeRequest('POST', uri, body: body);
      
      if (response.success && response.data != null) {
        final room = Room.fromJson(response.data!['room'] as Map<String, dynamic>);
        return ApiResult.success(room);
      } else {
        return ApiResult.error(response.error!);
      }
    } catch (e) {
      return ApiResult.error('加入房間失敗: $e');
    }
  }

  /// 認證（簡單的玩家名稱認證）
  Future<ApiResult<AuthInfo>> authenticate(String playerName) async {
    try {
      final body = {
        'player_name': playerName,
      };

      final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.authEndpoint}');
      final response = await _makeRequest('POST', uri, body: body);
      
      if (response.success && response.data != null) {
        final authInfo = AuthInfo.fromJson(response.data!['auth'] as Map<String, dynamic>);
        _authToken = authInfo.token;
        return ApiResult.success(authInfo);
      } else {
        return ApiResult.error(response.error!);
      }
    } catch (e) {
      return ApiResult.error('認證失敗: $e');
    }
  }

  /// 發送 HTTP 請求的內部方法
  Future<_HttpResponse> _makeRequest(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    try {
      // 對於開發階段，先返回模擬資料
      if (AppConstants.isDebugMode || uri.host == 'localhost' || uri.host == '10.0.2.2') {
        return _mockResponse(method, uri, body: body);
      }

      final request = await _httpClient.openUrl(method, uri);
      
      // 設定標頭
      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      if (_authToken != null) {
        request.headers.set('Authorization', 'Bearer $_authToken');
      }
      
      // 添加請求體
      if (body != null) {
        final bodyStr = jsonEncode(body);
        request.add(utf8.encode(bodyStr));
      }
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = responseBody.isNotEmpty 
            ? jsonDecode(responseBody) as Map<String, dynamic>
            : <String, dynamic>{};
        return _HttpResponse.success(data);
      } else {
        final errorData = responseBody.isNotEmpty 
            ? jsonDecode(responseBody) as Map<String, dynamic>
            : <String, dynamic>{};
        final errorMsg = errorData['message'] ?? 'HTTP ${response.statusCode}';
        return _HttpResponse.error(errorMsg);
      }
    } catch (e) {
      return _HttpResponse.error('網路請求失敗: $e');
    }
  }

  /// 模擬 API 回應（開發用）
  Future<_HttpResponse> _mockResponse(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    // 模擬網路延遲
    await Future.delayed(const Duration(milliseconds: 500));
    
    final path = uri.path;
    
    try {
      switch (method) {
        case 'GET':
          if (path == AppConstants.roomsEndpoint) {
            return _HttpResponse.success({
              'rooms': [
                _createMockRoom('新手友善房', 'ABC123', RoomStatus.waiting, 2, 4).toJson(),
                _createMockRoom('高手對決', 'XYZ789', RoomStatus.playing, 6, 6).toJson(),
                _createMockRoom('歷史愛好者聚會', 'DEF456', RoomStatus.waiting, 3, 7).toJson(),
              ],
            });
          } else if (path.startsWith('${AppConstants.roomsEndpoint}/')) {
            final roomCode = path.split('/').last;
            return _HttpResponse.success({
              'room': _createMockRoom('測試房間', roomCode, RoomStatus.waiting, 1, 7).toJson(),
            });
          }
          break;
          
        case 'POST':
          if (path == AppConstants.roomsEndpoint) {
            final roomName = body?['name'] ?? '新房間';
            // final hostName = body?['host_player_name'] ?? '房主'; // Unused for now
            final room = _createMockRoom(roomName, _generateRoomCode(), RoomStatus.waiting, 1, 7);
            return _HttpResponse.success({'room': room.toJson()});
          } else if (path == AppConstants.authEndpoint) {
            final playerName = body?['player_name'] ?? '玩家';
            return _HttpResponse.success({
              'auth': {
                'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
                'player_id': 'mock_player_${DateTime.now().millisecond}',
                'player_name': playerName,
                'expires_at': DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch,
              },
            });
          } else if (path.contains('/join')) {
            final roomCode = path.split('/')[2];
            final room = _createMockRoom('測試房間', roomCode, RoomStatus.waiting, 2, 7);
            return _HttpResponse.success({'room': room.toJson()});
          }
          break;
      }
      
      return _HttpResponse.error('API endpoint not found: $method $path');
    } catch (e) {
      return _HttpResponse.error('Mock API error: $e');
    }
  }

  Room _createMockRoom(String name, String code, RoomStatus status, int playerCount, int maxPlayers) {
    return RoomFactory.createRoom(
      name: name,
      hostPlayerId: 'host_id',
      settings: RoomSettings(maxPlayers: maxPlayers),
    ).copyWith(
      code: code,
      status: status,
      players: List.generate(playerCount, (index) => 
        PlayerFactory.createPlayer(
          name: '玩家${index + 1}',
          character: CharacterType.values[index % CharacterType.values.length],
          isHost: index == 0,
        ).copyWith(id: 'player_$index'),
      ),
    );
  }

  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (index) => 
      chars[DateTime.now().millisecond % chars.length]
    ).join();
  }

  // ==================== 單人模式 API ====================

  /// 開始 AI 快速對戰
  Future<ApiResult<Map<String, dynamic>>> startSinglePlayer({
    required String difficulty,
    String? character,
    required String playerName,
  }) async {
    try {
      final body = <String, dynamic>{
        'difficulty': difficulty,
        'player_name': playerName,
      };
      if (character != null) body['character'] = character;

      final uri = Uri.parse('${AppConstants.baseUrl}/api/v1/single/start');
      final response = await _makeRequest('POST', uri, body: body);
      if (response.success && response.data != null) {
        return ApiResult.success(response.data!);
      }
      return ApiResult.error(response.error ?? '啟動失敗');
    } catch (e) {
      return ApiResult.error('啟動單人對戰失敗: $e');
    }
  }

  /// 執行單人遊戲行動
  Future<ApiResult<Map<String, dynamic>>> singlePlayerAction({
    required String sessionId,
    required Map<String, dynamic> action,
  }) async {
    try {
      final body = {
        'session_id': sessionId,
        'action': action,
      };
      final uri = Uri.parse('${AppConstants.baseUrl}/api/v1/single/action');
      final response = await _makeRequest('POST', uri, body: body);
      if (response.success && response.data != null) {
        return ApiResult.success(response.data!);
      }
      return ApiResult.error(response.error ?? '行動失敗');
    } catch (e) {
      return ApiResult.error('行動失敗: $e');
    }
  }

  /// 取得單人遊戲狀態
  Future<ApiResult<Map<String, dynamic>>> getSinglePlayerState(
    String sessionId,
  ) async {
    try {
      final uri = Uri.parse(
          '${AppConstants.baseUrl}/api/v1/single/state/$sessionId');
      final response = await _makeRequest('GET', uri);
      if (response.success && response.data != null) {
        return ApiResult.success(response.data!);
      }
      return ApiResult.error(response.error ?? '取得狀態失敗');
    } catch (e) {
      return ApiResult.error('取得狀態失敗: $e');
    }
  }

  // ==================== 戰役 API ====================

  /// 取得戰役進度
  Future<ApiResult<Map<String, dynamic>>> getCampaignProgress() async {
    try {
      final uri = Uri.parse(
          '${AppConstants.baseUrl}/api/v1/campaign/progress');
      final response = await _makeRequest('GET', uri);
      if (response.success && response.data != null) {
        return ApiResult.success(response.data!);
      }
      return ApiResult.error(response.error ?? '取得進度失敗');
    } catch (e) {
      return ApiResult.error('取得戰役進度失敗: $e');
    }
  }

  /// 開始戰役章節
  Future<ApiResult<Map<String, dynamic>>> startCampaignChapter({
    required int chapter,
    int? stage,
    required String playerName,
    String? character,
  }) async {
    try {
      final body = <String, dynamic>{
        'chapter': chapter,
        'player_name': playerName,
      };
      if (stage != null) body['stage'] = stage;
      if (character != null) body['character'] = character;

      final uri = Uri.parse(
          '${AppConstants.baseUrl}/api/v1/single/campaign/start');
      final response = await _makeRequest('POST', uri, body: body);
      if (response.success && response.data != null) {
        return ApiResult.success(response.data!);
      }
      return ApiResult.error(response.error ?? '啟動戰役失敗');
    } catch (e) {
      return ApiResult.error('啟動戰役失敗: $e');
    }
  }

  // ==================== 教學 API ====================

  /// 取得教學進度
  Future<ApiResult<Map<String, dynamic>>> getTutorialProgress() async {
    try {
      final uri = Uri.parse(
          '${AppConstants.baseUrl}/api/v1/tutorial/progress');
      final response = await _makeRequest('GET', uri);
      if (response.success && response.data != null) {
        return ApiResult.success(response.data!);
      }
      return ApiResult.error(response.error ?? '取得教學進度失敗');
    } catch (e) {
      return ApiResult.error('取得教學進度失敗: $e');
    }
  }

  /// 完成教學步驟
  Future<ApiResult<Map<String, dynamic>>> completeTutorialStep(
    int step,
  ) async {
    try {
      final body = {'step': step};
      final uri = Uri.parse(
          '${AppConstants.baseUrl}/api/v1/tutorial/complete');
      final response = await _makeRequest('POST', uri, body: body);
      if (response.success && response.data != null) {
        return ApiResult.success(response.data!);
      }
      return ApiResult.error(response.error ?? '完成步驟失敗');
    } catch (e) {
      return ApiResult.error('完成教學步驟失敗: $e');
    }
  }

  /// 檢查是否需要教學
  Future<ApiResult<Map<String, dynamic>>> checkNeedsTutorial() async {
    try {
      final uri = Uri.parse(
          '${AppConstants.baseUrl}/api/v1/tutorial/check');
      final response = await _makeRequest('GET', uri);
      if (response.success && response.data != null) {
        return ApiResult.success(response.data!);
      }
      return ApiResult.error(response.error ?? '檢查失敗');
    } catch (e) {
      return ApiResult.error('檢查教學狀態失敗: $e');
    }
  }

  // ==================== IAP API ====================

  /// 取得寶石餘額
  Future<ApiResult<Map<String, dynamic>>> getGemBalance() async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/api/v1/iap/balance');
      final response = await _makeRequest('GET', uri);
      if (response.success && response.data != null) {
        return ApiResult.success(response.data!);
      }
      return ApiResult.error(response.error ?? '取得餘額失敗');
    } catch (e) {
      return ApiResult.error('取得寶石餘額失敗: $e');
    }
  }

  // ==================== 排行榜 API ====================

  /// 取得全球排行榜
  Future<ApiResult<Map<String, dynamic>>> getGlobalRankings({
    int? season,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': '$limit',
        'offset': '$offset',
      };
      if (season != null) queryParams['season'] = '$season';

      final uri = Uri.parse('${AppConstants.baseUrl}/api/v1/rankings/global')
          .replace(queryParameters: queryParams);

      final response = await _makeRequest('GET', uri);
      if (response.success && response.data != null) {
        return ApiResult.success(response.data!);
      }
      return ApiResult.error(response.error ?? '取得排行榜失敗');
    } catch (e) {
      return ApiResult.error('取得排行榜失敗: $e');
    }
  }

  /// 取得我的排名
  Future<ApiResult<Map<String, dynamic>>> getMyRanking({int? season}) async {
    try {
      final queryParams = <String, String>{};
      if (season != null) queryParams['season'] = '$season';

      final uri = Uri.parse('${AppConstants.baseUrl}/api/v1/rankings/me')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await _makeRequest('GET', uri);
      if (response.success && response.data != null) {
        return ApiResult.success(response.data!);
      }
      return ApiResult.error(response.error ?? '取得排名失敗');
    } catch (e) {
      return ApiResult.error('取得排名失敗: $e');
    }
  }

  /// 取得賽季列表
  Future<ApiResult<Map<String, dynamic>>> getSeasons() async {
    try {
      final uri =
          Uri.parse('${AppConstants.baseUrl}/api/v1/rankings/seasons');
      final response = await _makeRequest('GET', uri);
      if (response.success && response.data != null) {
        return ApiResult.success(response.data!);
      }
      return ApiResult.error(response.error ?? '取得賽季列表失敗');
    } catch (e) {
      return ApiResult.error('取得賽季列表失敗: $e');
    }
  }

  /// 取得當前賽季資訊
  Future<ApiResult<Map<String, dynamic>>> getCurrentSeason() async {
    try {
      final uri =
          Uri.parse('${AppConstants.baseUrl}/api/v1/rankings/season');
      final response = await _makeRequest('GET', uri);
      if (response.success && response.data != null) {
        return ApiResult.success(response.data!);
      }
      return ApiResult.error(response.error ?? '取得賽季資訊失敗');
    } catch (e) {
      return ApiResult.error('取得賽季資訊失敗: $e');
    }
  }

  // ==================== 圖鑑 API ====================

  /// 取得全卡牌列表（含收藏狀態）
  Future<ApiResult<Map<String, dynamic>>> getCodexCards() async {
    try {
      final uri = Uri.parse(
          '${AppConstants.baseUrl}${AppConstants.codexEndpoint}/cards');
      final response = await _makeRequest('GET', uri);
      if (response.success && response.data != null) {
        return ApiResult.success(response.data!);
      }
      return ApiResult.error(response.error ?? '取得卡牌列表失敗');
    } catch (e) {
      return ApiResult.error('取得卡牌列表失敗: $e');
    }
  }

  /// 取得我的收藏
  Future<ApiResult<Map<String, dynamic>>> getCollection() async {
    try {
      final uri = Uri.parse(
          '${AppConstants.baseUrl}${AppConstants.codexEndpoint}/collection');
      final response = await _makeRequest('GET', uri);
      if (response.success && response.data != null) {
        return ApiResult.success(response.data!);
      }
      return ApiResult.error(response.error ?? '取得收藏失敗');
    } catch (e) {
      return ApiResult.error('取得收藏失敗: $e');
    }
  }

  /// 取得圖鑑統計
  Future<ApiResult<Map<String, dynamic>>> getCodexStats() async {
    try {
      final uri = Uri.parse(
          '${AppConstants.baseUrl}${AppConstants.codexEndpoint}/stats');
      final response = await _makeRequest('GET', uri);
      if (response.success && response.data != null) {
        return ApiResult.success(response.data!);
      }
      return ApiResult.error(response.error ?? '取得統計失敗');
    } catch (e) {
      return ApiResult.error('取得圖鑑統計失敗: $e');
    }
  }

  /// 取得成就列表（含進度）
  Future<ApiResult<Map<String, dynamic>>> getAchievements() async {
    try {
      final uri = Uri.parse(
          '${AppConstants.baseUrl}${AppConstants.codexEndpoint}/achievements');
      final response = await _makeRequest('GET', uri);
      if (response.success && response.data != null) {
        return ApiResult.success(response.data!);
      }
      return ApiResult.error(response.error ?? '取得成就失敗');
    } catch (e) {
      return ApiResult.error('取得成就列表失敗: $e');
    }
  }

  /// 領取成就獎勵
  Future<ApiResult<Map<String, dynamic>>> claimAchievement(
    String achievementId,
  ) async {
    try {
      final body = {'achievement_id': achievementId};
      final uri = Uri.parse(
          '${AppConstants.baseUrl}${AppConstants.codexEndpoint}/achievements/claim');
      final response = await _makeRequest('POST', uri, body: body);
      if (response.success && response.data != null) {
        return ApiResult.success(response.data!);
      }
      return ApiResult.error(response.error ?? '領取獎勵失敗');
    } catch (e) {
      return ApiResult.error('領取成就獎勵失敗: $e');
    }
  }

  void dispose() {
    _httpClient.close();
  }
}

/// API 結果包裝類
class ApiResult<T> {
  final bool success;
  final T? data;
  final String? error;

  const ApiResult._({
    required this.success,
    this.data,
    this.error,
  });

  factory ApiResult.success(T data) {
    return ApiResult._(success: true, data: data);
  }

  factory ApiResult.error(String error) {
    return ApiResult._(success: false, error: error);
  }
}

/// HTTP 回應內部類
class _HttpResponse {
  final bool success;
  final Map<String, dynamic>? data;
  final String? error;

  const _HttpResponse._({
    required this.success,
    this.data,
    this.error,
  });

  factory _HttpResponse.success(Map<String, dynamic> data) {
    return _HttpResponse._(success: true, data: data);
  }

  factory _HttpResponse.error(String error) {
    return _HttpResponse._(success: false, error: error);
  }
}

/// 認證資訊
class AuthInfo {
  final String token;
  final String playerId;
  final String playerName;
  final DateTime expiresAt;

  const AuthInfo({
    required this.token,
    required this.playerId,
    required this.playerName,
    required this.expiresAt,
  });

  factory AuthInfo.fromJson(Map<String, dynamic> json) {
    return AuthInfo(
      token: json['token'] as String,
      playerId: json['player_id'] as String,
      playerName: json['player_name'] as String,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(json['expires_at'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'player_id': playerId,
      'player_name': playerName,
      'expires_at': expiresAt.millisecondsSinceEpoch,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}