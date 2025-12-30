import SwiftUI

// MARK: - Paper Surface Modifier
struct PaperSurface: ViewModifier {
    var withBorder: Bool = true

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    Color.parliamentParchment

                    // Texture simulation (using random opacity noise would be ideal, but for now just a color blend)
                    Color.parliamentWood.opacity(0.05)
                        .blendMode(.multiply)
                }
            )
            .overlay(
                Group {
                    if withBorder {
                        RoundedRectangle(cornerRadius: 0)
                            .strokeBorder(Color.parliamentGold.opacity(0.3), lineWidth: 1)
                    }
                }
            )
    }
}

extension View {
    func paperSurface(withBorder: Bool = true) -> some View {
        modifier(PaperSurface(withBorder: withBorder))
    }
}

// MARK: - Fog of War Overlay
struct FogOfWarOverlay<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            // Background Layer
            content

            // Fog Layer
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    let width = size.width
                    let height = size.height

                    // Draw drifting cloud-like shapes
                    let cloudColor = Color.black.opacity(0.4)

                    // Simple drifting circles for "fog"
                    for i in 0..<8 {
                        let speed = Double(10 + i * 5)
                        let x = (time * speed).truncatingRemainder(dividingBy: width + 200) - 100
                        let yOffset = sin(time * 0.5 + Double(i)) * 50

                        let y = height * (0.2 + 0.1 * Double(i)) + yOffset
                        let scale = 1.0 + Double(i % 3) * 0.5

                        context.drawLayer { ctx in
                            ctx.opacity = 0.3
                            ctx.fill(
                                Path(
                                    ellipseIn: CGRect(
                                        x: x, y: y, width: 150 * scale, height: 100 * scale)),
                                with: .color(cloudColor)
                            )
                        }
                    }
                }
                .blur(radius: 30)  // Soften everything into fog
            }
            .allowsHitTesting(false)

            // Vignette
            RadialGradient(
                colors: [.clear, .black.opacity(0.7)],
                center: .center,
                startRadius: 200,
                endRadius: 600
            )
            .allowsHitTesting(false)
            .ignoresSafeArea()
        }
    }
}

// MARK: - Pointy Hexagon Shape (matches VictorianOvalFrame geometry)
struct PointyHexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midX = rect.midX
        let midY = rect.midY
        let radiusX = width / 2.0
        let radiusY = height / 2.0

        // Pointy-top hexagon: start at top (angle = Pi/3 * i - Pi/2)
        for i in 0..<6 {
            let angle = Double.pi / 3.0 * Double(i) - Double.pi / 2.0
            let x = midX + radiusX * cos(angle)
            let y = midY + radiusY * sin(angle)

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Victorian Oval Frame
struct VictorianOvalFrame: View {
    var size: CGSize

    var body: some View {
        ZStack {
            // Drop Shadow
            hexPath(size: size, inset: 2)
                .stroke(Color.black.opacity(0.5), lineWidth: 4)
                .offset(x: 2, y: 3)
                .blur(radius: 2)

            // Metallic Gradient Stroke
            hexPath(size: size)
                .stroke(
                    Color.goldMetallicGradient,
                    lineWidth: 5
                )

            // Inner Hairline
            hexPath(size: size, inset: 6)
                .stroke(
                    LinearGradient(
                        colors: [.parliamentGold, .white.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )

            // Corner Rivets (Approximated at points)
            ForEach(0..<6) { i in
                let point = hexPoint(index: i, size: size)
                Circle()
                    .fill(Color.goldMetallicGradient)
                    .frame(width: 6, height: 6)
                    .position(point)
                    .shadow(radius: 1)
            }
        }
    }

    private func hexPath(size: CGSize, inset: CGFloat = 0) -> Path {
        var path = Path()
        let width = size.width - inset * 2
        let height = size.height - inset * 2
        let xOff = inset
        let yOff = inset
        let midX = width / 2 + xOff
        let midY = height / 2 + yOff

        for i in 0..<6 {
            let point = hexPoint(
                index: i, size: CGSize(width: width, height: height),
                offset: CGPoint(x: midX, y: midY))
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }

    private func hexPoint(index: Int, size: CGSize, offset: CGPoint? = nil) -> CGPoint {
        // Pointy topped hexagon? No, waiting room had Flat top in reference but let's match Android's pointy top if possible.
        // Android code: "Pointy-top hexagon: start at top" (angle = Pi/3 * i - Pi/2)
        // Let's match that.
        let angle = Double.pi / 3.0 * Double(index) - Double.pi / 2.0
        let radiusX = size.width / 2.0
        let radiusY = size.height / 2.0

        // If offset provided use it, else calculate center based on size
        let midX = offset?.x ?? size.width / 2.0
        let midY = offset?.y ?? size.height / 2.0

        return CGPoint(
            x: midX + radiusX * cos(angle),
            y: midY + radiusY * sin(angle)
        )
    }
}

// MARK: - Victorian Oval Player Card
struct VictorianOvalPlayerCard: View {
    let nickname: String
    let roleType: String?  // "worker", "factory", etc
    let isHost: Bool
    let isReady: Bool
    let isCurrentUser: Bool

    // Consistent sizes for proper centering
    private let portraitWidth: CGFloat = 70
    private let portraitHeight: CGFloat = 85
    private let frameWidth: CGFloat = 80
    private let frameHeight: CGFloat = 98

    var body: some View {
        VStack(spacing: 8) {
            // Portrait Frame - centered in container
            ZStack {
                // Portrait Content - centered
                if let role = roleType {
                    // Using role type string to load image
                    Image(role)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: portraitWidth, height: portraitHeight)
                        .clipShape(PointyHexagonShape())
                } else {
                    // Initial - show first letter of nickname, centered
                    ZStack {
                        Color.black
                        Text(nickname.prefix(1).uppercased())
                            .font(.system(size: 32, weight: .bold, design: .serif))
                            .foregroundColor(.parliamentGold)
                    }
                    .frame(width: portraitWidth, height: portraitHeight)
                    .clipShape(PointyHexagonShape())
                }

                // Frame - overlay centered on portrait with explicit frame
                VictorianOvalFrame(size: CGSize(width: frameWidth, height: frameHeight))
                    .frame(width: frameWidth, height: frameHeight)

                // HOST Crown
                if isHost {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.parliamentGold)
                        .padding(4)
                        .background(Color.black.opacity(0.7).clipShape(Circle()))
                        .offset(y: -frameHeight / 2 - 5)
                }
            }
            .frame(width: frameWidth, height: frameHeight)

            // Text Info
            VStack(spacing: 2) {
                Text(nickname)
                    .font(.custom("Songti TC", size: 14).weight(.semibold))
                    .foregroundColor(.parliamentTextPrimary)
                    .lineLimit(1)

                // Status Badge (Text only version, no checkmark overlay)
                if isReady {
                    Text("已就緒")
                        .font(.custom("Songti TC", size: 10))
                        .foregroundColor(.parliamentBackground)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.green))
                } else if roleType != nil {
                    Text("待就緒")
                        .font(.custom("Songti TC", size: 10))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.orange))
                } else {
                    Text("等待選角")
                        .font(.custom("Songti TC", size: 10))
                        .foregroundColor(.parliamentTextMuted)
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.parliamentCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            isCurrentUser
                                ? Color.parliamentGold.opacity(0.8)
                                : Color.parliamentGold.opacity(0.2),
                            lineWidth: isCurrentUser ? 2 : 1
                        )
                )
        )
    }
}
