// 1812 國會風雲 - AI 決策引擎
//
// 這個引擎負責 AI 玩家的所有決策邏輯，包括：
// 1. 分析當前局勢
// 2. 選擇適當策略
// 3. 生成可能行動
// 4. 評分並選擇最優行動

import 'dart:math';

import '../models/models.dart';
import 'ai_character_behaviors.dart';

/// AI 策略類型
/// 根據 AI 個性和當前局勢決定的行動策略
enum AIStrategy {
  /// 全力攻擊 - 針對威脅最高的敵人發起質詢
  allOutAttack,

  /// 選擇性攻擊 - 攻擊最弱的敵人以快速擊敗
  targetWeakest,

  /// 防禦反擊 - 優先防禦，有機會時反擊
  defensiveCounter,

  /// 全面防禦 - 聲望危急，全力保護自己
  turtleDefense,

  /// 積極外交 - 主動尋求盟友
  activeDiplomacy,

  /// 維持盟友 - 與現有盟友保持關係
  maintainAllies,

  /// 伺機背叛 - 等待最佳時機背刺盟友
  waitForBetrayal,

  /// 混亂製造 - 製造混亂，從中獲利
  createChaos,

  /// 觀望等待 - 不主動行動，觀察局勢
  waitAndSee,
}

/// AI 策略擴展方法
extension AIStrategyExtension on AIStrategy {
  /// 策略名稱
  String get displayName {
    switch (this) {
      case AIStrategy.allOutAttack:
        return '全力攻擊';
      case AIStrategy.targetWeakest:
        return '選擇性攻擊';
      case AIStrategy.defensiveCounter:
        return '防禦反擊';
      case AIStrategy.turtleDefense:
        return '全面防禦';
      case AIStrategy.activeDiplomacy:
        return '積極外交';
      case AIStrategy.maintainAllies:
        return '維持盟友';
      case AIStrategy.waitForBetrayal:
        return '伺機背叛';
      case AIStrategy.createChaos:
        return '混亂製造';
      case AIStrategy.waitAndSee:
        return '觀望等待';
    }
  }

  /// 是否為攻擊性策略
  bool get isAggressive {
    return this == AIStrategy.allOutAttack ||
        this == AIStrategy.targetWeakest ||
        this == AIStrategy.createChaos;
  }

  /// 是否為防禦性策略
  bool get isDefensive {
    return this == AIStrategy.defensiveCounter ||
        this == AIStrategy.turtleDefense ||
        this == AIStrategy.waitAndSee;
  }

  /// 是否為外交性策略
  bool get isDiplomatic {
    return this == AIStrategy.activeDiplomacy ||
        this == AIStrategy.maintainAllies;
  }
}

/// AI 決策引擎
///
/// 核心職責：
/// 1. 分析遊戲局勢
/// 2. 根據 AI 個性選擇策略
/// 3. 生成並評估可能的行動
/// 4. 根據難度決定最終行動
class AIDecisionEngine {
  /// 隨機數生成器
  final Random _random;

  /// 是否啟用調試日誌
  final bool enableDebugLogging;

  /// 玩家角色映射（用於角色專屬行為查詢）
  Map<String, Role?> _playerRoles = {};

  AIDecisionEngine({
    Random? random,
    this.enableDebugLogging = false,
  }) : _random = random ?? Random();

  /// 設置玩家角色映射
  ///
  /// 在遊戲開始時調用，提供角色資訊給 AI 決策參考
  void setPlayerRoles(Map<String, Role?> roles) {
    _playerRoles = roles;
  }

  // ============================================================
  // 核心決策流程
  // ============================================================

  /// 主決策方法 - 整合所有步驟，返回最終決策
  ///
  /// 決策流程：
  /// 1. 分析當前局勢
  /// 2. 獲取角色專屬行為
  /// 3. 根據個性和局勢選擇策略
  /// 4. 生成所有可能的行動
  /// 5. 根據策略和角色行為對行動評分
  /// 6. 根據難度決定是否選擇最優解
  AIDecision decide(AIPlayer ai, GameState state) {
    _log('=== AI 決策開始: ${ai.displayName} ===');

    // 步驟 1: 分析局勢
    final situation = analyzeSituation(state, ai);
    _log('局勢分析: 自身狀態=${situation.selfStatus.toStringAsFixed(1)}, '
        '威脅=${situation.threatLevel.toStringAsFixed(1)}, '
        '機會=${situation.opportunityLevel.toStringAsFixed(1)}');

    // 步驟 2: 獲取角色專屬行為
    final characterBehavior = CharacterBehaviorManager.getBehavior(ai.roleId);
    if (characterBehavior != null) {
      _log('角色行為: ${characterBehavior.characterName}');
    }

    // 步驟 3: 選擇策略
    final strategy = selectStrategy(ai.personality, situation);
    _log('選擇策略: ${strategy.displayName}');

    // 步驟 4: 生成可能行動（考慮角色偏好）
    final possibleActions = _generatePossibleActions(ai, state);
    _log('可能行動數: ${possibleActions.length}');

    if (possibleActions.isEmpty) {
      _log('無可用行動，選擇等待');
      return AIDecision.wait(reasoning: '無可用行動');
    }

    // 步驟 5: 對行動評分（包含角色專屬加成）
    final scoredActions = _scoreActions(
      possibleActions,
      strategy,
      ai,
      state,
      situation,
      characterBehavior: characterBehavior,
    );
    _log('評分完成，最高分: ${scoredActions.first.finalScore.toStringAsFixed(1)}');

    // 步驟 6: 根據難度決定最終選擇
    final selectedAction = _selectActionByDifficulty(scoredActions, ai.difficulty);
    _log('最終選擇: ${selectedAction.actionType.displayName}, '
        '目標: ${selectedAction.targetId ?? "無"}');

    // 轉換為 AIDecision
    return AIDecision(
      actionType: selectedAction.actionType,
      targetId: selectedAction.targetId,
      parameters: _extractParameters(selectedAction, possibleActions),
      score: selectedAction.finalScore,
      reasoning: _generateReasoning(
        selectedAction,
        strategy,
        situation,
        characterBehavior: characterBehavior,
      ),
      timestamp: DateTime.now(),
    );
  }

