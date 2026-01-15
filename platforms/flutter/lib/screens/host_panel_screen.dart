import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/room_provider.dart';
import '../providers/game_provider.dart';
import '../config/theme.dart';
import '../utils/constants.dart';

/// 主持人控制面板
class HostPanelScreen extends StatefulWidget {
  const HostPanelScreen({super.key});

  @override
  State<HostPanelScreen> createState() => _HostPanelScreenState();
}

class _HostPanelScreenState extends State<HostPanelScreen> {
  int _selectedTimer = 5;

  @override
  Widget build(BuildContext context) {
    final roomProvider = Provider.of<RoomProvider>(context);
    final gameProvider = Provider.of<GameProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('主持人控制面板'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 房間資訊
              _buildSection(
                title: '房間資訊',
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('房間碼', roomProvider.room?.code ?? '-'),
                      _buildInfoRow('玩家數', '${roomProvider.players.length}/20'),
                      _buildInfoRow('目前階段', gameProvider.phaseName),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 階段控制
              _buildSection(
                title: '階段控制',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: GamePhase.values.map((phase) {
                    final isCurrentPhase = gameProvider.currentPhase == phase.index;
                    return ElevatedButton(
                      onPressed: () => _changePhase(phase.index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCurrentPhase
                            ? AppTheme.secondaryColor
                            : AppTheme.cardBackground,
                      ),
                      child: Text(phase.name),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // 計時器控制
              _buildSection(
                title: '計時器控制',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _selectedTimer.toDouble(),
                            min: 1,
                            max: 30,
                            divisions: 29,
                            label: '$_selectedTimer 分鐘',
                            onChanged: (value) {
                              setState(() {
                                _selectedTimer = value.toInt();
                              });
                            },
                          ),
                        ),
                        Text('$_selectedTimer 分鐘'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _startTimer(_selectedTimer),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('開始計時'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _stopTimer,
                          icon: const Icon(Icons.stop),
                          label: const Text('停止'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 突發事件
              _buildSection(
                title: '突發事件',
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _triggerRandomEvent,
                        icon: const Icon(Icons.shuffle),
                        label: const Text('抽取隨機事件'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 投票控制
              _buildSection(
                title: '投票控制',
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _startVoting(1),
                        child: const Text('開始第一輪投票'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _startVoting(2),
                        child: const Text('開始第二輪投票'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 結束遊戲
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _endGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('結束遊戲'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.secondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _changePhase(int phase) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    gameProvider.changePhase(phase);
  }

  void _startTimer(int minutes) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    gameProvider.startTimer(minutes);
  }

  void _stopTimer() {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    gameProvider.stopTimer();
  }

  void _triggerRandomEvent() {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    gameProvider.triggerRandomEvent();
  }

  void _startVoting(int round) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    gameProvider.startVoting(round);
  }

  void _endGame() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認結束遊戲？'),
        content: const Text('此操作將結束當前遊戲，所有玩家將被踢出房間。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final roomProvider = Provider.of<RoomProvider>(context, listen: false);
              roomProvider.closeRoom();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('確認結束'),
          ),
        ],
      ),
    );
  }
}
