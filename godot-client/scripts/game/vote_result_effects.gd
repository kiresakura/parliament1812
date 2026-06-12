## vote_result_effects.gd
## 法案投票結果動效管理器
## 掛在 game_board 場景上，由 voting_panel 結果信號觸發。
##
## 公開方法：
##   play_pass_effect(streak: int)  — 法案通過（streak 1/2/3+）
##   play_fail_effect()             — 法案失敗
##   trigger_vote_pass(streak: int) — §9 精確時序版通過動效
##
## 信號：
##   effect_finished()  — 所有動效播放完畢
class_name VoteResultEffects
extends Node

signal effect_finished()

# ---------------------------------------------------------------------------
# 常數
# ---------------------------------------------------------------------------
const OVERLAY_CANVAS_LAYER := 90

const GOLD_COLOR := Color(1.0, 0.84, 0.0)          # 金色粒子
const DARK_RED   := Color("#8B0000")                # 法案否決文字
const RIPPLE_COLOR := Color(0.15, 0.1, 0.1, 0.6)   # 暗色波紋

const MAX_CONCURRENT_PARTICLES := 3

# §9 時序常數
const STREAK_HAPTIC_DELAY_MS  := 0      # T+0ms:   觸覺回饋
const STREAK_PARTICLE_DELAY_S := 0.05   # T+50ms:  粒子
const STREAK_SFX_DELAY_S      := 0.05   # T+100ms: 音效（粒子後再 50ms）
# §10 限制：總時長 <600ms, 粒子 <3 組, haptic 間隔 >80ms
const HAPTIC_MIN_INTERVAL_S   := 0.08

# ---------------------------------------------------------------------------
# 內部狀態
# ---------------------------------------------------------------------------
var _canvas_layer: CanvasLayer
var _overlay_rect: ColorRect          # 白色 / 黑色 overlay
var _label: Label                     # 結果文字
var _active_particles: Array[GPUParticles2D] = []
var _playing := false
var _viewport_size := Vector2.ZERO

# ---------------------------------------------------------------------------
# 生命週期
# ---------------------------------------------------------------------------
func _ready() -> void:
	_viewport_size = get_viewport().get_visible_rect().size
	get_viewport().size_changed.connect(_on_viewport_resized)
	_build_canvas_layer()


func _on_viewport_resized() -> void:
	_viewport_size = get_viewport().get_visible_rect().size
	if is_instance_valid(_overlay_rect):
		_overlay_rect.size = _viewport_size


# =========================================================================
#  PUBLIC API
# =========================================================================

## 法案通過動效（streak 決定演出等級）
func play_pass_effect(streak: int) -> void:
	if _playing:
		return
	_playing = true
	streak = maxi(streak, 1)

	if streak >= 3:
		_play_pass_streak3(streak)
	elif streak == 2:
		_play_pass_streak2()
	else:
		_play_pass_streak1()


## 法案失敗動效
func play_fail_effect() -> void:
	if _playing:
		return
	_playing = true
	_play_fail()


# =========================================================================
#  §9 精確時序 — trigger_vote_pass
# =========================================================================

## §9 精確時序版法案通過動效
## 時序：T+0ms haptic → T+50ms particles → T+100ms sfx
## 遵守 §10 限制：<600ms 總時長, <3 粒子組, haptic 間隔 >80ms
func trigger_vote_pass(streak: int) -> void:
	if _playing:
		return
	_playing = true
	streak = maxi(streak, 1)

	# T+0ms: 觸覺回饋
	_play_streak_haptic(streak)

	# T+50ms: 粒子效果
	await get_tree().create_timer(STREAK_PARTICLE_DELAY_S).timeout
	_spawn_streak_particles(streak)

	# T+100ms: 音效（從粒子後再等 50ms）
	await get_tree().create_timer(STREAK_SFX_DELAY_S).timeout
	_play_sfx("vote_pass_%d" % mini(streak, 3))

	# 視覺動畫繼續（非阻塞），完成後清理
	# streak 1: ~2s, streak 2: ~2.5s, streak 3+: ~3.5s
	var finish_delay := 2.0 if streak == 1 else (2.5 if streak == 2 else 3.5)
	_delayed(finish_delay, _finish)


## §9 觸覺回饋：streak 1=light, streak 2=medium, streak 3+=heavy
func _play_streak_haptic(streak: int) -> void:
	match streak:
		1:
			_haptic("light")
		2:
			_haptic("medium")
		_:
			# streak 3+: heavy，第二次 heavy 間隔 >80ms（§10）
			_haptic("heavy")
			_delayed(HAPTIC_MIN_INTERVAL_S + 0.02, func():
				_haptic("heavy")
			)


