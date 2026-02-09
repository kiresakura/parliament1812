import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/constants.dart';

// ============================================================
// Models
// ============================================================

/// 排行榜項目
class RankingEntry {
  final int rank;
  final String userId;
  final String username;
  final String? displayName;
  final int eloRating;
  final int gamesPlayed;
  final int wins;
  final double winRate;

  const RankingEntry({
    required this.rank,
    required this.userId,
    required this.username,
    this.displayName,
    required this.eloRating,
    required this.gamesPlayed,
    required this.wins,
    required this.winRate,
  });

  factory RankingEntry.fromJson(Map<String, dynamic> json) {
    return RankingEntry(
      rank: json['rank'] as int,
      userId: json['user_id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String?,
      eloRating: json['elo_rating'] as int,
      gamesPlayed: json['games_played'] as int,
      wins: json['wins'] as int,
      winRate: (json['win_rate'] as num).toDouble(),
    );
  }

  String get name => displayName ?? username;
}

/// 我的排名
class MyRanking {
  final int? rank;
  final int eloRating;
  final int gamesPlayed;
  final int wins;
  final double winRate;
  final int totalRanked;
  final int seasonId;
  final String seasonName;

  const MyRanking({
    this.rank,
    required this.eloRating,
    required this.gamesPlayed,
    required this.wins,
    required this.winRate,
    required this.totalRanked,
    required this.seasonId,
    required this.seasonName,
  });

  factory MyRanking.fromJson(Map<String, dynamic> json) {
    return MyRanking(
      rank: json['rank'] as int?,
      eloRating: json['elo_rating'] as int,
      gamesPlayed: json['games_played'] as int,
      wins: json['wins'] as int,
      winRate: (json['win_rate'] as num).toDouble(),
      totalRanked: json['total_ranked'] as int,
      seasonId: json['season_id'] as int,
      seasonName: json['season_name'] as String,
    );
  }
}

/// 賽季
class SeasonInfo {
  final int id;
  final String name;
  final String startDate;
  final String endDate;
  final bool isActive;

  const SeasonInfo({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  factory SeasonInfo.fromJson(Map<String, dynamic> json) {
    return SeasonInfo(
      id: json['id'] as int,
      name: json['name'] as String,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      isActive: json['is_active'] as bool,
    );
  }
}

// ============================================================
// State
// ============================================================

/// 排行榜狀態
class RankingsState {
  final List<RankingEntry> rankings;
  final MyRanking? myRanking;
  final List<SeasonInfo> seasons;
  final int? currentSeasonId;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  const RankingsState({
    this.rankings = const [],
    this.myRanking,
    this.seasons = const [],
    this.currentSeasonId,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  RankingsState copyWith({
    List<RankingEntry>? rankings,
    MyRanking? myRanking,
    List<SeasonInfo>? seasons,
    int? currentSeasonId,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) {
    return RankingsState(
      rankings: rankings ?? this.rankings,
      myRanking: myRanking ?? this.myRanking,
      seasons: seasons ?? this.seasons,
      currentSeasonId: currentSeasonId ?? this.currentSeasonId,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ============================================================
// Notifier
// ============================================================

class RankingsNotifier extends StateNotifier<RankingsState> {
  RankingsNotifier() : super(const RankingsState());

  static const int _pageSize = 50;

  /// 載入初始資料
  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // 並行載入賽季列表和全球排行榜
      await Future.wait([
        _loadSeasons(),
        _loadGlobalRankings(offset: 0),
        _loadMyRanking(),
      ]);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '載入排行榜失敗: $e');
    }
  }

  /// 載入更多排行榜資料（無限滾動）
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    await _loadGlobalRankings(offset: state.rankings.length);
    state = state.copyWith(isLoadingMore: false);
  }

  /// 切換賽季
  Future<void> changeSeason(int seasonId) async {
    state = state.copyWith(
      currentSeasonId: seasonId,
      rankings: [],
      isLoading: true,
      hasMore: true,
      clearError: true,
    );

    await Future.wait([
      _loadGlobalRankings(offset: 0, seasonId: seasonId),
      _loadMyRanking(seasonId: seasonId),
    ]);
  }

  Future<void> _loadSeasons() async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/api/v1/rankings/seasons');
      final response = await _httpGet(uri);

      if (response != null) {
        final List<dynamic> seasonsJson = response['seasons'] as List<dynamic>;
        final seasons = seasonsJson
            .map((json) => SeasonInfo.fromJson(json as Map<String, dynamic>))
            .toList();

        // 找到活躍賽季
        final activeSeason = seasons.where((s) => s.isActive).firstOrNull;

        state = state.copyWith(
          seasons: seasons,
          currentSeasonId: activeSeason?.id,
        );
      }
    } catch (e) {
      // 使用 mock 資料
      _loadMockSeasons();
    }
  }

  Future<void> _loadGlobalRankings({required int offset, int? seasonId}) async {
    try {
      final queryParams = <String, String>{
        'limit': '$_pageSize',
        'offset': '$offset',
      };
      if (seasonId != null) queryParams['season'] = '$seasonId';

      final uri = Uri.parse('${AppConstants.baseUrl}/api/v1/rankings/global')
          .replace(queryParameters: queryParams);

      final response = await _httpGet(uri);

      if (response != null) {
        final List<dynamic> rankingsJson = response['rankings'] as List<dynamic>;
        final newEntries = rankingsJson
            .map((json) => RankingEntry.fromJson(json as Map<String, dynamic>))
            .toList();

        final total = response['total'] as int;

        state = state.copyWith(
          rankings: offset == 0 ? newEntries : [...state.rankings, ...newEntries],
          hasMore: (offset + newEntries.length) < total,
          isLoading: false,
        );
        return;
      }
    } catch (_) {
      // fall through to mock
    }

    // Mock 資料
    _loadMockRankings(offset);
  }

  Future<void> _loadMyRanking({int? seasonId}) async {
    try {
      final queryParams = <String, String>{};
      if (seasonId != null) queryParams['season'] = '$seasonId';

      final uri = Uri.parse('${AppConstants.baseUrl}/api/v1/rankings/me')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await _httpGet(uri);

      if (response != null) {
        state = state.copyWith(myRanking: MyRanking.fromJson(response));
        return;
      }
    } catch (_) {
      // fall through to mock
    }

    // Mock
    _loadMockMyRanking();
  }

  Future<Map<String, dynamic>?> _httpGet(Uri uri) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = await response.transform(utf8.decoder).join();
        return jsonDecode(body) as Map<String, dynamic>;
      }
    } catch (_) {
      // API not available
    }
    return null;
  }

