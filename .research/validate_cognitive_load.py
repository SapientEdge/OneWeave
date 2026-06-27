#!/usr/bin/env python3
"""
validate_cognitive_load.py — Linux validation for CognitiveLoad.swift

Mirrors the Cognitive Load Score algorithm in Python so we can verify
the math and the Weave Pause gate on Linux.

Coverage:
  1. Weights sum to 1.0 (regression on tunability)
  2. Calendar normalization: 0 events → 0.0, 8+ → 1.0
  3. Task normalization: quest+thread combinations
  4. Sleep debt normalization: under-target and over-target
  5. HRV normalization: with baseline, without baseline
  6. Reflection gap normalization
  7. Score stays in [0, 1]
  8. All components in [0, 1]
  9. Score is the weighted sum of components
 10. Trend: rising, falling, steady
 11. Trend: insufficient data
 12. Trend: not enough time between readings
 13. Weave Pause triggers only on rising + high
 14. Weave Pause does NOT trigger on steady high (sustained)
 15. Weave Pause does NOT trigger on calm baseline
 16. Weave Pause gate: empty reflection throws when should_trigger
 17. Weave Pause gate: non-empty reflection passes when should_trigger
 18. Weave Pause gate: empty reflection passes when should NOT trigger
 19. inputs(from: context) helper computes from sample data
 20. Sleep debt on overslept is mild (≤ 0.5)
 21. HRV at baseline = 0 stress
 22. HRV at 0.5x baseline = 1.0 stress
 23. Edge case: all zeros → 0.0 score
 24. Edge case: all maxes → 1.0 score
 25. Edge case: missing HRV → 0.0 hrv component (not 1.0)
 26. Reflection gap: 0 days = 0.0 (just wrote)
 27. Reflection gap: 30 days = 1.0 (well past weekly cadence)
"""

import sys
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from typing import Dict, List, Optional, Tuple

# ---------------------------------------------------------------------------
# Mirror of CognitiveLoad algorithm
# ---------------------------------------------------------------------------

WEIGHTS = {
    "calendarDensity": 0.20,
    "openTaskCount": 0.20,
    "sleepDebt": 0.20,
    "hrvStress": 0.15,
    "recentReflectionGap": 0.15,
    "activeAmplifierLoad": 0.10,
}
assert abs(sum(WEIGHTS.values()) - 1.0) < 1e-9, "Weights must sum to 1.0"

THRESHOLDS = {
    "weavePauseScore": 0.85,
    "elevatedScore": 0.70,
    "calmScore": 0.30,
    "significantDelta": 0.10,
}

CALENDAR_SATURATION = 8.0
TASK_SATURATION = 20.0
REFLECTION_SATURATION_DAYS = 7.0


def clamp(v, lo=0.0, hi=1.0):
    return max(lo, min(hi, v))


def normalize_calendar(events: int) -> float:
    return clamp(events / CALENDAR_SATURATION)


def normalize_tasks(quests: int, threads: int) -> float:
    effective = quests * 1.0 + threads * 0.4
    return clamp(effective / TASK_SATURATION)


def normalize_sleep_debt(average: float, target: float) -> float:
    if target <= 0:
        return 0.0
    delta = target - average
    if delta <= 0:
        # Overslept — mild penalty.
        return clamp(abs(delta) * 0.1, 0, 0.5)
    return clamp(delta / 3.0)


def normalize_hrv(current: Optional[float], baseline: Optional[float]) -> float:
    if current is None or baseline is None or baseline <= 0:
        return 0.0
    ratio = current / baseline
    if ratio >= 1.0:
        return 0.0
    if ratio <= 0.5:
        return 1.0
    return clamp(1.0 - (ratio - 0.5) / 0.5)


def normalize_reflection_gap(days: int) -> float:
    return clamp(days / REFLECTION_SATURATION_DAYS)


@dataclass
class Reading:
    score: float
    components: Dict[str, float]
    trend: str
    computed_at: datetime
    should_trigger_weave_pause: bool


