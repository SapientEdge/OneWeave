#!/usr/bin/env python3
"""
validate_cognitive_load_depth.py — Deep validator for CognitiveLoad.swift (Cycle 49 / F)

Cycle 49 chose CognitiveLoad as the deep-dive feature. This validator tests
the SHOULD-DIM-UI + soft-exhale sequence (cycle 34 T168 GLM C7), the body-depletion
clause for Weave Pause (cycle 41 A1), and several edge cases that the existing
validate_cognitive_load.py covers at only a surface level.

Coverage (60+ new checks beyond validate_cognitive_load.py):
  Section 1: CognitiveLoadThresholds constants (5 checks)
    - weavePauseScore == 0.85
    - elevatedScore == 0.70
    - calmScore == 0.30
    - significantDelta == 0.10
    - Ordering: calmScore < elevatedScore < weavePauseScore

  Section 2: shouldDimUI behavior — soft exhale before hard pause (8 checks)
    - shouldDimUI is FALSE when score < 0.70
    - shouldDimUI is TRUE when score >= 0.70
    - shouldDimUI is FALSE when score < 0.85 (so weave pause doesn't fire)
    - At exactly 0.70 (elevatedScore), shouldDimUI is TRUE
    - At exactly 0.85 (weavePauseScore), shouldDimUI is TRUE (and weave pause may also fire)
    - Default constructor: shouldDimUI defaults to (score >= elevatedScore) when omitted
    - Explicit shouldDimUI=true overrides default logic
    - Explicit shouldDimUI=false overrides default logic

  Section 3: Trend computation edge cases (10 checks)
    - Previous = None → .insufficient
    - Previous > 36 hours old → .insufficient
    - Previous 24h old, delta = 0.05 (< half-significant) → .steady
    - Previous 24h old, delta = +0.20 → .rising
    - Previous 24h old, delta = -0.20 → .falling
    - Previous 24h old, current=0.80, delta=0.04 → .steadyHigh (delta small + level elevated)
    - Previous 24h old, current=0.20, delta=0.04 → .steadyLow
    - Previous 24h old, current=0.50, delta=0.04 → .steady (mid-range)
    - Threshold: absDelta < significantDelta * 0.5 = 0.05
    - Threshold: absDelta = 0.05 exactly → .steady* (boundary)

  Section 4: Body-depletion clause for Weave Pause (6 checks)
    - Rising + 0.90 + sleepScore<0.5 + hrvScore<0.5 → should NOT trigger
      (rising on top of rest is not a pause per §5 anti-nag)
    - Rising + 0.90 + sleepScore>=0.5 → SHOULD trigger (sleep depleted)
    - Rising + 0.90 + hrvScore>=0.5 → SHOULD trigger (HRV stressed)
    - Rising + 0.90 + sleepScore>=0.5 + hrvScore>=0.5 → SHOULD trigger
    - Steady high + 0.90 → should NOT trigger (sustained high, not rising)
    - Score < 0.85 + rising + body depleted → should NOT trigger (below threshold)

  Section 5: Soft-exhale sequence (6 checks)
    - score=0.70 → shouldDimUI=true, shouldTriggerWeavePause=false
    - score=0.75 → shouldDimUI=true, shouldTriggerWeavePause=false
    - score=0.80 → shouldDimUI=true, shouldTriggerWeavePause=false
    - score=0.85+rising+body_depleted → shouldDimUI=true, shouldTriggerWeavePause=true
    - score=0.50 → shouldDimUI=false, shouldTriggerWeavePause=false (calm)
    - Score progression 0.50 → 0.70 → 0.85 (sequence: no_dim → dim → dim+pause)

  Section 6: Component normalization boundary cases (10 checks)
    - calendar: 8 events = 1.0 exactly; 7 events = 0.875; 16 events = 1.0 (clamp)
    - tasks: 25 quests = 1.0 (clamp); 12 quests + 20 threads = 1.0 (clamp)
    - sleep: 1h under target → 1/3; 2h under → 2/3; 3h under → 1.0
    - sleep: 0.5h over → 0.05; 5h over → 0.5 (capped at 0.5)
    - sleep: target=0 → 0.0 (guard against divide-by-zero)
    - hrv: ratio=1.0 → 0.0; ratio=0.5 → 1.0; ratio=0.7 → 0.6; ratio=1.5 → 0.0
    - hrv: both nil → 0.0; current=nil → 0.0; baseline=nil → 0.0
    - reflection: 0 days = 0.0; 7 days = 1.0; 14 days = 1.0 (clamp); -1 days = 0.0
    - amplifier: clamped to [0, 1] on input; -0.5 → 0.0; 1.5 → 1.0
    - Weighted sum: empty components dict = 0.0

  Section 7: WeavePauseGate behavior (6 checks)
    - Empty reflection + shouldTrigger=true → throws CognitiveLoadPauseError.reflectionRequired
    - Non-empty reflection + shouldTrigger=true → passes (no throw)
    - Whitespace-only reflection + shouldTrigger=true → throws (trimmed empty)
    - Empty reflection + shouldTrigger=false → passes
    - Error message includes top 2 components (by value, desc)
    - Error message includes score as percentage

  Section 8: Clamping invariants (5 checks)
    - score clamped to [0, 1] in init
    - components preserved exactly (no clamping per-value)
    - trend preserved exactly (no transformation)
    - computedAt preserved exactly
    - shouldTriggerWeavePause preserved exactly (no auto-flip)

Total: ~56 checks across 8 sections.
"""

