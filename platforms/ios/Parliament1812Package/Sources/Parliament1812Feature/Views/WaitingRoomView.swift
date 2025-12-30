import SwiftUI

struct WaitingRoomView: View {
    let roomCode: String
    let currentPlayer: Player
    let isHost: Bool

    @State private var players: [Player] = []
    @State private var webSocketService = WebSocketService()
    @State private var showNFCScan = false
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var myRole: (type: String, index: Int)?
    @State private var isReady = false
    @State private var isSettingReady = false
    @State private var isStartingGame = false
    @State private var showCopiedToast = false
    @State private var navigateToGame = false
    @State private var refreshTimer: Timer?
    @State private var isLeavingRoom = false
    @Environment(\.dismiss) private var dismiss

    // Computed property for all players ready check
    private var allPlayersReady: Bool {
        guard !players.isEmpty else { return false }
        return players.allSatisfy { $0.hasRole && $0.isReady }
    }

    // Computed property for ready count
    private var readyCount: Int {
        players.filter { $0.isReady }.count
    }

    var body: some View {
        FogOfWarOverlay {
            ZStack {
                // Background
                backgroundView.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Royal Pass Header (皇家通行證)
                    royalPassHeader
                        .padding(.top, ParliamentSpacing.md)
                        .padding(.horizontal, ParliamentSpacing.md)
                    
                    // Stats Section (在席成員 / 準備就緒)
                    statsSection
                        .padding(.top, ParliamentSpacing.md)
                        .padding(.horizontal, ParliamentSpacing.md)
                    
                    // Players list (國會議員名單)
                    playersSection
                        .padding(.top, ParliamentSpacing.md)
                        .padding(.horizontal, ParliamentSpacing.md)
                        .frame(maxHeight: .infinity)
                    
                    // Bottom action (compact)
                    bottomActionSection
                        .padding(.horizontal, ParliamentSpacing.md)
                        .padding(.bottom, ParliamentSpacing.md)
                    
                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                            .padding(.horizontal, ParliamentSpacing.md)
                            .padding(.bottom, ParliamentSpacing.xs)
                    }
                }
                
                // Copied toast
                if showCopiedToast {
                    VStack {
                        Spacer()
                        Text("已複製通行碼")
                            .font(.custom("Songti TC", size: 14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.8))
                            )
                            .padding(.bottom, 100)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    Task {
                        await leaveRoom()
                    }
                } label: {
                    HStack(spacing: 4) {
                        if isLeavingRoom {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .parliamentGold))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        Text("退出")
                            .font(.custom("Songti TC", size: 15))
                    }
                    .foregroundColor(.parliamentGold)
                }
                .disabled(isLeavingRoom)
            }
        }
        .toolbarBackground(Color.parliamentBackground.opacity(0.95), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showNFCScan) {
            NFCScanView(
                roomCode: roomCode,
                playerId: currentPlayer.id
            ) { roleType, roleIndex in
                myRole = (roleType, roleIndex)
                showNFCScan = false
                // 同時更新 players 陣列中當前玩家的角色
                if let index = players.firstIndex(where: { $0.id == currentPlayer.id }) {
                    players[index].roleType = RoleType(rawValue: roleType)
                    players[index].roleIndex = roleIndex
                }
            }
        }
        .navigationDestination(isPresented: $navigateToGame) {
            GameFlowView(
                roomCode: roomCode,
                currentPlayer: Player(
                    id: currentPlayer.id,
                    nickname: currentPlayer.nickname,
                    isHost: currentPlayer.isHost,
                    roleType: myRole.flatMap { RoleType(rawValue: $0.type) },
                    roleIndex: myRole?.index
                ),
                isHost: isHost
            )
        }
        .task {
            await loadPlayers()
            setupWebSocket()
            // 立即檢查房間狀態，確保不會錯過遊戲已開始的情況
            await checkRoomPhase()
            startPeriodicRefresh()
        }
        .onDisappear {
            webSocketService.disconnect()
            refreshTimer?.invalidate()
            refreshTimer = nil
        }
    }

    // MARK: - Background (Civ6 Style)
    private var backgroundView: some View {
        ZStack {
            // Base color
            Color.parliamentBackground

            // Subtle parchment texture gradient
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.1, blue: 0.08),
                    Color.parliamentBackground,
                    Color(red: 0.08, green: 0.06, blue: 0.04),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Hexagonal grid pattern overlay (Civ6 signature)
            GeometryReader { geo in
                Canvas { context, size in
                    let hexSize: CGFloat = 40
                    let rows = Int(size.height / (hexSize * 0.75)) + 2
                    let cols = Int(size.width / (hexSize * 0.866)) + 2

                    for row in 0..<rows {
                        for col in 0..<cols {
                            let xOffset = col % 2 == 0 ? 0 : hexSize * 0.433
                            let x = CGFloat(col) * hexSize * 0.866
                            let y = CGFloat(row) * hexSize * 0.75 + xOffset

                            let path = hexagonPath(
                                center: CGPoint(x: x, y: y), size: hexSize * 0.45)
                            context.stroke(
                                path, with: .color(Color.parliamentGold.opacity(0.03)),
                                lineWidth: 0.5)
                        }
                    }
                }
            }

            // Corner vignette
            RadialGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.4),
                ],
                center: .center,
                startRadius: 100,
                endRadius: 500
            )

            // Top decorative line
            VStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.parliamentGold.opacity(0.3),
                                Color.parliamentGold.opacity(0.5),
                                Color.parliamentGold.opacity(0.3),
                                Color.clear,
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .padding(.top, 56)
                Spacer()
            }
        }
    }

    // Helper function for hexagon path
    private func hexagonPath(center: CGPoint, size: CGFloat) -> Path {
        var path = Path()
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3 - .pi / 6
            let point = CGPoint(
                x: center.x + size * cos(angle),
                y: center.y + size * sin(angle)
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }

    // MARK: - Royal Pass Header (皇家通行證 - Victorian Style)
    private var royalPassHeader: some View {
        VStack(spacing: ParliamentSpacing.md) {
            // Header with Wax Seal aesthetic look
            HStack {
                // Left decorative element
                Image(systemName: "ornament.fill")
                    .foregroundColor(.parliamentGold.opacity(0.6))
                    .font(.caption)

                Text("ROYAL DECREE")
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .foregroundColor(.parliamentTextMuted)
                    .tracking(4)

                Image(systemName: "ornament.fill")
                    .foregroundColor(.parliamentGold.opacity(0.6))
                    .font(.caption)
            }

            // Room Code as Centerpiece
            VStack(spacing: 8) {
                Text(roomCode)
                    .font(.custom("Georgia", size: 48).weight(.bold))  // Serif font for document feel
                    .foregroundColor(.parliamentGoldDark)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)

                // Copy Button (Styled as a stamp/action)
                Button {
                    UIPasteboard.general.string = roomCode
                    withAnimation(.easeInOut(duration: 0.3)) { showCopiedToast = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { showCopiedToast = false }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc.fill")
                        Text("複製通行碼")
                    }
                    .font(.custom("Songti TC", size: 12).weight(.medium))
                    .foregroundColor(.parliamentTextSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .stroke(Color.parliamentTextSecondary.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, ParliamentSpacing.lg)
            .background(
                ZStack {
                    // Inner faint border
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.parliamentGold.opacity(0.15), lineWidth: 1)
                        .padding(4)

                    // Corner decorations
                    VictorianCorner(
                        position: .topLeading, size: 16, color: .parliamentGold.opacity(0.4)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(4)
                    VictorianCorner(
                        position: .bottomTrailing, size: 16, color: .parliamentGold.opacity(0.4)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(4)
                }
            )
        }
        .padding(ParliamentSpacing.md)
        .paperSurface(withBorder: true)  // Use new modifier
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }

    // MARK: - Stats Section (在席成員 / 準備就緒)
    private var statsSection: some View {
        HStack(spacing: ParliamentSpacing.md) {
            // 在席成員 (Members Present)
            statCard(
                icon: "person.2.fill",
                label: "在席成員",
                value: "\(players.count)",
                total: "\(AppConfig.maxPlayersPerRoom)",
                color: .parliamentGold
            )

            // 準備就緒 (Ready)
            statCard(
                icon: "checkmark.circle.fill",
                label: "準備就緒",
                value: "\(readyCount)",
                total: "\(players.count)",
                color: readyCount == players.count && players.count > 0
                    ? .green : .parliamentMongoose
            )
        }
    }

    private func statCard(icon: String, label: String, value: String, total: String, color: Color)
        -> some View
    {
        HStack(spacing: ParliamentSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.custom("Songti TC", size: 12))
                    .foregroundColor(.parliamentTextMuted)

                HStack(spacing: 2) {
                    Text(value)
                        .font(.custom("Songti TC", size: 22).weight(.bold))
                        .foregroundColor(color)
                    Text("/\(total)")
                        .font(.custom("Songti TC", size: 16))
                        .foregroundColor(.parliamentTextMuted)
                }
            }

            Spacer()
        }
        .padding(ParliamentSpacing.md)
        .modifier(PaperSurface())
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }

    // MARK: - Players Section (Victorian Scroll)
    private var playersSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VictorianSectionHeader("國會議員名單", subtitle: "MEMBERS OF PARLIAMENT")
                .padding(.horizontal, ParliamentSpacing.md)
                .padding(.vertical, ParliamentSpacing.sm)
                .background(Color.parliamentOil.opacity(0.4))

            VictorianDivider()
                .padding(.horizontal, ParliamentSpacing.md)

            // Player grid
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: ParliamentSpacing.sm),
                        GridItem(.flexible(), spacing: ParliamentSpacing.sm),
                    ],
                    spacing: ParliamentSpacing.md
                ) {
                    ForEach(players) { player in
                        VictorianOvalPlayerCard(
                            // Use currentPlayer.nickname for current user to ensure correct display
                            nickname: player.id == currentPlayer.id ? currentPlayer.nickname : player.nickname,
                            roleType: player.roleType?.imageName,
                            isHost: player.isHost,
                            isReady: player.isReady,
                            isCurrentUser: player.id == currentPlayer.id
                        )
                    }
                }
                .padding(ParliamentSpacing.md)
            }
            // Mask the bottom slightly for scroll effect
            .mask(
                LinearGradient(
                    colors: [.black, .black, .black, .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // Waiting section (顯示需要多少人)
            if players.count < AppConfig.minPlayersToStart {
                waitingMembersSection
            }
        }
    }

    // MARK: - Waiting Members Section (等待成員)
    private var waitingMembersSection: some View {
        VStack(spacing: 6) {
            VictorianDivider()
                .padding(.bottom, 4)

            HStack {
                Image(systemName: "hourglass")
                    .font(.system(size: 14))
                    .foregroundColor(.parliamentGold)

                Text("等待成員")
                    .font(.custom("Songti TC", size: 13))
                    .foregroundColor(.parliamentTextMuted)

                Spacer()

                Text("需\(AppConfig.minPlayersToStart)人即可開始")
                    .font(.custom("Songti TC", size: 12))
                    .foregroundColor(.parliamentTextMuted)
            }
            .padding(.horizontal, ParliamentSpacing.md)
            .padding(.vertical, ParliamentSpacing.sm)
        }
        .background(Color.black.opacity(0.2)) // Darker tint mainly
    }

    // MARK: - Bottom Action Section (固定底部按鈕樣式)
    @ViewBuilder
    private var bottomActionSection: some View {
        if myRole == nil {
            // 尚未分配角色 - 顯示 NFC 掃描按鈕
            nfcScanButton
        } else if !isReady {
            // 已分配角色但尚未準備 - 顯示準備按鈕
            readyConfirmSection
        } else if isHost && allPlayersReady {
            // 房主且所有人準備完成 - 顯示開始遊戲按鈕
            startGameSection
        } else {
            // 已準備 - 顯示等待狀態
            waitingForGameSection
        }
    }

    // 準備確認區塊 (已分配角色，等待確認)
    private var readyConfirmSection: some View {
        VStack(spacing: 0) {
            VictorianDivider()
                .padding(.bottom, ParliamentSpacing.sm)

            HStack(spacing: ParliamentSpacing.md) {
                // 角色頭像
                if let roleTypeString = myRole?.type,
                   let roleType = RoleType(rawValue: roleTypeString) {
                    Image(roleType.imageName, bundle: .main)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 60)
                        .clipShape(PointyHexagonShape())
                        .overlay(VictorianOvalFrame(size: CGSize(width: 50, height: 60)))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("角色已分配")
                        .font(.custom("Songti TC", size: 11))
                        .foregroundColor(.parliamentTextMuted)

                    if let roleTypeString = myRole?.type,
                       let roleType = RoleType(rawValue: roleTypeString) {
                        Text(roleType.characterName)
                            .font(.custom("Songti TC", size: 16).weight(.bold))
                            .foregroundColor(.parliamentGold)
                    }
                }

                Spacer()

                // 準備按鈕
                Button {
                    Task {
                        await setReadyStatus(ready: true)
                    }
                } label: {
                    HStack(spacing: 6) {
                        if isSettingReady {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text("準備就緒")
                            .font(.custom("Songti TC", size: 14).weight(.bold))
                    }
                }
                .buttonStyle(Civ6ButtonStyle(style: .primary))
                .disabled(isSettingReady)
                .frame(width: 120)
            }
            .padding(ParliamentSpacing.md)
        }
    }

    // NFC 掃描按鈕 (Victorian Style)
    private var nfcScanButton: some View {
        VStack(spacing: 0) {
            VictorianDivider()
                .padding(.bottom, ParliamentSpacing.sm)

            Button {
                showNFCScan = true
            } label: {
                HStack(spacing: ParliamentSpacing.md) {
                    Image(systemName: "wave.3.right.circle.fill")
                        .font(.system(size: 24))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("掃描角色卡")
                            .font(.custom("Songti TC", size: 16).weight(.bold))
                        Text("請將 NFC 卡片靠近手機背面")
                            .font(.custom("Songti TC", size: 11))
                            .opacity(0.8)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .padding(.horizontal, 4)
            }
            .buttonStyle(Civ6ButtonStyle(style: .primary))
        }

    }

    // 開始遊戲區塊（房主專用）
    private var startGameSection: some View {
        VStack(spacing: 0) {
            VictorianDivider()
                .padding(.bottom, ParliamentSpacing.sm)

            Button {
                Task {
                    await startGame()
                }
            } label: {
                HStack(spacing: ParliamentSpacing.md) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.parliamentGold)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("全員準備完成")
                            .font(.custom("Songti TC", size: 11))
                            .opacity(0.8)
                        Text("開始遊戲")
                            .font(.custom("Songti TC", size: 18).weight(.bold))
                            .foregroundColor(.parliamentGold)
                    }

                    Spacer()

                    if isStartingGame {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .parliamentGold))
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.parliamentGold)
                    }
                }
                .padding(.horizontal, 4)
            }
            .buttonStyle(Civ6ButtonStyle(style: .primary))
            .disabled(isStartingGame)
        }
    }

    // 等待遊戲開始區塊
    private var waitingForGameSection: some View {
        VStack(spacing: 0) {
            VictorianDivider()
                .padding(.bottom, ParliamentSpacing.sm)

            HStack(spacing: ParliamentSpacing.md) {
                // 角色頭像
                if let roleTypeString = myRole?.type,
                   let roleType = RoleType(rawValue: roleTypeString) {
                    Image(roleType.imageName, bundle: .main)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 60)
                        .clipShape(PointyHexagonShape())
                        .overlay(VictorianOvalFrame(size: CGSize(width: 50, height: 60)))
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                        Text("準備完成")
                            .font(.custom("Songti TC", size: 11).weight(.bold))
                            .foregroundColor(.green)
                    }

                    if let roleTypeString = myRole?.type,
                       let roleType = RoleType(rawValue: roleTypeString) {
                        Text(roleType.characterName)
                            .font(.custom("Songti TC", size: 14).weight(.semibold))
                            .foregroundColor(.parliamentGold)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // 取消準備按鈕 + 等待指示
                VStack(spacing: 6) {
                    // 取消準備按鈕
                    Button {
                        Task {
                            await setReadyStatus(ready: false)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            if isSettingReady {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .parliamentTextMuted))
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "xmark.circle")
                            }
                            Text("取消準備")
                                .font(.custom("Songti TC", size: 12))
                        }
                    }
                    .buttonStyle(Civ6ButtonStyle(style: .secondary))
                    .disabled(isSettingReady)
                    .frame(width: 110)

                    // 等待指示
                    if allPlayersReady {
                        Text("等待房主開始")
                            .font(.custom("Songti TC", size: 10))
                            .foregroundColor(.parliamentTextMuted)
                    } else {
                        let readyCount = players.filter { $0.isReady }.count
                        Text("\(readyCount)/\(players.count) 已準備")
                            .font(.custom("Songti TC", size: 10))
                            .foregroundColor(.parliamentTextMuted)
                    }
                }
            }
            .padding(ParliamentSpacing.md)
        }
    }

    // MARK: - Data Loading
    private func loadPlayers() async {
        isLoading = true
        do {
            players = try await APIService.shared.getPlayers(roomCode: roomCode)
            // Initialize myRole and isReady from current player's data
            if let currentPlayerData = players.first(where: { $0.id == currentPlayer.id }) {
                if let roleType = currentPlayerData.roleType,
                    let roleIndex = currentPlayerData.roleIndex
                {
                    myRole = (roleType.rawValue, roleIndex)
                    print(
                        "loadPlayers: Initialized myRole for current player - \(roleType.rawValue), index: \(roleIndex)"
                    )
                }
                isReady = currentPlayerData.isReady
                print("loadPlayers: Initialized isReady for current player - \(isReady)")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Leave Room
    private func leaveRoom() async {
        // 主持人不能離開房間，只能關閉房間
        if isHost {
            webSocketService.disconnect()
            dismiss()
            return
        }

        isLeavingRoom = true
        do {
            try await APIService.shared.leaveRoom(code: roomCode, playerId: currentPlayer.id)
        } catch {
            print("Failed to leave room: \(error.localizedDescription)")
            // 即使 API 呼叫失敗也繼續退出
        }
        webSocketService.disconnect()
        isLeavingRoom = false
        dismiss()
    }

    private func setupWebSocket() {
        webSocketService.connect(roomCode: roomCode, playerId: currentPlayer.id)

        webSocketService.onPlayerJoined = { player in
            Task { @MainActor in
                print("WebSocket: Player joined - \(player.nickname), id: \(player.id)")
                if let existingIndex = players.firstIndex(where: { $0.id == player.id }) {
                    // 玩家已存在，更新資料
                    players[existingIndex] = player
                    print("WebSocket: Updated existing player \(player.nickname)")
                } else {
                    // 新玩家，加入列表
                    players.append(player)
                    print("WebSocket: Added new player \(player.nickname)")
                }
            }
        }

        webSocketService.onPlayerLeft = { playerId in
            Task { @MainActor in
                print("WebSocket: Player left - \(playerId)")
                players.removeAll { $0.id == playerId }
            }
        }

        webSocketService.onRoleAssigned = { playerId, roleTypeString, roleIndex in
            Task { @MainActor in
                print(
                    "WebSocket: Role assigned - playerId: \(playerId), role: \(roleTypeString), index: \(roleIndex)"
                )
                if playerId == currentPlayer.id {
                    myRole = (roleTypeString, roleIndex)
                }
                if let index = players.firstIndex(where: { $0.id == playerId }) {
                    var updatedPlayer = players[index]
                    updatedPlayer.roleType = RoleType(rawValue: roleTypeString)
                    updatedPlayer.roleIndex = roleIndex
                    players[index] = updatedPlayer
                    print("WebSocket: Updated player role at index \(index)")
                } else {
                    // 玩家不在列表中，觸發刷新
                    print("WebSocket: Player \(playerId) not found in list, refreshing...")
                    await refreshPlayersQuietly()
                }
            }
        }

        webSocketService.onPlayerReady = { playerId, ready in
            Task { @MainActor in
                print("WebSocket: Player ready - \(playerId), ready: \(ready)")
                if let index = players.firstIndex(where: { $0.id == playerId }) {
                    var updatedPlayer = players[index]
                    updatedPlayer.isReady = ready
                    players[index] = updatedPlayer
                }
                // 更新自己的準備狀態
                if playerId == currentPlayer.id {
                    isReady = ready
                }
            }
        }

        webSocketService.onPhaseChanged = { phase in
            Task { @MainActor in
                // 遊戲開始時轉場到議事廳 (phase 2 = preparing)
                if phase == .preparing {
                    print("Game started! Navigating to game flow...")
                    navigateToGame = true
                }
            }
        }
    }

    /// 啟動定時刷新玩家列表（每1秒一次，確保同步）
    private func startPeriodicRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                await refreshPlayersQuietly()
            }
        }
    }

    /// 立即檢查房間狀態（確保不會錯過遊戲已開始的情況）
    private func checkRoomPhase() async {
        do {
            let room = try await APIService.shared.getRoom(code: roomCode)
            print("checkRoomPhase: Room phase is \(room.phase)")
            if room.phase >= 2 && !navigateToGame {
                print("checkRoomPhase: Game already started (phase=\(room.phase)), navigating to game flow...")
                navigateToGame = true
            }
        } catch {
            print("checkRoomPhase: Failed to check room phase: \(error)")
        }
    }

    /// 靜默刷新玩家列表（不顯示 loading 狀態）
    private func refreshPlayersQuietly() async {
        do {
            // Also check room status as fallback for WebSocket phase_change event
            let room = try await APIService.shared.getRoom(code: roomCode)

            // Fallback: If room phase has changed to preparing (2) and we haven't navigated yet
            if room.phase >= 2 && !navigateToGame {
                print("refreshPlayersQuietly: Detected game started via API (phase=\(room.phase)), navigating to game flow...")
                navigateToGame = true
                return
            }

            let freshPlayers = try await APIService.shared.getPlayers(roomCode: roomCode)
            // 合併更新：保留現有玩家資料，更新角色和準備狀態
            var updatedPlayers: [Player] = []
            for freshPlayer in freshPlayers {
                if let existingIndex = players.firstIndex(where: { $0.id == freshPlayer.id }) {
                    // 更新現有玩家
                    var updated = players[existingIndex]
                    updated.roleType = freshPlayer.roleType
                    updated.roleIndex = freshPlayer.roleIndex
                    updated.isReady = freshPlayer.isReady
                    updatedPlayers.append(updated)
                } else {
                    // 新玩家
                    updatedPlayers.append(freshPlayer)
                }
            }
            players = updatedPlayers

            // Sync myRole and isReady from current player's data
            if let currentPlayerData = players.first(where: { $0.id == currentPlayer.id }) {
                if let roleType = currentPlayerData.roleType,
                    let roleIndex = currentPlayerData.roleIndex,
                    myRole == nil
                {
                    myRole = (roleType.rawValue, roleIndex)
                    print("refreshPlayersQuietly: Synced myRole - \(roleType.rawValue)")
                }
                if currentPlayerData.isReady != isReady {
                    isReady = currentPlayerData.isReady
                    print("refreshPlayersQuietly: Synced isReady - \(isReady)")
                }
            }
            print("Players refreshed: \(players.count) players, room phase: \(room.phase)")
        } catch {
            // 靜默處理錯誤，不顯示給用戶
            print("Failed to refresh players: \(error)")
        }
    }

    // MARK: - Actions

    private func setReadyStatus(ready: Bool) async {
        isSettingReady = true
        errorMessage = nil

        do {
            let updatedPlayer = try await APIService.shared.setReady(
                playerId: currentPlayer.id, isReady: ready)
            isReady = updatedPlayer.isReady
        } catch {
            errorMessage = "設定準備狀態失敗：\(error.localizedDescription)"
        }

        isSettingReady = false
    }

    private func startGame() async {
        isStartingGame = true
        errorMessage = nil

        print("DEBUG: startGame() called, roomCode: \(roomCode), playerId: \(currentPlayer.id)")

        do {
            // 使用新的 startGame API，傳入 playerId 驗證房主身份
            try await APIService.shared.startGame(roomCode: roomCode, playerId: currentPlayer.id)
            print("DEBUG: startGame API call succeeded! Navigating to game flow...")
            // 直接導航到遊戲畫面，不等待 WebSocket 事件
            navigateToGame = true
        } catch {
            print("DEBUG: startGame API call FAILED: \(error.localizedDescription)")
            errorMessage = "開始遊戲失敗：\(error.localizedDescription)"
        }

        isStartingGame = false
    }
}

#Preview {
    NavigationStack {
        WaitingRoomView(
            roomCode: "PTB2HL",
            currentPlayer: Player(
                id: "test-id",
                nickname: "TestPlayer",
                isHost: true,
                roleType: nil,
                roleIndex: nil
            ),
            isHost: true
        )
    }
}
