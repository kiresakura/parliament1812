"""
秘密任務資料定義

每種角色有 4 種不同的秘密任務：
- _01: 內心衝突型（私人利益 vs 公開立場）
- _02: 復仇/恩怨型
- _03: 雙面人/臥底型
- _04: 理想主義/覺醒型
"""
from typing import TypedDict


class MissionData(TypedDict):
    """秘密任務資料結構"""
    id: str
    role_type: str
    title: str
    description: str
    success_condition: str
    points: int
    difficulty: str  # easy, medium, hard


SECRET_MISSIONS: dict[str, MissionData] = {
    # ========== 工人 (Worker) 秘密任務 ==========
    "worker_01": {
        "id": "worker_01",
        "role_type": "worker",
        "title": "家族的秘密",
        "description": """你的兒子偷偷在威爾森先生的工廠找到了一份工作，
負責操作新式織機。如果禁止機器的法案通過，他就會失業。
但你在工人中的威望要求你必須反對機器...""",
        "success_condition": "投票支持選項 C（折衷改革），同時在辯論中至少發言兩次支持工人權益",
        "points": 50,
        "difficulty": "medium",
    },
    "worker_02": {
        "id": "worker_02",
        "role_type": "worker",
        "title": "父親的仇恨",
        "description": """你的父親去年在一次工廠意外中喪生，
而那家工廠的主人正是今天在場的理查·威爾森。
你發誓要讓他付出代價，無論用什麼方式...""",
        "success_condition": "成功說服至少 2 名玩家在最終投票中投票反對威爾森支持的選項",
        "points": 60,
        "difficulty": "hard",
    },
    "worker_03": {
        "id": "worker_03",
        "role_type": "worker",
        "title": "政府的線人",
        "description": """你其實是內政部安插在工人中的線人。
你的任務是記錄今天所有同情盧德派的言論，
並在會後向你的上級報告可疑人物的身份...""",
        "success_condition": "私訊至少 3 名不同玩家套取他們對盧德派的真實看法，並記錄下來",
        "points": 70,
        "difficulty": "hard",
    },
    "worker_04": {
        "id": "worker_04",
        "role_type": "worker",
        "title": "覺醒的火種",
        "description": """你最近讀了湯瑪斯·潘恩的《人權論》，
開始相信真正的問題不是機器，而是整個不平等的社會制度。
你想在今天的辯論中播下革命思想的種子...""",
        "success_condition": "在辯論中至少一次公開質疑現有政治制度的公平性，並獲得至少 1 名玩家的附和",
        "points": 50,
        "difficulty": "medium",
    },
    
    # ========== 工廠主 (Factory) 秘密任務 ==========
    "factory_01": {
        "id": "factory_01",
        "role_type": "factory",
        "title": "破產的邊緣",
        "description": """你的工廠其實已經負債累累。
如果不能繼續使用機器降低成本，你將在三個月內破產。
但你必須維持成功企業家的形象...""",
        "success_condition": "確保最終投票結果不是選項 A（禁止機器）",
        "points": 50,
        "difficulty": "medium",
    },
    "factory_02": {
        "id": "factory_02",
        "role_type": "factory",
        "title": "背叛者的復仇",
        "description": """盧德派領袖喬治·梅勒曾是你工廠的工人，
三年前他帶頭罷工時你解僱了他。現在他成了你的死敵。
你要在今天揭露他的真實身份，讓他被逮捕...""",
        "success_condition": "在辯論中公開指控某位玩家有盧德派嫌疑（不一定要是真的盧德派）",
        "points": 60,
        "difficulty": "hard",
    },
    "factory_03": {
        "id": "factory_03",
        "role_type": "factory",
        "title": "雙面商人",
        "description": """你私下已經和一些盧德派達成協議：
你資助他們攻擊競爭對手的工廠，換取他們不碰你的產業。
今天你需要表面上譴責盧德派，但暗中保護你的「合作夥伴」...""",
        "success_condition": "投票支持選項 B（保護財產），但私下告訴至少 1 名玩家你同情工人",
        "points": 70,
        "difficulty": "hard",
    },
    "factory_04": {
        "id": "factory_04",
        "role_type": "factory",
        "title": "良心的覺醒",
        "description": """上週你親眼看到一個八歲的童工被機器壓斷了手指。
那個孩子的眼神讓你徹夜難眠。你開始懷疑自己一直以來的信念...
也許羅伯特·乾文說的是對的？""",
        "success_condition": "在辯論中至少一次公開支持改善工人待遇，並最終投票支持選項 C",
        "points": 50,
        "difficulty": "medium",
    },
    
    # ========== 盧德派 (Luddite) 秘密任務 ==========
    "luddite_01": {
        "id": "luddite_01",
        "role_type": "luddite",
        "title": "臥底的矛盾",
        "description": """你的弟弟在威爾森的工廠工作，是家裡唯一的經濟來源。
如果你的盧德派身份曝光，他也會被連累解僱。
你必須在革命理想和家庭責任之間做出選擇...""",
        "success_condition": "全程不暴露自己的盧德派身份，但仍設法讓最終投票不是選項 B",
        "points": 60,
        "difficulty": "hard",
    },
    "luddite_02": {
        "id": "luddite_02",
        "role_type": "luddite",
        "title": "血債血償",
        "description": """去年的一次夜襲中，你的同伴被工廠警衛射殺。
你發誓要找到下令開槍的人。你的情報顯示，
那個人今天就在這個房間裡...""",
        "success_condition": "找出並私訊指控你認為是「兇手」的玩家（由主持人秘密指定）",
        "points": 70,
        "difficulty": "hard",
    },
    "luddite_03": {
        "id": "luddite_03",
        "role_type": "luddite",
        "title": "激進派的使命",
        "description": """你是盧德派中最激進的一員。
你認為今天的辯論毫無意義，真正的改變只能透過暴力實現。
你的任務是讓這場辯論失敗，證明和平手段行不通...""",
        "success_condition": "讓最終投票無法達成任何選項的過半數（造成僵局）",
        "points": 80,
        "difficulty": "hard",
    },
    "luddite_04": {
        "id": "luddite_04",
        "role_type": "luddite",
        "title": "和平的可能",
        "description": """你最近開始懷疑暴力是否真的能帶來改變。
你聽說了羅伯特·乾文的新拉納克實驗，也許還有另一條路？
你想在今天尋找一個不流血的解決方案...""",
        "success_condition": "與改革者（羅伯特）建立同盟，並在最終投票中支持選項 C",
        "points": 50,
        "difficulty": "medium",
    },
    
    # ========== 改革者 (Reformer) 秘密任務 ==========
    "reformer_01": {
        "id": "reformer_01",
        "role_type": "reformer",
        "title": "理想與現實",
        "description": """你的新拉納克工廠最近遇到了財務困難。
投資人威脅說，如果你繼續堅持「浪費錢」在工人福利上，
他們就會撤資。你需要證明人道經營也能盈利...""",
        "success_condition": "說服至少 2 名玩家公開支持你的改革理念",
        "points": 50,
        "difficulty": "medium",
    },
    "reformer_02": {
        "id": "reformer_02",
        "role_type": "reformer",
        "title": "舊日的恩怨",
        "description": """威爾森曾是你的商業夥伴，但五年前他背叛了你，
偷走了你的一項專利設計。你表面上已經和解，
但內心深處你一直在等待報復的機會...""",
        "success_condition": "在辯論中找機會揭露或暗示威爾森的不道德行為",
        "points": 60,
        "difficulty": "hard",
    },
    "reformer_03": {
        "id": "reformer_03",
        "role_type": "reformer",
        "title": "秘密的同情者",
        "description": """你私下資助了一些盧德派的家庭，幫助他們度過難關。
如果這件事曝光，你的社會地位和生意都會毀於一旦。
但你相信這是正確的事...""",
        "success_condition": "私下聯繫你認為是盧德派的玩家，表達支持但不暴露自己的秘密",
        "points": 60,
        "difficulty": "medium",
    },
    "reformer_04": {
        "id": "reformer_04",
        "role_type": "reformer",
        "title": "烏托邦的夢想",
        "description": """你一直夢想建立一個完美的工人社區，
一個沒有剝削、人人平等的新社會。今天的辯論可能是
讓更多人聽到你理念的機會...""",
        "success_condition": "在辯論中詳細闡述你的社會改革願景，並獲得至少 3 名玩家的正面回應",
        "points": 50,
        "difficulty": "medium",
    },
    
    # ========== 議員 (MP) 秘密任務 ==========
    "mp_01": {
        "id": "mp_01",
        "role_type": "mp",
        "title": "政治的代價",
        "description": """你的主要政治獻金來源是工廠主們。
如果你投票支持限制機器的法案，他們威脅會在下次選舉中支持你的對手。
但你的選區工人選民也在看著你...""",
        "success_condition": "最終投票支持選項 C（折衷方案），並在辯論中展現「兩面討好」的技巧",
        "points": 50,
        "difficulty": "medium",
    },
    "mp_02": {
        "id": "mp_02",
        "role_type": "mp",
        "title": "家族的秘密",
        "description": """你的侄子是一名盧德派成員，上個月剛被逮捕。
如果這件事公開，你的政治生涯就完了。
你需要確保今天的辯論不會讓任何人挖出這個秘密...""",
        "success_condition": "阻止任何對盧德派成員進行「肉搜」或身份調查的提議",
        "points": 60,
        "difficulty": "hard",
    },
    "mp_03": {
        "id": "mp_03",
        "role_type": "mp",
        "title": "內閣的眼線",
        "description": """內政大臣私下要求你監視今天的辯論，
記錄任何可能威脅社會穩定的激進言論。
作為回報，他承諾在下次內閣改組時提拔你...""",
        "success_condition": "記錄至少 3 條「激進言論」並在遊戲結束時報告（私訊主持人）",
        "points": 70,
        "difficulty": "hard",
    },
    "mp_04": {
        "id": "mp_04",
        "role_type": "mp",
        "title": "良心的召喚",
        "description": """你年輕時曾是一名理想主義者，相信政治可以改變世界。
多年的政壇浮沉讓你變得世故。但今天，看著這些真誠的面孔，
你開始回想起當初從政的初衷...""",
        "success_condition": "在辯論中至少一次放棄政治算計，真誠地表達你對工人的同情",
        "points": 40,
        "difficulty": "easy",
    },

    # ========== 喬治三世 (George III) 秘密任務 ==========
    "george_iii_01": {
        "id": "george_iii_01",
        "role_type": "george_iii",
        "title": "清醒時刻",
        "description": """你今天精神狀態良好，要在攝政王面前證明自己仍然清醒。
世人稱你為「瘋王」，但你知道自己只是偶爾不適。
今天你要展現真正的王者風範...""",
        "success_condition": "整場辯論中沒有表現出任何精神錯亂的跡象",
        "points": 50,
        "difficulty": "medium",
    },
    "george_iii_02": {
        "id": "george_iii_02",
        "role_type": "george_iii",
        "title": "帝國榮光",
        "description": """你想在有生之年看到帝國戰勝拿破崙。
工業革命帶來的生產力對戰爭至關重要，
你不能讓任何事情阻礙帝國的軍事力量...""",
        "success_condition": "最終決議有利於戰爭物資生產（不是選項 A）",
        "points": 60,
        "difficulty": "medium",
    },
    "george_iii_03": {
        "id": "george_iii_03",
        "role_type": "george_iii",
        "title": "王室秘密",
        "description": """你其實暗中同情那些失業的工人，因為他們讓你想起年輕時的自己。
在成為國王之前，你曾在鄉間與普通人交談。
你要在辯論中為工人說話，但不能太明顯...""",
        "success_condition": "在辯論中為工人說至少一句好話，但不能太明顯影響你的王權威嚴",
        "points": 70,
        "difficulty": "hard",
    },
    "george_iii_04": {
        "id": "george_iii_04",
        "role_type": "george_iii",
        "title": "瘋王的智慧",
        "description": """有時候，裝瘋是最好的政治策略...
當局勢對你不利時，一次「發作」可以巧妙地轉移話題。
沒有人會責怪一個「病人」的失態...""",
        "success_condition": "在關鍵時刻「發作」，成功轉移話題或打斷對你不利的討論",
        "points": 80,
        "difficulty": "hard",
    },
}


