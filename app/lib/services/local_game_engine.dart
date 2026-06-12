import 'dart:math';

import '../models/single_player.dart';
import '../models/card.dart';
import '../models/player.dart';

/// 本地 AI 遊戲引擎
/// 完全離線運行，不需要連接 server API
class LocalGameEngine {
  final AiDifficulty difficulty;
  final String playerCharacter;
  final String playerName;
  final Random _random = Random();

  // 內部遊戲狀態
  late List<_InternalPlayer> _players;
  late List<GameCard> _deck;
  String _phase = 'player_turn';
  int _currentRound = 1;
  String _currentBill = '';
  final List<String> _aiActionsLog = [];
  bool _isGameOver = false;
  SinglePlayerResult? _result;
  String _sessionId = '';

  // 回合制狀態
  int _currentTurnIndex = 0;
  int _actionPointsRemaining = 3;
  static const int actionPointsPerTurn = 3;

  // AI 行動記錄（供 UI 逐步展示）
  final List<AiActionRecord> _pendingAiActions = [];

  // 回合常數
  static const int maxRounds = 5;
  static const int initialHandSize = 4;
  static const int maxHandSize = 7;

  // 議案列表
  static const List<String> bills = [
    '工廠法案：限制工廠工時，保護勞工權益',
    '新聞審查法：加強對報章的審查與管制',
    '穀物法廢除：廢除穀物進口關稅，降低麵包價格',
    '結社自由法：允許工人自由組建工會',
    '選舉改革法：擴大選舉權，增加議員席次',
  ];

  // 4 個可選角色（快速對戰用）
  static const List<({String id, String name, CharacterType type})>
      availableCharacters = [
    (id: 'thomas', name: '工人湯瑪斯', type: CharacterType.thomasWorker),
    (id: 'richard', name: '工廠主理查', type: CharacterType.richardFactory),
    (id: 'edward', name: '記者愛德華', type: CharacterType.edwardJournalist),
    (id: 'george', name: '盧德派喬治', type: CharacterType.georgeLuddite),
  ];

  LocalGameEngine({
    required this.difficulty,
    required this.playerCharacter,
    required this.playerName,
  });

  /// 初始化遊戲
  SinglePlayerState initGame() {
    _sessionId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    _aiActionsLog.clear();
    _isGameOver = false;
    _result = null;
    _currentRound = 1;
    _phase = 'player_turn';
    _currentTurnIndex = 0;
    _actionPointsRemaining = actionPointsPerTurn;

    // 建立牌庫
    _buildDeck();

    // 建立玩家
    _buildPlayers();

    // 發初始手牌
    for (final player in _players) {
      for (int i = 0; i < initialHandSize; i++) {
        _drawCardForPlayer(player);
      }
    }

    // 抽取第一個議案
    _currentBill = bills[_random.nextInt(bills.length)];

    _aiActionsLog.add('📜 第 $_currentRound 回合開始');
    _aiActionsLog.add('📋 議案：$_currentBill');

    return _buildState();
  }

  /// 建立牌庫
  void _buildDeck() {
    _deck = [];
    final universalCards = CardDatabase.getUniversalCards();

    // 加入通用牌（common + rare 各加 2 份, epic 1 份）
    for (final card in universalCards) {
      switch (card.rarity) {
        case CardRarity.normal:
          _deck.addAll([card, card, card]);
          break;
        case CardRarity.rare:
          _deck.addAll([card, card]);
          break;
        case CardRarity.epic:
          _deck.add(card);
          break;
        case CardRarity.legendary:
          // legendary 不進普通牌庫
          break;
      }
    }

    _deck.shuffle(_random);
  }

  /// 建立玩家列表
  void _buildPlayers() {
    _players = [];

    // 找出玩家選擇的角色
    final playerChar = availableCharacters.firstWhere(
      (c) => c.id == playerCharacter || c.type.name == playerCharacter,
      orElse: () => availableCharacters[0],
    );

    // 建立人類玩家
    _players.add(_InternalPlayer(
      id: 'player',
      name: playerName,
      character: playerChar.type,
      characterId: playerChar.id,
      isAi: false,
      reputation: playerChar.type.initialReputation,
      gold: playerChar.type.initialGold,
    ));

    // 建立 AI 玩家
    for (final char in availableCharacters) {
      if (char.id == playerChar.id) continue;
      _players.add(_InternalPlayer(
        id: 'ai_${char.id}',
        name: char.name,
        character: char.type,
        characterId: char.id,
        isAi: true,
        reputation: char.type.initialReputation,
        gold: char.type.initialGold,
      ));
    }
  }

