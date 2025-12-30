import SwiftUI

/// 私訊畫面 - 對話列表與聊天
struct MessagesView: View {
    let roomCode: String
    let currentPlayer: Player
    let players: [Player]

    @StateObject private var viewModel = MessageViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                backgroundView

                // Content
                Group {
                    if viewModel.uiState.isLoading && viewModel.uiState.conversations.isEmpty {
                        loadingView
                    } else if viewModel.uiState.conversations.isEmpty && otherPlayers.isEmpty {
                        emptyStateView
                    } else {
                        conversationListView
                    }
                }
            }
            .navigationTitle("私訊")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.parliamentTextPrimary)
                    }
                }

                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("私訊")
                            .font(.system(size: 17, weight: .semibold, design: .serif))
                            .foregroundColor(.parliamentTextPrimary)
                        Text("MESSAGES")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.parliamentTextMuted)
                            .tracking(2)
                    }
                }
            }
            .toolbarBackground(Color.parliamentCardBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .task {
            await viewModel.loadConversations(roomCode: roomCode, playerId: currentPlayer.id)
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
        }
        .alert("錯誤", isPresented: .init(
            get: { viewModel.uiState.error != nil },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button("確定") { viewModel.clearError() }
        } message: {
            Text(viewModel.uiState.error ?? "")
        }
    }

    // MARK: - Other Players (excluding self)
    private var otherPlayers: [Player] {
        players.filter { $0.id != currentPlayer.id }
    }

    // MARK: - Background
    private var backgroundView: some View {
        ZStack {
            Color.parliamentBackground.ignoresSafeArea()

            // Subtle gradient
            LinearGradient(
                colors: [
                    Color.parliamentBurgundy.opacity(0.1),
                    Color.parliamentBackground,
                    Color.parliamentWood.opacity(0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Hexagonal pattern
            HexagonalBackground()
                .opacity(0.05)
                .ignoresSafeArea()
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: ParliamentSpacing.md) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.parliamentGold)

            Text("載入中...")
                .font(.system(size: 14, design: .serif))
                .foregroundColor(.parliamentTextSecondary)
        }
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: ParliamentSpacing.lg) {
            Image(systemName: "envelope.badge")
                .font(.system(size: 60))
                .foregroundColor(.parliamentGold.opacity(0.5))

            Text("尚無私訊")
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundColor(.parliamentTextPrimary)

            Text("選擇一位玩家開始對話")
                .font(.system(size: 14))
                .foregroundColor(.parliamentTextSecondary)
        }
        .padding(ParliamentSpacing.xl)
    }

    // MARK: - Conversation List View
    private var conversationListView: some View {
        ScrollView {
            LazyVStack(spacing: ParliamentSpacing.sm) {
                // Show all other players as potential conversations
                ForEach(otherPlayers) { player in
                    NavigationLink {
                        ChatView(
                            roomCode: roomCode,
                            currentPlayer: currentPlayer,
                            otherPlayer: player,
                            viewModel: viewModel
                        )
                    } label: {
                        ConversationRow(
                            player: player,
                            conversation: viewModel.uiState.conversations.first { $0.playerId == player.id }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, ParliamentSpacing.md)
            .padding(.vertical, ParliamentSpacing.md)
        }
    }
}

// MARK: - Conversation Row

private struct ConversationRow: View {
    let player: Player
    let conversation: Conversation?

    var body: some View {
        HStack(spacing: ParliamentSpacing.md) {
            // Player Avatar
            playerAvatar

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(player.nickname)
                        .font(.system(size: 16, weight: .semibold, design: .serif))
                        .foregroundColor(.parliamentTextPrimary)

                    Spacer()

                    // Time
                    if let lastMessageAt = conversation?.lastMessageAt {
                        Text(formatTime(lastMessageAt))
                            .font(.system(size: 11))
                            .foregroundColor(.parliamentTextMuted)
                    }
                }

                HStack {
                    // Last message preview
                    Text(conversation?.lastMessage ?? "開始對話...")
                        .font(.system(size: 13))
                        .foregroundColor(.parliamentTextSecondary)
                        .lineLimit(1)

                    Spacer()

                    // Unread badge
                    if let unreadCount = conversation?.unreadCount, unreadCount > 0 {
                        Text("\(unreadCount)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 20, minHeight: 20)
                            .background(Circle().fill(Color.parliamentBurgundy))
                    }
                }
            }
        }
        .padding(ParliamentSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ParliamentRadius.medium)
                .fill(Color.parliamentCardBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ParliamentRadius.medium)
                .stroke(Color.parliamentWood.opacity(0.2), lineWidth: 1)
        )
    }

    private var playerAvatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.parliamentBurgundy, Color.parliamentBurgundy.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 50, height: 50)

            Text(String(player.nickname.prefix(1)).uppercased())
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundColor(.parliamentParchment)
        }
    }

    private func formatTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: dateString) else {
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: dateString) else {
                return ""
            }
            return formatRelativeTime(date)
        }
        return formatRelativeTime(date)
    }

    private func formatRelativeTime(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)

        if interval < 60 {
            return "剛剛"
        } else if interval < 3600 {
            return "\(Int(interval / 60))分鐘前"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))小時前"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Chat View

private struct ChatView: View {
    let roomCode: String
    let currentPlayer: Player
    let otherPlayer: Player
    @ObservedObject var viewModel: MessageViewModel

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isInputFocused: Bool
    @State private var scrollProxy: ScrollViewProxy?