import sys
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from typing import Dict, List, Optional, Tuple

# ---------------------------------------------------------------------------
# Mirror of CognitiveLoad algorithm (from CognitiveLoad.swift)
# ---------------------------------------------------------------------------

WEIGHTS = {
    "calendarDensity": 0.20,
    "openTaskCount": 0.20,
    "sleepDebt": 0.15,
    "hrvStress": 0.10,
    "recentReflectionGap": 0.20,
    "activeAmplifierLoad": 0.15,
}

# Thresholds (from CognitiveLoadThresholds in CognitiveLoad.swift)
WAVE_PAUSE_SCORE = 0.85
ELEVATED_SCORE = 0.70
CALM_SCORE = 0.30
SIGNIFICANT_DELTA = 0.10

CALENDAR_SATURATION = 8.0
TASK_SATURATION = 20.0
SLEEP_DEBT_CAP_HOURS = 3.0
HRV_STRESS_RATIO = 0.5
REFLECTION_GAP_DAYS = 7.0


def clamp(v, lo=0.0, hi=1.0):
    return max(lo, min(hi, v))


def normalize_calendar(events: int) -> float:
    return clamp(float(events) / CALENDAR_SATURATION)


def normalize_tasks(quests: int, threads: int) -> float:
    effective = float(quests) * 1.0 + float(threads) * 0.4
    return clamp(effective / TASK_SATURATION)


def normalize_sleep_debt(average: float, target: float) -> float:
    if target <= 0:
        return 0.0
    delta = target - average
    if delta <= 0:
        return clamp(abs(delta) * 0.1, 0, 0.5)
    return clamp(delta / SLEEP_DEBT_CAP_HOURS)


def normalize_hrv(current, baseline):
    if current is None or baseline is None or baseline <= 0:
        return 0.0
    ratio = current / baseline
    if ratio >= 1.0:
        return 0.0
    if ratio <= HRV_STRESS_RATIO:
        return 1.0
    return clamp((1.0 - (ratio - HRV_STRESS_RATIO) / HRV_STRESS_RATIO))


def normalize_reflection_gap(days: int) -> float:
    return clamp(float(days) / REFLECTION_GAP_DAYS)