  /// 為玩家抽牌
  bool _drawCardForPlayer(_InternalPlayer player) {
    if (player.hand.length >= maxHandSize) return false;
    if (_deck.isEmpty) {
      _buildDeck(); // 牌庫用完重新洗
    }
    if (_deck.isNotEmpty) {
      player.hand.add(_deck.removeLast());
      return true;
    }
    return false;
  }

  /// 執行玩家行動
  SinglePlayerState performAction(Map<String, dynamic> action) {
    if (_isGameOver) return _buildState();

    final type = action['type'] as String? ?? '';

    switch (type) {
      case 'play_card':
        if (_phase == 'player_turn' && _actionPointsRemaining > 0) {
          _handlePlayCard(action);
          _actionPointsRemaining--;
        } else {
          _aiActionsLog.add('⚠️ 行動點數不足或不在行動階段');
        }
        break;
      case 'draw_card':
        _handleDrawCard();
        break;
      case 'challenge':
        if (_phase == 'player_turn' && _actionPointsRemaining > 0) {
          _handleChallenge(action);
          _actionPointsRemaining--;
        } else {
          _aiActionsLog.add('⚠️ 行動點數不足或不在行動階段');
        }
        break;
      case 'vote':
        _handleVote(action);
        break;
      case 'form_alliance':
        if (_phase == 'player_turn' && _actionPointsRemaining > 0) {
          _handleFormAlliance(action);
          _actionPointsRemaining--;
        } else {
          _aiActionsLog.add('⚠️ 行動點數不足或不在行動階段');
        }
        break;
      case 'end_turn':
        _handleEndTurn();
        break;
      case 'end_phase':
        _handleEndPhase();
        break;
    }

    return _buildState();
  }

  /// 結束玩家回合（回合制）
  void _handleEndTurn() {
    if (_phase != 'player_turn') return;

    _aiActionsLog.add('⏭️ 你結束了回合');
    _pendingAiActions.clear();

    // AI 玩家輪流行動（收集行動記錄）
    _processAllAiTurns();

    if (_pendingAiActions.isNotEmpty) {
      // 有 AI 行動需要展示 → 進入 ai_turn phase
      _phase = 'ai_turn';
    } else {
      // 沒有 AI 行動 → 直接進入投票
      _phase = 'voting';
      _aiActionsLog.add('🗳️ 進入投票階段');
    }
  }

  /// 完成 AI 回合展示後，由 provider 呼叫以推進到投票階段
  SinglePlayerState finishAiTurnPhase() {
    _pendingAiActions.clear();
    _phase = 'voting';
    _aiActionsLog.add('🗳️ 進入投票階段');
    return _buildState();
  }

  /// 處理所有 AI 玩家的回合
  void _processAllAiTurns() {
    for (final ai in _aiPlayers) {
      if (!ai.isAlive) continue;

      // 每個 AI 有固定行動點數
      int aiActionPoints = actionPointsPerTurn;
      
      while (aiActionPoints > 0) {
        // AI 每回合開始自動抽牌
        if (!ai.drawnThisTurn) {
          _drawCardForPlayer(ai);
          ai.drawnThisTurn = true;
        }

        // AI 決定行動
        bool didAct = _aiSingleAction(ai);
        if (!didAct) break; // AI 選擇不行動
        aiActionPoints--;
      }
    }
  }

  /// AI 執行單一行動，回傳是否有執行
  bool _aiSingleAction(_InternalPlayer ai) {
    switch (difficulty) {
      case AiDifficulty.easy:
        return _aiSingleActionEasy(ai);
      case AiDifficulty.normal:
        return _aiSingleActionNormal(ai);
      case AiDifficulty.hard:
      case AiDifficulty.expert:
        return _aiSingleActionHard(ai);
    }
  }

  bool _aiSingleActionEasy(_InternalPlayer ai) {
    if (ai.hand.isEmpty || _random.nextDouble() < 0.5) return false;
    final card = ai.hand[_random.nextInt(ai.hand.length)];
    final target = _getRandomTarget(ai);
    ai.hand.remove(card);
    _applyCard(ai, card, target?.id);
    return true;
  }

