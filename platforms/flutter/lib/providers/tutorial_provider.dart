// 1812 國會風雲 - 教學系統狀態管理
//
// 使用 Riverpod 管理教學系統的所有狀態

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/tutorial.dart';
import '../data/local/tutorial_data.dart';

// ============================================================
// 教學系統狀態
// ============================================================

/// 教學系統狀態
class TutorialState {
  /// 教學是否正在進行中
  final bool isActive;

  /// 當前課程
  final TutorialLesson? currentLesson;

  /// 當前步驟索引（在課程內的索引）
  final int currentStepIndex;

  /// 已完成的課程列表
  final Set<TutorialLesson> completedLessons;

  /// 當前高亮的元素 ID
  final String? highlightedElement;

  /// 當前教學步驟
  final TutorialStep? currentStep;

  /// 是否正在等待玩家動作
  final bool isWaitingForAction;

  /// 是否正在演示中
  final bool isDemonstrating;

  /// 演示進度（0.0 - 1.0）
  final double demoProgress;

  /// 是否顯示提示
  final bool showHint;

  /// 是否已完成全部教學
  final bool isFullyCompleted;

  /// 是否為首次遊玩
  final bool isFirstTime;

  /// 教學暫停中
  final bool isPaused;

  /// 錯誤訊息（如果有）
  final String? errorMessage;

  const TutorialState({
    this.isActive = false,
    this.currentLesson,
    this.currentStepIndex = 0,
    this.completedLessons = const {},
    this.highlightedElement,
    this.currentStep,
    this.isWaitingForAction = false,
    this.isDemonstrating = false,
    this.demoProgress = 0.0,
    this.showHint = false,
    this.isFullyCompleted = false,
    this.isFirstTime = true,
    this.isPaused = false,
    this.errorMessage,
  });

  /// 當前課程的步驟列表
  List<TutorialStep> get currentLessonSteps {
    if (currentLesson == null) return [];
    return TutorialData.getStepsForLesson(currentLesson!);
  }

  /// 當前課程的總步驟數
  int get totalStepsInLesson => currentLessonSteps.length;

  /// 是否為課程的最後一步
  bool get isLastStepInLesson =>
      currentStepIndex >= totalStepsInLesson - 1;

  /// 是否為課程的第一步
  bool get isFirstStepInLesson => currentStepIndex == 0;

  /// 課程進度百分比
  double get lessonProgress {
    if (totalStepsInLesson == 0) return 0.0;
    return (currentStepIndex + 1) / totalStepsInLesson;
  }

  /// 總進度百分比（所有課程）
  double get overallProgress {
    final totalLessons = TutorialLesson.values.length;
    final completed = completedLessons.length;
    if (currentLesson != null && !completedLessons.contains(currentLesson)) {
      return (completed + lessonProgress) / totalLessons;
    }
    return completed / totalLessons;
  }

  /// 下一個待完成的課程
  TutorialLesson? get nextLesson {
    for (final lesson in TutorialLesson.values) {
      if (!completedLessons.contains(lesson)) {
        return lesson;
      }
    }
    return null;
  }

