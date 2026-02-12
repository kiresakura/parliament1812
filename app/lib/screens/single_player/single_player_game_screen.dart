import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/single_player.dart';
import '../../providers/single_player_provider.dart';
import '../../services/audio_service.dart';

/// 單人遊戲主畫面
class SinglePlayerGameScreen extends ConsumerStatefulWidget {
  const SinglePlayerGameScreen({super.key});

  @override
  ConsumerState<SinglePlayerGameScreen> createState() =>
      _SinglePlayerGameScreenState();
}

class _SinglePlayerGameScreenState
    extends ConsumerState<SinglePlayerGameScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gameState = ref.watch(singlePlayerProvider);

    if (gameState == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('載入中...', style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      );
    }

    if (gameState.isGameOver && gameState.result != null) {
      return _GameOverView(result: gameState.result!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('回合 ${gameState.currentRound}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _showQuitDialog(context),
        ),
        actions: [
          Chip(
            label: Text(
              _phaseDisplayName(gameState.phase),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 議案資訊
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.primaryContainer,
            child: Text(
              '📜 ${gameState.currentBill}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // 玩家列表
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: gameState.players.length,
              itemBuilder: (context, index) {
                final player = gameState.players[index];
                return _PlayerChip(player: player);
              },
            ),
          ),

          const Divider(height: 1),

          // AI 行動日誌
          if (gameState.aiActionsLog.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: theme.colorScheme.surfaceContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🤖 AI 行動',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ...gameState.aiActionsLog.take(3).map(
                        (log) => Text(
                          log,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                ],
              ),
            ),

          // 遊戲主區域
          Expanded(
            child: Center(
              child: Text(
                _phaseDisplayName(gameState.phase),
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),

          // 手牌區
          if (gameState.hand.isNotEmpty)
            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: gameState.hand.length,
                itemBuilder: (context, index) {
                  final card = gameState.hand[index];
                  return _HandCard(
                    card: card,
                    onTap: () => _playCard(card),
                  );
                },
              ),
            ),

          // 行動按鈕列
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(singlePlayerProvider.notifier).drawCard(),
                    icon: const Icon(Icons.add_card),
                    label: const Text('抽牌'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        ref.read(singlePlayerProvider.notifier).endTurn(),
                    icon: const Icon(Icons.skip_next),
                    label: const Text('結束'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _playCard(Map<String, dynamic> card) {
    final cardId = card['id'] as String? ?? '';
    ref.read(singlePlayerProvider.notifier).playCard(cardId);
    ref.read(audioServiceProvider).playSfx(SfxType.cardPlay);
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

  String _phaseDisplayName(String phase) {
    switch (phase) {
      case 'conspiracy':
        return '🕵️ 密謀階段';
      case 'debate':
        return '🗣️ 辯論階段';
      case 'voting':
        return '🗳️ 投票階段';
      case 'result':
        return '📊 結算階段';
      default:
        return '⏳ 等待中';
    }
  }
}

class _PlayerChip extends StatelessWidget {
  final SinglePlayerInfo player;

  const _PlayerChip({required this.player});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDead = player.isPoliticallyDead;

    return Container(
      width: 80,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDead
            ? theme.colorScheme.surfaceContainer
            : (player.isAi
                ? theme.colorScheme.secondaryContainer
                : theme.colorScheme.primaryContainer),
        borderRadius: BorderRadius.circular(12),
        border: player.isAi
            ? null
            : Border.all(color: theme.colorScheme.primary, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            player.isAi ? '🤖' : '👤',
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            player.name,
            style: theme.textTheme.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '❤️${player.reputation}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: player.reputation < 30 ? Colors.red : null,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _HandCard extends StatelessWidget {
  final Map<String, dynamic> card;
  final VoidCallback onTap;

  const _HandCard({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = card['name'] as String? ?? '卡牌';
    final cardType = card['card_type'] as String? ?? '';

    final typeIcon = {
      'attack': '⚔️',
      'defense': '🛡️',
      'control': '🔒',
      'buff': '⬆️',
      'intel': '🔍',
      'healing': '💚',
      'social': '🤝',
      'special': '⭐',
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              typeIcon[cardType] ?? '🃏',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: theme.textTheme.labelSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

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
              Icon(
                result.won ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                size: 80,
                color: result.won ? Colors.amber : Colors.grey,
              ),
              const SizedBox(height: 24),
              Text(
                result.won ? '🎉 勝利！' : '😔 落敗',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: result.won ? Colors.amber : Colors.grey,
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
              ...result.rankings.map(
                (p) => ListTile(
                  leading: Text(p.isAi ? '🤖' : '👤'),
                  title: Text(p.name),
                  trailing: Text('${p.score}分'),
                ),
              ),
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
