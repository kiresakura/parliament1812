import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/single_player.dart';
import '../../providers/auth_provider.dart';
import '../../providers/single_player_provider.dart';
import '../../services/audio_service.dart';
import '../../services/stamina_service.dart';
import '../../widgets/stamina_bar.dart';

/// AI 難度選擇畫面
class DifficultySelectScreen extends ConsumerWidget {
  const DifficultySelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('快速對戰'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/menu'),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 行動力顯示
                const StaminaBar(),

                const SizedBox(height: 16),

                Text(
                  '選擇難度',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  authState.isAuthenticated
                      ? '對戰記錄將同步到伺服器'
                      : '訪客模式：對戰記錄僅存在本地',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                Expanded(
                  child: ListView(
                    children: AiDifficulty.values
                        .map((difficulty) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _DifficultyCard(difficulty: difficulty),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DifficultyCard extends ConsumerWidget {
  final AiDifficulty difficulty;

  const _DifficultyCard({required this.difficulty});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final colors = {
      AiDifficulty.easy: Colors.green,
      AiDifficulty.normal: Colors.blue,
      AiDifficulty.hard: Colors.orange,
      AiDifficulty.expert: Colors.red,
    };

    final icons = {
      AiDifficulty.easy: Icons.sentiment_satisfied,
      AiDifficulty.normal: Icons.psychology,
      AiDifficulty.hard: Icons.whatshot,
      AiDifficulty.expert: Icons.military_tech,
    };

    final descriptions = {
      AiDifficulty.easy: '隨機出牌，適合新手練習',
      AiDifficulty.normal: '基本策略，考驗基礎操作',
      AiDifficulty.hard: '進階策略，會預測你的行動',
      AiDifficulty.expert: '最佳化策略，幾乎不犯錯',
    };

    final color = colors[difficulty] ?? Colors.grey;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _startGame(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icons[difficulty],
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      difficulty.displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descriptions[difficulty] ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // 行動力消耗提示
              Column(
                children: [
                  const Icon(Icons.bolt, size: 14, color: Colors.amber),
                  Text(
                    '${StaminaService.costQuickMatch}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startGame(BuildContext context, WidgetRef ref) async {
    // 檢查行動力
    final staminaService = ref.read(staminaServiceProvider);
    await staminaService.init();
    final current = await staminaService.currentStamina;

    if (current < StaminaService.costQuickMatch) {
      if (!context.mounted) return;
      final purchased = await showStaminaInsufficientDialog(
        context,
        ref,
        cost: StaminaService.costQuickMatch,
        current: current,
      );
      if (!purchased) return;
    }

    // 消耗行動力
    final consumed = await staminaService.consume(StaminaService.costQuickMatch);
    if (!consumed) return;
    ref.invalidate(currentStaminaProvider);

    ref.read(audioServiceProvider).playSfx(SfxType.cardPlay);

    // Show loading
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // 取得玩家名稱
    final authState = ref.read(authProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    String playerName = authState.playerName ?? prefs.getString('player_name') ?? '議員';

    final notifier = ref.read(singlePlayerProvider.notifier);
    final success = await notifier.startQuickMatch(
      difficulty: difficulty,
      playerName: playerName,
    );

    // Dismiss loading
    if (context.mounted) Navigator.of(context).pop();

    if (success && context.mounted) {
      context.go('/single-player/game');
    } else if (context.mounted) {
      // 退還行動力
      await staminaService.purchase(StaminaService.costQuickMatch, 0);
      ref.invalidate(currentStaminaProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('無法開始對戰，請稍後再試。'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
