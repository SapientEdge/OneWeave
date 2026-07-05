//
//  RelationshipDecayTracker.swift
//  OneWeave
//
//  Relationship Decay Tracking — passive signal that surfaces "you haven't
//  connected with X in N days" prompts based on the user's cadence.
//
//  Why this exists:
//    Research blueprint §7 calls this a "high impact, medium complexity"
//    feature. The basic insight: relationships decay on a curve, and most
//    people lose touch with important people not because they don't care,
//    but because no signal prompts them to reach out. A gentle prompt
//    ("you haven't talked to Mom in 23 days; your cadence is every 14")
//    closes the loop without nagging.
//
//  Data sources:
//    1. LifeEntity of kind .person with `domains` containing "CareKin"
//       (matches the existing Family Pod heir logic — same consent model).
//    2. Calendar co-presence: TimelineEvents where the person is mentioned.
//    3. Journal/reflection entities that mention the person by name
//       (entity references; the LifeGraph already links these).
//    4. Explicit interaction records (we keep an InteractionRecord per
//       person: timestamp + channel + brief note).
//
//  Privacy model:
//    - All data is already in LifeContext / LifeGraph. No new data sources.
//    - Cadence defaults are user-configurable (per person or global).
//    - Decay is NEVER publicly broadcast; only the user sees their own list.
//    - The prompt itself is calm: "Reach out?" — never "you're neglecting X."
//
//  Design pillars:
//    1. No judgment. The math is descriptive, not moral.
//    2. User-tuned. The user sets the cadence for each person; we never
//       impose a default like "every 7 days."
//    3. Reflection-gated. Suggesting a heavy outreach (e.g., "you haven't
//       had a deep talk in 90 days") requires the user to write a one-line
//       intent before the prompt becomes actionable.
//    4. Quiet by default. The morning briefing surfaces at most one
//       decay prompt per day, never the whole list.
//    5. Anti-nag. After surfacing a prompt, we suppress that person for
//       `suppressionDays` so we don't ask again tomorrow.
//
//  What this file does NOT contain:
//    - The actual outreach (no messaging, no calendar event creation).
//      Mac side wires that to Reminders or Calendar.
//    - A real LifeGraph query implementation. We define the input shape
//      and the algorithm; the Mac side wires to SwiftData.
//
//  Test coverage is in .research/validate_relationship_decay.py.
//

import Foundation

// MARK: - Public types

/// A relationship record per person the user cares about.
public struct RelationshipRecord: Codable, Equatable {
    public let lifeEntityID: String
    public let displayName: String
    public let lastInteractionAt: Date
    public let cadenceDays: Int              // user-set; default 14
    public let relationshipKind: RelationshipKind
    public let domains: [String]
    public let suppressionDays: Int          // suppress from prompts for N days after surfacing

    public init(
        lifeEntityID: String,
        displayName: String,
        lastInteractionAt: Date,
        cadenceDays: Int = 14,
        relationshipKind: RelationshipKind = .friend,
        domains: [String] = [],
        suppressionDays: Int = 7
    ) {
        self.lifeEntityID = lifeEntityID
        self.displayName = displayName
        self.lastInteractionAt = lastInteractionAt
        self.cadenceDays = max(1, cadenceDays)
        self.relationshipKind = relationshipKind
        self.domains = domains
        self.suppressionDays = max(0, suppressionDays)
    }
}

/// Kind of relationship — affects the cadence hint + prompt framing.
public enum RelationshipKind: String, Codable, CaseIterable {
    case family
    case closeFriend
    case friend
    case colleague
    case mentor
    case acquaintance

    /// Default cadence hint if the user hasn't set one explicitly.
    public var defaultCadenceDays: Int {
        switch self {
        case .family: return 14
        case .closeFriend: return 14
        case .friend: return 30
        case .colleague: return 21
        case .mentor: return 60
        case .acquaintance: return 90
        }
    }

    /// Tone of the prompt — calm, never guilt-tripping.
    public var promptFrame: String {
        switch self {
        case .family: return "Reach out to"
        case .closeFriend: return "Check in with"
        case .friend: return "Drop a line to"
        case .colleague: return "Catch up with"
        case .mentor: return "Touch base with"
        case .acquaintance: return "Reconnect with"
        }
    }
}

/// A decay prompt — one per relationship that's overdue.
public struct RelationshipDecayPrompt: Codable, Equatable {
    public let record: RelationshipRecord
    public let daysSinceLastInteraction: Int
    public let overdueMultiplier: Double      // daysSinceLast / cadenceDays; >1 = overdue
    public let severity: DecaySeverity
    public let suggestedAction: String        // "Send a text", "Schedule a call", etc.
    public let requiresReflection: Bool       // true for severe prompts

