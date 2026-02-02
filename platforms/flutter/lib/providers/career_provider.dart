// 1812 國會風雲 - 生涯狀態管理

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/player_career.dart';
import '../data/local/career_storage.dart';

/// 生涯狀態
class CareerState {
  /// 玩家生涯數據
  final PlayerCareer? career;
  
  /// 是否正在加載
  final bool isLoading;
  
  /// 錯誤信息
  final String? error;
  
  /// 最近一次經驗獲得結果
  final ExpGainResult? lastExpGain;

  const CareerState({
    this.career,
    this.isLoading = false,
    this.error,
    this.lastExpGain,
  });

  /// 是否已初始化生涯
  bool get hasCareer => career != null;

  /// 當前等級
  ParliamentLevel? get currentLevel => career?.level;

  /// 當前等級進度
  double get levelProgress => career?.levelProgress ?? 0.0;

  CareerState copyWith({
    PlayerCareer? career,
    bool? isLoading,
    String? error,
    ExpGainResult? lastExpGain,
    bool clearError = false,
    bool clearLastExpGain = false,
  }) {
    return CareerState(
      career: career ?? this.career,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      lastExpGain: clearLastExpGain ? null : (lastExpGain ?? this.lastExpGain),
    );
  }
}

/// 經驗獲得結果
class ExpGainResult {
  /// 獲得的經驗值
  final int expGained;
  
  /// 經驗明細
  final Map<String, int> breakdown;
  
  /// 是否升級
  final bool leveledUp;
  
  /// 升級前等級
  final ParliamentLevel previousLevel;
  
  /// 升級後等級
  final ParliamentLevel newLevel;
  
  /// 新解鎖的內容
  final List<UnlockContent> newUnlocks;

  const ExpGainResult({
    required this.expGained,
    required this.breakdown,
    required this.leveledUp,
    required this.previousLevel,
    required this.newLevel,
    this.newUnlocks = const [],
  });
}

/// 生涯 Notifier
class CareerNotifier extends StateNotifier<CareerState> {
  CareerStorage? _storage;
  
  CareerNotifier() : super(const CareerState(isLoading: true)) {
    _init();
  }
  
  /// 初始化
  Future<void> _init() async {
    try {
      _storage = await CareerStorage.create();
      final career = _storage?.loadCareer();
      
      state = state.copyWith(
        career: career,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '初始化失敗: $e',
      );
    }
  }
  
  /// 創建新生涯
  Future<void> createCareer({
    required String playerId,
    required String nickname,
  }) async {
    state = state.copyWith(isLoading: true);
    
    try {
      final career = PlayerCareer.create(
        playerId: playerId,
        nickname: nickname,
      );
      
      await _storage?.saveCareer(career);
      
      state = state.copyWith(
        career: career,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '創建生涯失敗: $e',
      );
    }
  }
  
  /// 更新暱稱
  Future<void> updateNickname(String nickname) async {
    final currentCareer = state.career;
    if (currentCareer == null) return;
    
    final updatedCareer = currentCareer.copyWith(nickname: nickname);
    await _storage?.saveCareer(updatedCareer);
    
    state = state.copyWith(career: updatedCareer);
  }
  
