import SwiftData
import Foundation

// Enhanced MeaningThread per OneWeave spec and USER_JOURNEYS_ONEWEAVE.md.
// Meaning & Legacy thread: reflection, stories, niche projects, legacy capture.
//
// Features:
// - story/legacy capture: captureStory(), captureLegacy() — both call TimelineService.emitEvent + LifeContext update for EVERY action.
// - processEvent for ripples from other threads (Self goals/habits, Stewardship leaks/savings, CareKin tasks) — adds insights + proactively emits ripple events + suggestions.
// - suggestions linking to Self/Care: suggestLinkToSelfCare(), suggestLegacyForSelfGoal() — generates and stores suggestions that weave Self progress or Care moments into legacy stories/experiences.
// - Aligns with journeys: "Freed resources from leak → legacy experience?", "Started training despite care load — modeling resilience for kids", high-energy ripple to Meaning.
// - Event-driven: capture links back to ["Self", "CareKin"]; processEvent emits "legacy_suggestion", "family_legacy_suggestion" etc. with linkedThreads.
// - Testable: legacySummary(), clearForTesting(), direct calls in prototype/Compass.
// 
// Privacy / global best practices: local-only (SwiftData @Model), no-training (on-device rule-based; ). 
// All data (stories, legacies, suggestions) stays on device. Real-world focus: analog stories, family rituals over digital. References constitution + spec journeys.
// See also: TimelineService.swift (emit with linked), LifeContext (agg + insight), InsightGenerator (mentions legacy), Thread.swift (protocol + default bridge).

@Model
final class MeaningThread: ThreadProtocol {
    var name: String = "Meaning"
    
    // Core persisted state (stories + legacyGoals as before; extended for suggestions)
    var stories: [String] = []
    var legacyGoals: [String] = []
    
    // Suggestions specifically linking Meaning to Self (habits/goals) and Care (family/kin moments)
    var legacySuggestions: [String] = []
    
    var recentInsights: [String] = []
    
    // Local activity log (private, compacted)
    var activityLog: [String] = []
    
    init() {}
    
    // MARK: - Story / Legacy Capture (MUST call service per task + patterns)
    
    func captureStory(_ story: String, service: TimelineService? = nil, context: LifeContext? = nil) {
        guard !story.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let cleanStory = story.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !stories.contains(cleanStory) {
            stories.append(cleanStory)
        }
        
        logActivity("Captured story: \(cleanStory)")
        
        let payload: [String: String] = ["story": cleanStory]
        let event = TimelineEvent(thread: name, type: "story_captured", payload: payload)
        
        // Primary path: call service (emits, persists, notifies LifeContext, handles linked ripples)
        if let svc = service {
            svc.emitEvent(
                thread: name,
                type: "story_captured",
                payload: payload,
                affectsEnergy: false,
                linkedThreads: ["Self", "CareKin"]  // per task: suggestions linking to Self/Care
            )
        }
        
        if let ctx = context {
            ctx.updateFromEvent(event)
        }
        
        recentInsights.append("Story captured — weaves real-world legacy. Link to Self progress or CareKin moments?")
        if recentInsights.count > 8 { recentInsights.removeFirst() }
    }
    
    func captureLegacy(_ legacy: String, linkedTo: String = "Self/Care", service: TimelineService? = nil, context: LifeContext? = nil) {
        guard !legacy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let cleanLegacy = legacy.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !legacyGoals.contains(cleanLegacy) {
            legacyGoals.append(cleanLegacy)
        }
        
        logActivity("Legacy captured: \(cleanLegacy) (linked to \(linkedTo))")
        
        let payload: [String: String] = [
            "legacy": cleanLegacy,
            "linkedTo": linkedTo
        ]
        
        if let svc = service {
            svc.emitEvent(
                thread: name,
                type: "legacy_captured",
                payload: payload,
                affectsEnergy: false,
                linkedThreads: ["Self", "CareKin"]
            )
        }
        
        if let ctx = context {
            let ev = TimelineEvent(
                thread: name,
                type: "legacy_captured",
                payload: payload,
                affectsEnergy: false,
                linkedThreads: ["Self", "CareKin"]
            )
            ctx.updateFromEvent(ev)
        }
        
        recentInsights.append("Legacy goal/experience captured: \(cleanLegacy). Suggest integrating with Self habits or Care family rituals.")
        if recentInsights.count > 8 { recentInsights.removeFirst() }
    }
    
    // MARK: - Suggestions linking to Self/Care (new per task)
    
    /// Generates (and stores) a suggestion explicitly linking Meaning legacy to Self goals/habits or CareKin moments.
    /// Real-world bridge emphasis: analog, family, non-digital.
    func suggestLinkToSelfCare(context: LifeContext? = nil) -> String {
        let focus = context?.values["focus"] ?? context?.priorities.first ?? "current Self goals/habits"
        let season = context?.values["season"] ?? "your current season"
        
        let suggestion = "Link '\(focus)' (Self) to a Meaning legacy story. Weave Care & Kin moments from \(season) into an analog family ritual or shareable story for future generations. Choose IRL over more apps."
        
        if !legacySuggestions.contains(suggestion) {
            legacySuggestions.append(suggestion)
        }
        
        if !recentInsights.contains(suggestion) {
            recentInsights.append(suggestion)
            if recentInsights.count > 8 { recentInsights.removeFirst() }
        }
        
        logActivity("Generated Self/Care legacy link suggestion")
        return suggestion
    }
    
    func suggestLegacyForSelfGoal(goal: String) -> String {
        let s = "Progress on Self goal '\(goal)' is legacy in action — capture the story now: resilience, values modeled, or long-term impact?"
        if !legacySuggestions.contains(s) {
            legacySuggestions.append(s)
        }
        recentInsights.append(s)
        if recentInsights.count > 8 { recentInsights.removeFirst() }
        return s
    }
    
