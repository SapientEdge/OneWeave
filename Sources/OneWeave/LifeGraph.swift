import SwiftData
import Foundation

// MARK: - Life Graph Core (from Feature Matrix + Unified Blueprint)
// Unified ontology for entities and relationships across life domains.
// Extends existing OneWeave Threads/TimelineEvent/WeaveQuest without replacement.
// All data local-first. Vector embeddings for on-device retrieval only.
//
// Privacy stance (Cycle 39 / T171-T178):
//   - Embeddings are Apple-shipped via NaturalLanguage.NLEmbedding
//     (free, on-device, runs offline — verified fail-closed).
//   - Embeddings are RETRIEVAL ONLY. They are NEVER used to synthesize,
//     generate, or paraphrase the user's text. The Invisible Mentor
//     (InvisibleMentor.swift) and Quick Capture (QuickCaptureInbox.swift)
//     only use embeddings to *rerank* candidates drawn from the user's own
//     past writing — they never produce new sentences from embeddings.
//   - Embeddings stay in this struct (Codable, kept on-device). They are
//     not transmitted, not logged, not shared via P2P.
//   - Constitutional alignment: see constitution.md §2 (Privacy-First,
//     Zero-Trust) and §3 (Calm Intelligence — no generation, only retrieval).

// MARK: - LifeEmbedding (Cycle 39 / T171)
//
// Typed wrapper around a sentence-embedding vector produced by
// `OnDeviceEmbedder` (NaturalLanguage.NLEmbedding.sentenceEmbedding(.english)).
//
// Why a struct, not a raw `Data?` blob:
//   1. Strongly-typed access — readers get `[Float]` directly, no manual
//      byte unpacking.
//   2. Versioned — if Apple changes embedding dimensionality or model
//      between OS releases, we can detect old vectors at read time and
//      re-embed on demand (idempotent path in T174).
//   3. Auditable — `generatedAt` lets us answer "when was this entity last
//      embedded?" without external metadata.
//   4. Codable — round-trips through SwiftData + portable export.
//
// The dimension is fixed at 512 (matches the `embeddingData: Data?`
// placeholder's original "MobileBERT-style 512-dim" comment, line 29 in the
// pre-Cycle-39 source). If we ever need a different dimensionality we
// bump `version` and add a migration in `SchemaMigrationPlan.swift`.
public struct LifeEmbedding: Codable, Equatable, Sendable {
    /// 512-dim float32 vector — matches the legacy `embeddingData` capacity
    /// (4 × 512 = 2048 bytes for a Float32 representation).
    public let vector: [Float]
    /// Embedding format version. Bumped if NLEmbedding changes dimensionality
    /// or normalization between iOS versions. `1` = initial Cycle 39 schema.
    public let version: Int
    /// Wall-clock timestamp of when this vector was generated.
    public let generatedAt: Date

    /// Current schema version. Update this constant when introducing a new
    /// vector format — readers should then re-embed.
    public static let currentVersion: Int = 1

    /// Expected dimensionality for the current schema. Kept as a constant so
    /// readers can spot stale vectors without iterating the whole array.
    public static let expectedDimension: Int = 512

    public init(vector: [Float], version: Int = LifeEmbedding.currentVersion, generatedAt: Date = Date()) {
        self.vector = vector
        self.version = version
        self.generatedAt = generatedAt
    }

    /// True if this embedding matches the current schema (version + dim).
    /// Stale embeddings should be re-derived rather than trusted.
    public var isCurrent: Bool {
        return version == LifeEmbedding.currentVersion
            && vector.count == LifeEmbedding.expectedDimension
    }
}

