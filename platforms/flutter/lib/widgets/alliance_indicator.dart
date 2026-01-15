import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../models/alliance.dart';
import '../models/player.dart';

/// 同盟指示器 Widget
/// 1812 國會風雲 - 顯示玩家之間的同盟關係
class AllianceIndicator extends StatelessWidget {
  /// 同盟關係
  final Alliance alliance;

  /// 是否為主視角玩家的同盟
  final bool isMyAlliance;

  /// 是否顯示詳細資訊
  final bool showDetails;

  /// 點擊同盟時的回調
  final VoidCallback? onTap;

  /// 長按查看同盟詳情
  final VoidCallback? onLongPress;

  const AllianceIndicator({
    super.key,
    required this.alliance,
    this.isMyAlliance = false,
    this.showDetails = true,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _getAllianceColor().withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getAllianceColor().withValues(alpha: 0.5),
            width: isMyAlliance ? 2 : 1,
          ),
          boxShadow: isMyAlliance
              ? [
                  BoxShadow(
                    color: _getAllianceColor().withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 同盟圖示
            _buildAllianceIcon(),
            if (showDetails) ...[
              const SizedBox(width: 8),
              _buildAllianceInfo(),
            ],
          ],
        ),
      ),
    );
  }

  /// 同盟圖示
  Widget _buildAllianceIcon() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            _getAllianceColor(),
            _getAllianceColor().withValues(alpha: 0.6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _getAllianceColor().withValues(alpha: 0.5),
            blurRadius: 6,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '🤝',
          style: TextStyle(fontSize: 16),
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.1, 1.1),
          duration: 1500.ms,
        );
  }

  /// 同盟資訊
  Widget _buildAllianceInfo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getAllianceTypeText(),
          style: AppTheme.labelSmall.copyWith(
            color: _getAllianceColor(),
            fontWeight: FontWeight.bold,
          ),
        ),
        ...[
          const SizedBox(height: 2),
          Text(
            '第 ${_getTurnsSinceFormed()} 回合',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textTertiary,
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }

  /// 取得同盟類型文字
  String _getAllianceTypeText() {
    switch (alliance.type) {
      case AllianceType.political:
        return '政治同盟';
      case AllianceType.economic:
        return '經濟同盟';
      case AllianceType.secret:
        return '秘密同盟';
      case AllianceType.temporary:
        return '暫時同盟';
    }
  }

  /// 取得同盟顏色
  Color _getAllianceColor() {
    switch (alliance.type) {
      case AllianceType.political:
        return AppTheme.raritySR; // 紫色
      case AllianceType.economic:
        return AppTheme.goldYellow; // 金色
      case AllianceType.secret:
        return AppTheme.textSecondary; // 灰色
      case AllianceType.temporary:
        return AppTheme.influenceBlue; // 藍色
    }
  }

  /// 計算同盟成立以來的回合數
  int _getTurnsSinceFormed() {
    // 簡化計算，實際應從遊戲狀態取得
    return 1;
  }
}

/// 同盟徽章
/// 顯示在玩家頭像旁的小型同盟標記
class AllianceBadge extends StatelessWidget {
  /// 同盟數量
  final int allianceCount;

  /// 同盟類型列表
  final List<AllianceType> types;

  /// 是否顯示數量
  final bool showCount;

