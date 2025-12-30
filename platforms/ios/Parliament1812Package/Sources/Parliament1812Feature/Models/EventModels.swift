import Foundation

// MARK: - Event Category

/// 事件分類：國內事件或國際事件
enum EventCategory: String, Codable, CaseIterable, Sendable {
    case domestic = "domestic"       // 國內事件
    case international = "international" // 國際事件

    var displayName: String {
        switch self {
        case .domestic: return "國內事件"
        case .international: return "國際事件"
        }
    }

    var englishName: String {
        switch self {
        case .domestic: return "Domestic"
        case .international: return "International"
        }
    }

    var iconName: String {
        switch self {
        case .domestic: return "building.columns.fill"
        case .international: return "globe.europe.africa.fill"
        }
    }
}

// MARK: - Event Type

/// 事件類型
enum EventType: String, Codable, CaseIterable, Sendable {
    // 國內事件類型
    case disaster = "disaster"       // 災難：工廠爆炸、大火、洪災、瘟疫、糧食歉收
    case political = "political"     // 政治：貪腐醜聞、國王病發、選舉舞弊、王室醜聞、內閣改組
    case social = "social"           // 社會：盧德派暴動、改革遊行、礦工罷工、民間諷刺劇、識字運動
    case economic = "economic"       // 經濟：經濟危機、投機泡沫、通貨膨脹、貿易繁榮、銀行倒閉
    case military = "military"       // 軍事：軍隊嘩變、戰爭英雄歸來、叛亂鎮壓、海軍勝利、軍火走私
    case religious = "religious"     // 宗教：宗教覺醒、教會分裂、神蹟顯現
    case special = "special"         // 特殊：叛徒曝光、人口普查

    // 國際事件類型
    case war = "war"                 // 戰爭：法軍逼近、拿破崙戰爭升級、滑鐵盧戰役
    case diplomacy = "diplomacy"     // 外交：和平談判、神聖同盟、歐洲王室聯姻
    case colony = "colony"           // 殖民地：愛爾蘭起義、印度動亂、廢奴運動

    var displayName: String {
        switch self {
        case .disaster: return "災難"
        case .political: return "政治"
        case .social: return "社會"
        case .economic: return "經濟"
        case .military: return "軍事"
        case .religious: return "宗教"
        case .special: return "特殊"
        case .war: return "戰爭"
        case .diplomacy: return "外交"
        case .colony: return "殖民地"
        }
    }

    var englishName: String {
        switch self {
        case .disaster: return "Disaster"
        case .political: return "Political"
        case .social: return "Social"
        case .economic: return "Economic"
        case .military: return "Military"
        case .religious: return "Religious"
        case .special: return "Special"
        case .war: return "War"
        case .diplomacy: return "Diplomacy"
        case .colony: return "Colonial"
        }
    }

    var iconName: String {
        switch self {
        case .disaster: return "flame.fill"
        case .political: return "crown.fill"
        case .social: return "person.3.fill"
        case .economic: return "sterlingsign.circle.fill"
        case .military: return "shield.fill"
        case .religious: return "cross.fill"
        case .special: return "exclamationmark.triangle.fill"
        case .war: return "burst.fill"
        case .diplomacy: return "handshake.fill"
        case .colony: return "flag.fill"
        }
    }

    var themeColor: String {
        switch self {
        case .disaster: return "red"
        case .political: return "purple"
        case .social: return "blue"
        case .economic: return "gold"
        case .military: return "gray"
        case .religious: return "white"
        case .special: return "orange"
        case .war: return "darkRed"
        case .diplomacy: return "green"
        case .colony: return "brown"
        }
    }
}

// MARK: - Event Effect

/// 事件效果
struct EventEffect: Codable, Identifiable, Sendable, Hashable {
    var id: String { "\(targetRole ?? "all")_\(supportChange)_\(reputationChange)" }

    /// 受影響角色，nil 表示全體
    let targetRole: String?

    /// 支持度變化
    let supportChange: Int

    /// 聲望值變化
    let reputationChange: Int

    /// 觸發條件（可選）
    let condition: String?

    init(
        targetRole: String? = nil,
        supportChange: Int = 0,
        reputationChange: Int = 0,
        condition: String? = nil
    ) {
        self.targetRole = targetRole
        self.supportChange = supportChange
        self.reputationChange = reputationChange
        self.condition = condition
    }

    /// 效果描述
    var description: String {
        var parts: [String] = []
        let target = targetRole ?? "全體"

        if supportChange != 0 {
            let sign = supportChange > 0 ? "+" : ""
            parts.append("\(target) \(sign)\(supportChange) 支持度")
        }

        if reputationChange != 0 {
            let sign = reputationChange > 0 ? "+" : ""
            parts.append("\(target) \(sign)\(reputationChange) 聲望")
        }

        return parts.joined(separator: ", ")
    }
}

