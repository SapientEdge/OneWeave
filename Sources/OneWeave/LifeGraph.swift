import SwiftData
import Foundation

// MARK: - Life Graph Core (from Feature Matrix + Unified Blueprint)
// Unified ontology for entities and relationships across life domains.
// Extends existing OneWeave Threads/TimelineEvent/WeaveQuest without replacement.
// All data local-first. Vector embeddings for future on-device RAG/semantic search.
// Privacy: Per-entity Data Leash flags (default strict).

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
    
    // Vector embedding placeholder (512-dim for MobileBERT-style; store as Data for Core ML/Accelerate)
    // In real: compute on-device with Core ML or llama.cpp embeddings
    var embeddingData: Data? = nil
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
        }
        return entity
    }
}

extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Graph Operations (for Insight Engine + RAG foundation)
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
    
    // Placeholder for on-device vector similarity (future: Accelerate or Core ML)
    static func semanticSearch(queryEmbedding: Data, entities: [LifeEntity], topK: Int = 5) -> [LifeEntity] {
        // Stub for now - in production: cosine similarity on embeddingData
        // For prototype validation: return recent high-coherence entities
        return Array(entities.sorted { $0.lastUpdated > $1.lastUpdated }.prefix(topK))
    }
}
