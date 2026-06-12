class_name NotificationPopup
extends PanelContainer
## 通知彈窗
## 滑入/滑出動畫，可自動或手動關閉

# === 信號 ===
signal dismissed()

# === 節點參考 ===
@onready var message_label: Label = $MarginContainer/HBox/MessageLabel
@onready var close_button: Button = $MarginContainer/HBox/CloseButton
@onready var icon_label: Label = $MarginContainer/HBox/IconLabel
@onready var anim_player: AnimationPlayer = $AnimationPlayer

# === 常數 (MOTION_SPEC §8) ===
const DEFAULT_DURATION: float = 3.5
const SLIDE_IN_OFFSET: float = 300.0  # 從右側 +300px 滑入
const SLIDE_IN_DURATION: float = 0.15  # 150ms Ease Out
const SLIDE_OUT_DURATION: float = 0.5  # opacity 1.0→0, 500ms
const SLIDE_DURATION: float = 0.3  # fallback

# === 狀態 ===
var _auto_dismiss: bool = true
var _duration: float = DEFAULT_DURATION


func _ready() -> void:
	if close_button:
		close_button.pressed.connect(_dismiss)

	# 初始位置：從右側滑入
	modulate.a = 0.0

	# 設定動畫（如果有 AnimationPlayer 自訂動畫就用，否則用 Tween）
	if anim_player and anim_player.has_animation("slide_in"):
		anim_player.play("slide_in")
	else:
		_play_slide_in()


# === 公開方法 ===

## 設定通知內容
func setup(text: String, icon: String = "ℹ️", duration: float = DEFAULT_DURATION, auto_dismiss: bool = true) -> void:
	_duration = duration
	_auto_dismiss = auto_dismiss

	if message_label:
		message_label.text = text
	if icon_label:
		icon_label.text = icon

	# 自動消失
	if _auto_dismiss:
		await get_tree().create_timer(_duration).timeout
		_dismiss()


## 設定通知顏色
func set_type(type: String) -> void:
	var color: Color = Color(0.91, 0.835, 0.718, 1)
	match type:
		"success":
			color = Color(0.2, 0.8, 0.2, 1)
		"error":
			color = Color(0.8, 0.2, 0.2, 1)
		"warning":
			color = Color(0.9, 0.7, 0.1, 1)
		"info":
			color = Color(0.788, 0.659, 0.298, 1)

	if message_label:
		message_label.add_theme_color_override("font_color", color)


# === 內部方法 ===

## Tween 滑入動畫 (MOTION_SPEC §8: 從右側 +300px → 0px, 150ms Ease Out)
func _play_slide_in() -> void:
	var original_x: float = position.x
	position.x += SLIDE_IN_OFFSET
	modulate.a = 0.0

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:x", original_x, SLIDE_IN_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 1.0, SLIDE_IN_DURATION * 0.7)
	await tween.finished


## 關閉通知
func _dismiss() -> void:
	if anim_player and anim_player.has_animation("slide_out"):
		anim_player.play("slide_out")
		await anim_player.animation_finished
	else:
		await _play_slide_out()

	dismissed.emit()
	queue_free()


## Tween 滑出動畫 (MOTION_SPEC §8: opacity 1.0→0, 500ms)
func _play_slide_out() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, SLIDE_OUT_DURATION)
	await tween.finished
