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