class_name DifficultySelect
extends Control
## 難度選擇畫面
## 選擇後呼叫 API 開始單人模式，拿到 game state 後進入 game_board

# === 節點參考 ===
@onready var title_label: Label = $VBox/TitleLabel
@onready var easy_button: Button = $VBox/ButtonBox/EasyButton
@onready var normal_button: Button = $VBox/ButtonBox/NormalButton
@onready var hard_button: Button = $VBox/ButtonBox/HardButton
@onready var back_button: Button = $VBox/BackButton
@onready var status_label: Label = $VBox/StatusLabel

# === Mock 數據（離線模式用）===
const MOCK_HAND: Array[Dictionary] = [
	{"id": "mock_1", "name": "減稅提案", "description": "降低關稅以促進貿易。贊成票+2。", "type": 0, "rarity": 0, "cost": 1, "power": 2, "influence": 1, "effects": []},
	{"id": "mock_2", "name": "軍事結盟", "description": "與鄰國簽訂軍事協議。", "type": 2, "rarity": 1, "cost": 2, "power": 3, "influence": 2, "effects": []},
	{"id": "mock_3", "name": "激烈辯論", "description": "在議場上發表激烈演說。對手贊成票-1。", "type": 1, "rarity": 0, "cost": 1, "power": 1, "influence": 1, "effects": []},
	{"id": "mock_4", "name": "秘密策略", "description": "暗中操作投票結果。", "type": 3, "rarity": 2, "cost": 3, "power": 4, "influence": 3, "effects": []},
	{"id": "mock_5", "name": "經濟改革", "description": "提出全面的經濟改革方案。", "type": 0, "rarity": 3, "cost": 4, "power": 5, "influence": 4, "effects": []},
]

const MOCK_PLAYERS: Array[Dictionary] = [
	{"id": "local_player", "username": "你", "score": 0, "is_ai": false},
	{"id": "ai_easy", "username": "AI 議員", "score": 0, "is_ai": true},
]


func _ready() -> void:
	# 連接按鈕
	if easy_button:
		easy_button.pressed.connect(_on_easy_pressed)
	if normal_button:
		normal_button.pressed.connect(_on_normal_pressed)
	if hard_button:
		hard_button.pressed.connect(_on_hard_pressed)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

	if status_label:
		status_label.text = ""

	# 入場動畫
	_play_entrance_animation()


func _on_easy_pressed() -> void:
	AudioManager.play_sfx(AudioManagerClass.SFX.BUTTON_CLICK)
	await _start_single_game("easy")


func _on_normal_pressed() -> void:
	AudioManager.play_sfx(AudioManagerClass.SFX.BUTTON_CLICK)
	await _start_single_game("normal")


func _on_hard_pressed() -> void:
	AudioManager.play_sfx(AudioManagerClass.SFX.BUTTON_CLICK)
	await _start_single_game("hard")


func _on_back_pressed() -> void:
	AudioManager.play_sfx(AudioManagerClass.SFX.BUTTON_CLICK)
	SceneManager.go_to_main_menu()