// MARK: - Cosine similarity (Cycle 39 / T173a)
//
// Pure Swift mirror of the Python oracle in `audit/algorithm_oracle.py`.
// Returns 1.0 for identical direction, 0.0 for orthogonal, -1.0 for opposite.
// Identical-to-TonalCoherence.swift::coherenceAngle dot-product but returns
// the raw similarity (not the angle in degrees) — that's what semantic
// retrieval ranks by.
//
// Numerical safety:
//   - Zero-magnitude vectors short-circuit to 0.0 (no NaN).
//   - Dot product is clamped to [-1, 1] before downstream code uses it
//     for an acos, defending against floating-point drift.
@inlinable
public func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Double {
    guard a.count == b.count, !a.isEmpty else { return 0.0 }
    var dot: Double = 0
    var magA: Double = 0
    var magB: Double = 0
    for i in 0..<a.count {
        let ai = Double(a[i])
        let bi = Double(b[i])
        dot += ai * bi
        magA += ai * ai
        magB += bi * bi
    }
    let denom = (magA.squareRoot()) * (magB.squareRoot())
    guard denom > 0 else { return 0.0 }
    let raw = dot / denom
    // Clamp to [-1, 1] — defends against acos drift if a caller asks for θ.
    return max(-1.0, min(1.0, raw))
}

// MARK: - LifeEntity

@Model
final class LifeEntity {
    var id: UUID = UUID()
    var type: EntityType = .concept
    var title: String = ""
    var summary: String = ""
    var createdAt: Date = Date()
    var lastUpdated: Date = Date()

    // Gamification tie-in (from existing LifeContext essence/harmony)
    var essenceContribution: Double = 0
    var harmonyImpact: Double = 0

    // Privacy / Data Leash (from research - critical)
    var isPrivate: Bool = true
    var allowedCategories: [String] = ["personal"]  // e.g. "health", "finance", "social", "work"

    // Vector embedding (Cycle 39 / T171).
    //
    // Was `embeddingData: Data?` (a raw byte buffer placeholder). Now a typed
    // optional `LifeEmbedding` so readers can do `entity.embedding?.vector`
    // directly. SwiftData treats `LifeEmbedding?` as an optional Codable
    // property — the lightweight migration path stores the encoded JSON in
    // the underlying column. Old `Data?` payloads would migrate as nil; a
    // background re-embed pass (T174/T175) populates them on next access.
    //
    // CRITICAL: nil-safe. Every read site must treat `embedding == nil` as
    // "no semantic signal available" — callers fall back to lexical ranking
    // (see `LifeGraph.semanticSearch`, T173).
    var embedding: LifeEmbedding? = nil

    // JSON bag for entity-specific metadata (e.g. HealthMetrics for Body Thread).
    // Nemotron cycle-25 finding: was previously `String = ""` which broke every
    // `entity.attributes = [k: v]` assignment across the codebase. Now typed
    // as `[String: String]` to match SacredEcho + BodyThread conventions.
    var attributes: [String: String] = [:]
    // Distinguishes user-authored reflection text from system-imported content
    // (calendar event notes, contact org names, reminder notes). Invisible
    // Mentor only surfaces entities with `isUserReflection == true` so that
    // contact metadata isn't misattributed as "you wrote". (Nemotron #39)
    var isUserReflection: Bool = false

    // Relationships (SwiftData bidirectional)
    @Relationship(inverse: \LifeRelationship.fromEntity) var outgoingRelationships: [LifeRelationship] = []
    @Relationship(inverse: \LifeRelationship.toEntity) var incomingRelationships: [LifeRelationship] = []

    // Typed memory classification (Episodic/Semantic/Procedural from research)
    var memoryType: MemoryType = .semantic

    // Cross-domain tags for insights
    var domains: [String] = []

    init(type: EntityType, title: String, summary: String = "", memoryType: MemoryType = .semantic) {
        self.type = type
        self.title = title
        self.summary = summary
        self.memoryType = memoryType
    }

    // Fresh idea: Coherence Score contribution (unique to OneWeave)
    func coherenceScoreContribution() -> Double {
        let connectionStrength = Double(outgoingRelationships.count + incomingRelationships.count) * 0.1
        let recency = max(0, 1 - (Date().timeIntervalSince(lastUpdated) / (86400 * 30))) // decay over 30 days
        return (harmonyImpact * 0.4 + essenceContribution * 0.3 + connectionStrength * 0.2 + recency * 0.1).clamped(to: 0...1)
    }
}

enum EntityType: String, Codable, CaseIterable {
    case person, event, task, note, healthMetric, financial, place, project, concept
}

