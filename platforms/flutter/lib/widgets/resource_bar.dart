import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../models/player_resources.dart';

/// 資源條 Widget
/// 1812 國會風雲 - 顯示玩家三大資源：聲望❤️、影響力🌟、金幣💰
class ResourceBar extends StatelessWidget {
  /// 玩家資源
  final PlayerResources resources;

  /// 是否為緊湊模式（用於其他玩家顯示）
  final bool isCompact;

  /// 是否顯示數值
  final bool showValues;

  /// 是否顯示圖示
  final bool showIcons;

  /// 資源變化時的回調
  final void Function(ResourceType type, int change)? onResourceChange;

  const ResourceBar({
    super.key,
    required this.resources,
    this.isCompact = false,
    this.showValues = true,
    this.showIcons = true,
    this.onResourceChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 8 : 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isCompact ? _buildCompactLayout() : _buildFullLayout(),
    );
  }

  /// 完整佈局（主玩家用）
  Widget _buildFullLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildResourceRow(
          type: ResourceType.reputation,
          value: resources.reputation,
          maxValue: PlayerResources.maxReputation,
          percentage: resources.reputationPercentage,
          color: AppTheme.reputationRed,
        ),
        const SizedBox(height: 8),
        _buildResourceRow(
          type: ResourceType.influence,
          value: resources.influence,
          maxValue: PlayerResources.maxInfluence,
          percentage: resources.influencePercentage,
          color: AppTheme.influenceBlue,
        ),
        const SizedBox(height: 8),
        _buildResourceRow(
          type: ResourceType.gold,
          value: resources.gold,
          maxValue: PlayerResources.maxGold,
          percentage: resources.goldPercentage,
          color: AppTheme.goldYellow,
        ),
      ],
    );
  }

  /// 緊湊佈局（其他玩家用）
  Widget _buildCompactLayout() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCompactResource(
          type: ResourceType.reputation,
          value: resources.reputation,
          color: AppTheme.reputationRed,
        ),
        const SizedBox(width: 12),
        _buildCompactResource(
          type: ResourceType.influence,
          value: resources.influence,
          color: AppTheme.influenceBlue,
        ),
        const SizedBox(width: 12),
        _buildCompactResource(
          type: ResourceType.gold,
          value: resources.gold,
          color: AppTheme.goldYellow,
        ),
      ],
    );
  }

  /// 單列資源顯示（完整模式）
  Widget _buildResourceRow({
    required ResourceType type,
    required int value,
    required int maxValue,
    required double percentage,
    required Color color,
  }) {
    return Row(
      children: [
        // 圖示
        if (showIcons)
          SizedBox(
            width: 28,
            child: Text(
              type.icon,
              style: const TextStyle(fontSize: 18),
            ),
          ),

        // 進度條
        Expanded(
          child: _AnimatedProgressBar(
            percentage: percentage,
            color: color,
            height: 16,
          ),
        ),

        // 數值
        if (showValues)
          Container(
            width: 60,
            alignment: Alignment.centerRight,
            child: Text(
              '$value/$maxValue',
              style: AppTheme.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  /// 緊湊資源顯示
  Widget _buildCompactResource({
    required ResourceType type,
    required int value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcons)
          Text(
            type.icon,
            style: const TextStyle(fontSize: 14),
          ),
        if (showIcons) const SizedBox(width: 4),
        Text(
          '$value',
          style: AppTheme.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// 動畫進度條
class _AnimatedProgressBar extends StatelessWidget {
  final double percentage;
  final Color color;
  final double height;

  const _AnimatedProgressBar({
    required this.percentage,
    required this.color,
    this.height = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.panelBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: Stack(
          children: [
            // 進度條填充
            AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              alignment: Alignment.centerLeft,
              widthFactor: percentage.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.8),
                      color,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // 高光效果
            Positioned(
              top: 2,
              left: 4,
              right: 4,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.3),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 資源變化飄字動畫 Widget
class ResourceChangeIndicator extends StatelessWidget {
  final ResourceType type;
  final int change;
  final VoidCallback? onComplete;

  const ResourceChangeIndicator({
    super.key,
    required this.type,
    required this.change,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = change > 0;
    final color = isPositive
        ? AppTheme.successColor
        : AppTheme.errorColor;
    final prefix = isPositive ? '+' : '';

    return Text(
      '$prefix$change ${type.icon}',
      style: AppTheme.headlineMedium.copyWith(
        color: color,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 8,
          ),
        ],
      ),
    )
        .animate(onComplete: (_) => onComplete?.call())
        .fadeIn(duration: 200.ms)
        .moveY(begin: 0, end: -30, duration: 800.ms, curve: Curves.easeOut)
        .fadeOut(delay: 600.ms, duration: 200.ms);
  }
}

/// 政治死亡警告 Widget
class PoliticalDeathWarning extends StatelessWidget {
  final bool isVisible;

  const PoliticalDeathWarning({
    super.key,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.errorColor,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppTheme.errorColor,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            '政治死亡！',
            style: AppTheme.labelMedium.copyWith(
              color: AppTheme.errorColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 1500.ms, color: AppTheme.errorColor.withValues(alpha: 0.3));
  }
}

/// 投票權重顯示 Widget
class VoteWeightIndicator extends StatelessWidget {
  final double weight;
  final String description;
  final bool showDetail;

  const VoteWeightIndicator({
    super.key,
    required this.weight,
    required this.description,
    this.showDetail = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getWeightColor(weight);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.how_to_vote_outlined,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            '${weight}x',
            style: AppTheme.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (showDetail) ...[
            const SizedBox(width: 8),
            Text(
              description,
              style: AppTheme.bodySmall.copyWith(
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getWeightColor(double weight) {
    if (weight >= 1.5) return AppTheme.raritySR; // 政治明星 - 紫色
    if (weight >= 1.2) return AppTheme.successColor; // 有影響力 - 綠色
    if (weight >= 1.0) return AppTheme.textSecondary; // 普通 - 灰色
    if (weight >= 0.8) return AppTheme.warningColor; // 邊緣 - 橙色
    if (weight > 0) return AppTheme.errorColor; // 瀕死 - 紅色
    return AppTheme.textTertiary; // 政治死亡 - 禁用色
  }
}

/// 資源條動畫控制器
class ResourceBarController extends ChangeNotifier {
  /// 資源變化隊列
  final List<_ResourceChangeEvent> _changeQueue = [];

  /// 是否正在播放動畫
  bool _isAnimating = false;

  bool get isAnimating => _isAnimating;

  /// 添加資源變化事件
  void addChange({
    required ResourceType type,
    required int oldValue,
    required int newValue,
  }) {
    final change = newValue - oldValue;
    if (change == 0) return;

    _changeQueue.add(_ResourceChangeEvent(
      type: type,
      change: change,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  /// 取得並移除下一個變化事件（內部使用）
  /// 返回資源類型、變化量和時間戳
  (ResourceType type, int change, DateTime timestamp)? popNextChange() {
    if (_changeQueue.isEmpty) return null;
    final event = _changeQueue.removeAt(0);
    notifyListeners();
    return (event.type, event.change, event.timestamp);
  }

  /// 清空所有變化事件
  void clearChanges() {
    _changeQueue.clear();
    notifyListeners();
  }

  /// 設定動畫狀態
  void setAnimating(bool value) {
    _isAnimating = value;
    notifyListeners();
  }
}

/// 資源變化事件
class _ResourceChangeEvent {
  final ResourceType type;
  final int change;
  final DateTime timestamp;

  const _ResourceChangeEvent({
    required this.type,
    required this.change,
    required this.timestamp,
  });
}

/// 帶動畫的資源條 Widget
class AnimatedResourceBar extends StatefulWidget {
  final PlayerResources resources;
  final ResourceBarController? controller;
  final bool isCompact;

  const AnimatedResourceBar({
    super.key,
    required this.resources,
    this.controller,
    this.isCompact = false,
  });

  @override
  State<AnimatedResourceBar> createState() => _AnimatedResourceBarState();
}

class _AnimatedResourceBarState extends State<AnimatedResourceBar> {
  PlayerResources? _previousResources;
  final List<_ActiveChangeIndicator> _activeIndicators = [];
  int _indicatorIdCounter = 0;

  @override
  void didUpdateWidget(AnimatedResourceBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 檢測資源變化並顯示飄字
    if (_previousResources != null) {
      _checkResourceChange(
        ResourceType.reputation,
        _previousResources!.reputation,
        widget.resources.reputation,
      );
      _checkResourceChange(
        ResourceType.influence,
        _previousResources!.influence,
        widget.resources.influence,
      );
      _checkResourceChange(
        ResourceType.gold,
        _previousResources!.gold,
        widget.resources.gold,
      );
    }

    _previousResources = widget.resources;
  }

  void _checkResourceChange(ResourceType type, int oldValue, int newValue) {
    final change = newValue - oldValue;
    if (change == 0) return;

    final id = _indicatorIdCounter++;
    setState(() {
      _activeIndicators.add(_ActiveChangeIndicator(
        id: id,
        type: type,
        change: change,
      ));
    });
  }

  void _removeIndicator(int id) {
    setState(() {
      _activeIndicators.removeWhere((i) => i.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ResourceBar(
          resources: widget.resources,
          isCompact: widget.isCompact,
        ),
        // 飄字動畫
        ..._activeIndicators.map((indicator) {
          return Positioned(
            top: -30,
            left: 0,
            right: 0,
            child: Center(
              child: ResourceChangeIndicator(
                type: indicator.type,
                change: indicator.change,
                onComplete: () => _removeIndicator(indicator.id),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _ActiveChangeIndicator {
  final int id;
  final ResourceType type;
  final int change;

  const _ActiveChangeIndicator({
    required this.id,
    required this.type,
    required this.change,
  });
}
