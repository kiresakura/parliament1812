import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

/// 房間代碼顯示組件
class RoomCodeDisplay extends StatefulWidget {
  /// 房間代碼
  final String code;

  /// 標題文字
  final String? title;

  /// 是否緊湊模式
  final bool compact;

  const RoomCodeDisplay({
    super.key,
    required this.code,
    this.title,
    this.compact = false,
  });

  @override
  State<RoomCodeDisplay> createState() => _RoomCodeDisplayState();
}

class _RoomCodeDisplayState extends State<RoomCodeDisplay>
    with SingleTickerProviderStateMixin {
  bool _copied = false;

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);

    // 顯示複製成功提示
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '已複製房間代碼',
            style: GoogleFonts.lora(),
          ),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }

    // 2 秒後重置狀態
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _copied = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompact();
    }
    return _buildFull();
  }

  Widget _buildCompact() {
    return GestureDetector(
      onTap: _copyToClipboard,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryMid,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.accent.withAlpha(128),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.code,
              style: GoogleFonts.cinzelDecorative(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.accent,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              _copied ? Icons.check : Icons.copy,
              color: _copied ? AppTheme.success : AppTheme.accent,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFull() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.title != null) ...[
          Text(
            widget.title!,
            style: GoogleFonts.lora(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
        ],

        GestureDetector(
          onTap: _copyToClipboard,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.primaryMid,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.accent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accent.withAlpha(51),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                // 房間代碼 - 大字顯示
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: widget.code.split('').map((char) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryDark,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppTheme.accent.withAlpha(77),
                        ),
                      ),
                      child: Text(
                        char,
                        style: GoogleFonts.cinzelDecorative(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accent,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                // 點擊複製提示
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _copied ? Icons.check : Icons.copy,
                      color: _copied ? AppTheme.success : AppTheme.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _copied ? '已複製！' : '點擊複製',
                      style: GoogleFonts.lora(
                        fontSize: 12,
                        color: _copied
                            ? AppTheme.success
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
