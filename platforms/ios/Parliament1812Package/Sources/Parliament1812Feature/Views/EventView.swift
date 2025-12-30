import SwiftUI

// MARK: - Event Card View

/// Main event card display component with Victorian newspaper styling
struct EventCardView: View {
    let event: GameEventData
    var showEffects: Bool = true
    var isCompact: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header with event type and category
            eventHeader

            VictorianDivider(color: categoryColor.opacity(0.6))
                .padding(.horizontal, ParliamentSpacing.md)

            // Main content
            VStack(spacing: ParliamentSpacing.md) {
                // Title section
                titleSection

                // Description
                Text(event.description)
                    .font(.parliamentBody)
                    .foregroundColor(.parliamentTextPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, ParliamentSpacing.md)

                // Effects list
                if showEffects && !event.effects.isEmpty {
                    effectsSection
                }
            }
            .padding(.vertical, ParliamentSpacing.md)
        }
        .background(
            ZStack {
                // Parchment background
                Color.parliamentCardBackground

                // Aged paper texture overlay
                LinearGradient(
                    colors: [
                        Color.parliamentSepia.opacity(0.1),
                        Color.clear,
                        Color.parliamentSepia.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: ParliamentRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: ParliamentRadius.medium)
                .stroke(categoryColor.opacity(0.8), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
    }

    // MARK: - Subviews

    private var eventHeader: some View {
        HStack {
            // Type icon
            eventTypeIcon

            Spacer()

            // Category label
            Text(event.category == .domestic ? "國內事件" : "國際事件")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(categoryColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(categoryColor.opacity(0.15))
                        .overlay(
                            Capsule()
                                .stroke(categoryColor.opacity(0.3), lineWidth: 1)
                        )
                )

            Spacer()

            // Severity indicator
            severityIndicator
        }
        .padding(.horizontal, ParliamentSpacing.md)
        .padding(.vertical, ParliamentSpacing.sm)
        .background(categoryColor.opacity(0.1))
    }

    private var eventTypeIcon: some View {
        ZStack {
            Circle()
                .fill(categoryColor.opacity(0.2))
                .frame(width: 36, height: 36)

            Image(systemName: event.type.iconName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(categoryColor)
        }
    }

    private var severityIndicator: some View {
        HStack(spacing: 3) {
            ForEach(1...3, id: \.self) { level in
                Circle()
                    .fill(level <= event.severity ? severityColor : Color.parliamentTextMuted.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }

    private var titleSection: some View {
        VStack(spacing: ParliamentSpacing.xs) {
            Text(event.title)
                .font(.custom("Songti TC", size: isCompact ? 18 : 22).weight(.bold))
                .foregroundColor(.parliamentTextPrimary)
                .multilineTextAlignment(.center)

            Text(event.englishTitle)
                .font(.system(size: isCompact ? 12 : 14, weight: .medium, design: .serif))
                .foregroundColor(.parliamentTextSecondary)
                .italic()
        }
        .padding(.horizontal, ParliamentSpacing.md)
    }

    private var effectsSection: some View {
        VStack(spacing: ParliamentSpacing.sm) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 12))
                Text("影響效果")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.parliamentTextMuted)

            VStack(spacing: ParliamentSpacing.xs) {
                ForEach(event.effects) { effect in
                    EventEffectRow(effect: effect)
                }
            }
        }
        .padding(ParliamentSpacing.sm)
        .background(Color.black.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: ParliamentRadius.small))
        .padding(.horizontal, ParliamentSpacing.md)
    }

    // MARK: - Computed Properties

    private var categoryColor: Color {
        event.category == .domestic ? .parliamentGold : .parliamentBronze
    }

    private var severityColor: Color {
        switch event.severity {
        case 1: return .parliamentGreen
        case 2: return .parliamentGold
        case 3: return .victorianRed
        default: return .parliamentTextMuted
        }
    }
}

// MARK: - Event Effect Row

struct EventEffectRow: View {
    let effect: EventEffect

    var body: some View {
        HStack(spacing: ParliamentSpacing.sm) {
            // Target role icon
            if let targetRole = effect.targetRole {
                Text(targetRole)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.parliamentTextSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.parliamentWood.opacity(0.5))
                    )
            } else {
                Text("全體")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.parliamentTextSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.parliamentWood.opacity(0.5))
                    )
            }

            Spacer()

            // Support change
            if effect.supportChange != 0 {
                EffectValueBadge(
                    label: "支持",
                    value: effect.supportChange,
                    icon: "hand.thumbsup.fill"
                )
            }

            // Reputation change
            if effect.reputationChange != 0 {
                EffectValueBadge(
                    label: "聲望",
                    value: effect.reputationChange,
                    icon: "star.fill"
                )
            }
        }
    }
}

