import SwiftUI

// MARK: - Design System for 1812 Parliament Game
// Based on Figma design: Regency Era aesthetic

// MARK: - Color Palette (Based on Figma Design)
extension Color {
    /// Primary gold/amber color for accents and highlights - Old Gold #D4AF37
    static let parliamentGold = Color(red: 0.831, green: 0.686, blue: 0.216)  // #D4AF37

    /// Darker gold for pressed states
    static let parliamentGoldDark = Color(red: 0.722, green: 0.580, blue: 0.122)  // #B8941F

    /// Light gold for subtle highlights
    static let parliamentGoldLight = Color(red: 0.902, green: 0.800, blue: 0.400)  // #E6CC66

    /// Deep background color - Dark #1A1614
    static let parliamentBackground = Color(red: 0.102, green: 0.086, blue: 0.078)  // #1A1614

    /// Card/Panel background - Oil #241B14 with transparency
    static let parliamentCardBackground = Color(red: 0.141, green: 0.106, blue: 0.078).opacity(0.95)  // #241B14

    /// Text colors
    static let parliamentTextPrimary = Color.white
    static let parliamentTextSecondary = Color(red: 0.722, green: 0.627, blue: 0.494)  // #B8A07E - Mongoose
    static let parliamentTextMuted = Color(red: 0.545, green: 0.467, blue: 0.325)  // #8B7753 - Shadow

    /// Overlay for background image
    static let parliamentOverlay = Color.black.opacity(0.55)

    // MARK: - Figma Design Extended Palette

    /// Mongoose tan color for secondary text
    static let parliamentMongoose = Color(red: 0.722, green: 0.627, blue: 0.494)  // #B8A07E

    /// Shadow brown for muted elements
    static let parliamentShadow = Color(red: 0.545, green: 0.467, blue: 0.325)  // #8B7753

    /// Mirage dark blue for button backgrounds
    static let parliamentMirage = Color(red: 0.102, green: 0.102, blue: 0.180)  // #1A1A2E

    /// Oil color for panel backgrounds
    static let parliamentOil = Color(red: 0.141, green: 0.106, blue: 0.078)  // #241B14

    /// Gray for placeholder text
    static let parliamentGray = Color(red: 0.545, green: 0.545, blue: 0.545)  // #8B8B8B

    /// Victorian burgundy/wine red
    static let parliamentBurgundy = Color(red: 0.45, green: 0.15, blue: 0.18)  // #722830

    /// Bronze metallic accent
    static let parliamentBronze = Color(red: 0.55, green: 0.42, blue: 0.25)  // #8C6B40

    /// Sepia tone for aged paper feel
    static let parliamentSepia = Color(red: 0.44, green: 0.36, blue: 0.26)  // #705C42

    /// Cream/parchment color
    static let parliamentParchment = Color(red: 0.96, green: 0.93, blue: 0.85)  // #F5EDD9

    /// Dark wood color
    static let parliamentWood = Color(red: 0.25, green: 0.18, blue: 0.12)  // #402E1F

    /// British racing green (for accents)
    static let parliamentGreen = Color(red: 0.15, green: 0.30, blue: 0.20)  // #264D33

    // MARK: - Refined Victorian Palette (Matching Android)
    static let victorianRed = Color(hex: 0x722830)  // Burgundy
    static let victorianGreen = Color(hex: 0x264D33)  // British Racing Green
    static let victorianBlue = Color(hex: 0x002366)  // Royal Navy Blue

    // Parchment / Paper
    static let parchment = Color(hex: 0xF5EDD9)
    static let parchmentDark = Color(hex: 0xE6DCC3)

    // Metallic Gold Gradients
    static let metallicGoldStop1 = Color(hex: 0xBF953F)
    static let metallicGoldStop2 = Color(hex: 0xFCF6BA)
    static let metallicGoldStop3 = Color(hex: 0xB38728)
    static let metallicGoldStop4 = Color(hex: 0xFBF5B7)
    static let metallicGoldStop5 = Color(hex: 0xAA771C)

