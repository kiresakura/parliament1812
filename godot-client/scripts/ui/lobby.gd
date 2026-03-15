class_name Lobby
extends Control
## 大廳邏輯
## 負責房間列表、建立房間、快速配對、好友邀請

# === 節點參考 ===
@onready var room_list_container: VBoxContainer = $VBox/ScrollContainer/RoomList
@onready var create_button: Button = $VBox/ButtonBar/CreateButton
@onready var quickmatch_button: Button = $VBox/ButtonBar/QuickmatchButton
@onready var join_code_input: LineEdit = $VBox/JoinBar/CodeInput
@onready var join_button: Button = $VBox/JoinBar/JoinButton
@onready var back_button: Button = $VBox/BackButton
@onready var refresh_button: Button = $VBox/ButtonBar/RefreshButton
@onready var status_label: Label = $VBox/StatusLabel

# === 狀態 ===
var _rooms: Array[Dictionary] = []
var _is_loading: bool = false
var _refresh_timer: Timer = null


func _ready() -> void:
	# 連接按鈕
	if create_button:
		create_button.pressed.connect(_on_create_pressed)
	if quickmatch_button:
		quickmatch_button.pressed.connect(_on_quickmatch_pressed)
	if join_button:
		join_button.pressed.connect(_on_join_pressed)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if refresh_button:
		refresh_button.pressed.connect(_on_refresh_pressed)

	# 自動刷新計時器（每 5 秒）
	_refresh_timer = Timer.new()
	_refresh_timer.wait_time = 5.0
	_refresh_timer.timeout.connect(_refresh_rooms)
	add_child(_refresh_timer)

	# 播放大廳音樂
	AudioManager.play_music(AudioManagerClass.MusicTrack.LOBBY)

	# 載入房間列表
	_refresh_rooms()
	_refresh_timer.start()


func _exit_tree() -> void:
	if _refresh_timer:
		_refresh_timer.stop()


# === 按鈕回調 ===

func _on_create_pressed() -> void:
	AudioManager.play_sfx(AudioManagerClass.SFX.BUTTON_CLICK)
	_set_loading(true, "建立房間中...")
	var room_code: String = await GameManager.create_room()
	_set_loading(false)
	if room_code != "":
		SceneManager.change_scene("res://scenes/lobby/room.tscn")
	else:
		_show_status("建立房間失敗", Color.RED)


func _on_quickmatch_pressed() -> void:
	AudioManager.play_sfx(AudioManagerClass.SFX.BUTTON_CLICK)
	_set_loading(true, "配對中...")
	var success: bool = await GameManager.quickmatch()
	_set_loading(false)
	if success:
		SceneManager.change_scene("res://scenes/lobby/room.tscn")
	else:
		_show_status("配對失敗，請稍後再試", Color.RED)


func _on_join_pressed() -> void:
	if not join_code_input:
		return
	var code: String = join_code_input.text.strip_edges().to_upper()
	if code.length() < 4:
		_show_status("請輸入有效的房間代碼", Color.YELLOW)
		return

	AudioManager.play_sfx(AudioManagerClass.SFX.BUTTON_CLICK)
	_set_loading(true, "加入房間中...")
	var success: bool = await GameManager.join_room(code)
	_set_loading(false)
	if success:
		SceneManager.change_scene("res://scenes/lobby/room.tscn")
	else:
		_show_status("無法加入房間 %s" % code, Color.RED)


func _on_back_pressed() -> void:
	AudioManager.play_sfx(AudioManagerClass.SFX.BUTTON_CLICK)
	SceneManager.go_to_main_menu()


func _on_refresh_pressed() -> void:
	_refresh_rooms()


# === 內部方法 ===

## 刷新房間列表
func _refresh_rooms() -> void:
	if _is_loading:
		return

	var result: Dictionary = await ApiService.rooms_list()
	if result.get("success", false):
		_rooms = result.get("data", {}).get("rooms", [])
		_update_room_list()
	else:
		_show_status("無法取得房間列表", Color.YELLOW)


## 更新房間列表顯示
func _update_room_list() -> void:
	if not room_list_container:
		return

	# 清除舊列表
	for child: Node in room_list_container.get_children():
		child.queue_free()

	if _rooms.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "目前沒有可用的房間"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		room_list_container.add_child(empty_label)
		return

	for room: Dictionary in _rooms:
		var entry: Button = _create_room_entry(room)
		room_list_container.add_child(entry)


## 建立房間列表項目
func _create_room_entry(room: Dictionary) -> Button:
	var btn: Button = Button.new()
	var code: String = room.get("code", "???")
	var player_count: int = room.get("player_count", 0) as int
	var max_players: int = room.get("max_players", 4) as int
	var host_name: String = room.get("host_name", "")
	var status: String = room.get("status", "waiting")

	btn.text = "[%s]  %s 的房間  (%d/%d)  %s" % [
		code, host_name, player_count, max_players,
		"等待中" if status == "waiting" else "遊戲中"
	]
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.disabled = (status != "waiting")
	btn.pressed.connect(func() -> void:
		_join_room(code)
	)
	return btn


## 加入指定房間
func _join_room(code: String) -> void:
	AudioManager.play_sfx(AudioManagerClass.SFX.BUTTON_CLICK)
	_set_loading(true, "加入房間中...")
	var success: bool = await GameManager.join_room(code)
	_set_loading(false)
	if success:
		SceneManager.change_scene("res://scenes/lobby/room.tscn")
	else:
		_show_status("加入房間失敗", Color.RED)


## 設定載入狀態
func _set_loading(loading: bool, message: String = "") -> void:
	_is_loading = loading
	if create_button:
		create_button.disabled = loading
	if quickmatch_button:
		quickmatch_button.disabled = loading
	if join_button:
		join_button.disabled = loading
	if loading and message != "":
		_show_status(message, Color.WHITE)


## 顯示狀態訊息
func _show_status(text: String, color: Color = Color.WHITE) -> void:
	if status_label:
		status_label.text = text
		status_label.add_theme_color_override("font_color", color)
		# 3 秒後自動清除
		await get_tree().create_timer(3.0).timeout
		if status_label and status_label.text == text:
			status_label.text = ""
