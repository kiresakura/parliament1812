import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/stamina_service.dart';

/// 行動力顯示元件
class StaminaBar extends ConsumerWidget {
  /// 是否顯示購買按鈕
  final bool showPurchaseButton;

  /// 購買回調
  final VoidCallback? onPurchase;

  const StaminaBar({
    super.key,
    this.showPurchaseButton = true,
    this.onPurchase,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final staminaAsync = ref.watch(currentStaminaProvider);
    final timeAsync = ref.watch(staminaTimeProvider);

    return staminaAsync.when(
      data: (stamina) {
        final progress = stamina / StaminaService.maxStamina;
        final isFull = stamina >= StaminaService.maxStamina;
        final isLow = stamina < 20;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 上排：標題 + 數值 + 購買按鈕
              Row(
                children: [
                  Icon(
                    Icons.bolt,
                    color: isLow ? Colors.red : Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '行動力',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$stamina / ${StaminaService.maxStamina}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isLow ? Colors.red : theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (showPurchaseButton && !isFull)
                    _PurchaseButton(onTap: () {
                      if (onPurchase != null) {
                        onPurchase!();
                      } else {
                        _showPurchaseDialog(context, ref);
                      }
                    }),
                ],
              ),

              const SizedBox(height: 6),

              // 進度條
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainer,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isLow
                        ? Colors.red
                        : isFull
                            ? Colors.green
                            : Colors.amber,
                  ),
                ),
              ),

              // 回復時間
              if (!isFull) ...[
                const SizedBox(height: 4),
                timeAsync.when(
                  data: (time) => Text(
                    '預計回滿：$time',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 50,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showPurchaseDialog(BuildContext context, WidgetRef ref) {
    showStaminaPurchaseDialog(context, ref);
  }
}

/// 購買按鈕
class _PurchaseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _PurchaseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: Colors.amber),
            SizedBox(width: 2),
            Text(
              '💎',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// 行動力不足對話框
Future<bool> showStaminaInsufficientDialog(
  BuildContext context,
  WidgetRef ref, {
  required int cost,
  required int current,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.bolt, color: Colors.red),
            const SizedBox(width: 8),
            Text('行動力不足', style: theme.textTheme.titleLarge),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('需要 $cost 行動力，目前只有 $current。'),
            const SizedBox(height: 16),
            _purchaseOption(
              theme,
              icon: '💎',
              label: '${StaminaService.gemCostHalf} 寶石 → +${StaminaService.staminaHalfRefill} 行動力',
              onTap: () async {
                final service = ref.read(staminaServiceProvider);
                await service.purchase(
                    StaminaService.staminaHalfRefill, StaminaService.gemCostHalf);
                ref.invalidate(currentStaminaProvider);
                if (ctx.mounted) Navigator.of(ctx).pop(true);
              },
            ),
            const SizedBox(height: 8),
            _purchaseOption(
              theme,
              icon: '💎',
              label: '${StaminaService.gemCostFull} 寶石 → 回滿行動力',
              onTap: () async {
                final service = ref.read(staminaServiceProvider);
                await service.refillFull();
                ref.invalidate(currentStaminaProvider);
                if (ctx.mounted) Navigator.of(ctx).pop(true);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// 行動力購買對話框
void showStaminaPurchaseDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.bolt, color: Colors.amber),
            const SizedBox(width: 8),
            Text('補充行動力', style: theme.textTheme.titleLarge),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _purchaseOption(
              theme,
              icon: '💎',
              label: '${StaminaService.gemCostHalf} 寶石 → +${StaminaService.staminaHalfRefill} 行動力',
              onTap: () async {
                final service = ref.read(staminaServiceProvider);
                await service.purchase(
                    StaminaService.staminaHalfRefill, StaminaService.gemCostHalf);
                ref.invalidate(currentStaminaProvider);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
            ),
            const SizedBox(height: 8),
            _purchaseOption(
              theme,
              icon: '💎',
              label: '${StaminaService.gemCostFull} 寶石 → 回滿行動力',
              onTap: () async {
                final service = ref.read(staminaServiceProvider);
                await service.refillFull();
                ref.invalidate(currentStaminaProvider);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('關閉'),
          ),
        ],
      );
    },
  );
}

Widget _purchaseOption(
  ThemeData theme, {
  required String icon,
  required String label,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(Icons.chevron_right,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
        ],
      ),
    ),
  );
}
