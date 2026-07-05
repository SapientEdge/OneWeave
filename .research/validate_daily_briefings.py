#!/usr/bin/env python3
"""
validate_daily_briefings.py — Linux validation for DailyBriefings.swift

Mirrors the morning briefing + evening review generators in Python.
Verifies section composition, time-of-day behavior, prompts, and
reflection-gated output.

Coverage:
  1. TimeOfDay classifier for each hour bucket
  2. Morning briefing sections: greeting always present
  3. Morning briefing: cognitive load shown only when ≥ 0.50
  4. Morning briefing: weather section added when provider returns data
  5. Morning briefing: weather absent when provider returns nil
  6. Morning briefing: body thread section when bt present
  7. Morning briefing: calendar section shows up to maxCalendar events
  8. Morning briefing: priorities section shows up to maxPriorities quests
  9. Morning briefing: echoes section filtered to ≤7 days OR ready
 10. Morning briefing: empty context → minimal sections (greeting only)
 11. Morning briefing: sections sorted by priority
 12. Evening review: reflections + quests + harmony recap present
 13. Evening review: reflection-gated prompt when no reflection today
 14. Evening review: NO prompt when reflection was written
 15. Evening review: open threads count aggregated
 16. Evening review: quiet reminder after 9pm
 17. Evening review: NO quiet reminder between 9am and 9pm
 18. Evening prompt rotation is deterministic (same date → same prompt)
 19. Evening prompt rotation cycles through 10 prompts over time
 20. Morning briefing headline reflects weather when present
 21. Morning briefing headline reflects high cognitive load
 22. Morning briefing headline falls back to "Ready" or "Quiet day"
"""

import sys
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from typing import Dict, List, Optional, Tuple

# ---------------------------------------------------------------------------
# Mirror data types
# ---------------------------------------------------------------------------

@dataclass
class FakeTimelineEvent:
    id: str
    timestamp: datetime
    title: str
    note: str


@dataclass
class FakeQuest:
    id: str
    title: str
    is_completed: bool
    completed_at: Optional[datetime] = None
    reflection_text: str = ""


@dataclass
class FakeThread:
    title: str


@dataclass
class FakeBodyThread:
    average_sleep: Optional[float]
    sleep_target: Optional[float]
    hrv_sdnn: Optional[float]
    hrv_baseline: Optional[float]


@dataclass
class FakeCognitiveLoad:
    score: float
    trend: str
    should_trigger_weave_pause: bool


@dataclass
class FakeLifeContext:
    timeline: List[FakeTimelineEvent] = field(default_factory=list)
    quests: List[FakeQuest] = field(default_factory=list)
    threads: List[FakeThread] = field(default_factory=list)
    care_kin_threads: List[FakeThread] = field(default_factory=list)
    meaning_threads: List[FakeThread] = field(default_factory=list)
    stewardship_threads: List[FakeThread] = field(default_factory=list)
    body_thread: Optional[FakeBodyThread] = None
    upcoming_echoes: List[dict] = field(default_factory=list)


# ---------------------------------------------------------------------------
# Mirror of TimeOfDay + sections
# ---------------------------------------------------------------------------

class TimeOfDay:
    earlyMorning = "earlyMorning"
    morning = "morning"
    afternoon = "afternoon"
    evening = "evening"
    night = "night"


def tod_from_hour(hour: int) -> str:
    if 5 <= hour < 9: return TimeOfDay.earlyMorning
    if 9 <= hour < 12: return TimeOfDay.morning
    if 12 <= hour < 17: return TimeOfDay.afternoon
    if 17 <= hour < 20: return TimeOfDay.evening
    return TimeOfDay.night


# Section priority (lower = first)
SECTION_PRIORITY = {
    "greeting": 0,
    "cognitiveLoad": 5,
    "weather": 10,
    "bodyThread": 15,
    "calendar": 20,
    "priorities": 25,
    "echoes": 30,
    "openThreads": 35,
    "yesterdayRecap": 40,
    "eveningPrompt": 50,
    "quietReminder": 90,
}


