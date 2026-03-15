class_name CharacterData
extends Resource
## 角色資料模型
## 定義所有可選角色的屬性、技能與背景故事
## 對齊後端 CharacterType（Thomas / Richard / George / Robert / William）

# === 角色類型列舉 ===
enum CharacterType {
	THOMAS,    # 工人湯瑪斯
	RICHARD,   # 工廠主理查
	GEORGE,    # 盧德派喬治
	ROBERT,    # 外交官羅伯特
	WILLIAM,   # 貴族威廉
	EDWARD,    # 勞工領袖艾德華
}

# === 技能類型列舉 ===
enum SkillType {
	PASSIVE,   # 被動技能
	ACTIVE,    # 主動技能
}

# === 基本資料 ===
@export var id: String = ""
@export var character_name: String = ""
@export var character_name_en: String = ""
@export var character_type: CharacterType = CharacterType.THOMAS
@export var faction_id: String = ""
@export var portrait_path: String = ""
@export var description: String = ""
@export var lore: String = ""

# === 基礎屬性（1-10） ===
@export_range(1, 10) var attack: int = 5
@export_range(1, 10) var defense: int = 5
@export_range(1, 10) var charisma: int = 5
@export_range(1, 10) var intelligence: int = 5
@export_range(1, 10) var luck: int = 5

# === 技能 ===
@export var skill_name: String = ""
@export var skill_description: String = ""
@export var skill_type: SkillType = SkillType.PASSIVE
@export var skill_effect: Dictionary = {}

# === 角色類型名稱映射 ===
static var character_type_names: Dictionary = {
	CharacterType.THOMAS: "工人湯瑪斯",
	CharacterType.RICHARD: "工廠主理查",
	CharacterType.GEORGE: "盧德派喬治",
	CharacterType.ROBERT: "外交官羅伯特",
	CharacterType.WILLIAM: "貴族威廉",
	CharacterType.EDWARD: "勞工領袖艾德華",
}

static var character_type_names_en: Dictionary = {
	CharacterType.THOMAS: "Thomas",
	CharacterType.RICHARD: "Richard",
	CharacterType.GEORGE: "George",
	CharacterType.ROBERT: "Robert",
	CharacterType.WILLIAM: "William",
	CharacterType.EDWARD: "Edward",
}


## 取得角色類型名稱
func get_type_name() -> String:
	return character_type_names.get(character_type, "未知")


## 取得角色英文類型名稱
func get_type_name_en() -> String:
	return character_type_names_en.get(character_type, "Unknown")


## 取得屬性總和
func get_total_stats() -> int:
	return attack + defense + charisma + intelligence + luck


## 取得屬性字典
func get_stats_dict() -> Dictionary:
	return {
		"attack": attack,
		"defense": defense,
		"charisma": charisma,
		"intelligence": intelligence,
		"luck": luck,
	}


## 從 Dictionary 建立 CharacterData
static func from_dict(data: Dictionary) -> CharacterData:
	var character: CharacterData = CharacterData.new()
	character.id = str(data.get("id", ""))
	character.character_name = str(data.get("character_name", ""))
	character.character_name_en = str(data.get("character_name_en", ""))
	character.character_type = int(data.get("character_type", CharacterType.THOMAS)) as CharacterType
	character.faction_id = str(data.get("faction_id", ""))
	character.portrait_path = str(data.get("portrait_path", ""))
	character.description = str(data.get("description", ""))
	character.lore = str(data.get("lore", ""))
	character.attack = int(data.get("attack", 5))
	character.defense = int(data.get("defense", 5))
	character.charisma = int(data.get("charisma", 5))
	character.intelligence = int(data.get("intelligence", 5))
	character.luck = int(data.get("luck", 5))
	character.skill_name = str(data.get("skill_name", ""))
	character.skill_description = str(data.get("skill_description", ""))
	character.skill_type = int(data.get("skill_type", SkillType.PASSIVE)) as SkillType
	character.skill_effect = data.get("skill_effect", {}) as Dictionary
	return character


## 轉換為 Dictionary
func to_dict() -> Dictionary:
	return {
		"id": id,
		"character_name": character_name,
		"character_name_en": character_name_en,
		"character_type": character_type,
		"faction_id": faction_id,
		"portrait_path": portrait_path,
		"description": description,
		"lore": lore,
		"attack": attack,
		"defense": defense,
		"charisma": charisma,
		"intelligence": intelligence,
		"luck": luck,
		"skill_name": skill_name,
		"skill_description": skill_description,
		"skill_type": skill_type,
		"skill_effect": skill_effect,
	}


# ============================================================
# === 靜態查詢方法 ===
# ============================================================

## 取得所有角色
static func get_all_characters() -> Array[CharacterData]:
	return [
		_create_thomas(),
		_create_richard(),
		_create_george(),
		_create_robert(),
		_create_william(),
		_create_edward(),
	]


## 根據 id 取得角色
static func get_character_by_id(character_id: String) -> CharacterData:
	for character: CharacterData in get_all_characters():
		if character.id == character_id:
			return character
	return null


