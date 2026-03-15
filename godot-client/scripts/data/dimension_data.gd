class_name DimensionState
extends RefCounted
## 四維度系統
## 管理民意、財政、軍事、外交四個維度的狀態與變化
## 維度範圍 0-100，任一歸零即觸發破產（GAME_OVER）

# === 信號（透過 Signal Bus 或直接連接） ===
# 注意：RefCounted 不能用 signal，改用回調模式

# === 常數 ===
const MIN_VALUE: int = 0
const MAX_VALUE: int = 100
const DEFAULT_VALUE: int = 50
const DANGER_LOW: int = 20     ## 低於此值進入危險區
const DANGER_HIGH: int = 80    ## 高於此值進入過熱區

## 預算等級對應行動點上限
const BUDGET_LEVELS: Dictionary = {
	0: 2,   # treasury 0-19：只有 2 行動點
	1: 3,   # treasury 20-39：3 行動點
	2: 4,   # treasury 40-59：4 行動點（標準）
	3: 5,   # treasury 60-79：5 行動點
	4: 6,   # treasury 80-100：6 行動點（富裕）
}

# === 四維度 ===
var public_opinion: int = DEFAULT_VALUE  ## 民意 0-100
var treasury: int = DEFAULT_VALUE        ## 財政 0-100
var military: int = DEFAULT_VALUE        ## 軍事 0-100
var diplomacy: int = DEFAULT_VALUE       ## 外交 0-100

# === 維度名稱映射 ===
static var dimension_names: Dictionary = {
	"public_opinion": "民意",
	"treasury": "財政",
	"military": "軍事",
	"diplomacy": "外交",
}

# === 維度顏色映射 ===
static var dimension_colors: Dictionary = {
	"public_opinion": Color(0.2, 0.7, 0.3),   # 綠色
	"treasury": Color(0.78, 0.66, 0.31),       # 金色
	"military": Color(0.7, 0.2, 0.2),          # 紅色
	"diplomacy": Color(0.2, 0.4, 0.8),         # 藍色
}


## 重置所有維度為預設值
func reset() -> void:
	public_opinion = DEFAULT_VALUE
	treasury = DEFAULT_VALUE
	military = DEFAULT_VALUE
	diplomacy = DEFAULT_VALUE


## 取得指定維度的值
func get_dimension(dimension_key: String) -> int:
	match dimension_key:
		"public_opinion":
			return public_opinion
		"treasury":
			return treasury
		"military":
			return military
		"diplomacy":
			return diplomacy
		_:
			push_warning("[DimensionState] 未知維度: %s" % dimension_key)
			return 0


## 設定指定維度的值（自動 clamp）
func set_dimension(dimension_key: String, value: int) -> void:
	var clamped: int = clampi(value, MIN_VALUE, MAX_VALUE)
	match dimension_key:
		"public_opinion":
			public_opinion = clamped
		"treasury":
			treasury = clamped
		"military":
			military = clamped
		"diplomacy":
			diplomacy = clamped
		_:
			push_warning("[DimensionState] 未知維度: %s" % dimension_key)


## 修改指定維度的值（增減）
func modify_dimension(dimension_key: String, delta: int) -> int:
	var old_value: int = get_dimension(dimension_key)
	var new_value: int = clampi(old_value + delta, MIN_VALUE, MAX_VALUE)
	set_dimension(dimension_key, new_value)
	return new_value


## 套用卡牌效果
## 效果格式：{"dimension": "treasury", "value": -10} 或 {"type": "draw", "value": 2}
func apply_card_effect(effect: Dictionary) -> Dictionary:
	var result: Dictionary = {"applied": false, "dimension": "", "old_value": 0, "new_value": 0}

	if effect.has("dimension"):
		var dim_key: String = str(effect["dimension"])
		var value: int = int(effect.get("value", 0))
		var old_val: int = get_dimension(dim_key)
		var new_val: int = modify_dimension(dim_key, value)
		result = {
			"applied": true,
			"dimension": dim_key,
			"old_value": old_val,
			"new_value": new_val,
			"delta": new_val - old_val,
		}

	return result


## 批次套用多個效果
func apply_effects(effects: Array) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for effect: Variant in effects:
		if effect is Dictionary:
			var r: Dictionary = apply_card_effect(effect as Dictionary)
			if r.get("applied", false):
				results.append(r)
	return results


## 檢查閾值事件
## 當維度進入危險區或過熱區時觸發
func check_threshold_events() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var dimensions: Dictionary = get_all_dimensions()

	for dim_key: String in dimensions:
		var value: int = dimensions[dim_key] as int
		var dim_name: String = dimension_names.get(dim_key, dim_key)

		if value <= 0:
			events.append({
				"type": "bankrupt",
				"dimension": dim_key,
				"dimension_name": dim_name,
				"value": value,
				"message": "%s崩潰！國家陷入危機！" % dim_name,
			})
		elif value < DANGER_LOW:
			events.append({
				"type": "danger_low",
				"dimension": dim_key,
				"dimension_name": dim_name,
				"value": value,
				"message": "%s告急！（%d/100）" % [dim_name, value],
			})
		elif value > DANGER_HIGH:
			events.append({
				"type": "danger_high",
				"dimension": dim_key,
				"dimension_name": dim_name,
				"value": value,
				"message": "%s過熱！（%d/100）" % [dim_name, value],
			})

	return events


## 任一維度歸零（破產檢查）
func is_any_dimension_zero() -> bool:
	return public_opinion <= 0 or treasury <= 0 or military <= 0 or diplomacy <= 0


## 任一維度達到最大值
func is_any_dimension_max() -> bool:
	return public_opinion >= MAX_VALUE or treasury >= MAX_VALUE or military >= MAX_VALUE or diplomacy >= MAX_VALUE


## 根據 treasury 回傳行動點上限
func get_budget_level() -> int:
	var tier: int = treasury / 20  # 0-4（每 20 一個檔次）
	tier = clampi(tier, 0, 4)
	return BUDGET_LEVELS.get(tier, 4)


## 取得所有維度的 Dictionary
func get_all_dimensions() -> Dictionary:
	return {
		"public_opinion": public_opinion,
		"treasury": treasury,
		"military": military,
		"diplomacy": diplomacy,
	}


## 取得指定維度是否處於危險區
func is_dimension_in_danger(dimension_key: String) -> bool:
	var value: int = get_dimension(dimension_key)
	return value < DANGER_LOW or value > DANGER_HIGH


## 取得指定維度的危險等級
## 0: 正常, 1: 低危, 2: 高危, 3: 破產
func get_danger_level(dimension_key: String) -> int:
	var value: int = get_dimension(dimension_key)
	if value <= 0:
		return 3  # 破產
	elif value < DANGER_LOW:
		return 1  # 低危
	elif value > DANGER_HIGH:
		return 2  # 高危
	return 0  # 正常


## 從 Dictionary 載入狀態
func load_from_dict(data: Dictionary) -> void:
	public_opinion = int(data.get("public_opinion", DEFAULT_VALUE))
	treasury = int(data.get("treasury", DEFAULT_VALUE))
	military = int(data.get("military", DEFAULT_VALUE))
	diplomacy = int(data.get("diplomacy", DEFAULT_VALUE))


## 轉換為 Dictionary
func to_dict() -> Dictionary:
	return get_all_dimensions()
