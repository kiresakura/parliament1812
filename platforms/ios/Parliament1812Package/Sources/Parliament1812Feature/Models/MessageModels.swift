import Foundation

// MARK: - Message Response
struct MessageResponse: Codable, Identifiable, Sendable, Equatable {
    let id: String
    let senderId: String
    let senderNickname: String
    let receiverId: String
    let receiverNickname: String
    let content: String
    let isRead: Bool
    let sentAt: String
}

// MARK: - Message List Response
struct MessageListResponse: Codable, Sendable {
    let messages: [MessageResponse]
    let total: Int
    let unreadCount: Int
}

// MARK: - Conversation
struct Conversation: Codable, Identifiable, Sendable, Equatable {
    var id: String { playerId }
    let playerId: String
    let nickname: String
    let lastMessage: String
    let lastMessageAt: String
    let unreadCount: Int
}

// MARK: - Conversations Response
struct ConversationsResponse: Codable, Sendable {
    let conversations: [Conversation]
    let totalUnread: Int
}

// MARK: - Mark Read Response
struct MarkReadResponse: Codable, Sendable {
    let markedCount: Int
    let message: String
}

// MARK: - Unread Count Response
struct UnreadCountResponse: Codable, Sendable {
    let unreadCount: Int
}