  // ============================================================
  // Mock Data（開發用）
  // ============================================================

  void _loadMockSeasons() {
    state = state.copyWith(
      seasons: [
        const SeasonInfo(
          id: 1,
          name: 'Season 1',
          startDate: '2026-01-01T00:00:00Z',
          endDate: '2026-01-31T00:00:00Z',
          isActive: false,
        ),
        const SeasonInfo(
          id: 2,
          name: 'Season 2',
          startDate: '2026-02-01T00:00:00Z',
          endDate: '2026-03-03T00:00:00Z',
          isActive: true,
        ),
      ],
      currentSeasonId: 2,
    );
  }

  void _loadMockRankings(int offset) {
    final mockEntries = List.generate(
      offset >= 50 ? 10 : _pageSize,
      (i) => RankingEntry(
        rank: offset + i + 1,
        userId: 'user_${offset + i}',
        username: _mockNames[(offset + i) % _mockNames.length],
        eloRating: 2000 - (offset + i) * 15,
        gamesPlayed: 100 - (offset + i),
        wins: 60 - (offset + i) ~/ 2,
        winRate: 60.0 - (offset + i) * 0.5,
      ),
    );

    state = state.copyWith(
      rankings: offset == 0 ? mockEntries : [...state.rankings, ...mockEntries],
      hasMore: offset < 100,
      isLoading: false,
    );
  }

  void _loadMockMyRanking() {
    state = state.copyWith(
      myRanking: const MyRanking(
        rank: 42,
        eloRating: 1234,
        gamesPlayed: 28,
        wins: 16,
        winRate: 57.14,
        totalRanked: 200,
        seasonId: 2,
        seasonName: 'Season 2',
      ),
    );
  }

  static const _mockNames = [
    'Lord Wellington',
    'Lady Peel',
    'Sir Spencer',
    'Duke of York',
    'Earl Grey',
    'Lord Byron',
    'Sir Walter',
    'Viscount Melbourne',
    'Baron Rothschild',
    'Marquess of Salisbury',
  ];
}

// ============================================================
// Provider
// ============================================================

final rankingsProvider =
    StateNotifierProvider<RankingsNotifier, RankingsState>((ref) {
  return RankingsNotifier();
});
