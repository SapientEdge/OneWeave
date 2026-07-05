import SwiftUI
import SwiftData

// QuestService: Generates, manages quests per 002-gamification spec.
// Local-only, context-aware, IRL-first, anti-addictive (reflection required for full reward).
final class QuestService {
    static let shared = QuestService()
    
    private init() {}
    
    // Starter templates (rule-based, per domains + cross)
    func generateSuggestedQuests(from context: LifeContext, recentEvents: [TimelineEvent]) -> [WeaveQuest] {
        var quests: [WeaveQuest] = []
        
        // Self domain
        quests.append(WeaveQuest(
            title: "3-day body awareness micro-practice",
            description: "Notice physical sensations 3x daily. Log one without judgment.",
            domains: ["Self"],
            baseEssence: 8,
            estimatedIRLMinutes: 5,
            validationHints: "Do this IRL now. Step away from screen."
        ))
        
        // Stewardship
        quests.append(WeaveQuest(
            title: "Audit 1 subscription leak + propose redirect",
            description: "Find one unused sub or leak. Redirect equivalent to an experience.",
            domains: ["Stewardship"],
            baseEssence: 10,
            estimatedIRLMinutes: 20,
            validationHints: "Real action: cancel or redirect savings."
        ))
        
        // CareKin
        quests.append(WeaveQuest(
            title: "Schedule + complete 1 non-digital meetup",
            description: "Plan and do a real-world connection. Log outcome + note.",
            domains: ["CareKin"],
            baseEssence: 12,
            estimatedIRLMinutes: 45,
            validationHints: "Close app. Make it happen IRL."
        ))
        
        // Meaning
        quests.append(WeaveQuest(
            title: "Capture 1 legacy memory/story",
            description: "Record a meaningful story or memory. Echo a past ripple if possible.",
            domains: ["Meaning"],
            baseEssence: 7,
            estimatedIRLMinutes: 10,
            validationHints: "Voice note or journal entry."
        ))
        
        // Cross-domain example
        if context.harmonyScore > 0.6 {
            quests.append(WeaveQuest(
                title: "Stewardship win → CareKin ripple",
                description: "Use a recent savings insight to support someone in CareKin thread.",
                domains: ["Stewardship", "CareKin"],
                baseEssence: 15,
                estimatedIRLMinutes: 30,
                validationHints: "Cross-thread action for max harmony."
            ))
        }
        
        // Low energy restoration
        if context.energyProfile == .low {
            quests.append(WeaveQuest(
                title: "Restorative micro-rest",
                description: "10 min non-digital reset. Note energy after.",
                domains: ["Self"],
                baseEssence: 5,
                estimatedIRLMinutes: 10,
                validationHints: "Grace for streak. Rest first."
            ))
        }
        
        // Limit to 3-5 active
        return Array(quests.prefix(4))
    }
    
    func acceptQuest(_ quest: WeaveQuest, context: LifeContext, modelContext: ModelContext) {
        context.activeQuests.append(quest.id)
    let qs = (try? modelContext.fetch(FetchDescriptor<WeaveQuest>())) ?? []
    context.pushSnapshotToWidgets(from: qs)
        // In full: persist quest to SwiftData
    }
    
    // Called from UI after reflection
    func completeWithReflection(questId: UUID, reflection: String, context: LifeContext, modelContext: ModelContext) {
        context.completeQuest(questId, reflection: reflection, context: modelContext)
    let qs = (try? modelContext.fetch(FetchDescriptor<WeaveQuest>())) ?? []
    context.pushSnapshotToWidgets(from: qs)
    }


    // Custom quest forge (Phase 2): spend Essence (or future premium) to create user-defined WeaveQuest.
    // Local only. Validation: title required, domains from existing, reasonable IRL estimate.
    func forgeCustomQuest(title: String, description: String, domains: [String], estimatedIRLMinutes: Int, baseEssence: Int, context: LifeContext) -> WeaveQuest? {
        if context.weaveEssence < 20 {  // cost to forge
            return nil
        }
        context.weaveEssence -= 20
        context.essenceLedger.append("-20 for custom quest forge")
        
        let forged = WeaveQuest(
            title: title,
            description: description,
            domains: domains.isEmpty ? ["Self"] : domains,
            baseEssence: max(5, min(30, baseEssence)),
            estimatedIRLMinutes: max(1, min(120, estimatedIRLMinutes))
        )
        // In real: would persist or add to suggested immediately
        return forged
    }

}
