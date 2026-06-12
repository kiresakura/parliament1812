class_name AudioManagerClass
extends Node
## 音效管理（Autoload）
## 負責背景音樂、音效播放、音量控制

# === 常數 ===
const MUSIC_BUS: String = "Music"
const SFX_BUS: String = "SFX"
const FADE_DURATION: float = 1.0

# === 信號 ===
signal music_changed(track_name: String)

# === 音軌定義 ===
enum MusicTrack {
	NONE,
	MAIN_MENU,
	LOBBY,
	IN_GAME,
	GAME_OVER,
	CAMPAIGN,
}

# === 音效定義 ===
enum SFX {
	CARD_PLAY,
	CARD_FLIP,
	CARD_DRAW,
	CARD_IMPACT,
	VOTE_CAST,
	VOTE_PASS_1,
	VOTE_PASS_2,
	VOTE_PASS_3,
	VOTE_FAIL,
	BUTTON_CLICK,
	BUTTON_HOVER,
	NOTIFICATION,
	VICTORY,
	DEFEAT,
	TIMER_TICK,
	TIMER_URGENT,
	COIN_COLLECT,
	GAVEL,
	QUILL_WRITING,
	SCENE_TRANSITION,
	CHALLENGE,
}

# === 音效路徑映射 ===
var _music_paths: Dictionary = {
	MusicTrack.MAIN_MENU: "res://assets/audio/music_main_menu.ogg",
	MusicTrack.LOBBY: "res://assets/audio/music_lobby.ogg",
	MusicTrack.IN_GAME: "res://assets/audio/music_in_game.ogg",
	MusicTrack.GAME_OVER: "res://assets/audio/music_game_over.ogg",
	MusicTrack.CAMPAIGN: "res://assets/audio/music_campaign.ogg",
}

var _sfx_paths: Dictionary = {
	SFX.CARD_PLAY: "res://assets/audio/sfx_card_play.ogg",
	SFX.CARD_FLIP: "res://assets/audio/sfx_card_flip.ogg",
	SFX.CARD_DRAW: "res://assets/audio/sfx_card_draw.ogg",
	SFX.CARD_IMPACT: "res://assets/audio/sfx_card_play.ogg",      # 共用 card_play
	SFX.VOTE_CAST: "res://assets/audio/sfx_vote_cast.ogg",
	SFX.VOTE_PASS_1: "res://assets/audio/sfx_vote_pass_1.ogg",
	SFX.VOTE_PASS_2: "res://assets/audio/sfx_vote_pass_2.ogg",
	SFX.VOTE_PASS_3: "res://assets/audio/sfx_vote_pass_3.ogg",
	SFX.VOTE_FAIL: "res://assets/audio/sfx_vote_fail.ogg",
	SFX.BUTTON_CLICK: "res://assets/audio/sfx_button_click.ogg",
	SFX.BUTTON_HOVER: "res://assets/audio/sfx_button_hover.ogg",
	SFX.NOTIFICATION: "res://assets/audio/sfx_notification.ogg",
	SFX.VICTORY: "res://assets/audio/sfx_victory.ogg",
	SFX.DEFEAT: "res://assets/audio/sfx_defeat.ogg",
	SFX.TIMER_TICK: "res://assets/audio/sfx_timer_tick.ogg",
	SFX.TIMER_URGENT: "res://assets/audio/sfx_timer_urgent.ogg",
	SFX.COIN_COLLECT: "res://assets/audio/sfx_coin_collect.ogg",
	SFX.GAVEL: "res://assets/audio/sfx_gavel.ogg",
	SFX.QUILL_WRITING: "res://assets/audio/sfx_quill_writing.ogg",
	SFX.SCENE_TRANSITION: "res://assets/audio/sfx_scene_transition.ogg",
	SFX.CHALLENGE: "res://assets/audio/sfx_challenge.ogg",
}

# === 播放器 ===
var _music_player: AudioStreamPlayer = null
var _sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS: int = 8

# === 狀態 ===
var _current_track: MusicTrack = MusicTrack.NONE
var _music_volume: float = 0.8
var _sfx_volume: float = 1.0
var _is_fading: bool = false
var _sfx_cache: Dictionary = {}

# === 字串名稱 → SFX enum 映射 ===
var _sfx_name_map: Dictionary = {
	"card_play": SFX.CARD_PLAY,
	"card_flip": SFX.CARD_FLIP,
	"card_draw": SFX.CARD_DRAW,
	"card_impact": SFX.CARD_IMPACT,
	"vote_cast": SFX.VOTE_CAST,
	"vote_pass_1": SFX.VOTE_PASS_1,
	"vote_pass_2": SFX.VOTE_PASS_2,
	"vote_pass_3": SFX.VOTE_PASS_3,
	"vote_fail": SFX.VOTE_FAIL,
	"button_click": SFX.BUTTON_CLICK,
	"button_hover": SFX.BUTTON_HOVER,
	"notification": SFX.NOTIFICATION,
	"victory": SFX.VICTORY,
	"defeat": SFX.DEFEAT,
	"timer_tick": SFX.TIMER_TICK,
	"timer_urgent": SFX.TIMER_URGENT,
	"coin_collect": SFX.COIN_COLLECT,
	"gavel": SFX.GAVEL,
	"quill_writing": SFX.QUILL_WRITING,
	"scene_transition": SFX.SCENE_TRANSITION,
	"challenge": SFX.CHALLENGE,
}