    public init(
        record: RelationshipRecord,
        daysSinceLastInteraction: Int,
        overdueMultiplier: Double,
        severity: DecaySeverity,
        suggestedAction: String,
        requiresReflection: Bool
    ) {
        self.record = record
        self.daysSinceLastInteraction = daysSinceLastInteraction
        self.overdueMultiplier = overdueMultiplier
        self.severity = severity
        self.suggestedAction = suggestedAction
        self.requiresReflection = requiresReflection
    }
}

public enum DecaySeverity: String, Codable, CaseIterable {
    case gentle      // overdueMultiplier 1.0-1.5x
    case moderate    // 1.5-2.5x
    case severe      // >2.5x (rare; triggers reflection gate)
}

// MARK: - Tracker

public enum RelationshipDecayTracker {

    /// Maximum prompts to surface per day.
    public static let maxPromptsPerDay = 1

    /// Suggested action by relationship kind. Kept simple — the Mac side
    /// can override per person with custom mappings.
    public static func suggestedAction(for record: RelationshipRecord) -> String {
        switch record.relationshipKind {
        case .family, .closeFriend:
            return record.daysSinceLastInteractionHint >= 30
                ? "Schedule a call" : "Send a text"
        case .friend:
            return "Drop a message"
        case .colleague:
            return "Say hi"
        case .mentor:
            return "Send an update"
        case .acquaintance:
            return "Send a brief note"
        }
    }

    /// Compute the day's prompt set. Honors `maxPromptsPerDay` and the
    /// per-record `suppressionDays` (we don't see a record whose last
    /// surfacing was within suppressionDays of now).
    public static func todaysPrompts(
        records: [RelationshipRecord],
        recentlySurfaced: [String: Date] = [:],   // lifeEntityID → lastSurfacedAt
        now: Date = Date()
    ) -> [RelationshipDecayPrompt] {
        var candidates: [RelationshipDecayPrompt] = []
        for record in records {
            // Skip if recently surfaced.
            if let lastSurfaced = recentlySurfaced[record.lifeEntityID] {
                let daysSinceSurfaced = now.timeIntervalSince(lastSurfaced) / 86400
                if Double(daysSinceSurfaced) < Double(record.suppressionDays) {
                    continue
                }
            }

            let daysSince = max(0, Int(now.timeIntervalSince(record.lastInteractionAt) / 86400))
            let multiplier = Double(daysSince) / Double(record.cadenceDays)

            // Only overdue relationships generate prompts.
            guard multiplier >= 1.0 else { continue }

            let severity: DecaySeverity
            if multiplier < 1.5 { severity = .gentle }
            else if multiplier < 2.5 { severity = .moderate }
            else { severity = .severe }

            let prompt = RelationshipDecayPrompt(
                record: record,
                daysSinceLastInteraction: daysSince,
                overdueMultiplier: multiplier,
                severity: severity,
                suggestedAction: suggestedAction(for: record),
                requiresReflection: severity == .severe
            )
            candidates.append(prompt)
        }

        // Sort by overdueMultiplier desc — most overdue first.
        candidates.sort { $0.overdueMultiplier > $1.overdueMultiplier }

        // Cap at maxPromptsPerDay.
        return Array(candidates.prefix(maxPromptsPerDay))
    }

    /// Compute decay stats across all records (for trend display).
    /// Returns (overdue count, severe count, average daysSinceInteraction).
    public static func stats(
        for records: [RelationshipRecord],
        now: Date = Date()
    ) -> (overdue: Int, severe: Int, averageDaysSince: Double) {
        guard !records.isEmpty else { return (0, 0, 0.0) }
        var overdue = 0
        var severe = 0
        var totalDays = 0
        for record in records {
            let daysSince = max(0, Int(now.timeIntervalSince(record.lastInteractionAt) / 86400))
            let multiplier = Double(daysSince) / Double(record.cadenceDays)
            totalDays += daysSince
            if multiplier >= 1.0 { overdue += 1 }
            if multiplier >= 2.5 { severe += 1 }
        }
        return (overdue, severe, Double(totalDays) / Double(records.count))
    }