enum MemoryType: String, Codable, CaseIterable {
    case episodic   // past events, conversations (from TimelineEvent)
    case semantic   // facts, preferences, knowledge (from Threads/Notes)
    case procedural // learned workflows, habits (from quests + reflection)
}

@Model
final class LifeRelationship {
    var id: UUID = UUID()
    var type: RelationshipType = .associative
    var strength: Double = 0.5  // 0-1, influenced by harmony/essence
    var createdAt: Date = Date()
    var metadata: [String: String] = [:]  // e.g. "context": "quest reflection"

    @Relationship var fromEntity: LifeEntity?
    @Relationship var toEntity: LifeEntity?

    init(type: RelationshipType, strength: Double = 0.5) {
        self.type = type
        self.strength = strength.clamped(to: 0...1)
    }
}

enum RelationshipType: String, Codable, CaseIterable {
    case temporal, causal, associative, hierarchical, social
}

// MARK: - Integration with existing OneWeave gamification
extension LifeEntity {
    // Bridge from existing Thread/TimelineEvent
    //
    // Cycle 39 / T174: When the source TimelineEvent carries a user-authored
    // reflection (event.type == "reflection" / "weave_commit" with a
    // payload["reflection"]), we now derive a 512-dim embedding on a
    // background queue. Embedding is NEVER computed on the main thread —
    // the SwiftData store sits on MainActor and we must not block it for
    // an NLEmbedding pass that can take 50-300ms on older hardware.
    //
    // Idempotency: if the resulting entity already has an embedding
    // (e.g., seeded entities from older cycles), we skip. Same for the
    // lexical text — we re-use title + summary verbatim rather than
    // re-synthesizing anything. Constitutional §3: retrieval only.
    static func fromTimelineEvent(_ event: TimelineEvent, context: LifeContext) -> LifeEntity {
        let entity = LifeEntity(
            type: .event,
            title: event.type,
            summary: event.payload.values.joined(separator: " "),
            memoryType: .episodic
        )
        entity.domains = [event.thread]
        entity.harmonyImpact = context.harmonyScore
        entity.essenceContribution = 1.0 // base from weaves
        // System-imported content — not a user-authored reflection. The only
        // exception is events of type "weave_commit" / "reflection" which
        // carry user-written text in payload["reflection"] (see ResonanceOracle).
        if let reflection = event.payload["reflection"], !reflection.isEmpty {
            entity.isUserReflection = true
            entity.summary = reflection
            // Cycle 37: feed the reflection timestamp into the LifeContext
            // so computedHarmonyScore.reflectionPace actually reflects the
            // user's cadence. (Was previously always 0.)
            context.recordReflection(at: event.timestamp)
            // Cycle 39 / T174: schedule a background embedding pass for the
            // user-authored reflection. We pass the text only; the embedder
            // returns `nil` on OOM or token-cap-exceeded and we leave
            // `entity.embedding == nil` — `LifeGraph.semanticSearch` knows
            // how to fall back to lexical ranking in that case.
            OnDeviceEmbedder.shared.embedInBackground(
                text: entity.title + " " + entity.summary,
                assignTo: entity
            )
        }
        // Add relationships to active threads
        return entity
    }

    // From WeaveQuest (Task). Honours Nemotron #8: derive essence from quest.baseEssence
    // (and gate on completion). Reflection is required for the entity to be created from
    // a completed quest.
    static func fromQuest(_ quest: WeaveQuest) -> LifeEntity {
        return fromQuest(quest, context: nil)
    }

