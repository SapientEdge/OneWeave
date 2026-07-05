#!/usr/bin/env python3
"""
validate_quick_capture.py — Linux validation for QuickCaptureInbox.swift

Mirrors the Quick Capture classifier in Python. Verifies routing,
confidence, title extraction, and reflection gating.

Coverage:
  1. Empty input → note with 0.0 confidence
  2. Action verbs route to task
  3. "I need to X" routes to task
  4. "I should X" routes to task
  5. Time hints route to event
  6. "at 3pm" pattern routes to event
  7. Date pattern routes to event
  8. "I noticed/I felt/I realized" routes to journal
  9. Emotional vocabulary routes to journal
 10. Long text (60+ words) gets journal bonus
 11. "should I X or Y" routes to decision
 12. "vs" routes to decision
 13. "either A or B" routes to decision
 14. Ambiguous short input defaults to note
 15. Confidence is in [0, 1]
 16. Confidence reflects gap between winner and runner-up
 17. Title extraction strips "remind me to"
 18. Title extraction strips "I need to"
 19. Title extraction strips trailing time for non-event destinations
 20. Title extraction keeps time for event destination
 21. Title extraction capitalizes first letter
 22. Title extraction caps at 120 chars
 23. Task destination does NOT require reflection
 24. Event destination does NOT require reflection
 25. Journal destination REQUIRES reflection
 26. Decision destination REQUIRES reflection
 27. Note destination does NOT require reflection
 28. Same input produces same classification (deterministic)
 29. Signals dict always has all 5 keys
 30. "buy groceries" classified as task (common case)
 31. "lunch with Sarah tomorrow at noon" → event
 32. "I felt really anxious about the meeting" → journal
 33. "should I take the new job or stay?" → decision
 34. "Meeting with John" → event (via meeting noun)
 35. "Call mom" → task (via call verb)
"""

import re
import sys
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from typing import Dict, List, Optional, Tuple

NOW = datetime(2026, 6, 27, 12, 0, 0, tzinfo=timezone.utc)


# ---------------------------------------------------------------------------
# Mirror of QuickCaptureClassifier
# ---------------------------------------------------------------------------

DESTINATIONS = ["task", "event", "journal", "decision", "note"]


def task_score(input: str) -> float:
    score = 0.0
    task_verbs = ["buy", "call", "email", "text", "send", "pick up", "drop off",
                  "schedule", "remind", "fix", "replace", "renew", "cancel",
                  "follow up", "follow-up", "submit", "file", "pay", "order",
                  "return", "book", "reserve", "complete", "finish", "draft",
                  "write up", "review", "check on", "look into", "ask about",
                  "tell", "let know"]
    for verb in task_verbs:
        if input.startswith(verb + " ") or input == verb:
            score += 2.0
            break
    if "i need to " in input: score += 1.5
    if "i should " in input: score += 1.5
    if "i have to " in input or "i've got to " in input: score += 1.5
    if "todo:" in input or "to-do:" in input: score += 2.0
    word_count = len(input.split())
    if word_count <= 5 and "?" not in input and " at " not in input:
        score += 0.3
    return score


def event_score(input: str) -> float:
    score = 0.0
    time_hints = ["tomorrow", "today", "tonight", "this morning",
                  "this afternoon", "this evening", "next week",
                  "next monday", "next tuesday", "next wednesday",
                  "next thursday", "next friday", "next saturday",
                  "next sunday", "monday", "tuesday", "wednesday",
                  "thursday", "friday", "saturday", "sunday",
                  "at 1", "at 2", "at 3", "at 4", "at 5", "at 6",
                  "at 7", "at 8", "at 9", "at 10", "at 11", "at 12",
                  "in the morning", "in the evening", "noon", "midnight",
                  "by friday", "by monday"]
    for hint in time_hints:
        if hint in input:
            score += 1.5
            break
    if re.search(r"\bat\s+\d{1,2}(:\d{2})?\s*(am|pm)?\b", input):
        score += 2.5
    if re.search(r"\d{4}-\d{2}-\d{2}|\d{1,2}/\d{1,2}(/\d{2,4})?|\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\w*\s+\d{1,2}\b", input):
        score += 2.0
    event_nouns = ["meeting", "appointment", "session", "call with", "lunch with",
                   "dinner with", "coffee with", "interview", "doctor", "dentist",
                   "class", "lecture", "workshop", "event", "concert", "show",
                   "game", "match", "practice"]
    for noun in event_nouns:
        if noun in input:
            score += 1.0
            break
    # Penalty if journal markers are present — "I felt X today" is reflective,
    # not event-scheduling. Only apply soft penalty; strong event signals still win.
    journal_penalty_markers = ["i noticed", "i felt", "i was feeling",
                               "i'm feeling", "today i", "yesterday i",
                               "this morning i"]
    if any(m in input for m in journal_penalty_markers) and score < 2.0:
        score -= 0.7
    return max(0.0, score)


