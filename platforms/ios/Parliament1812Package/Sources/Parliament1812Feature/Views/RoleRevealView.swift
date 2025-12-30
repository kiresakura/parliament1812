import SwiftUI

// MARK: - Role Reveal View

/// 角色揭示頁面 - 顯示封蠟動畫、角色卡片、技能和秘密任務
struct RoleRevealView: View {
    let roleType: String
    let roleIndex: Int
    let onContinue: () -> Void

    @State private var isRevealed = false
    @State private var showDetails = false
    @State private var selectedMissionTab = 0

    private var roleData: RoleDetailData? {
        RoleDatabase.getRole(byType: roleType)
    }

    private var secretMission: SecretMission? {
        RoleDatabase.getSecretMission(roleType: roleType, missionIndex: roleIndex)
    }

    var body: some View {
        ZStack {
            // Background
            Color.parliamentBackground
                .ignoresSafeArea()

            if !isRevealed {
                // Wax seal animation
                WaxSealView(isRevealed: $isRevealed) {
                    HapticManager.shared.playWaxSealImpact()
                    withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                        showDetails = true
                    }
                }
            } else {
                // Role card content
                ScrollView {
                    VStack(spacing: ParliamentSpacing.lg) {
                        // Success badge header
                        successBadge
                            .opacity(showDetails ? 1 : 0)
                            .offset(y: showDetails ? 0 : -20)

                        // Role card
                        roleCard
                            .opacity(showDetails ? 1 : 0)
                            .scaleEffect(showDetails ? 1 : 0.9)

                        // Abilities section
                        if let role = roleData {
                            abilitiesSection(role: role)
                                .opacity(showDetails ? 1 : 0)
                                .offset(y: showDetails ? 0 : 20)
                        }

                        // Secret mission section
                        if let mission = secretMission {
                            secretMissionSection(mission: mission)
                                .opacity(showDetails ? 1 : 0)
                                .offset(y: showDetails ? 0 : 20)
                        }

                        // Continue button
                        continueButton
                            .opacity(showDetails ? 1 : 0)
                            .offset(y: showDetails ? 0 : 30)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, ParliamentSpacing.md)
                    .padding(.top, ParliamentSpacing.lg)
                }
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showDetails)
    }

    // MARK: - Success Badge

    private var successBadge: some View {
        VStack(spacing: ParliamentSpacing.sm) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.parliamentGoldLight, .parliamentGold],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Text("角色已分配")
                .font(.parliamentTitle)
                .foregroundColor(.parliamentTextPrimary)

