import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';

// ============================================================
// 資料模型
// ============================================================

/// 獎勵
class QuestReward {
  final String type;
  final int amount;
  final String display;

  const QuestReward({
    required this.type,
    required this.amount,
    required this.display,
  });

  factory QuestReward.fromJson(Map<String, dynamic> json) {
    return QuestReward(
      type: json['type'] as String? ?? 'gold',
      amount: json['amount'] as int? ?? 0,
      display: json['display'] as String? ?? '',
    );
  }
}

/// 單一任務
class DailyQuest {
  final String questId;
  final String name;
  final String description;
  final int progress;
  final int target;
  final QuestReward reward;
  final bool claimed;
  final bool completed;

  const DailyQuest({
    required this.questId,
    required this.name,
    required this.description,
    required this.progress,
    required this.target,
    required this.reward,
    required this.claimed,
    required this.completed,
  });

  factory DailyQuest.fromJson(Map<String, dynamic> json) {
    return DailyQuest(
      questId: json['quest_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      progress: json['progress'] as int? ?? 0,
      target: json['target'] as int? ?? 1,
      reward: QuestReward.fromJson(json['reward'] as Map<String, dynamic>? ?? {}),
      claimed: json['claimed'] as bool? ?? false,
      completed: json['completed'] as bool? ?? false,
    );
  }
}

/// 每日任務狀態
class DailyQuestsState {
  final List<DailyQuest> quests;
  final int currentStreak;
  final int longestStreak;
  final bool allClaimed;
  final int resetInSecs;
  final bool isLoading;
  final String? error;

  const DailyQuestsState({
    this.quests = const [],
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.allClaimed = false,
    this.resetInSecs = 0,
    this.isLoading = false,
    this.error,
  });

  /// 未完成的任務數量
  int get unclaimedCount => quests.where((q) => q.completed && !q.claimed).length;

  /// 未完成 + 未領取的總數（用於 badge）
  int get pendingCount => quests.where((q) => !q.claimed).length;

  DailyQuestsState copyWith({
    List<DailyQuest>? quests,
    int? currentStreak,
    int? longestStreak,
    bool? allClaimed,
    int? resetInSecs,
    bool? isLoading,
    String? error,
  }) {
    return DailyQuestsState(
      quests: quests ?? this.quests,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      allClaimed: allClaimed ?? this.allClaimed,
      resetInSecs: resetInSecs ?? this.resetInSecs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 歷史天
class QuestHistoryDay {
  final String date;
  final List<DailyQuest> quests;
  final bool allCompleted;

  const QuestHistoryDay({
    required this.date,
    required this.quests,
    required this.allCompleted,
  });

  factory QuestHistoryDay.fromJson(Map<String, dynamic> json) {
    return QuestHistoryDay(
      date: json['date'] as String? ?? '',
      quests: (json['quests'] as List<dynamic>?)
              ?.map((q) => DailyQuest.fromJson(q as Map<String, dynamic>))
              .toList() ??
          [],
      allCompleted: json['all_completed'] as bool? ?? false,
    );
  }
}

// ============================================================
// Provider
// ============================================================

final questsProvider =
    StateNotifierProvider<QuestsNotifier, DailyQuestsState>((ref) {
  return QuestsNotifier();
});

class QuestsNotifier extends StateNotifier<DailyQuestsState> {
  QuestsNotifier() : super(const DailyQuestsState());

  Timer? _resetTimer;
  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  /// 載入今日任務
  Future<void> loadDailyQuests() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 開發模式使用 mock 資料
      if (AppConstants.isDebugMode) {
        await Future.delayed(const Duration(milliseconds: 300));
        state = _mockDailyQuests();
        _startResetTimer();
        return;
      }

      final uri = Uri.parse('${AppConstants.baseUrl}/api/v1/quests/daily');
      final client = HttpClient();
      client.connectionTimeout = AppConstants.connectionTimeout;

      final request = await client.getUrl(uri);
      if (_authToken != null) {
        request.headers.set('Authorization', 'Bearer $_authToken');
      }

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = jsonDecode(body) as Map<String, dynamic>;
        final quests = (data['quests'] as List<dynamic>)
            .map((q) => DailyQuest.fromJson(q as Map<String, dynamic>))
            .toList();

        state = DailyQuestsState(
          quests: quests,
          currentStreak: data['current_streak'] as int? ?? 0,
          longestStreak: data['longest_streak'] as int? ?? 0,
          allClaimed: data['all_claimed'] as bool? ?? false,
          resetInSecs: data['reset_in_secs'] as int? ?? 0,
          isLoading: false,
        );

        _startResetTimer();
      } else {
        state = state.copyWith(
          isLoading: false,
          error: '載入失敗 (${response.statusCode})',
        );
      }

      client.close();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '網路錯誤: $e');
    }
  }

