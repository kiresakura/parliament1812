import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/game_colors.dart';
import '../../config/theme.dart';
import '../../ui/theme/game_colors.dart' as gc;
import '../../ui/theme/game_fonts.dart';
import '../../ui/theme/game_spacing.dart';
import '../../models/card.dart';
import '../../models/single_player.dart';
import '../../providers/auth_provider.dart';
import '../../providers/single_player_provider.dart';
import '../../services/audio_service.dart';
import '../../services/haptic_service.dart';
import '../../services/performance_service.dart';
import '../../widgets/game_card_widget.dart';
import '../../widgets/performance_aware.dart';
// AnimatedReputationBar replaced by LinearProgressIndicator in Rossetti v2

// ═══════════════════════════════════════════
// 角色肖像映射
// ═══════════════════════════════════════════

/// 根據角色 ID 返回角色肖像路徑
String _portraitPath(String characterId) {
  const map = {
    'thomas': 'assets/images/characters/portrait_thomas.png',
    'richard': 'assets/images/characters/portrait_richard.png',
    'george': 'assets/images/characters/portrait_george.png',
    'robert': 'assets/images/characters/portrait_robert.png',
    'william': 'assets/images/characters/portrait_william.png',
    'edward': 'assets/images/characters/portrait_thomas.png', // fallback
  };
  return map[characterId] ?? 'assets/images/characters/portrait_thomas.png';
}

/// 根據角色 ID 返回角色名（中文）
String _characterDisplayName(String characterId) {
  const map = {
    'thomas': '工人湯瑪斯',
    'richard': '工廠主理查',
    'george': '盧德派喬治',
    'robert': '改革者羅伯特',
    'edward': '記者愛德華',
    'william': '議員威廉',
  };
  return map[characterId] ?? characterId;
}

/// 根據角色 ID 返回所屬派系
String _characterFaction(String characterId) {
  const map = {
    'thomas': 'labor',
    'george': 'labor',
    'richard': 'capital',
    'robert': 'reform',
    'edward': 'neutral',
    'william': 'neutral',
  };
  return map[characterId] ?? 'neutral';
}

// ═══════════════════════════════════════════
// 卡牌映射：Map<String,dynamic> → GameCard
// ═══════════════════════════════════════════

/// 將本地引擎輸出的卡牌 Map 轉換為 GameCard 模型
GameCard _mapToGameCard(Map<String, dynamic> cardMap) {
  final id = cardMap['id'] as String? ?? '';

  // 嘗試從 CardDatabase 直接取得
  final dbCard = CardDatabase.getCard(id);
  if (dbCard != null) return dbCard;

  // fallback: 從 map 建構
  final name = cardMap['name'] as String? ?? '卡牌';
  final description = cardMap['description'] as String? ?? '';
  final typeStr = cardMap['card_type'] as String? ?? 'attack';
  final rarityStr = cardMap['rarity'] as String? ?? 'N';
  final baseValue = cardMap['base_value'] as int? ?? 0;
  final influenceCost = cardMap['influence_cost'] as int? ?? 0;

  CardType cardType;
  switch (typeStr) {
    case 'attack':
      cardType = CardType.attack;
      break;
    case 'defense':
      cardType = CardType.defense;
      break;
    case 'control':
      cardType = CardType.control;
      break;
    case 'buff':
      cardType = CardType.buff;
      break;
    case 'intel':
      cardType = CardType.intel;
      break;
    case 'healing':
      cardType = CardType.healing;
      break;
    case 'social':
      cardType = CardType.social;
      break;
    case 'special':
      cardType = CardType.special;
      break;
    default:
      cardType = CardType.attack;
  }

  CardRarity rarity;
  switch (rarityStr) {
    case 'R':
      rarity = CardRarity.rare;
      break;
    case 'SR':
      rarity = CardRarity.epic;
      break;
    case 'SSR':
      rarity = CardRarity.legendary;
      break;
    default:
      rarity = CardRarity.normal;
  }

  return GameCard(
    id: id,
    name: name,
    description: description,
    type: cardType,
    rarity: rarity,
    targetType: CardTargetType.single,
    influenceCost: influenceCost,
    baseValue: baseValue,
  );
}

// ═══════════════════════════════════════════
// 階段引導提示
// ═══════════════════════════════════════════

const _phaseGuideMessages = <String, String>{
  'player_turn': '行動階段：出牌、質詢、結盟或使用技能（有限行動點數）',
  'conspiracy': '密謀階段：你可以與其他議員私下交流、結盟或調查對手',
  'debate': '辯論階段：攻擊對手、防禦自己，或使用卡牌',
  'voting': '投票階段：支持或反對議案，決定國家的未來',
  'ai_turn': 'AI 議員正在行動，請觀察他們的策略...',
};

// ═══════════════════════════════════════════
// 主畫面
// ═══════════════════════════════════════════

class SinglePlayerGameScreen extends ConsumerStatefulWidget {
  const SinglePlayerGameScreen({super.key});

  @override
  ConsumerState<SinglePlayerGameScreen> createState() =>
      _SinglePlayerGameScreenState();
}

