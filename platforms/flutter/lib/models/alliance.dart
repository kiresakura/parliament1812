/// 同盟資料模型
/// 1812 國會風雲 - 同盟系統
library alliance;

/// 同盟類型枚舉
enum AllianceType {
  political,  // 政治同盟
  economic,   // 經濟同盟
  secret,     // 秘密同盟
  temporary,  // 暫時同盟
}

/// 同盟類型顯示
extension AllianceTypeExtension on AllianceType {
  String get displayName {
    switch (this) {
      case AllianceType.political:
        return '政治同盟';
      case AllianceType.economic:
        return '經濟同盟';
      case AllianceType.secret:
        return '秘密同盟';
      case AllianceType.temporary:
        return '暫時同盟';
    }
  }

  String get icon {
    switch (this) {
      case AllianceType.political:
        return '🏛️';
      case AllianceType.economic:
        return '💰';
      case AllianceType.secret:
        return '🤫';
      case AllianceType.temporary:
        return '⏳';
    }
  }

  static AllianceType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'political':
        return AllianceType.political;
      case 'economic':
        return AllianceType.economic;
      case 'secret':
        return AllianceType.secret;
      case 'temporary':
        return AllianceType.temporary;
      default:
        return AllianceType.political;
    }
  }
}

/// 同盟狀態枚舉
enum AllianceStatus {
  pending,  // 待確認
  active,   // 有效同盟
  broken,   // 已破裂（背叛）
}

/// 同盟狀態顯示
extension AllianceStatusExtension on AllianceStatus {
  String get displayName {
    switch (this) {
      case AllianceStatus.pending:
        return '待確認';
      case AllianceStatus.active:
        return '有效同盟';
      case AllianceStatus.broken:
        return '已破裂';
    }
  }

  String get icon {
    switch (this) {
      case AllianceStatus.pending:
        return '⏳';
      case AllianceStatus.active:
        return '🤝';
      case AllianceStatus.broken:
        return '💔';
    }
  }

  static AllianceStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return AllianceStatus.pending;
      case 'active':
        return AllianceStatus.active;
      case 'broken':
        return AllianceStatus.broken;
      default:
        return AllianceStatus.pending;
    }
  }
}

/// 同盟模型
class Alliance {
  final String id;
  final String roomId;
  final String player1Id;
  final String player2Id;
  final AllianceType type;
  final AllianceStatus status;
  final DateTime formedAt;
  final DateTime? brokenAt;
  final String? betrayerId;

  /// 每位玩家最多同盟數
  static const int maxAlliancesPerPlayer = 2;

  /// 背叛後冷卻回合數
  static const int betrayalCooldownTurns = 2;

  const Alliance({
    required this.id,
    required this.roomId,
    required this.player1Id,
    required this.player2Id,
    this.type = AllianceType.political,
    required this.status,
    required this.formedAt,
    this.brokenAt,
    this.betrayerId,
  });

  /// 是否為有效同盟
  bool get isActive => status == AllianceStatus.active;

  /// 是否已破裂
  bool get isBroken => status == AllianceStatus.broken;

  /// 是否待確認
  bool get isPending => status == AllianceStatus.pending;

  /// 檢查玩家是否為此同盟的成員
  bool isMember(String playerId) {
    return player1Id == playerId || player2Id == playerId;
  }

  /// 取得同盟中的另一位玩家 ID
  String? getPartnerId(String playerId) {
    if (player1Id == playerId) return player2Id;
    if (player2Id == playerId) return player1Id;
    return null;
  }

  /// 檢查玩家是否為背叛者
  bool isBetrayer(String playerId) {
    return betrayerId == playerId;
  }

  /// 檢查玩家是否為受害者
  bool isVictim(String playerId) {
    if (!isBroken || betrayerId == null) return false;
    return isMember(playerId) && !isBetrayer(playerId);
  }

  /// 同盟持續時間
  Duration get duration {
    final endTime = brokenAt ?? DateTime.now();
    return endTime.difference(formedAt);
  }