  bool _aiSingleActionNormal(_InternalPlayer ai) {
    if (ai.hand.isEmpty) return false;

    // 低血量優先治療
    if (ai.reputation < 40) {
      final healCard = ai.hand.where((c) => c.type == CardType.healing).firstOrNull;
      if (healCard != null) {
        ai.hand.remove(healCard);
        _applyCard(ai, healCard, ai.id);
        return true;
      }
    }

    // 攻擊最高聲望
    if (_random.nextDouble() < 0.6) {
      final attackCard = ai.hand.where((c) => c.type == CardType.attack).firstOrNull;
      if (attackCard != null) {
        final target = _getHighestReputationTarget(ai);
        if (target != null) {
          ai.hand.remove(attackCard);
          _applyCard(ai, attackCard, target.id);
          return true;
        }
      }
    }

    return false;
  }

  bool _aiSingleActionHard(_InternalPlayer ai) {
    if (ai.hand.isEmpty) return false;

    if (ai.reputation < 50) {
      final healCard = ai.hand.where((c) => c.type == CardType.healing).firstOrNull;
      if (healCard != null) {
        ai.hand.remove(healCard);
        _applyCard(ai, healCard, ai.id);
        return true;
      }
    }

    final attackCard = ai.hand.where((c) => c.type == CardType.attack).firstOrNull;
    if (attackCard != null) {
      final targets = _alivePlayers
          .where((p) => p.id != ai.id && !ai.allies.contains(p.id))
          .toList();
      if (targets.isNotEmpty) {
        targets.sort((a, b) => b.reputation.compareTo(a.reputation));
        ai.hand.remove(attackCard);
        _applyCard(ai, attackCard, targets.first.id);
        return true;
      }
    }

    return false;
  }

  /// 出牌
  void _handlePlayCard(Map<String, dynamic> action) {
    final cardId = action['card_id'] as String? ?? '';
    final targetId = action['target_id'] as String?;

    final player = _humanPlayer;
    final cardIndex = player.hand.indexWhere((c) => c.id == cardId);
    if (cardIndex == -1) return;

    final card = player.hand.removeAt(cardIndex);
    _applyCard(player, card, targetId);
    // 回合制：不再立即觸發 AI 回應，等玩家結束回合
  }

  /// 抽牌
  void _handleDrawCard() {
    final player = _humanPlayer;
    if (_drawCardForPlayer(player)) {
      _aiActionsLog.add('🃏 你抽了一張牌');
    } else {
      _aiActionsLog.add('⚠️ 手牌已滿，無法抽牌');
    }
  }

  /// 質詢
  void _handleChallenge(Map<String, dynamic> action) {
    final targetId = action['target_id'] as String? ?? '';
    final target = _findPlayer(targetId);
    if (target == null) return;

    final damage = 5 + _random.nextInt(6); // 5~10
    target.reputation -= damage;
    _aiActionsLog.add('⚔️ 你對 ${target.name} 發起質詢，造成 $damage 聲望傷害');

    _checkPoliticalDeath(target);
    // 回合制：不再立即觸發 AI 回應，等玩家結束回合
  }

  /// 投票
  void _handleVote(Map<String, dynamic> action) {
    final choice = action['choice'] as String? ?? 'a';

    _aiActionsLog.add('🗳️ 你投了 ${choice.toUpperCase()} 票');

    // AI 投票
    for (final ai in _aiPlayers) {
      if (!ai.isAlive) continue;
      final aiChoice = _aiVote(ai);
      _aiActionsLog.add('🤖 ${ai.name} 投了 ${aiChoice.toUpperCase()} 票');
    }

    // 結算投票效果
    _resolveVoting(choice);

    // 進入下一回合
    _advanceRound();
  }

  /// 結盟
  void _handleFormAlliance(Map<String, dynamic> action) {
    final targetId = action['target_id'] as String? ?? '';
    final target = _findPlayer(targetId);
    if (target == null) return;

    // AI 50% 概率接受（根據難度調整）
    final acceptChance = switch (difficulty) {
      AiDifficulty.easy => 0.7,
      AiDifficulty.normal => 0.5,
      AiDifficulty.hard => 0.3,
      AiDifficulty.expert => 0.2,
    };

    if (_random.nextDouble() < acceptChance) {
      _humanPlayer.allies.add(targetId);
      target.allies.add('player');
      _aiActionsLog.add('🤝 ${target.name} 接受了你的結盟！');
    } else {
      _aiActionsLog.add('❌ ${target.name} 拒絕了你的結盟請求');
    }
  }

