class_name FactionData
extends Resource
## 派系資料模型
## 定義六個派系的所有屬性與能力
## 保守黨（保皇派）、自由派（改革派）、商行聯盟、鷹派、民社黨、外交聯盟

# === 派系類型列舉 ===
enum FactionType {
	ROYALIST,    # 保皇派 / 保守黨
	REFORMIST,   # 改革派 / 自由派
	MERCHANT,    # 商行聯盟
	HAWK,        # 鷹派
	SOCIAL,      # 民社黨
	DIPLOMATIC,  # 外交聯盟
}

# === 派系屬性 ===
@export var id: String = ""
@export var faction_name: String = ""
@export var faction_type: FactionType = FactionType.ROYALIST
@export var description: String = ""
@export var playstyle: String = ""          ## "防禦型" / "連段型" / "控制型" / "軍事型" / "平衡型" / "外交型"
@export var difficulty: int = 1             ## 1-3 星難度
@export var starting_legacy: Dictionary = {} ## 派系專屬起始遺產
@export var color_primary: Color = Color.WHITE
@export var color_secondary: Color = Color.GRAY
@export var icon_path: String = ""

# === 派系能力 ===
@export var passive_ability: Dictionary = {} ## 被動能力 { name, description, effect }
@export var active_ability: Dictionary = {}  ## 主動技能 { name, description, cooldown, effect }

# === 派系名稱映射 ===
static var faction_type_names: Dictionary = {
	FactionType.ROYALIST: "保守黨",
	FactionType.REFORMIST: "自由派",
	FactionType.MERCHANT: "商行聯盟",
	FactionType.HAWK: "鷹派",
	FactionType.SOCIAL: "民社黨",
	FactionType.DIPLOMATIC: "外交聯盟",
}

# === 派系英文名稱映射 ===
static var faction_type_names_en: Dictionary = {
	FactionType.ROYALIST: "Royalist",
	FactionType.REFORMIST: "Reformist",
	FactionType.MERCHANT: "Merchant Guild",
	FactionType.HAWK: "Hawk",
	FactionType.SOCIAL: "Social Democrat",
	FactionType.DIPLOMATIC: "Diplomatic Alliance",
}


## 取得派系類型名稱
func get_type_name() -> String:
	return faction_type_names.get(faction_type, "未知")


## 取得派系英文類型名稱
func get_type_name_en() -> String:
	return faction_type_names_en.get(faction_type, "Unknown")


## 從 Dictionary 建立 FactionData
static func from_dict(data: Dictionary) -> FactionData:
	var faction: FactionData = FactionData.new()
	faction.id = str(data.get("id", ""))
	faction.faction_name = str(data.get("faction_name", ""))
	faction.faction_type = int(data.get("faction_type", FactionType.ROYALIST)) as FactionType
	faction.description = str(data.get("description", ""))
	faction.playstyle = str(data.get("playstyle", ""))
	faction.difficulty = int(data.get("difficulty", 1))
	faction.starting_legacy = data.get("starting_legacy", {}) as Dictionary
	if data.has("color_primary"):
		faction.color_primary = Color(str(data["color_primary"]))
	if data.has("color_secondary"):
		faction.color_secondary = Color(str(data["color_secondary"]))
	faction.icon_path = str(data.get("icon_path", ""))
	faction.passive_ability = data.get("passive_ability", {}) as Dictionary
	faction.active_ability = data.get("active_ability", {}) as Dictionary
	return faction


## 轉換為 Dictionary
func to_dict() -> Dictionary:
	return {
		"id": id,
		"faction_name": faction_name,
		"faction_type": faction_type,
		"description": description,
		"playstyle": playstyle,
		"difficulty": difficulty,
		"starting_legacy": starting_legacy,
		"color_primary": color_primary.to_html(),
		"color_secondary": color_secondary.to_html(),
		"icon_path": icon_path,
		"passive_ability": passive_ability,
		"active_ability": active_ability,
	}


# ============================================================
# === 靜態派系資料 ===
# ============================================================

## 取得所有派系資料
static func get_all_factions() -> Array[FactionData]:
	return [
		_create_royalist(),
		_create_reformist(),
		_create_merchant(),
		_create_hawk(),
		_create_social(),
		_create_diplomatic(),
	]


## 根據 FactionType 取得派系資料
static func get_faction(type: FactionType) -> FactionData:
	match type:
		FactionType.ROYALIST:
			return _create_royalist()
		FactionType.REFORMIST:
			return _create_reformist()
		FactionType.MERCHANT:
			return _create_merchant()
		FactionType.HAWK:
			return _create_hawk()
		FactionType.SOCIAL:
			return _create_social()
		FactionType.DIPLOMATIC:
			return _create_diplomatic()
		_:
			return _create_royalist()


## 根據 id 取得派系資料
static func get_faction_by_id(faction_id: String) -> FactionData:
	for faction: FactionData in get_all_factions():
		if faction.id == faction_id:
			return faction
	return null


# ============================================================
# === 原有三派系 ===
# ============================================================

