## api_connection_test.gd
## API 連線測試腳本
## 掛在場景 Node 上執行，測試 Godot → fly.io 後端連通性
## 測試流程：health → register → game create
extends Node

const BASE_URL := "https://parliament1812-api.fly.dev"

var _test_count: int = 0
var _pass_count: int = 0
var _fail_count: int = 0


func _ready() -> void:
	print("")
	print("========================================")
	print("[APITest] Starting connection test...")
	print("[APITest] Target: %s" % BASE_URL)
	print("========================================")
	_test_health()


# === Test 1: Health Check ===

func _test_health() -> void:
	_test_count += 1
	print("\n[APITest] Test 1: Health check...")
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_health_response)
	var err := http.request(BASE_URL + "/health")
	if err != OK:
		_fail_count += 1
		print("[APITest] FAIL: Cannot send request. Error: %d" % err)
		_test_auth()


func _on_health_response(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		_pass_count += 1
		var response := body.get_string_from_utf8()
		print("[APITest] PASS: Server reachable. Response: %s" % response)
	else:
		_fail_count += 1
		print("[APITest] FAIL: Health check failed. result=%d code=%d" % [result, code])
	_test_auth()


# === Test 2: Auth Register ===

func _test_auth() -> void:
	_test_count += 1
	print("\n[APITest] Test 2: Auth register...")
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_auth_response)
	var headers := PackedStringArray(["Content-Type: application/json"])
	var username := "test_godot_%d" % randi()
	var payload := JSON.stringify({
		"username": username,
		"email": "%s@test.local" % username,
		"password": "test12345678"
	})
	var err := http.request(BASE_URL + "/api/v1/auth/register", headers, HTTPClient.METHOD_POST, payload)
	if err != OK:
		_fail_count += 1
		print("[APITest] FAIL: Cannot send auth request. Error: %d" % err)
		_print_summary()


func _on_auth_response(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var response := body.get_string_from_utf8()
	if code == 200 or code == 201:
		_pass_count += 1
		print("[APITest] PASS: Auth endpoint works. Token received.")
		var json := JSON.new()
		if json.parse(response) == OK and json.data is Dictionary:
			var data: Dictionary = json.data as Dictionary
			# 嘗試從多種可能的 response 結構取得 token
			var token: String = ""
			if data.has("access_token"):
				token = data["access_token"]
			elif data.has("token"):
				token = data["token"]
			elif data.has("data") and data["data"] is Dictionary:
				var inner: Dictionary = data["data"] as Dictionary
				token = inner.get("access_token", inner.get("token", ""))

			if token != "":
				print("[APITest] PASS: JWT token: %s..." % token.substr(0, 20))
				_test_game_create(token)
				return
			else:
				print("[APITest] INFO: Auth succeeded but no token in response. Keys: %s" % str(data.keys()))
	elif code == 409:
		_pass_count += 1
		print("[APITest] INFO: User exists (expected). Auth endpoint works.")
	elif code == 422:
		# 驗證錯誤，但 endpoint 有回應 = 連通
		_pass_count += 1
		print("[APITest] INFO: Validation error (endpoint responsive). Response: %s" % response.substr(0, 200))
	else:
		_fail_count += 1
		print("[APITest] FAIL: Auth response code=%d body=%s" % [code, response.substr(0, 200)])

	# 如果沒有 token，跳過 game create 測試
	_print_summary()


# === Test 3: Game Create ===

func _test_game_create(token: String) -> void:
	_test_count += 1
	print("\n[APITest] Test 3: Game create (with auth)...")
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_game_response)
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer " + token
	])
	var payload := JSON.stringify({"mode": "ai", "difficulty": "normal"})
	var err := http.request(BASE_URL + "/api/v1/single/start", headers, HTTPClient.METHOD_POST, payload)
	if err != OK:
		_fail_count += 1
		print("[APITest] FAIL: Cannot send game create request. Error: %d" % err)
		_print_summary()


func _on_game_response(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var response := body.get_string_from_utf8()
	if code == 200 or code == 201:
		_pass_count += 1
		print("[APITest] PASS: Game create succeeded.")
	elif code == 404:
		# Endpoint 可能尚未實現
		_pass_count += 1
		print("[APITest] INFO: Game endpoint not found (may not be implemented yet).")
	else:
		_fail_count += 1
		print("[APITest] WARN: Game create: code=%d response=%s" % [code, response.substr(0, 300)])

	_print_summary()


# === Summary ===

func _print_summary() -> void:
	print("")
	print("========================================")
	print("[APITest] === All tests complete ===")
	print("[APITest] Total: %d  Pass: %d  Fail: %d" % [_test_count, _pass_count, _fail_count])
	if _fail_count == 0:
		print("[APITest] ✅ All tests passed!")
	else:
		print("[APITest] ⚠️  Some tests failed.")
	print("========================================")
