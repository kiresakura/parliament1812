/// 玩家模型
class Player {
  final String id;
  final String roomId;
  final String nickname;
  final String? roleType;
  final int? roleIndex;
  final String? secretMissionId;
  final bool isHost;
  final DateTime joinedAt;

  // 角色詳細資訊（可選）
  final Role? role;
  final SecretMission? secretMission;

  Player({
    required this.id,
    required this.roomId,
    required this.nickname,
    this.roleType,
    this.roleIndex,
    this.secretMissionId,
    required this.isHost,
    required this.joinedAt,
    this.role,
    this.secretMission,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    // 安全解析 role_index，支援字串或整數
    int? parseRoleIndex(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return Player(
      id: json['id'] as String? ?? '',
      roomId: json['room_id'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      roleType: json['role_type'] as String?,
      roleIndex: parseRoleIndex(json['role_index']),
      secretMissionId: json['secret_mission_id'] as String?,
      isHost: json['is_host'] as bool? ?? false,
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'])
          : DateTime.now(),
      role: json['role'] != null ? Role.fromJson(json['role']) : null,
      secretMission: json['secret_mission'] != null
          ? SecretMission.fromJson(json['secret_mission'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'nickname': nickname,
      'role_type': roleType,
      'role_index': roleIndex,
      'secret_mission_id': secretMissionId,
      'is_host': isHost,
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  bool get hasRole => roleType != null;

  /// 複製並更新部分屬性
  Player copyWith({
    String? id,
    String? roomId,
    String? nickname,
    String? roleType,
    int? roleIndex,
    String? secretMissionId,
    bool? isHost,
    DateTime? joinedAt,
    Role? role,
    SecretMission? secretMission,
  }) {
    return Player(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      nickname: nickname ?? this.nickname,
      roleType: roleType ?? this.roleType,
      roleIndex: roleIndex ?? this.roleIndex,
      secretMissionId: secretMissionId ?? this.secretMissionId,
      isHost: isHost ?? this.isHost,
      joinedAt: joinedAt ?? this.joinedAt,
      role: role ?? this.role,
      secretMission: secretMission ?? this.secretMission,
    );
  }
}

/// 角色模型
class Role {
  final String roleType;
  final int index;
  final String name;
  final int age;
  final String description;
  final String stance;
  final String background;
  final List<String> characteristics;
  final List<String> talkingPoints;
  final String quote;

  Role({
    required this.roleType,
    required this.index,
    required this.name,
    required this.age,
    required this.description,
    required this.stance,
    required this.background,
    required this.characteristics,
    required this.talkingPoints,
    required this.quote,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    // 安全解析整數欄位，支援字串或整數
    int parseIntField(dynamic value, [int defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return Role(
      roleType: json['role_type'] ?? '',
      index: parseIntField(json['index']),
      name: json['name'] ?? '',
      age: parseIntField(json['age']),
      description: json['description'] ?? '',
      stance: json['stance'] ?? '',
      background: json['background'] ?? '',
      characteristics: List<String>.from(json['characteristics'] ?? []),
      talkingPoints: List<String>.from(json['talking_points'] ?? []),
      quote: json['quote'] ?? '',
    );
  }

  // 角色類型中文名稱 - 根據企劃書設定
  static const Map<String, String> typeNames = {
    'worker': '紡織工人',
    'factory': '工廠主',
    'luddite': '盧德派成員',
    'reformer': '社會改革者',
    'mp': '國會議員',
  };

  String get typeName => typeNames[roleType] ?? '未知';
}

/// 秘密任務模型
class SecretMission {
  final String id;
  final String roleType;
  final String title;
  final String description;
  final String? successCondition;
  final int points;

  SecretMission({
    required this.id,
    required this.roleType,
    required this.title,
    required this.description,
    this.successCondition,
    required this.points,
  });

  factory SecretMission.fromJson(Map<String, dynamic> json) {
    // 安全解析整數欄位
    int parsePoints(dynamic value) {
      if (value == null) return 50;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 50;
      return 50;
    }

    return SecretMission(
      id: json['id'] ?? '',
      roleType: json['role_type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      successCondition: json['success_condition'],
      points: parsePoints(json['points']),
    );
  }
}
