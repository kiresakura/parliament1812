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
    return Player(
      id: json['id'],
      roomId: json['room_id'],
      nickname: json['nickname'],
      roleType: json['role_type'],
      roleIndex: json['role_index'],
      secretMissionId: json['secret_mission_id'],
      isHost: json['is_host'] ?? false,
      joinedAt: DateTime.parse(json['joined_at']),
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
    return Role(
      roleType: json['role_type'],
      index: json['index'],
      name: json['name'],
      age: json['age'],
      description: json['description'],
      stance: json['stance'] ?? '',
      background: json['background'] ?? '',
      characteristics: List<String>.from(json['characteristics'] ?? []),
      talkingPoints: List<String>.from(json['talking_points'] ?? []),
      quote: json['quote'] ?? '',
    );
  }

  // 角色類型中文名稱
  static const Map<String, String> typeNames = {
    'worker': '紡織工人',
    'factory': '工廠主',
    'luddite': '盧德派',
    'reformer': '改革者',
    'mp': '議員',
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
    return SecretMission(
      id: json['id'],
      roleType: json['role_type'],
      title: json['title'],
      description: json['description'],
      successCondition: json['success_condition'],
      points: json['points'] ?? 50,
    );
  }
}
