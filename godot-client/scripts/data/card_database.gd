class_name CardDatabase
extends RefCounted
## MVP 卡牌資料庫（98 張）
## 每派系 14 張專屬 + 14 張通用
## 保守黨：軍事威嚇、教會支持、貴族特權、皇室權威
## 自由派：民意動員、言論自由、改革法案、媒體操控
## 商行聯盟：貿易協定、金融操作、市場壟斷、殖民擴張
## 鷹派：軍事動員、砲艦外交、焦土戰術、軍事政變
## 民社黨：勞工請願、工廠法案、集體談判、社會契約
## 外交聯盟：外交照會、條約談判、國際仲裁、維也納會議
## 通用：基礎議事、外交斡旋、情報蒐集、歷史事件
##
## server 欄位映射:
##   server_card_type: attack / defense / utility / signature
##   target_type: self / single_enemy / single_ally / none / all_players / all_enemies

# === 派系歸屬常數 ===
const FACTION_ROYALIST: String = "royalist"
const FACTION_REFORMIST: String = "reformist"
const FACTION_MERCHANT: String = "merchant"
const FACTION_HAWK: String = "hawk"
const FACTION_SOCIAL: String = "social"
const FACTION_DIPLOMATIC: String = "diplomatic"
const FACTION_NEUTRAL: String = "neutral"

# === 快取 ===
static var _all_cards: Array[Dictionary] = []
static var _initialized: bool = false


## 取得所有卡牌資料
static func get_all_cards() -> Array[Dictionary]:
	if not _initialized:
		_initialize()
	return _all_cards


## 根據派系取得專屬卡牌
static func get_faction_cards(faction_id: String) -> Array[Dictionary]:
	if not _initialized:
		_initialize()
	var result: Array[Dictionary] = []
	for card: Dictionary in _all_cards:
		if card.get("faction", "") == faction_id:
			result.append(card)
	return result


## 取得通用卡牌
static func get_neutral_cards() -> Array[Dictionary]:
	return get_faction_cards(FACTION_NEUTRAL)


## 根據 id 取得卡牌
static func get_card_by_id(card_id: String) -> Dictionary:
	if not _initialized:
		_initialize()
	for card: Dictionary in _all_cards:
		if card.get("id", "") == card_id:
			return card
	return {}


## 建立 MVP 起始牌組（派系 5 張 + 通用 3 張 = 8 張手牌）
static func build_starter_deck(faction_id: String) -> Array[Dictionary]:
	if not _initialized:
		_initialize()

	var deck: Array[Dictionary] = []
	var faction_cards: Array[Dictionary] = get_faction_cards(faction_id)
	var neutral_cards: Array[Dictionary] = get_neutral_cards()

	# 隨機選 5 張派系卡
	var shuffled_faction: Array[Dictionary] = faction_cards.duplicate()
	shuffled_faction.shuffle()
	for i: int in range(mini(5, shuffled_faction.size())):
		deck.append(shuffled_faction[i])

	# 隨機選 3 張通用卡
	var shuffled_neutral: Array[Dictionary] = neutral_cards.duplicate()
	shuffled_neutral.shuffle()
	for i: int in range(mini(3, shuffled_neutral.size())):
		deck.append(shuffled_neutral[i])

	return deck


## 建立完整牌庫（派系全部 + 通用全部，用於抽牌池）
static func build_full_pool(faction_id: String) -> Array[Dictionary]:
	if not _initialized:
		_initialize()

	var pool: Array[Dictionary] = []
	pool.append_array(get_faction_cards(faction_id))
	pool.append_array(get_neutral_cards())
	pool.shuffle()
	return pool


## 從牌庫抽一張（給定牌庫池）
static func draw_card_from_pool(pool: Array[Dictionary]) -> Dictionary:
	if pool.is_empty():
		return {}
	var index: int = randi() % pool.size()
	return pool[index]


# ============================================================
# === 初始化所有卡牌資料 ===
# ============================================================

static func _initialize() -> void:
	_all_cards.clear()
	_all_cards.append_array(_create_royalist_cards())
	_all_cards.append_array(_create_reformist_cards())
	_all_cards.append_array(_create_merchant_cards())
	_all_cards.append_array(_create_hawk_cards())
	_all_cards.append_array(_create_social_cards())
	_all_cards.append_array(_create_diplomatic_cards())
	_all_cards.append_array(_create_neutral_cards())
	_initialized = true
	print("[CardDatabase] 初始化完成，共 %d 張卡牌" % _all_cards.size())


# ============================================================
# === 保守黨卡牌（14 張） ===
# ============================================================