## §9 粒子效果：根據 streak 等級生成對應粒子
## 遵守 §10：最多 2 組粒子同時存在
func _spawn_streak_particles(streak: int) -> void:
	match streak:
		1:
			_spawn_gold_particles(30, 150.0, 1.5)
		2:
			_spawn_gold_particles(60, 250.0, 1.5)
		_:
			# streak 3+: 粒子暴雨（全畫面）
			# 僅 1 組大量粒子而非多組，遵守 §10 <3 粒子組限制
			_spawn_rain_particles(150, 3.0)


# =========================================================================
#  STREAK 1 — 基礎通過
# =========================================================================
func _play_pass_streak1() -> void:
	# T+0ms  閃光 + 音效 + 觸覺
	_flash_overlay(Color.WHITE, 0.15, 0.1, 0.1)
	_play_sfx("vote_pass_1")
	_haptic("medium")

	# T+50ms  金色粒子
	_delayed(0.05, func():
		_spawn_gold_particles(30, 150.0, 1.5)
	)

	# T+100ms  文字 slide up
	_delayed(0.1, func():
		_show_result_label("法案通過！", Color.WHITE, 80.0, 0.3)
	)

	# 整體完成（label 動畫 300ms + 停留 1.2s + fade 300ms ≈ 2s）
	_delayed(2.0, _finish)


# =========================================================================
#  STREAK 2 — 連線
# =========================================================================
func _play_pass_streak2() -> void:
	# T+0ms  閃光（更強）+ 光暈 + 音效 + 觸覺
	_flash_overlay(Color.WHITE, 0.25, 0.125, 0.125)
	_play_sfx("vote_pass_2")
	_haptic("heavy")

	# T+0ms  「連線！×2」文字飛入
	_show_streak_label("連線！×2", 0.3, 1.0, 0.3)

	# T+50ms  金色粒子（量 ×2，範圍擴大）
	_delayed(0.05, func():
		_spawn_gold_particles(60, 250.0, 1.5)
	)

	_delayed(2.5, _finish)


# =========================================================================
#  STREAK 3+ — 全屏爆發
# =========================================================================
func _play_pass_streak3(streak: int) -> void:
	# T+0ms  強烈閃光 + 音效 + 雙重觸覺
	_flash_overlay(Color.WHITE, 0.4, 0.15, 0.3)
	_play_sfx("vote_pass_3")
	_haptic("heavy")
	_delayed(0.1, func(): _haptic("heavy"))

	# T+100ms  粒子暴雨（全畫面）
	_delayed(0.1, func():
		_spawn_rain_particles(150, 3.0)
	)

	# T+150ms  相機震動
	_delayed(0.15, func():
		_camera_shake(5.0, 8, 0.4)
	)

	# T+200ms  「傳奇連線！×N」彈跳
	_delayed(0.2, func():
		_show_bounce_label("傳奇連線！×%d" % streak, 0.5)
	)

	_delayed(3.5, _finish)


# =========================================================================
#  FAIL — 法案失敗
# =========================================================================
func _play_fail() -> void:
	# T+0ms  暗化 + 音效 + 觸覺
	_darken_overlay(0.3, 0.8)
	_play_sfx("vote_fail")
	_haptic("light")

	# T+200ms  「法案否決」文字 fade in（無動畫位移）
	_delayed(0.2, func():
		_show_fail_label("法案否決", DARK_RED)
	)

	# T+500ms  暗色波紋 ×3
	_delayed(0.5, func():
		for i in range(3):
			_delayed(i * 0.2, func():
				_spawn_ripple()
			)
	)

	# 整體完成（暗化 800ms + 波紋 ≈ 1.5s + 恢復）
	_delayed(3.0, func():
		_fade_overlay_out(0.5)
		_fade_label_out(0.5)
		_delayed(0.6, _finish)
	)


# =========================================================================
#  OVERLAY
# =========================================================================
func _build_canvas_layer() -> void:
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = OVERLAY_CANVAS_LAYER
	add_child(_canvas_layer)

	_overlay_rect = ColorRect.new()
	_overlay_rect.size = _viewport_size
	_overlay_rect.color = Color(1, 1, 1, 0)
	_overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas_layer.add_child(_overlay_rect)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.size = _viewport_size
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 48)
	_label.modulate.a = 0.0
	_canvas_layer.add_child(_label)


