class_name ApiServiceClass
extends Node
## HTTP API 客戶端（Autoload）
## 負責所有 REST API 通訊，JWT 管理，錯誤處理

# === 常數 ===
const ENV_DEV: String = "dev"
const ENV_PROD: String = "prod"
const MAX_RETRIES: int = 3
const RETRY_DELAY_BASE: float = 1.0
const TOKEN_REFRESH_MARGIN: int = 300  # token 過期前 5 分鐘刷新

# === 信號 ===
signal request_completed(endpoint: String, response: Dictionary)
signal request_failed(endpoint: String, error: Dictionary)
signal token_refreshed()
signal unauthorized()  # 401 時發出，通知需要重新登入

# === 環境配置 ===
var _base_urls: Dictionary = {
	ENV_DEV: "http://localhost:8080",
	ENV_PROD: "https://parliament1812-api.fly.dev",
}
var _current_env: String = ENV_PROD
var _base_url: String:
	get:
		return _base_urls[_current_env]

# === Token 管理 ===
var _access_token: String = ""
var _refresh_token: String = ""
var _token_expiry: int = 0
var _config: ConfigFile = ConfigFile.new()
const TOKEN_CONFIG_PATH: String = "user://auth_tokens.cfg"

# === HTTP 請求池 ===
var _request_queue: Array[Dictionary] = []
var _active_requests: Dictionary = {}  # request_id -> HTTPRequest node
var _request_counter: int = 0
var _is_refreshing: bool = false


func _ready() -> void:
	_load_tokens()


func _process(_delta: float) -> void:
	# 檢查是否需要自動刷新 token
	if _access_token != "" and _token_expiry > 0:
		var current_time: int = int(Time.get_unix_time_from_system())
		if current_time >= _token_expiry - TOKEN_REFRESH_MARGIN:
			if not _is_refreshing:
				_auto_refresh_token()


# === 公開 API 方法 ===

## 設定環境（dev / prod）
func set_environment(env: String) -> void:
	if env in _base_urls:
		_current_env = env
		print("[ApiService] 環境切換至: %s (%s)" % [env, _base_url])


## 取得目前 base URL
func get_base_url() -> String:
	return _base_url


## 設定 JWT token
func set_tokens(access: String, refresh: String, expiry: int = 0) -> void:
	_access_token = access
	_refresh_token = refresh
	_token_expiry = expiry
	_save_tokens()


## 清除 token（登出）
func clear_tokens() -> void:
	_access_token = ""
	_refresh_token = ""
	_token_expiry = 0
	_save_tokens()


## 是否有有效的 token
func has_token() -> bool:
	return _access_token != ""


## GET 請求
func get_request(endpoint: String, require_auth: bool = false) -> Dictionary:
	return await _make_request(HTTPClient.METHOD_GET, endpoint, {}, require_auth)


## POST 請求
func post_request(endpoint: String, body: Dictionary = {}, require_auth: bool = false) -> Dictionary:
	return await _make_request(HTTPClient.METHOD_POST, endpoint, body, require_auth)


## PUT 請求
func put_request(endpoint: String, body: Dictionary = {}, require_auth: bool = false) -> Dictionary:
	return await _make_request(HTTPClient.METHOD_PUT, endpoint, body, require_auth)


## DELETE 請求
func delete_request(endpoint: String, require_auth: bool = false) -> Dictionary:
	return await _make_request(HTTPClient.METHOD_DELETE, endpoint, {}, require_auth)


# === Auth API ===

func auth_register(username: String, email: String, password: String) -> Dictionary:
	return await post_request("/api/v1/auth/register", {
		"username": username,
		"email": email,
		"password": password,
	})


func auth_login(email: String, password: String) -> Dictionary:
	# 後端 LoginRequest 使用 "username" 欄位（支援 email 或 username）
	var result: Dictionary = await post_request("/api/v1/auth/login", {
		"username": email,
		"password": password,
	})
	if result.get("success", false):
		_handle_auth_response(result.get("data", {}))
	return result


