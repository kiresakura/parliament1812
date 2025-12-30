import SwiftUI

/// 遊戲結算畫面 - 顯示最終結果、秘密任務揭示和排名
struct GameResultView: View {
    let winningOption: VoteOption
    let playerResults: [PlayerGameResult]
    let currentPlayerId: String
    var onPlayAgain: (() -> Void)?
    var onExit: (() -> Void)?

    @State private var showLeaderboard = false
    @State private var revealedMissions: Set<String> = []
    @State private var selectedPlayer: PlayerGameResult?
    @State private var animationPhase = 0

    var body: some View {
        ZStack {
            // Background
            backgroundView

            ScrollView {
                VStack(spacing: ParliamentSpacing.xl) {
                    // Victory banner
                    victoryBanner
                        .padding(.top, ParliamentSpacing.xl)

                    // Winning option card
                    winningOptionCard
                        .padding(.horizontal, ParliamentSpacing.lg)

                    // Leaderboard
                    if showLeaderboard {
                        leaderboardSection
                            .padding(.horizontal, ParliamentSpacing.lg)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Action buttons
                    actionButtons
                        .padding(.horizontal, ParliamentSpacing.lg)
                        .padding(.bottom, ParliamentSpacing.xl)
                }
            }
        }
        .onAppear {
            startRevealAnimation()
        }
        .sheet(item: $selectedPlayer) { player in
            SecretMissionRevealSheet(playerResult: player)
        }
    }

    // MARK: - Background
    private var backgroundView: some View {
        ZStack {
            Color.parliamentBackground.ignoresSafeArea()

            // Celebration gradient
            RadialGradient(
                colors: [
                    Color.parliamentGold.opacity(0.15),
                    Color.parliamentBackground
                ],
                center: .top,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()

            // Hexagonal pattern
            HexagonalBackground()
                .opacity(0.1)
                .ignoresSafeArea()

            // Particle overlay (celebration effect)
            if animationPhase >= 2 {
                CelebrationParticles()
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: - Victory Banner
    private var victoryBanner: some View {
        VStack(spacing: ParliamentSpacing.md) {
            // Crown with glow
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.parliamentGold.opacity(0.4),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)

                Image(systemName: "crown.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.parliamentGold, Color.parliamentBronze],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .parliamentGold.opacity(0.5), radius: 10, x: 0, y: 5)
            }
            .scaleEffect(animationPhase >= 1 ? 1.0 : 0.5)
            .opacity(animationPhase >= 1 ? 1.0 : 0)

            // Title
            Text("辯論落幕")
                .font(.parliamentHeroTitle)
                .foregroundColor(.parliamentTextPrimary)
                .opacity(animationPhase >= 1 ? 1.0 : 0)

            Text("THE DEBATE HAS CONCLUDED")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.parliamentTextMuted)
                .tracking(4)
                .opacity(animationPhase >= 1 ? 1.0 : 0)
        }
    }

    // MARK: - Winning Option Card
    private var winningOptionCard: some View {
        VictorianFrame(cornerSize: 24) {
            VStack(spacing: ParliamentSpacing.md) {
                Text("國會決議")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.parliamentTextMuted)
                    .tracking(2)

                VictorianDivider()

                // Winning option
                HStack(spacing: ParliamentSpacing.md) {
                    // Letter badge
                    Text(winningOption.letter)
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundColor(.parliamentParchment)
                        .frame(width: 60, height: 60)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.parliamentGold, Color.parliamentBronze],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: .parliamentGold.opacity(0.5), radius: 8, x: 0, y: 4)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(winningOption.title)
                            .font(.parliamentTitle)
                            .foregroundColor(.parliamentGold)

                        Text(winningOption.description)
                            .font(.parliamentBody)
                            .foregroundColor(.parliamentTextSecondary)
                            .lineLimit(2)
                    }
                }

                VictorianDivider()

                // Historical note
                Text("「歷史的車輪已經轉動，1812年的國會做出了他們的選擇。」")
                    .font(.system(size: 13, design: .serif))
                    .foregroundColor(.parliamentTextMuted)
                    .italic()
                    .multilineTextAlignment(.center)
            }
            .padding(ParliamentSpacing.lg)
        }
        .opacity(animationPhase >= 2 ? 1.0 : 0)
        .offset(y: animationPhase >= 2 ? 0 : 30)
    }

    // MARK: - Leaderboard Section
    private var leaderboardSection: some View {
        VStack(spacing: ParliamentSpacing.md) {
            VictorianSectionHeader(
                "議員排名",
                subtitle: "Final Rankings"
            )

            // Player cards
            ForEach(Array(playerResults.enumerated()), id: \.element.id) { index, result in
                PlayerResultCard(
                    rank: index + 1,
                    result: result,
                    isCurrentPlayer: result.id == currentPlayerId,
                    isMissionRevealed: revealedMissions.contains(result.id),
                    onRevealMission: {
                        selectedPlayer = result
                    }
                )
                .opacity(animationPhase >= 3 ? 1.0 : 0)
                .offset(y: animationPhase >= 3 ? 0 : 20)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.1),
                    value: animationPhase
                )
            }
        }
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: ParliamentSpacing.md) {
            Button {
                onPlayAgain?()
            } label: {
                HStack(spacing: ParliamentSpacing.sm) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .bold))
                    Text("再來一局")
                }
            }
            .buttonStyle(Civ6ButtonStyle(isEnabled: true))

            Button {
                onExit?()
            } label: {
                Text("返回大廳")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.parliamentTextSecondary)
            }
        }
        .opacity(animationPhase >= 4 ? 1.0 : 0)
    }

    // MARK: - Animation
    private func startRevealAnimation() {
        // Phase 1: Crown and title
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
            animationPhase = 1
        }

        // Phase 2: Winning card
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.8)) {
            animationPhase = 2
        }

        // Phase 3: Leaderboard
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                showLeaderboard = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
                animationPhase = 3
            }
        }

        // Phase 4: Buttons
        withAnimation(.easeOut(duration: 0.5).delay(2.5)) {
            animationPhase = 4
        }
    }
}

