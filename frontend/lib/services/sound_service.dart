import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 音效類型
enum SoundEffect {
  // UI 音效
  buttonClick,
  cardFlip,
  pageTransition,
  notification,

  // 遊戲音效
  gavel,           // 木槌聲
  quillWriting,    // 羽毛筆書寫
  paperRustle,     // 紙張沙沙聲
  sealStamp,       // 蠟封蓋章
  crowdMurmur,     // 人群議論
  bellRing,        // 鈴聲
  voteCount,       // 唱票聲
  victory,         // 勝利
  dramatic,        // 戲劇性時刻

  // 環境音效
  ambient,         // 背景環境音
  fireplace,       // 壁爐聲
  clockTick,       // 鐘錶滴答
}

/// 音效服務 - 管理遊戲音效和震動回饋
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _effectPlayer = AudioPlayer();
  final AudioPlayer _ambientPlayer = AudioPlayer();

  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _hapticEnabled = true;
  double _volume = 0.7;

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get hapticEnabled => _hapticEnabled;
  double get volume => _volume;

  // 音效檔案路徑映射
  static const Map<SoundEffect, String> _soundPaths = {
    SoundEffect.buttonClick: 'assets/sounds/button_click.mp3',
    SoundEffect.cardFlip: 'assets/sounds/card_flip.mp3',
    SoundEffect.pageTransition: 'assets/sounds/page_turn.mp3',
    SoundEffect.notification: 'assets/sounds/notification.mp3',
    SoundEffect.gavel: 'assets/sounds/gavel.mp3',
    SoundEffect.quillWriting: 'assets/sounds/quill_writing.mp3',
    SoundEffect.paperRustle: 'assets/sounds/paper_rustle.mp3',
    SoundEffect.sealStamp: 'assets/sounds/seal_stamp.mp3',
    SoundEffect.crowdMurmur: 'assets/sounds/crowd_murmur.mp3',
    SoundEffect.bellRing: 'assets/sounds/bell_ring.mp3',
    SoundEffect.voteCount: 'assets/sounds/vote_count.mp3',
    SoundEffect.victory: 'assets/sounds/victory.mp3',
    SoundEffect.dramatic: 'assets/sounds/dramatic.mp3',
    SoundEffect.ambient: 'assets/sounds/ambient.mp3',
    SoundEffect.fireplace: 'assets/sounds/fireplace.mp3',
    SoundEffect.clockTick: 'assets/sounds/clock_tick.mp3',
  };

  bool _isInitialized = false;

  /// 初始化音效服務
  Future<void> init() async {
    await _loadSettings();
    try {
      await _effectPlayer.setVolume(_volume);
      await _ambientPlayer.setVolume(_volume * 0.5); // 環境音較小聲
      _isInitialized = true;
    } catch (e) {
      // 音效插件不可用時（如模擬器）靜默失敗
      _isInitialized = false;
    }
  }

  /// 載入設定
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    _musicEnabled = prefs.getBool('music_enabled') ?? true;
    _hapticEnabled = prefs.getBool('haptic_enabled') ?? true;
    _volume = prefs.getDouble('volume') ?? 0.7;
  }

  /// 儲存設定
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', _soundEnabled);
    await prefs.setBool('music_enabled', _musicEnabled);
    await prefs.setBool('haptic_enabled', _hapticEnabled);
    await prefs.setDouble('volume', _volume);
  }

  /// 播放音效
  Future<void> play(SoundEffect effect) async {
    if (!_soundEnabled || !_isInitialized) return;

    final path = _soundPaths[effect];
    if (path == null) return;

    try {
      await _effectPlayer.stop();
      await _effectPlayer.setAsset(path);
      await _effectPlayer.play();
    } catch (e) {
      // 音效檔案不存在或插件不可用時靜默失敗
    }
  }

  /// 播放環境音樂
  Future<void> playAmbient(SoundEffect effect) async {
    if (!_musicEnabled || !_isInitialized) return;

    final path = _soundPaths[effect];
    if (path == null) return;

    try {
      await _ambientPlayer.setLoopMode(LoopMode.all);
      await _ambientPlayer.setAsset(path);
      await _ambientPlayer.play();
    } catch (e) {
      // 音效檔案不存在或插件不可用時靜默失敗
    }
  }

  /// 停止環境音樂
  Future<void> stopAmbient() async {
    if (!_isInitialized) return;
    try {
      await _ambientPlayer.stop();
    } catch (e) {
      // 插件不可用時靜默失敗
    }
  }

  /// 觸發震動回饋
  Future<void> haptic(HapticType type) async {
    if (!_hapticEnabled) return;

    switch (type) {
      case HapticType.light:
        await HapticFeedback.lightImpact();
        break;
      case HapticType.medium:
        await HapticFeedback.mediumImpact();
        break;
      case HapticType.heavy:
        await HapticFeedback.heavyImpact();
        break;
      case HapticType.selection:
        await HapticFeedback.selectionClick();
        break;
      case HapticType.vibrate:
        await HapticFeedback.vibrate();
        break;
    }
  }

  /// 按鈕點擊回饋 (音效 + 震動)
  Future<void> buttonFeedback() async {
    await Future.wait([
      play(SoundEffect.buttonClick),
      haptic(HapticType.light),
    ]);
  }

  /// 卡片翻轉回饋
  Future<void> cardFlipFeedback() async {
    await Future.wait([
      play(SoundEffect.cardFlip),
      haptic(HapticType.medium),
    ]);
  }

  /// 重要事件回饋
  Future<void> dramaticFeedback() async {
    await Future.wait([
      play(SoundEffect.dramatic),
      haptic(HapticType.heavy),
    ]);
  }

  /// 投票回饋
  Future<void> voteFeedback() async {
    await Future.wait([
      play(SoundEffect.sealStamp),
      haptic(HapticType.medium),
    ]);
  }

  /// 設定音效開關
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    await _saveSettings();
  }

  /// 設定音樂開關
  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    if (!enabled) {
      await stopAmbient();
    }
    await _saveSettings();
  }

  /// 設定震動開關
  Future<void> setHapticEnabled(bool enabled) async {
    _hapticEnabled = enabled;
    await _saveSettings();
  }

  /// 設定音量
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (_isInitialized) {
      try {
        await _effectPlayer.setVolume(_volume);
        await _ambientPlayer.setVolume(_volume * 0.5);
      } catch (e) {
        // 插件不可用時靜默失敗
      }
    }
    await _saveSettings();
  }

  /// 釋放資源
  Future<void> dispose() async {
    try {
      await _effectPlayer.dispose();
      await _ambientPlayer.dispose();
    } catch (e) {
      // 插件不可用時靜默失敗
    }
  }
}

/// 震動類型
enum HapticType {
  light,
  medium,
  heavy,
  selection,
  vibrate,
}

/// 音效服務快捷存取
final soundService = SoundService();
