import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectionStatus {
  connected,
  connecting,
  disconnected,
  error,
}

extension ConnectionStatusExtension on ConnectionStatus {
  Color get color {
    switch (this) {
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.connecting:
        return Colors.orange;
      case ConnectionStatus.disconnected:
        return Colors.grey;
      case ConnectionStatus.error:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case ConnectionStatus.connected:
        return Icons.wifi;
      case ConnectionStatus.connecting:
        return Icons.wifi_off;
      case ConnectionStatus.disconnected:
        return Icons.wifi_off;
      case ConnectionStatus.error:
        return Icons.error;
    }
  }

  String get displayName {
    switch (this) {
      case ConnectionStatus.connected:
        return '已連接';
      case ConnectionStatus.connecting:
        return '連接中';
      case ConnectionStatus.disconnected:
        return '已斷線';
      case ConnectionStatus.error:
        return '連接錯誤';
    }
  }

  String get description {
    switch (this) {
      case ConnectionStatus.connected:
        return '與伺服器連接正常';
      case ConnectionStatus.connecting:
        return '正在嘗試連接伺服器...';
      case ConnectionStatus.disconnected:
        return '與伺服器連接中斷';
      case ConnectionStatus.error:
        return '連接發生錯誤，請檢查網路';
    }
  }
}

// TODO: 實際的連線狀態 Provider
final connectionStatusProvider = StateProvider<ConnectionStatus>((ref) {
  // 模擬連線狀態，實際應該從 WebSocket 服務取得
  return ConnectionStatus.connected;
});

final connectionLatencyProvider = StateProvider<int?>((ref) {
  // 模擬延遲，實際應該從 WebSocket 服務取得
  return 45; // ms
});

class ConnectionIndicator extends ConsumerWidget {
  final bool showLabel;
  final bool showLatency;

  const ConnectionIndicator({
    super.key,
    this.showLabel = false,
    this.showLatency = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectionStatusProvider);
    final latency = ref.watch(connectionLatencyProvider);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _showConnectionDetails(context, status, latency),
      child: Container(
        padding: EdgeInsets.all(showLabel ? 8 : 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 連接狀態圖標
            Stack(
              children: [
                Icon(
                  status.icon,
                  color: status.color,
                  size: 20,
                ),
                
                // 連接中的動畫
                if (status == ConnectionStatus.connecting)
                  Positioned.fill(
                    child: _PulsingIcon(
                      icon: Icons.wifi,
                      color: status.color,
                    ),
                  ),
              ],
            ),
            
            // 狀態標籤（可選）
            if (showLabel) ...[
              const SizedBox(width: 6),
              
              Text(
                status.displayName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: status.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            
            // 延遲顯示（可選）
            if (showLatency && latency != null && status == ConnectionStatus.connected) ...[
              const SizedBox(width: 6),
              
              Text(
                '${latency}ms',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _getLatencyColor(latency),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getLatencyColor(int latency) {
    if (latency <= 50) return Colors.green;
    if (latency <= 100) return Colors.orange;
    return Colors.red;
  }

  void _showConnectionDetails(BuildContext context, ConnectionStatus status, int? latency) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _ConnectionDetailsSheet(
        status: status,
        latency: latency,
      ),
    );
  }
}

class _PulsingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _PulsingIcon({
    required this.icon,
    required this.color,
  });

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Icon(
            widget.icon,
            color: widget.color,
            size: 20,
          ),
        );
      },
    );
  }
}

class _ConnectionDetailsSheet extends ConsumerWidget {
  final ConnectionStatus status;
  final int? latency;

  const _ConnectionDetailsSheet({
    required this.status,
    required this.latency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題
          Row(
            children: [
              Icon(
                Icons.wifi_find,
                color: theme.colorScheme.primary,
              ),
              
              const SizedBox(width: 12),
              
              Text(
                '連接狀態',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 連接狀態
          _DetailItem(
            label: '狀態',
            value: status.displayName,
            valueColor: status.color,
            icon: status.icon,
            iconColor: status.color,
          ),
          
          const SizedBox(height: 16),
          
          // 延遲
          if (latency != null && status == ConnectionStatus.connected)
            _DetailItem(
              label: '延遲',
              value: '${latency} ms',
              valueColor: _getLatencyColor(latency!),
              icon: Icons.speed,
              iconColor: _getLatencyColor(latency!),
            ),
          
          const SizedBox(height: 16),
          
          // 伺服器
          _DetailItem(
            label: '伺服器',
            value: 'localhost:8080',
            icon: Icons.dns,
          ),
          
          const SizedBox(height: 24),
          
          // 狀態描述
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: status.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: status.color.withOpacity(0.3),
              ),
            ),
            child: Text(
              status.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: status.color,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 操作按鈕
          if (status != ConnectionStatus.connected)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _reconnect(ref),
                icon: const Icon(Icons.refresh),
                label: const Text('重新連接'),
              ),
            ),
        ],
      ),
    );
  }

  Color _getLatencyColor(int latency) {
    if (latency <= 50) return Colors.green;
    if (latency <= 100) return Colors.orange;
    return Colors.red;
  }

  void _reconnect(WidgetRef ref) {
    // TODO: 實際重新連接邏輯
    ref.read(connectionStatusProvider.notifier).state = ConnectionStatus.connecting;
    
    // 模擬重新連接
    Future.delayed(const Duration(seconds: 2), () {
      ref.read(connectionStatusProvider.notifier).state = ConnectionStatus.connected;
    });
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;
  final Color? iconColor;

  const _DetailItem({
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon!,
            size: 20,
            color: iconColor ?? theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          
          const SizedBox(width: 12),
        ],
        
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: valueColor ?? theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}