static func _create_royalist_cards() -> Array[Dictionary]:
	return [
		# --- roy_01 ~ roy_08 (原有) ---
		{
			"id": "roy_01", "name": "軍隊調動 / Military Mobilization",
			"description": "調動王室禁衛軍進駐議會周圍，震懾反對派。",
			"type": CardData.CardType.TACTIC, "cost": 2,
			"power": 3, "influence": 2, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_ROYALIST,
			"effects": [
				{"dimension": "military", "value": 10},
				{"dimension": "public_opinion", "value": -5},
			],
			"server_card_type": "defense", "target_type": "self",
			"art_path": "res://assets/ui/cards/art/card_strategy_martial-law_char.png",
		},
		{
			"id": "roy_02", "name": "教會支持 / Church Endorsement",
			"description": "獲得大主教的公開背書，鞏固傳統勢力。",
			"type": CardData.CardType.ALLIANCE, "cost": 2,
			"power": 2, "influence": 3, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_ROYALIST,
			"effects": [
				{"dimension": "public_opinion", "value": 5},
				{"dimension": "diplomacy", "value": 3},
			],
			"server_card_type": "utility", "target_type": "none",
			"art_path": "res://assets/ui/cards/art/card_strategy_endorse_char.png",
		},
		{
			"id": "roy_03", "name": "傳統法案 / Tradition Act",
			"description": "提議維護現有法律體系，阻止任何激進改革。",
			"type": CardData.CardType.PROPOSAL, "cost": 1,
			"power": 2, "influence": 1, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_ROYALIST,
			"effects": [
				{"dimension": "public_opinion", "value": 3},
				{"dimension": "military", "value": 2},
			],
			"server_card_type": "utility", "target_type": "none",
			"art_path": "res://assets/ui/cards/art/card_strategy_procedural-motion_char.png",
		},
		{
			"id": "roy_04", "name": "皇家特權 / Royal Prerogative",
			"description": "援引國王特權，強制通過一項爭議法案。",
			"type": CardData.CardType.TACTIC, "cost": 4,
			"power": 5, "influence": 4, "rarity": CardData.Rarity.RARE,
			"faction": FACTION_ROYALIST,
			"effects": [
				{"dimension": "military", "value": 8},
				{"dimension": "public_opinion", "value": -10},
				{"dimension": "diplomacy", "value": -5},
			],
			"server_card_type": "defense", "target_type": "self",
			"art_path": "res://assets/ui/cards/art/card_strategy_royal-favor_char.png",
		},
		{
			"id": "roy_05", "name": "貴族宴會 / Aristocrat's Banquet",
			"description": "舉辦奢華宴會拉攏搖擺議員。",
			"type": CardData.CardType.ALLIANCE, "cost": 3,
			"power": 3, "influence": 3, "rarity": CardData.Rarity.RARE,
			"faction": FACTION_ROYALIST,
			"effects": [
				{"dimension": "treasury", "value": -8},
				{"dimension": "diplomacy", "value": 7},
			],
			"server_card_type": "utility", "target_type": "single_ally",
			"art_path": "res://assets/ui/cards/art/card_strategy_backroom-deal_char.png",
		},
		{
			"id": "roy_06", "name": "禁衛軍威嚇 / Royal Guard Threat",
			"description": "在議會辯論前展示軍事力量。",
			"type": CardData.CardType.DEBATE, "cost": 2,
			"power": 3, "influence": 2, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_ROYALIST,
			"effects": [
				{"dimension": "military", "value": 5},
				{"dimension": "public_opinion", "value": -3},
			],
			"server_card_type": "attack", "target_type": "single_enemy",
			"art_path": "res://assets/ui/cards/art/card_strategy_blockade_char.png",
		},
		{
			"id": "roy_07", "name": "王室詔令 / Royal Decree",
			"description": "以國王名義發布詔令，要求議員服從。",
			"type": CardData.CardType.PROPOSAL, "cost": 3,
			"power": 4, "influence": 3, "rarity": CardData.Rarity.RARE,
			"faction": FACTION_ROYALIST,
			"effects": [
				{"dimension": "military", "value": 5},
				{"dimension": "diplomacy", "value": 5},
				{"dimension": "public_opinion", "value": -5},
			],
			"server_card_type": "utility", "target_type": "none",
			"art_path": "res://assets/ui/cards/art/card_strategy_royal-decree_char.png",
		},
		{
			"id": "roy_08", "name": "古老誓約 / Ancient Oath",
			"description": "喚起對先王誓言的記憶，凝聚保守勢力。",
			"type": CardData.CardType.EVENT, "cost": 1,
			"power": 1, "influence": 2, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_ROYALIST,
			"effects": [
				{"dimension": "public_opinion", "value": 3},
				{"dimension": "military", "value": 3},
			],
			"server_card_type": "signature", "target_type": "all_players",
			"art_path": "res://assets/ui/cards/art/card_strategy_moral-appeal_char.png",
		},
		# --- roy_09 ~ roy_14 (新增) ---
		{
			"id": "roy_09", "name": "報刊管制 / Press Censorship",
			"description": "下令審查反對派報章，壓制異見聲音。",
			"type": CardData.CardType.TACTIC, "cost": 2,
			"power": 2, "influence": 2, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_ROYALIST,
			"effects": [
				{"dimension": "military", "value": 5},
				{"dimension": "public_opinion", "value": -3},
			],
			"server_card_type": "defense", "target_type": "self",
			"art_path": "res://assets/ui/cards/art/card_strategy_rumor_char.png",
		},
		{
			"id": "roy_10", "name": "貴族院否決 / Lords' Veto",
			"description": "動用上議院多數否決下議院通過的改革法案。",
			"type": CardData.CardType.DEBATE, "cost": 3,
			"power": 4, "influence": 3, "rarity": CardData.Rarity.RARE,
			"faction": FACTION_ROYALIST,
			"effects": [
				{"dimension": "diplomacy", "value": 5},
				{"dimension": "public_opinion", "value": -5},
				{"dimension": "military", "value": 3},
			],
			"server_card_type": "attack", "target_type": "single_enemy",
			"art_path": "res://assets/ui/cards/art/card_strategy_no-confidence_char.png",
		},
		{
			"id": "roy_11", "name": "密室交易 / Backroom Deal",
			"description": "在貴族俱樂部與搖擺派系秘密談判。",
			"type": CardData.CardType.ALLIANCE, "cost": 3,
			"power": 3, "influence": 4, "rarity": CardData.Rarity.RARE,
			"faction": FACTION_ROYALIST,
			"effects": [
				{"dimension": "diplomacy", "value": 8},
				{"dimension": "treasury", "value": -5},
			],
			"server_card_type": "utility", "target_type": "single_ally",
			"art_path": "res://assets/ui/cards/art/card_strategy_compromise_char.png",
		},
		{
			"id": "roy_12", "name": "戒嚴令 / Martial Law",
			"description": "宣布議會周邊戒嚴，以軍事力量壓制一切反對聲音。",
			"type": CardData.CardType.TACTIC, "cost": 4,
			"power": 5, "influence": 3, "rarity": CardData.Rarity.EPIC,
			"faction": FACTION_ROYALIST,
			"effects": [
				{"dimension": "military", "value": 15},
				{"dimension": "public_opinion", "value": -12},
				{"dimension": "diplomacy", "value": -5},
			],
			"server_card_type": "defense", "target_type": "self",
			"art_path": "res://assets/ui/cards/art/card_strategy_call-to-order_char.png",
		},
		{
			"id": "roy_13", "name": "間諜網絡 / Spy Network",
			"description": "部署皇家密探滲透反對派組織，獲取情報。",
			"type": CardData.CardType.TACTIC, "cost": 3,
			"power": 3, "influence": 3, "rarity": CardData.Rarity.EPIC,
			"faction": FACTION_ROYALIST,
			"effects": [
				{"dimension": "diplomacy", "value": 5},
				{"dimension": "military", "value": 5},
				{"dimension": "treasury", "value": -5},
			],
			"server_card_type": "defense", "target_type": "single_enemy",
			"art_path": "res://assets/ui/cards/art/card_strategy_espionage_char.png",
		},
		{
			"id": "roy_14", "name": "王座演說 / King's Speech",
			"description": "國王親臨議會發表演說，宣示王權的不可動搖。",
			"type": CardData.CardType.EVENT, "cost": 5,
			"power": 6, "influence": 5, "rarity": CardData.Rarity.LEGENDARY,
			"faction": FACTION_ROYALIST,
			"effects": [
				{"dimension": "public_opinion", "value": 10},
				{"dimension": "military", "value": 10},
				{"dimension": "diplomacy", "value": 8},
				{"dimension": "treasury", "value": -5},
			],
			"server_card_type": "signature", "target_type": "all_players",
			"art_path": "res://assets/ui/cards/art/card_strategy_opening-statement_char.png",
		},
	]


# ============================================================
# === 自由派卡牌（14 張） ===
# ============================================================