  /// 結束階段（回合制：等同結束回合）
  void _handleEndPhase() {
    switch (_phase) {
      case 'player_turn':
        _handleEndTurn();
        break;
      case 'voting':
        _advanceRound();
        break;
      case 'result':
        _advanceRound();
        break;
    }
  }

  /// AI 在密謀階段的行動
  void _aiConspiracyActions() {
    for (final ai in _aiPlayers) {
      if (!ai.isAlive) continue;
      // 根據難度決定是否結盟
      if (difficulty == AiDifficulty.easy) continue;

      // Normal+: 嘗試與合適的角色結盟
      final potentialAlly = _findBestAlly(ai);
      if (potentialAlly != null && !ai.allies.contains(potentialAlly.id)) {
        if (_random.nextDouble() < 0.4) {
          ai.allies.add(potentialAlly.id);
          potentialAlly.allies.add(ai.id);
          _aiActionsLog.add('🤝 ${ai.name} 和 ${potentialAlly.name} 結盟了');
        }
      }
    }
  }

  /// AI 回合
  void _aiTurn() {
    for (final ai in _aiPlayers) {
      if (!ai.isAlive) continue;

      // 每回合開始自動抽牌
      if (ai.drawnThisTurn == false) {
        _drawCardForPlayer(ai);
        ai.drawnThisTurn = true;
      }

      switch (difficulty) {
        case AiDifficulty.easy:
          _aiTurnEasy(ai);
          break;
        case AiDifficulty.normal:
          _aiTurnNormal(ai);
          break;
        case AiDifficulty.hard:
          _aiTurnHard(ai);
          break;
        case AiDifficulty.expert:
          _aiTurnExpert(ai);
          break;
      }
    }
  }

  /// Easy AI: 隨機出牌
  void _aiTurnEasy(_InternalPlayer ai) {
    if (ai.hand.isEmpty || _random.nextDouble() < 0.4) return;

    final card = ai.hand[_random.nextInt(ai.hand.length)];
    final target = _getRandomTarget(ai);
    ai.hand.remove(card);
    _applyCard(ai, card, target?.id);
  }

  /// Normal AI: 基本策略
  void _aiTurnNormal(_InternalPlayer ai) {
    if (ai.hand.isEmpty) return;

    // 優先策略
    // 1. 如果聲望低，用治療卡
    if (ai.reputation < 40) {
      final healCard = ai.hand.where((c) => c.type == CardType.healing).firstOrNull;
      if (healCard != null) {
        ai.hand.remove(healCard);
        _applyCard(ai, healCard, ai.id);
        return;
      }
    }

    // 2. 攻擊聲望最高的對手
    if (_random.nextDouble() < 0.6) {
      final attackCard = ai.hand.where((c) => c.type == CardType.attack).firstOrNull;
      if (attackCard != null) {
        final target = _getHighestReputationTarget(ai);
        if (target != null) {
          ai.hand.remove(attackCard);
          _applyCard(ai, attackCard, target.id);
          return;
        }
      }
    }

    // 3. 隨機出一張
    if (_random.nextDouble() < 0.3 && ai.hand.isNotEmpty) {
      final card = ai.hand[_random.nextInt(ai.hand.length)];
      final target = _getRandomTarget(ai);
      ai.hand.remove(card);
      _applyCard(ai, card, target?.id);
    }
  }

