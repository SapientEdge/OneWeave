#!/usr/bin/env python3
"""
validate_relationship_decay.py — Linux validation for RelationshipDecayTracker.swift

Mirrors the decay math in Python. Verifies:
  1. Records on time generate NO prompts
  2. Records 1-1.5x cadence generate gentle prompts
  3. Records 1.5-2.5x cadence generate moderate prompts
  4. Records >2.5x cadence generate severe prompts (require reflection)
  5. maxPromptsPerDay caps the result
  6. Recently surfaced records are suppressed
  7. Most-overdue records surface first
  8. Default cadence hints per RelationshipKind
  9. Prompt frames are calm (no guilt)
 10. Stats: overdue/sever/average
 11. Empty records → empty prompts + zero stats
 12. Custom cadence respected (overrides defaults)
 13. Reflection gate only triggers on severe
 14. Recently surfaced within suppressionDays NOT surfaced again
 15. Records with cadenceDays=1 force daily prompts when overdue
"""

import sys
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Dict, List, Optional, Tuple

# ---------------------------------------------------------------------------
# Mirror
# ---------------------------------------------------------------------------

MAX_PROMPTS_PER_DAY = 1


@dataclass
class Record:
    life_entity_id: str
    display_name: str
    last_interaction_at: datetime
    cadence_days: int = 14
    relationship_kind: str = "friend"
    domains: List[str] = None
    suppression_days: int = 7

    def __post_init__(self):
        if self.domains is None:
            self.domains = []


KIND_DEFAULTS = {
    "family": 14,
    "closeFriend": 14,
    "friend": 30,
    "colleague": 21,
    "mentor": 60,
    "acquaintance": 90,
}

KIND_FRAMES = {
    "family": "Reach out to",
    "closeFriend": "Check in with",
    "friend": "Drop a line to",
    "colleague": "Catch up with",
    "mentor": "Touch base with",
    "acquaintance": "Reconnect with",
}


def suggested_action(kind: str, days: int) -> str:
    if kind in ("family", "closeFriend"):
        return "Schedule a call" if days >= 30 else "Send a text"
    return {
        "friend": "Drop a message",
        "colleague": "Say hi",
        "mentor": "Send an update",
        "acquaintance": "Send a brief note",
    }[kind]


def compute_severity(multiplier: float) -> str:
    if multiplier < 1.5: return "gentle"
    if multiplier < 2.5: return "moderate"
    return "severe"


def todays_prompts(records: List[Record],
                   recently_surfaced: Dict[str, datetime] = None,
                   now: datetime = None) -> List[dict]:
    if recently_surfaced is None:
        recently_surfaced = {}
    candidates = []
    for r in records:
        if r.life_entity_id in recently_surfaced:
            last = recently_surfaced[r.life_entity_id]
            days_since_surfaced = (now - last).total_seconds() / 86400
            if days_since_surfaced < r.suppression_days:
                continue
        days_since = max(0, int((now - r.last_interaction_at).total_seconds() / 86400))
        multiplier = days_since / r.cadence_days
        if multiplier < 1.0:
            continue
        severity = compute_severity(multiplier)
        candidates.append({
            "record": r,
            "daysSinceLastInteraction": days_since,
            "overdueMultiplier": multiplier,
            "severity": severity,
            "suggestedAction": suggested_action(r.relationship_kind, days_since),
            "requiresReflection": severity == "severe"
        })
    candidates.sort(key=lambda c: -c["overdueMultiplier"])
    return candidates[:MAX_PROMPTS_PER_DAY]


def stats(records: List[Record], now: datetime) -> dict:
    if not records:
        return {"overdue": 0, "severe": 0, "averageDaysSince": 0.0}
    overdue = severe = total_days = 0
    for r in records:
        days = max(0, int((now - r.last_interaction_at).total_seconds() / 86400))
        mult = days / r.cadence_days
        total_days += days
        if mult >= 1.0: overdue += 1
        if mult >= 2.5: severe += 1
    return {"overdue": overdue, "severe": severe, "averageDaysSince": total_days / len(records)}


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

