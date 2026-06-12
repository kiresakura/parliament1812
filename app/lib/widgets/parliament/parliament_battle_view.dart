import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/game_state.dart';
import '../../models/player.dart';
import '../../models/card.dart';
import '../../models/room.dart';
import '../../providers/game_provider.dart';
import '../../services/haptic_service.dart';
import '../../services/audio_service.dart';
import '../../ui/theme/game_colors.dart';

import 'opponent_rail_view.dart';
import 'turn_order_view.dart';
import 'motion_area_view.dart';
import 'hand_view.dart';
import 'player_hud_view.dart';

/// 議會對局主畫面（ParliamentBattleView）
///
/// 豎屏固定，從上到下五層：
/// 1. OpponentRailView  ~100pt  對手縮略列
/// 2. TurnOrderView     ~40pt   行動順序條
/// 3. MotionAreaView    ~160pt  議案區
/// 4. HandView          ~180pt  手牌區
/// 5. PlayerHUDView     ~120pt  玩家 HUD
///
/// 支援 4 人和 8 人模式
class ParliamentBattleView extends ConsumerWidget {
  final GameState gameState;

  const ParliamentBattleView({
    super.key,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = gameState.currentPlayerId;
    final allPlayers = gameState.room.players;
    final isCompact = allPlayers.length > 5; // 8人模式

    // 分離自己和對手
    final opponents = allPlayers.where((p) => p.id != myId).toList();
    final myPlayer = allPlayers.where((p) => p.id == myId).firstOrNull;

    // 當前行動者 ID
    final currentTurnId = gameState.currentTurnPlayerId;

    // 建構對手資訊
    final opponentInfos = opponents.map((p) {
      return OpponentInfo.fromPlayer(
        p,
        isActive: p.id == currentTurnId,
      );
    }).toList();

    // 行動順序
    final turnOrder = gameState.turnOrder.isNotEmpty
        ? gameState.turnOrder
        : allPlayers.map((p) => p.id).toList();

    final myIndex = myId != null
        ? turnOrder.indexOf(myId)
        : -1;
    final currentTurnIndex = currentTurnId != null
        ? turnOrder.indexOf(currentTurnId)
        : 0;

    // 玩家首字 map
    final playerInitials = <String, String>{};
    for (final p in allPlayers) {
      playerInitials[p.id] = p.name.isNotEmpty ? p.name.substring(0, 1) : '?';
    }

    // 派系色 map
    final playerFactionColors = <String, Color>{};
    for (final p in allPlayers) {
      playerFactionColors[p.id] =
          GameColors.getFactionColor(p.character?.faction ?? 'neutral');
    }

    // 議案資訊
    final motion = _buildMotionInfo(gameState);

    // 辯論日誌
    final debateLog = _buildDebateLog(gameState);

    // 我的 HUD 資訊
    final myHud = _buildMyHud(myPlayer, gameState);

    // 是否輪到我
    final isMyTurn = gameState.isMyTurn;

    return Container(
      color: GameColors.bgPrimary,
      child: Column(
        children: [
          // 1. 對手縮略列
          OpponentRailView(
            opponents: opponentInfos,
            isCompact: isCompact,
          ),

          // 2. 行動順序條
          TurnOrderView(
            playerIds: turnOrder,
            playerInitials: playerInitials,
            currentIndex: currentTurnIndex.clamp(0, turnOrder.length - 1),
            myIndex: myIndex.clamp(0, turnOrder.length - 1),
            playerFactionColors: playerFactionColors,
          ),

          // 3. 議案區（可滾動區域）
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  MotionAreaView(
                    motion: motion,
                    logEntries: debateLog,
                  ),
                ],
              ),
            ),
          ),

          // 4. 手牌區
          HandView(
            cards: gameState.hand,
            playableCards: gameState.playableCards,
            onCardPlayed: (card) {
              _onCardPlayed(ref, card);
            },
            onCardTapped: (card) {
              HapticService.dragStart();
            },
          ),

          // 5. 玩家 HUD
          PlayerHUDView(
            player: myHud,
            isMyTurn: isMyTurn,
            onQuery: () => _onQuery(ref),
            onSpeech: () => _onSpeech(ref),
            onAlliance: () => _onAlliance(ref),
            onEndSpeech: () => _onEndSpeech(ref),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 資料轉換
  // ═══════════════════════════════════════════

  MotionInfo _buildMotionInfo(GameState gs) {
    return MotionInfo(
      title: gs.currentBill ?? '等待議案',
      reading: gs.round.clamp(1, 3),
      forRatio: _computeForRatio(gs),
      againstRatio: _computeAgainstRatio(gs),
    );
  }

  double _computeForRatio(GameState gs) {
    if (gs.votes.isEmpty) return 0.0;
    final total = gs.votes.length;
    final forCount = gs.votes.values
        .where((v) => v == VoteChoice.a)
        .length;
    return total > 0 ? forCount / total : 0.0;
  }

  double _computeAgainstRatio(GameState gs) {
    if (gs.votes.isEmpty) return 0.0;
    final total = gs.votes.length;
    final againstCount = gs.votes.values
        .where((v) => v == VoteChoice.b)
        .length;
    return total > 0 ? againstCount / total : 0.0;
  }

  List<DebateLogEntry> _buildDebateLog(GameState gs) {
    return gs.gameEvents.reversed.take(5).map((event) {
      return DebateLogEntry(
        id: event.id,
        playerName: event.playerName ?? '系統',
        cardName: event.type == GameEventType.cardUsed
            ? (event.data['cardName'] as String?)
            : null,
        description: event.description,
        timestamp: event.timestamp,
      );
    }).toList();
  }

  MyPlayerInfo _buildMyHud(Player? player, GameState gs) {
    if (player == null) {
      return const MyPlayerInfo(
        name: '???',
        faction: 'neutral',
        influenceRatio: 0.0,
      );
    }

    return MyPlayerInfo(
      name: player.name,
      faction: player.character?.faction ?? 'neutral',
      influenceRatio: (player.reputation / 100.0).clamp(0.0, 1.0),
      ap: gs.actionPointsRemaining,
      currentRound: gs.round,
      totalRounds: 6,
      handCount: gs.hand.length,
    );
  }

  // ═══════════════════════════════════════════
  // 行動回調
  // ═══════════════════════════════════════════

  void _onCardPlayed(WidgetRef ref, GameCard card) {
    HapticService.cardPlayed();
    ref.read(audioServiceProvider).playSfx(SfxType.cardPlay);
    ref.read(gameActionsProvider).useCard(card);
  }

  void _onQuery(WidgetRef ref) {
    HapticService.cardPlayed();
    // 觸發質詢選擇對話框（由外部 GameScreen 處理）
  }

  void _onSpeech(WidgetRef ref) {
    HapticService.cardPlayed();
    // 觸發演講操作
  }

  void _onAlliance(WidgetRef ref) {
    HapticService.cardPlayed();
    // 觸發結盟選擇
  }

  void _onEndSpeech(WidgetRef ref) {
    HapticService.cardPlayed();
    ref.read(gameActionsProvider).endTurn();
  }
}
