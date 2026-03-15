class_name WsServiceClass
extends Node
## WebSocket 客戶端（Autoload）
## 負責即時通訊、自動重連、心跳維持
## 協議格式：flat JSON（與 Rust server serde(tag="type", rename_all="snake_case") 相容）

# === 常數 ===
const HEARTBEAT_INTERVAL: float = 30.0  # 心跳間隔（秒）
const RECONNECT_BASE_DELAY: float = 1.0  # 重連基礎延遲
const RECONNECT_MAX_DELAY: float = 30.0  # 重連最大延遲
const MAX_RECONNECT_ATTEMPTS: int = 10

# === 信號：連線狀態 ===
signal connected()
signal disconnected()
signal connection_error(error: String)
signal reconnecting(attempt: int)

# === 信號：伺服器事件（對應 ServerMessage 的 type） ===
# 連線 & 錯誤
signal server_connected(data: Dictionary)
signal error_received(data: Dictionary)

# 房間
signal room_state_received(data: Dictionary)
signal room_state_updated(data: Dictionary)
signal player_joined(data: Dictionary)
signal player_left(data: Dictionary)
signal player_ready_changed(data: Dictionary)
signal player_unready(data: Dictionary)
signal player_selected_character(data: Dictionary)

# 遊戲流程
signal game_started(data: Dictionary)
signal game_ended(data: Dictionary)
signal phase_changed(data: Dictionary)
signal timer_updated(data: Dictionary)
signal turn_changed(data: Dictionary)

# 戰鬥 & 技能
signal challenge_event(data: Dictionary)
signal counter_event(data: Dictionary)
signal skill_used(data: Dictionary)
signal card_played(data: Dictionary)
signal card_drawn(data: Dictionary)
signal hand_updated(data: Dictionary)
signal player_hand_count_changed(data: Dictionary)

# 聲望 & 金幣
signal reputation_changed(data: Dictionary)
signal gold_changed(data: Dictionary)
signal player_political_death(data: Dictionary)

# 投票
signal vote_received(data: Dictionary)
signal vote_result(data: Dictionary)

# 聊天
signal chat_message(data: Dictionary)
signal system_message(data: Dictionary)
signal message_reaction(data: Dictionary)

# 同盟
signal alliance_proposed(data: Dictionary)
signal alliance_accepted(data: Dictionary)
signal alliance_rejected(data: Dictionary)
signal alliance_betrayed(data: Dictionary)

# 重連
signal reconnect_data(data: Dictionary)

# === 連線狀態 ===
var _socket: WebSocketPeer = WebSocketPeer.new()
var _is_connected: bool = false
var _is_connecting: bool = false
var _current_url: String = ""
var _current_room_code: String = ""

# === 重連機制 ===
var _reconnect_attempts: int = 0
var _should_reconnect: bool = false
var _reconnect_timer: Timer = null

# === 心跳 ===
var _heartbeat_timer: Timer = null
var _last_pong_time: float = 0.0

# === 事件映射（server type string → signal） ===
var _event_signals: Dictionary = {}


func _ready() -> void:
	# 建立心跳計時器
	_heartbeat_timer = Timer.new()
	_heartbeat_timer.wait_time = HEARTBEAT_INTERVAL
	_heartbeat_timer.timeout.connect(_send_heartbeat)
	add_child(_heartbeat_timer)

	# 建立重連計時器
	_reconnect_timer = Timer.new()
	_reconnect_timer.one_shot = true
	_reconnect_timer.timeout.connect(_attempt_reconnect)
	add_child(_reconnect_timer)

	# 建立事件映射表（server type → 信號）
	_event_signals = {
		# 連線
		"connected": server_connected,
		"error": error_received,
		# 房間
		"room_state": room_state_received,
		"room_update": room_state_updated,
		"player_joined": player_joined,
		"player_left": player_left,
		"player_ready": player_ready_changed,
		"player_unready": player_unready,
		"player_selected_character": player_selected_character,
		# 遊戲流程
		"game_started": game_started,
		"game_result": game_ended,
		"phase_changed": phase_changed,
		"timer_update": timer_updated,
		"turn_changed": turn_changed,
		# 戰鬥 & 技能
		"challenge_event": challenge_event,
		"counter_event": counter_event,
		"skill_used": skill_used,
		"card_used": card_played,
		"card_drawn": card_drawn,
		"hand_updated": hand_updated,
		"player_hand_count_changed": player_hand_count_changed,
		# 聲望 & 金幣
		"reputation_changed": reputation_changed,
		"gold_changed": gold_changed,
		"player_political_death": player_political_death,
		# 投票
		"vote_received": vote_received,
		"vote_result": vote_result,
		# 聊天
		"chat_message": chat_message,
		"system_message": system_message,
		"message_reaction": message_reaction,
		# 同盟
		"alliance_proposed": alliance_proposed,
		"alliance_accepted": alliance_accepted,
		"alliance_rejected": alliance_rejected,
		"alliance_betrayed": alliance_betrayed,
		# 重連
		"reconnect_data": reconnect_data,
	}


