import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../config/theme.dart';

/// 結果畫面
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    // roomProvider 目前未使用但可能在將來需要

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
                  '$count 票',
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
