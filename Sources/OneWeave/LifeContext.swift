import SwiftUI
import SwiftData

@Model
final class LifeContext {
    var values: [String: String] = [:]  // e.g. "season": "High Care Load", "focus": "goal name"
    var energyProfile: EnergyProfile = .normal
    var priorities: [String] = []
    var lastUpdated: Date = Date()
    
    // Aggregated state from all threads (event-driven)
    var activeThreads: [String] = ["Self", "Stewardship", "CareKin", "Meaning"]
    var eventCount: Int = 0
    var lastEventType: String = ""
    var recentEventSummaries: [String] = []  // lightweight local aggregation, no full events

    // Formal AppStateMachine integration: persisted lightweight state for UI + feedback
    // Transitions driven by TimelineEvents in updateFromEvent
    var currentAppState: String = AppState.idle.rawValue
    var currentStateDetail: String = ""
    var lastStateTransition: Date = Date()
    
    init() {}

    // Improved event-driven aggregation from TimelineEvents
    func updateFromEvent(_ event: TimelineEvent) {
        lastUpdated = Date()
        eventCount += 1
        lastEventType = event.type
        
        // Keep lightweight recent summaries for UI/privacy (no raw payloads in summary beyond type)
        let summary = event.summary ?? "\(event.type)@\(event.thread)"
        if !recentEventSummaries.contains(summary) {
            recentEventSummaries.append(summary)
        }
        if recentEventSummaries.count > 5 {
            recentEventSummaries.removeFirst()
        }
        
        // Update energy based on event (more sophisticated than before)
        if event.affectsEnergy {
            if event.type.contains("stress") || event.type.contains("leak") || event.type.contains("overwhelm") {
                energyProfile = .low
            } else if event.type.contains("win") || event.type.contains("complete") || event.type.contains("progress") {
                energyProfile = .high
            } else {
                energyProfile = .low  // default for affectors like new goals
            }
        } else if event.type.contains("restore") || event.type.contains("rest") {
            energyProfile = .high
        }
        
        // Aggregate values from payload (e.g. season, focus)
        for (key, value) in event.payload {
            if ["season", "focus", "priority", "energy", "load"].contains(key) {
                values[key] = value
            } else if key == "goal" || key == "task" {
                values["focus"] = value
            }
        }
        
        // Update priorities from events
        if event.type == "goal_added", let goal = event.payload["goal"] {
            if !priorities.contains(goal) {
                priorities.append(goal)
            }
            values["focus"] = goal
        }
        if event.type.contains("leak") || event.type.contains("subscription") {
            values["season"] = "High Stewardship Load"
            if !priorities.contains("stewardship") {
                priorities.append("stewardship")
            }
        }
        if event.type.contains("family") || event.thread == "CareKin" {
            values["season"] = values["season"] ?? "High Care Load"
        }
        
        // Cross-thread ripple (local aggregation)
        for linked in event.linkedThreads {
            if !activeThreads.contains(linked) {
                activeThreads.append(linked)
            }
        }

        // === Formal AppStateMachine: transitions triggered by TimelineEvents ===
        // Updates currentAppState + detail so Compass/History reflect live state with colors/animations.
        applyStateTransition(from: event)
    }
    
    // Recompute aggregates from a batch of recent events (for full refresh)
    func aggregateFromRecentEvents(_ events: [TimelineEvent]) {
        // Reset lightweight state for re-agg (values/priorities can accumulate or be smart)
        // In production: more sophisticated scoring, decay etc.
        recentEventSummaries = []
        eventCount = events.count
        for event in events.prefix(10) {  // recent window
            updateFromEvent(event)  // reuses logic, last wins for simple
        }
        lastUpdated = Date()
    }
    
