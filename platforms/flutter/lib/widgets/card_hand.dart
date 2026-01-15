import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../models/card.dart';
import 'card_widget.dart';

/// 手牌區 Widget
/// 1812 國會風雲 - 顯示玩家手牌的底部區域
class CardHand extends StatefulWidget {
  /// 玩家手牌列表
  final List<HandCard> cards;

  /// 當前選中的卡牌 ID
  final String? selectedCardId;

  /// 玩家可用的影響力（用於判斷是否能使用卡牌）
  final int availableInfluence;

  /// 玩家可用的金幣（用於判斷是否能使用卡牌）
  final int availableGold;

  /// 是否可以使用卡牌（如：是否輪到玩家回合）
  final bool canUseCards;

  /// 卡牌被點擊時的回調
  final void Function(HandCard card)? onCardTap;

  /// 卡牌被長按時的回調（顯示詳情）
  final void Function(HandCard card)? onCardLongPress;

  /// 卡牌被選中確認使用時的回調
  final void Function(HandCard card)? onCardUse;

  /// 是否展開顯示
  final bool isExpanded;

  /// 切換展開狀態的回調
  final VoidCallback? onToggleExpand;

  const CardHand({
    super.key,
    required this.cards,
    this.selectedCardId,
    this.availableInfluence = 0,
    this.availableGold = 0,
    this.canUseCards = true,
    this.onCardTap,
    this.onCardLongPress,
    this.onCardUse,
    this.isExpanded = false,
    this.onToggleExpand,
  });

  @override
  State<CardHand> createState() => _CardHandState();
}

class _CardHandState extends State<CardHand> {
  /// 當前懸停的卡牌索引
  int? _hoveredIndex;

  /// 手牌區收合高度
  static const double _collapsedHeight = 80.0;

