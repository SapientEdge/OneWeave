//
//  MasteryKnot.swift
//  OneWeave
//
//  Cycle 35 / T149 (GLM A9) — Apprentice Knots.
//
//  Each Mastery node can have unresolved "knots" — questions the user
//  themselves logged as blockers. Mastery tier advances by untying knots,
//  not by time served.
//
//  Embodies Constitution §5: genuine mastery > time-served gamification.
//
//  Why this exists:
//    The existing Mastery tier system (`masteryTiers: [String: Int]` on
//    LifeContext) advances purely on quest completion. But completing
//    many low-quality quests shouldn't outpace wrestling with one hard
//    question for weeks. Knots capture the *deliberate struggle*.
//
//  Lifecycle:
//    1. User logs a knot: "How do I receive critical feedback without
//       becoming defensive?" Tied to a domain (e.g., "Self").
//    2. The knot is "tied" (open). Mastery tier for that domain is
//       capped at (currentTier) — you can't advance past the tier
//       where you have an open knot.
//    3. When the user resolves it (writes a reflection, links to a
//       sealed decision, or marks it resolved), the knot is "untied".
//    4. Tier can now advance. Quests that *cite* the untying get a
//       quiet "+1" essence bonus (cycle 35 follow-up).
//
//  UX: "Adept tier awaits 2 knots. You wrote one in February."
//
//  Privacy: knots are private by default. Never sync via P2P. Never
//  used in any aggregate metric.
//
//  Test coverage is in .research/validate_mastery_knots.py.
//

import Foundation

// MARK: - Knot states

/// Lifecycle state of a single apprentice knot.
public enum KnotState: String, Codable, CaseIterable {
    case tied       // open, blocking tier advancement
    case loosening  // user has started work on it (notes exist, partial reflection)
    case untied     // resolved — reflection written, decision linked, or explicit resolve
}

// MARK: - ApprenticeKnot

/// A single unresolved question logged as a Mastery-tier blocker.
/// Persisted by the Mac side (here we model the struct + algorithm).
public struct ApprenticeKnot: Codable, Equatable, Identifiable {
    public let id: UUID
    public var domain: String                 // "Self", "Stewardship", "CareKin", "Meaning", "Body"
    public var question: String               // "How do I receive critical feedback without becoming defensive?"
    public var state: KnotState
    public var tiedAt: Date                   // when it was logged
    public var resolvedAt: Date?              // when it transitioned to .untied
    public var notes: [KnotNote]              // chronological — user can add reflections as they wrestle
    public var relatedDecisionID: UUID?       // link to a DecisionLog entry if the untying happened via decision
    public var relatedReflectionText: String?  // link to a reflection if the untying happened via reflection

    public init(
        id: UUID = UUID(),
        domain: String,
        question: String,
        state: KnotState = .tied,
        tiedAt: Date = Date(),
        resolvedAt: Date? = nil,
        notes: [KnotNote] = [],
        relatedDecisionID: UUID? = nil,
        relatedReflectionText: String? = nil
    ) {
        self.id = id
        self.domain = domain
        self.question = question
        self.state = state
        self.tiedAt = tiedAt
        self.resolvedAt = resolvedAt
        self.notes = notes
        self.relatedDecisionID = relatedDecisionID
        self.relatedReflectionText = relatedReflectionText
    }

    /// Days the knot has been tied. 0 if just created, positive otherwise.
    public var daysTied: Int {
        let end = resolvedAt ?? Date()
        return max(0, Int(end.timeIntervalSince(tiedAt) / 86400))
    }
}

/// A short note the user appends to a knot while working on it.
/// Like a reflection but scoped to a single question.
public struct KnotNote: Codable, Equatable, Identifiable {
    public let id: UUID
    public let createdAt: Date
    public let text: String

    public init(id: UUID = UUID(), createdAt: Date = Date(), text: String) {
        self.id = id
        self.createdAt = createdAt
        self.text = text
    }
}

// MARK: - Tier algorithm

/// Tier advancement rules that respect open knots.
///
/// `maxTier(for: domain, knots:)` returns the *highest* tier the user can
/// reach in that domain given their open knots:
///   - 0 open knots: no cap (can reach any tier)
///   - 1 open knot: capped at current tier (can't advance past it)
///   - 2+ open knots: capped at (current tier - 1) — the knots pull
///     you back to apprentice level until they're untied
///
/// This embodies the "Apprentice Knots" concept: each untied knot
/// unlocks the *next* tier above current. The user can see clearly
/// "Adept tier awaits 2 knots" — never vague "you're almost there".
public enum MasteryKnotEngine {

    /// Maximum tier the user can reach in `domain` given their knots.
    /// `currentTier` is the tier they've already achieved. 0 means
    /// apprentice.
    public static func maxTier(
        for domain: String,
        currentTier: Int,
        knots: [ApprenticeKnot]
    ) -> Int {
        let openCount = knots.filter {
            $0.domain == domain &&
            ($0.state == .tied || $0.state == .loosening)
        }.count

        if openCount == 0 {
            return Int.max   // no cap
        } else if openCount == 1 {
            return currentTier
        } else {
            return max(0, currentTier - 1)
        }
    }

    /// Count open knots for a domain. Used by the MasteryMap UI to show
    /// "Adept tier awaits N knots".
    public static func openKnotCount(
        for domain: String,
        knots: [ApprenticeKnot]
    ) -> Int {
        return knots.filter {
            $0.domain == domain &&
            ($0.state == .tied || $0.state == .loosening)
        }.count
    }

    /// Calm suggestion text for a domain with N open knots.
    /// Cycle 35 / T149: "Adept tier awaits 2 knots. You wrote one in February."
    public static func tierBlockedMessage(
        for domain: String,
        openKnots: [ApprenticeKnot]
    ) -> String? {
        guard !openKnots.isEmpty else { return nil }
        let n = openKnots.count
        let noun = n == 1 ? "knot" : "knots"
        let cap = domain.prefix(1).uppercased() + domain.dropFirst()
        let line = "\(cap) tier awaits \(n) \(noun)."
        // Tiebreaker: show the oldest knot's age
        if let oldest = openKnots.min(by: { $0.tiedAt < $1.tiedAt }) {
            let days = oldest.daysTied
            if days >= 30 {
                let months = days / 30
                let monthWord = months == 1 ? "month" : "months"
                return "\(line) You wrote one \(months) \(monthWord) ago."
            } else if days >= 7 {
                let weeks = days / 7
                let weekWord = weeks == 1 ? "week" : "weeks"
                return "\(line) You wrote one \(weeks) \(weekWord) ago."
            }
        }
        return line
    }

    /// Resolve (untie) a knot. Returns the updated knot + sets resolvedAt.
    /// Caller is responsible for persisting the change.
    public static func untie(
        _ knot: ApprenticeKnot,
        via reflection: String? = nil,
        relatedDecisionID: UUID? = nil,
        now: Date = Date()
    ) -> ApprenticeKnot {
        var updated = knot
        updated.state = .untied
        updated.resolvedAt = now
        if let r = reflection, !r.isEmpty {
            updated.relatedReflectionText = r
        }
        if let d = relatedDecisionID {
            updated.relatedDecisionID = d
        }
        return updated
    }

    /// Move a knot from .tied to .loosening (user started working on it).
    /// Idempotent — calling on an already-loosening knot is a no-op.
    public static func loosen(_ knot: ApprenticeKnot) -> ApprenticeKnot {
        guard knot.state == .tied else { return knot }
        var updated = knot
        updated.state = .loosening
        return updated
    }
}