  const AllianceBadge({
    super.key,
    required this.allianceCount,
    this.types = const [],
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    if (allianceCount == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.raritySR.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.raritySR.withValues(alpha: 0.5),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🤝', style: TextStyle(fontSize: 10)),
          if (showCount && allianceCount > 1) ...[
            const SizedBox(width: 2),
            Text(
              '×$allianceCount',
              style: AppTheme.labelSmall.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 同盟連線視覺化
/// 在場上玩家之間繪製同盟連線
class AllianceConnectionPainter extends CustomPainter {
  /// 同盟列表
  final List<AllianceConnection> connections;

  /// 是否使用動畫
  final double animationProgress;

  AllianceConnectionPainter({
    required this.connections,
    this.animationProgress = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final connection in connections) {
      _drawConnection(canvas, connection);
    }
  }

  void _drawConnection(Canvas canvas, AllianceConnection connection) {
    final paint = Paint()
      ..color = _getConnectionColor(connection.type)
          .withValues(alpha: 0.6 * animationProgress)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // 繪製曲線連接
    final path = Path();
    path.moveTo(connection.start.dx, connection.start.dy);

    // 計算控制點使線條呈弧形
    final midX = (connection.start.dx + connection.end.dx) / 2;
    final midY = (connection.start.dy + connection.end.dy) / 2;
    final controlY = midY - 30; // 向上彎曲

    path.quadraticBezierTo(
      midX,
      controlY,
      connection.end.dx,
      connection.end.dy,
    );

    canvas.drawPath(path, paint);

    // 在連線中央繪製同盟標記
    if (animationProgress > 0.5) {
      final iconPaint = Paint()
        ..color = _getConnectionColor(connection.type)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(midX, controlY),
        8,
        iconPaint,
      );
    }
  }

  Color _getConnectionColor(AllianceType type) {
    switch (type) {
      case AllianceType.political:
        return AppTheme.raritySR;
      case AllianceType.economic:
        return AppTheme.goldYellow;
      case AllianceType.secret:
        return AppTheme.textSecondary;
      case AllianceType.temporary:
        return AppTheme.influenceBlue;
    }
  }

  @override
  bool shouldRepaint(AllianceConnectionPainter oldDelegate) {
    return connections != oldDelegate.connections ||
        animationProgress != oldDelegate.animationProgress;
  }
}

/// 同盟連線資料
class AllianceConnection {
  final Offset start;
  final Offset end;
  final AllianceType type;
  final String player1Id;
  final String player2Id;

  const AllianceConnection({
    required this.start,
    required this.end,
    required this.type,
    required this.player1Id,
    required this.player2Id,
  });
}

/// 同盟形成動畫
class AllianceFormAnimation extends StatelessWidget {
  /// 玩家 1 名稱
  final String player1Name;

  /// 玩家 2 名稱
  final String player2Name;

  /// 同盟類型
  final AllianceType type;

  /// 動畫完成回調
  final VoidCallback? onComplete;

  const AllianceFormAnimation({
    super.key,
    required this.player1Name,
    required this.player2Name,
    required this.type,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getAllianceColor().withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getAllianceColor().withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 標題
          Text(
            '🤝 同盟建立！',
            style: AppTheme.headlineMedium.copyWith(
              color: _getAllianceColor(),
              fontWeight: FontWeight.bold,
            ),
          ).animate(onComplete: (_) => onComplete?.call()).fadeIn(duration: 300.ms).scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.0, 1.0),
                duration: 400.ms,
                curve: Curves.elasticOut,
              ),

          const SizedBox(height: 16),

          // 兩位玩家名稱
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPlayerBadge(player1Name),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '×',
                  style: AppTheme.headlineSmall.copyWith(
                    color: _getAllianceColor(),
                  ),
                ),
              ),
              _buildPlayerBadge(player2Name),
            ],
          ).animate(delay: 200.ms).fadeIn(duration: 300.ms),

          const SizedBox(height: 12),

          // 同盟類型
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getAllianceColor().withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getAllianceColor().withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              _getAllianceTypeText(),
              style: AppTheme.labelMedium.copyWith(
                color: _getAllianceColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ).animate(delay: 400.ms).fadeIn(duration: 300.ms).slideY(
                begin: 0.3,
                end: 0,
                curve: Curves.easeOut,
              ),
        ],
      ),
    );
  }

  Widget _buildPlayerBadge(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.panelBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        name,
        style: AppTheme.labelMedium.copyWith(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getAllianceColor() {
    switch (type) {
      case AllianceType.political:
        return AppTheme.raritySR;
      case AllianceType.economic:
        return AppTheme.goldYellow;
      case AllianceType.secret:
        return AppTheme.textSecondary;
      case AllianceType.temporary:
        return AppTheme.influenceBlue;
    }
  }

  String _getAllianceTypeText() {
    switch (type) {
      case AllianceType.political:
        return '政治同盟';
      case AllianceType.economic:
        return '經濟同盟';
      case AllianceType.secret:
        return '秘密同盟';
      case AllianceType.temporary:
        return '暫時同盟';
    }
  }
}

/// 背叛動畫
class BetrayalAnimation extends StatelessWidget {
  /// 背叛者名稱
  final String betrayerName;

  /// 受害者名稱
  final String victimName;

  /// 造成的傷害
  final int damage;

  /// 動畫完成回調
  final VoidCallback? onComplete;

  const BetrayalAnimation({
    super.key,
    required this.betrayerName,
    required this.victimName,
    required this.damage,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.errorColor.withValues(alpha: 0.7),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.errorColor.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 標題
          Text(
            '💔 同盟破裂！',
            style: AppTheme.headlineMedium.copyWith(
              color: AppTheme.errorColor,
              fontWeight: FontWeight.bold,
            ),
          )
              .animate(onComplete: (_) => onComplete?.call())
              .fadeIn(duration: 200.ms)
              .shakeX(hz: 4, amount: 5, duration: 400.ms),

          const SizedBox(height: 16),

          // 背叛描述
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
              children: [
                TextSpan(
                  text: betrayerName,
                  style: const TextStyle(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(text: ' 背叛了 '),
                TextSpan(
                  text: victimName,
                  style: const TextStyle(
                    color: AppTheme.warningColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(text: '！'),
              ],
            ),
          ).animate(delay: 300.ms).fadeIn(duration: 300.ms),

          const SizedBox(height: 12),

          // 傷害數值
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '-$damage',
                style: AppTheme.headlineLarge.copyWith(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              const Text('❤️', style: TextStyle(fontSize: 24)),
            ],
          )
              .animate(delay: 500.ms)
              .fadeIn(duration: 200.ms)
              .scale(
                begin: const Offset(1.5, 1.5),
                end: const Offset(1.0, 1.0),
                duration: 300.ms,
                curve: Curves.elasticOut,
              ),

          const SizedBox(height: 8),

          // 背叛懲罰說明
          Text(
            '背叛者 2 回合內無法再次結盟',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ).animate(delay: 700.ms).fadeIn(duration: 300.ms),
        ],
      ),
    );
  }
}

