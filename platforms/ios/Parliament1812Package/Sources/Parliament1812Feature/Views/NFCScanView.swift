import SwiftUI

struct NFCScanView: View {
    let roomCode: String
    let playerId: String
    var onRoleAssigned: ((String, Int) -> Void)?

    @State private var nfcService = NFCService()
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var scanSuccess = false
    @State private var showRolePicker = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                // Parliament 風格背景
                backgroundView.ignoresSafeArea()

                VStack(spacing: ParliamentSpacing.xl) {
                    Spacer()

                    // NFC 圖標區域
                    nfcIconSection

                    // 狀態文字
                    statusTextSection

                    // 錯誤訊息
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding(ParliamentSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: ParliamentRadius.small)
                                    .fill(Color.red.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: ParliamentRadius.small)
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, ParliamentSpacing.lg)
                    }

                    Spacer()

                    // 掃描按鈕區域
                    actionButtonSection

                    // NFC 不支援提示
                    if !nfcService.isNFCAvailable {
                        HStack(spacing: ParliamentSpacing.xs) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                            Text("此設備不支援 NFC")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.parliamentGold)
                        .padding(.bottom, ParliamentSpacing.md)
                    }
                }
                .padding(ParliamentSpacing.lg)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("掃描角色卡")
                        .font(.parliamentTabLabel)
                        .foregroundColor(.parliamentTextPrimary)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: ParliamentSpacing.xs) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .semibold))
                            Text("取消")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.parliamentGold)
                    }
                }
            }
            .toolbarBackground(Color.parliamentBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .onChange(of: nfcService.scannedCardData) { oldValue, newValue in
            guard let cardData = newValue else { return }
            Task {
                await submitNFCScan(cardData)
            }
        }
        .onChange(of: nfcService.error?.localizedDescription) { oldValue, newValue in
            if let errorDesc = newValue {
                errorMessage = errorDesc
            }
        }
    }

    private func startNFCScan() {
        errorMessage = nil
        nfcService.startScan()
    }

    #if DEBUG
    /// 虛擬 NFC 卡片資料（用於模擬器測試）
    private struct VirtualCard: Identifiable {
        let id: String  // 角色代碼，如 W01
        let roleType: String
        let roleName: String
        let cardIndex: Int
        let description: String
        let color: Color

        var displayName: String {
            "\(roleName) #\(cardIndex)"
        }
    }

    /// 所有可用的虛擬卡片
    private var virtualCards: [VirtualCard] {
        [
            // 紡織工人 (Worker)
            VirtualCard(id: "W01", roleType: "worker", roleName: "紡織工人", cardIndex: 1,
                       description: "湯瑪斯 - 內心衝突型", color: .blue),
            VirtualCard(id: "W02", roleType: "worker", roleName: "紡織工人", cardIndex: 2,
                       description: "湯瑪斯 - 復仇恩怨型", color: .blue),
            VirtualCard(id: "W03", roleType: "worker", roleName: "紡織工人", cardIndex: 3,
                       description: "湯瑪斯 - 雙面人型", color: .blue),
            VirtualCard(id: "W04", roleType: "worker", roleName: "紡織工人", cardIndex: 4,
                       description: "湯瑪斯 - 理想主義型", color: .blue),

            // 工廠主 (Factory)
            VirtualCard(id: "F01", roleType: "factory", roleName: "工廠主", cardIndex: 1,
                       description: "理查 - 內心衝突型", color: .purple),
            VirtualCard(id: "F02", roleType: "factory", roleName: "工廠主", cardIndex: 2,
                       description: "理查 - 復仇恩怨型", color: .purple),
            VirtualCard(id: "F03", roleType: "factory", roleName: "工廠主", cardIndex: 3,
                       description: "理查 - 雙面人型", color: .purple),
            VirtualCard(id: "F04", roleType: "factory", roleName: "工廠主", cardIndex: 4,
                       description: "理查 - 理想主義型", color: .purple),

            // 盧德派 (Luddite)
            VirtualCard(id: "L01", roleType: "luddite", roleName: "盧德派", cardIndex: 1,
                       description: "喬治 - 內心衝突型", color: .red),
            VirtualCard(id: "L02", roleType: "luddite", roleName: "盧德派", cardIndex: 2,
                       description: "喬治 - 復仇恩怨型", color: .red),
            VirtualCard(id: "L03", roleType: "luddite", roleName: "盧德派", cardIndex: 3,
                       description: "喬治 - 雙面人型", color: .red),
            VirtualCard(id: "L04", roleType: "luddite", roleName: "盧德派", cardIndex: 4,
                       description: "喬治 - 理想主義型", color: .red),

            // 社會改革者 (Reformer)
            VirtualCard(id: "R01", roleType: "reformer", roleName: "改革者", cardIndex: 1,
                       description: "羅伯特 - 內心衝突型", color: .green),
            VirtualCard(id: "R02", roleType: "reformer", roleName: "改革者", cardIndex: 2,
                       description: "羅伯特 - 復仇恩怨型", color: .green),
            VirtualCard(id: "R03", roleType: "reformer", roleName: "改革者", cardIndex: 3,
                       description: "羅伯特 - 雙面人型", color: .green),
            VirtualCard(id: "R04", roleType: "reformer", roleName: "改革者", cardIndex: 4,
                       description: "羅伯特 - 理想主義型", color: .green),

            // 國會議員 (MP)
            VirtualCard(id: "M01", roleType: "mp", roleName: "議員", cardIndex: 1,
                       description: "威廉 - 內心衝突型", color: .orange),
            VirtualCard(id: "M02", roleType: "mp", roleName: "議員", cardIndex: 2,
                       description: "威廉 - 復仇恩怨型", color: .orange),
            VirtualCard(id: "M03", roleType: "mp", roleName: "議員", cardIndex: 3,
                       description: "威廉 - 雙面人型", color: .orange),
            VirtualCard(id: "M04", roleType: "mp", roleName: "議員", cardIndex: 4,
                       description: "威廉 - 理想主義型", color: .orange),
        ]
    }

    /// 手動分配角色（使用後端 API）
    private func assignRoleManually(_ card: VirtualCard) async {
        isSubmitting = true
        errorMessage = nil

        do {
            let response = try await APIService.shared.assignRoleManually(
                roomCode: roomCode,
                playerId: playerId,
                roleCode: card.id
            )

            if response.success, let roleType = response.roleType, let roleIndex = response.roleIndex {
                scanSuccess = true
                onRoleAssigned?(roleType, roleIndex)

                // 延遲關閉
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                dismiss()
            } else {
                errorMessage = response.message ?? "角色分配失敗"
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }

    /// 模擬 NFC 掃描（舊版，使用測試卡片）
    private func simulateScan() {
        // 使用測試卡片 (UID 綁定防偽格式)
        let testCards: [(cardId: String, signature: String, uid: String)] = [
            ("GEORGEIII01", "4F54F9E82A76A3BD", "04F178BA2E0289"),
        ]
        let card = testCards.randomElement()!
        nfcService.simulateScan(cardId: card.cardId, signature: card.signature, uid: card.uid)
    }
    #endif

    private func submitNFCScan(_ cardData: NFCCardData) async {
        isSubmitting = true
        errorMessage = nil

        // 使用新的便利初始化器，自動處理新舊格式
        let request = NFCScanRequest(
            roomCode: roomCode,
            playerId: playerId,
            cardData: cardData
        )

        do {
            let response = try await APIService.shared.scanNFC(request)
            if response.success, let roleType = response.roleType, let roleIndex = response.roleIndex {
                scanSuccess = true
                onRoleAssigned?(roleType, roleIndex)

                // 延遲關閉
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                dismiss()
            } else {
                errorMessage = response.message ?? "角色分配失敗"
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }

    // MARK: - Background View
    private var backgroundView: some View {
        ZStack {
            Color.parliamentBackground

            // Decorative gradient
            LinearGradient(
                colors: [
                    Color.parliamentGold.opacity(0.08),
                    Color.clear,
                    Color.black.opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Radial glow effect for NFC scanning
            if nfcService.isScanning {
                RadialGradient(
                    colors: [
                        Color.parliamentGold.opacity(0.15),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 50,
                    endRadius: 250
                )
            }
        }
    }

    // MARK: - NFC Icon Section
    private var nfcIconSection: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.parliamentGold.opacity(0.3),
                            Color.parliamentGold.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 180, height: 180)

            // Inner glow circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            scanSuccess
                                ? Color.green.opacity(0.2)
                                : nfcService.isScanning
                                    ? Color.parliamentGold.opacity(0.15)
                                    : Color.parliamentGold.opacity(0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)

            // NFC icon
            Image(systemName: scanSuccess ? "checkmark.circle.fill" : "wave.3.right.circle.fill")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(
                    scanSuccess
                        ? Color.green
                        : nfcService.isScanning
                            ? Color.parliamentGold
                            : Color.parliamentTextMuted
                )
                .symbolEffect(.pulse, isActive: nfcService.isScanning)
        }
    }

    // MARK: - Status Text Section
    private var statusTextSection: some View {
        VStack(spacing: ParliamentSpacing.sm) {
            if scanSuccess {
                Text("掃描成功！")
                    .font(.parliamentTitle)
                    .foregroundColor(.green)

                Text("正在載入角色資訊...")
                    .font(.parliamentBody)
                    .foregroundColor(.parliamentTextMuted)
            } else if nfcService.isScanning {
                Text("掃描中...")
                    .font(.parliamentTitle)
                    .foregroundColor(.parliamentTextPrimary)

                Text("請將 NFC 角色卡片靠近手機頂部")
                    .font(.parliamentBody)
                    .foregroundColor(.parliamentTextMuted)
                    .multilineTextAlignment(.center)
            } else if isSubmitting {
                Text("驗證角色中...")
                    .font(.parliamentTitle)
                    .foregroundColor(.parliamentTextPrimary)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .parliamentGold))
                    .scaleEffect(1.2)
                    .padding(.top, ParliamentSpacing.sm)
            } else {
                Text("準備掃描 NFC 角色卡")
                    .font(.parliamentTitle)
                    .foregroundColor(.parliamentTextPrimary)

                Text("點擊下方按鈕開始掃描")
                    .font(.parliamentBody)
                    .foregroundColor(.parliamentTextMuted)
            }
        }
    }

    // MARK: - Action Button Section
    @ViewBuilder
    private var actionButtonSection: some View {
        if !scanSuccess {
            VStack(spacing: ParliamentSpacing.md) {
                Button {
                    startNFCScan()
                } label: {
                    HStack(spacing: ParliamentSpacing.sm) {
                        Image(systemName: "sensor.tag.radiowaves.forward.fill")
                            .font(.system(size: 18))
                        Text(nfcService.isScanning ? "掃描中..." : "開始掃描")
                    }
                }
                .buttonStyle(ParliamentPrimaryButtonStyle(isEnabled: !nfcService.isScanning && !isSubmitting))
                .disabled(nfcService.isScanning || isSubmitting)

                #if DEBUG
                // Debug 模式：選擇角色（虛擬 NFC 卡）
                Button {
                    showRolePicker = true
                } label: {
                    HStack(spacing: ParliamentSpacing.xs) {
                        Image(systemName: "person.crop.rectangle.stack.fill")
                            .font(.system(size: 14))
                        Text("選擇角色 (模擬器)")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, ParliamentSpacing.lg)
                    .padding(.vertical, ParliamentSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: ParliamentRadius.medium)
                            .fill(Color.blue.opacity(0.8))
                    )
                }
                .disabled(nfcService.isScanning || isSubmitting)
                .sheet(isPresented: $showRolePicker) {
                    debugRolePickerSheet
                }
                #endif
            }
            .padding(.bottom, ParliamentSpacing.lg)
        }
    }

    // MARK: - DEBUG Role Picker Sheet
    #if DEBUG
    private var debugRolePickerSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ParliamentSpacing.lg) {
                    // 說明文字
                    Text("選擇一張虛擬 NFC 卡片以測試不同角色")
                        .font(.system(size: 14))
                        .foregroundColor(.parliamentTextMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // 按角色類型分組
                    ForEach(["worker", "factory", "luddite", "reformer", "mp"], id: \.self) { roleType in
                        VStack(alignment: .leading, spacing: ParliamentSpacing.sm) {
                            // 角色類型標題
                            HStack {
                                Circle()
                                    .fill(colorForRoleType(roleType))
                                    .frame(width: 12, height: 12)
                                Text(nameForRoleType(roleType))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.parliamentTextPrimary)
                            }
                            .padding(.horizontal, ParliamentSpacing.md)

                            // 該類型的卡片列表
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: ParliamentSpacing.sm) {
                                ForEach(virtualCards.filter { $0.roleType == roleType }) { card in
                                    Button {
                                        showRolePicker = false
                                        Task {
                                            await assignRoleManually(card)
                                        }
                                    } label: {
                                        VStack(spacing: 4) {
                                            Text(card.id)
                                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                                .foregroundColor(.white)

                                            Text(card.description)
                                                .font(.system(size: 10))
                                                .foregroundColor(.white.opacity(0.8))
                                                .lineLimit(1)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, ParliamentSpacing.md)
                                        .background(
                                            RoundedRectangle(cornerRadius: ParliamentRadius.small)
                                                .fill(card.color.opacity(0.85))
                                        )
                                    }
                                    .disabled(isSubmitting)
                                }
                            }
                            .padding(.horizontal, ParliamentSpacing.md)
                        }

                        Divider()
                            .padding(.vertical, ParliamentSpacing.xs)
                    }
                }
                .padding(.vertical, ParliamentSpacing.lg)
            }
            .background(Color.parliamentBackground.ignoresSafeArea())
            .navigationTitle("虛擬 NFC 卡片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        showRolePicker = false
                    }
                    .foregroundColor(.parliamentGold)
                }
            }
            .toolbarBackground(Color.parliamentCardBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.large])
    }

    private func colorForRoleType(_ type: String) -> Color {
        switch type {
        case "worker": return .blue
        case "factory": return .purple
        case "luddite": return .red
        case "reformer": return .green
        case "mp": return .orange
        default: return .gray
        }
    }

    private func nameForRoleType(_ type: String) -> String {
        switch type {
        case "worker": return "紡織工人 (Worker)"
        case "factory": return "工廠主 (Factory)"
        case "luddite": return "盧德派 (Luddite)"
        case "reformer": return "改革者 (Reformer)"
        case "mp": return "國會議員 (MP)"
        default: return type
        }
    }
    #endif
}

#Preview {
    NFCScanView(
        roomCode: "ABC123",
        playerId: "test-player-id"
    ) { roleType, roleIndex in
        print("Role assigned: \(roleType) #\(roleIndex)")
    }
}
