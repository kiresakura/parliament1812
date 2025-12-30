import Foundation
import SwiftUI

// MARK: - Role Ability

struct RoleAbility: Sendable {
    let name: String
    let description: String
    let icon: String
}

// MARK: - Secret Mission

struct SecretMission: Codable, Identifiable, Sendable {
    let id: String
    let roleType: String
    let title: String
    let description: String
    let successCondition: String?
    let points: Int
}

// MARK: - Detailed Role Data

struct RoleDetailData: Sendable {
    let type: String
    let nameZh: String
    let nameEn: String
    let characterName: String
    let age: Int
    let occupation: String
    let background: String
    let description: String
    let quote: String
    let color: Color
    let abilities: [RoleAbility]
    let secretMissions: [SecretMission]
    let stance: String
    let allies: [String]
    let enemies: [String]
}

// MARK: - Role Database

enum RoleDatabase {

    // MARK: - Colors

    static let workerColor = Color(red: 0.5, green: 0.35, blue: 0.25)
    static let factoryColor = Color(red: 0.3, green: 0.3, blue: 0.35)
    static let ludditeColor = Color(red: 0.55, green: 0.25, blue: 0.2)
    static let reformerColor = Color.parliamentGreen
    static let mpColor = Color.parliamentBurgundy
    static let georgeIIIColor = Color(red: 0.55, green: 0.42, blue: 0.25)

    // MARK: - Worker

    static let worker = RoleDetailData(
        type: "worker",
        nameZh: "紡織工人",
        nameEn: "TEXTILE WORKER",
        characterName: "湯瑪斯·哈德卡索",
        age: 38,
        occupation: "約克郡紡織工人",
        background: """
        湯瑪斯出生於約克郡的一個紡織世家，從十二歲起便在家庭作坊中學習織布技藝。
        二十年來，他以精湛的手藝聞名鄉里，但新式蒸汽織布機的出現，
        讓他和無數同行的生計面臨前所未有的威脅。
        """,
        description: "你是一名紡織工人，機器的出現威脅著你的生計。你需要為工人的權益發聲。",
        quote: "機器或許能織布，但它不能養活我們的家庭。",
        color: workerColor,
        abilities: [
            RoleAbility(name: "工人團結", description: "說服其他工人支持你的立場時，獲得額外說服力", icon: "Ⅰ"),
            RoleAbility(name: "基層智慧", description: "了解實際勞動情況，可以揭穿不切實際的政策", icon: "Ⅱ"),
            RoleAbility(name: "家庭負擔", description: "在討論民生議題時，你的發言更具感染力", icon: "Ⅲ")
        ],
        secretMissions: [
            SecretMission(id: "worker_01", roleType: "worker", title: "私藏的發明圖紙",
                          description: "你的岳父是一位機械工程師，臨終前交給你一份改良織布機的圖紙。如果這份圖紙被工廠主採用，你可以獲得專利費過上好日子——但這將加速機器取代工人的進程。",
                          successCondition: "在遊戲結束前，選擇公開或銷毀圖紙，並讓至少一名玩家知道你的選擇", points: 60),
            SecretMission(id: "worker_02", roleType: "worker", title: "復仇的種子",
                          description: "三年前，工廠主理查·威爾森的工廠爆發瘟疫，你的弟弟就是因為惡劣的工作環境而死去。威爾森從未承認責任，甚至沒有給予任何補償。",
                          successCondition: "在公開辯論中指控工廠主威爾森，並得到至少兩名玩家的支持", points: 50),
            SecretMission(id: "worker_03", roleType: "worker", title: "盧德派的臥底",
                          description: "你其實是盧德派運動的秘密成員。你們計劃在法案通過後發動一場破壞行動，而你的任務是收集情報。但你開始動搖——暴力真的是唯一的出路嗎？",
                          successCondition: "秘密與盧德派成員交換至少三條情報，或在最終投票前公開你的真實身份", points: 70),
            SecretMission(id: "worker_04", roleType: "worker", title: "覺醒的改革者",
                          description: "一位來自城市的改革者曾在你的家鄉演講，他的話語在你心中種下了改革的種子。你開始相信，或許透過教育和立法，工人可以與機器共存。",
                          successCondition: "成功說服一名工人或盧德派支持「折衷改革」選項", points: 55)
        ],
        stance: "傾向禁止機器 (選項A)",
        allies: ["luddite", "reformer"],
        enemies: ["factory_owner"]
    )

    // MARK: - Factory Owner

