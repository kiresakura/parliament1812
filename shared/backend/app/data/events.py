"""
突發事件資料

主持人可以抽取事件卡改變局勢
"""

# 突發事件定義
EVENTS = {
    # === 工人相關事件 ===
    "riot_nottingham": {
        "id": "riot_nottingham",
        "title": "諾丁漢暴動",
        "description": "諾丁漢的織襪工人發起大規模暴動，數十台機器被搗毀。軍隊已被派往鎮壓。這場暴動讓國會對盧德派的態度更加強硬。",
        "effect_type": "opinion_shift",
        "severity": 4,
        "effect_detail": "支持選項 B（保護財產）的壓力增加",
    },
    "worker_petition": {
        "id": "worker_petition",
        "title": "工人請願書",
        "description": "來自約克郡的一萬名紡織工人聯名請願，懇求國會保護他們的生計。請願書描述了工人家庭的悲慘處境，引起了部分議員的同情。",
        "effect_type": "opinion_shift",
        "severity": 3,
        "effect_detail": "支持選項 A（禁止機器）或 C（折衷改革）的聲浪增加",
    },
    "child_labor_report": {
        "id": "child_labor_report",
        "title": "童工調查報告",
        "description": "一份關於工廠童工的調查報告被公開。報告揭露了駭人的工作條件：六歲的孩子每天工作十四小時，許多人因操作機器而受傷甚至死亡。",
        "effect_type": "scandal",
        "severity": 4,
        "effect_detail": "工廠主的公信力受損，改革派聲勢上升",
    },

    # === 政治事件 ===
    "royal_interest": {
        "id": "royal_interest",
        "title": "王室關注",
        "description": "攝政王喬治對機器問題表示關切，暗示可能成立皇家調查委員會。這為辯論增添了新的可能性。",
        "effect_type": "unlock_option",
        "severity": 5,
        "effect_detail": "解鎖投票選項 D（皇家調查）",
    },
    "tory_pressure": {
        "id": "tory_pressure",
        "title": "托利黨施壓",
        "description": "首相帕西瓦爾的托利黨政府發出明確信號：政府立場偏向保護工廠主的財產權。任何支持工人的議員可能面臨政治後果。",
        "effect_type": "pressure",
        "severity": 3,
        "effect_detail": "對議員角色施加壓力，傾向支持選項 B",
    },
    "whig_speech": {
        "id": "whig_speech",
        "title": "輝格黨演說",
        "description": "著名的輝格黨議員發表了一場激情演說，呼籲以人道主義的方式處理機器問題，強調工人的基本權利不應被忽視。",
        "effect_type": "opinion_shift",
        "severity": 3,
        "effect_detail": "改革派立場獲得支持",
    },

    # === 經濟事件 ===
    "export_boom": {
        "id": "export_boom",
        "title": "出口激增",
        "description": "來自殖民地的訂單激增，英國紡織品出口創下新高。工廠主們強調，這證明了機器的重要性——沒有機器，英國無法滿足市場需求。",
        "effect_type": "economic",
        "severity": 3,
        "effect_detail": "支持工業化的論點更有說服力",
    },
    "food_shortage": {
        "id": "food_shortage",
        "title": "糧食短缺",
        "description": "由於戰爭和歉收，麵包價格飆升。失業工人的處境更加艱難，部分地區已出現搶糧事件。社會動盪的風險正在升高。",
        "effect_type": "crisis",
        "severity": 4,
        "effect_detail": "社會穩定成為首要考量",
    },
    "bank_failure": {
        "id": "bank_failure",
        "title": "銀行倒閉",
        "description": "一家與紡織業密切相關的地方銀行宣布破產，多家工廠面臨資金鏈斷裂的危機。經濟不確定性增加了各方的焦慮。",
        "effect_type": "economic",
        "severity": 4,
        "effect_detail": "經濟穩定成為關注焦點",
    },

    # === 突發事件 ===
    "luddite_leader_arrest": {
        "id": "luddite_leader_arrest",
        "title": "盧德派領袖被捕",
        "description": "據報一名盧德派核心人物在約克郡被捕。軍方聲稱掌握了更多領袖的情報，盧德運動面臨被瓦解的危機。",
        "effect_type": "arrest",
        "severity": 5,
        "effect_detail": "盧德派角色面臨額外壓力",
    },
    "factory_fire": {
        "id": "factory_fire",
        "title": "工廠大火",
        "description": "曼徹斯特一家大型紡織廠發生火災，數名工人喪生。起火原因不明，有人懷疑是盧德派縱火，也有人認為是工廠安全措施不足所致。",
        "effect_type": "incident",
        "severity": 4,
        "effect_detail": "各方可以利用此事件支持自己的立場",
    },
    "spy_revealed": {
        "id": "spy_revealed",
        "title": "間諜曝光",
        "description": "有傳言稱，工人組織中有政府安插的間諜。這個消息讓工人們對彼此的信任產生動搖，也讓盧德派的組織活動更加困難。",
        "effect_type": "betrayal",
        "severity": 3,
        "effect_detail": "工人陣營內部信任度下降",
    },

    # === 國際事件 ===
    "napoleon_news": {
        "id": "napoleon_news",
        "title": "拿破崙戰報",
        "description": "前線傳來消息：與拿破崙的戰爭正處於關鍵時刻。有議員提醒，國內的動亂可能被法國利用，現在不是分裂的時候。",
        "effect_type": "external",
        "severity": 3,
        "effect_detail": "國家團結的論點更有說服力",
    },
    "american_trade": {
        "id": "american_trade",
        "title": "美國貿易爭議",
        "description": "英美關係惡化，美國市場可能對英國關閉。這對紡織業是巨大打擊，工廠主和工人都將受到影響。",
        "effect_type": "external",
        "severity": 3,
        "effect_detail": "經濟合作的重要性被強調",
    },
}


def get_event_by_id(event_id: str) -> dict | None:
    """根據 ID 取得事件"""
    return EVENTS.get(event_id)


def get_all_events() -> list[dict]:
    """取得所有事件"""
    return list(EVENTS.values())


def get_events_by_severity(min_severity: int = 1, max_severity: int = 5) -> list[dict]:
    """根據嚴重程度篩選事件"""
    return [
        e for e in EVENTS.values()
        if min_severity <= e["severity"] <= max_severity
    ]


def get_events_by_effect_type(effect_type: str) -> list[dict]:
    """根據效果類型篩選事件"""
    return [e for e in EVENTS.values() if e["effect_type"] == effect_type]
