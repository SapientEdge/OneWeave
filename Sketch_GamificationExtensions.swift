// OneWeave Gamification Sketch Extensions (for reference / incremental impl)
// Drop into Sources/OneWeave/ alongside existing models.
// All local SwiftData. Follows existing patterns (TimelineEvent emission, LifeContext updates, ThreadProtocol).
// See ONEWEAVE_GAMIFICATION_SPEC.md for full details.

import SwiftData
import Foundation
import SwiftUI

// Extend existing LifeContext (additive, non-breaking)
extension LifeContext {
    var weaveEssence: Double = 0
    var weaveLevel: Int = 1
    var masteryTiers: [String: Int] = ["Self": 1, "Stewardship": 1, "CareKin": 1, "Meaning": 1]  // 1=Novice ... 4=Luminary
    var harmonyScore: Double = 0.5  // 0-1 balance across domains
    
    // Called from existing updateFromEvent or new QuestService
    func awardEssence(_ amount: Double, source: String) {
        weaveEssence += amount
        // Recalculate level / harmony (simple rule-based for MVP)
        if weaveEssence > Double(weaveLevel * 25) { weaveLevel += 1 }
        // Harmony from recent cross-domain events (tie to existing recentEventSummaries)
    }
}

// New Quest model (SwiftData)
@Model
final class WeaveQuest {
    @Attribute(.unique) var id: UUID = UUID()
    var title: String
    var prompt: String
    var domains: [String]          // e.g. ["Stewardship", "CareKin"]
    var baseEssence: Double
    var status: QuestStatus = .available
    var acceptedAt: Date?
    var completedAt: Date?
    var linkedEventID: UUID?       // Ties to TimelineEvent on completion
    var reflectionNote: String?    // Required for full reward (anti-addiction)
    
    enum QuestStatus: String, Codable { case available, active, completed, archived }
    
    init(title: String, prompt: String, domains: [String], baseEssence: Double = 10) {
        self.title = title
        self.prompt = prompt
        self.domains = domains
        self.baseEssence = baseEssence
    }
}

// QuestService sketch (integrates with existing TimelineService + LifeContext)
@Observable
final class QuestService {
    private let modelContext: ModelContext
    private let timelineService: TimelineService
    
    init(modelContext: ModelContext, timelineService: TimelineService) {
        self.modelContext = modelContext
        self.timelineService = timelineService
    }
    
    func completeQuest(_ quest: WeaveQuest, reflection: String, realWorldEvidence: String? = nil) {
        guard quest.status == .active else { return }
        
        quest.completedAt = Date()
        quest.status = .completed
        quest.reflectionNote = reflection
        
        // Emit rich ripple event (core mechanic)
        let payload: [String: String] = [
            "quest": quest.title,
            "domains": quest.domains.joined(separator: ","),
            "reflection": reflection.prefix(120),
            "evidence": realWorldEvidence ?? "self-reported"
        ]
        
        timelineService.emitEvent(
            thread: quest.domains.first ?? "Meaning",
            type: "quest_completed",
            payload: payload,
            affectsEnergy: true,
            linkedThreads: Array(Set(quest.domains + ["Meaning"])),  // always ripple to Meaning
            summary: "Completed: \(quest.title)"
        )
        
        // Award economy + update context (extends existing)
        if let ctx = try? modelContext.fetch(FetchDescriptor<LifeContext>()).first {
            let multiplier = quest.domains.count > 1 ? 1.5 : 1.0
            let awarded = quest.baseEssence * multiplier
            ctx.awardEssence(awarded, source: "quest")
            // Update mastery/harmony as needed
        }
        
        // Optional: trigger calm celebration hook (haptics + state)
    }
    
    // Simple rule-based + context-aware generator (expand with on-device FM later)
    func generateStarterQuests() -> [WeaveQuest] {
        // Pull from LifeContext / recent events for personalization
        return [
            WeaveQuest(title: "Redirect Savings to IRL", prompt: "Find one leak. Redirect value to a real shared experience.", domains: ["Stewardship", "CareKin"], baseEssence: 18),
            WeaveQuest(title: "Echo Legacy Story", prompt: "Revisit one past Meaning entry. Add one new reflection or connection to current Self habit.", domains: ["Meaning", "Self"], baseEssence: 12)
        ]
    }
}

// Usage in existing flow (e.g. CompassView or new Quests tab)
// After logging/completing:
// questService.completeQuest(quest, reflection: userNote, realWorldEvidence: "photo logged locally")

// Extend ThreadRingView / Compass for mastery visuals + tapestry hints (sketch)
// struct EnhancedThreadRing: View { ... mastery glow, small essence delta, etc. }

// Anti-addiction hook example (call after completion):
// func enforceReflectionGate(quest: WeaveQuest) { if quest.reflectionNote == nil { /* prompt */ } }

// All additions preserve zero-trust local-only, event-driven ripples, calm UI principles.
