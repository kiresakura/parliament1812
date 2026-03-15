class_name HUD
extends CanvasLayer
## 遊戲中 HUD
## 負責顯示回合資訊、計時器、玩家狀態

# === 節點參考 ===
@onready var timer_label: Label = $TopBar/TimerLabel
@onready var phase_label: Label = $TopBar/PhaseLabel
@onready var round_label: Label = $TopBar/RoundLabel
@onready var coin_label: Label = $TopBar/CoinLabel
@onready var notification_container: VBoxContainer = $NotificationArea
@onready var menu_button: Button = $TopBar/MenuButton
@onready var chat_button: Button = $BottomBar/ChatButton

# === 常數 ===
const NOTIFICATION_DURATION: float = 3.0
const MAX_NOTIFICATIONS: int = 5

# === 狀態 ===
var _active_notifications: Array[Control] = []


func _ready() -> void:
	layer = 10  # 確保在最上層

	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)
	if chat_button:
		chat_button.pressed.connect(_on_chat_pressed)


# === 公開方法 ===

## 更新計時器
func update_timer(time_text: String, urgent: bool = false) -> void:
	if timer_label:
		timer_label.text = time_text
		if urgent:
			timer_label.add_theme_color_override("font_color", Color.RED)
		else:
			timer_label.remove_theme_color_override("font_color")


## 更新階段顯示
func update_phase(phase_name: String) -> void:
	if phase_label:
		phase_label.text = phase_name


## 更新回合顯示
func update_round(current: int, total: int) -> void:
	if round_label:
		round_label.text = "回合 %d/%d" % [current, total]


## 更新金幣
func update_coins(amount: int) -> void:
	if coin_label:
		coin_label.text = str(amount)


## 顯示通知
func show_notification(text: String, color: Color = Color.WHITE) -> void:
	if not notification_container:
		return

	# 限制通知數量
	if _active_notifications.size() >= MAX_NOTIFICATIONS:
		var oldest: Control = _active_notifications.pop_front()
		oldest.queue_free()

	# 建立通知元素
	var notification: PanelContainer = PanelContainer.new()
	var label: Label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification.add_child(label)

	notification_container.add_child(notification)
	_active_notifications.append(notification)

	# 淡入動畫
	notification.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(notification, "modulate:a", 1.0, 0.2)

	# 自動移除
	await get_tree().create_timer(NOTIFICATION_DURATION).timeout
	if is_instance_valid(notification):
		var fade: Tween = create_tween()
		fade.tween_property(notification, "modulate:a", 0.0, 0.3)
		await fade.finished
		if is_instance_valid(notification):
			_active_notifications.erase(notification)
			notification.queue_free()


## 顯示玩家出牌提示
func show_card_played(player_name: String, card_name: String) -> void:
	show_notification("%s 打出了「%s」" % [player_name, card_name], Color(0.788, 0.659, 0.298))


## 顯示投票提示
func show_vote_notification(player_name: String) -> void:
	show_notification("%s 已投票" % player_name)


# === 內部方法 ===

func _on_menu_pressed() -> void:
	AudioManager.play_sfx(AudioManagerClass.SFX.BUTTON_CLICK)
	# TODO: 顯示遊戲內選單（暫停、設定、離開）


func _on_chat_pressed() -> void:
	AudioManager.play_sfx(AudioManagerClass.SFX.BUTTON_CLICK)
	# TODO: 開啟聊天視窗
