import SwiftUI

// MARK: - Dice Roll View
/// Displays an animated dice roll for international events (Phase 7)
/// A roll of ≥4 triggers the international event
struct DiceRollView: View {
    let diceValue: Int
    let threshold: Int
    let triggered: Bool
    let onComplete: (() -> Void)?

    @State private var isRolling: Bool = true
    @State private var displayValue: Int = 1
    @State private var rotation: Double = 0
    @State private var scale: Double = 0.5
    @State private var showResult: Bool = false

    private let rollDuration: Double = 2.0

    init(
        diceValue: Int,
        threshold: Int = 4,
        triggered: Bool? = nil,
        onComplete: (() -> Void)? = nil
    ) {
        self.diceValue = diceValue
        self.threshold = threshold
        self.triggered = triggered ?? (diceValue >= threshold)
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(spacing: ParliamentSpacing.lg) {
            // Header
            Text("國際情勢")
                .font(.custom("Songti TC", size: 24).weight(.bold))
                .foregroundColor(.parliamentGold)

            Text("INTERNATIONAL AFFAIRS")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.parliamentTextMuted)
                .tracking(2)

            Spacer().frame(height: ParliamentSpacing.md)

            // Dice container
            ZStack {
                // Glow effect when result shows
                if showResult {
                    Circle()
                        .fill(
                            triggered
                                ? Color.parliamentGold.opacity(0.3)
                                : Color.parliamentTextMuted.opacity(0.2)
                        )
                        .frame(width: 180, height: 180)
                        .blur(radius: 30)
                }

                // Dice
                DiceFace(value: displayValue)
                    .frame(width: 120, height: 120)
                    .rotation3DEffect(
                        .degrees(rotation),
                        axis: (x: 1, y: 1, z: 0)
                    )
                    .scaleEffect(scale)
                    .shadow(
                        color: showResult && triggered
                            ? .parliamentGold.opacity(0.5)
                            : .black.opacity(0.3),
                        radius: showResult ? 20 : 10
                    )
            }
            .frame(height: 200)

            Spacer().frame(height: ParliamentSpacing.md)

            // Result text
            if showResult {
                VStack(spacing: ParliamentSpacing.sm) {
                    HStack(spacing: ParliamentSpacing.sm) {
                        Text("擲出")
                            .font(.custom("Songti TC", size: 18))
                            .foregroundColor(.parliamentTextSecondary)

                        Text("\(diceValue)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(triggered ? .parliamentGold : .parliamentTextPrimary)

                        Text("點")
                            .font(.custom("Songti TC", size: 18))
                            .foregroundColor(.parliamentTextSecondary)
                    }

                    Text(triggered ? "國際事件觸發！" : "風平浪靜")
                        .font(.custom("Songti TC", size: 20).weight(.semibold))
                        .foregroundColor(triggered ? .parliamentGold : .parliamentTextMuted)
                        .padding(.top, ParliamentSpacing.xs)

                    Text(triggered ? "INTERNATIONAL EVENT TRIGGERED" : "NO INTERNATIONAL EVENT")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.parliamentTextMuted)
                        .tracking(1)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            } else {
                // Rolling indicator
                Text("擲骰中...")
                    .font(.custom("Songti TC", size: 18))
                    .foregroundColor(.parliamentTextMuted)
            }

            Spacer().frame(height: ParliamentSpacing.lg)

            // Threshold indicator
            HStack(spacing: ParliamentSpacing.sm) {
                ForEach(1...6, id: \.self) { value in
                    ThresholdDot(
                        value: value,
                        threshold: threshold,
                        currentValue: showResult ? diceValue : nil
                    )
                }
            }
            .padding(.horizontal, ParliamentSpacing.lg)

            Text("≥ \(threshold) 觸發國際事件")
                .font(.system(size: 12))
                .foregroundColor(.parliamentTextMuted)
        }
        .padding(ParliamentSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: ParliamentRadius.large)
                .fill(Color.parliamentCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: ParliamentRadius.large)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.parliamentGold.opacity(0.5),
                                    Color.parliamentGold.opacity(0.2),
                                    Color.parliamentGold.opacity(0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .onAppear {
            startRolling()
        }
    }

    private func startRolling() {
        // Initial scale animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            scale = 1.0
        }

        // Rolling animation
        let rollCount = 15
        let rollInterval = rollDuration / Double(rollCount)

        for i in 0..<rollCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + rollInterval * Double(i)) {
                if i < rollCount - 1 {
                    // Random values during roll
                    displayValue = Int.random(in: 1...6)

                    // Rotation animation
                    withAnimation(.easeInOut(duration: rollInterval)) {
                        rotation += 90
                    }

                    // Haptic for each roll
                    if i % 3 == 0 {
                        HapticManager.shared.playImpact()
                    }
                } else {
                    // Final value
                    displayValue = diceValue

                    withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                        rotation = 0
                    }

                    // Show result after brief pause
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeOut(duration: 0.5)) {
                            isRolling = false
                            showResult = true
                        }

                        // Final haptic
                        if triggered {
                            HapticManager.shared.playNotification(type: .success)
                        } else {
                            HapticManager.shared.playImpact()
                        }

                        // Callback
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            onComplete?()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Dice Face
/// Renders a single face of the dice with Victorian styling
struct DiceFace: View {
    let value: Int

    var body: some View {
        ZStack {
            // Dice background
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.93, blue: 0.88),
                            Color(red: 0.85, green: 0.82, blue: 0.75)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.parliamentGold.opacity(0.5), lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.2), radius: 4, x: 2, y: 2)

            // Pips
            DicePips(value: value)
                .padding(16)
        }
    }
}