  TutorialState copyWith({
    bool? isActive,
    TutorialLesson? currentLesson,
    int? currentStepIndex,
    Set<TutorialLesson>? completedLessons,
    String? highlightedElement,
    TutorialStep? currentStep,
    bool? isWaitingForAction,
    bool? isDemonstrating,
    double? demoProgress,
    bool? showHint,
    bool? isFullyCompleted,
    bool? isFirstTime,
    bool? isPaused,
    String? errorMessage,
    bool clearHighlight = false,
    bool clearCurrentStep = false,
    bool clearError = false,
  }) {
    return TutorialState(
      isActive: isActive ?? this.isActive,
      currentLesson: currentLesson ?? this.currentLesson,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      completedLessons: completedLessons ?? this.completedLessons,
      highlightedElement:
          clearHighlight ? null : (highlightedElement ?? this.highlightedElement),
      currentStep:
          clearCurrentStep ? null : (currentStep ?? this.currentStep),
      isWaitingForAction: isWaitingForAction ?? this.isWaitingForAction,
      isDemonstrating: isDemonstrating ?? this.isDemonstrating,
      demoProgress: demoProgress ?? this.demoProgress,
      showHint: showHint ?? this.showHint,
      isFullyCompleted: isFullyCompleted ?? this.isFullyCompleted,
      isFirstTime: isFirstTime ?? this.isFirstTime,
      isPaused: isPaused ?? this.isPaused,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ============================================================
// 教學系統控制器
// ============================================================

/// 教學系統控制器
class TutorialNotifier extends StateNotifier<TutorialState> {
  TutorialNotifier() : super(const TutorialState());

  // 持久化 key
  static const String _prefsKeyCompletedLessons = 'tutorial_completed_lessons';
  static const String _prefsKeyIsFirstTime = 'tutorial_is_first_time';
  static const String _prefsKeyFullyCompleted = 'tutorial_fully_completed';

  // 提示延遲計時器
  Timer? _hintTimer;

  // 演示計時器
  Timer? _demoTimer;

  // ============================================================
  // 初始化
  // ============================================================

  /// 初始化教學系統（從持久化存儲讀取狀態）
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 讀取已完成的課程
      final completedList = prefs.getStringList(_prefsKeyCompletedLessons) ?? [];
      final completedLessons = completedList
          .map((name) => TutorialLesson.values.firstWhere(
                (l) => l.name == name,
                orElse: () => TutorialLesson.introduction,
              ))
          .toSet();

      // 讀取其他狀態
      final isFirstTime = prefs.getBool(_prefsKeyIsFirstTime) ?? true;
      final isFullyCompleted = prefs.getBool(_prefsKeyFullyCompleted) ?? false;

      state = state.copyWith(
        completedLessons: completedLessons,
        isFirstTime: isFirstTime,
        isFullyCompleted: isFullyCompleted,
      );

      debugPrint('[Tutorial] Initialized: '
          'completedLessons=${completedLessons.length}, '
          'isFirstTime=$isFirstTime, '
          'isFullyCompleted=$isFullyCompleted');
    } catch (e) {
      debugPrint('[Tutorial] Failed to initialize: $e');
      state = state.copyWith(
        errorMessage: '載入教學進度失敗',
      );
    }
  }

  /// 保存進度到持久化存儲
  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setStringList(
        _prefsKeyCompletedLessons,
        state.completedLessons.map((l) => l.name).toList(),
      );
      await prefs.setBool(_prefsKeyIsFirstTime, state.isFirstTime);
      await prefs.setBool(_prefsKeyFullyCompleted, state.isFullyCompleted);

      debugPrint('[Tutorial] Progress saved');
    } catch (e) {
      debugPrint('[Tutorial] Failed to save progress: $e');
    }
  }

  // ============================================================
  // 教學控制
  // ============================================================

  /// 開始教學（從第一個未完成的課程開始）
  void startTutorial() {
    final nextLesson = state.nextLesson;
    if (nextLesson == null) {
      debugPrint('[Tutorial] All lessons completed, nothing to start');
      return;
    }

    startLesson(nextLesson);
  }

  /// 開始特定課程
  void startLesson(TutorialLesson lesson) {
    final steps = TutorialData.getStepsForLesson(lesson);
    if (steps.isEmpty) {
      debugPrint('[Tutorial] No steps for lesson: ${lesson.name}');
      return;
    }

    final firstStep = steps.first;

    state = state.copyWith(
      isActive: true,
      currentLesson: lesson,
      currentStepIndex: 0,
      currentStep: firstStep,
      highlightedElement: firstStep.targetElement,
      isWaitingForAction: firstStep.requiresPlayerAction,
      isDemonstrating: false,
      demoProgress: 0.0,
      showHint: false,
      isPaused: false,
      isFirstTime: false,
      clearError: true,
    );

    // 設置標記為非首次
    _saveProgress();

    // 啟動提示計時器
    _startHintTimer(firstStep.hintDelay);

    // 如果是演示步驟，啟動演示
    if (firstStep.isDemoStep) {
      _startDemonstration(firstStep);
    }

    debugPrint('[Tutorial] Started lesson: ${lesson.name}, step: ${firstStep.id}');
  }

  /// 進入下一步
  void nextStep() {
    if (!state.isActive || state.currentLesson == null) return;

    _cancelTimers();

    final steps = state.currentLessonSteps;
    final nextIndex = state.currentStepIndex + 1;

    if (nextIndex >= steps.length) {
      // 課程結束
      completeLesson();
      return;
    }

    final nextStepData = steps[nextIndex];

    state = state.copyWith(
      currentStepIndex: nextIndex,
      currentStep: nextStepData,
      highlightedElement: nextStepData.targetElement,
      isWaitingForAction: nextStepData.requiresPlayerAction,
      isDemonstrating: false,
      demoProgress: 0.0,
      showHint: false,
    );

    // 啟動提示計時器
    _startHintTimer(nextStepData.hintDelay);

    // 如果是演示步驟，啟動演示
    if (nextStepData.isDemoStep) {
      _startDemonstration(nextStepData);
    }

    debugPrint('[Tutorial] Advanced to step $nextIndex: ${nextStepData.id}');
  }

  /// 返回上一步
  void previousStep() {
    if (!state.isActive || state.currentStepIndex <= 0) return;

    _cancelTimers();

    final steps = state.currentLessonSteps;
    final prevIndex = state.currentStepIndex - 1;
    final prevStep = steps[prevIndex];

    state = state.copyWith(
      currentStepIndex: prevIndex,
      currentStep: prevStep,
      highlightedElement: prevStep.targetElement,
      isWaitingForAction: prevStep.requiresPlayerAction,
      isDemonstrating: false,
      demoProgress: 0.0,
      showHint: false,
    );

    _startHintTimer(prevStep.hintDelay);

    debugPrint('[Tutorial] Went back to step $prevIndex: ${prevStep.id}');
  }

  /// 跳過當前課程
  void skipLesson() {
    if (!state.isActive) return;

    _cancelTimers();

    debugPrint('[Tutorial] Skipped lesson: ${state.currentLesson?.name}');

    state = state.copyWith(
      isActive: false,
      clearCurrentStep: true,
      clearHighlight: true,
      isWaitingForAction: false,
      isDemonstrating: false,
      showHint: false,
    );
  }

  /// 跳過整個教學
  void skipTutorial() {
    _cancelTimers();

    debugPrint('[Tutorial] Tutorial skipped entirely');

    state = state.copyWith(
      isActive: false,
      isFirstTime: false,
      clearCurrentStep: true,
      clearHighlight: true,
      isWaitingForAction: false,
      isDemonstrating: false,
      showHint: false,
    );

    _saveProgress();
  }

  /// 完成當前課程
  void completeLesson() {
    if (state.currentLesson == null) return;

    _cancelTimers();

    final completedLesson = state.currentLesson!;
    final newCompletedLessons = {...state.completedLessons, completedLesson};
    final allCompleted =
        newCompletedLessons.length == TutorialLesson.values.length;

    debugPrint('[Tutorial] Completed lesson: ${completedLesson.name}');

    state = state.copyWith(
      isActive: false,
      completedLessons: newCompletedLessons,
      isFullyCompleted: allCompleted,
      clearCurrentStep: true,
      clearHighlight: true,
      isWaitingForAction: false,
      isDemonstrating: false,
      showHint: false,
    );

    _saveProgress();

    if (allCompleted) {
      debugPrint('[Tutorial] All lessons completed! Tutorial finished.');
    }
  }

  /// 檢查課程是否已完成
  bool isLessonCompleted(TutorialLesson lesson) {
    return state.completedLessons.contains(lesson);
  }

  /// 暫停教學
  void pauseTutorial() {
    if (!state.isActive) return;

    _cancelTimers();

    state = state.copyWith(isPaused: true);
    debugPrint('[Tutorial] Paused');
  }

  /// 恢復教學
  void resumeTutorial() {
    if (!state.isActive || !state.isPaused) return;

    state = state.copyWith(isPaused: false);

    // 重新啟動提示計時器
    if (state.currentStep != null) {
      _startHintTimer(state.currentStep!.hintDelay);
    }

    debugPrint('[Tutorial] Resumed');
  }

  // ============================================================
  // 玩家動作處理
  // ============================================================

  /// 玩家完成了要求的動作
  void onPlayerActionCompleted({
    required TutorialAction action,
    Map<String, dynamic>? data,
  }) {
    if (!state.isActive || !state.isWaitingForAction) return;

    final currentStep = state.currentStep;
    if (currentStep == null) return;

    // 檢查動作是否匹配
    if (currentStep.requiredAction != action) {
      debugPrint('[Tutorial] Action mismatch: expected ${currentStep.requiredAction}, got $action');
      return;
    }

    // 驗證動作（如果需要）
    if (currentStep.actionValidation != null && data != null) {
      if (!_validateAction(currentStep.actionValidation!, data)) {
        debugPrint('[Tutorial] Action validation failed');
        return;
      }
    }

    debugPrint('[Tutorial] Player completed action: ${action.name}');

    state = state.copyWith(isWaitingForAction: false);

    // 如果動作完成後需要自動進入下一步，稍後進入
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        nextStep();
      }
    });
  }

  /// 驗證動作
  bool _validateAction(
    Map<String, dynamic> validation,
    Map<String, dynamic> data,
  ) {
    for (final entry in validation.entries) {
      if (data[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  /// 更新高亮元素
  void setHighlightedElement(String? elementId) {
    state = state.copyWith(highlightedElement: elementId);
  }

  // ============================================================
  // 演示控制
  // ============================================================

  /// 啟動演示
  void _startDemonstration(TutorialStep step) {
    if (step.demoConfig == null) return;

    final duration = step.demoConfig!.duration;

    state = state.copyWith(
      isDemonstrating: true,
      demoProgress: 0.0,
    );

    // 演示進度計時器
    const updateInterval = Duration(milliseconds: 50);
    final totalTicks = duration ~/ updateInterval.inMilliseconds;
    var currentTick = 0;

    _demoTimer = Timer.periodic(updateInterval, (timer) {
      currentTick++;
      final progress = currentTick / totalTicks;

      if (progress >= 1.0) {
        timer.cancel();
        _onDemonstrationComplete();
      } else {
        state = state.copyWith(demoProgress: progress);
      }
    });

    debugPrint('[Tutorial] Started demonstration for ${step.id}');
  }

  /// 演示完成
  void _onDemonstrationComplete() {
    state = state.copyWith(
      isDemonstrating: false,
      demoProgress: 1.0,
    );

    debugPrint('[Tutorial] Demonstration complete');

    // 自動進入下一步
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        nextStep();
      }
    });
  }

  // ============================================================
  // 提示系統
  // ============================================================

  /// 啟動提示計時器
  void _startHintTimer(int delayMs) {
    _hintTimer?.cancel();

    if (delayMs <= 0) {
      state = state.copyWith(showHint: true);
      return;
    }

    _hintTimer = Timer(Duration(milliseconds: delayMs), () {
      if (mounted && state.isActive && !state.isPaused) {
        state = state.copyWith(showHint: true);
      }
    });
  }

  /// 顯示提示
  void showHint() {
    state = state.copyWith(showHint: true);
  }

  /// 隱藏提示
  void hideHint() {
    state = state.copyWith(showHint: false);
  }

  // ============================================================
  // 重置
  // ============================================================

  /// 重置教學進度（用於測試或用戶主動重置）
  Future<void> resetProgress() async {
    _cancelTimers();

    state = const TutorialState(
      isFirstTime: true,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKeyCompletedLessons);
      await prefs.setBool(_prefsKeyIsFirstTime, true);
      await prefs.setBool(_prefsKeyFullyCompleted, false);
      debugPrint('[Tutorial] Progress reset');
    } catch (e) {
      debugPrint('[Tutorial] Failed to reset progress: $e');
    }
  }

  // ============================================================
  // 清理
  // ============================================================

  void _cancelTimers() {
    _hintTimer?.cancel();
    _hintTimer = null;
    _demoTimer?.cancel();
    _demoTimer = null;
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }
}

// ============================================================
// Riverpod Providers
// ============================================================

/// 教學系統狀態 Provider
final tutorialProvider =
    StateNotifierProvider<TutorialNotifier, TutorialState>((ref) {
  return TutorialNotifier();
});

/// 教學是否正在進行中
final isTutorialActiveProvider = Provider<bool>((ref) {
  return ref.watch(tutorialProvider).isActive;
});

/// 當前教學步驟
final currentTutorialStepProvider = Provider<TutorialStep?>((ref) {
  return ref.watch(tutorialProvider).currentStep;
});

/// 當前高亮元素
final highlightedElementProvider = Provider<String?>((ref) {
  return ref.watch(tutorialProvider).highlightedElement;
});

/// 是否為首次遊玩
final isFirstTimePlayerProvider = Provider<bool>((ref) {
  return ref.watch(tutorialProvider).isFirstTime;
});

/// 教學進度百分比
final tutorialProgressProvider = Provider<double>((ref) {
  return ref.watch(tutorialProvider).overallProgress;
});

/// 是否應該顯示教學提示
final shouldShowTutorialProvider = Provider<bool>((ref) {
  final state = ref.watch(tutorialProvider);
  return state.isFirstTime && !state.isFullyCompleted;
});