  /// Hard AI: 進階策略
  void _aiTurnHard(_InternalPlayer ai) {
    if (ai.hand.isEmpty) return;

    // 1. 防禦優先：如果剛被攻擊，使用防禦牌
    if (ai.damagedThisTurn && _random.nextDouble() < 0.7) {
      final defCard = ai.hand.where((c) => c.type == CardType.defense).firstOrNull;
      if (defCard != null) {
        ai.hand.remove(defCard);
        _applyCard(ai, defCard, null);
        return;
      }
    }

    // 2. 低血量時治療
    if (ai.reputation < 50) {
      final healCard = ai.hand.where((c) => c.type == CardType.healing).firstOrNull;
      if (healCard != null) {
        ai.hand.remove(healCard);
        _applyCard(ai, healCard, ai.id);
        return;
      }
    }

    // 3. 使用 buff
    if (_random.nextDouble() < 0.4) {
      final buffCard = ai.hand.where((c) => c.type == CardType.buff).firstOrNull;
      if (buffCard != null) {
        ai.hand.remove(buffCard);
        _applyCard(ai, buffCard, ai.id);
        return;
      }
    }

    // 4. 聯盟策略：攻擊非盟友中聲望最高的
    final attackCard = ai.hand.where((c) => c.type == CardType.attack).firstOrNull;
    if (attackCard != null) {
      final targets = _alivePlayers
          .where((p) => p.id != ai.id && !ai.allies.contains(p.id))
          .toList();
      if (targets.isNotEmpty) {
        targets.sort((a, b) => b.reputation.compareTo(a.reputation));
        ai.hand.remove(attackCard);
        _applyCard(ai, attackCard, targets.first.id);
        return;
      }
    }

    // 5. 控制卡
    if (_random.nextDouble() < 0.5) {
      final ctrlCard = ai.hand.where((c) => c.type == CardType.control).firstOrNull;
      if (ctrlCard != null) {
        final target = _getHighestReputationTarget(ai);
        if (target != null) {
          ai.hand.remove(ctrlCard);
          _applyCard(ai, ctrlCard, target.id);
          return;
        }
      }
    }
  }

  /// Expert AI: 最優化策略
  void _aiTurnExpert(_InternalPlayer ai) {
    if (ai.hand.isEmpty) return;

    // Expert 與 Hard 類似，但更精準
    // 1. 始終保留一張防禦牌
    final defCards = ai.hand.where((c) => c.type == CardType.defense).toList();
    final hasDefenseReserve = defCards.length > 1;

    // 2. 計算最佳行動
    if (ai.reputation < 40) {
      // 急需治療
      final healCard = ai.hand.where((c) => c.type == CardType.healing).firstOrNull;
      if (healCard != null) {
        ai.hand.remove(healCard);
        _applyCard(ai, healCard, ai.id);
        return;
      }
    }

    // 3. 如果是最後回合，全力攻擊
    if (_currentRound >= maxRounds - 1) {
      final attackCards = ai.hand.where((c) => c.type == CardType.attack).toList();
      if (attackCards.isNotEmpty) {
        // 攻擊最大威脅（與自己聲望差距最小的）
        final threats = _alivePlayers
            .where((p) => p.id != ai.id)
            .toList()
          ..sort((a, b) => (b.reputation - ai.reputation).abs()
              .compareTo((a.reputation - ai.reputation).abs()));
        if (threats.isNotEmpty) {
          final bestAttack = attackCards.reduce((a, b) =>
              a.baseValue > b.baseValue ? a : b);
          ai.hand.remove(bestAttack);
          _applyCard(ai, bestAttack, threats.first.id);
          return;
        }
      }
    }

    // 4. 使用 buff 強化自己
    if (_random.nextDouble() < 0.5) {
      final buffCard = ai.hand.where((c) => c.type == CardType.buff).firstOrNull;
      if (buffCard != null) {
        ai.hand.remove(buffCard);
        _applyCard(ai, buffCard, ai.id);
        return;
      }
    }

    // 5. 攻擊非盟友中聲望最高的對手
    final attackCard = ai.hand.where((c) =>
        c.type == CardType.attack &&
        (!hasDefenseReserve || c.type != CardType.defense)).firstOrNull;
    if (attackCard != null) {
      final targets = _alivePlayers
          .where((p) => p.id != ai.id && !ai.allies.contains(p.id))
          .toList();
      if (targets.isNotEmpty) {
        targets.sort((a, b) => b.reputation.compareTo(a.reputation));
        ai.hand.remove(attackCard);
        _applyCard(ai, attackCard, targets.first.id);
        return;
      }
    }

    // 6. 隨機出牌（Expert 不會浪費太多牌）
    if (ai.hand.length > 5 && ai.hand.isNotEmpty) {
      final card = ai.hand.where((c) =>
          c.type != CardType.defense).firstOrNull;
      if (card != null) {
        final target = _getRandomTarget(ai);
        ai.hand.remove(card);
        _applyCard(ai, card, target?.id);
      }
    }
  }