func _ready() -> void:
	# 建立音樂播放器
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = MUSIC_BUS
	add_child(_music_player)

	# 建立音效播放器池
	for i: int in range(MAX_SFX_PLAYERS):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = SFX_BUS
		add_child(player)
		_sfx_players.append(player)

	# 設定音量
	_apply_volumes()


# === 公開方法 ===

## 播放背景音樂
func play_music(track: MusicTrack, fade: bool = true) -> void:
	if track == _current_track and _music_player.playing:
		return
	if track == MusicTrack.NONE:
		stop_music(fade)
		return

	var path: String = _music_paths.get(track, "")
	if path == "":
		push_warning("[AudioManager] 未知音軌: %d" % track)
		return

	# 檢查資源是否存在
	if not ResourceLoader.exists(path):
		push_warning("[AudioManager] 音檔不存在: %s（跳過）" % path)
		_current_track = track
		return

	if fade and _music_player.playing:
		await _fade_out()

	var stream: AudioStream = load(path) as AudioStream
	if stream:
		_music_player.stream = stream
		_music_player.play()
		_current_track = track
		if fade:
			await _fade_in()
		music_changed.emit(MusicTrack.keys()[track])


## 停止背景音樂
func stop_music(fade: bool = true) -> void:
	if not _music_player.playing:
		return
	if fade:
		await _fade_out()
	_music_player.stop()
	_current_track = MusicTrack.NONE


## 播放音效（接受 SFX enum 或字串名稱，向後相容）
func play_sfx(sfx: Variant) -> void:
	# 支援字串呼叫：自動轉換為 enum
	if sfx is String:
		play_sfx_by_name(sfx as String)
		return

	var sfx_enum: SFX = sfx as SFX
	var path: String = _sfx_paths.get(sfx_enum, "")
	if path == "":
		return

	# 檢查資源是否存在
	if not ResourceLoader.exists(path):
		return

	# 從快取載入或載入新的
	var stream: AudioStream
	if _sfx_cache.has(sfx_enum):
		stream = _sfx_cache[sfx_enum]
	else:
		stream = load(path) as AudioStream
		if stream:
			_sfx_cache[sfx_enum] = stream

	if not stream:
		return

	# 找到可用的播放器
	var player: AudioStreamPlayer = _get_available_sfx_player()
	if player:
		player.stream = stream
		player.play()


## 透過字串名稱播放音效
func play_sfx_by_name(sfx_name: String) -> void:
	if _sfx_name_map.has(sfx_name):
		play_sfx(_sfx_name_map[sfx_name])
	else:
		push_warning("[AudioManager] Unknown SFX name: %s" % sfx_name)


## 設定音樂音量（0.0 ~ 1.0）
func set_music_volume(volume: float) -> void:
	_music_volume = clampf(volume, 0.0, 1.0)
	_apply_volumes()


## 設定音效音量（0.0 ~ 1.0）
func set_sfx_volume(volume: float) -> void:
	_sfx_volume = clampf(volume, 0.0, 1.0)
	_apply_volumes()


## 取得音樂音量
func get_music_volume() -> float:
	return _music_volume


## 取得音效音量
func get_sfx_volume() -> float:
	return _sfx_volume


# === 內部方法 ===

## 取得可用的音效播放器
func _get_available_sfx_player() -> AudioStreamPlayer:
	for player: AudioStreamPlayer in _sfx_players:
		if not player.playing:
			return player
	# 全部都在用，返回第一個（搶佔）
	return _sfx_players[0]


## 套用音量設定
func _apply_volumes() -> void:
	var music_db: float = linear_to_db(_music_volume) if _music_volume > 0 else -80.0
	var sfx_db: float = linear_to_db(_sfx_volume) if _sfx_volume > 0 else -80.0
	_music_player.volume_db = music_db
	for player: AudioStreamPlayer in _sfx_players:
		player.volume_db = sfx_db


## 淡出音樂
func _fade_out() -> void:
	if _is_fading:
		return
	_is_fading = true
	var tween: Tween = create_tween()
	tween.tween_property(_music_player, "volume_db", -80.0, FADE_DURATION)
	await tween.finished
	_is_fading = false


## 淡入音樂
func _fade_in() -> void:
	if _is_fading:
		return
	_is_fading = true
	var target_db: float = linear_to_db(_music_volume) if _music_volume > 0 else -80.0
	_music_player.volume_db = -80.0
	var tween: Tween = create_tween()
	tween.tween_property(_music_player, "volume_db", target_db, FADE_DURATION)
	await tween.finished
	_is_fading = false