func auth_refresh() -> Dictionary:
	var result: Dictionary = await post_request("/api/v1/auth/refresh", {
		"refresh_token": _refresh_token,
	})
	if result.get("success", false):
		_handle_auth_response(result.get("data", {}))
		token_refreshed.emit()
	return result


func auth_oauth_google(token: String) -> Dictionary:
	var result: Dictionary = await post_request("/api/v1/auth/oauth/google", {
		"token": token,
	})
	if result.get("success", false):
		_handle_auth_response(result.get("data", {}))
	return result


func auth_oauth_apple(token: String) -> Dictionary:
	var result: Dictionary = await post_request("/api/v1/auth/oauth/apple", {
		"token": token,
	})
	if result.get("success", false):
		_handle_auth_response(result.get("data", {}))
	return result


func auth_me() -> Dictionary:
	return await get_request("/api/v1/auth/me", true)


func auth_update_profile(data: Dictionary) -> Dictionary:
	return await put_request("/api/v1/auth/profile", data, true)


func auth_forgot_password(email: String) -> Dictionary:
	return await post_request("/api/v1/auth/forgot-password", {"email": email})


func auth_reset_password(token: String, new_password: String) -> Dictionary:
	return await post_request("/api/v1/auth/reset-password", {
		"token": token,
		"new_password": new_password,
	})


func auth_delete_account() -> Dictionary:
	return await delete_request("/api/v1/auth/account", true)


func auth_link_google(token: String) -> Dictionary:
	return await post_request("/api/v1/auth/link/google", {"token": token}, true)


func auth_link_apple(token: String) -> Dictionary:
	return await post_request("/api/v1/auth/link/apple", {"token": token}, true)


func auth_unlink_provider(provider: String) -> Dictionary:
	return await delete_request("/api/v1/auth/link/%s" % provider, true)


func auth_get_linked_accounts() -> Dictionary:
	return await get_request("/api/v1/auth/links", true)


# === Rooms API ===

func rooms_list() -> Dictionary:
	return await get_request("/api/v1/rooms")


func rooms_get(code: String) -> Dictionary:
	return await get_request("/api/v1/rooms/%s" % code)


func rooms_create() -> Dictionary:
	return await post_request("/api/v1/rooms", {}, true)


func rooms_quickmatch() -> Dictionary:
	return await post_request("/api/v1/rooms/quickmatch", {}, true)


func rooms_join(code: String) -> Dictionary:
	return await post_request("/api/v1/rooms/%s/join" % code, {}, true)


func rooms_leave(code: String) -> Dictionary:
	return await post_request("/api/v1/rooms/%s/leave" % code, {}, true)


func rooms_spectate(code: String) -> Dictionary:
	return await post_request("/api/v1/rooms/%s/spectate" % code, {}, true)


# === Rankings API ===

func rankings_global() -> Dictionary:
	return await get_request("/api/v1/rankings/global")


func rankings_seasons() -> Dictionary:
	return await get_request("/api/v1/rankings/seasons")


func rankings_season() -> Dictionary:
	return await get_request("/api/v1/rankings/season")


func rankings_me() -> Dictionary:
	return await get_request("/api/v1/rankings/me", true)


# === Quests API ===

func quests_daily() -> Dictionary:
	return await get_request("/api/v1/quests/daily", true)


func quests_claim(quest_id: String) -> Dictionary:
	return await post_request("/api/v1/quests/claim/%s" % quest_id, {}, true)


func quests_weekly() -> Dictionary:
	return await get_request("/api/v1/quests/weekly", true)


func quests_summary() -> Dictionary:
	return await get_request("/api/v1/quests/summary", true)


func quests_history() -> Dictionary:
	return await get_request("/api/v1/quests/history", true)


