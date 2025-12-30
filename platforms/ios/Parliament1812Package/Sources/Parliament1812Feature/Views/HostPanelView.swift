import SwiftUI

/// 主持人控制面板視圖
/// Host Control Panel for managing game phases, timer, and events
struct HostPanelView: View {
    @StateObject private var viewModel = HostPanelViewModel()

    let roomCode: String
    let playerId: String
    let onDismiss: () -> Void

    @State private var showTimerSheet = false
    @State private var showEventSheet = false
    @State private var selectedTimerMinutes: Int = 10

    var body: some View {
        ZStack {
            // Background
            Color.parliamentBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HostPanelHeader(
                    roomCode: roomCode,
                    playerCount: viewModel.uiState.playerCount,
                    onRefresh: { viewModel.refreshData() },
                    onDismiss: onDismiss
                )

                ScrollView {
                    VStack(spacing: ParliamentSpacing.lg) {
                        // Current Status
                        CurrentStatusSection(
                            currentPhase: viewModel.uiState.currentPhase,
                            phaseName: viewModel.currentPhaseName,
                            isTimerRunning: viewModel.isTimerRunning,
                            timerFormatted: viewModel.timerRemainingFormatted
                        )

                        // Phase Control
                        PhaseControlSection(
                            currentPhase: viewModel.uiState.currentPhase,
                            isChangingPhase: viewModel.uiState.isChangingPhase,
                            canGoNext: viewModel.canGoNext,
                            canGoPrevious: viewModel.canGoPrevious,
                            onPhaseChange: { phase in viewModel.changePhase(to: phase) },
                            onNextPhase: { viewModel.nextPhase() },
                            onPreviousPhase: { viewModel.previousPhase() }
                        )

                        // Timer Control
                        TimerControlSection(
                            isSettingTimer: viewModel.uiState.isSettingTimer,
                            selectedMinutes: $selectedTimerMinutes,
                            onSetTimer: { minutes in viewModel.setTimer(minutes: minutes) }
                        )

                        // Event Control
                        EventControlSection(
                            availableEvents: viewModel.uiState.availableEvents,
                            isTriggeringEvent: viewModel.uiState.isTriggeringEvent,
                            onTriggerEvent: { event in viewModel.triggerEvent(event) },
                            onTriggerRandomEvent: { viewModel.triggerRandomEvent() }
                        )

                        Spacer(minLength: ParliamentSpacing.xxl)
                    }
                    .padding(.horizontal, ParliamentSpacing.md)
                    .padding(.top, ParliamentSpacing.md)
                }
            }

            // Loading overlay
            if viewModel.uiState.isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .parliamentGold))
                    .scaleEffect(1.5)
            }

            // Triggered Event Overlay
            if let event = viewModel.uiState.triggeredEvent {
                TriggeredEventOverlay(
                    event: event,
                    onDismiss: { viewModel.clearTriggeredEvent() }
                )
            }
        }
        .onAppear {
            viewModel.initialize(roomCode: roomCode, playerId: playerId)
        }
        .alert("錯誤", isPresented: .constant(viewModel.uiState.error != nil)) {
            Button("確定") { viewModel.clearError() }
        } message: {
            Text(viewModel.uiState.error ?? "")
        }
        .overlay(alignment: .top) {
            // Success toast
            if let message = viewModel.uiState.successMessage {
                SuccessToast(message: message)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            viewModel.clearSuccessMessage()
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: viewModel.uiState.successMessage)
    }
}

// MARK: - Header

private struct HostPanelHeader: View {
    let roomCode: String
    let playerCount: Int
    let onRefresh: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            // Back button
            Button(action: onDismiss) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.parliamentGold)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("主持人面板")
                    .font(.parliamentTitle)
                    .foregroundColor(.parliamentTextPrimary)

                HStack(spacing: ParliamentSpacing.sm) {
                    // Room code
                    HStack(spacing: 4) {
                        Image(systemName: "number")
                            .font(.system(size: 10))
                        Text(roomCode)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                    }
                    .foregroundColor(.parliamentGold)

                    // Player count
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 10))
                        Text("\(playerCount)")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.parliamentTextSecondary)
                }
            }

            Spacer()

            // Refresh button
            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.parliamentGold)
            }
        }
        .padding(.horizontal, ParliamentSpacing.md)
        .padding(.vertical, ParliamentSpacing.sm)
        .background(Color.parliamentCardBackground)
    }
}