  // ============================================================
  // 局勢分析
  // ============================================================

  /// 分析當前遊戲局勢
  ///
  /// 評估要素：
  /// 1. 自身狀態（聲望、資源、狀態效果）
  /// 2. 各玩家威脅度
  /// 3. 陣營形勢
  /// 4. 潛在盟友和敵人
  SituationAnalysis analyzeSituation(GameState state, AIPlayer ai) {
    // === 評估自身狀態 (0-100) ===
    final selfStatus = _evaluateSelfStatus(ai);

    // === 計算各玩家威脅度 ===
    final playerThreats = <String, double>{};
    final alivePlayers = state.players.where((p) => p.isAlive && p.id != ai.id);

    for (final player in alivePlayers) {
      playerThreats[player.id] = _calculateThreatLevel(player, ai, state);
    }

    // === 識別威脅、盟友、目標 ===
    final mainThreats = _identifyMainThreats(playerThreats);
    final potentialAllies = _identifyPotentialAllies(ai, state.players, playerThreats);
    final weakTargets = _identifyWeakTargets(state.players, ai);
    final strongPlayers = _identifyStrongPlayers(state.players, ai);

    // === 計算整體威脅等級 (0-100) ===
    double overallThreat = 0;
    if (playerThreats.isNotEmpty) {
      final avgThreat = playerThreats.values.reduce((a, b) => a + b) / playerThreats.length;
      final maxThreat = playerThreats.values.reduce(max);
      overallThreat = (avgThreat * 0.4 + maxThreat * 0.6).clamp(0, 100);
    }

    // === 計算機會等級 (0-100) ===
    final opportunityLevel = _calculateOpportunityLevel(ai, state, weakTargets);

    // === 建議策略 ===
    final suggestedStrategy = _suggestStrategy(
      selfStatus: selfStatus,
      threatLevel: overallThreat,
      opportunityLevel: opportunityLevel,
      hasAllies: ai.allies.isNotEmpty,
      personality: ai.personality,
    );

    return SituationAnalysis(
      timestamp: DateTime.now(),
      selfStatus: selfStatus,
      threatLevel: overallThreat,
      opportunityLevel: opportunityLevel,
      mainThreats: mainThreats,
      potentialAllies: potentialAllies,
      weakTargets: weakTargets,
      strongPlayers: strongPlayers,
      strategy: suggestedStrategy,
      analysisNotes: _generateAnalysisNotes(selfStatus, overallThreat, opportunityLevel),
    );
  }

  /// 評估自身狀態 (0-100)
  double _evaluateSelfStatus(AIPlayer ai) {
    double status = 0;

    // 聲望貢獻 (0-50 分)
    // 聲望 100 = 50分, 聲望 50 = 25分, 聲望 0 = 0分
    status += (ai.reputation / 100 * 50).clamp(0, 50);

    // 資源貢獻 (0-20 分)
    final resourceScore = (ai.gold / 50 * 5) + // 金幣
        (ai.intel / 10 * 5) + // 情報
        (ai.favor / 10 * 10); // 人情（更重要）
    status += resourceScore.clamp(0, 20);

    // 盟友貢獻 (0-15 分)
    status += (ai.allies.length * 5).clamp(0, 15);

    // 狀態效果 (±15 分)
    for (final effect in ai.player.statusEffects) {
      if (effect.isBuff) {
        status += 5;
      } else {
        status -= 5;
      }
    }

    return status.clamp(0, 100);
  }

