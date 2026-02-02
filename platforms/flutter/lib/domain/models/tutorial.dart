// 1812 國會風雲 - 教學系統模型
//
// 定義教學流程相關的資料模型

/// 教學動作類型
enum TutorialAction {
  /// 點擊按鈕
  tapButton,

  /// 選擇角色
  selectCharacter,

  /// 發送私訊
  sendMessage,

  /// 質詢玩家
  attackPlayer,

  /// 反駁攻擊
  defendAttack,

  /// 使用技能
  useSkill,

  /// 投票
  castVote,

  /// 查看資訊
  viewInfo,

  /// 結盟
  formAlliance,

  /// 確認/繼續
  confirm,

  /// 等待（觀看演示）
  wait,
}

/// TutorialAction 擴展
extension TutorialActionExtension on TutorialAction {
  /// 動作名稱
  String get displayName {
    switch (this) {
      case TutorialAction.tapButton:
        return '點擊按鈕';
      case TutorialAction.selectCharacter:
        return '選擇角色';
      case TutorialAction.sendMessage:
        return '發送私訊';
      case TutorialAction.attackPlayer:
        return '質詢玩家';
      case TutorialAction.defendAttack:
        return '反駁攻擊';
      case TutorialAction.useSkill:
        return '使用技能';
      case TutorialAction.castVote:
        return '投票';
      case TutorialAction.viewInfo:
        return '查看資訊';
      case TutorialAction.formAlliance:
        return '結盟';
      case TutorialAction.confirm:
        return '確認';
      case TutorialAction.wait:
        return '觀看';
    }
  }

  /// 動作提示文字
  String get hintText {
    switch (this) {
      case TutorialAction.tapButton:
        return '點擊高亮的按鈕繼續';
      case TutorialAction.selectCharacter:
        return '點擊選擇一個角色';
      case TutorialAction.sendMessage:
        return '輸入訊息並發送';
      case TutorialAction.attackPlayer:
        return '選擇一個對手並發起質詢';
      case TutorialAction.defendAttack:
        return '點擊「反駁」按鈕';
      case TutorialAction.useSkill:
        return '點擊技能按鈕使用技能';
      case TutorialAction.castVote:
        return '選擇一個選項並投票';
      case TutorialAction.viewInfo:
        return '點擊查看詳細資訊';
      case TutorialAction.formAlliance:
        return '向目標發送結盟請求';
      case TutorialAction.confirm:
        return '點擊確認繼續';
      case TutorialAction.wait:
        return '請觀看演示...';
    }
  }
}

/// 教學課程類型
enum TutorialLesson {
  /// 第一課：認識遊戲
  introduction,

  /// 第二課：學習質詢
  query,

  /// 第三課：學習反駁
  rebut,

  /// 第四課：使用技能
  skill,

  /// 第五課：完成投票
  vote,
}

/// TutorialLesson 擴展
extension TutorialLessonExtension on TutorialLesson {
  /// 課程名稱
  String get displayName {
    switch (this) {
      case TutorialLesson.introduction:
        return '認識遊戲';
      case TutorialLesson.query:
        return '學習質詢';
      case TutorialLesson.rebut:
        return '學習反駁';
      case TutorialLesson.skill:
        return '使用技能';
      case TutorialLesson.vote:
        return '完成投票';
    }
  }

  /// 課程編號
  int get lessonNumber {
    switch (this) {
      case TutorialLesson.introduction:
        return 1;
      case TutorialLesson.query:
        return 2;
      case TutorialLesson.rebut:
        return 3;
      case TutorialLesson.skill:
        return 4;
      case TutorialLesson.vote:
        return 5;
    }
  }

  /// 課程描述
  String get description {
    switch (this) {
      case TutorialLesson.introduction:
        return '了解遊戲的基本規則和系統';
      case TutorialLesson.query:
        return '學習如何在辯論中發起質詢';
      case TutorialLesson.rebut:
        return '學習如何防禦對手的攻擊';
      case TutorialLesson.skill:
        return '學習如何使用角色專屬技能';
      case TutorialLesson.vote:
        return '學習投票系統和勝利條件';
    }
  }

  /// 課程步驟數
  int get stepCount {
    switch (this) {
      case TutorialLesson.introduction:
        return 5;
      case TutorialLesson.query:
        return 4;
      case TutorialLesson.rebut:
        return 3;
      case TutorialLesson.skill:
        return 4;
      case TutorialLesson.vote:
        return 3;
    }
  }
}

/// 教學步驟
class TutorialStep {
  /// 步驟唯一 ID
  final String id;

  /// 所屬課程
  final TutorialLesson lesson;