// MARK: - Event Choice

/// 事件選項（用於需要玩家選擇的事件）
struct EventChoice: Codable, Identifiable, Sendable, Hashable {
    let id: String
    let title: String
    let description: String
    let effects: [EventEffect]

    init(id: String, title: String, description: String, effects: [EventEffect]) {
        self.id = id
        self.title = title
        self.description = description
        self.effects = effects
    }
}

// MARK: - Game Event Data

/// 遊戲事件數據
struct GameEventData: Codable, Identifiable, Sendable, Hashable {
    let id: String
    let title: String
    let englishTitle: String
    let description: String
    let category: EventCategory
    let type: EventType
    let severity: Int // 1-3，影響程度
    let effects: [EventEffect]
    let choices: [EventChoice]?

    init(
        id: String,
        title: String,
        englishTitle: String,
        description: String,
        category: EventCategory,
        type: EventType,
        severity: Int = 1,
        effects: [EventEffect],
        choices: [EventChoice]? = nil
    ) {
        self.id = id
        self.title = title
        self.englishTitle = englishTitle
        self.description = description
        self.category = category
        self.type = type
        self.severity = min(max(severity, 1), 3)
        self.effects = effects
        self.choices = choices
    }

    /// 是否需要玩家選擇
    var requiresChoice: Bool {
        choices != nil && !(choices?.isEmpty ?? true)
    }

    /// 是否為緊急事件（嚴重程度 >= 2）
    var isUrgent: Bool {
        severity >= 2
    }

    /// 是否為危機事件（嚴重程度 == 3）
    var isCritical: Bool {
        severity == 3
    }
}

// MARK: - Predefined Events Data

/// 預設事件數據庫
enum EventDatabase {

    // MARK: - 國內事件 (Domestic Events)