static func _create_reformist_cards() -> Array[Dictionary]:
	return [
		# --- ref_01 ~ ref_08 (原有) ---
		{
			"id": "ref_01", "name": "民意動員 / Public Rally",
			"description": "在廣場舉辦大規模集會，號召市民支持改革。",
			"type": CardData.CardType.TACTIC, "cost": 2,
			"power": 3, "influence": 2, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_REFORMIST,
			"effects": [
				{"dimension": "public_opinion", "value": 10},
				{"dimension": "military", "value": -3},
			],
			"server_card_type": "defense", "target_type": "self",
			"art_path": "res://assets/ui/cards/art/card_strategy_public-appeal_char.png",
		},
		{
			"id": "ref_02", "name": "言論自由法 / Free Speech Act",
			"description": "提案保障議員在議會中的言論豁免權。",
			"type": CardData.CardType.PROPOSAL, "cost": 2,
			"power": 2, "influence": 3, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_REFORMIST,
			"effects": [
				{"dimension": "public_opinion", "value": 8},
				{"dimension": "diplomacy", "value": 3},
			],
			"server_card_type": "utility", "target_type": "none",
			"art_path": "res://assets/ui/cards/art/card_strategy_habeas-corpus_char.png",
		},
		{
			"id": "ref_03", "name": "改革法案 / Reform Bill",
			"description": "提出全面的議會改革方案，擴大選舉權。",
			"type": CardData.CardType.PROPOSAL, "cost": 3,
			"power": 4, "influence": 3, "rarity": CardData.Rarity.RARE,
			"faction": FACTION_REFORMIST,
			"effects": [
				{"dimension": "public_opinion", "value": 12},
				{"dimension": "military", "value": -5},
				{"dimension": "treasury", "value": -3},
			],
			"server_card_type": "utility", "target_type": "none",
			"art_path": "res://assets/ui/cards/art/card_strategy_reform-act_char.png",
		},
		{
			"id": "ref_04", "name": "媒體操控 / Press Manipulation",
			"description": "透過親近的報社散佈對自己有利的消息。",
			"type": CardData.CardType.TACTIC, "cost": 2,
			"power": 2, "influence": 3, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_REFORMIST,
			"effects": [
				{"dimension": "public_opinion", "value": 7},
				{"dimension": "treasury", "value": -3},
			],
			"server_card_type": "defense", "target_type": "self",
			"art_path": "res://assets/ui/cards/art/card_strategy_propaganda_char.png",
		},
		{
			"id": "ref_05", "name": "街頭演說 / Street Oration",
			"description": "議員親自上街發表演說，煽動民眾熱情。",
			"type": CardData.CardType.DEBATE, "cost": 1,
			"power": 2, "influence": 1, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_REFORMIST,
			"effects": [
				{"dimension": "public_opinion", "value": 5},
			],
			"server_card_type": "attack", "target_type": "single_enemy",
			"art_path": "res://assets/ui/cards/art/card_strategy_brief-speech_char.png",
		},
		{
			"id": "ref_06", "name": "請願書 / Petition Drive",
			"description": "收集萬人簽名的請願書提交議會。",
			"type": CardData.CardType.ALLIANCE, "cost": 2,
			"power": 2, "influence": 2, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_REFORMIST,
			"effects": [
				{"dimension": "public_opinion", "value": 6},
				{"dimension": "diplomacy", "value": 2},
			],
			"server_card_type": "utility", "target_type": "none",
			"art_path": "res://assets/ui/cards/art/card_strategy_petition_char.png",
		},
		{
			"id": "ref_07", "name": "揭露醜聞 / Scandal Exposure",
			"description": "揭發保守派的腐敗醜聞，動搖其根基。",
			"type": CardData.CardType.TACTIC, "cost": 3,
			"power": 3, "influence": 4, "rarity": CardData.Rarity.RARE,
			"faction": FACTION_REFORMIST,
			"effects": [
				{"dimension": "public_opinion", "value": 8},
				{"dimension": "diplomacy", "value": -5},
			],
			"server_card_type": "attack", "target_type": "single_enemy",
			"art_path": "res://assets/ui/cards/art/card_strategy_expose-scandal_char.png",
		},
		{
			"id": "ref_08", "name": "平民英雄 / People's Champion",
			"description": "推出深受民眾愛戴的議員代表發言。",
			"type": CardData.CardType.EVENT, "cost": 4,
			"power": 5, "influence": 4, "rarity": CardData.Rarity.RARE,
			"faction": FACTION_REFORMIST,
			"effects": [
				{"dimension": "public_opinion", "value": 15},
				{"dimension": "military", "value": -5},
			],
			"server_card_type": "signature", "target_type": "all_players",
			"art_path": "res://assets/ui/cards/art/card_radical_edward-scoop_char.png",
		},
		# --- ref_09 ~ ref_14 (新增) ---
		{
			"id": "ref_09", "name": "工會集會 / Union Assembly",
			"description": "召集各行業工會代表在酒館秘密集會，凝聚改革力量。",
			"type": CardData.CardType.ALLIANCE, "cost": 2,
			"power": 2, "influence": 2, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_REFORMIST,
			"effects": [
				{"dimension": "public_opinion", "value": 6},
				{"dimension": "military", "value": -2},
			],
			"server_card_type": "utility", "target_type": "none",
			"art_path": "res://assets/ui/cards/art/card_strategy_coalition_char.png",
		},
		{
			"id": "ref_10", "name": "印刷傳單 / Pamphlet Campaign",
			"description": "印製並散發改革傳單，喚醒市民的政治意識。",
			"type": CardData.CardType.TACTIC, "cost": 1,
			"power": 2, "influence": 2, "rarity": CardData.Rarity.RARE,
			"faction": FACTION_REFORMIST,
			"effects": [
				{"dimension": "public_opinion", "value": 5},
				{"dimension": "treasury", "value": -2},
			],
			"server_card_type": "defense", "target_type": "self",
			"art_path": "res://assets/ui/cards/art/card_strategy_pamphlet_char.png",
		},
		{
			"id": "ref_11", "name": "議會質詢 / Parliamentary Question",
			"description": "在下議院向執政方提出尖銳質詢，令其顏面盡失。",
			"type": CardData.CardType.DEBATE, "cost": 2,
			"power": 3, "influence": 3, "rarity": CardData.Rarity.RARE,
			"faction": FACTION_REFORMIST,
			"effects": [
				{"dimension": "public_opinion", "value": 5},
				{"dimension": "diplomacy", "value": -3},
			],
			"server_card_type": "attack", "target_type": "single_enemy",
			"art_path": "res://assets/ui/cards/art/card_strategy_interrogate_char.png",
		},
		{
			"id": "ref_12", "name": "民權宣言 / Rights Declaration",
			"description": "起草並宣讀《人民權利宣言》，震撼整個議會。",
			"type": CardData.CardType.PROPOSAL, "cost": 4,
			"power": 4, "influence": 4, "rarity": CardData.Rarity.EPIC,
			"faction": FACTION_REFORMIST,
			"effects": [
				{"dimension": "public_opinion", "value": 15},
				{"dimension": "military", "value": -8},
				{"dimension": "treasury", "value": -3},
			],
			"server_card_type": "utility", "target_type": "all_players",
			"art_path": "res://assets/ui/cards/art/card_event_magna-carta_char.png",
		},
		{
			"id": "ref_13", "name": "工廠調查 / Factory Investigation",
			"description": "組織議員親赴工廠視察童工與惡劣勞動條件。",
			"type": CardData.CardType.TACTIC, "cost": 3,
			"power": 3, "influence": 3, "rarity": CardData.Rarity.EPIC,
			"faction": FACTION_REFORMIST,
			"effects": [
				{"dimension": "public_opinion", "value": 10},
				{"dimension": "treasury", "value": -5},
				{"dimension": "diplomacy", "value": 3},
			],
			"server_card_type": "attack", "target_type": "single_enemy",
			"art_path": "res://assets/ui/cards/art/card_strategy_inspection_char.png",
		},
		{
			"id": "ref_14", "name": "人民憲章 / People's Charter",
			"description": "提出劃時代的《人民憲章》，要求普選權與秘密投票。",
			"type": CardData.CardType.EVENT, "cost": 5,
			"power": 6, "influence": 5, "rarity": CardData.Rarity.LEGENDARY,
			"faction": FACTION_REFORMIST,
			"effects": [
				{"dimension": "public_opinion", "value": 18},
				{"dimension": "military", "value": -10},
				{"dimension": "diplomacy", "value": 5},
			],
			"server_card_type": "signature", "target_type": "all_players",
			"art_path": "res://assets/ui/cards/art/card_strategy_revolution_char.png",
		},
	]


# ============================================================
# === 商行聯盟卡牌（14 張） ===
# ============================================================