class _SinglePlayerGameScreenState
    extends ConsumerState<SinglePlayerGameScreen>
    with TickerProviderStateMixin {
  // 階段轉場動畫
  late AnimationController _phaseTransitionController;
  late Animation<double> _phaseTransitionOpacity;
  late Animation<double> _phaseTransitionScale;
  bool _isShowingPhaseTransition = false;
  String? _transitionPhase;

  // P0-1: 金色呼吸光暈
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // 聊天面板
  bool _isChatExpanded = false;
  final TextEditingController _chatController = TextEditingController();
  final List<_ChatMsg> _chatMessages = [];

  // 引導氣泡
  bool _showGuide = false;
  String _guideText = '';

  // 追蹤上一次的階段（偵測階段變化）
  String? _lastPhase;

  // AI 回合展示
  bool _isShowingAiTurn = false;
  int _currentAiActionIndex = 0;
  Timer? _aiTurnTimer;

  // P0-3: 數值飛字追蹤
  final Map<String, int> _lastReputations = {};
  final Map<String, _FlyTextData?> _flyTexts = {};

  // P0-4: 事件日誌追蹤（用於 fadeIn 動畫）
  int _lastLogCount = 0;

  // Step 5: 手牌扇形展示 — 選中牌索引
  int? _selectedCardIndex;

  // 快捷訊息
  final List<String> _quickMessages = [
    '結盟？',
    '好手段！',
    '你完了。',
    '投我一票',
    '我同意。',
  ];

  @override
  void initState() {
    super.initState();

    _phaseTransitionController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _phaseTransitionOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _phaseTransitionController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _phaseTransitionScale = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _phaseTransitionController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _phaseTransitionController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() => _isShowingPhaseTransition = false);
            _phaseTransitionController.reset();
          }
        });
      }
    });

    // P0-1: 金色呼吸光暈
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(
      begin: GameColors.selectionGlowOpacityMin,
      end: GameColors.selectionGlowOpacityMax,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // 播放遊戲 BGM
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioServiceProvider).playBgm(BgmType.game);
      _checkShowGuide();
    });
  }

  @override
  void dispose() {
    _phaseTransitionController.dispose();
    _glowController.dispose();
    _chatController.dispose();
    _aiTurnTimer?.cancel();
    super.dispose();
  }

  /// 檢查是否需要顯示引導
  Future<void> _checkShowGuide() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final seen = prefs.getBool('sp_guide_seen') ?? false;
    if (!seen) {
      final state = ref.read(singlePlayerProvider);
      if (state != null && _phaseGuideMessages.containsKey(state.phase)) {
        setState(() {
          _showGuide = true;
          _guideText = _phaseGuideMessages[state.phase]!;
        });
      }
    }
  }

  /// 關閉引導
  void _dismissGuide() async {
    setState(() => _showGuide = false);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('sp_guide_seen', true);
  }

  /// 開始 AI 回合逐步展示
  void _startAiTurnAnimation(SinglePlayerState gameState) {
    if (_isShowingAiTurn) return;
    final actions = gameState.pendingAiActions;
    if (actions.isEmpty) return;

    _isShowingAiTurn = true;
    _currentAiActionIndex = 0;

    _showNextAiAction(actions);
  }

  void _showNextAiAction(List<AiActionRecord> actions) {
    if (!mounted) return;
    if (_currentAiActionIndex >= actions.length) {
      // 所有 AI 行動展示完畢
      _aiTurnTimer?.cancel();
      setState(() => _isShowingAiTurn = false);
      ref.read(singlePlayerProvider.notifier).updateAiTurnActor(null);
      // 推進到投票階段
      ref.read(singlePlayerProvider.notifier).finishAiTurn();
      return;
    }

    final action = actions[_currentAiActionIndex];
    ref.read(singlePlayerProvider.notifier).updateAiTurnActor(action.actorId);
    setState(() {});

    _currentAiActionIndex++;

    // 間隔 1000ms 展示下一個行動
    _aiTurnTimer = Timer(const Duration(milliseconds: 1000), () {
      _showNextAiAction(actions);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gameState = ref.watch(singlePlayerProvider);

    // 監聽階段變化
    if (gameState != null && gameState.phase != _lastPhase) {
      final oldPhase = _lastPhase;
      _lastPhase = gameState.phase;
      if (oldPhase != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _triggerPhaseTransition(gameState.phase);
          _showPhaseGuide(gameState.phase);

          // 偵測進入 AI 回合
          if (gameState.phase == 'ai_turn') {
            _startAiTurnAnimation(gameState);
          }
        });
      }
    }

    // P0-3: 追蹤聲望變化用於飛字
    if (gameState != null) {
      _trackReputationChanges(gameState);
    }

    if (gameState == null) {
      return _buildLoadingScreen(theme);
    }

    if (gameState.isGameOver && gameState.result != null) {
      return _GameOverView(result: gameState.result!);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
              _buildTopInfoBar(gameState, theme),
              _buildTurnOrderBar(gameState, theme),
              Expanded(
                child: _buildMainContent(gameState, theme),
              ),
              _buildBottomActionArea(gameState, theme),
            ],
          ),

          // 聊天面板（行動/密謀階段）
          if (gameState.phase == 'player_turn' || gameState.phase == 'conspiracy') _buildChatOverlay(theme),

          // 階段轉場動畫
          if (_isShowingPhaseTransition) _buildPhaseTransitionOverlay(theme),

          // 引導氣泡
          if (_showGuide) _buildGuideOverlay(theme),
        ],
      ),
    );
  }

  /// P0-3: 追蹤聲望變化
  void _trackReputationChanges(SinglePlayerState gameState) {
    for (final player in gameState.players) {
      final lastRep = _lastReputations[player.id];
      if (lastRep != null && lastRep != player.reputation) {
        final delta = player.reputation - lastRep;
        _flyTexts[player.id] = _FlyTextData(
          delta: delta,
          timestamp: DateTime.now(),
        );
      }
      _lastReputations[player.id] = player.reputation;
    }
  }

  // ─── 載入畫面 ───

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

  // ─── 頂部信息欄 ───

  Widget _buildTopInfoBar(SinglePlayerState state, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _buildPhaseIndicator(state.phase, theme),
              const Spacer(),
              _buildRoundBadge(state.currentRound, theme),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.settings,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    size: 20),
                onPressed: () => _showGameSettings(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseIndicator(String phase, ThemeData theme) {
    String text;
    IconData icon;
    Color color;

    switch (phase) {
      case 'player_turn':
        text = '行動階段';
        icon = Icons.play_circle_outline;
        color = theme.colorScheme.primary;
        break;
      case 'ai_turn':
        text = 'AI 回合';
        icon = Icons.smart_toy;
        color = GameColors.aiTurnHighlight;
        break;
      case 'conspiracy':
        text = '密謀階段';
        icon = Icons.visibility_off;
        color = theme.colorScheme.secondary;
        break;
      case 'debate':
        text = '辯論階段';
        icon = Icons.forum;
        color = theme.colorScheme.primary;
        break;
      case 'voting':
        text = '投票階段';
        icon = Icons.how_to_vote;
        color = const Color(0xFF4CAF50);
        break;
      case 'result':
        text = '結算階段';
        icon = Icons.emoji_events;
        color = theme.colorScheme.secondary;
        break;
      default:
        text = '準備中';
        icon = Icons.hourglass_empty;
        color = theme.colorScheme.outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(text,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildRoundBadge(int round, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3), width: 1),
      ),
      child: Text('第$round回合',
          style:
              theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
    );
  }

  // ─── 中央主內容 ───

  Widget _buildMainContent(SinglePlayerState state, ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 議案區
          _buildBillArea(state, theme),

          // 玩家卡片區
          _buildPlayersArea(state, theme),

          // 事件日誌
          if (state.aiActionsLog.isNotEmpty) _buildEventLog(state, theme),
        ],
      ),
    );
  }

  // ─── 投票支持率計算 ───

  /// 根據玩家派系與聲望計算 FOR/AGAINST 百分比
  (double forPct, double againstPct) _calculateVotePercentage(
      SinglePlayerState state) {
    if (state.players.isEmpty) return (0.55, 0.45);

    // 找到人類玩家的派系
    final humanPlayer = state.players.where((p) => !p.isAi).firstOrNull;
    if (humanPlayer == null) return (0.55, 0.45);

    final humanFaction = _characterFaction(humanPlayer.character);

    double forWeight = 0;
    double againstWeight = 0;
    double totalWeight = 0;

    for (final player in state.players) {
      if (player.isPoliticallyDead) continue;

      final rep = player.reputation.toDouble().clamp(1.0, double.infinity);
      totalWeight += rep;

      if (!player.isAi) {
        // 人類玩家算 FOR
        forWeight += rep;
      } else {
        final aiFaction = _characterFaction(player.character);
        if (aiFaction == humanFaction) {
          // 同派系 → FOR
          forWeight += rep;
        } else if (aiFaction == 'neutral') {
          // neutral → 50/50
          forWeight += rep * 0.5;
          againstWeight += rep * 0.5;
        } else {
          // 不同派系 → AGAINST
          againstWeight += rep;
        }
      }
    }

    if (totalWeight <= 0) return (0.55, 0.45);

    final forPct = (forWeight / totalWeight).clamp(0.0, 1.0);
    final againstPct = (againstWeight / totalWeight).clamp(0.0, 1.0);

    return (forPct, againstPct);
  }

  // ─── 投票進度條 ───

  Widget _buildVoteProgressBars(SinglePlayerState state, ThemeData theme) {
    final (forPct, againstPct) = _calculateVotePercentage(state);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          _buildSingleVoteBar(
            label: 'FOR',
            percent: forPct,
            color: const Color(0xFF27AE60),
            icon: '✓',
            theme: theme,
          ),
          const SizedBox(height: 6),
          _buildSingleVoteBar(
            label: 'AGAINST',
            percent: againstPct,
            color: const Color(0xFFE74C3C),
            icon: '✗',
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildSingleVoteBar({
    required String label,
    required double percent,
    required Color color,
    required String icon,
    required ThemeData theme,
  }) {
    final percentInt = (percent * 100).round();

    return Row(
      children: [
        // 標籤（固定寬度，Inter Bold 12sp）
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: GameFont.factionBadge.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        // 進度條
        Expanded(
          child: SizedBox(
            height: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Stack(
                children: [
                  // 背景
                  Container(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  // 動畫進度條
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: percent),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: value.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 百分比 + icon（右對齊）
        SizedBox(
          width: 52,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: percentInt.toDouble()),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Text(
                '${value.round()}% $icon',
                textAlign: TextAlign.right,
                style: GameFont.factionBadge.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── 議案區 ───

  Widget _buildBillArea(SinglePlayerState state, ThemeData theme) {
    final config = ref.watch(qualityConfigProvider);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: PerformanceAwareDecoration.build(
        config: config,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.secondary.withValues(alpha: 0.12),
            theme.colorScheme.secondary.withValues(alpha: 0.04),
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
              Icon(Icons.gavel,
                  color: theme.colorScheme.secondary, size: 22),
              const SizedBox(width: 8),
              Text('當前議案',
                  style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            state.currentBill.isNotEmpty ? state.currentBill : '等待議案',
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),

          // FOR/AGAINST 投票進度條（所有階段都顯示）
          if (state.currentBill.isNotEmpty)
            _buildVoteProgressBars(state, theme),

          // 投票階段顯示效果預覽
          if (state.phase == 'voting') ...[
            const SizedBox(height: 12),
            _buildBillEffectPreview(state.currentBill, theme),
          ],
        ],
      ),
    );
  }

  Widget _buildBillEffectPreview(String billName, ThemeData theme) {
    final effects = _getBillEffects(billName);
    return Container(
      padding: const EdgeInsets.all(10),
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
          const SizedBox(height: 6),
          ...effects.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    Icon(Icons.arrow_forward_ios,
                        size: 10,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6)),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(e, style: theme.textTheme.bodySmall)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  List<String> _getBillEffects(String billName) {
    if (billName.contains('工廠')) {
      return ['通過：工人聲望+10，工廠主聲望-10', '否決：工人聲望-5，工廠主聲望+5'];
    }
    if (billName.contains('新聞')) {
      return ['通過：記者聲望-15，其他+5', '否決：記者聲望+8，其他-2'];
    }
    if (billName.contains('穀物')) {
      return ['通過：工廠主聲望+10，工人+5', '否決：工廠主-5，工人-3'];
    }
    if (billName.contains('結社')) {
      return ['通過：盧德派聲望+15，工廠主-10', '否決：盧德派-8，工廠主+5'];
    }
    if (billName.contains('選舉')) {
      return ['通過：全員聲望+5，最高聲望者-10', '否決：全員聲望-3'];
    }
    return ['投票效果將在議案確定後顯示'];
  }

  // ─── 玩家卡片區（羅塞蒂 v2 三欄 + 回合順序列） ───

  Widget _buildPlayersArea(SinglePlayerState state, ThemeData theme) {
    return Column(
      children: [
        // 三欄橫排玩家卡
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GameSpacing.screenPadding,
            vertical: 8,
          ),
          child: Row(
            children: [
              for (int i = 0; i < state.players.length; i++) ...[
                if (i > 0) const SizedBox(width: GameSpacing.cardGap),
                Expanded(
                  child: _PlayerCard(
                    player: state.players[i],
                    glowAnimation: _glowAnimation,
                    isAiTurnActor: state.aiTurnActorId == state.players[i].id,
                    isCurrentTurn: state.currentTurnPlayerId == state.players[i].id,
                    flyText: _flyTexts[state.players[i].id],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ─── 回合順序列 ───

  Widget _buildTurnOrderBar(SinglePlayerState state, ThemeData theme) {
    final players = state.players;
    final currentTurnId = state.currentTurnPlayerId;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: GameSpacing.screenPadding,
        vertical: 6,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < players.length; i++) ...[
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
                players[i],
                isActive: players[i].id == currentTurnId,
                isMe: !players[i].isAi,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTurnOrderItem(
    SinglePlayerInfo player, {
    required bool isActive,
    required bool isMe,
  }) {
    final faction = _characterFaction(player.character);
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
          _characterDisplayName(player.character),
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

  // ─── P0-4: 事件日誌（可讀性改善） ───

  Widget _buildEventLog(SinglePlayerState state, ThemeData theme) {
    final config = ref.watch(qualityConfigProvider);
    final maxEvents = config.maxGameEvents;
    final logs = state.aiActionsLog.length > maxEvents
        ? state.aiActionsLog.sublist(state.aiActionsLog.length - maxEvents)
        : state.aiActionsLog;

    // 記錄新事件數量用於動畫
    final newLogCount = logs.length;
    final newEventsCount = newLogCount - _lastLogCount;
    _lastLogCount = newLogCount;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: PerformanceAwareDecoration.build(
        config: config,
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
              Icon(Icons.history,
                  color: theme.colorScheme.secondary, size: 18),
              const SizedBox(width: 6),
              Text('事件日誌',
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          ...logs.asMap().entries.map((entry) {
            final index = entry.key;
            final log = entry.value;

            // 分隔線
            if (log.startsWith('─')) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Divider(
                  color: GameColors.gold.withValues(alpha: 0.3),
                  height: 1,
                ),
              );
            }

            final eventInfo = _parseEventInfo(log);
            final isNew = index >= (logs.length - newEventsCount.clamp(0, logs.length));
            final isImportant = _isImportantEvent(log);

            return _EventLogEntry(
              log: log,
              eventInfo: eventInfo,
              isNew: isNew,
              isImportant: isImportant,
            );
          }),
        ],
      ),
    );
  }

  _EventInfo _parseEventInfo(String log) {
    if (log.contains('⚔️') || log.contains('質詢')) {
      return _EventInfo(icon: Icons.gavel, color: GameColors.logChallenge, emoji: '⚔️');
    }
    if (log.contains('💚') || log.contains('恢復')) {
      return _EventInfo(icon: Icons.favorite, color: GameColors.logAlliance, emoji: '🤝');
    }
    if (log.contains('🤝') || log.contains('結盟')) {
      return _EventInfo(icon: Icons.handshake, color: GameColors.logAlliance, emoji: '🤝');
    }
    if (log.contains('🗳️') || log.contains('投')) {
      return _EventInfo(icon: Icons.how_to_vote, color: GameColors.logVote, emoji: '🗳️');
    }
    if (log.contains('💀') || log.contains('死亡') || log.contains('淘汰')) {
      return _EventInfo(icon: Icons.dangerous, color: GameColors.logChallenge, emoji: '💀');
    }
    if (log.contains('🃏') || log.contains('抽')) {
      return _EventInfo(icon: Icons.style, color: GameColors.logCard, emoji: '🃏');
    }
    if (log.contains('💰') || log.contains('金幣')) {
      return _EventInfo(icon: Icons.monetization_on, color: GameColors.logEconomy, emoji: '💰');
    }
    if (log.contains('⬆️') || log.contains('⬇️')) {
      return _EventInfo(icon: Icons.trending_up, color: GameColors.logCard, emoji: '🃏');
    }
    if (log.contains('🔒')) {
      return _EventInfo(icon: Icons.lock, color: GameColors.logCard, emoji: '🃏');
    }
    if (log.contains('📊')) {
      return _EventInfo(icon: Icons.bar_chart, color: GameColors.logVote, emoji: '🗳️');
    }
    return _EventInfo(icon: Icons.info_outline, color: GameColors.logSystem, emoji: '📜');
  }

  bool _isImportantEvent(String log) {
    return log.contains('💀') || log.contains('死亡') ||
           log.contains('📊') || log.contains('淘汰') ||
           log.contains('投票結果');
  }

  // ─── 底部行動區 ───

  Widget _buildBottomActionArea(SinglePlayerState state, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
              width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 手牌區（扇形展示）
              _buildHandCardsArea(state, theme),
              const SizedBox(height: 8),
              // 角色狀態面板
              _buildCharacterPanel(state),
              const SizedBox(height: 8),
              // 行動按鈕
              _buildActionButtons(state, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandCardsArea(SinglePlayerState state, ThemeData theme) {
    final handCards = state.hand;
    final count = handCards.length;

    if (count == 0) {
      return SizedBox(
        height: 130,
        child: Container(
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
        ),
      );
    }

    const cardWidth = 85.0;
    const cardHeight = 125.0;
    const overlap = 60.0;
    const maxAngleDeg = 15.0;

    final totalWidth = cardWidth + (count - 1) * overlap;
    final canPlay =
        state.phase == 'player_turn' || state.phase == 'debate' || state.phase == 'conspiracy';

    // 清除選中狀態如果手牌數量變化導致索引越界
    if (_selectedCardIndex != null && _selectedCardIndex! >= count) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedCardIndex = null);
      });
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        height: cardHeight + 40, // 額外空間給選中跳起
        child: Center(
          child: SizedBox(
            width: totalWidth,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: List.generate(count, (i) {
                // 計算扇形角度（均分 -15° 到 +15°）
                final normalizedPos = count > 1
                    ? (i - (count - 1) / 2) / ((count - 1) / 2)
                    : 0.0;
                final angleDeg = normalizedPos * maxAngleDeg;
                final angleRad = angleDeg * math.pi / 180;
                // 弧形下沉：越外側越下移
                final yOffset = (normalizedPos.abs()) * 12;
                final isSelected = _selectedCardIndex == i;

                final cardMap = handCards[i];
                final gameCard = _mapToGameCard(cardMap);

                // 選中的牌提到最上層（z-index）
                return Positioned(
                  left: i * overlap,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () {
                      if (_selectedCardIndex == i) {
                        // 再次點擊 → 出牌
                        if (canPlay) {
                          setState(() => _selectedCardIndex = null);
                          _onCardTapped(gameCard);
                        }
                      } else {
                        setState(() => _selectedCardIndex = i);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      // ignore: deprecated_member_use
                      transform: Matrix4.identity()
                        // ignore: deprecated_member_use
                        ..translate(0.0, isSelected ? -20.0 : yOffset)
                        ..rotateZ(angleRad)
                        // ignore: deprecated_member_use
                        ..scale(isSelected ? 1.05 : 1.0),
                      transformAlignment: Alignment.bottomCenter,
                      child: GameCardWidget(
                        card: gameCard,
                        isPlayable: canPlay,
                        width: cardWidth,
                        height: cardHeight,
                        onTap: null, // 由外層 GestureDetector 處理
                        onDragCompleted: canPlay ? _onCardPlayed : null,
                      ),
                    ),
                  ),
                );
              })
                // 重新排序：選中的牌放最後（最上層）
                ..sort((a, b) {
                  final aPos = a as Positioned;
                  final bPos = b as Positioned;
                  final aIdx = (aPos.left! / overlap).round();
                  final bIdx = (bPos.left! / overlap).round();
                  if (_selectedCardIndex == aIdx) return 1;
                  if (_selectedCardIndex == bIdx) return -1;
                  return aIdx.compareTo(bIdx);
                }),
            ),
          ),
        ),
      ),
    );
  }

  /// 角色狀態面板（羅塞蒂 v2）
  Widget _buildCharacterPanel(SinglePlayerState state) {
    // 找到人類玩家
    final humanPlayer = state.players.cast<SinglePlayerInfo?>().firstWhere(
          (p) => p != null && !p.isAi,
          orElse: () => null,
        );
    if (humanPlayer == null) return const SizedBox.shrink();

    final characterName = _characterDisplayName(humanPlayer.character);
    final faction = _characterFaction(humanPlayer.character);
    final factionLabel = gc.GameColors.getFactionLabel(faction).toUpperCase();
    final factionColor = gc.GameColors.getFactionColor(faction);
    final reputation = humanPlayer.reputation;
    const maxReputation = 100;
    final reputationRatio = (reputation / maxReputation).clamp(0.0, 1.0);
    final ap = state.actionPointsRemaining;
    const maxAp = 4;
    final round = state.currentRound;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: gc.GameColors.bgSecondary,
        borderRadius: BorderRadius.circular(GameSpacing.buttonRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: 角色名 + 黨派 badge + 回合數
          Row(
            children: [
              // 角色名
              Text(
                characterName,
                style: GameFont.cardTitle.copyWith(
                  color: gc.GameColors.textPrimary,
                ),
              ),
              const Spacer(),
              // 黨派 badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: factionColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(GameSpacing.badgeRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: factionColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      factionLabel,
                      style: GameFont.factionBadge.copyWith(
                        color: factionColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 回合數
              Text(
                '回合 $round/6',
                style: GameFont.factionBadge.copyWith(
                  color: gc.GameColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Row 2: INFLUENCE 進度條
          Row(
            children: [
              Text(
                'INFLUENCE',
                style: GameFont.factionBadge.copyWith(
                  color: gc.GameColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: reputationRatio,
                    minHeight: 6,
                    backgroundColor: gc.GameColors.textSecondary.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(gc.GameColors.roseRed),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$reputation/$maxReputation',
                style: GameFont.factionBadge.copyWith(
                  color: gc.GameColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Row 3: AP 圓點
          Row(
            children: [
              Text(
                'AP',
                style: GameFont.factionBadge.copyWith(
                  color: gc.GameColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              ...List.generate(maxAp, (i) {
                final filled = i < ap;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? gc.GameColors.victorianGold : Colors.transparent,
                      border: Border.all(
                        color: filled
                            ? gc.GameColors.victorianGold
                            : gc.GameColors.textSecondary.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(SinglePlayerState state, ThemeData theme) {
    List<Widget> buttons;

    switch (state.phase) {
      case 'player_turn':
        final ap = state.actionPointsRemaining;
        buttons = [
          _SteampunkButton(
            label: '質詢',
            icon: Icons.search,
            accentColor: GameColors.btnChallenge,
            onPressed: ap > 0 ? () {
              HapticService.cardPlayed();
              ref.read(audioServiceProvider).playSfx(SfxType.cardPlay);
              _showTargetDialog(context, '選擇質詢目標', (targetId) {
                ref.read(singlePlayerProvider.notifier).challenge(targetId);
              });
            } : null,
          ),
          _SteampunkButton(
            label: '結盟',
            icon: Icons.handshake,
            accentColor: GameColors.btnAlliance,
            onPressed: ap > 0 ? () {
              HapticService.cardPlayed();
              _showTargetDialog(context, '選擇結盟對象', (targetId) {
                ref.read(singlePlayerProvider.notifier).formAlliance(targetId);
              });
            } : null,
          ),
          _SteampunkButton(
            label: '抽牌',
            icon: Icons.style,
            accentColor: GameColors.btnDraw,
            onPressed: () {
              HapticService.cardPlayed();
              ref.read(audioServiceProvider).playSfx(SfxType.cardPlay);
              ref.read(singlePlayerProvider.notifier).drawCard();
            },
          ),
          _SteampunkButton(
            label: '結束發言',
            icon: Icons.flag,
            accentColor: GameColors.btnEndTurn,
            onPressed: () {
              HapticService.voteConfirmed();
              ref.read(singlePlayerProvider.notifier).performAction({'type': 'end_turn'});
            },
          ),
        ];
        break;
      case 'ai_turn':
        buttons = [
          _SteampunkButton(
            label: 'AI 行動中...',
            icon: Icons.smart_toy,
            accentColor: GameColors.btnWaiting,
            onPressed: null,
          ),
        ];
        break;
      case 'conspiracy':
        buttons = [
          _SteampunkButton(
            label: '調查',
            icon: Icons.search,
            accentColor: GameColors.btnInvestigate,
            onPressed: () {
              HapticService.cardPlayed();
              ref.read(audioServiceProvider).playSfx(SfxType.cardPlay);
              _showTargetDialog(context, '選擇調查目標', (targetId) {
                ref.read(singlePlayerProvider.notifier).challenge(targetId);
              });
            },
          ),
          _SteampunkButton(
            label: '結盟',
            icon: Icons.handshake,
            accentColor: GameColors.btnAlliance,
            onPressed: () {
              HapticService.cardPlayed();
              _showTargetDialog(context, '選擇結盟對象', (targetId) {
                ref.read(singlePlayerProvider.notifier).formAlliance(targetId);
              });
            },
          ),
          _SteampunkButton(
            label: '下一階段',
            icon: Icons.flag,
            accentColor: GameColors.btnNextPhase,
            onPressed: () {
              HapticService.voteConfirmed();
              ref.read(singlePlayerProvider.notifier).endTurn();
            },
          ),
        ];
        break;
      case 'debate':
        buttons = [
          _SteampunkButton(
            label: '質詢',
            icon: Icons.search,
            accentColor: GameColors.btnChallenge,
            onPressed: () {
              HapticService.cardPlayed();
              _showTargetDialog(context, '選擇質詢目標', (targetId) {
                ref.read(singlePlayerProvider.notifier).challenge(targetId);
              });
            },
          ),
          _SteampunkButton(
            label: '抽牌',
            icon: Icons.style,
            accentColor: GameColors.btnDraw,
            onPressed: () {
              HapticService.cardPlayed();
              ref.read(audioServiceProvider).playSfx(SfxType.cardPlay);
              ref.read(singlePlayerProvider.notifier).drawCard();
            },
          ),
          _SteampunkButton(
            label: '下一階段',
            icon: Icons.flag,
            accentColor: GameColors.btnNextPhase,
            onPressed: () {
              HapticService.voteConfirmed();
              ref.read(singlePlayerProvider.notifier).endTurn();
            },
          ),
        ];
        break;
      case 'voting':
        buttons = [
          _SteampunkButton(
            label: '支持',
            icon: Icons.thumb_up,
            accentColor: GameColors.btnVoteFor,
            onPressed: () {
              HapticService.voteConfirmed();
              ref.read(audioServiceProvider).playSfx(SfxType.vote);
              ref.read(singlePlayerProvider.notifier).vote('a');
            },
          ),
          _SteampunkButton(
            label: '反對',
            icon: Icons.thumb_down,
            accentColor: GameColors.btnVoteAgainst,
            onPressed: () {
              HapticService.voteConfirmed();
              ref.read(audioServiceProvider).playSfx(SfxType.vote);
              ref.read(singlePlayerProvider.notifier).vote('b');
            },
          ),
          _SteampunkButton(
            label: '棄權',
            icon: Icons.remove,
            accentColor: GameColors.btnAbstain,
            onPressed: () {
              HapticService.voteConfirmed();
              ref.read(audioServiceProvider).playSfx(SfxType.vote);
              ref.read(singlePlayerProvider.notifier).vote('abstain');
            },
          ),
        ];
        break;
      default:
        buttons = [
          _SteampunkButton(
            label: '等待中',
            icon: Icons.hourglass_empty,
            accentColor: GameColors.btnWaiting,
            onPressed: null,
          ),
        ];
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: buttons.map((btn) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: btn,
        ),
      )).toList(),
    );
  }

  // ─── 目標選擇對話框 ───

  void _showTargetDialog(
      BuildContext context, String title, void Function(String) onSelect) {
    final state = ref.read(singlePlayerProvider);
    if (state == null) return;

    final targets = state.players
        .where((p) => p.isAi && !p.isPoliticallyDead)
        .toList();
    if (targets.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: targets.length,
            itemBuilder: (_, index) {
              final target = targets[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      AssetImage(_portraitPath(target.character)),
                  radius: 20,
                ),
                title: Text(_characterDisplayName(target.character)),
                subtitle: Text('聲望: ${target.reputation}  金幣: ${target.gold}'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  HapticService.cardPlayed();
                  onSelect(target.id);
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

  // ─── 卡牌操作 ───

  void _onCardTapped(GameCard card) {
    HapticService.cardPlayed();
    ref.read(audioServiceProvider).playSfx(SfxType.cardPlay);

    // 如果是攻擊 / 控制類型，需要選目標
    if (card.type == CardType.attack ||
        card.type == CardType.control ||
        card.type == CardType.social) {
      _showTargetDialog(context, '選擇目標', (targetId) {
        ref
            .read(singlePlayerProvider.notifier)
            .playCard(card.id, targetId: targetId);
      });
    } else {
      ref.read(singlePlayerProvider.notifier).playCard(card.id);
    }
  }

  void _onCardPlayed(GameCard card) {
    _onCardTapped(card);
  }

  // ─── 聊天面板（密謀階段私訊） ───

  Widget _buildChatOverlay(ThemeData theme) {
    return Positioned(
      right: 12,
      top: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isChatExpanded)
            Container(
              width: 280,
              height: 320,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 標題列
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.chat,
                            size: 16, color: theme.colorScheme.secondary),
                        const SizedBox(width: 6),
                        Text('密謀通訊',
                            style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.w600)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _isChatExpanded = false),
                          child: Icon(Icons.close,
                              size: 16, color: theme.colorScheme.onSurface),
                        ),
                      ],
                    ),
                  ),

                  // 訊息列表
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _chatMessages.length,
                      itemBuilder: (_, i) {
                        final msg = _chatMessages[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Column(
                            crossAxisAlignment: msg.isPlayer
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(msg.sender,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.secondary)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: msg.isPlayer
                                      ? theme.colorScheme.primary
                                          .withValues(alpha: 0.2)
                                      : theme.colorScheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(msg.text,
                                    style: theme.textTheme.bodySmall),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // 快捷訊息
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: _quickMessages.map((msg) {
                        return GestureDetector(
                          onTap: () => _sendChatMessage(msg),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: theme.colorScheme.secondary
                                      .withValues(alpha: 0.3)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(msg,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.secondary,
                                    fontSize: 10)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // 輸入框
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            style: theme.textTheme.bodySmall,
                            decoration: InputDecoration(
                              hintText: '輸入私訊...',
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                    color: theme.colorScheme.outline
                                        .withValues(alpha: 0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                    color: theme.colorScheme.outline
                                        .withValues(alpha: 0.3)),
                              ),
                              isDense: true,
                            ),
                            onSubmitted: _sendChatMessage,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () =>
                              _sendChatMessage(_chatController.text),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.send,
                                size: 14,
                                color: theme.colorScheme.onSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          FloatingActionButton(
            mini: true,
            heroTag: 'sp_chat',
            onPressed: () => setState(() => _isChatExpanded = !_isChatExpanded),
            backgroundColor: theme.colorScheme.secondary,
            child: Icon(
              _isChatExpanded ? Icons.close : Icons.chat,
              color: theme.colorScheme.onSecondary,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  void _sendChatMessage(String text) {
    if (text.trim().isEmpty) return;
    _chatController.clear();

    setState(() {
      _chatMessages.add(_ChatMsg(
        sender: '你',
        text: text.trim(),
        isPlayer: true,
      ));
    });

    // AI 自動回應（模擬）
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      final state = ref.read(singlePlayerProvider);
      if (state == null) return;

      final aiPlayers =
          state.players.where((p) => p.isAi && !p.isPoliticallyDead).toList();
      if (aiPlayers.isEmpty) return;

      final responder = aiPlayers[DateTime.now().millisecond % aiPlayers.length];

      String response;
      final lowerText = text.trim().toLowerCase();
      if (lowerText.contains('結盟') || lowerText.contains('盟')) {
        response = '讓我考慮一下...也許我們可以合作。';
      } else if (lowerText.contains('投') || lowerText.contains('票')) {
        response = '我會根據議案內容做出判斷。';
      } else {
        const responses = [
          '有意思...',
          '我會記住這件事的。',
          '我有我的計劃。',
          '你的提議很誘人。',
          '讓我們拭目以待。',
          '在議會中，沒有永遠的朋友。',
        ];
        response = responses[DateTime.now().second % responses.length];
      }

      setState(() {
        _chatMessages.add(_ChatMsg(
          sender: _characterDisplayName(responder.character),
          text: response,
          isPlayer: false,
        ));
      });
    });
  }

  // ─── 階段轉場動畫 ───

  void _triggerPhaseTransition(String phase) {
    if (!mounted) return;
    final config = ref.read(qualityConfigProvider);
    if (config.skipPhaseTransition) return;

    _phaseTransitionController.duration = config.phaseTransitionDuration;

    if (config.enableElasticCurves) {
      _phaseTransitionScale = Tween<double>(begin: 0.8, end: 1.2).animate(
        CurvedAnimation(
          parent: _phaseTransitionController,
          curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
        ),
      );
    } else {
      _phaseTransitionScale = Tween<double>(begin: 0.9, end: 1.1).animate(
        CurvedAnimation(
          parent: _phaseTransitionController,
          curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
        ),
      );
    }

    setState(() {
      _transitionPhase = phase;
      _isShowingPhaseTransition = true;
    });
    _phaseTransitionController.forward();
  }

  Widget _buildPhaseTransitionOverlay(ThemeData theme) {
    if (_transitionPhase == null) return const SizedBox.shrink();
    final info = _getPhaseTransitionInfo(_transitionPhase!);

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
                colors: info.colors,
              ),
            ),
            child: Center(
              child: Transform.scale(
                scale: _phaseTransitionScale.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child:
                          Icon(info.icon, size: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      info.title,
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
                    ),
                    const SizedBox(height: 12),
                    Text(
                      info.subtitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
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

  _PhaseInfo _getPhaseTransitionInfo(String phase) {
    switch (phase) {
      case 'player_turn':
        return _PhaseInfo(
          title: '行動階段',
          subtitle: '輪到你了！策劃行動',
          icon: Icons.play_circle_outline,
          colors: [
            const Color(0xFF2E7D32).withValues(alpha: 0.9),
            const Color(0xFF43A047).withValues(alpha: 0.9),
          ],
        );
      case 'ai_turn':
        return _PhaseInfo(
          title: 'AI 回合',
          subtitle: '其他議員正在行動...',
          icon: Icons.smart_toy,
          colors: [
            const Color(0xFF5C4A1E).withValues(alpha: 0.9),
            const Color(0xFFD4A843).withValues(alpha: 0.9),
          ],
        );
      case 'conspiracy':
        return _PhaseInfo(
          title: '密謀階段',
          subtitle: '策劃你的行動',
          icon: Icons.visibility_off,
          colors: [
            const Color(0xFF2C3E50).withValues(alpha: 0.9),
            const Color(0xFF34495E).withValues(alpha: 0.9),
          ],
        );
      case 'debate':
        return _PhaseInfo(
          title: '辯論階段',
          subtitle: '展開激烈的政治攻防',
          icon: Icons.campaign,
          colors: [
            const Color(0xFF8B0000).withValues(alpha: 0.9),
            const Color(0xFFDC143C).withValues(alpha: 0.9),
          ],
        );
      case 'voting':
        return _PhaseInfo(
          title: '投票階段',
          subtitle: '決定議案的命運',
          icon: Icons.how_to_vote,
          colors: [
            const Color(0xFFD4AF37).withValues(alpha: 0.9),
            const Color(0xFFFFD700).withValues(alpha: 0.9),
          ],
        );
      default:
        return _PhaseInfo(
          title: '結算中...',
          subtitle: '統計投票結果',
          icon: Icons.analytics,
          colors: [
            const Color(0xFF4A90E2).withValues(alpha: 0.9),
            const Color(0xFF7B68EE).withValues(alpha: 0.9),
          ],
        );
    }
  }

  // ─── 引導氣泡 ───

  void _showPhaseGuide(String phase) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final key = 'sp_guide_$phase';
    final seen = prefs.getBool(key) ?? false;
    if (seen) return;

    final msg = _phaseGuideMessages[phase];
    if (msg == null) return;

    setState(() {
      _showGuide = true;
      _guideText = msg;
    });
    await prefs.setBool(key, true);
  }

  Widget _buildGuideOverlay(ThemeData theme) {
    return Positioned(
      top: 100,
      left: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Parliament1812Theme.charcoal,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Parliament1812Theme.gold.withValues(alpha: 0.5),
                width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb,
                  color: Parliament1812Theme.gold, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _guideText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Parliament1812Theme.cream,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _dismissGuide,
                child: Icon(Icons.close,
                    color: Parliament1812Theme.cream.withValues(alpha: 0.7),
                    size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 設定對話框 ───

  void _showGameSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('遊戲設定'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('遊戲規則'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('離開遊戲'),
              onTap: () {
                Navigator.of(ctx).pop();
                _showQuitDialog(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  void _showQuitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('離開對戰？'),
        content: const Text('確定要離開嗎？目前的進度將會遺失。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(singlePlayerProvider.notifier).clearGame();
              context.go('/menu');
            },
            child: const Text('離開'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// P0-2: 蒸汽朋克按鈕 Widget
// ═══════════════════════════════════════════

class _SteampunkButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onPressed;

  const _SteampunkButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    this.onPressed,
  });

  @override
  State<_SteampunkButton> createState() => _SteampunkButtonState();
}

class _SteampunkButtonState extends State<_SteampunkButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;

    return GestureDetector(
      onTapDown: enabled ? (_) {
        setState(() => _isPressed = true);
        _pressController.forward();
      } : null,
      onTapUp: enabled ? (_) {
        setState(() => _isPressed = false);
        _pressController.reverse();
        widget.onPressed?.call();
      } : null,
      onTapCancel: enabled ? () {
        setState(() => _isPressed = false);
        _pressController.reverse();
      } : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: enabled ? 1.0 : 0.4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                decoration: BoxDecoration(
                  color: widget.accentColor,
                  borderRadius: BorderRadius.circular(GameSpacing.buttonRadius),
                  boxShadow: _isPressed
                      ? []
                      : const [
                          BoxShadow(
                            offset: Offset(0, 2),
                            blurRadius: 8,
                            color: Color(0x66000000),
                          ),
                        ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, size: 16, color: gc.GameColors.textPrimary),
                    const SizedBox(height: 2),
                    Text(
                      widget.label,
                      style: GameFont.uiLabel.copyWith(
                        color: gc.GameColors.textPrimary,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════
// P0-1: 玩家卡片 Widget（羅塞蒂 v2 三欄設計 + 呼吸光暈 + 飛字）
// ═══════════════════════════════════════════

class _PlayerCard extends ConsumerWidget {
  final SinglePlayerInfo player;
  final Animation<double> glowAnimation;
  final bool isAiTurnActor;
  final bool isCurrentTurn;
  final _FlyTextData? flyText;

  const _PlayerCard({
    required this.player,
    required this.glowAnimation,
    this.isAiTurnActor = false,
    this.isCurrentTurn = false,
    this.flyText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDead = player.isPoliticallyDead;
    final isHuman = !player.isAi;
    final isActiveTurn = isCurrentTurn || (isHuman && !isAiTurnActor);
    final faction = _characterFaction(player.character);
    final factionColor = gc.GameColors.getFactionColor(faction);
    final reputationPct = (player.reputation / 100).clamp(0.0, 1.0);

    // 影響力進度條顏色
    Color barColor;
    if (reputationPct > 0.6) {
      barColor = const Color(0xFF27AE60);
    } else if (reputationPct > 0.3) {
      barColor = const Color(0xFFFFB74D);
    } else {
      barColor = const Color(0xFFE74C3C);
    }

    // 派系頭像背景色
    Color avatarBg;
    switch (faction) {
      case 'labor':
        avatarBg = const Color(0xFF3D7CC9);
        break;
      case 'capital':
        avatarBg = const Color(0xFFC0392B);
        break;
      case 'reform':
        avatarBg = const Color(0xFF6B3FA0);
        break;
      default:
        avatarBg = const Color(0xFFC9A84C);
    }

    final shouldGlow = isActiveTurn || isAiTurnActor;

    Widget card = Container(
      padding: const EdgeInsets.all(GameSpacing.cardPadding),
      decoration: BoxDecoration(
        color: isDead
            ? gc.GameColors.bgCard.withValues(alpha: 0.5)
            : gc.GameColors.bgCard,
        borderRadius: GameSpacing.cardBorderRadius,
        border: Border.all(
          color: isActiveTurn
              ? gc.GameColors.victorianGold
              : isAiTurnActor
                  ? gc.GameColors.victorianGold
                  : Colors.transparent,
          width: (isActiveTurn || isAiTurnActor) ? 1.5 : 0,
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
      child: Opacity(
        opacity: isDead ? 0.4 : 1.0,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 「行動中」badge
                if (isActiveTurn)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
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
                // 圓形字母頭像（置中）
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: avatarBg,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _characterDisplayName(player.character)
                        .substring(0, 1),
                    style: GameFont.factionBadge.copyWith(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // 姓名（置中）
                Text(
                  _characterDisplayName(player.character),
                  style: GameFont.playerName.copyWith(
                    color: gc.GameColors.textPrimary,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 3),
                // 黨派 badge（水平 Row：● + WHIG）
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: factionColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      gc.GameColors.getFactionLabel(faction)
                          .toUpperCase(),
                      style: GameFont.factionBadge.copyWith(
                        color: factionColor,
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
                      '${player.handCount}',
                      style: GameFont.factionBadge.copyWith(
                        color: gc.GameColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                // 政治死亡標記
                if (isDead)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('💀 政治死亡',
                        style: TextStyle(
                            color: Colors.red.shade300, fontSize: 9)),
                  ),
              ],
            ),

            // P0-3: 飛字效果
            if (flyText != null && !flyText!.isExpired)
              Positioned(
                top: -10,
                right: 0,
                child: _FlyTextWidget(data: flyText!),
              ),
          ],
        ),
      ),
    );

    // 呼吸光暈
    if (shouldGlow && !isDead) {
      return AnimatedBuilder(
        animation: glowAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: GameSpacing.cardBorderRadius,
              boxShadow: [
                BoxShadow(
                  color: gc.GameColors.victorianGold
                      .withValues(alpha: glowAnimation.value),
                  blurRadius: GameColors.selectionGlowBlur,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: card,
          );
        },
      );
    }

    return card;
  }
}

// ═══════════════════════════════════════════
// P0-3: 飛字 Widget
// ═══════════════════════════════════════════

class _FlyTextData {
  final int delta;
  final DateTime timestamp;

  const _FlyTextData({required this.delta, required this.timestamp});

  bool get isExpired =>
      DateTime.now().difference(timestamp).inMilliseconds > 800;
}

class _FlyTextWidget extends StatefulWidget {
  final _FlyTextData data;

  const _FlyTextWidget({required this.data});

  @override
  State<_FlyTextWidget> createState() => _FlyTextWidgetState();
}

class _FlyTextWidgetState extends State<_FlyTextWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _offsetY;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    final isPositive = widget.data.delta > 0;
    final isBig = widget.data.delta.abs() >= 5;

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 40),
    ]).animate(_controller);

    _offsetY = Tween<double>(
      begin: 0,
      end: isPositive ? -30 : 20,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // icon 微震效果
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: isBig ? 1.5 : 1.3), weight: 30),
      TweenSequenceItem(tween: Tween(begin: isBig ? 1.5 : 1.3, end: 1.0), weight: 70),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.33),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = widget.data.delta > 0;
    final isBig = widget.data.delta.abs() >= 5;
    final text = isPositive
        ? '+${widget.data.delta}${isBig ? '!' : ''}'
        : '${widget.data.delta}${isBig ? '!' : ''}';
    final color = isPositive ? GameColors.flyTextPositive : GameColors.flyTextNegative;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _offsetY.value),
          child: Opacity(
            opacity: _opacity.value,
            child: Transform.scale(
              scale: _scale.value,
              child: Text(
                text,
                style: TextStyle(
                  fontSize: isBig ? 18 : 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 1),
                      blurRadius: 3,
                      color: Colors.black.withValues(alpha: 0.5),
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
}

// ═══════════════════════════════════════════
// P0-4: 事件日誌條目 Widget（含 fadeIn + slideUp）
// ═══════════════════════════════════════════

class _EventLogEntry extends StatefulWidget {
  final String log;
  final _EventInfo eventInfo;
  final bool isNew;
  final bool isImportant;

  const _EventLogEntry({
    required this.log,
    required this.eventInfo,
    required this.isNew,
    required this.isImportant,
  });

  @override
  State<_EventLogEntry> createState() => _EventLogEntryState();
}

class _EventLogEntryState extends State<_EventLogEntry>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _opacity = Tween<double>(begin: widget.isNew ? 0.0 : 1.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _slide = Tween<Offset>(
      begin: widget.isNew ? const Offset(0, 0.3) : Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.isNew) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: widget.isImportant
              ? const EdgeInsets.only(left: 6)
              : EdgeInsets.zero,
          decoration: widget.isImportant
              ? BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: GameColors.gold,
                      width: 3,
                    ),
                  ),
                )
              : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(widget.eventInfo.icon, size: 14, color: widget.eventInfo.color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.log,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: widget.eventInfo.color,
                    fontWeight: widget.isImportant ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                    height: 1.6,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 遊戲結束畫面
// ═══════════════════════════════════════════

class _GameOverView extends ConsumerWidget {
  final SinglePlayerResult result;

  const _GameOverView({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 勝負圖標
              Icon(
                result.won ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                size: 80,
                color: result.won ? Parliament1812Theme.gold : Colors.grey,
              ),
              const SizedBox(height: 24),
              Text(
                result.won ? '🎉 勝利！' : '😔 落敗',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: result.won ? Parliament1812Theme.gold : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '排名 #${result.rank}　得分 ${result.score}',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // 排名列表
              ...result.rankings.asMap().entries.map((entry) {
                final index = entry.key;
                final p = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: index == 0
                        ? Parliament1812Theme.gold.withValues(alpha: 0.1)
                        : theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: index == 0
                        ? Border.all(
                            color: Parliament1812Theme.gold
                                .withValues(alpha: 0.3))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Text(
                        '#${index + 1}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: index == 0
                              ? Parliament1812Theme.gold
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          p.name,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight:
                                !p.isAi ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      Text(
                        '${p.score}分',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 32),
              FilledButton(
                onPressed: () {
                  ref.read(singlePlayerProvider.notifier).clearGame();
                  context.go('/single-player/difficulty');
                },
                child: const Text('再來一局'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  ref.read(singlePlayerProvider.notifier).clearGame();
                  context.go('/menu');
                },
                child: const Text('返回主選單'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Helper 資料類
// ═══════════════════════════════════════════

class _PhaseInfo {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;

  const _PhaseInfo({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
  });
}

class _ChatMsg {
  final String sender;
  final String text;
  final bool isPlayer;

  const _ChatMsg({
    required this.sender,
    required this.text,
    required this.isPlayer,
  });
}

class _EventInfo {
  final IconData icon;
  final Color color;
  final String emoji;

  const _EventInfo({
    required this.icon,
    required this.color,
    required this.emoji,
  });
}