    static let domesticEvents: [GameEventData] = [
        // 災難類
        GameEventData(
            id: "factory_explosion",
            title: "工廠大爆炸",
            englishTitle: "Factory Explosion",
            description: "曼徹斯特一間大型紡織廠發生鍋爐爆炸，造成數十人死傷。工人們要求加強安全法規，工廠主則擔心成本上升。",
            category: .domestic,
            type: .disaster,
            severity: 3,
            effects: [
                EventEffect(targetRole: "factory", supportChange: -4, reputationChange: -2),
                EventEffect(targetRole: "worker", supportChange: 0, reputationChange: 2)
            ]
        ),

        GameEventData(
            id: "great_fire",
            title: "倫敦大火",
            englishTitle: "The Great Fire",
            description: "泰晤士河畔的倉庫區發生大火，延燒數日。數百戶人家無家可歸，糧食物資嚴重短缺。",
            category: .domestic,
            type: .disaster,
            severity: 2,
            effects: [
                EventEffect(targetRole: nil, supportChange: -1, reputationChange: -1)
            ]
        ),

        GameEventData(
            id: "plague_outbreak",
            title: "瘟疫爆發",
            englishTitle: "Plague Outbreak",
            description: "利物浦港口傳出傳染病疫情，已有多人死亡。恐慌情緒在城市蔓延，民眾要求政府採取行動。",
            category: .domestic,
            type: .disaster,
            severity: 3,
            effects: [
                EventEffect(targetRole: nil, supportChange: -2, reputationChange: -2)
            ]
        ),

        // 政治類
        GameEventData(
            id: "corruption_scandal",
            title: "貪腐醜聞",
            englishTitle: "Corruption Scandal",
            description: "一名內閣大臣被揭發收受賄賂，引發朝野震動。改革派呼籲清洗腐敗，保守派則試圖淡化事件。",
            category: .domestic,
            type: .political,
            severity: 2,
            effects: [
                EventEffect(targetRole: "mp", supportChange: -3, reputationChange: -2),
                EventEffect(targetRole: "reformer", supportChange: 2, reputationChange: 1)
            ]
        ),

        GameEventData(
            id: "king_illness",
            title: "國王病發",
            englishTitle: "King's Illness",
            description: "喬治三世再度陷入精神錯亂，攝政王權力擴大。政局動盪，各方勢力蠢蠢欲動。",
            category: .domestic,
            type: .political,
            severity: 3,
            effects: [
                EventEffect(targetRole: nil, supportChange: -1, reputationChange: 0),
                EventEffect(targetRole: "mp", supportChange: 0, reputationChange: -1)
            ]
        ),

        GameEventData(
            id: "cabinet_reshuffle",
            title: "內閣改組",
            englishTitle: "Cabinet Reshuffle",
            description: "首相宣布內閣改組，多位大臣去職。新任命引發議會激烈辯論。",
            category: .domestic,
            type: .political,
            severity: 1,
            effects: [
                EventEffect(targetRole: "mp", supportChange: 1, reputationChange: 0)
            ]
        ),

        // 社會類
        GameEventData(
            id: "luddite_riot",
            title: "盧德派暴動",
            englishTitle: "Luddite Riot",
            description: "諾丁漢郡爆發大規模盧德派暴動，數十台機器被搗毀。政府派軍鎮壓，數人被捕。",
            category: .domestic,
            type: .social,
            severity: 3,
            effects: [
                EventEffect(targetRole: "luddite", supportChange: -2, reputationChange: 3),
                EventEffect(targetRole: "factory", supportChange: 2, reputationChange: -1)
            ]
        ),

        GameEventData(
            id: "reform_march",
            title: "改革遊行",
            englishTitle: "Reform March",
            description: "數千名群眾在倫敦街頭遊行，要求擴大選舉權和議會改革。遊行和平進行，但當局嚴陣以待。",
            category: .domestic,
            type: .social,
            severity: 2,
            effects: [
                EventEffect(targetRole: "reformer", supportChange: 2, reputationChange: 2),
                EventEffect(targetRole: "mp", supportChange: -1, reputationChange: 0)
            ]
        ),

        GameEventData(
            id: "miners_strike",
            title: "礦工罷工",
            englishTitle: "Miners' Strike",
            description: "威爾斯煤礦工人發動罷工，要求改善工作條件和提高工資。罷工導致煤炭供應短缺。",
            category: .domestic,
            type: .social,
            severity: 2,
            effects: [
                EventEffect(targetRole: "worker", supportChange: 1, reputationChange: 2),
                EventEffect(targetRole: "factory", supportChange: -2, reputationChange: 0)
            ]
        ),

        // 經濟類
        GameEventData(
            id: "economic_crisis",
            title: "經濟危機",
            englishTitle: "Economic Crisis",
            description: "戰爭開支導致國家財政吃緊，銀行收縮信貸，多家企業倒閉。民眾生活困難，怨聲載道。",
            category: .domestic,
            type: .economic,
            severity: 3,
            effects: [
                EventEffect(targetRole: nil, supportChange: -2, reputationChange: 0),
                EventEffect(targetRole: "factory", supportChange: -2, reputationChange: 0)
            ]
        ),

        GameEventData(
            id: "trade_boom",
            title: "貿易繁榮",
            englishTitle: "Trade Boom",
            description: "大西洋貿易蓬勃發展，商船往來頻繁。工廠訂單增加，商人獲利豐厚。",
            category: .domestic,
            type: .economic,
            severity: 1,
            effects: [
                EventEffect(targetRole: "factory", supportChange: 2, reputationChange: 1),
                EventEffect(targetRole: nil, supportChange: 1, reputationChange: 0)
            ]
        ),

        // 軍事類
        GameEventData(
            id: "war_hero_returns",
            title: "戰爭英雄歸來",
            englishTitle: "War Hero Returns",
            description: "威靈頓公爵從西班牙戰場凱旋歸來，全國歡慶。軍方威望大增，主戰派聲勢高漲。",
            category: .domestic,
            type: .military,
            severity: 1,
            effects: [
                EventEffect(targetRole: nil, supportChange: 1, reputationChange: 1),
                EventEffect(targetRole: "mp", supportChange: 1, reputationChange: 0)
            ]
        ),

        // 宗教類
        GameEventData(
            id: "religious_revival",
            title: "宗教覺醒",
            englishTitle: "Religious Revival",
            description: "衛斯理宗的佈道會在各地引發宗教復興運動，信徒人數激增。傳統教會感到壓力。",
            category: .domestic,
            type: .religious,
            severity: 1,
            effects: [
                EventEffect(targetRole: "reformer", supportChange: 1, reputationChange: 1)
            ]
        ),

        // 特殊類
        GameEventData(
            id: "traitor_exposed",
            title: "叛徒曝光",
            englishTitle: "Traitor Exposed",
            description: "一名議員被發現暗中與敵國勾結，引發朝野震驚。忠誠問題成為焦點。",
            category: .domestic,
            type: .special,
            severity: 3,
            effects: [
                EventEffect(targetRole: "mp", supportChange: -3, reputationChange: -3)
            ],
            choices: [
                EventChoice(
                    id: "harsh_punishment",
                    title: "嚴厲懲處",
                    description: "公開審判並處以極刑，以儆效尤",
                    effects: [
                        EventEffect(targetRole: nil, supportChange: 1, reputationChange: 0)
                    ]
                ),
                EventChoice(
                    id: "quiet_removal",
                    title: "低調處理",
                    description: "悄悄剝奪其職位，避免醜聞擴大",
                    effects: [
                        EventEffect(targetRole: "mp", supportChange: 0, reputationChange: -1)
                    ]
                )
            ]
        ),

        GameEventData(
            id: "census_results",
            title: "人口普查",
            englishTitle: "Census Results",
            description: "最新人口普查結果顯示，工業城市人口激增，農村人口大量流失。社會結構正在劇變。",
            category: .domestic,
            type: .special,
            severity: 1,
            effects: [
                EventEffect(targetRole: "worker", supportChange: 1, reputationChange: 0),
                EventEffect(targetRole: "factory", supportChange: 1, reputationChange: 0)
            ]
        )
    ]