    /// Helper for Metallic Gradient
    static var goldMetallicGradient: LinearGradient {
        LinearGradient(
            colors: [
                metallicGoldStop1,
                metallicGoldStop2,
                metallicGoldStop3,
                metallicGoldStop4,
                metallicGoldStop5,
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}

// MARK: - Typography
// 使用 iOS 內建的商業可用字體
// - Songti TC (明體): 傳統繁體中文印刷字體，適合歷史主題
// - 全部中文字體統一使用宋體增加歷史感
extension Font {
    /// Large title font for "1812" - 使用襯線字體增加歷史感
    static let parliamentHeroTitle = Font.custom("Georgia", size: 72).weight(.light)

    /// Main title font for "國會風雲" - 使用明體增加古典風味
    static let parliamentTitle = Font.custom("Songti TC", size: 28).weight(.semibold)

    /// Subtitle font - 中文副標題
    static let parliamentSubtitle = Font.custom("Songti TC", size: 14)

    /// Tab label font - 標籤使用明體
    static let parliamentTabLabel = Font.custom("Songti TC", size: 16).weight(.medium)

    /// Tab sublabel font
    static let parliamentTabSublabel = Font.custom("Songti TC", size: 11)

    /// Input label font
    static let parliamentInputLabel = Font.custom("Songti TC", size: 13)

    /// Button font - 按鈕使用明體
    static let parliamentButton = Font.custom("Songti TC", size: 16).weight(.semibold)

    /// Body text
    static let parliamentBody = Font.custom("Songti TC", size: 15)

    /// Caption/Quote font - 引言使用明體
    static let parliamentQuote = Font.custom("Songti TC", size: 12)

    /// Header brand font
    static let parliamentBrand = Font.custom("Songti TC", size: 12).weight(.semibold)

    /// Civ6 style header font - 大標題
    static let civ6Header = Font.custom("Georgia", size: 18).weight(.bold)

    /// Civ6 style label font - 標籤使用明體
    static let civ6Label = Font.custom("Songti TC", size: 11).weight(.medium)
}

// MARK: - Spacing
enum ParliamentSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius
enum ParliamentRadius {
    static let small: CGFloat = 4
    static let medium: CGFloat = 8
    static let large: CGFloat = 12
}

// MARK: - Custom View Modifiers

/// Gold-accented text field style
struct ParliamentTextFieldStyle: ViewModifier {
    var isActive: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, ParliamentSpacing.md)
            .padding(.vertical, 14)
            .background(
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.parliamentGold)
                        .frame(width: 3)
                    Rectangle()
                        .fill(Color.black.opacity(0.5))
                }
            )
            .foregroundColor(.parliamentTextPrimary)
    }
}

/// Primary gold button style
struct ParliamentPrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.parliamentButton)
            .foregroundColor(.parliamentBackground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Group {
                    if isEnabled {
                        configuration.isPressed
                            ? Color.parliamentGoldDark
                            : Color.parliamentGold
                    } else {
                        Color.gray.opacity(0.3)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 2))
    }
}

/// Secondary/outline button style
struct ParliamentSecondaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.parliamentButton)
            .foregroundColor(isEnabled ? .parliamentGold : .parliamentTextMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(
                        isEnabled ? Color.parliamentGold : Color.parliamentTextMuted, lineWidth: 1)
            )
    }
}

// MARK: - View Extensions

extension View {
    func parliamentTextField(isActive: Bool = false) -> some View {
        modifier(ParliamentTextFieldStyle(isActive: isActive))
    }
}

// MARK: - Custom Components

/// Hexagonal badge with star icon
struct ParliamentBadge: View {
    var body: some View {
        ZStack {
            // Hexagon shape
            HexagonShape()
                .stroke(Color.parliamentGold, lineWidth: 2)
                .frame(width: 60, height: 52)

            // Inner hexagon
            HexagonShape()
                .stroke(Color.parliamentGold.opacity(0.5), lineWidth: 1)
                .frame(width: 50, height: 43)

            // Star icon
            Image(systemName: "star.fill")
                .font(.system(size: 20))
                .foregroundColor(.parliamentGold)
        }
    }
}

/// Hexagon shape
struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let centerX = rect.midX
        let centerY = rect.midY

        // Points for hexagon (flat top)
        let points: [CGPoint] = [
            CGPoint(x: centerX - width / 4, y: centerY - height / 2),
            CGPoint(x: centerX + width / 4, y: centerY - height / 2),
            CGPoint(x: centerX + width / 2, y: centerY),
            CGPoint(x: centerX + width / 4, y: centerY + height / 2),
            CGPoint(x: centerX - width / 4, y: centerY + height / 2),
            CGPoint(x: centerX - width / 2, y: centerY),
        ]

        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()

        return path
    }
}

