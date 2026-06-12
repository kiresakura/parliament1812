class_name VictoryScreen
extends Control
## 勝利結算動效系統
## MOTION_SPEC 第七章 — 勝利結算
##
## 時間線：
##   T+0ms    金色光爆粒子（GPUParticles2D, amount=200, 2s）
##   T+200ms  BGM 切換勝利版本
##   T+500ms  「勝利！」標題彈入（scale 0→1.3→1.0, 300ms）
##   T+800ms  戰績逐項計數顯示（每項 300ms 間隔）
##
## 粒子上限：1 個 GPUParticles2D

# === 信號 ===
signal victory_sequence_finished()

# === 常數 ===
const GOLD_COLOR := Color(0.788, 0.659, 0.298, 1.0)  # #C9A84C
const PARTICLE_AMOUNT: int = 200
const PARTICLE_LIFETIME: float = 2.0
const PARTICLE_LAYER: int = 80

const DELAY_BGM_MS: float = 0.2          # T+200ms
const DELAY_TITLE_MS: float = 0.5        # T+500ms
const DELAY_STATS_MS: float = 0.8        # T+800ms

const TITLE_BOUNCE_UP_DURATION: float = 0.15
const TITLE_BOUNCE_DOWN_DURATION: float = 0.15
const TITLE_FADE_DURATION: float = 0.1
const TITLE_OVERSHOOT_SCALE := Vector2(1.3, 1.3)
const TITLE_FINAL_SCALE := Vector2(1.0, 1.0)

const STAT_INTERVAL: float = 0.3
const STAT_COUNT_DURATION: float = 0.3

# === 節點參考（與 result_screen.tscn 對應）===
@onready var result_title: Label = $VBox/ResultTitle
@onready var player_list: VBoxContainer = $VBox/PlayerList
@onready var reward_label: Label = $VBox/RewardLabel
@onready var rating_change: Label = $VBox/RatingChange

# === 內部狀態 ===
var _particles: GPUParticles2D = null
var _particle_layer: CanvasLayer = null
var _sequence_running: bool = false
var _stat_labels: Array[Label] = []


func _ready() -> void:
	_setup_particles()


# ============================================================
# 公開方法
# ============================================================

## 播放完整勝利結算序列
func play_victory_sequence() -> void:
	if _sequence_running:
		return
	_sequence_running = true

	# --- T+0ms: 金色光爆 ---
	_fire_particles()

	# --- T+200ms: BGM 切換 ---
	var bgm_timer: SceneTreeTimer = get_tree().create_timer(DELAY_BGM_MS)
	bgm_timer.timeout.connect(_play_victory_music)

	# --- T+500ms: 勝利標題 ---
	var title_timer: SceneTreeTimer = get_tree().create_timer(DELAY_TITLE_MS)
	title_timer.timeout.connect(_animate_title)

	# --- T+800ms: 等待標題開始後再啟動戰績（由 show_stats 外部呼叫或內部自動） ---
	# 戰績由外部呼叫 show_stats()，或可在此接續


## 顯示戰績數值（逐項計數）
## stats 格式: [{label: String, value: int}, ...]
func show_stats(stats: Array[Dictionary]) -> void:
	# 清除舊的 stat labels
	_clear_stat_labels()

	if stats.is_empty():
		_finish_sequence()
		return

	# 逐項顯示
	for i: int in range(stats.size()):
		var delay: float = DELAY_STATS_MS + (i * STAT_INTERVAL)
		var stat: Dictionary = stats[i]
		var timer: SceneTreeTimer = get_tree().create_timer(delay)
		var is_last: bool = (i == stats.size() - 1)
		# 用 Callable bind 傳遞參數
		timer.timeout.connect(_animate_single_stat.bind(stat, is_last))


# ============================================================
# 粒子系統
# ============================================================

## 預建粒子節點（只建 1 個）
func _setup_particles() -> void:
	# CanvasLayer (layer=80)
	_particle_layer = CanvasLayer.new()
	_particle_layer.layer = PARTICLE_LAYER
	add_child(_particle_layer)

	# GPUParticles2D
	_particles = GPUParticles2D.new()
	_particles.emitting = false
	_particles.amount = PARTICLE_AMOUNT
	_particles.one_shot = true
	_particles.explosiveness = 1.0
	_particles.lifetime = PARTICLE_LIFETIME

	# 定位畫面中央
	_particles.position = get_viewport_rect().size / 2.0

	# ParticleProcessMaterial
	var mat := ParticleProcessMaterial.new()

	# 球形發射（向四周爆散）
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 10.0  # 起始聚攏

	# 方向：向外爆散（radial）
	mat.direction = Vector3(1.0, 0.0, 0.0)
	mat.spread = 180.0  # 完整 360 度

	# 速度
	mat.initial_velocity_min = 300.0
	mat.initial_velocity_max = 800.0

	# 重力歸零（太空爆散感）
	mat.gravity = Vector3.ZERO

	# 阻尼（讓粒子慢慢停下）
	mat.damping_min = 2.0
	mat.damping_max = 5.0

	# 顏色：金色 → 透明
	var color_ramp := Gradient.new()
	color_ramp.colors = PackedColorArray([
		GOLD_COLOR,
		Color(GOLD_COLOR.r, GOLD_COLOR.g, GOLD_COLOR.b, 0.0),
	])
	color_ramp.offsets = PackedFloat32Array([0.0, 1.0])
	var color_texture := GradientTexture1D.new()
	color_texture.gradient = color_ramp
	mat.color_ramp = color_texture

	# 初始顏色也設定金色
	mat.color = GOLD_COLOR

	# 縮放：從大到小
	var scale_curve := Curve.new()
	scale_curve.add_point(Vector2(0.0, 1.0))
	scale_curve.add_point(Vector2(0.5, 0.6))
	scale_curve.add_point(Vector2(1.0, 0.0))
	var scale_texture := CurveTexture.new()
	scale_texture.curve = scale_curve
	mat.scale_curve = scale_texture
	mat.scale_min = 3.0
	mat.scale_max = 8.0

	_particles.process_material = mat
	_particle_layer.add_child(_particles)