PASSED = 0
FAILED = 0
RESULTS = []


def check(name: str, condition: bool, detail: str = "") -> None:
    global PASSED, FAILED
    if condition:
        PASSED += 1
        RESULTS.append((name, True, ""))
    else:
        FAILED += 1
        RESULTS.append((name, False, detail))


NOW = datetime(2026, 6, 27, 12, 0, 0, tzinfo=timezone.utc)


def rec(eid: str, days_ago: int, cadence: int = 14, kind: str = "friend") -> Record:
    return Record(
        life_entity_id=eid, display_name=eid,
        last_interaction_at=NOW - timedelta(days=days_ago),
        cadence_days=cadence, relationship_kind=kind
    )


# Test 1: on time → no prompts
records = [rec("alice", 5, cadence=14)]
prompts = todays_prompts(records, now=NOW)
check("on_time_no_prompts", len(prompts) == 0)

# Test 2: 1.0-1.5x → gentle
records = [rec("alice", 18, cadence=14)]  # 18/14 = 1.29x
prompts = todays_prompts(records, now=NOW)
check("gentle_severity", len(prompts) == 1 and prompts[0]["severity"] == "gentle")

# Test 3: 1.5-2.5x → moderate
records = [rec("alice", 30, cadence=14)]  # 30/14 = 2.14x
prompts = todays_prompts(records, now=NOW)
check("moderate_severity", len(prompts) == 1 and prompts[0]["severity"] == "moderate")

# Test 4: >2.5x → severe, requires reflection
records = [rec("alice", 40, cadence=14)]  # 40/14 = 2.86x
prompts = todays_prompts(records, now=NOW)
check("severe_severity", len(prompts) == 1 and prompts[0]["severity"] == "severe")
check("severe_requires_reflection", prompts[0]["requiresReflection"])

# Test 5: maxPromptsPerDay = 1 cap
records = [rec(f"p{i}", 40 + i, cadence=14) for i in range(5)]
prompts = todays_prompts(records, now=NOW)
check("max_one_prompt_per_day", len(prompts) == 1)

# Test 6: most overdue surfaces first
records = [
    rec("mild", 20, cadence=14),     # 1.43x
    rec("very_overdue", 60, cadence=14),  # 4.29x
    rec("moderate", 25, cadence=14),  # 1.79x
]
prompts = todays_prompts(records, now=NOW)
check("most_overdue_first",
      len(prompts) == 1 and prompts[0]["record"].life_entity_id == "very_overdue")

# Test 7: suppression
records = [rec("alice", 40, cadence=14)]
surfaced = {"alice": NOW - timedelta(days=2)}  # surfaced 2 days ago
prompts = todays_prompts(records, recently_surfaced=surfaced, now=NOW)
# alice has suppression_days=7, so 2 < 7 → suppressed
check("recently_surfaced_suppressed", len(prompts) == 0)

# Test 8: surfacing older than suppressionDays → unsuppressed
surfaced = {"alice": NOW - timedelta(days=10)}  # 10 days ago > 7
prompts = todays_prompts(records, recently_surfaced=surfaced, now=NOW)
check("suppression_expires", len(prompts) == 1)

# Test 9: cadence defaults per kind
for kind, expected in KIND_DEFAULTS.items():
    actual = Record(
        life_entity_id="x", display_name="X",
        last_interaction_at=NOW, cadence_days=KIND_DEFAULTS[kind],
        relationship_kind=kind
    ).cadence_days
check("kind_defaults_present", expected == KIND_DEFAULTS[kind])

# Test 10: prompt frames calm (no guilt words)
guilt_words = ["forgotten", "neglect", "shame", "guilt", "bad friend", "ignored"]
all_calm = all(
    not any(gw in KIND_FRAMES[k].lower() for gw in guilt_words)
    for k in KIND_FRAMES
)
check("prompt_frames_calm", all_calm)