/// Tab selector with gold underline
struct ParliamentTabSelector: View {
    @Binding var selectedTab: Int
    let tabs: [(chinese: String, english: String)]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: 4) {
                        VStack(spacing: 2) {
                            Text(tab.chinese)
                                .font(.parliamentTabLabel)
                            Text(tab.english)
                                .font(.parliamentTabSublabel)
                                .textCase(.uppercase)
                        }
                        .foregroundColor(
                            selectedTab == index ? .parliamentTextPrimary : .parliamentTextMuted)

                        // Gold underline indicator
                        Rectangle()
                            .fill(selectedTab == index ? Color.parliamentGold : Color.clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ParliamentSpacing.sm)
                }
            }
        }
    }
}

/// Input field with label
struct ParliamentInputField: View {
    let label: String
    let englishLabel: String
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: ParliamentSpacing.sm) {
            HStack(spacing: ParliamentSpacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundColor(.parliamentGold)
                }
                Text(label)
                    .font(.parliamentInputLabel)
                    .foregroundColor(.parliamentTextPrimary)
                Text(englishLabel)
                    .font(.parliamentInputLabel)
                    .foregroundColor(.parliamentTextMuted)
            }

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .parliamentTextField()
        }
    }
}

/// Quote footer
struct ParliamentQuoteFooter: View {
    let chineseQuote: String
    let englishQuote: String

    var body: some View {
        VStack(spacing: ParliamentSpacing.xs) {
            HStack {
                Image(systemName: "quote.opening")
                    .font(.system(size: 10))
                    .foregroundColor(.parliamentGold.opacity(0.6))
                Spacer()
            }

            Text(chineseQuote)
                .font(.parliamentQuote)
                .foregroundColor(.parliamentTextSecondary)
                .multilineTextAlignment(.center)

            Text(englishQuote)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(.parliamentTextMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, ParliamentSpacing.lg)
    }
}

/// Header with brand
struct ParliamentHeader: View {
    var body: some View {
        HStack {
            HStack(spacing: ParliamentSpacing.sm) {
                // Crown icon
                Image(systemName: "crown.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.parliamentGold)

                VStack(alignment: .leading, spacing: 0) {
                    Text("REGENCY ERA")
                        .font(.parliamentBrand)
                        .foregroundColor(.parliamentTextPrimary)
                    Text("1812 • British Parliament")
                        .font(.system(size: 9))
                        .foregroundColor(.parliamentTextMuted)
                }
            }

            Spacer()
        }
        .padding(.horizontal, ParliamentSpacing.md)
        .padding(.top, ParliamentSpacing.sm)
    }
}

// MARK: - Victorian Decorative Elements

/// Victorian-style flourish divider
struct VictorianDivider: View {
    var color: Color = .parliamentGold

