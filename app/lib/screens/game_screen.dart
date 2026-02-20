import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/game_provider.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../models/room.dart';
import '../models/card.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../services/performance_service.dart';
import '../ui/theme/game_colors.dart' as gc;
import '../ui/theme/game_fonts.dart';
import '../ui/theme/game_animations.dart';
import '../ui/theme/game_spacing.dart';
import '../widgets/game_card_widget.dart';
import '../widgets/performance_aware.dart';
import '../widgets/parliament/parliament_battle_view.dart';

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

    // 階段轉場動畫初始化（時長由效能設定控制）
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

    // 播放遊戲 BGM
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioServiceProvider).playBgm(BgmType.game);
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

    // 監聽遊戲結果
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

    // 議會回合制模式：使用新的 ParliamentBattleView
    final useParliamentLayout = gameState.phase == GamePhase.playerTurn ||
        (gameState.turnOrder.isNotEmpty &&
            gameState.phase != GamePhase.waiting &&
            gameState.phase != GamePhase.result);

    return Scaffold(
      backgroundColor: gc.GameColors.bgPrimary,
      body: Stack(
        children: [
          if (useParliamentLayout)
            SafeArea(
              bottom: false,
              child: ParliamentBattleView(gameState: gameState),
            )
          else
            Column(
              children: [
                _buildTopInfoBar(gameState, theme),
                Expanded(
                  child: Column(
                    children: [
                      if (gameState.phase == GamePhase.voting ||
                          gameState.phase == GamePhase.debate)
                        _buildBillArea(gameState, theme),
                      Expanded(
                        child: _buildGameArea(gameState, theme),
                      ),
                    ],
                  ),
                ),
                _buildBottomActionArea(gameState, theme),
              ],
            ),
          _buildChatOverlay(gameState, theme),
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
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('載入遊戲中...', style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildTopInfoBar(GameState gameState, ThemeData theme) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: gc.GameColors.bgSecondary,
        border: Border(
          bottom: BorderSide(
            color: gc.GameColors.victorianGold.withValues(alpha: 0.2),
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
              _buildPhaseIndicator(gameState.phase, theme),
              _buildTimer(gameState.remainingSeconds, theme),
              Row(
                children: [
                  _buildRoundIndicator(gameState.round, theme),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.settings,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
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
        phaseColor = gc.GameColors.raritySR; // 薰衣草紫
        break;
      case GamePhase.debate:
        phaseText = '辯論階段';
        phaseIcon = Icons.forum;
        phaseColor = gc.GameColors.roseRed; // 玫瑰紅
        break;
      case GamePhase.voting:
        phaseText = '投票階段';
        phaseIcon = Icons.how_to_vote;
        phaseColor = gc.GameColors.actionAlliance; // 翠綠
        break;
      case GamePhase.result:
        phaseText = '結果階段';
        phaseIcon = Icons.emoji_events;
        phaseColor = gc.GameColors.victorianGold;
        break;
      default:
        phaseText = '準備中';
        phaseIcon = Icons.hourglass_empty;
        phaseColor = gc.GameColors.textMuted;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: phaseColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: phaseColor.withValues(alpha: 0.6), width: 1),
        boxShadow: [
          BoxShadow(
            color: phaseColor.withValues(alpha: 0.3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(phaseIcon, size: 16, color: phaseColor),
          const SizedBox(width: 6),
          Text(phaseText,
              style: GameFont.turnPhase.copyWith(
                  color: phaseColor)),
        ],
      ),
    );
  }

  Widget _buildTimer(int remainingSeconds, ThemeData theme) {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    final isUrgent = remainingSeconds <= 30;
    final config = ref.watch(qualityConfigProvider);

    // 低品質：不使用 border 動畫色，固定顏色
    final borderColor = isUrgent && config.enableAnimations
        ? theme.colorScheme.error
        : isUrgent
            ? theme.colorScheme.error.withValues(alpha: 0.6)
            : theme.colorScheme.outline.withValues(alpha: 0.4);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isUrgent
            ? theme.colorScheme.error.withValues(alpha: 0.15)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer,
              size: 18,
              color: isUrgent
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurface),
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
        color: gc.GameColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: gc.GameColors.victorianGold.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('第', style: GameFont.uiLabel.copyWith(
              color: gc.GameColors.textSecondary)),
          Text('$round', style: GameFont.turnCounter.copyWith(
              color: gc.GameColors.textGold, fontSize: 16)),
          Text('回合', style: GameFont.uiLabel.copyWith(
              color: gc.GameColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildGameArea(GameState gameState, ThemeData theme) {
    return Column(
      children: [
        // 頂部：玩家卡三欄 + 回合順序列
        _buildPlayersArea(gameState, theme),
        _buildTurnOrderBar(gameState, theme),
        // 中間：議案區 + 事件日誌
        Expanded(child: _buildCentralArea(gameState, theme)),
      ],
    );
  }

  Widget _buildPlayersArea(GameState gameState, ThemeData theme) {
    final players = gameState.room.players;
    final currentTurnId = gameState.currentTurnPlayerId;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: GameSpacing.screenPadding,
        vertical: 8,
      ),
      child: Row(
        children: [
          for (int i = 0; i < players.length; i++) ...[
            if (i > 0) const SizedBox(width: GameSpacing.cardGap),
            Expanded(
              child: _buildPlayerCard(
                players[i],
                players[i].id == currentTurnId,
                theme,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 取得派系對應的頭像背景色（羅塞蒂設計規範）
  Color _getFactionAvatarColor(String faction) {
    switch (faction.toLowerCase()) {
      case 'whig':
      case 'labor':
        return const Color(0xFF3D7CC9);
      case 'tory':
      case 'capital':
        return const Color(0xFFC0392B);
      case 'radical':
      case 'reform':
        return const Color(0xFF6B3FA0);
      case 'independent':
      case 'neutral':
      case 'crown':
        return const Color(0xFFC9A84C);
      default:
        return const Color(0xFFC9A84C);
    }
  }

  Widget _buildPlayerCard(
      Player player, bool isActiveTurn, ThemeData theme) {
    final faction = player.character?.faction ?? 'neutral';
    final factionColor = gc.GameColors.getFactionColor(faction);
    final avatarBg = _getFactionAvatarColor(faction);
    final reputationPct = (player.reputation / 100).clamp(0.0, 1.0);

    // 影響力進度條顏色：綠→橙→紅
    Color barColor;
    if (reputationPct > 0.6) {
      barColor = gc.GameColors.actionAlliance; // 翠綠
    } else if (reputationPct > 0.3) {
      barColor = gc.GameColors.actionDraw; // 琥珀橙
    } else {
      barColor = gc.GameColors.roseRed; // 玫瑰紅
    }

    return Container(
      padding: const EdgeInsets.all(GameSpacing.cardPadding),
      decoration: BoxDecoration(
        color: gc.GameColors.bgCard,
        borderRadius: GameSpacing.cardBorderRadius,
        border: Border.all(
          color: isActiveTurn
              ? gc.GameColors.victorianGold
              : Colors.transparent,
          width: isActiveTurn ? 1.5 : 0,
        ),
        boxShadow: [
          const BoxShadow(
            offset: Offset(0, 4),
            blurRadius: 12,
            color: Color(0x80000000),
          ),
          if (isActiveTurn)
            BoxShadow(
              offset: Offset.zero,
              blurRadius: 16,
              color: gc.GameColors.victorianGold.withValues(alpha: 0.4),
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 「行動中」badge（僅當前行動玩家）
          if (isActiveTurn)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: gc.GameColors.victorianGold,
                borderRadius: GameSpacing.badgeBorderRadius,
              ),
              child: Text(
                '行動中',
                style: GameFont.factionBadge.copyWith(
                  color: gc.GameColors.bgPrimary,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          // 圓形字母頭像 + 姓名 + 黨派
          Row(
            children: [
              // 圓形頭像 40px
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: avatarBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  player.name.isNotEmpty
                      ? player.name.substring(0, 1).toUpperCase()
                      : '?',
                  style: GameFont.factionBadge.copyWith(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 姓名 + 黨派
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: GameFont.playerName.copyWith(
                        color: gc.GameColors.textPrimary,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      gc.GameColors.getFactionLabel(faction).toUpperCase(),
                      style: GameFont.factionBadge.copyWith(
                        color: factionColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 影響力進度條（4px 高）
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 4,
              child: LinearProgressIndicator(
                value: reputationPct,
                backgroundColor: gc.GameColors.bgPrimary,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // 手牌數（右對齊）
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.style,
                size: 12,
                color: gc.GameColors.textSecondary,
              ),
              const SizedBox(width: 3),
              Text(
                '${player.handCards.length}',
                style: GameFont.factionBadge.copyWith(
                  color: gc.GameColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 回合順序指示器
  /// 格式：● Wellington YOU › ● Palmerston › ● Peel
  Widget _buildTurnOrderBar(GameState gameState, ThemeData theme) {
    final players = gameState.room.players;
    final currentTurnId = gameState.currentTurnPlayerId;
    final myId = gameState.currentPlayerId;

    // 按 turnOrder 排序（如果有）；否則用 players 順序
    final orderedPlayers = gameState.turnOrder.isNotEmpty
        ? gameState.turnOrder
            .map((id) => players.where((p) => p.id == id).firstOrNull)
            .whereType<Player>()
            .toList()
        : players;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: GameSpacing.screenPadding, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < orderedPlayers.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '›',
                    style: GameFont.factionBadge.copyWith(
                      color: gc.GameColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ),
              _buildTurnOrderItem(
                orderedPlayers[i],
                isActive: orderedPlayers[i].id == currentTurnId,
                isMe: orderedPlayers[i].id == myId,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTurnOrderItem(Player player, {required bool isActive, required bool isMe}) {
    final faction = player.character?.faction ?? 'neutral';
    final dotColor = isActive
        ? gc.GameColors.victorianGold
        : gc.GameColors.getFactionColor(faction);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          player.name,
          style: GameFont.factionBadge.copyWith(
            color: isActive
                ? gc.GameColors.victorianGold
                : gc.GameColors.textSecondary,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 11,
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: gc.GameColors.victorianGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              'YOU',
              style: GameFont.factionBadge.copyWith(
                color: gc.GameColors.victorianGold,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCentralArea(GameState gameState, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
              flex: 1,
              child: _buildBillDisplay(gameState.currentBill, theme)),
          const SizedBox(height: 16),

          // 出牌目標區域（拖曳出牌）
          if (gameState.phase == GamePhase.debate ||
              gameState.phase == GamePhase.conspiracy)
            SizedBox(
              height: 80,
              child: CardPlayZone(
                onCardPlayed: (card) => _onCardPlayed(card),
              ),
            ),
          if (gameState.phase == GamePhase.debate ||
              gameState.phase == GamePhase.conspiracy)
            const SizedBox(height: 16),

          Expanded(
              flex: 2,
              child: _buildEventLog(gameState.gameEvents, theme)),
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
            color: theme.colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.article,
                  color: theme.colorScheme.secondary, size: 20),
              const SizedBox(width: 8),
              Text('當前議案',
                  style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w600)),
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
    final config = ref.watch(qualityConfigProvider);
    final maxEvents = config.maxGameEvents;
    final displayEvents = events.length > maxEvents
        ? events.sublist(events.length - maxEvents)
        : events;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.history,
                    color: theme.colorScheme.secondary, size: 20),
                const SizedBox(width: 8),
                Text('事件日誌',
                    style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: displayEvents.length,
              addAutomaticKeepAlives: false,
              itemBuilder: (context, index) =>
                  _buildEventItem(displayEvents[index], theme),
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
          Icon(eventIcon, size: 16, color: eventColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(event.description,
                style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.8))),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionArea(GameState gameState, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: gc.GameColors.bgSecondary,
        border: Border(
          top: BorderSide(
              color: gc.GameColors.victorianGold.withValues(alpha: 0.2),
              width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 手牌區 — 使用新的 GameCardWidget
              SizedBox(
                height: 130,
                child: _buildHandCardsArea(gameState, theme),
              ),
              const SizedBox(height: 16),
              _buildActionButtons(gameState.phase, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandCardsArea(GameState gameState, ThemeData theme) {
    final handCards = gameState.hand;

    if (handCards.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text('暫無手牌',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.6))),
        ),
      );
    }

    // 計算哪些牌可以出
    final playableCards = gameState.playableCards;

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: handCards.length,
      itemBuilder: (context, index) {
        final card = handCards[index];
        final isPlayable = playableCards.contains(card);

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GameCardWidget(
            card: card,
            isPlayable: isPlayable,
            width: 85,
            height: 125,
            onTap: isPlayable ? () => _onCardTapped(card) : null,
            onDragCompleted: isPlayable ? _onCardPlayed : null,
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(GamePhase phase, ThemeData theme) {
    final gameState = ref.read(gameStateProvider);
    List<Widget> buttons = [];

    switch (phase) {
      case GamePhase.playerTurn:
        final isMyTurn = gameState?.isMyTurn ?? false;
        if (isMyTurn) {
          buttons = [
            _buildActionButton('質詢', Icons.gavel, theme, () {
              _showChallengeDialog(context);
            }),
            _buildActionButton('結盟', Icons.handshake, theme, () {}),
            _buildActionButton('技能', Icons.flash_on, theme, () {
              _showSkillDialog(context);
            }),
            _buildEndTurnButton(theme),
          ];
        } else {
          final turnPlayerName = gameState?.currentTurnPlayerName ?? '其他玩家';
          buttons = [
            _buildActionButton('等待 $turnPlayerName', Icons.hourglass_empty, theme, null),
          ];
        }
        break;
      case GamePhase.conspiracy:
        buttons = [
          _buildActionButton('調查', Icons.search, theme, () {}),
          _buildActionButton('結盟', Icons.handshake, theme, () {}),
          _buildActionButton('賄賂', Icons.attach_money, theme, () {}),
        ];
        break;
      case GamePhase.debate:
        buttons = [
          _buildActionButton('質詢', Icons.gavel, theme, () {
            _showChallengeDialog(context);
          }),
          _buildActionButton('反駁', Icons.shield, theme, () {
            HapticService.cardPlayed();
            ref.read(gameActionsProvider).counter();
          }),
          _buildActionButton('技能', Icons.flash_on, theme, () {
            _showSkillDialog(context);
          }),
        ];
        break;
      case GamePhase.voting:
        buttons = [
          _buildActionButton('支持', Icons.thumb_up, theme, () {
            HapticService.voteConfirmed();
            ref.read(audioServiceProvider).playSfx(SfxType.vote);
            ref.read(gameActionsProvider).vote(VoteChoice.a);
          }),
          _buildActionButton('反對', Icons.thumb_down, theme, () {
            HapticService.voteConfirmed();
            ref.read(audioServiceProvider).playSfx(SfxType.vote);
            ref.read(gameActionsProvider).vote(VoteChoice.b);
          }),
          _buildActionButton('棄權', Icons.remove, theme, () {
            HapticService.voteConfirmed();
            ref.read(audioServiceProvider).playSfx(SfxType.vote);
            ref.read(gameActionsProvider).vote(VoteChoice.abstain);
          }),
        ];
        break;
      default:
        buttons = [
          _buildActionButton('等待中', Icons.hourglass_empty, theme, null),
        ];
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 回合制資訊列（行動點數 + 輪到誰）
        if (phase == GamePhase.playerTurn && gameState != null) ...[
          _buildTurnInfoBar(gameState!, theme),
          const SizedBox(height: 8),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: buttons,
        ),
      ],
    );
  }

  /// 回合制資訊列：顯示輪到誰、剩餘行動點數
  Widget _buildTurnInfoBar(GameState gameState, ThemeData theme) {
    final isMyTurn = gameState.isMyTurn;
    final turnPlayerName = gameState.currentTurnPlayerName ?? '等待中';
    final actionPoints = gameState.actionPointsRemaining;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isMyTurn
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: isMyTurn
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isMyTurn ? Icons.play_circle_filled : Icons.hourglass_top,
            size: 18,
            color: isMyTurn
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            isMyTurn ? '🎯 輪到你了！' : '⏳ $turnPlayerName 行動中',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isMyTurn ? FontWeight.bold : FontWeight.normal,
              color: isMyTurn
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (isMyTurn) ...[
            const SizedBox(width: 12),
            // 行動點數指示器
            Row(
              children: List.generate(3, (i) => Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Icon(
                  i < actionPoints ? Icons.circle : Icons.circle_outlined,
                  size: 12,
                  color: i < actionPoints
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
              )),
            ),
            const SizedBox(width: 4),
            Text(
              '$actionPoints AP',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 結束回合按鈕 — 金色漸層大按鈕
  Widget _buildEndTurnButton(ThemeData theme) {
    return _EndTurnButton(
      onTap: () {
        HapticService.cardPlayed();
        ref.read(gameActionsProvider).endTurn();
      },
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, ThemeData theme, VoidCallback? onPressed) {
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
            : theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isChatExpanded ? 400 : 0,
            width: _isChatExpanded ? 320 : 0,
            child: _isChatExpanded
                ? _buildChatContent(gameState.chatMessages, theme)
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              FloatingActionButton(
                mini: true,
                onPressed: _toggleChat,
                backgroundColor: theme.colorScheme.secondary,
                child: Icon(_isChatExpanded ? Icons.close : Icons.chat,
                    color: theme.colorScheme.onSecondary),
              ),
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
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
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
    final config = ref.watch(qualityConfigProvider);
    final maxMessages = config.maxChatMessages;
    final displayMessages = messages.length > maxMessages
        ? messages.sublist(messages.length - maxMessages)
        : messages;

    return Container(
      decoration: PerformanceAwareDecoration.build(
        config: config,
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.chat, size: 16, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Text('聊天',
                    style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: displayMessages.length,
              addAutomaticKeepAlives: false,
              itemBuilder: (context, index) =>
                  _buildChatMessage(displayMessages[index], theme),
            ),
          ),
          Divider(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.3)),
          _buildQuickMessages(theme),
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
          Text(message.fromName,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w600)),
          Text(message.content, style: theme.textTheme.bodySmall),
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
                    color:
                        theme.colorScheme.secondary.withValues(alpha: 0.3)),
              ),
              child: Text(message,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.secondary)),
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                      color:
                          theme.colorScheme.outline.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                      color:
                          theme.colorScheme.outline.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide:
                      BorderSide(color: theme.colorScheme.secondary),
                ),
              ),
              onSubmitted: _sendChatMessage,
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
              child: Icon(Icons.send,
                  size: 16, color: theme.colorScheme.onSecondary),
            ),
          ),
        ],
      ),
    );
  }

  void _sendQuickMessage(String message) {
    ref.read(gameActionsProvider).sendChat(message);
  }

  void _sendChatMessage(String text) {
    if (text.trim().isEmpty) return;
    ref.read(gameActionsProvider).sendChat(text.trim());
    _chatController.clear();
  }

  void _triggerPhaseTransition(GamePhase newPhase) {
    if (!mounted) return;

    final config = ref.read(qualityConfigProvider);

    // 低品質：跳過轉場動畫
    if (config.skipPhaseTransition) {
      return;
    }

    // 根據品質調整動畫參數
    _phaseTransitionController.duration = config.phaseTransitionDuration;

    if (config.enableElasticCurves) {
      _phaseTransitionScale = Tween<double>(
        begin: 0.8,
        end: 1.2,
      ).animate(CurvedAnimation(
        parent: _phaseTransitionController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ));
    } else {
      // 中品質：去掉 elasticOut，用 easeOut
      _phaseTransitionScale = Tween<double>(
        begin: 0.9,
        end: 1.1,
      ).animate(CurvedAnimation(
        parent: _phaseTransitionController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ));
    }

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
                      child:
                          Icon(phaseInfo.icon, size: 60, color: Colors.white),
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
                              color: Colors.black.withValues(alpha: 0.3)),
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
                              color: Colors.black.withValues(alpha: 0.3)),
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
            gc.GameColors.bgPrimary.withValues(alpha: 0.95),
            gc.GameColors.bgCard.withValues(alpha: 0.95),
          ],
        );
      case GamePhase.debate:
        return PhaseTransitionInfo(
          title: '辯論階段',
          subtitle: '展開激烈的政治攻防',
          icon: Icons.campaign,
          colors: [
            gc.GameColors.deepCrimson.withValues(alpha: 0.9),
            gc.GameColors.roseRed.withValues(alpha: 0.9),
          ],
        );
      case GamePhase.voting:
        return PhaseTransitionInfo(
          title: '投票階段',
          subtitle: '決定議案的命運',
          icon: Icons.how_to_vote,
          colors: [
            gc.GameColors.victorianGold.withValues(alpha: 0.9),
            gc.GameColors.goldLight.withValues(alpha: 0.9),
          ],
        );
      case GamePhase.result:
        return PhaseTransitionInfo(
          title: '結算中...',
          subtitle: '統計投票結果',
          icon: Icons.analytics,
          colors: [
            gc.GameColors.raritySR.withValues(alpha: 0.9),
            gc.GameColors.rarityR.withValues(alpha: 0.9),
          ],
        );
      default:
        return PhaseTransitionInfo(
          title: '遊戲進行中',
          subtitle: '',
          icon: Icons.play_arrow,
          colors: [
            gc.GameColors.bgPrimary.withValues(alpha: 0.9),
            gc.GameColors.bgSecondary.withValues(alpha: 0.9),
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
          Row(
            children: [
              Icon(Icons.gavel, color: theme.colorScheme.secondary, size: 24),
              const SizedBox(width: 8),
              Text('當前議案',
                  style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            gameState.currentBill ?? '等待議案',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _getBillDescription(gameState.currentBill),
            style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.8)),
          ),
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
            color: theme.colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('投票效果預覽',
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...effects.map((effect) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.arrow_forward_ios,
                        size: 12,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.7)),
                    const SizedBox(width: 8),
                    Expanded(
                        child:
                            Text(effect, style: theme.textTheme.bodySmall)),
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
          '否決：工人聲望 -5，工廠主聲望 +5'
        ];
      case '《新聞審查法》':
        return [
          '通過：記者聲望 -15，其他人聲望 +5',
          '否決：記者聲望 +8，其他人聲望 -2'
        ];
      case '《穀物法廢除》':
        return [
          '通過：工廠主聲望 +10，工人聲望 +5',
          '否決：工廠主聲望 -5，工人聲望 -3'
        ];
      case '《結社自由法》':
        return [
          '通過：盧德派聲望 +15，工廠主聲望 -10',
          '否決：盧德派聲望 -8，工廠主聲望 +5'
        ];
      case '《選舉改革法》':
        return [
          '通過：全員聲望 +5，最高聲望者 -10',
          '否決：全員聲望 -3'
        ];
      default:
        return ['投票效果將在議案確定後顯示'];
    }
  }

  void _toggleChat() {
    setState(() => _isChatExpanded = !_isChatExpanded);
  }

  void _onCardTapped(GameCard card) {
    HapticService.cardPlayed();
    ref.read(audioServiceProvider).playSfx(SfxType.cardPlay);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('使用卡牌: ${card.name}')),
    );
  }

  void _onCardPlayed(GameCard card) {
    HapticService.cardPlayed();
    ref.read(audioServiceProvider).playSfx(SfxType.cardPlay);
    final gameActions = ref.read(gameActionsProvider);
    gameActions.useCard(card);
  }

  void _showChallengeDialog(BuildContext context) {
    final gameState = ref.read(gameStateProvider);
    if (gameState == null) return;

    final currentId = gameState.currentPlayerId;
    final targets = gameState.room.alivePlayers
        .where((p) => p.id != currentId)
        .toList();

    if (targets.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('選擇質詢目標'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: targets.length,
            itemBuilder: (_, index) {
              final target = targets[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(target.name.isNotEmpty
                      ? target.name.substring(0, 1)
                      : '?'),
                ),
                title: Text(target.name),
                subtitle: Text(target.character?.displayName ?? ''),
                onTap: () {
                  Navigator.of(ctx).pop();
                  HapticService.cardPlayed();
                  ref.read(gameActionsProvider).challengePlayer(target);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _showSkillDialog(BuildContext context) {
    final gameState = ref.read(gameStateProvider);
    if (gameState == null) return;

    final currentId = gameState.currentPlayerId;
    final targets = gameState.room.alivePlayers
        .where((p) => p.id != currentId)
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('使用技能'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 無目標技能
              ListTile(
                leading: const Icon(Icons.flash_on),
                title: const Text('對自己使用（無目標）'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  HapticService.cardPlayed();
                  ref.read(gameStateProvider.notifier).sendUseSkill(null);
                },
              ),
              const Divider(),
              const Text('或選擇目標：'),
              ...targets.map((target) => ListTile(
                    leading: CircleAvatar(
                      child: Text(target.name.isNotEmpty
                          ? target.name.substring(0, 1)
                          : '?'),
                    ),
                    title: Text(target.name),
                    subtitle: Text(target.character?.displayName ?? ''),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      HapticService.cardPlayed();
                      ref.read(gameStateProvider.notifier).sendUseSkill(target.id);
                    },
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
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

/// 結束回合按鈕 — 金色漸層 + 待機脈衝光暈
///
/// 規格：
/// - 尺寸：140×52pt，圓角 12pt
/// - 背景：goldLight → victorianGold → goldDim 漸層
/// - 文字：深色（bgPrimary）在金色底上
/// - 待機脈衝：邊框 opacity 0.3↔0.9, scaleEffect 1.0↔1.04, 1.2s 週期
class _EndTurnButton extends StatefulWidget {
  final VoidCallback onTap;

  const _EndTurnButton({required this.onTap});

  @override
  State<_EndTurnButton> createState() => _EndTurnButtonState();
}

class _EndTurnButtonState extends State<_EndTurnButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: GameAnimation.endTurnPulseDuration,
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final pulseValue = _pulseAnimation.value;
        final borderOpacity = 0.3 + pulseValue * 0.6;
        final scale = _isPressed ? 0.92 : (1.0 + pulseValue * 0.04);
        final shadowRadius = 6.0 + pulseValue * 6.0;

        return GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: scale,
            duration: GameAnimation.buttonPressDuration,
            curve: GameAnimation.buttonPressCurve,
            child: Container(
              width: 140,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: gc.GameColors.goldButtonGradient,
                border: Border.all(
                  color: gc.GameColors.goldLight.withValues(alpha: borderOpacity),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gc.GameColors.victorianGold.withValues(alpha: 0.5),
                    blurRadius: shadowRadius,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield, size: 18,
                      color: gc.GameColors.bgPrimary),
                  const SizedBox(width: 6),
                  Text(
                    '結束回合',
                    style: GameFont.endTurnButton.copyWith(
                      color: gc.GameColors.bgPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
