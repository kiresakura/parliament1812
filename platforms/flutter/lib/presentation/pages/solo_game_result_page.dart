// 1812 國會風雲 - 單人模式遊戲結算頁面
//
// 顯示遊戲結果、投票統計、個人分數、MVP 和獎勵

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/game_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/models.dart';
import '../../providers/solo_game_provider.dart';

// ============================================================
// 遊戲結果類型
// ============================================================

/// 遊戲結果類型
enum GameResultType {
  victory,  // 勝利
  defeat,   // 失敗
  draw,     // 平局
}

/// 玩家結算資料
class PlayerResultData {
  final String playerId;
  final String name;
  final String? roleId;
  final int finalReputation;
  final bool isAlive;
  final String? votedOption;
  final int score;
  final bool isHuman;

  const PlayerResultData({
    required this.playerId,
    required this.name,
    this.roleId,
    required this.finalReputation,
    required this.isAlive,
    this.votedOption,
    required this.score,
    this.isHuman = false,
  });
}

/// MVP 資料
class MVPData {
  final String title;
  final String description;
  final String playerId;
  final String playerName;
  final String emoji;
  final int value;

  const MVPData({
    required this.title,
    required this.description,
    required this.playerId,
    required this.playerName,
    required this.emoji,
    required this.value,
  });
}

/// 成就資料
class AchievementData {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int bonusScore;
  final bool isNew;

  const AchievementData({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.bonusScore = 0,
    this.isNew = false,
  });
}

// ============================================================
// 主頁面
// ============================================================

/// 單人模式遊戲結算頁面
class SoloGameResultPage extends ConsumerStatefulWidget {
  const SoloGameResultPage({super.key});

  @override
  ConsumerState<SoloGameResultPage> createState() => _SoloGameResultPageState();
}