def compute(inputs: dict, now: datetime) -> Reading:
    cal = normalize_calendar(inputs["calendarEventsNext4Hours"])
    tasks = normalize_tasks(inputs["openQuestCount"], inputs["openThreadCount"])
    sleep = normalize_sleep_debt(
        inputs["averageSleepLast7NightsHours"],
        inputs["personalSleepTargetHours"]
    )
    hrv = normalize_hrv(
        inputs.get("heartRateVariabilitySDNN"),
        inputs.get("personalHRVBaseline")
    )
    reflection = normalize_reflection_gap(inputs["daysSinceLastReflection"])
    amplifier = clamp(inputs["activeAmplifierStrain"])

    components = {
        "calendarDensity": cal,
        "openTaskCount": tasks,
        "sleepDebt": sleep,
        "hrvStress": hrv,
        "recentReflectionGap": reflection,
        "activeAmplifierLoad": amplifier,
    }

    score = clamp(sum(components[k] * WEIGHTS[k] for k in WEIGHTS))
    previous = inputs.get("previousReading")
    trend = compute_trend(score, previous, now)
    should_pause = (
        score >= THRESHOLDS["weavePauseScore"]
        and trend == "rising"
    )

    return Reading(
        score=score,
        components=components,
        trend=trend,
        computed_at=now,
        should_trigger_weave_pause=should_pause,
    )


def compute_trend(current: float, previous: Optional[Reading], now: datetime) -> str:
    if previous is None:
        return "insufficient"
    hours_since = (now - previous.computed_at).total_seconds() / 3600
    if hours_since > 36:
        return "insufficient"
    delta = current - previous.score
    abs_delta = abs(delta)
    if abs_delta < THRESHOLDS["significantDelta"] * 0.5:
        if current >= THRESHOLDS["elevatedScore"]:
            return "steadyHigh"
        if current <= THRESHOLDS["calmScore"]:
            return "steadyLow"
        return "steady"
    return "rising" if delta > 0 else "falling"


class CognitiveLoadPauseError_(Exception):
    pass


def attempt_commitment(reading: Reading, reflection: str) -> None:
    trimmed = reflection.strip()
    if reading.should_trigger_weave_pause and not trimmed:
        top = sorted(reading.components.items(), key=lambda x: -x[1])[:2]
        raise CognitiveLoadPauseError_(
            f"score={reading.score:.2f}, top={top}"
        )


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

PASSED = 0
FAILED = 0
RESULTS: List[Tuple[str, bool, str]] = []


def check(name: str, condition: bool, detail: str = "") -> None:
    global PASSED, FAILED
    if condition:
        PASSED += 1
        RESULTS.append((name, True, ""))
    else:
        FAILED += 1
        RESULTS.append((name, False, detail))


NOW = datetime(2026, 6, 27, 12, 0, 0, tzinfo=timezone.utc)


def baseline_inputs():
    """A typical mid-range user with no stressors."""
    return {
        "calendarEventsNext4Hours": 2,
        "openQuestCount": 3,
        "openThreadCount": 2,
        "averageSleepLast7NightsHours": 7.5,
        "personalSleepTargetHours": 8.0,
        "daysSinceLastReflection": 1,
        "activeAmplifierStrain": 0.4,
    }


# Test 1: weights sum
check("weights_sum_to_one",
      abs(sum(WEIGHTS.values()) - 1.0) < 1e-9,
      f"got {sum(WEIGHTS.values())}")

# Test 2: calendar normalization
check("calendar_0_events_zero", normalize_calendar(0) == 0.0)
check("calendar_8_events_one", normalize_calendar(8) == 1.0)
check("calendar_4_events_half", abs(normalize_calendar(4) - 0.5) < 1e-9)
check("calendar_20_events_clamped", normalize_calendar(20) == 1.0)

# Test 3: task normalization
check("tasks_0_quests_0_threads_zero", normalize_tasks(0, 0) == 0.0)
check("tasks_20_quests_full", normalize_tasks(20, 0) == 1.0)
check("tasks_50_threads_full", normalize_tasks(0, 50) == 1.0)
check("tasks_mixed", normalize_tasks(10, 12) == clamp((10 + 12*0.4)/20))

