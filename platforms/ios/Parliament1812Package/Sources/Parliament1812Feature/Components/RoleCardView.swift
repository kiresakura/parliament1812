import SwiftUI

/// 角色卡片視圖 - 顯示玩家的角色資訊
struct RoleCardView: View {
    let player: Player

    var body: some View {
        VStack(spacing: ParliamentSpacing.lg) {
            // Role portrait area
            rolePortrait

            // Role info
            roleInfo

            // Secret mission hint (if available)
            if player.roleType != nil {
                secretMissionHint
            }
        }
        .padding(ParliamentSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: ParliamentRadius.large)
                .fill(Color.parliamentCardBackground)
                .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 10)
        )
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
    }

    // MARK: - Role Portrait
    private var rolePortrait: some View {
        ZStack {
            // Decorative frame
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.parliamentGold, Color.parliamentBronze],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )
                .frame(width: 120, height: 120)

            // Inner circle with gradient
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            player.roleType?.color.opacity(0.8) ?? Color.parliamentBurgundy.opacity(0.8),
                            player.roleType?.color.opacity(0.4) ?? Color.parliamentBurgundy.opacity(0.4)
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 55
                    )
                )
                .frame(width: 110, height: 110)

            // Role icon
            Text(player.roleType?.emoji ?? "🎭")
                .font(.system(size: 50))

            // Decorative dots
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(Color.parliamentGold.opacity(0.6))
                    .frame(width: 6, height: 6)
                    .offset(y: -68)
                    .rotationEffect(.degrees(Double(index) * 45))
            }
        }
    }

    // MARK: - Role Info
    private var roleInfo: some View {
        VStack(spacing: ParliamentSpacing.sm) {
            // Role type badge
            if let roleType = player.roleType {
                Text(roleType.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.parliamentParchment)
                    .tracking(2)
                    .padding(.horizontal, ParliamentSpacing.md)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(roleType.color.opacity(0.8))
                    )
            }

            // Character name
            Text(player.roleType?.characterName ?? player.nickname)
                .font(.parliamentTitle)
                .foregroundColor(.parliamentTextPrimary)
                .multilineTextAlignment(.center)

            // Character description
            if let roleType = player.roleType {
                Text(roleType.description)
                    .font(.system(size: 13))
                    .foregroundColor(.parliamentTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, ParliamentSpacing.sm)
            }

            VictorianDivider()
                .padding(.vertical, ParliamentSpacing.xs)

            // Player nickname
            HStack(spacing: 6) {
                Image(systemName: "person.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.parliamentGold)

                Text("玩家：\(player.nickname)")
                    .font(.system(size: 14))
                    .foregroundColor(.parliamentTextMuted)
            }
        }
    }

    // MARK: - Secret Mission Hint
    private var secretMissionHint: some View {
        VStack(spacing: ParliamentSpacing.xs) {
            HStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                Text("秘密任務")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.parliamentGold)

            Text("只有你知道你的秘密任務")
                .font(.system(size: 11))
                .foregroundColor(.parliamentTextMuted)
        }
        .padding(ParliamentSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ParliamentRadius.medium)
                .fill(Color.parliamentWood.opacity(0.3))
        )
    }
}

// MARK: - Player Role Card (for lists)

struct PlayerRoleCard: View {
    let player: Player
    let isCurrentPlayer: Bool

    var body: some View {
        HStack(spacing: ParliamentSpacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(player.roleType?.color ?? Color.parliamentBurgundy)
                    .frame(width: 50, height: 50)

                Text(player.roleType?.emoji ?? "🎭")
                    .font(.system(size: 24))

                if isCurrentPlayer {
                    Circle()
                        .stroke(Color.parliamentGold, lineWidth: 2)
                        .frame(width: 56, height: 56)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(player.nickname)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(isCurrentPlayer ? .parliamentGold : .parliamentTextPrimary)

                    if isCurrentPlayer {
                        Text("(你)")
                            .font(.system(size: 11))
                            .foregroundColor(.parliamentGold)
                    }

                    if player.isHost {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.parliamentGold)
                    }
                }

                if let roleType = player.roleType {
                    Text(roleType.displayName)
                        .font(.system(size: 12))
                        .foregroundColor(.parliamentTextMuted)
                }
            }

            Spacer()
        }
        .padding(ParliamentSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ParliamentRadius.medium)
                .fill(Color.parliamentCardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ParliamentRadius.medium)
                .stroke(
                    isCurrentPlayer ? Color.parliamentGold.opacity(0.5) : Color.clear,
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Preview

#Preview("Role Card") {
    ZStack {
        Color.parliamentBackground.ignoresSafeArea()

        RoleCardView(
            player: Player(
                id: "1",
                nickname: "威廉",
                isHost: true,
                roleType: .mp,
                roleIndex: 1
            )
        )
        .padding()
    }
}

#Preview("Player Role Cards") {
    ZStack {
        Color.parliamentBackground.ignoresSafeArea()

        VStack(spacing: ParliamentSpacing.md) {
            PlayerRoleCard(
                player: Player(id: "1", nickname: "威廉", isHost: true, roleType: .mp, roleIndex: 1),
                isCurrentPlayer: true
            )

            PlayerRoleCard(
                player: Player(id: "2", nickname: "湯瑪斯", isHost: false, roleType: .worker, roleIndex: 1),
                isCurrentPlayer: false
            )

            PlayerRoleCard(
                player: Player(id: "3", nickname: "喬治", isHost: false, roleType: .luddite, roleIndex: 2),
                isCurrentPlayer: false
            )
        }
        .padding()
    }
}
