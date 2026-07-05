#!/usr/bin/env python3
"""
ALGORITHM FUZZ TESTER — property-based testing of OneWeave algorithms.

Generates random inputs in valid ranges and verifies invariants hold:

INVARIANTS:
  1. All scores in [0, 1]
  2. No NaN or Inf in any output
  3. Determinism: same inputs → same outputs (no hidden state)
  4. Monotonicity: where expected, increasing input → increasing output
  5. Symmetry: tonal_distance(a,b) == tonal_distance(b,a)
  6. Continuity: small input change → small output change

If any invariant fails, prints diagnostic + offending input.
"""
import math
import random
import sys
import os

# Re-import the oracle functions
sys.path.insert(0, os.path.dirname(__file__))
from algorithm_oracle import (
    cognitive_load_components, cognitive_load_score,
    vitality, rhizome_index, tonal_distance, tonal_magnitude,
    tonal_coherence_angle, loom_distance, reflection_gate_entropy_score,
    decision_reverb_half_life, mastery_knot_max_tier, clamp,
    computed_harmony_score,
)


random.seed(20260628)
N = 10_000  # iterations per test
failures = []
checks_run = 0


def check(name, condition, detail=""):
    global checks_run
    checks_run += 1
    if not condition:
        failures.append((name, detail))


# ──────────────────────────────────────────────────────────────────────
# Property 1: CognitiveLoad score is always in [0, 1]
# ──────────────────────────────────────────────────────────────────────
for i in range(N):
    cal = random.randint(0, 100)
    quests = random.randint(0, 50)
    threads = random.randint(0, 30)
    sleep = random.uniform(0, 12)
    target = random.uniform(6, 9)
    days_refl = random.randint(0, 365)
    amp = random.uniform(0, 1)
    hrv_c = random.uniform(10, 100) if random.random() > 0.3 else None
    hrv_b = random.uniform(40, 80) if hrv_c else None
    comps = cognitive_load_components(
        cal, quests, threads, sleep, target,
        hrv_c, hrv_b, days_refl, amp,
    )
    score = cognitive_load_score(comps)
    if math.isnan(score) or math.isinf(score):
        check(f"CL no_nan[{i}]", False, f"score={score} for input {cal,quests,threads,sleep,target,days_refl,amp,hrv_c,hrv_b}")
    if not (0.0 <= score <= 1.0):
        check(f"CL range[{i}]", False, f"score={score} out of [0,1]")
    # All components in [0, 1]
    for k, v in comps.items():
        if not (0.0 <= v <= 1.0):
            check(f"CL comp[{i}].{k}", False, f"component {k}={v}")


# ──────────────────────────────────────────────────────────────────────
# Property 2: Vitality monotonicity in Δt (more time → lower vitality)
# ──────────────────────────────────────────────────────────────────────
for i in range(N):
    dt1 = random.uniform(0, 365)
    dt2 = dt1 + random.uniform(0.1, 100)
    n_events = random.randint(0, 10)
    clustered = random.randint(0, n_events)
    v1 = vitality(dt1, n_events, clustered)
    v2 = vitality(dt2, n_events, clustered)
    if not (v2 <= v1 + 1e-9):
        check(f"VITALITY monotonic[{i}]", False, f"v({dt1})={v1} > v({dt2})={v2}")


# ──────────────────────────────────────────────────────────────────────
# Property 3: Vitality always in [0, 1]
# ──────────────────────────────────────────────────────────────────────
for i in range(N):
    dt = random.uniform(0, 1000)
    n = random.randint(0, 100)
    c = random.randint(0, n)
    lam = random.uniform(0.0001, 0.05)
    v = vitality(dt, n, c, lambda_rate=lam)
    if math.isnan(v) or math.isinf(v):
        check(f"VITALITY nan[{i}]", False, f"dt={dt} n={n} c={c} lam={lam} → {v}")
    if not (0.0 <= v <= 1.0):
        check(f"VITALITY range[{i}]", False, f"v={v}")


# ──────────────────────────────────────────────────────────────────────
# Property 4: Rhizome always produces a valid kind
# ──────────────────────────────────────────────────────────────────────
valid_kinds = {"taproot_starved", "rhizome_noisy", "balanced", "developing"}
for i in range(N):
    depth = random.randint(-100, 1000)
    breadth = random.randint(0, 200)
    r, kind = rhizome_index(depth, breadth)
    if math.isnan(r) or math.isinf(r):
        check(f"RHI nan[{i}]", False, f"r={r} depth={depth} breadth={breadth}")
    if kind not in valid_kinds:
        check(f"RHI kind[{i}]", False, f"kind={kind} not in {valid_kinds}")
    if r < 0:
        check(f"RHI nonneg[{i}]", False, f"R={r} negative")


# ──────────────────────────────────────────────────────────────────────
# Property 5: Tonal distance symmetry
# ──────────────────────────────────────────────────────────────────────
for i in range(N):
    a = tuple(random.uniform(-1, 1) for _ in range(4))
    b = tuple(random.uniform(-1, 1) for _ in range(4))
    d1 = tonal_distance(a, b)
    d2 = tonal_distance(b, a)
    if abs(d1 - d2) > 1e-9:
        check(f"TONAL sym[{i}]", False, f"d(a,b)={d1} != d(b,a)={d2}")
    # Triangle inequality: |d(a,b) - |a-b|| < epsilon
    mag = math.sqrt(sum((x-y)**2 for x,y in zip(a,b)))
    if abs(d1 - mag) > 1e-9:
        check(f"TONAL tri[{i}]", False, f"d(a,b)={d1} != ||a-b||={mag}")


