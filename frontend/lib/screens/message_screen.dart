import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/message.dart';
import '../providers/room_provider.dart';
import '../providers/player_provider.dart';
import '../providers/message_provider.dart';
import '../widgets/message_bubble.dart';

/// 私訊畫面
class MessageScreen extends StatefulWidget {
  final String otherPlayerId;
  final String otherPlayerNickname;

  const MessageScreen({
    super.key,
    required this.otherPlayerId,
    required this.otherPlayerNickname,
  });

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final roomCode = context.read<RoomProvider>().room?.code;
    final playerId = context.read<PlayerProvider>().currentPlayer?.id;

    if (roomCode != null && playerId != null) {
      await context.read<MessageProvider>().loadMessages(
            roomCode: roomCode,
            playerId: playerId,
            otherPlayerId: widget.otherPlayerId,
          );

      // 標記為已讀
      await context.read<MessageProvider>().markAsRead(
            playerId: playerId,
            senderId: widget.otherPlayerId,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherPlayerNickname),
      ),
      body: Consumer3<RoomProvider, PlayerProvider, MessageProvider>(
        builder: (context, roomProvider, playerProvider, messageProvider, _) {
          final roomCode = roomProvider.room?.code;
          final currentPlayerId = playerProvider.currentPlayer?.id;
          final messages = messageProvider.getMessagesWithPlayer(
            widget.otherPlayerId,
          );

          if (roomCode == null || currentPlayerId == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // 訊息列表
              Expanded(
                child: _buildMessageList(messages, currentPlayerId),
              ),

              // 輸入框
              _buildInputArea(roomCode, currentPlayerId),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageList(List<Message> messages, String currentPlayerId) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 16),
            Text(
              '開始與 ${widget.otherPlayerNickname} 密謀',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == currentPlayerId;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: MessageBubble(
            message: message,
            isMe: isMe,
          ),
        );
      },
    );
  }

  Widget _buildInputArea(String roomCode, String currentPlayerId) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: '輸入悄悄話...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppTheme.darkBackground,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(roomCode, currentPlayerId),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _sendMessage(roomCode, currentPlayerId),
              icon: const Icon(Icons.send),
              color: AppTheme.secondaryColor,
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage(String roomCode, String currentPlayerId) async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();

    final success = await context.read<MessageProvider>().sendMessage(
          roomCode: roomCode,
          senderId: currentPlayerId,
          receiverId: widget.otherPlayerId,
          content: content,
        );

    if (success && mounted) {
      // 滾動到底部
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }
}

/// 對話列表畫面
class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final roomCode = context.read<RoomProvider>().room?.code;
    final playerId = context.read<PlayerProvider>().currentPlayer?.id;

    if (roomCode != null && playerId != null) {
      await context.read<MessageProvider>().loadConversations(
            roomCode: roomCode,
            playerId: playerId,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('私訊'),
      ),
      body: Consumer<MessageProvider>(
        builder: (context, provider, _) {
          final conversations = provider.conversations;

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.forum_outlined,
                    size: 64,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '還沒有任何對話',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '在等待室點擊玩家頭像開始私訊',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conv = conversations[index];
              return _buildConversationTile(conv);
            },
          );
        },
      ),
    );
  }

  Widget _buildConversationTile(Conversation conv) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: conv.roleType != null
            ? AppTheme.getRoleColor(conv.roleType!)
            : Colors.grey[700],
        child: Text(
          conv.nickname[0].toUpperCase(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Row(
        children: [
          Text(conv.nickname),
          if (conv.unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${conv.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        conv.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: conv.unreadCount > 0 ? Colors.white70 : Colors.grey[500],
        ),
      ),
      trailing: Text(
        _formatTime(conv.lastMessageAt),
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 12,
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MessageScreen(
              otherPlayerId: conv.playerId,
              otherPlayerNickname: conv.nickname,
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return '剛剛';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}分鐘前';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}小時前';
    } else {
      return '${diff.inDays}天前';
    }
  }
}
