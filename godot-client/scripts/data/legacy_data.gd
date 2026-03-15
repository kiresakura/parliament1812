class_name LegacyData
extends Resource
## 政治遺產資料模型
## 代表議會行動中獲得的持久性被動效果

# === 遺產屬性 ===
@export var id: String = ""
@export var legacy_name: String = ""
@export var description: String = ""
@export var effect: Dictionary = {}   ## {"type": "passive", "target": "draw", "value": 1}
@export var source: String = ""       ## "bill_passed" / "event" / "faction_start"
@export var rarity: int = 0           ## 0=普通, 1=罕見, 2=稀有


## 從 Dictionary 建立 LegacyData
static func from_dict(data: Dictionary) -> LegacyData:
	var legacy: LegacyData = LegacyData.new()
	legacy.id = str(data.get("id", ""))
	legacy.legacy_name = str(data.get("legacy_name", ""))
	legacy.description = str(data.get("description", ""))
	legacy.effect = data.get("effect", {}) as Dictionary
	legacy.source = str(data.get("source", ""))
	legacy.rarity = int(data.get("rarity", 0))
	return legacy


## 轉換為 Dictionary
func to_dict() -> Dictionary:
	return {
		"id": id,
		"legacy_name": legacy_name,
		"description": description,
		"effect": effect,
		"source": source,
		"rarity": rarity,
	}


## 取得效果類型
func get_effect_type() -> String:
	return str(effect.get("type", "passive"))


## 取得效果目標
func get_effect_target() -> String:
	return str(effect.get("target", ""))


## 取得效果數值
func get_effect_value() -> int:
	return int(effect.get("value", 0))
