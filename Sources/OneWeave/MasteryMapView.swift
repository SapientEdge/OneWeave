import SwiftUI
import SwiftData

// Phase 5 Mastery Map: calm grid/list showing tiers, progress, suggested review/echo actions.
// Tap domain for "echo practice" (simulates review + small resonance/essence + mastery tick if low).
// Local-only, no punitive, reflection-aware. Integrated in Prototype + accessible via Compass nav.
struct MasteryMapView: View {
    @Query private var contexts: [LifeContext]
    @Environment(\.modelContext) private var modelContext
    @State private var feedback: String = ""
    
    private let domains = ["Self", "Stewardship", "CareKin", "Meaning"]
    
    var body: some View {
        if let ctx = contexts.first {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("🗺️ Mastery Map")
                        .font(.title2.bold())
                    Text("Tiers grow from real ripples, quests, and cross-harmony. Tap to review/echo a domain (calm practice).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    // Grid of mastery cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(domains, id: \.self) { domain in
                            let tier = ctx.masteryTiers[domain] ?? 1
                            let progress = Double(tier) / 4.0
                            Button {
                                practiceEcho(domain: domain, ctx: ctx)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(domain)
                                            .font(.headline)
                                        Spacer()
                                        Text("L\(tier)")
                                            .font(.caption.bold())
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(tierColor(tier).opacity(0.2))
                                            .clipShape(Capsule())
                                    }
                                    // Visual bar for progress to next tier (calm)
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule()
                                                .fill(Color.gray.opacity(0.15))
                                                .frame(height: 6)
                                            Capsule()
                                                .fill(tierColor(tier))
                                                .frame(width: geo.size.width * progress, height: 6)
                                        }
                                    }
                                    .frame(height: 6)
                                    
                                    Text(tierDescription(tier))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    
                                    Text("Tap to echo/review")
                                        .font(.caption2)
                                        .foregroundStyle(.blue)
                                }
                                .padding(10)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Global stats + harmony
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Global: Harmony \(Int(ctx.harmonyScore * 100))% • Essence \(ctx.essenceDisplay) • Streak \(ctx.globalWeaveStreak) (grace protected)")
                            .font(.caption)
                        Text("Completed quests: \(ctx.completedQuestCount) (reflections drive full mastery)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.top)
                    
                    if !feedback.isEmpty {
                        Text(feedback)
                            .font(.caption)
                            .foregroundStyle(.green)
                            .padding(8)
                            .background(Color.green.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    Text("Anti-addictive: Echoes give insight + small boost. No streaks broken. All local.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
                }
                .padding()
            }
        } else {
            Text("No LifeContext yet. Seed in Prototype or Compass.")
                .padding()
        }
    }
    
    private func tierColor(_ tier: Int) -> Color {
        switch tier {
        case 4: return .purple
        case 3: return .indigo
        case 2: return .blue
        default: return .gray
        }
    }
    
    private func tierDescription(_ tier: Int) -> String {
        switch tier {
        case 4: return "Luminary • Legacy weaver"
        case 3: return "Expert • Deep ripples"
        case 2: return "Practitioner • Consistent"
        default: return "Novice • Starting weave"
        }
    }
    
    private func practiceEcho(domain: String, ctx: LifeContext) {
        // Echo enhancement: simulate review of domain -> small essence, possible mastery tick, harmony bump, new ripple event
        let oldTier = ctx.masteryTiers[domain] ?? 1
        var gain = 0.5
        if oldTier < 4 && Int.random(in: 0..<3) == 0 {
            ctx.masteryTiers[domain] = min(4, oldTier + 1)
            gain = 2
        }
        ctx.weaveEssence += gain
        ctx.harmonyScore = min(1.0, ctx.harmonyScore + 0.05)
        
        // Emit echo event for ripples / Meaning boost
        let echoEvent = TimelineEvent(
            thread: domain == "Meaning" ? domain : "Meaning",
            type: "echo_review",
            payload: ["echoed": domain, "insight": "Reviewed mastery in \(domain)"],
            affectsEnergy: false,
            linkedThreads: [domain]
        )
        // Note: would use service but for view, direct update simulates
        ctx.updateFromEvent(echoEvent)
        
        feedback = "Echoed \(domain) (L\(oldTier)→L\(ctx.masteryTiers[domain] ?? oldTier)). +\(Int(gain)) Essence • Resonance ripple."
        
        // Auto clear feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            feedback = ""
        }
    }
}