    func suggestLegacyForCareMoment(task: String) -> String {
        let s = "Care & Kin task '\(task)' is quiet legacy-building. Capture the story for family history or ritual."
        if !legacySuggestions.contains(s) {
            legacySuggestions.append(s)
        }
        recentInsights.append(s)
        if recentInsights.count > 8 { recentInsights.removeFirst() }
        return s
    }
    
    // MARK: - Logging (local, private)
    
    func logActivity(_ note: String) {
        let ts = Date().formatted(date: .omitted, time: .shortened)
        activityLog.append("[\(ts)] \(note)")
        if activityLog.count > 25 {
            activityLog.removeFirst()
        }
    }
    
    // MARK: - Real processEvent for ripples from other threads (spec journeys + task req)
    
    func processEvent(_ event: TimelineEvent, context: LifeContext, service: TimelineService) {
        logActivity("Ripple received: \(event.type) from \(event.thread)")
        
        var rippleInsight = false
        
        if event.thread == "Self" && (event.type.contains("goal") || event.type.contains("habit") || event.type.contains("completed") || event.type.contains("progress")) {
            let trigger = event.payload.values.first ?? "Self activity"
            let msg = "Self progress (\(trigger)) — opportunity for legacy capture or story."
            if !recentInsights.contains(msg) {
                recentInsights.append(msg)
            }
            rippleInsight = true
            
            // Call service (ripple suggestion back)
            service.emitEvent(
                thread: name,
                type: "legacy_suggestion_from_self",
                payload: ["trigger": event.type, "sourcePayload": trigger],
                affectsEnergy: false,
                linkedThreads: ["Self"]
            )
            
            if let g = event.payload["goal"] ?? event.payload["habit"] {
                _ = suggestLegacyForSelfGoal(goal: g)
            }
            
        } else if event.thread == "Stewardship" && (event.type.contains("leak") || event.type.contains("savings") || event.type.contains("subscription") || event.type.contains("cancel")) {
            let msg = "Freed resources from Stewardship (leak/savings) — redirect to Meaning legacy experience?"
            if !recentInsights.contains(msg) {
                recentInsights.append(msg)
            }
            rippleInsight = true
            
            service.emitEvent(
                thread: name,
                type: "legacy_opportunity",
                payload: ["from": "Stewardship", "type": event.type],
                affectsEnergy: false,
                linkedThreads: ["Self", "CareKin"]
            )
            
            _ = suggestLinkToSelfCare(context: context)
            
        } else if event.thread == "CareKin" && (event.type.contains("task") || event.type.contains("family") || event.type.contains("irl") || event.type.contains("added")) {
            let trigger = event.payload.values.first ?? "Care moment"
            let msg = "Care & Kin moments (\(trigger)) build legacy — capture as family story?"
            if !recentInsights.contains(msg) {
                recentInsights.append(msg)
            }
            rippleInsight = true
            
            service.emitEvent(
                thread: name,
                type: "family_legacy_suggestion",
                payload: ["from": "CareKin", "trigger": trigger],
                affectsEnergy: false,
                linkedThreads: ["CareKin", "Self"]
            )
            
            if let t = event.payload["task"] {
                _ = suggestLegacyForCareMoment(task: t)
            }
            
        } else if event.type.contains("story") || event.type.contains("legacy") || event.thread == name {
            recentInsights.append("Meaning activity compounding — legacy threads strengthening.")
        }
        
        // Always refresh on ripple (mirrors Self pattern)
        if recentInsights.count > 10 {
            recentInsights.removeFirst()
        }
        
        if rippleInsight {
            // Emit internal ripple processed event (updates context like in Self)
            let rippleEvent = TimelineEvent(
                thread: name,
                type: "meaning_ripple",
                payload: ["sourceThread": event.thread, "sourceType": event.type]
            )
            context.updateFromEvent(rippleEvent)
        }
    }
    
    // MARK: - Helpers & testing (for prototype, Compass, verification)
    
    func legacySummary() -> String {
        let st = stories.isEmpty ? "none" : stories.prefix(2).joined(separator: ", ")
        let lg = legacyGoals.isEmpty ? "none" : legacyGoals.prefix(2).joined(separator: ", ")
        let sg = legacySuggestions.count
        return "Stories[\(st)] Legacies[\(lg)] Suggestions:\(sg) Insights:\(recentInsights.count) Logs:\(activityLog.count)"
    }
    
    func clearForTesting() {
        stories.removeAll()
        legacyGoals.removeAll()
        legacySuggestions.removeAll()
        recentInsights.removeAll()
        activityLog.removeAll()
    }


    // Uniform .summary() for ThreadsOverviewView (delegates to detailed legacySummary)
    func summary() -> String { return legacySummary() }

}

// Global best practice: Focuses on real-world legacy and analog stories. 
// All capture/processing is local-only. Suggestions push toward IRL/family/analog (e.g. "choose IRL over more apps").
// Future: on-device Foundation Models could enhance story generation or pattern detection here (with no-training prefix).
// Usage examples (call from ThreadDetailView, prototype, or quick-capture routing):
//   let meaning = MeaningThread()
//   meaning.captureStory("Started training despite care load — modeling resilience for kids", service: svc, context: ctx)
//   meaning.captureLegacy("Fund family analog project with leak savings", linkedTo: "Self/Care", service: svc)
//   let link = meaning.suggestLinkToSelfCare(context: ctx)
//   meaning.processEvent(stewardshipLeakEvent, context: ctx, service: svc)
//   print(meaning.legacySummary())