  /// 步驟標題
  final String title;

  /// 步驟描述（可支援簡單的 markdown）
  final String description;

  /// 要高亮的 UI 元素 ID（可選）
  final String? targetElement;

  /// 需要玩家執行的動作（可選，null 表示只需點擊繼續）
  final TutorialAction? requiredAction;

  /// 動作驗證條件（例如：需要質詢特定目標）
  final Map<String, dynamic>? actionValidation;

  /// 完成回調數據（可選）
  final Map<String, dynamic>? onCompleteData;

  /// 是否可跳過
  final bool skippable;

  /// 提示延遲時間（毫秒，顯示提示前的等待時間）
  final int hintDelay;

  /// 額外的說明圖片（可選）
  final String? illustrationAsset;

  /// AI 演示配置（可選，用於演示 AI 行動）
  final TutorialDemoConfig? demoConfig;

  const TutorialStep({
    required this.id,
    required this.lesson,
    required this.title,
    required this.description,
    this.targetElement,
    this.requiredAction,
    this.actionValidation,
    this.onCompleteData,
    this.skippable = false,
    this.hintDelay = 3000,
    this.illustrationAsset,
    this.demoConfig,
  });

  /// 是否需要玩家執行特定動作
  bool get requiresPlayerAction => requiredAction != null;

  /// 是否為觀看演示步驟
  bool get isDemoStep => requiredAction == TutorialAction.wait;

  /// 步驟簡短 ID（不含課程前綴）
  String get shortId {
    final parts = id.split('_');
    return parts.length > 2 ? parts.sublist(2).join('_') : id;
  }

  TutorialStep copyWith({
    String? id,
    TutorialLesson? lesson,
    String? title,
    String? description,
    String? targetElement,
    TutorialAction? requiredAction,
    Map<String, dynamic>? actionValidation,
    Map<String, dynamic>? onCompleteData,
    bool? skippable,
    int? hintDelay,
    String? illustrationAsset,
    TutorialDemoConfig? demoConfig,
  }) {
    return TutorialStep(
      id: id ?? this.id,
      lesson: lesson ?? this.lesson,
      title: title ?? this.title,
      description: description ?? this.description,
      targetElement: targetElement ?? this.targetElement,
      requiredAction: requiredAction ?? this.requiredAction,
      actionValidation: actionValidation ?? this.actionValidation,
      onCompleteData: onCompleteData ?? this.onCompleteData,
      skippable: skippable ?? this.skippable,
      hintDelay: hintDelay ?? this.hintDelay,
      illustrationAsset: illustrationAsset ?? this.illustrationAsset,
      demoConfig: demoConfig ?? this.demoConfig,
    );
  }

