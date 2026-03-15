class_name RoomListPanel
extends Control
## 房間內等待邏輯
## 負責顯示房間內玩家、準備狀態、聊天

# === 信號 ===
signal all_players_ready()
signal player_left_room()

# === 節點參考 ===
@onready var room_code_label: Label = $VBox/RoomCodeLabel
@onready var player_list: VBoxContainer = $VBox/PlayerList
@onready var ready_button: Button = $VBox/ButtonBar/ReadyButton
@onready var leave_button: Button = $VBox/ButtonBar/LeaveButton
@onready var start_button: Button = $VBox/ButtonBar/StartButton
@onready var chat_input: LineEdit = $VBox/ChatBar/ChatInput
@onready var chat_send: Button = $VBox/ChatBar/ChatSend
@onready var chat_log: RichTextLabel = $VBox/ChatLog
@onready var status_label: Label = $VBox/StatusLabel

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
		start_button.visible = false  # 只有房主可見
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
	# 斷開 WS 事件
	if WsService.player_joined.is_connected(_on_player_joined):
		WsService.player_joined.disconnect(_on_player_joined)
	if WsService.player_left.is_connected(_on_player_left):
		WsService.player_left.disconnect(_on_player_left)


# === 按鈕回調 ===

func _on_ready_pressed() -> void:
	AudioManager.play_sfx(AudioManagerClass.SFX.BUTTON_CLICK)
	_is_ready = not _is_ready
	if _is_ready:
		WsService.send_ready()
	else:
		WsService.send_unready()
	if ready_button:
		ready_button.text = "取消準備" if _is_ready else "準備"


func _on_leave_pressed() -> void:
	AudioManager.play_sfx(AudioManagerClass.SFX.BUTTON_CLICK)
	await GameManager.leave_room()
	player_left_room.emit()
	SceneManager.go_to_lobby()


func _on_start_pressed() -> void:
	if not _is_host:
		return
	AudioManager.play_sfx(AudioManagerClass.SFX.BUTTON_CLICK)
	WsService.send_start_game()


func _on_chat_send() -> void:
	if chat_input and chat_input.text.strip_edges() != "":
		WsService.send_chat(chat_input.text)
		chat_input.text = ""


func _on_chat_submitted(text: String) -> void:
	if text.strip_edges() != "":
		WsService.send_chat(text)
		chat_input.text = ""


# === WebSocket 事件 ===

## 玩家加入（server: player_joined → {type, player: {id, name, ...}}）
func _on_player_joined(data: Dictionary) -> void:
	var player: Dictionary = data.get("player", {})
	var player_name: String = str(player.get("name", player.get("player_name", "未知")))
	_add_chat_system("'%s' 加入了房間" % player_name)
	_load_room_info()


## 玩家離開（server: player_left → {type, player_id, player_name, ...}）
func _on_player_left(data: Dictionary) -> void:
	var player_name: String = str(data.get("player_name", "未知"))
	_add_chat_system("'%s' 離開了房間" % player_name)
	_load_room_info()


## 初次收到完整房間狀態（server: room_state → {type, room, players}）
func _on_room_state(data: Dictionary) -> void:
	_players.clear()
	var players_arr: Array = data.get("players", [])
	for p: Variant in players_arr:
		if p is Dictionary:
			_players.append(p as Dictionary)
	_update_player_list()
	_check_host_status()


## 房間狀態更新（server: room_update → {type, room, players, update_type, ...}）
func _on_room_updated(data: Dictionary) -> void:
	_players.clear()
	var players_arr: Array = data.get("players", [])
	for p: Variant in players_arr:
		if p is Dictionary:
			_players.append(p as Dictionary)
	_update_player_list()
	_check_host_status()


## 聊天（server: chat_message → {type, from_id, from_name, content, is_private, ...}）
func _on_chat_received(data: Dictionary) -> void:
	var sender: String = str(data.get("from_name", "???"))
	var content: String = str(data.get("content", ""))
	var is_private: bool = data.get("is_private", false)
	if is_private:
		_add_chat_message("[私訊] %s" % sender, content)
	else:
		_add_chat_message(sender, content)


func _on_game_started(_data: Dictionary) -> void:
	# GameManager 會處理場景切換
	pass


# === 內部方法 ===

## 載入房間資訊
func _load_room_info() -> void:
	if _room_code == "":
		return
	var result: Dictionary = await ApiService.rooms_get(_room_code)
	if result.get("success", false):
		var room_data: Dictionary = result.get("data", {})
		_players.clear()
		var players_arr: Array = room_data.get("players", [])
		for p: Variant in players_arr:
			if p is Dictionary:
				_players.append(p as Dictionary)
		_update_player_list()
		_check_host_status()


## 更新玩家列表（server player fields: id, name, is_host, is_ready）
func _update_player_list() -> void:
	if not player_list:
		return

	for child: Node in player_list.get_children():
		child.queue_free()

	for player: Dictionary in _players:
		var entry: HBoxContainer = HBoxContainer.new()

		# 玩家名稱（server 用 "name"；API 可能用 "username"，都試）
		var name_lbl: Label = Label.new()
		name_lbl.text = str(player.get("name", player.get("username", player.get("player_name", ""))))
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		entry.add_child(name_lbl)

		# 房主標記
		if player.get("is_host", false):
			var host_lbl: Label = Label.new()
			host_lbl.text = "👑"
			entry.add_child(host_lbl)

		# 準備狀態
		var ready_lbl: Label = Label.new()
		ready_lbl.text = "✓ 已準備" if player.get("is_ready", false) else "等待中"
		ready_lbl.add_theme_color_override("font_color",
			Color(0.2, 0.8, 0.2) if player.get("is_ready", false) else Color(0.5, 0.5, 0.5)
		)
		entry.add_child(ready_lbl)

		player_list.add_child(entry)

	if status_label:
		status_label.text = "%d/4 位玩家" % _players.size()


## 檢查是否為房主
func _check_host_status() -> void:
	var local_id: String = AuthService.get_user_id()
	_is_host = false
	for player: Dictionary in _players:
		if str(player.get("id", "")) == local_id and player.get("is_host", false):
			_is_host = true
			break
	if start_button:
		start_button.visible = _is_host


## 新增聊天訊息
func _add_chat_message(sender: String, text: String) -> void:
	if chat_log:
		chat_log.append_text("[color=#C9A84C]%s[/color]: %s\n" % [sender, text])


## 新增系統訊息
func _add_chat_system(text: String) -> void:
	if chat_log:
		chat_log.append_text("[color=#888888][%s][/color]\n" % text)
