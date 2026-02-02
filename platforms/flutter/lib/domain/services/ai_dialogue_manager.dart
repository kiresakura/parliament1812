// 1812 國會風雲 - AI 對話管理器
//
// 負責管理 AI 角色的對話選擇和格式化：
// 1. 根據情境獲取適當的對話
// 2. 支援變數替換
// 3. 追蹤對話歷史避免重複

import 'dart:math';

import '../../data/local/ai_dialogues.dart';
import '../models/models.dart';
import 'solo_game_controller.dart';

// ============================================================
// 對話變數
// ============================================================

/// 對話變數 key 常數
class DialogueVariables {
  DialogueVariables._();

  /// 目標玩家名稱
  static const String target = 'target';

  /// 攻擊者名稱
  static const String attacker = 'attacker';

  /// 傷害數值
  static const String damage = 'damage';

  /// 當前聲望
  static const String reputation = 'reputation';

  /// 盟友名稱
  static const String allyName = 'allyName';

  /// 技能名稱
  static const String skillName = 'skillName';

  /// 選項名稱
  static const String optionName = 'optionName';

  /// 回合數
  static const String roundNumber = 'roundNumber';
}

// ============================================================
// 對話歷史記錄
// ============================================================

/// 對話歷史條目
class DialogueHistoryEntry {
  /// 角色 ID
  final String characterId;

  /// 情境類型
  final DialogueContext context;

  /// 對話索引
  final int dialogueIndex;

  /// 時間戳
  final DateTime timestamp;

  const DialogueHistoryEntry({
    required this.characterId,
    required this.context,
    required this.dialogueIndex,
    required this.timestamp,
  });
}

/// 對話歷史追蹤器
class DialogueHistoryTracker {
  /// 歷史記錄
  final List<DialogueHistoryEntry> _history = [];

  /// 每種情境最少使用不同台詞數量才能重複
  final int minRotation;

  /// 最大歷史記錄數
  final int maxHistory;

  DialogueHistoryTracker({
    this.minRotation = 3,
    this.maxHistory = 100,
  });

  /// 記錄使用的對話
  void recordDialogue({
    required String characterId,
    required DialogueContext context,
    required int dialogueIndex,
  }) {
    _history.add(DialogueHistoryEntry(
      characterId: characterId,
      context: context,
      dialogueIndex: dialogueIndex,
      timestamp: DateTime.now(),
    ));

    // 限制歷史大小
    if (_history.length > maxHistory) {
      _history.removeRange(0, _history.length - maxHistory);
    }
  }

  /// 獲取某角色某情境最近使用的對話索引
  List<int> getRecentIndices(String characterId, DialogueContext context) {
    return _history
        .where((e) => e.characterId == characterId && e.context == context)
        .map((e) => e.dialogueIndex)
        .toList();
  }

  /// 獲取可用的對話索引（排除最近使用的）
  List<int> getAvailableIndices({
    required String characterId,
    required DialogueContext context,
    required int totalCount,
  }) {
    final recentIndices = getRecentIndices(characterId, context);
    final allIndices = List.generate(totalCount, (i) => i);

    // 如果最近使用的數量已達到輪換要求，則只排除最近 minRotation - 1 個
    if (recentIndices.length >= minRotation - 1) {
      final toExclude = recentIndices.sublist(
        (recentIndices.length - minRotation + 1).clamp(0, recentIndices.length),
      );
      return allIndices.where((i) => !toExclude.contains(i)).toList();
    }

    // 排除所有最近使用的
    return allIndices.where((i) => !recentIndices.contains(i)).toList();
  }

  /// 清除歷史記錄
  void clear() {
    _history.clear();
  }

  /// 清除特定角色的歷史
  void clearForCharacter(String characterId) {
    _history.removeWhere((e) => e.characterId == characterId);
  }
}

// ============================================================
// AI 對話管理器
// ============================================================

/// AI 對話管理器
///
/// 負責管理 AI 角色的對話選擇，支援：
/// - 根據情境和遊戲狀態選擇適當對話
/// - 變數替換
/// - 避免對話重複
class AIDialogueManager {
  /// 隨機數生成器
  final Random _random;

  /// 對話歷史追蹤器
  final DialogueHistoryTracker _historyTracker;

  /// 是否啟用情緒修飾
  final bool enableEmotionalModifiers;

  /// 是否啟用動作描述
  final bool enableActionDescriptions;

  AIDialogueManager({
    Random? random,
    DialogueHistoryTracker? historyTracker,
    this.enableEmotionalModifiers = true,
    this.enableActionDescriptions = true,
  })  : _random = random ?? Random(),
        _historyTracker = historyTracker ?? DialogueHistoryTracker();

