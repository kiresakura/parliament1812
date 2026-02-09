import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/card.dart';
import '../services/haptic_service.dart';

/// 遊戲卡牌 Widget — 支援長按預覽、拖曳出牌
class GameCardWidget extends StatefulWidget {
  final GameCard card;
  final bool isPlayable;
  final VoidCallback? onTap;
  final ValueChanged<GameCard>? onDragCompleted;
  final double width;
  final double height;

  const GameCardWidget({
    super.key,
    required this.card,
    this.isPlayable = true,
    this.onTap,
    this.onDragCompleted,
    this.width = 80,
    this.height = 120,
  });

  @override
  State<GameCardWidget> createState() => _GameCardWidgetState();
}

class _GameCardWidgetState extends State<GameCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _hoverAnimation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  Color get _rarityColor {
    switch (widget.card.rarity) {
      case CardRarity.normal:
        return Parliament1812Theme.commonCardColor;
      case CardRarity.rare:
        return Parliament1812Theme.rareCardColor;
      case CardRarity.epic:
        return Parliament1812Theme.epicCardColor;
      case CardRarity.legendary:
        return Parliament1812Theme.legendaryCardColor;
    }
  }

  IconData get _typeIcon {
    switch (widget.card.type) {
      case CardType.attack:
        return Icons.gavel;
      case CardType.defense:
        return Icons.shield;
      case CardType.control:
        return Icons.lock;
      case CardType.buff:
        return Icons.arrow_upward;
      case CardType.intel:
        return Icons.search;
      case CardType.healing:
        return Icons.favorite;
      case CardType.social:
        return Icons.handshake;
      case CardType.special:
        return Icons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardContent = _buildCardContent(context);

    if (!widget.isPlayable) {
      return Opacity(opacity: 0.5, child: cardContent);
    }

    // Wrap with draggable
    return Draggable<GameCard>(
      data: widget.card,
      feedback: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(8),
        child: Transform.scale(
          scale: 1.1,
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: _buildCardContent(context, isDragging: true),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: cardContent,
      ),
      onDragStarted: () {
        HapticService.dragStart();
      },
      onDragEnd: (details) {},
      onDragCompleted: () {
        HapticService.dragAccepted();
        widget.onDragCompleted?.call(widget.card);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: () => _showCardPreview(context),
        child: AnimatedBuilder(
          animation: _hoverAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _hoverAnimation.value),
              child: cardContent,
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, {bool isDragging = false}) {
    final theme = Theme.of(context);
    final rarityColor = _rarityColor;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Parliament1812Theme.charcoal,
            Parliament1812Theme.slate,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDragging
              ? Parliament1812Theme.gold
              : rarityColor.withValues(alpha: 0.6),
          width: isDragging ? 2 : 1.5,
        ),
        boxShadow: isDragging
            ? [
                BoxShadow(
                  color: Parliament1812Theme.gold.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 頂部：稀有度 + 類型圖標
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: rarityColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.card.rarity.symbol,
                    style: TextStyle(
                      color: rarityColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(_typeIcon, size: 14, color: rarityColor),
              ],
            ),

            // 中間：卡牌名稱
            Expanded(
              child: Center(
                child: Text(
                  widget.card.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // 底部：費用
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.card.influenceCost > 0) ...[
                  Icon(Icons.flash_on,
                      size: 12, color: Parliament1812Theme.influenceColor),
                  Text(
                    '${widget.card.influenceCost}',
                    style: TextStyle(
                      color: Parliament1812Theme.influenceColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                if (widget.card.goldCost > 0) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.monetization_on,
                      size: 12, color: Parliament1812Theme.gold),
                  Text(
                    '${widget.card.goldCost}',
                    style: TextStyle(
                      color: Parliament1812Theme.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 卡片長按預覽 — 放大顯示效果說明
  void _showCardPreview(BuildContext context) {
    HapticService.cardPreview();
    final theme = Theme.of(context);
    final rarityColor = _rarityColor;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 280,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Parliament1812Theme.charcoal,
                      Parliament1812Theme.slate,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: rarityColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: rarityColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 頂部：名稱 + 稀有度
                    Row(
                      children: [
                        Icon(_typeIcon, color: rarityColor, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.card.name,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: rarityColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: rarityColor.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            widget.card.rarity.displayName,
                            style: TextStyle(
                              color: rarityColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Divider(
                        color:
                            Parliament1812Theme.lightBrown.withValues(alpha: 0.3)),
                    const SizedBox(height: 12),

                    // 效果說明
                    Text(
                      widget.card.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 費用資訊
                    Row(
                      children: [
                        if (widget.card.influenceCost > 0)
                          _buildCostChip(
                            icon: Icons.flash_on,
                            value: widget.card.influenceCost,
                            label: '影響力',
                            color: Parliament1812Theme.influenceColor,
                          ),
                        if (widget.card.goldCost > 0) ...[
                          const SizedBox(width: 8),
                          _buildCostChip(
                            icon: Icons.monetization_on,
                            value: widget.card.goldCost,
                            label: '金幣',
                            color: Parliament1812Theme.gold,
                          ),
                        ],
                        if (widget.card.baseValue > 0 &&
                            widget.card.baseValue < 900) ...[
                          const SizedBox(width: 8),
                          _buildCostChip(
                            icon: Icons.flash_on,
                            value: widget.card.baseValue,
                            label: '效果值',
                            color: Parliament1812Theme.darkRed,
                          ),
                        ],
                      ],
                    ),

                    // 角色專屬標示
                    if (widget.card.roleId != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              Parliament1812Theme.gold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Parliament1812Theme.gold
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '⭐ 角色專屬卡',
                          style: TextStyle(
                            color: Parliament1812Theme.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCostChip({
    required IconData icon,
    required int value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$value',
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// 出牌目標區域 — DragTarget
class CardPlayZone extends StatefulWidget {
  final ValueChanged<GameCard>? onCardPlayed;
  final String label;

  const CardPlayZone({
    super.key,
    this.onCardPlayed,
    this.label = '拖曳至此出牌',
  });

  @override
  State<CardPlayZone> createState() => _CardPlayZoneState();
}

class _CardPlayZoneState extends State<CardPlayZone> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DragTarget<GameCard>(
      onWillAcceptWithDetails: (details) {
        setState(() => _isHovering = true);
        return true;
      },
      onLeave: (_) {
        setState(() => _isHovering = false);
      },
      onAcceptWithDetails: (details) {
        setState(() => _isHovering = false);
        widget.onCardPlayed?.call(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isHovering
                ? Parliament1812Theme.gold.withValues(alpha: 0.15)
                : Parliament1812Theme.charcoal.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovering
                  ? Parliament1812Theme.gold
                  : Parliament1812Theme.lightBrown.withValues(alpha: 0.3),
              width: _isHovering ? 2 : 1,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isHovering ? Icons.check_circle : Icons.add_circle_outline,
                  color: _isHovering
                      ? Parliament1812Theme.gold
                      : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  _isHovering ? '放開出牌' : widget.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _isHovering
                        ? Parliament1812Theme.gold
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight:
                        _isHovering ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