    /// Cycle 37 overload: accepts a LifeContext so the reflection timestamp
    /// can be recorded (feeds computedHarmonyScore.reflectionPace).
    /// `nil` context = no recording (legacy path, tests, prototypes).
    ///
    /// Cycle 39 / T175: when the quest carries a non-empty `reflectionNote`,
    /// we ALSO schedule a background embedding pass (same idempotency
    /// guarantees as `fromTimelineEvent`). We pass `title + " " + reflectionNote`
    /// as the embedding text — exactly the text a user would search for if
    /// they later asked "show me when I felt this way about Stewardship".
    static func fromQuest(_ quest: WeaveQuest, context: LifeContext?) -> LifeEntity {
        let entity = LifeEntity(
            type: .task,
            title: quest.title,
            summary: quest.reflectionNote ?? "No reflection yet",
            memoryType: .procedural
        )
        entity.domains = quest.domains
        entity.essenceContribution = Double(quest.baseEssence)
        // A quest reflection is genuine user-authored content; mark it so
        // Invisible Mentor surfaces it as "you wrote" rather than as
        // synthesized system content. (Nemotron #39.)
        entity.isUserReflection = (quest.reflectionNote?.isEmpty == false)
        // If the quest hasn't been completed, tag memory as still-procedural but mark
        // isPrivate so it doesn't leak through P2P / insights until the user reflects.
        if quest.completedAt == nil {
            entity.isPrivate = true
            entity.summary = "[Pending reflection] " + entity.summary
        }
        // Cycle 37: record reflection timestamp when quest has one.
        // Use completedAt if available, else quest creation time.
        if entity.isUserReflection {
            let when = quest.completedAt ?? quest.createdAt ?? Date()
            context?.recordReflection(at: when)
            // Cycle 39 / T175: schedule background embedding of the user's
            // reflection text. Same idempotency rules as T174 — skip if
            // `entity.embedding` is already populated (defensive: tests +
            // double-import paths can call this twice with the same entity).
            let embeddingText = entity.title + " " + (quest.reflectionNote ?? "")
            OnDeviceEmbedder.shared.embedInBackground(
                text: embeddingText,
                assignTo: entity
            )
        }
        return entity
    }
}

extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Graph Operations (for Insight Engine + retrieval foundation)
struct LifeGraph {
    static func buildCoherenceScore(entities: [LifeEntity]) -> Double {
        guard !entities.isEmpty else { return 0 }
        let total = entities.reduce(0) { $0 + $1.coherenceScoreContribution() }
        return (total / Double(entities.count)).clamped(to: 0...1)
    }

    // Fresh unique idea: "Weave Resonance" - graph-based harmony boost
    static func calculateResonance(for entity: LifeEntity, allEntities: [LifeEntity]) -> Double {
        let connected = allEntities.filter { e in
            entity.outgoingRelationships.contains(where: { $0.toEntity?.id == e.id }) ||
            entity.incomingRelationships.contains(where: { $0.fromEntity?.id == e.id })
        }
        let avgHarmony = connected.isEmpty ? 0.5 : connected.reduce(0) { $0 + $1.harmonyImpact } / Double(connected.count)
        return (entity.harmonyImpact * 0.6 + avgHarmony * 0.4).clamped(to: 0...1)
    }

    // MARK: - Cycle 39 / T173: semanticSearch(query:in:limit:)
    //
    // Retrieval over the Life Graph using Apple-shipped on-device sentence
    // embeddings (NaturalLanguage.NLEmbedding). Falls back to lexical-only
    // ranking if >50% of the candidate corpus lacks embeddings — this
    // protects users with sparse reflection history from receiving
    // "no results" when their history clearly has something relevant.
    //
    // The query text is embedded on the calling thread (caller is
    // responsible for dispatching off-main). The candidate corpus scan
    // is O(N) over `entities` and pure CPU — safe to run synchronously
    // for thousands of entities on any modern iPhone/Mac.
    //
    // Returns ranked candidates (highest similarity first), capped at
    // `limit`. Empty input → empty output. Empty corpus → empty output.
    //
    // Fallback rule (T173b): if `embeddingMissingFraction > 0.5`, we use
    // lexical overlap (Jaccard on tokens, identical to the InvisibleMentor
    // ranker) instead of cosine. This keeps search useful during the
    // early days of a user's history (only a handful of reflections
    // embedded) while automatically upgrading to semantic ranking as
    // the corpus matures.
    public static func semanticSearch(
        query: String,
        in entities: [LifeEntity],
        limit: Int = 5
    ) -> [LifeEntity] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !entities.isEmpty, limit > 0 else { return [] }

        let totalCount = entities.count
        let withEmbedding = entities.filter { $0.embedding?.isCurrent == true }.count
        let missingFraction = totalCount == 0 ? 0.0 : Double(totalCount - withEmbedding) / Double(totalCount)

