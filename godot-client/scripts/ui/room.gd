class_name RoomScene
extends Control
## 房間內等待場景
## 顯示已加入的玩家、準備狀態、房主可啟動遊戲

# === 信號 ===
signal game_starting()

# === 節點參考 ===
@onready var room_code_label: Label = $VBox/TopBar/RoomCodeLabel
@onready var player_list: VBoxContainer = $VBox/PlayerList
@onready var ready_button: Button = $VBox/ButtonBar/ReadyButton
@onready var leave_button: Button = $VBox/ButtonBar/LeaveButton
@onready var start_button: Button = $VBox/ButtonBar/StartButton
@onready var status_label: Label = $VBox/StatusLabel
@onready var chat_log: RichTextLabel = $VBox/ChatLog
@onready var chat_input: LineEdit = $VBox/ChatBar/ChatInput
@onready var chat_send: Button = $VBox/ChatBar/ChatSend

# === 狀態 ===
var _room_code: String = ""
var _players: Array[Dictionary] = []
var _is_ready: bool = false
var _is_host: bool = false


func _ready() -> void:
	# 連接按鈕
	if ready_button:
		ready_button.pressed.connect(_on_ready_pressed)
	if leave_button:
		leave_button.pressed.connect(_on_leave_pressed)
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
		start_button.visible = false
	if chat_send:
		chat_send.pressed.connect(_on_chat_send)
	if chat_input:
		chat_input.text_submitted.connect(_on_chat_submitted)

	# 連接 WebSocket 事件
	WsService.player_joined.connect(_on_player_joined)
	WsService.player_left.connect(_on_player_left)
	WsService.room_state_received.connect(_on_room_state)
	WsService.room_state_updated.connect(_on_room_updated)
	WsService.chat_message.connect(_on_chat_received)
	WsService.game_started.connect(_on_game_started)

	# 載入房間資訊
	_room_code = GameManager.current_room_code
	if room_code_label:
		room_code_label.text = "房間代碼: %s" % _room_code

	_load_room_info()


func _exit_tree() -> void:
	# 斷開 WebSocket 事件
	if WsService.player_joined.is_connected(_on_player_joined):
		WsService.player_joined.disconnect(_on_player_joined)
	if WsService.player_left.is_connected(_on_player_left):
		WsService.player_left.disconnect(_on_player_left)
	if WsService.room_state_received.is_connected(_on_room_state):
		WsService.room_state_received.disconnect(_on_room_state)
	if WsService.room_state_updated.is_connected(_on_room_updated):
		WsService.room_state_updated.disconnect(_on_room_updated)
	if WsService.chat_message.is_connected(_on_chat_received):
		WsService.chat_message.disconnect(_on_chat_received)
	if WsService.game_started.is_connected(_on_game_started):
		WsService.game_started.disconnect(_on_game_started)


# === 按鈕回調 ===

## 切換準備狀態
func _on_ready_pressed() -> void:
	AudioManager.play_sfx(AudioManagerClass.SFX.BUTTON_CLICK)
	_is_ready = not _is_ready
	if _is_ready:
		WsService.send_ready()
	else:
		WsService.send_unready()
	if ready_button:
		ready_button.text = "取消準備" if _is_ready else "準備"


## 離開房間
func _on_leave_pressed() -> void:
	AudioManager.play_sfx(AudioManagerClass.SFX.BUTTON_CLICK)
	await GameManager.leave_room()
	SceneManager.go_to_lobby()


## 房主按下開始
func _on_start_pressed() -> void:
	if not _is_host:
		return
	AudioManager.play_sfx(AudioManagerClass.SFX.BUTTON_CLICK)
	WsService.send_start_game()


## 發送聊天訊息
func _on_chat_send() -> void:
	if chat_input and chat_input.text.strip_edges() != "":
		WsService.send_chat(chat_input.text)
		chat_input.text = ""


## 聊天輸入提交
func _on_chat_submitted(text: String) -> void:
	if text.strip_edges() != "":
		WsService.send_chat(text)
		if chat_input:
			chat_input.text = ""


# === WebSocket 事件 ===

## player_joined: {type, player: {id, name, ...}}
func _on_player_joined(data: Dictionary) -> void:
	var player: Dictionary = data.get("player", {})
	var player_name: String = str(player.get("name", player.get("player_name", "未知")))
	_add_system_message("'%s' 加入了房間" % player_name)
	_load_room_info()


## player_left: {type, player_id, player_name, was_host, new_host_id}
func _on_player_left(data: Dictionary) -> void:
	var player_name: String = str(data.get("player_name", "未知"))
	_add_system_message("'%s' 離開了房間" % player_name)
	_load_room_info()


## room_state: {type, room, players} (初次加入)
func _on_room_state(data: Dictionary) -> void:
	_players.clear()
	var players_arr: Array = data.get("players", [])
	for p: Variant in players_arr:
		if p is Dictionary:
			_players.append(p as Dictionary)
	_update_player_list()
	_check_host()


## room_update: {type, room, players, update_type, related_player_id}
func _on_room_updated(data: Dictionary) -> void:
	_players.clear()
	var players_arr: Array = data.get("players", [])
	for p: Variant in players_arr:
		if p is Dictionary:
			_players.append(p as Dictionary)
	_update_player_list()
	_check_host()


## chat_message: {type, from_id, from_name, content, is_private, timestamp}
func _on_chat_received(data: Dictionary) -> void:
	var sender: String = str(data.get("from_name", "???"))
	var content: String = str(data.get("content", ""))
	if chat_log:
		chat_log.append_text("[color=#C9A84C]%s[/color]: %s\n" % [sender, content])


func _on_game_started(_data: Dictionary) -> void:
	game_starting.emit()


# === 內部方法 ===

## 載入房間資訊
func _load_room_info() -> void:
	if _room_code == "":
		return
	var result: Dictionary = await ApiService.rooms_get(_room_code)
	if result.get("success", false):
		var room_data: Dictionary = result.get("data", {})
		_players = room_data.get("players", [])
		_update_player_list()
		_check_host()


## 更新玩家列表
func _update_player_list() -> void:
	if not player_list:
		return
	for child: Node in player_list.get_children():
		child.queue_free()

	for player: Dictionary in _players:
		var entry: HBoxContainer = HBoxContainer.new()
		entry.add_theme_constant_override("separation", 8)

		# 房主標記
		if player.get("is_host", false):
			var crown: Label = Label.new()
			crown.text = "👑"
			entry.add_child(crown)

		# 玩家名稱
		var name_lbl: Label = Label.new()
		name_lbl.text = str(player.get("name", player.get("username", player.get("player_name", ""))))
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		entry.add_child(name_lbl)

		# 準備狀態
		var ready_lbl: Label = Label.new()
		var is_player_ready: bool = player.get("is_ready", false)
		ready_lbl.text = "✓ 已準備" if is_player_ready else "等待中"
		ready_lbl.add_theme_color_override("font_color",
			Color(0.2, 0.8, 0.2) if is_player_ready else Color(0.5, 0.5, 0.5)
		)
		entry.add_child(ready_lbl)

		player_list.add_child(entry)

	if status_label:
		status_label.text = "%d/4 位玩家" % _players.size()


## 檢查是否為房主
func _check_host() -> void:
	var local_id: String = AuthService.get_user_id()
	_is_host = false
	for player: Dictionary in _players:
		if player.get("id", "") == local_id and player.get("is_host", false):
			_is_host = true
			break
	if start_button:
		start_button.visible = _is_host


## 加入系統訊息
func _add_system_message(text: String) -> void:
	if chat_log:
		chat_log.append_text("[color=#888888][%s][/color]\n" % text)