func quests_weekly_claim(quest_id: String) -> Dictionary:
	return await post_request("/api/v1/quests/weekly/claim/%s" % quest_id, {}, true)


# === Friends API ===

func friends_list() -> Dictionary:
	return await get_request("/api/v1/friends", true)


func friends_request(user_id: String) -> Dictionary:
	return await post_request("/api/v1/friends/request", {"user_id": user_id}, true)


func friends_accept(request_id: String) -> Dictionary:
	return await post_request("/api/v1/friends/accept", {"request_id": request_id}, true)


func friends_invite_game(friend_id: String, room_code: String) -> Dictionary:
	return await post_request("/api/v1/friends/invite-game", {
		"friend_id": friend_id,
		"room_code": room_code,
	}, true)


func friends_pending() -> Dictionary:
	return await get_request("/api/v1/friends/pending", true)


func friends_reject(request_id: String) -> Dictionary:
	return await post_request("/api/v1/friends/reject", {"request_id": request_id}, true)


func friends_remove(user_id: String) -> Dictionary:
	return await delete_request("/api/v1/friends/%s" % user_id, true)


func friends_block(user_id: String) -> Dictionary:
	return await post_request("/api/v1/friends/block", {"user_id": user_id}, true)


func friends_unblock(user_id: String) -> Dictionary:
	return await post_request("/api/v1/friends/unblock", {"user_id": user_id}, true)


func users_search(query: String) -> Dictionary:
	return await get_request("/api/v1/users/search?q=%s" % query.uri_encode(), true)


# === Codex API ===

func codex_cards() -> Dictionary:
	return await get_request("/api/codex/cards", true)


func codex_collection() -> Dictionary:
	return await get_request("/api/codex/collection", true)


func codex_achievements() -> Dictionary:
	return await get_request("/api/codex/achievements", true)


func codex_stats() -> Dictionary:
	return await get_request("/api/codex/stats", true)


func codex_claim_achievement(achievement_id: String) -> Dictionary:
	return await post_request("/api/codex/achievements/claim", {"achievement_id": achievement_id}, true)


# === Single Player API ===

func single_start() -> Dictionary:
	return await post_request("/api/v1/single/start", {}, true)


func single_action(session_id: String, action: Dictionary) -> Dictionary:
	return await post_request("/api/v1/single/action", {
		"session_id": session_id,
		"action": action,
	}, true)


func single_state(session_id: String) -> Dictionary:
	return await get_request("/api/v1/single/state/%s" % session_id, true)


func single_campaign_start(chapter: int, stage: int = -1, player_name: String = "", character: String = "") -> Dictionary:
	var body: Dictionary = {"chapter": chapter}
	if stage >= 0:
		body["stage"] = stage
	if player_name != "":
		body["player_name"] = player_name
	if character != "":
		body["character"] = character
	return await post_request("/api/v1/single/campaign/start", body, true)


func single_campaign_progress() -> Dictionary:
	return await get_request("/api/v1/single/campaign/progress", true)


# === Campaign API ===

func campaign_chapters() -> Dictionary:
	return await get_request("/api/v1/campaign/chapters")


func campaign_progress() -> Dictionary:
	return await get_request("/api/v1/campaign/progress", true)


func campaign_chapter_detail(chapter_id: String) -> Dictionary:
	return await get_request("/api/v1/campaign/chapter/%s" % chapter_id, true)


func campaign_complete_stage(data: Dictionary) -> Dictionary:
	return await post_request("/api/v1/campaign/complete", data, true)


func campaign_unlock_chapter(data: Dictionary) -> Dictionary:
	return await post_request("/api/v1/campaign/unlock", data, true)


# === Tutorial API ===

func tutorial_steps() -> Dictionary:
	return await get_request("/api/v1/tutorial/steps")


func tutorial_progress() -> Dictionary:
	return await get_request("/api/v1/tutorial/progress", true)


func tutorial_complete(step_id: String) -> Dictionary:
	return await post_request("/api/v1/tutorial/complete", {"step_id": step_id}, true)