    var body: some View {
        HStack(spacing: ParliamentSpacing.sm) {
            // Left flourish
            HStack(spacing: 2) {
                Circle()
                    .fill(color.opacity(0.5))
                    .frame(width: 4, height: 4)
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0), color.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
            }

            // Center ornament
            Image(systemName: "fleuron")
                .font(.system(size: 12))
                .foregroundColor(color)

            // Right flourish
            HStack(spacing: 2) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.6), color.opacity(0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                Circle()
                    .fill(color.opacity(0.5))
                    .frame(width: 4, height: 4)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

/// Victorian corner ornament shape
struct VictorianCorner: View {
    var position: CornerPosition = .topLeading
    var size: CGFloat = 24
    var color: Color = .parliamentGold

    enum CornerPosition {
        case topLeading, topTrailing, bottomLeading, bottomTrailing
    }

    var body: some View {
        Canvas { context, canvasSize in
            let strokeColor = color.resolve(in: .init())

            // Draw corner L-shape with decorative elements
            var path = Path()

            switch position {
            case .topLeading:
                path.move(to: CGPoint(x: 0, y: size * 0.8))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: size * 0.8, y: 0))
            case .topTrailing:
                path.move(to: CGPoint(x: size - size * 0.8, y: 0))
                path.addLine(to: CGPoint(x: size, y: 0))
                path.addLine(to: CGPoint(x: size, y: size * 0.8))
            case .bottomLeading:
                path.move(to: CGPoint(x: 0, y: size - size * 0.8))
                path.addLine(to: CGPoint(x: 0, y: size))
                path.addLine(to: CGPoint(x: size * 0.8, y: size))
            case .bottomTrailing:
                path.move(to: CGPoint(x: size, y: size - size * 0.8))
                path.addLine(to: CGPoint(x: size, y: size))
                path.addLine(to: CGPoint(x: size - size * 0.8, y: size))
            }

            context.stroke(
                path,
                with: .color(
                    Color(
                        red: Double(strokeColor.red),
                        green: Double(strokeColor.green),
                        blue: Double(strokeColor.blue))),
                lineWidth: 2
            )

            // Draw corner dot
            let dotPosition: CGPoint
            switch position {
            case .topLeading: dotPosition = CGPoint(x: 3, y: 3)
            case .topTrailing: dotPosition = CGPoint(x: size - 3, y: 3)
            case .bottomLeading: dotPosition = CGPoint(x: 3, y: size - 3)
            case .bottomTrailing: dotPosition = CGPoint(x: size - 3, y: size - 3)
            }

            context.fill(
                Path(
                    ellipseIn: CGRect(
                        x: dotPosition.x - 2, y: dotPosition.y - 2, width: 4, height: 4)),
                with: .color(
                    Color(
                        red: Double(strokeColor.red),
                        green: Double(strokeColor.green),
                        blue: Double(strokeColor.blue)))
            )
        }
        .frame(width: size, height: size)
    }
}

/// Victorian frame container with corner ornaments
struct VictorianFrame<Content: View>: View {
    let content: Content
    var cornerSize: CGFloat = 20
    var borderColor: Color = .parliamentGold

    init(
        cornerSize: CGFloat = 20, borderColor: Color = .parliamentGold,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerSize = cornerSize
        self.borderColor = borderColor
        self.content = content()
    }

    var body: some View {
        content
            .overlay(
                ZStack {
                    // Corner ornaments
                    VStack {
                        HStack {
                            VictorianCorner(
                                position: .topLeading, size: cornerSize, color: borderColor)
                            Spacer()
                            VictorianCorner(
                                position: .topTrailing, size: cornerSize, color: borderColor)
                        }
                        Spacer()
                        HStack {
                            VictorianCorner(
                                position: .bottomLeading, size: cornerSize, color: borderColor)
                            Spacer()
                            VictorianCorner(
                                position: .bottomTrailing, size: cornerSize, color: borderColor)
                        }
                    }

                    // Side lines connecting corners
                    GeometryReader { geo in
                        // Top line
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        borderColor.opacity(0), borderColor.opacity(0.4),
                                        borderColor.opacity(0),
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width - cornerSize * 2, height: 1)
                            .position(x: geo.size.width / 2, y: 0)

                        // Bottom line
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        borderColor.opacity(0), borderColor.opacity(0.4),
                                        borderColor.opacity(0),
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width - cornerSize * 2, height: 1)
                            .position(x: geo.size.width / 2, y: geo.size.height)
                    }
                }
            )
    }
}

/// Royal seal badge (enhanced version of ParliamentBadge)
struct RoyalSealBadge: View {
    var size: CGFloat = 80

    var body: some View {
        ZStack {
            // Outer decorative ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.parliamentGold.opacity(0.3),
                            Color.parliamentGold,
                            Color.parliamentGold.opacity(0.3),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: size, height: size)

            // Inner ring with pattern
            Circle()
                .stroke(Color.parliamentGold.opacity(0.5), lineWidth: 1)
                .frame(width: size * 0.8, height: size * 0.8)

            // Radial lines (seal pattern)
            ForEach(0..<12, id: \.self) { index in
                Rectangle()
                    .fill(Color.parliamentGold.opacity(0.3))
                    .frame(width: 1, height: size * 0.15)
                    .offset(y: -size * 0.35)
                    .rotationEffect(.degrees(Double(index) * 30))
            }

            // Crown icon in center
            Image(systemName: "crown.fill")
                .font(.system(size: size * 0.3))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.parliamentGoldLight, Color.parliamentGold],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .parliamentGold.opacity(0.5), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Metal Shaders
@available(iOS 17.0, *)
extension ShaderLibrary {
    static let metallicSheen = ShaderLibrary.bundle(.main).metallicSheen
    static let fogOfWar = ShaderLibrary.bundle(.main).fogOfWar
}

// MARK: - Haptic Feedback
@MainActor
final class HapticManager: Sendable {
    static let shared = HapticManager()

