extends Control
## 註冊場景邏輯

@onready var username_input: LineEdit = $CenterContainer/ScrollContainer/Panel/MarginContainer/VBox/UsernameInput
@onready var email_input: LineEdit = $CenterContainer/ScrollContainer/Panel/MarginContainer/VBox/EmailInput
@onready var password_input: LineEdit = $CenterContainer/ScrollContainer/Panel/MarginContainer/VBox/PasswordInput
@onready var confirm_input: LineEdit = $CenterContainer/ScrollContainer/Panel/MarginContainer/VBox/ConfirmInput
@onready var register_button: Button = $CenterContainer/ScrollContainer/Panel/MarginContainer/VBox/RegisterButton
@onready var login_link: Button = $CenterContainer/ScrollContainer/Panel/MarginContainer/VBox/LoginLink
@onready var error_label: Label = $CenterContainer/ScrollContainer/Panel/MarginContainer/VBox/ErrorLabel


func _ready() -> void:
	register_button.pressed.connect(_on_register_pressed)
	login_link.pressed.connect(_on_login_link_pressed)

	AuthService.register_succeeded.connect(_on_register_success)
	AuthService.register_failed.connect(_on_register_failed)


func _on_register_pressed() -> void:
	var username: String = username_input.text.strip_edges()
	var email: String = email_input.text.strip_edges()
	var password: String = password_input.text
	var confirm: String = confirm_input.text

	# 驗證
	if username == "" or email == "" or password == "":
		_show_error("請填寫所有欄位")
		return
	if username.length() < 3:
		_show_error("使用者名稱至少 3 個字元")
		return
	if password.length() < 8:
		_show_error("密碼至少 8 個字元")
		return
	if password != confirm:
		_show_error("兩次密碼不一致")
		return

	register_button.disabled = true
	register_button.text = "註冊中..."
	error_label.text = ""
	await AuthService.register(username, email, password)


func _on_login_link_pressed() -> void:
	SceneManager.change_scene("res://scenes/auth/login.tscn")


func _on_register_success(_user: Dictionary) -> void:
	SceneManager.go_to_main_menu()


func _on_register_failed(error: String) -> void:
	register_button.disabled = false
	register_button.text = "註冊"
	_show_error(error)


func _show_error(text: String) -> void:
	if error_label:
		error_label.text = text
		error_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