func tutorial_reset() -> Dictionary:
	return await post_request("/api/v1/tutorial/reset", {}, true)


func tutorial_check_needs() -> Dictionary:
	return await get_request("/api/v1/tutorial/check", true)


# === IAP API ===

func iap_verify_apple(receipt: String) -> Dictionary:
	return await post_request("/api/v1/iap/verify/apple", {"receipt": receipt}, true)


func iap_balance() -> Dictionary:
	return await get_request("/api/v1/iap/balance", true)


func iap_verify_google(purchase_token: String) -> Dictionary:
	return await post_request("/api/v1/iap/verify/google", {"purchase_token": purchase_token}, true)


func iap_spend(item_id: String, amount: int) -> Dictionary:
	return await post_request("/api/v1/iap/spend", {"item_id": item_id, "amount": amount}, true)


func iap_history() -> Dictionary:
	return await get_request("/api/v1/iap/history", true)


# === Invite API ===

func invite_generate() -> Dictionary:
	return await post_request("/api/v1/invite/generate", {}, true)


func invite_resolve(token: String) -> Dictionary:
	return await post_request("/api/v1/invite/resolve/%s" % token, {})


func invite_stats() -> Dictionary:
	return await get_request("/api/v1/invite/stats", true)


func invite_convert() -> Dictionary:
	return await post_request("/api/v1/invite/convert", {}, true)


func invite_summons(data: Dictionary) -> Dictionary:
	return await post_request("/api/v1/invite/summons", data, true)


# === Referral API ===

func referral_milestones() -> Dictionary:
	return await get_request("/api/v1/referral/milestones")


func referral_progress() -> Dictionary:
	return await get_request("/api/v1/referral/progress", true)


func referral_claim() -> Dictionary:
	return await post_request("/api/v1/referral/claim", {}, true)


# === Season Pass API ===

func season_pass_status() -> Dictionary:
	return await get_request("/api/v1/season-pass", true)


func season_pass_claim(data: Dictionary) -> Dictionary:
	return await post_request("/api/v1/season-pass/claim", data, true)


func season_pass_purchase_premium() -> Dictionary:
	return await post_request("/api/v1/season-pass/premium", {}, true)


func season_pass_leaderboard() -> Dictionary:
	return await get_request("/api/v1/season-pass/leaderboard")


# === Weekly Bills API ===

func weekly_current_bill() -> Dictionary:
	return await get_request("/api/v1/weekly/current-bill")


func weekly_bill_history() -> Dictionary:
	return await get_request("/api/v1/weekly/history")


# === UGC Bills API ===

func ugc_bills_list() -> Dictionary:
	return await get_request("/api/v1/bills")


func ugc_bill_get(bill_id: String) -> Dictionary:
	return await get_request("/api/v1/bills/%s" % bill_id)


func ugc_bill_create(data: Dictionary) -> Dictionary:
	return await post_request("/api/v1/bills", data, true)


func ugc_bill_vote(bill_id: String, data: Dictionary) -> Dictionary:
	return await post_request("/api/v1/bills/%s/vote" % bill_id, data, true)


func ugc_bills_mine() -> Dictionary:
	return await get_request("/api/v1/bills/mine", true)


# === Relationships API ===

func relationships_list() -> Dictionary:
	return await get_request("/api/v1/relationships", true)


func relationships_nemeses() -> Dictionary:
	return await get_request("/api/v1/relationships/nemeses", true)


func relationships_allies() -> Dictionary:
	return await get_request("/api/v1/relationships/allies", true)


func relationship_with(user_id: String) -> Dictionary:
	return await get_request("/api/v1/relationships/%s" % user_id, true)


# === Streaming API ===

func streaming_link(data: Dictionary) -> Dictionary:
	return await post_request("/api/v1/streaming/link", data, true)