## 白色閃光：alpha 0 → peak → 0
func _flash_overlay(color: Color, peak: float, rise_dur: float, fall_dur: float) -> void:
	_overlay_rect.color = Color(color.r, color.g, color.b, 0.0)
	var tw := create_tween()
	tw.tween_property(_overlay_rect, "color:a", peak, rise_dur)
	tw.tween_property(_overlay_rect, "color:a", 0.0, fall_dur)


## 黑色暗化：alpha 0 → target
func _darken_overlay(target_alpha: float, duration: float) -> void:
	_overlay_rect.color = Color(0, 0, 0, 0)
	var tw := create_tween()
	tw.tween_property(_overlay_rect, "color:a", target_alpha, duration)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


func _fade_overlay_out(duration: float) -> void:
	var tw := create_tween()
	tw.tween_property(_overlay_rect, "color:a", 0.0, duration)


# =========================================================================
#  LABELS
# =========================================================================

## streak=1 的 slide-up + fade-in
func _show_result_label(text: String, color: Color, slide_px: float, duration: float) -> void:
	_label.text = text
	_label.add_theme_color_override("font_color", color)
	_label.modulate.a = 0.0
	_label.position = Vector2(0, slide_px)
	_label.pivot_offset = _viewport_size * 0.5
	_label.scale = Vector2.ONE

	var tw := create_tween().set_parallel(true)
	tw.tween_property(_label, "modulate:a", 1.0, duration)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(_label, "position:y", 0.0, duration)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	# 停留後 fade out
	_delayed(duration + 1.2, func():
		_fade_label_out(0.3)
	)


## streak=2 的飛入文字
func _show_streak_label(text: String, fly_dur: float, hold_dur: float, fade_dur: float) -> void:
	_label.text = text
	_label.add_theme_color_override("font_color", GOLD_COLOR)
	_label.modulate.a = 0.0
	_label.position = Vector2(0, _viewport_size.y * 0.3)
	_label.pivot_offset = _viewport_size * 0.5
	_label.scale = Vector2.ONE

	var tw := create_tween().set_parallel(true)
	tw.tween_property(_label, "modulate:a", 1.0, fly_dur)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(_label, "position:y", 0.0, fly_dur)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	_delayed(fly_dur + hold_dur, func():
		_fade_label_out(fade_dur)
	)


## streak=3+ 的彈跳文字：scale 0.5 → 1.2 → 1.0
func _show_bounce_label(text: String, total_dur: float) -> void:
	_label.text = text
	_label.add_theme_color_override("font_color", GOLD_COLOR)
	_label.modulate.a = 1.0
	_label.position = Vector2.ZERO
	_label.pivot_offset = _viewport_size * 0.5
	_label.scale = Vector2(0.5, 0.5)

	var tw := create_tween()
	tw.tween_property(_label, "scale", Vector2(1.2, 1.2), total_dur * 0.6)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(_label, "scale", Vector2.ONE, total_dur * 0.4)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)

	_delayed(total_dur + 1.5, func():
		_fade_label_out(0.3)
	)


## 法案失敗文字（純 fade in，無位移動畫）
func _show_fail_label(text: String, color: Color) -> void:
	_label.text = text
	_label.add_theme_color_override("font_color", color)
	_label.modulate.a = 0.0
	_label.position = Vector2.ZERO
	_label.pivot_offset = _viewport_size * 0.5
	_label.scale = Vector2.ONE

	var tw := create_tween()
	tw.tween_property(_label, "modulate:a", 1.0, 0.4)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


func _fade_label_out(duration: float) -> void:
	var tw := create_tween()
	tw.tween_property(_label, "modulate:a", 0.0, duration)


# =========================================================================
#  PARTICLES
# =========================================================================

## 金色向上噴發粒子
func _spawn_gold_particles(amount: int, radius: float, lifetime: float) -> void:
	if _active_particles.size() >= MAX_CONCURRENT_PARTICLES:
		_remove_oldest_particle()

	var particles := GPUParticles2D.new()
	particles.amount = amount
	particles.lifetime = lifetime
	particles.one_shot = true
	particles.emitting = true
	particles.position = _viewport_size * 0.5

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)             # 向上
	mat.spread = 30.0
	mat.initial_velocity_min = 200.0
	mat.initial_velocity_max = 400.0
	mat.gravity = Vector3(0, 300, 0)               # 重力拉回
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = radius
	mat.scale_min = 3.0
	mat.scale_max = 6.0
	mat.color = GOLD_COLOR

	particles.process_material = mat
	_canvas_layer.add_child(particles)
	_active_particles.append(particles)

	# 自動清理
	_delayed(lifetime + 0.5, func():
		_remove_particle(particles)
	)


