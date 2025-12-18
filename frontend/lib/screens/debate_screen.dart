import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/room_provider.dart';
import '../providers/game_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/timer_widget.dart';
import '../widgets/phase_indicator.dart';
import '../widgets/player_avatar.dart';
import '../config/theme.dart';
import 'message_screen.dart';
import 'vote_screen.dart';

// 使用 ConversationListScreen 來顯示對話列表

/// 辯論主畫面
class DebateScreen extends StatefulWidget {
  const DebateScreen({super.key});

  @override
  State<DebateScreen> createState() => _DebateScreenState();
}

class _DebateScreenState extends State<DebateScreen> {
  @override
  Widget build(BuildContext context) {
    final roomProvider = Provider.of<RoomProvider>(context);
    final gameProvider = Provider.of<GameProvider>(context);
    final playerProvider = Provider.of<PlayerProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('1812 國會風雲'),
        actions: [
          // 私訊按鈕
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConversationListScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 階段指示器
            PhaseIndicator(
              currentPhase: gameProvider.currentPhase,
              phaseName: gameProvider.phaseName,
            ),

            // 計時器
            if (gameProvider.timerEndAt != null)
              TimerWidget(
                endTime: gameProvider.timerEndAt!,
                onTimerEnd: () {
                  // 計時結束處理
                },
              ),

            const SizedBox(height: 16),

            // 在線玩家列表
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: roomProvider.players.length,
                itemBuilder: (context, index) {
                  final player = roomProvider.players[index];
                  final isCurrentPlayer = player.id == playerProvider.currentPlayer?.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: PlayerAvatar(
                      nickname: player.nickname,
                      roleType: player.roleType,
                      isHost: player.isHost,
                      hasRole: player.roleType != null,
                      onTap: isCurrentPlayer ? null : () {
                        // 點擊其他玩家打開私訊
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MessageScreen(
                              otherPlayerId: player.id,
                              otherPlayerNickname: player.nickname,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            const Divider(),

            // 主要內容區域
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.record_voice_over,
                      size: 64,
                      color: AppTheme.secondaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      gameProvider.phaseName,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getPhaseDescription(gameProvider.currentPhase),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 底部操作按鈕
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ConversationListScreen()),
                        );
                      },
                      icon: const Icon(Icons.chat),
                      label: const Text('私訊密謀'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: gameProvider.currentPhase >= 8
                          ? () {
                              // 根據階段決定投票輪次
                              final round = gameProvider.currentPhase == 8 ? 1 : 2;
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => VoteScreen(round: round)),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.how_to_vote),
                      label: const Text('投票'),
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

  String _getPhaseDescription(int phase) {
    switch (phase) {
      case 2:
        return '研究你的角色背景\n與同陣營玩家討論策略';
      case 3:
        return '利用這段時間\n與其他玩家私下密謀';
      case 4:
        return '每位代表進行開場陳述\n表明立場';
      case 5:
      case 7:
        return '主持人抽取突發事件卡\n改變局勢';
      case 6:
        return '自由辯論時間\n說服其他代表支持你的立場';
      case 8:
        return '第一輪匿名投票\n只公布比例不公開身份';
      case 9:
        return '最後攻防時間\n做出最後的說服';
      case 10:
        return '第二輪記名投票\n公開唱票';
      default:
        return '';
    }
  }
}