  // ============================================================
  // 核心對話獲取方法
  // ============================================================

  /// 獲取對話
  ///
  /// [characterId] 角色 ID
  /// [context] 對話情境
  /// [state] 遊戲狀態（可選，用於選擇更相關的對話）
  /// [targetId] 目標角色 ID（可選）
  /// [variables] 變數替換映射（可選）
  String getDialogue(
    String characterId,
    DialogueContext context, {
    GameState? state,
    String? targetId,
    Map<String, String>? variables,
  }) {
    // 獲取所有可用對話
    final allDialogues = AIDialogues.getAllDialogues(characterId, context);
    if (allDialogues.isEmpty) {
      return _getDefaultDialogue(context);
    }

    // 獲取可用索引（排除最近使用的）
    final availableIndices = _historyTracker.getAvailableIndices(
      characterId: characterId,
      context: context,
      totalCount: allDialogues.length,
    );

    // 選擇對話索引
    int selectedIndex;
    if (availableIndices.isEmpty) {
      // 所有對話都用過，隨機選擇
      selectedIndex = _random.nextInt(allDialogues.length);
    } else if (state != null) {
      // 根據遊戲狀態選擇更相關的對話
      selectedIndex = _selectContextualIndex(
        characterId: characterId,
        context: context,
        availableIndices: availableIndices,
        state: state,
      );
    } else {
      // 隨機選擇可用對話
      selectedIndex = availableIndices[_random.nextInt(availableIndices.length)];
    }

    // 記錄使用的對話
    _historyTracker.recordDialogue(
      characterId: characterId,
      context: context,
      dialogueIndex: selectedIndex,
    );

    // 獲取原始對話
    String dialogue = allDialogues[selectedIndex];

    // 嘗試使用針對特定目標的對話
    if (targetId != null && _shouldUseTargetedDialogue(context)) {
      final targetedDialogue = TargetedDialogues.getTargetedDialogue(
        characterId,
        targetId,
        _random,
      );
      if (targetedDialogue != null && _random.nextDouble() < 0.4) {
        dialogue = targetedDialogue;
      }
    }

    // 添加情緒修飾
    if (enableEmotionalModifiers && state != null) {
      final player = state.getPlayerById(characterId);
      if (player != null) {
        dialogue = DialogueModifiers.addEmotionalPrefix(
          dialogue,
          player.reputation,
        );
      }
    }

    // 添加動作描述
    if (enableActionDescriptions) {
      dialogue = DialogueModifiers.addActionDescription(dialogue, context);
    }

    // 變數替換
    if (variables != null && variables.isNotEmpty) {
      dialogue = formatDialogue(dialogue, variables);
    }

    return dialogue;
  }

  /// 根據遊戲事件獲取對話
  ///
  /// 自動根據事件類型判斷對話情境
  String getContextualDialogue(
    String characterId,
    GameEvent event, {
    GameState? state,
  }) {
    // 將遊戲事件映射到對話情境
    final context = _mapEventToContext(event);

    // 構建變數映射
    final variables = _buildVariablesFromEvent(event, state);

    return getDialogue(
      characterId,
      context,
      state: state,
      targetId: event.targetId,
      variables: variables,
    );
  }

  /// 格式化對話，替換變數
  ///
  /// 支援的變數格式：{variableName}
  /// 例如：「我要質詢 {target}！」→「我要質詢理查！」
  String formatDialogue(String template, Map<String, String> variables) {
    String result = template;

    for (final entry in variables.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }

    return result;
  }

  // ============================================================
  // 事件到情境映射
  // ============================================================

  /// 將遊戲事件映射到對話情境
  DialogueContext _mapEventToContext(GameEvent event) {
    switch (event.type) {
      case GameEventType.gameStart:
        return DialogueContext.greeting;

      case GameEventType.playerQuery:
        // 如果是這個角色發起的攻擊
        return DialogueContext.attacking;

      case GameEventType.playerRebut:
        return DialogueContext.defending;

      case GameEventType.playerSkill:
        return DialogueContext.usingSkill;

      case GameEventType.playerVote:
        return DialogueContext.voting;

      case GameEventType.allianceRequest:
        return DialogueContext.allyRequest;

      case GameEventType.allianceAccepted:
        return DialogueContext.allyAccept;

      case GameEventType.allianceRejected:
        return DialogueContext.allyReject;

      case GameEventType.betrayal:
        return DialogueContext.betraying;

      case GameEventType.reputationChange:
        final change = event.data['change'] as int? ?? 0;
        if (change < 0) {
          return DialogueContext.beingAttacked;
        }
        return DialogueContext.greeting;

      case GameEventType.playerEliminated:
        return DialogueContext.losing;

      case GameEventType.gameEnd:
        final isWinner = event.data['isWinner'] as bool? ?? false;
        return isWinner ? DialogueContext.winning : DialogueContext.losing;

      case GameEventType.phaseChange:
        final phase = event.data['phase'] as String?;
        if (phase == 'debate') {
          return DialogueContext.greeting;
        }
        return DialogueContext.greeting;

      default:
        return DialogueContext.greeting;
    }
  }

