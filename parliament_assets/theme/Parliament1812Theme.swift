// Parliament1812Theme.swift
// 1812 國會風雲 - iOS Theme Configuration
// Based on Figma Design System

import SwiftUI

// MARK: - Color Palette
extension Color {
    struct Parliament1812 {
        // Primary Colors
        static let darkNavy = Color(hex: "1a1a2e")          // PRIMARY BACKGROUND
        static let secondaryNavy = Color(hex: "16213e")      // CARD BACKGROUNDS
        static let darkBrown = Color(hex: "1a1614")          // Alternative dark background
        static let cardBrown = Color(hex: "241b14")          // Card background variant
        
        // Accent Colors
        static let antiqueGold = Color(hex: "d4af37")        // PRIMARY ACCENT
        static let saddleBrown = Color(hex: "8b4513")        // SECONDARY ACCENT
        static let mutedGold = Color(hex: "b8941f")          // Gradient gold
        
        // Text Colors
        static let parchmentCream = Color(hex: "f5e6d3")     // PRIMARY TEXT
        static let mutedText = Color(hex: "b8a07e")          // SECONDARY TEXT
        static let subtleText = Color(hex: "8b7753")         // Tertiary text
        
        // Political Party Colors
        static let toryBlue = Color(hex: "1e3a5f")           // TORY PARTY
        static let whigOrange = Color(hex: "cc7722")         // WHIG PARTY
        static let neutral = Color(hex: "8b7753")            // NEUTRAL
        
        // Voting Colors
        static let ayeGreen = Color(hex: "2d5a27")           // AYE/SUCCESS
        static let nayCrimson = Color(hex: "8b2500")         // NAY/DANGER
        
        // Wax Seal Colors
        static let sealDark = Color(hex: "6e1e00")
        static let sealMid = Color(hex: "8b2500")
        static let sealLight = Color(hex: "a3320b")
    }
}

// MARK: - Hex Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography
struct Parliament1812Typography {
    // Primary font: Georgia (serif)
    static let titleLarge = Font.custom("Georgia", size: 48).weight(.bold)
    static let titleMedium = Font.custom("Georgia", size: 32).weight(.bold)
    static let titleSmall = Font.custom("Georgia", size: 24).weight(.semibold)
    static let heading = Font.custom("Georgia", size: 20).weight(.semibold)
    static let body = Font.custom("Georgia", size: 16)
    static let caption = Font.custom("Georgia", size: 14)
    static let small = Font.custom("Georgia", size: 12)
    
    // Letter spacing
    static let wideSpacing: CGFloat = 4
    static let normalSpacing: CGFloat = 2
}

// MARK: - Button Styles
struct GoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [Color.Parliament1812.antiqueGold, Color.Parliament1812.mutedGold],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(Color.Parliament1812.darkNavy)
            .font(.custom("Georgia", size: 16).weight(.semibold))
            .clipShape(Parliament1812ButtonShape())
            .shadow(color: Color.Parliament1812.antiqueGold.opacity(0.4), radius: 8, y: 4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Color.clear)
            .foregroundColor(Color.Parliament1812.antiqueGold)
            .font(.custom("Georgia", size: 16).weight(.semibold))
            .overlay(
                Parliament1812ButtonShape()
                    .stroke(Color.Parliament1812.antiqueGold, lineWidth: 2)
            )
            .clipShape(Parliament1812ButtonShape())
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

struct AyeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal: 32, .vertical: 16)
            .background(Color.Parliament1812.ayeGreen)
            .foregroundColor(Color.Parliament1812.parchmentCream)
            .font(.custom("Georgia", size: 18).weight(.bold))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct NayButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal: 32, .vertical: 16)
            .background(Color.Parliament1812.nayCrimson)
            .foregroundColor(Color.Parliament1812.parchmentCream)
            .font(.custom("Georgia", size: 18).weight(.bold))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - Custom Shapes
struct Parliament1812ButtonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cornerCut: CGFloat = 12
        var path = Path()
        
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - cornerCut))
        path.addLine(to: CGPoint(x: rect.width - cornerCut, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Card Style
struct Parliament1812Card<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.Parliament1812.cardBrown.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.Parliament1812.antiqueGold.opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.5), radius: 10, y: 4)
    }
}