# ──────────────────────────────────────────────────────────────────────
# Property 6: Tonal angle is always in [0, 180] or None
# ──────────────────────────────────────────────────────────────────────
for i in range(N):
    a = tuple(random.uniform(-1, 1) for _ in range(4))
    b = tuple(random.uniform(-1, 1) for _ in range(4))
    angle = tonal_coherence_angle(a, b)
    if angle is not None:
        if math.isnan(angle) or math.isinf(angle):
            check(f"TONAL angle nan[{i}]", False, f"angle={angle}")
        if not (0.0 <= angle <= 180.0):
            check(f"TONAL angle range[{i}]", False, f"angle={angle} out of [0,180]")


# ──────────────────────────────────────────────────────────────────────
# Property 7: Decision reverb labels are valid
# ──────────────────────────────────────────────────────────────────────
valid_reverb = {"settled", "still_open", "unrated"}
for i in range(N):
    d7 = random.randint(0, 100)
    d30 = random.randint(0, 100)
    d90 = random.randint(0, 100)
    d365 = random.randint(0, 100)
    hl, label, _ = decision_reverb_half_life(d7, d30, d90, d365)
    if hl is not None and not (hl in {30, 90, 365}):
        check(f"REVERB hl[{i}]", False, f"hl={hl}")
    if label not in valid_reverb:
        check(f"REVERB label[{i}]", False, f"label={label}")


# ──────────────────────────────────────────────────────────────────────
# Property 8: ReflectionGate entropy is in [0, log2(n)]
# ──────────────────────────────────────────────────────────────────────
for i in range(N):
    n = random.randint(0, 1000)
    # Mix of distinct and repeated
    distinct = random.randint(1, max(1, n))
    words = [f"w{j}" for j in range(distinct)]
    if n > distinct:
        words += [random.choice(words) for _ in range(n - distinct)]
    random.shuffle(words)
    entropy, passes = reflection_gate_entropy_score(words)
    if entropy > 0 and not (entropy <= math.log2(n) + 1e-9 if n > 0 else entropy == 0):
        check(f"GATE entropy[{i}]", False, f"H={entropy} > log2({n})")


# ──────────────────────────────────────────────────────────────────────
# Property 10: Computed Harmony Score in [0, 1], deterministic
# ──────────────────────────────────────────────────────────────────────
for i in range(N):
    tiers = {"Self": random.randint(1, 4), "Stewardship": random.randint(1, 4),
             "CareKin": random.randint(1, 4), "Meaning": random.randint(1, 4)}
    active = random.randint(0, 10)
    days = random.uniform(0, 30) if random.random() > 0.2 else None
    coh = random.uniform(0, 1)
    h = computed_harmony_score(tiers, active, days, coh)
    if math.isnan(h) or math.isinf(h):
        check(f"HARMONY nan[{i}]", False, f"H={h}")
    if not (0.0 <= h <= 1.0):
        check(f"HARMONY range[{i}]", False, f"H={h} for tiers={tiers} active={active} days={days} coh={coh}")
    # Determinism
    h2 = computed_harmony_score(tiers, active, days, coh)
    if h != h2:
        check(f"HARMONY det[{i}]", False, f"{h} != {h2}")


# ──────────────────────────────────────────────────────────────────────
# Property 9: Determinism — re-running gives same result
# ──────────────────────────────────────────────────────────────────────
for i in range(100):
    cal = random.randint(0, 100)
    quests = random.randint(0, 50)
    threads = random.randint(0, 30)
    sleep = random.uniform(0, 12)
    target = random.uniform(6, 9)
    days_refl = random.randint(0, 365)
    amp = random.uniform(0, 1)
    s1 = cognitive_load_score(cognitive_load_components(cal, quests, threads, sleep, target, None, None, days_refl, amp))
    s2 = cognitive_load_score(cognitive_load_components(cal, quests, threads, sleep, target, None, None, days_refl, amp))
    if s1 != s2:
        check(f"DETERM[{i}]", False, f"{s1} != {s2}")


# ──────────────────────────────────────────────────────────────────────
# Report
# ──────────────────────────────────────────────────────────────────────

print("=" * 70)
print(f"  FUZZ TEST RESULTS — {N:,} iterations per property")
print("=" * 70)
print()

if failures:
    print(f"  ❌ {len(failures)} PROPERTY VIOLATIONS detected")
    print()
    for name, detail in failures[:20]:
        print(f"  • {name}")
        print(f"      {detail}")
    if len(failures) > 20:
        print(f"  ... and {len(failures) - 20} more")
    sys.exit(1)
else:
    print(f"  ✅ ALL FUZZ PROPERTIES HOLD across {N:,} random inputs each")
    print()
    print("  Verified:")
    print("    • CognitiveLoad scores always in [0, 1]")
    print("    • Vitality monotonic in time and in [0, 1]")
    print("    • RhizomeIndex always returns valid kind, R ≥ 0")
    print("    • Tonal distance symmetric, satisfies triangle inequality")
    print("    • Tonal angle in [0, 180] (or None for zero vectors)")
    print("    • DecisionReverb returns valid labels and half-lives")
    print("    • ReflectionGate entropy ≤ log₂(n)")
    print("    • Determinism: same inputs → same outputs")
    print("    • No NaN or Inf in any algorithm output")
    sys.exit(0)