    // MARK: - 國際事件 (International Events)

    static let internationalEvents: [GameEventData] = [
        // 戰爭類
        GameEventData(
            id: "french_advance",
            title: "法軍逼近",
            englishTitle: "French Advance",
            description: "拿破崙的軍隊在歐洲大陸節節勝利，威脅英國盟友。國會必須決定是否增派援軍。",
            category: .international,
            type: .war,
            severity: 3,
            effects: [
                EventEffect(targetRole: nil, supportChange: -1, reputationChange: -1)
            ],
            choices: [
                EventChoice(
                    id: "send_troops",
                    title: "增派援軍",
                    description: "立即動員軍隊支援盟國",
                    effects: [
                        EventEffect(targetRole: nil, supportChange: -2, reputationChange: 1)
                    ]
                ),
                EventChoice(
                    id: "negotiate",
                    title: "外交談判",
                    description: "嘗試通過外交途徑解決危機",
                    effects: [
                        EventEffect(targetRole: "reformer", supportChange: 2, reputationChange: 0)
                    ]
                )
            ]
        ),

        GameEventData(
            id: "napoleon_war_escalation",
            title: "拿破崙戰爭升級",
            englishTitle: "Napoleonic War Escalation",
            description: "法國皇帝拿破崙宣布對英國實施大陸封鎖，全面禁止歐洲與英國貿易。經濟壓力驟增。",
            category: .international,
            type: .war,
            severity: 3,
            effects: [
                EventEffect(targetRole: nil, supportChange: -2, reputationChange: 0),
                EventEffect(targetRole: "factory", supportChange: -3, reputationChange: 0)
            ]
        ),

        GameEventData(
            id: "waterloo_battle",
            title: "滑鐵盧戰役",
            englishTitle: "Battle of Waterloo",
            description: "聯軍與拿破崙的最終決戰即將展開。戰爭的結果將決定歐洲的命運。",
            category: .international,
            type: .war,
            severity: 3,
            effects: [
                EventEffect(targetRole: nil, supportChange: 0, reputationChange: 0)
            ],
            choices: [
                EventChoice(
                    id: "victory",
                    title: "勝利",
                    description: "聯軍大獲全勝，拿破崙被流放",
                    effects: [
                        EventEffect(targetRole: nil, supportChange: 3, reputationChange: 3)
                    ]
                ),
                EventChoice(
                    id: "pyrrhic_victory",
                    title: "慘勝",
                    description: "聯軍獲勝但損失慘重",
                    effects: [
                        EventEffect(targetRole: nil, supportChange: 1, reputationChange: 1)
                    ]
                )
            ]
        ),

        // 外交類
        GameEventData(
            id: "peace_negotiation",
            title: "和平談判",
            englishTitle: "Peace Negotiation",
            description: "法國提出和談建議，願意在某些條件下停止敵對行動。鴿派與鷹派意見分歧。",
            category: .international,
            type: .diplomacy,
            severity: 2,
            effects: [
                EventEffect(targetRole: "reformer", supportChange: 2, reputationChange: 1)
            ],
            choices: [
                EventChoice(
                    id: "accept_terms",
                    title: "接受條件",
                    description: "同意法國提出的和平條件",
                    effects: [
                        EventEffect(targetRole: nil, supportChange: 2, reputationChange: -1)
                    ]
                ),
                EventChoice(
                    id: "reject_terms",
                    title: "拒絕談判",
                    description: "堅持戰鬥到底，直到完全勝利",
                    effects: [
                        EventEffect(targetRole: nil, supportChange: -1, reputationChange: 2)
                    ]
                )
            ]
        ),

        GameEventData(
            id: "holy_alliance",
            title: "神聖同盟",
            englishTitle: "Holy Alliance",
            description: "俄國、奧地利和普魯士組成神聖同盟，英國考慮是否加入這個保守勢力聯盟。",
            category: .international,
            type: .diplomacy,
            severity: 2,
            effects: [
                EventEffect(targetRole: "mp", supportChange: 1, reputationChange: 1)
            ]
        ),

        // 殖民地類
        GameEventData(
            id: "irish_uprising",
            title: "愛爾蘭起義",
            englishTitle: "Irish Uprising",
            description: "愛爾蘭爆發大規模起義，要求獨立。政府面臨鎮壓還是妥協的艱難抉擇。",
            category: .international,
            type: .colony,
            severity: 3,
            effects: [
                EventEffect(targetRole: nil, supportChange: -2, reputationChange: -1)
            ],
            choices: [
                EventChoice(
                    id: "military_suppression",
                    title: "軍事鎮壓",
                    description: "派遣軍隊強力鎮壓叛亂",
                    effects: [
                        EventEffect(targetRole: nil, supportChange: -1, reputationChange: -2)
                    ]
                ),
                EventChoice(
                    id: "political_concession",
                    title: "政治讓步",
                    description: "與起義領袖談判，給予部分自治權",
                    effects: [
                        EventEffect(targetRole: "reformer", supportChange: 2, reputationChange: 1)
                    ]
                )
            ]
        ),

        GameEventData(
            id: "india_unrest",
            title: "印度動亂",
            englishTitle: "Indian Unrest",
            description: "東印度公司在印度的統治遭遇挑戰，當地勢力蠢蠢欲動。殖民利益面臨威脅。",
            category: .international,
            type: .colony,
            severity: 2,
            effects: [
                EventEffect(targetRole: "factory", supportChange: -2, reputationChange: 0)
            ]
        ),

        GameEventData(
            id: "abolition_movement",
            title: "廢奴運動",
            englishTitle: "Abolition Movement",
            description: "威爾伯福斯等人推動的廢奴運動獲得越來越多支持。奴隸貿易的存廢成為重大議題。",
            category: .international,
            type: .colony,
            severity: 2,
            effects: [
                EventEffect(targetRole: "reformer", supportChange: 3, reputationChange: 2),
                EventEffect(targetRole: "factory", supportChange: -1, reputationChange: 0)
            ],
            choices: [
                EventChoice(
                    id: "support_abolition",
                    title: "支持廢奴",
                    description: "支持立法禁止奴隸貿易",
                    effects: [
                        EventEffect(targetRole: "reformer", supportChange: 2, reputationChange: 2)
                    ]
                ),
                EventChoice(
                    id: "protect_trade",
                    title: "維護貿易",
                    description: "以經濟利益為由反對廢奴",
                    effects: [
                        EventEffect(targetRole: "factory", supportChange: 2, reputationChange: -2)
                    ]
                )
            ]
        )
    ]

