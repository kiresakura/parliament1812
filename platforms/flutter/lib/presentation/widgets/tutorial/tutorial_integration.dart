// 1812 國會風雲 - 教學系統整合工具
//
// 提供教學系統與遊戲畫面的整合功能

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/models/tutorial.dart';
import '../../../providers/tutorial_provider.dart';
import 'tutorial_overlay.dart';

// ============================================================
// 教學整合配置
// ============================================================

/// 教學整合配置
class TutorialIntegrationConfig {
  /// 是否在教學期間暫停遊戲計時
  final bool pauseTimerDuringTutorial;

  /// 是否在教學期間禁用 AI 攻擊玩家
  final bool disableAIAttackDuringTutorial;

  /// 是否自動啟動教學（首次遊玩）
  final bool autoStartForNewPlayers;

  /// 教學完成後是否顯示恭喜對話框
  final bool showCompletionDialog;

  /// 遮罩顏色
  final Color overlayColor;

  /// 遮罩透明度
  final double overlayOpacity;

  const TutorialIntegrationConfig({
    this.pauseTimerDuringTutorial = true,
    this.disableAIAttackDuringTutorial = true,
    this.autoStartForNewPlayers = true,
    this.showCompletionDialog = true,
    this.overlayColor = Colors.black,
    this.overlayOpacity = 0.75,
  });

  static const TutorialIntegrationConfig defaultConfig =
      TutorialIntegrationConfig();
}

// ============================================================
// 教學整合 Mixin
// ============================================================

/// 教學整合 Mixin
///
/// 用於遊戲畫面，提供教學相關的輔助方法
mixin TutorialIntegrationMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// 教學配置
  TutorialIntegrationConfig get tutorialConfig =>
      TutorialIntegrationConfig.defaultConfig;

  /// 是否正在進行教學
  bool get isTutorialActive => ref.read(tutorialProvider).isActive;

  /// 是否為首次遊玩
  bool get isFirstTimePlayer => ref.read(tutorialProvider).isFirstTime;

  /// 當前教學步驟
  TutorialStep? get currentTutorialStep =>
      ref.read(tutorialProvider).currentStep;

  /// 初始化教學系統
  Future<void> initializeTutorial() async {
    await ref.read(tutorialProvider.notifier).initialize();

    // 首次遊玩自動啟動教學
    if (tutorialConfig.autoStartForNewPlayers && isFirstTimePlayer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTutorialPrompt();
      });
    }
  }

  /// 顯示教學提示對話框
  void _showTutorialPrompt() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _TutorialPromptDialog(
        onStart: () {
          Navigator.of(context).pop();
          ref.read(tutorialProvider.notifier).startTutorial();
        },
        onSkip: () {
          Navigator.of(context).pop();
          ref.read(tutorialProvider.notifier).skipTutorial();
        },
      ),
    );
  }

  /// 手動啟動教學
  void startTutorial() {
    ref.read(tutorialProvider.notifier).startTutorial();
  }

  /// 啟動特定課程
  void startLesson(TutorialLesson lesson) {
    ref.read(tutorialProvider.notifier).startLesson(lesson);
  }

  /// 檢查是否應該暫停遊戲計時
  bool shouldPauseTimer() {
    return tutorialConfig.pauseTimerDuringTutorial && isTutorialActive;
  }

  /// 檢查是否應該禁用 AI 攻擊
  bool shouldDisableAIAttack() {
    return tutorialConfig.disableAIAttackDuringTutorial && isTutorialActive;
  }

  /// 通知教學系統玩家完成了某個動作
  void notifyTutorialAction(
    TutorialAction action, {
    Map<String, dynamic>? data,
  }) {
    ref.read(tutorialProvider.notifier).onPlayerActionCompleted(
          action: action,
          data: data,
        );
  }

  /// 包裝遊戲畫面，添加教學覆蓋層
  Widget wrapWithTutorialOverlay(Widget child) {
    return TutorialOverlay(
      overlayColor: tutorialConfig.overlayColor,
      overlayOpacity: tutorialConfig.overlayOpacity,
      child: child,
    );
  }
}

// ============================================================
// 教學提示對話框
// ============================================================