static func _create_merchant_cards() -> Array[Dictionary]:
	return [
		# --- mer_01 ~ mer_08 (原有) ---
		{
			"id": "mer_01", "name": "貿易協定 / Trade Agreement",
			"description": "與外國簽訂互利的貿易條約。",
			"type": CardData.CardType.PROPOSAL, "cost": 2,
			"power": 2, "influence": 3, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_MERCHANT,
			"effects": [
				{"dimension": "treasury", "value": 10},
				{"dimension": "diplomacy", "value": 5},
			],
			"server_card_type": "utility", "target_type": "none",
			"art_path": "res://assets/ui/cards/art/card_strategy_corn-law_char.png",
		},
		{
			"id": "mer_02", "name": "收買議員 / Bribe Parliamentarian",
			"description": "以重金賄賂搖擺不定的議員。",
			"type": CardData.CardType.TACTIC, "cost": 3,
			"power": 3, "influence": 4, "rarity": CardData.Rarity.RARE,
			"faction": FACTION_MERCHANT,
			"effects": [
				{"dimension": "treasury", "value": -10},
				{"dimension": "diplomacy", "value": 8},
			],
			"server_card_type": "attack", "target_type": "single_enemy",
			"art_path": "res://assets/ui/cards/art/card_industrial_richard-bribe_char.png",
		},
		{
			"id": "mer_03", "name": "金融操作 / Financial Manipulation",
			"description": "操控倫敦交易所的股價，製造經濟壓力。",
			"type": CardData.CardType.TACTIC, "cost": 3,
			"power": 3, "influence": 3, "rarity": CardData.Rarity.RARE,
			"faction": FACTION_MERCHANT,
			"effects": [
				{"dimension": "treasury", "value": 8},
				{"dimension": "public_opinion", "value": -5},
			],
			"server_card_type": "attack", "target_type": "single_enemy",
			"art_path": "res://assets/ui/cards/art/card_strategy_double-agent_char.png",
		},
		{
			"id": "mer_04", "name": "市場控制 / Market Control",
			"description": "壟斷關鍵商品市場，迫使對手就範。",
			"type": CardData.CardType.TACTIC, "cost": 4,
			"power": 4, "influence": 4, "rarity": CardData.Rarity.RARE,
			"faction": FACTION_MERCHANT,
			"effects": [
				{"dimension": "treasury", "value": 12},
				{"dimension": "public_opinion", "value": -8},
				{"dimension": "diplomacy", "value": -3},
			],
			"server_card_type": "defense", "target_type": "self",
			"art_path": "res://assets/ui/cards/art/card_strategy_embargo_char.png",
		},
		{
			"id": "mer_05", "name": "航運補助 / Shipping Subsidy",
			"description": "以國庫資金補貼商船隊，擴大貿易版圖。",
			"type": CardData.CardType.PROPOSAL, "cost": 2,
			"power": 2, "influence": 2, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_MERCHANT,
			"effects": [
				{"dimension": "treasury", "value": 7},
				{"dimension": "military", "value": 3},
			],
			"server_card_type": "utility", "target_type": "none",
			"art_path": "res://assets/ui/cards/art/card_strategy_lobby_char.png",
		},
		{
			"id": "mer_06", "name": "商會密談 / Guild Meeting",
			"description": "召集各大商會代表秘密協商。",
			"type": CardData.CardType.ALLIANCE, "cost": 1,
			"power": 1, "influence": 2, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_MERCHANT,
			"effects": [
				{"dimension": "treasury", "value": 5},
				{"dimension": "diplomacy", "value": 3},
			],
			"server_card_type": "utility", "target_type": "none",
			"art_path": "res://assets/ui/cards/art/card_strategy_grand-coalition_char.png",
		},
		{
			"id": "mer_07", "name": "債務陷阱 / Debt Trap",
			"description": "透過貸款讓對手陷入財務困境。",
			"type": CardData.CardType.DEBATE, "cost": 2,
			"power": 2, "influence": 3, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_MERCHANT,
			"effects": [
				{"dimension": "treasury", "value": 5},
				{"dimension": "public_opinion", "value": -3},
			],
			"server_card_type": "attack", "target_type": "single_enemy",
			"art_path": "res://assets/ui/cards/art/card_strategy_war-debt_char.png",
		},
		{
			"id": "mer_08", "name": "黃金獻禮 / Golden Tribute",
			"description": "向議會獻上大筆資金，換取商業特許權。",
			"type": CardData.CardType.EVENT, "cost": 2,
			"power": 2, "influence": 2, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_MERCHANT,
			"effects": [
				{"dimension": "treasury", "value": 8},
				{"dimension": "public_opinion", "value": -3},
			],
			"server_card_type": "signature", "target_type": "none",
			"art_path": "res://assets/ui/cards/art/card_strategy_charity_char.png",
		},
		# --- mer_09 ~ mer_14 (新增) ---
		{
			"id": "mer_09", "name": "殖民地投資 / Colonial Investment",
			"description": "投資海外殖民地產業，獲取豐厚回報。",
			"type": CardData.CardType.PROPOSAL, "cost": 2,
			"power": 2, "influence": 2, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_MERCHANT,
			"effects": [
				{"dimension": "treasury", "value": 8},
				{"dimension": "diplomacy", "value": 3},
				{"dimension": "public_opinion", "value": -2},
			],
			"server_card_type": "utility", "target_type": "none",
			"art_path": "res://assets/ui/cards/art/card_strategy_tax-debate_char.png",
		},
		{
			"id": "mer_10", "name": "壟斷特許 / Monopoly Charter",
			"description": "向王室申請商品專營特許狀，排除競爭對手。",
			"type": CardData.CardType.TACTIC, "cost": 3,
			"power": 3, "influence": 3, "rarity": CardData.Rarity.RARE,
			"faction": FACTION_MERCHANT,
			"effects": [
				{"dimension": "treasury", "value": 10},
				{"dimension": "public_opinion", "value": -6},
			],
			"server_card_type": "defense", "target_type": "self",
			"art_path": "res://assets/ui/cards/art/card_strategy_whip_char.png",
		},
		{
			"id": "mer_11", "name": "稅務遊說 / Tax Lobbying",
			"description": "派遣說客向議員施壓，要求降低商業稅率。",
			"type": CardData.CardType.DEBATE, "cost": 2,
			"power": 3, "influence": 3, "rarity": CardData.Rarity.RARE,
			"faction": FACTION_MERCHANT,
			"effects": [
				{"dimension": "treasury", "value": 5},
				{"dimension": "diplomacy", "value": 3},
				{"dimension": "public_opinion", "value": -3},
			],
			"server_card_type": "attack", "target_type": "single_enemy",
			"art_path": "res://assets/ui/cards/art/card_strategy_lobby_char.png",
		},
		{
			"id": "mer_12", "name": "銀行擠兌 / Bank Run",
			"description": "散佈謠言引發銀行擠兌，癱瘓對手的資金來源。",
			"type": CardData.CardType.TACTIC, "cost": 4,
			"power": 5, "influence": 3, "rarity": CardData.Rarity.EPIC,
			"faction": FACTION_MERCHANT,
			"effects": [
				{"dimension": "treasury", "value": 15},
				{"dimension": "public_opinion", "value": -10},
				{"dimension": "diplomacy", "value": -5},
			],
			"server_card_type": "attack", "target_type": "single_enemy",
			"art_path": "res://assets/ui/cards/art/card_strategy_crisis_char.png",
		},
		{
			"id": "mer_13", "name": "走私網絡 / Smuggling Network",
			"description": "建立跨海峽走私網絡，規避關稅獲取暴利。",
			"type": CardData.CardType.TACTIC, "cost": 3,
			"power": 3, "influence": 3, "rarity": CardData.Rarity.EPIC,
			"faction": FACTION_MERCHANT,
			"effects": [
				{"dimension": "treasury", "value": 8},
				{"dimension": "military", "value": 3},
				{"dimension": "public_opinion", "value": -5},
			],
			"server_card_type": "defense", "target_type": "self",
			"art_path": "res://assets/ui/cards/art/card_strategy_blockade_char.png",
		},
		{
			"id": "mer_14", "name": "東印度公司 / East India Company",
			"description": "動用東印度公司的龐大資源，左右議會決策。",
			"type": CardData.CardType.EVENT, "cost": 5,
			"power": 6, "influence": 5, "rarity": CardData.Rarity.LEGENDARY,
			"faction": FACTION_MERCHANT,
			"effects": [
				{"dimension": "treasury", "value": 18},
				{"dimension": "military", "value": 5},
				{"dimension": "diplomacy", "value": 5},
				{"dimension": "public_opinion", "value": -8},
			],
			"server_card_type": "signature", "target_type": "all_players",
			"art_path": "res://assets/ui/cards/art/card_strategy_grand-coalition_char.png",
		},
	]


# ============================================================
# === 鷹派卡牌（14 張） ===
# ============================================================

