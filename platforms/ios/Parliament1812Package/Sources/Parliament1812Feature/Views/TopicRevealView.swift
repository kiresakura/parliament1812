import SwiftUI

/// 議題揭示畫面 - 展示本場辯論的核心議題
struct TopicRevealView: View {
    let topic: DebateTopic
    var onContinue: (() -> Void)?

    @State private var isRevealed = false
    @State private var titleOpacity: Double = 0
    @State private var descriptionOpacity: Double = 0
    @State private var optionsOpacity: Double = 0
    @State private var decorOpacity: Double = 0

    var body: some View {
        ZStack {
            // Background
            Color.parliamentBackground
                .ignoresSafeArea()

            // Hexagonal pattern overlay
            HexagonalBackground()
                .opacity(0.15)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Wax seal reveal
                WaxSealRevealView {
                    topicContent
                }

                Spacer()

                // Continue button (appears after reveal)
                if isRevealed {
                    continueButton
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding()
        }
        .onChange(of: isRevealed) { _, revealed in
            if revealed {
                animateContent()
            }
        }
    }

    // MARK: - Topic Content
    private var topicContent: some View {
        VStack(spacing: ParliamentSpacing.lg) {
            // Header decoration
            VStack(spacing: ParliamentSpacing.xs) {
                Text("本日議題")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.parliamentTextMuted)
                    .tracking(4)

                Text("TODAY'S DEBATE")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.parliamentTextMuted.opacity(0.6))
                    .tracking(2)
            }
            .opacity(decorOpacity)

            VictorianDivider()
                .opacity(decorOpacity)

            // Topic title
            VStack(spacing: ParliamentSpacing.sm) {
                Text(topic.title)
                    .font(.parliamentTitle)
                    .foregroundColor(.parliamentTextPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(titleOpacity)

                Text(topic.englishTitle)
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundColor(.parliamentGold)
                    .italic()
                    .opacity(titleOpacity)
            }

            // Topic description
            Text(topic.description)
                .font(.parliamentBody)
                .foregroundColor(.parliamentTextSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, ParliamentSpacing.md)
                .opacity(descriptionOpacity)

            VictorianDivider()
                .opacity(decorOpacity)

            // Voting options preview
            VStack(spacing: ParliamentSpacing.sm) {
                Text("投票選項")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.parliamentTextMuted)
                    .tracking(2)

                VStack(spacing: ParliamentSpacing.xs) {
                    ForEach(topic.options) { option in
                        TopicOptionRow(option: option)
                    }
                }
            }
            .opacity(optionsOpacity)
        }
        .padding(ParliamentSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: ParliamentRadius.large)
                .fill(Color.parliamentCardBackground)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ParliamentRadius.large)
                .stroke(Color.parliamentGold.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            // Trigger reveal animation after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isRevealed = true
            }
        }
    }

    // MARK: - Topic Option Row
    private struct TopicOptionRow: View {
        let option: VoteOption

        var body: some View {
            HStack(spacing: ParliamentSpacing.sm) {
                // Option letter badge
                Text(option.letter)
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundColor(.parliamentParchment)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.parliamentBurgundy, Color.parliamentBurgundy.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )

                // Option text
                Text(option.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.parliamentTextSecondary)

                Spacer()
            }
            .padding(.horizontal, ParliamentSpacing.sm)
            .padding(.vertical, ParliamentSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: ParliamentRadius.small)
                    .fill(Color.parliamentWood.opacity(0.2))
            )
        }
    }

    // MARK: - Continue Button
    private var continueButton: some View {
        Button {
            onContinue?()
        } label: {
            HStack(spacing: ParliamentSpacing.sm) {
                Text("進入辯論")
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .semibold))
            }
        }
        .buttonStyle(Civ6ButtonStyle(isEnabled: true))
        .padding(.bottom, ParliamentSpacing.xl)
    }

    // MARK: - Animation
    private func animateContent() {
        // Staggered reveal animation
        withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
            decorOpacity = 1
        }

        withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
            titleOpacity = 1
        }

        withAnimation(.easeOut(duration: 0.6).delay(0.6)) {
            descriptionOpacity = 1
        }

        withAnimation(.easeOut(duration: 0.6).delay(0.9)) {
            optionsOpacity = 1
        }
    }
}

// MARK: - Data Models

/// 辯論議題
struct DebateTopic: Identifiable {
    let id: String
    let title: String
    let englishTitle: String
    let description: String
    let options: [VoteOption]
}

// VoteOption is defined in VotingModels.swift

// MARK: - Hexagonal Background Pattern

struct HexagonalBackground: View {
    let hexSize: CGFloat = 40

    var body: some View {
        GeometryReader { geometry in
            let columns = Int(geometry.size.width / (hexSize * 1.5)) + 2
            let rows = Int(geometry.size.height / (hexSize * 0.866)) + 2

            Canvas { context, size in
                for row in 0..<rows {
                    for col in 0..<columns {
                        let offset = row.isMultiple(of: 2) ? 0 : hexSize * 0.75
                        let x = CGFloat(col) * hexSize * 1.5 + offset
                        let y = CGFloat(row) * hexSize * 0.866

                        let hexPath = createHexagonPath(
                            center: CGPoint(x: x, y: y),
                            size: hexSize * 0.45
                        )

                        context.stroke(
                            hexPath,
                            with: .color(Color.parliamentGold.opacity(0.3)),
                            lineWidth: 0.5
                        )
                    }
                }
            }
        }
    }

    private func createHexagonPath(center: CGPoint, size: CGFloat) -> Path {
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
}

// MARK: - Preview

#Preview("Topic Reveal") {
    TopicRevealView(
        topic: DebateTopic(
            id: "machine_question",
            title: "機器問題",
            englishTitle: "The Machine Question",
            description: "隨著工業革命的推進，機器正在取代傳統手工業者。國會必須決定：我們應該如何回應這場變革？",
            options: [
                VoteOption(id: "A", letter: "A", title: "禁止機器", description: "立法禁止工廠使用省力機器"),
                VoteOption(id: "B", letter: "B", title: "保護財產", description: "嚴厲打擊破壞機器的暴民"),
                VoteOption(id: "C", letter: "C", title: "折衷改革", description: "允許機器但立法保障工人權益")
            ]
        )
    )
}
