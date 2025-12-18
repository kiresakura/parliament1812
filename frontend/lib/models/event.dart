/// 突發事件模型
class GameEvent {
  final String id;
  final String title;
  final String description;
  final String? effectType;
  final int severity;

  GameEvent({
    required this.id,
    required this.title,
    required this.description,
    this.effectType,
    required this.severity,
  });

  factory GameEvent.fromJson(Map<String, dynamic> json) {
    return GameEvent(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      effectType: json['effect_type'],
      severity: json['severity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'effect_type': effectType,
      'severity': severity,
    };
  }

  // 嚴重程度描述
  String get severityDescription {
    switch (severity) {
      case 1:
        return '輕微';
      case 2:
        return '一般';
      case 3:
        return '重要';
      case 4:
        return '嚴重';
      case 5:
        return '危機';
      default:
        return '未知';
    }
  }

  // 效果類型描述
  String get effectDescription {
    switch (effectType) {
      case 'public_opinion':
        return '影響輿論';
      case 'unlock_option':
        return '解鎖選項';
      case 'economic':
        return '經濟影響';
      case 'political':
        return '政治影響';
      case 'social':
        return '社會影響';
      case 'diplomatic':
        return '外交影響';
      default:
        return '一般事件';
    }
  }
}

/// 已觸發的事件記錄
class TriggeredEvent {
  final String id;
  final String roomId;
  final String eventId;
  final GameEvent event;
  final DateTime triggeredAt;

  TriggeredEvent({
    required this.id,
    required this.roomId,
    required this.eventId,
    required this.event,
    required this.triggeredAt,
  });

  factory TriggeredEvent.fromJson(Map<String, dynamic> json) {
    return TriggeredEvent(
      id: json['id'],
      roomId: json['room_id'],
      eventId: json['event_id'],
      event: GameEvent.fromJson(json['event']),
      triggeredAt: DateTime.parse(json['triggered_at']),
    );
  }
}