class _SoloGameResultPageState extends ConsumerState<SoloGameResultPage>
    with TickerProviderStateMixin {
  /// 動畫控制器
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scoreController;

  /// 動畫
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scoreAnimation;

  /// 是否顯示詳細日誌
  bool _showDetailedLog = false;

  @override
  void initState() {
    super.initState();

    // 淡入動畫
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // 滑入動畫
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // 分數計數動畫
    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scoreAnimation = CurvedAnimation(
      parent: _scoreController,
      curve: Curves.easeOutCubic,
    );

    // 開始動畫序列
    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _slideController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _scoreController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(soloGameProvider);

    // 計算結果資料
    final resultType = _calculateResultType(gameState);
    final voteResults = _calculateVoteResults(gameState);
    final playerResults = _calculatePlayerResults(gameState);
    final personalScore = _calculatePersonalScore(gameState, resultType);
    final mvpList = _calculateMVPs(gameState);
    final achievements = _calculateAchievements(gameState);
    final rewards = _calculateRewards(gameState, resultType);

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Stack(
          children: [
            // 背景裝飾
            _buildBackground(resultType),

            // 主要內容
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: CustomScrollView(
                  slivers: [
                    // 1. 結果公布區域
                    SliverToBoxAdapter(
                      child: _buildResultHeader(resultType, voteResults),
                    ),

                    // 2. 個人結算
                    SliverToBoxAdapter(
                      child: _buildPersonalScore(personalScore),
                    ),

                    // 3. MVP 展示
                    if (mvpList.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _buildMVPSection(mvpList),
                      ),

                    // 4. 所有玩家結算
                    SliverToBoxAdapter(
                      child: _buildAllPlayersSection(playerResults),
                    ),

                    // 5. 獎勵顯示
                    SliverToBoxAdapter(
                      child: _buildRewardsSection(rewards, achievements),
                    ),

                    // 底部間距
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100),
                    ),
                  ],
                ),
              ),
            ),

            // 6. 底部按鈕
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomButtons(),
            ),

            // 詳細日誌面板
            if (_showDetailedLog) _buildDetailedLogPanel(gameState),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 背景裝飾
  // ============================================================

  Widget _buildBackground(GameResultType resultType) {
    Color glowColor;
    switch (resultType) {
      case GameResultType.victory:
        glowColor = AppTheme.success;
        break;
      case GameResultType.defeat:
        glowColor = AppTheme.danger;
        break;
      case GameResultType.draw:
        glowColor = AppTheme.warning;
        break;
    }

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              glowColor.withValues(alpha: 0.15),
              AppTheme.primaryDark,
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 1. 結果公布區域
  // ============================================================

  Widget _buildResultHeader(
    GameResultType resultType,
    VoteResultsData voteResults,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 大標題
          _ResultTitle(resultType: resultType),

          const SizedBox(height: 24),

          // 投票結果
          _VoteResultsCard(voteResults: voteResults),
        ],
      ),
    );
  }

  // ============================================================
  // 2. 個人結算
  // ============================================================

  Widget _buildPersonalScore(PersonalScoreData data) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryMid,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accent.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '個人結算',
            style: TextStyle(
              color: AppTheme.accent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // 分數項目
          _ScoreRow(
            label: '陣營分數',
            value: data.factionScore,
            icon: Icons.groups,
          ),
          const SizedBox(height: 8),
          _ScoreRow(
            label: '生存獎勵',
            value: data.survivalBonus,
            icon: Icons.favorite,
          ),
          const SizedBox(height: 8),
          _ScoreRow(
            label: '行動分數',
            value: data.actionScore,
            icon: Icons.flash_on,
          ),

          if (data.secretMissionCompleted) ...[
            const SizedBox(height: 8),
            _ScoreRow(
              label: '秘密任務',
              value: data.secretMissionScore,
              icon: Icons.assignment_turned_in,
              isHighlight: true,
            ),
          ],

          const Divider(color: AppTheme.accent, height: 32),

          // 總分
          AnimatedBuilder(
            animation: _scoreAnimation,
            builder: (context, child) {
              final displayScore =
                  (_scoreAnimation.value * data.totalScore).round();
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '總分',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$displayScore',
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 3. MVP 展示
  // ============================================================

  Widget _buildMVPSection(List<MVPData> mvpList) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              '本場 MVP',
              style: TextStyle(
                color: AppTheme.accent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: mvpList.length,
              itemBuilder: (context, index) {
                return _MVPCard(mvp: mvpList[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 4. 所有玩家結算
  // ============================================================

  Widget _buildAllPlayersSection(List<PlayerResultData> players) {
    // 按分數排序
    final sortedPlayers = List<PlayerResultData>.from(players)
      ..sort((a, b) => b.score.compareTo(a.score));

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryMid,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accent.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '玩家排名',
            style: TextStyle(
              color: AppTheme.accent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...sortedPlayers.asMap().entries.map((entry) {
            final index = entry.key;
            final player = entry.value;
            return _PlayerResultRow(
              rank: index + 1,
              player: player,
            );
          }),
        ],
      ),
    );
  }

  // ============================================================
  // 5. 獎勵顯示
  // ============================================================

  Widget _buildRewardsSection(
    RewardsData rewards,
    List<AchievementData> achievements,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 獎勵標題
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              '獲得獎勵',
              style: TextStyle(
                color: AppTheme.accent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 獎勵卡片
          Row(
            children: [
              Expanded(
                child: _RewardCard(
                  icon: '💰',
                  label: '金幣',
                  value: '+${rewards.goldEarned}',
                  color: AppTheme.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RewardCard(
                  icon: '⭐',
                  label: '經驗值',
                  value: '+${rewards.expEarned}',
                  color: AppTheme.accent,
                ),
              ),
            ],
          ),

          // 成就
          if (achievements.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                '獲得成就',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
            ...achievements.map((achievement) => _AchievementRow(
                  achievement: achievement,
                )),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // 6. 底部按鈕
  // ============================================================

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryDark.withValues(alpha: 0),
            AppTheme.primaryDark,
          ],
        ),
      ),
      child: Row(
        children: [
          // 返回主頁
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _returnToHome(),
              icon: const Icon(Icons.home),
              label: const Text('返回主頁'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accent,
                side: const BorderSide(color: AppTheme.accent),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // 查看詳情
          IconButton(
            onPressed: () => setState(() => _showDetailedLog = true),
            icon: const Icon(Icons.list_alt, color: AppTheme.accent),
            tooltip: '查看詳情',
          ),

          const SizedBox(width: 8),

          // 再來一局
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => _playAgain(),
              icon: const Icon(Icons.replay),
              label: const Text('再來一局'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: AppTheme.primaryDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 詳細日誌面板
  // ============================================================

  Widget _buildDetailedLogPanel(SoloGameState gameState) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _showDetailedLog = false),
        child: Container(
          color: Colors.black87,
          child: Center(
            child: GestureDetector(
              onTap: () {}, // 防止點擊穿透
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.7,
                decoration: BoxDecoration(
                  color: AppTheme.primaryMid,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.accent, width: 2),
                ),
                child: Column(
                  children: [
                    // 標題欄
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
                            '完整遊戲日誌',
                            style: TextStyle(
                              color: AppTheme.accent,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () =>
                                setState(() => _showDetailedLog = false),
                            icon: const Icon(Icons.close, color: AppTheme.accent),
                          ),
                        ],
                      ),
                    ),

                    // 日誌列表
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: gameState.gameLog.length,
                        itemBuilder: (context, index) {
                          final event = gameState.gameLog[index];
                          return _DetailedLogItem(event: event);
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
  // 計算方法
  // ============================================================

  GameResultType _calculateResultType(SoloGameState state) {
    final humanPlayer = state.humanPlayer;
    if (humanPlayer == null) return GameResultType.draw;

    // 判斷勝負
    if (state.winner == humanPlayer.name) {
      return GameResultType.victory;
    } else if (state.winner != null) {
      return GameResultType.defeat;
    }

    // 判斷是否存活
    if (!humanPlayer.isAlive) {
      return GameResultType.defeat;
    }

    // 判斷投票結果（簡化版）
    final humanRole = RoleDatabase.getRoleById(humanPlayer.roleId ?? '');
    if (humanRole != null && state.currentBill != null) {
      final winningOption = _getWinningOption(state);
      final billOption = state.currentBill!.getOptionById(winningOption);
      if (billOption?.benefitFaction == humanRole.faction) {
        return GameResultType.victory;
      }
    }

    return GameResultType.draw;
  }

  String _getWinningOption(SoloGameState state) {
    final tally = <String, double>{'A': 0, 'B': 0, 'C': 0};
    for (final entry in state.votes.entries) {
      final player = state.allPlayers.firstWhere(
        (p) => p.id == entry.key,
        orElse: () => const Player(id: '', name: ''),
      );
      if (player.isAlive) {
        tally[entry.value] = (tally[entry.value] ?? 0) + player.voteWeight;
      }
    }

    String winner = 'C';
    double maxVotes = 0;
    for (final entry in tally.entries) {
      if (entry.value > maxVotes) {
        maxVotes = entry.value;
        winner = entry.key;
      }
    }
    return winner;
  }

  VoteResultsData _calculateVoteResults(SoloGameState state) {
    final tally = <String, double>{'A': 0, 'B': 0, 'C': 0};
    final votersByOption = <String, List<String>>{'A': [], 'B': [], 'C': []};

    for (final entry in state.votes.entries) {
      final player = state.allPlayers.firstWhere(
        (p) => p.id == entry.key,
        orElse: () => const Player(id: '', name: ''),
      );
      final playerName = player.name.isNotEmpty ? player.name : entry.key;
      tally[entry.value] = (tally[entry.value] ?? 0) + player.voteWeight;
      votersByOption[entry.value]?.add(playerName);
    }

    final winningOption = _getWinningOption(state);

    return VoteResultsData(
      optionAVotes: tally['A'] ?? 0,
      optionBVotes: tally['B'] ?? 0,
      optionCVotes: tally['C'] ?? 0,
      winningOption: winningOption,
      votersByOption: votersByOption,
      bill: state.currentBill,
    );
  }

  List<PlayerResultData> _calculatePlayerResults(SoloGameState state) {
    final results = <PlayerResultData>[];

    // 人類玩家
    if (state.humanPlayer != null) {
      results.add(PlayerResultData(
        playerId: state.humanPlayer!.id,
        name: state.humanPlayer!.name,
        roleId: state.humanPlayer!.roleId,
        finalReputation: state.humanPlayer!.reputation,
        isAlive: state.humanPlayer!.isAlive,
        votedOption: state.votes[state.humanPlayer!.id],
        score: _calculatePlayerScore(state.humanPlayer!, state),
        isHuman: true,
      ));
    }

    // AI 玩家
    for (final ai in state.aiPlayers) {
      results.add(PlayerResultData(
        playerId: ai.id,
        name: ai.displayName,
        roleId: ai.roleId,
        finalReputation: ai.reputation,
        isAlive: ai.isAlive,
        votedOption: state.votes[ai.id],
        score: _calculatePlayerScore(ai.player, state),
      ));
    }

    return results;
  }

  int _calculatePlayerScore(Player player, SoloGameState state) {
    int score = 0;

    // 生存獎勵
    if (player.isAlive) {
      score += 50;
      score += player.reputation ~/ 2;
    }

    // 投票獎勵
    final vote = state.votes[player.id];
    final winningOption = _getWinningOption(state);
    if (vote == winningOption) {
      score += 30;
    }

    return score;
  }

  PersonalScoreData _calculatePersonalScore(
    SoloGameState state,
    GameResultType resultType,
  ) {
    final humanPlayer = state.humanPlayer;
    if (humanPlayer == null) {
      return const PersonalScoreData(
        factionScore: 0,
        survivalBonus: 0,
        actionScore: 0,
        secretMissionCompleted: false,
        secretMissionScore: 0,
        totalScore: 0,
      );
    }

    // 陣營分數
    int factionScore = 0;
    if (resultType == GameResultType.victory) {
      factionScore = GameConstants.billVictoryScore;
    } else if (resultType == GameResultType.draw) {
      factionScore = GameConstants.billCompromiseScore;
    }

    // 生存獎勵
    int survivalBonus = 0;
    if (humanPlayer.isAlive) {
      survivalBonus = 50 + humanPlayer.reputation ~/ 2;
    }

    // 行動分數（根據遊戲日誌計算）
    int actionScore = 0;
    for (final event in state.gameLog) {
      if (event.playerId == humanPlayer.id) {
        switch (event.type) {
          case GameEventType.playerAction:
            actionScore += 5;
            break;
          case GameEventType.damage:
            actionScore += 10;
            break;
          case GameEventType.allianceFormed:
            actionScore += 15;
            break;
          default:
            break;
        }
      }
    }

    // 秘密任務（簡化版，總是未完成）
    const secretMissionCompleted = false;
    const secretMissionScore = 0;

    final totalScore =
        factionScore + survivalBonus + actionScore + secretMissionScore;

    return PersonalScoreData(
      factionScore: factionScore,
      survivalBonus: survivalBonus,
      actionScore: actionScore,
      secretMissionCompleted: secretMissionCompleted,
      secretMissionScore: secretMissionScore,
      totalScore: totalScore,
    );
  }

  List<MVPData> _calculateMVPs(SoloGameState state) {
    final mvps = <MVPData>[];
    final playerDamage = <String, int>{};
    final playerAlliances = <String, int>{};

    // 統計資料
    for (final event in state.gameLog) {
      if (event.type == GameEventType.damage && event.playerId != null) {
        final damage = event.data['damage'] as int? ?? 0;
        playerDamage[event.playerId!] =
            (playerDamage[event.playerId!] ?? 0) + damage;
      }
      if (event.type == GameEventType.allianceFormed && event.playerId != null) {
        playerAlliances[event.playerId!] =
            (playerAlliances[event.playerId!] ?? 0) + 1;
      }
    }

    // 最高傷害
    if (playerDamage.isNotEmpty) {
      final topDamager = playerDamage.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      final player = _findPlayer(state, topDamager.key);
      if (player != null) {
        mvps.add(MVPData(
          title: '最佳辯論',
          description: '造成最高傷害',
          playerId: topDamager.key,
          playerName: player.name,
          emoji: '⚔️',
          value: topDamager.value,
        ));
      }
    }

    // 最多結盟
    if (playerAlliances.isNotEmpty) {
      final topAlly = playerAlliances.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      final player = _findPlayer(state, topAlly.key);
      if (player != null) {
        mvps.add(MVPData(
          title: '外交大師',
          description: '建立最多同盟',
          playerId: topAlly.key,
          playerName: player.name,
          emoji: '🤝',
          value: topAlly.value,
        ));
      }
    }

    // 生存者（聲望最高）
    final alivePlayers = state.allPlayers.where((p) => p.isAlive).toList();
    if (alivePlayers.isNotEmpty) {
      final topSurvivor = alivePlayers
          .reduce((a, b) => a.reputation > b.reputation ? a : b);
      mvps.add(MVPData(
        title: '屹立不倒',
        description: '最高聲望存活',
        playerId: topSurvivor.id,
        playerName: topSurvivor.name,
        emoji: '🏆',
        value: topSurvivor.reputation,
      ));
    }

    return mvps;
  }

  Player? _findPlayer(SoloGameState state, String playerId) {
    if (state.humanPlayer?.id == playerId) return state.humanPlayer;
    return state.aiPlayers
        .where((ai) => ai.id == playerId)
        .map((ai) => ai.player)
        .firstOrNull;
  }

  List<AchievementData> _calculateAchievements(SoloGameState state) {
    final achievements = <AchievementData>[];
    final humanPlayer = state.humanPlayer;
    if (humanPlayer == null) return achievements;

    // 檢查各種成就
    if (humanPlayer.isAlive && humanPlayer.reputation >= 80) {
      achievements.add(const AchievementData(
        id: 'high_reputation',
        name: '聲譽卓著',
        description: '以 80+ 聲望完成遊戲',
        icon: '👑',
        bonusScore: 20,
        isNew: true,
      ));
    }

    // 檢查是否造成過傷害
    final dealtDamage = state.gameLog.any(
      (e) => e.type == GameEventType.damage && e.playerId == humanPlayer.id,
    );
    if (dealtDamage) {
      achievements.add(const AchievementData(
        id: 'first_blood',
        name: '初試啼聲',
        description: '成功對其他玩家造成傷害',
        icon: '⚔️',
        bonusScore: 10,
      ));
    }

    // 檢查是否結盟過
    if (humanPlayer.allies.isNotEmpty) {
      achievements.add(const AchievementData(
        id: 'diplomat',
        name: '外交手腕',
        description: '與其他玩家結成同盟',
        icon: '🤝',
        bonusScore: 10,
      ));
    }

    return achievements;
  }

  RewardsData _calculateRewards(SoloGameState state, GameResultType resultType) {
    int goldEarned = 10; // 基礎獎勵
    int expEarned = 20;

    if (resultType == GameResultType.victory) {
      goldEarned += 30;
      expEarned += 50;
    } else if (resultType == GameResultType.draw) {
      goldEarned += 15;
      expEarned += 25;
    }

    // 根據生存狀態加成
    if (state.humanPlayer?.isAlive ?? false) {
      goldEarned += 10;
      expEarned += 20;
    }

    return RewardsData(
      goldEarned: goldEarned,
      expEarned: expEarned,
    );
  }

  // ============================================================
  // 導航方法
  // ============================================================

  void _returnToHome() {
    ref.read(soloGameProvider.notifier).resetGame();
    context.go('/');
  }

  void _playAgain() {
    ref.read(soloGameProvider.notifier).resetGame();
    // 返回設定頁面
    context.go('/solo/setup');
  }
}

// ============================================================
// 資料類
// ============================================================

class VoteResultsData {
  final double optionAVotes;
  final double optionBVotes;
  final double optionCVotes;
  final String winningOption;
  final Map<String, List<String>> votersByOption;
  final Bill? bill;

  const VoteResultsData({
    required this.optionAVotes,
    required this.optionBVotes,
    required this.optionCVotes,
    required this.winningOption,
    required this.votersByOption,
    this.bill,
  });

  double get totalVotes => optionAVotes + optionBVotes + optionCVotes;
}

class PersonalScoreData {
  final int factionScore;
  final int survivalBonus;
  final int actionScore;
  final bool secretMissionCompleted;
  final int secretMissionScore;
  final int totalScore;

  const PersonalScoreData({
    required this.factionScore,
    required this.survivalBonus,
    required this.actionScore,
    required this.secretMissionCompleted,
    required this.secretMissionScore,
    required this.totalScore,
  });
}

class RewardsData {
  final int goldEarned;
  final int expEarned;

  const RewardsData({
    required this.goldEarned,
    required this.expEarned,
  });
}

// ============================================================
// 子元件
// ============================================================

/// 結果標題
class _ResultTitle extends StatelessWidget {
  final GameResultType resultType;

  const _ResultTitle({required this.resultType});

  @override
  Widget build(BuildContext context) {
    String title;
    Color color;
    IconData icon;

    switch (resultType) {
      case GameResultType.victory:
        title = '勝利！';
        color = AppTheme.success;
        icon = Icons.emoji_events;
        break;
      case GameResultType.defeat:
        title = '失敗...';
        color = AppTheme.danger;
        icon = Icons.sentiment_dissatisfied;
        break;
      case GameResultType.draw:
        title = '平局';
        color = AppTheme.warning;
        icon = Icons.balance;
        break;
    }

    return Column(
      children: [
        Icon(icon, color: color, size: 64),
        const SizedBox(height: 12),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// 投票結果卡片
class _VoteResultsCard extends StatelessWidget {
  final VoteResultsData voteResults;

  const _VoteResultsCard({required this.voteResults});

  @override
  Widget build(BuildContext context) {
    final bill = voteResults.bill;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryMid,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accent.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '投票結果',
            style: TextStyle(
              color: AppTheme.accent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // 三個選項的票數
          _VoteOptionResult(
            label: 'A',
            title: bill?.optionA.title ?? '',
            votes: voteResults.optionAVotes,
            totalVotes: voteResults.totalVotes,
            isWinner: voteResults.winningOption == 'A',
            voters: voteResults.votersByOption['A'] ?? [],
          ),
          const SizedBox(height: 12),
          _VoteOptionResult(
            label: 'B',
            title: bill?.optionB.title ?? '',
            votes: voteResults.optionBVotes,
            totalVotes: voteResults.totalVotes,
            isWinner: voteResults.winningOption == 'B',
            voters: voteResults.votersByOption['B'] ?? [],
          ),
          const SizedBox(height: 12),
          _VoteOptionResult(
            label: 'C',
            title: bill?.optionC.title ?? '',
            votes: voteResults.optionCVotes,
            totalVotes: voteResults.totalVotes,
            isWinner: voteResults.winningOption == 'C',
            voters: voteResults.votersByOption['C'] ?? [],
          ),
        ],
      ),
    );
  }
}

/// 投票選項結果
class _VoteOptionResult extends StatelessWidget {
  final String label;
  final String title;
  final double votes;
  final double totalVotes;
  final bool isWinner;
  final List<String> voters;

  const _VoteOptionResult({
    required this.label,
    required this.title,
    required this.votes,
    required this.totalVotes,
    required this.isWinner,
    required this.voters,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = totalVotes > 0 ? votes / totalVotes : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWinner
            ? AppTheme.accent.withValues(alpha: 0.2)
            : AppTheme.primaryDark,
        borderRadius: BorderRadius.circular(8),
        border: isWinner
            ? Border.all(color: AppTheme.accent, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 選項標籤
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isWinner ? AppTheme.accent : AppTheme.textSecondary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isWinner
                          ? AppTheme.primaryDark
                          : AppTheme.primaryMid,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 標題
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isWinner
                            ? AppTheme.accent
                            : AppTheme.textPrimary,
                        fontWeight:
                            isWinner ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (voters.isNotEmpty)
                      Text(
                        voters.join('、'),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // 票數
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    votes.toStringAsFixed(1),
                    style: TextStyle(
                      color: isWinner ? AppTheme.accent : AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${(percentage * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),

              // 獲勝標記
              if (isWinner) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.accent,
                  size: 24,
                ),
              ],
            ],
          ),

          // 進度條
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: AppTheme.primaryMid,
              valueColor: AlwaysStoppedAnimation<Color>(
                isWinner ? AppTheme.accent : AppTheme.textSecondary,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

/// 分數行
class _ScoreRow extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final bool isHighlight;

  const _ScoreRow({
    required this.label,
    required this.value,
    required this.icon,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: isHighlight ? AppTheme.accent : AppTheme.textSecondary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isHighlight ? AppTheme.textPrimary : AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          '+$value',
          style: TextStyle(
            color: isHighlight ? AppTheme.accent : AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

/// MVP 卡片
class _MVPCard extends StatelessWidget {
  final MVPData mvp;

  const _MVPCard({required this.mvp});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryMid,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accent.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(mvp.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            mvp.title,
            style: const TextStyle(
              color: AppTheme.accent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            mvp.playerName,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${mvp.value}',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// 玩家結果行
class _PlayerResultRow extends StatelessWidget {
  final int rank;
  final PlayerResultData player;

  const _PlayerResultRow({
    required this.rank,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    final role = RoleDatabase.getRoleById(player.roleId ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: player.isHuman
            ? AppTheme.accent.withValues(alpha: 0.1)
            : AppTheme.primaryDark,
        borderRadius: BorderRadius.circular(8),
        border: player.isHuman
            ? Border.all(color: AppTheme.accent.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        children: [
          // 排名
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _getRankColor(rank),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: AppTheme.primaryDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 頭像
          Text(
            role?.emoji ?? '🎭',
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),

          // 名稱和狀態
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      player.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (player.isHuman)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '你',
                          style: TextStyle(
                            color: AppTheme.primaryDark,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  player.isAlive
                      ? '聲望: ${player.finalReputation}'
                      : '已出局',
                  style: TextStyle(
                    color: player.isAlive
                        ? AppTheme.textSecondary
                        : AppTheme.danger,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // 投票
          if (player.votedOption != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryMid,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '投 ${player.votedOption}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),

          const SizedBox(width: 12),

          // 分數
          Text(
            '${player.score}',
            style: const TextStyle(
              color: AppTheme.accent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return AppTheme.accent;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.brown.shade400;
      default:
        return AppTheme.textSecondary;
    }
  }
}

/// 獎勵卡片
class _RewardCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;

  const _RewardCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryMid,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 成就行
class _AchievementRow extends StatelessWidget {
  final AchievementData achievement;

  const _AchievementRow({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: achievement.isNew
            ? AppTheme.accent.withValues(alpha: 0.1)
            : AppTheme.primaryMid,
        borderRadius: BorderRadius.circular(8),
        border: achievement.isNew
            ? Border.all(color: AppTheme.accent.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        children: [
          Text(
            achievement.icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      achievement.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (achievement.isNew)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: AppTheme.primaryDark,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  achievement.description,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (achievement.bonusScore > 0)
            Text(
              '+${achievement.bonusScore}',
              style: const TextStyle(
                color: AppTheme.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}

/// 詳細日誌項目
class _DetailedLogItem extends StatelessWidget {
  final GameEvent event;

  const _DetailedLogItem({required this.event});

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
          // 時間
          Text(
            timeStr,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 12),

          // 事件圖標
          Icon(
            _getEventIcon(),
            color: _getEventColor(),
            size: 16,
          ),
          const SizedBox(width: 8),

          // 事件內容
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

  IconData _getEventIcon() {
    switch (event.type) {
      case GameEventType.gameStarted:
        return Icons.play_arrow;
      case GameEventType.phaseChanged:
        return Icons.schedule;
      case GameEventType.playerAction:
      case GameEventType.aiAction:
        return Icons.person;
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
      case GameEventType.voteResult:
        return Icons.bar_chart;
      case GameEventType.playerEliminated:
        return Icons.person_off;
      case GameEventType.gameEnded:
        return Icons.flag;
      default:
        return Icons.info_outline;
    }
  }

  Color _getEventColor() {
    switch (event.type) {
      case GameEventType.gameStarted:
      case GameEventType.gameEnded:
        return AppTheme.accent;
      case GameEventType.damage:
      case GameEventType.allianceBroken:
      case GameEventType.playerEliminated:
        return AppTheme.danger;
      case GameEventType.heal:
      case GameEventType.allianceFormed:
        return AppTheme.success;
      case GameEventType.voteSubmitted:
      case GameEventType.voteResult:
        return AppTheme.accent;
      default:
        return AppTheme.textSecondary;
    }
  }
}
