/// 卡牌狀態管理
/// 1812 國會風雲 - 卡牌系統 Provider
library card_provider;

import 'package:flutter/foundation.dart';
import '../models/card.dart';
import '../models/player_resources.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

/// 卡牌使用結果
class CardUseResult {
  final bool success;
  final String? message;
  final CardEffect? appliedEffect;
  final List<ResourceChange>? resourceChanges;

  const CardUseResult({
    required this.success,
    this.message,
    this.appliedEffect,
    this.resourceChanges,
  });

  factory CardUseResult.fromJson(Map<String, dynamic> json) {
    return CardUseResult(
      success: json['success'] ?? false,
      message: json['message'],
      appliedEffect: json['applied_effect'] != null
          ? CardEffect.fromJson(json['applied_effect'])
          : null,
      resourceChanges: json['resource_changes'] != null
          ? (json['resource_changes'] as List)
              .map((e) => ResourceChange.fromJson(e))
              .toList()
          : null,
    );
  }

  /// 從 CardUseApiResult 建立
  factory CardUseResult.fromApiResult(CardUseApiResult apiResult) {
    return CardUseResult(
      success: apiResult.success,
      message: apiResult.message,
      appliedEffect: apiResult.appliedEffect,
      resourceChanges: apiResult.resourceChanges,
    );
  }
}

/// 卡牌狀態管理 Provider
class CardProvider with ChangeNotifier {
  final _api = ApiService();
  final _ws = WebSocketService();

  // ==================== 狀態 ====================

  /// 所有卡牌定義（從後端載入）
  Map<String, GameCard> _cardDefinitions = {};

  /// 玩家手牌
  List<HandCard> _hand = [];

  /// 已使用的卡牌記錄
  List<CardUseRecord> _usedCards = [];

  /// 當前選中的卡牌（準備使用）
  HandCard? _selectedCard;

  /// 當前選中的目標玩家 ID 列表
  List<String> _selectedTargets = [];

  /// 卡牌庫剩餘數量
  int _deckRemaining = 0;

  /// 棄牌堆數量
  int _discardPileCount = 0;

  /// 角色專屬卡列表
  List<GameCard> _characterCards = [];

  /// 載入狀態
  bool _isLoading = false;

  /// 錯誤訊息
  String? _error;

  /// 房間與玩家資訊
  String? _roomCode;
  String? _playerId;

  /// 最近的卡牌使用動畫資料
  CardAnimationData? _lastCardAnimation;

  // ==================== Getters ====================

  Map<String, GameCard> get cardDefinitions =>
      Map.unmodifiable(_cardDefinitions);
  List<HandCard> get hand => List.unmodifiable(_hand);
  List<CardUseRecord> get usedCards => List.unmodifiable(_usedCards);
  HandCard? get selectedCard => _selectedCard;
  List<String> get selectedTargets => List.unmodifiable(_selectedTargets);
  int get deckRemaining => _deckRemaining;
  int get discardPileCount => _discardPileCount;
  List<GameCard> get characterCards => List.unmodifiable(_characterCards);
  bool get isLoading => _isLoading;
  String? get error => _error;
  CardAnimationData? get lastCardAnimation => _lastCardAnimation;

  /// 可用手牌（未使用的）
  List<HandCard> get availableCards => _hand.where((c) => !c.isUsed).toList();

  /// 可用手牌數量（未使用的）
  int get availableCardCount => availableCards.length;

  /// 已使用卡牌數量
  int get usedCount => _hand.where((c) => c.isUsed).length;

  /// 是否有選中卡牌
  bool get hasSelectedCard => _selectedCard != null;

  /// 是否選擇了足夠的目標
  bool get hasEnoughTargets {
    if (_selectedCard == null) return false;
    final card = _selectedCard!.card;
    if (card.targetType == CardTargetType.self ||
        card.targetType == CardTargetType.none) {
      return true;
    }
    return _selectedTargets.length >= card.targetCount;
  }

  // ==================== 初始化 ====================

  /// 設置房間資訊
  void setRoomInfo({
    required String roomCode,
    required String playerId,
  }) {
    _roomCode = roomCode;
    _playerId = playerId;
  }

  /// 初始化卡牌監聽
  void initCardListeners() {
    _ws.eventStream.listen(_handleWSEvent);
  }

  /// 處理 WebSocket 事件
  void _handleWSEvent(WSEvent event) {
    switch (event.type) {
      case WSEventType.cardUsed:
        _onCardUsed(event.data);
        break;
      case WSEventType.cardBlocked:
        _onCardBlocked(event.data);
        break;
      case WSEventType.cardsDrawn:
        _onCardsDrawn(event.data);
        break;
      case WSEventType.resourceChange:
        // 資源變化由 ResourceProvider 處理
        break;
      default:
        break;
    }
  }

