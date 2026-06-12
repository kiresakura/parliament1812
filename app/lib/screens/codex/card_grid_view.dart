import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/codex_provider.dart';
import '../../services/performance_service.dart';
import '../../widgets/performance_aware.dart';
import 'card_detail_dialog.dart';

/// 稀有度顏色
Color _rarityColor(CodexRarity rarity) {
  switch (rarity) {
    case CodexRarity.common:
      return Colors.white70;
    case CodexRarity.uncommon:
      return Colors.green;
    case CodexRarity.rare:
      return Colors.blue;
    case CodexRarity.legendary:
      return const Color(0xFFD4AF37);
  }
}

IconData _typeIcon(String type) {
  switch (type) {
    case 'attack':
      return Icons.gavel;
    case 'defense':
      return Icons.shield;
    case 'utility':
      return Icons.build;
    case 'signature':
      return Icons.star;
    default:
      return Icons.help_outline;
  }
}

/// 3 列卡牌網格
class CardGridView extends StatelessWidget {
  final List<CodexCard> cards;

  const CardGridView({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.collections_bookmark_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('尚無卡牌', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.72,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: cards.length,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemBuilder: (context, index) => _CardTile(card: cards[index]),
    );
  }
}

class _CardTile extends ConsumerWidget {
  final CodexCard card;

  const _CardTile({required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _rarityColor(card.rarity);
    final owned = card.owned;
    final config = ref.watch(qualityConfigProvider);

    return GestureDetector(
      onTap: () => showCardDetailDialog(context, card),
      child: Container(
        decoration: PerformanceAwareDecoration.build(
          config: config,
          color: owned ? const Color(0xFF2F2F2F) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: owned ? color.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.2),
            width: owned ? 1.5 : 1,
          ),
          boxShadow: owned
              ? [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 8)]
              : null,
        ),
        child: Stack(
          children: [
            // 卡牌內容
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 卡牌圖片
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: _buildCardImage(config, owned, color),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // 名稱
                  Text(
                    card.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: owned ? Colors.white : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 稀有度指示
                  Container(
                    height: 3,
                    width: 24,
                    decoration: BoxDecoration(
                      color: owned ? color : Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),

            // 未擁有鎖頭
            if (!owned)
              Positioned(
                right: 4,
                top: 4,
                child: Icon(
                  Icons.lock,
                  size: 14,
                  color: Colors.grey.withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardImage(QualityConfig config, bool owned, Color color) {
    final imageWidget = Image.asset(
      card.imagePath,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      cacheWidth: config.imageCacheWidth,
      errorBuilder: (_, _, _) => Icon(
        _typeIcon(card.cardType),
        size: 32,
        color: color,
      ),
    );

    if (owned) {
      return imageWidget;
    }

    // 未擁有卡牌的濾鏡處理
    switch (config.unownedCardFilterMode) {
      case CardFilterMode.opacity:
        // 低品質：僅用 Opacity
        return Opacity(
          opacity: 0.4,
          child: imageWidget,
        );

      case CardFilterMode.simpleGrayscale:
        // 中品質：簡化灰階
        return ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Colors.grey,
            BlendMode.saturation,
          ),
          child: Opacity(
            opacity: 0.5,
            child: imageWidget,
          ),
        );

      case CardFilterMode.fullGrayscaleMatrix:
        // 高品質：完整灰階矩陣
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0, 0, 0, 0.4, 0,
          ]),
          child: imageWidget,
        );
    }
  }
}
