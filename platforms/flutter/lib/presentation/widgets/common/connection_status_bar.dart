import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/services/socket_service.dart';
import '../../../providers/socket_provider.dart';

/// 連接狀態欄
class ConnectionStatusBar extends ConsumerWidget {
  final bool showWhenConnected;

  const ConnectionStatusBar({
    super.key,
    this.showWhenConnected = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(socketConnectionProvider);

    // 已連接且不顯示時，返回空
    if (connectionState == ConnectionState.connected && !showWhenConnected) {
      return const SizedBox.shrink();
    }

    final (color, icon, text, showRetry) = _getStatusInfo(connectionState);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: color.withAlpha(230),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            _buildIcon(icon, connectionState),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.lora(
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ),
            if (showRetry)
              TextButton(
                onPressed: () => _reconnect(ref),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                child: Text(
                  '重新連接',
                  style: GoogleFonts.lora(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(IconData icon, ConnectionState state) {
    if (state == ConnectionState.connecting || state == ConnectionState.reconnecting) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }
    return Icon(icon, color: Colors.white, size: 18);
  }

  (Color, IconData, String, bool) _getStatusInfo(ConnectionState state) {
    switch (state) {
      case ConnectionState.connecting:
        return (Colors.orange, Icons.sync, '正在連接伺服器...', false);
      case ConnectionState.connected:
        return (AppTheme.success, Icons.check_circle, '已連接', false);
      case ConnectionState.reconnecting:
        return (Colors.orange, Icons.sync, '正在重新連接...', false);
      case ConnectionState.error:
        return (AppTheme.danger, Icons.error, '連接失敗', true);
      case ConnectionState.disconnected:
        return (AppTheme.textSecondary, Icons.cloud_off, '未連接', true);
    }
  }

  void _reconnect(WidgetRef ref) {
    ref.read(socketServiceProvider).reconnect();
  }
}

/// 連接狀態指示器（小圓點）
class ConnectionStatusIndicator extends ConsumerWidget {
  final double size;

  const ConnectionStatusIndicator({
    super.key,
    this.size = 8,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(socketConnectionProvider);
    final color = _getColor(connectionState);
    final isAnimating = connectionState == ConnectionState.connecting ||
        connectionState == ConnectionState.reconnecting;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: isAnimating
            ? [
                BoxShadow(
                  color: color.withAlpha(128),
                  blurRadius: 4,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
    );
  }

  Color _getColor(ConnectionState state) {
    switch (state) {
      case ConnectionState.connected:
        return AppTheme.success;
      case ConnectionState.connecting:
      case ConnectionState.reconnecting:
        return Colors.orange;
      case ConnectionState.error:
      case ConnectionState.disconnected:
        return AppTheme.danger;
    }
  }
}

/// 連接狀態監聽器
class ConnectionStatusListener extends ConsumerWidget {
  final Widget child;
  final VoidCallback? onConnected;
  final VoidCallback? onDisconnected;
  final VoidCallback? onError;

  const ConnectionStatusListener({
    super.key,
    required this.child,
    this.onConnected,
    this.onDisconnected,
    this.onError,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<ConnectionState>(socketConnectionProvider, (previous, next) {
      if (previous == next) return;

      switch (next) {
        case ConnectionState.connected:
          onConnected?.call();
          break;
        case ConnectionState.disconnected:
          onDisconnected?.call();
          break;
        case ConnectionState.error:
          onError?.call();
          break;
        default:
          break;
      }
    });

    return child;
  }
}
