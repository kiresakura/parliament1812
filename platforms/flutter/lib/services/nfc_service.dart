import 'dart:async';
import 'package:flutter/foundation.dart';

// NFC 功能暫時停用，待後續版本實作
// nfc_manager 4.x API 有重大變更，需要使用 nfc_manager_ndef 套件
// TODO: 實作完整 NFC 功能時，使用以下套件：
// - nfc_manager: ^4.1.1
// - nfc_manager_ndef: ^1.0.0

/// NFC 服務 - 處理 NFC 卡片掃描
/// 目前為存根實作，NFC 功能待後續版本啟用
class NfcService {
  static final NfcService _instance = NfcService._internal();
  factory NfcService() => _instance;
  NfcService._internal();

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  /// 檢查 NFC 是否可用
  /// 目前始終返回 false，待 NFC 功能實作後啟用
  Future<bool> isAvailable() async {
    // NFC 功能暫時停用
    debugPrint('NFC 功能暫時停用');
    return false;
  }

  /// 開始掃描 NFC 卡片
  /// 目前為存根實作
  Future<NfcCardData?> startScan({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (_isScanning) return null;

    debugPrint('NFC 掃描功能暫時停用');
    return null;
  }

  /// 停止掃描
  Future<void> stopScan() async {
    _isScanning = false;
  }
}

/// NFC 卡片資料
class NfcCardData {
  final String cardId;
  final String signature;
  final String rawUri;

  NfcCardData({
    required this.cardId,
    required this.signature,
    required this.rawUri,
  });

  @override
  String toString() => 'NfcCardData(cardId: $cardId)';
}

/// NFC 例外
class NfcException implements Exception {
  final String message;

  NfcException(this.message);

  @override
  String toString() => 'NfcException: $message';
}