# NFC 卡片 ID 對應秘密任務的映射
# 格式：{card_id: mission_id}
# 每種角色有 4 張卡片，編號 01-04
NFC_CARD_MAPPING: dict[str, str] = {
    # Worker 卡片
    "WORKER01": "worker_01",
    "WORKER02": "worker_02",
    "WORKER03": "worker_03",
    "WORKER04": "worker_04",
    # Factory 卡片
    "FACTORY01": "factory_01",
    "FACTORY02": "factory_02",
    "FACTORY03": "factory_03",
    "FACTORY04": "factory_04",
    # Luddite 卡片
    "LUDDITE01": "luddite_01",
    "LUDDITE02": "luddite_02",
    "LUDDITE03": "luddite_03",
    "LUDDITE04": "luddite_04",
    # Reformer 卡片
    "REFORMER01": "reformer_01",
    "REFORMER02": "reformer_02",
    "REFORMER03": "reformer_03",
    "REFORMER04": "reformer_04",
    # MP 卡片
    "MP01": "mp_01",
    "MP02": "mp_02",
    "MP03": "mp_03",
    "MP04": "mp_04",
    # George III 卡片 (特殊角色)
    "GEORGEIII01": "george_iii_01",
    "GEORGEIII02": "george_iii_02",
    "GEORGEIII03": "george_iii_03",
    "GEORGEIII04": "george_iii_04",
}