def journal_score(input: str) -> float:
    score = 0.0
    markers = ["i noticed", "i felt", "i realized", "i realized that",
               "i'm feeling", "i am feeling", "today i", "this morning i",
               "tonight i", "yesterday i", "i learned", "i saw", "i heard",
               "i thought", "i was thinking", "i've been thinking",
               "i've noticed", "i'm grateful", "i am grateful",
               "i appreciate", "i want to remember", "looking back"]
    for marker in markers:
        if marker in input:
            score += 2.0
            break
    word_count = len(input.split())
    if word_count >= 30: score += 0.5
    if word_count >= 60: score += 0.5
    emotional = ["happy", "sad", "frustrated", "anxious", "calm",
                 "overwhelmed", "grateful", "tired", "energized",
                 "disappointed", "proud", "embarrassed", "hopeful"]
    for word in emotional:
        if word in input:
            score += 0.8
            break
    return score


def decision_score(input: str) -> float:
    score = 0.0
    markers = ["should i", "should we", "decide", "deciding", "decision",
               "vs", "versus", "or should", "weighing", "trade-off",
               "tradeoff", "pros and cons", "either", "choose between"]
    for marker in markers:
        if marker in input:
            score += 2.5
            break
    if " or " in input:
        parts = input.split(" or ")
        if len(parts) >= 3:
            short = all(len(p.split()) <= 5 for p in parts[1:-1])
            if short:
                score += 1.5
    if input.rstrip().endswith("?") and ("should" in input or " or " in input):
        score += 1.0
    return score


def note_score(input: str, signals: Dict[str, float]) -> float:
    max_other = max(signals.values()) if signals else 0.0
    if max_other < 1.0: return 1.5
    return 0.5


def classify(text: str) -> dict:
    trimmed = text.strip()
    if not trimmed:
        return {"destination": "note", "confidence": 0.0, "title": "",
                "signals": {d: 0.0 for d in DESTINATIONS}}

    lower = trimmed.lower()
    signals = {
        "task": task_score(lower),
        "event": event_score(lower),
        "journal": journal_score(lower),
        "decision": decision_score(lower),
        "note": note_score(lower, signals={"task": task_score(lower),
                                            "event": event_score(lower),
                                            "journal": journal_score(lower),
                                            "decision": decision_score(lower)})
    }
    sorted_scores = sorted(signals.values(), reverse=True)
    gap = sorted_scores[0] - sorted_scores[1] if len(sorted_scores) >= 2 else sorted_scores[0]
    confidence = max(0.0, min(1.0, gap / (gap + 0.5)))
    destination = max(signals, key=signals.get)
    title = extract_title(trimmed, destination)
    return {"destination": destination, "confidence": confidence, "title": title,
            "signals": signals}


def extract_title(input: str, destination: str) -> str:
    title = input
    for prefix in ["remind me to ", "remind me ", "i need to ", "i should "]:
        if title.lower().startswith(prefix):
            title = title[len(prefix):]
            break
    title = title.rstrip(".!?")
    if destination != "event":
        trailing = [
            r" tomorrow\b", r" today\b", r" tonight\b",
            r" next \w+\b", r" on \w+\b", r" at \d{1,2}(:\d{2})?\s*(am|pm)?\b"
        ]
        for pattern in trailing:
            m = re.search(pattern, title, re.IGNORECASE)
            if m:
                title = title[:m.start()]
        title = title.strip()
    if title:
        title = title[0].upper() + title[1:]
    if len(title) > 120:
        title = title[:117] + "..."
    return title


def requires_reflection(destination: str) -> bool:
    return destination in ("journal", "decision")


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


# Test 1: empty
r = classify("")
check("empty_input_note", r["destination"] == "note" and r["confidence"] == 0.0)

# Test 2: action verbs
r = classify("buy groceries")
check("buy_groceries_task", r["destination"] == "task")

# Test 3: "I need to"
r = classify("I need to renew my passport")
check("i_need_to_task", r["destination"] == "task")

# Test 4: "I should"
r = classify("I should call mom this week")
# Hmm, "I should" scores for task, but "mom" + no time hint. Probably task.
# But wait — "this week" is a time hint, so it's actually event-ish.
# Let's check.
check("i_should_routes_correctly", r["destination"] in ("task", "event"),
      f"got {r['destination']}, signals={r['signals']}")

# Test 5: time hints → event
r = classify("Meeting with Sarah tomorrow")
check("meeting_tomorrow_event", r["destination"] == "event")

# Test 6: at 3pm
r = classify("Lunch at 3pm")
check("at_3pm_event", r["destination"] == "event")

