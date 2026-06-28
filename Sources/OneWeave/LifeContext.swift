import SwiftUI
import SwiftData

// MARK: - File-scope supporting types

/// Single essence ledger entry (audit trail for the calm, anti-addictive economy).
public struct EssenceTransaction: Codable, Identifiable, Hashable {
    public var id: UUID = UUID()
    public var amount: Double
    public var reason: String
    public var timestamp: Date = Date()
    public var thread: String? = nil

    public init(amount: Double, reason: String, timestamp: Date = Date(), thread: String? = nil) {
        self.amount = amount
        self.reason = reason
        self.timestamp = timestamp
        self.thread = thread
    }
}

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
    
    // === Full Gamification (local-only, Spec Kit 002 compliant, calm & anti-addictive) ===
    // XP/Essence tracking - earned on weaves/ripples/quests, powers level & mastery
    var weaveEssence: Double = 0
    var weaveLevel: Int = 1
    // Per-thread mastery 1=Novice ... 4=Luminary (updated on impactful events)
    var masteryTiers: [String: Int] = ["Self": 1, "Stewardship": 1, "CareKin": 1, "Meaning": 1]
    var harmonyScore: Double = 0.5
    // Streak with restorative grace (no punitive reset; lowEnergy suggests restoration)
    var globalWeaveStreak: Int = 0
    var lastActiveWeaveDate: Date = Date()
    var graceDaysUsed: Int = 0
    var maxGraceDays: Int = 2

    // Cognitive load previous reading (for trend computation).
    // Stored on the model so it survives app restarts; not exported to widgets/snapshots.
    var previousCognitiveLoadReadingJSON: String = ""

    // Active quests and completed count for retention
    