  /// 手牌區展開高度
  static const double _expandedHeight = 220.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      height: widget.isExpanded ? _expandedHeight : _collapsedHeight,
      decoration: _buildContainerDecoration(),
      child: Column(
        children: [
          // 展開/收合按鈕
          _buildExpandToggle(),

          // 卡牌列表區域
          Expanded(
            child: widget.cards.isEmpty
                ? _buildEmptyHand()
                : _buildCardList(),
          ),
        ],
      ),
    );
  }

  /// 容器裝飾
  BoxDecoration _buildContainerDecoration() {
    return BoxDecoration(
      color: AppTheme.cardBackground.withOpacity(0.95),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      border: Border(
        top: BorderSide(
          color: AppTheme.accentGold.withOpacity(0.5),
          width: 2,
        ),
        left: BorderSide(
          color: AppTheme.accentGold.withOpacity(0.3),
          width: 1,
        ),
        right: BorderSide(
          color: AppTheme.accentGold.withOpacity(0.3),
          width: 1,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 20,
          offset: const Offset(0, -8),
        ),
      ],
    );
  }

  /// 展開/收合切換按鈕
  Widget _buildExpandToggle() {
    return GestureDetector(
      onTap: widget.onToggleExpand,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            // 拖動指示條
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            // 手牌數量 + 圖示
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.isExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_up,
                  color: AppTheme.accentGold,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '手牌 (${widget.cards.length})',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.accentGold,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  widget.isExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_up,
                  color: AppTheme.accentGold,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 空手牌提示
  Widget _buildEmptyHand() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.style_outlined,
            size: 32,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            '手牌為空',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  /// 卡牌列表
  Widget _buildCardList() {
    return widget.isExpanded
        ? _buildExpandedCardList()
        : _buildCollapsedCardList();
  }

  /// 收合狀態：卡牌疊放顯示
  Widget _buildCollapsedCardList() {
    final cardCount = widget.cards.length;
    if (cardCount == 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // 計算卡牌偏移量使其扇形疊放
        const cardWidth = 50.0;
        final totalWidth = constraints.maxWidth;
        final overlap = cardCount > 1
            ? ((cardWidth * cardCount) - totalWidth + 40) / (cardCount - 1)
            : 0.0;
        final actualOverlap = overlap > 0 ? overlap : 0.0;
        final stackWidth = cardWidth * cardCount - actualOverlap * (cardCount - 1);
        final startX = (totalWidth - stackWidth) / 2;

        return Stack(
          children: List.generate(cardCount, (index) {
            final card = widget.cards[index];
            final isSelected = card.instanceId == widget.selectedCardId;
            final xOffset = startX + index * (cardWidth - actualOverlap);

            return Positioned(
              left: xOffset,
              top: isSelected ? 0 : 8,
              child: GestureDetector(
                onTap: () => widget.onCardTap?.call(card),
                child: _buildMiniCard(card, isSelected),
              ),
            );
          }),
        );
      },
    );
  }

  /// 迷你卡牌（收合狀態用）
  Widget _buildMiniCard(HandCard handCard, bool isSelected) {
    final card = handCard.card;
    final canAfford = _canAfford(card);
    final isDisabled = !widget.canUseCards || !canAfford || handCard.isUsed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 50,
      height: 40,
      transform: Matrix4.identity()..translate(0.0, isSelected ? -8.0 : 0.0),
      decoration: BoxDecoration(
        color: isDisabled
            ? AppTheme.cardBackground.withOpacity(0.6)
            : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected
              ? AppTheme.accentGold
              : _getRarityColor(card.rarity).withOpacity(0.6),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppTheme.accentGold.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Center(
        child: Text(
          card.type.icon,
          style: TextStyle(
            fontSize: 16,
            color: isDisabled ? Colors.grey : null,
          ),
        ),
      ),
    );
  }

  /// 展開狀態：卡牌橫向滾動
  Widget _buildExpandedCardList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.cards.length,
        itemBuilder: (context, index) {
          final handCard = widget.cards[index];
          final card = handCard.card;
          final isSelected = handCard.instanceId == widget.selectedCardId;
          final canAfford = _canAfford(card);
          final isDisabled =
              !widget.canUseCards || !canAfford || handCard.isUsed;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: MouseRegion(
              onEnter: (_) => setState(() => _hoveredIndex = index),
              onExit: (_) => setState(() => _hoveredIndex = null),
              child: Column(
                children: [
                  Expanded(
                    child: CardWidget(
                      card: card,
                      isSelected: isSelected,
                      isDisabled: isDisabled,
                      showCost: true,
                      isCompact: true,
                      onTap: () => widget.onCardTap?.call(handCard),
                      onLongPress: () => widget.onCardLongPress?.call(handCard),
                    ),
                  ),
                  // 使用按鈕（僅選中卡牌顯示）
                  if (isSelected && widget.canUseCards && canAfford)
                    _buildUseButton(handCard),
                ],
              ),
            ),
          )
              .animate(
                target: _hoveredIndex == index ? 1 : 0,
              )
              .scaleXY(begin: 1.0, end: 1.05, duration: 150.ms);
        },
      ),
    );
  }

  /// 使用按鈕
  Widget _buildUseButton(HandCard handCard) {
    return GestureDetector(
      onTap: () => widget.onCardUse?.call(handCard),
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.accentGold,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentGold.withOpacity(0.5),
              blurRadius: 8,
            ),
          ],
        ),
        child: Text(
          '使用',
          style: AppTheme.bodySmall.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.3));
  }

  /// 檢查是否能負擔卡牌消耗
  bool _canAfford(GameCard card) {
    return widget.availableInfluence >= card.influenceCost &&
        widget.availableGold >= card.goldCost;
  }

  /// 取得稀有度顏色
  Color _getRarityColor(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.n:
        return AppTheme.rarityN;
      case CardRarity.r:
        return AppTheme.rarityR;
      case CardRarity.sr:
        return AppTheme.raritySR;
      case CardRarity.ssr:
        return AppTheme.raritySSR;
    }
  }
}

/// 手牌區展開控制器
class CardHandController extends ChangeNotifier {
  bool _isExpanded = false;
  String? _selectedCardId;

  bool get isExpanded => _isExpanded;
  String? get selectedCardId => _selectedCardId;

  void toggleExpand() {
    _isExpanded = !_isExpanded;
    notifyListeners();
  }

  void expand() {
    if (!_isExpanded) {
      _isExpanded = true;
      notifyListeners();
    }
  }

  void collapse() {
    if (_isExpanded) {
      _isExpanded = false;
      notifyListeners();
    }
  }

  void selectCard(String? cardId) {
    _selectedCardId = cardId;
    notifyListeners();
  }

  void clearSelection() {
    _selectedCardId = null;
    notifyListeners();
  }
}
