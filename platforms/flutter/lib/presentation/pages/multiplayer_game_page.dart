import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/multiplayer_game_provider.dart';

/// 多人遊戲主頁面
class MultiplayerGamePage extends ConsumerStatefulWidget {
  const MultiplayerGamePage({super.key});

  @override
  ConsumerState<MultiplayerGamePage> createState() => _MultiplayerGamePageState();
}

class _MultiplayerGamePageState extends ConsumerState<MultiplayerGamePage> {
  final _chatController = TextEditingController();
  final _chatScrollController = ScrollController();

  @override
  void dispose() {
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(multiplayerGameProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            // 頂部：階段指示器 + 計時器
            _buildHeader(gameState),

            // 中間：玩家座位圈
            Expanded(
              flex: 3,
              child: _buildPlayersArea(gameState),
            ),

            // 行動記錄區
            Expanded(
              flex: 1,
              child: _buildActionLog(gameState),
            ),

            // 底部：手牌區 + 行動按鈕
            _buildBottomArea(gameState),
          ],
        ),
      ),
    );
  }

  /// 頂部標題欄
  Widget _buildHeader(MultiplayerGameState gameState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // 返回按鈕
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => _showLeaveConfirmDialog(),
          ),
          const SizedBox(width: 8),

          // 階段指示器
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getPhaseTitle(gameState.phase),
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '第 ${gameState.round} 回合',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // 計時器
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: gameState.timeRemaining < 30
                  ? Colors.red.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer,
                  color: gameState.timeRemaining < 30 ? Colors.red : Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(gameState.timeRemaining),
                  style: TextStyle(
                    color: gameState.timeRemaining < 30 ? Colors.red : Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 玩家座位區
  Widget _buildPlayersArea(MultiplayerGameState gameState) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: gameState.players.map((player) {
            return _buildPlayerSeat(player, gameState);
          }).toList(),
        ),
      ),
    );
  }

  /// 玩家座位
  Widget _buildPlayerSeat(MultiplayerPlayer player, MultiplayerGameState gameState) {
    final isLocal = player.id == gameState.localPlayerId;
    final canTarget = gameState.phase == MultiplayerPhase.debate &&
        !isLocal &&
        player.isAlive;

    return GestureDetector(
      onTap: canTarget ? () => _showTargetOptions(player) : null,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isLocal
              ? const Color(0xFFD4AF37).withValues(alpha: 0.1)
              : player.isAlive
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLocal
                ? const Color(0xFFD4AF37)
                : player.isAlive
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.red.withValues(alpha: 0.3),
            width: isLocal ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 頭像
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _getFactionColor(player.characterId).withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getFactionColor(player.characterId),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  player.characterName?.isNotEmpty == true
                      ? player.characterName![0]
                      : player.name[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 名稱
            Text(
              player.name,
              style: TextStyle(
                color: player.isAlive ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
                decoration: player.isAlive ? null : TextDecoration.lineThrough,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // 角色
            if (player.characterName != null)
              Text(
                player.characterName!,
                style: TextStyle(
                  color: _getFactionColor(player.characterId),
                  fontSize: 12,
                ),
              ),

            const SizedBox(height: 8),

            // 聲望條
            _buildReputationBar(player.reputation),

            // 資源顯示
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildResourceBadge(Icons.shield, player.defense, Colors.blue),
                const SizedBox(width: 8),
                _buildResourceBadge(
                    Icons.monetization_on, player.gold, const Color(0xFFFFD700)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 聲望條
  Widget _buildReputationBar(int reputation) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '聲望',
              style: TextStyle(color: Colors.white54, fontSize: 10),
            ),
            Text(
              '$reputation',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: reputation / 100,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              reputation > 50
                  ? Colors.green
                  : reputation > 25
                      ? Colors.orange
                      : Colors.red,
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  /// 資源徽章
  Widget _buildResourceBadge(IconData icon, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            '$value',
            style: TextStyle(color: color, fontSize: 10),
          ),
        ],
      ),
    );
  }

  /// 行動記錄區
  Widget _buildActionLog(MultiplayerGameState gameState) {
    final messages = [
      ...gameState.challengeRecords.map((r) => ChatMessage(
            fromId: r.attackerId,
            fromName: r.attackerName,
            content: r.countered
                ? '質詢 ${r.targetName}，但被反駁了！'
                : '質詢 ${r.targetName}，造成 ${r.damage} 點傷害！',
            isSystem: true,
            timestamp: r.timestamp,
          )),
      ...gameState.chatMessages,
    ]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 標題
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.history, size: 16, color: Colors.white54),
                SizedBox(width: 8),
                Text(
                  '議事記錄',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          // 記錄列表
          Expanded(
            child: ListView.builder(
              controller: _chatScrollController,
              padding: const EdgeInsets.all(8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    msg.isSystem
                        ? '⚔️ ${msg.content}'
                        : '${msg.fromName}: ${msg.content}',
                    style: TextStyle(
                      color: msg.isSystem
                          ? const Color(0xFFD4AF37)
                          : Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 底部區域
  Widget _buildBottomArea(MultiplayerGameState gameState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        children: [
          // 行動按鈕
          if (gameState.phase == MultiplayerPhase.debate)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // 顯示玩家選擇器
                      _showPlayerSelector('質詢');
                    },
                    icon: const Icon(Icons.gavel),
                    label: const Text('質詢'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(multiplayerGameProvider.notifier).counter();
                    },
                    icon: const Icon(Icons.shield),
                    label: const Text('反駁'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // 使用技能
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('技能'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

          // 投票按鈕
          if (gameState.phase == MultiplayerPhase.voting &&
              gameState.votingState != null)
            Column(
              children: [
                Text(
                  gameState.votingState!.billTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildVoteButton('A', gameState.votingState!.optionADesc),
                    const SizedBox(width: 8),
                    _buildVoteButton('B', gameState.votingState!.optionBDesc),
                    const SizedBox(width: 8),
                    _buildVoteButton('C', gameState.votingState!.optionCDesc),
                  ],
                ),
              ],
            ),

          const SizedBox(height: 12),

          // 聊天輸入
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '發送訊息...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: _sendChat,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _sendChat(_chatController.text),
                icon: const Icon(Icons.send, color: Color(0xFFD4AF37)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoteButton(String choice, String description) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          ref.read(multiplayerGameProvider.notifier).vote(choice);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD4AF37).withValues(alpha: 0.2),
          foregroundColor: const Color(0xFFD4AF37),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFD4AF37)),
          ),
        ),
        child: Column(
          children: [
            Text(
              '選項 $choice',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              description,
              style: const TextStyle(fontSize: 10),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ===== Helper Methods =====

  String _getPhaseTitle(MultiplayerPhase phase) {
    switch (phase) {
      case MultiplayerPhase.lobby:
        return '大廳';
      case MultiplayerPhase.conspiracy:
        return '密謀階段';
      case MultiplayerPhase.debate:
        return '辯論階段';
      case MultiplayerPhase.voting:
        return '投票階段';
      case MultiplayerPhase.result:
        return '結算';
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Color _getFactionColor(String? characterId) {
    if (characterId == null) return Colors.grey;
    if (characterId.contains('thomas') || characterId.contains('george')) {
      return Colors.red; // 勞工派
    } else if (characterId.contains('richard')) {
      return const Color(0xFFFFD700); // 資方派
    } else if (characterId.contains('robert') || characterId.contains('edward')) {
      return Colors.blue; // 改革派
    } else if (characterId.contains('king') || characterId.contains('william')) {
      return Colors.purple; // 皇室/中立
    }
    return Colors.grey;
  }

  void _showTargetOptions(MultiplayerPlayer player) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '對 ${player.name} 進行行動',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.gavel, color: Colors.red),
                title: const Text('質詢', style: TextStyle(color: Colors.white)),
                subtitle: Text('攻擊對方，降低其聲望',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(multiplayerGameProvider.notifier).challenge(player.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat, color: Colors.blue),
                title: const Text('私訊', style: TextStyle(color: Colors.white)),
                subtitle: Text('發送私密訊息',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: 顯示私訊對話框
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPlayerSelector(String action) {
    final gameState = ref.read(multiplayerGameProvider);
    final targets = gameState.players
        .where((p) => p.id != gameState.localPlayerId && p.isAlive)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '選擇$action目標',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...targets.map((player) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getFactionColor(player.characterId),
                      child: Text(player.name[0]),
                    ),
                    title: Text(player.name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text('聲望: ${player.reputation}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(multiplayerGameProvider.notifier).challenge(player.id);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  void _sendChat(String text) {
    if (text.trim().isNotEmpty) {
      ref.read(multiplayerGameProvider.notifier).sendChat(text.trim());
      _chatController.clear();
    }
  }

  void _showLeaveConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('離開遊戲', style: TextStyle(color: Colors.white)),
          content: const Text(
            '確定要離開遊戲嗎？這將放棄當前進度。',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(multiplayerGameProvider.notifier).leaveRoom();
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('離開'),
            ),
          ],
        );
      },
    );
  }
}
