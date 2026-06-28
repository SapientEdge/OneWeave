//
//  DecisionLog.swift
//  OneWeave
//
//  Decision Log — tracks the user's significant decisions over time and
//  feeds them to the Invisible Mentor so it can cite the user's own
//  reasoning when relevant.
//
//  Why this exists:
//    Research blueprint §5 + on-device AI doc both flag "decision support"
//    as a high-value feature. The MVP of this is: capture the decision
//    at the moment of choice, capture the outcome later, and let the
//    Invisible Mentor cite past decisions. No LLM, no cloud — just a
//    structured log + good query API.
//
//  What it captures:
//    1. The decision itself (title + description)
//    2. The options considered (titles only)
//    3. The user's reasoning (free text — this is what the Mentor cites)
//    4. The user's expected outcome (free text)
//    5. The actual outcome (free text, filled in later)
//    6. Confidence at the time of decision (0..1)
//    7. Domain tags (so the Mentor can find decisions about X when asked about X)
//    8. References to LifeGraph entities the decision touches
//
//  Privacy model:
//    - Decisions are private by default (isPrivate = true).
//    - The reasoning is the user's own words — gated to Mentor only when
//      isUserReflection-equivalent (we use isPrivate + isUserReflection on
//      a derived LifeEntity to keep the existing pipeline working).
//    - Decisions are never shared via P2P.
//    - No telemetry. No analytics on "what kinds of decisions do users make?"
//
//  Design pillars:
//    1. Reflection-gated. Recording a decision requires a non-empty reasoning
//       (otherwise the decision has no value — we don't know WHY).
//    2. Outcome-aware. After the decision, the user is gently prompted
//       (via the Cognitive Load integration or Evening Review) to record
//       what actually happened. Empty outcome → no judgment, just status.
//    3. Mentor-citable. The decision's reasoning is exposed via the same
//       reflection pipeline that powers InvisibleMentor. When the user
//       asks the Mentor "should I do X?", past decisions about X
//       are returned as candidates.
//    4. Time-aware. Old decisions can be referenced but new ones take
//       priority (recency weighted).
//    5. Calm by design. The Decision Log is not a "track your regrets" tool.
//       It's a memory aid — capture reasoning, learn from patterns.
//
//  What this file does NOT contain:
//    - Decision template suggestions (Mac side wires those).
//    - Cross-device sync (P2P doesn't sync decisions; they're private).
//    - The Mentor query integration (Mac side calls `mentorDecisionCandidates`
//      and feeds them into MentorInput).
//
//  Test coverage is in .research/validate_decision_log.py.
//

import Foundation

// MARK: - Public types

/// A single decision record.
public struct DecisionRecord: Codable, Equatable, Identifiable {
    public let id: UUID
    public var title: String                // "Should I take the new job?"
    public var optionsConsidered: [String]   // ["Stay at current role", "Take new role"]
    public var chosenOptionIndex: Int?       // Cycle 34 / T152: index into optionsConsidered.
                                             // nil for decisions recorded before cycle 34.
                                             // When non-nil + optionsConsidered.count >= 2,
                                             // the unchosen path is the *other* option.
    public var reasoning: String             // "I want more growth and the team seems strong."
    public var expectedOutcome: String       // "More growth, similar comp."
    public var actualOutcome: String?       // Filled in later.
    public var confidenceAtDecision: Double  // 0..1
    public var domainTags: [String]         // ["Self", "Stewardship"]
    public var referencedEntityIDs: [UUID]   // LifeGraph entities this touches
    public var decidedAt: Date
    public var outcomeRecordedAt: Date?
    public var isPrivate: Bool               // default true
    public var attributes: [String: String]