// MARK: - Effect Value Badge

struct EffectValueBadge: View {
    let label: String
    let value: Int
    let icon: String

    private var isPositive: Bool { value > 0 }
    private var color: Color { isPositive ? .parliamentGreen : .victorianRed }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))

            Text("\(isPositive ? "+" : "")\(value)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
        }
        .foregroundColor(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(color.opacity(0.15))
        )
    }
}

// MARK: - Event Reveal Animation View

struct EventRevealAnimationView: View {
    let event: GameEventData
    @Binding var isRevealed: Bool
    var onRevealComplete: (() -> Void)?

    @State private var flipAngle: Double = 0
    @State private var sealScale: CGFloat = 1.0
    @State private var sealOpacity: Double = 1.0
    @State private var showCard: Bool = false
    @State private var cardScale: CGFloat = 0.8
    @State private var cardOpacity: Double = 0

    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    if !isRevealed {
                        revealEvent()
                    }
                }

            if !showCard {
                // Wax seal before reveal
                waxSealView
            } else {
                // Event card after reveal
                EventCardView(event: event)
                    .frame(maxWidth: 340)
                    .scaleEffect(cardScale)
                    .opacity(cardOpacity)
                    .rotation3DEffect(
                        .degrees(flipAngle),
                        axis: (x: 0, y: 1, z: 0)
                    )
            }
        }
        .onAppear {
            // Auto-reveal after a short delay if configured
        }
    }

    private var waxSealView: some View {
        VStack(spacing: ParliamentSpacing.lg) {
            // Category indicator
            Text(event.category == .domestic ? "國內緊急公文" : "國際外交文書")
                .font(.custom("Songti TC", size: 16).weight(.medium))
                .foregroundColor(.parliamentTextSecondary)

            // Wax seal
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                (event.severity >= 3 ? Color.victorianRed : Color.parliamentBurgundy).opacity(0.6),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)

                // Seal base
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                event.severity >= 3 ? Color.victorianRed : Color.parliamentBurgundy,
                                Color(red: 0.35, green: 0.1, blue: 0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: .black.opacity(0.5), radius: 8, y: 4)

                // Seal emboss
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.clear,
                                Color.black.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 110, height: 110)

                // Crown icon
                Image(systemName: "crown.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.parliamentGoldLight,
                                Color.parliamentGold
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
            }
            .scaleEffect(sealScale)
            .opacity(sealOpacity)

            // Instruction text
            Text("點擊揭曉事件")
                .font(.system(size: 14))
                .foregroundColor(.parliamentTextMuted)
                .padding(.top, ParliamentSpacing.md)

            // Pulsing indicator
            Circle()
                .fill(Color.parliamentGold.opacity(0.6))
                .frame(width: 8, height: 8)
                .scaleEffect(sealScale)
                .animation(
                    .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                    value: sealScale
                )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                sealScale = 1.05
            }
        }
    }

    private func revealEvent() {
        HapticManager.shared.playWaxSealImpact()

        // Break seal animation
        withAnimation(.easeOut(duration: 0.3)) {
            sealScale = 1.3
            sealOpacity = 0
        }

        // Show card with flip
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showCard = true

            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                cardScale = 1.0
                cardOpacity = 1.0
                flipAngle = 360
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                isRevealed = true
                onRevealComplete?()
            }
        }
    }
}