    private let impactGenerator: UIImpactFeedbackGenerator
    private let selectionGenerator: UISelectionFeedbackGenerator
    private let notificationGenerator: UINotificationFeedbackGenerator

    private init() {
        impactGenerator = UIImpactFeedbackGenerator(style: .heavy)
        selectionGenerator = UISelectionFeedbackGenerator()
        notificationGenerator = UINotificationFeedbackGenerator()
        impactGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }

    func playImpact() {
        impactGenerator.impactOccurred()
    }

    func playSelection() {
        selectionGenerator.selectionChanged()
    }

    func playNotification(type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationGenerator.notificationOccurred(type)
    }

    // Custom "Wax Seal" heavy thud
    func playWaxSealImpact() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.prepare()
        generator.impactOccurred(intensity: 1.0)
    }
}

/// Button style variants

enum Civ6ButtonStyleVariant {
    case primary
    case secondary
}

/// Civ6-style embossed/beveled button style
struct Civ6ButtonStyle: ButtonStyle {
    var isEnabled: Bool = true
    var style: Civ6ButtonStyleVariant = .primary

    func makeBody(configuration: Configuration) -> some View {
        Group {
            switch style {
            case .primary:
                primaryButton(configuration: configuration)
            case .secondary:
                secondaryButton(configuration: configuration)
            }
        }
        .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        .onChange(of: configuration.isPressed) { oldValue, newValue in
            if newValue && !oldValue {
                HapticManager.shared.playSelection()
            }
        }
    }

    private func primaryButton(configuration: Configuration) -> some View {
        configuration.label
            .font(.parliamentButton)
            .foregroundColor(isEnabled ? .parliamentParchment : .parliamentTextMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    // Base gradient (wood/bronze feel)
                    LinearGradient(
                        colors: isEnabled
                            ? (configuration.isPressed
                                ? [Color.parliamentWood, Color.parliamentBronze.opacity(0.8)]
                                : [Color.parliamentBronze, Color.parliamentWood])
                            : [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    // Top highlight
                    VStack {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(isEnabled ? 0.2 : 0.05),
                                        Color.clear,
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 8)
                        Spacer()
                    }

                    // Bottom shadow
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.clear,
                                        Color.black.opacity(isEnabled ? 0.3 : 0.1),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 6)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.parliamentGold.opacity(0.6),
                                Color.parliamentGold.opacity(0.2),
                                Color.parliamentGold.opacity(0.4),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isEnabled ? 2 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
            // Apply Metal Sheen Effect
            .visualEffect { content, proxy in
                content.colorEffect(
                    ShaderLibrary.metallicSheen(
                        .float(Date().timeIntervalSince1970),
                        .float2(proxy.size)
                    )
                )
            }
    }

    private func secondaryButton(configuration: Configuration) -> some View {
        configuration.label
            .font(.parliamentButton)
            .foregroundColor(isEnabled ? .parliamentGold : .parliamentTextMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.parliamentCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(
                        isEnabled
                            ? (configuration.isPressed
                                ? Color.parliamentGoldDark : Color.parliamentGold)
                            : Color.parliamentTextMuted.opacity(0.5),
                        lineWidth: 1
                    )
            )
    }
}

/// Decorative section header with Victorian styling
struct VictorianSectionHeader: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(spacing: ParliamentSpacing.xs) {
            HStack(spacing: ParliamentSpacing.sm) {
                // Left ornament
                Image(systemName: "seal.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.parliamentGold.opacity(0.6))

                Text(title.uppercased())
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .foregroundColor(.parliamentGold)
                    .tracking(2)

                // Right ornament
                Image(systemName: "seal.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.parliamentGold.opacity(0.6))
            }

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.parliamentTextMuted)
            }

            // Underline flourish
            HStack(spacing: 4) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.parliamentGold.opacity(0), Color.parliamentGold.opacity(0.5),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 40, height: 1)

                Circle()
                    .fill(Color.parliamentGold)
                    .frame(width: 4, height: 4)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.parliamentGold.opacity(0.5), Color.parliamentGold.opacity(0),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 40, height: 1)
            }
        }
    }
}

// MARK: - Figma-Style Components for HomeView

