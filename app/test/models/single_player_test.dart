import 'package:flutter_test/flutter_test.dart';
import 'package:parliament1812/models/single_player.dart';

void main() {
  group('AiDifficulty', () {
    test('displayName returns correct Chinese names', () {
      expect(AiDifficulty.easy.displayName, '簡單');
      expect(AiDifficulty.normal.displayName, '普通');
      expect(AiDifficulty.hard.displayName, '困難');
      expect(AiDifficulty.expert.displayName, '專家');
    });

    test('displayNameEn returns correct English names', () {
      expect(AiDifficulty.easy.displayNameEn, 'Easy');
      expect(AiDifficulty.normal.displayNameEn, 'Normal');
      expect(AiDifficulty.hard.displayNameEn, 'Hard');
      expect(AiDifficulty.expert.displayNameEn, 'Expert');
    });

    test('toJson returns name', () {
      expect(AiDifficulty.easy.toJson(), 'easy');
      expect(AiDifficulty.expert.toJson(), 'expert');
    });

    test('fromJson parses correctly', () {
      expect(AiDifficulty.fromJson('easy'), AiDifficulty.easy);
      expect(AiDifficulty.fromJson('normal'), AiDifficulty.normal);
      expect(AiDifficulty.fromJson('hard'), AiDifficulty.hard);
      expect(AiDifficulty.fromJson('expert'), AiDifficulty.expert);
    });

    test('fromJson returns easy for unknown value', () {
      expect(AiDifficulty.fromJson('unknown'), AiDifficulty.easy);
      expect(AiDifficulty.fromJson(''), AiDifficulty.easy);
    });

    test('has 4 values', () {
      expect(AiDifficulty.values.length, 4);
    });
  });

  group('SinglePlayerState', () {
    test('fromJson with minimal data', () {
      final state = SinglePlayerState.fromJson({});
      expect(state.sessionId, '');
      expect(state.phase, 'waiting');
      expect(state.currentRound, 0);
      expect(state.isGameOver, false);
      expect(state.result, isNull);
      expect(state.players, isEmpty);
      expect(state.hand, isEmpty);
    });

    test('fromJson with full data', () {
      final state = SinglePlayerState.fromJson({
        'session_id': 'abc-123',
        'phase': 'debate',
        'current_round': 3,
        'current_bill': '工廠法案',
        'players': [
          {
            'id': 'p1',
            'name': 'Player',
            'character': 'thomas',
            'reputation': 70,
            'gold': 100,
            'is_ai': false,
            'is_politically_dead': false,
            'hand_count': 5,
          }
        ],
        'hand': [
          {'id': 'card1', 'name': '攻擊'}
        ],
        'phase_time_remaining': 120,
        'ai_actions_log': ['AI played card'],
        'is_game_over': false,
      });

      expect(state.sessionId, 'abc-123');
      expect(state.phase, 'debate');
      expect(state.currentRound, 3);
      expect(state.currentBill, '工廠法案');
      expect(state.players.length, 1);
      expect(state.players[0].name, 'Player');
      expect(state.hand.length, 1);
      expect(state.phaseTimeRemaining, 120);
      expect(state.aiActionsLog.length, 1);
      expect(state.isGameOver, false);
    });
  });

  group('SinglePlayerInfo', () {
    test('fromJson creates correct info', () {
      final info = SinglePlayerInfo.fromJson({
        'id': 'test-id',
        'name': 'Thomas',
        'character': 'thomas',
        'reputation': 70,
        'gold': 50,
        'is_ai': true,
        'is_politically_dead': false,
        'hand_count': 4,
      });

      expect(info.id, 'test-id');
      expect(info.name, 'Thomas');
      expect(info.reputation, 70);
      expect(info.gold, 50);
      expect(info.isAi, true);
      expect(info.isPoliticallyDead, false);
      expect(info.handCount, 4);
    });

    test('fromJson with missing data has defaults', () {
      final info = SinglePlayerInfo.fromJson({});
      expect(info.id, '');
      expect(info.name, '');
      expect(info.reputation, 0);
      expect(info.isAi, false);
    });
  });

  group('SinglePlayerResult', () {
    test('fromJson with win', () {
      final result = SinglePlayerResult.fromJson({
        'won': true,
        'rank': 1,
        'score': 150,
        'rankings': [
          {'name': 'Player', 'score': 150, 'is_ai': false},
          {'name': 'AI-1', 'score': 100, 'is_ai': true},
        ],
      });

      expect(result.won, true);
      expect(result.rank, 1);
      expect(result.score, 150);
      expect(result.rankings.length, 2);
      expect(result.rankings[0].name, 'Player');
      expect(result.rankings[1].isAi, true);
    });

    test('fromJson with loss', () {
      final result = SinglePlayerResult.fromJson({
        'won': false,
        'rank': 3,
        'score': 50,
      });

      expect(result.won, false);
      expect(result.rank, 3);
      expect(result.rankings, isEmpty);
    });
  });

  group('CampaignChapter', () {
    test('fromJson creates chapter correctly', () {
      final chapter = CampaignChapter.fromJson({
        'chapter': 1,
        'title': '風暴前夕',
        'title_en': 'Before the Storm',
        'description': '測試描述',
        'description_en': 'Test desc',
        'is_unlocked': true,
        'is_free': true,
        'gem_cost': 0,
        'stages_completed': 3,
        'total_stages': 5,
        'stars': 7,
        'max_stars': 15,
      });

      expect(chapter.chapter, 1);
      expect(chapter.title, '風暴前夕');
      expect(chapter.isUnlocked, true);
      expect(chapter.isFree, true);
      expect(chapter.gemCost, 0);
      expect(chapter.stagesCompleted, 3);
      expect(chapter.totalStages, 5);
      expect(chapter.stars, 7);
    });

    test('fromJson with paid chapter', () {
      final chapter = CampaignChapter.fromJson({
        'chapter': 2,
        'title': '盧德之怒',
        'is_unlocked': false,
        'is_free': false,
        'gem_cost': 200,
      });

      expect(chapter.isUnlocked, false);
      expect(chapter.isFree, false);
      expect(chapter.gemCost, 200);
    });

    test('fromJson with minimal data has defaults', () {
      final chapter = CampaignChapter.fromJson({});
      expect(chapter.chapter, 0);
      expect(chapter.title, '');
      expect(chapter.isUnlocked, false);
      expect(chapter.totalStages, 5);
      expect(chapter.maxStars, 15);
    });
  });

  group('TutorialStep', () {
    test('fromJson creates step correctly', () {
      final step = TutorialStep.fromJson({
        'step': 1,
        'title': '歡迎來到國會',
        'title_en': 'Welcome to Parliament',
        'description': '了解基本介面',
        'description_en': 'Learn the basics',
        'action_type': 'show_ui',
        'highlight_target': 'resource_panel',
        'dialogue': [
          {
            'speaker': '旁白',
            'text': '歡迎！',
            'text_en': 'Welcome!',
          }
        ],
        'completed': false,
      });

      expect(step.step, 1);
      expect(step.title, '歡迎來到國會');
      expect(step.actionType, 'show_ui');
      expect(step.highlightTarget, 'resource_panel');
      expect(step.dialogue.length, 1);
      expect(step.dialogue[0].speaker, '旁白');
      expect(step.completed, false);
    });

    test('fromJson with minimal data', () {
      final step = TutorialStep.fromJson({});
      expect(step.step, 0);
      expect(step.title, '');
      expect(step.dialogue, isEmpty);
      expect(step.completed, false);
    });
  });

  group('TutorialDialogue', () {
    test('fromJson creates dialogue', () {
      final dialogue = TutorialDialogue.fromJson({
        'speaker': '導師',
        'text': '你好',
        'text_en': 'Hello',
      });

      expect(dialogue.speaker, '導師');
      expect(dialogue.text, '你好');
      expect(dialogue.textEn, 'Hello');
    });
  });

  group('PlayerFinalScore', () {
    test('fromJson creates score', () {
      final score = PlayerFinalScore.fromJson({
        'name': 'Player',
        'score': 100,
        'is_ai': false,
      });

      expect(score.name, 'Player');
      expect(score.score, 100);
      expect(score.isAi, false);
    });

    test('fromJson with AI player', () {
      final score = PlayerFinalScore.fromJson({
        'name': 'AI-Richard',
        'score': 80,
        'is_ai': true,
      });

      expect(score.isAi, true);
    });
  });
}