// MARK: - Event Choice View

struct EventChoiceView: View {
    let event: GameEventData
    @Binding var selectedChoice: EventChoice?
    var onChoiceSelected: ((EventChoice) -> Void)?

    var body: some View {
        VStack(spacing: ParliamentSpacing.md) {
            // Header
            VStack(spacing: ParliamentSpacing.xs) {
                Text("請選擇應對方案")
                    .font(.custom("Songti TC", size: 18).weight(.semibold))
                    .foregroundColor(.parliamentTextPrimary)

                Text("Choose Your Response")
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .foregroundColor(.parliamentTextMuted)
                    .italic()
            }

            VictorianDivider()
                .padding(.horizontal, ParliamentSpacing.lg)

            // Choices
            if let choices = event.choices, !choices.isEmpty {
                VStack(spacing: ParliamentSpacing.sm) {
                    ForEach(choices) { choice in
                        EventChoiceCard(
                            choice: choice,
                            isSelected: selectedChoice?.id == choice.id,
                            onSelect: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedChoice = choice
                                }
                                onChoiceSelected?(choice)
                            }
                        )
                    }
                }
                .padding(.horizontal, ParliamentSpacing.md)
            } else {
                // No choices available
                VStack(spacing: ParliamentSpacing.sm) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundColor(.parliamentTextMuted)

                    Text("此事件無需選擇")
                        .font(.parliamentBody)
                        .foregroundColor(.parliamentTextSecondary)
                }
                .padding(.vertical, ParliamentSpacing.lg)
            }
        }
        .padding(.vertical, ParliamentSpacing.md)
        .background(Color.parliamentCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ParliamentRadius.medium))
    }
}

// MARK: - Event Choice Card

struct EventChoiceCard: View {
    let choice: EventChoice
    var isSelected: Bool = false
    var onSelect: (() -> Void)?

    var body: some View {
        Button(action: { onSelect?() }) {
            VStack(alignment: .leading, spacing: ParliamentSpacing.sm) {
                // Choice title
                HStack {
                    Text(choice.title)
                        .font(.custom("Songti TC", size: 15).weight(.medium))
                        .foregroundColor(isSelected ? .parliamentBackground : .parliamentTextPrimary)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.parliamentBackground)
                    }
                }

                // Choice description
                Text(choice.description)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? .parliamentBackground.opacity(0.8) : .parliamentTextSecondary)
                    .multilineTextAlignment(.leading)

                // Effect preview
                if !choice.effects.isEmpty {
                    HStack(spacing: ParliamentSpacing.sm) {
                        ForEach(choice.effects) { effect in
                            ChoiceEffectPreview(effect: effect, isSelected: isSelected)
                        }
                    }
                }
            }
            .padding(ParliamentSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: ParliamentRadius.small)
                    .fill(isSelected ? Color.parliamentGold : Color.parliamentWood.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: ParliamentRadius.small)
                    .stroke(
                        isSelected ? Color.parliamentGold : Color.parliamentGold.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Choice Effect Preview

struct ChoiceEffectPreview: View {
    let effect: EventEffect
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 4) {
            if effect.supportChange != 0 {
                Image(systemName: "hand.thumbsup.fill")
                    .font(.system(size: 10))
                Text("\(effect.supportChange > 0 ? "+" : "")\(effect.supportChange)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
            }

            if effect.reputationChange != 0 {
                if effect.supportChange != 0 {
                    Text("/")
                        .font(.system(size: 10))
                }
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                Text("\(effect.reputationChange > 0 ? "+" : "")\(effect.reputationChange)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
            }
        }
        .foregroundColor(isSelected ? .parliamentBackground.opacity(0.7) : effectColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(effectColor.opacity(0.15))
        )
    }

    private var effectColor: Color {
        if effect.supportChange > 0 || effect.reputationChange > 0 {
            return .parliamentGreen
        } else if effect.supportChange < 0 || effect.reputationChange < 0 {
            return .victorianRed
        }
        return .parliamentTextMuted
    }
}

// MARK: - Animated Event Effect View

struct EventEffectAnimationView: View {
    let effects: [EventEffect]
    @State private var visibleEffects: Set<String> = []
    @State private var floatingValues: [String: CGFloat] = [:]

    var body: some View {
        VStack(spacing: ParliamentSpacing.lg) {
            ForEach(effects) { effect in
                AnimatedEffectItem(
                    effect: effect,
                    isVisible: visibleEffects.contains(effect.id),
                    floatOffset: floatingValues[effect.id] ?? 0
                )
            }
        }
        .onAppear {
            animateEffects()
        }
    }

    private func animateEffects() {
        for (index, effect) in effects.enumerated() {
            // Stagger effect appearances
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.3) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    visibleEffects.insert(effect.id)
                }

                // Start floating animation
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    floatingValues[effect.id] = -8
                }
            }
        }
    }
}