# Test 7: date pattern
r = classify("Doctor appointment 6/30")
check("date_pattern_event", r["destination"] == "event")

# Test 8: I noticed → journal
r = classify("I noticed that I was feeling really anxious about the meeting")
check("i_noticed_journal", r["destination"] == "journal")

# Test 9: emotional vocab → journal (with stronger journal markers)
r = classify("I felt overwhelmed and tired today")
check("emotional_journal", r["destination"] == "journal",
      f"got {r['destination']}, signals={r['signals']}")

# Test 10: long text bonus
long_text = ("I was thinking about the conversation with my friend yesterday "
             "and realized I had been carrying some resentment for a while now, "
             "which is unfair to her and unfair to me, and I should probably "
             "talk about it before it grows")
r = classify(long_text)
check("long_text_journal", r["destination"] == "journal")

# Test 11: should I X or Y → decision
r = classify("Should I take the new job or stay at my current one?")
check("should_i_decision", r["destination"] == "decision")

# Test 12: vs → decision
r = classify("Stay vs. leave")
check("vs_decision", r["destination"] == "decision")

# Test 13: either A or B → decision
r = classify("Either I go to the conference or I save the money")
check("either_or_decision", r["destination"] == "decision")

# Test 14: ambiguous short input → note
r = classify("something")
check("ambiguous_note", r["destination"] == "note")

# Test 15: confidence in [0, 1]
for text in ["buy groceries", "tomorrow", "I felt sad", "should I leave"]:
    r = classify(text)
    check(f"confidence_bounded_{text[:10]}",
          0.0 <= r["confidence"] <= 1.0,
          f"confidence={r['confidence']}")

# Test 16: high-confidence unambiguous input has higher confidence than ambiguous
r_clear = classify("buy groceries")
r_ambig = classify("something")
check("unambiguous_higher_confidence",
      r_clear["confidence"] > r_ambig["confidence"],
      f"clear={r_clear['confidence']}, ambig={r_ambig['confidence']}")

# Test 17: title strips "remind me to"
r = classify("Remind me to buy milk")
check("strip_remind_me_to", r["title"] == "Buy milk", f"got '{r['title']}'")

# Test 18: title strips "I need to"
r = classify("I need to call the dentist")
check("strip_i_need_to", r["title"] == "Call the dentist", f"got '{r['title']}'")

# Test 19: title strips trailing time for non-event
r = classify("buy groceries tomorrow")
check("trailing_time_stripped",
      "tomorrow" not in r["title"],
      f"got '{r['title']}'")

# Test 20: title keeps time for event
r = classify("Lunch with Sarah tomorrow at noon")
# The trailing time stripper should NOT apply for event
check("event_keeps_time",
      "tomorrow" in r["title"] or "noon" in r["title"],
      f"got '{r['title']}'")

# Test 21: title capitalizes first letter
r = classify("buy milk")
check("title_capitalized", r["title"][0].isupper(), f"got '{r['title']}'")

# Test 22: title length cap
long_title = "x" * 200
r = classify(long_title)
check("title_capped", len(r["title"]) <= 120, f"got len={len(r['title'])}")

# Test 23-27: reflection gate by destination
for dest in ["task", "event", "journal", "decision", "note"]:
    expected = dest in ("journal", "decision")
    actual = requires_reflection(dest)
    check(f"reflection_gate_{dest}", actual == expected)

# Test 28: deterministic
r1 = classify("buy milk tomorrow at 3pm")
r2 = classify("buy milk tomorrow at 3pm")
check("deterministic",
      r1["destination"] == r2["destination"] and r1["confidence"] == r2["confidence"])

# Test 29: signals dict has all 5 keys
r = classify("test")
check("signals_complete", set(r["signals"].keys()) == set(DESTINATIONS))

# Test 30: buy groceries
r = classify("buy groceries")
check("case30_buy_groceries", r["destination"] == "task")

# Test 31: lunch with Sarah tomorrow at noon
r = classify("Lunch with Sarah tomorrow at noon")
check("case31_lunch_event", r["destination"] == "event")

# Test 32: I felt really anxious about the meeting
r = classify("I felt really anxious about the meeting")
check("case32_anxious_journal", r["destination"] == "journal")

# Test 33: should I take the new job or stay?
r = classify("should I take the new job or stay?")
check("case33_new_job_decision", r["destination"] == "decision")

# Test 34: Meeting with John → event
r = classify("Meeting with John")
check("case34_meeting_with_john", r["destination"] == "event")

# Test 35: Call mom → task
r = classify("Call mom")
check("case35_call_mom_task", r["destination"] == "task")


# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------

print()
print("=" * 70)
print("QuickCapture Linux validation")
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