def section_kind(section) -> str:
    """Returns the section 'kind' string for priority lookup."""
    if isinstance(section, dict):
        return section["kind"]
    return section[0]


# ---------------------------------------------------------------------------
# Generators (mirrors of DailyBriefingGenerator)
# ---------------------------------------------------------------------------

def morning_briefing(context: FakeLifeContext, weather=None,
                     cognitive_load: Optional[FakeCognitiveLoad] = None,
                     now: datetime = None,
                     max_priorities: int = 3,
                     max_calendar: int = 5,
                     max_echoes: int = 3) -> dict:
    hour = now.hour
    tod = tod_from_hour(hour)
    sections = []

    sections.append({"kind": "greeting", "timeOfDay": tod})

    if cognitive_load and cognitive_load.score >= 0.50:
        sections.append({
            "kind": "cognitiveLoad",
            "score": cognitive_load.score,
            "trend": cognitive_load.trend,
            "shouldPause": cognitive_load.should_trigger_weave_pause
        })

    if weather:
        sections.append({"kind": "weather", "tempF": weather[0], "condition": weather[1]})

    if context.body_thread:
        bt = context.body_thread
        if bt.hrv_sdnn is not None and bt.hrv_baseline and bt.hrv_baseline > 0:
            ratio = bt.hrv_sdnn / bt.hrv_baseline
            if ratio >= 1.0: hrv_status = "Recovered"
            elif ratio >= 0.7: hrv_status = "Normal"
            else: hrv_status = "Stressed"
        else:
            hrv_status = "Unmeasured"
        sections.append({
            "kind": "bodyThread",
            "avgSleep": bt.average_sleep if bt.average_sleep is not None else 7.0,
            "sleepTarget": bt.sleep_target if bt.sleep_target is not None else 8.0,
            "hrvStatus": hrv_status
        })

    cutoff = now + timedelta(hours=12)
    upcoming = sorted(
        [e for e in context.timeline if now <= e.timestamp <= cutoff],
        key=lambda e: e.timestamp
    )[:max_calendar]
    if upcoming:
        sections.append({
            "kind": "calendar",
            "events": [{"id": e.id, "title": e.title, "startTime": e.timestamp,
                        "durationMinutes": 60} for e in upcoming]
        })

    open_quests = sorted(
        [q for q in context.quests if not q.is_completed],
        key=lambda q: q.title
    )[:max_priorities]
    if open_quests:
        sections.append({
            "kind": "priorities",
            "quests": [{"id": q.id, "title": q.title, "isHeavy": True,
                        "priorityHint": 3} for q in open_quests]
        })

    if context.upcoming_echoes:
        echoes = [e for e in context.upcoming_echoes
                  if e["daysUntilUnlock"] <= 7 or e["isReadyToOpen"]][:max_echoes]
        if echoes:
            sections.append({"kind": "echoes", "countdowns": echoes})

    sections.sort(key=lambda s: SECTION_PRIORITY[section_kind(s)])
    return {"generatedAt": now, "sections": sections}


def evening_review(context: FakeLifeContext, cognitive_load=None,
                   yesterday_cognitive_load=None, now: datetime = None) -> dict:
    hour = now.hour
    tod = tod_from_hour(hour)
    sections = []

    sections.append({"kind": "greeting", "timeOfDay": tod})

    start_of_today = now.replace(hour=0, minute=0, second=0, microsecond=0)
    end_of_today = start_of_today + timedelta(days=1)
    reflections_today = sum(
        1 for e in context.timeline
        if start_of_today <= e.timestamp < end_of_today
        and ("reflection" in e.note.lower() or "Reflection" in e.note)
    )
    quests_completed_today = sum(
        1 for q in context.quests
        if q.is_completed and q.completed_at
        and start_of_today <= q.completed_at < end_of_today
    )
    harmony_delta = (cognitive_load.score if cognitive_load else 0.5) - \
                    (yesterday_cognitive_load.score if yesterday_cognitive_load else 0.5)
    sections.append({
        "kind": "yesterdayRecap",
        "reflectionsWritten": reflections_today,
        "questsCompleted": quests_completed_today,
        "harmonyDelta": harmony_delta
    })

    if reflections_today == 0:
        sections.append({"kind": "eveningPrompt", "prompt": pick_evening_prompt(now)})

    open_count = (
        sum(1 for t in context.threads if t.title)
        + sum(1 for t in context.care_kin_threads if t.title)
        + sum(1 for t in context.meaning_threads if t.title)
        + sum(1 for t in context.stewardship_threads if t.title)
    )
    if open_count > 0:
        sections.append({"kind": "openThreads", "count": open_count})

    if hour >= 21 or hour < 5:
        sections.append({"kind": "quietReminder"})

    sections.sort(key=lambda s: SECTION_PRIORITY[section_kind(s)])
    return {"generatedAt": now, "sections": sections}


