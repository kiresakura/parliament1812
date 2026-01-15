import SwiftUI

/// 投票結果畫面 - 顯示投票結果統計
struct VoteResultView: View {
    let round: Int
    let results: [VoteResultItem]
    let voters: [VoterInfo]?  // Only for round 2 (roll call)
    let winningOption: String?
    var onContinue: (() -> Void)?

    @State private var animatedProgress: [String: CGFloat] = [:]
    @State private var showVoters = false
    @State private var headerScale: CGFloat = 0.8
    @State private var headerOpacity: Double = 0

    var body: some View {
        ZStack {
            // Background
            backgroundView

            ScrollView {
                VStack(spacing: ParliamentSpacing.lg) {
                    // Header with announcement
                    resultHeader
                        .padding(.top, ParliamentSpacing.xl)
                        .scaleEffect(headerScale)
                        .opacity(headerOpacity)

                    // Results chart
                    resultsChart
                        .padding(.horizontal, ParliamentSpacing.lg)

                    // Voter breakdown (for round 2)
                    if round == 2, let voters = voters {
                        voterBreakdown(voters: voters)
                            .padding(.horizontal, ParliamentSpacing.lg)
                            .opacity(showVoters ? 1 : 0)
                            .offset(y: showVoters ? 0 : 20)
                    }

                    // Continue button
                    Button {
                        onContinue?()
                    } label: {
                        HStack(spacing: ParliamentSpacing.sm) {
                            Text("繼續")
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                    }
                    .buttonStyle(Civ6ButtonStyle(isEnabled: true))
                    .padding(.top, ParliamentSpacing.lg)
                    .padding(.bottom, ParliamentSpacing.xl)
                }
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Background
    private var backgroundView: some View {
        ZStack {
            Color.parliamentBackground.ignoresSafeArea()

            // Dramatic gradient
            RadialGradient(
                colors: [
                    Color.parliamentBurgundy.opacity(0.2),
                    Color.parliamentBackground
                ],
                center: .top,
                startRadius: 100,
                endRadius: 500
            )
            .ignoresSafeArea()

            // Hexagonal pattern
            HexagonalBackground()
                .opacity(0.08)
                .ignoresSafeArea()
        }
    }

    // MARK: - Result Header
    private var resultHeader: some View {
        VStack(spacing: ParliamentSpacing.md) {
            // Crown icon
            Image(systemName: "crown.fill")
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.parliamentGold, Color.parliamentBronze],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Text(round == 1 ? "初步投票結果" : "最終投票結果")
                .font(.parliamentHeroTitle)
                .foregroundColor(.parliamentTextPrimary)

            Text(round == 1 ? "PRELIMINARY RESULTS" : "FINAL RESULTS")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.parliamentTextMuted)
                .tracking(4)

            if let winning = winningOption,
               let result = results.first(where: { $0.optionId == winning }) {
                // Winning announcement
                VStack(spacing: 4) {
                    Text("獲勝選項")
                        .font(.system(size: 12))
                        .foregroundColor(.parliamentTextMuted)

                    HStack(spacing: 8) {
                        Text(result.letter)
                            .font(.system(size: 24, weight: .bold, design: .serif))
                            .foregroundColor(.parliamentParchment)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.parliamentGold)
                            )

                        Text(result.title)
                            .font(.parliamentTitle)
                            .foregroundColor(.parliamentGold)
                    }
                }
                .padding(.top, ParliamentSpacing.sm)
            }

            VictorianDivider()
                .padding(.top, ParliamentSpacing.sm)
        }
    }

    // MARK: - Results Chart
    private var resultsChart: some View {
        VictorianFrame(cornerSize: 20) {
            VStack(spacing: ParliamentSpacing.md) {
                ForEach(results.sorted(by: { $0.percentage > $1.percentage })) { result in
                    VoteResultBar(
                        result: result,
                        isWinner: result.optionId == winningOption,
                        animatedProgress: animatedProgress[result.optionId] ?? 0,
                        showCount: round == 2  // Only show count for roll call
                    )
                }
            }
            .padding(ParliamentSpacing.lg)
        }
    }

    // MARK: - Voter Breakdown
    private func voterBreakdown(voters: [VoterInfo]) -> some View {
        VStack(spacing: ParliamentSpacing.md) {
            VictorianSectionHeader(
                "唱票記錄",
                subtitle: "Roll Call Record"
            )

            // Group voters by their vote
            ForEach(results) { result in
                let votersForOption = voters.filter { $0.votedFor == result.optionId }
                if !votersForOption.isEmpty {
                    VStack(alignment: .leading, spacing: ParliamentSpacing.sm) {
                        // Option header
                        HStack {
                            Text("選項 \(result.letter)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.parliamentGold)

                            Text("- \(result.title)")
                                .font(.system(size: 14))
                                .foregroundColor(.parliamentTextSecondary)

                            Spacer()

                            Text("\(votersForOption.count) 票")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.parliamentTextMuted)
                        }

                        // Voters
                        FlowLayout(spacing: ParliamentSpacing.xs) {
                            ForEach(votersForOption) { voter in
                                VoterChip(voter: voter)
                            }
                        }
                    }
                    .padding(ParliamentSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: ParliamentRadius.medium)
                            .fill(Color.parliamentCardBackground)
                    )
                }
            }
        }
    }

    // MARK: - Animations
    private func startAnimations() {
        // Header animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            headerScale = 1.0
            headerOpacity = 1.0
        }

        // Bar chart animations
        for (index, result) in results.enumerated() {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3 + Double(index) * 0.15)) {
                animatedProgress[result.optionId] = CGFloat(result.percentage / 100)
            }
        }

        // Voter breakdown animation
        withAnimation(.easeOut(duration: 0.5).delay(1.0)) {
            showVoters = true
        }
    }
}