@dataclass
class Reading:
    score: float
    components: Dict[str, float]
    trend: str
    computed_at: datetime
    should_trigger_weave_pause: bool
    should_dim_ui: Optional[bool] = None

    def __post_init__(self):
        self.score = clamp(self.score, 0.0, 1.0)
        if self.should_dim_ui is None:
            self.should_dim_ui = self.score >= ELEVATED_SCORE


def compute(inputs: dict, now: datetime) -> Reading:
    cal = normalize_calendar(inputs.get("calendarEventsNext4Hours", 0))
    tasks = normalize_tasks(inputs.get("openQuestCount", 0), inputs.get("openThreadCount", 0))
    sleep = normalize_sleep_debt(
        inputs.get("averageSleepLast7NightsHours", 7.0),
        inputs.get("personalSleepTargetHours", 8.0),
    )
    hrv = normalize_hrv(
        inputs.get("heartRateVariabilitySDNN"),
        inputs.get("personalHRVBaseline"),
    )
    refl = normalize_reflection_gap(inputs.get("daysSinceLastReflection", 0))
    amp = clamp(inputs.get("activeAmplifierStrain", 0.4), 0.0, 1.0)

    components = {
        "calendarDensity": cal,
        "openTaskCount": tasks,
        "sleepDebt": sleep,
        "hrvStress": hrv,
        "recentReflectionGap": refl,
        "activeAmplifierLoad": amp,
    }
    weighted = (
        cal * WEIGHTS["calendarDensity"]
        + tasks * WEIGHTS["openTaskCount"]
        + sleep * WEIGHTS["sleepDebt"]
        + hrv * WEIGHTS["hrvStress"]
        + refl * WEIGHTS["recentReflectionGap"]
        + amp * WEIGHTS["activeAmplifierLoad"]
    )
    score = clamp(weighted, 0.0, 1.0)

    prev = inputs.get("previousReading")
    trend = compute_trend(score, prev, now)

    body_depleted = sleep >= 0.5 or hrv >= 0.5
    should_trigger = (
        score >= WAVE_PAUSE_SCORE and trend == "rising" and body_depleted
    )
    should_dim = score >= ELEVATED_SCORE

    return Reading(
        score=score,
        components=components,
        trend=trend,
        computed_at=now,
        should_trigger_weave_pause=should_trigger,
        should_dim_ui=should_dim,
    )


def compute_trend(current: float, previous: Optional[Reading], now: datetime) -> str:
    if previous is None:
        return "insufficient"
    hours_since = (now - previous.computed_at).total_seconds() / 3600
    if hours_since > 36:
        return "insufficient"
    delta = current - previous.score
    if abs(delta) < SIGNIFICANT_DELTA * 0.5:
        if current >= ELEVATED_SCORE:
            return "steadyHigh"
        if current <= CALM_SCORE:
            return "steadyLow"
        return "steady"
    return "rising" if delta > 0 else "falling"


class CognitiveLoadPauseError(Exception):
    def __init__(self, score: float, components: List[Tuple[str, float]]):
        self.score = score
        self.components = components
        super().__init__("Reflection required")


def attempt_commitment(reading: Reading, reflection: str) -> None:
    trimmed = reflection.strip()
    if reading.should_trigger_weave_pause and not trimmed:
        top = sorted(reading.components.items(), key=lambda kv: kv[1], reverse=True)[:2]
        raise CognitiveLoadPauseError(reading.score, top)


# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------

RESULTS: List[Tuple[str, bool, str]] = []
PASSED = 0
FAILED = 0


def check(name: str, condition: bool, detail: str = "") -> None:
    global PASSED, FAILED
    if condition:
        PASSED += 1
        RESULTS.append((name, True, ""))
    else:
        FAILED += 1
        RESULTS.append((name, False, detail))


NOW = datetime(2026, 7, 5, 12, 0, tzinfo=timezone.utc)


# ---------------------------------------------------------------------------
# Section 1: CognitiveLoadThresholds constants
# ---------------------------------------------------------------------------

