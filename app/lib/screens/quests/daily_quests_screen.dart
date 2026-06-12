import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/quests_provider.dart';
import 'quest_card.dart';

/// 每日任務畫面
///
/// 顯示「今日任務」標題、重置倒數計時器、3 個任務卡片、
/// 全完成 bonus 提示、streak badge。
class DailyQuestsScreen extends ConsumerStatefulWidget {
  const DailyQuestsScreen({super.key});

  @override
  ConsumerState<DailyQuestsScreen> createState() => _DailyQuestsScreenState();
}

class _DailyQuestsScreenState extends ConsumerState<DailyQuestsScreen> {
  Timer? _countdownTimer;
  int _remainingSecs = 0;

  @override
  void initState() {
    super.initState();
    // 載入任務
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(questsProvider.notifier).loadDailyQuests();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(int secs) {
    _countdownTimer?.cancel();
    _remainingSecs = secs;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingSecs--;
        if (_remainingSecs <= 0) {
          timer.cancel();
          ref.read(questsProvider.notifier).loadDailyQuests();
        }
      });
    });
  }

  String _formatCountdown(int secs) {
    if (secs <= 0) return '即將重置...';
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(questsProvider);

    // 同步倒計時
    if (state.resetInSecs > 0 && _remainingSecs <= 0 && !state.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startCountdown(state.resetInSecs);
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/menu'),
        ),
        title: const Text('每日任務'),
        actions: [
          // 重置倒數
          if (!state.isLoading && state.quests.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer, size: 16, color: theme.colorScheme.secondary),
                    const SizedBox(width: 4),
                    Text(
                      _formatCountdown(_remainingSecs),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? _buildError(theme, state.error!)
              : _buildContent(theme, state),
    );
  }

  Widget _buildError(ThemeData theme, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(error, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.read(questsProvider.notifier).loadDailyQuests(),
            child: const Text('重試'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, DailyQuestsState state) {
    return RefreshIndicator(
      onRefresh: () => ref.read(questsProvider.notifier).loadDailyQuests(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Streak Badge
          if (state.currentStreak > 0) ...[
            _buildStreakBadge(theme, state),
            const SizedBox(height: 16),
          ],

          // 任務卡片
          ...state.quests.map((quest) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: QuestCard(
                quest: quest,
                onClaim: quest.completed && !quest.claimed
                    ? () => _handleClaim(quest.questId)
                    : null,
              ),
            );
          }),

          // 全完成 Bonus
          if (state.quests.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildBonusSection(theme, state),
          ],
        ],
      ),
    );
  }

  Widget _buildStreakBadge(ThemeData theme, DailyQuestsState state) {
    final isWeekStreak = state.currentStreak >= 7;
    final streakColor = isWeekStreak
        ? const Color(0xFFFF6B00)
        : const Color(0xFFD4AF37);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            streakColor.withValues(alpha: 0.15),
            streakColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: streakColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // 火焰圖標
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: streakColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '🔥',
                style: TextStyle(fontSize: isWeekStreak ? 24 : 20),
              ),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '連續 ${state.currentStreak} 天',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: streakColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '最長紀錄：${state.longestStreak} 天',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),

          // 7天里程碑
          if (state.currentStreak >= 7)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: streakColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '🎉 ${state.currentStreak ~/ 7}x7 天',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBonusSection(ThemeData theme, DailyQuestsState state) {
    final completedCount = state.quests.where((q) => q.completed).length;
    final totalCount = state.quests.length;
    final allDone = completedCount == totalCount && totalCount > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: allDone
              ? const Color(0xFF9C27B0).withValues(alpha: 0.5)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        color: allDone
            ? const Color(0xFF9C27B0).withValues(alpha: 0.08)
            : null,
      ),
      child: Row(
        children: [
          Icon(
            allDone ? Icons.diamond : Icons.diamond_outlined,
            color: allDone ? const Color(0xFF9C27B0) : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '全完成獎勵',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: allDone ? const Color(0xFF9C27B0) : Colors.grey,
                  ),
                ),
                Text(
                  allDone
                      ? '完成所有任務！領取任務即可獲得額外 10 寶石'
                      : '完成所有 $totalCount 個任務可額外獲得 10 寶石（$completedCount/$totalCount）',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          // 進度指示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (allDone ? const Color(0xFF9C27B0) : Colors.grey).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$completedCount/$totalCount',
              style: TextStyle(
                color: allDone ? const Color(0xFF9C27B0) : Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleClaim(String questId) async {
    final message = await ref.read(questsProvider.notifier).claimReward(questId);
    if (mounted && message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