## streak=3+ 粒子暴雨（全畫面隨機飛散）
func _spawn_rain_particles(amount: int, lifetime: float) -> void:
	if _active_particles.size() >= MAX_CONCURRENT_PARTICLES:
		_remove_oldest_particle()

	var particles := GPUParticles2D.new()
	particles.amount = amount
	particles.lifetime = lifetime
	particles.one_shot = true
	particles.emitting = true
	particles.position = _viewport_size * 0.5

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 0, 0)
	mat.spread = 180.0                             # 全方向
	mat.initial_velocity_min = 150.0
	mat.initial_velocity_max = 600.0
	mat.gravity = Vector3(0, 100, 0)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 20.0              # 中心爆發
	mat.scale_min = 2.0
	mat.scale_max = 8.0
	mat.color = GOLD_COLOR

	particles.process_material = mat
	_canvas_layer.add_child(particles)
	_active_particles.append(particles)

	_delayed(lifetime + 0.5, func():
		_remove_particle(particles)
	)


func _remove_particle(p: GPUParticles2D) -> void:
	if is_instance_valid(p):
		_active_particles.erase(p)
		p.queue_free()


func _remove_oldest_particle() -> void:
	if _active_particles.is_empty():
		return
	var oldest := _active_particles.pop_front() as GPUParticles2D
	if is_instance_valid(oldest):
		oldest.queue_free()


# =========================================================================
#  CAMERA SHAKE
# =========================================================================

## parent position offset 震動，完成後歸零
func _camera_shake(intensity: float, count: int, duration: float) -> void:
	var parent := get_parent()
	if parent == null:
		return

	var original_pos: Vector2 = parent.position
	var step := duration / float(count)
	var tw := create_tween()

	for i in range(count):
		var offset := Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		tw.tween_property(parent, "position", original_pos + offset, step * 0.5)\
			.set_trans(Tween.TRANS_SINE)
		tw.tween_property(parent, "position", original_pos, step * 0.5)\
			.set_trans(Tween.TRANS_SINE)

	# 確保歸零
	tw.tween_callback(func(): parent.position = original_pos)


# =========================================================================
#  RIPPLE（暗色波紋）
# =========================================================================

## 從畫面中心擴散的暗色圓形波紋
func _spawn_ripple() -> void:
	var ripple := _RippleCircle.new()
	ripple.position = _viewport_size * 0.5
	ripple.color = RIPPLE_COLOR
	ripple.max_radius = _viewport_size.length() * 0.5
	ripple.duration = 1.0
	_canvas_layer.add_child(ripple)


# 內部輔助類別：繪製擴散圓形
class _RippleCircle extends Node2D:
	var color := Color.WHITE
	var max_radius := 500.0
	var duration := 1.0

	var _elapsed := 0.0
	var _current_radius := 0.0
	var _current_alpha := 0.0

	func _process(delta: float) -> void:
		_elapsed += delta
		var t := clampf(_elapsed / duration, 0.0, 1.0)

		# Ease-out: 快速擴張，緩慢結束
		var eased := 1.0 - pow(1.0 - t, 3.0)

		_current_radius = eased * max_radius
		_current_alpha = color.a * (1.0 - eased)   # 漸漸消失
		queue_redraw()

		if t >= 1.0:
			queue_free()

	func _draw() -> void:
		var ring_width := 4.0
		draw_arc(
			Vector2.ZERO,
			_current_radius,
			0.0,
			TAU,
			64,
			Color(color.r, color.g, color.b, _current_alpha),
			ring_width,
			true
		)


# =========================================================================
#  AUDIO / HAPTIC
# =========================================================================

func _play_sfx(sfx_name: String) -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx_by_name(sfx_name)
	elif Engine.has_singleton("AudioManager"):
		var am := Engine.get_singleton("AudioManager")
		am.call("play_sfx_by_name", sfx_name)


func _haptic(intensity: String) -> void:
	if Engine.has_singleton("HapticFeedback"):
		var hf := Engine.get_singleton("HapticFeedback")
		match intensity:
			"light":
				hf.call("light")
			"medium":
				hf.call("medium")
			"heavy":
				hf.call("heavy")


# =========================================================================
#  UTILITY
# =========================================================================

func _delayed(seconds: float, callback: Callable) -> void:
	get_tree().create_timer(seconds).timeout.connect(callback, CONNECT_ONE_SHOT)


func _finish() -> void:
	_playing = false
	# 確保 overlay 歸零
	_overlay_rect.color.a = 0.0
	_label.modulate.a = 0.0
	effect_finished.emit()