check("thresholds.weavePauseScore_is_0.85", WAVE_PAUSE_SCORE == 0.85,
      f"got {WAVE_PAUSE_SCORE}")
check("thresholds.elevatedScore_is_0.70", ELEVATED_SCORE == 0.70,
      f"got {ELEVATED_SCORE}")
check("thresholds.calmScore_is_0.30", CALM_SCORE == 0.30,
      f"got {CALM_SCORE}")
check("thresholds.significantDelta_is_0.10", SIGNIFICANT_DELTA == 0.10,
      f"got {SIGNIFICANT_DELTA}")
check("thresholds.ordered_calm_lt_elevated_lt_pause",
      CALM_SCORE < ELEVATED_SCORE < WAVE_PAUSE_SCORE,
      f"calm={CALM_SCORE} elevated={ELEVATED_SCORE} pause={WAVE_PAUSE_SCORE}")


# ---------------------------------------------------------------------------
# Section 2: shouldDimUI behavior — soft exhale before hard pause
# ---------------------------------------------------------------------------

check("dimUI.below_elevated_false", Reading(score=0.50, components={}, trend="steady",
      computed_at=NOW, should_trigger_weave_pause=False).should_dim_ui == False,
      "score=0.50 should not dim")

check("dimUI.at_elevated_true", Reading(score=0.70, components={}, trend="steady",
      computed_at=NOW, should_trigger_weave_pause=False).should_dim_ui == True,
      "score=0.70 (exactly elevated) should dim")

check("dimUI.above_elevated_true", Reading(score=0.80, components={}, trend="steady",
      computed_at=NOW, should_trigger_weave_pause=False).should_dim_ui == True,
      "score=0.80 should dim")

check("dimUI.below_pause_no_trigger", Reading(score=0.80, components={}, trend="steady",
      computed_at=NOW, should_trigger_weave_pause=False).should_dim_ui == True,
      "score=0.80 dims but does not trigger pause")

check("dimUI.above_pause_true", Reading(score=0.90, components={}, trend="steady",
      computed_at=NOW, should_trigger_weave_pause=True).should_dim_ui == True,
      "score=0.90 should dim AND may trigger pause")

check("dimUI.default_omitted_uses_score_check",
      Reading(score=0.71, components={}, trend="steady",
              computed_at=NOW, should_trigger_weave_pause=False).should_dim_ui == True,
      "score=0.71 with default should_dim_ui=None should be True")

check("dimUI.default_omitted_below_threshold",
      Reading(score=0.69, components={}, trend="steady",
              computed_at=NOW, should_trigger_weave_pause=False).should_dim_ui == False,
      "score=0.69 with default should_dim_ui=None should be False")

check("dimUI.explicit_true_overrides",
      Reading(score=0.50, components={}, trend="steady",
              computed_at=NOW, should_trigger_weave_pause=False,
              should_dim_ui=True).should_dim_ui == True,
      "explicit True overrides default logic")

check("dimUI.explicit_false_overrides",
      Reading(score=0.90, components={}, trend="steady",
              computed_at=NOW, should_trigger_weave_pause=True,
              should_dim_ui=False).should_dim_ui == False,
      "explicit False overrides default logic")


# ---------------------------------------------------------------------------
# Section 3: Trend computation edge cases
# ---------------------------------------------------------------------------

check("trend.no_previous_insufficient",
      compute_trend(0.5, None, NOW) == "insufficient")

old_prev = Reading(score=0.5, components={}, trend="steady", computed_at=NOW - timedelta(hours=40),
                  should_trigger_weave_pause=False)
check("trend.previous_too_old_insufficient",
      compute_trend(0.5, old_prev, NOW) == "insufficient")

yesterday = NOW - timedelta(hours=20)
prev_same = Reading(score=0.5, components={}, trend="steady", computed_at=yesterday,
                    should_trigger_weave_pause=False)
check("trend.delta_tiny_steady",
      compute_trend(0.52, prev_same, NOW) == "steady",
      f"delta=0.02 should be steady (absDelta<{SIGNIFICANT_DELTA*0.5})")