def get_mission_by_id(mission_id: str) -> MissionData | None:
    """
    根據 ID 取得秘密任務
    
    Args:
        mission_id: 任務 ID
        
    Returns:
        任務資料或 None
    """
    return SECRET_MISSIONS.get(mission_id)


def get_missions_by_role(role_type: str) -> list[MissionData]:
    """
    取得某角色的所有秘密任務
    
    Args:
        role_type: 角色類型
        
    Returns:
        該角色的所有秘密任務列表
    """
    return [
        mission for mission in SECRET_MISSIONS.values()
        if mission["role_type"] == role_type
    ]


def get_mission_by_card_id(card_id: str) -> MissionData | None:
    """
    根據 NFC 卡片 ID 取得秘密任務
    
    Args:
        card_id: NFC 卡片 ID
        
    Returns:
        任務資料或 None
    """
    mission_id = NFC_CARD_MAPPING.get(card_id.upper())
    if mission_id:
        return get_mission_by_id(mission_id)
    return None


def get_role_from_card_id(card_id: str) -> tuple[str, int] | None:
    """
    從卡片 ID 解析角色類型和索引

    Args:
        card_id: NFC 卡片 ID（如 "WORKER01" 或 "GEORGEIII01"）

    Returns:
        (角色類型, 索引) 元組或 None
    """
    card_id = card_id.upper()

    # 解析卡片 ID (注意：GEORGEIII 要在其他角色之前檢查，因為它比較長)
    for role in ["GEORGEIII", "WORKER", "FACTORY", "LUDDITE", "REFORMER", "MP"]:
        if card_id.startswith(role):
            try:
                index = int(card_id[len(role):])
                # GEORGEIII 映射到 george_iii
                role_type = "george_iii" if role == "GEORGEIII" else role.lower()
                return (role_type, index)
            except ValueError:
                return None

    return None
