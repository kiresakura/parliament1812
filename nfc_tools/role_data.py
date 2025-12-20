"""
1812 國會風雲 - 角色與秘密任務資料
"""

from dataclasses import dataclass
from typing import List, Optional
import hashlib
import secrets

@dataclass
class SecretMission:
    """秘密任務"""
    title: str
    description: str
    success_condition: str
    points: int = 50

@dataclass
class Role:
    """角色定義"""
    id: str
    name_zh: str
    name_en: str
    title: str
    age: int
    background: str
    core_stance: str
    greatest_fear: str
    arguments: List[str]
    secret_missions: List[SecretMission]
    is_special: bool = False  # 特殊角色標記
    special_ability: Optional[str] = None  # 特殊能力

# ═══════════════════════════════════════════════════════════════
# 👑 特殊角色
# ═══════════════════════════════════════════════════════════════

SPECIAL_ROLES = {
    "george_iii": Role(
        id="george_iii",
        name_zh="喬治三世",
        name_en="George III",
        title="大不列顛國王",
        age=73,
        background="漢諾威王朝國王，統治大英帝國長達60年。你見證了美國獨立、法國大革命，如今又要面對工業革命帶來的社會動盪。晚年飽受精神疾病折磨，世人稱你為「瘋王」。",
        core_stance="維護王權與帝國穩定，在各方勢力中保持平衡",
        greatest_fear="失去理智、王權旁落、帝國分裂",
        arguments=[
            "朕是神授君權的體現，國家的穩定繫於王室的威嚴",
            "無論托利黨還是輝格黨，都必須服從王權",
            "朕不會讓任何人動搖大英帝國的根基"
        ],
        secret_missions=[
            SecretMission("清醒時刻", "你今天精神狀態良好，要在攝政王面前證明自己仍然清醒。", "整場辯論中沒有表現出任何精神錯亂的跡象", 50),
            SecretMission("帝國榮光", "你想在有生之年看到帝國戰勝拿破崙。", "最終決議有利於戰爭物資生產", 60),
            SecretMission("王室秘密", "你其實暗中同情那些失業的工人，因為他們讓你想起年輕時的自己。", "在辯論中為工人說至少一句好話，但不能太明顯", 70),
            SecretMission("瘋王的智慧", "有時候，裝瘋是最好的政治策略...", "在關鍵時刻「發作」，成功轉移話題或打斷對你不利的討論", 80)
        ],
        is_special=True,
        special_ability="【王權宣言】每場遊戲可發動一次，強制結束當前辯論並進入投票階段。"
    ),
}

# ═══════════════════════════════════════════════════════════════
# 👥 一般角色
# ═══════════════════════════════════════════════════════════════