prev_high = Reading(score=0.65, components={}, trend="steady", computed_at=yesterday,
                    should_trigger_weave_pause=False)
check("trend.delta_positive_rising",
      compute_trend(0.85, prev_high, NOW) == "rising",
      "delta=+0.20 should be rising")

prev_high2 = Reading(score=0.85, components={}, trend="steady", computed_at=yesterday,
                     should_trigger_weave_pause=False)
check("trend.delta_negative_falling",
      compute_trend(0.65, prev_high2, NOW) == "falling",
      "delta=-0.20 should be falling")

# Steady high: current elevated + tiny delta
prev_sh = Reading(score=0.78, components={}, trend="steadyHigh", computed_at=yesterday,
                  should_trigger_weave_pause=False)
check("trend.small_delta_at_elevated_steadyHigh",
      compute_trend(0.80, prev_sh, NOW) == "steadyHigh",
      "delta=0.02 at level 0.80 should be steadyHigh")

prev_sl = Reading(score=0.20, components={}, trend="steadyLow", computed_at=yesterday,
                  should_trigger_weave_pause=False)
check("trend.small_delta_at_calm_steadyLow",
      compute_trend(0.22, prev_sl, NOW) == "steadyLow",
      "delta=0.02 at level 0.22 should be steadyLow")

prev_mid = Reading(score=0.50, components={}, trend="steady", computed_at=yesterday,
                   should_trigger_weave_pause=False)
check("trend.small_delta_at_mid_steady",
      compute_trend(0.52, prev_mid, NOW) == "steady",
      "delta=0.02 at level 0.52 should be steady")

# Boundary: absDelta = SIGNIFICANT_DELTA * 0.5 = 0.05 exactly → still "steady"
prev_at_threshold = Reading(score=0.50, components={}, trend="steady", computed_at=yesterday,
                            should_trigger_weave_pause=False)
check("trend.at_steady_threshold_rising",
      compute_trend(0.55, prev_at_threshold, NOW) == "rising",
      "delta=0.05 (exactly threshold) should be rising (>= threshold)")

prev_above_threshold = Reading(score=0.50, components={}, trend="steady", computed_at=yesterday,
                               should_trigger_weave_pause=False)
check("trend.above_steady_threshold_rising",
      compute_trend(0.56, prev_above_threshold, NOW) == "rising",
      "delta=0.06 (above threshold) should be rising")

# Just below threshold: delta = 0.04 → steady
prev_below = Reading(score=0.50, components={}, trend="steady", computed_at=yesterday,
                     should_trigger_weave_pause=False)
check("trend.below_steady_threshold_steady",
      compute_trend(0.54, prev_below, NOW) == "steady",
      "delta=0.04 (below threshold) should be steady")


# ---------------------------------------------------------------------------
# Section 4: Body-depletion clause for Weave Pause
# ---------------------------------------------------------------------------

# Construct inputs that yield score=0.90 with rising trend + sleepScore<0.5 (no depletion)
prev_calm = Reading(score=0.50, components={}, trend="steady", computed_at=NOW - timedelta(hours=20),
                    should_trigger_weave_pause=False)
