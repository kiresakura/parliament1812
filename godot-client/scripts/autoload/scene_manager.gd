class_name SceneManagerClass
extends Node
## 場景切換管理（Autoload）
## 負責場景載入、轉場動畫、歷史記錄

# === 信號 ===
signal scene_change_started(scene_path: String)
signal scene_change_completed(scene_path: String)
signal loading_progress(progress: float)

# === 轉場類型 ===
enum TransitionType {
	NONE,         # 無轉場
	FADE,         # 淡入淡出
	SLIDE_LEFT,   # 左滑
	SLIDE_RIGHT,  # 右滑
	BOOK_FLIP,    # 書頁翻轉（進入遊戲用）
	WHITE_BURST,  # 白色光爆（勝利用）
	SLOW_DARKEN,  # 緩慢暗化（失敗用）
}

# === 常數 ===
const TRANSITION_DURATION: float = 0.3
const PARCHMENT_COLOR: Color = Color("#D4C5A9")
const WAX_SEAL_COLOR: Color = Color("#8B0000")
const WAX_SEAL_RADIUS: float = 60.0

# === 狀態 ===
var _current_scene_path: String = ""
var _scene_history: Array[String] = []
var _is_transitioning: bool = false
var _transition_layer: CanvasLayer = null
var _transition_rect: ColorRect = null
var _white_rect: ColorRect = null
var _parchment_rect: ColorRect = null
var _wax_seal: Control = null


func _ready() -> void:
	# 建立轉場用的 CanvasLayer（最上層）
	_transition_layer = CanvasLayer.new()
	_transition_layer.layer = 100
	add_child(_transition_layer)

	# 建立遮罩用的 ColorRect（FADE / SLOW_DARKEN 用）
	_transition_rect = ColorRect.new()
	_transition_rect.color = Color(0.102, 0.102, 0.18, 1.0)  # 深藍黑
	_transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_transition_rect.modulate.a = 0.0
	_transition_rect.visible = false
	_transition_layer.add_child(_transition_rect)

	# 白色光爆用的 ColorRect（WHITE_BURST 用）
	_white_rect = ColorRect.new()
	_white_rect.color = Color.WHITE
	_white_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_white_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_white_rect.modulate.a = 0.0
	_white_rect.visible = false
	_transition_layer.add_child(_white_rect)

	# 羊皮紙背景（BOOK_FLIP 用）
	_parchment_rect = ColorRect.new()
	_parchment_rect.color = PARCHMENT_COLOR
	_parchment_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_parchment_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_parchment_rect.modulate.a = 0.0
	_parchment_rect.visible = false
	_transition_layer.add_child(_parchment_rect)

	# 蠟封控件（BOOK_FLIP 用）
	_wax_seal = _WaxSealControl.new()
	_wax_seal.set_anchors_preset(Control.PRESET_CENTER)
	_wax_seal.custom_minimum_size = Vector2(WAX_SEAL_RADIUS * 2.5, WAX_SEAL_RADIUS * 2.5)
	_wax_seal.size = Vector2(WAX_SEAL_RADIUS * 2.5, WAX_SEAL_RADIUS * 2.5)
	_wax_seal.pivot_offset = _wax_seal.size / 2.0
	_wax_seal.position = -_wax_seal.size / 2.0
	_wax_seal.scale = Vector2.ZERO
	_wax_seal.visible = false
	_wax_seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_layer.add_child(_wax_seal)


# === 公開方法 ===

## 切換場景（主要方法）
func change_scene(scene_path: String, transition: TransitionType = TransitionType.FADE) -> void:
	if _is_transitioning:
		push_warning("[SceneManager] 正在轉場中，忽略請求")
		return

	_is_transitioning = true
	scene_change_started.emit(scene_path)

	# 記錄歷史
	if _current_scene_path != "":
		_scene_history.append(_current_scene_path)
		# 限制歷史長度
		if _scene_history.size() > 20:
			_scene_history.remove_at(0)

	match transition:
		TransitionType.FADE:
			await _fade_transition(scene_path)
		TransitionType.BOOK_FLIP:
			await _book_flip_transition(scene_path)
		TransitionType.WHITE_BURST:
			await _white_burst_transition(scene_path)
		TransitionType.SLOW_DARKEN:
			await _slow_darken_transition(scene_path)
		TransitionType.NONE:
			_direct_change(scene_path)
		_:
			await _fade_transition(scene_path)

	_current_scene_path = scene_path
	_is_transitioning = false
	scene_change_completed.emit(scene_path)


