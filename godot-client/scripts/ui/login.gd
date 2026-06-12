extends Control
## 登入畫面腳本

func _ready() -> void:
	# 如果有返回按鈕，連接信號
	var back_btn := get_node_or_null("BackButton")
	if back_btn:
		back_btn.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	# 進入離線模式並回主選單
	AuthService.is_logged_in = true
	AuthService.current_user = {"username": "離線玩家", "coins": 0}
	SceneManager.go_to_main_menu()

# ESC 也可以返回
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
