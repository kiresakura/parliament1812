class_name DimensionHUD
extends HBoxContainer
## 四維度 HUD 組件（Portrait 直立模式：水平排列 4 個維度）
## 顯示民意、財政、軍事、外交四個維度的直立條
## 數值變化時有動畫（顏色閃爍 + 數字滾動）
## 危險區域（<20 或 >80）變紅/變金
## 響應式：根據 viewport 動態計算所有尺寸

# === 基準常數（依 viewport 縮放） ===
const BASE_BAR_HEIGHT: float = 50.0
const BASE_BAR_WIDTH: float = 80.0
const BASE_LABEL_WIDTH: float = 60.0
const BASE_VALUE_WIDTH: float = 40.0
const ANIMATION_DURATION: float = 0.4
const FLASH_DURATION: float = 0.3

const DIMENSION_ORDER: Array[String] = ["public_opinion", "treasury", "military", "diplomacy"]
const DIMENSION_ICONS: Dictionary = {
	"public_opinion": "👥",
	"treasury": "💰",
	"military": "⚔",
	"diplomacy": "🤝",
}

# === 危險顏色 ===
const COLOR_NORMAL: Color = Color(0.3, 0.3, 0.3)
const COLOR_DANGER_LOW: Color = Color(0.8, 0.2, 0.2)    # 紅色
const COLOR_DANGER_HIGH: Color = Color(0.78, 0.66, 0.31) # 金色

# === 內部節點 ===
var _bars: Dictionary = {}          ## dim_key -> ProgressBar
var _value_labels: Dictionary = {}  ## dim_key -> Label
var _name_labels: Dictionary = {}   ## dim_key -> Label
var _rows: Dictionary = {}          ## dim_key -> HBoxContainer
var _current_values: Dictionary = {} ## dim_key -> int

# === 行動點顯示 ===
var _ap_label: Label = null

# === 響應式尺寸 ===
var _bar_width: float = BASE_BAR_WIDTH
var _bar_height: float = BASE_BAR_HEIGHT
var _label_width: float = BASE_LABEL_WIDTH
var _value_width: float = BASE_VALUE_WIDTH


func _ready() -> void:
	_calculate_sizes()
	_build_ui()


## 計算響應式尺寸（直立模式：4 欄水平排列）
func _calculate_sizes() -> void:
	var sf: float = UIScaleClass.scale_factor()
	var vp: Vector2 = UIScaleClass.get_viewport_size()
	# 每個維度欄佔螢幕寬度約 1/5（留空間給行動點標籤）
	var col_w: float = vp.x * 0.18
	_bar_width = minf(BASE_BAR_WIDTH * sf, col_w)
	_bar_height = BASE_BAR_HEIGHT * sf
	_label_width = minf(BASE_LABEL_WIDTH * sf, col_w)
	_value_width = minf(BASE_VALUE_WIDTH * sf, col_w * 0.4)


# ============================================================
# === UI 建構 ===
# ============================================================

func _build_ui() -> void:
	var sf: float = UIScaleClass.scale_factor()

	# HBoxContainer 容器設定（水平排列 4 個維度 + 行動點）
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", int(6.0 * sf))

	# 四個維度直欄
	for dim_key: String in DIMENSION_ORDER:
		var col: VBoxContainer = _create_dimension_column(dim_key)
		add_child(col)
		_rows[dim_key] = col
		_current_values[dim_key] = DimensionState.DEFAULT_VALUE

	# 分隔
	var sep: VSeparator = VSeparator.new()
	sep.add_theme_constant_override("separation", int(3.0 * sf))
	add_child(sep)

	# 行動點顯示
	var ap_vbox: VBoxContainer = VBoxContainer.new()
	ap_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_ap_label = Label.new()
	_ap_label.text = "AP\n4/4"
	_ap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ap_label.add_theme_font_size_override("font_size", UIScaleClass.font_size(12))
	_ap_label.add_theme_color_override("font_color", Color(0.91, 0.835, 0.718))
	ap_vbox.add_child(_ap_label)
	add_child(ap_vbox)


func _create_dimension_column(dim_key: String) -> VBoxContainer:
	var sf: float = UIScaleClass.scale_factor()
	var col: VBoxContainer = VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", int(2.0 * sf))
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# 圖示
	var name_lbl: Label = Label.new()
	var icon: String = DIMENSION_ICONS.get(dim_key, "")
	name_lbl.text = icon
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", UIScaleClass.font_size(14))
	name_lbl.add_theme_color_override("font_color", Color(0.85, 0.82, 0.78))
	col.add_child(name_lbl)
	_name_labels[dim_key] = name_lbl

	# 進度條（水平）
	var bar: ProgressBar = ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = DimensionState.DEFAULT_VALUE
	bar.custom_minimum_size = Vector2(_bar_width, _bar_height * 0.45)
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# 設定進度條樣式
	var bg_style: StyleBoxFlat = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.15, 0.15)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("background", bg_style)

	var fill_style: StyleBoxFlat = StyleBoxFlat.new()
	fill_style.bg_color = DimensionState.dimension_colors.get(dim_key, Color.WHITE)
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("fill", fill_style)

	col.add_child(bar)
	_bars[dim_key] = bar

	# 數值標籤
	var val_lbl: Label = Label.new()
	val_lbl.text = str(DimensionState.DEFAULT_VALUE)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val_lbl.add_theme_font_size_override("font_size", UIScaleClass.font_size(11))
	val_lbl.add_theme_color_override("font_color", Color(0.91, 0.835, 0.718))
	col.add_child(val_lbl)
	_value_labels[dim_key] = val_lbl

	return col