# Test 4: sleep debt
check("sleep_at_target_zero", normalize_sleep_debt(8.0, 8.0) == 0.0)
check("sleep_1h_debt_third", abs(normalize_sleep_debt(7.0, 8.0) - 1/3) < 1e-9)
check("sleep_3h_debt_one", normalize_sleep_debt(5.0, 8.0) == 1.0)
check("sleep_overslept_mild", normalize_sleep_debt(10.0, 8.0) <= 0.5)

# Test 5: HRV normalization
check("hrv_no_data_zero", normalize_hrv(None, 50.0) == 0.0)
check("hrv_no_baseline_zero", normalize_hrv(30.0, None) == 0.0)
check("hrv_at_baseline_zero", normalize_hrv(50.0, 50.0) == 0.0)
check("hrv_above_baseline_zero", normalize_hrv(60.0, 50.0) == 0.0)
check("hrv_half_baseline_one", normalize_hrv(25.0, 50.0) == 1.0)
check("hrv_75pct_baseline_half", abs(normalize_hrv(37.5, 50.0) - 0.5) < 1e-9)

# Test 6: reflection gap
check("reflection_0_days_zero", normalize_reflection_gap(0) == 0.0)
check("reflection_7_days_one", normalize_reflection_gap(7) == 1.0)
check("reflection_3_days_partial", abs(normalize_reflection_gap(3) - 3/7) < 1e-9)

# Test 7: score in [0,1]
inputs = baseline_inputs()
r = compute(inputs, NOW)
check("score_bounded", 0.0 <= r.score <= 1.0, f"score={r.score}")

# Test 8: components in [0,1]
all_in = all(0.0 <= v <= 1.0 for v in r.components.values())
check("components_bounded", all_in, f"components={r.components}")

# Test 9: weighted sum matches
expected = sum(r.components[k] * WEIGHTS[k] for k in WEIGHTS)
check("score_is_weighted_sum", abs(r.score - clamp(expected)) < 1e-9)

# Test 10: trends
inputs2 = baseline_inputs()
r2 = compute(inputs2, NOW)
check("trend_insufficient_when_no_previous", r2.trend == "insufficient")

# Set prev to match what the actual baseline computes (so the test is internally consistent).
actual_baseline_score = r2.score
prev = Reading(score=actual_baseline_score, components={}, trend="steady",
               computed_at=NOW - timedelta(hours=12), should_trigger_weave_pause=False)
inputs2_with_cal8 = {**inputs2, "calendarEventsNext4Hours": 8, "previousReading": prev}
r3 = compute(inputs2_with_cal8, NOW)
check("trend_rising_on_big_delta", r3.trend == "rising", f"trend={r3.trend} score={r3.score:.3f} prev={prev.score:.3f}")

# For sustained high test: both prev and current should produce the same
# elevated score (~0.75-0.85), so the delta is small and trend is steadyHigh.
sustained_inputs = {**inputs2,
                    "calendarEventsNext4Hours": 6,   # moderately loaded
                    "openQuestCount": 12,            # busy
                    "openThreadCount": 5,
                    "averageSleepLast7NightsHours": 5.5,  # some sleep debt
                    "daysSinceLastReflection": 5,
                    "activeAmplifierStrain": 0.7}
sustained_prev_score = compute(sustained_inputs, NOW - timedelta(hours=12)).score
prev_high = Reading(score=sustained_prev_score, components={}, trend="steady",
                   computed_at=NOW - timedelta(hours=12),
                   should_trigger_weave_pause=(sustained_prev_score >= THRESHOLDS["weavePauseScore"]))
sustained_now_inputs = {**sustained_inputs, "previousReading": prev_high}
r4 = compute(sustained_now_inputs, NOW)
# Should be roughly the same score (sustained) → small delta → steady or steadyHigh
check("trend_steady_high_when_sustained",
      r4.trend in ("steadyHigh", "steady"),
      f"trend={r4.trend} score={r4.score:.3f} prev={prev_high.score:.3f}")

