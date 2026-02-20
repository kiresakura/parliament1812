import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/single_player.dart';
import '../services/local_game_engine.dart';

/// 單人模式狀態
class SinglePlayerNotifier extends StateNotifier<SinglePlayerState?> {
  SinglePlayerNotifier() : super(null);

  LocalGameEngine? _engine;
  bool _loading = false;

  bool get isLoading => _loading;
  String? get sessionId => state?.sessionId;

  /// 開始快速對戰（本地引擎）
  Future<bool> startQuickMatch({
    required AiDifficulty difficulty,
    String? character,
    String? playerName,
  }) async {
    _loading = true;

    try {
      _engine = LocalGameEngine(
        difficulty: difficulty,
        playerCharacter: character ?? 'thomas',
        playerName: playerName ?? 'Player',
      );
      state = _engine!.initGame();
      _loading = false;
      return true;
    } catch (e) {
      _loading = false;
      return false;
    }
  }

  /// 執行行動（本地引擎）
  Future<bool> performAction(Map<String, dynamic> action) async {
    if (_engine == null) return false;

    try {
      state = _engine!.performAction(action);
      return true;
    } catch (e) {
      return false;
    }
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

  /// 完成 AI 回合展示，推進到投票階段
  Future<bool> finishAiTurn() async {
    if (_engine == null) return false;
    try {
      state = _engine!.finishAiTurnPhase();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 更新 AI 回合展示狀態（高亮當前 AI）
  void updateAiTurnActor(String? actorId) {
    if (state == null) return;
    state = state!.copyWith(aiTurnActorId: actorId);
  }

  /// 重新取得狀態（從本地引擎讀取）
  Future<void> refreshState() async {
    // 本地引擎不需要 refresh，state 已經是最新的
  }

  /// 從外部設定遊戲狀態（如戰役開始）
  void setGameState(SinglePlayerState newState, String sessionId) {
    state = newState;
  }

  /// 設定引擎並更新狀態
  void setEngine(LocalGameEngine engine, SinglePlayerState gameState) {
    _engine = engine;
    state = gameState;
  }

  /// 清除遊戲
  void clearGame() {
    _engine = null;
    state = null;
  }
}

final singlePlayerProvider =
    StateNotifierProvider<SinglePlayerNotifier, SinglePlayerState?>((ref) {
  return SinglePlayerNotifier();
});

/// 戰役進度（本地 SharedPreferences）
class CampaignNotifier extends StateNotifier<List<CampaignChapter>> {
  CampaignNotifier() : super([]);

  bool _loading = false;
  bool get isLoading => _loading;

  // 本地章節定義
  static const List<Map<String, dynamic>> _localChapters = [
    {
      'chapter': 1,
      'title': '議會新手',
      'title_en': 'The New MP',
      'description': '學習議會基礎，你的第一次辯論',
      'description_en': 'Learn the basics of parliament',
      'is_free': true,
      'gem_cost': 0,
      'difficulty': 'easy',
      'total_stages': 3,
    },
    {
      'chapter': 2,
      'title': '政治風暴',
      'title_en': 'Political Storm',
      'description': '聯盟機制登場，學會結交盟友',
      'description_en': 'Master the alliance system',
      'is_free': true,
      'gem_cost': 0,
      'difficulty': 'normal',
      'total_stages': 3,
    },
    {
      'chapter': 3,
      'title': '工業革命',
      'title_en': 'Industrial Revolution',
      'description': '工人 vs 工廠主的激烈對決',
      'description_en': 'Workers vs Factory owners',
      'is_free': false,
      'gem_cost': 50,
      'difficulty': 'hard',
      'total_stages': 3,
    },
    {
      'chapter': 4,
      'title': '改革之路',
      'title_en': 'Road to Reform',
      'description': '多方博弈，每個選擇都至關重要',
      'description_en': 'Every choice matters',
      'is_free': false,
      'gem_cost': 100,
      'difficulty': 'hard',
      'total_stages': 3,
    },
    {
      'chapter': 5,
      'title': '彼得盧之役',
      'title_en': 'Peterloo',
      'description': '終極挑戰，Expert 難度的最終決戰',
      'description_en': 'The ultimate challenge',
      'is_free': false,
      'gem_cost': 200,
      'difficulty': 'expert',
      'total_stages': 3,
    },
  ];

  /// 載入戰役進度（本地 SharedPreferences）
  Future<void> loadProgress() async {
    _loading = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString('campaign_progress');
      Map<int, Map<String, dynamic>> savedProgress = {};

      if (savedData != null) {
        final decoded = jsonDecode(savedData) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          savedProgress[int.parse(entry.key)] =
              entry.value as Map<String, dynamic>;
        }
      }

      final chapters = _localChapters.map((def) {
        final chapterNum = def['chapter'] as int;
        final saved = savedProgress[chapterNum];
        final prevCompleted = chapterNum == 1 ||
            (savedProgress[chapterNum - 1]?['completed'] == true);

        return CampaignChapter(
          chapter: chapterNum,
          title: def['title'] as String,
          titleEn: def['title_en'] as String,
          description: def['description'] as String,
          descriptionEn: def['description_en'] as String,
          isUnlocked: prevCompleted || (def['is_free'] as bool),
          isFree: def['is_free'] as bool,
          gemCost: def['gem_cost'] as int,
          stagesCompleted: saved?['stages_completed'] as int? ?? 0,
          totalStages: def['total_stages'] as int? ?? 3,
          stars: saved?['stars'] as int? ?? 0,
          maxStars: (def['total_stages'] as int? ?? 3) * 3,
        );
      }).toList();

      state = chapters;
    } catch (_) {
      // 預設：只有第一章解鎖
      state = _localChapters.map((def) {
        return CampaignChapter(
          chapter: def['chapter'] as int,
          title: def['title'] as String,
          titleEn: def['title_en'] as String,
          description: def['description'] as String,
          descriptionEn: def['description_en'] as String,
          isUnlocked: def['chapter'] == 1,
          isFree: def['is_free'] as bool,
          gemCost: def['gem_cost'] as int,
          stagesCompleted: 0,
          totalStages: def['total_stages'] as int? ?? 3,
          stars: 0,
          maxStars: (def['total_stages'] as int? ?? 3) * 3,
        );
      }).toList();
    }

    _loading = false;
  }

  /// 儲存進度到本地
  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, dynamic>{};
    for (final chapter in state) {
      data['${chapter.chapter}'] = {
        'stages_completed': chapter.stagesCompleted,
        'stars': chapter.stars,
        'completed': chapter.stagesCompleted >= chapter.totalStages,
      };
    }
    await prefs.setString('campaign_progress', jsonEncode(data));
  }

