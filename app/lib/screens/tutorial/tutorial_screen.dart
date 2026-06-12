import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 5 步新手教學互動畫面
class TutorialScreen extends StatefulWidget {
  /// 完成回呼（可用來導航回主選單）
  final VoidCallback? onComplete;

  const TutorialScreen({super.key, this.onComplete});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();

  /// 檢查是否需要顯示教學（首次進入）
  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_completedKey) ?? false);
  }

  /// 標記教學已完成
  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
  }

  static const _completedKey = 'tutorial_completed';
}

class _TutorialScreenState extends State<TutorialScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late final PageController _pageController;
  late final AnimationController _overlayAnimation;

  final List<_TutorialStepData> _steps = [
    _TutorialStepData(
      title: '歡迎來到國會',
      subtitle: '1812 年，英國議會',
      icon: Icons.account_balance,
      color: const Color(0xFFD4AF37),
      content: '歡迎來到 1812 年的英國國會！\n\n'
          '工業革命的浪潮席捲全國，工人、工廠主、記者與革命家齊聚議會，'
          '每一句話都是武器，每一票都決定命運。\n\n'
          '你將扮演一位議員，在政治的漩渦中生存。',
      highlightHint: '畫面上方是你的三大資源：\n❤️ 聲望 ⚡ 影響力 💰 金幣',
      interactionHint: null,
    ),
    _TutorialStepData(
      title: '出牌的藝術',
      subtitle: '拖曳手牌到目標',
      icon: Icons.style,
      color: Colors.red,
      content: '你的手牌在畫面下方，每張牌都有不同效果和消耗。\n\n'
          '⚔️ 攻擊卡 — 對目標造成聲望傷害\n'
          '🛡️ 防禦卡 — 抵消對方攻擊\n'
          '🔧 功能卡 — 恢復聲望或特殊效果\n'
          '⭐ 專屬卡 — 角色獨有的強力卡牌\n\n'
          '每回合自動抽 1 張牌，手牌上限 10 張。',
      highlightHint: '選擇一張攻擊卡，拖向敵方議員！',
      interactionHint: '試試拖曳下方的卡牌',
    ),
    _TutorialStepData(
      title: '投票的力量',
      subtitle: '你的一票改變局勢',
      icon: Icons.how_to_vote,
      color: Colors.blue,
      content: '每回合結束時，議會對議案投票。\n\n'
          '🅰️ 選項 A — 偏向勞工權益\n'
          '🅱️ 選項 B — 偏向工業發展\n'
          '🅲️ 選項 C — 折衷改革\n\n'
          '投票結果會影響所有議員的聲望！\n'
          '聲望越高，你的投票權重越大。',
      highlightHint: '選擇對你最有利的選項',
      interactionHint: '點擊一個選項進行投票',
    ),
    _TutorialStepData(
      title: '質詢與反駁',
      subtitle: '議會中的攻防',
      icon: Icons.gavel,
      color: Colors.orange,
      content: '質詢（⚔️）是辯論階段的主要攻擊手段。\n\n'
          '質詢流程：\n'
          '1. 選擇目標議員\n'
          '2. 消耗 10 聲望發動質詢\n'
          '3. 目標有 10 秒可以反駁\n'
          '4. 成功反駁 = 無傷；未反駁 = 受傷\n\n'
          '反駁需要消耗 5 聲望，但能避免 15 點傷害！',
      highlightHint: '反駁按鈕會在被質詢時亮起',
      interactionHint: null,
    ),
    _TutorialStepData(
      title: '技能與結盟',
      subtitle: '每個角色的獨特能力',
      icon: Icons.auto_awesome,
      color: Colors.purple,
      content: '每個角色都有獨特技能，每回合可使用一次：\n\n'
          '🔨 湯瑪斯 — 團結：盟友越多防禦越高\n'
          '💰 理查 — 收買：花金幣沉默對手\n'
          '📰 愛德華 — 爆料：揭露目標身份\n'
          '🔥 喬治 — 怒火：雙倍傷害但自傷\n\n'
          '密謀階段可以結盟，但小心被背叛！\n'
          '在政治中，沒有永遠的朋友。',
      highlightHint: '準備好了？開始你的國會之旅！',
      interactionHint: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _overlayAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _overlayAnimation.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _overlayAnimation.reset();
      _overlayAnimation.forward();
    } else {
      _completeTutorial();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeTutorial() async {
    await TutorialScreen.markCompleted();
    if (mounted) {
      if (widget.onComplete != null) {
        widget.onComplete!();
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  void _skipTutorial() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('跳過教學？'),
        content: const Text('你可以之後在設定中重新開啟教學。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('繼續學習'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _completeTutorial();
            },
            child: const Text('跳過'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final step = _steps[_currentStep];
    final isLast = _currentStep == _steps.length - 1;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              step.color.withValues(alpha: 0.08),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 頂部：跳過按鈕 + 進度條
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/menu'),
                    ),
                    TextButton(
                      onPressed: _skipTutorial,
                      child: Text(
                        '跳過',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_currentStep + 1} / ${_steps.length}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // 進度指示器
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  children: List.generate(_steps.length, (i) {
                    final isActive = i <= _currentStep;
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: isActive
                              ? step.color
                              : theme.colorScheme.onSurface.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 24),

              // 主內容區
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _steps.length,
                  itemBuilder: (context, index) {
                    final s = _steps[index];
                    return _TutorialStepView(
                      data: s,
                      animation: _overlayAnimation,
                    );
                  },
                ),
              ),

              // 高亮提示 overlay
              if (step.highlightHint != null)
                FadeTransition(
                  opacity: _overlayAnimation,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: step.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: step.color.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline,
                            color: step.color, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            step.highlightHint!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: step.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // 底部按鈕
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      OutlinedButton(
                        onPressed: _previousStep,
                        child: const Text('上一步'),
                      )
                    else
                      const SizedBox(width: 80),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _nextStep,
                      icon: Icon(isLast ? Icons.check : Icons.arrow_forward),
                      label: Text(isLast ? '開始遊戲！' : '下一步'),
                      style: FilledButton.styleFrom(
                        backgroundColor: step.color,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Step View
// ============================================================

class _TutorialStepView extends StatelessWidget {
  final _TutorialStepData data;
  final AnimationController animation;

  const _TutorialStepView({
    required this.data,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.05, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        )),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 圖示
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: data.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(data.icon, size: 40, color: data.color),
                ),
              ),
              const SizedBox(height: 20),

              // 標題
              Center(
                child: Text(
                  data.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: data.color,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  data.subtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 內容
              Text(
                data.content,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                ),
              ),

              // 互動提示
              if (data.interactionHint != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.touch_app,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data.interactionHint!,
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Step Data Model
// ============================================================

class _TutorialStepData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String content;
  final String? highlightHint;
  final String? interactionHint;

  const _TutorialStepData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.content,
    this.highlightHint,
    this.interactionHint,
  });
}