func _process(_delta: float) -> void:
	if _is_connected or _is_connecting:
		_socket.poll()
		var state: WebSocketPeer.State = _socket.get_ready_state()

		match state:
			WebSocketPeer.STATE_OPEN:
				if not _is_connected:
					_on_connected()
				# 處理接收的訊息
				while _socket.get_available_packet_count() > 0:
					var packet: PackedByteArray = _socket.get_packet()
					_handle_message(packet.get_string_from_utf8())
			WebSocketPeer.STATE_CLOSING:
				pass  # 等待關閉完成
			WebSocketPeer.STATE_CLOSED:
				if _is_connected:
					_on_disconnected()
			WebSocketPeer.STATE_CONNECTING:
				pass  # 等待連線完成


# === 公開方法 ===

## 連線到 WebSocket（一般）
func connect_general() -> void:
	var ws_url: String = _get_ws_url("/ws")
	_connect_to(ws_url)
	_current_room_code = ""


## 連線到指定房間
func connect_to_room(room_code: String) -> void:
	var ws_url: String = _get_ws_url("/ws")
	_connect_to(ws_url)
	_current_room_code = room_code


## 斷開連線
func disconnect_ws() -> void:
	_should_reconnect = false
	_reconnect_attempts = 0
	_heartbeat_timer.stop()
	_current_room_code = ""
	if _is_connected or _is_connecting:
		_socket.close(1000, "正常斷開")
		_is_connected = false
		_is_connecting = false
		print("[WsService] 手動斷開連線")


## 是否已連線
func is_connected_ws() -> bool:
	return _is_connected


# === 發送方法（flat JSON，無 data 包裝） ===

## 發送 JSON 訊息（flat format：{"type": "xxx", "field": "value", ...}）
func send_message(event_type: String, fields: Dictionary = {}) -> void:
	if not _is_connected:
		push_warning("[WsService] 未連線，無法發送訊息")
		return
	var message: Dictionary = {"type": event_type}
	message.merge(fields)
	var json_text: String = JSON.stringify(message)
	_socket.send_text(json_text)


## 加入房間
func send_join_room(room_code: String, player_name: String) -> void:
	send_message("join_room", {"room_code": room_code, "player_name": player_name})


## 離開房間
func send_leave_room() -> void:
	send_message("leave_room")


## 選擇角色
func send_select_character(character: String) -> void:
	send_message("select_character", {"character": character})


## 準備
func send_ready() -> void:
	send_message("ready")


## 取消準備
func send_unready() -> void:
	send_message("unready")


## 開始遊戲（僅房主）
func send_start_game() -> void:
	send_message("start_game")


## 發送公開聊天
func send_chat(content: String) -> void:
	send_message("send_chat", {"content": content})


## 發送私訊
func send_private_chat(target_id: String, content: String) -> void:
	send_message("send_private_chat", {"target_id": target_id, "content": content})


## 質詢（攻擊）
func send_challenge(target_id: String) -> void:
	send_message("challenge", {"target_id": target_id})


## 反駁（防禦）
func send_counter() -> void:
	send_message("counter")


## 使用技能
func send_use_skill(target_id: String = "") -> void:
	var fields: Dictionary = {}
	if target_id != "":
		fields["target_id"] = target_id
	send_message("use_skill", fields)


## 投票（choice: "a", "b", "c"）
func send_vote(choice: String) -> void:
	send_message("vote", {"choice": choice})


## 使用卡牌
func send_play_card(card_id: String, target_id: String = "") -> void:
	var fields: Dictionary = {"card_id": card_id}
	if target_id != "":
		fields["target_id"] = target_id
	send_message("use_card", fields)


