import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';

/// BGM 類型
enum BgmType {
  menu('bgm/menu', '主選單'),
  game('bgm/game', '遊戲中'),
  result('bgm/result', '結算');

  final String assetPath;
  final String displayName;
  const BgmType(this.assetPath, this.displayName);
}

/// SFX 類型
enum SfxType {
  cardPlay('sfx/card_play', '出牌'),
  vote('sfx/vote', '投票'),
  victory('sfx/victory', '勝利'),
  defeat('sfx/defeat', '失敗'),
  reputationUp('sfx/reputation_up', '聲望上升'),
  reputationDown('sfx/reputation_down', '聲望下降');

  final String assetPath;
  final String displayName;
  const SfxType(this.assetPath, this.displayName);
}

/// 音頻服務 — BGM + SFX 管理
class AudioService {
  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _bgmEnabled = true;
  bool _sfxEnabled = true;
  double _bgmVolume = 0.5;
  double _sfxVolume = 0.7;
  BgmType? _currentBgm;

  // Audio files are placeholder — actual playback will work once
  // real audio files (.mp3/.ogg) are placed in assets/audio/
  bool _hasRealAssets = false;

  bool get bgmEnabled => _bgmEnabled;
  bool get sfxEnabled => _sfxEnabled;
  double get bgmVolume => _bgmVolume;
  double get sfxVolume => _sfxVolume;
  BgmType? get currentBgm => _currentBgm;

  AudioService() {
    _bgmPlayer.setReleaseMode(ReleaseMode.loop);
  }

  /// 從 SharedPreferences 載入設定
  Future<void> loadSettings(SharedPreferences prefs) async {
    _bgmEnabled = prefs.getBool('audio_bgm_enabled') ?? true;
    _sfxEnabled = prefs.getBool('audio_sfx_enabled') ?? true;
    _bgmVolume = prefs.getDouble('audio_bgm_volume') ?? 0.5;
    _sfxVolume = prefs.getDouble('audio_sfx_volume') ?? 0.7;
  }

  /// 儲存設定到 SharedPreferences
  Future<void> _saveSettings(SharedPreferences prefs) async {
    await prefs.setBool('audio_bgm_enabled', _bgmEnabled);
    await prefs.setBool('audio_sfx_enabled', _sfxEnabled);
    await prefs.setDouble('audio_bgm_volume', _bgmVolume);
    await prefs.setDouble('audio_sfx_volume', _sfxVolume);
  }

  /// 播放 BGM
  Future<void> playBgm(BgmType bgm) async {
    if (!_bgmEnabled || !_hasRealAssets) return;
    if (_currentBgm == bgm) return; // 同一首不重複播

    _currentBgm = bgm;
    try {
      await _bgmPlayer.setVolume(_bgmVolume);
      await _bgmPlayer.play(AssetSource('audio/${bgm.assetPath}.mp3'));
    } catch (e) {
      // Audio file not found — expected with placeholder assets
    }
  }

  /// 停止 BGM
  Future<void> stopBgm() async {
    _currentBgm = null;
    await _bgmPlayer.stop();
  }

  /// 暫停 BGM
  Future<void> pauseBgm() async {
    await _bgmPlayer.pause();
  }

  /// 恢復 BGM
  Future<void> resumeBgm() async {
    if (_bgmEnabled && _currentBgm != null) {
      await _bgmPlayer.resume();
    }
  }

  /// 播放音效
  Future<void> playSfx(SfxType sfx) async {
    if (!_sfxEnabled || !_hasRealAssets) return;

    try {
      await _sfxPlayer.setVolume(_sfxVolume);
      await _sfxPlayer.play(AssetSource('audio/${sfx.assetPath}.mp3'));
    } catch (e) {
      // Audio file not found — expected with placeholder assets
    }
  }

  /// 設定 BGM 啟用/停用
  Future<void> setBgmEnabled(bool enabled, SharedPreferences prefs) async {
    _bgmEnabled = enabled;
    if (!enabled) {
      await stopBgm();
    }
    await _saveSettings(prefs);
  }

  /// 設定 SFX 啟用/停用
  Future<void> setSfxEnabled(bool enabled, SharedPreferences prefs) async {
    _sfxEnabled = enabled;
    await _saveSettings(prefs);
  }

  /// 設定 BGM 音量
  Future<void> setBgmVolume(double volume, SharedPreferences prefs) async {
    _bgmVolume = volume.clamp(0.0, 1.0);
    await _bgmPlayer.setVolume(_bgmVolume);
    await _saveSettings(prefs);
  }

  /// 設定 SFX 音量
  Future<void> setSfxVolume(double volume, SharedPreferences prefs) async {
    _sfxVolume = volume.clamp(0.0, 1.0);
    await _saveSettings(prefs);
  }

  /// 啟用真實音檔播放（當音檔放入後呼叫）
  void enableRealAssets() {
    _hasRealAssets = true;
  }

  /// 釋放資源
  Future<void> dispose() async {
    await _bgmPlayer.dispose();
    await _sfxPlayer.dispose();
  }
}

/// AudioService 全域 Provider
final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();

  // 嘗試載入設定
  final prefs = ref.watch(sharedPreferencesProvider);
  service.loadSettings(prefs);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});