  // ==================== 卡牌定義載入 ====================

  /// 載入所有卡牌定義
  Future<void> loadCardDefinitions() async {
    _setLoading(true);
    _clearError();

    try {
      final cards = await _api.getCardDefinitions();
      _cardDefinitions = {for (var card in cards) card.id: card};
      notifyListeners();
    } catch (e) {
      _setError('載入卡牌定義失敗: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 根據 ID 取得卡牌定義
  GameCard? getCardById(String id) => _cardDefinitions[id];

  /// 取得特定類型的卡牌
  List<GameCard> getCardsByType(CardType type) {
    return _cardDefinitions.values.where((c) => c.type == type).toList();
  }

  /// 取得特定稀有度的卡牌
  List<GameCard> getCardsByRarity(CardRarity rarity) {
    return _cardDefinitions.values.where((c) => c.rarity == rarity).toList();
  }

  /// 取得特定角色的專屬卡
  List<GameCard> getCharacterCards(String characterType) {
    return _cardDefinitions.values
        .where((c) => c.isCharacterSpecific && c.characterType == characterType)
        .toList();
  }

  // ==================== 手牌管理 ====================

  /// 抽牌（遊戲開始時呼叫）
  Future<bool> drawCards({
    required int count,
    bool includeCharacterCards = true,
  }) async {
    if (_roomCode == null || _playerId == null) return false;

    _setLoading(true);
    _clearError();

    try {
      final result = await _api.drawCards(
        roomCode: _roomCode!,
        playerId: _playerId!,
        count: count,
        includeCharacterCards: includeCharacterCards,
      );

      _hand = result.drawnCards;
      _characterCards = result.characterCards;
      _deckRemaining = result.deckRemaining;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('抽牌失敗: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 載入當前手牌（重新連線時）
  Future<void> loadHand() async {
    if (_roomCode == null || _playerId == null) return;

    _setLoading(true);
    _clearError();

    try {
      final result = await _api.getPlayerHand(
        roomCode: _roomCode!,
        playerId: _playerId!,
      );

      _hand = result.hand;
      _characterCards = result.characterCards;
      notifyListeners();
    } catch (e) {
      _setError('載入手牌失敗: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 補充手牌到指定數量
  Future<bool> refillHand({required int targetCount}) async {
    if (_roomCode == null || _playerId == null) return false;

    final currentCount = availableCardCount;
    if (currentCount >= targetCount) return true;

    return drawCards(count: targetCount - currentCount);
  }

  // ==================== 卡牌選擇 ====================

  /// 選擇卡牌
  void selectCard(HandCard card) {
    if (card.isUsed) return;

    _selectedCard = card;
    _selectedTargets = [];

    // 如果是自己為目標的卡牌，自動設定目標
    if (card.card.targetType == CardTargetType.self) {
      _selectedTargets = [_playerId!];
    }

    notifyListeners();
  }

  /// 取消選擇卡牌
  void deselectCard() {
    _selectedCard = null;
    _selectedTargets = [];
    notifyListeners();
  }

  /// 選擇目標
  void selectTarget(String targetId) {
    if (_selectedCard == null) return;

    final card = _selectedCard!.card;
    final maxTargets = card.targetCount;

    // 檢查是否已選擇此目標
    if (_selectedTargets.contains(targetId)) {
      _selectedTargets.remove(targetId);
    } else if (_selectedTargets.length < maxTargets) {
      _selectedTargets.add(targetId);
    } else if (maxTargets == 1) {
      // 單目標卡牌，替換目標
      _selectedTargets = [targetId];
    }

    notifyListeners();
  }

  /// 清除目標選擇
  void clearTargets() {
    _selectedTargets = [];
    notifyListeners();
  }

  // ==================== 卡牌使用 ====================

  /// 檢查是否可以使用指定卡牌
  /// 根據 Task 1.4 規格要求
  bool canUseCard(String cardId, PlayerResources resources) {
    // 找到卡牌
    final handCard = _hand.firstWhere(
      (c) => c.card.id == cardId || c.instanceId == cardId,
      orElse: () => const HandCard(
        instanceId: '',
        card: GameCard(
          id: '',
          name: '',
          type: CardType.attack,
          rarity: CardRarity.n,
          category: CardCategory.universal,
          targetType: CardTargetType.singleEnemy,
          effect: CardEffect(effectType: '', description: ''),
        ),
      ),
    );

    // 卡牌不存在
    if (handCard.instanceId.isEmpty) return false;

    // 卡牌已使用
    if (handCard.isUsed) return false;

    // 玩家已政治死亡
    if (resources.isPoliticallyDead) return false;

    // 檢查資源是否足夠
    return resources.canUseCard(
      influenceCost: handCard.card.influenceCost,
      goldCost: handCard.card.goldCost,
    );
  }

  /// 使用卡牌
  Future<CardUseResult> useCard({
    required PlayerResources resources,
  }) async {
    if (_selectedCard == null) {
      return const CardUseResult(success: false, message: '未選擇卡牌');
    }

    if (!hasEnoughTargets) {
      return const CardUseResult(success: false, message: '請選擇目標');
    }

    final card = _selectedCard!.card;

    // 檢查資源是否足夠
    if (!resources.canUseCard(
      influenceCost: card.influenceCost,
      goldCost: card.goldCost,
    )) {
      return const CardUseResult(success: false, message: '資源不足');
    }

    if (_roomCode == null || _playerId == null) {
      return const CardUseResult(success: false, message: '房間資訊不完整');
    }

    _setLoading(true);
    _clearError();

    try {
      final apiResult = await _api.useCard(
        roomCode: _roomCode!,
        playerId: _playerId!,
        cardInstanceId: _selectedCard!.instanceId,
        targetIds: _selectedTargets,
      );

      // 轉換 API 結果
      final result = CardUseResult.fromApiResult(apiResult);

      if (result.success) {
        // 標記卡牌為已使用
        _markCardAsUsed(_selectedCard!.instanceId);

        // 記錄使用歷史
        _usedCards.add(CardUseRecord(
          card: card,
          targetIds: List.from(_selectedTargets),
          usedAt: DateTime.now(),
          result: result,
        ));

        // 設置動畫資料
        _lastCardAnimation = CardAnimationData(
          card: card,
          sourcePlayerId: _playerId!,
          targetPlayerIds: List.from(_selectedTargets),
          effect: result.appliedEffect,
        );

        // 清除選擇
        deselectCard();
      }

      notifyListeners();
      return result;
    } catch (e) {
      _setError('使用卡牌失敗: $e');
      return CardUseResult(success: false, message: e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// 使用防禦卡（回應攻擊）
  Future<CardUseResult> useDefenseCard({
    required String attackCardId,
    required String attackerId,
    required HandCard defenseCard,
    required PlayerResources resources,
  }) async {
    if (defenseCard.isUsed) {
      return const CardUseResult(success: false, message: '卡牌已使用');
    }

    final card = defenseCard.card;
    if (card.type != CardType.defense) {
      return const CardUseResult(success: false, message: '這不是防禦卡');
    }

    if (!resources.canUseCard(
      influenceCost: card.influenceCost,
      goldCost: card.goldCost,
    )) {
      return const CardUseResult(success: false, message: '資源不足');
    }

    if (_roomCode == null || _playerId == null) {
      return const CardUseResult(success: false, message: '房間資訊不完整');
    }

    _setLoading(true);
    _clearError();

    try {
      final apiResult = await _api.useDefenseCard(
        roomCode: _roomCode!,
        playerId: _playerId!,
        cardInstanceId: defenseCard.instanceId,
        attackCardId: attackCardId,
        attackerId: attackerId,
      );

      // 轉換 API 結果
      final result = CardUseResult.fromApiResult(apiResult);

      if (result.success) {
        _markCardAsUsed(defenseCard.instanceId);
      }

      notifyListeners();
      return result;
    } catch (e) {
      _setError('使用防禦卡失敗: $e');
      return CardUseResult(success: false, message: e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// 標記卡牌為已使用
  void _markCardAsUsed(String instanceId) {
    final index = _hand.indexWhere((c) => c.instanceId == instanceId);
    if (index != -1) {
      _hand[index] = _hand[index].markAsUsed();
      _discardPileCount++;
    }
  }

  // ==================== WebSocket 事件處理 ====================

  void _onCardUsed(Map<String, dynamic> data) {
    final usedByPlayerId = data['player_id'] ?? data['playerId'];
    final cardId = data['card_id'] ?? data['cardId'];
    final targetIds = (data['target_ids'] ?? data['targetIds'] ?? [])
        .cast<String>()
        .toList();

    final card = _cardDefinitions[cardId];
    if (card != null) {
      // 設置動畫資料（其他玩家使用卡牌）
      _lastCardAnimation = CardAnimationData(
        card: card,
        sourcePlayerId: usedByPlayerId,
        targetPlayerIds: targetIds,
        effect: data['effect'] != null
            ? CardEffect.fromJson(data['effect'])
            : null,
      );
      notifyListeners();
    }
  }

  void _onCardBlocked(Map<String, dynamic> data) {
    final defenderId = data['defender_id'] ?? data['defenderId'];
    final defenseCardId = data['card_id'] ?? data['cardId'];

    final card = _cardDefinitions[defenseCardId];
    if (card != null) {
      _lastCardAnimation = CardAnimationData(
        card: card,
        sourcePlayerId: defenderId,
        targetPlayerIds: [],
        isBlock: true,
      );
      notifyListeners();
    }
  }

  void _onCardsDrawn(Map<String, dynamic> data) {
    final count = data['count'] as int? ?? 0;
    _deckRemaining = data['deck_remaining'] ?? _deckRemaining;

    // 如果是當前玩家抽牌，重新載入手牌
    final playerId = data['player_id'] ?? data['playerId'];
    if (playerId == _playerId) {
      loadHand();
    }

    debugPrint('玩家 $playerId 抽了 $count 張卡');
    notifyListeners();
  }

  // ==================== 動畫控制 ====================

  /// 清除動畫資料
  void clearCardAnimation() {
    _lastCardAnimation = null;
    notifyListeners();
  }

  // ==================== 工具方法 ====================

  /// 取得手牌中特定類型的卡牌
  List<HandCard> getHandCardsByType(CardType type) {
    return _hand.where((c) => !c.isUsed && c.card.type == type).toList();
  }

  /// 取得可用的防禦卡
  List<HandCard> getAvailableDefenseCards() {
    return getHandCardsByType(CardType.defense);
  }

  /// 檢查是否有可用的防禦卡
  bool hasDefenseCard() {
    return getAvailableDefenseCards().isNotEmpty;
  }

  /// 取得卡牌使用歷史
  List<CardUseRecord> getCardHistory({int? limit}) {
    if (limit != null && limit < _usedCards.length) {
      return _usedCards.sublist(_usedCards.length - limit);
    }
    return List.from(_usedCards);
  }

  // ==================== 狀態管理 ====================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    debugPrint('CardProvider Error: $message');
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// 重置卡牌狀態
  void reset() {
    _cardDefinitions = {};
    _hand = [];
    _usedCards = [];
    _selectedCard = null;
    _selectedTargets = [];
    _deckRemaining = 0;
    _discardPileCount = 0;
    _characterCards = [];
    _lastCardAnimation = null;
    _roomCode = null;
    _playerId = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    reset();
    super.dispose();
  }
}

// ==================== 輔助類別 ====================

/// 卡牌使用記錄
class CardUseRecord {
  final GameCard card;
  final List<String> targetIds;
  final DateTime usedAt;
  final CardUseResult result;

  const CardUseRecord({
    required this.card,
    required this.targetIds,
    required this.usedAt,
    required this.result,
  });

  @override
  String toString() =>
      'CardUseRecord(${card.name} → $targetIds at $usedAt)';
}

/// 卡牌動畫資料
class CardAnimationData {
  final GameCard card;
  final String sourcePlayerId;
  final List<String> targetPlayerIds;
  final CardEffect? effect;
  final bool isBlock;

  const CardAnimationData({
    required this.card,
    required this.sourcePlayerId,
    required this.targetPlayerIds,
    this.effect,
    this.isBlock = false,
  });
}

/// 抽牌結果
class DrawCardsResult {
  final List<HandCard> drawnCards;
  final List<GameCard> characterCards;
  final int deckRemaining;

  const DrawCardsResult({
    required this.drawnCards,
    required this.characterCards,
    required this.deckRemaining,
  });

  factory DrawCardsResult.fromJson(Map<String, dynamic> json) {
    return DrawCardsResult(
      drawnCards: (json['drawn_cards'] ?? json['drawnCards'] ?? [])
          .map<HandCard>((e) => HandCard.fromJson(e))
          .toList(),
      characterCards:
          (json['character_cards'] ?? json['characterCards'] ?? [])
              .map<GameCard>((e) => GameCard.fromJson(e))
              .toList(),
      deckRemaining: json['deck_remaining'] ?? json['deckRemaining'] ?? 0,
    );
  }
}

/// 玩家手牌結果
class PlayerHandResult {
  final List<HandCard> hand;
  final List<GameCard> characterCards;

  const PlayerHandResult({
    required this.hand,
    required this.characterCards,
  });

  factory PlayerHandResult.fromJson(Map<String, dynamic> json) {
    return PlayerHandResult(
      hand: (json['hand'] ?? [])
          .map<HandCard>((e) => HandCard.fromJson(e))
          .toList(),
      characterCards: (json['character_cards'] ?? json['characterCards'] ?? [])
          .map<GameCard>((e) => GameCard.fromJson(e))
          .toList(),
    );
  }
}