static func _create_hawk_cards() -> Array[Dictionary]:
	return [
		{
			"id": "haw_01", "name": "前線衝鋒 / Frontline Charge",
			"description": "率領退役軍官衝入辯論場，以軍人氣勢壓制對手。",
			"type": CardData.CardType.DEBATE, "cost": 2,
			"power": 3, "influence": 2, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_HAWK,
			"effects": [
				{"dimension": "military", "value": 8},
				{"dimension": "public_opinion", "value": -3},
			],
			"server_card_type": "attack", "target_type": "single_enemy",
			"art_path": "res://assets/ui/cards/art/card_strategy_rebut_char.png",
		},
		{
			"id": "haw_02", "name": "軍械庫 / Arsenal",
			"description": "展示從半島戰爭帶回的武器收藏，暗示武力後盾。",
			"type": CardData.CardType.TACTIC, "cost": 1,
			"power": 2, "influence": 1, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_HAWK,
			"effects": [
				{"dimension": "military", "value": 5},
				{"dimension": "treasury", "value": -3},
			],
			"server_card_type": "defense", "target_type": "self",
			"art_path": "res://assets/ui/cards/art/card_strategy_martial-law_char.png",
		},
		{
			"id": "haw_03", "name": "徵兵令 / Conscription Act",
			"description": "提議擴大徵兵範圍，加強國防力量。",
			"type": CardData.CardType.PROPOSAL, "cost": 2,
			"power": 2, "influence": 2, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_HAWK,
			"effects": [
				{"dimension": "military", "value": 7},
				{"dimension": "public_opinion", "value": -5},
			],
			"server_card_type": "utility", "target_type": "none",
			"art_path": "res://assets/ui/cards/art/card_strategy_call-to-order_char.png",
		},
		{
			"id": "haw_04", "name": "砲艦外交 / Gunboat Diplomacy",
			"description": "派遣軍艦至他國港口，以武力脅迫達成外交目標。",
			"type": CardData.CardType.DEBATE, "cost": 2,
			"power": 3, "influence": 2, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_HAWK,
			"effects": [
				{"dimension": "military", "value": 5},
				{"dimension": "diplomacy", "value": 3},
				{"dimension": "public_opinion", "value": -3},
			],
			"server_card_type": "attack", "target_type": "single_enemy",
			"art_path": "res://assets/ui/cards/art/card_strategy_press-leak_char.png",
		},
		{
			"id": "haw_05", "name": "軍事演習 / Military Exercise",
			"description": "在議會附近舉行大規模軍事演習，展示武力。",
			"type": CardData.CardType.TACTIC, "cost": 1,
			"power": 1, "influence": 2, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_HAWK,
			"effects": [
				{"dimension": "military", "value": 4},
				{"dimension": "treasury", "value": -2},
			],
			"server_card_type": "defense", "target_type": "self",
			"art_path": "res://assets/ui/cards/art/card_strategy_quick-wit_char.png",
		},
		{
			"id": "haw_06", "name": "戰時經濟 / War Economy",
			"description": "推動軍工產業發展，從戰爭準備中獲取經濟利益。",
			"type": CardData.CardType.EVENT, "cost": 2,
			"power": 2, "influence": 2, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_HAWK,
			"effects": [
				{"dimension": "treasury", "value": 5},
				{"dimension": "military", "value": 3},
				{"dimension": "public_opinion", "value": -3},
			],
			"server_card_type": "signature", "target_type": "all_players",
			"art_path": "res://assets/ui/cards/art/card_strategy_war-debt_char.png",
		},
		{
			"id": "haw_07", "name": "將軍背書 / General's Endorsement",
			"description": "邀請戰爭英雄公開為派系站台。",
			"type": CardData.CardType.ALLIANCE, "cost": 3,
			"power": 3, "influence": 3, "rarity": CardData.Rarity.RARE,
			"faction": FACTION_HAWK,
			"effects": [
				{"dimension": "military", "value": 6},
				{"dimension": "diplomacy", "value": 3},
				{"dimension": "public_opinion", "value": -2},
			],
			"server_card_type": "utility", "target_type": "single_ally",
			"art_path": "res://assets/ui/cards/art/card_strategy_endorse_char.png",
		},
		{
			"id": "haw_08", "name": "軍事法庭 / Court Martial",
			"description": "以叛國罪名將政敵送上軍事法庭。",
			"type": CardData.CardType.DEBATE, "cost": 3,
			"power": 4, "influence": 3, "rarity": CardData.Rarity.RARE,
			"faction": FACTION_HAWK,
			"effects": [
				{"dimension": "military", "value": 5},
				{"dimension": "diplomacy", "value": -3},
				{"dimension": "public_opinion", "value": 3},
			],
			"server_card_type": "attack", "target_type": "single_enemy",
			"art_path": "res://assets/ui/cards/art/card_strategy_public-trial_char.png",
		},
		{
			"id": "haw_09", "name": "武器禁運 / Arms Embargo",
			"description": "封鎖對敵對勢力的武器供應，削弱其力量。",
			"type": CardData.CardType.TACTIC, "cost": 2,
			"power": 3, "influence": 2, "rarity": CardData.Rarity.RARE,
			"faction": FACTION_HAWK,
			"effects": [
				{"dimension": "military", "value": 3},
				{"dimension": "diplomacy", "value": -5},
				{"dimension": "treasury", "value": 5},
			],
			"server_card_type": "defense", "target_type": "single_enemy",
			"art_path": "res://assets/ui/cards/art/card_strategy_embargo_char.png",
		},
		{
			"id": "haw_10", "name": "海軍擴張 / Naval Expansion",
			"description": "提案大幅增加皇家海軍艦隊規模。",
			"type": CardData.CardType.PROPOSAL, "cost": 3,
			"power": 3, "influence": 3, "rarity": CardData.Rarity.RARE,
			"faction": FACTION_HAWK,
			"effects": [
				{"dimension": "military", "value": 8},
				{"dimension": "treasury", "value": -8},
				{"dimension": "diplomacy", "value": 3},
			],
			"server_card_type": "utility", "target_type": "none",
			"art_path": "res://assets/ui/cards/art/card_strategy_blockade_char.png",
		},
		{
			"id": "haw_11", "name": "焦土戰術 / Scorched Earth",
			"description": "不惜一切代價摧毀敵方的政治根基。",
			"type": CardData.CardType.TACTIC, "cost": 3,
			"power": 4, "influence": 2, "rarity": CardData.Rarity.RARE,
			"faction": FACTION_HAWK,
			"effects": [
				{"dimension": "military", "value": 10},
				{"dimension": "public_opinion", "value": -8},
				{"dimension": "treasury", "value": -3},
			],
			"server_card_type": "attack", "target_type": "single_enemy",
			"art_path": "res://assets/ui/cards/art/card_luddite_george-fury_char.png",
		},
		{
			"id": "haw_12", "name": "閃電突襲 / Lightning Strike",
			"description": "在敵方毫無防備之際發動猛烈的議會攻勢。",
			"type": CardData.CardType.TACTIC, "cost": 4,
			"power": 5, "influence": 3, "rarity": CardData.Rarity.EPIC,
			"faction": FACTION_HAWK,
			"effects": [
				{"dimension": "military", "value": 12},
				{"dimension": "public_opinion", "value": -5},
				{"dimension": "diplomacy", "value": -5},
			],
			"server_card_type": "attack", "target_type": "single_enemy",
			"art_path": "res://assets/ui/cards/art/card_strategy_strike_char.png",
		},
		{
			"id": "haw_13", "name": "軍事政變 / Military Coup",
			"description": "策動軍方勢力直接干預議會運作。",
			"type": CardData.CardType.TACTIC, "cost": 4,
			"power": 5, "influence": 4, "rarity": CardData.Rarity.EPIC,
			"faction": FACTION_HAWK,
			"effects": [
				{"dimension": "military", "value": 15},
				{"dimension": "public_opinion", "value": -10},
				{"dimension": "diplomacy", "value": -8},
			],
			"server_card_type": "defense", "target_type": "self",
			"art_path": "res://assets/ui/cards/art/card_strategy_revolution_char.png",
		},
		{
			"id": "haw_14", "name": "滑鐵盧號令 / Waterloo Command",
			"description": "以滑鐵盧戰役的榮光號召全軍，發動決定性的政治攻勢。",
			"type": CardData.CardType.EVENT, "cost": 5,
			"power": 6, "influence": 5, "rarity": CardData.Rarity.LEGENDARY,
			"faction": FACTION_HAWK,
			"effects": [
				{"dimension": "military", "value": 15},
				{"dimension": "public_opinion", "value": 5},
				{"dimension": "diplomacy", "value": 5},
				{"dimension": "treasury", "value": -8},
			],
			"server_card_type": "signature", "target_type": "all_players",
			"art_path": "res://assets/ui/cards/art/card_strategy_royal-decree_char.png",
		},
	]


# ============================================================
# === 民社黨卡牌（14 張） ===
# ============================================================

