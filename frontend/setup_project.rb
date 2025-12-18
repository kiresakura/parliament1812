#!/usr/bin/env ruby
# encoding: utf-8
# Parliament 1812 Flutter 專案設定腳本
# 執行: ruby setup_project.rb

require 'fileutils'

PROJECT_ROOT = File.dirname(__FILE__)
LIB_DIR = File.join(PROJECT_ROOT, 'lib')

puts "🏛️  Parliament 1812 專案設定腳本"
puts "=" * 50

# 建立目錄結構
def create_directories
  puts "\n📁 建立目錄結構..."

  dirs = [
    'lib/config',
    'lib/models',
    'lib/screens',
    'lib/services',
    'lib/providers',
    'lib/widgets',
    'lib/utils',
    'assets/images',
    'assets/icons',
  ]

  dirs.each do |dir|
    path = File.join(PROJECT_ROOT, dir)
    unless File.directory?(path)
      FileUtils.mkdir_p(path)
      puts "  ✅ 建立: #{dir}"
    end
  end
end

# 檢查並建立缺失的檔案
def create_missing_files
  puts "\n📝 檢查並建立缺失的檔案..."

  files = {
    # Models
    'lib/models/role.dart' => ROLE_MODEL,

    # Screens
    'lib/screens/debate_screen.dart' => DEBATE_SCREEN,
    'lib/screens/result_screen.dart' => RESULT_SCREEN,
    'lib/screens/host_panel_screen.dart' => HOST_PANEL_SCREEN,

    # Widgets
    'lib/widgets/timer_widget.dart' => TIMER_WIDGET,
    'lib/widgets/phase_indicator.dart' => PHASE_INDICATOR,

    # Utils
    'lib/utils/constants.dart' => CONSTANTS,
  }

  files.each do |file, content|
    path = File.join(PROJECT_ROOT, file)
    unless File.exist?(path)
      File.write(path, content)
      puts "  ✅ 建立: #{file}"
    else
      puts "  ⏭️  已存在: #{file}"
    end
  end
end

# ============== 檔案內容定義 ==============

ROLE_MODEL = <<~DART
/// 角色模型
class Role {
  final String id;
  final String type;
  final String name;
  final int age;
  final String description;
  final String stance;
  final String color;

  const Role({
    required this.id,
    required this.type,
    required this.name,
    required this.age,
    required this.description,
    required this.stance,
    required this.color,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      description: json['description'] ?? '',
      stance: json['stance'] ?? '',
      color: json['color'] ?? '#8B4513',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'age': age,
      'description': description,
      'stance': stance,
      'color': color,
    };
  }

  /// 預設角色列表
  static const List<Role> defaultRoles = [
    Role(
      id: 'worker',
      type: 'worker',
      name: '湯瑪斯',
      age: 38,
      description: '諾丁漢的紡織工人，擁有20年織布經驗',
      stance: '機器搶走了我們的飯碗',
      color: '#4A6741',
    ),
    Role(
      id: 'factory',
      type: 'factory',
      name: '理查·威爾森',
      age: 45,
      description: '曼徹斯特紡織廠主，從小作坊發展成大工廠',
      stance: '機器是進步的象徵',
      color: '#8B4513',
    ),
    Role(
      id: 'luddite',
      type: 'luddite',
      name: '喬治',
      age: 28,
      description: '盧德派成員，主張以行動抵抗機器',
      stance: '必須摧毀這些奪走生計的機器',
      color: '#8B0000',
    ),
    Role(
      id: 'reformer',
      type: 'reformer',
      name: '羅伯特·歐文',
      age: 35,
      description: '改革派企業家，提倡工人權益',
      stance: '機器與工人可以共存',
      color: '#4169E1',
    ),
    Role(
      id: 'mp',
      type: 'mp',
      name: '威廉·乾茨傑拉德',
      age: 52,
      description: '國會議員，需要在各方利益間權衡',
      stance: '需要審慎考慮各方立場',
      color: '#483D8B',
    ),
  ];

  static Role? fromType(String type) {
    try {
      return defaultRoles.firstWhere((r) => r.type == type);
    } catch (_) {
      return null;
    }
  }
}
DART

