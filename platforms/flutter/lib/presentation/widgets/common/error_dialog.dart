import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

/// 錯誤對話框
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final bool showCancel;

  const ErrorDialog({
    super.key,
    this.title = '錯誤',
    required this.message,
    this.actionText,
    this.onAction,
    this.showCancel = true,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.primaryMid,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.danger, width: 1),
      ),
      title: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.danger, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.cinzel(
                color: AppTheme.danger,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: GoogleFonts.lora(
          color: AppTheme.textSecondary,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      actions: [
        if (showCancel)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '關閉',
              style: GoogleFonts.lora(color: AppTheme.textSecondary),
            ),
          ),
        if (actionText != null)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onAction?.call();
            },
            child: Text(
              actionText!,
              style: GoogleFonts.lora(
                color: AppTheme.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  /// 顯示錯誤對話框
  static Future<void> show(
    BuildContext context, {
    String title = '錯誤',
    required String message,
    String? actionText,
    VoidCallback? onAction,
    bool showCancel = true,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        actionText: actionText,
        onAction: onAction,
        showCancel: showCancel,
      ),
    );
  }
}

/// 確認對話框
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final Color? confirmColor;
  final VoidCallback? onConfirm;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = '確認',
    this.cancelText = '取消',
    this.confirmColor,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.primaryMid,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.accent, width: 1),
      ),
      title: Text(
        title,
        style: GoogleFonts.cinzel(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: Text(
        message,
        style: GoogleFonts.lora(
          color: AppTheme.textSecondary,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            cancelText,
            style: GoogleFonts.lora(color: AppTheme.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, true);
            onConfirm?.call();
          },
          child: Text(
            confirmText,
            style: GoogleFonts.lora(
              color: confirmColor ?? AppTheme.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// 顯示確認對話框
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = '確認',
    String cancelText = '取消',
    Color? confirmColor,
    VoidCallback? onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: confirmColor,
        onConfirm: onConfirm,
      ),
    );
  }
}

/// 載入對話框
class LoadingDialog extends StatelessWidget {
  final String message;

  const LoadingDialog({
    super.key,
    this.message = '載入中...',
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: AppTheme.primaryMid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.accent, width: 1),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: GoogleFonts.lora(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 顯示載入對話框
  static void show(BuildContext context, {String message = '載入中...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoadingDialog(message: message),
    );
  }

  /// 隱藏載入對話框
  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}

/// Toast 訊息
void showToast(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: GoogleFonts.lora(),
      ),
      backgroundColor: isError ? AppTheme.danger : AppTheme.primaryMid,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isError ? AppTheme.danger : AppTheme.accent,
        ),
      ),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ),
  );
}

/// 成功訊息
void showSuccessToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.lora(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ),
  );
}