## 發射粒子
func _fire_particles() -> void:
	if not _particles:
		return
	# 更新位置（防止 viewport 尺寸變化）
	_particles.position = get_viewport_rect().size / 2.0
	_particles.restart()
	_particles.emitting = true


# ============================================================
# 音樂
# ============================================================

## 播放勝利 BGM
func _play_victory_music() -> void:
	if not has_node("/root/AudioManager"):
		push_warning("[VictoryScreen] AudioManager 不存在，跳過 BGM")
		return
	var audio_mgr: Node = get_node("/root/AudioManager")
	audio_mgr.play_music(AudioManagerClass.MusicTrack.GAME_OVER)


# ============================================================
# 標題動畫
# ============================================================

## 「勝利！」彈入動畫
func _animate_title() -> void:
	if not result_title:
		return

	result_title.text = "勝利！"
	result_title.add_theme_color_override("font_color", GOLD_COLOR)
	result_title.pivot_offset = result_title.size / 2.0

	# 初始狀態
	result_title.scale = Vector2.ZERO
	result_title.modulate.a = 0.0

	# Tween: fade in (100ms) + scale overshoot (150ms) + settle (150ms)
	var tween: Tween = create_tween()
	tween.set_parallel(true)

	# 淡入
	tween.tween_property(
		result_title, "modulate:a", 1.0, TITLE_FADE_DURATION
	)

	# Scale: 0 → 1.3（Ease Out, 150ms）
	tween.tween_property(
		result_title, "scale", TITLE_OVERSHOOT_SCALE, TITLE_BOUNCE_UP_DURATION
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Scale: 1.3 → 1.0（Ease In-Out, 150ms，delay 150ms）
	tween.tween_property(
		result_title, "scale", TITLE_FINAL_SCALE, TITLE_BOUNCE_DOWN_DURATION
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD).set_delay(
		TITLE_BOUNCE_UP_DURATION
	)


# ============================================================
# 戰績計數
# ============================================================

## 動畫顯示單一戰績項
func _animate_single_stat(stat: Dictionary, is_last: bool) -> void:
	var label_text: String = stat.get("label", "")
	var target_value: int = stat.get("value", 0)

	# 建立 Label
	var stat_label := Label.new()
	stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stat_label.add_theme_font_size_override("font_size", 24)
	stat_label.add_theme_color_override("font_color", Color(0.91, 0.835, 0.718, 1.0))
	stat_label.text = "%s: 0" % label_text

	# 淡入
	stat_label.modulate.a = 0.0

	if player_list:
		player_list.add_child(stat_label)
	else:
		add_child(stat_label)
	_stat_labels.append(stat_label)

	# 淡入 Tween
	var fade_tween: Tween = create_tween()
	fade_tween.tween_property(stat_label, "modulate:a", 1.0, 0.1)

	# 計數 Tween（0 → target_value）
	var counter := {"current": 0}
	var count_tween: Tween = create_tween()
	count_tween.tween_method(
		func(val: int) -> void:
			counter["current"] = val
			stat_label.text = "%s: %d" % [label_text, val],
		0,
		target_value,
		STAT_COUNT_DURATION
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	# 計數完畢 → 播放輕微音效
	count_tween.finished.connect(func() -> void:
		_play_stat_sfx()
		if is_last:
			_finish_sequence()
	)


## 播放戰績到位音效
func _play_stat_sfx() -> void:
	if not has_node("/root/AudioManager"):
		return
	var audio_mgr: Node = get_node("/root/AudioManager")
	audio_mgr.play_sfx(AudioManagerClass.SFX.COIN_COLLECT)


## 清除舊 stat labels
func _clear_stat_labels() -> void:
	for lbl: Label in _stat_labels:
		if is_instance_valid(lbl):
			lbl.queue_free()
	_stat_labels.clear()


# ============================================================
# 序列結束
# ============================================================

## 標記序列完成
func _finish_sequence() -> void:
	_sequence_running = false
	victory_sequence_finished.emit()


# ============================================================
# 清理
# ============================================================

func _exit_tree() -> void:
	_clear_stat_labels()
	if is_instance_valid(_particle_layer):
		_particle_layer.queue_free()
