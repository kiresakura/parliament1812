import SwiftUI

// MARK: - Phase Progress Bar
/// Shows the progress through all game phases with Victorian styling
struct PhaseProgressBar: View {
    let currentPhase: GamePhase

    private let debatePhases = GamePhase.debatePhases

    var body: some View {
        VStack(spacing: ParliamentSpacing.sm) {
            // Phase name header
            HStack {
                Text(currentPhase.displayName)
                    .font(.custom("Songti TC", size: 14).weight(.semibold))
                    .foregroundColor(.parliamentGold)

                Spacer()

                Text(currentPhase.englishName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.parliamentTextMuted)
                    .tracking(1)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(Color.parliamentOil)
                        .frame(height: 8)
                        .overlay(
                            Capsule()
                                .stroke(Color.parliamentGold.opacity(0.3), lineWidth: 1)
                        )

                    // Filled progress
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.parliamentGoldLight,
                                    Color.parliamentGold,
                                    Color.parliamentGoldDark
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: progressWidth(for: geometry.size.width), height: 8)
                        .shadow(color: .parliamentGold.opacity(0.5), radius: 4)
                        .animation(.easeInOut(duration: 0.5), value: currentPhase)

                    // Phase markers
                    HStack(spacing: 0) {
                        ForEach(Array(debatePhases.enumerated()), id: \.offset) { index, phase in
                            Circle()
                                .fill(markerColor(for: phase))
                                .frame(width: 10, height: 10)
                                .overlay(
                                    Circle()
                                        .stroke(Color.parliamentGold.opacity(0.5), lineWidth: 1)
                                )
                                .shadow(
                                    color: phase == currentPhase
                                        ? Color.parliamentGold.opacity(0.8)
                                        : .clear,
                                    radius: 4
                                )

                            if index < debatePhases.count - 1 {
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
            .frame(height: 12)

            // Phase indicator text
            Text("階段 \(currentPhaseIndex + 1)/\(debatePhases.count)")
                .font(.system(size: 10))
                .foregroundColor(.parliamentTextMuted)
        }
        .padding(ParliamentSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ParliamentRadius.medium)
                .fill(Color.parliamentCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: ParliamentRadius.medium)
                        .stroke(Color.parliamentGold.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var currentPhaseIndex: Int {
        debatePhases.firstIndex(of: currentPhase) ?? 0
    }

    private func progressWidth(for totalWidth: CGFloat) -> CGFloat {
        guard debatePhases.count > 1 else { return 0 }
        let progress = CGFloat(currentPhaseIndex) / CGFloat(debatePhases.count - 1)
        return max(12, totalWidth * progress) // Minimum width for visibility
    }

    private func markerColor(for phase: GamePhase) -> Color {
        guard let phaseIndex = debatePhases.firstIndex(of: phase),
              let currentIndex = debatePhases.firstIndex(of: currentPhase) else {
            return Color.parliamentShadow
        }

        if phaseIndex < currentIndex {
            return Color.parliamentGold
        } else if phaseIndex == currentIndex {
            return Color.parliamentGoldLight
        } else {
            return Color.parliamentShadow
        }
    }
}

// MARK: - Countdown Timer View
/// Displays the countdown timer for the current phase with Victorian styling
struct CountdownTimerView: View {
    let endTime: Date?
    let phaseName: String

    @State private var remainingSeconds: Int = 0
    @State private var isUrgent: Bool = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: ParliamentSpacing.md) {
            // Timer icon with glow when urgent
            ZStack {
                if isUrgent {
                    Circle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .blur(radius: 8)
                }

                Image(systemName: isUrgent ? "hourglass.bottomhalf.filled" : "hourglass")
                    .font(.system(size: 24))
                    .foregroundColor(isUrgent ? .red : .parliamentGold)
                    .symbolEffect(.pulse, isActive: isUrgent)
            }

            VStack(alignment: .leading, spacing: ParliamentSpacing.xs) {
                // Phase name
                Text(phaseName)
                    .font(.custom("Songti TC", size: 12))
                    .foregroundColor(.parliamentTextSecondary)

                // Time display
                Text(formattedTime)
                    .font(.system(size: 32, weight: .light, design: .monospaced))
                    .foregroundColor(isUrgent ? .red : .parliamentTextPrimary)
                    .contentTransition(.numericText())
                    .animation(.default, value: remainingSeconds)
            }

            Spacer()

            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.parliamentOil, lineWidth: 4)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: progressRatio)
                    .stroke(
                        isUrgent
                            ? Color.red
                            : Color.parliamentGold,
                        style: StrokeStyle(
                            lineWidth: 4,
                            lineCap: .round
                        )
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progressRatio)

                Text("\(Int(progressRatio * 100))%")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.parliamentTextMuted)
            }
        }
        .padding(ParliamentSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ParliamentRadius.medium)
                .fill(Color.parliamentCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: ParliamentRadius.medium)
                        .stroke(
                            isUrgent
                                ? Color.red.opacity(0.5)
                                : Color.parliamentGold.opacity(0.2),
                            lineWidth: 1
                        )
                )
        )
        .overlay(
            // Urgent warning indicator
            Group {
                if isUrgent {
                    RoundedRectangle(cornerRadius: ParliamentRadius.medium)
                        .stroke(Color.red.opacity(0.5), lineWidth: 2)
                        .shadow(color: .red.opacity(0.3), radius: 8)
                }
            }
        )
        .onReceive(timer) { _ in
            updateRemainingTime()
        }
        .onAppear {
            updateRemainingTime()
        }
        .onChange(of: endTime) { _, _ in
            updateRemainingTime()
        }
    }

    private var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var progressRatio: CGFloat {
        guard let endTime = endTime else { return 0 }

        // Assume max duration is the phase's default duration
        let totalDuration = GamePhase.debatePhases.first?.defaultDuration ?? 600
        let elapsed = totalDuration - TimeInterval(remainingSeconds)
        let progress = elapsed / totalDuration

        return max(0, min(1, 1 - progress))
    }

    private func updateRemainingTime() {
        guard let endTime = endTime else {
            remainingSeconds = 0
            isUrgent = false
            return
        }

        let remaining = endTime.timeIntervalSinceNow
        remainingSeconds = max(0, Int(remaining))

        // Urgent when less than 60 seconds
        withAnimation {
            isUrgent = remainingSeconds > 0 && remainingSeconds < 60
        }

        // Haptic feedback at key moments
        if remainingSeconds == 60 || remainingSeconds == 30 || remainingSeconds == 10 {
            HapticManager.shared.playNotification(type: .warning)
        } else if remainingSeconds == 0 {
            HapticManager.shared.playNotification(type: .error)
        }
    }
}