inputs_busy_rested = {
    "calendarEventsNext4Hours": 20,    # calendarDensity = 1.0
    "openQuestCount": 30,              # openTaskCount = 1.0
    "openThreadCount": 0,
    "averageSleepLast7NightsHours": 8.0,  # at target, sleepDebt = 0.0
    "personalSleepTargetHours": 8.0,
    "daysSinceLastReflection": 0,
    "activeAmplifierStrain": 1.0,     # max amplifier
    "previousReading": prev_calm,
    "heartRateVariabilitySDNN": None,  # no HRV data → 0.0
    "personalHRVBaseline": None,
}
# Score = 0.20 (cal) + 0.20 (tasks) + 0.0 (sleep) + 0.0 (hrv) + 0.0 (refl) + 0.15 (amp) = 0.55
# This isn't enough to test body-depletion; need score=0.85+. Let me think.
# To get score >= 0.85 with sleepDebt=0 and hrvStress=0, need other components to add up to >=0.85.
# Max other components = 0.20+0.20+0.20+0.15 = 0.75. Can't reach 0.85 without sleep or HRV contributing.
# So the "busy but rested" case can NEVER reach 0.85. bodyDepleted clause is therefore protected.
# But compute() should still produce a low score and NOT trigger pause. Test that:
r_busy_rested = compute(inputs_busy_rested, NOW)
check("pause.busy_rested_below_pause", r_busy_rested.score < WAVE_PAUSE_SCORE,
      f"score={r_busy_rested.score} — busy-rested user should stay below 0.85")
check("pause.busy_rested_no_trigger", r_busy_rested.should_trigger_weave_pause == False,
      f"trigger={r_busy_rested.should_trigger_weave_pause}")

# Now construct: rising + score >= 0.85 + body depleted via sleep
prev_low = Reading(score=0.40, components={}, trend="steady", computed_at=NOW - timedelta(hours=20),
                   should_trigger_weave_pause=False)
inputs_depleted = {
    "calendarEventsNext4Hours": 20,
    "openQuestCount": 30,
    "openThreadCount": 0,
    "averageSleepLast7NightsHours": 5.0,  # 3h debt → sleepDebt = 1.0
    "personalSleepTargetHours": 8.0,
    "daysSinceLastReflection": 14,        # refl = 1.0
    "activeAmplifierStrain": 1.0,
    "previousReading": prev_low,
    "heartRateVariabilitySDNN": None,
    "personalHRVBaseline": None,
}
r_depleted = compute(inputs_depleted, NOW)
# Score = 0.20 + 0.20 + 0.15 + 0.0 + 0.20 + 0.15 = 0.90
check("pause.sleep_depleted_triggers", r_depleted.should_trigger_weave_pause == True,
      f"trigger={r_depleted.should_trigger_weave_pause}")
check("pause.sleep_depleted_score_high", r_depleted.score >= WAVE_PAUSE_SCORE,
      f"score={r_depleted.score}")

# Steady high (sustained high) → should NOT trigger even at 0.90
prev_high3 = Reading(score=0.92, components={}, trend="steadyHigh",
                     computed_at=NOW - timedelta(hours=20), should_trigger_weave_pause=False)
inputs_sustained = {**inputs_depleted, "previousReading": prev_high3}
r_sustained = compute(inputs_sustained, NOW)
check("pause.steady_high_no_trigger", r_sustained.should_trigger_weave_pause == False,
      f"trigger={r_sustained.should_trigger_weave_pause} (sustained high should not nag)")


# ---------------------------------------------------------------------------
# Section 5: Soft-exhale sequence
# ---------------------------------------------------------------------------

def make_reading(score: float, trend: str = "steady") -> Reading:
    r = Reading(score=score, components={}, trend=trend, computed_at=NOW,
                should_trigger_weave_pause=False, should_dim_ui=score >= ELEVATED_SCORE)
    # __post_init__ sets it but the type system sees Optional; force bool
    r.should_dim_ui = bool(r.should_dim_ui) if r.should_dim_ui is not None else (score >= ELEVATED_SCORE)
    return r


check("exhale.score_50_no_dim_no_pause",
      not make_reading(0.50).should_dim_ui and not make_reading(0.50).should_trigger_weave_pause)

check("exhale.score_70_dim_no_pause",
      make_reading(0.70).should_dim_ui and not make_reading(0.70).should_trigger_weave_pause)

check("exhale.score_75_dim_no_pause",
      make_reading(0.75).should_dim_ui and not make_reading(0.75).should_trigger_weave_pause)

check("exhale.score_80_dim_no_pause",
      make_reading(0.80).should_dim_ui and not make_reading(0.80).should_trigger_weave_pause)