func streaming_unlink(platform: String) -> Dictionary:
	return await delete_request("/api/v1/streaming/link/%s" % platform, true)


func streaming_status() -> Dictionary:
	return await get_request("/api/v1/streaming/status", true)


func streaming_update_settings(platform: String, data: Dictionary) -> Dictionary:
	return await put_request("/api/v1/streaming/settings/%s" % platform, data, true)


func streaming_set_live(data: Dictionary) -> Dictionary:
	return await post_request("/api/v1/streaming/live", data, true)


func streaming_live() -> Dictionary:
	return await get_request("/api/v1/streaming/live")


func streaming_analytics() -> Dictionary:
	return await get_request("/api/v1/streaming/analytics", true)


# === Streamer API ===

func streamer_enable() -> Dictionary:
	return await post_request("/api/v1/streamer/enable", {}, true)


func streamer_disable() -> Dictionary:
	return await post_request("/api/v1/streamer/disable", {}, true)


func streamer_settings() -> Dictionary:
	return await get_request("/api/v1/streamer/settings", true)


func streamer_update_settings(data: Dictionary) -> Dictionary:
	return await put_request("/api/v1/streamer/settings", data, true)


func streamer_regenerate_token() -> Dictionary:
	return await post_request("/api/v1/streamer/regenerate-token", {}, true)


func streamer_overlay(token: String) -> Dictionary:
	return await get_request("/api/v1/streamer/overlay/%s" % token)


# === Game Summary API ===

func game_summary(game_id: String) -> Dictionary:
	return await get_request("/api/v1/games/%s/summary" % game_id, true)


func game_replay(game_id: String) -> Dictionary:
	return await get_request("/api/v1/games/%s/replay" % game_id, true)


func game_shared_summary(share_token: String) -> Dictionary:
	return await get_request("/api/v1/share/%s" % share_token)


# === Discord API ===

func discord_link(data: Dictionary) -> Dictionary:
	return await post_request("/api/v1/discord/link", data, true)


func discord_unlink() -> Dictionary:
	return await delete_request("/api/v1/discord/link", true)


func discord_stats(discord_user_id: String) -> Dictionary:
	return await get_request("/api/v1/discord/stats/%s" % discord_user_id)


func discord_weekly() -> Dictionary:
	return await get_request("/api/v1/discord/weekly")


# === 內部方法 ===

