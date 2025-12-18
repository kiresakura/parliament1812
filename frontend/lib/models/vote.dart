/// 投票模型
class Vote {
  final String id;
  final String roomId;
  final String playerId;
  final int round;
  final String choice;
  final DateTime votedAt;

  Vote({
    required this.id,
    required this.roomId,
    required this.playerId,
    required this.round,
    required this.choice,
    required this.votedAt,
  });

  factory Vote.fromJson(Map<String, dynamic> json) {
    return Vote(
      id: json['id'],
      roomId: json['room_id'],
      playerId: json['player_id'],
      round: json['round'],
      choice: json['choice'],
      votedAt: DateTime.parse(json['voted_at']),
    );
  }
}

/// 投票選項
class VoteOption {
  final String id;
  final String label;
  final String description;
  final bool isHidden;

  VoteOption({
    required this.id,
    required this.label,
    required this.description,
    this.isHidden = false,
  });

  factory VoteOption.fromJson(Map<String, dynamic> json) {
    return VoteOption(
      id: json['id'],
      label: json['label'],
      description: json['description'],
      isHidden: json['is_hidden'] ?? false,
    );
  }

  static List<VoteOption> get defaultOptions => [
        VoteOption(
          id: 'A',
          label: '禁止機器',
          description: '立法禁止工廠使用省力機器',
        ),
        VoteOption(
          id: 'B',
          label: '保護財產',
          description: '嚴厲打擊破壞機器的暴民',
        ),
        VoteOption(
          id: 'C',
          label: '折衷改革',
          description: '允許機器但立法保障工人權益',
        ),
      ];
}

/// 第一輪投票結果（匿名）
class Round1Result {
  final Map<String, double> percentages;
  final int totalVotes;
  final int totalPlayers;

  Round1Result({
    required this.percentages,
    required this.totalVotes,
    required this.totalPlayers,
  });

  factory Round1Result.fromJson(Map<String, dynamic> json) {
    return Round1Result(
      percentages: Map<String, double>.from(
        (json['percentages'] as Map).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      ),
      totalVotes: json['total_votes'],
      totalPlayers: json['total_players'],
    );
  }

  double get votedPercentage =>
      totalPlayers > 0 ? (totalVotes / totalPlayers * 100) : 0;
}

/// 第二輪投票結果（記名）
class Round2Result {
  final Map<String, int> counts;
  final Map<String, List<PlayerVote>> details;
  final int totalVotes;
  final int totalPlayers;

  Round2Result({
    required this.counts,
    required this.details,
    required this.totalVotes,
    required this.totalPlayers,
  });

  factory Round2Result.fromJson(Map<String, dynamic> json) {
    final detailsMap = <String, List<PlayerVote>>{};
    final jsonDetails = json['details'] as Map<String, dynamic>? ?? {};

    jsonDetails.forEach((key, value) {
      detailsMap[key] = (value as List)
          .map((v) => PlayerVote.fromJson(v))
          .toList();
    });

    return Round2Result(
      counts: Map<String, int>.from(json['counts'] ?? {}),
      details: detailsMap,
      totalVotes: json['total_votes'] ?? 0,
      totalPlayers: json['total_players'] ?? 0,
    );
  }
}

/// 玩家投票記錄（用於第二輪公開）
class PlayerVote {
  final String playerId;
  final String nickname;
  final String? roleName;

  PlayerVote({
    required this.playerId,
    required this.nickname,
    this.roleName,
  });

  factory PlayerVote.fromJson(Map<String, dynamic> json) {
    return PlayerVote(
      playerId: json['player_id'],
      nickname: json['nickname'],
      roleName: json['role_name'],
    );
  }
}