// MARK: - Input Field Style
struct Parliament1812TextField: View {
    let placeholder: String
    @Binding var text: String
    var isCode: Bool = false
    
    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(Color.Parliament1812.cardBrown.opacity(0.8))
            .foregroundColor(Color.Parliament1812.parchmentCream)
            .font(isCode ? .system(size: 24, design: .monospaced) : .custom("Georgia", size: 16))
            .overlay(
                Parliament1812ButtonShape()
                    .stroke(Color.Parliament1812.antiqueGold, lineWidth: 2)
            )
            .clipShape(Parliament1812ButtonShape())
            .autocapitalization(isCode ? .allCharacters : .words)
    }
}

// MARK: - Decorative Elements
struct CornerFlourish: View {
    enum Position {
        case topLeft, topRight, bottomLeft, bottomRight
    }
    
    let position: Position
    let size: CGFloat
    let color: Color
    
    init(position: Position = .topLeft, size: CGFloat = 32, color: Color = .Parliament1812.antiqueGold) {
        self.position = position
        self.size = size
        self.color = color
    }
    
    var body: some View {
        Image(systemName: "leaf.fill")
            .resizable()
            .frame(width: size, height: size)
            .foregroundColor(color.opacity(0.4))
            .rotationEffect(rotationAngle)
            .scaleEffect(scaleEffect)
    }
    
    private var rotationAngle: Angle {
        switch position {
        case .topLeft: return .degrees(45)
        case .topRight: return .degrees(135)
        case .bottomLeft: return .degrees(-45)
        case .bottomRight: return .degrees(-135)
        }
    }
    
    private var scaleEffect: CGSize {
        switch position {
        case .topRight, .bottomRight: return CGSize(width: -1, height: 1)
        default: return CGSize(width: 1, height: 1)
        }
    }
}

struct DividerLine: View {
    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(LinearGradient(
                    colors: [.clear, Color.Parliament1812.antiqueGold],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(width: 64, height: 1)
            
            Diamond()
                .fill(Color.Parliament1812.antiqueGold)
                .frame(width: 6, height: 6)
            
            Rectangle()
                .fill(LinearGradient(
                    colors: [Color.Parliament1812.antiqueGold, .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(width: 64, height: 1)
        }
        .opacity(0.6)
    }
}

struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Crown Icon
struct CrownIcon: View {
    let size: CGFloat
    let color: Color
    
    init(size: CGFloat = 24, color: Color = .Parliament1812.antiqueGold) {
        self.size = size
        self.color = color
    }
    
    var body: some View {
        Image(systemName: "crown.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .foregroundColor(color)
    }
}

// MARK: - Hexagon Shape
struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3 - .pi / 2
            let point = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
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

// MARK: - Party Badge
struct PartyBadge: View {
    enum Party {
        case tory, whig, neutral
        
        var color: Color {
            switch self {
            case .tory: return .Parliament1812.toryBlue
            case .whig: return .Parliament1812.whigOrange
            case .neutral: return .Parliament1812.neutral
            }
        }
        
        var nameChinese: String {
            switch self {
            case .tory: return "托利黨"
            case .whig: return "輝格黨"
            case .neutral: return "中立"
            }
        }
        
        var nameEnglish: String {
            switch self {
            case .tory: return "TORY"
            case .whig: return "WHIG"
            case .neutral: return "NEUTRAL"
            }
        }
    }
    
    let party: Party
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(party.color)
                .frame(width: 8, height: 8)
            Text(party.nameChinese)
                .font(.custom("Georgia", size: 12))
                .foregroundColor(party.color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .stroke(party.color, lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.Parliament1812.darkBrown
            .ignoresSafeArea()
        
        VStack(spacing: 24) {
            // Title
            Text("1812")
                .font(Parliament1812Typography.titleLarge)
                .foregroundColor(.Parliament1812.antiqueGold)
                .shadow(color: .Parliament1812.antiqueGold.opacity(0.4), radius: 15)
            
            Text("國會風雲")
                .font(Parliament1812Typography.titleSmall)
                .foregroundColor(.Parliament1812.mutedText)
            
            DividerLine()
            
            // Buttons
            Button("建立房間") {}
                .buttonStyle(GoldButtonStyle())
            
            Button("加入房間") {}
                .buttonStyle(OutlineButtonStyle())
            
            // Party badges
            HStack(spacing: 16) {
                PartyBadge(party: .tory)
                PartyBadge(party: .whig)
            }
            
            // Card example
            Parliament1812Card {
                VStack(alignment: .leading, spacing: 8) {
                    Text("議案表決")
                        .font(.custom("Georgia", size: 18))
                        .foregroundColor(.Parliament1812.antiqueGold)
                    Text("在攝政王的注視下...")
                        .font(.custom("Georgia", size: 14))
                        .foregroundColor(.Parliament1812.mutedText)
                }
            }
        }
        .padding()
    }
}