  /// 記錄 AI 行動（如果 source 是 AI，加入 pendingAiActions）
  void _recordAiAction(_InternalPlayer source, String actionType, String description, {
    _InternalPlayer? target,
    int? valueChange,
  }) {
    if (source.isAi) {
      _pendingAiActions.add(AiActionRecord(
        actorId: source.id,
        actorName: source.name,
        actionType: actionType,
        description: description,
        targetId: target?.id,
        targetName: target?.name,
        valueChange: valueChange,
      ));
    }
  }

  /// 套用卡牌效果
  void _applyCard(_InternalPlayer source, GameCard card, String? targetId) {
    final target = targetId != null ? _findPlayer(targetId) : null;

    for (final effect in card.effects) {
      switch (effect.type) {
        case CardEffectType.damage:
          final effectTarget = effect.target == 'self' ? source : (target ?? _getRandomTarget(source));
          if (effectTarget != null) {
            effectTarget.reputation -= effect.value;
            effectTarget.damagedThisTurn = true;
            final msg = '⚔️ ${source.name} 使用 ${card.name} 對 ${effectTarget.name} 造成 ${effect.value} 傷害';
            _aiActionsLog.add(msg);
            _recordAiAction(source, 'attack', msg, target: effectTarget, valueChange: -effect.value);
            _checkPoliticalDeath(effectTarget);
          }
          break;
        case CardEffectType.heal:
          final healTarget = target ?? source;
          healTarget.reputation += effect.value;
          final msg = '💚 ${source.name} 使用 ${card.name} 恢復了 ${effect.value} 聲望';
          _aiActionsLog.add(msg);
          _recordAiAction(source, 'heal', msg, target: healTarget, valueChange: effect.value);
          break;
        case CardEffectType.buff:
          final msg = '⬆️ ${source.name} 使用了 ${card.name}';
          _aiActionsLog.add(msg);
          // buff 在簡化版中直接加聲望
          source.reputation += (effect.value ~/ 2);
          _recordAiAction(source, 'buff', msg, valueChange: effect.value ~/ 2);
          break;
        case CardEffectType.debuff:
          if (target != null) {
            final msg = '⬇️ ${source.name} 對 ${target.name} 使用了 ${card.name}';
            _aiActionsLog.add(msg);
            target.reputation -= (effect.value * 2);
            _recordAiAction(source, 'debuff', msg, target: target, valueChange: -(effect.value * 2));
            _checkPoliticalDeath(target);
          }
          break;
        case CardEffectType.control:
          if (target != null) {
            final msg = '🔒 ${source.name} 對 ${target.name} 使用了 ${card.name}';
            _aiActionsLog.add(msg);
            _recordAiAction(source, 'control', msg, target: target);
          }
          break;
        case CardEffectType.draw:
          for (int i = 0; i < effect.value; i++) {
            _drawCardForPlayer(source);
          }
          final msg = '🃏 ${source.name} 抽了 ${effect.value} 張牌';
          _aiActionsLog.add(msg);
          _recordAiAction(source, 'draw', msg);
          break;
        case CardEffectType.discard:
          if (target != null && target.hand.isNotEmpty) {
            final discardCount = min(effect.value, target.hand.length);
            for (int i = 0; i < discardCount; i++) {
              target.hand.removeAt(_random.nextInt(target.hand.length));
            }
            final msg = '🗑️ ${target.name} 被迫棄了 $discardCount 張牌';
            _aiActionsLog.add(msg);
            _recordAiAction(source, 'discard', msg, target: target);
          }
          break;
        case CardEffectType.resource:
          source.gold += effect.value;
          final msg = '💰 ${source.name} 獲得了 ${effect.value} 金幣';
          _aiActionsLog.add(msg);
          _recordAiAction(source, 'resource', msg, valueChange: effect.value);
          break;
        case CardEffectType.special:
          final msg = '⭐ ${source.name} 使用了 ${card.name}';
          _aiActionsLog.add(msg);
          _recordAiAction(source, 'special', msg);
          break;
      }
    }

    // 如果卡牌沒有效果，預設行為
    if (card.effects.isEmpty) {
      if (target != null && card.baseValue > 0) {
        if (card.type == CardType.attack) {
          target.reputation -= card.baseValue;
          target.damagedThisTurn = true;
          final msg = '⚔️ ${source.name} 使用 ${card.name} 對 ${target.name} 造成 ${card.baseValue} 傷害';
          _aiActionsLog.add(msg);
          _recordAiAction(source, 'attack', msg, target: target, valueChange: -card.baseValue);
          _checkPoliticalDeath(target);
        } else if (card.type == CardType.healing) {
          final healTarget = target;
          healTarget.reputation += card.baseValue;
          final msg = '💚 ${source.name} 使用 ${card.name} 恢復了 ${card.baseValue} 聲望';
          _aiActionsLog.add(msg);
          _recordAiAction(source, 'heal', msg, target: healTarget, valueChange: card.baseValue);
        }
      }
    }
  }

