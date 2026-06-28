# OneWeave Algorithm Audit Report

**Date**: 2026-06-28
**Scope**: All Swift source code in `Sources/OneWeave/` (61 files, 17,859 LOC)
**Method**: Python oracle (algorithm_oracle.py) + fuzz testing (algorithm_fuzz.py)
          + Swift source extraction (verify_against_source.py)
**Test count**: 43 unit tests + 9 fuzz properties × 10,000 iterations each

---

## EXECUTIVE SUMMARY

| Status | Count |
|--------|-------|
| ✅ Algorithms fully verified (formula matches implementation, edge cases handled) | 8 |
| ⚠️  Algorithms simplified vs documentation but functional | 2 |
| ❌ "Algorithms" that are actually incremental counters (no real formula) | 2 |
| 🆕 New algorithm primitives needing verification | 0 |

**Critical finding**: `harmonyScore` is **not a real algorithm** — it's a counter
that drifts via hardcoded nudges (+0.05, +0.08, +0.10...). This is shown to users
as a percentage. Risk: misleading users with no defensible formula.

---

## VERIFIED ALGORITHMS (all tests pass, 80,000+ random inputs)

### 1. CognitiveLoad.compute (Sources/OneWeave/CognitiveLoad.swift:186-246)

**Formula** (verified line-by-line against source):
```
score = Σᵢ (componentᵢ × weightᵢ)  clamped to [0, 1]
where:
  component_calendar    = min(events_4h / 8, 1)                          weight 0.20
  component_tasks       = min((quests + threads*0.4) / 20, 1)            weight 0.20
  component_sleep       = piecewise under/over target                    weight 0.20
  component_hrv         = piecewise ratio-based                          weight 0.15
  component_reflection  = min(days_since_reflection / 7, 1)              weight 0.15
  component_amplifier   = active_amplifier_strain                        weight 0.10
weights sum: 1.0 ✓
```

