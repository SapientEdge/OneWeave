import Foundation
import SwiftData

// Novel Feature: Resonance Oracle - Local Decision Simulator
// No one has built this: Embodied foresight by simulating impact on your entire Life Graph.
// User inputs a scenario. App runs a private simulation using current graph + patterns.
// Outputs coherence delta, thread ripples, essence cost, and suggested micro-weaves.
// All local, calm, requires reflection before 'committing' to a weave.

struct ResonanceSimulation {
    let scenario: String
    let coherenceDelta: Double  // -1.0 to +1.0 predicted change
    let threadRipples: [String: Double]  // e.g. ["CareKin": +0.15, "Stewardship": -0.08]
    let essenceCost: Double
    let harmonyImpact: Double
    let suggestedMicroWeaves: [String]
    let riskNotes: [String]
    let timestamp: Date
}

struct ResonanceOracle {
    
    static func simulate(scenario: String, context: LifeContext) -> ResonanceSimulation {
        // Local simulation - no cloud. Uses current graph state + simple learned patterns from history.
        let currentCoherence = context.lifeCoherenceScore
        let entityCount = Double(context.lifeGraphEntities.count)
        
        // Heuristic model (in real: small on-device model or rules from user's history)
        var predictedDelta = 0.0
        var ripples: [String: Double] = [:]
        var cost = 5.0
        var harmony = 0.0
        var suggestions: [String] = []
        var risks: [String] = []
        
        let lower = scenario.lowercased()
        
        // Domain detection
        if lower.contains("family") || lower.contains("partner") || lower.contains("kids") {
            ripples["CareKin"] = 0.18
            ripples["Self"] = 0.05
            predictedDelta += 0.12
            suggestions.append("Weave a small CareKin ritual into the decision (e.g., shared reflection)")
        }
        
        if lower.contains("work") || lower.contains("project") || lower.contains("deadline") {
            ripples["Stewardship"] = 0.22
            ripples["Meaning"] = -0.07
            predictedDelta -= 0.05
            cost += 8
            risks.append("Potential over-investment in Stewardship at expense of Meaning")
        }
        
        if lower.contains("health") || lower.contains("sleep") || lower.contains("exercise") || lower.contains("rest") {
            ripples["Self"] = 0.25
            predictedDelta += 0.15
            harmony += 0.08
            suggestions.append("Link this to your Body Thread - schedule a health weave first")
        }
        
        if lower.contains("money") || lower.contains("finance") || lower.contains("budget") {
            ripples["Stewardship"] = 0.10
            cost += 3
        }
        
        // Graph density effect (more connected life = bigger ripples)
        let densityBonus = min(0.1, entityCount / 50.0)
        predictedDelta += densityBonus
        
        // Clamp
        predictedDelta = max(-0.4, min(0.4, predictedDelta))
        
        // Creative: "What if" suggestions based on graph
        if !suggestions.isEmpty {
            suggestions.append("Run a small test weave for 3 days and measure actual coherence change")
        }
        
        if risks.isEmpty && predictedDelta < 0.05 {
            risks.append("Low predicted resonance - consider if this aligns with your current high-coherence threads")
        }
        
        return ResonanceSimulation(
            scenario: scenario,
            coherenceDelta: predictedDelta,
            threadRipples: ripples,
            essenceCost: cost,
            harmonyImpact: harmony,
            suggestedMicroWeaves: suggestions,
            riskNotes: risks,
            timestamp: Date()
        )
    }
    
    // After simulation, user can "commit" a weave - creates entity + requires reflection
    @MainActor
    static func commitWeave(from simulation: ResonanceSimulation, into context: LifeContext, userReflection: String, modelContext: ModelContext? = nil) {
        guard !userReflection.trimmingCharacters(in: .whitespaces).isEmpty else {
            print("[Oracle] Reflection gate: Must reflect before committing")
            return
        }

        let entity = LifeEntity(
            type: .concept,
            title: "Decision: \(String(simulation.scenario.prefix(40)))",
            summary: "Simulated resonance: \(String(format: "%.2f", simulation.coherenceDelta)) coherence. Reflection: \(userReflection)",
            memoryType: .procedural
        )
        entity.domains = Array(simulation.threadRipples.keys)
        entity.harmonyImpact = simulation.harmonyImpact + simulation.coherenceDelta * 0.5

        if let mc = modelContext {
            mc.insert(entity)
        }
        context.lifeGraphEntities.append(entity)

        // Apply gentle predicted impact (actual will come from future data)
        context.harmonyScore = max(0, min(1.0, context.harmonyScore + simulation.harmonyImpact * 0.3))

        // Create reflection event
        let event = TimelineEvent(
            thread: "Self",
            type: "oracle_commit",
            payload: [
                "scenario": simulation.scenario,
                "reflection": userReflection,
                "delta": String(format: "%.3f", simulation.coherenceDelta)
            ]
        )
        if let mc = modelContext {
            mc.insert(event)
        }
        context.updateFromEvent(event)

        // Keep widget timeline in sync after a commit. Claude cycle-14 finding.
        let quests: [WeaveQuest] = (try? modelContext?.fetch(FetchDescriptor<WeaveQuest>())) ?? []
        context.pushSnapshotToWidgets(from: quests)

        // New entity written — insight cache is now stale. Force regeneration
        // next read so the Insight Engine sees the new graph node. Tier A #1.
        GraphInsightGenerator.invalidateCache()

        print("[Oracle] Weave committed. Predicted delta applied gently. Actual coherence will be measured over time.")
    }
}

// Usage in prototype / Command Palette:
// let sim = ResonanceOracle.simulate(scenario: "Taking on extra project this month", context: lifeContext)
// Then show UI with sim results + commit button that requires reflection text.