  /// 檢查政治死亡
  void _checkPoliticalDeath(_InternalPlayer player) {
    if (player.reputation <= 0) {
      player.reputation = 0;
      player.isAlive = false;
      _aiActionsLog.add('💀 ${player.name} 政治死亡！');
    }
  }

  /// AI 投票決策
  String _aiVote(_InternalPlayer ai) {
    switch (difficulty) {
      case AiDifficulty.easy:
        return ['a', 'b', 'c', 'abstain'][_random.nextInt(4)];
      case AiDifficulty.normal:
        // 根據角色偏好投票
        return _getCharacterPreferredVote(ai);
      case AiDifficulty.hard:
      case AiDifficulty.expert:
        // 策略性投票：看盟友怎麼投
        return _getStrategicVote(ai);
    }
  }

  /// 根據角色偏好投票
  String _getCharacterPreferredVote(_InternalPlayer ai) {
    // 工人傾向支持勞工法案
    if (ai.character == CharacterType.thomasWorker ||
        ai.character == CharacterType.georgeLuddite) {
      if (_currentBill.contains('工廠') || _currentBill.contains('結社') || _currentBill.contains('改革')) {
        return 'a'; // 支持
      }
      return 'b'; // 反對
    }
    // 工廠主傾向反對管制
    if (ai.character == CharacterType.richardFactory) {
      if (_currentBill.contains('工廠') || _currentBill.contains('結社')) {
        return 'b'; // 反對
      }
      return 'a'; // 支持
    }
    // 記者中立偏支持
    return _random.nextBool() ? 'a' : 'b';
  }

  /// 策略性投票
  String _getStrategicVote(_InternalPlayer ai) {
    // Expert 會看盟友的可能投票方向
    final allyCount = ai.allies.length;
    if (allyCount > 0) {
      // 跟盟友一起投
      return _getCharacterPreferredVote(ai);
    }
    // 沒有盟友，投對自己有利的
    return _getCharacterPreferredVote(ai);
  }

  /// 結算投票
  void _resolveVoting(String playerChoice) {
    // 計算各選項得票
    final votes = <String, int>{'a': 0, 'b': 0, 'c': 0, 'abstain': 0};
    votes[playerChoice] = (votes[playerChoice] ?? 0) + 1;

    // 根據投票結果影響聲望
    // 多數派 +5 聲望，少數派 -3 聲望
    final winner = votes.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final isPlayerMajority = playerChoice == winner.key;

    if (isPlayerMajority) {
      _humanPlayer.reputation += 5;
      _aiActionsLog.add('📊 議案投票結果：你在多數派！+5 聲望');
    } else {
      _humanPlayer.reputation -= 3;
      _aiActionsLog.add('📊 議案投票結果：你在少數派。-3 聲望');
    }

    // AI 也受投票影響
    for (final ai in _aiPlayers) {
      if (!ai.isAlive) continue;
      ai.reputation += _random.nextInt(5) - 2; // -2 ~ +2
    }
  }

  /// 推進回合
  void _advanceRound() {
    _currentRound++;

    if (_currentRound > maxRounds || _alivePlayers.length <= 1) {
      _endGame();
      return;
    }

    _phase = 'player_turn';
    _currentTurnIndex = 0;
    _actionPointsRemaining = actionPointsPerTurn;
    _currentBill = bills[(_currentRound - 1) % bills.length];

    // 每回合自動抽牌
    for (final player in _players) {
      if (!player.isAlive) continue;
      _drawCardForPlayer(player);
      player.damagedThisTurn = false;
      player.drawnThisTurn = false;
    }

    // 回合金幣收入
    for (final player in _players) {
      if (!player.isAlive) continue;
      player.gold += 5 + _random.nextInt(6); // 5~10
    }

    // 不清空日誌，用分隔線區分新回合
    _aiActionsLog.add('───────────────');
    _aiActionsLog.add('📜 第 $_currentRound 回合開始');
    _aiActionsLog.add('📋 議案：$_currentBill');
  }

