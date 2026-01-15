/// 私訊模型
class Message {
  final String id;
  final String senderId;
  final String senderNickname;
  final String receiverId;
  final String receiverNickname;
  final String content;
  final bool isRead;
  final DateTime sentAt;

  Message({
    required this.id,
    required this.senderId,
    required this.senderNickname,
    required this.receiverId,
    required this.receiverNickname,
    required this.content,
    required this.isRead,
    required this.sentAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['sender_id'],
      senderNickname: json['sender_nickname'],
      receiverId: json['receiver_id'],
      receiverNickname: json['receiver_nickname'],
      content: json['content'],
      isRead: json['is_read'] ?? false,
      sentAt: DateTime.parse(json['sent_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_nickname': senderNickname,
      'receiver_id': receiverId,
      'receiver_nickname': receiverNickname,
      'content': content,
      'is_read': isRead,
      'sent_at': sentAt.toIso8601String(),
    };
  }
}

/// 對話模型（用於對話列表）
class Conversation {
  final String playerId;
  final String nickname;
  final String? roleType;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;

  Conversation({
    required this.playerId,
    required this.nickname,
    this.roleType,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      playerId: json['player_id'],
      nickname: json['nickname'],
      roleType: json['role_type'],
      lastMessage: json['last_message'],
      lastMessageAt: DateTime.parse(json['last_message_at']),
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}