EVENING_PROMPTS = [
    "What is one thing that went well today?",
    "What is something you'd like to do differently tomorrow?",
    "Who or what are you grateful for right now?",
    "What is something you noticed but didn't act on?",
    "How is your body feeling as the day winds down?",
    "What is a question you're sitting with?",
    "What did you learn about yourself today?",
    "Where did you notice energy, and where did you notice depletion?",
    "What is one small thing that would make tomorrow better?",
    "What is something you want to remember about today?",
]


def pick_evening_prompt(now: datetime) -> str:
    day_of_year = now.timetuple().tm_yday
    return EVENING_PROMPTS[day_of_year % len(EVENING_PROMPTS)]


def headline(briefing: dict) -> str:
    for s in briefing["sections"]:
        if s["kind"] == "weather":
            return f"{s['tempF']}° {s['condition']}"
        if s["kind"] == "cognitiveLoad" and s["score"] >= 0.70:
            return f"Load {int(s['score'] * 100)}% ({s['trend']})"
    return "Ready" if len(briefing["sections"]) > 1 else "Quiet day"


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


MORNING = datetime(2026, 6, 27, 7, 30, 0, tzinfo=timezone.utc)
AFTERNOON = datetime(2026, 6, 27, 14, 0, 0, tzinfo=timezone.utc)
EVENING = datetime(2026, 6, 27, 20, 30, 0, tzinfo=timezone.utc)
NIGHT = datetime(2026, 6, 27, 23, 0, 0, tzinfo=timezone.utc)


def empty_ctx() -> FakeLifeContext:
    return FakeLifeContext()


# Test 1: TimeOfDay
check("tod_early_morning", tod_from_hour(6) == TimeOfDay.earlyMorning)
check("tod_morning", tod_from_hour(10) == TimeOfDay.morning)
check("tod_afternoon", tod_from_hour(14) == TimeOfDay.afternoon)
check("tod_evening", tod_from_hour(18) == TimeOfDay.evening)
check("tod_night_late", tod_from_hour(23) == TimeOfDay.night)
check("tod_night_early", tod_from_hour(2) == TimeOfDay.night)

# Test 2: morning briefing greeting
b = morning_briefing(empty_ctx(), now=MORNING)
check("morning_has_greeting", b["sections"][0]["kind"] == "greeting")

# Test 3: cognitive load shown only when >= 0.50
b_no_load = morning_briefing(empty_ctx(), cognitive_load=FakeCognitiveLoad(0.3, "steady", False), now=MORNING)
check("cognitive_load_under_50_excluded",
      not any(s["kind"] == "cognitiveLoad" for s in b_no_load["sections"]))

b_with_load = morning_briefing(empty_ctx(), cognitive_load=FakeCognitiveLoad(0.7, "rising", True), now=MORNING)
check("cognitive_load_70_shown",
      any(s["kind"] == "cognitiveLoad" for s in b_with_load["sections"]))

# Test 4: weather when provider returns data
b_w = morning_briefing(empty_ctx(), weather=(72, "Sunny"), now=MORNING)
check("weather_section_present",
      any(s["kind"] == "weather" and s["tempF"] == 72 for s in b_w["sections"]))