  /// 結束遊戲
  void _endGame() {
    _isGameOver = true;
    _phase = 'result';

    // 排名
    final ranking = _players.toList()
      ..sort((a, b) => b.reputation.compareTo(a.reputation));

    final playerRank = ranking.indexWhere((p) => p.id == 'player') + 1;
    final won = playerRank == 1;

    _result = SinglePlayerResult(
      won: won,
      rank: playerRank,
      score: _humanPlayer.reputation,
      rankings: ranking
          .map((p) => PlayerFinalScore(
                name: p.name,
                score: p.reputation,
                isAi: p.isAi,
              ))
          .toList(),
    );

    _aiActionsLog.add(won ? '🎉 恭喜獲勝！' : '😔 遊戲結束');
  }

  /// 建構對外狀態
  SinglePlayerState _buildState() {
    final humanPlayer = _humanPlayer;

    return SinglePlayerState(
      sessionId: _sessionId,
      phase: _phase,
      currentRound: _currentRound,
      currentBill: _currentBill,
      players: _players
          .map((p) => SinglePlayerInfo(
                id: p.id,
                name: p.name,
                character: p.characterId,
                reputation: p.reputation,
                gold: p.gold,
                isAi: p.isAi,
                isPoliticallyDead: !p.isAlive,
                handCount: p.hand.length,
              ))
          .toList(),
      hand: humanPlayer.hand
          .map((c) => {
                'id': c.id,
                'name': c.name,
                'description': c.description,
                'card_type': c.type.name,
                'rarity': c.rarity.symbol,
                'base_value': c.baseValue,
                'influence_cost': c.influenceCost,
              })
          .toList(),
      phaseTimeRemaining: 0,
      aiActionsLog: List.from(_aiActionsLog),
      isGameOver: _isGameOver,
      result: _result,
      actionPointsRemaining: _actionPointsRemaining,
      currentTurnPlayerId: _phase == 'player_turn' ? 'player' : null,
      pendingAiActions: List.from(_pendingAiActions),
    );
  }

  // ─── Helper getters ───
  _InternalPlayer get _humanPlayer =>
      _players.firstWhere((p) => !p.isAi);

  List<_InternalPlayer> get _aiPlayers =>
      _players.where((p) => p.isAi).toList();

  List<_InternalPlayer> get _alivePlayers =>
      _players.where((p) => p.isAlive).toList();

  _InternalPlayer? _findPlayer(String id) {
    try {
      return _players.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  _InternalPlayer? _getRandomTarget(_InternalPlayer source) {
    final targets = _alivePlayers.where((p) => p.id != source.id).toList();
    if (targets.isEmpty) return null;
    return targets[_random.nextInt(targets.length)];
  }

  _InternalPlayer? _getHighestReputationTarget(_InternalPlayer source) {
    final targets = _alivePlayers.where((p) => p.id != source.id).toList();
    if (targets.isEmpty) return null;
    targets.sort((a, b) => b.reputation.compareTo(a.reputation));
    return targets.first;
  }

  _InternalPlayer? _findBestAlly(_InternalPlayer ai) {
    // 根據陣營偏好選擇盟友
    final sameFaction = _alivePlayers.where((p) =>
        p.id != ai.id &&
        !ai.allies.contains(p.id) &&
        p.character.faction == ai.character.faction).toList();
    if (sameFaction.isNotEmpty) {
      return sameFaction[_random.nextInt(sameFaction.length)];
    }
    return null;
  }
}

/// 內部玩家狀態
class _InternalPlayer {
  final String id;
  final String name;
  final CharacterType character;
  final String characterId;
  final bool isAi;
  int reputation;
  int gold;
  bool isAlive;
  List<GameCard> hand;
  List<String> allies;
  bool damagedThisTurn;
  bool drawnThisTurn;

  _InternalPlayer({
    required this.id,
    required this.name,
    required this.character,
    required this.characterId,
    required this.isAi,
    required this.reputation,
    required this.gold,
  })  : isAlive = true,
        hand = [],
        allies = [],
        damagedThisTurn = false,
        drawnThisTurn = false;
}