  /// 計算單個玩家對 AI 的威脅度 (0-100)
  double _calculateThreatLevel(Player player, AIPlayer ai, GameState state) {
    double threat = 0;

    // === 聲望威脅 (0-40) ===
    // 聲望越高，威脅越大
    threat += (player.reputation / 100 * 40).clamp(0, 40);

    // === 關係威脅 (0-30) ===
    // 如果對方對我有敵意（負面關係分數），威脅更高
    final relationScore = ai.getRelationshipScore(player.id);
    if (relationScore < 0) {
      threat += (relationScore.abs() / 100 * 30).clamp(0, 30);
    }

    // === 位置威脅 (0-20) ===
    // 如果對方是當前發言者或即將發言，威脅更高
    if (state.currentSpeakerId == player.id) {
      threat += 15;
    }
    if (state.speakingOrder.isNotEmpty) {
      final index = state.speakingOrder.indexOf(player.id);
      if (index >= 0 && index < 3) {
        threat += (10 - index * 3);
      }
    }

    // === 資源威脅 (0-10) ===
    // 對方資源越多，潛在威脅越大
    threat += ((player.gold + player.intel * 2) / 30 * 10).clamp(0, 10);

    return threat.clamp(0, 100);
  }

  /// 識別主要威脅（威脅度 > 50 的玩家）
  List<String> _identifyMainThreats(Map<String, double> playerThreats) {
    return playerThreats.entries
        .where((e) => e.value > 50)
        .map((e) => e.key)
        .toList()
      ..sort((a, b) => playerThreats[b]!.compareTo(playerThreats[a]!));
  }

  /// 識別潛在盟友
  List<String> _identifyPotentialAllies(
    AIPlayer ai,
    List<Player> players,
    Map<String, double> playerThreats,
  ) {
    final potentialAllies = <String>[];

    for (final player in players) {
      if (player.id == ai.id || !player.isAlive) continue;
      if (ai.allies.contains(player.id)) continue; // 已經是盟友

      // 威脅度低且關係分數不太負面的玩家是潛在盟友
      final threat = playerThreats[player.id] ?? 50;
      final relation = ai.getRelationshipScore(player.id);

      if (threat < 40 && relation > -20) {
        potentialAllies.add(player.id);
      }
    }

    return potentialAllies;
  }

  /// 識別弱勢目標（適合攻擊）
  List<String> _identifyWeakTargets(List<Player> players, AIPlayer ai) {
    return players
        .where((p) =>
            p.id != ai.id &&
            p.isAlive &&
            p.reputation < 40 && // 聲望低
            !ai.allies.contains(p.id)) // 不是盟友
        .map((p) => p.id)
        .toList();
  }

  /// 識別強勢玩家
  List<String> _identifyStrongPlayers(List<Player> players, AIPlayer ai) {
    return players
        .where((p) =>
            p.id != ai.id &&
            p.isAlive &&
            p.reputation > 70) // 聲望高
        .map((p) => p.id)
        .toList();
  }

  /// 計算機會等級
  double _calculateOpportunityLevel(
    AIPlayer ai,
    GameState state,
    List<String> weakTargets,
  ) {
    double opportunity = 30; // 基礎機會

    // 弱勢目標越多，機會越好
    opportunity += weakTargets.length * 10;

    // 自己聲望高，機會更好
    if (ai.reputation > 70) {
      opportunity += 20;
    }

    // 有盟友支持，機會更好
    opportunity += ai.allies.length * 5;

    // 有足夠資源執行計劃
    if (ai.gold >= 10 || ai.intel >= 2) {
      opportunity += 10;
    }

    return opportunity.clamp(0, 100);
  }

  /// 根據局勢建議策略
  SuggestedStrategy _suggestStrategy({
    required double selfStatus,
    required double threatLevel,
    required double opportunityLevel,
    required bool hasAllies,
    required AIPersonality personality,
  }) {
    // 緊急情況：聲望危急
    if (selfStatus < 25) {
      return SuggestedStrategy.survival;
    }

    // 根據個性調整
    switch (personality) {
      case AIPersonality.aggressive:
        if (opportunityLevel > 60) {
          return SuggestedStrategy.aggressive;
        }
        return threatLevel > 50
            ? SuggestedStrategy.balanced
            : SuggestedStrategy.aggressive;

      case AIPersonality.defensive:
        if (threatLevel > 60) {
          return SuggestedStrategy.defensive;
        }
        return selfStatus > 60
            ? SuggestedStrategy.balanced
            : SuggestedStrategy.defensive;

      case AIPersonality.diplomatic:
        if (!hasAllies) {
          return SuggestedStrategy.diplomatic;
        }
        return SuggestedStrategy.balanced;

      case AIPersonality.cunning:
        if (hasAllies && opportunityLevel > 50) {
          return SuggestedStrategy.betrayal;
        }
        return SuggestedStrategy.opportunistic;
    }
  }

  /// 生成分析備註
  String _generateAnalysisNotes(
    double selfStatus,
    double threatLevel,
    double opportunityLevel,
  ) {
    final notes = <String>[];

    if (selfStatus < 30) {
      notes.add('聲望危急');
    } else if (selfStatus > 70) {
      notes.add('狀態良好');
    }

    if (threatLevel > 70) {
      notes.add('威脅嚴重');
    } else if (threatLevel < 30) {
      notes.add('相對安全');
    }

    if (opportunityLevel > 60) {
      notes.add('機會大好');
    }

    return notes.isEmpty ? '局勢平穩' : notes.join(', ');
  }