# Test 5: no weather when provider returns nil
b_nw = morning_briefing(empty_ctx(), weather=None, now=MORNING)
check("weather_absent_when_no_provider",
      not any(s["kind"] == "weather" for s in b_nw["sections"]))

# Test 6: body thread
ctx = empty_ctx()
ctx.body_thread = FakeBodyThread(7.5, 8.0, 45.0, 50.0)
b_bt = morning_briefing(ctx, now=MORNING)
bt_section = next((s for s in b_bt["sections"] if s["kind"] == "bodyThread"), None)
check("body_thread_present", bt_section is not None)
check("body_thread_hrv_status_normal", bt_section["hrvStatus"] == "Normal" if bt_section else False)

# Test 7: calendar cap
ctx = empty_ctx()
now = MORNING
for i in range(10):
    ctx.timeline.append(FakeTimelineEvent(
        id=f"e{i}", timestamp=now + timedelta(hours=i+1),
        title=f"Event {i}", note=""
    ))
b_cal = morning_briefing(ctx, now=now, max_calendar=5)
cal = next(s for s in b_cal["sections"] if s["kind"] == "calendar")
check("calendar_caps_at_max", len(cal["events"]) == 5, f"got {len(cal['events'])}")

# Test 8: priorities cap
ctx = empty_ctx()
for i in range(10):
    ctx.quests.append(FakeQuest(id=f"q{i}", title=f"Quest {i}", is_completed=False))
b_p = morning_briefing(ctx, now=MORNING, max_priorities=3)
pri = next(s for s in b_p["sections"] if s["kind"] == "priorities")
check("priorities_caps_at_max", len(pri["quests"]) == 3)

# Test 9: echoes filter
ctx = empty_ctx()
ctx.upcoming_echoes = [
    {"id": "e1", "title": "Soon", "daysUntilUnlock": 3, "isReadyToOpen": False},
    {"id": "e2", "title": "Far", "daysUntilUnlock": 30, "isReadyToOpen": False},
    {"id": "e3", "title": "Ready", "daysUntilUnlock": 0, "isReadyToOpen": True},
    {"id": "e4", "title": "Way far", "daysUntilUnlock": 200, "isReadyToOpen": False},
]
b_e = morning_briefing(ctx, now=MORNING)
ec = next(s for s in b_e["sections"] if s["kind"] == "echoes")
check("echoes_filters_far", len(ec["countdowns"]) == 2, f"got {len(ec['countdowns'])}")

# Test 10: empty context
b_empty = morning_briefing(empty_ctx(), now=MORNING)
check("empty_context_minimal", len(b_empty["sections"]) == 1)

# Test 11: sections sorted by priority
ctx = empty_ctx()
ctx.body_thread = FakeBodyThread(7.0, 8.0, None, None)
for i in range(3):
    ctx.timeline.append(FakeTimelineEvent(
        id=f"e{i}", timestamp=MORNING + timedelta(hours=i+1),
        title=f"E{i}", note=""
    ))
b_sort = morning_briefing(ctx, weather=(70, "Clear"), cognitive_load=FakeCognitiveLoad(0.6, "steady", False), now=MORNING)
kinds = [s["kind"] for s in b_sort["sections"]]
priorities = [SECTION_PRIORITY[k] for k in kinds]
check("sections_sorted_by_priority", priorities == sorted(priorities), f"got {kinds}")

# Test 12: evening recap
ctx = empty_ctx()
ctx.timeline.append(FakeTimelineEvent(
    id="r1", timestamp=EVENING - timedelta(hours=2),
    title="Reflection", note="wrote a reflection"
))
ctx.quests.append(FakeQuest(id="q1", title="Done", is_completed=True, completed_at=EVENING - timedelta(hours=1)))
e = evening_review(ctx, now=EVENING)
recap = next(s for s in e["sections"] if s["kind"] == "yesterdayRecap")
check("evening_recap_reflections_count", recap["reflectionsWritten"] == 1)
check("evening_recap_quests_count", recap["questsCompleted"] == 1)

