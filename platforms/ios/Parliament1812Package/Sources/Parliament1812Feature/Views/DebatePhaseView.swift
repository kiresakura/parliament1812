import SwiftUI

/// 辯論階段畫面 - 顯示計時器、當前階段和玩家狀態
struct DebatePhaseView: View {
    let phase: GamePhase
    let players: [Player]
    let currentPlayer: Player
    let timerEndAt: Date?
    var onOpenMessages: (() -> Void)?
    var onViewRole: (() -> Void)?

    @State private var timeRemaining: TimeInterval = 0
    @State private var timerColor: Color = .parliamentGold
    @State private var showingQuickActions = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Background
            backgroundView

            VStack(spacing: 0) {
                // Top bar with phase info
                phaseHeader
                    .padding(.top, ParliamentSpacing.md)

                // Timer display
                timerSection
                    .padding(.top, ParliamentSpacing.lg)

                // Phase description
                phaseDescriptionCard
                    .padding(.top, ParliamentSpacing.lg)
                    .padding(.horizontal, ParliamentSpacing.lg)

                // Players grid
                playersSection
                    .padding(.top, ParliamentSpacing.lg)

                Spacer()

                // Bottom action bar
                actionBar
                    .padding(.bottom, ParliamentSpacing.lg)
            }
        }
        .onReceive(timer) { _ in
            updateTimer()
        }
        .onAppear {
            updateTimer()
        }
    }

    // MARK: - Background
    private var backgroundView: some View {
        ZStack {
            Color.parliamentBackground.ignoresSafeArea()

            // Hexagonal pattern
            HexagonalBackground()
                .opacity(0.1)
                .ignoresSafeArea()

            // Gradient overlay
            LinearGradient(
                colors: [
                    Color.parliamentWood.opacity(0.3),
                    Color.clear,
                    Color.parliamentWood.opacity(0.2)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Phase Header
    private var phaseHeader: some View {
        VStack(spacing: ParliamentSpacing.xs) {
            // Phase indicator
            HStack(spacing: ParliamentSpacing.sm) {
                ForEach(GamePhase.debatePhases, id: \.self) { p in
                    PhaseIndicatorDot(
                        isActive: p == phase,
                        isPast: p.rawValue < phase.rawValue
                    )
                }
            }

            // Phase name
            Text(phase.displayName)
                .font(.parliamentTitle)
                .foregroundColor(.parliamentTextPrimary)

            Text(phase.englishName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.parliamentTextMuted)
                .tracking(2)
        }
    }

    // MARK: - Timer Section
    private var timerSection: some View {
        VStack(spacing: ParliamentSpacing.sm) {
            // Circular timer
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.parliamentWood.opacity(0.3), lineWidth: 8)
                    .frame(width: 160, height: 160)

                // Progress ring
                Circle()
                    .trim(from: 0, to: timerProgress)
                    .stroke(
                        timerColor,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timerProgress)

                // Time display
                VStack(spacing: 4) {
                    Text(formattedTime)
                        .font(.system(size: 42, weight: .light, design: .serif))
                        .foregroundColor(timerColor)
                        .monospacedDigit()

                    Text("剩餘時間")
                        .font(.system(size: 11))
                        .foregroundColor(.parliamentTextMuted)
                }

                // Decorative ring
                Circle()
                    .stroke(Color.parliamentGold.opacity(0.2), lineWidth: 1)
                    .frame(width: 180, height: 180)
            }

            // Warning indicator
            if timeRemaining < 60 && timeRemaining > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                    Text("時間緊迫")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(.orange)
                .padding(.horizontal, ParliamentSpacing.sm)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.15))
                )
            }
        }
    }

    // MARK: - Phase Description
    private var phaseDescriptionCard: some View {
        VictorianFrame(cornerSize: 16) {
            VStack(spacing: ParliamentSpacing.sm) {
                Text(phase.description)
                    .font(.parliamentBody)
                    .foregroundColor(.parliamentTextSecondary)
                    .multilineTextAlignment(.center)

                if let hint = phase.hint {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.parliamentGold)
                        Text(hint)
                            .font(.system(size: 12))
                            .foregroundColor(.parliamentGold)
                    }
                }
            }
            .padding(ParliamentSpacing.md)
        }
    }

    // MARK: - Players Section
    private var playersSection: some View {
        VStack(spacing: ParliamentSpacing.sm) {
            // Section header
            VictorianSectionHeader(
                "議員席",
                subtitle: "\(players.count) 位議員出席"
            )
            .padding(.horizontal, ParliamentSpacing.lg)

            // Players grid
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ParliamentSpacing.sm) {
                    ForEach(players) { player in
                        PlayerAvatarCard(
                            player: player,
                            isCurrentPlayer: player.id == currentPlayer.id
                        )
                    }
                }
                .padding(.horizontal, ParliamentSpacing.lg)
            }
        }
    }

    // MARK: - Action Bar
    private var actionBar: some View {
        HStack(spacing: ParliamentSpacing.md) {
            // View role button
            Button {
                onViewRole?()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 20))
                    Text("角色")
                        .font(.system(size: 10))
                }
                .foregroundColor(.parliamentGold)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(Color.parliamentCardBackground)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                )
            }

            Spacer()

            // Messages button with badge
            Button {
                onOpenMessages?()
            } label: {
                ZStack(alignment: .topTrailing) {
                    VStack(spacing: 4) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 20))
                        Text("密信")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.parliamentGold)
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(Color.parliamentCardBackground)
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    )

                    // Unread badge (placeholder)
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .offset(x: 2, y: -2)
                }
            }
        }
        .padding(.horizontal, ParliamentSpacing.xl)
    }

    // MARK: - Timer Logic
    private var timerProgress: CGFloat {
        guard timerEndAt != nil else { return 1.0 }
        let totalDuration = phase.defaultDuration
        let progress = timeRemaining / totalDuration
        return CGFloat(max(0, min(1, progress)))
    }

    private var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func updateTimer() {
        guard let endAt = timerEndAt else {
            timeRemaining = phase.defaultDuration
            return
        }

        timeRemaining = max(0, endAt.timeIntervalSinceNow)

        // Update color based on remaining time
        if timeRemaining < 30 {
            timerColor = .red
        } else if timeRemaining < 60 {
            timerColor = .orange
        } else {
            timerColor = .parliamentGold
        }
    }
}