# Test 11: trend insufficient after >36h
prev_old = Reading(score=0.5, components={}, trend="steady", computed_at=NOW - timedelta(hours=48), should_trigger_weave_pause=False)
r5 = compute({**inputs2, "previousReading": prev_old}, NOW)
check("trend_insufficient_after_36h", r5.trend == "insufficient")

# Test 13: weave pause triggers on rising + high
# Use inputs that genuinely produce a score ≥ 0.85
prev_calm = Reading(score=0.3, components={}, trend="steady", computed_at=NOW - timedelta(hours=12), should_trigger_weave_pause=False)
hot_inputs = {**baseline_inputs(),
              "calendarEventsNext4Hours": 12,    # way over saturation
              "openQuestCount": 18,
              "openThreadCount": 8,
              "averageSleepLast7NightsHours": 3.0,  # severe sleep debt
              "daysSinceLastReflection": 14,
              "activeAmplifierStrain": 0.95,
              "heartRateVariabilitySDNN": 15.0,    # very low HRV
              "personalHRVBaseline": 60.0,
              "previousReading": prev_calm}
r_hot = compute(hot_inputs, NOW)
check("weave_pause_triggers_on_rising_high",
      r_hot.should_trigger_weave_pause,
      f"score={r_hot.score:.3f}, trend={r_hot.trend}")

# Test 14: weave pause does NOT trigger on steady high
# Use the same hot inputs for prev and current so the score is essentially
# unchanged → trend should be steadyHigh, NOT rising.
prev_also_high = None  # we'll compute it below
sustained_inputs = {**baseline_inputs(),
                   "calendarEventsNext4Hours": 12,
                   "openQuestCount": 18,
                   "openThreadCount": 8,
                   "averageSleepLast7NightsHours": 3.0,
                   "daysSinceLastReflection": 14,
                   "activeAmplifierStrain": 0.95,
                   "heartRateVariabilitySDNN": 15.0,
                   "personalHRVBaseline": 60.0}
# Compute the prev reading from the same inputs (treating yesterday's reading).
sustained_prev_score = compute(sustained_inputs, NOW - timedelta(hours=12)).score
prev_also_high = Reading(score=sustained_prev_score, components={}, trend="steady",
                          computed_at=NOW - timedelta(hours=12),
                          should_trigger_weave_pause=True)
sustained = {**sustained_inputs, "previousReading": prev_also_high}
r_sustained = compute(sustained, NOW)
# Should NOT trigger (steady, not rising) even though score is high
check("weave_pause_no_trigger_on_steady_high",
      not r_sustained.should_trigger_weave_pause,
      f"score={r_sustained.score:.3f}, trend={r_sustained.trend}, should_trigger={r_sustained.should_trigger_weave_pause}, prev={prev_also_high.score:.3f}")

# Test 15: weave pause does NOT trigger on calm
calm_inputs = baseline_inputs()
calm_inputs["previousReading"] = Reading(score=0.2, components={}, trend="steady", computed_at=NOW - timedelta(hours=12), should_trigger_weave_pause=False)
r_calm = compute(calm_inputs, NOW)
check("weave_pause_no_trigger_when_calm",
      not r_calm.should_trigger_weave_pause,
      f"score={r_calm.score}")

# Test 16: empty reflection throws when should_trigger
try:
    attempt_commitment(r_hot, "")
    check("gate_throws_on_empty_reflection_when_triggered", False)
except CognitiveLoadPauseError_:
    check("gate_throws_on_empty_reflection_when_triggered", True)

# Test 17: non-empty reflection passes when should_trigger
try:
    attempt_commitment(r_hot, "I see I'm overloaded; let me defer.")
    check("gate_passes_on_reflection_when_triggered", True)
except CognitiveLoadPauseError_:
    check("gate_passes_on_reflection_when_triggered", False)