// MARK: - Dice Pips
/// Renders the dots/pips on the dice face
struct DicePips: View {
    let value: Int

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let pipSize: CGFloat = size.width * 0.18
            let spacing = size.width * 0.28

            ZStack {
                switch value {
                case 1:
                    Pip(size: pipSize)
                        .position(x: size.width / 2, y: size.height / 2)

                case 2:
                    Pip(size: pipSize)
                        .position(x: size.width / 2 - spacing, y: size.height / 2 - spacing)
                    Pip(size: pipSize)
                        .position(x: size.width / 2 + spacing, y: size.height / 2 + spacing)

                case 3:
                    Pip(size: pipSize)
                        .position(x: size.width / 2 - spacing, y: size.height / 2 - spacing)
                    Pip(size: pipSize)
                        .position(x: size.width / 2, y: size.height / 2)
                    Pip(size: pipSize)
                        .position(x: size.width / 2 + spacing, y: size.height / 2 + spacing)

                case 4:
                    Pip(size: pipSize)
                        .position(x: size.width / 2 - spacing, y: size.height / 2 - spacing)
                    Pip(size: pipSize)
                        .position(x: size.width / 2 + spacing, y: size.height / 2 - spacing)
                    Pip(size: pipSize)
                        .position(x: size.width / 2 - spacing, y: size.height / 2 + spacing)
                    Pip(size: pipSize)
                        .position(x: size.width / 2 + spacing, y: size.height / 2 + spacing)

                case 5:
                    Pip(size: pipSize)
                        .position(x: size.width / 2 - spacing, y: size.height / 2 - spacing)
                    Pip(size: pipSize)
                        .position(x: size.width / 2 + spacing, y: size.height / 2 - spacing)
                    Pip(size: pipSize)
                        .position(x: size.width / 2, y: size.height / 2)
                    Pip(size: pipSize)
                        .position(x: size.width / 2 - spacing, y: size.height / 2 + spacing)
                    Pip(size: pipSize)
                        .position(x: size.width / 2 + spacing, y: size.height / 2 + spacing)

                case 6:
                    Pip(size: pipSize)
                        .position(x: size.width / 2 - spacing, y: size.height / 2 - spacing)
                    Pip(size: pipSize)
                        .position(x: size.width / 2 + spacing, y: size.height / 2 - spacing)
                    Pip(size: pipSize)
                        .position(x: size.width / 2 - spacing, y: size.height / 2)
                    Pip(size: pipSize)
                        .position(x: size.width / 2 + spacing, y: size.height / 2)
                    Pip(size: pipSize)
                        .position(x: size.width / 2 - spacing, y: size.height / 2 + spacing)
                    Pip(size: pipSize)
                        .position(x: size.width / 2 + spacing, y: size.height / 2 + spacing)

                default:
                    EmptyView()
                }
            }
        }
    }
}

// MARK: - Pip
/// A single dot on the dice
struct Pip: View {
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(Color.parliamentOil)
            .frame(width: size, height: size)
            .shadow(color: .black.opacity(0.3), radius: 1, x: 1, y: 1)
    }
}

// MARK: - Threshold Dot
/// Shows the threshold indicator for dice values
struct ThresholdDot: View {
    let value: Int
    let threshold: Int
    let currentValue: Int?

    private var isAboveThreshold: Bool {
        value >= threshold
    }

    private var isCurrentValue: Bool {
        currentValue == value
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(
                        isAboveThreshold
                            ? Color.parliamentGold.opacity(0.3)
                            : Color.parliamentShadow
                    )
                    .frame(width: 32, height: 32)

                if isCurrentValue {
                    Circle()
                        .stroke(Color.parliamentGold, lineWidth: 3)
                        .frame(width: 36, height: 36)
                }

                Text("\(value)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(
                        isAboveThreshold
                            ? .parliamentGold
                            : .parliamentTextMuted
                    )
            }

            if value == threshold {
                Image(systemName: "chevron.up")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.parliamentGold)
            }
        }
    }
}

// MARK: - Compact Dice Result
/// A smaller version for showing dice results in lists or summaries
struct CompactDiceResult: View {
    let value: Int
    let triggered: Bool

    var body: some View {
        HStack(spacing: ParliamentSpacing.sm) {
            // Mini dice
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(white: 0.9))
                    .frame(width: 28, height: 28)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.parliamentGold.opacity(0.5), lineWidth: 1)
                    )

                Text("\(value)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.parliamentOil)
            }

            // Result indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(triggered ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)

                Text(triggered ? "觸發" : "未觸發")
                    .font(.system(size: 12))
                    .foregroundColor(triggered ? .parliamentGold : .parliamentTextMuted)
            }
        }
        .padding(.horizontal, ParliamentSpacing.sm)
        .padding(.vertical, ParliamentSpacing.xs)
        .background(
            Capsule()
                .fill(Color.parliamentCardBackground)
                .overlay(
                    Capsule()
                        .stroke(Color.parliamentGold.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview
#Preview("Dice Roll - Triggered") {
    ZStack {
        Color.parliamentBackground.ignoresSafeArea()

        DiceRollView(diceValue: 5, threshold: 4, triggered: true)
            .padding()
    }
}

#Preview("Dice Roll - Not Triggered") {
    ZStack {
        Color.parliamentBackground.ignoresSafeArea()

        DiceRollView(diceValue: 2, threshold: 4, triggered: false)
            .padding()
    }
}

#Preview("Compact Results") {
    ZStack {
        Color.parliamentBackground.ignoresSafeArea()

        VStack(spacing: 16) {
            CompactDiceResult(value: 6, triggered: true)
            CompactDiceResult(value: 3, triggered: false)
            CompactDiceResult(value: 4, triggered: true)
        }
    }
}
