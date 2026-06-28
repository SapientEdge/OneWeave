//
//  InvisibleMentor.swift
//  OneWeave
//
//  Invisible Mentor — 5th creative feature (Tier A #4).
//
//  The Invisible Mentor is the user, talking to themselves across time. It is
//  NOT an external AI. Every response is composed from the user's own past
//  reflections, completed quests, opened Sacred Echoes, and resolved
//  contradictions. No network calls. No LLM. No "AI wisdom" — just the user,
//  in their own words, from a different day.
//
//  Design pillars:
//    1. You, not a chatbot. Mentor text is drawn from the user's own history.
//    2. Structured turns. Each turn presents 2-3 candidate responses; the user
//       picks one or writes their own. No hallucinated free-form replies.
//    3. Reflection-gated always. The Mentor never activates until the user has
//       written at least one reflection in their history. Empty graphs = silent.
//    4. Privacy-first. All synthesis is on-device against the local Life Graph.
//    5. Local-first. No Mentor content leaves the device. No telemetry.
//    6. Calm by design. The Mentor is a slow, gentle voice — never pushy.
//
//  What this file does NOT contain:
//    - Any network code. There is no "send to server" path. There isn't even
//      a server to send to.
//    - Any LLM call. No "ask Foundation Models". No Core ML model. The Mentor
//      is a deterministic synthesizer over the user's local data.
//

import Foundation

// MARK: - Mentor turn shape

/// A single Mentor utterance — one possible response the past-self would give
/// to the user's current situation. The user picks one, or writes their own.
public struct MentorTurn: Identifiable, Equatable {
    public let id: UUID
    public let spoken: String              // what past-you would say (in your voice)
    public let citedReflectionID: UUID?    // the source quest/echo/echo id
    public let citedReflectionExcerpt: String?  // first 240 chars of the source
    public let citedDaysAgo: Int           // how long ago the source was written
    public let relevanceScore: Double      // 0..1, higher = more relevant to current

    public init(
        id: UUID = UUID(),
        spoken: String,
        citedReflectionID: UUID? = nil,
        citedReflectionExcerpt: String? = nil,
        citedDaysAgo: Int = 0,
        relevanceScore: Double = 0.5
    ) {
        self.id = id
        self.spoken = spoken
        self.citedReflectionID = citedReflectionID
        self.citedReflectionExcerpt = citedReflectionExcerpt
        self.citedDaysAgo = citedDaysAgo
        self.relevanceScore = relevanceScore.clamped(to: 0...1)
    }
}

/// A dialogue session: the user's current question + the Mentor's response
/// options + the user's chosen response (if any).
public struct MentorDialogue: Equatable {
    public let userPrompt: String
    public let candidates: [MentorTurn]
    public let chosenTurnID: UUID?
    public let userFollowUp: String?

    public init(
        userPrompt: String,
        candidates: [MentorTurn],
        chosenTurnID: UUID? = nil,
        userFollowUp: String? = nil
    ) {
        self.userPrompt = userPrompt
        self.candidates = candidates
        self.chosenTurnID = chosenTurnID
        self.userFollowUp = userFollowUp
    }
}

// MARK: - Mentor input shape

/// Snapshot of the user's history that the Mentor synthesizes from. Built
/// once at session start; the Mentor never reads from mutable state mid-turn.
public struct MentorInput {
    public struct ReflectionSeed {
        public let id: UUID
        public let text: String
        public let domains: [String]
        public let daysAgo: Int
        public let harmonyImpact: Double
    }

    public struct OpenedEchoSeed {
        public let id: UUID
        public let title: String
        public let text: String
        public let daysSinceOpened: Int
    }

    public let reflections: [ReflectionSeed]
    public let openedEchoes: [OpenedEchoSeed]
    public let coherenceScore: Double
    public let completedQuestCount: Int
    public let now: Date

    public init(
        reflections: [ReflectionSeed],
        openedEchoes: [OpenedEchoSeed],
        coherenceScore: Double,
        completedQuestCount: Int,
        now: Date = Date()
    ) {
        self.reflections = reflections
        self.openedEchoes = openedEchoes
        self.coherenceScore = coherenceScore
        self.completedQuestCount = completedQuestCount
        self.now = now
    }
}

