import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/theme.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../widgets/animations/ranking_reveal_animation.dart';
import '../widgets/animations/reputation_change_animation.dart';

/// 遊戲結算畫面
class GameResultScreen extends ConsumerStatefulWidget {
  final String roomCode;
  final GameResult gameResult;

  const GameResultScreen({
    super.key,
    required this.roomCode,
    required this.gameResult,
  });

  @override
  ConsumerState<GameResultScreen> createState() => _GameResultScreenState();
}

class _GameResultScreenState extends ConsumerState<GameResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.bounceOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    ));

    _animationController.forward();

    // 播放結算 BGM + 震動
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audio = ref.read(audioServiceProvider);
      audio.playBgm(BgmType.result);
      if (_isPlayerVictory()) {
        audio.playSfx(SfxType.victory);
        HapticService.victory();
      } else {
        audio.playSfx(SfxType.defeat);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Parliament1812Theme.slate,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Parliament1812Theme.darkRed.withValues(alpha: 0.3),
              Parliament1812Theme.slate,
              Parliament1812Theme.slate.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 結果標題
              _buildResultHeader(),

              // 主要內容區域
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // 排名列表 — 使用逐條出現動畫
                      _buildRankingsList(),

                      const SizedBox(height: 24),

                      // 統計資料
                      _buildGameStatistics(),

                      const SizedBox(height: 32),

                      // 操作按鈕
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultHeader() {
    final isVictory = _isPlayerVictory();

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isVictory
                    ? [Parliament1812Theme.gold, Parliament1812Theme.darkGold]
                    : [
                        Parliament1812Theme.darkRed,
                        const Color(0xFF440000)
                      ],
              ),
            ),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Icon(
                        isVictory ? Icons.emoji_events : Icons.trending_down,
                        size: 64,
                        color: isVictory
                            ? Parliament1812Theme.darkBrown
                            : Parliament1812Theme.cream,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  isVictory ? '大獲全勝！' : '政治失敗',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: isVictory
                            ? Parliament1812Theme.darkBrown
                            : Parliament1812Theme.cream,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getResultSubtitle(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isVictory
                            ? Parliament1812Theme.darkBrown
                                .withValues(alpha: 0.8)
                            : Parliament1812Theme.cream
                                .withValues(alpha: 0.8),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRankingsList() {
    final rankings = widget.gameResult.rankings;

    return SlideTransition(
      position: _slideAnimation,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.leaderboard, color: Parliament1812Theme.gold, size: 24),
                  const SizedBox(width: 8),
                  Text('最終排名',
                      style: Theme.of(context).textTheme.headlineMedium),
                ],
              ),
              const SizedBox(height: 16),

              // 使用逐條出現動畫
              RankingRevealAnimation(
                rankingItems: rankings.asMap().entries.map((entry) {
                  final index = entry.key;
                  final ranking = entry.value;
                  final isMvp = index == 0;
                  return _buildRankingItem(ranking, isMvp);
                }).toList(),
                delayBetween: const Duration(milliseconds: 400),
                itemDuration: const Duration(milliseconds: 600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankingItem(PlayerRanking ranking, bool isMvp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMvp
            ? Parliament1812Theme.gold.withValues(alpha: 0.1)
            : Parliament1812Theme.charcoal.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: isMvp
            ? Border.all(color: Parliament1812Theme.gold, width: 2)
            : Border.all(
                color: Parliament1812Theme.lightBrown.withValues(alpha: 0.3),
                width: 1,
              ),
      ),
      child: Row(
        children: [
          // 排名
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getRankColor(ranking.rank),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${ranking.rank}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Parliament1812Theme.cream,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // 角色頭像
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getCharacterColor(ranking.character),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getCharacterIcon(ranking.character),
              color: Parliament1812Theme.cream,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // 玩家資訊
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      ranking.playerName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (isMvp) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Parliament1812Theme.gold,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'MVP',
                          style: TextStyle(
                            color: Parliament1812Theme.darkBrown,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  _getCharacterName(ranking.character),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Parliament1812Theme.cream.withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),

          // 分數 — 使用數字滾動動畫
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ReputationChangeAnimation(
                oldValue: 0,
                newValue: ranking.score,
                duration: const Duration(milliseconds: 1500),
                textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Parliament1812Theme.gold,
                    ),
              ),
              Text(
                '聲望: ${ranking.finalReputation}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Parliament1812Theme.cream.withValues(alpha: 0.7),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameStatistics() {
    return SlideTransition(
      position: _slideAnimation,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bar_chart, color: Parliament1812Theme.gold, size: 24),
                  const SizedBox(width: 8),
                  Text('遊戲統計',
                      style: Theme.of(context).textTheme.headlineMedium),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatItem('使用卡牌數', '12 張'),
              _buildStatItem('造成傷害', '85 點'),
              _buildStatItem('受到傷害', '62 點'),
              _buildStatItem('投票勝率', '75%'),
              _buildStatItem('遊戲時長', _getGameDuration()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Parliament1812Theme.gold,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/room/${widget.roomCode}'),
              child: const Text('再來一局'),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go('/menu'),
              child: const Text('返回主選單'),
            ),
          ),
        ],
      ),
    );
  }

  bool _isPlayerVictory() {
    final rankings = widget.gameResult.rankings;
    if (rankings.isEmpty) return false;
    return rankings.take(2).any((r) => r.playerId == 'current_player_id');
  }

  String _getResultSubtitle() {
    if (_isPlayerVictory()) {
      return '在這場政治角力中表現卓越！';
    } else {
      return '政治是一門藝術，下次會更好。';
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Parliament1812Theme.gold;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.brown[400]!;
      default:
        return Parliament1812Theme.lightBrown;
    }
  }

  Color _getCharacterColor(CharacterType character) {
    switch (character) {
      case CharacterType.thomasWorker:
        return Parliament1812Theme.laborColor;
      case CharacterType.richardFactory:
        return Parliament1812Theme.capitalColor;
      case CharacterType.edwardJournalist:
        return Parliament1812Theme.reformColor;
      case CharacterType.georgeLuddite:
        return Parliament1812Theme.neutralColor;
      default:
        return Parliament1812Theme.neutralColor;
    }
  }

  IconData _getCharacterIcon(CharacterType character) {
    switch (character) {
      case CharacterType.thomasWorker:
        return Icons.groups;
      case CharacterType.richardFactory:
        return Icons.business;
      case CharacterType.edwardJournalist:
        return Icons.edit;
      case CharacterType.georgeLuddite:
        return Icons.balance;
      default:
        return Icons.person;
    }
  }

  String _getCharacterName(CharacterType character) {
    switch (character) {
      case CharacterType.thomasWorker:
        return '湯瑪斯';
      case CharacterType.richardFactory:
        return '理查';
      case CharacterType.edwardJournalist:
        return '愛德華';
      case CharacterType.georgeLuddite:
        return '喬治';
      default:
        return '未知';
    }
  }

  String _getGameDuration() {
    return '15:30';
  }
}