# Test 13: evening prompt when no reflection
ctx = empty_ctx()
e_no_ref = evening_review(ctx, now=EVENING)
prompt = next((s for s in e_no_ref["sections"] if s["kind"] == "eveningPrompt"), None)
check("evening_prompt_when_no_reflection", prompt is not None)

# Test 14: no prompt when reflection exists
ctx = empty_ctx()
ctx.timeline.append(FakeTimelineEvent(
    id="r1", timestamp=EVENING - timedelta(hours=1),
    title="R", note="reflection: I noticed..."
))
e_with_ref = evening_review(ctx, now=EVENING)
prompt_with_ref = next((s for s in e_with_ref["sections"] if s["kind"] == "eveningPrompt"), None)
check("no_evening_prompt_when_reflection_exists", prompt_with_ref is None)

# Test 15: open threads count
ctx = empty_ctx()
ctx.threads = [FakeThread(title="Self"), FakeThread(title="Other")]
ctx.care_kin_threads = [FakeThread(title="Family")]
ctx.meaning_threads = [FakeThread(title="Purpose")]
e_threads = evening_review(ctx, now=EVENING, cognitive_load=FakeCognitiveLoad(0.4, "steady", False))
threads_section = next((s for s in e_threads["sections"] if s["kind"] == "openThreads"), None)
# Note: empty timeline means no reflection, so a prompt will also be present
# Open threads = 3 (Self, Family, Purpose) — "Other" was filtered out (wait, no, it has a title)
# Actually count all: Self, Other, Family, Purpose = 4
check("open_threads_count", threads_section["count"] == 4, f"got {threads_section['count']}")

# Test 16: quiet reminder after 9pm
ctx = empty_ctx()
e_late = evening_review(ctx, now=NIGHT)
check("quiet_reminder_at_night", any(s["kind"] == "quietReminder" for s in e_late["sections"]))

# Test 17: no quiet reminder during day
ctx = empty_ctx()
e_day = evening_review(ctx, now=AFTERNOON)
check("no_quiet_reminder_during_day", not any(s["kind"] == "quietReminder" for s in e_day["sections"]))

# Test 18: prompt rotation deterministic
prompt_a = pick_evening_prompt(datetime(2026, 6, 27, 22, 0, 0, tzinfo=timezone.utc))
prompt_b = pick_evening_prompt(datetime(2026, 6, 27, 22, 0, 0, tzinfo=timezone.utc))
check("prompt_rotation_deterministic", prompt_a == prompt_b)

# Test 19: prompt cycles through 10
seen = set()
for day in range(30):
    dt = datetime(2026, 1, 1, 22, 0, 0, tzinfo=timezone.utc) + timedelta(days=day)
    seen.add(pick_evening_prompt(dt))
check("prompt_rotates_through_pool", len(seen) >= 5, f"got {len(seen)} unique prompts in 30 days")

# Test 20: headline weather
b_w = morning_briefing(empty_ctx(), weather=(68, "Partly Cloudy"), now=MORNING)
check("headline_weather", headline(b_w) == "68° Partly Cloudy")

# Test 21: headline high load
b_h = morning_briefing(empty_ctx(), cognitive_load=FakeCognitiveLoad(0.8, "rising", True), now=MORNING)
check("headline_high_load", "Load" in headline(b_h) and "80%" in headline(b_h))

# Test 22: headline fallback
b_q = morning_briefing(empty_ctx(), now=MORNING)
check("headline_quiet_day", headline(b_q) == "Quiet day")

# Test 23: sections always have unique kinds (no duplicates)
ctx = empty_ctx()
ctx.body_thread = FakeBodyThread(7.0, 8.0, 50.0, 60.0)
b_dup = morning_briefing(ctx, cognitive_load=FakeCognitiveLoad(0.7, "rising", True), weather=(70, "Clear"), now=MORNING)
kinds = [s["kind"] for s in b_dup["sections"]]
check("no_duplicate_section_kinds", len(kinds) == len(set(kinds)), f"kinds: {kinds}")


# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------

print()
print("=" * 70)
print("DailyBriefings Linux validation")
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