/// 同盟請求卡片
class AllianceRequestCard extends StatelessWidget {
  /// 請求者
  final Player requester;

  /// 同盟類型
  final AllianceType type;

  /// 接受回調
  final VoidCallback? onAccept;

  /// 拒絕回調
  final VoidCallback? onReject;

  const AllianceRequestCard({
    super.key,
    required this.requester,
    required this.type,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getAllianceColor().withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 標題
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🤝', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                '同盟請求',
                style: AppTheme.headlineSmall.copyWith(
                  color: _getAllianceColor(),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 請求者資訊
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.panelBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 請求者頭像
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _getAllianceColor().withValues(alpha: 0.2),
                  child: Text(
                    requester.nickname.isNotEmpty
                        ? requester.nickname[0].toUpperCase()
                        : '?',
                    style: AppTheme.labelMedium.copyWith(
                      color: _getAllianceColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      requester.nickname,
                      style: AppTheme.labelMedium.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '提議 ${_getAllianceTypeText()}',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 按鈕
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拒絕按鈕
              OutlinedButton(
                onPressed: onReject,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: const BorderSide(color: AppTheme.errorColor),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('拒絕'),
              ),
              const SizedBox(width: 16),
              // 接受按鈕
              ElevatedButton(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getAllianceColor(),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('接受'),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOut);
  }

  Color _getAllianceColor() {
    switch (type) {
      case AllianceType.political:
        return AppTheme.raritySR;
      case AllianceType.economic:
        return AppTheme.goldYellow;
      case AllianceType.secret:
        return AppTheme.textSecondary;
      case AllianceType.temporary:
        return AppTheme.influenceBlue;
    }
  }

  String _getAllianceTypeText() {
    switch (type) {
      case AllianceType.political:
        return '政治同盟';
      case AllianceType.economic:
        return '經濟同盟';
      case AllianceType.secret:
        return '秘密同盟';
      case AllianceType.temporary:
        return '暫時同盟';
    }
  }
}

/// 同盟狀態面板
/// 顯示玩家當前的所有同盟關係
class AllianceStatusPanel extends StatelessWidget {
  /// 同盟列表
  final List<Alliance> alliances;

  /// 當前玩家 ID
  final String currentPlayerId;

  /// 玩家名稱映射
  final Map<String, String> playerNames;

  /// 背叛回調
  final void Function(Alliance alliance)? onBetray;

  /// 最大同盟數
  static const int maxAlliances = 2;

  const AllianceStatusPanel({
    super.key,
    required this.alliances,
    required this.currentPlayerId,
    required this.playerNames,
    this.onBetray,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 標題
          Row(
            children: [
              const Text('🤝', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                '我的同盟',
                style: AppTheme.labelMedium.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // 同盟數量
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getCountColor().withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${alliances.length}/$maxAlliances',
                  style: AppTheme.labelSmall.copyWith(
                    color: _getCountColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 同盟列表或空狀態
          if (alliances.isEmpty)
            _buildEmptyState()
          else
            ...alliances.map((alliance) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildAllianceItem(alliance),
                )),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.panelBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.textTertiary.withValues(alpha: 0.3),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            color: AppTheme.textTertiary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '尚無同盟關係',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllianceItem(Alliance alliance) {
    final partnerId = alliance.player1Id == currentPlayerId
        ? alliance.player2Id
        : alliance.player1Id;
    final partnerName = playerNames[partnerId] ?? '未知玩家';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getAllianceColor(alliance.type).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getAllianceColor(alliance.type).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // 同盟圖示
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getAllianceColor(alliance.type).withValues(alpha: 0.2),
            ),
            child: const Center(
              child: Text('🤝', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          // 同盟資訊
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partnerName,
                  style: AppTheme.labelMedium.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _getAllianceTypeText(alliance.type),
                  style: AppTheme.bodySmall.copyWith(
                    color: _getAllianceColor(alliance.type),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // 背叛按鈕
          if (onBetray != null)
            IconButton(
              onPressed: () => onBetray!(alliance),
              icon: const Icon(Icons.heart_broken, size: 18),
              color: AppTheme.errorColor,
              tooltip: '背叛同盟',
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.errorColor.withValues(alpha: 0.1),
              ),
            ),
        ],
      ),
    );
  }

  Color _getCountColor() {
    if (alliances.length >= maxAlliances) {
      return AppTheme.warningColor;
    }
    return AppTheme.successColor;
  }

  Color _getAllianceColor(AllianceType type) {
    switch (type) {
      case AllianceType.political:
        return AppTheme.raritySR;
      case AllianceType.economic:
        return AppTheme.goldYellow;
      case AllianceType.secret:
        return AppTheme.textSecondary;
      case AllianceType.temporary:
        return AppTheme.influenceBlue;
    }
  }

  String _getAllianceTypeText(AllianceType type) {
    switch (type) {
      case AllianceType.political:
        return '政治同盟';
      case AllianceType.economic:
        return '經濟同盟';
      case AllianceType.secret:
        return '秘密同盟';
      case AllianceType.temporary:
        return '暫時同盟';
    }
  }
}
