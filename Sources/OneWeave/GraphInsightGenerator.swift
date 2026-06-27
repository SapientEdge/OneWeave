import Foundation
import SwiftData

// Cross-Domain Insight Engine (from Feature Matrix + Unified Blueprint)
// Uses Life Graph + existing harmony/quests/essence for "Aha!" moments.
// All on-device. Privacy-respecting (respects Data Leash).
// Fresh OneWeave twist: Insights can award essence and suggest graph-linked quests.

struct GraphInsight: Identifiable {
    let id: UUID = UUID()
    let title: String
    let description: String
    let confidence: Double // 0-1
    let domains: [String]
    let suggestedAction: String?
    let essenceBonus: Double
}

// MARK: - Insight Generator State
//
// All insight generation runs on the main actor (consistent with `commitWeave`
// in ResonanceOracle, with the SwiftUI binding surface in LifeContext, and with
// the call sites in OneWeavePrototype / OneWeavePrototype+GraphValidation).
//
// Caching: `generateInsights` is now non-allocating on warm cache. The cache is
// keyed by (entity-signature, context-version, contradiction-rule-version) and
// has a 5-minute TTL. Callers that mutate the underlying state MUST invoke
// `invalidateCache()` to force regeneration next read.
//
// Why a cache here?
// - Insight generation scans the whole Life Graph plus the LiveContext state.
// - It runs on every render of the Compass HUD / Oracle sheet.
// - Under load (large graphs, live P2P receive), regeneration can cause UI
//   hitches. The cache turns repeated reads into O(1) lookups.
// - Reflection-gated awards still go through `applyInsight` — the cache only
//   stores the *generated insights list*, never the awarded essence.
//
// Privacy: caching is fully local. No insight content leaves the device.
// Audit: invalidation calls are logged with a counter so we can verify the
// cache is actually invalidating when expected.
@MainActor
struct GraphInsightGenerator {

    // MARK: Cache state (main-actor isolated)

    /// Cached insight list, keyed by the signature at the time of generation.
    private static var cache: (
        key: InsightCacheKey?,
        insights: [GraphInsight],
        generatedAt: Date
    ) = (nil, [], .distantPast)

    /// TTL for the insight cache. After this many seconds, the next
    /// `generateInsights` call regenerates regardless of the key.
    static let cacheTTLSeconds: TimeInterval = 5 * 60

    /// Monotonic counter incremented on every explicit invalidation. Useful
    /// for tests and for the build-log audit trail.
    private static var invalidationCount: Int = 0

    /// Counter of cache hits (returned cached insights without regenerating).
    /// Reset on `resetCounters()`. Exposed for the prototype harness.
    private static var cacheHits: Int = 0

    /// Counter of cache misses (had to regenerate).
    private static var cacheMisses: Int = 0

    /// Cache key: a fingerprint of (entity ids + types + harmonyImpacts,
    /// coherenceScore, completedQuestCount, masteryTiers, currentSeason,
    /// graceDaysUsed, energyProfile) at the moment we generated. Plus a
    /// generation-counter suffix so any caller-visible mutation can force a
    /// miss simply by bumping the key.
    private struct InsightCacheKey: Equatable {
        let entitySignature: Int        // XOR-folded hash of (id, type, harmonyImpact)
        let coherenceScoreBucket: Int   // rounded to 0.01
        let harmonyScoreBucket: Int     // Nemotron cycle-25 #27: harmony thresholds
                                        // (e.g. ">0.7 triggers insight") depend on
                                        // this; bucket to 0.01 to avoid stale results.
        let completedQuestCount: Int
        let masteryTiersHash: Int
        let currentSeason: String
        let graceDaysUsed: Int
        let energyProfileRaw: Int
        let generation: Int             // increments on every explicit invalidation
    }

