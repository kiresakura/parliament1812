import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/room.dart';
import '../models/player.dart';
import '../models/message.dart';
import '../models/vote.dart';
import '../models/event.dart';
import '../models/card.dart';
import '../models/player_resources.dart';

/// API 服務 - 處理所有 HTTP 請求
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String get baseUrl => AppConfig.currentApiUrl;

  // HTTP Headers
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ==================== 房間 API ====================

  /// 建立房間 - 返回簡化結果
  Future<CreateRoomResult> createRoom({required String hostNickname}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/rooms'),
        headers: _headers,
        body: jsonEncode({'host_nickname': hostNickname}),
      );
      return _handleResponse(response, (data) => CreateRoomResult.fromJson(data));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: '無法連接伺服器，請檢查網路連線',
      );
    }
  }

  /// 取得房間資訊
  Future<Room> getRoom(String roomCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/rooms/$roomCode'),
        headers: _headers,
      );
      return _handleResponse(response, (data) => Room.fromJson(data));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: '無法連接伺服器，請檢查網路連線',
      );
    }
  }

  /// 加入房間
  Future<Player> joinRoom({
    required String roomCode,
    required String nickname,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/rooms/$roomCode/join'),
        headers: _headers,
        body: jsonEncode({'nickname': nickname}),
      );
      return _handleResponse(response, (data) => Player.fromJson(data));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: '無法連接伺服器，請檢查網路連線',
      );
    }
  }

  /// 取得房間內所有玩家
  Future<List<Player>> getRoomPlayers(String roomCode) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/rooms/$roomCode/players'),
      headers: _headers,
    );
    return _handleResponse(response, (data) {
      // 後端直接返回列表，不是 {'players': [...]}
      final players = data is List ? data : (data['players'] as List);
      return players.map((p) => Player.fromJson(p)).toList();
    });
  }

  // ==================== 玩家 API ====================

  /// NFC 掃卡分配角色
  /// 返回掃卡結果，包含 role_type, role_index 等資訊
  Future<NfcScanResult> scanNfc({
    required String roomCode,
    required String playerId,
    required String cardId,
    required String signature,
  }) async {
    // player_id 應該是 query parameter
    final response = await http.post(
      Uri.parse('$baseUrl/api/rooms/$roomCode/scan-nfc?player_id=$playerId'),
      headers: _headers,
      body: jsonEncode({
        'card_id': cardId,
        'secret_hash': signature, // 後端期望 secret_hash
      }),
    );
    return _handleResponse(response, (data) => NfcScanResult.fromJson(data));
  }

  /// 手動輸入角色代碼分配角色（NFC 備用方案）
  /// 返回結果類似 NFC 掃描，包含 role_type, role_index 等資訊
  Future<ManualRoleResult> assignRoleManually({
    required String roomCode,
    required String playerId,
    required String roleCode,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/rooms/$roomCode/assign-role-manual'),
      headers: _headers,
      body: jsonEncode({
        'player_id': playerId,
        'role_code': roleCode,
      }),
    );
    return _handleResponse(response, (data) => ManualRoleResult.fromJson(data));
  }

  /// 取得玩家的秘密任務
  /// 後端需要 requesting_player_id 來驗證是否為本人請求
  Future<SecretMission> getSecretMission(String playerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/players/$playerId/secret?requesting_player_id=$playerId'),
      headers: _headers,
    );
    return _handleResponse(response, (data) => SecretMission.fromJson(data));
  }

  // ==================== 私訊 API ====================

  /// 發送私訊
  Future<Message> sendMessage({
    required String roomCode,
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/messages?sender_id=$senderId&room_code=$roomCode'),
      headers: _headers,
      body: jsonEncode({
        'receiver_id': receiverId,
        'content': content,
      }),
    );
    return _handleResponse(response, (data) => Message.fromJson(data));
  }

  /// 取得私訊列表
  Future<List<Message>> getMessages({
    required String roomCode,
    required String playerId,
    String? otherPlayerId,
    int limit = 50,
    int offset = 0,
  }) async {
    var url = '$baseUrl/api/messages?player_id=$playerId&room_code=$roomCode&limit=$limit&offset=$offset';
    if (otherPlayerId != null) {
      url += '&other_player_id=$otherPlayerId';
    }

    final response = await http.get(Uri.parse(url), headers: _headers);
    return _handleResponse(response, (data) {
      final messages = data['messages'] as List;
      return messages.map((m) => Message.fromJson(m)).toList();
    });
  }

  /// 取得對話列表
  Future<List<Conversation>> getConversations({
    required String roomCode,
    required String playerId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/messages/conversations?player_id=$playerId&room_code=$roomCode'),
      headers: _headers,
    );
    return _handleResponse(response, (data) {
      final conversations = data['conversations'] as List;
      return conversations.map((c) => Conversation.fromJson(c)).toList();
    });
  }

  /// 標記訊息為已讀
  Future<void> markMessagesAsRead({
    required String playerId,
    List<String>? messageIds,
    String? senderId,
  }) async {
    var url = '$baseUrl/api/messages/read?player_id=$playerId';
    if (senderId != null) {
      url += '&sender_id=$senderId';
    }

    final response = await http.put(
      Uri.parse(url),
      headers: _headers,
      body: jsonEncode({'message_ids': messageIds}),
    );
    _handleResponse(response, (data) => null);
  }

  // ==================== 投票 API ====================

  /// 投票
  Future<Vote> castVote({
    required String roomCode,
    required String playerId,
    required int round,
    required String choice,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/rooms/$roomCode/votes?player_id=$playerId'),
      headers: _headers,
      body: jsonEncode({
        'round': round,
        'choice': choice,
      }),
    );
    return _handleResponse(response, (data) => Vote.fromJson(data));
  }

  /// 取得投票進度
  Future<Map<String, dynamic>> getVoteProgress({
    required String roomCode,
    required int round,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/rooms/$roomCode/votes/progress?round=$round'),
      headers: _headers,
    );
    return _handleResponse(response, (data) => data as Map<String, dynamic>);
  }

  /// 取得投票結果
  Future<dynamic> getVoteResult({
    required String roomCode,
    required int round,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/rooms/$roomCode/votes/result?round=$round'),
      headers: _headers,
    );
    return _handleResponse(response, (data) {
      if (round == 1) {
        return Round1Result.fromJson(data);
      } else {
        return Round2Result.fromJson(data);
      }
    });
  }

  /// 取得投票選項
  Future<List<VoteOption>> getVoteOptions(String roomCode) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/rooms/$roomCode/votes/options'),
      headers: _headers,
    );
    return _handleResponse(response, (data) {
      final options = data['options'] as List;
      return options.map<VoteOption>((o) => VoteOption.fromJson(o)).toList();
    });
  }

  // ==================== 事件 API ====================

  /// 取得可用事件（僅主持人）
  Future<List<GameEvent>> getAvailableEvents({
    required String roomCode,
    required String hostId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/rooms/$roomCode/events?host_id=$hostId'),
      headers: _headers,
    );
    return _handleResponse(response, (data) {
      final events = data['events'] as List;
      return events.map((e) => GameEvent.fromJson(e)).toList();
    });
  }

  /// 觸發事件（僅主持人）
  Future<TriggeredEvent> triggerEvent({
    required String roomCode,
    required String hostId,
    required String eventId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/rooms/$roomCode/events/trigger?host_id=$hostId'),
      headers: _headers,
      body: jsonEncode({'event_id': eventId}),
    );
    return _handleResponse(response, (data) => TriggeredEvent.fromJson(data));
  }

  /// 隨機觸發事件（僅主持人）
  Future<TriggeredEvent> randomTriggerEvent({
    required String roomCode,
    required String hostId,
    int? minSeverity,
    int? maxSeverity,
  }) async {
    var url = '$baseUrl/api/rooms/$roomCode/events/random?host_id=$hostId';
    if (minSeverity != null) url += '&min_severity=$minSeverity';
    if (maxSeverity != null) url += '&max_severity=$maxSeverity';

    final response = await http.post(Uri.parse(url), headers: _headers);
    return _handleResponse(response, (data) => TriggeredEvent.fromJson(data));
  }

  /// 取得已觸發事件歷史
  Future<List<TriggeredEvent>> getEventHistory(String roomCode) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/rooms/$roomCode/events/history'),
      headers: _headers,
    );
    return _handleResponse(response, (data) {
      final events = data['events'] as List;
      return events.map((e) => TriggeredEvent.fromJson(e)).toList();
    });
  }

  // ==================== 卡牌系統 API ====================

  /// 取得所有卡牌定義
  Future<List<GameCard>> getCardDefinitions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/cards'),
        headers: _headers,
      );
      return _handleResponse(response, (data) {
        final cards = data is List ? data : (data['cards'] as List);
        return cards.map((c) => GameCard.fromJson(c)).toList();
      });
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: '無法載入卡牌資料',
      );
    }
  }

  /// 抽取卡牌
  Future<DrawCardsApiResult> drawCards({
    required String roomCode,
    required String playerId,
    required int count,
    bool includeCharacterCards = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/rooms/$roomCode/draw-cards?player_id=$playerId'),
        headers: _headers,
        body: jsonEncode({
          'count': count,
          'include_character_cards': includeCharacterCards,
        }),
      );
      return _handleResponse(response, (data) => DrawCardsApiResult.fromJson(data));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: '無法抽取卡牌',
      );
    }
  }

  /// 取得玩家手牌
  Future<PlayerHandApiResult> getPlayerHand({
    required String roomCode,
    required String playerId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/rooms/$roomCode/players/$playerId/hand'),
        headers: _headers,
      );
      return _handleResponse(response, (data) => PlayerHandApiResult.fromJson(data));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: '無法取得手牌',
      );
    }
  }

  /// 使用卡牌
  Future<CardUseApiResult> useCard({
    required String roomCode,
    required String playerId,
    required String cardInstanceId,
    List<String>? targetIds,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/rooms/$roomCode/use-card?player_id=$playerId'),
        headers: _headers,
        body: jsonEncode({
          'card_instance_id': cardInstanceId,
          'target_ids': targetIds ?? [],
        }),
      );
      return _handleResponse(response, (data) => CardUseApiResult.fromJson(data));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: '無法使用卡牌',
      );
    }
  }

  /// 使用防禦卡
  Future<CardUseApiResult> useDefenseCard({
    required String roomCode,
    required String playerId,
    required String cardInstanceId,
    required String attackCardId,
    required String attackerId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/rooms/$roomCode/use-defense-card?player_id=$playerId'),
        headers: _headers,
        body: jsonEncode({
          'card_instance_id': cardInstanceId,
          'attack_card_id': attackCardId,
          'attacker_id': attackerId,
        }),
      );
      return _handleResponse(response, (data) => CardUseApiResult.fromJson(data));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: '無法使用防禦卡',
      );
    }
  }

  /// 取得玩家資源
  Future<PlayerResources> getPlayerResources({
    required String roomCode,
    required String playerId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/rooms/$roomCode/players/$playerId/resources'),
        headers: _headers,
      );
      return _handleResponse(response, (data) => PlayerResources.fromJson(data));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: '無法取得玩家資源',
      );
    }
  }

  // ==================== 遊戲流程 API ====================

  /// 開始遊戲（僅主持人）
  Future<void> startGame(String roomCode, String playerId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/rooms/$roomCode/start?player_id=$playerId'),
      headers: _headers,
    );
    _handleResponse(response, (data) => null);
  }

  /// 切換遊戲階段（僅主持人）
  Future<Room> changePhase({
    required String roomCode,
    required String hostId,
    required int phase,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/rooms/$roomCode/phase?host_id=$hostId'),
      headers: _headers,
      body: jsonEncode({'phase': phase}),
    );
    return _handleResponse(response, (data) => Room.fromJson(data));
  }

  /// 設定計時器（僅主持人）
  Future<Room> setTimer({
    required String roomCode,
    required String hostId,
    required int durationMinutes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/rooms/$roomCode/timer?host_id=$hostId'),
      headers: _headers,
      body: jsonEncode({'duration_minutes': durationMinutes}),
    );
    return _handleResponse(response, (data) => Room.fromJson(data));
  }

  /// 開始計時器（僅主持人）
  Future<DateTime> startTimer({
    required String roomCode,
    required String hostId,
    required int minutes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/rooms/$roomCode/timer?host_id=$hostId'),
      headers: _headers,
      body: jsonEncode({'duration_minutes': minutes}),
    );
    return _handleResponse(response, (data) {
      final endAt = data['timer_end_at'] ?? data['timerEndAt'];
      if (endAt != null) {
        return DateTime.parse(endAt);
      }
      return DateTime.now().add(Duration(minutes: minutes));
    });
  }

  /// 停止計時器（僅主持人）
  Future<void> stopTimer({
    required String roomCode,
    required String hostId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/rooms/$roomCode/timer?host_id=$hostId'),
      headers: _headers,
    );
    _handleResponse(response, (data) => null);
  }

  /// 開始投票（僅主持人）
  Future<void> startVoting({
    required String roomCode,
    required String hostId,
    required int round,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/rooms/$roomCode/votes/start?host_id=$hostId'),
      headers: _headers,
      body: jsonEncode({'round': round}),
    );
    _handleResponse(response, (data) => null);
  }

  /// 關閉房間（僅主持人）
  Future<void> closeRoom(String roomCode) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/rooms/$roomCode'),
      headers: _headers,
    );
    _handleResponse(response, (data) => null);
  }

  // ==================== 通用處理 ====================

  /// 處理 API 回應
  T _handleResponse<T>(http.Response response, T Function(dynamic) parser) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return parser(data);
      } catch (e) {
        throw ApiException(
          statusCode: response.statusCode,
          message: '解析回應失敗: $e',
        );
      }
    } else {
      String errorMessage = '發生錯誤';
      try {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        errorMessage = error['detail'] ?? error['message'] ?? '伺服器錯誤';
      } catch (_) {
        errorMessage = '伺服器無回應 (${response.statusCode})';
      }
      throw ApiException(
        statusCode: response.statusCode,
        message: errorMessage,
      );
    }
  }
}