    // MARK: - Cycle 34 / T147 (GLM A3): pickOneNeglect
    //
    // Returns the single thread with the steepest week-over-week decay,
    // framed as invitation, not accusation. The "One Neglect" card lives
    // on the morning briefing.
    //
    // Algorithm: rank records by `overdueMultiplier = daysSince / cadenceDays`.
    // Ties broken by absolute `daysSinceLastInteraction` (older = more
    // overdue, hence more "neglect" — but framed as care).
    //
    // Only overdue records (multiplier >= 1.0) qualify. None overdue → nil.
    // Honors `RelationshipRecord.suppressionDays` so we don't repeat the
    // same person tomorrow.
    //
    // Output: `OneNeglectSuggestion` with a single calm action prompt.
    public static func pickOneNeglect(
        records: [RelationshipRecord],
        recentlySurfaced: [String: Date] = [:],
        now: Date = Date()
    ) -> OneNeglectSuggestion? {
        var candidates: [(record: RelationshipRecord, multiplier: Double, daysSince: Int)] = []
        for record in records {
            // Skip recently surfaced
            if let lastSurfaced = recentlySurfaced[record.lifeEntityID] {
                let daysSinceSurfaced = now.timeIntervalSince(lastSurfaced) / 86400
                if Double(daysSinceSurfaced) < Double(record.suppressionDays) {
                    continue
                }
            }
            let daysSince = max(0, Int(now.timeIntervalSince(record.lastInteractionAt) / 86400))
            let multiplier = Double(daysSince) / Double(record.cadenceDays)
            guard multiplier >= 1.0 else { continue }
            candidates.append((record, multiplier, daysSince))
        }
        guard !candidates.isEmpty else { return nil }

        // Sort by multiplier desc, then daysSince desc
        candidates.sort { a, b in
            if a.multiplier != b.multiplier { return a.multiplier > b.multiplier }
            return a.daysSince > b.daysSince
        }
        let top = candidates[0]
        return OneNeglectSuggestion(
            record: top.record,
            daysSinceLastInteraction: top.daysSince,
            overdueMultiplier: top.multiplier,
            suggestedAction: suggestedAction(for: top.record)
        )
    }

    public struct OneNeglectSuggestion: Codable, Equatable {
        public let record: RelationshipRecord
        public let daysSinceLastInteraction: Int
        public let overdueMultiplier: Double
        public let suggestedAction: String

        public init(
            record: RelationshipRecord,
            daysSinceLastInteraction: Int,
            overdueMultiplier: Double,
            suggestedAction: String
        ) {
            self.record = record
            self.daysSinceLastInteraction = daysSinceLastInteraction
            self.overdueMultiplier = overdueMultiplier
            self.suggestedAction = suggestedAction
        }

        /// Calm, single-line, invitation framing. Never guilt-tripping.
        /// Cycle 34 / T147 (GLM A3): "Today's single quiet thread: X. 3 minutes would move it."
        public var briefingText: String {
            let days = daysSinceLastInteraction
            let dayWord = days == 1 ? "day" : "days"
            return "Today's single quiet thread: \(record.displayName). " +
                "\(days) \(dayWord) since a touch — 3 minutes would move it."
        }
    }

    // MARK: - Cycle 33 / GLM A1: Threadline Decay Garden (botanical vitality model)
    //
    // The basic overdue-multiplier is purely subtractive: each day, more overdue.
    // The botanical model instead models "vitality" as an exponential decay
    // multiplied by a positive sum of care-events with diminishing returns.
    //
    //     V(t) = V₀ · e^(-λ·Δt) · (1 + Σ(care_event_i · κ_i))
    //
    // where:
    //   - V₀ = 1.0 at the last care event
    //   - λ = base decay rate (per day). Higher λ = faster fade.
    //   - Δt = days since last care event
    //   - κ_i = care-event weight with diminishing returns if clustered
    //
    // This produces asymmetric recovery: a long-dormant thread that gets
    // *one* care event lifts visibly, but a thread that just got 5 care
    // events in a row doesn't get 5× the lift (you can't binge-care).
    //
    // Anti-addictive: V is clamped to [0, 1]. Below 0.2 the thread is
    // "dormant" (Threadline Decay Garden visual: leaf desaturated). The
    // dashboard surfaces "your Care Kin thread is going dormant" — never
    // "you lost it."
    public static func vitality(
        for record: RelationshipRecord,
        careEvents: [Date] = [],        // recent care-event timestamps
        baseDecayRate: Double = 0.005,  // 0.5%/day — matches existing decay default
        now: Date = Date()
    ) -> Double {
        // Δt: days since last interaction (or since earliest careEvent if newer)
        let lastTouch = careEvents.max() ?? record.lastInteractionAt
        let dt = max(0, now.timeIntervalSince(lastTouch) / 86400)

        // V₀ · e^(-λ·Δt)
        let decayed = exp(-baseDecayRate * dt)

        // Σ care events with diminishing returns if clustered (within 3 days)
        // κ_i = 0.15 per event, halved for each event already in the cluster
        let threeDays: TimeInterval = 3 * 86400
        let sortedEvents = careEvents.sorted()
        var sumK = 0.0
        var lastClusteredAt: Date = .distantPast
        for ev in sortedEvents {
            let sincePrev = ev.timeIntervalSince(lastClusteredAt)
            let baseK = 0.15
            let clustered = sincePrev < threeDays
            let k = clustered ? baseK * 0.5 : baseK
            sumK += k
            lastClusteredAt = ev
        }

        // (1 + Σκ) — diminishing returns via sqrt to flatten clusters
        let boost = 1.0 + sqrt(sumK)

        let raw = decayed * boost
        return min(1.0, max(0.0, raw))
    }