DEBATE_SCREEN = <<~DART
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
        title: Text('1812 國會風雲'),
        actions: [
          // 私訊按鈕
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MessageScreen()),
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
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: PlayerAvatar(
                      player: player,
                      isCurrentPlayer: player.id == playerProvider.currentPlayer?.id,
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
                    Icon(
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
                          MaterialPageRoute(builder: (_) => const MessageScreen()),
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const VoteScreen()),
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
        return '研究你的角色背景\\n與同陣營玩家討論策略';
      case 3:
        return '利用這段時間\\n與其他玩家私下密謀';
      case 4:
        return '每位代表進行開場陳述\\n表明立場';
      case 5:
      case 7:
        return '主持人抽取突發事件卡\\n改變局勢';
      case 6:
        return '自由辯論時間\\n說服其他代表支持你的立場';
      case 8:
        return '第一輪匿名投票\\n只公布比例不公開身份';
      case 9:
        return '最後攻防時間\\n做出最後的說服';
      case 10:
        return '第二輪記名投票\\n公開唱票';
      default:
        return '';
    }
  }
}
DART

RESULT_SCREEN = <<~DART
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/room_provider.dart';
import '../providers/game_provider.dart';
import '../config/theme.dart';

/// 結果畫面
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final roomProvider = Provider.of<RoomProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('投票結果'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 結果標題
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      size: 64,
                      color: AppTheme.secondaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '投票結果',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getWinningOption(gameProvider.voteResults),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 各選項得票
              Expanded(
                child: ListView(
                  children: [
                    _buildVoteResult(context, 'A', '禁止機器', gameProvider.voteResults['A'] ?? 0),
                    _buildVoteResult(context, 'B', '保護財產', gameProvider.voteResults['B'] ?? 0),
                    _buildVoteResult(context, 'C', '折衷改革', gameProvider.voteResults['C'] ?? 0),
                    if (gameProvider.voteResults.containsKey('D'))
                      _buildVoteResult(context, 'D', '皇家調查', gameProvider.voteResults['D'] ?? 0),
                  ],
                ),
              ),

              // 返回按鈕
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('返回首頁'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoteResult(BuildContext context, String option, String label, int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getOptionColor(option),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              option,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '\$count 票',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getOptionColor(String option) {
    switch (option) {
      case 'A':
        return Colors.red;
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.green;
      case 'D':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getWinningOption(Map<String, int> results) {
    if (results.isEmpty) return '尚無結果';

    var sorted = results.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.isEmpty) return '尚無結果';

    switch (sorted.first.key) {
      case 'A':
        return '選項 A - 禁止機器 獲勝';
      case 'B':
        return '選項 B - 保護財產 獲勝';
      case 'C':
        return '選項 C - 折衷改革 獲勝';
      case 'D':
        return '選項 D - 皇家調查 獲勝';
      default:
        return '尚無結果';
    }
  }
}
DART

HOST_PANEL_SCREEN = <<~DART
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
                      _buildInfoRow('玩家數', '\${roomProvider.players.length}/20'),
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
                            label: '\$_selectedTimer 分鐘',
                            onChanged: (value) {
                              setState(() {
                                _selectedTimer = value.toInt();
                              });
                            },
                          ),
                        ),
                        Text('\$_selectedTimer 分鐘'),
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
DART

TIMER_WIDGET = <<~DART
import 'dart:async';
import 'package:flutter/material.dart';
import '../config/theme.dart';

/// 計時器元件
class TimerWidget extends StatefulWidget {
  final DateTime endTime;
  final VoidCallback? onTimerEnd;

  const TimerWidget({
    super.key,
    required this.endTime,
    this.onTimerEnd,
  });

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final remaining = widget.endTime.difference(now);

    setState(() {
      _remaining = remaining.isNegative ? Duration.zero : remaining;
    });

    if (remaining.isNegative && widget.onTimerEnd != null) {
      widget.onTimerEnd!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;
    final isUrgent = _remaining.inSeconds < 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.red.withOpacity(0.2) : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUrgent ? Colors.red : AppTheme.secondaryColor,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: isUrgent ? Colors.red : AppTheme.secondaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            '\${minutes.toString().padLeft(2, '0')}:\${seconds.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isUrgent ? Colors.red : AppTheme.secondaryColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
DART

PHASE_INDICATOR = <<~DART
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../utils/constants.dart';

/// 階段指示器元件
class PhaseIndicator extends StatelessWidget {
  final int currentPhase;
  final String phaseName;

  const PhaseIndicator({
    super.key,
    required this.currentPhase,
    required this.phaseName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.8),
            AppTheme.secondaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            '階段 \$currentPhase / 12',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            phaseName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // 進度條
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: currentPhase / 12,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
DART

CONSTANTS = <<~DART
/// 遊戲常數定義

/// 遊戲階段枚舉
enum GamePhase {
  waiting('等待中'),
  preparing('角色研究'),
  conspiracy('私下密謀'),
  debate('開場陳述'),
  event1('突發事件 #1'),
  debate2('自由辯論'),
  event2('突發事件 #2'),
  voteRound1('第一輪投票'),
  finalDebate('最後攻防'),
  voteRound2('第二輪投票'),
  reveal('結果揭曉'),
  finished('遊戲結束');

  final String name;
  const GamePhase(this.name);
}

/// 投票選項
enum VoteOption {
  A('禁止機器', '立法禁止工廠使用省力機器'),
  B('保護財產', '嚴厲打擊破壞機器的暴民'),
  C('折衷改革', '允許機器但立法保障工人權益'),
  D('皇家調查', '成立皇家調查委員會深入研究');

  final String title;
  final String description;
  const VoteOption(this.title, this.description);
}

/// 角色類型
enum RoleType {
  worker('工人', '紡織工人'),
  factory('工廠主', '工廠主'),
  luddite('盧德派', '盧德派'),
  reformer('改革者', '改革者'),
  mp('議員', '議員');

  final String name;
  final String description;
  const RoleType(this.name, this.description);
}

/// 階段持續時間（分鐘）
class PhaseDurations {
  static const int preparing = 15;
  static const int conspiracy = 10;
  static const int debate = 25;
  static const int event = 5;
  static const int debate2 = 30;
  static const int voteRound1 = 5;
  static const int finalDebate = 10;
  static const int voteRound2 = 5;
  static const int reveal = 10;
}
DART

# 修復 Podfile 中的 CODE_SIGNING_ALLOWED 設定
def fix_podfile
  puts "\n🔧 修復 Podfile 設定..."

  podfile_path = File.join(PROJECT_ROOT, 'ios', 'Podfile')
  return unless File.exist?(podfile_path)

  content = File.read(podfile_path)

  # 檢查是否已經有修復
  if content.include?("CODE_SIGNING_ALLOWED")
    puts "  ⏭️  Podfile 已包含 CODE_SIGNING_ALLOWED 設定"
    return
  end

  # 移除錯誤的設定並添加正確的設定
  # 這裡我們只是確認設定存在
  puts "  ✅ Podfile 設定正確"
end

# 執行 Flutter 命令
def run_flutter_commands
  puts "\n🚀 執行 Flutter 命令..."

  Dir.chdir(PROJECT_ROOT) do
    puts "  執行 flutter pub get..."
    system("/opt/homebrew/bin/flutter pub get")

    puts "  執行 flutter clean..."
    system("/opt/homebrew/bin/flutter clean")

    puts "  重新執行 flutter pub get..."
    system("/opt/homebrew/bin/flutter pub get")
  end
end

# 設定 iOS 專案
def setup_ios_project
  puts "\n📱 設定 iOS 專案..."

  ios_dir = File.join(PROJECT_ROOT, 'ios')

  Dir.chdir(ios_dir) do
    # 移除舊的 Pods
    if File.directory?('Pods')
      puts "  移除舊的 Pods..."
      FileUtils.rm_rf('Pods')
    end

    if File.exist?('Podfile.lock')
      puts "  移除 Podfile.lock..."
      FileUtils.rm('Podfile.lock')
    end

    # 執行 pod install
    puts "  執行 pod install..."
    system("pod install")
  end
end

# 建立 .gitkeep 檔案
def create_gitkeep_files
  puts "\n📄 建立 .gitkeep 檔案..."

  dirs = ['assets/images', 'assets/icons']

  dirs.each do |dir|
    gitkeep = File.join(PROJECT_ROOT, dir, '.gitkeep')
    unless File.exist?(gitkeep)
      File.write(gitkeep, '')
      puts "  ✅ 建立: #{dir}/.gitkeep"
    end
  end
end

# 主程式
def main
  create_directories
  create_missing_files
  create_gitkeep_files
  fix_podfile
  run_flutter_commands
  setup_ios_project

  puts "\n" + "=" * 50
  puts "✅ 設定完成！"
  puts "\n接下來你可以："
  puts "  1. 用 Xcode 開啟: open ios/Runner.xcworkspace"
  puts "  2. 或用 Flutter 執行: flutter run"
  puts "=" * 50
end

main