// MARK: - Player Result Card

struct PlayerResultCard: View {
    let rank: Int
    let result: PlayerGameResult
    let isCurrentPlayer: Bool
    let isMissionRevealed: Bool
    let onRevealMission: () -> Void

    private var rankMedal: some View {
        Group {
            switch rank {
            case 1:
                Image(systemName: "medal.fill")
                    .foregroundColor(.yellow)
            case 2:
                Image(systemName: "medal.fill")
                    .foregroundColor(.gray)
            case 3:
                Image(systemName: "medal.fill")
                    .foregroundColor(.brown)
            default:
                Text("\(rank)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.parliamentTextMuted)
            }
        }
        .font(.system(size: 20))
    }

    var body: some View {
        HStack(spacing: ParliamentSpacing.md) {
            // Rank
            rankMedal
                .frame(width: 30)

            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.parliamentBurgundy, Color.parliamentBurgundy.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 45, height: 45)

                Text(String(result.nickname.prefix(1)))
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundColor(.parliamentParchment)

                if isCurrentPlayer {
                    Circle()
                        .stroke(Color.parliamentGold, lineWidth: 2)
                        .frame(width: 51, height: 51)
                }
            }

            // Player info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(result.nickname)
                        .font(.system(size: 15, weight: isCurrentPlayer ? .bold : .medium))
                        .foregroundColor(isCurrentPlayer ? .parliamentGold : .parliamentTextPrimary)

                    if isCurrentPlayer {
                        Text("(你)")
                            .font(.system(size: 11))
                            .foregroundColor(.parliamentGold)
                    }
                }