    static let factoryOwner = RoleDetailData(
        type: "factory_owner",
        nameZh: "工廠主",
        nameEn: "FACTORY OWNER",
        characterName: "理查·威爾森",
        age: 45,
        occupation: "曼徹斯特紡織廠主",
        background: """
        理查·威爾森是曼徹斯特最大的紡織廠主之一。
        他從一個小作坊起家，透過精明的商業頭腦和對新技術的敏銳嗅覺，
        在二十年間建立起一個紡織帝國。
        """,
        description: "你是一名工廠主，機器能為你帶來更多利潤。但你也需要考慮社會穩定。",
        quote: "進步的車輪不會因為幾個懷舊者的眼淚而停止轉動。",
        color: factoryColor,
        abilities: [
            RoleAbility(name: "商業影響力", description: "可以用經濟利益說服議員支持你的立場", icon: "Ⅰ"),
            RoleAbility(name: "產業先驅", description: "在討論技術和經濟議題時，你的專業意見更有說服力", icon: "Ⅱ"),
            RoleAbility(name: "政商關係", description: "與某些議員有私下往來，可以獲得額外情報", icon: "Ⅲ")
        ],
        secretMissions: [
            SecretMission(id: "factory_01", roleType: "factory_owner", title: "良心的拷問",
                          description: "你的工廠確實發生過工人傷亡事件，你用錢封住了受害者家屬的口。但午夜夢迴時，那些面孔仍會出現在你的夢中。",
                          successCondition: "支持「折衷改革」選項，並在辯論中提出改善工人待遇的具體方案", points: 55),
            SecretMission(id: "factory_02", roleType: "factory_owner", title: "商業競爭對手",
                          description: "你的最大競爭對手——伯明翰的湯普森工廠，正在秘密遊說議會禁止機器。你知道他們這麼做是因為他們的機器技術落後。",
                          successCondition: "在辯論中成功指出反機器陣營中存在的利益衝突", points: 50),
            SecretMission(id: "factory_03", roleType: "factory_owner", title: "雙面人",
                          description: "你其實一直在暗中資助盧德派，希望利用他們破壞競爭對手的工廠。但事情開始失控——你自己的工廠也成為了目標。",
                          successCondition: "秘密與盧德派成員達成停火協議，並確保你的身份不被其他玩家發現", points: 75),
            SecretMission(id: "factory_04", roleType: "factory_owner", title: "工業革命的信徒",
                          description: "你真心相信機器是人類進步的象徵，而你願意分享這份進步的果實。你計劃建立一所工人學校，讓工人的孩子學習讀寫和機械知識。",
                          successCondition: "在辯論中提出工人教育計劃，並得到至少三名玩家的公開支持", points: 60)
        ],
        stance: "傾向保護財產 (選項B)",
        allies: ["mp"],
        enemies: ["worker", "luddite"]
    )

    // MARK: - Luddite

    static let luddite = RoleDetailData(
        type: "luddite",
        nameZh: "盧德派",
        nameEn: "LUDDITE",
        characterName: "「奈德王」喬治",
        age: 28,
        occupation: "盧德運動領袖",
        background: """
        沒有人知道喬治的真實姓氏，人們只知道他以傳說中的「奈德·盧德」之名領導著一群憤怒的工人。
        他曾是一名出色的剪裁師，但當機器奪走了他的工作，他選擇了戰鬥。
        """,
        description: "你是盧德運動的成員，堅信機器會毀滅工人的生活。你願意採取激進行動。",
        quote: "如果法律不保護我們，那就讓錘子來說話！",
        color: ludditeColor,
        abilities: [
            RoleAbility(name: "革命威望", description: "你的名聲讓其他激進分子願意聽從你的意見", icon: "Ⅰ"),
            RoleAbility(name: "地下網絡", description: "你可以獲得關於工廠動態的秘密情報", icon: "Ⅱ"),
            RoleAbility(name: "威嚇戰術", description: "可以用暴力威脅迫使某些人改變立場", icon: "Ⅲ")
        ],
        secretMissions: [
            SecretMission(id: "luddite_01", roleType: "luddite", title: "背負的血債",
                          description: "在一次破壞行動中，一名無辜的守夜人被你的追隨者誤殺。你從未告訴過任何人這件事，但死者的眼神一直縈繞在你心頭。",
                          successCondition: "在遊戲過程中放棄所有暴力威脅行動，並說服至少一名盧德派成員支持和平路線", points: 65),
            SecretMission(id: "luddite_02", roleType: "luddite", title: "私人恩怨",
                          description: "工廠主威爾森正是害得你父親破產自殺的人。五年前，威爾森用不正當手段收購了你父親的作坊。",
                          successCondition: "成功讓威爾森在公眾面前名譽掃地，或私下獲得他的道歉", points: 50),
            SecretMission(id: "luddite_03", roleType: "luddite", title: "政府的線人",
                          description: "你其實是政府派來的臥底。你的任務是打入盧德派內部，收集成員名單和行動計劃。但在這段時間裡，你開始理解工人們的苦難。",
                          successCondition: "在遊戲結束時，選擇向政府提交名單或公開你的臥底身份", points: 80),
            SecretMission(id: "luddite_04", roleType: "luddite", title: "和平的曙光",
                          description: "一位改革派議員曾私下接觸你，提議如果你們放棄暴力，他會在議會中為工人權益發聲。",
                          successCondition: "成功說服至少兩名工人或盧德派成員支持「折衷改革」選項", points: 60)
        ],
        stance: "傾向禁止機器 (選項A)",
        allies: ["worker"],
        enemies: ["factory_owner", "mp"]
    )

