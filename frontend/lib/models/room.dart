/// 房間模型
class Room {
  final String id;
  final String code;
  final String status;
  final int phase;
  final String phaseName;
  final int currentRound;
  final DateTime? timerEndAt;
  final int playerCount;
  final DateTime createdAt;

  Room({
    required this.id,
    required this.code,
    required this.status,
    required this.phase,
    required this.phaseName,
    required this.currentRound,
    this.timerEndAt,
    required this.playerCount,
    required this.createdAt,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      status: json['status'] as String? ?? 'waiting',
      phase: json['phase'] as int? ?? 1,
      phaseName: json['phase_name'] as String? ?? 'waiting',
      currentRound: json['current_round'] as int? ?? 0,
      timerEndAt: json['timer_end_at'] != null
          ? DateTime.parse(json['timer_end_at'])
          : null,
      playerCount: json['player_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'status': status,
      'phase': phase,
      'phase_name': phaseName,
      'current_round': currentRound,
      'timer_end_at': timerEndAt?.toIso8601String(),
      'player_count': playerCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // 遊戲階段常數
  static const Map<int, String> phaseNames = {
    1: '等待中',
    2: '角色研究',
    3: '私下密謀',
    4: '開場陳述',
    5: '突發事件 #1',
    6: '自由辯論',
    7: '突發事件 #2',
    8: '第一輪投票',
    9: '最後攻防',
    10: '第二輪投票',
    11: '結果揭曉',
    12: '遊戲結束',
  };

  String get phaseDisplayName => phaseNames[phase] ?? '未知階段';

  bool get isWaiting => status == 'waiting';
  bool get isPlaying => status == 'playing';
  bool get isFinished => status == 'finished';
}