## 返回上一個場景
func go_back(transition: TransitionType = TransitionType.FADE) -> bool:
	if _scene_history.is_empty():
		return false
	var previous_scene: String = _scene_history.pop_back()
	# 暫時移除歷史記錄避免重複
	var temp_current: String = _current_scene_path
	await change_scene(previous_scene, transition)
	# 移除因 change_scene 自動加入的記錄
	if not _scene_history.is_empty() and _scene_history[-1] == temp_current:
		_scene_history.pop_back()
	return true


## 切換到主選單
func go_to_main_menu() -> void:
	_scene_history.clear()
	await change_scene("res://scenes/main/main_menu.tscn")


## 切換到登入
func go_to_login() -> void:
	_scene_history.clear()
	await change_scene("res://scenes/auth/login.tscn")


## 切換到大廳
func go_to_lobby() -> void:
	await change_scene("res://scenes/lobby/lobby.tscn")


## 切換到派系選擇
func go_to_faction_select() -> void:
	await change_scene("res://scenes/game/faction_select.tscn")


## 切換到遊戲
func go_to_game() -> void:
	await change_scene("res://scenes/game/game_board.tscn")


## 進入遊戲（書頁翻轉轉場）
func go_to_game_enter() -> void:
	await change_scene("res://scenes/game/game_board.tscn", TransitionType.BOOK_FLIP)


## 勝利進結算（白色光爆轉場）
func go_to_victory_result() -> void:
	await change_scene("res://scenes/game/result_screen.tscn", TransitionType.WHITE_BURST)


## 失敗進結算（緩慢暗化轉場）
func go_to_defeat_result() -> void:
	await change_scene("res://scenes/game/result_screen.tscn", TransitionType.SLOW_DARKEN)


## 取得目前場景路徑
func get_current_scene() -> String:
	return _current_scene_path


## 是否可以返回
func can_go_back() -> bool:
	return not _scene_history.is_empty()


## 是否正在轉場
func is_transitioning() -> bool:
	return _is_transitioning


# === 內部方法 ===

## 直接切換（無動畫）
func _direct_change(scene_path: String) -> void:
	var err: int = get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("[SceneManager] 場景載入失敗: %s (error: %d)" % [scene_path, err])


## 淡入淡出轉場（一般切換：300ms out + 300ms in = 600ms，MOTION_SPEC §6）
func _fade_transition(scene_path: String) -> void:
	# 音效
	AudioManager.play_sfx(AudioManagerClass.SFX.SCENE_TRANSITION)

	# 淡出（變黑）
	_transition_rect.visible = true
	_transition_rect.modulate.a = 0.0
	var fade_out: Tween = create_tween()
	fade_out.tween_property(_transition_rect, "modulate:a", 1.0, TRANSITION_DURATION)
	await fade_out.finished

	# 切換場景
	var err: int = get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("[SceneManager] 場景載入失敗: %s" % scene_path)
		_transition_rect.visible = false
		return

	# 等一幀確保場景已載入
	await get_tree().process_frame

	# 淡入（變透明）
	var fade_in: Tween = create_tween()
	fade_in.tween_property(_transition_rect, "modulate:a", 0.0, TRANSITION_DURATION)
	await fade_in.finished
	_transition_rect.visible = false


## 書頁翻轉轉場（進入遊戲：500ms）
## 羊皮紙覆蓋 + 蠟封旋轉出現 → 切換 → 反向退場
func _book_flip_transition(scene_path: String) -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size

	# 重置蠟封位置（畫面中心）
	_wax_seal.size = Vector2(WAX_SEAL_RADIUS * 2.5, WAX_SEAL_RADIUS * 2.5)
	_wax_seal.pivot_offset = _wax_seal.size / 2.0
	_wax_seal.position = (viewport_size - _wax_seal.size) / 2.0
	_wax_seal.scale = Vector2.ZERO
	_wax_seal.rotation = 0.0
	_wax_seal.visible = true

	# 羊皮紙背景淡入
	_parchment_rect.visible = true
	_parchment_rect.modulate.a = 0.0

	# 進場動畫：羊皮紙覆蓋 + 蠟封旋轉放大（300ms）
	var tween_in: Tween = create_tween().set_parallel(true)
	tween_in.tween_property(_parchment_rect, "modulate:a", 1.0, 0.3) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween_in.tween_property(_wax_seal, "scale", Vector2.ONE, 0.3) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween_in.tween_property(_wax_seal, "rotation", TAU, 0.3) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	await tween_in.finished

	# 切換場景
	var err: int = get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("[SceneManager] 場景載入失敗: %s" % scene_path)
		_parchment_rect.visible = false
		_wax_seal.visible = false
		return

	await get_tree().process_frame

	# 退場動畫：蠟封縮小旋轉 + 羊皮紙淡出（200ms）
	var tween_out: Tween = create_tween().set_parallel(true)
	tween_out.tween_property(_wax_seal, "scale", Vector2.ZERO, 0.2) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween_out.tween_property(_wax_seal, "rotation", TAU * 2.0, 0.2) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween_out.tween_property(_parchment_rect, "modulate:a", 0.0, 0.2) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	await tween_out.finished

	_parchment_rect.visible = false
	_wax_seal.visible = false


