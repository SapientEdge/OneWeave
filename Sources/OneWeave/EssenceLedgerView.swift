import SwiftUI
import SwiftData

// Phase 6: Simple Essence Ledger view. Calm list of transactions + summary.
// Local-only. Ties to LifeContext. Reusable in prototype/Compass/Settings.
struct EssenceLedgerView: View {
    @Query private var contexts: [LifeContext]
    
    var body: some View {
        if let ctx = contexts.first {
            VStack(alignment: .leading, spacing: 12) {
                Text("✧ Essence Ledger")
                    .font(.title2.bold())
                Text("Track real ripples. All local. No grind.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Text("Current: \(ctx.essenceDisplay)")
                        .font(.headline)
                    Spacer()
                    Text("Lvl \(ctx.weaveLevel) • Harmony \(Int(ctx.harmonyScore * 100))%")
                        .font(.caption)
                }
                
                Divider()
                
                if ctx.essenceLedger.isEmpty {
                    Text("No entries yet. Weave, complete quests, or echo to start.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(ctx.essenceLedger.suffix(20).reversed(), id: \.self) { entry in
                                HStack {
                                    Text(entry)
                                        .font(.caption)
                                    Spacer()
                                }
                                .padding(6)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
                
                Text("Anti-addictive: Ledger shows purpose, not pressure. Export includes this.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }
            .padding()
        } else {
            Text("Seed LifeContext in Prototype first.")
                .padding()
        }
    }
}