    public init(
        id: UUID = UUID(),
        title: String,
        optionsConsidered: [String] = [],
        chosenOptionIndex: Int? = nil,
        reasoning: String,
        expectedOutcome: String = "",
        actualOutcome: String? = nil,
        confidenceAtDecision: Double = 0.5,
        domainTags: [String] = [],
        referencedEntityIDs: [UUID] = [],
        decidedAt: Date = Date(),
        outcomeRecordedAt: Date? = nil,
        isPrivate: Bool = true,
        attributes: [String: String] = [:]
    ) {
        self.id = id
        self.title = title
        self.optionsConsidered = optionsConsidered
        self.chosenOptionIndex = chosenOptionIndex
        self.reasoning = reasoning
        self.expectedOutcome = expectedOutcome
        self.actualOutcome = actualOutcome
        self.confidenceAtDecision = confidenceAtDecision.clamped(to: 0...1)
        self.domainTags = domainTags
        self.referencedEntityIDs = referencedEntityIDs
        self.decidedAt = decidedAt
        self.outcomeRecordedAt = outcomeRecordedAt
        self.isPrivate = isPrivate
        self.attributes = attributes
    }

    /// Cycle 34 / T152 (GLM A2): the option the user *didn't* take.
    /// Returns nil if the record doesn't have chosenOptionIndex or only
    /// has one option considered (no alternative existed).
    public var unchosenOption: String? {
        guard let chosen = chosenOptionIndex,
              optionsConsidered.count >= 2,
              chosen >= 0, chosen < optionsConsidered.count
        else { return nil }
        // Surface *one* unchosen option (the first other one). For decisions
        // with > 2 options, the first non-chosen is treated as the dominant
        // alternative — the one that mattered most at decision time.
        for (i, opt) in optionsConsidered.enumerated() where i != chosen {
            return opt
        }
        return nil
    }

    /// Whether the decision has an outcome recorded. Public for filtering.
    public var hasOutcome: Bool {
        return actualOutcome != nil && !(actualOutcome?.isEmpty ?? true)
    }

    /// Days between decision and outcome recording. 0 if no outcome yet.
    public var daysToOutcome: Int? {
        guard let outcomeAt = outcomeRecordedAt else { return nil }
        let interval = outcomeAt.timeIntervalSince(decidedAt)
        return max(0, Int(interval / 86400))
    }
}

// MARK: - Errors

public enum DecisionLogError: Error, LocalizedError {
    case emptyReasoning
    case emptyTitle
    case emptyOutcome

    public var errorDescription: String? {
        switch self {
        case .emptyReasoning:
            return "A decision needs reasoning — at least one sentence about why you chose this."
        case .emptyTitle:
            return "A decision needs a title — what was the choice?"
        case .emptyOutcome:
            return "Please write at least one sentence about what actually happened."
        }
    }
}

// MARK: - Log API

public enum DecisionLog {

    /// Record a new decision. Reflection-gated: reasoning must be non-empty.
    @discardableResult
    public static func record(
        title: String,
        reasoning: String,
        optionsConsidered: [String] = [],
        expectedOutcome: String = "",
        confidenceAtDecision: Double = 0.5,
        domainTags: [String] = [],
        referencedEntityIDs: [UUID] = [],
        isPrivate: Bool = true,
        now: Date = Date()
    ) throws -> DecisionRecord {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedReasoning = reasoning.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else { throw DecisionLogError.emptyTitle }
        guard !trimmedReasoning.isEmpty else { throw DecisionLogError.emptyReasoning }

        return DecisionRecord(
            title: trimmedTitle,
            optionsConsidered: optionsConsidered,
            reasoning: trimmedReasoning,
            expectedOutcome: expectedOutcome,
            actualOutcome: nil,
            confidenceAtDecision: confidenceAtDecision,
            domainTags: domainTags,
            referencedEntityIDs: referencedEntityIDs,
            decidedAt: now,
            outcomeRecordedAt: nil,
            isPrivate: isPrivate,
            attributes: [:]
        )
    }

    /// Update a decision with the actual outcome. Reflection-gated:
    /// the outcome text must be non-empty.
    public static func recordOutcome(
        for decision: DecisionRecord,
        actualOutcome: String,
        now: Date = Date()
    ) throws -> DecisionRecord {
        let trimmed = actualOutcome.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw DecisionLogError.emptyOutcome }