## 白色光爆轉場（勝利：150ms in + 250ms out = 400ms）
func _white_burst_transition(scene_path: String) -> void:
	_white_rect.visible = true
	_white_rect.modulate.a = 0.0

	# 白色光爆 alpha 0→1（150ms Ease In）
	var burst_in: Tween = create_tween()
	burst_in.tween_property(_white_rect, "modulate:a", 1.0, 0.15) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	await burst_in.finished

	# 切換場景
	var err: int = get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("[SceneManager] 場景載入失敗: %s" % scene_path)
		_white_rect.visible = false
		return

	await get_tree().process_frame

	# 光爆消退 alpha 1→0（250ms Ease Out）
	var burst_out: Tween = create_tween()
	burst_out.tween_property(_white_rect, "modulate:a", 0.0, 0.25) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	await burst_out.finished

	_white_rect.visible = false


## 緩慢暗化轉場（失敗：600ms in + 300ms out = 900ms）
func _slow_darken_transition(scene_path: String) -> void:
	# 複用 _transition_rect，暫時切換為純黑色
	var original_color: Color = _transition_rect.color
	_transition_rect.color = Color.BLACK
	_transition_rect.visible = true
	_transition_rect.modulate.a = 0.0

	# 暗化 alpha 0→1（600ms Ease In-Out）
	var darken_in: Tween = create_tween()
	darken_in.tween_property(_transition_rect, "modulate:a", 1.0, 0.6) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	await darken_in.finished

	# 切換場景
	var err: int = get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("[SceneManager] 場景載入失敗: %s" % scene_path)
		_transition_rect.color = original_color
		_transition_rect.visible = false
		return

	await get_tree().process_frame

	# 淡出 alpha 1→0（300ms Ease Out）
	var darken_out: Tween = create_tween()
	darken_out.tween_property(_transition_rect, "modulate:a", 0.0, 0.3) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	await darken_out.finished

	_transition_rect.visible = false
	_transition_rect.color = original_color


# === 蠟封內部控件 ===

## 自繪蠟封控件，用 _draw 繪製暗紅色蠟封圖案
class _WaxSealControl extends Control:
	func _draw() -> void:
		var center: Vector2 = size / 2.0
		var radius: float = min(size.x, size.y) / 2.5
		var seal_color: Color = Color("#8B0000")
		var highlight_color: Color = Color("#A52A2A")

		# 蠟封主體圓形
		draw_circle(center, radius, seal_color)

		# 外圈凸邊（模擬蠟封邊緣的不規則感）
		var edge_count: int = 24
		for i: int in range(edge_count):
			var angle: float = (TAU / edge_count) * i
			var bump_radius: float = radius + 4.0 + sin(angle * 3.0) * 3.0
			var bump_pos: Vector2 = center + Vector2(cos(angle), sin(angle)) * bump_radius
			draw_circle(bump_pos, 5.0, seal_color)

		# 內圈裝飾弧
		draw_arc(center, radius * 0.6, 0.0, TAU, 48, highlight_color, 2.0)
		draw_arc(center, radius * 0.35, 0.0, TAU, 32, highlight_color, 1.5)

		# 中心十字紋章
		var cross_half: float = radius * 0.2
		draw_line(center + Vector2(-cross_half, 0), center + Vector2(cross_half, 0), highlight_color, 2.5)
		draw_line(center + Vector2(0, -cross_half), center + Vector2(0, cross_half), highlight_color, 2.5)