  /// 記錄遊戲結果並發放經驗
  Future<ExpGainResult?> recordGameResult(GameResultData result) async {
    final currentCareer = state.career;
    if (currentCareer == null) return null;
    
    state = state.copyWith(isLoading: true);
    
    try {
      // 計算經驗
      final calcResult = ExpCalculator.calculateTotalExp(
        gameCompleted: result.completed,
        performance: result.performance,
        factionVictory: result.factionVictory,
        secretMissionComplete: result.secretMissionComplete,
        isMvp: result.isMvp,
      );
      
      final previousLevel = currentCareer.level;
      final updatedCareer = currentCareer.recordGameResult(result);
      final newLevel = updatedCareer.level;
      
      // 檢查新解鎖
      final leveledUp = newLevel.level > previousLevel.level;
      List<UnlockContent> newUnlocks = [];
      
      if (leveledUp) {
        // 收集所有新解鎖的內容
        for (int i = previousLevel.level + 1; i <= newLevel.level; i++) {
          final level = ParliamentLevel.values.firstWhere((l) => l.level == i);
          newUnlocks.addAll(UnlockDatabase.getUnlocksForLevel(level));
        }
      }
      
      // 保存
      await _storage?.saveCareer(updatedCareer);
      
      // 記錄經驗歷史
      await _storage?.addExpHistoryEntry(ExpHistoryEntry(
        amount: calcResult.totalExp,
        source: '遊戲結算',
        timestamp: DateTime.now(),
        previousExp: currentCareer.experience,
        newExp: updatedCareer.experience,
        leveledUp: leveledUp,
        newLevel: leveledUp ? newLevel.level : null,
      ));
      
      final expGainResult = ExpGainResult(
        expGained: calcResult.totalExp,
        breakdown: calcResult.breakdown,
        leveledUp: leveledUp,
        previousLevel: previousLevel,
        newLevel: newLevel,
        newUnlocks: newUnlocks,
      );
      
      state = state.copyWith(
        career: updatedCareer,
        isLoading: false,
        lastExpGain: expGainResult,
        clearError: true,
      );
      
      return expGainResult;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '記錄遊戲結果失敗: $e',
      );
      return null;
    }
  }
  
  /// 手動添加經驗（用於測試或特殊獎勵）
  Future<void> addExperience(int amount, String source) async {
    final currentCareer = state.career;
    if (currentCareer == null) return;
    
    try {
      final previousLevel = currentCareer.level;
      final updatedCareer = currentCareer.addExperience(amount);
      final newLevel = updatedCareer.level;
      
      await _storage?.saveCareer(updatedCareer);
      
      await _storage?.addExpHistoryEntry(ExpHistoryEntry(
        amount: amount,
        source: source,
        timestamp: DateTime.now(),
        previousExp: currentCareer.experience,
        newExp: updatedCareer.experience,
        leveledUp: newLevel.level > previousLevel.level,
        newLevel: newLevel.level > previousLevel.level ? newLevel.level : null,
      ));
      
      state = state.copyWith(career: updatedCareer);
    } catch (e) {
      state = state.copyWith(error: '添加經驗失敗: $e');
    }
  }
  
  /// 裝備頭像框
  Future<void> equipAvatarFrame(String? frameId) async {
    final currentCareer = state.career;
    if (currentCareer == null) return;
    
    // 驗證是否已解鎖
    if (frameId != null && !currentCareer.isContentUnlocked(frameId)) {
      state = state.copyWith(error: '該頭像框尚未解鎖');
      return;
    }
    
    final updatedCareer = currentCareer.copyWith(
      equippedAvatarFrameId: frameId,
    );
    
    await _storage?.saveCareer(updatedCareer);
    state = state.copyWith(career: updatedCareer);
  }
  
  /// 裝備稱號
  Future<void> equipTitle(String? titleId) async {
    final currentCareer = state.career;
    if (currentCareer == null) return;
    
    if (titleId != null && !currentCareer.isContentUnlocked(titleId)) {
      state = state.copyWith(error: '該稱號尚未解鎖');
      return;
    }
    
    final updatedCareer = currentCareer.copyWith(
      equippedTitleId: titleId,
    );
    
    await _storage?.saveCareer(updatedCareer);
    state = state.copyWith(career: updatedCareer);
  }
  
  /// 裝備皮膚
  Future<void> equipSkin(String? skinId) async {
    final currentCareer = state.career;
    if (currentCareer == null) return;
    
    if (skinId != null && !currentCareer.isContentUnlocked(skinId)) {
      state = state.copyWith(error: '該皮膚尚未解鎖');
      return;
    }
    
    final updatedCareer = currentCareer.copyWith(
      equippedSkinId: skinId,
    );
    
    await _storage?.saveCareer(updatedCareer);
    state = state.copyWith(career: updatedCareer);
  }
  
  /// 清除最近經驗獲得結果
  void clearLastExpGain() {
    state = state.copyWith(clearLastExpGain: true);
  }
  
  /// 清除錯誤
  void clearError() {
    state = state.copyWith(clearError: true);
  }
  
  /// 獲取經驗歷史
  List<ExpHistoryEntry> getExpHistory() {
    return _storage?.loadExpHistory() ?? [];
  }
  
  /// 重置生涯（警告：會清除所有數據）
  Future<void> resetCareer() async {
    state = state.copyWith(isLoading: true);
    
    try {
      await _storage?.clearAll();
      
      state = const CareerState(
        career: null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '重置失敗: $e',
      );
    }
  }
}

// ===== Providers =====

/// 生涯狀態 Provider
final careerProvider = StateNotifierProvider<CareerNotifier, CareerState>((ref) {
  return CareerNotifier();
});

/// 當前等級 Provider
final currentLevelProvider = Provider<ParliamentLevel?>((ref) {
  return ref.watch(careerProvider).currentLevel;
});

/// 等級進度 Provider
final levelProgressProvider = Provider<double>((ref) {
  return ref.watch(careerProvider).levelProgress;
});

/// 玩家經驗 Provider
final playerExpProvider = Provider<int>((ref) {
  return ref.watch(careerProvider).career?.experience ?? 0;
});

/// 總遊戲場次 Provider
final totalGamesProvider = Provider<int>((ref) {
  return ref.watch(careerProvider).career?.totalGames ?? 0;
});

/// 勝率 Provider
final winRateProvider = Provider<double>((ref) {
  return ref.watch(careerProvider).career?.winRate ?? 0.0;
});

/// MVP 次數 Provider
final mvpCountProvider = Provider<int>((ref) {
  return ref.watch(careerProvider).career?.mvpCount ?? 0;
});

/// 是否有生涯數據 Provider
final hasCareerProvider = Provider<bool>((ref) {
  return ref.watch(careerProvider).hasCareer;
});

/// 解鎖內容 Provider
final unlockedContentProvider = Provider<List<UnlockContent>>((ref) {
  final career = ref.watch(careerProvider).career;
  if (career == null) return [];
  
  return career.unlockedContentIds
      .map((id) => UnlockDatabase.getContentById(id))
      .whereType<UnlockContent>()
      .toList();
});

/// 可解鎖但尚未解鎖的內容 Provider
final lockedContentProvider = Provider<List<UnlockContent>>((ref) {
  final career = ref.watch(careerProvider).career;
  if (career == null) return UnlockDatabase.allContent;
  
  return UnlockDatabase.allContent
      .where((c) => !career.isContentUnlocked(c.id))
      .toList();
});

/// 距離下一級所需經驗 Provider
final expToNextLevelProvider = Provider<int>((ref) {
  return ref.watch(careerProvider).career?.expToNextLevel ?? 100;
});

/// 是否滿級 Provider
final isMaxLevelProvider = Provider<bool>((ref) {
  return ref.watch(careerProvider).career?.isMaxLevel ?? false;
});