## 發送 HTTP 請求（核心方法）
func _make_request(method: int, endpoint: String, body: Dictionary, require_auth: bool, retry_count: int = 0) -> Dictionary:
	var url: String = _base_url + endpoint
	var headers: PackedStringArray = PackedStringArray([
		"Content-Type: application/json",
		"Accept: application/json",
	])

	# 加入 JWT header
	if require_auth:
		if _access_token == "":
			unauthorized.emit()
			return {"success": false, "error": "未認證", "code": 401}
		headers.append("Authorization: Bearer %s" % _access_token)

	# 建立 HTTPRequest 節點
	var http_request: HTTPRequest = HTTPRequest.new()
	add_child(http_request)

	_request_counter += 1
	var request_id: String = str(_request_counter)
	_active_requests[request_id] = http_request

	# 準備 body
	var body_text: String = ""
	if body.size() > 0:
		body_text = JSON.stringify(body)

	# 發送請求
	var error: int = http_request.request(url, headers, method, body_text)
	if error != OK:
		_cleanup_request(request_id)
		return {"success": false, "error": "請求發送失敗", "code": error}

	# 等待回應
	var response: Array = await http_request.request_completed
	_cleanup_request(request_id)

	var result_code: int = response[0]
	var http_code: int = response[1]
	var _response_headers: PackedStringArray = response[2]
	var response_body: PackedByteArray = response[3]

	# 處理連線錯誤
	if result_code != HTTPRequest.RESULT_SUCCESS:
		if retry_count < MAX_RETRIES:
			await get_tree().create_timer(RETRY_DELAY_BASE * pow(2, retry_count)).timeout
			return await _make_request(method, endpoint, body, require_auth, retry_count + 1)
		var err_result: Dictionary = {"success": false, "error": "連線失敗", "code": result_code}
		request_failed.emit(endpoint, err_result)
		return err_result

	# 解析 JSON 回應
	var response_text: String = response_body.get_string_from_utf8()
	var parsed: Dictionary = _parse_json_response(response_text)

	# 處理 HTTP 狀態碼
	match http_code:
		200, 201:
			var success_result: Dictionary = {"success": true, "data": parsed, "code": http_code}
			request_completed.emit(endpoint, success_result)
			return success_result
		401:
			# 嘗試刷新 token
			if require_auth and _refresh_token != "" and retry_count == 0:
				var refresh_result: Dictionary = await auth_refresh()
				if refresh_result.get("success", false):
					return await _make_request(method, endpoint, body, require_auth, retry_count + 1)
			unauthorized.emit()
			var unauth_result: Dictionary = {"success": false, "error": "認證失敗", "code": 401}
			request_failed.emit(endpoint, unauth_result)
			return unauth_result
		var code when code >= 500:
			# 伺服器錯誤，重試
			if retry_count < MAX_RETRIES:
				await get_tree().create_timer(RETRY_DELAY_BASE * pow(2, retry_count)).timeout
				return await _make_request(method, endpoint, body, require_auth, retry_count + 1)
			var server_err: Dictionary = {"success": false, "error": "伺服器錯誤", "code": code, "data": parsed}
			request_failed.emit(endpoint, server_err)
			return server_err
		_:
			var fail_result: Dictionary = {"success": false, "error": parsed.get("error", "未知錯誤"), "code": http_code, "data": parsed}
			request_failed.emit(endpoint, fail_result)
			return fail_result


## 解析 JSON 回應
func _parse_json_response(text: String) -> Dictionary:
	if text.is_empty():
		return {}
	var json: JSON = JSON.new()
	var parse_result: int = json.parse(text)
	if parse_result == OK:
		var data: Variant = json.get_data()
		if data is Dictionary:
			return data
	return {"raw": text}


## 處理認證回應（儲存 token）
func _handle_auth_response(data: Dictionary) -> void:
	if data.has("access_token"):
		_access_token = data["access_token"]
	if data.has("refresh_token"):
		_refresh_token = data["refresh_token"]
	if data.has("expires_in"):
		_token_expiry = int(Time.get_unix_time_from_system()) + int(data["expires_in"])
	_save_tokens()


## 自動刷新 token
func _auto_refresh_token() -> void:
	if _is_refreshing or _refresh_token == "":
		return
	_is_refreshing = true
	print("[ApiService] 自動刷新 token...")
	var result: Dictionary = await auth_refresh()
	_is_refreshing = false
	if not result.get("success", false):
		print("[ApiService] Token 刷新失敗")
		unauthorized.emit()


## 儲存 token 到本地
func _save_tokens() -> void:
	_config.set_value("auth", "access_token", _access_token)
	_config.set_value("auth", "refresh_token", _refresh_token)
	_config.set_value("auth", "token_expiry", _token_expiry)
	_config.save(TOKEN_CONFIG_PATH)


## 從本地載入 token
func _load_tokens() -> void:
	var err: int = _config.load(TOKEN_CONFIG_PATH)
	if err == OK:
		_access_token = _config.get_value("auth", "access_token", "")
		_refresh_token = _config.get_value("auth", "refresh_token", "")
		_token_expiry = _config.get_value("auth", "token_expiry", 0)
		if _access_token != "":
			print("[ApiService] 已載入儲存的 token")


## 清理 HTTP 請求節點
func _cleanup_request(request_id: String) -> void:
	if _active_requests.has(request_id):
		var http: HTTPRequest = _active_requests[request_id]
		if is_instance_valid(http):
			http.queue_free()
		_active_requests.erase(request_id)
