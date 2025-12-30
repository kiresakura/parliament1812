import SwiftUI

/// 投票畫面 - 玩家選擇投票選項
struct VotingView: View {
    let round: Int  // 1 = 匿名投票, 2 = 記名投票
    let options: [VoteOption]
    let timerEndAt: Date?
    let votingProgress: Double  // 0.0 to 1.0
    var onVote: ((String) -> Void)?

    @State private var selectedOption: String?
    @State private var hasVoted = false
    @State private var timeRemaining: TimeInterval = 0
    @State private var showConfirmation = false
    @State private var cardAnimationOffset: [String: CGFloat] = [:]

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Background
            backgroundView

            VStack(spacing: 0) {
                // Header
                votingHeader
                    .padding(.top, ParliamentSpacing.lg)

                // Timer
                timerDisplay
                    .padding(.top, ParliamentSpacing.md)

                // Vote options
                if hasVoted {
                    waitingView
                        .transition(.opacity.combined(with: .scale))
                } else {
                    voteOptionsView
                        .padding(.top, ParliamentSpacing.lg)
                }

                Spacer()

                // Voting progress indicator
                votingProgressBar
                    .padding(.horizontal, ParliamentSpacing.lg)
                    .padding(.bottom, ParliamentSpacing.xl)
            }
        }
        .onReceive(timer) { _ in
            updateTimer()
        }
        .onAppear {
            updateTimer()
            animateCards()
        }
        .overlay {
            if showConfirmation {
                voteConfirmationOverlay
            }
        }
    }

    // MARK: - Background
    private var backgroundView: some View {
        ZStack {
            Color.parliamentBackground.ignoresSafeArea()

            // Dramatic gradient for voting
            LinearGradient(
                colors: [
                    Color.parliamentBurgundy.opacity(0.3),
                    Color.parliamentBackground,
                    Color.parliamentWood.opacity(0.2)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Hexagonal pattern
            HexagonalBackground()
                .opacity(0.08)
                .ignoresSafeArea()
        }
    }

    // MARK: - Voting Header
    private var votingHeader: some View {
        VStack(spacing: ParliamentSpacing.sm) {
            // Round indicator
            HStack(spacing: ParliamentSpacing.xs) {
                Circle()
                    .fill(round == 1 ? Color.parliamentGold : Color.parliamentWood.opacity(0.5))
                    .frame(width: 8, height: 8)
                Circle()
                    .fill(round == 2 ? Color.parliamentGold : Color.parliamentWood.opacity(0.5))
                    .frame(width: 8, height: 8)
            }

            Text(round == 1 ? "第一輪投票" : "第二輪投票")
                .font(.parliamentTitle)
                .foregroundColor(.parliamentTextPrimary)

            Text(round == 1 ? "ANONYMOUS VOTE" : "ROLL CALL VOTE")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.parliamentTextMuted)
                .tracking(3)

            // Vote type description
            Text(round == 1 ? "匿名投票 - 只公布比例" : "記名投票 - 公開唱票")
                .font(.system(size: 13))
                .foregroundColor(.parliamentGold)
                .padding(.horizontal, ParliamentSpacing.md)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.parliamentGold.opacity(0.15))
                )
        }
    }

    // MARK: - Timer Display
    private var timerDisplay: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.fill")
                .font(.system(size: 14))
                .foregroundColor(timeRemaining < 30 ? .red : .parliamentGold)

            Text(formattedTime)
                .font(.system(size: 24, weight: .medium, design: .serif))
                .foregroundColor(timeRemaining < 30 ? .red : .parliamentTextPrimary)
                .monospacedDigit()
        }
    }

    // MARK: - Vote Options
    private var voteOptionsView: some View {
        ScrollView {
            VStack(spacing: ParliamentSpacing.md) {
                ForEach(options) { option in
                    VoteOptionCard(
                        option: option,
                        isSelected: selectedOption == option.id,
                        onSelect: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedOption = option.id
                            }
                        }
                    )
                    .offset(y: cardAnimationOffset[option.id] ?? 50)
                }

                // Confirm button
                if selectedOption != nil {
                    Button {
                        showConfirmation = true
                    } label: {
                        HStack(spacing: ParliamentSpacing.sm) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 16))
                            Text("確認投票")
                        }
                    }
                    .buttonStyle(Civ6ButtonStyle(isEnabled: true))
                    .padding(.top, ParliamentSpacing.md)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.horizontal, ParliamentSpacing.lg)
            .padding(.bottom, ParliamentSpacing.lg)
        }
    }

    // MARK: - Waiting View (After voting)
    private var waitingView: some View {
        VStack(spacing: ParliamentSpacing.lg) {
            // Checkmark animation
            ZStack {
                Circle()
                    .fill(Color.parliamentGold.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.parliamentGold)
            }

            Text("您的票已投出")
                .font(.parliamentTitle)
                .foregroundColor(.parliamentTextPrimary)

            Text("等待其他議員完成投票...")
                .font(.parliamentBody)
                .foregroundColor(.parliamentTextSecondary)

            // Show selected option
            if let selected = selectedOption,
               let option = options.first(where: { $0.id == selected }) {
                HStack(spacing: ParliamentSpacing.sm) {
                    Text("您的選擇：")
                        .font(.system(size: 14))
                        .foregroundColor(.parliamentTextMuted)

                    Text("\(option.letter) - \(option.title)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.parliamentGold)
                }
                .padding(.top, ParliamentSpacing.md)
            }
        }
        .padding(ParliamentSpacing.xl)
    }

    // MARK: - Voting Progress Bar
    private var votingProgressBar: some View {
        VStack(spacing: ParliamentSpacing.xs) {
            Text("投票進度")
                .font(.system(size: 11))
                .foregroundColor(.parliamentTextMuted)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.parliamentWood.opacity(0.3))

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.parliamentGold, Color.parliamentBronze],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * votingProgress)
                        .animation(.easeOut(duration: 0.5), value: votingProgress)
                }
            }
            .frame(height: 8)

            Text("\(Int(votingProgress * 100))% 已投票")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.parliamentTextSecondary)
        }
    }

    // MARK: - Confirmation Overlay
    private var voteConfirmationOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    showConfirmation = false
                }

            VictorianFrame(cornerSize: 20) {
                VStack(spacing: ParliamentSpacing.lg) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.parliamentGold)

                    Text("確認投票？")
                        .font(.parliamentTitle)
                        .foregroundColor(.parliamentTextPrimary)

                    if let selected = selectedOption,
                       let option = options.first(where: { $0.id == selected }) {
                        VStack(spacing: 4) {
                            Text("選項 \(option.letter)")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.parliamentGold)

                            Text(option.title)
                                .font(.parliamentBody)
                                .foregroundColor(.parliamentTextSecondary)
                        }
                    }

                    Text(round == 1 ? "此投票為匿名，但投票後無法更改" : "此投票為記名，您的選擇將被公開")
                        .font(.system(size: 12))
                        .foregroundColor(.parliamentTextMuted)
                        .multilineTextAlignment(.center)

                    HStack(spacing: ParliamentSpacing.md) {
                        Button("取消") {
                            showConfirmation = false
                        }
                        .buttonStyle(Civ6ButtonStyle(isEnabled: true, style: .secondary))

                        Button("確認") {
                            confirmVote()
                        }
                        .buttonStyle(Civ6ButtonStyle(isEnabled: true))
                    }
                }
                .padding(ParliamentSpacing.lg)
            }
            .padding(ParliamentSpacing.xl)
            .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Helper Functions
    private var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func updateTimer() {
        guard let endAt = timerEndAt else {
            timeRemaining = 300 // Default 5 minutes
            return
        }
        timeRemaining = max(0, endAt.timeIntervalSinceNow)
    }

    private func animateCards() {
        for (index, option) in options.enumerated() {
            cardAnimationOffset[option.id] = 50
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1)) {
                cardAnimationOffset[option.id] = 0
            }
        }
    }

    private func confirmVote() {
        guard let selected = selectedOption else { return }

        showConfirmation = false
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            hasVoted = true
        }

        onVote?(selected)
    }
}

