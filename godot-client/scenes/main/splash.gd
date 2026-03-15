extends Control
## 開場動畫（Splash Screen）

@onready var title_label: Label = $CenterContainer/VBox/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/VBox/SubtitleLabel


func _ready() -> void:
	# 標題淡入動畫
	title_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0

	var tween: Tween = create_tween()
	tween.tween_property(title_label, "modulate:a", 1.0, 1.0)
	tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.8)


func _on_timer_timeout() -> void:
	# 2 秒後切換場景
	if AuthService.is_authenticated():
		SceneManager.change_scene("res://scenes/main/main_menu.tscn")
	else:
		SceneManager.change_scene("res://scenes/auth/login.tscn")
