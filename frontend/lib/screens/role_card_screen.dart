import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/player_provider.dart';
import '../widgets/role_card_widget.dart';
import '../widgets/secret_mission_card.dart';

/// 角色卡展示畫面
class RoleCardScreen extends StatefulWidget {
  const RoleCardScreen({super.key});

  @override
  State<RoleCardScreen> createState() => _RoleCardScreenState();
}

class _RoleCardScreenState extends State<RoleCardScreen> {
  bool _showSecret = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('你的角色'),
      ),
      body: Consumer<PlayerProvider>(
        builder: (context, provider, _) {
          final player = provider.currentPlayer;
          final role = player?.role;
          final mission = provider.secretMission;

          if (player == null || role == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 角色卡
                RoleCardWidget(role: role),
                const SizedBox(height: 24),

                // 秘密任務按鈕
                _buildSecretToggle(),
                const SizedBox(height: 16),

                // 秘密任務卡（可展開）
                if (_showSecret && mission != null)
                  SecretMissionCard(mission: mission),

                const SizedBox(height: 24),

                // 提示文字
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '請記住你的角色和秘密任務，遊戲開始後將無法再次查看秘密任務。',
                          style: TextStyle(
                            color: Colors.orange[200],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 確認按鈕
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('我已準備好'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSecretToggle() {
    return GestureDetector(
      onTap: () => setState(() => _showSecret = !_showSecret),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _showSecret
                ? AppTheme.secondaryColor
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _showSecret ? Icons.visibility_off : Icons.visibility,
              color: AppTheme.secondaryColor,
            ),
            const SizedBox(width: 12),
            Text(
              _showSecret ? '隱藏秘密任務' : '查看秘密任務',
              style: const TextStyle(
                color: AppTheme.secondaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
