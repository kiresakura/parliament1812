import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player.dart';
import '../services/api_service.dart';
import '../services/nfc_service.dart';

/// 玩家狀態管理
class PlayerProvider with ChangeNotifier {
  final _api = ApiService();
  final _nfc = NfcService();

  Player? _currentPlayer;
  SecretMission? _secretMission;
  bool _isLoading = false;
  String? _error;

  Player? get currentPlayer => _currentPlayer;
  SecretMission? get secretMission => _secretMission;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isLoggedIn => _currentPlayer != null;
  bool get hasRole => _currentPlayer?.hasRole ?? false;

  /// 設定當前玩家
  void setCurrentPlayer(Player player) {
    _currentPlayer = player;
    _savePlayerId(player.id);
    notifyListeners();
  }

  /// NFC 掃卡分配角色
  Future<Player?> scanNfcCard(String roomCode) async {
    if (_currentPlayer == null) return null;

    _setLoading(true);
    _clearError();

    try {
      // 檢查 NFC 是否可用
      final isAvailable = await _nfc.isAvailable();
      if (!isAvailable) {
        _setError('您的裝置不支援 NFC 或 NFC 已關閉');
        return null;
      }

      // 開始掃描
      final cardData = await _nfc.startScan();
      if (cardData == null) {
        _setError('掃描逾時或已取消');
        return null;
      }

      // 發送到後端驗證
      final player = await _api.scanNfc(
        roomCode: roomCode,
        playerId: _currentPlayer!.id,
        cardId: cardData.cardId,
        signature: cardData.signature,
      );

      _currentPlayer = player;
      notifyListeners();

      // 載入秘密任務
      await loadSecretMission();

      return player;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// 取消 NFC 掃描
  Future<void> cancelNfcScan() async {
    await _nfc.stopScan();
  }

  /// 載入秘密任務
  Future<void> loadSecretMission() async {
    if (_currentPlayer == null || !hasRole) return;

    try {
      _secretMission = await _api.getSecretMission(_currentPlayer!.id);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// 更新玩家資訊
  void updatePlayer(Player player) {
    if (_currentPlayer?.id == player.id) {
      _currentPlayer = player;
      notifyListeners();
    }
  }

  /// 清除玩家狀態
  void clearPlayer() {
    _currentPlayer = null;
    _secretMission = null;
    _clearSavedPlayerId();
    notifyListeners();
  }

  /// 儲存玩家 ID 到本地
  Future<void> _savePlayerId(String playerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('player_id', playerId);
  }

  /// 取得儲存的玩家 ID
  Future<String?> getSavedPlayerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('player_id');
  }

  /// 清除儲存的玩家 ID
  Future<void> _clearSavedPlayerId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('player_id');
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