# ============================================================
# === 公開方法 ===
# ============================================================

## 更新所有維度顯示（帶動畫）
func update_dimensions(dimensions: DimensionState) -> void:
	for dim_key: String in DIMENSION_ORDER:
		var new_value: int = dimensions.get_dimension(dim_key)
		var old_value: int = _current_values.get(dim_key, DimensionState.DEFAULT_VALUE) as int
		if new_value != old_value:
			_animate_value_change(dim_key, old_value, new_value)
		_current_values[dim_key] = new_value


## 直接設定維度（無動畫）
func set_dimensions(dimensions: DimensionState) -> void:
	for dim_key: String in DIMENSION_ORDER:
		var value: int = dimensions.get_dimension(dim_key)
		_current_values[dim_key] = value
		if _bars.has(dim_key):
			(_bars[dim_key] as ProgressBar).value = value
		if _value_labels.has(dim_key):
			(_value_labels[dim_key] as Label).text = str(value)
		_update_danger_style(dim_key, value)


## 更新行動點顯示
func update_action_points(current: int, max_ap: int) -> void:
	if _ap_label:
		_ap_label.text = "AP\n%d/%d" % [current, max_ap]
		if current <= 0:
			_ap_label.add_theme_color_override("font_color", Color(0.6, 0.3, 0.3))
		elif current <= 1:
			_ap_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.2))
		else:
			_ap_label.add_theme_color_override("font_color", Color(0.91, 0.835, 0.718))


# ============================================================
# === 動畫 ===
# ============================================================

func _animate_value_change(dim_key: String, old_value: int, new_value: int) -> void:
	var bar: ProgressBar = _bars.get(dim_key) as ProgressBar
	var val_lbl: Label = _value_labels.get(dim_key) as Label
	if bar == null or val_lbl == null:
		return

	# 進度條動畫
	var tween: Tween = create_tween()
	tween.tween_property(bar, "value", float(new_value), ANIMATION_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	# 數字滾動動畫
	var counter_tween: Tween = create_tween()
	counter_tween.tween_method(
		func(v: float) -> void:
			val_lbl.text = str(int(v)),
		float(old_value), float(new_value), ANIMATION_DURATION
	).set_ease(Tween.EASE_OUT)

	# 閃爍效果
	var delta: int = new_value - old_value
	var flash_color: Color
	if delta > 0:
		flash_color = Color(0.3, 0.9, 0.3)  # 綠色增加
	else:
		flash_color = Color(0.9, 0.3, 0.3)  # 紅色減少

	var flash_tween: Tween = create_tween()
	flash_tween.tween_property(val_lbl, "theme_override_colors/font_color", flash_color, FLASH_DURATION / 2.0)
	flash_tween.tween_property(val_lbl, "theme_override_colors/font_color", Color(0.91, 0.835, 0.718), FLASH_DURATION / 2.0)

	# 更新危險樣式
	_update_danger_style(dim_key, new_value)


func _update_danger_style(dim_key: String, value: int) -> void:
	var bar: ProgressBar = _bars.get(dim_key) as ProgressBar
	var name_lbl: Label = _name_labels.get(dim_key) as Label
	if bar == null:
		return

	var fill_style: StyleBoxFlat = bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill_style == null:
		return

	# 複製樣式避免共享引用問題
	fill_style = fill_style.duplicate() as StyleBoxFlat

	if value < DimensionState.DANGER_LOW:
		# 低危：紅色
		fill_style.bg_color = COLOR_DANGER_LOW
		if name_lbl:
			name_lbl.add_theme_color_override("font_color", COLOR_DANGER_LOW)
	elif value > DimensionState.DANGER_HIGH:
		# 高危：金色
		fill_style.bg_color = COLOR_DANGER_HIGH
		if name_lbl:
			name_lbl.add_theme_color_override("font_color", COLOR_DANGER_HIGH)
	else:
		# 正常：原色
		fill_style.bg_color = DimensionState.dimension_colors.get(dim_key, Color.WHITE)
		if name_lbl:
			name_lbl.add_theme_color_override("font_color", Color(0.85, 0.82, 0.78))

	bar.add_theme_stylebox_override("fill", fill_style)
