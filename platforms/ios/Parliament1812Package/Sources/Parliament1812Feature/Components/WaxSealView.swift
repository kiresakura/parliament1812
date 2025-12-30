import SwiftUI

/// 封蠟印章動畫元件 - 用於角色揭示
struct WaxSealView: View {
    @Binding var isRevealed: Bool
    var onReveal: (() -> Void)?

    @State private var sealScale: CGFloat = 1.0
    @State private var sealRotation: Double = 0
    @State private var crackOpacity: Double = 0
    @State private var glowIntensity: Double = 0.3
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Glow effect behind seal
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.parliamentGold.opacity(glowIntensity),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .blur(radius: 20)

            // Main seal
            ZStack {
                // Outer ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.parliamentBurgundy,
                                Color.parliamentBurgundy.opacity(0.8),
                                Color(red: 0.3, green: 0.1, blue: 0.1)
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)
                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)

                // Inner decorative ring
                Circle()
                    .stroke(Color.parliamentGold.opacity(0.6), lineWidth: 2)
                    .frame(width: 110, height: 110)

                // Crown emblem
                Image(systemName: "crown.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.parliamentGold, Color.parliamentBronze],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)

                // Decorative dots around crown
                ForEach(0..<8, id: \.self) { index in
                    Circle()
                        .fill(Color.parliamentGold.opacity(0.5))
                        .frame(width: 6, height: 6)
                        .offset(y: -45)
                        .rotationEffect(.degrees(Double(index) * 45))
                }

                // Crack overlay (appears when tapped)
                if crackOpacity > 0 {
                    CrackPattern()
                        .stroke(Color.black.opacity(crackOpacity), lineWidth: 2)
                        .frame(width: 120, height: 120)
                }
            }
            .scaleEffect(sealScale)
            .rotationEffect(.degrees(sealRotation))

            // Tap instruction
            if !isRevealed && !isAnimating {
                VStack {
                    Spacer()
                        .frame(height: 180)
                    Text("點擊揭開封印")
                        .font(.system(size: 14, weight: .medium, design: .serif))
                        .foregroundColor(.parliamentGold)
                        .opacity(0.8)
                }
            }
        }
        .onTapGesture {
            guard !isRevealed && !isAnimating else { return }
            breakSeal()
        }
        .onAppear {
            startIdleAnimation()
        }
    }

    private func startIdleAnimation() {
        // Subtle pulsing glow
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowIntensity = 0.5
        }
    }

    private func breakSeal() {
        isAnimating = true

        // Phase 1: Shake
        withAnimation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true)) {
            sealRotation = 5
        }

        // Phase 2: Cracks appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeIn(duration: 0.2)) {
                crackOpacity = 0.8
            }
        }

        // Phase 3: Break apart
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                sealScale = 1.3
                sealRotation = 15
            }

            withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
                sealScale = 0
                crackOpacity = 0
            }
        }

        // Complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isRevealed = true
            onReveal?()
        }
    }
}

/// 裂紋圖案
struct CrackPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)

        // Create random-looking cracks from center
        let crackLines: [(CGFloat, CGFloat)] = [
            (0, -50), (30, -40), (-25, -45),
            (45, 10), (-50, 5),
            (20, 45), (-30, 40), (0, 50)
        ]

        for (dx, dy) in crackLines {
            path.move(to: center)
            path.addLine(to: CGPoint(x: center.x + dx, y: center.y + dy))
        }

        return path
    }
}

/// 封蠟印章揭示容器
struct WaxSealRevealView<Content: View>: View {
    @State private var isRevealed = false
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            // Hidden content (revealed after seal breaks)
            content
                .opacity(isRevealed ? 1 : 0)
                .scaleEffect(isRevealed ? 1 : 0.8)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isRevealed)

            // Wax seal overlay
            if !isRevealed {
                WaxSealView(isRevealed: $isRevealed)
            }
        }
    }
}

#Preview("Wax Seal") {
    ZStack {
        Color.parliamentBackground.ignoresSafeArea()

        WaxSealRevealView {
            VStack(spacing: 16) {
                Text("🎭")
                    .font(.system(size: 60))
                Text("斯賓塞·珀西瓦爾")
                    .font(.parliamentTitle)
                    .foregroundColor(.parliamentTextPrimary)
                Text("首相 / 托利黨")
                    .font(.parliamentBody)
                    .foregroundColor(.parliamentGold)
            }
            .padding(40)
            .background(Color.parliamentCardBackground)
            .cornerRadius(ParliamentRadius.large)
        }
    }
}