ROLES = {
    "worker": Role(
        id="worker",
        name_zh="湯瑪斯",
        name_en="Thomas",
        title="紡織工人",
        age=38,
        background="14歲開始當學徒，苦練10年成為師傅。你的雙手能織出全村最精細的布料，這是你唯一的驕傲。但現在，一個工廠女工操作機器一天織的布，比你一週還多。",
        core_stance="機器搶走了我們的飯碗，必須限制或禁止",
        greatest_fear="變成乞丐，讓家人挨餓",
        arguments=[
            "我們的技術是花了十年才學會的，憑什麼一夕之間變得毫無價值？",
            "機器讓工廠主賺大錢，工人卻連飯都吃不飽，這公平嗎？",
            "如果所有人都失業，誰來買那些機器織的布？"
        ],
        secret_missions=[
            SecretMission("血濃於水", "你的長子在威爾森先生的工廠工作。如果工廠倒閉，他會失業。", "最終結果不是選項A（禁止機器）", 50),
            SecretMission("復仇之火", "威爾森的工廠害死了你的弟弟。你暗中聯繫了盧德派，想要他的工廠付出代價。", "成功說服至少一名盧德派成員在辯論中點名攻擊威爾森", 60),
            SecretMission("雙面人", "改革者烏爾文私下給你錢，要你在辯論中支持C選項，但你的工人同伴不知道這件事。", "投票選C，且不被同陣營發現你收了錢", 70),
            SecretMission("絕望的父親", "你的小女兒生了重病，需要一大筆醫藥費。有人暗示，如果選項B通過，會有人「感謝」你。", "最終結果是選項B", 40)
        ]
    ),
    "factory": Role(
        id="factory",
        name_zh="理查·威爾森",
        name_en="Richard Wilson",
        title="工廠主",
        age=45,
        background="父親是小布商，你靠自己的眼光和膽識投資了最新的蒸汽紡織機。現在你的工廠產量是傳統作坊的50倍。你相信機器化是進步的象徵。",
        core_stance="機器代表進步，政府應該保護私有財產",
        greatest_fear="暴民毀掉工廠，政府禁止機器，投資血本無歸",
        arguments=[
            "我的工廠雇用了200人，比任何手工作坊都多",
            "機器讓布料變便宜，窮人也買得起衣服穿了",
            "如果禁止機器，英國就會被法國和其他國家超越"
        ],
        secret_missions=[
            SecretMission("骯髒的秘密", "你的工廠有僱用童工，而且工作環境很差。如果這件事曝光，你會身敗名裂。", "整場辯論中沒有人提到你工廠的童工問題", 50),
            SecretMission("政治投資", "你暗中資助了菲茨傑拉德議員的選舉。他欠你人情。", "議員在辯論中至少兩次為你的立場說話", 60),
            SecretMission("商業間諜", "你其實也投資了競爭對手的工廠。如果你的工廠被砸，你反而會獲利。", "成功讓盧德派相信你是他們的主要敵人（轉移注意力）", 70),
            SecretMission("良心發現？", "你最近開始失眠，夢到那些因你而失業的工人。也許...改革不是壞事？", "在辯論中主動提出一項對工人有利的建議", 40)
        ]
    ),
    "luddite": Role(
        id="luddite",
        name_zh="喬治",
        name_en="George",
        title="盧德派成員",
        age=28,
        background="你曾是守法公民，但當你看到鄰居一家五口餓死街頭，你決定不再沉默。你們在夜間行動，砸毀機器，留下「乃德·盧德將軍」的署名。",
        core_stance="機器是工人的敵人，必須用行動摧毀它",
        greatest_fear="被逮捕處死，運動失敗，同伴白白犧牲",
        arguments=[
            "請願沒有用，遊行沒有用，只有行動才能讓他們聽見我們的聲音",
            "我們不是暴民，我們是被逼到絕路的人",
            "如果政府不保護人民，人民就只能自己保護自己"
        ],
        secret_missions=[
            SecretMission("臥底", "你其實是政府派來的線人。你的任務是讓盧德派的訴求失敗，並記錄誰是激進份子。", "最終結果不是選項A，且你在辯論中沒有暴露身份", 80),
            SecretMission("私人恩怨", "威爾森的工廠害死了你的父親。這不只是為了工人，這是為了復仇。", "在辯論中讓威爾森公開道歉或承認錯誤", 60),
            SecretMission("動搖的信念", "你開始懷疑暴力手段是否正確。改革者烏爾文的話讓你心動。", "在最終投票中選擇C而不是A", 50),
            SecretMission("真正的領袖", "你想成為盧德運動的真正領袖。你需要在這場辯論中證明自己。", "被其他盧德派成員推選為主要發言人，且發言獲得掌聲", 40)
        ]
    ),
    "reformer": Role(
        id="reformer",
        name_zh="羅伯特·烏爾文",
        name_en="Robert Owens",
        title="社會改革者",
        age=35,
        background="你同情工人，但你認為砸機器解決不了問題。機器本身是中性的，問題在於貪婪的工廠主和袖手旁觀的政府。你主張透過立法改革。",
        core_stance="問題不在機器，在於分配不公，應該立法保障工人",
        greatest_fear="被兩邊同時拋棄，改革永遠不會實現",
        arguments=[
            "砸機器只會招來鎮壓，我們需要的是長遠的制度改革",
            "工廠主也可以賺錢，但必須給工人合理的待遇",
            "教育和立法才是改變社會的真正力量"
        ],
        secret_missions=[
            SecretMission("金主的壓力", "威爾森先生資助了你的學校。如果你公開反對他，學校就會關門。", "整場辯論不直接批評威爾森本人（可以批評「工廠主」但不點名）", 50),
            SecretMission("激進的過去", "你年輕時其實參加過盧德派的行動，這是你不想讓人知道的黑歷史。", "沒有人在辯論中揭露你的過去", 60),
            SecretMission("野心家", "你想進入國會。這場辯論是你展示自己的機會。", "被議員公開稱讚，或被邀請進一步討論", 70),
            SecretMission("理想主義者", "你真心相信C選項能改變世界。你要說服盡可能多的人。", "至少有3名非改革者陣營的人投票選C", 40)
        ]
    ),
    "mp": Role(
        id="mp",
        name_zh="威廉·菲茨傑拉德",
        name_en="William Fitzgerald",
        title="國會議員",
        age=52,
        background="托利黨議員，擁有鄉間莊園。你本來對工業不太關心，但現在這件事鬧到國會了。你的選區裡既有工廠主也有工人，你得考慮選票。",
        core_stance="維護秩序是首要任務，但也要找到讓各方都能接受的方案",
        greatest_fear="做出錯誤決定，被歷史記住是個蠢貨或暴君",
        arguments=[
            "法律與秩序必須維護，破壞財產者必須受到懲罰",
            "但我們也不能讓民眾餓死，這會動搖國本",
            "也許我們需要一個折衷方案..."
        ],
        secret_missions=[
            SecretMission("骯髒的交易", "你收了威爾森的政治獻金。如果這件事曝光，你的政治生涯就完了。", "整場辯論沒有人質疑你與工廠主的關係", 50),
            SecretMission("私生子", "你有一個私生子，他是個工人。你不想讓他曝光，但也不想他餓死。", "最終結果不是選項B（純鎮壓）", 60),
            SecretMission("歷史的審判", "你在意後世如何評價你。你想被記住是個明智的政治家。", "提出一個被多數人接受的修正案或折衷方案", 70),
            SecretMission("黨派壓力", "黨魁私下告訴你，黨的立場是支持B選項。違背黨意可能影響你的仕途。", "最終投票選擇B", 40)
        ]
    )
}