  // ============================================================
  // 策略選擇
  // ============================================================

  /// 根據個性和局勢選擇具體策略
  AIStrategy selectStrategy(AIPersonality personality, SituationAnalysis situation) {
    // === 緊急情況優先處理 ===
    if (situation.selfStatus < 25) {
      return AIStrategy.turtleDefense; // 聲望危急，全力防禦
    }

    // === 根據個性選擇策略 ===
    switch (personality) {
      case AIPersonality.aggressive:
        return _selectAggressiveStrategy(situation);

      case AIPersonality.defensive:
        return _selectDefensiveStrategy(situation);

      case AIPersonality.diplomatic:
        return _selectDiplomaticStrategy(situation);

      case AIPersonality.cunning:
        return _selectCunningStrategy(situation);
    }
  }

  /// 激進型策略選擇
  AIStrategy _selectAggressiveStrategy(SituationAnalysis situation) {
    // 機會好就全力攻擊
    if (situation.opportunityLevel > 60 && situation.weakTargets.isNotEmpty) {
      return AIStrategy.targetWeakest;
    }

    // 威脅高時選擇防禦反擊
    if (situation.threatLevel > 60) {
      return AIStrategy.defensiveCounter;
    }

    // 預設全力攻擊
    return AIStrategy.allOutAttack;
  }

  /// 防守型策略選擇
  AIStrategy _selectDefensiveStrategy(SituationAnalysis situation) {
    // 威脅高時全面防禦
    if (situation.threatLevel > 50) {
      return AIStrategy.turtleDefense;
    }

    // 狀態好且威脅低時可以反擊
    if (situation.selfStatus > 60 && situation.threatLevel < 30) {
      return AIStrategy.defensiveCounter;
    }

    // 沒有明顯威脅就觀望
    return AIStrategy.waitAndSee;
  }

  /// 外交型策略選擇
  AIStrategy _selectDiplomaticStrategy(SituationAnalysis situation) {
    // 沒有盟友時積極外交
    if (situation.potentialAllies.isNotEmpty) {
      return AIStrategy.activeDiplomacy;
    }

    // 有盟友時維持關係
    return AIStrategy.maintainAllies;
  }

  /// 狡詐型策略選擇
  AIStrategy _selectCunningStrategy(SituationAnalysis situation) {
    // 有盟友且機會好時考慮背叛
    if (situation.opportunityLevel > 60 && situation.selfStatus > 50) {
      return AIStrategy.waitForBetrayal;
    }

    // 局勢混亂時製造更多混亂
    if (situation.threatLevel > 40 && situation.opportunityLevel > 40) {
      return AIStrategy.createChaos;
    }

    // 預設觀望等待
    return AIStrategy.waitAndSee;
  }

  // ============================================================
  // 行動生成
  // ============================================================

  /// 根據當前階段生成所有可能的行動（內部方法）
  List<_PossibleAction> _generatePossibleActions(AIPlayer ai, GameState state) {
    final actions = <_PossibleAction>[];

    switch (state.phase) {
      case GamePhase.conspiracy:
        // 密謀階段：私訊、結盟請求
        actions.addAll(_generateConspiracyActions(ai, state));
        break;

      case GamePhase.debate:
        // 辯論階段：質詢、反駁、使用技能
        actions.addAll(_generateDebateActions(ai, state));
        break;

      case GamePhase.voting:
        // 投票階段：選擇 A/B/C
        actions.addAll(_generateVotingActions(ai, state));
        break;

      default:
        // 其他階段：等待
        actions.add(_PossibleAction(
          actionType: AIActionType.wait,
          data: {},
        ));
    }

    // 總是可以選擇等待
    if (actions.every((a) => a.actionType != AIActionType.wait)) {
      actions.add(_PossibleAction(
        actionType: AIActionType.wait,
        data: {},
      ));
    }

    return actions;
  }

  /// 生成密謀階段行動
  List<_PossibleAction> _generateConspiracyActions(AIPlayer ai, GameState state) {
    final actions = <_PossibleAction>[];
    final otherPlayers = state.players.where((p) => p.id != ai.id && p.isAlive);

    for (final player in otherPlayers) {
      // 結盟請求（對非盟友）
      if (!ai.allies.contains(player.id)) {
        actions.add(_PossibleAction(
          actionType: AIActionType.ally,
          targetId: player.id,
          data: {'message': '願意結盟嗎？'},
        ));
      }

      // 私訊發言
      actions.add(_PossibleAction(
        actionType: AIActionType.speak,
        targetId: player.id,
        data: {'isPublic': false, 'content': '...'},
      ));
    }

    return actions;
  }