    // MARK: - Reformer

    static let reformer = RoleDetailData(
        type: "reformer",
        nameZh: "改革者",
        nameEn: "REFORMER",
        characterName: "羅伯特·烏爾文",
        age: 35,
        occupation: "改革派思想家",
        background: """
        羅伯特·烏爾文曾是劍橋大學的政治學教授，但他認為象牙塔中的學術爭論無法真正改變世界。
        他離開大學，投身於社會改革運動，成為最具影響力的改革派思想家之一。
        """,
        description: "你是一名改革者，相信透過立法可以在進步與保護之間找到平衡。",
        quote: "我們不能阻止時代的車輪，但我們可以為它鋪設正確的軌道。",
        color: reformerColor,
        abilities: [
            RoleAbility(name: "雄辯之才", description: "你的演講能夠影響中立者的立場", icon: "Ⅰ"),
            RoleAbility(name: "法律專家", description: "可以提出具體的法案修正案", icon: "Ⅱ"),
            RoleAbility(name: "橋樑建設者", description: "可以促成不同陣營之間的對話和妥協", icon: "Ⅲ")
        ],
        secretMissions: [
            SecretMission(id: "reformer_01", roleType: "reformer", title: "理想與現實",
                          description: "你的改革理論很美好，但你其實從未親眼見過工廠的真實情況。一位工人邀請你去參觀他工作的地方，你所見到的景象遠比你想像的要殘酷。",
                          successCondition: "在辯論中引用你「親眼所見」的工廠現況，並因此修改你的立場", points: 50),
            SecretMission(id: "reformer_02", roleType: "reformer", title: "背後的金主",
                          description: "你的改革運動一直由一位神秘的貴族資助。最近你發現，這位貴族其實是工廠主威爾森的表親，他資助你只是為了讓改革派分化工人陣營。",
                          successCondition: "在遊戲中公開你的資金來源，並拒絕繼續接受資助", points: 55),
            SecretMission(id: "reformer_03", roleType: "reformer", title: "雙面下注",
                          description: "你其實與盧德派有秘密聯繫，你一直在為他們提供法律建議，幫助他們規避政府的追捕。但如果這件事曝光，你的政治生涯就完了。",
                          successCondition: "成功說服盧德派在最終投票前放棄暴力威脅，同時保守你協助他們的秘密", points: 70),
            SecretMission(id: "reformer_04", roleType: "reformer", title: "未來的建築師",
                          description: "你有一個宏大的願景：建立一個工人、工廠主和政府三方合作的委員會，共同制定產業政策。",
                          successCondition: "讓至少各一名工人、工廠主和議員同意參與你提議的三方委員會", points: 65)
        ],
        stance: "傾向折衷改革 (選項C)",
        allies: ["worker", "mp"],
        enemies: []
    )

    // MARK: - Member of Parliament