            Text("ROLE ASSIGNED")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.parliamentTextMuted)
                .tracking(2)
        }
        .padding(.vertical, ParliamentSpacing.md)
    }

    // MARK: - Role Card

    private var roleCard: some View {
        VStack(spacing: 0) {
            if let role = roleData {
                // Role header with color accent
                ZStack {
                    // Background gradient
                    LinearGradient(
                        colors: [role.color, role.color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    VStack(spacing: ParliamentSpacing.md) {
                        // Portrait placeholder
                        rolePortrait(for: role)

                        // Name and title
                        VStack(spacing: ParliamentSpacing.xs) {
                            Text(role.characterName)
                                .font(.system(size: 24, weight: .bold, design: .serif))
                                .foregroundColor(.white)

                            Text(role.nameZh)
                                .font(.parliamentBody)
                                .foregroundColor(.white.opacity(0.9))

                            Text(role.nameEn)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .tracking(2)
                        }
                    }
                    .padding(.vertical, ParliamentSpacing.xl)
                }
                .frame(height: 280)

                // Quote and description
                VStack(spacing: ParliamentSpacing.md) {
                    // Quote
                    HStack {
                        Image(systemName: "quote.opening")
                            .font(.system(size: 10))
                            .foregroundColor(.parliamentGold.opacity(0.6))
                        Spacer()
                    }

                    Text(role.quote)
                        .font(.custom("Songti TC", size: 15))
                        .foregroundColor(.parliamentTextSecondary)
                        .multilineTextAlignment(.center)
                        .italic()

                    VictorianDivider()
                        .padding(.vertical, ParliamentSpacing.sm)

                    // Character info
                    HStack(spacing: ParliamentSpacing.lg) {
                        infoItem(label: "年齡", value: "\(role.age)歲")
                        infoItem(label: "職業", value: role.occupation)
                    }

                    // Description
                    Text(role.description)
                        .font(.parliamentBody)
                        .foregroundColor(.parliamentTextPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.top, ParliamentSpacing.sm)

                    // Stance
                    HStack {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.parliamentGold)
                        Text("立場：\(role.stance)")
                            .font(.system(size: 13))
                            .foregroundColor(.parliamentGold)
                    }
                    .padding(.top, ParliamentSpacing.sm)
                }
                .padding(ParliamentSpacing.lg)
                .background(Color.parliamentCardBackground)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: ParliamentRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: ParliamentRadius.large)
                .stroke(Color.parliamentGold.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }

    // MARK: - Role Portrait

    private func rolePortrait(for role: RoleDetailData) -> some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.parliamentGold, .parliamentGold.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 120, height: 120)

            // Inner circle with icon
            Circle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 110, height: 110)

            // Role icon
            Image(systemName: roleIcon(for: role.type))
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }

    private func roleIcon(for type: String) -> String {
        switch type.lowercased() {
        case "worker": return "person.fill"
        case "factory_owner", "factory": return "building.2.fill"
        case "luddite": return "hammer.fill"
        case "reformer": return "book.fill"
        case "mp": return "building.columns.fill"
        case "george_iii", "georgeiii": return "crown.fill"
        default: return "person.fill"
        }
    }

    private func infoItem(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.parliamentTextMuted)
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.parliamentTextPrimary)
        }
    }

    // MARK: - Abilities Section

    private func abilitiesSection(role: RoleDetailData) -> some View {
        VStack(spacing: ParliamentSpacing.md) {
            VictorianSectionHeader("特殊能力", subtitle: "SPECIAL ABILITIES")

            VStack(spacing: ParliamentSpacing.sm) {
                ForEach(Array(role.abilities.enumerated()), id: \.offset) { index, ability in
                    abilityRow(ability: ability, index: index)
                }
            }
            .padding(ParliamentSpacing.md)
            .background(Color.parliamentCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ParliamentRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: ParliamentRadius.medium)
                    .stroke(Color.parliamentGold.opacity(0.2), lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private func abilityRow(ability: RoleAbility, index: Int) -> some View {
        HStack(alignment: .top, spacing: ParliamentSpacing.md) {
            // Ability icon/number
            ZStack {
                Circle()
                    .fill(Color.parliamentGold.opacity(0.2))
                    .frame(width: 36, height: 36)

                Text(ability.icon)
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundColor(.parliamentGold)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(ability.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.parliamentTextPrimary)

                Text(ability.description)
                    .font(.system(size: 13))
                    .foregroundColor(.parliamentTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.vertical, ParliamentSpacing.sm)

        if index < 2 {
            Divider()
                .background(Color.parliamentGold.opacity(0.2))
        }
    }

    // MARK: - Secret Mission Section

    private func secretMissionSection(mission: SecretMission) -> some View {
        VStack(spacing: ParliamentSpacing.md) {
            VictorianSectionHeader("秘密任務", subtitle: "SECRET MISSION")

            VStack(spacing: ParliamentSpacing.md) {
                // Mission title
                HStack {
                    Image(systemName: "eye.slash.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.parliamentBurgundy)

                    Text(mission.title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.parliamentTextPrimary)

                    Spacer()

                    // Points badge
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                        Text("\(mission.points)分")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.parliamentGold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.parliamentGold.opacity(0.15))
                    .clipShape(Capsule())
                }

                // Mission description
                Text(mission.description)
                    .font(.parliamentBody)
                    .foregroundColor(.parliamentTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                VictorianDivider()

                // Success condition
                VStack(alignment: .leading, spacing: ParliamentSpacing.sm) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.parliamentGreen)

                        Text("達成條件")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.parliamentGold)
                    }

                    if let condition = mission.successCondition {
                        Text(condition)
                            .font(.system(size: 14))
                            .foregroundColor(.parliamentTextPrimary)
                            .padding(ParliamentSpacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.parliamentGreen.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: ParliamentRadius.small))
                    }
                }

                // Warning
                HStack(spacing: ParliamentSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)

                    Text("此任務僅供你個人查看，請勿洩露給其他玩家")
                        .font(.system(size: 12))
                        .foregroundColor(.parliamentTextMuted)
                }
                .padding(.top, ParliamentSpacing.sm)
            }
            .padding(ParliamentSpacing.lg)
            .background(Color.parliamentCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ParliamentRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: ParliamentRadius.medium)
                    .stroke(Color.parliamentBurgundy.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button(action: {
            HapticManager.shared.playImpact()
            onContinue()
        }) {
            HStack {
                Text("進入會議")
                    .font(.parliamentButton)

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
            }
        }
        .buttonStyle(Civ6ButtonStyle(isEnabled: true))
        .padding(.top, ParliamentSpacing.lg)
    }
}

// MARK: - Compact Role Card (for GameView sidebar)

struct CompactRoleCard: View {
    let roleType: String
    let roleIndex: Int
    var showMission: Bool = false

    private var roleData: RoleDetailData? {
        RoleDatabase.getRole(byType: roleType)
    }

    private var secretMission: SecretMission? {
        RoleDatabase.getSecretMission(roleType: roleType, missionIndex: roleIndex)
    }

    var body: some View {
        VStack(spacing: ParliamentSpacing.sm) {
            if let role = roleData {
                // Role header
                HStack(spacing: ParliamentSpacing.sm) {
                    // Mini portrait
                    ZStack {
                        Circle()
                            .fill(role.color)
                            .frame(width: 44, height: 44)

                        Image(systemName: iconFor(role.type))
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(role.characterName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.parliamentTextPrimary)

                        Text(role.nameZh)
                            .font(.system(size: 12))
                            .foregroundColor(.parliamentGold)
                    }

                    Spacer()
                }

                if showMission, let mission = secretMission {
                    Divider()
                        .background(Color.parliamentGold.opacity(0.3))

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "eye.slash.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.parliamentBurgundy)

                            Text(mission.title)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.parliamentTextPrimary)
                        }

                        Text(mission.description)
                            .font(.system(size: 11))
                            .foregroundColor(.parliamentTextSecondary)
                            .lineLimit(3)
                    }
                }
            }
        }
        .padding(ParliamentSpacing.md)
        .background(Color.parliamentCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ParliamentRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: ParliamentRadius.medium)
                .stroke(Color.parliamentGold.opacity(0.2), lineWidth: 1)
        )
    }

    private func iconFor(_ type: String) -> String {
        switch type.lowercased() {
        case "worker": return "person.fill"
        case "factory_owner", "factory": return "building.2.fill"
        case "luddite": return "hammer.fill"
        case "reformer": return "book.fill"
        case "mp": return "building.columns.fill"
        case "george_iii", "georgeiii": return "crown.fill"
        default: return "person.fill"
        }
    }
}

// MARK: - Preview

#Preview("Role Reveal - Worker") {
    RoleRevealView(
        roleType: "worker",
        roleIndex: 0,
        onContinue: {}
    )
}

#Preview("Role Reveal - Factory Owner") {
    RoleRevealView(
        roleType: "factory_owner",
        roleIndex: 1,
        onContinue: {}
    )
}

#Preview("Role Reveal - George III") {
    RoleRevealView(
        roleType: "george_iii",
        roleIndex: 0,
        onContinue: {}
    )
}

#Preview("Compact Role Card") {
    ZStack {
        Color.parliamentBackground.ignoresSafeArea()

        VStack(spacing: 16) {
            CompactRoleCard(roleType: "worker", roleIndex: 0, showMission: false)
            CompactRoleCard(roleType: "luddite", roleIndex: 2, showMission: true)
        }
        .padding()
    }
}