  /// 開始戰役章節（本地引擎）
  Future<({SinglePlayerState state, String sessionId})?> startChapter({
    required int chapter,
    int? stage,
    String? playerName,
    String? character,
  }) async {
    try {
      // 找到章節定義
      final chapterDef = _localChapters.firstWhere(
        (c) => c['chapter'] == chapter,
        orElse: () => _localChapters.first,
      );

      final difficultyStr = chapterDef['difficulty'] as String;
      final difficulty = AiDifficulty.values.firstWhere(
        (d) => d.name == difficultyStr,
        orElse: () => AiDifficulty.easy,
      );

      final engine = LocalGameEngine(
        difficulty: difficulty,
        playerCharacter: character ?? 'thomas',
        playerName: playerName ?? 'Player',
      );

      final gameState = engine.initGame();

      return (
        state: gameState,
        sessionId: gameState.sessionId,
      );
    } catch (_) {
      return null;
    }
  }

  /// 記錄章節完成
  Future<void> completeChapter(int chapter, int stars) async {
    final updated = state.map((c) {
      if (c.chapter == chapter) {
        return CampaignChapter(
          chapter: c.chapter,
          title: c.title,
          titleEn: c.titleEn,
          description: c.description,
          descriptionEn: c.descriptionEn,
          isUnlocked: c.isUnlocked,
          isFree: c.isFree,
          gemCost: c.gemCost,
          stagesCompleted: c.stagesCompleted + 1,
          totalStages: c.totalStages,
          stars: c.stars + stars,
          maxStars: c.maxStars,
        );
      }
      // 解鎖下一章
      if (c.chapter == chapter + 1) {
        return CampaignChapter(
          chapter: c.chapter,
          title: c.title,
          titleEn: c.titleEn,
          description: c.description,
          descriptionEn: c.descriptionEn,
          isUnlocked: true,
          isFree: c.isFree,
          gemCost: c.gemCost,
          stagesCompleted: c.stagesCompleted,
          totalStages: c.totalStages,
          stars: c.stars,
          maxStars: c.maxStars,
        );
      }
      return c;
    }).toList();

    state = updated;
    await _saveProgress();
  }
}

final campaignProvider =
    StateNotifierProvider<CampaignNotifier, List<CampaignChapter>>((ref) {
  return CampaignNotifier();
});

/// 教學進度（本地）
class TutorialNotifier extends StateNotifier<TutorialProgress> {
  TutorialNotifier() : super(TutorialProgress());

  /// 載入進度
  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    state = TutorialProgress(
      completed: prefs.getBool('tutorial_completed') ?? false,
      currentStep: prefs.getInt('tutorial_step') ?? 1,
    );
  }

  /// 完成步驟
  Future<bool> completeStep(int step) async {
    final prefs = await SharedPreferences.getInstance();
    final newStep = step + 1;
    final completed = newStep > state.totalSteps;
    await prefs.setInt('tutorial_step', newStep);
    if (completed) {
      await prefs.setBool('tutorial_completed', true);
    }
    state = TutorialProgress(
      completed: completed,
      currentStep: newStep,
      totalSteps: state.totalSteps,
    );
    return true;
  }

  /// 檢查是否需要教學
  Future<bool> needsTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('tutorial_completed') ?? false);
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
