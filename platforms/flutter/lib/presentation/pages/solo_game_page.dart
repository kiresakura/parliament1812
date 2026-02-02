// 1812 國會風雲 - 單人模式遊戲頁面
//
// 主遊戲畫面，顯示所有遊戲狀態和操作介面

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/game_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/models.dart';
import '../../providers/solo_game_provider.dart';

// ============================================================
// 主頁面
// ============================================================

/// 單人模式遊戲頁面
class SoloGamePage extends ConsumerStatefulWidget {
  const SoloGamePage({super.key});

  @override
  ConsumerState<SoloGamePage> createState() => _SoloGamePageState();
}

class _SoloGamePageState extends ConsumerState<SoloGamePage>
    with TickerProviderStateMixin {
  /// 當前選中的攻擊目標
  String? _selectedTargetId;

  /// 是否顯示遊戲日誌
  bool _showGameLog = false;

  /// AI 對話動畫控制器
  late AnimationController _dialogueAnimationController;

  /// 當前 AI 對話
  String? _currentAIDialogue;
  String? _currentAISpeakerId;

  @override
  void initState() {
    super.initState();
    _dialogueAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _dialogueAnimationController.dispose();
    super.dispose();
  }

  /// 顯示 AI 對話氣泡
  void _showAIDialogue(String aiId, String dialogue) {
    setState(() {
      _currentAISpeakerId = aiId;
      _currentAIDialogue = dialogue;
    });
    _dialogueAnimationController.forward();

    // 3 秒後隱藏
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _currentAISpeakerId == aiId) {
        _dialogueAnimationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _currentAIDialogue = null;
              _currentAISpeakerId = null;
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(soloGameProvider);

    // 監聽遊戲事件來顯示 AI 對話
    ref.listen<SoloGameState>(soloGameProvider, (previous, current) {
      if (previous != null && current.gameLog.length > previous.gameLog.length) {
        final newEvent = current.gameLog.last;
        if (newEvent.type == GameEventType.aiAction && newEvent.playerId != null) {
          _showAIDialogue(newEvent.playerId!, _getDialogueForEvent(newEvent));
        }
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Stack(
          children: [
            // 主要遊戲內容
            Column(
              children: [
                // 1. 頂部區域
                _buildTopBar(gameState),

                // 2. AI 玩家區域
                Expanded(
                  flex: 3,
                  child: _buildAIPlayersArea(gameState),
                ),

                // 3. 中央事件區域
                Expanded(
                  flex: 2,
                  child: _buildEventArea(gameState),
                ),

                // 4. 玩家資訊區
                _buildPlayerInfoArea(gameState),

                // 5. 行動按鈕區
                _buildActionButtons(gameState),
              ],
            ),

            // 遊戲日誌面板
            if (_showGameLog) _buildGameLogPanel(gameState),

            // 暫停覆蓋層
            if (gameState.isPaused) _buildPauseOverlay(),

            // 遊戲結束覆蓋層
            if (gameState.isGameOver) _buildGameOverOverlay(gameState),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 頂部區域
  // ============================================================

  Widget _buildTopBar(SoloGameState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryMid,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.accent.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 返回/暫停按鈕
          IconButton(
            onPressed: () => _showPauseMenu(context),
            icon: const Icon(Icons.menu, color: AppTheme.accent),
          ),

          const SizedBox(width: 8),

          // 階段指示器
          _PhaseIndicator(
            currentPhase: state.currentPhase,
            currentRound: state.currentRound,
            totalRounds: state.totalRounds,
            debateRound: state.debateRound,
            maxDebateRounds: state.maxDebateRounds,
          ),

          const Spacer(),

          // 回合指示（辯論階段）
          if (state.currentPhase == GamePhase.debate)
            _TurnIndicator(
              isHumanTurn: state.isHumanTurn,
              currentActorName: state.currentActor?.name ?? '',
              turnTime: state.turnTimeRemaining,
            )
          else
            // 倒計時（其他階段）
            _TimerDisplay(
              timeRemaining: state.phaseTimeRemaining,
              isWarning: state.phaseTimeRemaining <= 10,
            ),

          const SizedBox(width: 12),

          // 遊戲日誌按鈕
          IconButton(
            onPressed: () => setState(() => _showGameLog = !_showGameLog),
            icon: Badge(
              isLabelVisible: state.gameLog.isNotEmpty,
              label: Text(
                '${state.gameLog.length}',
                style: const TextStyle(fontSize: 10),
              ),
              child: Icon(
                _showGameLog ? Icons.close : Icons.history,
                color: AppTheme.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AI 玩家區域
  // ============================================================

  Widget _buildAIPlayersArea(SoloGameState state) {
    final aiPlayers = state.aiPlayers;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: aiPlayers.map((ai) {
          final isCurrentSpeaker = state.currentSpeakerId == ai.id;
          final isTarget = _selectedTargetId == ai.id;
          final isShowingDialogue = _currentAISpeakerId == ai.id;

          return Expanded(
            child: _AIPlayerCard(
              aiPlayer: ai,
              isActive: isCurrentSpeaker,
              isSelected: isTarget,
              dialogue: isShowingDialogue ? _currentAIDialogue : null,
              dialogueAnimation: _dialogueAnimationController,
              onTap: state.currentPhase == GamePhase.debate
                  ? () => setState(() {
                        _selectedTargetId =
                            _selectedTargetId == ai.id ? null : ai.id;
                      })
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // 中央事件區域
  // ============================================================

  Widget _buildEventArea(SoloGameState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryMid.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accent.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // 議案標題
          if (state.currentBill != null) ...[
            Text(
              state.currentBill!.title,
              style: const TextStyle(
                color: AppTheme.accent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // 最新事件
          Expanded(
            child: _buildLatestEvents(state),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestEvents(SoloGameState state) {
    final recentEvents = state.gameLog.reversed.take(3).toList();

    if (recentEvents.isEmpty) {
      return const Center(
        child: Text(
          '遊戲進行中...',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return ListView.builder(
      reverse: true,
      itemCount: recentEvents.length,
      itemBuilder: (context, index) {
        final event = recentEvents[index];
        return _EventMessage(event: event);
      },
    );
  }

  // ============================================================
  // 玩家資訊區
  // ============================================================

  Widget _buildPlayerInfoArea(SoloGameState state) {
    final player = state.humanPlayer;
    if (player == null) return const SizedBox.shrink();

    final role = RoleDatabase.getRoleById(player.roleId ?? '');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryMid,
        border: Border(
          top: BorderSide(
            color: AppTheme.accent.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 頭像與名稱
          Column(
            children: [
              _PlayerAvatar(
                emoji: role?.emoji ?? '🎭',
                isAlive: player.isAlive,
              ),
              const SizedBox(height: 4),
              Text(
                player.name,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          // 聲望條
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '聲望',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${player.reputation}',
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _ReputationBar(
                  current: player.reputation,
                  max: 100,
                  height: 16,
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // 資源顯示
          _ResourceDisplay(
            gold: player.gold,
            intel: player.intel,
          ),

          const SizedBox(width: 12),

          // 技能按鈕
          if (role != null && role.skills.isNotEmpty)
            _SkillButton(
              skill: role.skills.first,
              onPressed: () => _useSkill(role.skills.first),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // 行動按鈕區
  // ============================================================

  Widget _buildActionButtons(SoloGameState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryDark,
      child: _buildPhaseButtons(state),
    );
  }

  Widget _buildPhaseButtons(SoloGameState state) {
    switch (state.currentPhase) {
      case GamePhase.conspiracy:
        return _buildConspiracyButtons(state);
      case GamePhase.debate:
        return _buildDebateButtons(state);
      case GamePhase.voting:
        return _buildVotingButtons(state);
      default:
        return _buildWaitingButtons(state);
    }
  }

  /// 密謀階段按鈕
  Widget _buildConspiracyButtons(SoloGameState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButton(
          icon: Icons.mail_outline,
          label: '私訊',
          onPressed: () => _showMessageDialog(),
        ),
        _ActionButton(
          icon: Icons.handshake,
          label: '結盟',
          onPressed: () => _showAllianceDialog(state),
        ),
        _ActionButton(
          icon: Icons.skip_next,
          label: '結束階段',
          isPrimary: true,
          onPressed: () => ref.read(soloGameProvider.notifier).advancePhase(),
        ),
      ],
    );
  }

  /// 辯論階段按鈕
  Widget _buildDebateButtons(SoloGameState state) {
    final isHumanTurn = state.isHumanTurn;
    final canQuery = isHumanTurn &&
        state.humanPlayer != null &&
        state.humanPlayer!.reputation >= GameConstants.queryCost;
    final canRebut = isHumanTurn &&
        state.humanPlayer != null &&
        state.humanPlayer!.reputation >= GameConstants.rebutCost;

    // 如果不是玩家回合，顯示等待提示
    if (!isHumanTurn) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${state.currentActor?.name ?? "對手"} 正在行動...',
              style: const TextStyle(
                color: AppTheme.accent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
              ),
            ),
          ],
        ),
      );
    }

    // 玩家回合顯示行動按鈕
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 回合提示
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.accent),
          ),
          child: Text(
            '輪到你行動！(${state.turnTimeRemaining}秒)',
            style: const TextStyle(
              color: AppTheme.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // 行動按鈕
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ActionButton(
              icon: Icons.gavel,
              label: '質詢',
              subtitle: _selectedTargetId != null ? '攻擊目標' : '選擇目標',
              isEnabled: canQuery && _selectedTargetId != null,
              onPressed: () => _executeQuery(state),
            ),
            _ActionButton(
              icon: Icons.shield,
              label: '反駁',
              subtitle: '-${GameConstants.rebutCost} 聲望',
              isEnabled: canRebut,
              onPressed: () => _executeRebut(),
            ),
            _ActionButton(
              icon: Icons.auto_awesome,
              label: '技能',
              isEnabled: isHumanTurn,
              onPressed: () => _showSkillPanel(state),
            ),
            _ActionButton(
              icon: Icons.skip_next,
              label: '跳過',
              onPressed: () => ref.read(soloGameProvider.notifier).skipTurn(),
            ),
          ],
        ),
      ],
    );
  }

  /// 投票階段按鈕
  Widget _buildVotingButtons(SoloGameState state) {
    final bill = state.currentBill;
    if (bill == null) return const SizedBox.shrink();

    final hasVoted = state.votes.containsKey(state.humanPlayer?.id);

    if (hasVoted) {
      return const Center(
        child: Text(
          '已投票，等待其他玩家...',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '選擇你的立場',
          style: TextStyle(
            color: AppTheme.accent,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _VoteOptionButton(
              option: bill.optionA,
              onPressed: () => _submitVote('A'),
            ),
            _VoteOptionButton(
              option: bill.optionB,
              onPressed: () => _submitVote('B'),
            ),
            _VoteOptionButton(
              option: bill.optionC,
              onPressed: () => _submitVote('C'),
            ),
          ],
        ),
      ],
    );
  }

  /// 等待階段按鈕
  Widget _buildWaitingButtons(SoloGameState state) {
    if (state.currentPhase == GamePhase.preparing) {
      return Center(
        child: ElevatedButton.icon(
          onPressed: () => ref.read(soloGameProvider.notifier).advancePhase(),
          icon: const Icon(Icons.play_arrow),
          label: const Text('開始遊戲'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accent,
            foregroundColor: AppTheme.primaryDark,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
      );
    }

    return const Center(
      child: Text(
        '請稍候...',
        style: TextStyle(color: AppTheme.textSecondary),
      ),
    );
  }

  // ============================================================
  // 遊戲日誌面板
  // ============================================================

  Widget _buildGameLogPanel(SoloGameState state) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _showGameLog = false),
        child: Container(
          color: Colors.black54,
          child: Center(
            child: GestureDetector(
              onTap: () {}, // 阻止點擊穿透
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.6,
                decoration: BoxDecoration(
                  color: AppTheme.primaryMid,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.accent, width: 2),
                ),
                child: Column(
                  children: [
                    // 標題
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryDark,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(14),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.history, color: AppTheme.accent),
                          const SizedBox(width: 8),
                          const Text(
                            '遊戲日誌',
                            style: TextStyle(
                              color: AppTheme.accent,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () =>
                                setState(() => _showGameLog = false),
                            icon:
                                const Icon(Icons.close, color: AppTheme.accent),
                          ),
                        ],
                      ),
                    ),

                    // 日誌列表
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.gameLog.length,
                        itemBuilder: (context, index) {
                          final event =
                              state.gameLog[state.gameLog.length - 1 - index];
                          return _GameLogItem(event: event);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 暫停覆蓋層
  // ============================================================

  Widget _buildPauseOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black87,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.pause_circle_outline,
                color: AppTheme.accent,
                size: 80,
              ),
              const SizedBox(height: 16),
              const Text(
                '遊戲暫停',
                style: TextStyle(
                  color: AppTheme.accent,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(soloGameProvider.notifier).togglePause(),
                icon: const Icon(Icons.play_arrow),
                label: const Text('繼續遊戲'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: AppTheme.primaryDark,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 遊戲結束覆蓋層
  // ============================================================

  Widget _buildGameOverOverlay(SoloGameState state) {
    final isWinner =
        state.winner == state.humanPlayer?.name;

    return Positioned.fill(
      child: Container(
        color: Colors.black87,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isWinner ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                color: isWinner ? AppTheme.accent : AppTheme.textSecondary,
                size: 80,
              ),
              const SizedBox(height: 16),
              Text(
                isWinner ? '勝利！' : '失敗',
                style: TextStyle(
                  color: isWinner ? AppTheme.accent : AppTheme.danger,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.winner != null ? '${state.winner} 獲勝' : '遊戲結束',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(soloGameProvider.notifier).resetGame();
                      context.go('/solo');
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('返回主頁'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accent,
                      side: const BorderSide(color: AppTheme.accent),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/solo/result'),
                    icon: const Icon(Icons.bar_chart),
                    label: const Text('查看結算'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: AppTheme.primaryDark,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 對話框和動作方法
  // ============================================================

  void _showPauseMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.primaryMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.pause, color: AppTheme.accent),
              title: const Text('暫停遊戲',
                  style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                ref.read(soloGameProvider.notifier).togglePause();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: AppTheme.accent),
              title:
                  const Text('設定', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                // 設定功能將在後續版本實作
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('設定功能即將推出')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: AppTheme.danger),
              title:
                  const Text('離開遊戲', style: TextStyle(color: AppTheme.danger)),
              onTap: () {
                Navigator.pop(context);
                _showExitConfirmation(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showExitConfirmation(BuildContext dialogContext) {
    showDialog(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.primaryMid,
        title: const Text('離開遊戲？',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('離開將結束當前遊戲，確定要離開嗎？',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(soloGameProvider.notifier).resetGame();
              context.go('/solo');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
            ),
            child: const Text('離開'),
          ),
        ],
      ),
    );
  }

  void _showMessageDialog() {
    // 單人模式中私訊功能簡化為提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('單人模式暫不支援私訊')),
    );
  }

  void _showAllianceDialog(SoloGameState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryMid,
        title: const Text('選擇結盟對象',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: state.aiPlayers.where((ai) => ai.isAlive).map((ai) {
            final isAlly =
                state.humanPlayer?.allies.contains(ai.id) ?? false;
            return ListTile(
              leading: Text(
                RoleDatabase.getRoleById(ai.roleId ?? '')?.emoji ?? '🎭',
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(ai.displayName,
                  style: const TextStyle(color: AppTheme.textPrimary)),
              trailing: isAlly
                  ? const Icon(Icons.check_circle, color: AppTheme.success)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _proposeAlliance(ai.id);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _proposeAlliance(String targetId) {
    final action = AllyAction(
      id: 'ally_human_${DateTime.now().millisecondsSinceEpoch}',
      actorId: ref.read(soloGameProvider).humanPlayer?.id ?? '',
      targetId: targetId,
      timestamp: DateTime.now(),
    );
    ref.read(soloGameProvider.notifier).executeHumanAction(action);
  }

  void _executeQuery(SoloGameState state) {
    if (_selectedTargetId == null) return;

    final action = QueryAction(
      id: 'query_human_${DateTime.now().millisecondsSinceEpoch}',
      actorId: state.humanPlayer?.id ?? '',
      targetId: _selectedTargetId,
      timestamp: DateTime.now(),
      damage: GameConstants.queryBaseDamage,
      actualDamage: GameConstants.queryBaseDamage,
      reputationCost: GameConstants.queryCost,
    );

    ref.read(soloGameProvider.notifier).executeHumanAction(action);

    setState(() {
      _selectedTargetId = null;
    });
  }

  void _executeRebut() {
    final action = RebutAction(
      id: 'rebut_human_${DateTime.now().millisecondsSinceEpoch}',
      actorId: ref.read(soloGameProvider).humanPlayer?.id ?? '',
      timestamp: DateTime.now(),
      damageReduced: GameConstants.rebutBlock,
      reputationCost: GameConstants.rebutCost,
    );

    ref.read(soloGameProvider.notifier).executeHumanAction(action);
  }

  void _useSkill(Skill skill, {String? targetId}) {
    final gameState = ref.read(soloGameProvider);
    final humanPlayer = gameState.humanPlayer;
    if (humanPlayer == null) return;

    // 檢查是否輪到人類玩家
    if (gameState.currentPhase == GamePhase.debate && !gameState.isHumanTurn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('現在不是你的回合'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    // 檢查是否被動技能
    if (skill.type == SkillType.passive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('「${skill.name}」是被動技能，自動生效'),
          backgroundColor: AppTheme.primaryMid,
        ),
      );
      return;
    }

    // 檢查資源是否足夠
    if (humanPlayer.reputation < skill.reputationCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('聲望不足，無法使用技能'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }
    if (humanPlayer.gold < skill.goldCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('金幣不足，無法使用技能'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }
    if (humanPlayer.intel < skill.intelCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('情報不足，無法使用技能'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    // 需要選擇目標的技能
    final needsTarget = skill.id == 'factory_bribe' ||
        skill.id == 'reporter_expose' ||
        skill.id == 'luddite_rage';

    if (needsTarget && targetId == null && _selectedTargetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('請先選擇一個目標'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    final actualTargetId = targetId ?? _selectedTargetId;

    // 創建並執行技能動作
    final action = SkillAction(
      id: 'skill_human_${DateTime.now().millisecondsSinceEpoch}',
      actorId: humanPlayer.id,
      targetId: actualTargetId,
      timestamp: DateTime.now(),
      skillId: skill.id,
      skillName: skill.name,
      effectDescription: skill.description,
    );

    ref.read(soloGameProvider.notifier).executeHumanAction(action);

    setState(() {
      _selectedTargetId = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('使用了「${skill.name}」'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  void _showSkillPanel(SoloGameState state) {
    final player = state.humanPlayer;
    if (player == null) return;

    final role = RoleDatabase.getRoleById(player.roleId ?? '');
    if (role == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.primaryMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '角色技能',
              style: TextStyle(
                color: AppTheme.accent,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...role.skills.map((skill) => ListTile(
                  leading: Icon(
                    skill.type == SkillType.active
                        ? Icons.flash_on
                        : Icons.auto_awesome,
                    color: skill.type == SkillType.active
                        ? AppTheme.accent
                        : AppTheme.textSecondary,
                  ),
                  title: Text(
                    skill.name,
                    style: const TextStyle(color: AppTheme.textPrimary),
                  ),
                  subtitle: Text(
                    skill.description,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  trailing: skill.type == SkillType.active
                      ? ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _useSkill(skill);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            foregroundColor: AppTheme.primaryDark,
                          ),
                          child: const Text('使用'),
                        )
                      : const Text(
                          '被動',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                )),
          ],
        ),
      ),
    );
  }

  void _submitVote(String option) {
    ref.read(soloGameProvider.notifier).submitVote(option);
  }

  String _getDialogueForEvent(GameEvent event) {
    // 根據事件類型生成對話
    switch (event.type) {
      case GameEventType.aiAction:
        return event.message.contains('質詢')
            ? '看招！'
            : event.message.contains('反駁')
                ? '此言差矣！'
                : '......';
      case GameEventType.voteSubmitted:
        return '我已做出選擇';
      default:
        return '......';
    }
  }
}

// ============================================================
// 子元件
// ============================================================

/// 階段指示器
class _PhaseIndicator extends StatelessWidget {
  final GamePhase currentPhase;
  final int currentRound;
  final int totalRounds;
  final int debateRound;
  final int maxDebateRounds;

  const _PhaseIndicator({
    required this.currentPhase,
    required this.currentRound,
    required this.totalRounds,
    this.debateRound = 0,
    this.maxDebateRounds = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accent, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getPhaseIcon(),
            color: AppTheme.accent,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            _getPhaseName(),
            style: const TextStyle(
              color: AppTheme.accent,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          // 辯論階段顯示辯論回合
          if (currentPhase == GamePhase.debate && debateRound > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '回合 $debateRound/$maxDebateRounds',
                style: const TextStyle(
                  color: AppTheme.primaryDark,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'R$currentRound/$totalRounds',
                style: const TextStyle(
                  color: AppTheme.primaryDark,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getPhaseIcon() {
    switch (currentPhase) {
      case GamePhase.conspiracy:
        return Icons.visibility_off;
      case GamePhase.debate:
        return Icons.forum;
      case GamePhase.voting:
        return Icons.how_to_vote;
      default:
        return Icons.hourglass_empty;
    }
  }

  String _getPhaseName() {
    switch (currentPhase) {
      case GamePhase.preparing:
        return '準備';
      case GamePhase.conspiracy:
        return '密謀';
      case GamePhase.debate:
        return '辯論';
      case GamePhase.voting:
        return '投票';
      case GamePhase.result:
        return '結算';
      default:
        return '等待';
    }
  }
}

/// 計時器顯示
class _TimerDisplay extends StatelessWidget {
  final int timeRemaining;
  final bool isWarning;

  const _TimerDisplay({
    required this.timeRemaining,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = timeRemaining ~/ 60;
    final seconds = timeRemaining % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isWarning
            ? AppTheme.danger.withValues(alpha: 0.2)
            : AppTheme.primaryMid,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWarning ? AppTheme.danger : AppTheme.accent.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: isWarning ? AppTheme.danger : AppTheme.accent,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: isWarning ? AppTheme.danger : AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

/// 回合指示器（辯論階段）
class _TurnIndicator extends StatelessWidget {
  final bool isHumanTurn;
  final String currentActorName;
  final int turnTime;

  const _TurnIndicator({
    required this.isHumanTurn,
    required this.currentActorName,
    required this.turnTime,
  });

  @override
  Widget build(BuildContext context) {
    final isWarning = turnTime <= 10;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isHumanTurn
            ? AppTheme.accent.withValues(alpha: 0.2)
            : AppTheme.primaryMid,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHumanTurn
              ? AppTheme.accent
              : isWarning
                  ? AppTheme.danger
                  : AppTheme.accent.withValues(alpha: 0.5),
          width: isHumanTurn ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 回合圖示
          Icon(
            isHumanTurn ? Icons.person : Icons.smart_toy,
            color: isHumanTurn ? AppTheme.accent : AppTheme.textSecondary,
            size: 16,
          ),
          const SizedBox(width: 6),
          // 當前行動者
          Text(
            isHumanTurn ? '你的回合' : currentActorName,
            style: TextStyle(
              color: isHumanTurn ? AppTheme.accent : AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          // 倒計時
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isWarning ? AppTheme.danger : AppTheme.accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${turnTime}s',
              style: const TextStyle(
                color: AppTheme.primaryDark,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// AI 玩家卡片
class _AIPlayerCard extends StatelessWidget {
  final AIPlayer aiPlayer;
  final bool isActive;
  final bool isSelected;
  final String? dialogue;
  final AnimationController dialogueAnimation;
  final VoidCallback? onTap;

  const _AIPlayerCard({
    required this.aiPlayer,
    required this.dialogueAnimation,
    this.isActive = false,
    this.isSelected = false,
    this.dialogue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final role = RoleDatabase.getRoleById(aiPlayer.roleId ?? '');

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 卡片主體
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.accent.withValues(alpha: 0.2)
                  : AppTheme.primaryMid,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? AppTheme.accent
                    : isSelected
                        ? AppTheme.danger
                        : AppTheme.accent.withValues(alpha: 0.3),
                width: isActive || isSelected ? 2 : 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppTheme.accent.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 頭像
                _PlayerAvatar(
                  emoji: role?.emoji ?? '🎭',
                  isAlive: aiPlayer.isAlive,
                  isActive: isActive,
                ),

                const SizedBox(height: 4),

                // 名稱
                Text(
                  aiPlayer.displayName,
                  style: TextStyle(
                    color: aiPlayer.isAlive
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // 聲望條
                _ReputationBar(
                  current: aiPlayer.reputation,
                  max: 100,
                ),

                // 狀態標籤
                if (!aiPlayer.isAlive)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '出局',
                      style: TextStyle(
                        color: AppTheme.danger,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 對話氣泡
          if (dialogue != null)
            Positioned(
              top: -30,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: dialogueAnimation,
                child: _DialogueBubble(text: dialogue!),
              ),
            ),

          // 選中指示器
          if (isSelected)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppTheme.danger,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.gps_fixed,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 玩家頭像
class _PlayerAvatar extends StatelessWidget {
  final String emoji;
  final bool isAlive;
  final bool isActive;

  const _PlayerAvatar({
    required this.emoji,
    this.isAlive = true,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isAlive ? AppTheme.primaryDark : Colors.grey.shade800,
        border: Border.all(
          color: isActive ? AppTheme.accent : AppTheme.accent.withValues(alpha: 0.5),
          width: isActive ? 3 : 2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppTheme.accent.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(
            fontSize: 24,
            color: isAlive ? null : Colors.grey,
          ),
        ),
      ),
    );
  }
}

/// 聲望條
class _ReputationBar extends StatelessWidget {
  final int current;
  final int max;
  final double height;

  const _ReputationBar({
    required this.current,
    required this.max,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (current / max).clamp(0.0, 1.0);

    Color barColor;
    if (percentage > 0.6) {
      barColor = AppTheme.success;
    } else if (percentage > 0.3) {
      barColor = AppTheme.warning;
    } else {
      barColor = AppTheme.danger;
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: percentage,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [barColor, barColor.withValues(alpha: 0.7)],
            ),
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}

/// 對話氣泡
class _DialogueBubble extends StatelessWidget {
  final String text;

  const _DialogueBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryMid,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 11,
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// 資源顯示
class _ResourceDisplay extends StatelessWidget {
  final int gold;
  final int intel;

  const _ResourceDisplay({
    required this.gold,
    required this.intel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ResourceItem(icon: '💰', value: gold, label: '金幣'),
        const SizedBox(height: 4),
        _ResourceItem(icon: '📜', value: intel, label: '情報'),
      ],
    );
  }
}

class _ResourceItem extends StatelessWidget {
  final String icon;
  final int value;
  final String label;

  const _ResourceItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// 技能按鈕
class _SkillButton extends StatelessWidget {
  final Skill skill;
  final VoidCallback onPressed;

  const _SkillButton({
    required this.skill,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [AppTheme.accent, AppTheme.accentLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.auto_awesome,
            color: AppTheme.primaryDark,
            size: 28,
          ),
        ),
      ),
    );
  }
}

/// 行動按鈕
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool isPrimary;
  final bool isEnabled;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.subtitle,
    this.isPrimary = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onPressed : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isPrimary ? AppTheme.accent : AppTheme.primaryMid,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPrimary
                  ? AppTheme.accent
                  : AppTheme.accent.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isPrimary ? AppTheme.primaryDark : AppTheme.accent,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? AppTheme.primaryDark : AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: isPrimary
                        ? AppTheme.primaryDark.withValues(alpha: 0.7)
                        : AppTheme.textSecondary,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 投票選項按鈕
class _VoteOptionButton extends StatelessWidget {
  final BillOption option;
  final VoidCallback onPressed;

  const _VoteOptionButton({
    required this.option,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.primaryMid,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.accent.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppTheme.accent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  option.label,
                  style: const TextStyle(
                    color: AppTheme.primaryDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              option.title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// 事件訊息
class _EventMessage extends StatelessWidget {
  final GameEvent event;

  const _EventMessage({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getEventColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getEventColor().withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getEventIcon(),
            color: _getEventColor(),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              event.message,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getEventIcon() {
    switch (event.type) {
      case GameEventType.damage:
        return Icons.flash_on;
      case GameEventType.heal:
        return Icons.favorite;
      case GameEventType.allianceFormed:
        return Icons.handshake;
      case GameEventType.allianceBroken:
        return Icons.heart_broken;
      case GameEventType.voteSubmitted:
        return Icons.how_to_vote;
      case GameEventType.playerEliminated:
        return Icons.person_off;
      default:
        return Icons.info_outline;
    }
  }

  Color _getEventColor() {
    switch (event.type) {
      case GameEventType.damage:
        return AppTheme.danger;
      case GameEventType.heal:
        return AppTheme.success;
      case GameEventType.allianceFormed:
        return AppTheme.accent;
      case GameEventType.allianceBroken:
        return AppTheme.danger;
      case GameEventType.playerEliminated:
        return AppTheme.danger;
      default:
        return AppTheme.textSecondary;
    }
  }
}

/// 遊戲日誌項目
class _GameLogItem extends StatelessWidget {
  final GameEvent event;

  const _GameLogItem({required this.event});

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${event.timestamp.hour.toString().padLeft(2, '0')}:${event.timestamp.minute.toString().padLeft(2, '0')}:${event.timestamp.second.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            timeStr,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              event.message,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