// MARK: - Mentor synthesizer

/// Deterministic synthesizer: given the user's history and a prompt, return
/// 2-3 candidate MentorTurns drawn from the user's own past writing. Never
/// invents text. Never suggests actions the user hasn't already taken.
public enum InvisibleMentor {

    /// The minimum number of reflections required for the Mentor to activate.
    /// Below this, the Mentor is silent (returns empty candidates) — because
    /// without your own words, there's no "you" to talk to.
    public static let minimumReflections = 1

    /// Generate candidate Mentor responses for the user's current prompt.
    /// Returns empty `MentorDialogue` if the Mentor is dormant (insufficient
    /// history). The caller is responsible for honoring the reflection gate
    /// before persisting the dialogue.
    public static func respond(
        to prompt: String,
        from input: MentorInput
    ) -> MentorDialogue {
        // Reflection gate: dormant until the user has at least one reflection.
        guard input.reflections.count >= minimumReflections else {
            return MentorDialogue(userPrompt: prompt, candidates: [])
        }

        // Score every reflection by relevance to the prompt. Simple lexical
        // overlap weighted by domain match + recency + harmony impact. We do
        // NOT do embeddings (out of scope; would require vector store on Linux).
        let promptTokens = tokenize(prompt)
        let scored: [(MentorTurn, Double)] = input.reflections.compactMap { seed in
            let textTokens = tokenize(seed.text)
            guard !textTokens.isEmpty else { return nil }

            // Lexical overlap (Jaccard)
            let overlap = jaccard(promptTokens, textTokens)

            // Domain match bonus
            let promptDomains = extractDomains(from: prompt)
            let domainOverlap = promptDomains.isEmpty
                ? 0.0
                : Double(promptDomains.filter { seed.domains.contains($0) }.count)
                  / Double(promptDomains.count)

            // Recency: closer in time = slightly higher weight, but older is
            // also valuable (perspective). 1.0 at 0 days, 0.6 at 365 days.
            let recency = max(0.6, 1.0 - Double(seed.daysAgo) / 365.0 * 0.4)

            // Harmony impact bonus (positive or negative — both signal "this
            // mattered to you").
            let harmonySignal = abs(seed.harmonyImpact)

            let score = (overlap * 0.5 + domainOverlap * 0.3 + harmonySignal * 0.1)
                * recency
            let relevance = (score * 2.0).clamped(to: 0...1) // boost a bit

            // Compose the spoken line. The Mentor speaks AS past-self, so we
            // frame the user's own reflection back to them with a calm prefix.
            let spoken = composeSpoken(
                seed: seed,
                prompt: prompt,
                relevance: relevance
            )

            let turn = MentorTurn(
                spoken: spoken,
                citedReflectionID: seed.id,
                citedReflectionExcerpt: String(seed.text.prefix(240)),
                citedDaysAgo: seed.daysAgo,
                relevanceScore: relevance
            )
            return (turn, relevance)
        }

        // Top 3 candidates, sorted by relevance desc.
        let top = scored
            .sorted { $0.1 > $1.1 }
            .prefix(3)
            .map { $0.0 }

        return MentorDialogue(userPrompt: prompt, candidates: Array(top))
    }

    // MARK: - Cycle 35 / T154 (GLM A6): Devil's Advocate Mode
    //
    // When the user is forming an insight, the Mentor surfaces the strongest
    // counter-argument from the user's *own* past entries. Embodies the
    // Socratic tradition: the best teacher is your past self.
    //
    // Algorithm: find past reflections that share *domain* with the current
    // insight but have the most *opposing stance* (lexical + harmony-impact).
    //
    // Returns at most `limit` counter-arguments. Each cites the user's own
    // text — never invented, never paraphrased beyond the existing excerpt.
    //
    // UX: "In March you wrote the opposite. Is this growth, or forgetting?"
    public struct DevilAdvocateCounter: Codable, Equatable, Identifiable {
        public let id: UUID
        public let citedReflectionID: UUID
        public let citedTextExcerpt: String
        public let citedDaysAgo: Int
        public let oppositionScore: Double        // 0..1; higher = stronger counter
        public let prompt: String                  // calm prompt asking the user to weigh both

