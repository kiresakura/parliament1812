import Foundation
import SwiftUI

struct Role: Codable, Identifiable, Sendable {
    let id: String
    let nameZh: String
    let nameEn: String
    let faction: String
    let description: String?
}

// 角色類型對應
enum RoleType: String, Codable, CaseIterable, Sendable {
    case worker = "worker"
    case factory = "factory"
    case luddite = "luddite"
    case reformer = "reformer"
    case mp = "mp"
    case georgeiii = "george_iii"

    var displayName: String {
        switch self {
        case .worker: return "工人"
        case .factory: return "工廠主"
        case .luddite: return "盧德派"
        case .reformer: return "改革者"
        case .mp: return "議員"
        case .georgeiii: return "喬治三世"
        }
    }

    var emoji: String {
        switch self {
        case .worker: return "👷"
        case .factory: return "🏭"
        case .luddite: return "🔨"
        case .reformer: return "⚖️"
        case .mp: return "🎩"
        case .georgeiii: return "👑"
        }
    }

    var color: Color {
        switch self {
        case .worker: return Color(red: 0.5, green: 0.35, blue: 0.25)  // Brown
        case .factory: return Color(red: 0.3, green: 0.3, blue: 0.35)  // Gray
        case .luddite: return Color(red: 0.55, green: 0.25, blue: 0.2)  // Red-brown
        case .reformer: return Color.parliamentGreen
        case .mp: return Color.parliamentBurgundy
        case .georgeiii: return Color(red: 0.55, green: 0.42, blue: 0.25)  // Royal gold
        }
    }

    var characterName: String {
        switch self {
        case .worker: return "紡織工人 湯瑪斯"
        case .factory: return "工廠主 理查·威爾森"
        case .luddite: return "盧德派 喬治"
        case .reformer: return "改革者 羅伯特·歐文"
        case .mp: return "議員 威廉·菲茨傑拉德"
        case .georgeiii: return "國王 喬治三世"
        }
    }

    var description: String {
        switch self {
        case .worker:
            return "一位在紡織廠工作的普通工人，面對機器帶來的失業威脅，努力為自己和家人尋找出路。"
        case .factory:
            return "擁有多家紡織廠的成功商人，相信機器是進步的象徵，但也擔心暴民的破壞活動。"
        case .luddite:
            return "盧德運動的積極參與者，堅信機器是壓迫工人的工具，必須被摧毀。"
        case .reformer:
            return "理想主義的社會改革家，希望在工業發展與工人權益之間找到平衡。"
        case .mp:
            return "代表地方利益的國會議員，需要在各方勢力間周旋，做出對自己最有利的選擇。"
        case .georgeiii:
            return "大不列顛國王，儘管身受疾病困擾，仍在幕後影響著國會的走向。"
        }
    }

    /// 角色頭像圖片名稱（對應 Assets.xcassets/Characters/ 中的 imageset）
    var imageName: String {
        switch self {
        case .worker: return "character_worker"
        case .factory: return "character_factory"
        case .luddite: return "character_luddite"
        case .reformer: return "character_reformer"
        case .mp: return "character_mp"
        case .georgeiii: return "character_george_iii"
        }
    }

    /// 後端角色代碼（用於 API 請求，格式如 W01, F01, L01 等）
    var backendRoleCode: String {
        switch self {
        case .worker: return "W01"
        case .factory: return "F01"
        case .luddite: return "L01"
        case .reformer: return "R01"
        case .mp: return "M01"
        case .georgeiii: return "G01"
        }
    }
}
