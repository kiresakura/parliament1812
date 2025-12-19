import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../providers/room_provider.dart';
import '../providers/player_provider.dart';
import '../providers/game_provider.dart';
import '../widgets/animated_widgets.dart';
import '../services/sound_service.dart';

/// 投票畫面 - 1812 年議會投票風格
/// 基於 VotingScreen1812.tsx 設計
class VoteScreen extends StatefulWidget {
  final int round;

  const VoteScreen({
    super.key,
    required this.round,
  });

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

// 投票選項枚舉
enum VoteChoice { aye, nay, abstain }

// 法案資料
class BillData {
  final String titleChinese;
  final String titleEnglish;
  final String description;
  final String context;

  const BillData({
    required this.titleChinese,
    required this.titleEnglish,
    required this.description,
    required this.context,
  });
}

// 預設法案資料 - 1812 年天主教解放法案
const _defaultBill = BillData(
  titleChinese: '天主教解放法案',
  titleEnglish: 'Catholic Relief Act',
  description: '本法案旨在解除對天主教徒的政治限制，允許其擔任公職並進入議會。此舉將改變英國自宗教改革以來的基本國策，引發激烈爭論。',
  context: '當前英國法律禁止天主教徒擔任大多數公職，此法案若通過將是重大突破。',
);

class _VoteScreenState extends State<VoteScreen>
    with TickerProviderStateMixin {
  VoteChoice? _selectedChoice;
  bool _hasVoted = false;
  bool _showResults = false;
  int _timeLeft = 60; // 60 秒倒計時
  Timer? _countdownTimer;
  late AnimationController _glowController;
  late AnimationController _shineController;

  // 投票結果
  final Map<VoteChoice, int> _results = {
    VoteChoice.aye: 8,
    VoteChoice.nay: 12,
    VoteChoice.abstain: 2,
  };

  int get _totalVotes => _results.values.fold(0, (a, b) => a + b);

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _shineController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _loadVoteOptions();
    _startCountdown();

    // 入場音效
    Future.delayed(const Duration(milliseconds: 300), () {
      soundService.play(SoundEffect.paperRustle);
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _shineController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0 && !_hasVoted) {
        setState(() => _timeLeft--);
      } else if (_timeLeft == 0 && !_hasVoted) {
        _castVote(VoteChoice.abstain);
      }
    });
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  double get _progressPercent => _timeLeft / 60;

  Future<void> _loadVoteOptions() async {
    final roomCode = context.read<RoomProvider>().room?.code;
    if (roomCode != null) {
      await context.read<GameProvider>().loadVoteOptions(roomCode);
    }
  }

