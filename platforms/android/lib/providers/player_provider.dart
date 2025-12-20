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

      // 發送到後端驗證，返回 NfcScanResult
      final scanResult = await _api.scanNfc(
        roomCode: roomCode,
        playerId: _currentPlayer!.id,
        cardId: cardData.cardId,
        signature: cardData.signature,
      );

      // 使用掃描結果更新當前玩家的角色資訊
      _currentPlayer = _currentPlayer!.copyWith(
        roleType: scanResult.roleType,
        roleIndex: scanResult.roleIndex,
        secretMissionId: scanResult.secretMissionId,
      );
      notifyListeners();

      // 載入秘密任務
      await loadSecretMission();

      return _currentPlayer;
    } catch (e) {
      _setError(_formatError(e));
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// 取消 NFC 掃描
  Future<void> cancelNfcScan() async {
    await _nfc.stopScan();
  }

  /// 手動輸入角色代碼分配角色（NFC 備用方案）
  Future<Player?> assignRoleManually(String roomCode, String roleCode) async {
    if (_currentPlayer == null) return null;

    _setLoading(true);
    _clearError();

    try {
      // 驗證角色代碼格式 (如 W01, F02, L03, R04, M01 等)
      final validPattern = RegExp(r'^[WFLRM][0-9]{2}$', caseSensitive: false);
      if (!validPattern.hasMatch(roleCode)) {
        _setError('角色代碼格式錯誤，請輸入如 W01、F02 等格式');
        return null;
      }

      // 發送到後端驗證並分配角色，返回 ManualRoleResult
      final result = await _api.assignRoleManually(
        roomCode: roomCode,
        playerId: _currentPlayer!.id,
        roleCode: roleCode.toUpperCase(),
      );

      // 使用結果更新當前玩家的角色資訊（與 NFC 掃描相同的模式）
      _currentPlayer = _currentPlayer!.copyWith(
        roleType: result.roleType,
        roleIndex: result.roleIndex,
        secretMissionId: result.secretMissionId,
      );
      notifyListeners();

      // 載入秘密任務
      await loadSecretMission();

      return _currentPlayer;
    } catch (e) {
      _setError(_formatError(e));
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// 載入秘密任務
  Future<void> loadSecretMission() async {
    if (_currentPlayer == null || !hasRole) return;

    try {
      _secretMission = await _api.getSecretMission(_currentPlayer!.id);
      notifyListeners();
    } catch (e) {
      _setError(_formatError(e));
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
  
  /// 格式化錯誤訊息，避免顯示 "Instance of 'XXX'"
  String _formatError(dynamic e) {
    // 處理 NfcException
    if (e is NfcException) {
      return e.message;
    }
    // 處理 ApiException
    if (e is ApiException) {
      return e.message;
    }
    
    final str = e.toString();
    
    // 移除 "Instance of 'XXX'" 格式
    if (str.startsWith("Instance of '")) {
      // 嘗試從類名推斷錯誤類型
      if (str.contains('NfcError') || str.contains('Nfc')) {
        return 'NFC 讀取失敗，請確認卡片位置後重試';
      }
      return '發生未知錯誤，請重試';
    }
    
    // 移除 "NfcException: " 前綴
    if (str.startsWith('NfcException: ')) {
      return str.substring(14);
    }
    
    // 移除 "ApiException: [xxx]" 前綴
    if (str.contains('ApiException:')) {
      return str.replaceFirst(RegExp(r'ApiException: \[\d+\] '), '');
    }
    
    // 處理 PlatformException
    if (str.contains('PlatformException')) {
      if (str.contains('not available') || str.contains('NFC')) {
        return 'NFC 功能不可用，請檢查是否已開啟 NFC';
      }
      return '裝置功能異常，請重試';
    }
    
    return str;
  }
}
