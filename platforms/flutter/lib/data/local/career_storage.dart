// 1812 國會風雲 - 生涯數據本地存儲

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/player_career.dart';

/// 生涯數據存儲服務
class CareerStorage {
  static const String _careerKey = 'player_career';
  static const String _expHistoryKey = 'exp_history';
  
  final SharedPreferences _prefs;
  
  CareerStorage(this._prefs);
  
  /// 創建 CareerStorage 實例
  static Future<CareerStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return CareerStorage(prefs);
  }
  
  /// 保存玩家生涯數據
  Future<bool> saveCareer(PlayerCareer career) async {
    try {
      final json = jsonEncode(career.toJson());
      return await _prefs.setString(_careerKey, json);
    } catch (_) {
      // Error saving career - fail silently
      return false;
    }
  }
  
  /// 讀取玩家生涯數據
  PlayerCareer? loadCareer() {
    try {
      final json = _prefs.getString(_careerKey);
      if (json == null) return null;
      
      final data = jsonDecode(json) as Map<String, dynamic>;
      return PlayerCareer.fromJson(data);
    } catch (_) {
      // Error loading career - return null
      return null;
    }
  }
  
  /// 檢查是否有存儲的生涯數據
  bool hasCareer() {
    return _prefs.containsKey(_careerKey);
  }
  
  /// 刪除生涯數據
  Future<bool> deleteCareer() async {
    return await _prefs.remove(_careerKey);
  }
  
  /// 保存經驗獲得歷史記錄
  Future<bool> saveExpHistory(List<ExpHistoryEntry> history) async {
    try {
      final json = jsonEncode(history.map((e) => e.toJson()).toList());
      return await _prefs.setString(_expHistoryKey, json);
    } catch (_) {
      // Error saving exp history - fail silently
      return false;
    }
  }
  
  /// 讀取經驗獲得歷史記錄
  List<ExpHistoryEntry> loadExpHistory() {
    try {
      final json = _prefs.getString(_expHistoryKey);
      if (json == null) return [];
      
      final data = jsonDecode(json) as List<dynamic>;
      return data
          .map((e) => ExpHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Error loading exp history - return empty list
      return [];
    }
  }
  
  /// 添加經驗獲得記錄
  Future<bool> addExpHistoryEntry(ExpHistoryEntry entry) async {
    final history = loadExpHistory();
    history.add(entry);
    
    // 只保留最近 100 條記錄
    if (history.length > 100) {
      history.removeRange(0, history.length - 100);
    }
    
    return saveExpHistory(history);
  }
  
  /// 清除所有數據
  Future<bool> clearAll() async {
    try {
      await _prefs.remove(_careerKey);
      await _prefs.remove(_expHistoryKey);
      return true;
    } catch (_) {
      // Error clearing data - fail silently
      return false;
    }
  }
}

/// 經驗獲得歷史記錄
class ExpHistoryEntry {
  /// 獲得的經驗值
  final int amount;
  
  /// 來源描述
  final String source;
  
  /// 獲得時間
  final DateTime timestamp;
  
  /// 獲得前的經驗值
  final int previousExp;
  
  /// 獲得後的經驗值
  final int newExp;
  
  /// 是否觸發升級
  final bool leveledUp;
  
  /// 升級後的等級（如果升級了）
  final int? newLevel;

  const ExpHistoryEntry({
    required this.amount,
    required this.source,
    required this.timestamp,
    required this.previousExp,
    required this.newExp,
    this.leveledUp = false,
    this.newLevel,
  });

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'source': source,
    'timestamp': timestamp.toIso8601String(),
    'previousExp': previousExp,
    'newExp': newExp,
    'leveledUp': leveledUp,
    'newLevel': newLevel,
  };

  factory ExpHistoryEntry.fromJson(Map<String, dynamic> json) => ExpHistoryEntry(
    amount: json['amount'] as int,
    source: json['source'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    previousExp: json['previousExp'] as int,
    newExp: json['newExp'] as int,
    leveledUp: json['leveledUp'] as bool? ?? false,
    newLevel: json['newLevel'] as int?,
  );
}

/// 遊戲結算經驗計算器
class ExpCalculator {
  /// 計算遊戲完成經驗
  /// [performance] 0.0-1.0 表現分數
  static int calculateGameCompleteExp(double performance) {
    const minExp = 20;
    const maxExp = 50;
    return minExp + ((maxExp - minExp) * performance.clamp(0.0, 1.0)).round();
  }
  
  /// 計算陣營勝利經驗
  static int get factionVictoryExp => 30;
  
  /// 計算秘密任務經驗
  static int get secretMissionExp => 20;
  
  /// 計算 MVP 經驗
  static int get mvpExp => 50;
  
  /// 計算總經驗
  static ExpCalculationResult calculateTotalExp({
    required bool gameCompleted,
    double performance = 0.5,
    bool factionVictory = false,
    bool secretMissionComplete = false,
    bool isMvp = false,
  }) {
    final breakdown = <String, int>{};
    int total = 0;
    
    if (gameCompleted) {
      final gameExp = calculateGameCompleteExp(performance);
      breakdown['完成一局'] = gameExp;
      total += gameExp;
    }
    
    if (factionVictory) {
      breakdown['陣營勝利'] = factionVictoryExp;
      total += factionVictoryExp;
    }
    
    if (secretMissionComplete) {
      breakdown['完成秘密任務'] = secretMissionExp;
      total += secretMissionExp;
    }
    
    if (isMvp) {
      breakdown['獲得 MVP'] = mvpExp;
      total += mvpExp;
    }
    
    return ExpCalculationResult(
      totalExp: total,
      breakdown: breakdown,
    );
  }
}

/// 經驗計算結果
class ExpCalculationResult {
  final int totalExp;
  final Map<String, int> breakdown;

  const ExpCalculationResult({
    required this.totalExp,
    required this.breakdown,
  });
  
  /// 生成經驗獲得描述
  String get description {
    if (breakdown.isEmpty) return '無經驗獲得';
    
    final parts = breakdown.entries
        .map((e) => '${e.key}: +${e.value}')
        .join('\n');
    
    return '$parts\n總計: +$totalExp';
  }
}