// MARK: - Supporting Views

struct PhaseIndicatorDot: View {
    let isActive: Bool
    let isPast: Bool

    var body: some View {
        Circle()
            .fill(
                isActive ? Color.parliamentGold :
                isPast ? Color.parliamentGold.opacity(0.5) :
                Color.parliamentWood.opacity(0.3)
            )
            .frame(width: isActive ? 12 : 8, height: isActive ? 12 : 8)
            .overlay {
                if isActive {
                    Circle()
                        .stroke(Color.parliamentGold.opacity(0.5), lineWidth: 2)
                        .frame(width: 18, height: 18)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: isActive)
    }
}

struct PlayerAvatarCard: View {
    let player: Player
    let isCurrentPlayer: Bool

    var body: some View {
        VStack(spacing: 6) {
            // Avatar
            ZStack {
                // Character image or default avatar
                if let roleType = player.roleType {
                    Image(roleType.imageName, bundle: .main)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(
                                    isCurrentPlayer ? Color.parliamentGold : Color.parliamentWood.opacity(0.5),
                                    lineWidth: isCurrentPlayer ? 2 : 1
                                )
                        )
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.parliamentBurgundy,
                                    Color.parliamentBurgundy.opacity(0.7)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(String(player.nickname.prefix(1)))
                                .font(.system(size: 20, weight: .bold, design: .serif))
                                .foregroundColor(.parliamentParchment)
                        )

                    // Current player indicator
                    if isCurrentPlayer {
                        Circle()
                            .stroke(Color.parliamentGold, lineWidth: 2)
                            .frame(width: 56, height: 56)
                    }
                }

                // Host crown indicator
                if player.isHost {
                    VStack {
                        HStack {
                            Spacer()
                            Text("👑")
                                .font(.system(size: 12))
                                .background(
                                    Circle()
                                        .fill(Color.parliamentCardBackground)
                                        .frame(width: 18, height: 18)
                                )
                        }
                        Spacer()
                    }
                    .frame(width: 56, height: 56)
                }
            }

            // Name with HOST label
            HStack(spacing: 2) {
                Text(player.nickname)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isCurrentPlayer ? .parliamentGold : .parliamentTextSecondary)
                    .lineLimit(1)

                if player.isHost {
                    Text("主")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 3)
                        .padding(.vertical, 1)
                        .background(
                            Capsule()
                                .fill(Color.parliamentGold)
                        )
                }
            }

            // Role type (if revealed)
            if let roleType = player.roleType {
                Text(roleType.displayName)
                    .font(.system(size: 9))
                    .foregroundColor(.parliamentTextMuted)
            }
        }
        .frame(width: 70)
    }
}

// MARK: - Preview

#Preview("Debate Phase") {
    DebatePhaseView(
        phase: .debate,
        players: [
            Player(id: "1", nickname: "威廉", isHost: true, roleType: .mp, roleIndex: 1),
            Player(id: "2", nickname: "湯瑪斯", isHost: false, roleType: .worker, roleIndex: 1),
            Player(id: "3", nickname: "理查", isHost: false, roleType: .factory, roleIndex: 2),
            Player(id: "4", nickname: "喬治", isHost: false, roleType: .luddite, roleIndex: 1),
            Player(id: "5", nickname: "羅伯特", isHost: false, roleType: .reformer, roleIndex: 3)
        ],
        currentPlayer: Player(id: "1", nickname: "威廉", isHost: true, roleType: .mp, roleIndex: 1),
        timerEndAt: Date().addingTimeInterval(300)
    )
}