        public init(
            id: UUID = UUID(),
            citedReflectionID: UUID,
            citedTextExcerpt: String,
            citedDaysAgo: Int,
            oppositionScore: Double,
            prompt: String
        ) {
            self.id = id
            self.citedReflectionID = citedReflectionID
            self.citedTextExcerpt = citedTextExcerpt
            self.citedDaysAgo = citedDaysAgo
            self.oppositionScore = oppositionScore.clamped(to: 0...1)
            self.prompt = prompt
        }
    }

    /// Find counter-arguments to a current insight being formed.
    /// `currentClaim` is the proposed insight text (e.g., "You prioritize
    /// meaning over kin"). `pastReflections` is the user's history.
    /// `domain` restricts the search to a specific life domain.
    public static func devilAdvocate(
        currentClaim: String,
        domain: String,
        pastReflections: [MentorInput.ReflectionSeed],
        limit: Int = 1
    ) -> [DevilAdvocateCounter] {
        guard !pastReflections.isEmpty else { return [] }

        let claimTokens = tokenize(currentClaim)
        let claimPolar: Double = polarity(of: claimTokens)  // +1 if positive valence, -1 if negative

        struct Scored {
            let seed: MentorInput.ReflectionSeed
            let opposition: Double
            let prompt: String
        }

        var candidates: [Scored] = []
        for seed in pastReflections {
            // Must share domain
            guard seed.domains.contains(domain) else { continue }

            let textTokens = tokenize(seed.text)
            guard !textTokens.isEmpty else { continue }

            // Opposition: high lexical overlap but opposite polarity
            let overlap = jaccard(claimTokens, textTokens)
            guard overlap > 0.05 else { continue }  // must be topically related

            let seedPolar = polarity(of: textTokens)
            let polarityDistance = abs(claimPolar - seedPolar) / 2.0  // 0..1

            // Score: high topical overlap * high polarity distance
            let opposition = (overlap * 0.5 + polarityDistance * 0.5).clamped(to: 0...1)
            guard opposition > 0.15 else { continue }  // skip weak counters

            let prompt = makeDevilsAdvocatePrompt(
                currentClaim: currentClaim,
                pastText: seed.text,
                daysAgo: seed.daysAgo,
                opposition: opposition
            )

            candidates.append(Scored(seed: seed, opposition: opposition, prompt: prompt))
        }

        // Top `limit` by opposition
        let top = candidates
            .sorted { $0.opposition > $1.opposition }
            .prefix(limit)

        return top.map { s in
            DevilAdvocateCounter(
                citedReflectionID: s.seed.id,
                citedTextExcerpt: String(s.seed.text.prefix(240)),
                citedDaysAgo: s.seed.daysAgo,
                oppositionScore: s.opposition,
                prompt: s.prompt
            )
        }
    }

    /// Compute polarity from a token set using the TonalLexicon.
    /// Returns a value in [-1, +1] indicating overall valence.
    private static func polarity(of tokens: Set<String>) -> Double {
        guard !tokens.isEmpty else { return 0 }
        var sum = 0.0
        var counted = 0
        for token in tokens {
            let v = TonalLexicon.vector(for: token)
            // Use (calm + energy) / 2 as the polarity proxy
            // (positive when both high, negative when both low)
            let polar = (v.calm + v.energy) / 2.0
            if v.magnitude > 0 {
                sum += polar
                counted += 1
            }
        }
        return counted > 0 ? sum / Double(counted) : 0.0
    }

    /// Build the Socratic prompt. Calm; never verdict.
    private static func makeDevilsAdvocatePrompt(
        currentClaim: String,
        pastText: String,
        daysAgo: Int,
        opposition: Double
    ) -> String {
        let dayWord = daysAgo == 1 ? "day" : "days"
        let claimSnippet = currentClaim.count > 80
            ? String(currentClaim.prefix(80)) + "..."
            : currentClaim
        return "\(daysAgo) \(dayWord) ago you wrote something different. " +
            "Now you seem to be forming \"\(claimSnippet)\". " +
            "Is this growth, or forgetting?"
    }

