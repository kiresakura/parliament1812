import SwiftUI

public struct HomeView: View {
    @State private var nickname = ""
    @State private var roomCode = ""
    @State private var selectedTab = 0  // 0 = Create, 1 = Join
    @State private var isCreatingRoom = false
    @State private var isJoiningRoom = false
    @State private var errorMessage: String?
    @State private var navigateToWaitingRoom = false
    @State private var currentPlayer: Player?
    @State private var currentRoomCode: String?
    @State private var isHost = false

    public init() {}

    public var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Background
                    figmaBackgroundView

                    // Content
                    VStack(spacing: 0) {
                        // Figma-style Header
                        figmaHeader
                            .padding(.top, geometry.safeAreaInsets.top)

                        Spacer()

                        // Main content (no frame, transparent design)
                        VStack(spacing: ParliamentSpacing.lg) {
                            // Title section with crown
                            figmaTitleSection

                            // Side-by-side Create/Join buttons
                            modeSelectionButtons

                            // Form section
                            figmaFormSection

                            // Error message
                            if let error = errorMessage {
                                Text(error)
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.horizontal, ParliamentSpacing.lg)

                        Spacer()

                        // Quote footer (Figma style)
                        figmaQuoteFooter
                            .padding(.bottom, ParliamentSpacing.xl)
                            .padding(.horizontal, ParliamentSpacing.lg)
                    }
                }
                .ignoresSafeArea()
            }
            .navigationDestination(isPresented: $navigateToWaitingRoom) {
                if let player = currentPlayer, let code = currentRoomCode {
                    WaitingRoomView(
                        roomCode: code,
                        currentPlayer: player,
                        isHost: isHost
                    )
                }
            }
        }
    }

    // MARK: - Figma Background View
    private var figmaBackgroundView: some View {
        ZStack {
            // Base dark background (#1A1614)
            Color.parliamentBackground
                .ignoresSafeArea()

            // Parliament chamber image at 15% opacity (desaturated)
            Image("ParliamentBackground")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
                .saturation(0)
                .opacity(0.15)

            // Subtle gold particle effect overlay
            GoldParticleOverlay()
        }
    }

    // MARK: - Figma Header
    private var figmaHeader: some View {
        HStack {
            HStack(spacing: ParliamentSpacing.sm) {
                // Crown icon in circle
                ZStack {
                    Circle()
                        .fill(Color.parliamentGold.opacity(0.2))
                        .overlay(
                            Circle()
                                .stroke(Color.parliamentGold, lineWidth: 2)
                        )
                        .frame(width: 32, height: 32)

                    Image(systemName: "crown.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.parliamentGold)
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text("REGENCY ERA")
                        .font(.custom("Georgia", size: 14))
                        .foregroundColor(.parliamentGold)
                        .tracking(0.7)

                    Text("1812 • British Parliament")
                        .font(.custom("Georgia", size: 12))
                        .foregroundColor(.parliamentShadow)
                }
            }
            Spacer()
        }
        .padding(.horizontal, ParliamentSpacing.lg)
        .padding(.vertical, 12)
        .background(
            Color.parliamentOil.opacity(0.95)
                .overlay(
                    Rectangle()
                        .fill(Color.parliamentGold.opacity(0.3))
                        .frame(height: 1),
                    alignment: .bottom
                )
                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
        )
    }

    // MARK: - Figma Title Section
    private var figmaTitleSection: some View {
        VStack(spacing: ParliamentSpacing.sm) {
            // Crown emblem
            FigmaCrownEmblem(size: 80)

            // "1812" with flanking decorations
            HStack(spacing: ParliamentSpacing.md) {
                // Left decoration
                Image(systemName: "crown")
                    .font(.system(size: 16))
                    .foregroundColor(.parliamentShadow.opacity(0.3))

                Text("1812")
                    .font(.custom("Georgia", size: 72))
                    .foregroundColor(.parliamentGold)
                    .tracking(14.4)
                    .shadow(color: .black.opacity(0.9), radius: 8, y: 4)
                    .shadow(color: .parliamentGold.opacity(0.4), radius: 30)

                // Right decoration
                Image(systemName: "crown")
                    .font(.system(size: 16))
                    .foregroundColor(.parliamentShadow.opacity(0.3))
            }

            // Chinese subtitle - 使用明體增加歷史感
            Text("國會風雲")
                .font(.custom("Songti TC", size: 30))
                .foregroundColor(.parliamentMongoose)
                .tracking(9)
                .shadow(color: .black.opacity(0.9), radius: 4, y: 2)

            // English subtitle
            Text("PARLIAMENT DEBATES")
                .font(.custom("Georgia", size: 14))
                .foregroundColor(.parliamentShadow)
                .tracking(4.2)
                .textCase(.uppercase)
                .opacity(0.6)
                .shadow(color: .black.opacity(0.8), radius: 2, y: 1)

            // Victorian divider
            FigmaDivider()
                .padding(.top, ParliamentSpacing.xs)
        }
    }

    // MARK: - Mode Selection Buttons (Side-by-side, minimal)
    private var modeSelectionButtons: some View {
        HStack(spacing: ParliamentSpacing.sm) {
            // Create Room button (filled when selected)
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = 0
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                    Text("建立房間")
                        .font(.custom("Songti TC", size: 14).bold())
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
            }
            .buttonStyle(FigmaCompactButtonStyle(isSelected: selectedTab == 0))

            // Join Room button (outline when not selected)
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = 1
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 12))
                    Text("加入房間")
                        .font(.custom("Songti TC", size: 14).bold())
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
            }
            .buttonStyle(FigmaCompactButtonStyle(isSelected: selectedTab == 1))
        }
    }

    // MARK: - Figma Form Section
    @ViewBuilder
    private var figmaFormSection: some View {
        VStack(spacing: ParliamentSpacing.md) {
            // Nickname field (always shown)
            FigmaInputField(
                label: "您的暱稱",
                englishLabel: "Your Nickname",
                placeholder: "輸入暱稱...",
                text: $nickname
            )

            if selectedTab == 1 {
                // Room code field (only for Join mode)
                FigmaInputField(
                    label: "房間代碼",
                    englishLabel: "Room Code",
                    placeholder: "XXXXXX",
                    text: $roomCode
                )
                .onChange(of: roomCode) { _, newValue in
                    roomCode = String(newValue.uppercased().prefix(6))
                }
            }

            // Action button
            figmaActionButton
        }
    }

    // MARK: - Figma Action Button
    private var figmaActionButton: some View {
        Button {
            Task {
                if selectedTab == 0 {
                    await createRoom()
                } else {
                    await joinRoom()
                }
            }
        } label: {
            HStack(spacing: ParliamentSpacing.sm) {
                if isCreatingRoom || isJoiningRoom {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .parliamentMirage))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: selectedTab == 0 ? "crown.fill" : "building.columns.fill")
                        .font(.system(size: 16))
                }
                Text(selectedTab == 0 ? "建立新會議" : "進入議事廳")
                    .font(.custom("Songti TC", size: 17.6))
                    .tracking(2.64)
            }
            .foregroundColor(.parliamentMirage)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
        }
        .background(
            LinearGradient(
                colors: [Color.parliamentGold, Color(red: 184/255, green: 148/255, blue: 31/255)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(FigmaButtonShape())
        .overlay(
            FigmaButtonShape()
                .stroke(Color.white.opacity(0.3), lineWidth: 2)
        )
        .shadow(color: .parliamentGold.opacity(0.4), radius: 10, y: 6)
        .disabled((selectedTab == 0 && nickname.isEmpty) || (selectedTab == 1 && (nickname.isEmpty || roomCode.count != 6)) || isCreatingRoom || isJoiningRoom)
        .opacity(isButtonEnabled ? 1.0 : 0.5)
    }

    private var isButtonEnabled: Bool {
        if selectedTab == 0 {
            return !nickname.isEmpty && !isCreatingRoom
        } else {
            return !nickname.isEmpty && roomCode.count == 6 && !isJoiningRoom
        }
    }

    // MARK: - Figma Quote Footer
    private var figmaQuoteFooter: some View {
        VStack(spacing: 4) {
            // Quote icon
            HStack {
                Image(systemName: "quote.opening")
                    .font(.system(size: 12))
                    .foregroundColor(.parliamentShadow.opacity(0.4))
                Spacer()
            }

            // Chinese quote - 使用明體
            Text("「在攝政王的注視下，國會的權力鬥爭即將展開」")
                .font(.custom("Songti TC", size: 14))
                .foregroundColor(.parliamentMongoose)
                .multilineTextAlignment(.center)

            // English quote
            Text("Under the Prince Regent's gaze...")
                .font(.custom("Georgia", size: 12))
                .foregroundColor(.parliamentShadow)
                .opacity(0.7)
        }
        .padding(13)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.parliamentOil.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.parliamentShadow.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Actions
    private func createRoom() async {
        isCreatingRoom = true
        errorMessage = nil

        do {
            let response = try await APIService.shared.createRoom(hostNickname: nickname)
            currentPlayer = Player(
                id: response.playerId,
                nickname: nickname,
                isHost: true,
                roleType: nil,
                roleIndex: nil
            )
            currentRoomCode = response.code
            isHost = true
            navigateToWaitingRoom = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isCreatingRoom = false
    }

    private func joinRoom() async {
        isJoiningRoom = true
        errorMessage = nil

        do {
            let response = try await APIService.shared.joinRoom(code: roomCode, nickname: nickname)
            currentPlayer = Player(
                id: response.playerId,
                nickname: nickname,
                isHost: false,
                roleType: nil,
                roleIndex: nil
            )
            currentRoomCode = response.roomCode
            isHost = false
            navigateToWaitingRoom = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isJoiningRoom = false
    }
}

#Preview {
    HomeView()
}
