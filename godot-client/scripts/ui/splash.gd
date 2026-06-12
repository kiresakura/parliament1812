extends Control
## Splash 啟動畫面腳本
## Timer(2s) 到期後跳轉到主選單

func _ready() -> void:
	# 播放主選單 BGM（fade in）
	AudioManager.play_music(AudioManagerClass.MusicTrack.MAIN_MENU)

	# 嘗試自動登入（背景執行，不阻塞 splash）
	_try_background_auth()


## Timer timeout 信號回調（在 splash.tscn 中已連接）
func _on_timer_timeout() -> void:
	SceneManager.change_scene("res://scenes/main/main_menu.tscn")


## 背景嘗試認證（不阻塞畫面）
func _try_background_auth() -> void:
	if AuthService.is_authenticated():
		return  # 已登入

	if ApiService.has_token():
		# 有儲存的 token，AuthService._ready 會自動嘗試
		return

	# 沒有 token → 自動註冊訪客帳號
	var guest_id := "guest_%s" % str(randi() % 999999).pad_zeros(6)
	print("[Splash] 無 token，自動註冊訪客帳號: %s" % guest_id)
	var result: Dictionary = await ApiService.post_request("/api/v1/auth/register", {
		"username": guest_id,
		"password": "guest_%s" % guest_id,
		"display_name": "訪客",
		"email": "%s@parliament1812.local" % guest_id,
	})
	if result.get("success", false):
		var data: Dictionary = result.get("data", {})
		if data.has("access_token"):
			ApiService.set_tokens(
				data.get("access_token", ""),
				data.get("refresh_token", ""),
				int(Time.get_unix_time_from_system()) + data.get("expires_in", 3600)
			)
			# 取得使用者資料
			var me_result: Dictionary = await ApiService.auth_me()
			if me_result.get("success", false):
				AuthService.current_user = me_result.get("data", {})
				AuthService.is_logged_in = true
				AuthService.login_succeeded.emit(AuthService.current_user)
				print("[Splash] 訪客登入成功: %s" % AuthService.get_username())
			else:
				# 即使 /me 失敗也標記已登入（token 有效）
				AuthService.is_logged_in = true
				AuthService.current_user = {"username": "訪客"}
				AuthService.login_succeeded.emit(AuthService.current_user)
	else:
		print("[Splash] 訪客帳號建立失敗（離線模式）")
		# 離線模式：設定假資料讓主選單不會跳轉到登入頁
		AuthService.is_logged_in = true
		AuthService.current_user = {"username": "離線玩家", "coins": 0}
		AuthService.login_succeeded.emit(AuthService.current_user)