  void _castVote(VoteChoice choice) {
    if (_hasVoted) return;
    soundService.buttonFeedback();
    soundService.play(SoundEffect.sealStamp);
    soundService.haptic(HapticType.heavy);

    setState(() {
      _selectedChoice = choice;
      _hasVoted = true;
    });

    _countdownTimer?.cancel();

    // 2秒後顯示結果
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showResults = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Civ6 風格六角形背景
          const HexagonPatternBackground(),
          // 粒子效果
          const AtmosphereParticles(particleCount: 25),
          // 漸層覆蓋
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryBackground,
                  AppTheme.primaryBackground.withValues(alpha: 0.95),
                  AppTheme.cardBackground.withValues(alpha: 0.9),
                ],
              ),
            ),
          ),
          // 暈影效果
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  AppTheme.primaryBackground.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
          // 主內容
          SafeArea(
            child: Consumer3<RoomProvider, PlayerProvider, GameProvider>(
              builder: (context, roomProvider, playerProvider, gameProvider, _) {
                final room = roomProvider.room;
                final player = playerProvider.currentPlayer;

                if (room == null || player == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HexagonBadge(
                          size: 100,
                          glowColor: AppTheme.accentGold,
                          child: const Icon(
                            Icons.how_to_vote,
                            size: 50,
                            color: AppTheme.accentGold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '準備投票中...',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 16,
                            color: AppTheme.accentGold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Preparing ballot...',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 12,
                            color: AppTheme.textTertiary,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // 自訂 AppBar
                    _buildAppBar(),
                    // 法案資訊
                    _buildVoteHeader(),
                    // 倒計時進度條
                    _buildProgressBar(gameProvider.voteProgress),
                    // 投票選項 (AYE/NAY/ABSTAIN)
                    Expanded(
                      child: _buildVoteOptions([]),
                    ),
                    // 確認投票按鈕
                    _buildVoteButton(
                      roomCode: room.code,
                      playerId: player.id,
                      gameProvider: gameProvider,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.cardBackground.withValues(alpha: 0.95),
            AppTheme.cardBackground.withValues(alpha: 0.8),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.accentGold.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 返回按鈕
          GestureDetector(
            onTap: () {
              soundService.buttonFeedback();
              Navigator.pop(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.accentGold.withValues(alpha: 0.5),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: AppTheme.accentGold,
                size: 20,
              ),
            ),
          ),
          const Spacer(),
          // 標題區域
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.accentGold.withValues(
                      alpha: 0.4 + (_glowController.value * 0.3),
                    ),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentGold.withValues(
                        alpha: 0.1 + (_glowController.value * 0.1),
                      ),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HexagonIcon(
                      size: 18,
                      color: AppTheme.accentGold,
                      filled: true,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        Text(
                          '第 ${widget.round} 輪表決',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentGold,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          'VOTE ROUND ${widget.round}',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 10,
                            color: AppTheme.textTertiary,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    HexagonIcon(
                      size: 18,
                      color: AppTheme.accentGold,
                      filled: true,
                    ),
                  ],
                ),
              );
            },
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.5, end: 0);
  }

  Widget _buildVoteHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.parchmentColor.withValues(alpha: 0.1),
            AppTheme.cardBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentGold.withValues(alpha: 0.1),
            blurRadius: 15,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          // 羊皮紙捲軸圖標
          HexagonBadge(
            size: 60,
            glowColor: AppTheme.accentGold,
            child: const Icon(
              Icons.article_outlined,
              size: 30,
              color: AppTheme.accentGold,
            ),
          ),
          const SizedBox(height: 16),
          // 法案標題
          Text(
            _defaultBill.titleChinese,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentGold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _defaultBill.titleEnglish.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 11,
              color: AppTheme.textTertiary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          VictorianDivider(width: 200, color: AppTheme.accentGold),
          const SizedBox(height: 16),
          // 法案說明
          Text(
            _defaultBill.description,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // 背景資訊
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.textSecondary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _defaultBill.context,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textTertiary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildProgressBar(double progress) {
    // 根據剩餘時間決定顏色
    final Color timerColor = _timeLeft <= 10
        ? AppTheme.voteNay
        : (_timeLeft <= 30 ? AppTheme.whigOrange : AppTheme.accentGold);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: timerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: timerColor,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '表決時間',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Time Remaining',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 10,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
              // 倒計時顯示
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: timerColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: timerColor.withValues(
                          alpha: _timeLeft <= 10
                              ? 0.5 + (_glowController.value * 0.5)
                              : 0.4,
                        ),
                      ),
                      boxShadow: _timeLeft <= 10
                          ? [
                              BoxShadow(
                                color: timerColor.withValues(
                                  alpha: 0.2 + (_glowController.value * 0.3),
                                ),
                                blurRadius: 10,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      _formatTime(_timeLeft),
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: timerColor,
                        letterSpacing: 2,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 進度條（顯示時間進度）
          Stack(
            children: [
              // 背景
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBackground,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: timerColor.withValues(alpha: 0.2),
                  ),
                ),
              ),
              // 進度（時間剩餘）
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 8,
                width: MediaQuery.of(context).size.width * _progressPercent * 0.85,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      timerColor,
                      timerColor.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: timerColor.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }

  Widget _buildVoteOptions(List<dynamic> options) {
    // 如果已投票且顯示結果
    if (_showResults) {
      return _buildResultsView();
    }

    // 如果已投票，顯示確認
    if (_hasVoted) {
      return _buildVotedConfirmation();
    }

    // 顯示投票按鈕
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // AYE / NAY 按鈕並排
          Row(
            children: [
              // AYE 按鈕
              Expanded(
                child: _buildVoteChoiceButton(
                  choice: VoteChoice.aye,
                  label: '贊成',
                  englishLabel: 'AYE',
                  icon: Icons.thumb_up_outlined,
                  color: const Color(0xFF2d5a27), // 深綠色
                  isSelected: _selectedChoice == VoteChoice.aye,
                ),
              ),
              const SizedBox(width: 16),
              // NAY 按鈕
              Expanded(
                child: _buildVoteChoiceButton(
                  choice: VoteChoice.nay,
                  label: '反對',
                  englishLabel: 'NAY',
                  icon: Icons.thumb_down_outlined,
                  color: const Color(0xFF8b2500), // 深紅色
                  isSelected: _selectedChoice == VoteChoice.nay,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 24),
          // 棄權選項
          GestureDetector(
            onTap: _hasVoted ? null : () => _castVote(VoteChoice.abstain),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.textTertiary.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.do_not_disturb_alt,
                    size: 16,
                    color: AppTheme.textTertiary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '棄權',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 14,
                      color: AppTheme.textTertiary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'ABSTAIN',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 10,
                      color: AppTheme.textTertiary.withValues(alpha: 0.7),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }

  Widget _buildVoteChoiceButton({
    required VoteChoice choice,
    required String label,
    required String englishLabel,
    required IconData icon,
    required Color color,
    required bool isSelected,
  }) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return GestureDetector(
          onTap: _hasVoted ? null : () {
            soundService.buttonFeedback();
            setState(() => _selectedChoice = choice);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isSelected
                    ? [
                        color,
                        color.withValues(alpha: 0.8),
                      ]
                    : [
                        color.withValues(alpha: 0.2),
                        color.withValues(alpha: 0.1),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? color
                    : color.withValues(alpha: 0.4),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(
                          alpha: 0.3 + (_glowController.value * 0.2),
                        ),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                // 六角形圖標
                HexagonBadge(
                  size: 70,
                  glowColor: isSelected ? Colors.white : color,
                  child: Icon(
                    icon,
                    size: 35,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
                const SizedBox(height: 16),
                // 中文標籤
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : color,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 4),
                // 英文標籤
                Text(
                  englishLabel,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.8)
                        : color.withValues(alpha: 0.7),
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVotedConfirmation() {
    final String choiceText = switch (_selectedChoice) {
      VoteChoice.aye => '贊成',
      VoteChoice.nay => '反對',
      VoteChoice.abstain => '棄權',
      null => '',
    };
    final Color choiceColor = switch (_selectedChoice) {
      VoteChoice.aye => const Color(0xFF2d5a27),
      VoteChoice.nay => const Color(0xFF8b2500),
      VoteChoice.abstain => AppTheme.brassColor,
      null => AppTheme.accentGold,
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 印章效果
          _buildInkStamp(choiceText, choiceColor),
          const SizedBox(height: 30),
          Text(
            '選票已投入票箱',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentGold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your vote has been cast',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 12,
              color: AppTheme.textTertiary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 24),
          // 等待提示
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.brassColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '等待其他議員完成表決...',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildInkStamp(String text, Color color) {
    return Transform.rotate(
      angle: -0.1, // 輕微傾斜
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 8,
            ),
          ),
        ),
      ),
    )
        .animate()
        .scale(
          begin: const Offset(2.0, 2.0),
          end: const Offset(1.0, 1.0),
          duration: 300.ms,
          curve: Curves.easeOut,
        )
        .then()
        .shake(duration: 200.ms, hz: 4, rotation: 0.02);
  }

  Widget _buildResultsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 結果標題
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GearIcon(size: 16, color: AppTheme.accentGold),
                    const SizedBox(width: 12),
                    Text(
                      '表決結果',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentGold,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GearIcon(size: 16, color: AppTheme.accentGold),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'VOTING RESULTS',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 10,
                    color: AppTheme.textTertiary,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 24),
          // AYE 結果
          _buildResultBar(
            label: '贊成 AYE',
            count: _results[VoteChoice.aye]!,
            color: const Color(0xFF2d5a27),
            delay: 200,
          ),
          const SizedBox(height: 16),
          // NAY 結果
          _buildResultBar(
            label: '反對 NAY',
            count: _results[VoteChoice.nay]!,
            color: const Color(0xFF8b2500),
            delay: 400,
          ),
          const SizedBox(height: 16),
          // ABSTAIN 結果
          _buildResultBar(
            label: '棄權 ABSTAIN',
            count: _results[VoteChoice.abstain]!,
            color: AppTheme.brassColor,
            delay: 600,
          ),
          const SizedBox(height: 30),
          // 結論
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.cardBackground,
                    AppTheme.cardBackground.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _results[VoteChoice.aye]! > _results[VoteChoice.nay]!
                      ? const Color(0xFF2d5a27)
                      : const Color(0xFF8b2500),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _results[VoteChoice.aye]! > _results[VoteChoice.nay]!
                        ? '法案通過'
                        : '法案被否決',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _results[VoteChoice.aye]! > _results[VoteChoice.nay]!
                          ? const Color(0xFF2d5a27)
                          : const Color(0xFF8b2500),
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _results[VoteChoice.aye]! > _results[VoteChoice.nay]!
                        ? 'BILL PASSED'
                        : 'BILL REJECTED',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 12,
                      color: AppTheme.textTertiary,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 800.ms).scale(begin: const Offset(0.95, 0.95)),
        ],
      ),
    );
  }

  Widget _buildResultBar({
    required String label,
    required int count,
    required Color color,
    required int delay,
  }) {
    final double percent = _totalVotes > 0 ? count / _totalVotes : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              '$count 票 (${(percent * 100).toInt()}%)',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            // 背景
            Container(
              height: 24,
              decoration: BoxDecoration(
                color: AppTheme.primaryBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                ),
              ),
            ),
            // 進度
            AnimatedContainer(
              duration: Duration(milliseconds: 800 + delay),
              curve: Curves.easeOutCubic,
              height: 24,
              width: (MediaQuery.of(context).size.width - 40) * percent,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color,
                    color.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: Duration(milliseconds: delay));
  }

  Widget _buildVoteButton({
    required String roomCode,
    required String playerId,
    required GameProvider gameProvider,
  }) {
    // 如果已投票或顯示結果，不顯示按鈕
    if (_hasVoted || _showResults) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppTheme.primaryBackground.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: _selectedChoice != null
                  ? const LinearGradient(
                      colors: [
                        AppTheme.accentGold,
                        Color(0xFFB8941F),
                      ],
                    )
                  : LinearGradient(
                      colors: [
                        AppTheme.accentGold.withValues(alpha: 0.4),
                        AppTheme.accentGold.withValues(alpha: 0.3),
                      ],
                    ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: _selectedChoice != null
                  ? [
                      BoxShadow(
                        color: AppTheme.accentGold.withValues(alpha: 0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _selectedChoice == null
                    ? null
                    : () => _castVote(_selectedChoice!),
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HexagonIcon(
                      size: 20,
                      color: _selectedChoice == null
                          ? Colors.white60
                          : AppTheme.primaryBackground,
                      filled: true,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _selectedChoice != null ? '確認投票' : '請選擇一項',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _selectedChoice == null
                            ? Colors.white60
                            : AppTheme.primaryBackground,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedChoice != null ? 'CONFIRM' : 'SELECT ONE',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 10,
                        color: _selectedChoice == null
                            ? Colors.white38
                            : AppTheme.primaryBackground.withValues(alpha: 0.7),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 光澤動畫（僅在可點擊時顯示）
          if (_selectedChoice != null)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AnimatedBuilder(
                  animation: _shineController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        (_shineController.value * 400) - 100,
                        0,
                      ),
                      child: Container(
                        width: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.2),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