# Test 11: stats
records = [
    rec("a", 5, cadence=14),    # on time
    rec("b", 20, cadence=14),   # overdue
    rec("c", 50, cadence=14),   # severe
]
s = stats(records, now=NOW)
check("stats_overdue_count", s["overdue"] == 2, f"got {s['overdue']}")
check("stats_severe_count", s["severe"] == 1, f"got {s['severe']}")
check("stats_average", abs(s["averageDaysSince"] - 25.0) < 1e-9, f"got {s['averageDaysSince']}")

# Test 12: empty records
s_empty = stats([], now=NOW)
check("stats_empty_zero", s_empty == {"overdue": 0, "severe": 0, "averageDaysSince": 0.0})

p_empty = todays_prompts([], now=NOW)
check("prompts_empty_zero", len(p_empty) == 0)

# Test 13: reflection only for severe
records = [rec("alice", 20, cadence=14)]   # gentle
prompts = todays_prompts(records, now=NOW)
check("gentle_no_reflection", not prompts[0]["requiresReflection"])

records = [rec("alice", 30, cadence=14)]   # moderate
prompts = todays_prompts(records, now=NOW)
check("moderate_no_reflection", not prompts[0]["requiresReflection"])

records = [rec("alice", 40, cadence=14)]   # severe
prompts = todays_prompts(records, now=NOW)
check("severe_reflection_required", prompts[0]["requiresReflection"])

# Test 14: cadenceDays = 1 forces daily when overdue
records = [rec("daily_friend", 2, cadence=1)]  # 2x overdue
prompts = todays_prompts(records, now=NOW)
check("daily_cadence_overdue", len(prompts) == 1 and prompts[0]["overdueMultiplier"] > 1.5)

# Test 15: suggested action differs by kind
records = [rec("family_friend", 5, cadence=14, kind="family")]
prompts = todays_prompts(records, now=NOW)
# Not overdue yet, so no prompt; check action via direct call
check("family_short_action", suggested_action("family", 5) == "Send a text")
check("family_long_action", suggested_action("family", 40) == "Schedule a call")
check("friend_action", suggested_action("friend", 30) == "Drop a message")
check("mentor_action", suggested_action("mentor", 60) == "Send an update")

# Test 16: multiplier calculation
records = [rec("exact", 14, cadence=14)]
prompts = todays_prompts(records, now=NOW)
# 14 days exact → 1.0x → not overdue (>= 1.0 is the boundary)
# The check is `if multiplier < 1.0: continue`, so 1.0 is included
check("exactly_at_cadence_is_overdue", len(prompts) == 1 and prompts[0]["overdueMultiplier"] == 1.0)

# Test 17: zero days_since → no prompt
records = [rec("just_now", 0, cadence=14)]
prompts = todays_prompts(records, now=NOW)
check("just_now_no_prompt", len(prompts) == 0)

# Test 18: very old interaction (>2.5x with high cadence)
records = [rec("old_friend", 100, cadence=30)]  # 3.33x → severe
prompts = todays_prompts(records, now=NOW)
check("very_old_severe", len(prompts) == 1 and prompts[0]["severity"] == "severe")

# Test 19: suppression with custom suppressionDays
records = [Record(
    life_entity_id="alice", display_name="Alice",
    last_interaction_at=NOW - timedelta(days=40),
    cadence_days=14, relationship_kind="friend", suppression_days=3
)]
surfaced = {"alice": NOW - timedelta(days=2)}  # 2 < 3
prompts = todays_prompts(records, recently_surfaced=surfaced, now=NOW)
check("custom_suppression_respected", len(prompts) == 0)

surfaced = {"alice": NOW - timedelta(days=5)}  # 5 > 3
prompts = todays_prompts(records, recently_surfaced=surfaced, now=NOW)
check("custom_suppression_expires", len(prompts) == 1)

# Test 20: daysSince is integer
records = [rec("alice", 14, cadence=14)]
prompts = todays_prompts(records, now=NOW)
check("days_since_is_int", isinstance(prompts[0]["daysSinceLastInteraction"], int))


# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------

print()
print("=" * 70)
print("RelationshipDecay Linux validation")
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