static func _create_social_cards() -> Array[Dictionary]:
	return [
		{
			"id": "soc_01", "name": "勞工請願 / Workers' Petition",
			"description": "代表工人階級向議會提交改善勞動條件的請願書。",
			"type": CardData.CardType.PROPOSAL, "cost": 1,
			"power": 1, "influence": 1, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_SOCIAL,
			"effects": [
				{"dimension": "public_opinion", "value": 5},
				{"dimension": "treasury", "value": 2},
			],
			"server_card_type": "utility", "target_type": "none",
			"art_path": "res://assets/ui/cards/art/card_strategy_petition_char.png",
		},
		{
			"id": "soc_02", "name": "工廠法案 / Factory Act",
			"description": "提出限制童工與規範工時的工廠法案。",
			"type": CardData.CardType.PROPOSAL, "cost": 2,
			"power": 2, "influence": 2, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_SOCIAL,
			"effects": [
				{"dimension": "public_opinion", "value": 6},
				{"dimension": "treasury", "value": -3},
				{"dimension": "military", "value": -2},
			],
			"server_card_type": "utility", "target_type": "none",
			"art_path": "res://assets/ui/cards/art/card_strategy_factory-act_char.png",
		},
		{
			"id": "soc_03", "name": "互助基金 / Mutual Aid Fund",
			"description": "建立工人互助基金，在困難時期相互扶持。",
			"type": CardData.CardType.ALLIANCE, "cost": 2,
			"power": 2, "influence": 2, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_SOCIAL,
			"effects": [
				{"dimension": "public_opinion", "value": 3},
				{"dimension": "treasury", "value": 3},
				{"dimension": "diplomacy", "value": 2},
			],
			"server_card_type": "utility", "target_type": "single_ally",
			"art_path": "res://assets/ui/cards/art/card_strategy_charity_char.png",
		},
		{
			"id": "soc_04", "name": "罷工威脅 / Strike Threat",
			"description": "威脅發動大規模罷工，迫使資方讓步。",
			"type": CardData.CardType.DEBATE, "cost": 2,
			"power": 3, "influence": 2, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_SOCIAL,
			"effects": [
				{"dimension": "public_opinion", "value": 5},
				{"dimension": "treasury", "value": -3},
			],
			"server_card_type": "attack", "target_type": "single_enemy",
			"art_path": "res://assets/ui/cards/art/card_strategy_strike_char.png",
		},
		{
			"id": "soc_05", "name": "社區集會 / Community Meeting",
			"description": "在教區教堂召集居民討論地方民生議題。",
			"type": CardData.CardType.ALLIANCE, "cost": 1,
			"power": 1, "influence": 2, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_SOCIAL,
			"effects": [
				{"dimension": "public_opinion", "value": 4},
				{"dimension": "diplomacy", "value": 3},
			],
			"server_card_type": "utility", "target_type": "none",
			"art_path": "res://assets/ui/cards/art/card_worker_thomas-unity_char.png",
		},
		{
			"id": "soc_06", "name": "濟貧改革 / Poor Law Reform",
			"description": "推動改革現行濟貧法，減輕窮人負擔。",
			"type": CardData.CardType.TACTIC, "cost": 2,
			"power": 2, "influence": 2, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_SOCIAL,
			"effects": [
				{"dimension": "public_opinion", "value": 5},
				{"dimension": "treasury", "value": -5},
			],
			"server_card_type": "defense", "target_type": "self",
			"art_path": "res://assets/ui/cards/art/card_strategy_amnesty_char.png",
		},
		{
			"id": "soc_07", "name": "工人教育 / Workers' Education",
			"description": "開辦夜間識字班，提升工人的知識水準。",
			"type": CardData.CardType.TACTIC, "cost": 2,
			"power": 2, "influence": 3, "rarity": CardData.Rarity.RARE,
			"faction": FACTION_SOCIAL,
			"effects": [
				{"dimension": "public_opinion", "value": 6},
				{"dimension": "treasury", "value": -3},
				{"dimension": "diplomacy", "value": 2},
			],
			"server_card_type": "defense", "target_type": "self",
			"art_path": "res://assets/ui/cards/art/card_strategy_pamphlet_char.png",
		},
		{
			"id": "soc_08", "name": "集體談判 / Collective Bargaining",
			"description": "組織工人代表與資方進行集體薪資談判。",
			"type": CardData.CardType.DEBATE, "cost": 2,
			"power": 3, "influence": 3, "rarity": CardData.Rarity.RARE,
			"faction": FACTION_SOCIAL,
			"effects": [
				{"dimension": "public_opinion", "value": 5},
				{"dimension": "treasury", "value": 5},
				{"dimension": "diplomacy", "value": -3},
			],
			"server_card_type": "attack", "target_type": "single_enemy",
			"art_path": "res://assets/ui/cards/art/card_strategy_compromise_char.png",
		},
		{
			"id": "soc_09", "name": "福利提案 / Welfare Proposal",
			"description": "提出國家福利制度的初步構想，保障弱勢群體。",
			"type": CardData.CardType.PROPOSAL, "cost": 3,
			"power": 3, "influence": 3, "rarity": CardData.Rarity.RARE,
			"faction": FACTION_SOCIAL,
			"effects": [
				{"dimension": "public_opinion", "value": 8},
				{"dimension": "treasury", "value": -5},
			],
			"server_card_type": "utility", "target_type": "none",
			"art_path": "res://assets/ui/cards/art/card_strategy_reform-act_char.png",
		},
		{
			"id": "soc_10", "name": "勞資調解 / Labor Mediation",
			"description": "居中調解勞資糾紛，尋求雙方都能接受的方案。",
			"type": CardData.CardType.ALLIANCE, "cost": 2,
			"power": 2, "influence": 3, "rarity": CardData.Rarity.RARE,
			"faction": FACTION_SOCIAL,
			"effects": [
				{"dimension": "public_opinion", "value": 3},
				{"dimension": "treasury", "value": 3},
				{"dimension": "diplomacy", "value": 5},
			],
			"server_card_type": "utility", "target_type": "single_ally",
			"art_path": "res://assets/ui/cards/art/card_strategy_diplomatic-immunity_char.png",
		},
		{
			"id": "soc_11", "name": "濟貧院揭露 / Workhouse Expose",
			"description": "揭露濟貧院內的非人道待遇，震驚社會。",
			"type": CardData.CardType.TACTIC, "cost": 3,
			"power": 3, "influence": 3, "rarity": CardData.Rarity.RARE,
			"faction": FACTION_SOCIAL,
			"effects": [
				{"dimension": "public_opinion", "value": 8},
				{"dimension": "treasury", "value": -3},
				{"dimension": "diplomacy", "value": -3},
			],
			"server_card_type": "attack", "target_type": "single_enemy",
			"art_path": "res://assets/ui/cards/art/card_strategy_expose-scandal_char.png",
		},
		{
			"id": "soc_12", "name": "全國罷工 / General Strike",
			"description": "發動跨行業全國性大罷工，癱瘓經濟運作。",
			"type": CardData.CardType.TACTIC, "cost": 4,
			"power": 5, "influence": 3, "rarity": CardData.Rarity.EPIC,
			"faction": FACTION_SOCIAL,
			"effects": [
				{"dimension": "public_opinion", "value": 12},
				{"dimension": "military", "value": -5},
				{"dimension": "treasury", "value": -5},
			],
			"server_card_type": "attack", "target_type": "all_enemies",
			"art_path": "res://assets/ui/cards/art/card_strategy_strike_char.png",
		},
		{
			"id": "soc_13", "name": "社會契約 / Social Contract",
			"description": "提出一份劃時代的社會契約，重新定義政府與人民的關係。",
			"type": CardData.CardType.PROPOSAL, "cost": 4,
			"power": 4, "influence": 4, "rarity": CardData.Rarity.EPIC,
			"faction": FACTION_SOCIAL,
			"effects": [
				{"dimension": "public_opinion", "value": 10},
				{"dimension": "treasury", "value": 5},
				{"dimension": "diplomacy", "value": 5},
				{"dimension": "military", "value": -5},
			],
			"server_card_type": "utility", "target_type": "all_players",
			"art_path": "res://assets/ui/cards/art/card_strategy_habeas-corpus_char.png",
		},
		{
			"id": "soc_14", "name": "平等宣言 / Equality Declaration",
			"description": "在議會莊嚴宣讀《平等宣言》，為所有人爭取平等的權利。",
			"type": CardData.CardType.EVENT, "cost": 5,
			"power": 6, "influence": 5, "rarity": CardData.Rarity.LEGENDARY,
			"faction": FACTION_SOCIAL,
			"effects": [
				{"dimension": "public_opinion", "value": 15},
				{"dimension": "treasury", "value": 5},
				{"dimension": "diplomacy", "value": 5},
				{"dimension": "military", "value": -3},
			],
			"server_card_type": "signature", "target_type": "all_players",
			"art_path": "res://assets/ui/cards/art/card_event_peterloo_char.png",
		},
	]


# ============================================================
# === 外交聯盟卡牌（14 張） ===
# ============================================================