    // MARK: - All Events

    static var allEvents: [GameEventData] {
        domesticEvents + internationalEvents
    }

    /// 隨機獲取指定分類的事件
    static func randomEvent(category: EventCategory? = nil) -> GameEventData? {
        let pool: [GameEventData]
        if let category = category {
            pool = category == .domestic ? domesticEvents : internationalEvents
        } else {
            pool = allEvents
        }
        return pool.randomElement()
    }

    /// 根據 ID 獲取事件
    static func event(byId id: String) -> GameEventData? {
        allEvents.first { $0.id == id }
    }

    /// 獲取指定類型的所有事件
    static func events(ofType type: EventType) -> [GameEventData] {
        allEvents.filter { $0.type == type }
    }

    /// 獲取指定嚴重程度的事件
    static func events(severity: Int) -> [GameEventData] {
        allEvents.filter { $0.severity == severity }
    }
}

// MARK: - Event State for Game Flow

/// 事件狀態（用於遊戲流程追蹤）
@Observable
final class EventState: @unchecked Sendable {
    var currentEvent: GameEventData?
    var selectedChoice: EventChoice?
    var isRevealed: Bool = false
    var appliedEffects: [EventEffect] = []

    @MainActor
    func setEvent(_ event: GameEventData?) {
        self.currentEvent = event
        self.selectedChoice = nil
        self.isRevealed = false
        self.appliedEffects = []
    }

    @MainActor
    func reveal() {
        isRevealed = true
    }

    @MainActor
    func selectChoice(_ choice: EventChoice) {
        selectedChoice = choice
        appliedEffects = choice.effects
    }

    @MainActor
    func applyDefaultEffects() {
        if let event = currentEvent {
            appliedEffects = event.effects
        }
    }
}