// MARK: - Vote Result Bar

struct VoteResultBar: View {
    let result: VoteResultItem
    let isWinner: Bool
    let animatedProgress: CGFloat
    let showCount: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Option info
            HStack {
                // Letter badge
                Text(result.letter)
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundColor(.parliamentParchment)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(
                                isWinner ?
                                LinearGradient(
                                    colors: [Color.parliamentGold, Color.parliamentBronze],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ) :
                                LinearGradient(
                                    colors: [Color.parliamentBurgundy, Color.parliamentBurgundy.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )

                Text(result.title)
                    .font(.system(size: 15, weight: isWinner ? .semibold : .regular))
                    .foregroundColor(isWinner ? .parliamentGold : .parliamentTextPrimary)

                Spacer()

                // Percentage
                Text("\(Int(result.percentage))%")
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundColor(isWinner ? .parliamentGold : .parliamentTextSecondary)

                if showCount {
                    Text("(\(result.count) 票)")
                        .font(.system(size: 12))
                        .foregroundColor(.parliamentTextMuted)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.parliamentWood.opacity(0.3))

                    // Progress
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            isWinner ?
                            LinearGradient(
                                colors: [Color.parliamentGold, Color.parliamentBronze],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [Color.parliamentBurgundy.opacity(0.8), Color.parliamentBurgundy.opacity(0.5)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * animatedProgress)
                }
            }
            .frame(height: 12)
        }
    }
}

// MARK: - Voter Chip

struct VoterChip: View {
    let voter: VoterInfo

    var body: some View {
        HStack(spacing: 4) {
            // Avatar
            Circle()
                .fill(Color.parliamentBurgundy)
                .frame(width: 20, height: 20)
                .overlay(
                    Text(String(voter.nickname.prefix(1)))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.parliamentParchment)
                )

            Text(voter.nickname)
                .font(.system(size: 12))
                .foregroundColor(.parliamentTextSecondary)

            if let roleType = voter.roleType {
                Text("(\(roleType))")
                    .font(.system(size: 10))
                    .foregroundColor(.parliamentTextMuted)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.parliamentWood.opacity(0.2))
        )
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, spacing: spacing, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, spacing: spacing, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.origin.x, y: bounds.minY + frame.origin.y),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []

        init(in maxWidth: CGFloat, spacing: CGFloat, subviews: Subviews) {
            var origin = CGPoint.zero
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if origin.x + size.width > maxWidth && origin.x > 0 {
                    origin.x = 0
                    origin.y += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(origin: origin, size: size))
                origin.x += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            self.size = CGSize(
                width: maxWidth,
                height: origin.y + lineHeight
            )
        }
    }
}

// MARK: - Data Models

struct VoteResultItem: Identifiable {
    let id = UUID()
    let optionId: String
    let letter: String
    let title: String
    let count: Int
    let percentage: Double
    var voters: [VoterInfo] = []
}

struct VoterInfo: Identifiable {
    var id: String { playerId }
    let playerId: String
    let nickname: String
    var roleType: String? = nil
    var votedFor: String = ""

    // Convenience initializer for WebSocket data
    init(playerId: String, nickname: String) {
        self.playerId = playerId
        self.nickname = nickname
    }

    // Full initializer
    init(playerId: String, nickname: String, roleType: String?, votedFor: String) {
        self.playerId = playerId
        self.nickname = nickname
        self.roleType = roleType
        self.votedFor = votedFor
    }
}

// MARK: - Preview

#Preview("Vote Results - Round 1") {
    VoteResultView(
        round: 1,
        results: [
            VoteResultItem(optionId: "A", letter: "A", title: "禁止機器", count: 5, percentage: 25),
            VoteResultItem(optionId: "B", letter: "B", title: "保護財產", count: 8, percentage: 40),
            VoteResultItem(optionId: "C", letter: "C", title: "折衷改革", count: 7, percentage: 35)
        ],
        voters: nil,
        winningOption: "B"
    )
}

#Preview("Vote Results - Round 2") {
    VoteResultView(
        round: 2,
        results: [
            VoteResultItem(optionId: "A", letter: "A", title: "禁止機器", count: 4, percentage: 20),
            VoteResultItem(optionId: "B", letter: "B", title: "保護財產", count: 6, percentage: 30),
            VoteResultItem(optionId: "C", letter: "C", title: "折衷改革", count: 10, percentage: 50)
        ],
        voters: [
            VoterInfo(playerId: "1", nickname: "威廉", roleType: "議員", votedFor: "C"),
            VoterInfo(playerId: "2", nickname: "湯瑪斯", roleType: "工人", votedFor: "A"),
            VoterInfo(playerId: "3", nickname: "理查", roleType: "工廠主", votedFor: "B"),
            VoterInfo(playerId: "4", nickname: "喬治", roleType: "盧德派", votedFor: "A"),
            VoterInfo(playerId: "5", nickname: "羅伯特", roleType: "改革者", votedFor: "C")
        ],
        winningOption: "C"
    )
}