## 抽牌
func send_draw_card() -> void:
	send_message("draw_card")


## 棄牌
func send_discard_card(card_id: String) -> void:
	send_message("discard_card", {"card_id": card_id})


## 結束回合
func send_end_turn() -> void:
	send_message("end_turn")


## 提議同盟
func send_propose_alliance(target_id: String) -> void:
	send_message("propose_alliance", {"target_id": target_id})


## 回應同盟提議
func send_respond_to_alliance(proposer_id: String, accept: bool) -> void:
	send_message("respond_to_alliance", {"proposer_id": proposer_id, "accept": accept})


## 表情反應
func send_react_to_message(message_seq: int, emoji: String) -> void:
	send_message("react_to_message", {"message_seq": message_seq, "emoji": emoji})


# === 內部方法 ===

## 建立 WebSocket URL
func _get_ws_url(path: String) -> String:
	var base: String = ApiService.get_base_url()
	# 將 http(s) 轉換為 ws(s)
	base = base.replace("https://", "wss://").replace("http://", "ws://")
	var token: String = ""
	if ApiService.has_token():
		token = "?token=%s" % ApiService._access_token
	return base + path + token


## 連線到指定 URL
func _connect_to(url: String) -> void:
	# 如果已連線，先斷開
	if _is_connected:
		_socket.close()
		_is_connected = false

	_current_url = url
	_should_reconnect = true
	_is_connecting = true

	var error: int = _socket.connect_to_url(url)
	if error != OK:
		_is_connecting = false
		connection_error.emit("連線失敗: %d" % error)
		_schedule_reconnect()
		return

	print("[WsService] 連線中: %s" % url.split("?")[0])


## 連線成功回調
func _on_connected() -> void:
	_is_connected = true
	_is_connecting = false
	_reconnect_attempts = 0
	_last_pong_time = Time.get_unix_time_from_system()
	_heartbeat_timer.start()
	connected.emit()
	print("[WsService] 連線成功")


## 斷線回調
func _on_disconnected() -> void:
	_is_connected = false
	_is_connecting = false
	_heartbeat_timer.stop()
	disconnected.emit()
	print("[WsService] 連線已斷開")
	if _should_reconnect:
		_schedule_reconnect()


## 處理收到的訊息（flat JSON dispatch）
func _handle_message(text: String) -> void:
	var json: JSON = JSON.new()
	var parse_result: int = json.parse(text)
	if parse_result != OK:
		push_warning("[WsService] 無法解析訊息: %s" % text)
		return

	var data: Variant = json.get_data()
	if not data is Dictionary:
		return

	var message: Dictionary = data as Dictionary
	var event_type: String = message.get("type", "")

	# 處理 pong 心跳回應
	if event_type == "pong":
		_last_pong_time = Time.get_unix_time_from_system()
		return

	# 分發事件信號（傳遞完整 flat message）
	if _event_signals.has(event_type):
		_event_signals[event_type].emit(message)
	else:
		print("[WsService] 未處理的事件: %s" % event_type)


## 發送心跳
func _send_heartbeat() -> void:
	if not _is_connected:
		return

	# 檢查是否超時（沒收到 pong）
	var current_time: float = Time.get_unix_time_from_system()
	if current_time - _last_pong_time > HEARTBEAT_INTERVAL * 2:
		push_warning("[WsService] 心跳超時，斷開重連")
		_socket.close(1001, "心跳超時")
		return

	send_message("ping")


## 安排重連
func _schedule_reconnect() -> void:
	if not _should_reconnect:
		return
	if _reconnect_attempts >= MAX_RECONNECT_ATTEMPTS:
		push_error("[WsService] 超過最大重連次數")
		connection_error.emit("超過最大重連次數")
		return

	_reconnect_attempts += 1
	# 指數退避：1s, 2s, 4s, 8s, 16s, 30s（上限）
	var delay: float = minf(RECONNECT_BASE_DELAY * pow(2, _reconnect_attempts - 1), RECONNECT_MAX_DELAY)
	reconnecting.emit(_reconnect_attempts)
	print("[WsService] %s 秒後重連（第 %d 次）" % [str(delay), _reconnect_attempts])

	_reconnect_timer.wait_time = delay
	_reconnect_timer.start()


## 嘗試重連
func _attempt_reconnect() -> void:
	if _current_url == "":
		return
	print("[WsService] 嘗試重連...")
	_connect_to(_current_url)