    static let mp = RoleDetailData(
        type: "mp",
        nameZh: "議員",
        nameEn: "MEMBER OF PARLIAMENT",
        characterName: "威廉·菲茨傑拉德爵士",
        age: 52,
        occupation: "下議院議員",
        background: """
        威廉·菲茨傑拉德是一位資深議員，在西敏寺服務超過二十年。
        他代表的選區包括工業城鎮和農村地區，這讓他的立場總是需要謹慎權衡。
        """,
        description: "你是一名國會議員，需要在各方利益之間權衡，做出最終決定。",
        quote: "我們在這裡不是為了滿足某一方，而是為了國家的未來。",
        color: mpColor,
        abilities: [
            RoleAbility(name: "議事規則專家", description: "可以影響辯論的程序和規則", icon: "Ⅰ"),
            RoleAbility(name: "投票影響力", description: "你的投票對其他中立議員有示範效應", icon: "Ⅱ"),
            RoleAbility(name: "權力掮客", description: "可以在私下進行政治交易", icon: "Ⅲ")
        ],
        secretMissions: [
            SecretMission(id: "mp_01", roleType: "mp", title: "選區的壓力",
                          description: "你的選區工廠主們聯合寫信要求你支持「保護財產」法案，否則他們會在下次選舉中資助你的對手。",
                          successCondition: "找到一種投票方式既能滿足選區要求又能保護工人權益", points: 55),
            SecretMission(id: "mp_02", roleType: "mp", title: "舊日的債務",
                          description: "多年前，你曾在一次政治危機中接受過盧德派的幫助——他們幫你掩蓋了一樁醜聞。現在他們要求你償還這份人情。",
                          successCondition: "在不完全順從盧德派要求的情況下，保守你的秘密", points: 60),
            SecretMission(id: "mp_03", roleType: "mp", title: "王室的意志",
                          description: "你收到了來自王室的秘密信函，暗示國王喬治三世對這個議題有特定的看法。",
                          successCondition: "與喬治三世進行私下對話，並根據對話結果調整你的投票策略", points: 50),
            SecretMission(id: "mp_04", roleType: "mp", title: "改革的推手",
                          description: "你私下相信改革是正確的道路，但作為資深議員，你需要維持中立的形象。",
                          successCondition: "在私下協助改革派取得至少兩張額外的支持票", points: 65)
        ],
        stance: "中立，傾向折衷方案",
        allies: ["reformer", "factory_owner"],
        enemies: []
    )

    // MARK: - George III

    static let georgeIII = RoleDetailData(
        type: "george_iii",
        nameZh: "喬治三世",
        nameEn: "KING GEORGE III",
        characterName: "喬治·威廉·腓特烈",
        age: 74,
        occupation: "大不列顛及愛爾蘭聯合王國國王",
        background: """
        喬治三世是大英帝國的君主，在位已超過五十年。
        他曾是一位精力充沛的國王，但近年來精神疾病的發作讓他時而清醒時而糊塗。
        """,
        description: "你是英國國王喬治三世，雖然精神狀態不穩定，但你的意見仍然舉足輕重。",
        quote: "我可能會失去美洲，但我不會失去英格蘭的心。",
        color: georgeIIIColor,
        abilities: [
            RoleAbility(name: "王者威嚴", description: "你的發言自動獲得所有人的關注", icon: "Ⅰ"),
            RoleAbility(name: "皇室否決", description: "你可以要求重新考慮任何決議（限用一次）", icon: "Ⅱ"),
            RoleAbility(name: "精神波動", description: "你的精神狀態會影響辯論的走向", icon: "Ⅲ")
        ],
        secretMissions: [
            SecretMission(id: "george_01", roleType: "george_iii", title: "清醒的時刻",
                          description: "在這場辯論中，你經歷著一個罕見的清醒期。這可能是你最後一次對國家大事發表意見的機會。",
                          successCondition: "在辯論中發表一個改變至少兩名玩家立場的演說", points: 60),
            SecretMission(id: "george_02", roleType: "george_iii", title: "父親的責任",
                          description: "你的一個私生子（你從未公開承認的）正在工廠裡勞動。你收到了他的信，描述了工人的悲慘處境。",
                          successCondition: "推動一項保護工人的政策，同時不透露你的私人動機", points: 55),
            SecretMission(id: "george_03", roleType: "george_iii", title: "王室的秘密",
                          description: "你其實秘密投資了幾家使用新機器的工廠。如果這件事曝光，將會嚴重損害王室的形象。",
                          successCondition: "保守你的投資秘密，並確保你的投票不被質疑", points: 70),
            SecretMission(id: "george_04", roleType: "george_iii", title: "最後的遺產",
                          description: "你感覺到自己的清醒時刻越來越少。你想為臣民留下一份禮物——一個能夠讓英國走向繁榮與和諧的決定。",
                          successCondition: "投票支持得到最多不同陣營支持的方案", points: 50)
        ],
        stance: "不可預測（受精神狀態影響）",
        allies: [],
        enemies: []
    )

    // MARK: - Lookup Functions

    static func getRole(byType type: String) -> RoleDetailData? {
        switch type.lowercased() {
        case "worker": return worker
        case "factory_owner", "factory": return factoryOwner
        case "luddite": return luddite
        case "reformer": return reformer
        case "mp": return mp
        case "george_iii", "georgeiii", "king": return georgeIII
        default: return nil
        }
    }

    static func getSecretMission(roleType: String, missionIndex: Int) -> SecretMission? {
        guard let role = getRole(byType: roleType) else { return nil }
        guard missionIndex >= 0 && missionIndex < role.secretMissions.count else { return nil }
        return role.secretMissions[missionIndex]
    }
}
