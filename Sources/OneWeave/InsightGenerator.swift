import Foundation
import SwiftData

struct CrossThreadInsight {
    let summary: String
    let affectedThreads: [String]
    let suggestedAction: String
    let realWorldBridge: String
}

class InsightGenerator {
    static func generate(from context: LifeContext, recentEvents: [TimelineEvent]) -> CrossThreadInsight {
        let energy = context.energyProfile
        let season = context.values["season"] ?? "balanced"
        let focus = context.values["focus"] ?? context.priorities.first ?? "core priorities"
        
        let eventSummary = recentEvents.prefix(5).map { "\($0.thread):\($0.type)" }.joined(separator: ", ")
        let careCount = recentEvents.filter { $0.thread == "CareKin" || $0.type.contains("care") || $0.type.contains("task") || $0.type.contains("family") }.count
        
        // Real on-device rule-based logic with actual care count from events
        if energy == .low && (careCount > 0 || season.contains("Care")) {
            return CrossThreadInsight(
                summary: "Low energy in a \(season) season after \(recentEvents.count) recent events (\(eventSummary)). Care load: \(careCount) events.",
                affectedThreads: ["Self", "CareKin", "Stewardship"],
                suggestedAction: "Simplify 2 items in Care & Kin this week. Protect \(focus) in Self.",
                realWorldBridge: "Schedule a 15-min IRL walk or analog time with family instead of another app check-in or task."
            )
        } else if recentEvents.contains(where: { $0.type.contains("leak") || $0.type.contains("subscription") }) {
            let savings = context.values["savings"] ?? "resources"
            return CrossThreadInsight(
                summary: "Stewardship activity detected. Resources may be freed (\(savings)).",
                affectedThreads: ["Stewardship", "Self", "Meaning"],
                suggestedAction: "Redirect any time/money saved toward a Self goal or Meaning legacy experience.",
                realWorldBridge: "Use one freed evening for an analog hobby or legacy project instead of digital consumption."
            )
        } else if energy == .high {
            return CrossThreadInsight(
                summary: "High energy after recent events. Momentum available. Care events: \(careCount).",
                affectedThreads: ["Self", "Meaning"],
                suggestedAction: "Advance \(focus) and ripple impact to Meaning & Legacy.",
                realWorldBridge: "Turn progress into a shareable story or family ritual."
            )
        } else {
            return CrossThreadInsight(
                summary: "\(energy.rawValue.capitalized) energy in a \(season) season. \(recentEvents.count) events logged. Care: \(careCount).",
                affectedThreads: Array(context.activeThreads.prefix(3)),
                suggestedAction: "Review Stewardship for leaks while nurturing \(focus).",
                realWorldBridge: "Choose one real-world micro-connection today (call, walk, note) over another digital task."
            )
        }
    }
}