// Active quests tracking (Phase 3/6)
// Quests persist in activeQuests array; updated on accept/complete.
var activeQuests: [UUID] = []
    var completedQuestCount: Int = 0
    var essenceLedger: [String] = []
    var essenceTransactions: [EssenceTransaction] = []
    
    // Seasons: user or auto tag. On change: reflection gate, chapter summary, Essence burst.
    var currentSeason: String = "Spring"

    // T076 (GLM 5.2 round 1, cross-verified by Claude opus + Grok supergrok):
    // FamilyPod.swift:330/335/338 references `context.threads`, `context.currentSeasonName`,
    // `context.activeAmplifierName` — none of which exist. Without these computed
    // shims, `FamilyPodDigestBuilder.build` will not compile on Mac. Linux-side
    // mirror validated via validate_family_pod_builder_surface.py.
    var threads: [String] { activeThreads }
    var currentSeasonName: String { currentSeason }
    var activeAmplifierName: String? { nil }

    // === Life Graph Integration (from research - Tier 1 Life Graph + typed memory) ===
    // Extends existing threads/timeline without replacement. Enables coherence, insights, Data Leash.
    var lifeGraphEntities: [LifeEntity] = []
    var lifeGraphRelationships: [LifeRelationship] = []
    
    // Fresh unique: Overall Life Coherence Score (graph + harmony fusion)
    var lifeCoherenceScore: Double {
        LifeGraph.buildCoherenceScore(entities: lifeGraphEntities)
    }

    func pushSnapshotToWidgets(from quests: [WeaveQuest] = []) {
        let lookup = Dictionary(uniqueKeysWithValues: quests.map { ($0.id, $0) })
        let activeTitles = activeQuests.prefix(2).compactMap { lookup[$0]?.title }
        let topQuest = activeQuests.first.flatMap { lookup[$0] }
        let snap = OneWeaveSnapshot(
            harmonyScore: harmonyScore,
            weaveLevel: weaveLevel,
            weaveEssence: Int(weaveEssence),
            globalWeaveStreak: globalWeaveStreak,
            graceDaysUsed: graceDaysUsed,
            topQuestTitle: topQuest?.title,
            topQuestDomain: topQuest?.domains.first,
            activeQuestTitles: activeTitles,
            masteryTiers: masteryTiers,
            lastUpdated: Date(),
            lifeCoherenceScore: lifeCoherenceScore,
            graphEntityCount: lifeGraphEntities.count
        )
        OneWeaveSnapshotStore.shared.write(snap)
    }
  // or "High Care Load" style from values
    var seasonChangeDate: Date = Date()
    var seasonReflectionCompleted: Bool = false

    func changeSeason(to newSeason: String) {
        if newSeason != currentSeason {
            let old = currentSeason
            currentSeason = newSeason
            seasonChangeDate = Date()
            seasonReflectionCompleted = false  // gate re-arms; full +20 only on reflection commit
            values["season"] = newSeason
            // Reflection-gated burst (constitution: reflection-gated principle).
            // Award a small immediate "transition" tick so the change isn't invisible,
            // and stage the full +20 burst behind seasonReflectionCompleted = true.
            weaveEssence += 2
            essenceLedger.append("+2 season transition tick \(old) → \(newSeason) (full +20 burst pending reflection)")
        pushSnapshotToWidgets()
            harmonyScore = min(1.0, harmonyScore + 0.1)
        }
    }

    func completeSeasonReflection(note: String) {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            // Empty reflection — do nothing, do not flip the gate.
            return
        }
        if !seasonReflectionCompleted {
            seasonReflectionCompleted = true
            weaveEssence += 10
            // T107: strip reflection plaintext prefix from ledger entry (prevent export leak).
            // Was leaking 50 chars of reflection plaintext into Settings export.
            // Now logs only char count + date — no content.
            essenceLedger.append("+10 season reflection (\(trimmed.count) chars on \(Date().formatted(date: .abbreviated, time: .omitted)))")
            // Emit chapter summary event
            let summaryEvent = TimelineEvent(thread: "Meaning", type: "season_chapter_summary", payload: ["season": currentSeason, "reflection": trimmed], affectsEnergy: true)
            updateFromEvent(summaryEvent)
        }
    }
  // Phase 1 log  // lightweight log: "+5 for goal complete @Self"
    
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
        
        // === Basic Gamification: award on every ripple/weave (ties to state machine + threads) ===
        awardEssenceForEvent(event)
        updateMasteryFromEvent(event)
        updateHarmonyAndStreak(event)
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
    // Gentle decay (Phase 2): linear on long inactivity. Encourages rhythm, no hard timers or FOMO.
    // All local, tunable, anti-addictive.
    func applyGentleDecay() {
        let inactiveHours = timeInCurrentState / 3600.0
        if inactiveHours > 48 {
            let decay = min(5.0, inactiveHours * 0.05)
            if weaveEssence > 10 {
                weaveEssence = max(10, weaveEssence - decay)
                essenceLedger.append("-\(Int(decay)) gentle decay (rhythm)")
            }
            if harmonyScore > 0.5 {
                harmonyScore = max(0.5, harmonyScore - 0.01)
            }
        }
    }

    
    // MARK: - Basic Gamification (local only, tied to TimelineEvent + state machine)
    
    private func awardEssenceForEvent(_ event: TimelineEvent) {
        var amount: Double = 2.0  // base per weave/ripple - purposeful, not grindy
        
        // Multipliers for cross-thread ripples (core mechanic)
        if event.linkedThreads.count > 1 {
            amount += Double(event.linkedThreads.count) * 1.2
        }
        if event.linkedThreads.count >= 3 {
            amount += 3.0  // tasty cross-domain bonus
        }
        
        // Bonus for high-impact weave types (complete, win, quest, story, habit)
        let type = event.type.lowercased()
        if type.contains("complete") || type.contains("win") || type.contains("quest") || type.contains("story") || type.contains("habit_complete") {
            amount += 5.0
        }
        if event.affectsEnergy {
            amount += 1.0
        }
        
        weaveEssence += amount
        
        // Level up logic (simple thresholds)
        updateLevelIfNeeded()
    }
    
    private func updateLevelIfNeeded() {
        let threshold = Double(weaveLevel * 25 + 10)  // e.g. L1: ~35, L2:~60 etc - scales gently
        if weaveEssence >= threshold {
            weaveLevel += 1
            // Note: UI will show "Level Up!" feedback;
            // mastery may also advance
        }
    }
    
    private func updateMasteryFromEvent(_ event: TimelineEvent) {
        let thread = event.thread
        guard var currentTier = masteryTiers[thread] else { return }
        
        let type = event.type.lowercased()
        var masteryGain = 0
        
        // Cumulative from impactful actions + ripples (per 002 spec: ripples + validated quests + harmony)
        if type.contains("complete") || type.contains("win") || type.contains("quest") || type.contains("story_captured") || type.contains("habit_complete") || type.contains("leak_fixed") {
            masteryGain += 1
        }
        if event.linkedThreads.count > 1 {
            masteryGain += 1  // cross-ripple bonus
        }
        if event.linkedThreads.count >= 3 {
            masteryGain += 1
        }
        
        // Volume + harmony contribution (passive)
        if eventCount % 5 == 0 && harmonyScore > 0.7 {
            masteryGain += 1
        }
        
        if masteryGain > 0 {
            masteryTiers[thread] = min(4, currentTier + masteryGain)
        }
        
        // Cross-domain mastery tick for linked threads (resonance)
        for linked in event.linkedThreads {
            if let linkedTier = masteryTiers[linked], linkedTier < currentTier {
                if Int.random(in: 0..<2) == 0 {
                    masteryTiers[linked] = min(4, linkedTier + 1)
                }
            }
        }
    }
    
    private 
    func checkRestorativeGrace() {
        // Phase 5: if low activity or lowEnergy, suggest restoration; do not decrement global streak
        let now = Date()
        if now.timeIntervalSince(lastActiveWeaveDate) > 86400 * 2 {  // 2 days
            if globalWeaveStreak > 0 {
                // grace: keep streak, suggest quest
            }
        }
    }


    // Resonance/Combos (Phase 5): detect recent linkedThreads within window.
    // Award combo multiplier, boost to highFlow, surface insight.
    func detectResonance(from event: TimelineEvent) {
        // Simple window: last 3 events or recent linked
        let window = 3
        if event.linkedThreads.count >= 2 {
            // combo
            let multiplier = 1.0 + (Double(event.linkedThreads.count) * 0.5)
            weaveEssence += 2 * multiplier   // small bonus
            essenceLedger.append("+ resonance combo")
            harmonyScore = min(1.0, harmonyScore + 0.05)
            // In real UI: trigger visual chain + "Resonance unlocked"
        }
    }

    func updateHarmonyAndStreak(_ event: TimelineEvent) {
        // Harmony: based on active cross-domain coverage (ties to existing activeThreads)
        let coverage = min(4, Double(activeThreads.count))
        harmonyScore = min(1.0, 0.4 + (coverage * 0.15))
        
        // Streak with restorative grace (per 002 spec: no hard reset, suggest restoration on lowEnergy)
        let now = Date()
        let lastDay = Calendar.current.startOfDay(for: lastActiveWeaveDate)
        let today = Calendar.current.startOfDay(for: now)
        
        if lastDay != today || globalWeaveStreak == 0 {
            if energyProfile == .low && graceDaysUsed < maxGraceDays {
                graceDaysUsed += 1
                // Do not increment streak on grace, but preserve it
            } else {
                globalWeaveStreak += 1
                graceDaysUsed = 0
            }
        }
        lastActiveWeaveDate = now
        detectResonance(from: event)
        pushSnapshotToWidgets()
        
        // On high harmony or cross weave -> potential highFlow state synergy
    }
    
    /// Complete a quest with reflection. Full reward requires both a non-empty
    /// reflection (constitution: reflection-gated principle) AND at least
    /// `minReflectionChars` characters of substance (constitution: anti-bypass —
    /// prevents a 1-char "ok" from earning the full 10 essence). Empty/whitespace
    /// reflection yields the partial "engagement" reward only. Short-but-non-empty
    /// reflection yields partial.
    /// T075 (GLM 5.2 round 1, cross-verified): FamilyPod enforces a 20-char gate
    /// via `minExitReflectionChars`; completeQuest was inconsistent (accepted 1 char).
    func completeQuest(_ questId: UUID, reflection: String, context: ModelContext) {
        let trimmed = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
        let minChars = 20  // mirrors FamilyPod.minExitReflectionChars
        let bonus: Int
        let reason: String
        if trimmed.isEmpty {
            bonus = 3
            reason = "quest complete (no reflection)"
        } else if trimmed.count >= minChars {
            bonus = 10
            reason = "quest complete with reflection"
        } else {
            bonus = 3
            reason = "quest complete (short reflection: \(trimmed.count)/\(minChars) chars)"
        }
        weaveEssence += bonus
        completedQuestCount += 1
        activeQuests.removeAll { $0 == questId }

        // Update mastery/harmony/streak
        let questEvent = TimelineEvent(
            type: "quest_completed",
            thread: "Self", // default
            summary: "Quest completed",
            payload: ["reflection": trimmed],  // store trimmed; never the raw input
            linkedThreads: ["Self"],
            affectsEnergy: true
        )
        updateFromEvent(questEvent)

        // Log to ledger
        essenceLedger.append("+\(bonus) for \(reason)")
        if essenceLedger.count > 20 { essenceLedger.removeFirst() }
    }
    
    /// Public helper for quest completions etc to award bonus