// MARK: - Animated Effect Item

struct AnimatedEffectItem: View {
    let effect: EventEffect
    let isVisible: Bool
    let floatOffset: CGFloat

    var body: some View {
        HStack(spacing: ParliamentSpacing.md) {
            // Target role avatar
            ZStack {
                Circle()
                    .fill(Color.parliamentWood)
                    .frame(width: 50, height: 50)

                if let targetRole = effect.targetRole {
                    Text(String(targetRole.prefix(1)))
                        .font(.custom("Songti TC", size: 20).weight(.bold))
                        .foregroundColor(.parliamentGold)
                } else {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.parliamentGold)
                }
            }
            .overlay(
                Circle()
                    .stroke(Color.parliamentGold.opacity(0.5), lineWidth: 2)
            )
            .shadow(color: effectGlowColor.opacity(0.5), radius: 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(effect.targetRole ?? "全體角色")
                    .font(.custom("Songti TC", size: 14).weight(.medium))
                    .foregroundColor(.parliamentTextPrimary)

                if let condition = effect.condition {
                    Text(condition)
                        .font(.system(size: 11))
                        .foregroundColor(.parliamentTextMuted)
                }
            }

            Spacer()

            // Floating value badges
            HStack(spacing: ParliamentSpacing.sm) {
                if effect.supportChange != 0 {
                    FloatingValueBadge(
                        value: effect.supportChange,
                        icon: "hand.thumbsup.fill",
                        label: "支持"
                    )
                    .offset(y: floatOffset)
                }

                if effect.reputationChange != 0 {
                    FloatingValueBadge(
                        value: effect.reputationChange,
                        icon: "star.fill",
                        label: "聲望"
                    )
                    .offset(y: floatOffset * 0.8) // Slightly different timing
                }
            }
        }
        .padding(ParliamentSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ParliamentRadius.medium)
                .fill(Color.parliamentCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: ParliamentRadius.medium)
                        .stroke(effectGlowColor.opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0)
    }

    private var effectGlowColor: Color {
        if effect.supportChange > 0 || effect.reputationChange > 0 {
            return .parliamentGreen
        } else if effect.supportChange < 0 || effect.reputationChange < 0 {
            return .victorianRed
        }
        return .parliamentGold
    }
}

// MARK: - Floating Value Badge

struct FloatingValueBadge: View {
    let value: Int
    let icon: String
    let label: String

    private var isPositive: Bool { value > 0 }
    private var color: Color { isPositive ? .parliamentGreen : .victorianRed }

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))

                Text("\(isPositive ? "+" : "")\(value)")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
            }
            .foregroundColor(color)

            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.parliamentTextMuted)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: color.opacity(0.3), radius: 4, y: 2)
    }
}

// MARK: - Full Event Presentation View

/// Complete event presentation with reveal animation and choice selection
struct EventPresentationView: View {
    let event: GameEventData
    @Binding var isPresented: Bool
    var onEventComplete: ((EventChoice?) -> Void)?

    @State private var isRevealed: Bool = false
    @State private var selectedChoice: EventChoice?
    @State private var showEffects: Bool = false
    @State private var phase: EventPhase = .sealed

    enum EventPhase {
        case sealed
        case revealed
        case choosingAction
        case showingEffects
        case complete
    }