  /// 從事件構建變數映射
  Map<String, String> _buildVariablesFromEvent(
    GameEvent event,
    GameState? state,
  ) {
    final variables = <String, String>{};

    // 目標名稱
    if (event.targetId != null && state != null) {
      final target = state.getPlayerById(event.targetId!);
      if (target != null) {
        variables[DialogueVariables.target] = target.name;
      }
    }

    // 攻擊者名稱
    if (state != null) {
      final attacker = state.getPlayerById(event.actorId);
      if (attacker != null) {
        variables[DialogueVariables.attacker] = attacker.name;
      }
    }

    // 傷害數值
    final damage = event.data['damage'];
    if (damage != null) {
      variables[DialogueVariables.damage] = damage.toString();
    }

    // 聲望值
    final reputation = event.data['reputation'];
    if (reputation != null) {
      variables[DialogueVariables.reputation] = reputation.toString();
    }

    // 盟友名稱
    final allyId = event.data['allyId'] as String?;
    if (allyId != null && state != null) {
      final ally = state.getPlayerById(allyId);
      if (ally != null) {
        variables[DialogueVariables.allyName] = ally.name;
      }
    }

    // 技能名稱
    final skillName = event.data['skillName'] as String?;
    if (skillName != null) {
      variables[DialogueVariables.skillName] = skillName;
    }

    // 選項名稱
    final optionName = event.data['optionName'] as String?;
    if (optionName != null) {
      variables[DialogueVariables.optionName] = optionName;
    }

    // 回合數
    final roundNumber = event.data['round'];
    if (roundNumber != null) {
      variables[DialogueVariables.roundNumber] = roundNumber.toString();
    }

    return variables;
  }

  // ============================================================
  // 輔助方法
  // ============================================================

  /// 根據遊戲狀態選擇更相關的對話索引
  int _selectContextualIndex({
    required String characterId,
    required DialogueContext context,
    required List<int> availableIndices,
    required GameState state,
  }) {
    // 根據不同情境使用不同選擇策略
    switch (context) {
      case DialogueContext.lowHealth:
        // 聲望越低，傾向選擇更激烈的對話（較高索引）
        final player = state.getPlayerById(characterId);
        if (player != null && player.reputation < 30) {
          // 傾向選擇後面的對話
          final sortedIndices = List<int>.from(availableIndices)..sort();
          if (sortedIndices.isNotEmpty) {
            return sortedIndices.last;
          }
        }
        break;

      case DialogueContext.winning:
      case DialogueContext.losing:
        // 根據回合數選擇（後期用更激烈的對話）
        if (state.currentRound >= state.totalRounds) {
          final sortedIndices = List<int>.from(availableIndices)..sort();
          if (sortedIndices.isNotEmpty) {
            return sortedIndices.last;
          }
        }
        break;

      case DialogueContext.attacking:
      case DialogueContext.defending:
        // 辯論階段根據時間壓力選擇
        if (state.timeRemaining < 60) {
          // 時間緊迫，選擇更短促的對話（較低索引通常較短）
          final sortedIndices = List<int>.from(availableIndices)..sort();
          if (sortedIndices.isNotEmpty) {
            return sortedIndices.first;
          }
        }
        break;

      default:
        break;
    }

    // 預設隨機選擇
    return availableIndices[_random.nextInt(availableIndices.length)];
  }

  /// 判斷是否應該使用針對特定目標的對話
  bool _shouldUseTargetedDialogue(DialogueContext context) {
    return context == DialogueContext.attacking ||
        context == DialogueContext.taunt ||
        context == DialogueContext.betraying;
  }

  /// 獲取預設對話
  String _getDefaultDialogue(DialogueContext context) {
    switch (context) {
      case DialogueContext.greeting:
        return '各位議員，請聽我說。';
      case DialogueContext.attacking:
        return '我必須質疑這個觀點！';
      case DialogueContext.defending:
        return '這種指控毫無根據！';
      case DialogueContext.beingAttacked:
        return '你這是無理取鬧！';
      case DialogueContext.allyRequest:
        return '我們可以合作嗎？';
      case DialogueContext.allyAccept:
        return '我接受你的提議。';
      case DialogueContext.allyReject:
        return '恐怕我無法同意。';
      case DialogueContext.betraying:
        return '抱歉，這是為了更大的利益。';
      case DialogueContext.usingSkill:
        return '看我的！';
      case DialogueContext.voting:
        return '我已做出選擇。';
      case DialogueContext.winning:
        return '正義終將獲勝。';
      case DialogueContext.losing:
        return '這還沒結束...';
      case DialogueContext.lowHealth:
        return '局勢對我不利...';
      case DialogueContext.taunt:
        return '你太天真了。';
    }
  }

