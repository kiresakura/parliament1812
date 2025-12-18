import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/room_provider.dart';
import '../providers/player_provider.dart';
import 'role_card_screen.dart';

/// NFC 掃描畫面
class ScanNfcScreen extends StatefulWidget {
  const ScanNfcScreen({super.key});

  @override
  State<ScanNfcScreen> createState() => _ScanNfcScreenState();
}

class _ScanNfcScreenState extends State<ScanNfcScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // 自動開始掃描
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScan();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    // 取消掃描
    context.read<PlayerProvider>().cancelNfcScan();
    super.dispose();
  }

  Future<void> _startScan() async {
    if (_isScanning) return;

    setState(() => _isScanning = true);

    final roomProvider = context.read<RoomProvider>();
    final playerProvider = context.read<PlayerProvider>();

    final roomCode = roomProvider.room?.code;
    if (roomCode == null) {
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    final player = await playerProvider.scanNfcCard(roomCode);

    if (mounted) {
      setState(() => _isScanning = false);

      if (player != null && player.hasRole) {
        // 掃描成功，跳轉到角色卡頁面
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleCardScreen()),
        );
      } else if (playerProvider.error != null) {
        // 顯示錯誤
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(playerProvider.error!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('掃描 NFC 卡片'),
      ),
      body: Consumer<PlayerProvider>(
        builder: (context, provider, _) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // NFC 動畫圖示
                  _buildNfcAnimation(),
                  const SizedBox(height: 48),

                  // 提示文字
                  Text(
                    _isScanning ? '請將卡片靠近手機背面' : '準備掃描',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '每張卡片對應一個獨特的角色和秘密任務',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // 錯誤訊息
                  if (provider.error != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              provider.error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 重新掃描按鈕
                  if (!_isScanning && provider.error != null) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _startScan,
                      icon: const Icon(Icons.refresh),
                      label: const Text('重新掃描'),
                    ),
                  ],

                  // 載入指示器
                  if (provider.isLoading) ...[
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(
                      color: AppTheme.secondaryColor,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '正在驗證卡片...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNfcAnimation() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // 外圈波紋
            for (var i = 0; i < 3; i++)
              Transform.scale(
                scale: 1 + ((_animationController.value + i * 0.33) % 1) * 0.5,
                child: Opacity(
                  opacity: 1 - ((_animationController.value + i * 0.33) % 1),
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.secondaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            // 中心圖示
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.nfc,
                size: 48,
                color: AppTheme.secondaryColor,
              ),
            ),
          ],
        );
      },
    );
  }
}
