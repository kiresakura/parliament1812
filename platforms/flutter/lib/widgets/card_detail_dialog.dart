import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../models/card.dart';

/// 卡牌詳情彈窗 Widget
/// 1812 國會風雲 - 顯示卡牌完整資訊的 Modal Dialog
class CardDetailDialog extends StatelessWidget {
  /// 卡牌資料
  final GameCard card;

  /// 是否可以使用此卡牌
  final bool canUse;

  /// 使用卡牌的回調
  final VoidCallback? onUse;

  /// 關閉彈窗的回調
  final VoidCallback? onClose;

  const CardDetailDialog({
    super.key,
    required this.card,
    this.canUse = true,
    this.onUse,
    this.onClose,
  });

  /// 顯示卡牌詳情彈窗
  static Future<void> show({
    required BuildContext context,
    required GameCard card,
    bool canUse = true,
    VoidCallback? onUse,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CardDetailDialog(
        card: card,
        canUse: canUse,
        onUse: onUse,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppTheme.accentGold, width: 2),
          left: BorderSide(color: AppTheme.accentGold, width: 1),
          right: BorderSide(color: AppTheme.accentGold, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCardHeader(),
                  const SizedBox(height: 16),
                  _buildCardImage(),
                  const SizedBox(height: 16),
                  _buildEffectSection(),
                  const SizedBox(height: 16),
                  _buildCostSection(),
                  const SizedBox(height: 16),
                  _buildTargetInfo(),
                  if (card.flavorText != null) ...[
                    const SizedBox(height: 16),
                    _buildFlavorText(),
                  ],
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .slideY(begin: 0.3, end: 0, duration: 300.ms, curve: Curves.easeOutCubic)
        .fadeIn(duration: 200.ms);
  }

  /// 拖動指示條
  Widget _buildDragHandle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.accentGold.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  /// 卡牌標題區域
  Widget _buildCardHeader() {
    return Row(
      children: [
        // 卡牌類型圖示
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getTypeColor(card.type).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getTypeColor(card.type).withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              card.type.icon,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 卡牌名稱和稀有度
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.name,
                style: AppTheme.headlineMedium.copyWith(
                  color: _getRarityColor(card.rarity),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildRarityBadge(),
                  const SizedBox(width: 8),
                  _buildCategoryBadge(),
                ],
              ),
            ],
          ),
        ),
        // 關閉按鈕
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  /// 稀有度標籤
  Widget _buildRarityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getRarityColor(card.rarity).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _getRarityColor(card.rarity).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        card.rarity.displayName,
        style: AppTheme.bodySmall.copyWith(
          color: _getRarityColor(card.rarity),
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  /// 類別標籤
  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.panelBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppTheme.textSecondary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        card.category.displayName,
        style: AppTheme.bodySmall.copyWith(
          color: AppTheme.textSecondary,
          fontSize: 11,
        ),
      ),
    );
  }

  /// 卡牌圖片區域
  Widget _buildCardImage() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppTheme.panelBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getRarityColor(card.rarity).withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getRarityColor(card.rarity).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: card.imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                card.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholderImage(),
              ),
            )
          : _buildPlaceholderImage(),
    );
  }

  /// 佔位圖片
  Widget _buildPlaceholderImage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card.type.icon,
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 8),
          Text(
            card.type.displayName,
            style: AppTheme.labelMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 效果說明區域
  Widget _buildEffectSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.panelBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: AppTheme.accentGold,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '卡牌效果',
                style: AppTheme.labelMedium.copyWith(
                  color: AppTheme.accentGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            card.effect.description,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textPrimary,
              height: 1.5,
            ),
          ),
          if (card.effect.value case final effectValue? when effectValue > 0) ...[
            const SizedBox(height: 12),
            _buildEffectValue(),
          ],
          if (card.effect.condition != null) ...[
            const SizedBox(height: 12),
            _buildCondition(),
          ],
        ],
      ),
    );
  }

  /// 效果數值
  Widget _buildEffectValue() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _getEffectTypeColor(card.effect.effectType).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getEffectTypeIcon(card.effect.effectType),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 6),
              Text(
                '${card.effect.effectType == 'heal' ? '+' : ''}${card.effect.value}',
                style: AppTheme.labelMedium.copyWith(
                  color: _getEffectTypeColor(card.effect.effectType),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (card.effect.duration case final duration? when duration > 0) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '$duration 回合',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// 使用條件
  Widget _buildCondition() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.warningColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            size: 16,
            color: AppTheme.warningColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              card.effect.condition!,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.warningColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 消耗區域
  Widget _buildCostSection() {
    return Row(
      children: [
        // 影響力消耗
        Expanded(
          child: _buildCostItem(
            icon: '🌟',
            label: '影響力',
            value: card.influenceCost,
            color: AppTheme.influenceBlue,
          ),
        ),
        const SizedBox(width: 12),
        // 金幣消耗
        Expanded(
          child: _buildCostItem(
            icon: '💰',
            label: '金幣',
            value: card.goldCost,
            color: AppTheme.goldYellow,
          ),
        ),
      ],
    );
  }

  /// 單個消耗項目
  Widget _buildCostItem({
    required String icon,
    required String label,
    required int value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  '$value',
                  style: AppTheme.headlineMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 目標資訊
  Widget _buildTargetInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.panelBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textSecondary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.gps_fixed,
            size: 20,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '目標類型',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  _getTargetTypeDescription(card.targetType),
                  style: AppTheme.labelMedium.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (card.targetCount > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '×${card.targetCount}',
                style: AppTheme.labelMedium.copyWith(
                  color: AppTheme.accentGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 風味文字
  Widget _buildFlavorText() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.panelBackground.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textTertiary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '『',
            style: TextStyle(
              fontSize: 24,
              color: AppTheme.textTertiary,
              fontFamily: 'NotoSerifTC',
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                card.flavorText!,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const Text(
            '』',
            style: TextStyle(
              fontSize: 24,
              color: AppTheme.textTertiary,
              fontFamily: 'NotoSerifTC',
            ),
          ),
        ],
      ),
    );
  }

  /// 操作按鈕
  Widget _buildActionButtons() {
    return Row(
      children: [
        // 關閉按鈕
        Expanded(
          child: OutlinedButton(
            onPressed: onClose,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(
                color: AppTheme.accentGold.withValues(alpha: 0.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '關閉',
              style: AppTheme.labelMedium.copyWith(
                color: AppTheme.accentGold,
              ),
            ),
          ),
        ),
        if (onUse != null) ...[
          const SizedBox(width: 12),
          // 使用按鈕
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: canUse ? onUse : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: canUse
                    ? AppTheme.accentGold
                    : AppTheme.textTertiary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    canUse ? '使用卡牌' : '無法使用',
                    style: AppTheme.labelMedium.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ==================== Helper Methods ====================

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

  Color _getTypeColor(CardType type) {
    switch (type) {
      case CardType.attack:
        return AppTheme.errorColor;
      case CardType.defense:
        return AppTheme.influenceBlue;
      case CardType.control:
        return AppTheme.raritySR;
      case CardType.buff:
        return AppTheme.successColor;
      case CardType.intel:
        return AppTheme.warningColor;
      case CardType.social:
        return AppTheme.accentGold;
      case CardType.heal:
        return AppTheme.successColor;
      case CardType.special:
        return AppTheme.raritySSR;
    }
  }

  Color _getEffectTypeColor(String effectType) {
    switch (effectType) {
      case 'damage':
        return AppTheme.errorColor;
      case 'heal':
        return AppTheme.successColor;
      case 'buff':
        return AppTheme.influenceBlue;
      case 'debuff':
        return AppTheme.warningColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _getEffectTypeIcon(String effectType) {
    switch (effectType) {
      case 'damage':
        return '⚔️';
      case 'heal':
        return '💚';
      case 'buff':
        return '⬆️';
      case 'debuff':
        return '⬇️';
      default:
        return '✨';
    }
  }

  String _getTargetTypeDescription(CardTargetType targetType) {
    switch (targetType) {
      case CardTargetType.self:
        return '自己';
      case CardTargetType.singleEnemy:
        return '單一敵人';
      case CardTargetType.singleAlly:
        return '單一盟友';
      case CardTargetType.singleAny:
        return '任意玩家';
      case CardTargetType.allEnemies:
        return '所有敵人';
      case CardTargetType.allAllies:
        return '所有盟友';
      case CardTargetType.allPlayers:
        return '所有玩家';
      case CardTargetType.none:
        return '無需目標';
    }
  }
}