# === 保守黨（保皇派） ===
static func _create_royalist() -> FactionData:
	var faction: FactionData = FactionData.new()
	faction.id = "royalist"
	faction.faction_name = "保守黨"
	faction.faction_type = FactionType.ROYALIST
	faction.description = "擁護王室權威與傳統秩序的貴族聯盟。依靠軍隊與教會的支持，以穩固的防禦策略掌控議會。他們相信穩定高於一切，任何激進的改革都是對秩序的威脅。"
	faction.playstyle = "防禦型"
	faction.difficulty = 1
	faction.starting_legacy = {
		"id": "royal_charter",
		"legacy_name": "皇家特許狀",
		"description": "每回合開始時，軍事維度 +3",
		"effect": {"type": "passive", "target": "military", "value": 3},
		"source": "faction_start",
		"rarity": 1,
	}
	faction.color_primary = Color("#8B1A1A")    # 深紅
	faction.color_secondary = Color("#D4A574")  # 金銅
	faction.icon_path = "res://assets/ui/factions/royalist_icon.png"
	faction.passive_ability = {
		"name": "王室庇護",
		"description": "每回合開始時，所有友方角色防禦 +5。王室的旗幟是最堅固的盾。",
		"effect": {"type": "buff_defense", "target": "all_allies", "value": 5, "trigger": "turn_start"},
	}
	faction.active_ability = {
		"name": "御前宣令",
		"description": "以王室之名宣布一項法令，使所有敵方角色本回合攻擊力 -15%。冷卻 3 回合。",
		"cooldown": 3,
		"effect": {"type": "debuff_attack", "target": "all_enemies", "value": -0.15, "duration": 1},
	}
	return faction


# === 自由派（改革派） ===
static func _create_reformist() -> FactionData:
	var faction: FactionData = FactionData.new()
	faction.id = "reformist"
	faction.faction_name = "自由派"
	faction.faction_type = FactionType.REFORMIST
	faction.description = "追求民主與自由的改革先驅。善於操控民意與媒體輿論，以連段式的議會攻勢推動變革。他們深信人民的聲音才是最強大的武器，即使這意味著與權貴為敵。"
	faction.playstyle = "連段型"
	faction.difficulty = 2
	faction.starting_legacy = {
		"id": "press_freedom",
		"legacy_name": "新聞自由宣言",
		"description": "每回合開始時，民意維度 +3",
		"effect": {"type": "passive", "target": "public_opinion", "value": 3},
		"source": "faction_start",
		"rarity": 1,
	}
	faction.color_primary = Color("#1A3C8B")    # 深藍
	faction.color_secondary = Color("#7BA3D4")  # 淺藍
	faction.icon_path = "res://assets/ui/factions/reformist_icon.png"
	faction.passive_ability = {
		"name": "民意浪潮",
		"description": "每成功通過一項提案，下一回合所有行動牌效果 +10%。改革的動能如浪潮般不可阻擋。",
		"effect": {"type": "buff_card_effect", "target": "self", "value": 0.10, "trigger": "on_proposal_pass"},
	}
	faction.active_ability = {
		"name": "輿論風暴",
		"description": "發動一波媒體攻勢，使目標角色聲望 -15 並暴露其所有手牌。冷卻 3 回合。",
		"cooldown": 3,
		"effect": {"type": "media_attack", "target": "enemy_single", "reputation_damage": 15, "reveal_hand": true},
	}
	return faction


# === 商行聯盟 ===
static func _create_merchant() -> FactionData:
	var faction: FactionData = FactionData.new()
	faction.id = "merchant"
	faction.faction_name = "商行聯盟"
	faction.faction_type = FactionType.MERCHANT
	faction.description = "掌控金融與貿易的商業巨頭。以金錢為武器，收買議員、操控市場，用控制型策略讓對手在經濟壓力下屈服。在他們眼中，每個人都有價格，每場投票都是一筆交易。"
	faction.playstyle = "控制型"
	faction.difficulty = 3
	faction.starting_legacy = {
		"id": "trade_charter",
		"legacy_name": "貿易特許權",
		"description": "每回合開始時，財政維度 +3",
		"effect": {"type": "passive", "target": "treasury", "value": 3},
		"source": "faction_start",
		"rarity": 1,
	}
	faction.color_primary = Color("#8B7D1A")    # 金色
	faction.color_secondary = Color("#D4C874")  # 淺金
	faction.icon_path = "res://assets/ui/factions/merchant_icon.png"
	faction.passive_ability = {
		"name": "利潤至上",
		"description": "每回合結束時，根據當前財政維度額外獲得 10% 金幣。錢生錢，永不停歇。",
		"effect": {"type": "gold_income", "target": "self", "value": 0.10, "trigger": "turn_end", "base": "treasury"},
	}
	faction.active_ability = {
		"name": "市場操控",
		"description": "操控市場價格，使所有敵方角色本回合所有花費翻倍。冷卻 4 回合。",
		"cooldown": 4,
		"effect": {"type": "cost_multiplier", "target": "all_enemies", "multiplier": 2.0, "duration": 1},
	}
	return faction


# ============================================================
# === 新增三派系 ===
# ============================================================

