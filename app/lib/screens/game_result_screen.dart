import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/theme.dart';
import '../models/game_state.dart';
import '../models/player.dart';

// 私有顏色常量（從主題文件複製）
const _darkRed = Color(0xFF8B0000);
const _gold = Color(0xFFD4AF37);
const _darkGold = Color(0xFFB8941C);
const _cream = Color(0xFFFFF8DC);
const _darkBrown = Color(0xFF3C1810);
const _lightBrown = Color(0xFF8B4513);
const _charcoal = Color(0xFF2F2F2F);
const _slate = Color(0xFF1A1A1A);

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: _slate,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _darkRed.withValues(alpha: 0.3),
              _slate,
              _slate.withValues(alpha: 0.8),
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
                      
                      // 排名列表
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
                    ? [_gold, _darkGold]
                    : [_darkRed, const Color(0xFF440000)],
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
                            ? _darkBrown 
                            : _cream,
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  isVictory ? '大獲全勝！' : '政治失敗',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: isVictory 
                        ? _darkBrown 
                        : _cream,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  _getResultSubtitle(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isVictory 
                        ? _darkBrown.withValues(alpha: 0.8)
                        : _cream.withValues(alpha: 0.8),
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
                  Icon(
                    Icons.leaderboard,
                    color: _gold,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '最終排名',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              ...widget.gameResult.rankings.asMap().entries.map((entry) {
                final index = entry.key;
                final ranking = entry.value;
                final isMvp = index == 0;
                
                return _buildRankingItem(ranking, isMvp);
              }),
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
            ? _gold.withValues(alpha: 0.1)
            : _charcoal.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: isMvp
            ? Border.all(color: _gold, width: 2)
            : Border.all(
                color: _lightBrown.withValues(alpha: 0.3), 
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
                  color: _cream,
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
              color: _cream,
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
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _gold,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'MVP',
                          style: TextStyle(
                            color: _darkBrown,
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
                    color: _cream.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          
          // 分數
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${ranking.score}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '聲望: ${ranking.finalReputation}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _cream.withValues(alpha: 0.7),
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
                  Icon(
                    Icons.bar_chart,
                    color: _gold,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '遊戲統計',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // TODO: 這些統計數據需要從後端傳來
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
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: _gold,
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
              onPressed: () {
                // TODO: 重新開始遊戲邏輯
                context.go('/room/${widget.roomCode}');
              },
              child: const Text('再來一局'),
            ),
          ),
          
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                context.go('/menu');
              },
              child: const Text('返回主選單'),
            ),
          ),
        ],
      ),
    );
  }

  bool _isPlayerVictory() {
    // TODO: 根據當前玩家在排名中的位置判斷勝利
    // 目前先假設前兩名算勝利
    final rankings = widget.gameResult.rankings;
    if (rankings.isEmpty) return false;
    
    // 需要當前玩家 ID 來判斷
    return rankings.take(2).any((r) => r.playerId == 'current_player_id');
  }

  String _getResultSubtitle() {
    final isVictory = _isPlayerVictory();
    if (isVictory) {
      return '在這場政治角力中表現卓越！';
    } else {
      return '政治是一門藝術，下次會更好。';
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return _gold;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.brown[400]!;
      default:
        return _lightBrown;
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
        return Icons.groups; // 勞工領袖
      case CharacterType.richardFactory:
        return Icons.business; // 工廠主
      case CharacterType.edwardJournalist:
        return Icons.edit; // 記者
      case CharacterType.georgeLuddite:
        return Icons.balance; // 盧德派領袖
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
    // TODO: 計算遊戲實際時長
    return '15:30';
  }
}