**Pause gate**: Triggers `Weave Pause` ONLY when `score >= 0.85` AND `trend == .rising`
(constitution §3: don't punish chronically overloaded users who have adapted).

**Tests**: 11 unit tests + boundary conditions + score range [0,1] verified.

### 2. Vitality (Sources/OneWeave/RelationshipDecayTracker.swift:343-376)

**Formula**:
```
V(t) = V₀ · e^(-λ·Δt) · (1 + √(Σκᵢ))  clamped to [0, 1]
where:
  λ = 0.005 / day (base decay rate)
  κᵢ = 0.15 per event, halved if clustered within 3 days
  Δt = days since last care event (or lastInteractionAt)
```

**Properties verified**:
- Monotonic in time (more time → lower vitality)
- Always in [0, 1]
- Diminishing returns on clustered care events (anti-binge)
- No NaN/Inf for any input

### 3. RhizomeIndex (Sources/OneWeave/RelationshipDecayTracker.swift:393-416)

**Formula**:
```
R = depth² / (1 + breadth)     [depth clamped to 365]
kind = classifier(R, depth, breadth):
  - taproot_starved: depth≥180 AND breadth≤2
  - rhizome_noisy:   depth<90  AND breadth≥8
  - balanced:        depth≥90  AND breadth≥4
  - developing:      otherwise
```

**Properties verified**: R ≥ 0, kind always one of 4 valid values.

### 4. TonalCoherence (Sources/OneWeave/TonalCoherence.swift:160-256)

**Formulas**:
```
distance(a,b) = √(Σᵢ (aᵢ - bᵢ)²)       4-dim Euclidean
magnitude(v)  = √(Σᵢ vᵢ²)               4-dim L2 norm
angle(a,b)    = acos(clamp(cos θ, -1, 1)) × 180/π    with clamp defense
              = undefined (None) if either magnitude is 0
```

**Properties verified**: symmetric, triangle inequality, [0,180] range, FP drift
clamp defense prevents NaN.

### 5. LoomGeometry (Sources/OneWeave/LoomGeometry.swift:79-84)

**Formulas**:
```
magnitude(p) = √(x² + y²)
distance(p,q) = √((p.x-q.x)² + (p.y-q.y)²)
```

Trivial 2D Euclidean. Verified.

### 6. ReflectionGate (Sources/OneWeave/ReflectionGate.swift:60-72)

**Formula**:
```
H = -Σᵢ (pᵢ × log₂(pᵢ))    where pᵢ = countᵢ / total
passes = H ≥ threshold (default 2.5 bits/char)
```

**Properties verified**: H in [0, log₂(n)], no NaN for empty input.

### 7. DecisionReverb (Sources/OneWeave/DecisionLog.swift:460-527)

**Formula** (DENOMINATORS — caught a bug here):
```
firstWeekDailyRate = firstWeek / 7.0
day30DailyRate     = day30 / 23.0     ← NOT /30 (days 8-30 = 23 day span)
day90DailyRate     = day90 / 60.0     ← (days 31-90 = 60 day span)
day365DailyRate    = day365 / 275.0   ← (days 91-365 = 275 day span)
settledThreshold   = firstWeekDailyRate × 0.5
halfLife = first bucket where rate < threshold
         (30, 90, 365, or None if all rates above threshold)
```

**🐛 Bug caught**: My initial Python oracle used `/30.0` for the day-30 rate.
The source uses `/23.0` because the day-30 bucket covers days 8-30 (23 days, not 30).
**Impact**: First-week rate of 1.0 with day-30 returns of 12:
  - Wrong formula: 12/30 = 0.40, threshold 0.5 → "settled at 30" (incorrect)
  - Correct formula: 12/23 = 0.522, threshold 0.5 → "still open" (correct)
This would have under-reported "still open" decisions to users.

**Fix applied**: Oracle now matches Swift exactly.

### 8. MasteryKnots (Sources/OneWeave/MasteryKnot.swift — added cycle 35)

Tier advancement gated by remaining user "knots" (unresolved questions).
For tier T, user needs (T-1) knots cleared to advance. Verified.

---

## ALGORITHMS SIMPLIFIED vs DOCUMENTATION (functional but minimal)

### 9. LifeGraph.buildCoherenceScore (Sources/OneWeave/LifeGraph.swift:155-159)

**Implementation**:
```swift
total = Σ entity.coherenceScoreContribution()
return (total / entities.count).clamped(to: 0...1)
```

**Documentation claim** (GAMIFICATION_SPEC.md): "Live % balance across 4 domains
(low variance = high score)".

**Discrepancy**: Implementation is a simple mean across ALL entities (not domains),
and uses 4 weighted components per entity (harmony, essence, connections, recency).
The 4-domain harmony is approximated through `masteryTiers` which IS keyed by domain.

**Verdict**: Functional but documentation oversells. Recommend clarifying that
"coherence" = graph-level mean weighted by 4 components.

### 10. calculateResonance (Sources/OneWeave/LifeGraph.swift:162-169)

**Implementation**: `0.6 × self.harmonyImpact + 0.4 × mean(neighbor.harmonyImpact)`

Trivial weighted average. Verified but could be richer (e.g., variance-based).

---

## ❌ CRITICAL: "Algorithms" that are NOT real algorithms

### 11. harmonyScore (Sources/OneWeave/LifeContext.swift:47, mutated throughout)

**Current implementation** — searched all `.swift` files:
```swift
// DataSeeder.swift:19
ctx.harmonyScore = 0.65

// LifeContext.swift (excerpts of 14 mutation sites)
harmonyScore = min(1.0, harmonyScore + 0.1)              // line 126
harmonyScore = max(0.5, harmonyScore - 0.01)             // line 329
harmonyScore = min(1.0, harmonyScore + 0.05)             // line 431
harmonyScore = min(1.0, 0.4 + (coverage * 0.15))         // line 439
harmonyScore = min(1.0, harmonyScore + 0.1)              // line 551 (focus boost)
harmonyScore = min(1.0, harmonyScore + 0.08)             // line 556
// ... 8 more sites
```

**Problem**: This is an incremental counter, not a formula. Users see it as a
percentage ("Harmony 78%") but the value depends on the *order of events*,
not the *actual state* of their data. Two users with identical journal content
but different event sequences would get different harmony scores.

**Risk**: Misleading users → credibility loss → liability (privacy docs
promise accurate reflection; this is not reflective).

**Recommended fix** (Linux-fixable, algorithm-only): Replace with
deterministic function of state:

```swift
// PROPOSED harmonyScore:
// H = Σᵢ (wᵢ × vᵢ) where:
//   w_domains_active   = 0.25  (fraction of 4 domains with active threads)
//   w_reflections_30d  = 0.25  (count of reflections last 30 days, normalized)
//   w_quest_velocity   = 0.20  (completion rate vs spawn rate)
//   w_relationships    = 0.20  (mean vitality across active relationships)
//   w_breath_pace      = 0.10  (reflection cadence consistency)
// All normalized to [0,1] before weighting.
```

This is a **MEDIUM PRIORITY FIX** — should land before App Store submission.

### 12. masteryTiers (Sources/OneWeave/LifeContext.swift:46)

Same pattern: tier numbers incremented/decremented by hardcoded `masteryGain`
values. A real algorithm would compute tier from cumulative quality metrics
(consistency, depth, impact), not event-order counters.

**Recommended fix**: Compute tier as:
```
tier_d = f(consistency_d, depth_d, mastery_score_d, knots_cleared_d)
where f is monotonically increasing in all inputs
```

---

## EDGE CASES VERIFIED

All algorithms tested with these stress cases:
- Zero inputs (no events, no reflections, no relations)
- Pathological max values (1000 days, 100 events, 1M connections)
- Negative inputs (e.g., depth = -100, breadth = 0)
- Boundary precision (acos drift, FP rounding)
- Empty collections
- Mixed valid/invalid optional inputs

**Results**: Zero NaN, zero Inf, zero out-of-range outputs across 80,000+ random
test cases. All divisions guarded (target_sleep=0, hrv_baseline=0, breadth=0).

---

## MISSING ALGORITHMS (claimed in docs but not implemented)

None found — all algorithm claims in CLAUDE_COWORK_BRIEF.md, GAMIFICATION_SPEC.md,
and PR.md have implementations. The only gap is the `harmonyScore` /
`masteryTiers` oversimplification above.

---

## NEXT STEPS (Linux-fixable)

1. **Replace `harmonyScore` with formula** (recommended above) — 4-6 hours
2. **Add `coherence` test oracle** for `LifeGraph.buildCoherenceScore` — 1 hour
3. **Add `coherence` test oracle** for `calculateResonance` — 30 min
4. **Document formula in LIFE_CONTEXT.md** so user-facing numbers have citations
5. **Add regression tests** that prevent the `/30` vs `/23` denominator bug

---

## FILES

- `audit/algorithm_oracle.py` (33 KB) — Pure-Python oracle with 43 unit tests
- `audit/algorithm_fuzz.py` (12 KB) — Property-based fuzzing, 9 invariants × 10K
- `audit/verify_against_source.py` (7 KB) — Source-level extraction & cross-check
- `audit/algorithm_inventory.json` (26 KB) — Full function/loc inventory across 61 files
- `.research/validate_audit_*.py` — Harness wrappers (counted in validate_all.sh)

Run all three with:
```bash
cd /root/hermes-workspace/projects/oneweave
python3 audit/algorithm_oracle.py    # 43 tests
python3 audit/algorithm_fuzz.py      # 90K+ random cases
python3 audit/verify_against_source.py  # 29 source extractions
bash    .research/validate_all.sh    # all 36 suites green
```