import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/event.dart';

/// 突發事件卡元件
class EventCard extends StatelessWidget {
  final GameEvent event;
  final bool isTriggered;
  final VoidCallback? onTrigger;

  const EventCard({
    super.key,
    required this.event,
    this.isTriggered = false,
    this.onTrigger,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getSeverityColor(event.severity).withValues(alpha: 0.3),
            AppTheme.cardBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getSeverityColor(event.severity).withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // 頂部標籤
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getSeverityColor(event.severity).withValues(alpha: 0.2),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getSeverityIcon(event.severity),
                  color: _getSeverityColor(event.severity),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  event.severityDescription,
                  style: TextStyle(
                    color: _getSeverityColor(event.severity),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (event.effectType != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      event.effectDescription,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 內容
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  event.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),

                // 觸發按鈕（僅主持人）
                if (onTrigger != null && !isTriggered) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onTrigger,
                      icon: const Icon(Icons.flash_on),
                      label: const Text('觸發事件'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getSeverityColor(event.severity),
                      ),
                    ),
                  ),
                ],

                // 已觸發標記
                if (isTriggered) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 6),
                        Text(
                          '已觸發',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(int severity) {
    switch (severity) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getSeverityIcon(int severity) {
    switch (severity) {
      case 1:
        return Icons.info_outline;
      case 2:
        return Icons.warning_amber_outlined;
      case 3:
        return Icons.report_outlined;
      case 4:
        return Icons.error_outline;
      case 5:
        return Icons.dangerous_outlined;
      default:
        return Icons.help_outline;
    }
  }
}

/// 事件彈出對話框
class EventPopupDialog extends StatelessWidget {
  final TriggeredEvent triggeredEvent;

  const EventPopupDialog({
    super.key,
    required this.triggeredEvent,
  });

  @override
  Widget build(BuildContext context) {
    final event = triggeredEvent.event;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getSeverityColor(event.severity),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 標題區
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getSeverityColor(event.severity).withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.flash_on,
                    color: _getSeverityColor(event.severity),
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '突發事件',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // 內容
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    event.description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('我知道了'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(int severity) {
    switch (severity) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
