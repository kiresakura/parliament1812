// 1812 國會風雲 - 議案模型

import 'role.dart';

/// 議案選項
class BillOption {
  /// 選項 ID (A, B, C)
  final String id;

  /// 選項標籤
  final String label;

  /// 選項標題
  final String title;

  /// 選項描述
  final String description;

  /// 受益陣營（null 表示中立選項）
  final Faction? benefitFaction;

  /// 受益分數
  final int benefitScore;

  const BillOption({
    required this.id,
    required this.label,
    required this.title,
    required this.description,
    this.benefitFaction,
    required this.benefitScore,
  });

  factory BillOption.fromJson(Map<String, dynamic> json) {
    return BillOption(
      id: json['id'] as String,
      label: json['label'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      benefitFaction: json['benefitFaction'] != null
          ? Faction.values.firstWhere(
              (e) => e.name == json['benefitFaction'],
              orElse: () => Faction.neutral,
            )
          : null,
      benefitScore: json['benefitScore'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'title': title,
      'description': description,
      'benefitFaction': benefitFaction?.name,
      'benefitScore': benefitScore,
    };
  }
}

/// 投票記錄
class VoteRecord {
  /// 投票玩家 ID
  final String playerId;

  /// 選擇的選項 ID
  final String optionId;

  /// 投票權重
  final double weight;

  /// 投票時間
  final DateTime timestamp;

  const VoteRecord({
    required this.playerId,
    required this.optionId,
    required this.weight,
    required this.timestamp,
  });

  factory VoteRecord.fromJson(Map<String, dynamic> json) {
    return VoteRecord(
      playerId: json['playerId'] as String,
      optionId: json['optionId'] as String,
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'optionId': optionId,
      'weight': weight,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// 議案模型
class Bill {
  /// 議案 ID
  final String id;

  /// 議案標題
  final String title;

  /// 議案描述
  final String description;

  /// 議案背景故事
  final String backstory;

  /// 選項 A
  final BillOption optionA;

  /// 選項 B
  final BillOption optionB;

  /// 選項 C（折衷方案）
  final BillOption optionC;

  /// 投票記錄
  final List<VoteRecord> votes;

  /// 是否已完成投票
  final bool isVotingComplete;

  /// 獲勝選項 ID
  final String? winningOptionId;

  const Bill({
    required this.id,
    required this.title,
    required this.description,
    this.backstory = '',
    required this.optionA,
    required this.optionB,
    required this.optionC,
    this.votes = const [],
    this.isVotingComplete = false,
    this.winningOptionId,
  });

  /// 所有選項列表
  List<BillOption> get options => [optionA, optionB, optionC];

  /// 根據 ID 取得選項
  BillOption? getOptionById(String optionId) {
    switch (optionId) {
      case 'A':
        return optionA;
      case 'B':
        return optionB;
      case 'C':
        return optionC;
      default:
        return null;
    }
  }

  /// 計算各選項得票數
  Map<String, double> get voteTally {
    final tally = <String, double>{
      'A': 0.0,
      'B': 0.0,
      'C': 0.0,
    };

    for (final vote in votes) {
      if (tally.containsKey(vote.optionId)) {
        tally[vote.optionId] = tally[vote.optionId]! + vote.weight;
      }
    }

    return tally;
  }

  /// 取得獲勝選項（票數最高）
  String? get calculatedWinner {
    final tally = voteTally;
    if (tally.values.every((v) => v == 0)) return null;

    String? winner;
    double maxVotes = 0;

    for (final entry in tally.entries) {
      if (entry.value > maxVotes) {
        maxVotes = entry.value;
        winner = entry.key;
      }
    }

    return winner;
  }

  /// 取得玩家的投票記錄
  VoteRecord? getVoteByPlayerId(String playerId) {
    try {
      return votes.firstWhere((v) => v.playerId == playerId);
    } catch (e) {
      return null;
    }
  }

  /// 檢查玩家是否已投票
  bool hasPlayerVoted(String playerId) {
    return votes.any((v) => v.playerId == playerId);
  }

  Bill copyWith({
    String? id,
    String? title,
    String? description,
    String? backstory,
    BillOption? optionA,
    BillOption? optionB,
    BillOption? optionC,
    List<VoteRecord>? votes,
    bool? isVotingComplete,
    String? winningOptionId,
  }) {
    return Bill(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      backstory: backstory ?? this.backstory,
      optionA: optionA ?? this.optionA,
      optionB: optionB ?? this.optionB,
      optionC: optionC ?? this.optionC,
      votes: votes ?? this.votes,
      isVotingComplete: isVotingComplete ?? this.isVotingComplete,
      winningOptionId: winningOptionId ?? this.winningOptionId,
    );
  }

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      backstory: json['backstory'] as String? ?? '',
      optionA: BillOption.fromJson(json['optionA'] as Map<String, dynamic>),
      optionB: BillOption.fromJson(json['optionB'] as Map<String, dynamic>),
      optionC: BillOption.fromJson(json['optionC'] as Map<String, dynamic>),
      votes: (json['votes'] as List<dynamic>?)
              ?.map((e) => VoteRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isVotingComplete: json['isVotingComplete'] as bool? ?? false,
      winningOptionId: json['winningOptionId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'backstory': backstory,
      'optionA': optionA.toJson(),
      'optionB': optionB.toJson(),
      'optionC': optionC.toJson(),
      'votes': votes.map((e) => e.toJson()).toList(),
      'isVotingComplete': isVotingComplete,
      'winningOptionId': winningOptionId,
    };
  }
}