class _TutorialPromptDialog extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onSkip;

  const _TutorialPromptDialog({
    required this.onStart,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFD4AF37),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 標題
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF16213E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.school,
                    color: Color(0xFFD4AF37),
                    size: 32,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '歡迎來到 1812 國會！',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 內容
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '看起來這是你第一次進入國會議場。',
                    style: TextStyle(
                      color: Color(0xFFE8E8E8),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '建議先完成新手教學，學習基本的辯論技巧和投票規則。',
                    style: TextStyle(
                      color: Color(0xFFA0A0A0),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 教學內容預覽
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16213E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '你將學到：',
                          style: TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildLessonItem('認識聲望和生存系統'),
                        _buildLessonItem('學習質詢攻擊技巧'),
                        _buildLessonItem('掌握反駁防禦時機'),
                        _buildLessonItem('使用角色專屬技能'),
                        _buildLessonItem('參與投票決定結局'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 按鈕
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: onSkip,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFA0A0A0),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('跳過教學'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: onStart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: const Color(0xFF1A1A2E),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '開始教學',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildLessonItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Color(0xFF27AE60),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFFE8E8E8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 教學完成對話框
// ============================================================

/// 顯示教學完成對話框
void showTutorialCompletionDialog(
  BuildContext context, {
  VoidCallback? onContinue,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFD4AF37),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 標題
            Container(
              padding: const EdgeInsets.all(24),
              child: const Column(
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: Color(0xFFD4AF37),
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '恭喜！',
                    style: TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '你已完成全部教學課程',
                    style: TextStyle(
                      color: Color(0xFFE8E8E8),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // 內容
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  children: [
                    Text(
                      '你已準備好進入真正的 1812 國會！',
                      style: TextStyle(
                        color: Color(0xFFE8E8E8),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    Text(
                      '記住：\n聲望是你的生命\n質詢是你的武器\n反駁是你的盾牌\n技能是你的王牌',
                      style: TextStyle(
                        color: Color(0xFFA0A0A0),
                        fontSize: 13,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // 按鈕
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onContinue?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: const Color(0xFF1A1A2E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '開始遊戲！',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ============================================================
// 教學目標 ID 常數
// ============================================================

/// 教學目標 ID
///
/// 用於標識需要高亮的 UI 元素
class TutorialTargetIds {
  TutorialTargetIds._();

  // 主要 UI 元素
  static const String reputationBar = 'reputation_bar';
  static const String goldDisplay = 'gold_display';
  static const String phaseIndicator = 'phase_indicator';
  static const String timerDisplay = 'timer_display';

  // 動作按鈕
  static const String queryButton = 'query_button';
  static const String rebutButton = 'rebut_button';
  static const String skillButton = 'skill_button';
  static const String voteButton = 'vote_button';
  static const String messageButton = 'message_button';
  static const String allianceButton = 'alliance_button';

  // 面板區域
  static const String playerList = 'player_list';
  static const String actionButtons = 'action_buttons';
  static const String voteOptions = 'vote_options';
  static const String votePanel = 'vote_panel';
  static const String skillPanel = 'skill_panel';
  static const String resultPanel = 'result_panel';

  // 玩家卡片
  static const String humanPlayerCard = 'human_player_card';
  static const String aiPlayerCard = 'ai_player_card';
}

// ============================================================
// 教學狀態監聽擴展
// ============================================================

/// 教學完成監聽器
class TutorialCompletionListener extends ConsumerWidget {
  final Widget child;
  final void Function(TutorialLesson lesson)? onLessonComplete;
  final VoidCallback? onTutorialComplete;

  const TutorialCompletionListener({
    super.key,
    required this.child,
    this.onLessonComplete,
    this.onTutorialComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<TutorialState>(tutorialProvider, (previous, current) {
      // 檢查課程完成
      if (previous != null && current.completedLessons.length > previous.completedLessons.length) {
        final newlyCompleted = current.completedLessons
            .difference(previous.completedLessons)
            .firstOrNull;
        if (newlyCompleted != null) {
          onLessonComplete?.call(newlyCompleted);
        }
      }

      // 檢查全部完成
      if (previous != null &&
          !previous.isFullyCompleted &&
          current.isFullyCompleted) {
        onTutorialComplete?.call();
      }
    });

    return child;
  }
}

// ============================================================
// 首次遊玩檢測
// ============================================================

/// 檢查是否為首次遊玩
Future<bool> isFirstTimePlaying() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('tutorial_is_first_time') ?? true;
  } catch (_) {
    return true;
  }
}

/// 標記已非首次遊玩
Future<void> markAsNotFirstTime() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_is_first_time', false);
  } catch (_) {
    // 忽略錯誤
  }
}
