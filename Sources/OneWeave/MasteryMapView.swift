import SwiftUI
import SwiftData

// Phase 5/6 stub: Mastery Map view (calm list of tiers + suggested quests per domain)
struct MasteryMapView: View {
    @Query private var contexts: [LifeContext]
    
    var body: some View {
        if let ctx = contexts.first {
            VStack(alignment: .leading, spacing: 12) {
                Text("Mastery Map")
                    .font(.headline)
                ForEach(["Self", "Stewardship", "CareKin", "Meaning"], id: \.self) { domain in
                    let tier = ctx.masteryTiers[domain] ?? 1
                    HStack {
                        Text(domain)
                        Spacer()
                        Text("Tier \(tier)")
                            .font(.caption)
                            .padding(4)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    // Simple suggested quest hint
                    Text("Next: Advance \(domain) via cross-ripple or quest")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text("Harmony: \(Int(ctx.harmonyScore * 100))% • Essence: \(ctx.essenceDisplay)")
                    .font(.caption)
            }
            .padding()
        }
    }
}
