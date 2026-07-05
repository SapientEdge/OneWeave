import SwiftUI

struct WeaveSummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var contexts: [LifeContext]
    @Environment(AppStateMachine.self) private var stateMachine
    
    var body: some View {
        if let ctx = contexts.first {
            VStack(alignment: .leading, spacing: 4) {
                Text("Weave State")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Label(stateMachine.currentState.displayName, systemImage: stateMachine.currentState.systemImage)
                        .font(.caption.bold())
                        .foregroundStyle(stateMachine.currentState.color)
                    
                    Text("·")
                    Text("Energy: \(ctx.energyProfile.rawValue)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(6)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .sensoryFeedback(.selection, trigger: stateMachine.currentState)
        }
    }
}