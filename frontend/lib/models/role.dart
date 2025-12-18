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
    return Role(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
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

  /// 預設角色列表
  static const List<Role> defaultRoles = [
    Role(
      id: 'worker',
      type: 'worker',
      name: '湯瑪斯',
      age: 38,
      description: '諾丁漢的紡織工人，擁有20年織布經驗',
      stance: '機器搶走了我們的飯碗',
      color: '#4A6741',
    ),
    Role(
      id: 'factory',
      type: 'factory',
      name: '理查·威爾森',
      age: 45,
      description: '曼徹斯特紡織廠主，從小作坊發展成大工廠',
      stance: '機器是進步的象徵',
      color: '#8B4513',
    ),
    Role(
      id: 'luddite',
      type: 'luddite',
      name: '喬治',
      age: 28,
      description: '盧德派成員，主張以行動抵抗機器',
      stance: '必須摧毀這些奪走生計的機器',
      color: '#8B0000',
    ),
    Role(
      id: 'reformer',
      type: 'reformer',
      name: '羅伯特·歐文',
      age: 35,
      description: '改革派企業家，提倡工人權益',
      stance: '機器與工人可以共存',
      color: '#4169E1',
    ),
    Role(
      id: 'mp',
      type: 'mp',
      name: '威廉·乾茨傑拉德',
      age: 52,
      description: '國會議員，需要在各方利益間權衡',
      stance: '需要審慎考慮各方立場',
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
