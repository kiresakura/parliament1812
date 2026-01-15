import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../models/card.dart';

/// 遊戲卡牌 Widget
/// 1812 國會風雲 - 維多利亞風格卡牌元件
class CardWidget extends StatefulWidget {
  final GameCard card;
  final bool isSelected;
  final bool isDisabled;
  final bool showCost;
  final bool isCompact;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const CardWidget({
    super.key,
    required this.card,
    this.isSelected = false,
    this.isDisabled = false,
    this.showCost = true,
    this.isCompact = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<CardWidget> createState() => _CardWidgetState();
}

class _CardWidgetState extends State<CardWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final card = widget.card;

    return GestureDetector(
      onTap: widget.isDisabled ? null : widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()
          ..scale(_isPressed ? 0.95 : 1.0),
        child: widget.isCompact
            ? _buildCompactCard(card)
            : _buildFullCard(card),
      ),
    );
  }

  /// 完整版卡牌（用於手牌展示、卡牌詳情）
  Widget _buildFullCard(GameCard card) {
    return Container(
      width: 140,
      height: 200,
      decoration: _getCardDecoration(),
      child: Stack(
        children: [
          // 背景紋理
          _buildBackgroundTexture(),

          // 卡牌內容
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 頂部：類型圖示 + 稀有度
                _buildCardHeader(card),

                const SizedBox(height: 6),

                // 卡牌名稱
                _buildCardName(card),

                const SizedBox(height: 8),

                // 卡牌效果描述
                Expanded(
                  child: _buildEffectDescription(card),
                ),

                // 底部：消耗
                if (widget.showCost) _buildCostRow(card),
              ],
            ),
          ),

          // 選中效果
          if (widget.isSelected) _buildSelectedOverlay(),

          // 禁用效果
          if (widget.isDisabled) _buildDisabledOverlay(),
        ],
      ),
    )
        .animate(target: widget.isSelected ? 1 : 0)
        .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.05, 1.05), duration: 200.ms);
  }

  /// 精簡版卡牌（用於牌組列表、快速預覽）
  Widget _buildCompactCard(GameCard card) {
    return Container(
      width: 100,
      height: 140,
      decoration: _getCardDecoration(),
      child: Stack(
        children: [
          _buildBackgroundTexture(),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 類型 + 稀有度
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      card.type.icon,
                      style: const TextStyle(fontSize: 16),
                    ),
                    _buildRarityBadge(card.rarity, isSmall: true),
                  ],
                ),
                const SizedBox(height: 4),
                // 名稱
                Text(
                  card.name,
                  style: AppTheme.bodySmall.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentGold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                // 消耗
                if (widget.showCost) _buildCompactCost(card),
              ],
            ),
          ),
          if (widget.isSelected) _buildSelectedOverlay(),
          if (widget.isDisabled) _buildDisabledOverlay(),
        ],
      ),
    );
  }

  /// 卡牌裝飾
  BoxDecoration _getCardDecoration() {
    final rarityColor = _getRarityColor(widget.card.rarity);

    return BoxDecoration(
      color: AppTheme.cardBackground,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: widget.isSelected
            ? AppTheme.accentGold
            : rarityColor.withOpacity(0.6),
        width: widget.isSelected ? 3 : 2,
      ),
      boxShadow: [
        BoxShadow(
          color: widget.isSelected
              ? AppTheme.accentGold.withOpacity(0.4)
              : Colors.black.withOpacity(0.3),
          blurRadius: widget.isSelected ? 12 : 6,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// 背景紋理
  Widget _buildBackgroundTexture() {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Opacity(
          opacity: 0.1,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getRarityColor(widget.card.rarity),
                  AppTheme.cardBackground,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 卡牌頂部（類型 + 稀有度）
  Widget _buildCardHeader(GameCard card) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 類型圖示 + 名稱
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _getTypeColor(card.type).withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(card.type.icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                card.type.displayName,
                style: AppTheme.bodySmall.copyWith(
                  fontSize: 10,
                  color: _getTypeColor(card.type),
                ),
              ),
            ],
          ),
        ),
        // 稀有度
        _buildRarityBadge(card.rarity),
      ],
    );
  }

  /// 稀有度徽章
  Widget _buildRarityBadge(CardRarity rarity, {bool isSmall = false}) {
    final color = _getRarityColor(rarity);
    final size = isSmall ? 16.0 : 20.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.2),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Center(
        child: Text(
          rarity.name.toUpperCase(),
          style: TextStyle(
            fontSize: isSmall ? 8 : 10,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  /// 卡牌名稱
  Widget _buildCardName(GameCard card) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.accentGold.withOpacity(0.3)),
          bottom: BorderSide(color: AppTheme.accentGold.withOpacity(0.3)),
        ),
      ),
      child: Text(
        card.name,
        style: AppTheme.labelLarge.copyWith(
          fontSize: 13,
          color: AppTheme.accentGold,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// 效果描述
  Widget _buildEffectDescription(GameCard card) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        card.effect.description,
        style: AppTheme.bodySmall.copyWith(
          fontSize: 10,
          height: 1.3,
          color: AppTheme.textSecondary,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.fade,
      ),
    );
  }

  /// 消耗列
  Widget _buildCostRow(GameCard card) {
    return Container(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (card.influenceCost > 0) ...[
            _buildCostBadge('🌟', card.influenceCost, AppTheme.influenceBlue),
            if (card.goldCost > 0) const SizedBox(width: 8),
          ],
          if (card.goldCost > 0)
            _buildCostBadge('💰', card.goldCost, AppTheme.goldYellow),
          if (card.influenceCost == 0 && card.goldCost == 0)
            Text(
              '免費',
              style: AppTheme.bodySmall.copyWith(
                fontSize: 10,
                color: Colors.green,
              ),
            ),
        ],
      ),
    );
  }

  /// 消耗徽章
  Widget _buildCostBadge(String icon, int cost, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 2),
          Text(
            '$cost',
            style: AppTheme.bodySmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 精簡消耗顯示
  Widget _buildCompactCost(GameCard card) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (card.influenceCost > 0)
          Text('🌟${card.influenceCost}',
              style: const TextStyle(fontSize: 10)),
        if (card.influenceCost > 0 && card.goldCost > 0)
          const SizedBox(width: 4),
        if (card.goldCost > 0)
          Text('💰${card.goldCost}', style: const TextStyle(fontSize: 10)),
        if (card.influenceCost == 0 && card.goldCost == 0)
          Text('免費',
              style: AppTheme.bodySmall.copyWith(
                  fontSize: 9, color: Colors.green)),
      ],
    );
  }

  /// 選中效果層
  Widget _buildSelectedOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.accentGold,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentGold.withOpacity(0.5),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  /// 禁用效果層
  Widget _buildDisabledOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.black.withOpacity(0.5),
        ),
        child: Center(
          child: Icon(
            Icons.block,
            color: Colors.red.withOpacity(0.7),
            size: widget.isCompact ? 24 : 32,
          ),
        ),
      ),
    );
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

  /// 取得類型顏色
  Color _getTypeColor(CardType type) {
    switch (type) {
      case CardType.attack:
        return Colors.red;
      case CardType.defense:
        return Colors.blue;
      case CardType.control:
        return Colors.purple;
      case CardType.buff:
        return Colors.green;
      case CardType.intel:
        return Colors.cyan;
      case CardType.social:
        return Colors.orange;
      case CardType.heal:
        return Colors.lightGreen;
      case CardType.special:
        return AppTheme.accentGold;
    }
  }
}