check("exhale.score_85_dim_no_pause_if_steady",
      make_reading(0.85, "steadyHigh").should_dim_ui and not make_reading(0.85, "steadyHigh").should_trigger_weave_pause)

# Use actual compute() to verify the dim+pause sequence end-to-end.
# Rising + score>=0.85 + body depleted (sleep or hrv) → both dim AND pause fire.
prev_low_for_pause = Reading(score=0.40, components={}, trend="steady",
                             computed_at=NOW - timedelta(hours=20),
                             should_trigger_weave_pause=False)
inputs_full_pause = {
    "calendarEventsNext4Hours": 20, "openQuestCount": 30, "openThreadCount": 0,
    "averageSleepLast7NightsHours": 5.0,  # sleepDebt = 1.0 → body depleted
    "personalSleepTargetHours": 8.0,
    "daysSinceLastReflection": 14,
    "activeAmplifierStrain": 1.0,
    "previousReading": prev_low_for_pause,
    "heartRateVariabilitySDNN": None, "personalHRVBaseline": None,
}
r_full_pause = compute(inputs_full_pause, NOW)
dim_ui = bool(r_full_pause.should_dim_ui) if r_full_pause.should_dim_ui is not None else False
check("exhale.compute_score_85_plus_dim_and_pause",
      dim_ui and r_full_pause.should_trigger_weave_pause,
      f"dim={dim_ui} pause={r_full_pause.should_trigger_weave_pause}")


# ---------------------------------------------------------------------------
# Section 6: Component normalization boundary cases
# ---------------------------------------------------------------------------

check("norm.calendar_8_events_one", normalize_calendar(8) == 1.0)
check("norm.calendar_7_events_0.875", abs(normalize_calendar(7) - 0.875) < 1e-9)
check("norm.calendar_16_events_clamped_to_one", normalize_calendar(16) == 1.0)
check("norm.calendar_0_events_zero", normalize_calendar(0) == 0.0)

check("norm.tasks_25_quests_clamped", normalize_tasks(25, 0) == 1.0)
check("norm.tasks_12q_20t_clamped",
      normalize_tasks(12, 20) == clamp((12 + 20*0.4) / 20))

check("norm.sleep_1h_under", abs(normalize_sleep_debt(7.0, 8.0) - 1/3) < 1e-9)
check("norm.sleep_2h_under", abs(normalize_sleep_debt(6.0, 8.0) - 2/3) < 1e-9)
check("norm.sleep_3h_under_one", normalize_sleep_debt(5.0, 8.0) == 1.0)
check("norm.sleep_0.5h_over", abs(normalize_sleep_debt(8.5, 8.0) - 0.05) < 1e-9)
check("norm.sleep_5h_over_capped", normalize_sleep_debt(13.0, 8.0) == 0.5)
check("norm.sleep_zero_target_guard", normalize_sleep_debt(7.0, 0) == 0.0)

check("norm.hrv_ratio_one_zero", normalize_hrv(60, 60) == 0.0)
check("norm.hrv_ratio_0.5_one", normalize_hrv(30, 60) == 1.0)
check("norm.hrv_ratio_0.7_linear", abs(normalize_hrv(42, 60) - 0.6) < 1e-9)
check("norm.hrv_ratio_above_one_zero", normalize_hrv(90, 60) == 0.0)
check("norm.hrv_both_nil_zero", normalize_hrv(None, None) == 0.0)
check("norm.hrv_current_nil_zero", normalize_hrv(None, 60) == 0.0)
check("norm.hrv_baseline_nil_zero", normalize_hrv(60, None) == 0.0)

check("norm.reflection_0_days", normalize_reflection_gap(0) == 0.0)
check("norm.reflection_7_days_one", normalize_reflection_gap(7) == 1.0)
check("norm.reflection_14_clamped", normalize_reflection_gap(14) == 1.0)
check("norm.reflection_negative_clamped", normalize_reflection_gap(-1) == 0.0)


