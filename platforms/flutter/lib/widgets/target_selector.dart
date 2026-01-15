import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../models/card.dart';
import '../models/player.dart';

/// 目標選擇器 Widget
/// 1812 國會風雲 - 選擇卡牌使用目標的 Modal 介面
class TargetSelector extends StatefulWidget {
  /// 可選擇的目標玩家列表
  final List<Player> availableTargets;

  /// 目標類型
  final CardTargetType targetType;

  /// 需要選擇的目標數量
  final int targetCount;

  /// 當前玩家 ID（用於識別自己）
  final String currentPlayerId;

  /// 選擇完成時的回調
  final void Function(List<Player> selectedTargets)? onConfirm;

  /// 取消選擇的回調
  final VoidCallback? onCancel;

  /// 卡牌名稱（用於顯示）
  final String? cardName;

  const TargetSelector({
    super.key,
    required this.availableTargets,
    required this.targetType,
    this.targetCount = 1,
    required this.currentPlayerId,
    this.onConfirm,
    this.onCancel,
    this.cardName,
  });

  /// 顯示目標選擇器
  static Future<List<Player>?> show({
    required BuildContext context,
    required List<Player> availableTargets,
    required CardTargetType targetType,
    int targetCount = 1,
    required String currentPlayerId,
    String? cardName,
  }) async {
    return showModalBottomSheet<List<Player>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TargetSelector(
        availableTargets: availableTargets,
        targetType: targetType,
        targetCount: targetCount,
        currentPlayerId: currentPlayerId,
        cardName: cardName,
        onConfirm: (targets) => Navigator.of(context).pop(targets),
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  State<TargetSelector> createState() => _TargetSelectorState();
}

class _TargetSelectorState extends State<TargetSelector> {
  /// 已選擇的目標
  final Set<String> _selectedIds = {};

  /// 過濾後的可選目標
  late List<Player> _filteredTargets;

  @override
  void initState() {
    super.initState();
    _filterTargets();
  }

  /// 根據目標類型過濾可選玩家
  void _filterTargets() {
    switch (widget.targetType) {
      case CardTargetType.self:
        _filteredTargets = widget.availableTargets
            .where((p) => p.id == widget.currentPlayerId)
            .toList();
        // 自動選擇自己
        if (_filteredTargets.isNotEmpty) {
          _selectedIds.add(_filteredTargets.first.id);
        }
        break;
      case CardTargetType.singleEnemy:
        // 非盟友的其他玩家
        _filteredTargets = widget.availableTargets
            .where((p) => p.id != widget.currentPlayerId && !_isAlly(p))
            .toList();
        break;
      case CardTargetType.singleAlly:
        _filteredTargets = widget.availableTargets
            .where((p) => _isAlly(p))
            .toList();
        break;
      case CardTargetType.singleAny:
        _filteredTargets = widget.availableTargets;
        break;
      case CardTargetType.allEnemies:
        _filteredTargets = widget.availableTargets
            .where((p) => p.id != widget.currentPlayerId && !_isAlly(p))
            .toList();
        // 自動全選
        for (final p in _filteredTargets) {
          _selectedIds.add(p.id);
        }
        break;
      case CardTargetType.allAllies:
        _filteredTargets = widget.availableTargets
            .where((p) => _isAlly(p))
            .toList();
        // 自動全選
        for (final p in _filteredTargets) {
          _selectedIds.add(p.id);
        }
        break;
      case CardTargetType.allPlayers:
        _filteredTargets = widget.availableTargets;
        // 自動全選
        for (final p in _filteredTargets) {
          _selectedIds.add(p.id);
        }
        break;
      case CardTargetType.none:
        _filteredTargets = [];
        break;
    }
  }

  /// 檢查是否為盟友（需要整合同盟系統）
  bool _isAlly(Player player) {
    // TODO: 整合同盟系統後實作
    return false;
  }

  /// 是否可以確認選擇
  bool get _canConfirm {
    if (_isAutoSelectAll) return true;
    return _selectedIds.length == widget.targetCount;
  }

  /// 是否為自動全選類型
  bool get _isAutoSelectAll {
    return widget.targetType == CardTargetType.self ||
        widget.targetType == CardTargetType.allEnemies ||
        widget.targetType == CardTargetType.allAllies ||
        widget.targetType == CardTargetType.allPlayers ||
        widget.targetType == CardTargetType.none;
  }

  /// 切換選擇
  void _toggleSelection(Player player) {
    if (_isAutoSelectAll) return;

    setState(() {
      if (_selectedIds.contains(player.id)) {
        _selectedIds.remove(player.id);
      } else {
        if (_selectedIds.length < widget.targetCount) {
          _selectedIds.add(player.id);
        } else if (widget.targetCount == 1) {
          _selectedIds.clear();
          _selectedIds.add(player.id);
        }
      }
    });
  }

  /// 確認選擇
  void _confirm() {
    final selectedPlayers = _filteredTargets
        .where((p) => _selectedIds.contains(p.id))
        .toList();
    widget.onConfirm?.call(selectedPlayers);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
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
          _buildHeader(),
          const Divider(color: AppTheme.textTertiary, height: 1),
          Flexible(
            child: widget.targetType == CardTargetType.none
                ? _buildNoTargetMessage()
                : _filteredTargets.isEmpty
                    ? _buildEmptyMessage()
                    : _buildTargetGrid(),
          ),
          const Divider(color: AppTheme.textTertiary, height: 1),
          _buildActionButtons(),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
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

  /// 標題區域
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.gps_fixed,
                color: AppTheme.accentGold,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '選擇目標',
                      style: AppTheme.headlineSmall.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.cardName != null)
                      Text(
                        widget.cardName!,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.accentGold,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onCancel,
                icon: const Icon(Icons.close, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSelectionHint(),
        ],
      ),
    );
  }