  /// 生成辯論階段行動
  List<_PossibleAction> _generateDebateActions(AIPlayer ai, GameState state) {
    final actions = <_PossibleAction>[];
    final otherPlayers = state.players.where((p) => p.id != ai.id && p.isAlive);

    // === 質詢攻擊 ===
    // 需要消耗 10 聲望
    if (ai.reputation > 15) {
      for (final player in otherPlayers) {
        actions.add(_PossibleAction(
          actionType: AIActionType.attack,
          targetId: player.id,
          data: {
            'damage': 15,
            'reputationCost': 10,
          },
        ));
      }
    }

    // === 反駁防禦 ===
    // 需要消耗 5 聲望
    if (ai.reputation > 10) {
      actions.add(_PossibleAction(
        actionType: AIActionType.defend,
        data: {
          'reputationCost': 5,
        },
      ));
    }

    // === 背叛盟友 ===
    // 只能背叛盟友
    for (final allyId in ai.allies) {
      final ally = state.players.where((p) => p.id == allyId).firstOrNull;
      if (ally != null && ally.isAlive) {
        actions.add(_PossibleAction(
          actionType: AIActionType.betray,
          targetId: allyId,
          data: {
            'bonusDamage': 30,
            'selfReputationLoss': 20,
          },
        ));
      }
    }

    // === 公開發言 ===
    actions.add(_PossibleAction(
      actionType: AIActionType.speak,
      data: {'isPublic': true, 'content': '...'},
    ));

    return actions;
  }

  /// 生成投票階段行動
  List<_PossibleAction> _generateVotingActions(AIPlayer ai, GameState state) {
    final actions = <_PossibleAction>[];

    if (state.currentBill != null) {
      // 可以投 A、B、C 任一選項
      for (final option in ['A', 'B', 'C']) {
        actions.add(_PossibleAction(
          actionType: AIActionType.vote,
          data: {'option': option},
        ));
      }
    }

    return actions;
  }

  // ============================================================
  // 行動評分
  // ============================================================

  /// 根據策略對每個行動評分（內部方法）
  List<ActionScore> _scoreActions(
    List<_PossibleAction> actions,
    AIStrategy strategy,
    AIPlayer ai,
    GameState state,
    SituationAnalysis situation, {
    CharacterBehavior? characterBehavior,
  }) {
    final scores = <ActionScore>[];

    for (final action in actions) {
      final factors = <String, double>{};

      // === 基礎分數 ===
      double baseScore = _getBaseScore(action.actionType);

      // === 策略適配分數 ===
      factors['strategyFit'] = _getStrategyFitScore(action, strategy);

      // === 目標選擇分數 ===
      if (action.targetId != null) {
        factors['targetChoice'] = _getTargetChoiceScore(
          action,
          action.targetId!,
          ai,
          state,
          situation,
        );
      }

      // === 風險評估 ===
      factors['riskAdjustment'] = _getRiskAdjustment(action, ai, situation);

      // === 資源考量 ===
      factors['resourceValue'] = _getResourceValueScore(action, ai);

      // === 時機考量 ===
      factors['timing'] = _getTimingScore(action, state);

      // === 角色專屬行為加成 ===
      if (characterBehavior != null) {
        factors['characterBonus'] = _getCharacterBehaviorBonus(
          action,
          ai,
          state,
          characterBehavior,
        );
      }

      scores.add(ActionScore.calculate(
        actionType: action.actionType,
        targetId: action.targetId,
        baseScore: baseScore,
        factors: factors,
      ));
    }

    // 按分數排序（高到低）
    scores.sort((a, b) => b.finalScore.compareTo(a.finalScore));
    return scores;
  }

  /// 獲取行動基礎分數
  double _getBaseScore(AIActionType actionType) {
    switch (actionType) {
      case AIActionType.attack:
        return 40; // 攻擊中等基礎分
      case AIActionType.defend:
        return 35; // 防禦略低
      case AIActionType.ally:
        return 30; // 結盟基礎分
      case AIActionType.betray:
        return 25; // 背叛基礎分較低（風險高）
      case AIActionType.vote:
        return 50; // 投票必要行動
      case AIActionType.speak:
        return 20; // 發言基礎分低
      case AIActionType.wait:
        return 15; // 等待最低
      default:
        return 20;
    }
  }

  /// 計算策略適配分數 (-30 到 +30)
  double _getStrategyFitScore(_PossibleAction action, AIStrategy strategy) {
    // 攻擊性策略
    if (strategy == AIStrategy.allOutAttack || strategy == AIStrategy.targetWeakest) {
      if (action.actionType == AIActionType.attack) return 30;
      if (action.actionType == AIActionType.defend) return -10;
    }

    // 防禦性策略
    if (strategy == AIStrategy.turtleDefense || strategy == AIStrategy.defensiveCounter) {
      if (action.actionType == AIActionType.defend) return 30;
      if (action.actionType == AIActionType.attack) return -15;
    }

    // 外交策略
    if (strategy == AIStrategy.activeDiplomacy || strategy == AIStrategy.maintainAllies) {
      if (action.actionType == AIActionType.ally) return 30;
      if (action.actionType == AIActionType.betray) return -30;
    }

    // 背叛策略
    if (strategy == AIStrategy.waitForBetrayal) {
      if (action.actionType == AIActionType.betray) return 25;
    }

    // 混亂策略
    if (strategy == AIStrategy.createChaos) {
      if (action.actionType == AIActionType.attack) return 20;
      if (action.actionType == AIActionType.betray) return 20;
    }

    // 觀望策略
    if (strategy == AIStrategy.waitAndSee) {
      if (action.actionType == AIActionType.wait) return 20;
      if (action.actionType == AIActionType.speak) return 10;
    }

    return 0;
  }

