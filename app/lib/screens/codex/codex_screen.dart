import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/codex_provider.dart';
import '../../providers/achievements_provider.dart';
import 'card_grid_view.dart';
import 'character_codex_view.dart';
import 'achievements_list.dart';

/// 卡牌收藏圖鑑主畫面
class CodexScreen extends ConsumerWidget {
  const CodexScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codexState = ref.watch(codexProvider);
    final achievementsState = ref.watch(achievementsProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/menu'),
          ),
          title: const Text('卡牌圖鑑'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: Column(
              children: [
                // 收藏進度條
                _CollectionProgress(
                  collected: codexState.stats.collectedCards,
                  total: codexState.stats.totalCards,
                  percentage: codexState.stats.collectionPercentage,
                ),
                // Tab 欄
                TabBar(
                  indicatorColor: const Color(0xFFD4AF37),
                  labelColor: const Color(0xFFD4AF37),
                  unselectedLabelColor: Colors.white54,
                  tabs: [
                    const Tab(text: '全部卡牌'),
                    const Tab(text: '角色圖鑑'),
                    const Tab(text: '我的收藏'),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('成就'),
                          if (achievementsState.unclaimedCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${achievementsState.unclaimedCount}',
                                style: const TextStyle(fontSize: 10, color: Colors.white),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: 全部卡牌
            _AllCardsTab(codexState: codexState),
            // Tab 2: 角色圖鑑
            const CharacterCodexView(),
            // Tab 3: 我的收藏
            _MyCollectionTab(codexState: codexState),
            // Tab 4: 成就
            const AchievementsListView(),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 收藏進度條
// ═══════════════════════════════════════════

class _CollectionProgress extends StatelessWidget {
  final int collected;
  final int total;
  final double percentage;

  const _CollectionProgress({
    required this.collected,
    required this.total,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.collections_bookmark, size: 16, color: Color(0xFFD4AF37)),
          const SizedBox(width: 8),
          Text(
            '$collected/$total',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(width: 4),
          Text(
            '(${percentage.toInt()}%)',
            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total > 0 ? collected / total : 0,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFD4AF37)),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Tab 1: 全部卡牌（含篩選）
// ═══════════════════════════════════════════

class _AllCardsTab extends StatefulWidget {
  final CodexState codexState;

  const _AllCardsTab({required this.codexState});

  @override
  State<_AllCardsTab> createState() => _AllCardsTabState();
}

class _AllCardsTabState extends State<_AllCardsTab> {
  CodexRarity? _filterRarity;

  @override
  Widget build(BuildContext context) {
    if (widget.codexState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    var cards = widget.codexState.allCards;
    if (_filterRarity != null) {
      cards = cards.where((c) => c.rarity == _filterRarity).toList();
    }

    return Column(
      children: [
        // 篩選欄
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _FilterChip(
                label: '全部',
                selected: _filterRarity == null,
                onSelected: () => setState(() => _filterRarity = null),
              ),
              _FilterChip(
                label: '普通',
                selected: _filterRarity == CodexRarity.common,
                color: Colors.white70,
                onSelected: () => setState(() => _filterRarity = CodexRarity.common),
              ),
              _FilterChip(
                label: '稀有',
                selected: _filterRarity == CodexRarity.uncommon,
                color: Colors.green,
                onSelected: () => setState(() => _filterRarity = CodexRarity.uncommon),
              ),
              _FilterChip(
                label: '史詩',
                selected: _filterRarity == CodexRarity.rare,
                color: Colors.blue,
                onSelected: () => setState(() => _filterRarity = CodexRarity.rare),
              ),
              _FilterChip(
                label: '傳說',
                selected: _filterRarity == CodexRarity.legendary,
                color: const Color(0xFFD4AF37),
                onSelected: () => setState(() => _filterRarity = CodexRarity.legendary),
              ),
            ],
          ),
        ),
        Expanded(child: CardGridView(cards: cards)),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        selectedColor: (color ?? Colors.white).withValues(alpha: 0.2),
        checkmarkColor: color ?? Colors.white,
        labelStyle: TextStyle(
          color: selected ? (color ?? Colors.white) : Colors.white54,
          fontSize: 12,
        ),
        side: BorderSide(
          color: selected ? (color ?? Colors.white).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.15),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Tab 2: 我的收藏
// ═══════════════════════════════════════════

class _MyCollectionTab extends StatelessWidget {
  final CodexState codexState;

  const _MyCollectionTab({required this.codexState});

  @override
  Widget build(BuildContext context) {
    if (codexState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final owned = codexState.ownedCards;
    if (owned.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.collections_bookmark_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('尚未收藏任何卡牌', style: TextStyle(color: Colors.grey, fontSize: 16)),
            SizedBox(height: 8),
            Text('完成對局即可獲得卡牌！', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      );
    }

    return CardGridView(cards: owned);
  }
}
