import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/game_provider.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../models/room.dart';
import '../models/card.dart';

class GameScreen extends ConsumerStatefulWidget {
  final String roomCode;

  const GameScreen({
    super.key,
    required this.roomCode,
  });

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with TickerProviderStateMixin {
  bool _isChatExpanded = false;
  late AnimationController _chatAnimationController;
  final TextEditingController _chatController = TextEditingController();
  
  // 階段轉場動畫
  late AnimationController _phaseTransitionController;
  late Animation<double> _phaseTransitionOpacity;
  late Animation<double> _phaseTransitionScale;
  bool _isShowingPhaseTransition = false;
  GamePhase? _currentPhase;
  
  // 預設快捷語
  final List<String> _quickMessages = [
    '好手段！',
    '結盟？',
    '你完了。',
    '投我一票',
    '有意思...',
    '我同意。',
  ];
  
  @override
  void initState() {
    super.initState();
    _chatAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // 階段轉場動畫初始化
    _phaseTransitionController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _phaseTransitionOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _phaseTransitionController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
    ));
    
    _phaseTransitionScale = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _phaseTransitionController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));
    
    // 動畫完成後自動隱藏轉場
    _phaseTransitionController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _isShowingPhaseTransition = false;
            });
            _phaseTransitionController.reset();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _chatAnimationController.dispose();
    _phaseTransitionController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final theme = Theme.of(context);

    // 監聽遊戲結果，當有結果時導航到結算畫面
    ref.listen(gameStateProvider, (previous, next) {
      if (next?.result != null && previous?.result == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.go('/game/${widget.roomCode}/result');
          }
        });
      }
      
      // 監聽階段變化，觸發轉場動畫
      if (next?.phase != previous?.phase && next?.phase != null) {
        _triggerPhaseTransition(next!.phase);
      }
    });

    if (gameState == null) {
      return _buildLoadingScreen(theme);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 主遊戲區域
          Column(
            children: [
              // 頂部資訊列
              _buildTopInfoBar(gameState, theme),
              
              // 主遊戲區域
              Expanded(
                child: Column(
                  children: [
                    // 議案區域
                    if (gameState.phase == GamePhase.voting || 
                        gameState.phase == GamePhase.debate)
                      _buildBillArea(gameState, theme),
                    
                    // 遊戲區域
                    Expanded(
                      child: _buildGameArea(gameState, theme),
                    ),
                  ],
                ),
              ),
              
              // 底部操作區
              _buildBottomActionArea(gameState, theme),
            ],
          ),
          
          // 聊天浮層
          _buildChatOverlay(gameState, theme),
          
          // 階段轉場動畫覆蓋層
          if (_isShowingPhaseTransition)
            _buildPhaseTransitionOverlay(theme),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen(ThemeData theme) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '載入遊戲中...',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopInfoBar(GameState gameState, ThemeData theme) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 階段指示
              _buildPhaseIndicator(gameState.phase, theme),
              
              // 計時器
              _buildTimer(gameState.remainingSeconds, theme),
              
              // 回合數與設定
              Row(
                children: [
                  _buildRoundIndicator(gameState.round, theme),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.settings,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    onPressed: () => _showGameSettings(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseIndicator(GamePhase phase, ThemeData theme) {
    String phaseText;
    IconData phaseIcon;
    Color phaseColor;
    
    switch (phase) {
      case GamePhase.conspiracy:
        phaseText = '密謀階段';
        phaseIcon = Icons.visibility_off;
        phaseColor = theme.colorScheme.secondary;
        break;
      case GamePhase.debate:
        phaseText = '辯論階段';
        phaseIcon = Icons.forum;
        phaseColor = theme.colorScheme.primary;
        break;
      case GamePhase.voting:
        phaseText = '投票階段';
        phaseIcon = Icons.how_to_vote;
        phaseColor = const Color(0xFF4CAF50);
        break;
      case GamePhase.result:
        phaseText = '結果階段';
        phaseIcon = Icons.emoji_events;
        phaseColor = theme.colorScheme.secondary;
        break;
      default:
        phaseText = '準備中';
        phaseIcon = Icons.hourglass_empty;
        phaseColor = theme.colorScheme.outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: phaseColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: phaseColor.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            phaseIcon,
            size: 16,
            color: phaseColor,
          ),
          const SizedBox(width: 6),
          Text(
            phaseText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: phaseColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimer(int remainingSeconds, ThemeData theme) {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    final isUrgent = remainingSeconds <= 30;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isUrgent 
            ? theme.colorScheme.error.withOpacity(0.15)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUrgent 
              ? theme.colorScheme.error
              : theme.colorScheme.outline.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            size: 18,
            color: isUrgent 
                ? theme.colorScheme.error
                : theme.colorScheme.onSurface,
          ),
          const SizedBox(width: 6),
          Text(
            '$minutes:${seconds.toString().padLeft(2, '0')}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: isUrgent 
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundIndicator(int round, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        '第$round回合',
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildGameArea(GameState gameState, ThemeData theme) {
    return Row(
      children: [
        // 左側玩家
        Expanded(
          flex: 2,
          child: _buildPlayersArea(gameState, theme),
        ),
        
        // 中央區域
        Expanded(
          flex: 3,
          child: _buildCentralArea(gameState, theme),
        ),
      ],
    );
  }

  Widget _buildPlayersArea(GameState gameState, ThemeData theme) {
    final players = gameState.room.players;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 上方玩家
          if (players.length > 1)
            Expanded(child: _buildPlayerCard(players[1], false, theme)),
          
          const SizedBox(height: 16),
          
          // 中間：左右玩家
          Expanded(
            flex: 2,
            child: Row(
              children: [
                // 左側玩家
                if (players.length > 2)
                  Expanded(child: _buildPlayerCard(players[2], false, theme)),
                
                if (players.length > 3) const SizedBox(width: 16),
                
                // 右側玩家
                if (players.length > 3)
                  Expanded(child: _buildPlayerCard(players[3], false, theme)),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 下方玩家（自己）
          if (players.isNotEmpty)
            Expanded(child: _buildPlayerCard(players[0], true, theme)),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(Player player, bool isCurrentPlayer, ThemeData theme) {
    final isActive = player.id == ''; // TODO: 取得當前活動玩家ID
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive 
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withOpacity(0.3),
          width: isActive ? 2 : 1,
        ),
        boxShadow: isCurrentPlayer ? [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 頭像
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
              child: Text(
                player.character.displayName.substring(0, 1),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // 玩家名稱
            Text(
              player.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            // 角色
            Text(
              player.character.displayName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 8),
            
            // 聲望條
            _buildReputationBar(player.resources.reputation, theme),
            
            const SizedBox(height: 4),
            
            // 手牌數
            Text(
              '手牌: ${player.handCards.length}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReputationBar(int reputation, ThemeData theme) {
    final progress = reputation / 100.0;
    
    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.favorite,
              size: 12,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: theme.colorScheme.outline.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  reputation > 30 
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$reputation',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCentralArea(GameState gameState, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 議案顯示區
          Expanded(
            flex: 1,
            child: _buildBillDisplay(gameState.currentBill, theme),
          ),
          
          const SizedBox(height: 16),
          
          // 事件日誌
          Expanded(
            flex: 2,
            child: _buildEventLog(gameState.gameEvents, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildBillDisplay(String? currentBill, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.article,
                color: theme.colorScheme.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '當前議案',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Expanded(
            child: Text(
              currentBill ?? '暫無議案',
              style: theme.textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventLog(List<GameEvent> events, ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  color: theme.colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '事件日誌',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return _buildEventItem(event, theme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(GameEvent event, ThemeData theme) {
    IconData eventIcon;
    Color eventColor;
    
    switch (event.type) {
      case GameEventType.challenge:
        eventIcon = Icons.gavel;
        eventColor = theme.colorScheme.error;
        break;
      case GameEventType.cardUsed:
        eventIcon = Icons.style;
        eventColor = theme.colorScheme.primary;
        break;
      case GameEventType.reputationChanged:
        eventIcon = Icons.flash_on;
        eventColor = theme.colorScheme.secondary;
        break;
      default:
        eventIcon = Icons.info;
        eventColor = theme.colorScheme.onSurface;
        break;
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            eventIcon,
            size: 16,
            color: eventColor,
          ),
          
          const SizedBox(width: 8),
          
          Expanded(
            child: Text(
              event.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionArea(GameState gameState, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 手牌區
              SizedBox(
                height: 120,
                child: _buildHandCardsArea(gameState.hand, theme),
              ),
              
              const SizedBox(height: 16),
              
              // 動作按鈕區
              _buildActionButtons(gameState.phase, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandCardsArea(List<GameCard> handCards, ThemeData theme) {
    if (handCards.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Center(
          child: Text(
            '暫無手牌',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      );
    }
    
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: handCards.length,
      itemBuilder: (context, index) {
        final card = handCards[index];
        return _buildCardWidget(card, theme);
      },
    );
  }

  Widget _buildCardWidget(GameCard card, ThemeData theme) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: InkWell(
        onTap: () => _onCardTapped(card),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                card.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              
              Text(
                '${card.influenceCost}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(GamePhase phase, ThemeData theme) {
    List<Widget> buttons = [];
    
    switch (phase) {
      case GamePhase.conspiracy:
        buttons = [
          _buildActionButton('調查', Icons.search, theme, () {}),
          _buildActionButton('結盟', Icons.handshake, theme, () {}),
          _buildActionButton('賄賂', Icons.attach_money, theme, () {}),
        ];
        break;
      case GamePhase.debate:
        buttons = [
          _buildActionButton('質詢', Icons.gavel, theme, () {}),
          _buildActionButton('反駁', Icons.shield, theme, () {}),
          _buildActionButton('技能', Icons.flash_on, theme, () {}),
        ];
        break;
      case GamePhase.voting:
        buttons = [
          _buildActionButton('支持', Icons.thumb_up, theme, () {}),
          _buildActionButton('反對', Icons.thumb_down, theme, () {}),
          _buildActionButton('棄權', Icons.remove, theme, () {}),
        ];
        break;
      default:
        buttons = [
          _buildActionButton('等待中', Icons.hourglass_empty, theme, null),
        ];
        break;
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: buttons,
    );
  }

  Widget _buildActionButton(
    String label, 
    IconData icon, 
    ThemeData theme, 
    VoidCallback? onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: onPressed != null 
            ? theme.colorScheme.primary
            : theme.colorScheme.surface,
        foregroundColor: onPressed != null 
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface.withOpacity(0.5),
      ),
    );
  }

  Widget _buildChatOverlay(GameState gameState, ThemeData theme) {
    return Positioned(
      right: 16,
      bottom: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 聊天內容區
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isChatExpanded ? 400 : 0,
            width: _isChatExpanded ? 320 : 0,
            child: _isChatExpanded 
                ? _buildChatContent(gameState.chatMessages, theme)
                : const SizedBox.shrink(),
          ),
          
          const SizedBox(height: 8),
          
          // 聊天按鈕
          Stack(
            children: [
              FloatingActionButton(
                mini: true,
                onPressed: _toggleChat,
                backgroundColor: theme.colorScheme.secondary,
                child: Icon(
                  _isChatExpanded ? Icons.close : Icons.chat,
                  color: theme.colorScheme.onSecondary,
                ),
              ),
              
              // 未讀數 Badge
              if (!_isChatExpanded && gameState.chatMessages.isNotEmpty)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${gameState.chatMessages.length > 9 ? '9+' : gameState.chatMessages.length}',
                      style: TextStyle(
                        color: theme.colorScheme.onError,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatContent(List<ChatMessage> messages, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 聊天標題
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.chat,
                  size: 16,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  '聊天',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // 聊天訊息列表
          Expanded(
            flex: 3,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return _buildChatMessage(message, theme);
              },
            ),
          ),
          
          // 分隔線
          Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          
          // 快捷語按鈕
          _buildQuickMessages(theme),
          
          // 輸入框
          _buildChatInput(theme),
        ],
      ),
    );
  }

  Widget _buildChatMessage(ChatMessage message, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.fromName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          Text(
            message.content,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMessages(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: _quickMessages.map((message) {
          return InkWell(
            onTap: () => _sendQuickMessage(message),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChatInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              style: theme.textTheme.bodySmall,
              decoration: InputDecoration(
                hintText: '輸入訊息...',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
              onSubmitted: (text) {
                _sendChatMessage(text);
              },
            ),
          ),
          
          const SizedBox(width: 8),
          
          InkWell(
            onTap: () => _sendChatMessage(_chatController.text),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send,
                size: 16,
                color: theme.colorScheme.onSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendQuickMessage(String message) {
    final gameActions = ref.read(gameActionsProvider);
    gameActions.sendChat(message);
  }

  void _sendChatMessage(String text) {
    if (text.trim().isEmpty) return;
    
    final gameActions = ref.read(gameActionsProvider);
    gameActions.sendChat(text.trim());
    
    _chatController.clear();
  }

  void _triggerPhaseTransition(GamePhase newPhase) {
    if (!mounted) return;
    
    setState(() {
      _currentPhase = newPhase;
      _isShowingPhaseTransition = true;
    });
    
    _phaseTransitionController.forward();
  }

  Widget _buildPhaseTransitionOverlay(ThemeData theme) {
    if (_currentPhase == null) return const SizedBox.shrink();
    
    final phaseInfo = _getPhaseTransitionInfo(_currentPhase!);
    
    return AnimatedBuilder(
      animation: _phaseTransitionController,
      builder: (context, child) {
        return Opacity(
          opacity: _phaseTransitionOpacity.value,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: phaseInfo.colors,
              ),
            ),
            child: Center(
              child: Transform.scale(
                scale: _phaseTransitionScale.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        phaseInfo.icon,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    Text(
                      phaseInfo.title,
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                            color: Colors.black.withValues(alpha: 0.3),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      phaseInfo.subtitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                            color: Colors.black.withValues(alpha: 0.3),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  PhaseTransitionInfo _getPhaseTransitionInfo(GamePhase phase) {
    switch (phase) {
      case GamePhase.conspiracy:
        return PhaseTransitionInfo(
          title: '密謀階段',
          subtitle: '策劃你的行動',
          icon: Icons.visibility_off,
          colors: [
            const Color(0xFF2C3E50).withValues(alpha: 0.9),
            const Color(0xFF34495E).withValues(alpha: 0.9),
          ],
        );
      
      case GamePhase.debate:
        return PhaseTransitionInfo(
          title: '辯論階段',
          subtitle: '展開激烈的政治攻防',
          icon: Icons.campaign,
          colors: [
            const Color(0xFF8B0000).withValues(alpha: 0.9),
            const Color(0xFFDC143C).withValues(alpha: 0.9),
          ],
        );
      
      case GamePhase.voting:
        return PhaseTransitionInfo(
          title: '投票階段',
          subtitle: '決定議案的命運',
          icon: Icons.how_to_vote,
          colors: [
            const Color(0xFFD4AF37).withValues(alpha: 0.9),
            const Color(0xFFFFD700).withValues(alpha: 0.9),
          ],
        );
      
      case GamePhase.result:
        return PhaseTransitionInfo(
          title: '結算中...',
          subtitle: '統計投票結果',
          icon: Icons.analytics,
          colors: [
            const Color(0xFF4A90E2).withValues(alpha: 0.9),
            const Color(0xFF7B68EE).withValues(alpha: 0.9),
          ],
        );
      
      default:
        return PhaseTransitionInfo(
          title: '遊戲進行中',
          subtitle: '',
          icon: Icons.play_arrow,
          colors: [
            const Color(0xFF2C3E50).withValues(alpha: 0.9),
            const Color(0xFF34495E).withValues(alpha: 0.9),
          ],
        );
    }
  }

  Widget _buildBillArea(GameState gameState, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.secondary.withValues(alpha: 0.1),
            theme.colorScheme.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.secondary.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 議案標題
          Row(
            children: [
              Icon(
                Icons.gavel,
                color: theme.colorScheme.secondary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '當前議案',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 議案名稱（從 gameState 獲取）
          Text(
            gameState.currentBill ?? '等待議案',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 議案描述
          Text(
            _getBillDescription(gameState.currentBill),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          
          // 投票階段時顯示效果預覽
          if (gameState.phase == GamePhase.voting) ...[
            const SizedBox(height: 16),
            _buildBillEffectPreview(gameState.currentBill, theme),
          ],
        ],
      ),
    );
  }

  Widget _buildBillEffectPreview(String? billName, ThemeData theme) {
    final effects = _getBillEffects(billName);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '投票效果預覽',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 8),
          
          ...effects.map((effect) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    effect,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  String _getBillDescription(String? billName) {
    switch (billName) {
      case '《工廠法案》':
        return '限制工廠工時，改善勞工待遇。';
      case '《新聞審查法》':
        return '限制新聞自由，控制輿論傳播。';
      case '《穀物法廢除》':
        return '廢除穀物進口關稅，降低糧食價格。';
      case '《結社自由法》':
        return '允許工人組織工會和政治團體。';
      case '《選舉改革法》':
        return '擴大選舉權，改革議會選舉制度。';
      default:
        return '議案詳情待定...';
    }
  }

  List<String> _getBillEffects(String? billName) {
    switch (billName) {
      case '《工廠法案》':
        return [
          '通過：工人聲望 +10，工廠主聲望 -10',
          '否決：工人聲望 -5，工廠主聲望 +5',
        ];
      case '《新聞審查法》':
        return [
          '通過：記者聲望 -15，其他人聲望 +5',
          '否決：記者聲望 +8，其他人聲望 -2',
        ];
      case '《穀物法廢除》':
        return [
          '通過：工廠主聲望 +10，工人聲望 +5',
          '否決：工廠主聲望 -5，工人聲望 -3',
        ];
      case '《結社自由法》':
        return [
          '通過：盧德派聲望 +15，工廠主聲望 -10',
          '否決：盧德派聲望 -8，工廠主聲望 +5',
        ];
      case '《選舉改革法》':
        return [
          '通過：全員聲望 +5，最高聲望者 -10',
          '否決：全員聲望 -3',
        ];
      default:
        return ['投票效果將在議案確定後顯示'];
    }
  }

  void _toggleChat() {
    setState(() {
      _isChatExpanded = !_isChatExpanded;
    });
  }

  void _onCardTapped(GameCard card) {
    // TODO: 實作卡牌使用邏輯
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('使用卡牌: ${card.name}')),
    );
  }

  void _showGameSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('遊戲設定'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.volume_up),
              title: const Text('音效'),
              trailing: Switch(value: true, onChanged: (value) {}),
            ),
            
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('遊戲規則'),
              onTap: () {},
            ),
            
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('離開遊戲'),
              onTap: () => _showLeaveGameDialog(context),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  void _showLeaveGameDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('離開遊戲'),
        content: const Text('確定要離開遊戲嗎？遊戲進度將會遺失。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/rooms');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('離開'),
          ),
        ],
      ),
    );
  }
}

/// 階段轉場資訊
class PhaseTransitionInfo {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;

  const PhaseTransitionInfo({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
  });
}