// MARK: - Compact Countdown Timer
/// A smaller version of the countdown timer for embedding in navigation bars
struct CompactCountdownTimer: View {
    let endTime: Date?

    @State private var remainingSeconds: Int = 0
    @State private var isUrgent: Bool = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: ParliamentSpacing.xs) {
            Image(systemName: isUrgent ? "hourglass.bottomhalf.filled" : "clock")
                .font(.system(size: 12))
                .foregroundColor(isUrgent ? .red : .parliamentGold)

            Text(formattedTime)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(isUrgent ? .red : .parliamentTextPrimary)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, ParliamentSpacing.sm)
        .padding(.vertical, ParliamentSpacing.xs)
        .background(
            Capsule()
                .fill(Color.parliamentCardBackground)
                .overlay(
                    Capsule()
                        .stroke(
                            isUrgent ? Color.red.opacity(0.5) : Color.parliamentGold.opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
        .onReceive(timer) { _ in
            updateRemainingTime()
        }
        .onAppear {
            updateRemainingTime()
        }
        .onChange(of: endTime) { _, _ in
            updateRemainingTime()
        }
    }

    private var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func updateRemainingTime() {
        guard let endTime = endTime else {
            remainingSeconds = 0
            isUrgent = false
            return
        }

        let remaining = endTime.timeIntervalSinceNow
        remainingSeconds = max(0, Int(remaining))

        withAnimation {
            isUrgent = remainingSeconds > 0 && remainingSeconds < 60
        }
    }
}

// MARK: - Preview
#Preview("Phase Progress") {
    ZStack {
        Color.parliamentBackground.ignoresSafeArea()

        VStack(spacing: 24) {
            PhaseProgressBar(currentPhase: .debate)

            PhaseProgressBar(currentPhase: .voteRound1)

            PhaseProgressBar(currentPhase: .reveal)
        }
        .padding()
    }
}

#Preview("Countdown Timer") {
    ZStack {
        Color.parliamentBackground.ignoresSafeArea()

        VStack(spacing: 24) {
            CountdownTimerView(
                endTime: Date().addingTimeInterval(125),
                phaseName: "開場陳述"
            )

            CountdownTimerView(
                endTime: Date().addingTimeInterval(45),
                phaseName: "第一輪投票"
            )

            CompactCountdownTimer(endTime: Date().addingTimeInterval(300))
        }
        .padding()
    }
}