    /// Force the next `generateInsights` to regenerate. Call after `commitWeave`,
    /// `logWeave`, or any new-entity write. Safe to call repeatedly.
    static func invalidateCache() {
        invalidationCount += 1
        cache.key = nil
        cache.insights = []
        cache.generatedAt = .distantPast
    }

    /// Reset hit/miss counters (useful for the prototype harness so each
    /// validation run gets a clean slate).
    static func resetCounters() {
        cacheHits = 0
        cacheMisses = 0
        invalidationCount = 0
    }

    /// Snapshot of the cache counters — surfaced in the prototype harness so we
    /// can verify the cache is doing useful work in the validation runs.
    static func cacheStats() -> (hits: Int, misses: Int, invalidations: Int) {
        (cacheHits, cacheMisses, invalidationCount)
    }

    // MARK: - Core engine (cross-domain correlations)

    /// Generate cross-domain insights. Cached for `cacheTTLSeconds` per key.
    /// Callers that mutate state must invoke `invalidateCache()` to force
    /// regeneration; otherwise stale insights will be returned for up to 5 min.
    static func generateInsights(from context: LifeContext, entities: [LifeEntity]) -> [GraphInsight] {
        let key = makeCacheKey(from: context, entities: entities)

        // Cache hit?
        if let cachedKey = cache.key,
           cachedKey == key,
           Date().timeIntervalSince(cache.generatedAt) < cacheTTLSeconds {
            cacheHits += 1
            return cache.insights
        }

        cacheMisses += 1
        let insights = computeInsights(from: context, entities: entities)
        cache = (key, insights, Date())
        return insights
    }

    /// Pure (uncached) insight computation. Split out so the cache layer is
    /// easy to test and reason about in isolation.
    private static func computeInsights(from context: LifeContext, entities: [LifeEntity]) -> [GraphInsight] {
        var insights: [GraphInsight] = []
        
        // 1. Harmony vs Quest Completion (existing data + graph)
        let highHarmonyQuests = entities.filter { $0.type == .task && $0.harmonyImpact > 0.7 }.count
        if context.harmonyScore > 0.7 && context.completedQuestCount > 5 && highHarmonyQuests > 2 {
            insights.append(GraphInsight(
                title: "High Harmony + Quest Momentum",
                description: "Your harmony is strong and you're completing quests with high impact. This pattern often precedes major life coherence jumps.",
                confidence: 0.85,
                domains: ["wellness", "productivity"],
                suggestedAction: "Forge a custom quest linking a CareKin thread to a Meaning goal.",
                essenceBonus: 15
            ))
        }
        
        // 2. Graph Resonance (new from LifeGraph)
        if !entities.isEmpty {
            let avgResonance = entities.reduce(0.0) { $0 + LifeGraph.calculateResonance(for: $1, allEntities: entities) } / Double(entities.count)
            if avgResonance > 0.75 {
                insights.append(GraphInsight(
                    title: "Strong Weave Resonance Detected",
                    description: "Your Life Graph shows high connection strength across threads. Relationships and events are reinforcing each other.",
                    confidence: 0.78,
                    domains: ["social", "meaning"],
                    suggestedAction: "Share a subset of high-resonance entities via Weave Circle (P2P) for reflection.",
                    essenceBonus: 10
                ))
            }
        }
        
        // 3. Seasonal + Energy Pattern (from current seasons + energyProfile)
        let season = context.currentSeason
        if season == "Autumn" && context.energyProfile == .low && context.graceDaysUsed > 0 {
            insights.append(GraphInsight(
                title: "Autumn Grace Window",
                description: "You're using grace days in a reflective season. This is a powerful time for Life Graph review and relationship maintenance.",
                confidence: 0.7,
                domains: ["wellness", "stewardship"],
                suggestedAction: "Create a 'Relationship Decay Check' quest for CareKin entities.",
                essenceBonus: 8
            ))
        }
        
        // 4. Coherence vs Mastery (unique fusion)
        if context.lifeCoherenceScore > 0.65 && context.masteryTiers.values.contains(where: { $0 >= 3 }) {
            insights.append(GraphInsight(
                title: "Coherence-Mastery Alignment",
                description: "High life coherence combined with mastery progress in one or more threads. This is rare and valuable.",
                confidence: 0.9,
                domains: ["growth", "meaning"],
                suggestedAction: nil,
                essenceBonus: 20
            ))
        }
        
        // 5. Typed Memory Insight (episodic heavy?)
        let episodicCount = entities.filter { $0.memoryType == .episodic }.count
        if Double(episodicCount) / Double(max(1, entities.count)) > 0.6 {
            insights.append(GraphInsight(
                title: "Episodic Memory Dominant",
                description: "Your graph is rich with events and reflections. Consider synthesizing into semantic Concepts for long-term wisdom.",
                confidence: 0.65,
                domains: ["intelligence"],
                suggestedAction: "Convert recent high-impact TimelineEvents into Concept entities.",
                essenceBonus: 5
            ))
        }

        // 6. Contradiction Weaver (novel creative feature) — appended via separate detector.
        insights += detectContradictions(in: context)

        return insights.sorted { $0.confidence > $1.confidence }
    }