        var updated = decision
        updated.actualOutcome = trimmed
        updated.outcomeRecordedAt = now
        return updated
    }

    /// Days until next outcome reminder. Decisions with no outcome recorded
    /// get a nudge after `reminderDelayDays` (default 14) — but only if
    /// the user has at least one decision in their log.
    public static let reminderDelayDays: Int = 14

    /// Decisions that need an outcome reminder. Returns at most `maxReminders`
    /// to keep the morning briefing quiet.
    public static func needsOutcomeReminder(
        records: [DecisionRecord],
        now: Date = Date(),
        maxReminders: Int = 1
    ) -> [DecisionRecord] {
        let candidates = records
            .filter { !$0.hasOutcome }
            .filter { record in
                let days = now.timeIntervalSince(record.decidedAt) / 86400
                return Int(days) >= reminderDelayDays
            }
            .sorted(by: { $0.decidedAt < $1.decidedAt })  // oldest first
        return Array(candidates.prefix(maxReminders))
    }
}

// MARK: - Mentor integration

/// Bridges DecisionLog records into the Invisible Mentor's input stream.
/// The Mentor can cite past decisions as if they were reflections, with
/// the additional context of options considered + outcome (if known).
public enum DecisionMentorBridge {

    /// Convert a decision record into a Mentor reflection seed.
    /// The seed's "text" is the reasoning + (optionally) the outcome,
    /// formatted so the Mentor can quote the user back to themselves.
    public static func reflectionSeed(
        from decision: DecisionRecord,
        now: Date = Date()
    ) -> MentorInput.ReflectionSeed {
        var text = decision.reasoning
        if let outcome = decision.actualOutcome, !outcome.isEmpty {
            text += "\n\nOutcome: \(outcome)"
        }
        let days = max(0, Int(now.timeIntervalSince(decision.decidedAt) / 86400))
        return MentorInput.ReflectionSeed(
            id: decision.id,
            text: text,
            domains: decision.domainTags,
            daysAgo: days,
            harmonyImpact: decision.confidenceAtDecision  // higher confidence → higher "mattering"
        )
    }

    /// Find decisions that match a Mentor's prompt. Used by the Mentor
    /// to surface relevant past decisions when the user asks about a topic.
    /// Returns the top `limit` by relevance.
    public static func relevantDecisions(
        for prompt: String,
        in records: [DecisionRecord],
        now: Date = Date(),
        limit: Int = 3
    ) -> [(record: DecisionRecord, relevance: Double)] {
        let promptTokens = Set(
            prompt.lowercased()
                .components(separatedBy: .whitespacesAndNewlines.union(.punctuationCharacters))
                .filter { $0.count >= 3 }
        )
        guard !promptTokens.isEmpty else { return [] }

        var scored: [(DecisionRecord, Double)] = []
        for r in records {
            // Combine title + reasoning + outcome for search.
            let haystack = ([r.title, r.reasoning, r.actualOutcome ?? ""]
                .joined(separator: " ")).lowercased()
            let tokens = Set(
                haystack
                    .components(separatedBy: .whitespacesAndNewlines.union(.punctuationCharacters))
                    .filter { $0.count >= 3 }
            )
            if tokens.isEmpty { continue }
            let intersection = promptTokens.intersection(tokens).count
            let union = promptTokens.union(tokens).count
            let jaccard = union > 0 ? Double(intersection) / Double(union) : 0.0

            // Domain tag bonus.
            let domainBonus: Double = r.domainTags.isEmpty ? 0.0 : 0.1

            // Recency decay — older decisions slightly less relevant.
            let daysAgo = now.timeIntervalSince(r.decidedAt) / 86400
            let recency = max(0.5, 1.0 - daysAgo / 365.0 * 0.5)

            let score = (jaccard + domainBonus) * recency
            if score > 0.05 {
                scored.append((r, score))
            }
        }
        scored.sort(by: { $0.1 > $1.1 })
        return Array(scored.prefix(limit))
    }

