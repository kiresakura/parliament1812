import 'package:flutter/material.dart';

import '../../providers/codex_provider.dart';

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

String _rarityLabel(CodexRarity rarity) {
  switch (rarity) {
    case CodexRarity.common:
      return '普通';
    case CodexRarity.uncommon:
      return '稀有';
    case CodexRarity.rare:
      return '史詩';
    case CodexRarity.legendary:
      return '傳說';
  }
}

String _typeLabel(String type) {
  switch (type) {
    case 'attack':
      return '⚔️ 攻擊';
    case 'defense':
      return '🛡️ 防禦';
    case 'utility':
      return '🔧 功能';
    case 'signature':
      return '⭐ 專屬';
    default:
      return type;
  }
}

/// 卡牌詳情對話框
void showCardDetailDialog(BuildContext context, CodexCard card) {
  final color = _rarityColor(card.rarity);

  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: const Color(0xFF2F2F2F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 稀有度光條
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0), color, color.withValues(alpha: 0)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // 卡牌圖片
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: Image.asset(
                      card.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 名稱
              Center(
                child: Text(
                  card.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: card.owned ? color : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // 標籤列
              Center(
                child: Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      label: Text(_rarityLabel(card.rarity)),
                      backgroundColor: color.withValues(alpha: 0.15),
                      labelStyle: TextStyle(color: color, fontSize: 12),
                      side: BorderSide(color: color.withValues(alpha: 0.3)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Chip(
                      label: Text(_typeLabel(card.cardType)),
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      labelStyle: const TextStyle(fontSize: 12),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    if (card.character != null)
                      Chip(
                        label: Text(card.character!),
                        backgroundColor: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                        labelStyle: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12),
                        side: BorderSide(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 效果描述
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  card.description,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
              const SizedBox(height: 12),

              // 風味文字
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border(left: BorderSide(color: color.withValues(alpha: 0.4), width: 3)),
                ),
                child: Text(
                  card.flavorText,
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 解鎖條件
              Row(
                children: [
                  Icon(
                    card.owned ? Icons.check_circle : Icons.lock_outline,
                    color: card.owned ? Colors.green : Colors.grey,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      card.owned ? '已收藏' : card.unlockCondition,
                      style: TextStyle(
                        fontSize: 13,
                        color: card.owned ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 關閉按鈕
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('關閉'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
