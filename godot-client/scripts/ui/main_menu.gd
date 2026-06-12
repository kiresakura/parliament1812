class_name MainMenu
extends Control
## 主選單邏輯
## 負責選單按鈕、快速配對、進入各功能

# === 節點參考 ===
@onready var play_button: Button = $VBox/PlayButton
@onready var campaign_button: Button = $VBox/CampaignButton
@onready var single_button: Button = $VBox/SingleButton
@onready var codex_button: Button = $VBox/CodexButton
@onready var profile_button: Button = $VBox/ProfileButton
@onready var settings_button: Button = $VBox/SettingsButton
@onready var title_label: Label = $TitleLabel
@onready var player_name_label: Label = $TopBar/PlayerNameLabel
@onready var coin_label: Label = $TopBar/CoinLabel
@onready var version_label: Label = $VersionLabel

# === Toast 通知 ===
var _toast_label: Label = null
var _toast_tween: Tween = null


func _ready() -> void:
	# 連接按鈕
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
	if campaign_button:
		campaign_button.pressed.connect(_on_campaign_pressed)
	if single_button:
		single_button.pressed.connect(_on_single_pressed)
	if codex_button:
		codex_button.pressed.connect(_on_codex_pressed)
	if profile_button:
		profile_button.pressed.connect(_on_profile_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)

	# 建立 Toast Label（用於顯示提示訊息）
	_create_toast_label()

	# 如果未登入但有 splash 的離線模式設定，不跳轉
	if not AuthService.is_authenticated():
		# 如果連離線模式都沒有（直接進入 main_menu），嘗試補救
		if not AuthService.is_logged_in:
			# 設定離線模式假資料
			AuthService.is_logged_in = true
			AuthService.current_user = {"username": "離線玩家", "coins": 0}

	# 播放主選單音樂（如果還沒播）
	AudioManager.play_music(AudioManagerClass.MusicTrack.MAIN_MENU)

	# 更新使用者資訊
	_update_user_info()

	# 監聽登入成功事件（背景 auth 完成時更新）
	AuthService.login_succeeded.connect(_on_login_succeeded)

	# 入場動畫
	_play_entrance_animation()

	# 版本號
	if version_label:
		version_label.text = "v0.1.0"


# === 按鈕回調 ===

func _on_play_pressed() -> void:
	AudioManager.play_sfx(AudioManagerClass.SFX.BUTTON_CLICK)
	_show_toast("多人對戰 — 開發中 🚧")


func _on_campaign_pressed() -> void:
	AudioManager.play_sfx(AudioManagerClass.SFX.BUTTON_CLICK)
	_show_toast("故事戰役 — 開發中 🚧")


func _on_single_pressed() -> void:
	AudioManager.play_sfx(AudioManagerClass.SFX.BUTTON_CLICK)
	# 進入難度選擇畫面
	SceneManager.change_scene("res://scenes/game/difficulty_select.tscn")


func _on_codex_pressed() -> void:
	AudioManager.play_sfx(AudioManagerClass.SFX.BUTTON_CLICK)
	_show_toast("圖鑑 — 開發中 🚧")


func _on_profile_pressed() -> void:
	AudioManager.play_sfx(AudioManagerClass.SFX.BUTTON_CLICK)
	_show_toast("個人檔案 — 開發中 🚧")


func _on_settings_pressed() -> void:
	AudioManager.play_sfx(AudioManagerClass.SFX.BUTTON_CLICK)
	_show_toast("設定 — 開發中 🚧")


# === 內部方法 ===

## 更新使用者資訊顯示
func _update_user_info() -> void:
	var user: Dictionary = AuthService.current_user
	if user.is_empty():
		user = GameManager.cached_player
	if player_name_label:
		player_name_label.text = user.get("username", "訪客")
	if coin_label:
		coin_label.text = "💰 %s" % str(user.get("coins", 0))


## 登入成功回調
func _on_login_succeeded(_user: Dictionary) -> void:
	_update_user_info()


## 建立 Toast Label
func _create_toast_label() -> void:
	_toast_label = Label.new()
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast_label.add_theme_font_size_override("font_size", UIScaleClass.font_size(18))
	_toast_label.add_theme_color_override("font_color", Color(0.91, 0.835, 0.718))
	_toast_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	var vp_w: float = UIScaleClass.get_viewport_size().x
	_toast_label.offset_top = -80.0
	_toast_label.offset_bottom = -50.0
	_toast_label.offset_left = -minf(200.0, vp_w * 0.35)
	_toast_label.offset_right = minf(200.0, vp_w * 0.35)
	_toast_label.modulate.a = 0.0
	add_child(_toast_label)


## 顯示 Toast 通知
func _show_toast(text: String) -> void:
	if not _toast_label:
		return

	# 取消舊的動畫
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()

	_toast_label.text = text
	_toast_label.modulate.a = 0.0

	_toast_tween = create_tween()
	# 淡入
	_toast_tween.tween_property(_toast_label, "modulate:a", 1.0, 0.2)
	# 停留
	_toast_tween.tween_interval(2.0)
	# 淡出
	_toast_tween.tween_property(_toast_label, "modulate:a", 0.0, 0.3)


## 入場動畫
func _play_entrance_animation() -> void:
	# 標題動畫
	if title_label:
		title_label.modulate.a = 0.0
		title_label.position.y -= 30
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(title_label, "modulate:a", 1.0, 0.8)
		tween.tween_property(title_label, "position:y", title_label.position.y + 30, 0.8).set_ease(Tween.EASE_OUT)

	# 按鈕依序淡入
	var buttons: Array[Button] = []
	if play_button:
		buttons.append(play_button)
	if campaign_button:
		buttons.append(campaign_button)
	if single_button:
		buttons.append(single_button)
	if codex_button:
		buttons.append(codex_button)
	if profile_button:
		buttons.append(profile_button)
	if settings_button:
		buttons.append(settings_button)

	for i: int in range(buttons.size()):
		var btn: Button = buttons[i]
		btn.modulate.a = 0.0
		var tween: Tween = create_tween()
		tween.tween_interval(0.1 * i + 0.3)
		tween.tween_property(btn, "modulate:a", 1.0, 0.3)