    /// Convenience: turn a LifeContext + the user's reflection store + opened
    /// Sacred Echoes into a MentorInput. This is the only place that touches
    /// the broader app state.
    public static func makeInput(
        from context: LifeContext,
        openedEchoes: [(UUID, String, String, Date)] = []
    ) -> MentorInput {
        // Reflections come from LifeEntity.summary text on .task / .concept /
        // .event entities whose memoryType is .procedural or .episodic AND
        // whose `isUserReflection == true` (Nemotron #39). This prevents
        // contact org names, calendar notes, and reminder bodies from being
        // misattributed as "you wrote" in Mentor responses.
        let now = Date()
        var seeds: [MentorInput.ReflectionSeed] = []
        for e in context.lifeGraphEntities {
            guard e.isUserReflection else { continue }
            let trimmed = e.summary.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            guard e.memoryType == .procedural || e.memoryType == .episodic else { continue }
            // Skip obvious non-reflection placeholders.
            if trimmed.lowercased().contains("no reflection") { continue }
            if trimmed.lowercased().hasPrefix("[pending reflection]") { continue }

            let days = max(0, Int(now.timeIntervalSince(e.createdAt) / 86400))
            seeds.append(.init(
                id: e.id,
                text: trimmed,
                domains: e.domains,
                daysAgo: days,
                harmonyImpact: e.harmonyImpact
            ))
        }

        var echoSeeds: [MentorInput.OpenedEchoSeed] = []
        for (id, title, text, openedAt) in openedEchoes {
            let days = max(0, Int(now.timeIntervalSince(openedAt) / 86400))
            echoSeeds.append(.init(
                id: id,
                title: title,
                text: text,
                daysSinceOpened: days
            ))
        }

        return MentorInput(
            reflections: seeds,
            openedEchoes: echoSeeds,
            coherenceScore: context.lifeCoherenceScore,
            completedQuestCount: context.completedQuestCount,
            now: now
        )
    }

    // MARK: - Private helpers

    /// Compose the spoken line. The Mentor speaks AS past-self, addressing
    /// the user in their own voice (via their own words). We never paraphrase
    /// in a way that misrepresents the user's reflection — we either quote it
    /// or quote it lightly with a soft frame.
    private static func composeSpoken(
        seed: MentorInput.ReflectionSeed,
        prompt: String,
        relevance: Double
    ) -> String {
        let excerpt = String(seed.text.prefix(180))
        let timeRef = timeReference(daysAgo: seed.daysAgo)

        // Frame variants depending on relevance + age. We never invent content;
        // every spoken line ends with the user's own words.
        let frame: String
        if seed.daysAgo <= 7 {
            frame = "From \(timeRef):"
        } else if seed.daysAgo <= 90 {
            frame = "\(timeRef.capitalized) you wrote:"
        } else {
            frame = "A reflection from \(timeRef) — still yours:"
        }
        return "\(frame)\n\n\"\(excerpt)\""
    }

    private static func timeReference(daysAgo: Int) -> String {
        switch daysAgo {
        case 0: return "earlier today"
        case 1: return "yesterday"
        case 2..<7: return "\(daysAgo) days ago"
        case 7..<30: return "\(daysAgo / 7) weeks ago"
        case 30..<365: return "\(daysAgo / 30) months ago"
        default: return "over a year ago"
        }
    }

    private static func tokenize(_ s: String) -> Set<String> {
        // Minimal tokenization: lowercase, split on whitespace and punctuation,
        // drop short tokens. Good enough for lexical overlap without bringing
        // in NLP frameworks (we want this to work on Linux too).
        let lowered = s.lowercased()
        let separators = CharacterSet.whitespacesAndNewlines
            .union(.punctuationCharacters)
        let parts = lowered.components(separatedBy: separators)
        return Set(parts.filter { $0.count >= 3 })
    }

    private static func jaccard(_ a: Set<String>, _ b: Set<String>) -> Double {
        if a.isEmpty || b.isEmpty { return 0.0 }
        let intersection = a.intersection(b).count
        let union = a.union(b).count
        return Double(intersection) / Double(union)
    }

    /// Pull domain tags out of the prompt text. Domains are the canonical
    /// thread names: CareKin, Stewardship, Meaning, Self.
    private static func extractDomains(from prompt: String) -> [String] {
        let known = ["CareKin", "Stewardship", "Meaning", "Self"]
        return known.filter { prompt.localizedCaseInsensitiveContains($0) }
    }
}

// MARK: - Numeric clamping helper

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}