// MARK: - Current Status Section

private struct CurrentStatusSection: View {
    let currentPhase: Int
    let phaseName: String
    let isTimerRunning: Bool
    let timerFormatted: String

    var body: some View {
        VStack(spacing: ParliamentSpacing.md) {
            VictorianSectionHeader("當前狀態", subtitle: "Current Status")

            HStack(spacing: ParliamentSpacing.md) {
                // Phase status
                VStack(spacing: ParliamentSpacing.xs) {
                    Text("階段")
                        .font(.parliamentQuote)
                        .foregroundColor(.parliamentTextMuted)

                    Text("\(currentPhase)")
                        .font(.system(size: 36, weight: .bold, design: .serif))
                        .foregroundColor(.parliamentGold)

                    Text(phaseName)
                        .font(.parliamentBody)
                        .foregroundColor(.parliamentTextPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, ParliamentSpacing.md)
                .background(Color.parliamentCardBackground)
                .cornerRadius(ParliamentRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: ParliamentRadius.medium)
                        .stroke(Color.parliamentGold.opacity(0.3), lineWidth: 1)
                )

                // Timer status
                VStack(spacing: ParliamentSpacing.xs) {
                    Text("計時器")
                        .font(.parliamentQuote)
                        .foregroundColor(.parliamentTextMuted)

                    Text(isTimerRunning ? timerFormatted : "--:--")
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(isTimerRunning ? .parliamentGold : .parliamentTextMuted)

                    Text(isTimerRunning ? "進行中" : "未啟動")
                        .font(.parliamentBody)
                        .foregroundColor(isTimerRunning ? .green : .parliamentTextMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, ParliamentSpacing.md)
                .background(Color.parliamentCardBackground)
                .cornerRadius(ParliamentRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: ParliamentRadius.medium)
                        .stroke(Color.parliamentGold.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - Phase Control Section

private struct PhaseControlSection: View {
    let currentPhase: Int
    let isChangingPhase: Bool
    let canGoNext: Bool
    let canGoPrevious: Bool
    let onPhaseChange: (Int) -> Void
    let onNextPhase: () -> Void
    let onPreviousPhase: () -> Void

    var body: some View {
        VStack(spacing: ParliamentSpacing.md) {
            VictorianSectionHeader("階段控制", subtitle: "Phase Control")

            VStack(spacing: ParliamentSpacing.sm) {
                // Quick phase buttons
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: ParliamentSpacing.sm) {
                    ForEach(HostPanelViewModel.quickPhases, id: \.phase) { item in
                        QuickPhaseButton(
                            phase: item.phase,
                            label: item.label,
                            isSelected: currentPhase == item.phase,
                            isLoading: isChangingPhase,
                            onTap: { onPhaseChange(item.phase) }
                        )
                    }
                }

                VictorianDivider()
                    .padding(.vertical, ParliamentSpacing.xs)

                // Phase navigation
                HStack(spacing: ParliamentSpacing.md) {
                    // Previous
                    Button(action: onPreviousPhase) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("上一階段")
                        }
                        .font(.parliamentBody)
                        .foregroundColor(canGoPrevious ? .parliamentGold : .parliamentTextMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.parliamentCardBackground)
                        .cornerRadius(ParliamentRadius.small)
                        .overlay(
                            RoundedRectangle(cornerRadius: ParliamentRadius.small)
                                .stroke(canGoPrevious ? Color.parliamentGold.opacity(0.5) : Color.parliamentTextMuted.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .disabled(!canGoPrevious || isChangingPhase)

                    // Next
                    Button(action: onNextPhase) {
                        HStack(spacing: 6) {
                            Text("下一階段")
                            Image(systemName: "chevron.right")
                        }
                        .font(.parliamentBody)
                        .foregroundColor(canGoNext ? .parliamentBackground : .parliamentTextMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(canGoNext ? Color.parliamentGold : Color.parliamentCardBackground)
                        .cornerRadius(ParliamentRadius.small)
                    }
                    .disabled(!canGoNext || isChangingPhase)
                }
            }
            .padding(ParliamentSpacing.md)
            .background(Color.parliamentCardBackground)
            .cornerRadius(ParliamentRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: ParliamentRadius.medium)
                    .stroke(Color.parliamentGold.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

private struct QuickPhaseButton: View {
    let phase: Int
    let label: String
    let isSelected: Bool
    let isLoading: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(phase)")
                    .font(.system(size: 18, weight: .bold, design: .serif))
                Text(label)
                    .font(.system(size: 11))
            }
            .foregroundColor(isSelected ? .parliamentBackground : .parliamentGold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color.parliamentGold : Color.parliamentOil)
            .cornerRadius(ParliamentRadius.small)
            .overlay(
                RoundedRectangle(cornerRadius: ParliamentRadius.small)
                    .stroke(Color.parliamentGold.opacity(isSelected ? 0 : 0.5), lineWidth: 1)
            )
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.6 : 1.0)
    }
}

// MARK: - Timer Control Section

private struct TimerControlSection: View {
    let isSettingTimer: Bool
    @Binding var selectedMinutes: Int
    let onSetTimer: (Int) -> Void

    var body: some View {
        VStack(spacing: ParliamentSpacing.md) {
            VictorianSectionHeader("計時器", subtitle: "Timer")

            VStack(spacing: ParliamentSpacing.md) {
                // Timer preset chips
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: ParliamentSpacing.sm) {
                    ForEach(HostPanelViewModel.timerOptions, id: \.self) { minutes in
                        TimerChip(
                            minutes: minutes,
                            isSelected: selectedMinutes == minutes,
                            onTap: { selectedMinutes = minutes }
                        )
                    }
                }

                // Set timer button
                Button {
                    onSetTimer(selectedMinutes)
                } label: {
                    HStack(spacing: 8) {
                        if isSettingTimer {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .parliamentBackground))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "timer")
                        }
                        Text("設定 \(selectedMinutes) 分鐘計時器")
                    }
                    .font(.parliamentButton)
                    .foregroundColor(.parliamentBackground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.parliamentGold)
                    .cornerRadius(ParliamentRadius.small)
                }
                .disabled(isSettingTimer)
            }
            .padding(ParliamentSpacing.md)
            .background(Color.parliamentCardBackground)
            .cornerRadius(ParliamentRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: ParliamentRadius.medium)
                    .stroke(Color.parliamentGold.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

private struct TimerChip: View {
    let minutes: Int
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text("\(minutes)分")
                .font(.parliamentBody)
                .foregroundColor(isSelected ? .parliamentBackground : .parliamentTextPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color.parliamentGold : Color.parliamentOil)
                .cornerRadius(ParliamentRadius.small)
                .overlay(
                    RoundedRectangle(cornerRadius: ParliamentRadius.small)
                        .stroke(Color.parliamentGold.opacity(isSelected ? 0 : 0.5), lineWidth: 1)
                )
        }
    }
}

// MARK: - Event Control Section

private struct EventControlSection: View {
    let availableEvents: [EventData]
    let isTriggeringEvent: Bool
    let onTriggerEvent: (EventData) -> Void
    let onTriggerRandomEvent: () -> Void

    var body: some View {
        VStack(spacing: ParliamentSpacing.md) {
            VictorianSectionHeader("突發事件", subtitle: "Events")

            VStack(spacing: ParliamentSpacing.md) {
                // Random trigger button
                Button(action: onTriggerRandomEvent) {
                    HStack(spacing: 8) {
                        if isTriggeringEvent {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .parliamentGold))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "dice.fill")
                        }
                        Text("隨機觸發事件")
                    }
                    .font(.parliamentButton)
                    .foregroundColor(.parliamentGold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.parliamentOil)
                    .cornerRadius(ParliamentRadius.small)
                    .overlay(
                        RoundedRectangle(cornerRadius: ParliamentRadius.small)
                            .stroke(Color.parliamentGold, lineWidth: 1)
                    )
                }
                .disabled(isTriggeringEvent)

                VictorianDivider()

                // Event list
                if availableEvents.isEmpty {
                    Text("沒有可用的事件")
                        .font(.parliamentBody)
                        .foregroundColor(.parliamentTextMuted)
                        .padding(.vertical, ParliamentSpacing.lg)
                } else {
                    VStack(spacing: ParliamentSpacing.sm) {
                        ForEach(availableEvents) { event in
                            EventPreviewItem(
                                event: event,
                                isLoading: isTriggeringEvent,
                                onTrigger: { onTriggerEvent(event) }
                            )
                        }
                    }
                }
            }
            .padding(ParliamentSpacing.md)
            .background(Color.parliamentCardBackground)
            .cornerRadius(ParliamentRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: ParliamentRadius.medium)
                    .stroke(Color.parliamentGold.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

private struct EventPreviewItem: View {
    let event: EventData
    let isLoading: Bool
    let onTrigger: () -> Void

    var body: some View {
        HStack(spacing: ParliamentSpacing.sm) {
            // Severity indicator
            Circle()
                .fill(severityColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.parliamentBody)
                    .foregroundColor(.parliamentTextPrimary)
                    .lineLimit(1)

                Text(event.description)
                    .font(.parliamentQuote)
                    .foregroundColor(.parliamentTextMuted)
                    .lineLimit(2)
            }

            Spacer()

            Button(action: onTrigger) {
                Image(systemName: "play.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.parliamentGold)
                    .padding(8)
                    .background(Color.parliamentOil)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.parliamentGold.opacity(0.5), lineWidth: 1)
                    )
            }
            .disabled(isLoading)
        }
        .padding(ParliamentSpacing.sm)
        .background(Color.parliamentOil.opacity(0.5))
        .cornerRadius(ParliamentRadius.small)
    }

    private var severityColor: Color {
        switch event.severity ?? 1 {
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        default: return .red
        }
    }
}

// MARK: - Triggered Event Overlay

private struct TriggeredEventOverlay: View {
    let event: EventData
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: ParliamentSpacing.lg) {
                // Icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.parliamentGold)

                Text("突發事件")
                    .font(.parliamentTitle)
                    .foregroundColor(.parliamentGold)

                VStack(spacing: ParliamentSpacing.sm) {
                    Text(event.title)
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundColor(.parliamentTextPrimary)
                        .multilineTextAlignment(.center)

                    Text(event.description)
                        .font(.parliamentBody)
                        .foregroundColor(.parliamentTextSecondary)
                        .multilineTextAlignment(.center)
                }

                Button(action: onDismiss) {
                    Text("關閉")
                        .font(.parliamentButton)
                        .foregroundColor(.parliamentBackground)
                        .frame(width: 120)
                        .padding(.vertical, 12)
                        .background(Color.parliamentGold)
                        .cornerRadius(ParliamentRadius.small)
                }
            }
            .padding(ParliamentSpacing.xl)
            .background(Color.parliamentCardBackground)
            .cornerRadius(ParliamentRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: ParliamentRadius.large)
                    .stroke(Color.parliamentGold, lineWidth: 2)
            )
            .padding(ParliamentSpacing.xl)
        }
    }
}

// MARK: - Success Toast

private struct SuccessToast: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(message)
                .font(.parliamentBody)
                .foregroundColor(.parliamentTextPrimary)
        }
        .padding(.horizontal, ParliamentSpacing.md)
        .padding(.vertical, ParliamentSpacing.sm)
        .background(Color.parliamentCardBackground)
        .cornerRadius(ParliamentRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: ParliamentRadius.medium)
                .stroke(Color.green.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
        .padding(.top, ParliamentSpacing.xxl)
    }
}

// MARK: - Preview

#Preview {
    HostPanelView(
        roomCode: "ABC123",
        playerId: "test-player-id",
        onDismiss: {}
    )
}