    // MARK: - Cycle 34 / T152 (GLM A2): Unchosen Path candidates
    //
    // The Resonance Oracle, 30 days after a decision was sealed, simulates
    // *only* the option the user didn't take — and surfaces it as a
    // reflection prompt. Never as a verdict. UX: "Had you gone the other
    // way, what would today look like?"
    //
    // Returns up to `limit` decisions that:
    //   1. Were decided at least `minAgeDays` ago (default 30)
    //   2. Have a `chosenOptionIndex` and an `unchosenOption`
    //   3. Have not been surfaced before (caller passes `alreadySurfacedIDs`)
    //   4. Are not more than `maxAgeDays` old (default 365 — older decisions
    //      get faded out to keep the ritual fresh)
    //
    // Surfaced as `UnchosenPathPrompt`, which the Mac side renders with a
    // reflection CTA. Never awards essence or harmony without the user
    // actually writing a reflection.
    public static func unchosenPathCandidates(
        in records: [DecisionRecord],
        alreadySurfacedIDs: Set<UUID> = [],
        now: Date = Date(),
        minAgeDays: Int = 30,
        maxAgeDays: Int = 365,
        limit: Int = 1
    ) -> [UnchosenPathPrompt] {
        var candidates: [UnchosenPathPrompt] = []
        for record in records {
            // Skip if no unchosen option recorded
            guard let unchosen = record.unchosenOption else { continue }
            // Skip if already surfaced
            if alreadySurfacedIDs.contains(record.id) { continue }

            let daysAgo = Int(now.timeIntervalSince(record.decidedAt) / 86400)
            guard daysAgo >= minAgeDays, daysAgo <= maxAgeDays else { continue }

            candidates.append(UnchosenPathPrompt(
                record: record,
                unchosenOption: unchosen,
                daysAgo: daysAgo,
                prompt: makeUnchosenPathPrompt(for: record, unchosen: unchosen, daysAgo: daysAgo)
            ))
        }
        // Most recent first (closer to the 30-day window is fresher).
        candidates.sort { $0.daysAgo < $1.daysAgo }
        return Array(candidates.prefix(limit))
    }

    /// Build the calm reflection prompt. Embodies Constitution §3 (calm) +
    /// §4 (reflection-gated everything). Never a verdict.
    private static func makeUnchosenPathPrompt(
        for record: DecisionRecord,
        unchosen: String,
        daysAgo: Int
    ) -> String {
        let dayWord = daysAgo == 1 ? "day" : "days"
        return "\(daysAgo) \(dayWord) ago you decided \"\(record.title)\" and chose " +
            "the path you took. The other path was \"\(unchosen)\". " +
            "Had you gone that way, what would today look like?"
    }
}

/// Cycle 34 / T152 (GLM A2): one unchosen-path reflection prompt surfaced
/// by the Resonance Oracle. The user can choose to write a reflection
/// (then any insight / essence is awarded) or dismiss without consequence.
public struct UnchosenPathPrompt: Codable, Equatable, Identifiable {
    public let record: DecisionRecord
    public let unchosenOption: String
    public let daysAgo: Int
    public let prompt: String

    public var id: UUID { record.id }

    public init(record: DecisionRecord, unchosenOption: String, daysAgo: Int, prompt: String) {
        self.record = record
        self.unchosenOption = unchosenOption
        self.daysAgo = daysAgo
        self.prompt = prompt
    }
}

// MARK: - Stats

public struct DecisionLogStats: Codable, Equatable {
    public let totalDecisions: Int
    public let withOutcomes: Int
    public let averageDaysToOutcome: Double
    public let averageConfidence: Double

    public static func compute(from records: [DecisionRecord]) -> DecisionLogStats {
        guard !records.isEmpty else {
            return DecisionLogStats(totalDecisions: 0, withOutcomes: 0,
                                    averageDaysToOutcome: 0.0, averageConfidence: 0.0)
        }
        let withOutcomes = records.filter { $0.hasOutcome }
        let daysToOutcomes = withOutcomes.compactMap { $0.daysToOutcome }
        let avgDays: Double
        if daysToOutcomes.isEmpty {
            avgDays = 0.0
        } else {
            avgDays = Double(daysToOutcomes.reduce(0, +)) / Double(daysToOutcomes.count)
        }
        let avgConf = records.reduce(0.0) { $0 + $1.confidenceAtDecision } / Double(records.count)
        return DecisionLogStats(
            totalDecisions: records.count,
            withOutcomes: withOutcomes.count,
            averageDaysToOutcome: avgDays,
            averageConfidence: avgConf
        )
    }
}

// MARK: - Numeric clamping helper (private)

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}