                Text(result.roleName)
                    .font(.system(size: 12))
                    .foregroundColor(.parliamentTextMuted)
            }

            Spacer()

            // Mission status and score
            VStack(alignment: .trailing, spacing: 4) {
                // Score
                Text("\(result.totalScore) 分")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.parliamentGold)

                // Mission button
                Button {
                    onRevealMission()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: result.missionCompleted ? "checkmark.seal.fill" : "seal")
                            .font(.system(size: 10))
                        Text("秘密任務")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(result.missionCompleted ? .green : .parliamentTextMuted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(result.missionCompleted ? Color.green.opacity(0.15) : Color.parliamentWood.opacity(0.2))
                    )
                }
            }
        }
        .padding(ParliamentSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ParliamentRadius.medium)
                .fill(Color.parliamentCardBackground)
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ParliamentRadius.medium)
                .stroke(isCurrentPlayer ? Color.parliamentGold.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Secret Mission Reveal Sheet

struct SecretMissionRevealSheet: View {
    let playerResult: PlayerGameResult

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.parliamentBackground.ignoresSafeArea()

            VStack(spacing: ParliamentSpacing.lg) {
                // Header
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.parliamentTextMuted)
                    }
                }
                .padding()

                // Player info
                VStack(spacing: ParliamentSpacing.sm) {
                    Circle()
                        .fill(Color.parliamentBurgundy)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(String(playerResult.nickname.prefix(1)))
                                .font(.system(size: 24, weight: .bold, design: .serif))
                                .foregroundColor(.parliamentParchment)
                        )

                    Text(playerResult.nickname)
                        .font(.parliamentTitle)
                        .foregroundColor(.parliamentTextPrimary)

                    Text(playerResult.roleName)
                        .font(.parliamentBody)
                        .foregroundColor(.parliamentGold)
                }

                VictorianDivider()
                    .padding(.horizontal, ParliamentSpacing.lg)

                // Secret mission
                VictorianFrame(cornerSize: 16) {
                    VStack(spacing: ParliamentSpacing.md) {
                        HStack {
                            Image(systemName: "lock.open.fill")
                                .foregroundColor(.parliamentGold)
                            Text("秘密任務")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.parliamentTextMuted)
                        }

                        Text(playerResult.missionTitle)
                            .font(.parliamentTitle)
                            .foregroundColor(.parliamentTextPrimary)
                            .multilineTextAlignment(.center)

                        Text(playerResult.missionDescription)
                            .font(.parliamentBody)
                            .foregroundColor(.parliamentTextSecondary)
                            .multilineTextAlignment(.center)

                        // Mission result
                        HStack(spacing: 8) {
                            Image(systemName: playerResult.missionCompleted ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(playerResult.missionCompleted ? .green : .red)

                            Text(playerResult.missionCompleted ? "任務完成！" : "任務失敗")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(playerResult.missionCompleted ? .green : .red)

                            if playerResult.missionCompleted {
                                Text("+\(playerResult.missionPoints) 分")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.parliamentGold)
                            }
                        }
                        .padding(.top, ParliamentSpacing.sm)
                    }
                    .padding(ParliamentSpacing.lg)
                }
                .padding(.horizontal, ParliamentSpacing.lg)

                Spacer()
            }
        }
    }
}

// MARK: - Celebration Particles

struct CelebrationParticles: View {
    @State private var particles: [Particle] = []

    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var rotation: Double
        var scale: CGFloat
        var opacity: Double
        let color: Color
    }

    var body: some View {
        GeometryReader { geometry in
            ForEach(particles) { particle in
                Image(systemName: "star.fill")
                    .font(.system(size: 8))
                    .foregroundColor(particle.color)
                    .opacity(particle.opacity)
                    .scaleEffect(particle.scale)
                    .rotationEffect(.degrees(particle.rotation))
                    .position(x: particle.x, y: particle.y)
            }
        }
        .onAppear {
            createParticles()
        }
    }

    private func createParticles() {
        let colors: [Color] = [.parliamentGold, .parliamentBronze, .yellow, .orange]

        for _ in 0..<20 {
            let particle = Particle(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: -20,
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.5...1.5),
                opacity: 1.0,
                color: colors.randomElement() ?? .parliamentGold
            )
            particles.append(particle)
        }

        // Animate particles falling
        for (index, _) in particles.enumerated() {
            let delay = Double.random(in: 0...2)
            let duration = Double.random(in: 3...5)

            withAnimation(.easeIn(duration: duration).delay(delay)) {
                particles[index].y = UIScreen.main.bounds.height + 50
                particles[index].rotation += Double.random(in: 180...540)
                particles[index].opacity = 0
            }
        }
    }
}

// MARK: - Data Models

struct PlayerGameResult: Identifiable {
    let id: String
    let nickname: String
    let roleName: String
    let totalScore: Int
    let missionTitle: String
    let missionDescription: String
    let missionCompleted: Bool
    let missionPoints: Int
}

// MARK: - Preview

#Preview("Game Results") {
    GameResultView(
        winningOption: VoteOption(
            id: "C",
            letter: "C",
            title: "折衷改革",
            description: "允許機器但立法保障工人權益"
        ),
        playerResults: [
            PlayerGameResult(
                id: "1",
                nickname: "威廉",
                roleName: "議員 威廉·菲茨傑拉德",
                totalScore: 150,
                missionTitle: "隱藏的野心",
                missionDescription: "確保任何涉及工人權益的法案都被否決",
                missionCompleted: true,
                missionPoints: 50
            ),
            PlayerGameResult(
                id: "2",
                nickname: "湯瑪斯",
                roleName: "紡織工人 湯瑪斯",
                totalScore: 120,
                missionTitle: "家庭守護者",
                missionDescription: "說服至少一位議員改變立場支持工人",
                missionCompleted: true,
                missionPoints: 50
            ),
            PlayerGameResult(
                id: "3",
                nickname: "理查",
                roleName: "工廠主 理查·威爾森",
                totalScore: 100,
                missionTitle: "利潤至上",
                missionDescription: "讓保護財產的選項獲勝",
                missionCompleted: false,
                missionPoints: 0
            )
        ],
        currentPlayerId: "1"
    )
}