    var body: some View {
        ZStack {
            // Dark background
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: ParliamentSpacing.lg) {
                switch phase {
                case .sealed:
                    EventRevealAnimationView(
                        event: event,
                        isRevealed: $isRevealed,
                        onRevealComplete: {
                            withAnimation {
                                phase = .revealed
                            }
                        }
                    )

                case .revealed:
                    ScrollView {
                        VStack(spacing: ParliamentSpacing.lg) {
                            EventCardView(event: event)
                                .frame(maxWidth: 360)

                            if event.choices != nil && !event.choices!.isEmpty {
                                Button(action: {
                                    withAnimation {
                                        phase = .choosingAction
                                    }
                                }) {
                                    Text("選擇應對方案")
                                        .font(.parliamentButton)
                                }
                                .buttonStyle(Civ6ButtonStyle())
                                .frame(maxWidth: 280)
                            } else {
                                Button(action: {
                                    withAnimation {
                                        phase = .showingEffects
                                    }
                                }) {
                                    Text("查看影響")
                                        .font(.parliamentButton)
                                }
                                .buttonStyle(Civ6ButtonStyle())
                                .frame(maxWidth: 280)
                            }
                        }
                        .padding()
                    }

                case .choosingAction:
                    ScrollView {
                        VStack(spacing: ParliamentSpacing.lg) {
                            // Compact event card
                            EventCardView(event: event, showEffects: false, isCompact: true)
                                .frame(maxWidth: 340)

                            // Choice selection
                            EventChoiceView(
                                event: event,
                                selectedChoice: $selectedChoice,
                                onChoiceSelected: { _ in }
                            )
                            .frame(maxWidth: 340)

                            // Confirm button
                            Button(action: {
                                withAnimation {
                                    phase = .showingEffects
                                }
                            }) {
                                Text(selectedChoice != nil ? "確認選擇" : "跳過")
                                    .font(.parliamentButton)
                            }
                            .buttonStyle(Civ6ButtonStyle(isEnabled: true))
                            .frame(maxWidth: 280)
                        }
                        .padding()
                    }

                case .showingEffects:
                    VStack(spacing: ParliamentSpacing.lg) {
                        Text("事件影響")
                            .font(.custom("Songti TC", size: 20).weight(.semibold))
                            .foregroundColor(.parliamentGold)

                        EventEffectAnimationView(
                            effects: selectedChoice?.effects ?? event.effects
                        )
                        .frame(maxWidth: 360)
                        .padding()

                        Button(action: {
                            phase = .complete
                            onEventComplete?(selectedChoice)
                            isPresented = false
                        }) {
                            Text("繼續")
                                .font(.parliamentButton)
                        }
                        .buttonStyle(Civ6ButtonStyle())
                        .frame(maxWidth: 280)
                    }
                    .padding()

                case .complete:
                    EmptyView()
                }
            }

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        isPresented = false
                        onEventComplete?(nil)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.parliamentTextMuted)
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }
}

// MARK: - Previews

#Preview("Event Card") {
    ZStack {
        Color.parliamentBackground.ignoresSafeArea()

        EventCardView(event: EventDatabase.domesticEvents[0])
            .padding()
    }
}

#Preview("Event Reveal") {
    EventRevealAnimationView(
        event: EventDatabase.domesticEvents[2],
        isRevealed: .constant(false)
    )
}

#Preview("Event Choice") {
    ZStack {
        Color.parliamentBackground.ignoresSafeArea()

        EventChoiceView(
            event: EventDatabase.domesticEvents.first { $0.choices != nil }!,
            selectedChoice: .constant(nil)
        )
        .padding()
    }
}

#Preview("Effect Animation") {
    ZStack {
        Color.parliamentBackground.ignoresSafeArea()

        EventEffectAnimationView(
            effects: EventDatabase.domesticEvents[0].effects
        )
        .padding()
    }
}

#Preview("Full Presentation") {
    EventPresentationView(
        event: EventDatabase.domesticEvents[3],
        isPresented: .constant(true)
    )
}