    var body: some View {
        ZStack {
            // Background
            Color.parliamentBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Messages
                messagesScrollView

                // Divider
                Divider()
                    .background(Color.parliamentWood.opacity(0.3))

                // Input bar
                inputBar
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("返回")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.parliamentGold)
                }
            }

            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(otherPlayer.nickname)
                        .font(.system(size: 17, weight: .semibold, design: .serif))
                        .foregroundColor(.parliamentTextPrimary)

                    if let roleType = otherPlayer.roleType {
                        Text(roleType.displayName)
                            .font(.system(size: 10))
                            .foregroundColor(.parliamentTextMuted)
                    }
                }
            }
        }
        .toolbarBackground(Color.parliamentCardBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task {
            await viewModel.loadMessages(
                roomCode: roomCode,
                playerId: currentPlayer.id,
                otherPlayerId: otherPlayer.id
            )
        }
    }

    // MARK: - Messages ScrollView
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: ParliamentSpacing.sm) {
                    if viewModel.uiState.isLoading && viewModel.uiState.messages.isEmpty {
                        ProgressView()
                            .padding(.top, ParliamentSpacing.xl)
                    } else if viewModel.uiState.messages.isEmpty {
                        emptyMessagesView
                    } else {
                        ForEach(viewModel.uiState.messages) { message in
                            MessageBubble(
                                message: message,
                                isFromCurrentUser: message.senderId == currentPlayer.id
                            )
                            .id(message.id)
                        }
                    }
                }
                .padding(.horizontal, ParliamentSpacing.md)
                .padding(.vertical, ParliamentSpacing.md)
            }
            .onAppear {
                scrollProxy = proxy
                scrollToBottom()
            }
            .onChange(of: viewModel.uiState.messages.count) { _, _ in
                scrollToBottom()
            }
        }
    }

    private var emptyMessagesView: some View {
        VStack(spacing: ParliamentSpacing.md) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 40))
                .foregroundColor(.parliamentGold.opacity(0.4))

            Text("開始對話")
                .font(.system(size: 16, design: .serif))
                .foregroundColor(.parliamentTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }

    // MARK: - Input Bar
    private var inputBar: some View {
        HStack(spacing: ParliamentSpacing.sm) {
            // Text input
            TextField("輸入訊息...", text: .init(
                get: { viewModel.uiState.messageInput },
                set: { viewModel.updateMessageInput($0) }
            ))
            .font(.system(size: 15))
            .padding(.horizontal, ParliamentSpacing.md)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.parliamentCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.parliamentWood.opacity(0.3), lineWidth: 1)
                    )
            )
            .focused($isInputFocused)

            // Send button
            Button {
                Task {
                    await sendMessage()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(canSend ? Color.parliamentBurgundy : Color.parliamentWood.opacity(0.3))
                        .frame(width: 40, height: 40)

                    if viewModel.uiState.isSending {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .disabled(!canSend || viewModel.uiState.isSending)
        }
        .padding(.horizontal, ParliamentSpacing.md)
        .padding(.vertical, ParliamentSpacing.sm)
        .background(Color.parliamentBackground)
    }

    private var canSend: Bool {
        !viewModel.uiState.messageInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func sendMessage() async {
        await viewModel.sendMessage(
            roomCode: roomCode,
            senderId: currentPlayer.id,
            receiverId: otherPlayer.id
        )
        scrollToBottom()
    }

    private func scrollToBottom() {
        if let lastMessage = viewModel.uiState.messages.last {
            withAnimation(.easeOut(duration: 0.2)) {
                scrollProxy?.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: MessageResponse
    let isFromCurrentUser: Bool

    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer(minLength: 60)
            }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                // Message content
                Text(message.content)
                    .font(.system(size: 15))
                    .foregroundColor(isFromCurrentUser ? .white : .parliamentTextPrimary)
                    .padding(.horizontal, ParliamentSpacing.md)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(isFromCurrentUser ? Color.parliamentBurgundy : Color.parliamentCardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                isFromCurrentUser ? Color.clear : Color.parliamentWood.opacity(0.2),
                                lineWidth: 1
                            )
                    )

                // Time
                Text(formatMessageTime(message.sentAt))
                    .font(.system(size: 10))
                    .foregroundColor(.parliamentTextMuted)
                    .padding(.horizontal, 4)
            }

            if !isFromCurrentUser {
                Spacer(minLength: 60)
            }
        }
    }

    private func formatMessageTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: dateString) else {
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: dateString) else {
                return ""
            }
            return formatTime(date)
        }
        return formatTime(date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview("Messages View") {
    MessagesView(
        roomCode: "ABC123",
        currentPlayer: Player(id: "player1", nickname: "湯瑪斯", isHost: false),
        players: [
            Player(id: "player1", nickname: "湯瑪斯", isHost: false),
            Player(id: "player2", nickname: "理查德", isHost: true),
            Player(id: "player3", nickname: "喬治", isHost: false)
        ]
    )
}

#Preview("Chat View") {
    NavigationStack {
        ChatView(
            roomCode: "ABC123",
            currentPlayer: Player(id: "player1", nickname: "湯瑪斯", isHost: false),
            otherPlayer: Player(id: "player2", nickname: "理查德", isHost: true, roleType: .factory),
            viewModel: MessageViewModel()
        )
    }
}
