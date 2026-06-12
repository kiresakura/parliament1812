class_name GameManagerClass
extends Node
## 遊戲全局管理（Autoload）
## 負責遊戲狀態、玩家快取、全域事件

# === 信號 ===
signal game_state_changed(new_state: GameState)
signal player_data_updated(player: Dictionary)
signal room_joined(room_code: String)
signal room_left()

# === 遊戲狀態列舉 ===
enum GameState {
	IDLE,        # 閒置（主選單/大廳）
	IN_LOBBY,    # 在房間等待中
	IN_GAME,     # 遊戲進行中
	GAME_OVER,   # 遊戲結束
}

# === 狀態 ===
var current_state: GameState = GameState.IDLE
var current_room_code: String = ""
var current_game_data: Dictionary = {}
var cached_player: Dictionary = {}

# === 派系選擇（Phase 1 核心循環） ===
var selected_faction: FactionData = null

# === 設定 ===
var settings: Dictionary = {
	"music_volume": 0.8,
	"sfx_volume": 1.0,
	"language": "zh_TW",
	"notifications": true,
}

const SETTINGS_PATH: String = "user://settings.cfg"
var _settings_config: ConfigFile = ConfigFile.new()


func _ready() -> void:
	_load_settings()
	# 監聽 WebSocket 事件
	WsService.server_connected.connect(_on_ws_connected)
	WsService.game_started.connect(_on_game_started)
	WsService.game_ended.connect(_on_game_ended)
	WsService.room_state_received.connect(_on_room_state)
	WsService.room_state_updated.connect(_on_room_updated)
	WsService.reconnect_data.connect(_on_reconnect_data)
	# 監聯認證事件
	AuthService.login_succeeded.connect(_on_login_succeeded)
	AuthService.logout_completed.connect(_on_logout)


# === 公開方法 ===

## 切換遊戲狀態
func set_state(new_state: GameState) -> void:
	var old_state: GameState = current_state
	current_state = new_state
	game_state_changed.emit(new_state)
	print("[GameManager] 狀態: %s → %s" % [GameState.keys()[old_state], GameState.keys()[new_state]])


## 加入房間
func join_room(room_code: String) -> bool:
	var result: Dictionary = await ApiService.rooms_join(room_code)
	if result.get("success", false):
		current_room_code = room_code
		set_state(GameState.IN_LOBBY)
		WsService.connect_to_room(room_code)
		room_joined.emit(room_code)
		return true
	return false


## 建立房間
func create_room() -> String:
	var result: Dictionary = await ApiService.rooms_create()
	if result.get("success", false):
		var room_data: Dictionary = result.get("data", {})
		current_room_code = room_data.get("code", "")
		if current_room_code != "":
			set_state(GameState.IN_LOBBY)
			WsService.connect_to_room(current_room_code)
			room_joined.emit(current_room_code)
		return current_room_code
	return ""


## 快速配對
func quickmatch() -> bool:
	var result: Dictionary = await ApiService.rooms_quickmatch()
	if result.get("success", false):
		var room_data: Dictionary = result.get("data", {})
		current_room_code = room_data.get("code", "")
		if current_room_code != "":
			set_state(GameState.IN_LOBBY)
			WsService.connect_to_room(current_room_code)
			room_joined.emit(current_room_code)
		return true
	return false


## 離開房間
func leave_room() -> void:
	if current_room_code != "":
		WsService.send_leave_room()
		WsService.disconnect_ws()
		current_room_code = ""
		current_game_data = {}
		set_state(GameState.IDLE)
		room_left.emit()


## 取得遊戲設定
func get_setting(key: String, default_value: Variant = null) -> Variant:
	return settings.get(key, default_value)


## 更新設定
func update_setting(key: String, value: Variant) -> void:
	settings[key] = value
	_save_settings()
	# 即時套用音量設定
	if key == "music_volume":
		AudioManager.set_music_volume(value as float)
	elif key == "sfx_volume":
		AudioManager.set_sfx_volume(value as float)


# === 內部方法 ===

## WebSocket 連線成功後收到 connected 訊息
func _on_ws_connected(data: Dictionary) -> void:
	var server_version: String = str(data.get("server_version", ""))
	var player_id: String = str(data.get("player_id", ""))
	print("[GameManager] 伺服器版本: %s, 玩家 ID: %s" % [server_version, player_id])

	# 如果有待加入的房間，發送 join_room
	if current_room_code != "":
		var player_name: String = str(cached_player.get("username", cached_player.get("name", "Player")))
		WsService.send_join_room(current_room_code, player_name)


## 收到完整房間狀態（初次加入）
func _on_room_state(data: Dictionary) -> void:
	var room: Dictionary = data.get("room", {})
	var players: Array = data.get("players", [])
	current_game_data["room"] = room
	current_game_data["players"] = players
	print("[GameManager] 收到房間狀態，玩家數: %d" % players.size())


## 房間狀態更新（玩家加入/離開等）
func _on_room_updated(data: Dictionary) -> void:
	var room: Dictionary = data.get("room", {})
	var players: Array = data.get("players", [])
	current_game_data["room"] = room
	current_game_data["players"] = players


## 重連數據
func _on_reconnect_data(data: Dictionary) -> void:
	var room: Dictionary = data.get("room", {})
	var players: Array = data.get("players", [])
	current_game_data["room"] = room
	current_game_data["players"] = players
	var game_state: Variant = data.get("game_state", null)
	if game_state != null and game_state is Dictionary:
		current_game_data.merge(game_state as Dictionary, true)
		set_state(GameState.IN_GAME)
	print("[GameManager] 重連數據已恢復")


## 遊戲開始回調
func _on_game_started(data: Dictionary) -> void:
	current_game_data.merge(data, true)
	set_state(GameState.IN_GAME)
	SceneManager.change_scene("res://scenes/game/game_board.tscn")


## 遊戲結束回調
func _on_game_ended(data: Dictionary) -> void:
	current_game_data.merge(data, true)
	set_state(GameState.GAME_OVER)
	SceneManager.change_scene("res://scenes/game/result_screen.tscn")


## 登入成功回調
func _on_login_succeeded(user: Dictionary) -> void:
	cached_player = user
	player_data_updated.emit(user)


## 登出回調
func _on_logout() -> void:
	cached_player = {}
	current_room_code = ""
	current_game_data = {}
	set_state(GameState.IDLE)


## 儲存設定
func _save_settings() -> void:
	for key: String in settings:
		_settings_config.set_value("settings", key, settings[key])
	_settings_config.save(SETTINGS_PATH)


## 載入設定
func _load_settings() -> void:
	var err: int = _settings_config.load(SETTINGS_PATH)
	if err == OK:
		for key: String in settings:
			settings[key] = _settings_config.get_value("settings", key, settings[key])