// MARK: - Vote Option Card

struct VoteOptionCard: View {
    let option: VoteOption
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: ParliamentSpacing.md) {
                // Letter badge
                ZStack {
                    Circle()
                        .fill(
                            isSelected ?
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
                        .frame(width: 50, height: 50)

                    Text(option.letter)
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundColor(.parliamentParchment)
                }

                // Option details
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? .parliamentGold : .parliamentTextPrimary)

                    Text(option.description)
                        .font(.system(size: 13))
                        .foregroundColor(.parliamentTextSecondary)
                        .lineLimit(2)
                }

                Spacer()

                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.parliamentGold : Color.parliamentWood.opacity(0.5), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color.parliamentGold)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(ParliamentSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: ParliamentRadius.medium)
                    .fill(Color.parliamentCardBackground)
                    .shadow(
                        color: isSelected ? Color.parliamentGold.opacity(0.3) : Color.black.opacity(0.2),
                        radius: isSelected ? 8 : 4,
                        x: 0,
                        y: isSelected ? 4 : 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: ParliamentRadius.medium)
                    .stroke(
                        isSelected ? Color.parliamentGold : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Voting View") {
    VotingView(
        round: 1,
        options: [
            VoteOption(id: "A", letter: "A", title: "禁止機器", description: "立法禁止工廠使用省力機器"),
            VoteOption(id: "B", letter: "B", title: "保護財產", description: "嚴厲打擊破壞機器的暴民"),
            VoteOption(id: "C", letter: "C", title: "折衷改革", description: "允許機器但立法保障工人權益")
        ],
        timerEndAt: Date().addingTimeInterval(180),
        votingProgress: 0.65
    )
}