  factory TutorialStep.fromJson(Map<String, dynamic> json) {
    return TutorialStep(
      id: json['id'] as String,
      lesson: TutorialLesson.values.firstWhere(
        (e) => e.name == json['lesson'],
        orElse: () => TutorialLesson.introduction,
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      targetElement: json['targetElement'] as String?,
      requiredAction: json['requiredAction'] != null
          ? TutorialAction.values.firstWhere(
              (e) => e.name == json['requiredAction'],
              orElse: () => TutorialAction.confirm,
            )
          : null,
      actionValidation: json['actionValidation'] as Map<String, dynamic>?,
      onCompleteData: json['onCompleteData'] as Map<String, dynamic>?,
      skippable: json['skippable'] as bool? ?? false,
      hintDelay: json['hintDelay'] as int? ?? 3000,
      illustrationAsset: json['illustrationAsset'] as String?,
      demoConfig: json['demoConfig'] != null
          ? TutorialDemoConfig.fromJson(
              json['demoConfig'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lesson': lesson.name,
      'title': title,
      'description': description,
      'targetElement': targetElement,
      'requiredAction': requiredAction?.name,
      'actionValidation': actionValidation,
      'onCompleteData': onCompleteData,
      'skippable': skippable,
      'hintDelay': hintDelay,
      'illustrationAsset': illustrationAsset,
      'demoConfig': demoConfig?.toJson(),
    };
  }
}

/// 教學演示配置
class TutorialDemoConfig {
  /// 演示的 AI 角色 ID
  final String aiCharacterId;

  /// 演示的動作類型
  final TutorialAction action;

  /// 演示目標（如果需要）
  final String? targetId;

  /// 演示持續時間（毫秒）
  final int duration;

  /// 是否顯示思考動畫
  final bool showThinking;

  /// 演示前的對話
  final String? preDialogue;

  /// 演示後的對話
  final String? postDialogue;

  const TutorialDemoConfig({
    required this.aiCharacterId,
    required this.action,
    this.targetId,
    this.duration = 2000,
    this.showThinking = true,
    this.preDialogue,
    this.postDialogue,
  });

  factory TutorialDemoConfig.fromJson(Map<String, dynamic> json) {
    return TutorialDemoConfig(
      aiCharacterId: json['aiCharacterId'] as String,
      action: TutorialAction.values.firstWhere(
        (e) => e.name == json['action'],
        orElse: () => TutorialAction.wait,
      ),
      targetId: json['targetId'] as String?,
      duration: json['duration'] as int? ?? 2000,
      showThinking: json['showThinking'] as bool? ?? true,
      preDialogue: json['preDialogue'] as String?,
      postDialogue: json['postDialogue'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aiCharacterId': aiCharacterId,
      'action': action.name,
      'targetId': targetId,
      'duration': duration,
      'showThinking': showThinking,
      'preDialogue': preDialogue,
      'postDialogue': postDialogue,
    };
  }
}

/// 教學進度
class TutorialProgress {
  /// 已完成的課程
  final Set<TutorialLesson> completedLessons;

  /// 當前課程
  final TutorialLesson? currentLesson;

  /// 當前步驟索引
  final int currentStepIndex;

  /// 是否已完成全部教學
  final bool isFullyCompleted;

  /// 上次進行時間
  final DateTime? lastPlayedAt;

  const TutorialProgress({
    this.completedLessons = const {},
    this.currentLesson,
    this.currentStepIndex = 0,
    this.isFullyCompleted = false,
    this.lastPlayedAt,
  });

  /// 已完成課程數
  int get completedCount => completedLessons.length;

  /// 總課程數
  int get totalLessons => TutorialLesson.values.length;

  /// 完成百分比
  double get completionPercentage => completedCount / totalLessons;

  /// 是否剛開始（沒有任何進度）
  bool get isNewPlayer =>
      completedLessons.isEmpty && currentLesson == null;

  /// 下一個待完成的課程
  TutorialLesson? get nextLesson {
    for (final lesson in TutorialLesson.values) {
      if (!completedLessons.contains(lesson)) {
        return lesson;
      }
    }
    return null;
  }

  TutorialProgress copyWith({
    Set<TutorialLesson>? completedLessons,
    TutorialLesson? currentLesson,
    int? currentStepIndex,
    bool? isFullyCompleted,
    DateTime? lastPlayedAt,
  }) {
    return TutorialProgress(
      completedLessons: completedLessons ?? this.completedLessons,
      currentLesson: currentLesson ?? this.currentLesson,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isFullyCompleted: isFullyCompleted ?? this.isFullyCompleted,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }

  factory TutorialProgress.fromJson(Map<String, dynamic> json) {
    return TutorialProgress(
      completedLessons: (json['completedLessons'] as List<dynamic>?)
              ?.map((e) => TutorialLesson.values.firstWhere(
                    (l) => l.name == e,
                    orElse: () => TutorialLesson.introduction,
                  ))
              .toSet() ??
          {},
      currentLesson: json['currentLesson'] != null
          ? TutorialLesson.values.firstWhere(
              (e) => e.name == json['currentLesson'],
              orElse: () => TutorialLesson.introduction,
            )
          : null,
      currentStepIndex: json['currentStepIndex'] as int? ?? 0,
      isFullyCompleted: json['isFullyCompleted'] as bool? ?? false,
      lastPlayedAt: json['lastPlayedAt'] != null
          ? DateTime.parse(json['lastPlayedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'completedLessons': completedLessons.map((e) => e.name).toList(),
      'currentLesson': currentLesson?.name,
      'currentStepIndex': currentStepIndex,
      'isFullyCompleted': isFullyCompleted,
      'lastPlayedAt': lastPlayedAt?.toIso8601String(),
    };
  }
}

/// 教學高亮配置
class TutorialHighlight {
  /// 目標元素 key
  final String targetKey;

  /// 高亮形狀
  final HighlightShape shape;

  /// 內邊距
  final double padding;

  /// 是否允許點擊高亮區域
  final bool allowTargetTap;

  /// 是否允許點擊外部區域
  final bool allowOutsideTap;

  const TutorialHighlight({
    required this.targetKey,
    this.shape = HighlightShape.rectangle,
    this.padding = 8.0,
    this.allowTargetTap = true,
    this.allowOutsideTap = false,
  });
}

/// 高亮形狀
enum HighlightShape {
  /// 矩形
  rectangle,

  /// 圓角矩形
  roundedRectangle,

  /// 圓形
  circle,

  /// 橢圓形
  oval,
}
