class_name CardData
extends Resource
## 卡牌資料模型
## 定義卡牌的所有屬性與稀有度
## 支援本地（SP）和 Server（MP）兩種資料格式

# === 稀有度列舉（對齊 server 4 級） ===
enum Rarity {
	COMMON,     # N — server: "normal"
	RARE,       # R — server: "rare"
	EPIC,       # SR — server: "super_rare"
	LEGENDARY,  # SSR — server: "legendary"
}

# === 卡牌類型列舉（SP 維度系統） ===
enum CardType {
	PROPOSAL,   # 提案卡：發起議案
	DEBATE,     # 辯論卡：影響投票
	ALLIANCE,   # 結盟卡：改變陣營
	TACTIC,     # 策略卡：特殊效果
	EVENT,      # 事件卡：隨機事件
}

# === 卡牌屬性（共用） ===
@export var id: String = ""
@export var card_name: String = ""
@export var description: String = ""
@export var card_type: CardType = CardType.PROPOSAL
@export var rarity: Rarity = Rarity.COMMON
@export var cost: int = 0
@export var power: int = 0
@export var influence: int = 0
@export var art_path: String = ""
@export var effects: Array[Dictionary] = []  # SP 維度效果

# === Server（MP）專用屬性 ===
@export var server_card_type: String = ""   # server 原始 card_type 字串
@export var target_type: String = "none"    # 目標類型
@export var influence_cost: int = 0         # 影響力消耗
@export var gold_cost: int = 0              # 金幣消耗
@export var base_value: int = 0             # 基礎數值
@export var role_id: String = ""            # 角色專屬 ID

# === Server → Client 映射表 ===
static var _server_rarity_map: Dictionary = {
	"normal": Rarity.COMMON,
	"rare": Rarity.RARE,
	"super_rare": Rarity.EPIC,
	"legendary": Rarity.LEGENDARY,
}

static var _server_type_map: Dictionary = {
	"attack": CardType.DEBATE,
	"defense": CardType.TACTIC,
	"utility": CardType.ALLIANCE,
	"signature": CardType.EVENT,
}

# === 稀有度對應顏色（羅塞蒂色表 v2） ===
static var rarity_colors: Dictionary = {
	Rarity.COMMON: Color(0.549, 0.416, 0.247, 1.0),   # N 銅褐 #8C6A3F
	Rarity.RARE: Color(0.659, 0.722, 0.784, 1.0),      # R 銀藍 #A8B8C8
	Rarity.EPIC: Color(0.6, 0.2, 0.8, 1.0),             # SR 紫色
	Rarity.LEGENDARY: Color(0.784, 0.659, 0.306, 1.0),  # SSR 金色 #C8A84E
}

# === 稀有度對應卡框圖片路徑 ===
static var rarity_frame_paths: Dictionary = {
	Rarity.COMMON: "res://assets/ui/cards/card-frame-N.png",
	Rarity.RARE: "res://assets/ui/cards/card-frame-R.png",
	Rarity.EPIC: "res://assets/ui/cards/card-frame-SR.png",
	Rarity.LEGENDARY: "res://assets/ui/cards/card-frame-SSR.png",
}

# === 稀有度對應名稱 ===
static var rarity_names: Dictionary = {
	Rarity.COMMON: "普通",
	Rarity.RARE: "稀有",
	Rarity.EPIC: "史詩",
	Rarity.LEGENDARY: "傳說",
}

# === 卡牌類型對應名稱 ===
static var type_names: Dictionary = {
	CardType.PROPOSAL: "提案",
	CardType.DEBATE: "辯論",
	CardType.ALLIANCE: "結盟",
	CardType.TACTIC: "策略",
	CardType.EVENT: "事件",
}


## 從 Dictionary 建立 CardData（自動偵測本地/server 格式）
static func from_dict(data: Dictionary) -> CardData:
	if data.is_empty():
		return null
	# 偵測格式：server 的 card_type 是字串，本地是整數
	var is_server_format: bool = data.has("card_type") and data.get("card_type") is String
	if is_server_format:
		return _from_server_dict(data)
	else:
		return _from_local_dict(data)


## 從本地（SP）格式建立（card_database.gd 使用）
static func _from_local_dict(data: Dictionary) -> CardData:
	var card: CardData = CardData.new()
	card.id = str(data.get("id", ""))
	card.card_name = str(data.get("name", ""))
	card.description = str(data.get("description", ""))
	card.card_type = int(data.get("type", CardType.PROPOSAL)) as CardType
	card.rarity = int(data.get("rarity", Rarity.COMMON)) as Rarity
	card.cost = int(data.get("cost", 0))
	card.power = int(data.get("power", 0))
	card.influence = int(data.get("influence", 0))
	card.art_path = str(data.get("art_path", ""))
	# 安全轉換 effects 為 Array[Dictionary]
	var raw_effects: Variant = data.get("effects", [])
	if raw_effects is Array:
		for e: Variant in raw_effects:
			if e is Dictionary:
				card.effects.append(e as Dictionary)
	# Server 欄位（本地卡也可帶，用於雙模式支援）
	card.server_card_type = str(data.get("server_card_type", ""))
	card.target_type = str(data.get("target_type", "none"))
	card.influence_cost = int(data.get("influence_cost", card.cost))
	card.gold_cost = int(data.get("gold_cost", 0))
	card.base_value = int(data.get("base_value", card.power))
	card.role_id = str(data.get("role_id", ""))
	return card


## 從 Server（MP）格式建立（CardInfo via WebSocket）
static func _from_server_dict(data: Dictionary) -> CardData:
	var card: CardData = CardData.new()
	card.id = str(data.get("id", ""))
	card.card_name = str(data.get("name", ""))
	card.description = str(data.get("description", ""))

	# card_type: string → CardType enum
	var raw_type: String = str(data.get("card_type", ""))
	card.server_card_type = raw_type
	card.card_type = _server_type_map.get(raw_type, CardType.PROPOSAL) as CardType

	# rarity: string → Rarity enum
	var raw_rarity: String = str(data.get("rarity", "normal"))
	card.rarity = _server_rarity_map.get(raw_rarity, Rarity.COMMON) as Rarity

	# Server 專用欄位
	card.target_type = str(data.get("target_type", "none"))
	card.influence_cost = int(data.get("influence_cost", 0))
	card.gold_cost = int(data.get("gold_cost", 0))
	card.base_value = int(data.get("base_value", 0))
	card.role_id = str(data.get("role_id", ""))

	# cost 取 influence_cost 作為 fallback
	card.cost = card.influence_cost
	card.power = card.base_value

	return card


## 轉換為 Dictionary
func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": card_name,
		"description": description,
		"type": card_type,
		"rarity": rarity,
		"cost": cost,
		"power": power,
		"influence": influence,
		"art_path": art_path,
		"effects": effects,
	}


## 是否需要選擇目標
func requires_target() -> bool:
	return target_type in ["single_enemy", "single_ally", "single_any"]


## 取得稀有度顏色
func get_rarity_color() -> Color:
	return rarity_colors.get(rarity, Color.WHITE)


## 取得稀有度名稱
func get_rarity_name() -> String:
	return rarity_names.get(rarity, "未知")


## 取得類型名稱
func get_type_name() -> String:
	return type_names.get(card_type, "未知")


## 取得卡框圖片路徑
func get_frame_path() -> String:
	return rarity_frame_paths.get(rarity, rarity_frame_paths[Rarity.COMMON])