// Phase 2 essence economy (production amplifiers)
enum Amplifier: String, CaseIterable {
    case selfFocus = "SelfFocus"
    case redirectLens = "RedirectLens"
    case insightMagnifier = "InsightMagnifier"
    case streakShield = "StreakShield"
    case echoBoost = "EchoBoost"
}

extension LifeContext {
    
    // Echo (Phase 2): revisit past event/quest for insight + small essence + Meaning ripple. Integrate with MeaningThread.
    func echoPastEvent(eventId: UUID? = nil) {
        // production: lookup past TimelineEvent, award small essence, emit resonance to Meaning.
        weaveEssence += 1
        essenceLedger.append("+1 for echo")
        pushSnapshotToWidgets()
    }

    func spendEssenceForAmplifier(_ amp: Amplifier, amount: Double = 10) -> Bool {
        if weaveEssence < amount {
            return false
        }
        // Anti-spam: simple cooldown check via time (local only)
        if timeInCurrentState < 60 && amp != .streakShield {  // short window
            return false
        }
        weaveEssence -= amount
        pushSnapshotToWidgets()
        essenceLedger.append("-\(Int(amount)) for \(amp.rawValue) amplifier")
        
        // Apply temporary boost (calm, state-influenced, no FOMO)
        switch amp {
        case .selfFocus:
            harmonyScore = min(1.0, harmonyScore + 0.1)  // gentle focus boost
        case .redirectLens:
            // Would bias next suggestions toward Stewardship-like in real QuestService
            break
        case .insightMagnifier:
            harmonyScore = min(1.0, harmonyScore + 0.08)
        case .streakShield:
            if graceDaysUsed > 0 {
                graceDaysUsed -= 1  // protective
            }
        case .echoBoost:
            // Boosts echo value in echoPastEvent
            break
        }
        updateLevelIfNeeded()
        return true
    }
}

    func awardBonusEssence(_ amount: Double, reason: String = "weave") {
        weaveEssence += amount
        updateLevelIfNeeded()
        pushSnapshotToWidgets()
    }
    
    /// Computed for UI progress (tasty level badge)
    var levelProgress: Double {
        let threshold = Double(weaveLevel * 25 + 10)
        let prev = Double((weaveLevel - 1) * 25 + 10)
        let span = max(1.0, threshold - prev)
        return max(0, min(1.0, (weaveEssence - prev) / span))
    }
    
    var essenceDisplay: String {
        "✧ \(Int(weaveEssence))"
    }
}

enum EnergyProfile: String, Codable, CaseIterable {
    case low, normal, high
}

// Global best practice: Privacy - all data local-first, no external logging of raw events without consent.
// LifeContext aggregates locally only. No data leaves device unless explicit private sync.

// EssenceTransaction model (lightweight on-device ledger)