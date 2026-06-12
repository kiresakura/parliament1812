extends Control
## 登入場景邏輯

@onready var email_input: LineEdit = $CenterContainer/Panel/MarginContainer/VBox/EmailInput
@onready var password_input: LineEdit = $CenterContainer/Panel/MarginContainer/VBox/PasswordInput
@onready var login_button: Button = $CenterContainer/Panel/MarginContainer/VBox/LoginButton
@onready var google_button: Button = $CenterContainer/Panel/MarginContainer/VBox/OAuthBox/GoogleButton  # OAuthBox is now VBox in portrait
@onready var apple_button: Button = $CenterContainer/Panel/MarginContainer/VBox/OAuthBox/AppleButton
@onready var register_link: Button = $CenterContainer/Panel/MarginContainer/VBox/RegisterLink
@onready var error_label: Label = $CenterContainer/Panel/MarginContainer/VBox/ErrorLabel


func _ready() -> void:
	login_button.pressed.connect(_on_login_pressed)
	google_button.pressed.connect(_on_google_pressed)
	apple_button.pressed.connect(_on_apple_pressed)
	register_link.pressed.connect(_on_register_pressed)
	password_input.text_submitted.connect(func(_t: String) -> void: _on_login_pressed())

	AuthService.login_succeeded.connect(_on_login_success)
	AuthService.login_failed.connect(_on_login_failed)


func _on_login_pressed() -> void:
	var email: String = email_input.text.strip_edges()
	var password: String = password_input.text

	if email == "" or password == "":
		_show_error("請填寫所有欄位")
		return

	login_button.disabled = true
	login_button.text = "登入中..."
	error_label.text = ""
	await AuthService.login(email, password)


func _on_google_pressed() -> void:
	# TODO: Google OAuth 流程
	_show_error("Google 登入功能開發中")


func _on_apple_pressed() -> void:
	# TODO: Apple OAuth 流程
	_show_error("Apple 登入功能開發中")


func _on_register_pressed() -> void:
	SceneManager.change_scene("res://scenes/auth/register.tscn")


func _on_login_success(_user: Dictionary) -> void:
	SceneManager.go_to_main_menu()


func _on_login_failed(error: String) -> void:
	login_button.disabled = false
	login_button.text = "登入"
	_show_error(error)


func _show_error(text: String) -> void:
	if error_label:
		error_label.text = text
		error_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