/// 卡牌翻轉動畫 Widget
class FlippableCardWidget extends StatefulWidget {
  final GameCard card;
  final bool showFront;
  final VoidCallback? onFlipComplete;
  final VoidCallback? onTap;

  const FlippableCardWidget({
    super.key,
    required this.card,
    this.showFront = true,
    this.onFlipComplete,
    this.onTap,
  });

  @override
  State<FlippableCardWidget> createState() => _FlippableCardWidgetState();
}

class _FlippableCardWidgetState extends State<FlippableCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showFrontSide = true;

  @override
  void initState() {
    super.initState();
    _showFrontSide = widget.showFront;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFlipComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(FlippableCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showFront != oldWidget.showFront) {
      _flip();
    }
  }

  void _flip() {
    if (_controller.isAnimating) return;

    if (_showFrontSide) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _showFrontSide = !_showFrontSide;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ?? _flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * 3.1415926;
          final isBack = angle > 1.5707963; // 90 degrees

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: isBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(3.1415926),
                    child: CardWidget(card: widget.card),
                  )
                : _buildCardBack(),
          );
        },
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      width: 140,
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.primaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentGold, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.gavel,
              size: 48,
              color: AppTheme.accentGold,
            ),
            const SizedBox(height: 8),
            Text(
              '1812',
              style: AppTheme.headlineMedium.copyWith(
                fontSize: 20,
                color: AppTheme.accentGold,
              ),
            ),
            Text(
              '國會風雲',
              style: AppTheme.bodySmall.copyWith(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
