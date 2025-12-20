import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../config/app_config.dart';

/// NFC 服務 - 處理 NFC 卡片掃描
class NfcService {
  static final NfcService _instance = NfcService._internal();
  factory NfcService() => _instance;
  NfcService._internal();

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  /// 檢查 NFC 是否可用
  Future<bool> isAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (e) {
      debugPrint('NFC 檢查失敗: $e');
      return false;
    }
  }

  /// 開始掃描 NFC 卡片
  Future<NfcCardData?> startScan({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (_isScanning) return null;

    final completer = Completer<NfcCardData?>();
    Timer? timeoutTimer;

    _isScanning = true;

    try {
      // 設定超時
      timeoutTimer = Timer(timeout, () {
        if (!completer.isCompleted) {
          stopScan();
          completer.complete(null);
        }
      });

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            final cardData = await _processTag(tag);
            if (!completer.isCompleted) {
              completer.complete(cardData);
            }
          } catch (e) {
            if (!completer.isCompleted) {
              completer.completeError(e);
            }
          } finally {
            stopScan();
          }
        },
        onError: (error) async {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
          stopScan();
        },
      );

      return await completer.future;
    } catch (e) {
      _isScanning = false;
      rethrow;
    } finally {
      timeoutTimer?.cancel();
    }
  }

  /// 停止掃描
  Future<void> stopScan() async {
    if (!_isScanning) return;

    try {
      await NfcManager.instance.stopSession();
    } catch (e) {
      debugPrint('停止 NFC 掃描失敗: $e');
    } finally {
      _isScanning = false;
    }
  }

  /// 處理 NFC 標籤
  Future<NfcCardData?> _processTag(NfcTag tag) async {
    // 嘗試讀取 NDEF 資料
    final ndef = Ndef.from(tag);
    if (ndef == null) {
      throw NfcException('此卡片不支援 NDEF 格式');
    }

    final message = await ndef.read();
    if (message.records.isEmpty) {
      throw NfcException('卡片資料為空');
    }

    // 解析 NDEF 記錄
    for (final record in message.records) {
      if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown) {
        // URI 記錄
        if (record.type.length == 1 && record.type[0] == 0x55) {
          final uri = _decodeUri(record.payload);
          final cardData = _parseUri(uri);
          if (cardData != null) {
            return cardData;
          }
        }
      }
    }

    throw NfcException('無法解析卡片資料');
  }

  /// 解碼 URI
  String _decodeUri(List<int> payload) {
    if (payload.isEmpty) return '';

    // URI 前綴代碼
    const prefixes = [
      '', // 0x00
      'http://www.', // 0x01
      'https://www.', // 0x02
      'http://', // 0x03
      'https://', // 0x04
      'tel:', // 0x05
      'mailto:', // 0x06
    ];

    final prefixCode = payload[0];
    final prefix = prefixCode < prefixes.length ? prefixes[prefixCode] : '';
    final uri = String.fromCharCodes(payload.sublist(1));

    return prefix + uri;
  }

  /// 解析 URI 取得卡片資料
  /// 預期格式: parliament1812://role?id={card_id}&secret={hash}
  NfcCardData? _parseUri(String uri) {
    try {
      final parsed = Uri.parse(uri);

      // 檢查 scheme
      if (parsed.scheme != AppConfig.nfcUrlScheme) {
        return null;
      }

      final cardId = parsed.queryParameters['id'];
      final signature = parsed.queryParameters['secret'];

      if (cardId == null || signature == null) {
        return null;
      }

      return NfcCardData(
        cardId: cardId,
        signature: signature,
        rawUri: uri,
      );
    } catch (e) {
      return null;
    }
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