  /// 計算目標選擇分數 (-20 到 +20)
  double _getTargetChoiceScore(
    _PossibleAction action,
    String targetId,
    AIPlayer ai,
    GameState state,
    SituationAnalysis situation,
  ) {
    final target = state.players.where((p) => p.id == targetId).firstOrNull;
    if (target == null) return 0;

    double score = 0;

    // 攻擊行動：優先攻擊弱勢目標
    if (action.actionType == AIActionType.attack) {
      // 弱勢目標加分
      if (situation.weakTargets.contains(targetId)) {
        score += 15;
      }
      // 主要威脅加分（消除威脅）
      if (situation.mainThreats.contains(targetId)) {
        score += 10;
      }
      // 攻擊盟友扣分
      if (ai.allies.contains(targetId)) {
        score -= 25;
      }
    }

    // 結盟行動：優先選擇潛在盟友
    if (action.actionType == AIActionType.ally) {
      if (situation.potentialAllies.contains(targetId)) {
        score += 20;
      }
      // 避免與威脅結盟
      if (situation.mainThreats.contains(targetId)) {
        score -= 15;
      }
    }

    // 背叛行動：選擇收益最大的目標
    if (action.actionType == AIActionType.betray) {
      // 目標聲望高，背叛收益大
      score += (target.reputation / 100 * 15);
      // 但關係分數越好，心理障礙越大
      final relation = ai.getRelationshipScore(targetId);
      score -= (relation / 100 * 10).clamp(-10, 10);
    }

    return score.clamp(-20, 20);
  }

  /// 計算風險調整分數 (-20 到 +10)
  double _getRiskAdjustment(
    _PossibleAction action,
    AIPlayer ai,
    SituationAnalysis situation,
  ) {
    double adjustment = 0;

    // 聲望低時，高風險行動扣分更多
    final double lowHealthPenalty = ai.reputation < 30 ? -10.0 : 0.0;

    switch (action.actionType) {
      case AIActionType.attack:
        // 攻擊消耗聲望，有風險
        adjustment = -5 + lowHealthPenalty;
        break;

      case AIActionType.betray:
        // 背叛風險最高（會損失聲望和盟友）
        adjustment = -15 + lowHealthPenalty;
        break;

      case AIActionType.defend:
        // 防禦相對安全
        adjustment = 5;
        break;

      case AIActionType.ally:
        // 結盟風險低
        adjustment = 3;
        break;

      case AIActionType.wait:
        // 等待最安全
        adjustment = 10;
        // 但如果機會很好，等待是浪費
        if (situation.opportunityLevel > 60) {
          adjustment -= 15;
        }
        break;

      default:
        adjustment = 0;
    }

    return adjustment.clamp(-20, 10);
  }

  /// 計算資源價值分數 (-10 到 +10)
  double _getResourceValueScore(_PossibleAction action, AIPlayer ai) {
    final cost = action.data['reputationCost'] as int? ?? 0;

    // 沒有消耗不影響分數
    if (cost == 0) return 0;

    // 資源充足時，消耗影響小
    if (ai.reputation > 70) {
      return -2;
    }

    // 資源緊張時，消耗影響大
    if (ai.reputation < 40) {
      return -10;
    }

    return -5;
  }

  /// 計算時機分數 (-10 到 +10)
  double _getTimingScore(_PossibleAction action, GameState state) {
    // 回合初期，激進行動更好
    if (state.currentRound <= 1) {
      if (action.actionType == AIActionType.attack) return 5;
      if (action.actionType == AIActionType.ally) return 10;
    }

    // 回合後期，保守行動更好
    if (state.currentRound >= state.totalRounds - 1) {
      if (action.actionType == AIActionType.defend) return 5;
      if (action.actionType == AIActionType.vote) return 10;
    }

    return 0;
  }

  // ============================================================
  // 難度處理
  // ============================================================

  /// 根據難度選擇最終行動
  ///
  /// 難度對應的隨機因子：
  /// - beginner: 50% 隨機
  /// - intermediate: 30% 隨機
  /// - advanced: 15% 隨機
  /// - expert: 5% 隨機
  /// - master: 0% 隨機（永遠最優解）
  ActionScore _selectActionByDifficulty(
    List<ActionScore> scoredActions,
    AIDifficulty difficulty,
  ) {
    if (scoredActions.isEmpty) {
      throw StateError('No actions to select from');
    }

    // 獲取隨機因子
    final randomFactor = _getRandomFactor(difficulty);

    // 如果隨機因子為 0 或只有一個選項，選擇最優
    if (randomFactor == 0 || scoredActions.length == 1) {
      return scoredActions.first;
    }

    // 根據隨機因子決定是否選擇非最優解
    if (_random.nextDouble() < randomFactor) {
      // 從前幾名中隨機選擇
      final topN = _getTopNByDifficulty(difficulty, scoredActions.length);
      final candidates = scoredActions.take(topN).toList();
      return candidates[_random.nextInt(candidates.length)];
    }

    // 預設選擇最優解
    return scoredActions.first;
  }

