import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../models/player_resources.dart';

/// 治療動畫 Widget
/// 1812 國會風雲 - 顯示聲望恢復的視覺效果
class HealAnimation extends StatelessWidget {
  /// 治療數值
  final int healAmount;

  /// 治療類型
  final HealType type;

  /// 治療來源（卡牌名稱或原因）
  final String? source;

  /// 動畫完成回調
  final VoidCallback? onComplete;

  /// 是否顯示大型動畫（用於重要治療）
  final bool isLarge;

  const HealAnimation({
    super.key,
    required this.healAmount,
    this.type = HealType.normal,
    this.source,
    this.onComplete,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHealNumber(),
        if (source != null) _buildSourceText(),
      ],
    )
        .animate(onComplete: (_) => onComplete?.call())
        .fadeIn(duration: 150.ms)
        .moveY(begin: 0, end: -50, duration: 900.ms, curve: Curves.easeOut)
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1.2, 1.2),
          duration: 300.ms,
          curve: Curves.elasticOut,
        )
        .then(delay: 500.ms)
        .fadeOut(duration: 300.ms);
  }

  /// 治療數字
  Widget _buildHealNumber() {
    final color = _getHealColor();
    final fontSize = isLarge ? 48.0 : 32.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 加號
        Text(
          '+',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: color,
            shadows: [
              Shadow(
                color: color.withValues(alpha: 0.8),
                blurRadius: 16,
              ),
              Shadow(
                color: Colors.white.withValues(alpha: 0.5),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        // 數值
        Text(
          '$healAmount',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: color,
            shadows: [
              Shadow(
                color: color.withValues(alpha: 0.8),
                blurRadius: 16,
              ),
              Shadow(
                color: Colors.white.withValues(alpha: 0.5),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        // 圖示
        Text(
          _getHealIcon(),
          style: TextStyle(fontSize: isLarge ? 32 : 24),
        ),
      ],
    );
  }

  /// 治療來源文字
  Widget _buildSourceText() {
    return Text(
      source!,
      style: AppTheme.bodySmall.copyWith(
        color: _getHealColor().withValues(alpha: 0.8),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// 根據治療類型取得顏色
  Color _getHealColor() {
    switch (type) {
      case HealType.normal:
        return AppTheme.successColor;
      case HealType.powerful:
        return AppTheme.raritySR; // 紫色強力治療
      case HealType.revival:
        return AppTheme.raritySSR; // 金色復活
      case HealType.alliance:
        return AppTheme.influenceBlue; // 藍色同盟治療
      case HealType.blessing:
        return const Color(0xFFFFD700); // 純金祝福
    }
  }

  /// 根據治療類型取得圖示
  String _getHealIcon() {
    switch (type) {
      case HealType.normal:
        return '💚';
      case HealType.powerful:
        return '💜';
      case HealType.revival:
        return '✨';
      case HealType.alliance:
        return '🤝';
      case HealType.blessing:
        return '👑';
    }
  }
}

/// 治療類型
enum HealType {
  /// 普通治療
  normal,

  /// 強力治療
  powerful,

  /// 復活（從政治死亡恢復）
  revival,

  /// 同盟治療
  alliance,

  /// 王室祝福（國王特殊）
  blessing,
}

/// 治療動畫控制器
/// 用於管理和播放多個治療動畫
class HealAnimationController extends ChangeNotifier {
  /// 活動中的治療動畫列表
  final List<HealAnimationData> _animations = [];

  /// 取得活動中的動畫
  List<HealAnimationData> get animations => List.unmodifiable(_animations);

  int _idCounter = 0;

  /// 添加治療動畫
  void addHeal({
    required int healAmount,
    HealType type = HealType.normal,
    String? source,
    Offset? position,
    bool isLarge = false,
  }) {
    final id = _idCounter++;
    _animations.add(HealAnimationData(
      id: id,
      healAmount: healAmount,
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

/// 治療動畫數據
class HealAnimationData {
  final int id;
  final int healAmount;
  final HealType type;
  final String? source;
  final Offset position;
  final bool isLarge;
  final DateTime createdAt;

  const HealAnimationData({
    required this.id,
    required this.healAmount,
    required this.type,
    this.source,
    required this.position,
    required this.isLarge,
    required this.createdAt,
  });
}

/// 治療動畫覆蓋層
/// 用於在遊戲畫面上顯示治療動畫
class HealAnimationOverlay extends StatelessWidget {
  /// 動畫控制器
  final HealAnimationController controller;

  const HealAnimationOverlay({
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
              child: HealAnimation(
                healAmount: data.healAmount,
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

/// 全螢幕治療效果（綠色光芒 + 上升粒子）
class FullScreenHealEffect extends StatefulWidget {
  /// 治療數值（影響光芒強度）
  final int healAmount;

  /// 動畫完成回調
  final VoidCallback? onComplete;

  /// 是否為復活（特殊效果）
  final bool isRevival;

  const FullScreenHealEffect({
    super.key,
    required this.healAmount,
    this.onComplete,
    this.isRevival = false,
  });

  @override
  State<FullScreenHealEffect> createState() => _FullScreenHealEffectState();
}

class _FullScreenHealEffectState extends State<FullScreenHealEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.isRevival
          ? const Duration(milliseconds: 1200)
          : const Duration(milliseconds: 600),
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
        // 光芒強度
        final intensity = (widget.healAmount / 30).clamp(0.3, 1.0);
        final glowProgress = Curves.easeOutCubic.transform(_controller.value);

        // 脈動效果
        final pulseOpacity = widget.isRevival
            ? (sin(_controller.value * 4 * pi) * 0.2 + 0.3).clamp(0.0, 0.5)
            : (1 - _controller.value) * 0.3 * intensity;

        final baseColor =
            widget.isRevival ? AppTheme.raritySSR : AppTheme.successColor;

        return Stack(
          children: [
            // 底層光芒
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    baseColor.withValues(alpha: pulseOpacity),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // 上升光線效果
            if (widget.isRevival)
              Positioned.fill(
                child: CustomPaint(
                  painter: _RisingLightPainter(
                    progress: _controller.value,
                    color: baseColor,
                  ),
                ),
              ),
            // 邊緣光暈
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: baseColor.withValues(alpha: (1 - glowProgress) * 0.5),
                  width: 8 * (1 - glowProgress),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 上升光線繪製器
class _RisingLightPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RisingLightPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: (1 - progress) * 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final random = Random(42); // 固定種子確保一致性

    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final startY = size.height + random.nextDouble() * 50;
      final endY = startY - (size.height * 1.5 * progress);

      if (endY < size.height) {
        final lineOpacity = ((size.height - endY) / size.height).clamp(0.0, 1.0);
        paint.color = color.withValues(alpha: lineOpacity * (1 - progress) * 0.4);

        canvas.drawLine(
          Offset(x, max(0, endY)),
          Offset(x, min(size.height, endY + 30)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RisingLightPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// 目標治療指示器
/// 顯示在被治療玩家頭像周圍的視覺效果
class TargetHealIndicator extends StatelessWidget {
  /// 是否正在被治療
  final bool isBeingHealed;

  /// 子元件（玩家頭像）
  final Widget child;

  const TargetHealIndicator({
    super.key,
    required this.isBeingHealed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!isBeingHealed) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 綠色脈衝光環
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.successColor.withValues(alpha: 0.6),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(
                duration: 300.ms,
              ),
        ),
        // 上升粒子效果
        Positioned.fill(
          child: _HealParticles(),
        ),
        // 原始元件（帶縮放脈動）
        child
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.05, 1.05),
              duration: 400.ms,
            ),
      ],
    );
  }
}

/// 治療粒子效果
class _HealParticles extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(6, (index) {
        final delay = index * 100;
        return Positioned(
          left: 10.0 + (index % 3) * 20,
          bottom: 0,
          child: Text(
            '✦',
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.successColor.withValues(alpha: 0.8),
            ),
          )
              .animate(
                delay: Duration(milliseconds: delay),
                onPlay: (c) => c.repeat(),
              )
              .moveY(begin: 0, end: -40, duration: 800.ms)
              .fadeOut(duration: 800.ms),
        );
      }),
    );
  }
}

/// 增益效果指示器
/// 顯示玩家身上的正面效果
class BuffIndicator extends StatelessWidget {
  /// 增益類型
  final BuffType buffType;

  /// 剩餘回合數
  final int remainingTurns;

  /// 是否顯示詳情
  final bool showDetail;

  const BuffIndicator({
    super.key,
    required this.buffType,
    required this.remainingTurns,
    this.showDetail = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getBuffColor().withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBuffColor().withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getBuffIcon(),
            style: const TextStyle(fontSize: 14),
          ),
          if (showDetail) ...[
            const SizedBox(width: 4),
            Text(
              _getBuffName(),
              style: AppTheme.labelSmall.copyWith(
                color: _getBuffColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: _getBuffColor().withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$remainingTurns',
              style: AppTheme.labelSmall.copyWith(
                color: _getBuffColor(),
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(
          duration: 2000.ms,
          color: _getBuffColor().withValues(alpha: 0.2),
        );
  }

  Color _getBuffColor() {
    switch (buffType) {
      case BuffType.shield:
        return AppTheme.influenceBlue;
      case BuffType.damageBoost:
        return AppTheme.errorColor;
      case BuffType.influenceRegen:
        return AppTheme.raritySR;
      case BuffType.goldIncome:
        return AppTheme.goldYellow;
      case BuffType.immunity:
        return AppTheme.raritySSR;
      case BuffType.allianceBonus:
        return AppTheme.successColor;
    }
  }

  String _getBuffIcon() {
    switch (buffType) {
      case BuffType.shield:
        return '🛡️';
      case BuffType.damageBoost:
        return '⚔️';
      case BuffType.influenceRegen:
        return '🌟';
      case BuffType.goldIncome:
        return '💰';
      case BuffType.immunity:
        return '✨';
      case BuffType.allianceBonus:
        return '🤝';
    }
  }

  String _getBuffName() {
    switch (buffType) {
      case BuffType.shield:
        return '護盾';
      case BuffType.damageBoost:
        return '攻擊加成';
      case BuffType.influenceRegen:
        return '影響力回復';
      case BuffType.goldIncome:
        return '金幣收入';
      case BuffType.immunity:
        return '免疫';
      case BuffType.allianceBonus:
        return '同盟加成';
    }
  }
}

/// 增益類型
enum BuffType {
  /// 護盾（減少傷害）
  shield,

  /// 傷害加成
  damageBoost,

  /// 影響力回復
  influenceRegen,

  /// 金幣收入
  goldIncome,

  /// 免疫（無法被攻擊）
  immunity,

  /// 同盟加成
  allianceBonus,
}

/// 復活動畫
/// 用於顯示從政治死亡中復活的特效
class RevivalAnimation extends StatelessWidget {
  /// 復活的玩家名稱
  final String playerName;

  /// 治療者名稱
  final String? healerName;

  /// 動畫完成回調
  final VoidCallback? onComplete;

  const RevivalAnimation({
    super.key,
    required this.playerName,
    this.healerName,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            AppTheme.raritySSR.withValues(alpha: 0.3),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 復活圖示
          Text(
            '👑',
            style: const TextStyle(fontSize: 64),
          )
              .animate(onComplete: (_) => onComplete?.call())
              .scale(
                begin: const Offset(0, 0),
                end: const Offset(1, 1),
                duration: 500.ms,
                curve: Curves.elasticOut,
              )
              .shimmer(
                duration: 1500.ms,
                color: AppTheme.raritySSR.withValues(alpha: 0.5),
              ),

          const SizedBox(height: 16),

          // 復活文字
          Text(
            '政治復活！',
            style: AppTheme.headlineMedium.copyWith(
              color: AppTheme.raritySSR,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: AppTheme.raritySSR.withValues(alpha: 0.5),
                  blurRadius: 12,
                ),
              ],
            ),
          ).animate(delay: 200.ms).fadeIn(duration: 300.ms),

          const SizedBox(height: 8),

          // 玩家名稱
          Text(
            playerName,
            style: AppTheme.headlineSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ).animate(delay: 400.ms).fadeIn(duration: 300.ms),

          // 治療者
          if (healerName != null) ...[
            const SizedBox(height: 8),
            Text(
              '由 $healerName 復活',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondary,
              ),
            ).animate(delay: 600.ms).fadeIn(duration: 300.ms),
          ],
        ],
      ),
    );
  }
}

/// 連續治療動畫
/// 用於顯示多次連續治療的組合效果
class ComboHealAnimation extends StatelessWidget {
  /// 各次治療數值
  final List<int> heals;

  /// 動畫完成回調
  final VoidCallback? onComplete;

  const ComboHealAnimation({
    super.key,
    required this.heals,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    if (heals.isEmpty) return const SizedBox.shrink();

    final totalHeal = heals.fold(0, (sum, h) => sum + h);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 連擊數
        if (heals.length > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.successColor),
            ),
            child: Text(
              '${heals.length}連治療！',
              style: AppTheme.labelSmall.copyWith(
                color: AppTheme.successColor,
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
        // 總治療量
        HealAnimation(
          healAmount: totalHeal,
          type: heals.length >= 3 ? HealType.powerful : HealType.normal,
          isLarge: true,
          onComplete: onComplete,
        ),
      ],
    );
  }
}

/// 資源獲得動畫（用於顯示影響力或金幣獲得）
class ResourceGainAnimation extends StatelessWidget {
  /// 資源類型
  final ResourceType resourceType;

  /// 獲得量
  final int amount;

  /// 動畫完成回調
  final VoidCallback? onComplete;

  const ResourceGainAnimation({
    super.key,
    required this.resourceType,
    required this.amount,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getResourceColor();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '+$amount',
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
          style: const TextStyle(fontSize: 24),
        ),
      ],
    )
        .animate(onComplete: (_) => onComplete?.call())
        .fadeIn(duration: 150.ms)
        .moveY(begin: 0, end: -30, duration: 800.ms, curve: Curves.easeOut)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.1, 1.1),
          duration: 200.ms,
        )
        .then(delay: 400.ms)
        .fadeOut(duration: 300.ms);
  }

  Color _getResourceColor() {
    switch (resourceType) {
      case ResourceType.reputation:
        return AppTheme.reputationRed;
      case ResourceType.influence:
        return AppTheme.influenceBlue;
      case ResourceType.gold:
        return AppTheme.goldYellow;
    }
  }
}
