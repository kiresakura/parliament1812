import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/constants/game_constants.dart';
import '../../providers/game_provider.dart';
import '../../providers/socket_provider.dart';
import '../widgets/common/common_widgets.dart';

/// 遊戲主畫面
class GameScreen extends ConsumerStatefulWidget {
  final String roomId;

  const GameScreen({super.key, required this.roomId});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final List<StreamSubscription> _subscriptions = [];
  String? _selectedTargetId;
  String? _selectedVoteOption;

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    final gameService = ref.read(gameServiceProvider);

    // 監聽階段變化
    _subscriptions.add(gameService.onPhaseChanged.listen((data) {
      final phase = _parsePhase(data['phase'] as String?);
      final timeRemaining = data['timeRemaining'] as int? ?? 0;
      ref.read(gameProvider.notifier).setPhase(phase, timeRemaining);
    }));

    // 監聽遊戲狀態更新
    _subscriptions.add(gameService.onGameStateUpdate.listen((data) {
      // 更新剩餘時間
      final timeRemaining = data['timeRemaining'] as int?;
      if (timeRemaining != null) {
        ref.read(gameProvider.notifier).setTimeRemaining(timeRemaining);
      }

      // 更新玩家狀態
      final players = data['players'] as List<dynamic>?;
      if (players != null) {
        for (final playerData in players) {
          if (playerData is Map<String, dynamic>) {
            final playerId = playerData['id'] as String?;
            final reputation = playerData['reputation'] as int?;
            if (playerId != null && reputation != null) {
              final current = ref.read(gameProvider)?.players
                  .firstWhere((p) => p.id == playerId, orElse: () => const PlayerState(id: '', name: ''));
              if (current != null && current.reputation != reputation) {
                ref.read(gameProvider.notifier).updateReputation(
                    playerId, reputation - current.reputation);
              }
            }
          }
        }
      }
    }));

    // 監聯行動結果
    _subscriptions.add(gameService.onActionResult.listen((data) {
      final success = data['success'] as bool? ?? false;
      final message = data['message'] as String? ?? '';

      if (mounted) {
        showToast(context, message, isError: !success);
      }
    }));

    // 監聽訊息
    _subscriptions.add(gameService.onMessageReceived.listen((data) {
      // TODO: 顯示聊天訊息
      debugPrint('Message received: $data');
    }));