/// 建立房間結果
class CreateRoomResult {
  final String code;
  final String roomId;
  final String playerId;
  final String message;

  CreateRoomResult({
    required this.code,
    required this.roomId,
    required this.playerId,
    required this.message,
  });

  factory CreateRoomResult.fromJson(Map<String, dynamic> json) {
    return CreateRoomResult(
      code: json['code'] as String? ?? '',
      roomId: json['room_id'] as String? ?? '',
      playerId: json['player_id'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }
}

/// NFC 掃描結果
class NfcScanResult {
  final String message;
  final String playerId;
  final String roleType;
  final int roleIndex;
  final String? roleName;
  final String? secretMissionId;

  NfcScanResult({
    required this.message,
    required this.playerId,
    required this.roleType,
    required this.roleIndex,
    this.roleName,
    this.secretMissionId,
  });

  factory NfcScanResult.fromJson(Map<String, dynamic> json) {
    // 安全解析整數，支援字串或整數
    int parseIntSafe(dynamic value, [int defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return NfcScanResult(
      message: json['message'] as String? ?? '',
      playerId: json['player_id'] as String? ?? '',
      roleType: json['role_type'] as String? ?? '',
      roleIndex: parseIntSafe(json['role_index']),
      roleName: json['role_name'] as String?,
      secretMissionId: json['secret_mission_id'] as String?,
    );
  }
}

/// 手動角色分配結果
class ManualRoleResult {
  final String message;
  final String playerId;
  final String roleType;
  final int roleIndex;
  final String? roleName;
  final String? roleOccupation;
  final String? roleDescription;
  final String? roleBackground;
  final String? rolePublicStance;
  final String? avatarColor;
  final String? secretMissionId;

  ManualRoleResult({
    required this.message,
    required this.playerId,
    required this.roleType,
    required this.roleIndex,
    this.roleName,
    this.roleOccupation,
    this.roleDescription,
    this.roleBackground,
    this.rolePublicStance,
    this.avatarColor,
    this.secretMissionId,
  });

  factory ManualRoleResult.fromJson(Map<String, dynamic> json) {
    // 安全解析整數，支援字串或整數
    int parseIntSafe(dynamic value, [int defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return ManualRoleResult(
      message: json['message'] as String? ?? '',
      playerId: json['player_id'] as String? ?? '',
      roleType: json['role_type'] as String? ?? '',
      roleIndex: parseIntSafe(json['role_index']),
      roleName: json['role_name'] as String?,
      roleOccupation: json['role_occupation'] as String?,
      roleDescription: json['role_description'] as String?,
      roleBackground: json['role_background'] as String?,
      rolePublicStance: json['role_public_stance'] as String?,
      avatarColor: json['avatar_color'] as String?,
      secretMissionId: json['secret_mission_id'] as String?,
    );
  }
}

/// API 例外
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException: [$statusCode] $message';
}

/// 抽卡 API 結果
class DrawCardsApiResult {
  final List<HandCard> drawnCards;
  final List<GameCard> characterCards;
  final int totalHandSize;
  final int deckRemaining;
  final String? message;

  DrawCardsApiResult({
    required this.drawnCards,
    this.characterCards = const [],
    required this.totalHandSize,
    this.deckRemaining = 0,
    this.message,
  });

  factory DrawCardsApiResult.fromJson(Map<String, dynamic> json) {
    final cardsData = json['drawn_cards'] ?? json['drawnCards'] ?? [];
    final cards = (cardsData as List)
        .map((c) => HandCard.fromJson(c as Map<String, dynamic>))
        .toList();

    // 解析角色專屬卡
    final charCardsData = json['character_cards'] ?? json['characterCards'] ?? [];
    final charCards = (charCardsData as List)
        .map((c) => GameCard.fromJson(c as Map<String, dynamic>))
        .toList();

    return DrawCardsApiResult(
      drawnCards: cards,
      characterCards: charCards,
      totalHandSize: json['total_hand_size'] ?? json['totalHandSize'] ?? cards.length,
      deckRemaining: json['deck_remaining'] ?? json['deckRemaining'] ?? 0,
      message: json['message'] as String?,
    );
  }
}

/// 玩家手牌 API 結果
class PlayerHandApiResult {
  final List<HandCard> hand;
  final List<GameCard> characterCards;
  final int handSize;
  final int maxHandSize;

  PlayerHandApiResult({
    required this.hand,
    this.characterCards = const [],
    required this.handSize,
    this.maxHandSize = 10,
  });

  factory PlayerHandApiResult.fromJson(Map<String, dynamic> json) {
    final cardsData = json['hand'] ?? json['cards'] ?? [];
    final cards = (cardsData as List)
        .map((c) => HandCard.fromJson(c as Map<String, dynamic>))
        .toList();

    // 解析角色專屬卡
    final charCardsData = json['character_cards'] ?? json['characterCards'] ?? [];
    final charCards = (charCardsData as List)
        .map((c) => GameCard.fromJson(c as Map<String, dynamic>))
        .toList();

    return PlayerHandApiResult(
      hand: cards,
      characterCards: charCards,
      handSize: json['hand_size'] ?? json['handSize'] ?? cards.length,
      maxHandSize: json['max_hand_size'] ?? json['maxHandSize'] ?? 10,
    );
  }
}

/// 卡牌使用 API 結果
class CardUseApiResult {
  final bool success;
  final String? message;
  final String cardId;
  final String? cardName;
  final List<String> targetIds;
  final Map<String, dynamic>? effectResult;
  final List<ResourceChange>? resourceChanges;
  final bool wasBlocked;
  final String? blockedBy;
  final String? blockedByCardId;

  CardUseApiResult({
    required this.success,
    this.message,
    required this.cardId,
    this.cardName,
    this.targetIds = const [],
    this.effectResult,
    this.resourceChanges,
    this.wasBlocked = false,
    this.blockedBy,
    this.blockedByCardId,
  });

  /// 從 effectResult 解析 CardEffect
  CardEffect? get appliedEffect {
    if (effectResult == null) return null;
    return CardEffect.fromJson(effectResult!);
  }

  factory CardUseApiResult.fromJson(Map<String, dynamic> json) {
    // 解析資源變化
    List<ResourceChange>? changes;
    if (json['resource_changes'] != null) {
      changes = (json['resource_changes'] as List)
          .map((c) => ResourceChange.fromJson(c as Map<String, dynamic>))
          .toList();
    } else if (json['resourceChanges'] != null) {
      changes = (json['resourceChanges'] as List)
          .map((c) => ResourceChange.fromJson(c as Map<String, dynamic>))
          .toList();
    }

    // 解析目標 ID 列表
    List<String> targets = [];
    if (json['target_ids'] != null) {
      targets = (json['target_ids'] as List).map((e) => e.toString()).toList();
    } else if (json['targetIds'] != null) {
      targets = (json['targetIds'] as List).map((e) => e.toString()).toList();
    }

    return CardUseApiResult(
      success: json['success'] ?? true,
      message: json['message'] as String?,
      cardId: json['card_id'] ?? json['cardId'] ?? '',
      cardName: json['card_name'] ?? json['cardName'] as String?,
      targetIds: targets,
      effectResult: json['effect_result'] ?? json['effectResult'] as Map<String, dynamic>?,
      resourceChanges: changes,
      wasBlocked: json['was_blocked'] ?? json['wasBlocked'] ?? false,
      blockedBy: json['blocked_by'] ?? json['blockedBy'] as String?,
      blockedByCardId: json['blocked_by_card_id'] ?? json['blockedByCardId'] as String?,
    );
  }
}
