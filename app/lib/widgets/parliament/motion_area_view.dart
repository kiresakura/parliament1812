import 'package:flutter/material.dart';

import '../../ui/theme/game_colors.dart';
import '../../ui/theme/game_fonts.dart';
import '../../ui/theme/game_animations.dart';

/// 議案資訊
class MotionInfo {
  final String title;
  final String? description;
  final int reading; // 1, 2, 3（讀數階段）
  final double forRatio; // 0.0 ~ 1.0
  final double againstRatio; // 0.0 ~ 1.0

  const MotionInfo({
    required this.title,
    this.description,
    this.reading = 1,
    this.forRatio = 0.0,
    this.againstRatio = 0.0,
  });
}

/// 辯論日誌條目
class DebateLogEntry {
  final String id;
  final String playerName;
  final String? cardName;
  final String description;
  final DateTime timestamp;

  const DebateLogEntry({
    required this.id,
    required this.playerName,
    this.cardName,
    required this.description,
    required this.timestamp,
  });
}

/// 中央議案區
///
/// 高度 ~160pt，bgSecondary 背景，金色邊框
/// 包含：議案標題、投票進度條（FOR/AGAINST）、辯論日誌
class MotionAreaView extends StatelessWidget {
  final MotionInfo motion;
  final List<DebateLogEntry> logEntries;

  const MotionAreaView({
    super.key,
    required this.motion,
    this.logEntries = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GameColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GameColors.victorianGold.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 頂部標籤列
          Row(
            children: [
              Text(
                'MOTION IN PROGRESS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: GameColors.victorianGold.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              _ReadingBadge(reading: motion.reading),
            ],
          ),
          const SizedBox(height: 8),

          // 議案標題
          Text(
            motion.title,
            style: GameFont.billTitle.copyWith(
              color: GameColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          if (motion.description != null) ...[
            const SizedBox(height: 4),
            Text(
              motion.description!,
              style: GameFont.billBody.copyWith(
                color: GameColors.textSecondary,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),

          // 投票進度條
          VoteProgressBar(
            forRatio: motion.forRatio,
            againstRatio: motion.againstRatio,
          ),

          // 辯論日誌
          if (logEntries.isNotEmpty) ...[
            const SizedBox(height: 8),
            Divider(
              color: GameColors.victorianGold.withValues(alpha: 0.2),
              height: 1,
            ),
            const SizedBox(height: 8),
            ...logEntries.take(3).map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _DebateLogRow(entry: entry),
              );
            }),
          ],
        ],
      ),
    );
  }
}

/// 讀數階段徽章 (1ST / 2ND / 3RD READING)
class _ReadingBadge extends StatelessWidget {
  final int reading;

  const _ReadingBadge({required this.reading});

  String get _label {
    switch (reading) {
      case 1:
        return '1ST READING';
      case 2:
        return '2ND READING';
      case 3:
        return '3RD READING';
      default:
        return '${reading}TH READING';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: GameColors.victorianGold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: GameColors.victorianGold.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          color: GameColors.victorianGold,
        ),
      ),
    );
  }
}

/// 投票進度條：FOR (綠) vs AGAINST (紅)
class VoteProgressBar extends StatelessWidget {
  final double forRatio;
  final double againstRatio;

  const VoteProgressBar({
    super.key,
    required this.forRatio,
    required this.againstRatio,
  });

  @override
  Widget build(BuildContext context) {
    // Normalize: if both are 0, show empty bar
    final total = forRatio + againstRatio;
    final normalizedFor = total > 0 ? forRatio / total : 0.0;
    final normalizedAgainst = total > 0 ? againstRatio / total : 0.0;

    return SizedBox(
      height: 16,
      child: Row(
        children: [
          // FOR bar
          if (normalizedFor > 0)
            Expanded(
              flex: (normalizedFor * 100).round().clamp(1, 100),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: GameColors.voteFor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(2),
                    bottomLeft: const Radius.circular(2),
                    topRight: normalizedAgainst == 0
                        ? const Radius.circular(2)
                        : Radius.zero,
                    bottomRight: normalizedAgainst == 0
                        ? const Radius.circular(2)
                        : Radius.zero,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${(forRatio * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          if (normalizedFor > 0 && normalizedAgainst > 0)
            const SizedBox(width: 2),
          // AGAINST bar
          if (normalizedAgainst > 0)
            Expanded(
              flex: (normalizedAgainst * 100).round().clamp(1, 100),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: GameColors.voteAgainst,
                  borderRadius: BorderRadius.only(
                    topLeft: normalizedFor == 0
                        ? const Radius.circular(2)
                        : Radius.zero,
                    bottomLeft: normalizedFor == 0
                        ? const Radius.circular(2)
                        : Radius.zero,
                    topRight: const Radius.circular(2),
                    bottomRight: const Radius.circular(2),
                  ),
                ),
                child: Center(
                  child: Text(
                    '${(againstRatio * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          // Empty state
          if (total == 0)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: GameColors.bgCard,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Center(
                  child: Text(
                    '等待投票',
                    style: TextStyle(
                      color: GameColors.textMuted,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 辯論日誌單行
class _DebateLogRow extends StatefulWidget {
  final DebateLogEntry entry;

  const _DebateLogRow({required this.entry});

  @override
  State<_DebateLogRow> createState() => _DebateLogRowState();
}

class _DebateLogRowState extends State<_DebateLogRow> {
  bool _appeared = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _appeared = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _appeared ? 1.0 : 0.0,
      duration: GameAnimation.debateLogEntryDuration,
      curve: GameAnimation.debateLogEntryCurve,
      child: Row(
        children: [
          // 玩家名：金色加粗
          Text(
            widget.entry.playerName,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: GameColors.victorianGold,
            ),
          ),
          const SizedBox(width: 4),
          // 卡牌名：紫色斜體
          if (widget.entry.cardName != null) ...[
            Text(
              widget.entry.cardName!,
              style: const TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: GameColors.logCardName,
              ),
            ),
            const SizedBox(width: 4),
          ],
          // 事件描述：暖白色
          Expanded(
            child: Text(
              widget.entry.description,
              style: const TextStyle(
                fontSize: 11,
                color: GameColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