        // ── Fallback path (T173b): lexical-only when >50% of corpus is unembedded ──
        if missingFraction > 0.5 {
            return lexicalRank(query: trimmed, entities: entities, limit: limit)
        }

        // ── Primary path: cosine over current-schema embeddings ──
        // Embed the query on the current thread. We deliberately do NOT
        // hop to a background queue here — callers (QuickCaptureInbox,
        // InvisibleMentor) wrap us in their own background work. The
        // embed call is fast (~10ms for short queries) when the model
        // is already cached by `OnDeviceEmbedder.shared`.
        guard let queryVector = OnDeviceEmbedder.shared.embed(trimmed) else {
            // Embedder returned nil (OOM, token cap, or NLEmbedding not
            // available on this device). Degrade gracefully to lexical.
            return lexicalRank(query: trimmed, entities: entities, limit: limit)
        }

        // Score every entity that has a CURRENT embedding. Stale-format
        // embeddings (wrong dim or version) are treated as missing —
        // see LifeEmbedding.isCurrent.
        struct Scored {
            let entity: LifeEntity
            let score: Double
        }
        var scored: [Scored] = []
        scored.reserveCapacity(withEmbedding)
        for entity in entities {
            guard let emb = entity.embedding, emb.isCurrent else { continue }
            let s = cosineSimilarity(queryVector, emb.vector)
            scored.append(Scored(entity: entity, score: s))
        }

        // Top-k selection (T173c). Stable sort on score desc; ties broken
        // by recency (newer first) so the user sees their most recent
        // match in case of a numerical draw.
        let top = scored
            .sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                return lhs.entity.lastUpdated > rhs.entity.lastUpdated
            }
            .prefix(limit)
            .map { $0.entity }

        return Array(top)
    }

    // Lexical ranker used by the fallback path. Same Jaccard scheme as
    // InvisibleMentor.swift — tokens are lowercased, split on punctuation
    // + whitespace, length ≥ 3. This is intentional: the fallback must
    // produce results consistent with the Mentor's existing ranking so
    // the user does not see "this is your closest match" jump around
    // depending on whether their corpus is embedded or not.
    private static func lexicalRank(query: String, entities: [LifeEntity], limit: Int) -> [LifeEntity] {
        let queryTokens = Self.tokenize(query)
        guard !queryTokens.isEmpty else {
            // No usable tokens → return recent entities by `lastUpdated`.
            return Array(entities.sorted { $0.lastUpdated > $1.lastUpdated }.prefix(limit))
        }
        struct Scored {
            let entity: LifeEntity
            let score: Double
        }
        let scored: [Scored] = entities.compactMap { e in
            let text = e.title + " " + e.summary
            let tokens = Self.tokenize(text)
            guard !tokens.isEmpty else { return nil }
            let intersection = queryTokens.intersection(tokens).count
            let union = queryTokens.union(tokens).count
            let jaccard = union == 0 ? 0.0 : Double(intersection) / Double(union)
            return Scored(entity: e, score: jaccard)
        }
        let top = scored
            .sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                return lhs.entity.lastUpdated > rhs.entity.lastUpdated
            }
            .prefix(limit)
            .map { $0.entity }
        return Array(top)
    }

    // Tokenizer shared between the lexical fallback and (potentially)
    // future diagnostic dumps. Mirrors the InvisibleMentor tokenizer.
    private static func tokenize(_ s: String) -> Set<String> {
        let lowered = s.lowercased()
        let separators = CharacterSet.whitespacesAndNewlines
            .union(.punctuationCharacters)
        let parts = lowered.components(separatedBy: separators)
        return Set(parts.filter { $0.count >= 3 })
    }

    // MARK: - Cycle 39 / T178a: corpus embedding-coverage stat
    //
    // Returns the fraction of entities that lack a current-schema embedding.
    // Used by `EmbeddingCoverageHint` (T178) to decide whether to surface
    // the one-time UI hint "Search will improve as you add reflections."
    public static func missingEmbeddingFraction(in entities: [LifeEntity]) -> Double {
        guard !entities.isEmpty else { return 0.0 }
        let missing = entities.filter { $0.embedding?.isCurrent != true }.count
        return Double(missing) / Double(entities.count)
    }
}