  /// 領取獎勵
  Future<String?> claimReward(String questId) async {
    try {
      if (AppConstants.isDebugMode) {
        await Future.delayed(const Duration(milliseconds: 300));
        // Mock: 更新本地狀態
        final updatedQuests = state.quests.map((q) {
          if (q.questId == questId) {
            return DailyQuest(
              questId: q.questId,
              name: q.name,
              description: q.description,
              progress: q.progress,
              target: q.target,
              reward: q.reward,
              claimed: true,
              completed: q.completed,
            );
          }
          return q;
        }).toList();

        final allClaimed = updatedQuests.every((q) => q.claimed);
        state = state.copyWith(quests: updatedQuests, allClaimed: allClaimed);
        return null; // success
      }

      final uri = Uri.parse('${AppConstants.baseUrl}/api/v1/quests/claim/$questId');
      final client = HttpClient();
      client.connectionTimeout = AppConstants.connectionTimeout;

      final request = await client.postUrl(uri);
      if (_authToken != null) {
        request.headers.set('Authorization', 'Bearer $_authToken');
      }
      request.headers.set('Content-Type', 'application/json');

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        // 重新載入
        await loadDailyQuests();
        final data = jsonDecode(body) as Map<String, dynamic>;
        return data['message'] as String?;
      } else {
        final data = jsonDecode(body) as Map<String, dynamic>;
        return data['message'] as String? ?? '領取失敗';
      }
    } catch (e) {
      return '網路錯誤: $e';
    }
  }

  /// 載入歷史
  Future<List<QuestHistoryDay>> loadHistory() async {
    try {
      if (AppConstants.isDebugMode) {
        await Future.delayed(const Duration(milliseconds: 300));
        return _mockHistory();
      }

      final uri = Uri.parse('${AppConstants.baseUrl}/api/v1/quests/history');
      final client = HttpClient();
      client.connectionTimeout = AppConstants.connectionTimeout;

      final request = await client.getUrl(uri);
      if (_authToken != null) {
        request.headers.set('Authorization', 'Bearer $_authToken');
      }

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = jsonDecode(body) as Map<String, dynamic>;
        final days = (data['days'] as List<dynamic>)
            .map((d) => QuestHistoryDay.fromJson(d as Map<String, dynamic>))
            .toList();
        return days;
      }

      client.close();
      return [];
    } catch (_) {
      return [];
    }
  }

  void _startResetTimer() {
    _resetTimer?.cancel();
    if (state.resetInSecs > 0) {
      _resetTimer = Timer(Duration(seconds: state.resetInSecs), () {
        loadDailyQuests();
      });
    }
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  // Mock 資料（開發用）
  // ============================================================

  DailyQuestsState _mockDailyQuests() {
    return const DailyQuestsState(
      quests: [
        DailyQuest(
          questId: 'play_games',
          name: '國會日常',
          description: '進行 2 場遊戲',
          progress: 1,
          target: 2,
          reward: QuestReward(type: 'gold', amount: 50, display: '50 金幣'),
          claimed: false,
          completed: false,
        ),
        DailyQuest(
          questId: 'use_attack_cards',
          name: '舌戰群雄',
          description: '使用 3 張攻擊卡',
          progress: 3,
          target: 3,
          reward: QuestReward(type: 'gold', amount: 40, display: '40 金幣'),
          claimed: false,
          completed: true,
        ),
        DailyQuest(
          questId: 'form_alliance',
          name: '結盟之道',
          description: '與其他玩家結盟 1 次',
          progress: 0,
          target: 1,
          reward: QuestReward(type: 'gems', amount: 5, display: '5 寶石'),
          claimed: false,
          completed: false,
        ),
      ],
      currentStreak: 3,
      longestStreak: 7,
      allClaimed: false,
      resetInSecs: 43200,
      isLoading: false,
    );
  }

  List<QuestHistoryDay> _mockHistory() {
    return const [
      QuestHistoryDay(
        date: '2026-02-08',
        quests: [
          DailyQuest(
            questId: 'play_games',
            name: '國會日常',
            description: '進行 2 場遊戲',
            progress: 2,
            target: 2,
            reward: QuestReward(type: 'gold', amount: 50, display: '50 金幣'),
            claimed: true,
            completed: true,
          ),
        ],
        allCompleted: true,
      ),
    ];
  }
}