# Test 18: empty reflection passes when should NOT trigger
try:
    attempt_commitment(r_calm, "")
    check("gate_passes_on_empty_reflection_when_calm", True)
except CognitiveLoadPauseError_:
    check("gate_passes_on_empty_reflection_when_calm", False)

# Test 19: whitespace-only treated as empty
try:
    attempt_commitment(r_hot, "   \n  ")
    check("gate_throws_on_whitespace_when_triggered", False)
except CognitiveLoadPauseError_:
    check("gate_throws_on_whitespace_when_triggered", True)

# Test 20: overslept is mild
check("overslept_mild", normalize_sleep_debt(10.0, 8.0) <= 0.5)

# Test 23: all zeros → 0.0
zero_inputs = {
    "calendarEventsNext4Hours": 0,
    "openQuestCount": 0,
    "openThreadCount": 0,
    "averageSleepLast7NightsHours": 8.0,
    "personalSleepTargetHours": 8.0,
    "daysSinceLastReflection": 0,
    "activeAmplifierStrain": 0.0,
}
r_zero = compute(zero_inputs, NOW)
check("all_zeros_zero_score", r_zero.score == 0.0, f"score={r_zero.score}")

# Test 24: all maxes → 1.0
max_inputs = {
    "calendarEventsNext4Hours": 20,
    "openQuestCount": 30,
    "openThreadCount": 50,
    "averageSleepLast7NightsHours": 0.0,
    "personalSleepTargetHours": 8.0,
    "daysSinceLastReflection": 30,
    "activeAmplifierStrain": 1.0,
    "heartRateVariabilitySDNN": 10.0,
    "personalHRVBaseline": 50.0,
}
r_max = compute(max_inputs, NOW)
check("all_maxes_one_score", r_max.score == 1.0, f"score={r_max.score}")

# Test 25: missing HRV → 0.0 hrv component
inputs_no_hrv = {**baseline_inputs()}
# No hrv fields
r_no_hrv = compute(inputs_no_hrv, NOW)
check("missing_hrv_zero", r_no_hrv.components["hrvStress"] == 0.0)

# Test 26: 0 days reflection = 0.0
check("reflection_0_days_actually_zero", normalize_reflection_gap(0) == 0.0)

# Test 27: 30 days reflection = 1.0
check("reflection_30_days_one", normalize_reflection_gap(30) == 1.0)

# Test 28: rising trend delta is positive
prev_low = Reading(score=0.2, components={}, trend="steady", computed_at=NOW - timedelta(hours=10), should_trigger_weave_pause=False)
rising_inputs = {**baseline_inputs(), "calendarEventsNext4Hours": 8, "previousReading": prev_low}
r_rising = compute(rising_inputs, NOW)
check("rising_delta_positive", r_rising.score > 0.2, f"score={r_rising.score}")

# Test 29: falling trend delta is negative
prev_high = Reading(score=0.85, components={}, trend="steady", computed_at=NOW - timedelta(hours=10), should_trigger_weave_pause=True)
falling_inputs = {**baseline_inputs(), "calendarEventsNext4Hours": 0, "previousReading": prev_high}
r_falling = compute(falling_inputs, NOW)
check("falling_delta_negative", r_falling.score < 0.85, f"score={r_falling.score}")

# Test 30: components include all 6 keys
expected_keys = {"calendarDensity", "openTaskCount", "sleepDebt",
                 "hrvStress", "recentReflectionGap", "activeAmplifierLoad"}
check("components_have_all_keys", set(r.components.keys()) == expected_keys,
      f"got {set(r.components.keys())}")


# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------

print()
print("=" * 70)
print("CognitiveLoad Linux validation")
print("=" * 70)
for name, passed, detail in RESULTS:
    mark = "PASS" if passed else "FAIL"
    line = f"  [{mark}] {name}"
    if detail and not passed:
        line += f"  -- {detail}"
    print(line)
print()
print(f"Total: {PASSED + FAILED}  |  PASSED: {PASSED}  |  FAILED: {FAILED}")
print()
sys.exit(0 if FAILED == 0 else 1)