    // 監聽遊戲結束
    _subscriptions.add(gameService.onGameEnded.listen((data) {
      if (mounted) {
        _showGameEndDialog(data);
      }
    }));
  }

  GamePhase _parsePhase(String? phase) {
    switch (phase) {
      case 'conspiracy':
        return GamePhase.conspiracy;
      case 'debate':
        return GamePhase.debate;
      case 'event':
        return GamePhase.event;
      case 'voting':
        return GamePhase.voting;
      case 'result':
        return GamePhase.result;
      default:
        return GamePhase.waiting;
    }
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(gameProvider);
    final localPlayer = ref.watch(localPlayerProvider);

    // 監聽連接錯誤
    ref.listen(socketErrorProvider, (previous, next) {
      if (next != null && next.isNotEmpty) {
        showToast(context, next, isError: true);
        ref.read(socketErrorProvider.notifier).state = null;
      }
    });

    if (roomState == null) {
      return const Scaffold(
        body: Center(
          child: Text('遊戲不存在'),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryDark, AppTheme.primaryMid],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 連接狀態欄
              const ConnectionStatusBar(),

              // 頂部狀態列
              _buildTopBar(roomState),

              // 階段指示器
              _buildPhaseIndicator(roomState.phase),

              // 主要內容區
              Expanded(
                child: _buildMainContent(roomState),
              ),

              // 玩家狀態欄
              if (localPlayer != null) _buildPlayerStatusBar(localPlayer),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(RoomState roomState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 房間代碼
          Row(
            children: [
              const ConnectionStatusIndicator(),
              const SizedBox(width: 8),
              Text(
                '房間: ${roomState.roomCode}',
                style: GoogleFonts.lora(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),

          // 倒數計時
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.accent.withAlpha(32),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accent),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, color: AppTheme.accent, size: 18),
                const SizedBox(width: 8),
                Text(
                  _formatTime(roomState.timeRemaining),
                  style: GoogleFonts.cinzel(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accent,
                  ),
                ),
              ],
            ),
          ),

          // 玩家數量
          Text(
            '${roomState.players.length} 人',
            style: GoogleFonts.lora(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseIndicator(GamePhase phase) {
    final phases = [
      GamePhase.conspiracy,
      GamePhase.debate,
      GamePhase.voting,
    ];
    final phaseNames = ['密謀', '辯論', '投票'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(phases.length, (index) {
          final isActive = phases[index] == phase;
          final isPassed = phases.indexOf(phase) > index;

          return Row(
            children: [
              // 階段圓點
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? AppTheme.accent
                      : isPassed
                          ? AppTheme.success
                          : AppTheme.primaryMid,
                  border: Border.all(
                    color: isActive || isPassed
                        ? AppTheme.accent
                        : AppTheme.textSecondary,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.cinzel(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isActive || isPassed
                          ? (isActive ? AppTheme.primaryDark : AppTheme.textPrimary)
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),

              // 階段名稱
              const SizedBox(width: 8),
              Text(
                phaseNames[index],
                style: GoogleFonts.lora(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? AppTheme.accent : AppTheme.textSecondary,
                ),
              ),

              // 連接線
              if (index < phases.length - 1)
                Container(
                  width: 40,
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: isPassed ? AppTheme.accent : AppTheme.textSecondary,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMainContent(RoomState roomState) {
    switch (roomState.phase) {
      case GamePhase.waiting:
      case GamePhase.preparing:
        return _buildWaitingContent();
      case GamePhase.conspiracy:
        return _buildConspiracyContent();
      case GamePhase.debate:
      case GamePhase.event:
        return _buildDebateContent();
      case GamePhase.voting:
        return _buildVotingContent();
      case GamePhase.result:
        return _buildResultContent();
    }
  }

  Widget _buildWaitingContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.accent),
          const SizedBox(height: 24),
          Text(
            '遊戲即將開始...',
            style: GoogleFonts.lora(
              fontSize: 18,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConspiracyContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            '密謀階段',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '與其他玩家私訊、結盟，為即將到來的辯論做準備',
            style: GoogleFonts.lora(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // 玩家列表（可點擊私訊）
          Expanded(
            child: _buildPlayerGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildDebateContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            '辯論階段',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(height: 16),

          // 議案卡片
          _buildBillCard(),
          const SizedBox(height: 24),

          // 目標選擇
          if (_selectedTargetId == null)
            Text(
              '請選擇目標玩家',
              style: GoogleFonts.lora(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            )
          else
            _buildSelectedTarget(),

          const SizedBox(height: 16),

          // 玩家列表（用於選擇目標）
          Expanded(
            child: _buildPlayerGrid(selectable: true),
          ),

          // 動作按鈕
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.question_answer,
                label: '質詢',
                color: AppTheme.danger,
                onPressed: _selectedTargetId != null ? _sendQuery : null,
              ),
              _buildActionButton(
                icon: Icons.shield,
                label: '反駁',
                color: AppTheme.success,
                onPressed: _sendRebut,
              ),
              _buildActionButton(
                icon: Icons.auto_awesome,
                label: '技能',
                color: AppTheme.accent,
                onPressed: _sendSkill,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTarget() {
    final players = ref.watch(playersProvider);
    final target = players.firstWhere(
      (p) => p.id == _selectedTargetId,
      orElse: () => const PlayerState(id: '', name: '未知'),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.accent.withAlpha(32),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '目標: ${target.name}',
            style: GoogleFonts.lora(
              fontSize: 14,
              color: AppTheme.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _selectedTargetId = null),
            child: const Icon(Icons.close, size: 16, color: AppTheme.accent),
          ),
        ],
      ),
    );
  }

  Widget _buildVotingContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            '投票階段',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '請選擇您支持的議案選項',
            style: GoogleFonts.lora(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // 投票選項
          _buildVoteOption('ban_machines', 'A. 禁止機器', '全面禁止工廠使用機械設備'),
          const SizedBox(height: 16),
          _buildVoteOption('protect_property', 'B. 保護財產', '保障工廠主的機器財產權'),
          const SizedBox(height: 16),
          _buildVoteOption('compromise_reform', 'C. 折衷改革', '適度規範機器使用，保障勞工權益'),
        ],
      ),
    );
  }

  Widget _buildResultContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '結算中...',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(color: AppTheme.accent),
        ],
      ),
    );
  }

  Widget _buildPlayerGrid({bool selectable = false}) {
    final players = ref.watch(playersProvider);
    final localPlayer = ref.watch(localPlayerProvider);

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        final isMe = player.id == localPlayer?.id;
        final isSelected = player.id == _selectedTargetId;

        return GestureDetector(
          onTap: selectable && !isMe
              ? () => setState(() => _selectedTargetId = player.id)
              : null,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.accent.withAlpha(64)
                  : AppTheme.primaryMid,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.accent : AppTheme.accent.withAlpha(64),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isMe
                      ? AppTheme.accent
                      : AppTheme.accent.withAlpha(64),
                  child: Text(
                    player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                    style: GoogleFonts.cinzel(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isMe ? AppTheme.primaryDark : AppTheme.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${player.name}${isMe ? " (你)" : ""}',
                  style: GoogleFonts.lora(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // 聲望條
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: player.reputation / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: player.reputation > 30
                            ? AppTheme.success
                            : AppTheme.danger,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBillCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryMid,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent),
      ),
      child: Column(
        children: [
          Text(
            '【機器法案】',
            style: GoogleFonts.cinzel(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '關於工業機器的使用與規範',
            style: GoogleFonts.lora(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: onPressed != null ? color.withAlpha(32) : Colors.grey.withAlpha(32),
            foregroundColor: onPressed != null ? color : Colors.grey,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(20),
            side: BorderSide(color: onPressed != null ? color : Colors.grey, width: 2),
          ),
          child: Icon(icon, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.lora(
            fontSize: 14,
            color: onPressed != null ? color : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildVoteOption(String optionId, String title, String description) {
    final isSelected = _selectedVoteOption == optionId;

    return InkWell(
      onTap: () {
        setState(() => _selectedVoteOption = optionId);
        _sendVote(optionId);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accent.withAlpha(32) : AppTheme.primaryMid,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.accent : AppTheme.accent.withAlpha(64),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.accent : AppTheme.accent.withAlpha(32),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.accent),
              ),
              child: Center(
                child: isSelected
                    ? const Icon(Icons.check, color: AppTheme.primaryDark, size: 24)
                    : Text(
                        title[0],
                        style: GoogleFonts.cinzel(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accent,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cinzel(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.lora(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerStatusBar(PlayerState player) {
    final role = player.roleId != null
        ? RoleDatabase.getRoleById(player.roleId!)
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryMid,
        border: Border(
          top: BorderSide(color: AppTheme.accent.withAlpha(64)),
        ),
      ),
      child: Row(
        children: [
          // 頭像
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.accent.withAlpha(64),
            child: Text(
              role?.emoji ?? player.name[0].toUpperCase(),
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),

          // 資訊
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  player.name,
                  style: GoogleFonts.lora(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (role != null)
                  Text(
                    role.name,
                    style: GoogleFonts.lora(
                      fontSize: 12,
                      color: AppTheme.accent,
                    ),
                  ),
              ],
            ),
          ),

          // 聲望條
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '聲望',
                style: GoogleFonts.lora(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 100,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: player.reputation / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: player.reputation > 30
                          ? AppTheme.success
                          : AppTheme.danger,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${player.reputation}/100',
                style: GoogleFonts.cinzel(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          // 金幣
          Row(
            children: [
              const Icon(Icons.monetization_on, color: AppTheme.accent, size: 20),
              const SizedBox(width: 4),
              Text(
                '${player.gold}',
                style: GoogleFonts.cinzel(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 發送質詢
  void _sendQuery() {
    if (_selectedTargetId == null) return;

    final gameService = ref.read(gameServiceProvider);
    gameService.sendQuery(_selectedTargetId!);
    setState(() => _selectedTargetId = null);
  }

  // 發送反駁
  void _sendRebut() {
    final gameService = ref.read(gameServiceProvider);
    gameService.sendRebut();
  }

  // 發送技能
  void _sendSkill() {
    final gameService = ref.read(gameServiceProvider);
    gameService.sendSkill(targetId: _selectedTargetId);
    setState(() => _selectedTargetId = null);
  }

  // 發送投票
  void _sendVote(String optionId) {
    final gameService = ref.read(gameServiceProvider);
    gameService.vote(optionId);
  }

  // 顯示遊戲結束對話框
  void _showGameEndDialog(Map<String, dynamic> data) {
    final winningFaction = data['winningFaction'] as String? ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryMid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.accent, width: 2),
        ),
        title: Text(
          '🎉 遊戲結束',
          style: GoogleFonts.cinzelDecorative(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.accent,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '獲勝陣營',
              style: GoogleFonts.lora(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              winningFaction.toUpperCase(),
              style: GoogleFonts.cinzel(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.accent,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _returnToHome();
            },
            child: Text(
              '返回首頁',
              style: GoogleFonts.lora(
                color: AppTheme.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _returnToHome() {
    // 清除狀態
    final gameService = ref.read(gameServiceProvider);
    gameService.leaveRoom();

    ref.read(gameProvider.notifier).leaveRoom();
    ref.read(localPlayerProvider.notifier).clear();

    context.go('/');
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
