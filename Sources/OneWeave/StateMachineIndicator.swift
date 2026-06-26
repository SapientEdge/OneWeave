import SwiftUI

/// Subtle, peripheral, non-intrusive state machine indicator.
/// Per white paper calm tech: disappears into the fabric, peripheral awareness only.
/// Shows current AppState with minimal color + icon. Tappable for detail if needed.
struct StateMachineIndicator: View {
    @Environment(AppStateMachine.self) private var stateMachine
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: stateMachine.currentState.systemImage)
                .font(.caption.weight(.medium))
                .foregroundStyle(stateMachine.currentState.color)
                .symbolEffect(.pulse, isActive: stateMachine.currentState == .weaving || stateMachine.currentState == .highFlow)
            
            Text(stateMachine.currentState.displayName)
                .font(.caption2.weight(.medium))
                .foregroundStyle(stateMachine.currentState.color.opacity(0.9))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(stateMachine.currentState.color.opacity(0.08))
        )
        .overlay(
            Capsule()
                .stroke(stateMachine.currentState.color.opacity(0.25), lineWidth: 0.5)
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: stateMachine.currentState)
        .accessibilityLabel("Current state: \(stateMachine.currentState.displayName)")
    }
}