# 合併所有角色
ALL_ROLES = {**SPECIAL_ROLES, **ROLES}

EVENTS = [
    {"id": "newspaper_riot", "title": "📰 報紙號外", "description": "「曼徹斯特發生暴動，3名工人死於軍隊鎮壓！」\n\n輿論開始同情工人...", "effect": "所有人重新考慮對選項B的立場"},
    {"id": "bribery_scandal", "title": "💰 賄賂醜聞", "description": "「有匿名信指控某位議員收受工廠主賄賂！」\n\n（隨機指定一名議員玩家）", "effect": "被指控的議員必須公開回應"},
    {"id": "factory_fire", "title": "🔥 工廠大火", "description": "「威爾森先生的工廠今晨發生大火！懷疑是人為縱火！」\n\n盧德派是否該被追究？", "effect": "工廠主和盧德派必須表態"},
    {"id": "royal_concern", "title": "👑 皇室關切", "description": "「攝政王發表聲明：『社會和諧是國家之本，朕甚為關切。』」", "effect": "增加隱藏選項D：成立皇家調查委員會"},
    {"id": "letter_exposed", "title": "🤫 密信曝光", "description": "「一封神秘的信件被公開了！」\n\n（隨機揭露一名玩家的秘密任務）", "effect": "被選中的玩家秘密任務曝光"},
    {"id": "child_testimony", "title": "👧 童工證詞", "description": "「一名10歲女童在國會門口哭訴：『我每天工作14小時，手指都變形了...』」", "effect": "所有人必須回應童工問題"},
    {"id": "french_news", "title": "🇫🇷 法國消息", "description": "「據報，法國已開始大規模採用蒸汽機！英國工業將被超越！」", "effect": "國際競爭壓力增加"},
    {"id": "worker_death", "title": "💀 工人之死", "description": "「一名工人今晨餓死街頭，身上只有一張紙：『機器殺死了我』」", "effect": "情緒激動，可能影響投票"},
    {"id": "kings_madness", "title": "👑 國王發作", "description": "「國王陛下今日在宮中突然發作，高喊『朕是神！』」\n\n攝政王是否該正式接管？", "effect": "喬治三世玩家可選擇：裝作沒事/承認需要休息"}
]

def generate_card_id(role_type: str, index: int) -> str:
    """
    生成卡片 ID，格式需匹配後端
    後端期望格式: WORKER01, FACTORY02, LUDDITE03, REFORMER04, MP01
    """
    # 角色類型映射 (本地 -> 後端)
    role_mapping = {
        "worker": "WORKER",
        "factory": "FACTORY",
        "luddite": "LUDDITE",
        "reformer": "REFORMER",
        "mp": "MP",
        "george_iii": "GEORGE_III",  # 特殊角色 (需要後端支援)
    }
    backend_type = role_mapping.get(role_type, role_type.upper())
    return f"{backend_type}{index:02d}"


def generate_secret_hash(card_id: str, secret_key: str = None) -> str:
    """
    生成 NFC 卡片驗證 hash

    必須使用與後端相同的演算法：
    - HMAC-SHA256
    - 使用 SECRET_KEY 作為密鑰
    - 取前 16 個字元

    Args:
        card_id: 卡片 ID (如 WORKER01)
        secret_key: 後端的 SECRET_KEY (必須與 Railway 環境變數一致)

    Returns:
        16 字元的 hash
    """
    import hmac

    if not secret_key:
        raise ValueError(
            "⚠️  需要提供 SECRET_KEY！\n"
            "請從 Railway 環境變數取得 SECRET_KEY，或使用後端 API /api/admin/nfc-cards"
        )

    # 與後端相同的演算法
    expected_hash = hmac.new(
        secret_key.encode(),
        card_id.upper().encode(),
        hashlib.sha256,
    ).hexdigest()[:16]

    return expected_hash


def get_nfc_url(card_id: str, secret_hash: str) -> str:
    """生成 NFC URL"""
    return f"parliament1812://role?id={card_id}&secret={secret_hash}"