    // Better synthesizedInsight logic based on recent events + state
    var synthesizedInsight: String {
        let energyDesc = switch energyProfile {
        case .low: "low"
        case .high: "high"
        case .normal: "balanced"
        }
        let season = values["season"] ?? "balanced"
        let focus = values["focus"] ?? priorities.first ?? "core priorities"
        let recentCount = min(eventCount, 5)
        let stateName = (AppState(rawValue: currentAppState) ?? .idle).displayName
        
        // Event-driven, on-device logic (no external AI call)
        // Now also reflects formal AppStateMachine for psychological clarity
        if energyProfile == .low || currentAppState == AppState.lowEnergy.rawValue {
            return "[\(stateName)] Recent \(recentCount) events show \(energyDesc) energy in a \(season) season. Simplify 2 items in Care & Kin; focus on \(focus) only. (local aggregation + state)"
        } else if energyProfile == .high || currentAppState == AppState.weaving.rawValue {
            return "[\(stateName)] High energy after recent events. Advance \(focus) in Self thread and ripple to Meaning for legacy impact. (on-device insight)"
        } else if currentAppState == AppState.reflecting.rawValue {
            return "[\(stateName)] Reflecting on \(recentCount) events in \(season). Consider real-world bridges for \(focus)."
        } else {
            return "[\(stateName)] Your \(energyDesc) energy and \(season) season suggest reviewing Stewardship for leaks while nurturing \(focus). (synthesized from timeline)"
        }
    }

    // MARK: - Formal AppStateMachine Integration
    /// Apply transitions from a TimelineEvent. Mirrors AppStateMachine rules locally
    /// so that state is part of LifeContext (queryable, persists lightly across launches for UX).
    /// This is the central hook: transitions triggered by TimelineEvents.
    /// Supports full states incl. .weaving(event) representation via detail.
    func applyStateTransition(from event: TimelineEvent) {
        let type = event.type.lowercased()
        let prev = AppState(rawValue: currentAppState) ?? .idle
        var nextState = prev
        var detail = "\(event.type)@\(event.thread)"

        // Core transition rules (event-driven, aligned with examples: idle, capturing, weaving(event), reflecting, lowEnergy)
        if type.contains("capture") || type.contains("quick") || type.contains("input") {
            nextState = .capturing
            detail = "Capturing: \(event.payload.values.first ?? event.summary ?? event.type)"
        } else if type.contains("weave") || type.contains("ripple") || type.contains("goal") || type.contains("habit") || type.contains("add") || type.contains("complete") || type.contains("task") || type.contains("story") {
            nextState = .weaving
            detail = "Weaving(\(event.type)) in \(event.thread)"
            if !event.linkedThreads.isEmpty {
                detail += " → \(event.linkedThreads.joined(separator: ","))"
            }
        } else if type.contains("reflect") || type.contains("insight") || type.contains("review") || type.contains("legacy") || type.contains("story_captured") {
            nextState = .reflecting
            detail = "Reflecting on \(event.type)"
        } else if event.affectsEnergy && (type.contains("stress") || type.contains("leak") || type.contains("overwhelm") || type.contains("load") || type.contains("tired") || type.contains("care") ) {
            nextState = .lowEnergy
            detail = "Low energy from \(event.type) (\(event.thread))"
        } else if type.contains("restore") || type.contains("rest") || type.contains("win") || (event.affectsEnergy == false && type.contains("fixed")) {
            nextState = .idle
            detail = "Settled after \(event.type)"
        } else if prev == .lowEnergy && !event.affectsEnergy {
            // Recovery path
            nextState = .idle
            detail = "Recovering to idle"
        } else if (prev == .weaving || prev == .capturing) && !type.contains("capture") && !type.contains("weave") && !type.contains("add") && !type.contains("goal") {
            // Settle active states on follow-up non-active events (simulates end of flow)
            nextState = .idle
        } else {
            nextState = event.affectsEnergy ? .weaving : .idle
        }

        // Apply if changed (or refresh detail for active states)
        if nextState != prev || (nextState == .weaving || nextState == .capturing) {
            currentAppState = nextState.rawValue
            currentStateDetail = detail
            lastStateTransition = Date()
        }
    }

    /// Convenience computed property for type-safe state
    var appState: AppState {
        AppState(rawValue: currentAppState) ?? .idle
    }

    /// Time since last state change (supports decay UI logic / feedback)
    var timeInCurrentState: TimeInterval {
        Date().timeIntervalSince(lastStateTransition)
    }
}

enum EnergyProfile: String, Codable, CaseIterable {
    case low, normal, high
}

// Global best practice: Privacy - all data local-first, no external logging of raw events without consent.
// LifeContext aggregates locally only. No data leaves device unless explicit private sync.