    // MARK: - Contradiction Weaver (novel creative feature)

    /// Detect cognitive dissonance: a high-value concept entity contradicted by an event/task
    /// whose harmonyImpact is negative on the same domain.
    /// Returns a non-judgmental ritual prompt. Awarding essence / coherence is gated on
    /// the user actually writing a reflection — never automatic.
    static func detectContradictions(in context: LifeContext) -> [GraphInsight] {
        let entities = context.lifeGraphEntities
        var insights: [GraphInsight] = []

        // Rule A: concept vs conflicting event/task on overlapping domain
        // (Nemotron + Claude cycle-14 finding.)
        let concepts = entities.filter { $0.type == .concept }
        for concept in concepts {
            let conflicting = entities.filter { e in
                guard e.id != concept.id else { return false }
                guard e.type == .event || e.type == .task else { return false }
                let overlaps = !Set(concept.domains).isDisjoint(with: Set(e.domains))
                return overlaps && e.harmonyImpact < -0.1
            }
            if !conflicting.isEmpty {
                let ritual = """
                You value "\(concept.title)" but recent weaves in the same domain suggest tension.

                Take 5 minutes to reflect: what part of this tension is yours to name, and what part is yours to soften?

                (Reflection required before any coherence is awarded.)
                """
                insights.append(GraphInsight(
                    title: "Contradiction Weave: \(concept.title)",
                    description: "Detected tension between a concept you hold and recent activity.",
                    confidence: min(0.95, 0.5 + 0.1 * Double(conflicting.count)),
                    domains: Array(Set(concept.domains + conflicting.flatMap { $0.domains })),
                    suggestedAction: ritual,
                    essenceBonus: 12  // only awarded on reflection
                ))
            }
        }

        // Rule B: stewardship load vs body depletion / care-starved
        // (Claude cycle-14 finding: surfaces when investment exceeds restoration capacity.)
        let stewardshipLoad = entities
            .filter { $0.domains.contains("Stewardship") && $0.harmonyImpact > 0.1 }.count
        let bodyDepleted = entities.contains { e in
            e.type == .healthMetric && e.harmonyImpact < -0.02
        }
        let careStarved = !entities.contains { e in
            e.domains.contains("CareKin")
        }
        if stewardshipLoad >= 3 && (bodyDepleted || careStarved) {
            let axis = bodyDepleted ? "your body is signaling depletion" : "CareKin threads are thinning"
            insights.append(GraphInsight(
                title: "Contradiction: Work vs. Restoration",
                description: "You're heavily weaving Stewardship while \(axis). Held too long, this pattern erodes the coherence that work depends on.",
                confidence: 0.72,
                domains: ["stewardship", "wellness"],
                suggestedAction: "Ritual: name one Stewardship commitment you can soften this week, and one small CareKin or Body weave to place beside it.",
                essenceBonus: 12
            ))
        }

        return insights
    }