  factory Alliance.fromJson(Map<String, dynamic> json) {
    return Alliance(
      id: json['id'] ?? '',
      roomId: json['room_id'] ?? json['roomId'] ?? '',
      player1Id: json['player1_id'] ?? json['player1Id'] ?? '',
      player2Id: json['player2_id'] ?? json['player2Id'] ?? '',
      type: AllianceTypeExtension.fromString(
          json['type'] ?? 'political'),
      status: AllianceStatusExtension.fromString(
          json['status'] ?? 'pending'),
      formedAt: json['formed_at'] != null
          ? DateTime.parse(json['formed_at'])
          : json['formedAt'] != null
              ? DateTime.parse(json['formedAt'])
              : DateTime.now(),
      brokenAt: json['broken_at'] != null
          ? DateTime.parse(json['broken_at'])
          : json['brokenAt'] != null
              ? DateTime.parse(json['brokenAt'])
              : null,
      betrayerId: json['betrayer_id'] ?? json['betrayerId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'player1_id': player1Id,
      'player2_id': player2Id,
      'type': type.name,
      'status': status.name,
      'formed_at': formedAt.toIso8601String(),
      'broken_at': brokenAt?.toIso8601String(),
      'betrayer_id': betrayerId,
    };
  }

  Alliance copyWith({
    String? id,
    String? roomId,
    String? player1Id,
    String? player2Id,
    AllianceType? type,
    AllianceStatus? status,
    DateTime? formedAt,
    DateTime? brokenAt,
    String? betrayerId,
  }) {
    return Alliance(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      player1Id: player1Id ?? this.player1Id,
      player2Id: player2Id ?? this.player2Id,
      type: type ?? this.type,
      status: status ?? this.status,
      formedAt: formedAt ?? this.formedAt,
      brokenAt: brokenAt ?? this.brokenAt,
      betrayerId: betrayerId ?? this.betrayerId,
    );
  }

  /// 確認同盟（從 pending 變為 active）
  Alliance confirm() {
    if (status != AllianceStatus.pending) return this;
    return copyWith(status: AllianceStatus.active);
  }

  /// 背叛同盟
  Alliance betray(String betrayerPlayerId) {
    if (status != AllianceStatus.active) return this;
    if (!isMember(betrayerPlayerId)) return this;
    return copyWith(
      status: AllianceStatus.broken,
      brokenAt: DateTime.now(),
      betrayerId: betrayerPlayerId,
    );
  }

  @override
  String toString() =>
      'Alliance(id: $id, ${type.icon} ${status.icon} $player1Id ↔ $player2Id, type: ${type.displayName}, status: ${status.displayName})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Alliance &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// 同盟請求模型
class AllianceRequest {
  final String id;
  final String roomId;
  final String fromPlayerId;
  final String toPlayerId;
  final DateTime requestedAt;
  final bool isAccepted;
  final bool isRejected;

  const AllianceRequest({
    required this.id,
    required this.roomId,
    required this.fromPlayerId,
    required this.toPlayerId,
    required this.requestedAt,
    this.isAccepted = false,
    this.isRejected = false,
  });

  /// 是否待回應
  bool get isPending => !isAccepted && !isRejected;

  factory AllianceRequest.fromJson(Map<String, dynamic> json) {
    return AllianceRequest(
      id: json['id'] ?? '',
      roomId: json['room_id'] ?? json['roomId'] ?? '',
      fromPlayerId: json['from_player_id'] ?? json['fromPlayerId'] ?? '',
      toPlayerId: json['to_player_id'] ?? json['toPlayerId'] ?? '',
      requestedAt: json['requested_at'] != null
          ? DateTime.parse(json['requested_at'])
          : json['requestedAt'] != null
              ? DateTime.parse(json['requestedAt'])
              : DateTime.now(),
      isAccepted: json['is_accepted'] ?? json['isAccepted'] ?? false,
      isRejected: json['is_rejected'] ?? json['isRejected'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'from_player_id': fromPlayerId,
      'to_player_id': toPlayerId,
      'requested_at': requestedAt.toIso8601String(),
      'is_accepted': isAccepted,
      'is_rejected': isRejected,
    };
  }

  AllianceRequest copyWith({
    String? id,
    String? roomId,
    String? fromPlayerId,
    String? toPlayerId,
    DateTime? requestedAt,
    bool? isAccepted,
    bool? isRejected,
  }) {
    return AllianceRequest(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      fromPlayerId: fromPlayerId ?? this.fromPlayerId,
      toPlayerId: toPlayerId ?? this.toPlayerId,
      requestedAt: requestedAt ?? this.requestedAt,
      isAccepted: isAccepted ?? this.isAccepted,
      isRejected: isRejected ?? this.isRejected,
    );
  }

  /// 接受請求
  AllianceRequest accept() => copyWith(isAccepted: true);

  /// 拒絕請求
  AllianceRequest reject() => copyWith(isRejected: true);

  @override
  String toString() =>
      'AllianceRequest(from: $fromPlayerId, to: $toPlayerId, pending: $isPending)';
}

/// 背叛冷卻記錄
class BetrayalCooldown {
  final String playerId;
  final int remainingTurns;
  final DateTime startedAt;

  const BetrayalCooldown({
    required this.playerId,
    required this.remainingTurns,
    required this.startedAt,
  });

  /// 是否仍在冷卻中
  bool get isActive => remainingTurns > 0;

  /// 減少一回合冷卻
  BetrayalCooldown decrementTurn() {
    return BetrayalCooldown(
      playerId: playerId,
      remainingTurns: (remainingTurns - 1).clamp(0, Alliance.betrayalCooldownTurns),
      startedAt: startedAt,
    );
  }

  factory BetrayalCooldown.fromJson(Map<String, dynamic> json) {
    return BetrayalCooldown(
      playerId: json['player_id'] ?? json['playerId'] ?? '',
      remainingTurns: json['remaining_turns'] ?? json['remainingTurns'] ?? 0,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : json['startedAt'] != null
              ? DateTime.parse(json['startedAt'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'player_id': playerId,
      'remaining_turns': remainingTurns,
      'started_at': startedAt.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'BetrayalCooldown(player: $playerId, remaining: $remainingTurns turns)';
}
