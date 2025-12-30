import Foundation

struct NFCCardData: Codable, Sendable, Equatable {
    let cardId: String      // e.g., "george_iii_01"
    let signature: String   // 防偽簽名
    let uid: String         // 卡片 UID（防複製）
}

struct NFCScanRequest: Codable, Sendable {
    let roomCode: String
    let playerId: String
    let cardId: String
    let signature: String
    let uid: String

    /// 從 NFCCardData 建立請求
    init(roomCode: String, playerId: String, cardData: NFCCardData) {
        self.roomCode = roomCode
        self.playerId = playerId
        self.cardId = cardData.cardId
        self.signature = cardData.signature
        self.uid = cardData.uid
    }
}

struct NFCScanResponse: Codable, Sendable {
    let message: String?
    let playerId: String?
    let roleType: String?
    let roleIndex: Int?
    let roleName: String?
    let roleOccupation: String?
    let roleDescription: String?
    let roleBackground: String?
    let rolePublicStance: String?
    let avatarColor: String?

    /// Check if the scan was successful (has role type assigned)
    var success: Bool {
        roleType != nil
    }
}