  // ============================================================
  // 批量對話生成
  // ============================================================

  /// 為多個角色生成對話（例如辯論開場）
  Map<String, String> getDialoguesForCharacters(
    List<String> characterIds,
    DialogueContext context, {
    GameState? state,
  }) {
    final result = <String, String>{};
    for (final characterId in characterIds) {
      result[characterId] = getDialogue(
        characterId,
        context,
        state: state,
      );
    }
    return result;
  }

  /// 生成對話序列（例如連續攻防）
  List<DialogueSequenceEntry> generateDialogueSequence({
    required List<DialogueSequenceStep> steps,
    GameState? state,
  }) {
    final result = <DialogueSequenceEntry>[];

    for (final step in steps) {
      final dialogue = getDialogue(
        step.characterId,
        step.context,
        state: state,
        targetId: step.targetId,
        variables: step.variables,
      );

      result.add(DialogueSequenceEntry(
        characterId: step.characterId,
        dialogue: dialogue,
        context: step.context,
        delay: step.delay,
      ));
    }

    return result;
  }

  // ============================================================
  // 歷史管理
  // ============================================================

  /// 清除所有對話歷史
  void clearHistory() {
    _historyTracker.clear();
  }

  /// 清除特定角色的對話歷史
  void clearHistoryForCharacter(String characterId) {
    _historyTracker.clearForCharacter(characterId);
  }
}

// ============================================================
// 輔助類型
// ============================================================

/// 對話序列步驟
class DialogueSequenceStep {
  /// 角色 ID
  final String characterId;

  /// 對話情境
  final DialogueContext context;

  /// 目標 ID（可選）
  final String? targetId;

  /// 變數（可選）
  final Map<String, String>? variables;

  /// 延遲時間（毫秒）
  final int delay;

  const DialogueSequenceStep({
    required this.characterId,
    required this.context,
    this.targetId,
    this.variables,
    this.delay = 0,
  });
}

/// 對話序列條目
class DialogueSequenceEntry {
  /// 角色 ID
  final String characterId;

  /// 對話內容
  final String dialogue;

  /// 對話情境
  final DialogueContext context;

  /// 延遲時間（毫秒）
  final int delay;

  const DialogueSequenceEntry({
    required this.characterId,
    required this.dialogue,
    required this.context,
    required this.delay,
  });
}

// ============================================================
// 對話工廠
// ============================================================

/// 對話構建器 - 用於快速構建帶變數的對話
class DialogueBuilder {
  final AIDialogueManager _manager;
  final String _characterId;
  DialogueContext? _context;
  String? _targetId;
  GameState? _state;
  final Map<String, String> _variables = {};

  DialogueBuilder(this._manager, this._characterId);

  /// 設置情境
  DialogueBuilder context(DialogueContext context) {
    _context = context;
    return this;
  }

  /// 設置目標
  DialogueBuilder target(String targetId, {String? targetName}) {
    _targetId = targetId;
    if (targetName != null) {
      _variables[DialogueVariables.target] = targetName;
    }
    return this;
  }

  /// 設置遊戲狀態
  DialogueBuilder withState(GameState state) {
    _state = state;
    return this;
  }

  /// 設置傷害值
  DialogueBuilder damage(int value) {
    _variables[DialogueVariables.damage] = value.toString();
    return this;
  }

  /// 設置聲望值
  DialogueBuilder reputation(int value) {
    _variables[DialogueVariables.reputation] = value.toString();
    return this;
  }

  /// 設置盟友名稱
  DialogueBuilder ally(String name) {
    _variables[DialogueVariables.allyName] = name;
    return this;
  }

  /// 設置自定義變數
  DialogueBuilder variable(String key, String value) {
    _variables[key] = value;
    return this;
  }

  /// 構建對話
  String build() {
    if (_context == null) {
      throw StateError('必須設置 context');
    }

    return _manager.getDialogue(
      _characterId,
      _context!,
      state: _state,
      targetId: _targetId,
      variables: _variables.isNotEmpty ? _variables : null,
    );
  }
}

/// AIDialogueManager 擴展方法
extension AIDialogueManagerExtension on AIDialogueManager {
  /// 創建對話構建器
  DialogueBuilder forCharacter(String characterId) {
    return DialogueBuilder(this, characterId);
  }
}