/// Gold particle overlay for background
struct GoldParticleOverlay: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                // Draw random gold particles
                let particles: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
                    (0.99, 0.62, 2.64, 2.42),
                    (0.82, 0.01, 2.2, 2.09),
                    (0.11, 0.96, 1.64, 1.28),
                    (0.79, 0.69, 2.36, 2.70),
                    (0.10, 0.56, 2.91, 2.89),
                    (0.84, 0.71, 2.86, 2.78),
                    (0.79, 0.60, 1.66, 1.17),
                    (0.16, 0.39, 2.69, 2.75),
                    (0.44, 0.29, 2.45, 2.73),
                    (0.65, 0.58, 2.27, 2.19),
                    (0.08, 0.67, 1.39, 2.44),
                    (0.91, 0.82, 1.69, 2.41),
                    (0.25, 0.41, 1.63, 1.91),
                    (0.11, 0.54, 1.34, 2.27),
                    (0.59, 0.55, 1.80, 2.70),
                ]

                for (xRatio, yRatio, w, h) in particles {
                    let x = size.width * xRatio
                    let y = size.height * yRatio
                    let opacity = Double.random(in: 0.1...0.25)

                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: w, height: h)),
                        with: .color(Color.parliamentGold.opacity(opacity))
                    )
                }
            }
        }
    }
}

/// Crown emblem for title section
struct FigmaCrownEmblem: View {
    var size: CGFloat = 80

    var body: some View {
        ZStack {
            // Outer decorative circle
            Circle()
                .stroke(Color.parliamentGold, lineWidth: 2)
                .frame(width: size, height: size)

            // Inner background
            Circle()
                .fill(Color.parliamentGold.opacity(0.1))
                .frame(width: size * 0.9, height: size * 0.9)

            // Crown icon
            Image(systemName: "crown.fill")
                .font(.system(size: size * 0.35))
                .foregroundColor(.parliamentGold)
                .shadow(color: .parliamentGold.opacity(0.5), radius: 4)
        }
    }
}

/// Figma-style divider with diamond center
struct FigmaDivider: View {
    var body: some View {
        HStack(spacing: 0) {
            // Left line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.parliamentGold.opacity(0.6)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 64, height: 1)

            // Center diamond
            Rectangle()
                .fill(Color.parliamentGold.opacity(0.8))
                .frame(width: 6, height: 6)
                .rotationEffect(.degrees(45))

            // Right line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.parliamentGold.opacity(0.6), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 64, height: 1)
        }
    }
}

/// Button style for mode selection (Create/Join)
struct FigmaModeButtonStyle: ButtonStyle {
    var isSelected: Bool
    var showCrownIcon: Bool = false
    var showBuildingIcon: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            // Background
            if isSelected {
                // Gold filled background
                Color.parliamentGold
            } else {
                // Transparent with gold border
                Color.clear
            }

            // Content
            configuration.label
                .foregroundColor(isSelected ? .parliamentMirage : .parliamentGold)
        }
        .clipShape(FigmaModeButtonShape())
        .overlay(
            FigmaModeButtonShape()
                .stroke(Color.parliamentGold, lineWidth: 2)
        )
        .overlay(
            // Icon in corner
            Group {
                if showCrownIcon {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                        .foregroundColor(
                            isSelected
                                ? .parliamentMirage.opacity(0.3) : .parliamentGold.opacity(0.3)
                        )
                        .position(x: 20, y: 20)
                } else if showBuildingIcon {
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 12))
                        .foregroundColor(
                            isSelected
                                ? .parliamentMirage.opacity(0.3) : .parliamentGold.opacity(0.3)
                        )
                        .position(x: 20, y: 20)
                }
            }
        )
        .shadow(color: isSelected ? .parliamentGold.opacity(0.4) : .clear, radius: 8, y: 4)
        .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Decorative button shape for mode buttons
struct FigmaModeButtonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cornerCut: CGFloat = 8

        path.move(to: CGPoint(x: cornerCut, y: 0))
        path.addLine(to: CGPoint(x: rect.width - cornerCut, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: cornerCut))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - cornerCut))
        path.addLine(to: CGPoint(x: rect.width - cornerCut, y: rect.height))
        path.addLine(to: CGPoint(x: cornerCut, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height - cornerCut))
        path.addLine(to: CGPoint(x: 0, y: cornerCut))
        path.closeSubpath()

        return path
    }
}