  /// 選擇提示
  Widget _buildSelectionHint() {
    String hint;
    if (_isAutoSelectAll) {
      hint = _getAutoSelectHint();
    } else {
      final remaining = widget.targetCount - _selectedIds.length;
      if (remaining > 0) {
        hint = '請選擇 $remaining 個目標';
      } else {
        hint = '已選擇完成';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.panelBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _canConfirm ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: _canConfirm ? AppTheme.successColor : AppTheme.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            hint,
            style: AppTheme.bodySmall.copyWith(
              color: _canConfirm ? AppTheme.successColor : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 取得自動選擇的提示
  String _getAutoSelectHint() {
    switch (widget.targetType) {
      case CardTargetType.self:
        return '目標：自己';
      case CardTargetType.allEnemies:
        return '目標：所有敵人 (${_filteredTargets.length} 人)';
      case CardTargetType.allAllies:
        return '目標：所有盟友 (${_filteredTargets.length} 人)';
      case CardTargetType.allPlayers:
        return '目標：所有玩家 (${_filteredTargets.length} 人)';
      case CardTargetType.none:
        return '此卡牌無需選擇目標';
      default:
        return '';
    }
  }

  /// 無目標訊息
  Widget _buildNoTargetMessage() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome,
            size: 48,
            color: AppTheme.accentGold,
          ),
          const SizedBox(height: 16),
          Text(
            '此卡牌無需選擇目標',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '點擊確認直接使用',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  /// 無可選目標訊息
  Widget _buildEmptyMessage() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_off_outlined,
            size: 48,
            color: AppTheme.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '沒有可選擇的目標',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 目標選擇網格
  Widget _buildTargetGrid() {
    return GridView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredTargets.length,
      itemBuilder: (context, index) {
        final player = _filteredTargets[index];
        final isSelected = _selectedIds.contains(player.id);
        final isSelf = player.id == widget.currentPlayerId;
        final delay = index * 50;

        return _buildTargetCard(player, isSelected, isSelf)
            .animate()
            .fadeIn(delay: delay.ms, duration: 200.ms)
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1, 1),
              delay: delay.ms,
              duration: 200.ms,
            );
      },
    );
  }

  /// 單個目標卡片
  Widget _buildTargetCard(Player player, bool isSelected, bool isSelf) {
    final canSelect = !_isAutoSelectAll;

    return GestureDetector(
      onTap: canSelect ? () => _toggleSelection(player) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentGold.withValues(alpha: 0.2)
              : AppTheme.panelBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.accentGold
                : AppTheme.textTertiary.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.accentGold.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 頭像
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getPlayerColor(player).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getPlayerColor(player),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _getRoleIcon(player.roleType),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                // 選中標記
                if (isSelected)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: AppTheme.accentGold,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.black,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // 名稱
            Text(
              isSelf ? '${player.nickname} (自己)' : player.nickname,
              style: AppTheme.bodySmall.copyWith(
                color: isSelected ? AppTheme.accentGold : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // 角色類型
            if (player.roleType != null)
              Text(
                Role.typeNames[player.roleType!] ?? player.roleType!,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  /// 操作按鈕
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 取消按鈕
          Expanded(
            child: OutlinedButton(
              onPressed: widget.onCancel,
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
                '取消',
                style: AppTheme.labelMedium.copyWith(
                  color: AppTheme.accentGold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 確認按鈕
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _canConfirm ? _confirm : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: _canConfirm
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
                  const Icon(Icons.check, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '確認選擇',
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
      ),
    );
  }

  /// 取得玩家顏色（根據陣營/角色）
  Color _getPlayerColor(Player player) {
    if (player.id == widget.currentPlayerId) {
      return AppTheme.accentGold;
    }
    // TODO: 根據陣營返回不同顏色
    return AppTheme.textSecondary;
  }

  /// 取得角色圖示
  String _getRoleIcon(String? roleType) {
    switch (roleType) {
      case 'worker':
        return '👷';
      case 'factory':
        return '🏭';
      case 'luddite':
        return '🔨';
      case 'reformer':
        return '📜';
      case 'mp':
        return '🎩';
      default:
        return '👤';
    }
  }
}