  /// 獲取難度對應的隨機因子
  ///
  /// 調整後的勝率目標：
  /// - beginner: 玩家勝率 80% → AI 隨機 70%
  /// - intermediate: 玩家勝率 65% → AI 隨機 45%
  /// - advanced: 玩家勝率 50% → AI 隨機 25%
  /// - expert: 玩家勝率 35% → AI 隨機 10%
  /// - master: 玩家勝率 20% → AI 隨機 3%
  double _getRandomFactor(AIDifficulty difficulty) {
    switch (difficulty) {
      case AIDifficulty.beginner:
        return 0.70; // 70% 隨機（很弱）
      case AIDifficulty.intermediate:
        return 0.45; // 45% 隨機
      case AIDifficulty.advanced:
        return 0.25; // 25% 隨機
      case AIDifficulty.expert:
        return 0.10; // 10% 隨機
      case AIDifficulty.master:
        return 0.03; // 3% 隨機（幾乎完美）
    }
  }

  /// 獲取難度對應的攻擊傷害修正
  ///
  /// 低難度 AI 傷害降低，高難度 AI 傷害提高
  double getDamageModifier(AIDifficulty difficulty) {
    switch (difficulty) {
      case AIDifficulty.beginner:
        return 0.6; // 60% 傷害
      case AIDifficulty.intermediate:
        return 0.8; // 80% 傷害
      case AIDifficulty.advanced:
        return 1.0; // 100% 傷害
      case AIDifficulty.expert:
        return 1.15; // 115% 傷害
      case AIDifficulty.master:
        return 1.25; // 125% 傷害
    }
  }

  /// 獲取難度對應的攻擊頻率
  ///
  /// 低難度 AI 較少攻擊，高難度 AI 更積極攻擊
  double getAttackFrequency(AIDifficulty difficulty) {
    switch (difficulty) {
      case AIDifficulty.beginner:
        return 0.3; // 30% 機率攻擊
      case AIDifficulty.intermediate:
        return 0.5; // 50% 機率攻擊
      case AIDifficulty.advanced:
        return 0.7; // 70% 機率攻擊
      case AIDifficulty.expert:
        return 0.85; // 85% 機率攻擊
      case AIDifficulty.master:
        return 0.95; // 95% 機率攻擊
    }
  }

  /// 獲取難度對應的防禦反應時間（毫秒）
  ///
  /// 低難度 AI 反應慢，高難度 AI 反應快
  int getReactionTime(AIDifficulty difficulty) {
    switch (difficulty) {
      case AIDifficulty.beginner:
        return 2000; // 2 秒
      case AIDifficulty.intermediate:
        return 1500; // 1.5 秒
      case AIDifficulty.advanced:
        return 1000; // 1 秒
      case AIDifficulty.expert:
        return 600; // 0.6 秒
      case AIDifficulty.master:
        return 300; // 0.3 秒
    }
  }

  /// 獲取難度對應的候選數量
  ///
  /// 低難度 AI 從更多選項中隨機，高難度 AI 只選最優
  int _getTopNByDifficulty(AIDifficulty difficulty, int totalActions) {
    switch (difficulty) {
      case AIDifficulty.beginner:
        return totalActions; // 從所有選項中隨機（最弱）
      case AIDifficulty.intermediate:
        return min(totalActions, 5); // 從前 5 名中選
      case AIDifficulty.advanced:
        return min(totalActions, 3); // 從前 3 名中選
      case AIDifficulty.expert:
        return min(totalActions, 2); // 從前 2 名中選
      case AIDifficulty.master:
        return 1; // 只選最優（最強）
    }
  }

  // ============================================================
  // 輔助方法
  // ============================================================

  /// 從 ActionScore 中提取參數
  Map<String, dynamic> _extractParameters(
    ActionScore selectedAction,
    List<_PossibleAction> possibleActions,
  ) {
    // 找到對應的 PossibleAction
    final action = possibleActions.firstWhere(
      (a) =>
          a.actionType == selectedAction.actionType &&
          a.targetId == selectedAction.targetId,
      orElse: () => _PossibleAction(
        actionType: selectedAction.actionType,
        targetId: selectedAction.targetId,
        data: {},
      ),
    );

    return action.data;
  }

