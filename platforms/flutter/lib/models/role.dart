/// 角色模型
class Role {
  final String id;
  final String type;
  final String name;
  final int age;
  final String description;
  final String stance;
  final String color;

  const Role({
    required this.id,
    required this.type,
    required this.name,
    required this.age,
    required this.description,
    required this.stance,
    required this.color,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    // 安全解析整數欄位，支援字串或整數
    int parseAge(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return Role(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      age: parseAge(json['age']),
      description: json['description'] ?? '',
      stance: json['stance'] ?? '',
      color: json['color'] ?? '#8B4513',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'age': age,
      'description': description,
      'stance': stance,
      'color': color,
    };
  }

  /// 預設角色列表 - 根據企劃書設定
  static const List<Role> defaultRoles = [
    Role(
      id: 'worker',
      type: 'worker',
      name: '湯瑪斯',
      age: 38,
      description: '約克郡人，手工織布師傅，在這一行幹了二十多年，見證紡織業從手工到機器的轉變',
      stance: '機器搶走了我們的飯碗，必須限制或禁止',
      color: '#4A6741',
    ),
    Role(
      id: 'factory',
      type: 'factory',
      name: '理查·威爾森先生',
      age: 45,
      description: '曼徹斯特商人，擁有一間新式紡織工廠，配備蒸汽動力織機',
      stance: '機器代表進步，政府應該保護私有財產',
      color: '#8B4513',
    ),
    Role(
      id: 'luddite',
      type: 'luddite',
      name: '喬治「乃德·盧德」',
      age: 28,
      description: '前針織工，地下抵抗組織成員，已參與過多次破壞機器的行動',
      stance: '機器是工人的敵人，必須用行動摧毀它',
      color: '#8B0000',
    ),
    Role(
      id: 'reformer',
      type: 'reformer',
      name: '羅伯特·烏爾文',
      age: 35,
      description: '中產階級出身，辦過學校、寫過文章，相信教育和立法可以改善社會',
      stance: '問題不在機器，在於分配不公，應該立法保障工人',
      color: '#4169E1',
    ),
    Role(
      id: 'mp',
      type: 'mp',
      name: '威廉·菲茨傑拉德勳爵',
      age: 52,
      description: '托利黨議員，來自地方仕紳家庭，在鄉下擁有土地',
      stance: '維護秩序是首要任務，但也要找到讓各方都能接受的方案',
      color: '#483D8B',
    ),
  ];

  static Role? fromType(String type) {
    try {
      return defaultRoles.firstWhere((r) => r.type == type);
    } catch (_) {
      return null;
    }
  }
}