# === 鷹派 ===
static func _create_hawk() -> FactionData:
	var faction: FactionData = FactionData.new()
	faction.id = "hawk"
	faction.faction_name = "鷹派"
	faction.faction_type = FactionType.HAWK
	faction.description = "崇尚軍事力量的激進派系。由退役將領與軍工貴族組成，堅信只有強大的武力才能保障不列顛的利益。議會是另一個戰場，而他們從不打算輸。"
	faction.playstyle = "軍事型"
	faction.difficulty = 2
	faction.starting_legacy = {
		"id": "war_medal",
		"legacy_name": "半島戰爭勳章",
		"description": "每回合開始時，攻擊維度 +3",
		"effect": {"type": "passive", "target": "attack", "value": 3},
		"source": "faction_start",
		"rarity": 1,
	}
	faction.color_primary = Color("#5C1A1A")    # 暗紅
	faction.color_secondary = Color("#A85C5C")  # 鏽紅
	faction.icon_path = "res://assets/ui/factions/hawk_icon.png"
	faction.passive_ability = {
		"name": "戰爭紅利",
		"description": "每次攻擊行動額外造成 15% 傷害。戰場上鍛鍊的殺伐之氣，在議會中同樣致命。",
		"effect": {"type": "buff_attack_damage", "target": "self", "value": 0.15, "trigger": "on_attack"},
	}
	faction.active_ability = {
		"name": "軍事動員",
		"description": "召集軍方支持，本回合所有攻擊型行動牌效果翻倍，但下回合防禦 -20%。冷卻 3 回合。",
		"cooldown": 3,
		"effect": {"type": "attack_boost", "target": "self", "attack_multiplier": 2.0, "defense_penalty": -0.20, "duration": 1},
	}
	return faction


# === 民社黨 ===
static func _create_social() -> FactionData:
	var faction: FactionData = FactionData.new()
	faction.id = "social"
	faction.faction_name = "民社黨"
	faction.faction_type = FactionType.SOCIAL
	faction.description = "關注勞工權益與社會公正的溫和改革派。不走激進路線，而是透過議會辯論與立法爭取漸進式變革。他們相信制度內的改良終將帶來真正的平等。"
	faction.playstyle = "平衡型"
	faction.difficulty = 1
	faction.starting_legacy = {
		"id": "workers_charter",
		"legacy_name": "勞工憲章草案",
		"description": "每回合開始時，民意維度與財政維度各 +2",
		"effect": {"type": "passive", "target": ["public_opinion", "treasury"], "value": 2},
		"source": "faction_start",
		"rarity": 1,
	}
	faction.color_primary = Color("#8B4513")    # 鞍棕
	faction.color_secondary = Color("#CD853F")  # 秘魯棕
	faction.icon_path = "res://assets/ui/factions/social_icon.png"
	faction.passive_ability = {
		"name": "民心所向",
		"description": "當己方聲望低於 50 時，每回合自動恢復 5 點聲望。人民不會忘記為他們說話的人。",
		"effect": {"type": "heal_reputation", "target": "self", "value": 5, "trigger": "turn_start", "condition": "reputation_below_50"},
	}
	faction.active_ability = {
		"name": "社會動員",
		"description": "發起群眾集會，使己方所有角色本回合魅力 +20%，且行動牌抽取數 +1。冷卻 2 回合。",
		"cooldown": 2,
		"effect": {"type": "rally", "target": "all_allies", "charisma_boost": 0.20, "extra_draw": 1, "duration": 1},
	}
	return faction


# === 外交聯盟 ===
static func _create_diplomatic() -> FactionData:
	var faction: FactionData = FactionData.new()
	faction.id = "diplomatic"
	faction.faction_name = "外交聯盟"
	faction.faction_type = FactionType.DIPLOMATIC
	faction.description = "由外交官與國際商人組成的跨國派系。擅長在各方勢力間斡旋，以談判與交易取代對抗。他們的武器不是劍與筆，而是承諾與妥協。"
	faction.playstyle = "外交型"
	faction.difficulty = 3
	faction.starting_legacy = {
		"id": "vienna_accord",
		"legacy_name": "維也納密約",
		"description": "每回合開始時，外交維度 +3",
		"effect": {"type": "passive", "target": "diplomacy", "value": 3},
		"source": "faction_start",
		"rarity": 1,
	}
	faction.color_primary = Color("#2E5E4E")    # 深松綠
	faction.color_secondary = Color("#7FB5A0")  # 淺翡翠
	faction.icon_path = "res://assets/ui/factions/diplomatic_icon.png"
	faction.passive_ability = {
		"name": "和平紅利",
		"description": "每當成功與一個派系締結同盟，雙方各獲得 10 點聲望。外交的藝術在於讓每個人都是贏家。",
		"effect": {"type": "alliance_bonus", "target": "both", "value": 10, "trigger": "on_alliance_form"},
	}
	faction.active_ability = {
		"name": "和談桌",
		"description": "強制結束當前衝突，雙方回復至衝突前狀態，並各自獲得 5 金幣補償。冷卻 4 回合。",
		"cooldown": 4,
		"effect": {"type": "force_peace", "target": "conflict_parties", "gold_compensation": 5, "restore_state": true},
	}
	return faction