## 開始單人遊戲
func _start_single_game(difficulty: String) -> void:
	_set_buttons_disabled(true)
	if status_label:
		status_label.text = "正在連接伺服器..."

	# 確保已登入
	if not AuthService.is_authenticated() and not AuthService.is_logged_in:
		if status_label:
			status_label.text = "正在建立訪客帳號..."
		var guest_result: Dictionary = await ApiService.post_request("/api/v1/auth/guest", {})
		if guest_result.get("success", false):
			var data: Dictionary = guest_result.get("data", {})
			if data.has("access_token"):
				ApiService.set_tokens(
					data.get("access_token", ""),
					data.get("refresh_token", ""),
					int(Time.get_unix_time_from_system()) + data.get("expires_in", 3600)
				)
				AuthService.is_logged_in = true
				AuthService.current_user = data.get("user", {"username": "訪客"})

	# 嘗試呼叫 API 開始遊戲，失敗則用 mock
	var game_data: Dictionary = {}
	var use_mock := false

	if AuthService.is_authenticated() and ApiService.has_token():
		if status_label:
			status_label.text = "正在建立遊戲..."
		var result: Dictionary = await ApiService.post_request("/api/v1/single/start", {
			"difficulty": difficulty,
		}, true)
		if result.get("success", false):
			game_data = result.get("data", {})
			game_data["mode"] = "single"
			game_data["difficulty"] = difficulty
		else:
			use_mock = true
			print("[DifficultySelect] API 失敗，使用 mock 數據: %s" % result.get("error", "未知"))
	else:
		use_mock = true
		print("[DifficultySelect] 離線模式，直接使用 mock 數據")

	if use_mock:
		if status_label:
			status_label.text = "離線模式 — 使用模擬數據"
		await get_tree().create_timer(0.3).timeout
		game_data = _generate_mock_game_data(difficulty)

	GameManager.current_game_data = game_data

	if status_label:
		status_label.text = "選擇派系..."

	print("[DifficultySelect] 準備切換到 faction_select...")
	_deferred_change_scene.call_deferred()


func _deferred_change_scene() -> void:
	print("[DifficultySelect] 執行場景切換到 faction_select...")
	var err := get_tree().change_scene_to_file("res://scenes/game/faction_select.tscn")
	if err != OK:
		push_error("[DifficultySelect] 場景載入失敗! err=%d" % err)
	else:
		print("[DifficultySelect] change_scene_to_file 回傳 OK")


## 生成 mock 遊戲數據
func _generate_mock_game_data(difficulty: String) -> Dictionary:
	var ai_name: String = "AI 議員"
	match difficulty:
		"easy":
			ai_name = "菜鳥議員"
		"normal":
			ai_name = "資深議員"
		"hard":
			ai_name = "議長大人"

	var mock_players: Array[Dictionary] = [
		{"id": "local_player", "username": AuthService.current_user.get("username", "玩家"), "score": 0, "is_ai": false},
		{"id": "ai_opponent", "username": ai_name, "score": 0, "is_ai": true},
	]

	return {
		"mode": "single",
		"difficulty": difficulty,
		"session_id": "mock_session_%d" % randi(),
		"phase": GameStateData.Phase.PROPOSAL,
		"round": 1,
		"max_rounds": 5,
		"players": mock_players,
		"current_player_index": 0,
		"hand": MOCK_HAND.duplicate(true),
		"scores": {"local_player": 0, "ai_opponent": 0},
		"time_remaining": 60.0,
		"is_mock": true,
	}


## 禁用/啟用所有按鈕
func _set_buttons_disabled(disabled: bool) -> void:
	if easy_button:
		easy_button.disabled = disabled
	if normal_button:
		normal_button.disabled = disabled
	if hard_button:
		hard_button.disabled = disabled
	if back_button:
		back_button.disabled = disabled


## 入場動畫
func _play_entrance_animation() -> void:
	if title_label:
		title_label.modulate.a = 0.0
		var tween: Tween = create_tween()
		tween.tween_property(title_label, "modulate:a", 1.0, 0.5)

	var buttons: Array[Button] = []
	if easy_button:
		buttons.append(easy_button)
	if normal_button:
		buttons.append(normal_button)
	if hard_button:
		buttons.append(hard_button)

	for i: int in range(buttons.size()):
		var btn: Button = buttons[i]
		btn.modulate.a = 0.0
		var original_x: float = btn.position.x
		btn.position.x -= 30
		var tween: Tween = create_tween()
		tween.tween_interval(0.15 * i + 0.2)
		tween.set_parallel(true)
		tween.tween_property(btn, "modulate:a", 1.0, 0.3)
		tween.tween_property(btn, "position:x", original_x, 0.3).set_ease(Tween.EASE_OUT)