/// Compact button style for mode selection (Create/Join) - minimal height
struct FigmaCompactButtonStyle: ButtonStyle {
    var isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isSelected ? .parliamentMirage : .parliamentGold)
            .background(
                Group {
                    if isSelected {
                        Color.parliamentGold
                    } else {
                        Color.parliamentOil.opacity(0.6)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.parliamentGold, lineWidth: isSelected ? 0 : 1.5)
            )
            .shadow(color: isSelected ? .parliamentGold.opacity(0.3) : .clear, radius: 6, y: 3)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Figma-style input field
struct FigmaInputField: View {
    let label: String
    let englishLabel: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: ParliamentSpacing.sm) {
            // Label
            HStack(spacing: ParliamentSpacing.sm) {
                Image(systemName: "person.circle")
                    .font(.system(size: 14))
                    .foregroundColor(.parliamentMongoose)

                Text(label)
                    .font(.custom("Songti TC", size: 14))
                    .foregroundColor(.parliamentMongoose)

                Text(englishLabel)
                    .font(.custom("Songti TC", size: 12))
                    .foregroundColor(.parliamentMongoose.opacity(0.7))
            }

            // Input field - 使用明體保持一致性
            ZStack(alignment: .trailing) {
                TextField(
                    "", text: $text, prompt: Text(placeholder).foregroundColor(.parliamentGray)
                )
                .font(.custom("Songti TC", size: 16))
                .foregroundColor(.parliamentTextPrimary)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(
                    Color.parliamentOil.opacity(0.8)
                )
                .clipShape(FigmaInputShape())
                .overlay(
                    FigmaInputShape()
                        .stroke(Color.parliamentGold, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

                // Person icon on right
                Image(systemName: "person.circle")
                    .font(.system(size: 16))
                    .foregroundColor(.parliamentShadow.opacity(0.4))
                    .padding(.trailing, 12)
            }
        }
    }
}

/// Decorative shape for input field
struct FigmaInputShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cornerCut: CGFloat = 6

        path.move(to: CGPoint(x: cornerCut, y: 0))
        path.addLine(to: CGPoint(x: rect.width - cornerCut, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: cornerCut))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - cornerCut))
        path.addLine(to: CGPoint(x: rect.width - cornerCut, y: rect.height))
        path.addLine(to: CGPoint(x: cornerCut, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height - cornerCut))
        path.addLine(to: CGPoint(x: 0, y: cornerCut))
        path.closeSubpath()

        return path
    }
}

/// Decorative shape for action button
struct FigmaButtonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cornerCut: CGFloat = 10

        path.move(to: CGPoint(x: cornerCut, y: 0))
        path.addLine(to: CGPoint(x: rect.width - cornerCut, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: cornerCut))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - cornerCut))
        path.addLine(to: CGPoint(x: rect.width - cornerCut, y: rect.height))
        path.addLine(to: CGPoint(x: cornerCut, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height - cornerCut))
        path.addLine(to: CGPoint(x: 0, y: cornerCut))
        path.closeSubpath()

        return path
    }
}

// MARK: - Preview
#Preview("Design System") {
    ZStack {
        Color.parliamentBackground.ignoresSafeArea()

        VStack(spacing: 20) {
            ParliamentHeader()

            ParliamentBadge()

            Text("1812")
                .font(.parliamentHeroTitle)
                .foregroundColor(.parliamentTextPrimary)

            Text("國會風雲")
                .font(.parliamentTitle)
                .foregroundColor(.parliamentTextPrimary)

            ParliamentTabSelector(
                selectedTab: .constant(0),
                tabs: [
                    ("建立房間", "Create"),
                    ("加入房間", "Join"),
                ]
            )
            .padding(.horizontal)

            ParliamentInputField(
                label: "您的暱稱",
                englishLabel: "Your Nickname",
                placeholder: "輸入暱稱...",
                text: .constant(""),
                icon: "person.circle"
            )
            .padding(.horizontal)

            Button("建立新會議") {}
                .buttonStyle(ParliamentPrimaryButtonStyle())
                .padding(.horizontal)

            ParliamentQuoteFooter(
                chineseQuote: "「在攝政王的注視下，國會的權力鬥爭即將展開」",
                englishQuote: "Under the Prince Regent's gaze..."
            )
        }
    }
}
