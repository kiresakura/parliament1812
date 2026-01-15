import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../models/player_resources.dart';

/// 傷害動畫 Widget
/// 1812 國會風雲 - 顯示聲望傷害的視覺效果
class DamageAnimation extends StatelessWidget {
  /// 傷害數值
  final int damage;

  /// 傷害類型
  final DamageType type;

  /// 造成傷害的來源（卡牌名稱或原因）
  final String? source;

  /// 動畫完成回調
  final VoidCallback? onComplete;

  /// 是否顯示大型動畫（用於重要傷害）
  final bool isLarge;

  const DamageAnimation({
    super.key,
    required this.damage,
    this.type = DamageType.normal,
    this.source,
    this.onComplete,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDamageNumber(),
        if (source != null) _buildSourceText(),
      ],
    )
        .animate(onComplete: (_) => onComplete?.call())
        .fadeIn(duration: 150.ms)
        .moveY(begin: 0, end: -40, duration: 800.ms, curve: Curves.easeOut)
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1, 1),
          duration: 200.ms,
          curve: Curves.elasticOut,
        )
        .then(delay: 400.ms)
        .fadeOut(duration: 300.ms);
  }

  /// 傷害數字
  Widget _buildDamageNumber() {
    final color = _getDamageColor();
    final fontSize = isLarge ? 48.0 : 32.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 減號
        Text(
          '-',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: color,
            shadows: [
              Shadow(
                color: color.withValues(alpha: 0.8),
                blurRadius: 12,
              ),
              Shadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
            ],
          ),
        ),
        // 數值
        Text(
          '$damage',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: color,
            shadows: [
              Shadow(
                color: color.withValues(alpha: 0.8),
                blurRadius: 12,
              ),
              Shadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        // 聲望圖示
        Text(
          '❤️',
          style: TextStyle(fontSize: isLarge ? 32 : 24),
        ),
      ],
    );
  }

  /// 傷害來源文字
  Widget _buildSourceText() {
    return Text(
      source!,
      style: AppTheme.bodySmall.copyWith(
        color: _getDamageColor().withValues(alpha: 0.8),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// 根據傷害類型取得顏色
  Color _getDamageColor() {
    switch (type) {
      case DamageType.normal:
        return AppTheme.errorColor;
      case DamageType.critical:
        return AppTheme.raritySSR; // 金色暴擊
      case DamageType.betrayal:
        return AppTheme.raritySR; // 紫色背叛
      case DamageType.scandal:
        return const Color(0xFFFF6B6B); // 亮紅醜聞
      case DamageType.political:
        return const Color(0xFF8B0000); // 深紅政治死亡
    }
  }
}

/// 傷害類型
enum DamageType {
  /// 普通傷害
  normal,

  /// 暴擊傷害
  critical,

  /// 背叛傷害
  betrayal,

  /// 醜聞傷害
  scandal,

  /// 政治死亡（特殊）
  political,
}

/// 傷害動畫控制器
/// 用於管理和播放多個傷害動畫
class DamageAnimationController extends ChangeNotifier {
  /// 活動中的傷害動畫列表
  final List<DamageAnimationData> _animations = [];

  /// 取得活動中的動畫
  List<DamageAnimationData> get animations => List.unmodifiable(_animations);

  int _idCounter = 0;

  /// 添加傷害動畫
  void addDamage({
    required int damage,
    DamageType type = DamageType.normal,
    String? source,
    Offset? position,
    bool isLarge = false,
  }) {
    final id = _idCounter++;
    _animations.add(DamageAnimationData(
      id: id,
      damage: damage,
      type: type,
      source: source,
      position: position ?? Offset.zero,
      isLarge: isLarge,
      createdAt: DateTime.now(),
    ));
    notifyListeners();
  }

  /// 移除動畫
  void removeAnimation(int id) {
    _animations.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  /// 清除所有動畫
  void clear() {
    _animations.clear();
    notifyListeners();
  }
}

/// 傷害動畫數據
class DamageAnimationData {
  final int id;
  final int damage;
  final DamageType type;
  final String? source;
  final Offset position;
  final bool isLarge;
  final DateTime createdAt;

  const DamageAnimationData({
    required this.id,
    required this.damage,
    required this.type,
    this.source,
    required this.position,
    required this.isLarge,
    required this.createdAt,
  });
}

/// 傷害動畫覆蓋層
/// 用於在遊戲畫面上顯示傷害動畫
class DamageAnimationOverlay extends StatelessWidget {
  /// 動畫控制器
  final DamageAnimationController controller;

  const DamageAnimationOverlay({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Stack(
          children: controller.animations.map((data) {
            return Positioned(
              left: data.position.dx,
              top: data.position.dy,
              child: DamageAnimation(
                damage: data.damage,
                type: data.type,
                source: data.source,
                isLarge: data.isLarge,
                onComplete: () => controller.removeAnimation(data.id),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// 全螢幕傷害效果（紅色閃爍 + 震動）
class FullScreenDamageEffect extends StatefulWidget {
  /// 傷害數值（影響震動強度）
  final int damage;

  /// 動畫完成回調
  final VoidCallback? onComplete;

  /// 是否為致命傷害（政治死亡）
  final bool isFatal;

  const FullScreenDamageEffect({
    super.key,
    required this.damage,
    this.onComplete,
    this.isFatal = false,
  });

  @override
  State<FullScreenDamageEffect> createState() => _FullScreenDamageEffectState();
}

class _FullScreenDamageEffectState extends State<FullScreenDamageEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.isFatal
          ? const Duration(milliseconds: 800)
          : const Duration(milliseconds: 400),
    );
    _controller.forward().then((_) => widget.onComplete?.call());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // 震動偏移
        final shakeIntensity = (widget.damage / 30).clamp(0.5, 3.0);
        final shakeProgress = Curves.elasticOut.transform(
          (_controller.value * 4).clamp(0.0, 1.0),
        );
        final offsetX = sin(_controller.value * 20 * pi) *
            shakeIntensity *
            (1 - shakeProgress);
        final offsetY = cos(_controller.value * 20 * pi) *
            shakeIntensity *
            (1 - shakeProgress);

        // 紅色閃爍透明度
        final flashOpacity = widget.isFatal
            ? (sin(_controller.value * 6 * pi) * 0.3 + 0.3).clamp(0.0, 0.6)
            : (1 - _controller.value) * 0.4;

        return Transform.translate(
          offset: Offset(offsetX * 10, offsetY * 10),
          child: Container(
            color: AppTheme.errorColor.withValues(alpha: flashOpacity),
          ),
        );
      },
    );
  }
}

/// 目標受傷指示器
/// 顯示在被攻擊玩家頭像周圍的視覺效果
class TargetDamageIndicator extends StatelessWidget {
  /// 是否正在受傷
  final bool isUnderAttack;

  /// 子元件（玩家頭像）
  final Widget child;

  const TargetDamageIndicator({
    super.key,
    required this.isUnderAttack,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!isUnderAttack) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 紅色脈衝光環
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.errorColor.withValues(alpha: 0.6),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(
                duration: 200.ms,
              ),
        ),
        // 原始元件（帶震動）
        child
            .animate(onPlay: (c) => c.repeat())
            .shakeX(hz: 10, amount: 2, duration: 300.ms),
      ],
    );
  }
}

/// 資源變化動畫（用於顯示影響力或金幣消耗）
class ResourceChangeAnimation extends StatelessWidget {
  /// 資源類型
  final ResourceType resourceType;

  /// 變化量（負數為消耗，正數為獲得）
  final int change;

  /// 動畫完成回調
  final VoidCallback? onComplete;

  const ResourceChangeAnimation({
    super.key,
    required this.resourceType,
    required this.change,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = change > 0;
    final color = isPositive ? AppTheme.successColor : AppTheme.errorColor;
    final prefix = isPositive ? '+' : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$prefix$change',
          style: AppTheme.headlineSmall.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: color.withValues(alpha: 0.5), blurRadius: 8),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          resourceType.icon,
          style: const TextStyle(fontSize: 20),
        ),
      ],
    )
        .animate(onComplete: (_) => onComplete?.call())
        .fadeIn(duration: 150.ms)
        .moveY(begin: 0, end: -25, duration: 700.ms, curve: Curves.easeOut)
        .then(delay: 300.ms)
        .fadeOut(duration: 300.ms);
  }
}

/// 連擊傷害動畫
/// 用於顯示多次連續傷害的組合效果
class ComboHitAnimation extends StatelessWidget {
  /// 各次傷害數值
  final List<int> damages;

  /// 動畫完成回調
  final VoidCallback? onComplete;

  const ComboHitAnimation({
    super.key,
    required this.damages,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    if (damages.isEmpty) return const SizedBox.shrink();

    final totalDamage = damages.fold(0, (sum, d) => sum + d);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 連擊數
        if (damages.length > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accentGold),
            ),
            child: Text(
              '${damages.length} HIT!',
              style: AppTheme.labelSmall.copyWith(
                color: AppTheme.accentGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ).animate().scale(
                begin: const Offset(1.5, 1.5),
                end: const Offset(1, 1),
                duration: 200.ms,
                curve: Curves.elasticOut,
              ),
        const SizedBox(height: 8),
        // 總傷害
        DamageAnimation(
          damage: totalDamage,
          type: damages.length >= 3 ? DamageType.critical : DamageType.normal,
          isLarge: true,
          onComplete: onComplete,
        ),
      ],
    );
  }
}
