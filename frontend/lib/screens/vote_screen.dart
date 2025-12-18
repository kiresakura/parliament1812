import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/vote.dart';
import '../providers/room_provider.dart';
import '../providers/player_provider.dart';
import '../providers/game_provider.dart';
import '../widgets/vote_option_card.dart';

/// 投票畫面
class VoteScreen extends StatefulWidget {
  final int round;

  const VoteScreen({
    super.key,
    required this.round,
  });

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> {
  String? _selectedChoice;
  bool _hasVoted = false;

  @override
  void initState() {
    super.initState();
    _loadVoteOptions();
  }

  Future<void> _loadVoteOptions() async {
    final roomCode = context.read<RoomProvider>().room?.code;
    if (roomCode != null) {
      await context.read<GameProvider>().loadVoteOptions(roomCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('第 ${widget.round} 輪投票'),
      ),
      body: Consumer3<RoomProvider, PlayerProvider, GameProvider>(
        builder: (context, roomProvider, playerProvider, gameProvider, _) {
          final room = roomProvider.room;
          final player = playerProvider.currentPlayer;

          if (room == null || player == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // 投票說明
              _buildVoteHeader(),

              // 進度條
              _buildProgressBar(gameProvider.voteProgress),

              // 投票選項
              Expanded(
                child: _buildVoteOptions(gameProvider.voteOptions),
              ),

              // 投票按鈕
              _buildVoteButton(
                roomCode: room.code,
                playerId: player.id,
                gameProvider: gameProvider,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVoteHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: AppTheme.cardBackground,
      child: Column(
        children: [
          Text(
            widget.round == 1 ? '匿名投票' : '記名投票',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.round == 1
                ? '此輪投票結果只會顯示百分比，不會顯示具體票數'
                : '此輪投票將公開每位議員的投票選擇',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('投票進度', style: TextStyle(color: Colors.grey)),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: AppTheme.secondaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[800],
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.secondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoteOptions(List<VoteOption> options) {
    if (options.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        if (option.isHidden) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: VoteOptionCard(
            option: option,
            isSelected: _selectedChoice == option.id,
            isDisabled: _hasVoted,
            onTap: _hasVoted
                ? null
                : () => setState(() => _selectedChoice = option.id),
          ),
        );
      },
    );
  }

  Widget _buildVoteButton({
    required String roomCode,
    required String playerId,
    required GameProvider gameProvider,
  }) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_hasVoted)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      '你已投票，等待其他議員...',
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _hasVoted || _selectedChoice == null
                    ? null
                    : () => _submitVote(roomCode, playerId, gameProvider),
                child: gameProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_hasVoted ? '已投票' : '確認投票'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitVote(
    String roomCode,
    String playerId,
    GameProvider gameProvider,
  ) async {
    if (_selectedChoice == null) return;

    final success = await gameProvider.castVote(
      roomCode: roomCode,
      playerId: playerId,
      round: widget.round,
      choice: _selectedChoice!,
    );

    if (success && mounted) {
      setState(() => _hasVoted = true);
    } else if (gameProvider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(gameProvider.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
