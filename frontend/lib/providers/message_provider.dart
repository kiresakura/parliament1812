import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

/// 私訊狀態管理
class MessageProvider with ChangeNotifier {
  final _api = ApiService();
  final _ws = WebSocketService();

  List<Conversation> _conversations = [];
  Map<String, List<Message>> _messagesByPlayer = {};
  int _totalUnread = 0;
  bool _isLoading = false;
  String? _error;

  List<Conversation> get conversations => _conversations;
  int get totalUnread => _totalUnread;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 取得與特定玩家的訊息
  List<Message> getMessagesWithPlayer(String playerId) {
    return _messagesByPlayer[playerId] ?? [];
  }

  /// 初始化訊息監聽
  void initMessageListeners() {
    _ws.eventStream.listen(_handleWSEvent);
  }

  /// 處理 WebSocket 事件
  void _handleWSEvent(WSEvent event) {
    if (event.type == WSEventType.privateMessage) {
      _onPrivateMessage(event.data);
    }
  }

  /// 載入對話列表
  Future<void> loadConversations({
    required String roomCode,
    required String playerId,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _conversations = await _api.getConversations(
        roomCode: roomCode,
        playerId: playerId,
      );
      _totalUnread = _conversations.fold(0, (sum, c) => sum + c.unreadCount);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// 載入與特定玩家的訊息
  Future<void> loadMessages({
    required String roomCode,
    required String playerId,
    required String otherPlayerId,
    int limit = 50,
    int offset = 0,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final messages = await _api.getMessages(
        roomCode: roomCode,
        playerId: playerId,
        otherPlayerId: otherPlayerId,
        limit: limit,
        offset: offset,
      );
      _messagesByPlayer[otherPlayerId] = messages;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// 發送訊息
  Future<bool> sendMessage({
    required String roomCode,
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    _clearError();

    try {
      final message = await _api.sendMessage(
        roomCode: roomCode,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
      );

      // 新增到本地訊息列表
      if (_messagesByPlayer.containsKey(receiverId)) {
        _messagesByPlayer[receiverId]!.add(message);
      } else {
        _messagesByPlayer[receiverId] = [message];
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// 標記訊息為已讀
  Future<void> markAsRead({
    required String playerId,
    String? senderId,
    List<String>? messageIds,
  }) async {
    try {
      await _api.markMessagesAsRead(
        playerId: playerId,
        senderId: senderId,
        messageIds: messageIds,
      );

      // 更新本地狀態
      if (senderId != null) {
        final messages = _messagesByPlayer[senderId];
        if (messages != null) {
          for (var i = 0; i < messages.length; i++) {
            if (!messages[i].isRead) {
              _messagesByPlayer[senderId]![i] = Message(
                id: messages[i].id,
                senderId: messages[i].senderId,
                senderNickname: messages[i].senderNickname,
                receiverId: messages[i].receiverId,
                receiverNickname: messages[i].receiverNickname,
                content: messages[i].content,
                isRead: true,
                sentAt: messages[i].sentAt,
              );
            }
          }
        }

        // 更新對話列表的未讀數
        final convIndex = _conversations.indexWhere((c) => c.playerId == senderId);
        if (convIndex >= 0) {
          _totalUnread -= _conversations[convIndex].unreadCount;
          _conversations[convIndex] = Conversation(
            playerId: _conversations[convIndex].playerId,
            nickname: _conversations[convIndex].nickname,
            roleType: _conversations[convIndex].roleType,
            lastMessage: _conversations[convIndex].lastMessage,
            lastMessageAt: _conversations[convIndex].lastMessageAt,
            unreadCount: 0,
          );
        }
      }

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// 處理收到的私訊
  void _onPrivateMessage(Map<String, dynamic> data) {
    final message = Message(
      id: data['message_id'],
      senderId: data['from_id'],
      senderNickname: data['from_nickname'],
      receiverId: '', // 接收者就是當前用戶
      receiverNickname: '',
      content: data['content'],
      isRead: false,
      sentAt: DateTime.parse(data['sent_at']),
    );

    // 新增到訊息列表
    final senderId = message.senderId;
    if (_messagesByPlayer.containsKey(senderId)) {
      _messagesByPlayer[senderId]!.add(message);
    } else {
      _messagesByPlayer[senderId] = [message];
    }

    // 更新未讀數
    _totalUnread++;

    // 更新對話列表
    final convIndex = _conversations.indexWhere((c) => c.playerId == senderId);
    if (convIndex >= 0) {
      _conversations[convIndex] = Conversation(
        playerId: senderId,
        nickname: message.senderNickname,
        roleType: _conversations[convIndex].roleType,
        lastMessage: message.content,
        lastMessageAt: message.sentAt,
        unreadCount: _conversations[convIndex].unreadCount + 1,
      );
    } else {
      _conversations.insert(
        0,
        Conversation(
          playerId: senderId,
          nickname: message.senderNickname,
          lastMessage: message.content,
          lastMessageAt: message.sentAt,
          unreadCount: 1,
        ),
      );
    }

    notifyListeners();
  }

  /// 清除訊息狀態
  void clearMessages() {
    _conversations = [];
    _messagesByPlayer = {};
    _totalUnread = 0;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