static func _create_diplomatic_cards() -> Array[Dictionary]:
	return [
		{
			"id": "dip_01", "name": "外交照會 / Diplomatic Note",
			"description": "向各方發出正式外交照會，表明立場。",
			"type": CardData.CardType.PROPOSAL, "cost": 1,
			"power": 1, "influence": 2, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_DIPLOMATIC,
			"effects": [
				{"dimension": "diplomacy", "value": 5},
				{"dimension": "public_opinion", "value": 2},
			],
			"server_card_type": "utility", "target_type": "none",
			"art_path": "res://assets/ui/cards/art/card_strategy_diplomatic-immunity_char.png",
		},
		{
			"id": "dip_02", "name": "條約談判 / Treaty Negotiation",
			"description": "與他國展開雙邊條約談判，爭取有利條件。",
			"type": CardData.CardType.ALLIANCE, "cost": 2,
			"power": 2, "influence": 2, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_DIPLOMATIC,
			"effects": [
				{"dimension": "diplomacy", "value": 6},
				{"dimension": "treasury", "value": 2},
			],
			"server_card_type": "utility", "target_type": "single_ally",
			"art_path": "res://assets/ui/cards/art/card_strategy_compromise_char.png",
		},
		{
			"id": "dip_03", "name": "使節遊說 / Envoy Lobbying",
			"description": "派遣使節在各國宮廷間進行遊說活動。",
			"type": CardData.CardType.DEBATE, "cost": 2,
			"power": 2, "influence": 3, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_DIPLOMATIC,
			"effects": [
				{"dimension": "diplomacy", "value": 3},
				{"dimension": "public_opinion", "value": 3},
				{"dimension": "treasury", "value": -2},
			],
			"server_card_type": "attack", "target_type": "single_enemy",
			"art_path": "res://assets/ui/cards/art/card_strategy_lobby_char.png",
		},
		{
			"id": "dip_04", "name": "中立宣言 / Neutrality Declaration",
			"description": "宣布在特定議題上保持中立，贏得各方信任。",
			"type": CardData.CardType.TACTIC, "cost": 1,
			"power": 1, "influence": 2, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_DIPLOMATIC,
			"effects": [
				{"dimension": "diplomacy", "value": 5},
				{"dimension": "military", "value": -3},
			],
			"server_card_type": "defense", "target_type": "self",
			"art_path": "res://assets/ui/cards/art/card_strategy_withdraw_char.png",
		},
		{
			"id": "dip_05", "name": "情報交換 / Intelligence Exchange",
			"description": "與盟友交換各自掌握的政治情報。",
			"type": CardData.CardType.TACTIC, "cost": 2,
			"power": 2, "influence": 2, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_DIPLOMATIC,
			"effects": [
				{"dimension": "diplomacy", "value": 4},
				{"dimension": "military", "value": 3},
			],
			"server_card_type": "defense", "target_type": "self",
			"art_path": "res://assets/ui/cards/art/card_strategy_gather-intel_char.png",
		},
		{
			"id": "dip_06", "name": "貿易斡旋 / Trade Mediation",
			"description": "居中調解貿易爭端，從中獲取外交籌碼。",
			"type": CardData.CardType.ALLIANCE, "cost": 2,
			"power": 2, "influence": 2, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_DIPLOMATIC,
			"effects": [
				{"dimension": "diplomacy", "value": 5},
				{"dimension": "treasury", "value": 3},
			],
			"server_card_type": "utility", "target_type": "none",
			"art_path": "res://assets/ui/cards/art/card_strategy_corn-law_char.png",
		},
		{
			"id": "dip_07", "name": "密約簽訂 / Secret Treaty",
			"description": "與特定勢力秘密簽訂互利條約。",
			"type": CardData.CardType.ALLIANCE, "cost": 3,
			"power": 3, "influence": 3, "rarity": CardData.Rarity.RARE,
			"faction": FACTION_DIPLOMATIC,
			"effects": [
				{"dimension": "diplomacy", "value": 8},
				{"dimension": "treasury", "value": -3},
			],
			"server_card_type": "utility", "target_type": "single_ally",
			"art_path": "res://assets/ui/cards/art/card_strategy_backroom-deal_char.png",
		},
		{
			"id": "dip_08", "name": "外交豁免 / Diplomatic Immunity",
			"description": "援引外交豁免權，使己方免受政治攻擊。",
			"type": CardData.CardType.TACTIC, "cost": 2,
			"power": 3, "influence": 2, "rarity": CardData.Rarity.RARE,
			"faction": FACTION_DIPLOMATIC,
			"effects": [
				{"dimension": "diplomacy", "value": 5},
				{"dimension": "military", "value": 3},
				{"dimension": "public_opinion", "value": -2},
			],
			"server_card_type": "defense", "target_type": "self",
			"art_path": "res://assets/ui/cards/art/card_strategy_diplomatic-immunity_char.png",
		},
		{
			"id": "dip_09", "name": "聯盟提議 / Alliance Proposal",
			"description": "向搖擺派系正式提出結盟邀請。",
			"type": CardData.CardType.PROPOSAL, "cost": 3,
			"power": 2, "influence": 4, "rarity": CardData.Rarity.RARE,
			"faction": FACTION_DIPLOMATIC,
			"effects": [
				{"dimension": "diplomacy", "value": 7},
				{"dimension": "public_opinion", "value": 3},
			],
			"server_card_type": "utility", "target_type": "single_ally",
			"art_path": "res://assets/ui/cards/art/card_strategy_coalition_char.png",
		},
		{
			"id": "dip_10", "name": "國際仲裁 / International Arbitration",
			"description": "邀請歐洲列強仲裁國內政治紛爭。",
			"type": CardData.CardType.DEBATE, "cost": 3,
			"power": 3, "influence": 3, "rarity": CardData.Rarity.RARE,
			"faction": FACTION_DIPLOMATIC,
			"effects": [
				{"dimension": "diplomacy", "value": 5},
				{"dimension": "public_opinion", "value": 5},
				{"dimension": "military", "value": -3},
			],
			"server_card_type": "attack", "target_type": "single_enemy",
			"art_path": "res://assets/ui/cards/art/card_strategy_point-of-order_char.png",
		},
		{
			"id": "dip_11", "name": "通商特權 / Trade Privileges",
			"description": "透過外交手段獲取獨家通商特權。",
			"type": CardData.CardType.PROPOSAL, "cost": 2,
			"power": 2, "influence": 3, "rarity": CardData.Rarity.RARE,
			"faction": FACTION_DIPLOMATIC,
			"effects": [
				{"dimension": "diplomacy", "value": 3},
				{"dimension": "treasury", "value": 8},
				{"dimension": "public_opinion", "value": -3},
			],
			"server_card_type": "utility", "target_type": "none",
			"art_path": "res://assets/ui/cards/art/card_strategy_corn-law_char.png",
		},
		{
			"id": "dip_12", "name": "和平條約 / Peace Treaty",
			"description": "促成敵對派系簽署和平條約，化干戈為玉帛。",
			"type": CardData.CardType.ALLIANCE, "cost": 4,
			"power": 4, "influence": 4, "rarity": CardData.Rarity.EPIC,
			"faction": FACTION_DIPLOMATIC,
			"effects": [
				{"dimension": "diplomacy", "value": 12},
				{"dimension": "military", "value": -8},
				{"dimension": "public_opinion", "value": 5},
			],
			"server_card_type": "utility", "target_type": "all_players",
			"art_path": "res://assets/ui/cards/art/card_strategy_amnesty_char.png",
		},
		{
			"id": "dip_13", "name": "外交孤立 / Diplomatic Isolation",
			"description": "策動多國同時切斷與目標的外交關係。",
			"type": CardData.CardType.TACTIC, "cost": 4,
			"power": 5, "influence": 3, "rarity": CardData.Rarity.EPIC,
			"faction": FACTION_DIPLOMATIC,
			"effects": [
				{"dimension": "diplomacy", "value": 8},
				{"dimension": "military", "value": 3},
				{"dimension": "public_opinion", "value": -5},
			],
			"server_card_type": "attack", "target_type": "single_enemy",
			"art_path": "res://assets/ui/cards/art/card_strategy_espionage_char.png",
		},
		{
			"id": "dip_14", "name": "維也納會議 / Congress of Vienna",
			"description": "召集各方勢力參加如維也納會議般的大型峰會，重塑政治秩序。",
			"type": CardData.CardType.EVENT, "cost": 5,
			"power": 6, "influence": 5, "rarity": CardData.Rarity.LEGENDARY,
			"faction": FACTION_DIPLOMATIC,
			"effects": [
				{"dimension": "diplomacy", "value": 15},
				{"dimension": "treasury", "value": 5},
				{"dimension": "public_opinion", "value": 5},
				{"dimension": "military", "value": -3},
			],
			"server_card_type": "signature", "target_type": "all_players",
			"art_path": "res://assets/ui/cards/art/card_strategy_grand-coalition_char.png",
		},
	]


# ============================================================
# === 通用卡牌（14 張） ===
# ============================================================