  /// 生成決策理由
  String _generateReasoning(
    ActionScore selectedAction,
    AIStrategy strategy,
    SituationAnalysis situation, {
    CharacterBehavior? characterBehavior,
  }) {
    final parts = <String>[];

    // 角色說明
    if (characterBehavior != null) {
      parts.add('角色：${characterBehavior.characterName}');
    }

    // 策略說明
    parts.add('策略：${strategy.displayName}');

    // 行動說明
    parts.add('行動：${selectedAction.actionType.displayName}');

    // 目標說明
    if (selectedAction.targetId != null) {
      parts.add('目標：${selectedAction.targetId}');
    }

    // 局勢說明
    if (situation.isInDanger) {
      parts.add('局勢危急');
    } else if (situation.isInAdvantage) {
      parts.add('局勢有利');
    }

    // 分數說明
    parts.add('評分：${selectedAction.finalScore.toStringAsFixed(1)}');

    return parts.join(' | ');
  }

  // ============================================================
  // 角色專屬行為
  // ============================================================

  /// 計算角色專屬行為加成
  ///
  /// 根據角色的專屬行為對行動進行加分或減分
  double _getCharacterBehaviorBonus(
    _PossibleAction action,
    AIPlayer ai,
    GameState state,
    CharacterBehavior characterBehavior,
  ) {
    // 獲取角色對此行動的加成
    double bonus = characterBehavior.getActionBonus(
      action.actionType,
      ai,
      state,
      action.targetId,
    );

    // 投票行動特殊處理
    if (action.actionType == AIActionType.vote && state.currentBill != null) {
      final voteOption = action.data['option'] as String?;
      if (voteOption != null) {
        final preference = characterBehavior.getVotePreference(
          ai,
          state,
          state.currentBill!,
        );

        // 如果投票選項符合角色偏好，加分
        if (voteOption == preference.preferredOption) {
          bonus += preference.strength * 30; // 最高 +30 分
        } else if (!preference.canBeSwayed) {
          // 如果角色立場堅定且選項不符，大幅減分
          bonus -= 40;
        } else {
          // 可被說服的角色，其他選項小幅減分
          bonus -= 10;
        }
      }
    }

    // 應用行為修正
    final modifier = characterBehavior.baseModifier;

    switch (action.actionType) {
      case AIActionType.attack:
        bonus += modifier.attackModifier * 20;
        break;
      case AIActionType.defend:
        bonus += modifier.defenseModifier * 20;
        break;
      case AIActionType.ally:
        bonus += modifier.allyModifier * 20;
        break;
      case AIActionType.betray:
        bonus += modifier.betrayModifier * 20;
        break;
      case AIActionType.useSkill:
        bonus += modifier.skillModifier * 20;
        break;
      default:
        break;
    }

    // 風險承受度影響
    if (_isHighRiskAction(action.actionType)) {
      // 高風險行動根據風險承受度調整
      final riskAdjustment = (modifier.riskTolerance - 0.5) * 20;
      bonus += riskAdjustment;
    }

    return bonus.clamp(-40, 40);
  }

  /// 判斷是否為高風險行動
  bool _isHighRiskAction(AIActionType actionType) {
    return actionType == AIActionType.attack ||
        actionType == AIActionType.betray ||
        actionType == AIActionType.useSkill;
  }

  /// 獲取角色的投票決策
  ///
  /// 專門用於投票階段，返回角色偏好的投票選項
  VotePreference? getCharacterVotePreference(
    AIPlayer ai,
    GameState state,
  ) {
    final characterBehavior = CharacterBehaviorManager.getBehavior(ai.roleId);
    if (characterBehavior == null || state.currentBill == null) {
      return null;
    }

    return characterBehavior.getVotePreference(ai, state, state.currentBill!);
  }

  /// 獲取角色的優先攻擊目標
  ///
  /// 返回按優先級排序的目標列表
  List<TargetPriority> getCharacterPreferredTargets(
    AIPlayer ai,
    GameState state,
  ) {
    final characterBehavior = CharacterBehaviorManager.getBehavior(ai.roleId);
    if (characterBehavior == null) {
      return [];
    }

    return characterBehavior.getPreferredTargets(ai, state, _playerRoles);
  }

  /// 檢查角色是否應該使用技能
  bool shouldCharacterUseSkill(
    AIPlayer ai,
    GameState state,
    SituationAnalysis situation,
  ) {
    final characterBehavior = CharacterBehaviorManager.getBehavior(ai.roleId);
    if (characterBehavior == null) {
      return false;
    }

    return characterBehavior.shouldUseSkill(ai, state, situation);
  }

  /// 獲取角色技能的最佳目標
  String? getCharacterSkillTarget(AIPlayer ai, GameState state) {
    final characterBehavior = CharacterBehaviorManager.getBehavior(ai.roleId);
    if (characterBehavior == null) {
      return null;
    }

    return characterBehavior.getSkillTarget(ai, state);
  }

  /// 調試日誌
  void _log(String message) {
    if (enableDebugLogging) {
      // ignore: avoid_print
      print('[AIEngine] $message');
    }
  }
}

/// 內部類：可能的行動
class _PossibleAction {
  final AIActionType actionType;
  final String? targetId;
  final Map<String, dynamic> data;

  _PossibleAction({
    required this.actionType,
    this.targetId,
    this.data = const {},
  });
}