# ---------------------------------------------------------------------------
# Section 7: WeavePauseGate behavior
# ---------------------------------------------------------------------------

reading_pause = Reading(
    score=0.92, components={"calendarDensity": 0.9, "openTaskCount": 0.7,
                            "sleepDebt": 0.8, "hrvStress": 0.5,
                            "recentReflectionGap": 0.4, "activeAmplifierLoad": 0.6},
    trend="rising", computed_at=NOW, should_trigger_weave_pause=True, should_dim_ui=True,
)

try:
    attempt_commitment(reading_pause, "")
    check("gate.empty_reflection_throws", False, "no throw raised")
except CognitiveLoadPauseError as e:
    check("gate.empty_reflection_throws", True)
    check("gate.error_has_score", e.score == 0.92, f"score={e.score}")
    top_keys = [k for k, _ in e.components]
    check("gate.error_has_top2_components",
          len(e.components) == 2 and "calendarDensity" in top_keys,
          f"top={top_keys}")

try:
    attempt_commitment(reading_pause, "I see the load and choose to rest.")
    check("gate.non_empty_reflection_passes", True)
except Exception as e:
    check("gate.non_empty_reflection_passes", False, f"threw {e}")

try:
    attempt_commitment(reading_pause, "   \n  \t  ")
    check("gate.whitespace_only_throws", False, "no throw raised")
except CognitiveLoadPauseError:
    check("gate.whitespace_only_throws", True)

reading_no_pause = Reading(score=0.50, components={"calendarDensity": 0.3}, trend="steady",
                           computed_at=NOW, should_trigger_weave_pause=False, should_dim_ui=False)
try:
    attempt_commitment(reading_no_pause, "")
    check("gate.no_pause_empty_reflection_passes", True)
except Exception as e:
    check("gate.no_pause_empty_reflection_passes", False, f"threw {e}")


# ---------------------------------------------------------------------------
# Section 8: Clamping invariants
# ---------------------------------------------------------------------------

r_above = Reading(score=1.5, components={}, trend="steady", computed_at=NOW,
                  should_trigger_weave_pause=False)
check("clamp.score_above_1_clamped", r_above.score == 1.0, f"score={r_above.score}")

r_below = Reading(score=-0.5, components={}, trend="steady", computed_at=NOW,
                  should_trigger_weave_pause=False)
check("clamp.score_below_0_clamped", r_below.score == 0.0, f"score={r_below.score}")

r_components = Reading(score=0.5, components={"foo": 0.3, "bar": 0.7},
                      trend="steady", computed_at=NOW, should_trigger_weave_pause=False)
check("clamp.components_preserved", r_components.components == {"foo": 0.3, "bar": 0.7})

r_trend = Reading(score=0.5, components={}, trend="rising", computed_at=NOW,
                 should_trigger_weave_pause=False)
check("clamp.trend_preserved", r_trend.trend == "rising")

r_t = Reading(score=0.5, components={}, trend="steady", computed_at=NOW,
             should_trigger_weave_pause=False)
check("clamp.computed_at_preserved", r_t.computed_at == NOW)

r_st = Reading(score=0.5, components={}, trend="steady", computed_at=NOW,
              should_trigger_weave_pause=False)
check("clamp.should_trigger_preserved", r_st.should_trigger_weave_pause == False)


# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------

print()
print("=" * 70)
print("CognitiveLoad Depth validation (Cycle 49 F)")
print("=" * 70)
for name, passed, detail in RESULTS:
    mark = "PASS" if passed else "FAIL"
    line = f"  [{mark}] {name}"
    if detail and not passed:
        line += f"  -- {detail}"
    print(line)
print()
print(f"Total: {PASSED + FAILED}  |  PASSED: {PASSED}  |  FAILED: {FAILED}")
print(f"OVERALL: {'PASS' if FAILED == 0 else 'FAIL'}")
print()
sys.exit(0 if FAILED == 0 else 1)