    // MARK: - Insight award (reflection-gated)

    /// Apply an insight. **Callers MUST gate on user reflection before invoking with non-zero essenceBonus.**
    /// This function does not award essence unless `reflectionText` is non-empty.
    /// Side effect: a successful apply invalidates the insight cache so the next
    /// `generateInsights` call sees the updated harmony/essence and re-prioritises.
    /// Persists the underlying LifeContext changes via the supplied modelContext
    /// so a crash before SwiftData autosave doesn't lose the awarded essence
    /// (Nemotron cycle-25 #28).
    static func applyInsight(
        _ insight: GraphInsight,
        to context: LifeContext,
        reflectionText: String = "",
        modelContext: ModelContext? = nil
    ) {
        let trimmed = reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            print("[Insight] Reflection gate: essence not awarded for \"\(insight.title)\" without reflection.")
            return
        }
        context.weaveEssence += insight.essenceBonus
        context.essenceLedger.append("+\(Int(insight.essenceBonus)) from insight: \(insight.title)")
        // Gentle harmony boost (anti-addictive)
        context.harmonyScore = min(1.0, context.harmonyScore + 0.05)
        // Persist before invalidating the cache so a crash doesn't lose
        // the awarded essence. Save failures are logged but don't block —
        // autosave will retry on next write.
        if let mc = modelContext {
            do {
                try mc.save()
            } catch {
                print("[Insight] modelContext.save failed: \(error)")
            }
        }
        // Cache invalidation: applying an insight changes harmony + essence,
        // so any insight that depends on those should re-prioritise next read.
        invalidateCache()
    }

    // MARK: - Cache key construction

    /// Build a cache key from the inputs that affect insight generation. Hashing
    /// is fold-based (XOR over a stable per-entity signature) so it's O(n) over
    /// entities but allocation-free. The key includes the explicit
    /// `invalidationCount` so callers can force a miss simply by invalidating.
    private static func makeCacheKey(from context: LifeContext, entities: [LifeEntity]) -> InsightCacheKey {
        var sig: Int = 0
        for e in entities {
            // Combine id-hash, type raw, and harmonyImpact bucket.
            let idHash = e.id.uuidString.hashValue
            let typeRaw = e.type.rawValue.hashValue
            let impactBucket = Int((e.harmonyImpact * 100).rounded())
            sig ^= idHash &+ 0x9E3779B9
            sig ^= (typeRaw &+ 0x85EBCA6B) &<< 1
            sig ^= (impactBucket &+ 0xC2B2AE35) &<< 2
        }

        // Bucket coherence to 0.01 to allow small float drift without churn.
        let coherenceBucket = Int((context.lifeCoherenceScore * 100).rounded())
        // Bucket harmony the same way (Nemotron #27).
        let harmonyBucket = Int((context.harmonyScore * 100).rounded())

        // Fold masteryTiers dictionary into a stable hash.
        var masteryHash: Int = 0
        for (k, v) in context.masteryTiers {
            masteryHash ^= (k.hashValue &+ 0x27D4EB2F) &<< (v % 16)
        }

        let energyRaw: Int
        switch context.energyProfile {
        case .low: energyRaw = 1
        case .normal: energyRaw = 2
        case .high: energyRaw = 3
        }

        return InsightCacheKey(
            entitySignature: sig,
            coherenceScoreBucket: coherenceBucket,
            harmonyScoreBucket: harmonyBucket,
            completedQuestCount: context.completedQuestCount,
            masteryTiersHash: masteryHash,
            currentSeason: context.currentSeason,
            graceDaysUsed: context.graceDaysUsed,
            energyProfileRaw: energyRaw,
            generation: invalidationCount
        )
    }
}
