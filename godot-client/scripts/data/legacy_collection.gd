class_name LegacyCollection
extends RefCounted
## 政治遺產集合
## 管理玩家持有的所有遺產及其被動效果

# === 遺產列表 ===
var legacies: Array[LegacyData] = []


## 新增一個遺產
func add_legacy(legacy: LegacyData) -> void:
	# 避免重複
	for existing: LegacyData in legacies:
		if existing.id == legacy.id:
			push_warning("[LegacyCollection] 遺產已存在: %s" % legacy.id)
			return
	legacies.append(legacy)
	print("[LegacyCollection] 獲得遺產: %s（%s）" % [legacy.legacy_name, legacy.description])


## 移除一個遺產
func remove_legacy(legacy_id: String) -> bool:
	for i: int in range(legacies.size()):
		if legacies[i].id == legacy_id:
			legacies.remove_at(i)
			return true
	return false


## 取得所有被動效果
func get_passive_effects() -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	for legacy: LegacyData in legacies:
		if legacy.get_effect_type() == "passive":
			effects.append(legacy.effect.duplicate())
	return effects


## 在回合開始時套用所有被動效果到遊戲狀態
## 會修改 DimensionState 的維度值
func apply_passives_to_turn(dimensions: DimensionState) -> Array[Dictionary]:
	var applied: Array[Dictionary] = []
	for legacy: LegacyData in legacies:
		if legacy.get_effect_type() != "passive":
			continue

		var target: String = legacy.get_effect_target()
		var value: int = legacy.get_effect_value()

		# 檢查是否為維度目標
		if target in ["public_opinion", "treasury", "military", "diplomacy"]:
			var old_val: int = dimensions.get_dimension(target)
			var new_val: int = dimensions.modify_dimension(target, value)
			applied.append({
				"legacy_id": legacy.id,
				"legacy_name": legacy.legacy_name,
				"target": target,
				"value": value,
				"old_value": old_val,
				"new_value": new_val,
			})

	return applied


## 檢查是否有額外抽牌效果
func get_extra_draw_count() -> int:
	var extra: int = 0
	for legacy: LegacyData in legacies:
		if legacy.get_effect_type() == "passive" and legacy.get_effect_target() == "draw":
			extra += legacy.get_effect_value()
	return extra


## 檢查是否有額外行動點效果
func get_extra_action_points() -> int:
	var extra: int = 0
	for legacy: LegacyData in legacies:
		if legacy.get_effect_type() == "passive" and legacy.get_effect_target() == "action_points":
			extra += legacy.get_effect_value()
	return extra


## 取得遺產數量
func get_count() -> int:
	return legacies.size()


## 是否擁有指定遺產
func has_legacy(legacy_id: String) -> bool:
	for legacy: LegacyData in legacies:
		if legacy.id == legacy_id:
			return true
	return false


## 清空所有遺產
func clear() -> void:
	legacies.clear()


## 從 Dictionary 陣列載入
func load_from_array(data: Array) -> void:
	legacies.clear()
	for item: Variant in data:
		if item is Dictionary:
			var legacy: LegacyData = LegacyData.from_dict(item as Dictionary)
			legacies.append(legacy)


## 轉換為 Dictionary 陣列
func to_array() -> Array[Dictionary]:
	var arr: Array[Dictionary] = []
	for legacy: LegacyData in legacies:
		arr.append(legacy.to_dict())
	return arr