## 根據派系 id 取得角色列表
static func get_characters_by_faction(faction_id: String) -> Array[CharacterData]:
	var result: Array[CharacterData] = []
	for character: CharacterData in get_all_characters():
		if character.faction_id == faction_id:
			result.append(character)
	return result


## 根據派系 id 取得代表角色（第一個）
static func get_representative_character(faction_id: String) -> CharacterData:
	var characters: Array[CharacterData] = get_characters_by_faction(faction_id)
	if characters.size() > 0:
		return characters[0]
	return null


# ============================================================
# === 角色定義 ===
# ============================================================

# === 工人湯瑪斯 — 王黨派系 ===
static func _create_thomas() -> CharacterData:
	var c: CharacterData = CharacterData.new()
	c.id = "thomas"
	c.character_name = "工人湯瑪斯"
	c.character_name_en = "Thomas"
	c.character_type = CharacterType.THOMAS
	c.faction_id = "royalist"
	c.portrait_path = "res://assets/images/characters/portrait_thomas.png"
	c.description = "忠於王室的工人階級代言人。堅信穩定的社會秩序能保護底層人民的利益，以團結盟友著稱。"
	c.lore = "湯瑪斯出身倫敦東區的紡織工坊，父親是老實的織工。1811年的嚴冬中，他親眼見證暴動帶來的只有更多苦難，從此相信只有依附王室的秩序才能為工人爭取真正的改善。他在工廠中組織互助會，用團結而非暴力贏得了工人們的尊重。"
	# 屬性：防禦型角色，高防禦與魅力
	c.attack = 4
	c.defense = 9
	c.charisma = 7
	c.intelligence = 5
	c.luck = 5
	# 技能：團結 — 每有一個盟友，防禦 +10
	c.skill_name = "團結"
	c.skill_description = "每有一位存活的盟友，防禦值額外 +10。盟友越多，越堅不可摧。"
	c.skill_type = SkillType.PASSIVE
	c.skill_effect = {
		"type": "defense_per_ally",
		"value_per_ally": 10,
		"target": "self",
	}
	return c


# === 工廠主理查 — 商行聯盟 ===
static func _create_richard() -> CharacterData:
	var c: CharacterData = CharacterData.new()
	c.id = "richard"
	c.character_name = "工廠主理查"
	c.character_name_en = "Richard"
	c.character_type = CharacterType.RICHARD
	c.faction_id = "merchant"
	c.portrait_path = "res://assets/images/characters/portrait_richard.png"
	c.description = "精於算計的工廠巨頭。手握財富與人脈，擅長以金錢為武器操控局勢，讓所有人都為他的利益服務。"
	c.lore = "理查的祖父是約克郡的小地主，父親靠投資煤礦發跡。理查繼承家業後大舉擴張，在伯明翰建立了三座棉紡廠。他深諳『金錢即權力』的道理——議會裡沒有買不到的票，只有出價不夠高的蠢人。他的帳房裡記錄著每一位議員的弱點與價碼。"
	# 屬性：控制型角色，高智慧與魅力
	c.attack = 5
	c.defense = 4
	c.charisma = 8
	c.intelligence = 9
	c.luck = 6
	# 技能：收買 — 花 30 金收買敵方角色
	c.skill_name = "收買"
	c.skill_description = "花費 30 金幣收買一名敵方角色，使其在本回合無法行動。金錢能解決一切。"
	c.skill_type = SkillType.ACTIVE
	c.skill_effect = {
		"type": "bribe",
		"gold_cost": 30,
		"target": "enemy_single",
		"effect": "silence_1_turn",
	}
	return c


# === 盧德派喬治 — 改革派 ===
static func _create_george() -> CharacterData:
	var c: CharacterData = CharacterData.new()
	c.id = "george"
	c.character_name = "盧德派喬治"
	c.character_name_en = "George"
	c.character_type = CharacterType.GEORGE
	c.faction_id = "reformist"
	c.portrait_path = "res://assets/images/characters/portrait_george.png"
	c.description = "憤怒的機器破壞者。以暴烈的行動力聞名，不惜一切代價對抗工業化的壓迫，即使傷敵一千自損八百。"
	c.lore = "喬治原是諾丁漢的熟練織工，機械織布機的引入讓他和數百名工友一夜之間失業。他親手砸毀了第一台搶走他飯碗的機器，從此成為盧德運動的象徵。他的怒火無法遏止，但他心裡清楚：革命的代價，往往由革命者自己承擔。"
	# 屬性：攻擊型角色，高攻擊但防禦低
	c.attack = 10
	c.defense = 3
	c.charisma = 6
	c.intelligence = 4
	c.luck = 7
	# 技能：怒火 — 攻擊翻倍但自傷 10
	c.skill_name = "怒火"
	c.skill_description = "發動時攻擊傷害翻倍，但自身受到 10 點聲望損傷。孤注一擲的瘋狂之力。"
	c.skill_type = SkillType.ACTIVE
	c.skill_effect = {
		"type": "rage",
		"damage_multiplier": 2,
		"self_damage": 10,
		"target": "enemy_single",
	}
	return c


