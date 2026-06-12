class_name AuthServiceClass
extends Node
## 認證管理（Autoload）
## 負責登入、註冊、OAuth、token 管理

# === 信號 ===
signal login_succeeded(user: Dictionary)
signal login_failed(error: String)
signal register_succeeded(user: Dictionary)
signal register_failed(error: String)
signal logout_completed()
signal profile_updated(user: Dictionary)
signal profile_update_failed(error: String)

# === 使用者資料 ===
var current_user: Dictionary = {}
var is_logged_in: bool = false


func _ready() -> void:
	# 監聽 ApiService 的 unauthorized 信號
	ApiService.unauthorized.connect(_on_unauthorized)
	# 嘗試自動登入（如果有儲存的 token）
	if ApiService.has_token():
		_try_auto_login()


# === 公開方法 ===

## 帳密登入
func login(email: String, password: String) -> void:
	print("[AuthService] 登入中...")
	var result: Dictionary = await ApiService.auth_login(email, password)
	if result.get("success", false):
		await _fetch_user_profile()
		login_succeeded.emit(current_user)
	else:
		var error_msg: String = result.get("error", "登入失敗")
		login_failed.emit(error_msg)


## 註冊
func register(username: String, email: String, password: String) -> void:
	print("[AuthService] 註冊中...")
	var result: Dictionary = await ApiService.auth_register(username, email, password)
	if result.get("success", false):
		# 註冊成功後自動登入
		await login(email, password)
		if is_logged_in:
			register_succeeded.emit(current_user)
		else:
			register_failed.emit("註冊成功但自動登入失敗")
	else:
		var error_msg: String = result.get("error", "註冊失敗")
		register_failed.emit(error_msg)


## Google OAuth 登入
func oauth_google(token: String) -> void:
	print("[AuthService] Google OAuth 登入中...")
	var result: Dictionary = await ApiService.auth_oauth_google(token)
	if result.get("success", false):
		await _fetch_user_profile()
		login_succeeded.emit(current_user)
	else:
		login_failed.emit(result.get("error", "Google 登入失敗"))


## Apple OAuth 登入
func oauth_apple(token: String) -> void:
	print("[AuthService] Apple OAuth 登入中...")
	var result: Dictionary = await ApiService.auth_oauth_apple(token)
	if result.get("success", false):
		await _fetch_user_profile()
		login_succeeded.emit(current_user)
	else:
		login_failed.emit(result.get("error", "Apple 登入失敗"))


## 登出
func logout() -> void:
	current_user = {}
	is_logged_in = false
	ApiService.clear_tokens()
	WsService.disconnect_ws()
	logout_completed.emit()
	print("[AuthService] 已登出")


## 更新個人檔案
func update_profile(data: Dictionary) -> void:
	var result: Dictionary = await ApiService.auth_update_profile(data)
	if result.get("success", false):
		# 更新本地快取
		for key: String in data:
			current_user[key] = data[key]
		profile_updated.emit(current_user)
	else:
		profile_update_failed.emit(result.get("error", "更新失敗"))


## 是否已認證
func is_authenticated() -> bool:
	return is_logged_in and ApiService.has_token()


## 取得使用者 ID
func get_user_id() -> String:
	return current_user.get("id", "")


## 取得使用者名稱
func get_username() -> String:
	return current_user.get("username", "")


# === 內部方法 ===

## 嘗試自動登入（使用儲存的 token）
func _try_auto_login() -> void:
	print("[AuthService] 嘗試自動登入...")
	var result: Dictionary = await ApiService.auth_me()
	if result.get("success", false):
		current_user = result.get("data", {})
		is_logged_in = true
		login_succeeded.emit(current_user)
		print("[AuthService] 自動登入成功: %s" % get_username())
	else:
		# Token 可能過期，嘗試刷新
		var refresh_result: Dictionary = await ApiService.auth_refresh()
		if refresh_result.get("success", false):
			await _fetch_user_profile()
			if is_logged_in:
				print("[AuthService] Token 刷新後登入成功")
			else:
				print("[AuthService] 自動登入失敗，需要重新登入")
		else:
			ApiService.clear_tokens()
			print("[AuthService] 自動登入失敗，token 已清除")


## 取得使用者資料
func _fetch_user_profile() -> void:
	var result: Dictionary = await ApiService.auth_me()
	if result.get("success", false):
		current_user = result.get("data", {})
		is_logged_in = true
	else:
		current_user = {}
		is_logged_in = false


## 未授權回調（token 失效）
func _on_unauthorized() -> void:
	current_user = {}
	is_logged_in = false
	# 永遠進離線模式，不強制跳轉到 login（避免 crash）
	print("[AuthService] 認證失敗——進入離線模式")
	is_logged_in = true
	current_user = {"username": "離線玩家", "coins": 0}
