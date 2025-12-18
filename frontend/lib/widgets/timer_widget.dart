import 'dart:async';
import 'package:flutter/material.dart';
import '../config/theme.dart';

/// 計時器元件
class TimerWidget extends StatefulWidget {
  final DateTime endTime;
  final VoidCallback? onTimerEnd;

  const TimerWidget({
    super.key,
    required this.endTime,
    this.onTimerEnd,
  });

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final remaining = widget.endTime.difference(now);

    setState(() {
      _remaining = remaining.isNegative ? Duration.zero : remaining;
    });

    if (remaining.isNegative && widget.onTimerEnd != null) {
      widget.onTimerEnd!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;
    final isUrgent = _remaining.inSeconds < 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.red.withValues(alpha: 0.2) : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUrgent ? Colors.red : AppTheme.secondaryColor,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: isUrgent ? Colors.red : AppTheme.secondaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isUrgent ? Colors.red : AppTheme.secondaryColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