# === 外交官羅伯特 — 外交聯盟 ===
static func _create_robert() -> CharacterData:
	var c: CharacterData = CharacterData.new()
	c.id = "robert"
	c.character_name = "外交官羅伯特"
	c.character_name_en = "Robert"
	c.character_type = CharacterType.ROBERT
	c.faction_id = "diplomatic"
	c.portrait_path = "res://assets/images/characters/portrait_robert.png"
	c.description = "八面玲瓏的外交老手。穿梭於各派系之間，以談判與妥協化解衝突，讓每個人都覺得自己佔了便宜。"
	c.lore = "羅伯特出身外交官家族，父親曾出使維也納宮廷。他從小學會在餐桌上觀察每個人的表情，在沙龍中揣摩每句話的弦外之音。拿破崙戰爭期間，他多次在英法之間斡旋，挽救了無數條性命。他相信：戰場上得不到的，談判桌上都能爭取回來。"
	# 屬性：外交型角色，高魅力與智慧
	c.attack = 3
	c.defense = 5
	c.charisma = 10
	c.intelligence = 8
	c.luck = 6
	# 技能：斡旋 — 使兩個敵對勢力暫時停戰，本回合無法互相攻擊
	c.skill_name = "斡旋"
	c.skill_description = "指定兩名玩家，使他們本回合無法互相攻擊。優雅地讓衝突消弭於無形。"
	c.skill_type = SkillType.ACTIVE
	c.skill_effect = {
		"type": "mediate",
		"target": "enemy_pair",
		"effect": "prevent_attack_between_targets_1_turn",
		"cooldown": 2,
	}
	return c


# === 貴族威廉 — 鷹派 ===
static func _create_william() -> CharacterData:
	var c: CharacterData = CharacterData.new()
	c.id = "william"
	c.character_name = "貴族威廉"
	c.character_name_en = "William"
	c.character_type = CharacterType.WILLIAM
	c.faction_id = "hawk"
	c.portrait_path = "res://assets/images/characters/portrait_william.png"
	c.description = "戰功彪炳的軍事貴族。以鐵腕手段維護帝國榮光，相信只有強大的軍力才能確保不列顛的霸權與秩序。"
	c.lore = "威廉是威爾士邊境伯爵的長子，十六歲便隨父從軍。在半島戰爭中，他率領一支騎兵連隊突破法軍防線，贏得了『鐵騎威廉』的綽號。戰爭結束後回到議會，他發現文人政客的爭吵和戰場一樣兇險——但他手中的武器從劍變成了投票權。"
	# 屬性：軍事型角色，高攻擊與防禦
	c.attack = 9
	c.defense = 7
	c.charisma = 4
	c.intelligence = 6
	c.luck = 4
	# 技能：軍威 — 攻擊時有 30% 機率使目標下回合行動力 -1
	c.skill_name = "軍威"
	c.skill_description = "發動攻擊時，有 30% 機率震懾目標，使其下回合行動力 -1。戰場上的威壓延伸到議會。"
	c.skill_type = SkillType.PASSIVE
	c.skill_effect = {
		"type": "intimidate",
		"trigger": "on_attack",
		"chance": 0.3,
		"effect": "reduce_action_points",
		"value": -1,
		"duration": 1,
		"target": "attack_target",
	}
	return c


# === 勞工領袖艾德華 — 民社黨 ===
static func _create_edward() -> CharacterData:
	var c: CharacterData = CharacterData.new()
	c.id = "edward"
	c.character_name = "勞工領袖艾德華"
	c.character_name_en = "Edward"
	c.character_type = CharacterType.EDWARD
	c.faction_id = "social"
	c.portrait_path = "res://assets/images/characters/portrait_edward.png"
	c.description = "工人運動的溫和派領袖。相信透過議會途徑為勞工爭取權益，以穩健的手腕在各方勢力間取得平衡。"
	c.lore = "艾德華是曼徹斯特棉紡廠的工頭之子。父親因工傷失去右手後，他立志要用法律而非暴力改變工人的處境。他自學法律，在工廠裡開辦夜間識字班，培養了一批有組織能力的工運幹部。他常說：『我們不需要砸機器，我們需要的是投票權。』"
	# 屬性：平衡型角色，高魅力與智慧
	c.attack = 5
	c.defense = 6
	c.charisma = 8
	c.intelligence = 7
	c.luck = 5
	# 技能：團結談判 — 聲望落後時自動恢復
	c.skill_name = "團結談判"
	c.skill_description = "每回合結束時，若己方聲望低於對手，自動恢復 8 點聲望。沉默的多數終將發聲。"
	c.skill_type = SkillType.PASSIVE
	c.skill_effect = {
		"type": "underdog_heal",
		"value": 8,
		"trigger": "turn_end",
		"condition": "reputation_below_opponent",
		"target": "self",
	}
	return c
