import SwiftUI

/// 角色選擇底部彈窗 - 玩家點擊頭像時顯示
struct RoleSelectionSheet: View {
    @Binding var selectedRole: RoleType?
    let onConfirm: (RoleType) -> Void
    @Environment(\.dismiss) private var dismiss

    // Grid layout: 2 columns for 6 roles
    private let columns = [
        GridItem(.flexible(), spacing: ParliamentSpacing.md),
        GridItem(.flexible(), spacing: ParliamentSpacing.md)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            sheetHeader

            VictorianDivider()
                .padding(.horizontal, ParliamentSpacing.lg)

            // Role Grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: ParliamentSpacing.md) {
                    ForEach(RoleType.allCases, id: \.self) { role in
                        RoleSelectionCard(
                            role: role,
                            isSelected: selectedRole == role
                        )
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedRole = role
                            }
                            HapticManager.shared.playSelection()
                        }
                    }
                }
                .padding(ParliamentSpacing.lg)
            }

            // Confirm Button
            confirmButton
        }
        .background(Color.parliamentBackground)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Sheet Header
    private var sheetHeader: some View {
        VStack(spacing: ParliamentSpacing.sm) {
            Text("選擇你的角色")
                .font(.parliamentTitle)
                .foregroundColor(.parliamentTextPrimary)

            Text("點選一個角色，確認後將分配給你")
                .font(.system(size: 13))
                .foregroundColor(.parliamentTextMuted)
        }
        .padding(.top, ParliamentSpacing.xl)
        .padding(.bottom, ParliamentSpacing.md)
    }

    // MARK: - Confirm Button
    private var confirmButton: some View {
        VStack(spacing: ParliamentSpacing.sm) {
            Button {
                if let role = selectedRole {
                    HapticManager.shared.playImpact()
                    onConfirm(role)
                    dismiss()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                    Text("確認選擇")
                        .font(.parliamentButton)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, ParliamentSpacing.md)
            }
            .buttonStyle(Civ6ButtonStyle())
            .disabled(selectedRole == nil)
            .opacity(selectedRole == nil ? 0.5 : 1.0)

            Button {
                dismiss()
            } label: {
                Text("取消")
                    .font(.system(size: 14))
                    .foregroundColor(.parliamentTextMuted)
            }
            .padding(.bottom, ParliamentSpacing.sm)
        }
        .padding(.horizontal, ParliamentSpacing.lg)
        .padding(.top, ParliamentSpacing.md)
        .padding(.bottom, ParliamentSpacing.lg)
        .background(
            Color.parliamentCardBackground
                .shadow(color: .black.opacity(0.3), radius: 10, y: -5)
        )
    }
}

// MARK: - Role Selection Card

struct RoleSelectionCard: View {
    let role: RoleType
    let isSelected: Bool

    var body: some View {
        VStack(spacing: ParliamentSpacing.sm) {
            // Role Portrait
            ZStack {
                // Background circle with role color
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                role.color.opacity(0.8),
                                role.color.opacity(0.4)
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 35
                        )
                    )
                    .frame(width: 70, height: 70)

                // Role emoji
                Text(role.emoji)
                    .font(.system(size: 36))

                // Selection ring
                if isSelected {
                    Circle()
                        .stroke(Color.parliamentGold, lineWidth: 3)
                        .frame(width: 78, height: 78)

                    // Checkmark badge
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.parliamentGold)
                        .background(Circle().fill(Color.parliamentBackground))
                        .offset(x: 28, y: -28)
                }
            }
            .frame(height: 80)

            // Role name
            Text(role.displayName)
                .font(.system(size: 15, weight: .semibold, design: .serif))
                .foregroundColor(isSelected ? .parliamentGold : .parliamentTextPrimary)

            // Brief description (truncated)
            Text(role.description)
                .font(.system(size: 11))
                .foregroundColor(.parliamentTextMuted)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 30)
        }
        .padding(ParliamentSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ParliamentRadius.large)
                .fill(Color.parliamentCardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ParliamentRadius.large)
                .stroke(
                    isSelected ? Color.parliamentGold : Color.parliamentGold.opacity(0.2),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Preview

#Preview("Role Selection Sheet") {
    ZStack {
        Color.parliamentBackground.ignoresSafeArea()

        Text("Waiting Room Content")
            .foregroundColor(.white)
    }
    .sheet(isPresented: .constant(true)) {
        RoleSelectionSheet(
            selectedRole: .constant(.worker),
            onConfirm: { role in
                print("Selected role: \(role.displayName)")
            }
        )
    }
}

#Preview("Role Selection Card") {
    ZStack {
        Color.parliamentBackground.ignoresSafeArea()

        HStack(spacing: 16) {
            RoleSelectionCard(role: .worker, isSelected: false)
            RoleSelectionCard(role: .mp, isSelected: true)
        }
        .padding()
    }
}
