"""
Tier A #1 validation mirror — replicates the @MainActor + cache logic from
GraphInsightGenerator.swift in pure Python so we can verify the cache
behaviour end-to-end without a Swift compiler on this Linux VPS.
"""

import time
from dataclasses import dataclass, field
from typing import List, Optional


@dataclass
class GraphInsight:
    title: str
    description: str
    confidence: float
    domains: List[str]
    suggested_action: Optional[str]
    essence_bonus: float


@dataclass
class LifeEntity:
    id: str
    entity_type: str
    harmony_impact: float
    domains: List[str]
    memory_type: str = "episodic"
    is_private: bool = False


@dataclass
class LifeContextLite:
    life_coherence_score: float
    completed_quest_count: int
    mastery_tiers: dict
    current_season: str
    grace_days_used: int
    energy_profile: str
    weave_essence: float = 0.0
    essence_ledger: List[str] = field(default_factory=list)
    harmony_score: float = 0.5


class GraphInsightGeneratorLite:
    TTL = 5 * 60

    def __init__(self):
        self.cache_key = None
        self.cache_insights = []
        self.cache_generated_at = None
        self.hits = 0
        self.misses = 0
        self.invalidations = 0

    def invalidate(self):
        self.invalidations += 1
        self.cache_key = None
        self.cache_insights = []
        self.cache_generated_at = None

    def reset_counters(self):
        self.hits = 0
        self.misses = 0
        self.invalidations = 0

    def stats(self):
        return (self.hits, self.misses, self.invalidations)

    def _make_key(self, context, entities):
        sig = 0
        for e in entities:
            sig ^= (hash(e.id) + 0x9E3779B9) & 0xFFFFFFFF
            sig ^= ((hash(e.entity_type) + 0x85EBCA6B) << 1) & 0xFFFFFFFF
            sig ^= ((int(e.harmony_impact * 100) + 0xC2B2AE35) << 2) & 0xFFFFFFFF
        coherence_bucket = int(context.life_coherence_score * 100)
        mastery_hash = 0
        for k, v in context.mastery_tiers.items():
            mastery_hash ^= ((hash(k) + 0x27D4EB2F) << (v % 16)) & 0xFFFFFFFF
        energy_raw = {"low": 1, "balanced": 2, "high": 3}[context.energy_profile]
        return (
            sig, coherence_bucket, context.completed_quest_count, mastery_hash,
            context.current_season, context.grace_days_used, energy_raw,
            self.invalidations,
        )

    def _compute(self, context, entities):
        insights = []
        high_impact = [e for e in entities if e.entity_type == "task" and e.harmony_impact > 0.7]
        if context.harmony_score > 0.7 and context.completed_quest_count > 5 and len(high_impact) > 2:
            insights.append(GraphInsight("High Harmony + Quest Momentum", "", 0.85, [], None, 15))
        concepts = [e for e in entities if e.entity_type == "concept"]
        for c in concepts:
            for e in entities:
                if e.id == c.id:
                    continue
                if e.entity_type in ("event", "task") and e.harmony_impact < -0.1:
                    if set(c.domains) & set(e.domains):
                        insights.append(GraphInsight(f"Contradiction: {c.id}", "", 0.7, [], "ritual", 12))
                        break
        return insights

    def generate(self, context, entities):
        key = self._make_key(context, entities)
        now = time.time()
        if (self.cache_key is not None
                and self.cache_key == key
                and (now - (self.cache_generated_at or 0)) < self.TTL
                and (self.cache_insights or self.invalidations == 0)):
            self.hits += 1
            return list(self.cache_insights)
        self.misses += 1
        result = self._compute(context, entities)
        self.cache_key = key
        self.cache_insights = result
        self.cache_generated_at = now
        return list(result)

    def apply_insight(self, insight, context, reflection_text=""):
        if not reflection_text.strip():
            print(f"[Insight] Reflection gate: not awarded for '{insight.title}'")
            return
        context.weave_essence += insight.essence_bonus
        context.essence_ledger.append(f"+{int(insight.essence_bonus)} from {insight.title}")
        context.harmony_score = min(1.0, context.harmony_score + 0.05)
        self.invalidate()


def main():
    gen = GraphInsightGeneratorLite()
    ctx = LifeContextLite(
        life_coherence_score=0.58,
        completed_quest_count=8,
        mastery_tiers={"Stewardship": 3},
        current_season="Autumn",
        grace_days_used=1,
        energy_profile="balanced",
        harmony_score=0.72,
    )
    entities = [
        LifeEntity("a", "task",    0.8,  ["Stewardship"]),
        LifeEntity("b", "task",    0.85, ["Stewardship"]),
        LifeEntity("c", "task",    0.9,  ["Stewardship"]),
        LifeEntity("d", "task",    0.75, ["Stewardship"]),
        LifeEntity("e", "concept", 0.0,  ["Stewardship"]),
        LifeEntity("f", "event",  -0.2,  ["Stewardship"]),
    ]

    results = {}

    gen.reset_counters()
    r1 = gen.generate(ctx, entities)
    r2 = gen.generate(ctx, entities)
    gen.invalidate()
    r3 = gen.generate(ctx, entities)
    s = gen.stats()
    results["hit_count"] = (s[0] == 1)
    results["miss_count"] = (s[1] == 2)
    results["invalidations_count"] = (s[2] == 1)
    results["cache_equality"] = (
        [i.title for i in r1] == [i.title for i in r2] == [i.title for i in r3]
    )
    results["generated_insights"] = len(r1)

    k1 = gen._make_key(ctx, entities)
    k2 = gen._make_key(ctx, entities)
    results["key_stability"] = (k1 == k2)

    entities2 = list(entities)
    entities2[0] = LifeEntity("a2", "task", 0.95, ["Stewardship"])
    k3 = gen._make_key(ctx, entities2)
    results["key_sensitivity"] = (k3 != k1)

    gen.reset_counters()
    _ = gen.generate(ctx, entities)
    _ = gen.generate(ctx, entities)
    if r1:
        gen.apply_insight(r1[0], ctx, reflection_text="This is a real reflection.")
    pre_misses = gen.stats()[1]
    _ = gen.generate(ctx, entities)
    results["apply_forces_miss"] = (gen.stats()[1] == pre_misses + 1)

    ctx2 = LifeContextLite(0.5, 3, {}, "Spring", 0, "balanced")
    gen2 = GraphInsightGeneratorLite()
    gen2.reset_counters()
    pre_invs = gen2.stats()[2]
    gen2.apply_insight(GraphInsight("Test", "", 0.5, [], None, 10), ctx2, reflection_text="   ")
    post_invs = gen2.stats()[2]
    results["empty_reflection_no_invalidation"] = (pre_invs == post_invs)
    results["empty_reflection_no_essence"] = (ctx2.weave_essence == 0.0)

    print("=" * 60)
    print("Tier A #1 (InsightGenerator @MainActor + Cache) Validation")
    print("=" * 60)
    all_pass = True
    for name, passed in results.items():
        mark = "PASS" if passed else "FAIL"
        if not passed:
            all_pass = False
        print(f"  [{mark}] {name}")
    print("=" * 60)
    print(f"OVERALL: {'PASS' if all_pass else 'FAIL'}")
    print(f"  Insights generated on sample graph: {results['generated_insights']}")
    print(f"  Cache stats (last): hits={gen.stats()[0]}, misses={gen.stats()[1]}, invalidations={gen.stats()[2]}")
    print("=" * 60)
    return 0 if all_pass else 1


if __name__ == "__main__":
    import sys
    sys.exit(main())