    // MARK: - Cycle 33 / GLM B4: Relationship Rhizome Index
    //
    // Decay is one-dimensional. Relationships aren't. Some are *taproot*
    // (long shared history, few recent interactions) — like your mother.
    // Others are *rhizome* (many small, recent interactions) — like a
    // colleague. The two need different IRL nudges:
    //
    //   - Taproot starved: "Call one person you haven't spoken to in a month."
    //   - Rhizome noisy:  "You have 20 short touches; one long one would deepen."
    //
    // R = depth² / (1 + breadth)
    //   - depth = total days span of relationship history (max 365, clamped)
    //   - breadth = number of distinct interaction days in the last 90 days
    //
    // High R = taproot (deep, starved). Low R = rhizome (shallow, busy).
    public static func rhizomeIndex(
        for record: RelationshipRecord,
        interactionDays: [Date] = [],   // distinct interaction dates
        now: Date = Date()
    ) -> RhizomeReading {
        let oldest = interactionDays.min() ?? record.lastInteractionAt
        let depthDays = min(365, max(0, Int(now.timeIntervalSince(oldest) / 86400)))
        let ninetyAgo = now.addingTimeInterval(-90 * 86400)
        let breadth = interactionDays.filter { $0 >= ninetyAgo }.count

        let depthTerm = Double(depthDays * depthDays)
        let breadthTerm = 1.0 + Double(breadth)
        let r = depthTerm / breadthTerm

        let kind: RhizomeKind
        if depthDays >= 180 && breadth <= 2 {
            kind = .taprootStarved
        } else if depthDays < 90 && breadth >= 8 {
            kind = .rhizomeNoisy
        } else if depthDays >= 90 && breadth >= 4 {
            kind = .balanced
        } else {
            kind = .developing
        }

        return RhizomeReading(
            record: record,
            depthDays: depthDays,
            breadthDays: breadth,
            index: r,
            kind: kind
        )
    }
}

public enum RhizomeKind: String, Codable, CaseIterable {
    case taprootStarved   // deep history, very few recent touches
    case rhizomeNoisy     // shallow history, many touches
    case balanced         // both healthy
    case developing       // not enough data yet
}

public struct RhizomeReading: Codable, Equatable {
    public let record: RelationshipRecord
    public let depthDays: Int
    public let breadthDays: Int
    public let index: Double
    public let kind: RhizomeKind

    /// IRL nudge text matched to the kind. Never guilt-tripping.
    public var nudgeText: String {
        switch kind {
        case .taprootStarved:
            return "Deep relationship, quiet lately. One call would move it."
        case .rhizomeNoisy:
            return "Many small touches; one longer one would deepen this."
        case .balanced:
            return "Healthy mix of depth and presence."
        case .developing:
            return "Still learning the shape of this one."
        }
    }

    public init(record: RelationshipRecord, depthDays: Int, breadthDays: Int, index: Double, kind: RhizomeKind) {
        self.record = record
        self.depthDays = depthDays
        self.breadthDays = breadthDays
        self.index = index
        self.kind = kind
    }
}

// MARK: - Convenience extension for the "days since" hint

private extension RelationshipRecord {
    var daysSinceLastInteractionHint: Int {
        // Used only for the suggestedAction calculation; not for prompts.
        return max(0, Int(Date().timeIntervalSince(self.lastInteractionAt) / 86400))
    }
}

// MARK: - Numeric clamping helper (private to this file)

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}