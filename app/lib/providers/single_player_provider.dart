import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/single_player.dart';
import '../services/api_service.dart';

/// 單人模式狀態
class SinglePlayerNotifier extends StateNotifier<SinglePlayerState?> {
  SinglePlayerNotifier() : super(null);

  String? _sessionId;
  bool _loading = false;

  bool get isLoading => _loading;
  String? get sessionId => _sessionId;

  /// 開始快速對戰
  Future<bool> startQuickMatch({
    required AiDifficulty difficulty,
    String? character,
    String? playerName,
  }) async {
    _loading = true;

    final result = await ApiService().startSinglePlayer(
      difficulty: difficulty.name,
      character: character,
      playerName: playerName ?? 'Player',
    );

    _loading = false;

    if (result.success && result.data != null) {
      _sessionId = result.data!['session_id'];
      state = SinglePlayerState.fromJson(result.data!['state']);
      return true;
    }
    return false;
  }

  /// 執行行動
  Future<bool> performAction(Map<String, dynamic> action) async {
    if (_sessionId == null) return false;

    final result = await ApiService().singlePlayerAction(
      sessionId: _sessionId!,
      action: action,
    );

    if (result.success && result.data != null) {
      state = SinglePlayerState.fromJson(result.data!['state']);
      return true;
    }
    return false;
  }

  /// 出牌
  Future<bool> playCard(String cardId, {String? targetId}) async {
    return performAction({
      'type': 'play_card',
      'card_id': cardId,
      if (targetId != null) 'target_id': targetId,
    });
  }

  /// 抽牌
  Future<bool> drawCard() async {
    return performAction({'type': 'draw_card'});
  }

  /// 質詢
  Future<bool> challenge(String targetId) async {
    return performAction({
      'type': 'challenge',
      'target_id': targetId,
    });
  }

  /// 投票
  Future<bool> vote(String choice) async {
    return performAction({
      'type': 'vote',
      'choice': choice,
    });
  }

  /// 結盟
  Future<bool> formAlliance(String targetId) async {
    return performAction({
      'type': 'form_alliance',
      'target_id': targetId,
    });
  }

  /// 結束回合
  Future<bool> endTurn() async {
    return performAction({'type': 'end_phase'});
  }

  /// 重新取得狀態
  Future<void> refreshState() async {
    if (_sessionId == null) return;
    final result = await ApiService().getSinglePlayerState(_sessionId!);
    if (result.success && result.data != null) {
      state = SinglePlayerState.fromJson(result.data!);
    }
  }

  /// 清除遊戲
  void clearGame() {
    _sessionId = null;
    state = null;
  }
}

final singlePlayerProvider =
    StateNotifierProvider<SinglePlayerNotifier, SinglePlayerState?>((ref) {
  return SinglePlayerNotifier();
});

/// 戰役進度
class CampaignNotifier extends StateNotifier<List<CampaignChapter>> {
  CampaignNotifier() : super([]);

  bool _loading = false;
  bool get isLoading => _loading;

  /// 載入戰役進度
  Future<void> loadProgress() async {
    _loading = true;
    final result = await ApiService().getCampaignProgress();
    _loading = false;

    if (result.success && result.data != null) {
      final chapters = (result.data!['chapters'] as List<dynamic>?)
              ?.map((c) => CampaignChapter.fromJson(c))
              .toList() ??
          [];
      state = chapters;
    }
  }

  /// 開始戰役章節
  Future<SinglePlayerState?> startChapter({
    required int chapter,
    int? stage,
    String? playerName,
    String? character,
  }) async {
    final result = await ApiService().startCampaignChapter(
      chapter: chapter,
      stage: stage,
      playerName: playerName ?? 'Player',
      character: character,
    );

    if (result.success && result.data != null) {
      return SinglePlayerState.fromJson(result.data!['state']);
    }
    return null;
  }
}

final campaignProvider =
    StateNotifierProvider<CampaignNotifier, List<CampaignChapter>>((ref) {
  return CampaignNotifier();
});

/// 教學進度
class TutorialNotifier extends StateNotifier<TutorialProgress> {
  TutorialNotifier() : super(TutorialProgress());

  /// 載入進度
  Future<void> loadProgress() async {
    final result = await ApiService().getTutorialProgress();
    if (result.success && result.data != null) {
      state = TutorialProgress.fromJson(result.data!);
    }
  }

  /// 完成步驟
  Future<bool> completeStep(int step) async {
    final result = await ApiService().completeTutorialStep(step);
    if (result.success && result.data != null) {
      state = TutorialProgress.fromJson(result.data!);
      return true;
    }
    return false;
  }

  /// 檢查是否需要教學
  Future<bool> needsTutorial() async {
    final result = await ApiService().checkNeedsTutorial();
    if (result.success && result.data != null) {
      return result.data!['needs_tutorial'] ?? true;
    }
    return true;
  }
}

class TutorialProgress {
  final bool completed;
  final int currentStep;
  final int totalSteps;

  TutorialProgress({
    this.completed = false,
    this.currentStep = 1,
    this.totalSteps = 5,
  });

  factory TutorialProgress.fromJson(Map<String, dynamic> json) {
    return TutorialProgress(
      completed: json['completed'] ?? false,
      currentStep: json['current_step'] ?? 1,
      totalSteps: json['total_steps'] ?? 5,
    );
  }
}

final tutorialProvider =
    StateNotifierProvider<TutorialNotifier, TutorialProgress>((ref) {
  return TutorialNotifier();
});
