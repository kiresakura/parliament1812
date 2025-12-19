import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../models/message.dart';
import '../providers/room_provider.dart';
import '../providers/player_provider.dart';
import '../providers/message_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/animated_widgets.dart';
import '../services/sound_service.dart';

/// 私訊畫面 - Civ6 六角形 + 維多利亞風格
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

class _MessageScreenState extends State<MessageScreen>
    with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late AnimationController _quillController;
  late AnimationController _glowController;
  late AnimationController _shineController;
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _quillController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _shineController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _loadMessages();
    _messageController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final isComposing = _messageController.text.isNotEmpty;
    if (isComposing != _isComposing) {
      setState(() => _isComposing = isComposing);
      if (isComposing) {
        _quillController.repeat(reverse: true);
      } else {
        _quillController.stop();
        _quillController.reset();
      }
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _quillController.dispose();
    _glowController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final roomCode = context.read<RoomProvider>().room?.code;
    final playerId = context.read<PlayerProvider>().currentPlayer?.id;
    final messageProvider = context.read<MessageProvider>();

    if (roomCode != null && playerId != null) {
      await messageProvider.loadMessages(
        roomCode: roomCode,
        playerId: playerId,
        otherPlayerId: widget.otherPlayerId,
      );

      // 標記為已讀
      if (mounted) {
        await messageProvider.markAsRead(
          playerId: playerId,
          senderId: widget.otherPlayerId,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Civ6 風格六角形背景
          const HexagonPatternBackground(),
          // 粒子效果
          const AtmosphereParticles(particleCount: 25),
          // 漸層覆蓋
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryBackground,
                  AppTheme.primaryBackground.withValues(alpha: 0.95),
                  AppTheme.cardBackground.withValues(alpha: 0.9),
                ],
              ),
            ),
          ),
          // 主內容
          Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: Consumer3<RoomProvider, PlayerProvider, MessageProvider>(
                  builder: (context, roomProvider, playerProvider,
                      messageProvider, _) {
                    final roomCode = roomProvider.room?.code;
                    final currentPlayerId = playerProvider.currentPlayer?.id;
                    final messages = messageProvider.getMessagesWithPlayer(
                      widget.otherPlayerId,
                    );

                    if (roomCode == null || currentPlayerId == null) {
                      return Center(
                        child: HexagonBadge(
                          size: 80,
                          glowColor: AppTheme.accentGold,
                          child: const CircularProgressIndicator(
                            color: AppTheme.accentGold,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        // 訊息列表
                        Expanded(
                          child:
                              _buildMessageList(messages, currentPlayerId),
                        ),
                        // 輸入框
                        _buildInputArea(roomCode, currentPlayerId),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            right: 16,
            bottom: 12,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.cardBackground.withValues(alpha: 0.95),
                AppTheme.cardBackground.withValues(alpha: 0.85),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.accentGold.withValues(
                  alpha: 0.3 + (_glowController.value * 0.2),
                ),
                width: 1.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentGold.withValues(
                  alpha: 0.1 + (_glowController.value * 0.1),
                ),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // 返回按鈕
              IconButton(
                onPressed: () {
                  soundService.buttonFeedback();
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: AppTheme.accentGold.withValues(alpha: 0.8),
                  size: 20,
                ),
              ),
              // 六角形信封圖示
              HexagonBadge(
                size: 44,
                glowColor: AppTheme.accentGold,
                child: const Icon(
                  Icons.mail_outline,
                  color: AppTheme.accentGold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              // 對方名稱
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.otherPlayerNickname,
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '密函往來',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 11,
                        letterSpacing: 2,
                        color: AppTheme.accentGold.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // 羽毛筆動畫圖示
              AnimatedBuilder(
                animation: _quillController,
                builder: (context, _) {
                  return Transform.rotate(
                    angle: _isComposing
                        ? (_quillController.value * 0.1) - 0.05
                        : 0,
                    child: GearIcon(
                      size: 28,
                      color: _isComposing
                          ? AppTheme.accentGold
                          : AppTheme.textSecondary.withValues(alpha: 0.5),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageList(List<Message> messages, String currentPlayerId) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 六角形信封圖示
            HexagonBadge(
              size: 100,
              glowColor: AppTheme.accentGold,
              child: const Icon(
                Icons.markunread_mailbox_outlined,
                size: 48,
                color: AppTheme.accentGold,
              ),
            )
                .animate(
                  onPlay: (c) => c.repeat(reverse: true),
                )
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.05, 1.05),
                  duration: 2000.ms,
                ),
            const SizedBox(height: 24),
            Text(
              '與 ${widget.otherPlayerNickname} 的密函',
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontSize: 18,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '提筆開始您的秘密通信',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 14,
                color: AppTheme.textSecondary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            // 維多利亞風格分隔線
            const VictorianDivider(width: 200),
          ],
        ),
      ).animate().fadeIn(duration: 600.ms);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == currentPlayerId;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MessageBubble(
            message: message,
            isMe: isMe,
          ),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: 50 * index.clamp(0, 10)))
            .slideX(
              begin: isMe ? 0.1 : -0.1,
              end: 0,
              duration: 300.ms,
            );
      },
    );
  }

  Widget _buildInputArea(String roomCode, String currentPlayerId) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.cardBackground.withValues(alpha: 0.9),
            AppTheme.cardBackground,
          ],
        ),
        border: Border(
          top: BorderSide(
            color: AppTheme.accentGold.withValues(alpha: 0.2),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 提示文字
            if (!_isComposing)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HexagonIcon(
                      size: 12,
                      color: AppTheme.accentGold.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '此密函僅閣下與對方可見',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 11,
                        color: AppTheme.accentGold.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            // 輸入區域
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 輸入框
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryBackground.withValues(alpha: 0.8),
                          AppTheme.cardBackground.withValues(alpha: 0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isComposing
                            ? AppTheme.accentGold.withValues(alpha: 0.5)
                            : AppTheme.accentGold.withValues(alpha: 0.2),
                        width: _isComposing ? 1.5 : 1,
                      ),
                      boxShadow: _isComposing
                          ? [
                              BoxShadow(
                                color: AppTheme.accentGold.withValues(alpha: 0.1),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        hintText: '提筆書寫密函...',
                        hintStyle: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 15,
                          color: AppTheme.textSecondary.withValues(alpha: 0.5),
                          fontStyle: FontStyle.italic,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 4),
                          child: Icon(
                            Icons.edit,
                            size: 18,
                            color: _isComposing
                                ? AppTheme.accentGold
                                : AppTheme.textSecondary.withValues(alpha: 0.5),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) =>
                          _sendMessage(roomCode, currentPlayerId),
                      onTap: () => soundService.haptic(HapticType.selection),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 發送按鈕 - 六角形風格
                GestureDetector(
                  onTap: () => _sendMessage(roomCode, currentPlayerId),
                  child: AnimatedBuilder(
                    animation: _shineController,
                    builder: (context, child) {
                      return Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _isComposing
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.accentGold,
                                    Color(0xFFB8941F),
                                  ],
                                )
                              : LinearGradient(
                                  colors: [
                                    AppTheme.accentGold.withValues(alpha: 0.2),
                                    AppTheme.accentGold.withValues(alpha: 0.1),
                                  ],
                                ),
                          border: Border.all(
                            color: _isComposing
                                ? AppTheme.accentGold.withValues(alpha: 0.5)
                                : AppTheme.accentGold.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          boxShadow: _isComposing
                              ? [
                                  BoxShadow(
                                    color: AppTheme.accentGold.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Stack(
                          children: [
                            // 閃光效果
                            if (_isComposing)
                              Positioned.fill(
                                child: ClipOval(
                                  child: Transform.translate(
                                    offset: Offset(
                                      -100 + (_shineController.value * 200),
                                      0,
                                    ),
                                    child: Container(
                                      width: 30,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            Colors.white.withValues(alpha: 0.3),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            Center(
                              child: Icon(
                                Icons.send_rounded,
                                color: _isComposing
                                    ? AppTheme.primaryBackground
                                    : AppTheme.accentGold.withValues(alpha: 0.5),
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage(String roomCode, String currentPlayerId) async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    soundService.play(SoundEffect.quillWriting);
    soundService.haptic(HapticType.medium);

    _messageController.clear();
    final messageProvider = context.read<MessageProvider>();

    final success = await messageProvider.sendMessage(
      roomCode: roomCode,
      senderId: currentPlayerId,
      receiverId: widget.otherPlayerId,
      content: content,
    );

    if (success && mounted) {
      soundService.haptic(HapticType.light);
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

/// 對話列表畫面 - Civ6 六角形風格
class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _loadConversations();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    final roomCode = context.read<RoomProvider>().room?.code;
    final playerId = context.read<PlayerProvider>().currentPlayer?.id;
    final messageProvider = context.read<MessageProvider>();

    if (roomCode != null && playerId != null) {
      await messageProvider.loadConversations(
        roomCode: roomCode,
        playerId: playerId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Civ6 風格六角形背景
          const HexagonPatternBackground(),
          // 粒子效果
          const AtmosphereParticles(particleCount: 20),
          // 漸層覆蓋
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryBackground,
                  AppTheme.primaryBackground.withValues(alpha: 0.95),
                  AppTheme.cardBackground.withValues(alpha: 0.9),
                ],
              ),
            ),
          ),
          // 主內容
          Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: Consumer<MessageProvider>(
                  builder: (context, provider, _) {
                    final conversations = provider.conversations;

                    if (provider.isLoading) {
                      return Center(
                        child: HexagonBadge(
                          size: 80,
                          glowColor: AppTheme.accentGold,
                          child: const CircularProgressIndicator(
                            color: AppTheme.accentGold,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    }

                    if (conversations.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        final conv = conversations[index];
                        return _buildConversationTile(conv, index);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            right: 16,
            bottom: 16,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.cardBackground.withValues(alpha: 0.95),
                AppTheme.cardBackground.withValues(alpha: 0.85),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.accentGold.withValues(
                  alpha: 0.3 + (_glowController.value * 0.2),
                ),
                width: 1.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentGold.withValues(
                  alpha: 0.1 + (_glowController.value * 0.1),
                ),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // 返回按鈕
              IconButton(
                onPressed: () {
                  soundService.buttonFeedback();
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: AppTheme.accentGold.withValues(alpha: 0.8),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              // 六角形標題圖示
              HexagonBadge(
                size: 44,
                glowColor: AppTheme.accentGold,
                child: const Icon(
                  Icons.drafts_outlined,
                  color: AppTheme.accentGold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              // 標題
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '密函匣',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'SECRET CORRESPONDENCE',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 10,
                        letterSpacing: 2,
                        color: AppTheme.accentGold.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // 齒輪裝飾
              GearIcon(
                size: 24,
                color: AppTheme.textSecondary.withValues(alpha: 0.3),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 六角形信封圖示
          HexagonBadge(
            size: 120,
            glowColor: AppTheme.accentGold,
            child: Icon(
              Icons.markunread_mailbox_outlined,
              size: 56,
              color: AppTheme.accentGold.withValues(alpha: 0.7),
            ),
          )
              .animate(
                onPlay: (c) => c.repeat(reverse: true),
              )
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.05, 1.05),
                duration: 2000.ms,
              ),
          const SizedBox(height: 28),
          const Text(
            '密函匣空無一物',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 20,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '在等待室點擊玩家頭像',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 14,
              color: AppTheme.textSecondary.withValues(alpha: 0.7),
            ),
          ),
          Text(
            '開始您的秘密通信',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 14,
              color: AppTheme.textSecondary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 32),
          // 維多利亞風格分隔線
          const VictorianDivider(width: 200),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildConversationTile(Conversation conv, int index) {
    final roleColor =
        conv.roleType != null ? AppTheme.getRoleColor(conv.roleType!) : null;

    return GestureDetector(
      onTap: () {
        soundService.play(SoundEffect.paperRustle);
        soundService.haptic(HapticType.light);
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.cardBackground.withValues(alpha: 0.95),
              AppTheme.primaryBackground.withValues(alpha: 0.8),
              AppTheme.cardBackground.withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: conv.unreadCount > 0
                ? AppTheme.voteNay.withValues(alpha: 0.5)
                : AppTheme.accentGold.withValues(alpha: 0.2),
            width: conv.unreadCount > 0 ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: conv.unreadCount > 0
                  ? AppTheme.voteNay.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.2),
              blurRadius: conv.unreadCount > 0 ? 12 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 六角形頭像
              Stack(
                children: [
                  HexagonBadge(
                    size: 54,
                    glowColor: roleColor ?? AppTheme.accentGold,
                    child: Text(
                      conv.nickname[0].toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: roleColor ?? AppTheme.accentGold,
                      ),
                    ),
                  ),
                  // 未讀標記 - 蠟封風格
                  if (conv.unreadCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppTheme.voteNay,
                              AppTheme.voteNay.withValues(alpha: 0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.voteNay.withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${conv.unreadCount}',
                            style: const TextStyle(
                              fontFamily: 'Georgia',
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              // 內容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 名稱和時間
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          conv.nickname,
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 16,
                            fontWeight: conv.unreadCount > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          _formatTime(conv.lastMessageAt),
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 11,
                            color: conv.unreadCount > 0
                                ? AppTheme.accentGold
                                : AppTheme.textSecondary.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // 最後訊息
                    Row(
                      children: [
                        Icon(
                          conv.unreadCount > 0
                              ? Icons.mail
                              : Icons.mail_outline,
                          size: 14,
                          color: conv.unreadCount > 0
                              ? AppTheme.accentGold
                              : AppTheme.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            conv.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: conv.unreadCount > 0
                                  ? AppTheme.textPrimary.withValues(alpha: 0.8)
                                  : AppTheme.textSecondary.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 六角形箭頭
              HexagonIcon(
                size: 22,
                color: AppTheme.accentGold.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 80 * index))
        .slideX(begin: 0.1, end: 0, duration: 300.ms);
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return '方才';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}分前';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}時前';
    } else {
      return '${diff.inDays}日前';
    }
  }
}