static func _create_neutral_cards() -> Array[Dictionary]:
	return [
		# --- neu_01 ~ neu_06 (原有) ---
		{
			"id": "neu_01", "name": "基礎提案 / Basic Motion",
			"description": "提出一項基礎議案，推動議事進程。",
			"type": CardData.CardType.PROPOSAL, "cost": 1,
			"power": 1, "influence": 1, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_NEUTRAL,
			"effects": [
				{"dimension": "public_opinion", "value": 2},
				{"dimension": "treasury", "value": 2},
			],
			"server_card_type": "utility", "target_type": "none",
			"art_path": "res://assets/ui/cards/art/card_strategy_procedural-motion_char.png",
		},
		{
			"id": "neu_02", "name": "外交斡旋 / Diplomatic Mediation",
			"description": "在各方之間居中調停，緩和緊張局勢。",
			"type": CardData.CardType.ALLIANCE, "cost": 2,
			"power": 2, "influence": 2, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_NEUTRAL,
			"effects": [
				{"dimension": "diplomacy", "value": 8},
				{"dimension": "public_opinion", "value": 2},
			],
			"server_card_type": "utility", "target_type": "none",
			"art_path": "res://assets/ui/cards/art/card_strategy_diplomatic-immunity_char.png",
		},
		{
			"id": "neu_03", "name": "議事阻撓 / Filibuster",
			"description": "以冗長發言拖延議事，消耗對手資源。",
			"type": CardData.CardType.DEBATE, "cost": 1,
			"power": 1, "influence": 2, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_NEUTRAL,
			"effects": [
				{"dimension": "public_opinion", "value": -2},
				{"dimension": "diplomacy", "value": -3},
			],
			"server_card_type": "attack", "target_type": "single_enemy",
			"art_path": "res://assets/ui/cards/art/card_strategy_filibuster_char.png",
		},
		{
			"id": "neu_04", "name": "預算審查 / Budget Review",
			"description": "要求對國庫支出進行全面審計。",
			"type": CardData.CardType.PROPOSAL, "cost": 2,
			"power": 2, "influence": 1, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_NEUTRAL,
			"effects": [
				{"dimension": "treasury", "value": 5},
				{"dimension": "public_opinion", "value": 3},
			],
			"server_card_type": "utility", "target_type": "none",
			"art_path": "res://assets/ui/cards/art/card_strategy_tax-debate_char.png",
		},
		{
			"id": "neu_05", "name": "臨時聯盟 / Temporary Alliance",
			"description": "與立場不同的議員暫時結盟。",
			"type": CardData.CardType.ALLIANCE, "cost": 2,
			"power": 2, "influence": 3, "rarity": CardData.Rarity.RARE,
			"faction": FACTION_NEUTRAL,
			"effects": [
				{"dimension": "diplomacy", "value": 6},
				{"dimension": "military", "value": 2},
			],
			"server_card_type": "utility", "target_type": "single_ally",
			"art_path": "res://assets/ui/cards/art/card_strategy_coalition_char.png",
		},
		{
			"id": "neu_06", "name": "情報蒐集 / Intelligence Gathering",
			"description": "派遣密探蒐集對手的弱點。",
			"type": CardData.CardType.TACTIC, "cost": 1,
			"power": 1, "influence": 1, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_NEUTRAL,
			"effects": [
				{"dimension": "diplomacy", "value": 3},
				{"dimension": "military", "value": 2},
			],
			"server_card_type": "defense", "target_type": "self",
			"art_path": "res://assets/ui/cards/art/card_strategy_gather-intel_char.png",
		},
		# --- neu_07 ~ neu_14 (新增) ---
		{
			"id": "neu_07", "name": "密信傳遞 / Secret Correspondence",
			"description": "透過信使秘密傳遞盟友間的情報與指示。",
			"type": CardData.CardType.TACTIC, "cost": 1,
			"power": 1, "influence": 2, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_NEUTRAL,
			"effects": [
				{"dimension": "diplomacy", "value": 4},
				{"dimension": "military", "value": 1},
			],
			"server_card_type": "defense", "target_type": "single_ally",
			"art_path": "res://assets/ui/cards/art/card_strategy_espionage_char.png",
		},
		{
			"id": "neu_08", "name": "公開辯論 / Public Debate",
			"description": "在議會大廳公開挑戰對手的立場。",
			"type": CardData.CardType.DEBATE, "cost": 2,
			"power": 3, "influence": 2, "rarity": CardData.Rarity.COMMON,
			"faction": FACTION_NEUTRAL,
			"effects": [
				{"dimension": "public_opinion", "value": 3},
				{"dimension": "diplomacy", "value": -2},
			],
			"server_card_type": "attack", "target_type": "single_enemy",
			"art_path": "res://assets/ui/cards/art/card_strategy_rebut_char.png",
		},
		{
			"id": "neu_09", "name": "議長裁決 / Speaker's Ruling",
			"description": "請求議長對程序爭議作出裁決，改變辯論走向。",
			"type": CardData.CardType.PROPOSAL, "cost": 2,
			"power": 2, "influence": 3, "rarity": CardData.Rarity.RARE,
			"faction": FACTION_NEUTRAL,
			"effects": [
				{"dimension": "diplomacy", "value": 5},
				{"dimension": "public_opinion", "value": 2},
			],
			"server_card_type": "utility", "target_type": "none",
			"art_path": "res://assets/ui/cards/art/card_strategy_point-of-order_char.png",
		},
		{
			"id": "neu_10", "name": "經濟危機 / Economic Crisis",
			"description": "一場突如其來的經濟恐慌席捲倫敦金融城。",
			"type": CardData.CardType.EVENT, "cost": 3,
			"power": 3, "influence": 2, "rarity": CardData.Rarity.RARE,
			"faction": FACTION_NEUTRAL,
			"effects": [
				{"dimension": "treasury", "value": -8},
				{"dimension": "public_opinion", "value": -3},
				{"dimension": "military", "value": 2},
			],
			"server_card_type": "signature", "target_type": "all_players",
			"art_path": "res://assets/ui/cards/art/card_strategy_crisis_char.png",
		},
		{
			"id": "neu_11", "name": "外國干預 / Foreign Intervention",
			"description": "歐洲列強對英國內政表達關切，施加外交壓力。",
			"type": CardData.CardType.EVENT, "cost": 3,
			"power": 3, "influence": 3, "rarity": CardData.Rarity.RARE,
			"faction": FACTION_NEUTRAL,
			"effects": [
				{"dimension": "diplomacy", "value": -5},
				{"dimension": "military", "value": 5},
				{"dimension": "public_opinion", "value": -2},
			],
			"server_card_type": "signature", "target_type": "all_players",
			"art_path": "res://assets/ui/cards/art/card_strategy_impeachment_char.png",
		},
		{
			"id": "neu_12", "name": "暗殺陰謀 / Assassination Plot",
			"description": "揭露一場針對政要的暗殺計畫，朝野震動。",
			"type": CardData.CardType.TACTIC, "cost": 3,
			"power": 4, "influence": 2, "rarity": CardData.Rarity.EPIC,
			"faction": FACTION_NEUTRAL,
			"effects": [
				{"dimension": "military", "value": 5},
				{"dimension": "diplomacy", "value": -5},
				{"dimension": "public_opinion", "value": 3},
			],
			"server_card_type": "attack", "target_type": "single_enemy",
			"art_path": "res://assets/ui/cards/art/card_strategy_political-assassination_char.png",
		},
		{
			"id": "neu_13", "name": "王位繼承 / Succession Crisis",
			"description": "國王健康惡化，王位繼承問題引發政治風暴。",
			"type": CardData.CardType.EVENT, "cost": 4,
			"power": 4, "influence": 4, "rarity": CardData.Rarity.EPIC,
			"faction": FACTION_NEUTRAL,
			"effects": [
				{"dimension": "military", "value": 5},
				{"dimension": "public_opinion", "value": 5},
				{"dimension": "diplomacy", "value": -8},
			],
			"server_card_type": "signature", "target_type": "all_players",
			"art_path": "res://assets/ui/cards/art/card_strategy_royal-favor_char.png",
		},
		{
			"id": "neu_14", "name": "歷史轉折 / Historic Turning Point",
			"description": "一個改變國家命運的歷史性時刻降臨議會。",
			"type": CardData.CardType.EVENT, "cost": 5,
			"power": 5, "influence": 5, "rarity": CardData.Rarity.LEGENDARY,
			"faction": FACTION_NEUTRAL,
			"effects": [
				{"dimension": "public_opinion", "value": 10},
				{"dimension": "treasury", "value": 5},
				{"dimension": "military", "value": 5},
				{"dimension": "diplomacy", "value": 5},
			],
			"server_card_type": "signature", "target_type": "all_players",
			"art_path": "res://assets/ui/cards/art/card_strategy_opening-statement_char.png",
		},
	]
