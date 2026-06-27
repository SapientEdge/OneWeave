#!/usr/bin/env python3
"""
validate_decision_log.py — Linux validation for DecisionLog.swift

Mirrors the Decision Log API in Python. Verifies:
  1. Recording a decision requires non-empty title
  2. Recording a decision requires non-empty reasoning (reflection gate)
  3. Whitespace-only title/reasoning rejected
  4. Confidence clamped to [0, 1]
  5. Recording outcome requires non-empty text
  6. hasOutcome reflects actualOutcome presence
  7. daysToOutcome computed correctly
  8. needsOutcomeReminder returns oldest unrecorded
  9. needsOutcomeReminder respects maxReminders cap
 10. needsOutcomeReminder respects reminderDelayDays threshold
 11. DecisionMentorBridge.reflectionSeed formats correctly
 12. reflectionSeed includes outcome when present
 13. reflectionSeed excludes outcome when absent
 14. relevantDecisions uses lexical overlap
 15. relevantDecisions returns top N by score
 16. relevantDecisions respects domain tag bonus
 17. relevantDecisions returns empty for unrelated prompts
 18. Stats computed correctly
 19. Stats average confidence
 20. Stats for empty log
 21. DecisionLogStats has expected shape
 22. record() returns a DecisionRecord with the right fields
 23. recordOutcome preserves all fields except outcome + outcomeRecordedAt
 24. attributes dictionary is preserved
 25. isPrivate defaults to true
"""

import sys
import uuid as uuidlib
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from typing import Dict, List, Optional, Set, Tuple

# ---------------------------------------------------------------------------
# Mirror data types
# ---------------------------------------------------------------------------

REMINDER_DELAY_DAYS = 14


@dataclass
class DecisionRecord:
    id: str
    title: str
    options_considered: List[str]
    reasoning: str
    expected_outcome: str
    actual_outcome: Optional[str]
    confidence_at_decision: float
    domain_tags: List[str]
    referenced_entity_ids: List[str]
    decided_at: datetime
    outcome_recorded_at: Optional[datetime] = None
    is_private: bool = True
    attributes: Dict[str, str] = field(default_factory=dict)

    @property
    def has_outcome(self) -> bool:
        return self.actual_outcome is not None and self.actual_outcome != ""

    @property
    def days_to_outcome(self) -> Optional[int]:
        if self.outcome_recorded_at is None:
            return None
        delta = (self.outcome_recorded_at - self.decided_at).total_seconds() / 86400
        return max(0, int(delta))


class DecisionLogError_(Exception):
    pass


# ---------------------------------------------------------------------------
# Mirror of DecisionLog API
# ---------------------------------------------------------------------------

def record_decision(
    title: str,
    reasoning: str,
    options_considered: Optional[List[str]] = None,
    expected_outcome: str = "",
    confidence: float = 0.5,
    domain_tags: Optional[List[str]] = None,
    referenced_entity_ids: Optional[List[str]] = None,
    is_private: bool = True,
    now: Optional[datetime] = None
) -> DecisionRecord:
    trimmed_title = title.strip()
    trimmed_reasoning = reasoning.strip()
    if not trimmed_title:
        raise DecisionLogError_("emptyTitle")
    if not trimmed_reasoning:
        raise DecisionLogError_("emptyReasoning")
    return DecisionRecord(
        id=str(uuidlib.uuid4()),
        title=trimmed_title,
        options_considered=options_considered or [],
        reasoning=trimmed_reasoning,
        expected_outcome=expected_outcome,
        actual_outcome=None,
        confidence_at_decision=max(0.0, min(1.0, confidence)),
        domain_tags=domain_tags or [],
        referenced_entity_ids=referenced_entity_ids or [],
        decided_at=now or datetime.now(timezone.utc),
        outcome_recorded_at=None,
        is_private=is_private,
        attributes={}
    )


def record_outcome(decision: DecisionRecord, actual_outcome: str, now: Optional[datetime] = None) -> DecisionRecord:
    trimmed = actual_outcome.strip()
    if not trimmed:
        raise DecisionLogError_("emptyOutcome")
    updated = DecisionRecord(
        id=decision.id,
        title=decision.title,
        options_considered=list(decision.options_considered),
        reasoning=decision.reasoning,
        expected_outcome=decision.expected_outcome,
        actual_outcome=trimmed,
        confidence_at_decision=decision.confidence_at_decision,
        domain_tags=list(decision.domain_tags),
        referenced_entity_ids=list(decision.referenced_entity_ids),
        decided_at=decision.decided_at,
        outcome_recorded_at=now or datetime.now(timezone.utc),
        is_private=decision.is_private,
        attributes=dict(decision.attributes)
    )
    return updated


def needs_outcome_reminder(records: List[DecisionRecord], now: datetime, max_reminders: int = 1) -> List[DecisionRecord]:
    candidates = [
        r for r in records
        if not r.has_outcome
        and (now - r.decided_at).total_seconds() / 86400 >= REMINDER_DELAY_DAYS
    ]
    candidates.sort(key=lambda r: r.decided_at)
    return candidates[:max_reminders]


# Mirror of DecisionMentorBridge
def reflection_seed(decision: DecisionRecord, now: datetime) -> dict:
    text = decision.reasoning
    if decision.actual_outcome:
        text += f"\n\nOutcome: {decision.actual_outcome}"
    days = max(0, int((now - decision.decided_at).total_seconds() / 86400))
    return {
        "id": decision.id,
        "text": text,
        "domains": list(decision.domain_tags),
        "days_ago": days,
        "harmony_impact": decision.confidence_at_decision
    }


def tokenize(s: str) -> Set[str]:
    return {
        t for t in
        "".join(c if c.isalnum() or c.isspace() else " " for c in s.lower()).split()
        if len(t) >= 3
    }


def relevant_decisions(prompt: str, records: List[DecisionRecord],
                       now: datetime, limit: int = 3) -> List[Tuple[DecisionRecord, float]]:
    prompt_tokens = tokenize(prompt)
    if not prompt_tokens:
        return []
    scored = []
    for r in records:
        haystack = " ".join([r.title, r.reasoning, r.actual_outcome or ""])
        tokens = tokenize(haystack)
        if not tokens:
            continue
        intersection = len(prompt_tokens & tokens)
        union = len(prompt_tokens | tokens)
        jaccard = intersection / union if union > 0 else 0
        domain_bonus = 0.1 if r.domain_tags else 0.0
        days_ago = (now - r.decided_at).total_seconds() / 86400
        recency = max(0.5, 1.0 - days_ago / 365.0 * 0.5)
        score = (jaccard + domain_bonus) * recency
        if score > 0.05:
            scored.append((r, score))
    scored.sort(key=lambda x: -x[1])
    return scored[:limit]


@dataclass
class Stats:
    total_decisions: int
    with_outcomes: int
    average_days_to_outcome: float
    average_confidence: float


def compute_stats(records: List[DecisionRecord]) -> Stats:
    if not records:
        return Stats(0, 0, 0.0, 0.0)
    with_outcomes = [r for r in records if r.has_outcome]
    days = [r.days_to_outcome for r in with_outcomes if r.days_to_outcome is not None]
    avg_days = sum(days) / len(days) if days else 0.0
    avg_conf = sum(r.confidence_at_decision for r in records) / len(records)
    return Stats(len(records), len(with_outcomes), avg_days, avg_conf)


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


# Test 1: empty title rejected
try:
    record_decision("", "Some reasoning", now=NOW)
    check("empty_title_rejected", False)
except DecisionLogError_ as e:
    check("empty_title_rejected", str(e) == "emptyTitle", f"got {e}")

# Test 2: empty reasoning rejected (reflection gate)
try:
    record_decision("Title", "", now=NOW)
    check("empty_reasoning_rejected", False)
except DecisionLogError_ as e:
    check("empty_reasoning_rejected", str(e) == "emptyReasoning", f"got {e}")

# Test 3: whitespace-only rejected
try:
    record_decision("   ", "   ", now=NOW)
    check("whitespace_only_rejected", False)
except DecisionLogError_:
    check("whitespace_only_rejected", True)

# Test 4: confidence clamped
d = record_decision("T", "R", confidence=2.5, now=NOW)
check("confidence_clamped_high", d.confidence_at_decision == 1.0)
d2 = record_decision("T", "R", confidence=-0.5, now=NOW)
check("confidence_clamped_low", d2.confidence_at_decision == 0.0)

# Test 5: empty outcome rejected
try:
    record_outcome(d, "", now=NOW)
    check("empty_outcome_rejected", False)
except DecisionLogError_ as e:
    check("empty_outcome_rejected", str(e) == "emptyOutcome", f"got {e}")

# Test 6: hasOutcome
check("no_outcome_has_outcome_false", not d.has_outcome)
d_with_outcome = record_outcome(d, "It went well.", now=NOW + timedelta(days=7))
check("with_outcome_has_outcome_true", d_with_outcome.has_outcome)

# Test 7: daysToOutcome
check("days_to_outcome_correct", d_with_outcome.days_to_outcome == 7)
check("days_to_outcome_none_when_no_outcome", d.days_to_outcome is None)

# Test 8: needsOutcomeReminder returns oldest unrecorded
records = [
    record_decision(f"T{i}", f"R{i}", now=NOW - timedelta(days=20 + i * 5))
    for i in range(3)
]
reminders = needs_outcome_reminder(records, now=NOW, max_reminders=5)
# Oldest = T2 (30 days ago); most recent = T0 (20 days ago).
check("reminder_oldest_first",
      len(reminders) == 3 and reminders[0].title == "T2" and reminders[-1].title == "T0",
      f"order: {[r.title for r in reminders]}")

# Test 9: maxReminders cap
reminders_capped = needs_outcome_reminder(records, now=NOW, max_reminders=1)
check("reminder_cap_respected", len(reminders_capped) == 1)

# Test 10: reminderDelayDays threshold
recent = [record_decision("T", "R", now=NOW - timedelta(days=5))]
check("reminder_skipped_for_recent", len(needs_outcome_reminder(recent, now=NOW)) == 0)
old = [record_decision("T", "R", now=NOW - timedelta(days=20))]
check("reminder_after_delay", len(needs_outcome_reminder(old, now=NOW)) == 1)

# Test 11: reflectionSeed basic
d = record_decision("Take new job?", "I want growth.", now=NOW - timedelta(days=10))
seed = reflection_seed(d, now=NOW)
check("seed_text_matches_reasoning", seed["text"] == "I want growth.")
check("seed_days_ago_correct", seed["days_ago"] == 10)
check("seed_domains_match", seed["domains"] == [])

# Test 12: seed with outcome
d = record_decision("X", "Y", now=NOW - timedelta(days=20))
d = record_outcome(d, "It worked.", now=NOW)
seed = reflection_seed(d, now=NOW)
check("seed_includes_outcome", "Outcome: It worked." in seed["text"])

# Test 13: seed without outcome doesn't have "Outcome:" string
d = record_decision("X", "Y", now=NOW - timedelta(days=20))
seed = reflection_seed(d, now=NOW)
check("seed_no_outcome_string", "Outcome:" not in seed["text"])

# Test 14: relevantDecisions lexical
d1 = record_decision(
    "Should I move to Berlin?", "Career growth opportunity in Berlin.",
    now=NOW - timedelta(days=30)
)
d2 = record_decision(
    "Should I buy a new car?", "Reliability concerns with current vehicle.",
    now=NOW - timedelta(days=20)
)
rel = relevant_decisions("I'm thinking about a career move", [d1, d2], now=NOW)
check("relevant_decisions_lexical",
      len(rel) >= 1 and rel[0][0].title.startswith("Should I move"),
      f"got {rel}")

# Test 15: relevantDecisions top N by score
records = [
    record_decision(f"About career move {i}", f"Career thinking {i}", now=NOW - timedelta(days=10+i))
    for i in range(5)
]
rel = relevant_decisions("career move", records, now=NOW, limit=2)
check("relevant_top_n_cap", len(rel) == 2)

# Test 16: domain tag bonus — use a prompt that lexically overlaps with reasoning
with_domain = record_decision(
    "Career decision", "Thinking about career growth and opportunities.",
    domain_tags=["Career"], now=NOW - timedelta(days=30)
)
without_domain = record_decision(
    "Career decision", "Thinking about career growth and opportunities.",
    domain_tags=[], now=NOW - timedelta(days=30)
)
rel_with = relevant_decisions("career growth opportunities", [with_domain], now=NOW)
rel_without = relevant_decisions("career growth opportunities", [without_domain], now=NOW)
check("domain_bonus_both_return",
      len(rel_with) == 1 and len(rel_without) == 1,
      f"with={rel_with}, without={rel_without}")
if rel_with and rel_without:
    check("domain_bonus_increases_score",
          rel_with[0][1] > rel_without[0][1],
          f"with={rel_with[0][1]:.3f}, without={rel_without[0][1]:.3f}")

# Test 17: unrelated prompt returns empty
d = record_decision("About X", "Y", now=NOW - timedelta(days=10))
rel = relevant_decisions("completely unrelated query xyz", [d], now=NOW)
check("unrelated_returns_empty", len(rel) == 0)

# Test 18: stats
records = [
    record_decision(f"T{i}", "R", confidence=0.5 + i * 0.1, now=NOW - timedelta(days=20))
    for i in range(3)
]
records[0] = record_outcome(records[0], "A", now=records[0].decided_at + timedelta(days=10))
records[1] = record_outcome(records[1], "B", now=records[1].decided_at + timedelta(days=15))
s = compute_stats(records)
check("stats_total", s.total_decisions == 3)
check("stats_with_outcomes", s.with_outcomes == 2)
check("stats_avg_days", s.average_days_to_outcome == 12.5)  # (10+15)/2
check("stats_avg_confidence", abs(s.average_confidence - 0.6) < 1e-9)  # (0.5+0.6+0.7)/3

# Test 19: stats empty
s_empty = compute_stats([])
check("stats_empty", s_empty.total_decisions == 0 and s_empty.with_outcomes == 0)

# Test 20: record returns right fields
d = record_decision(
    "Title", "Reasoning",
    options_considered=["A", "B"],
    expected_outcome="Win",
    confidence=0.8,
    domain_tags=["Self"],
    referenced_entity_ids=["e1"],
    is_private=True,
    now=NOW
)
check("record_returns_id", isinstance(d.id, str) and len(d.id) == 36)
check("record_title", d.title == "Title")
check("record_reasoning", d.reasoning == "Reasoning")
check("record_options", d.options_considered == ["A", "B"])
check("record_expected_outcome", d.expected_outcome == "Win")
check("record_confidence", d.confidence_at_decision == 0.8)
check("record_domains", d.domain_tags == ["Self"])
check("record_refs", d.referenced_entity_ids == ["e1"])
check("record_is_private", d.is_private)
check("record_no_outcome", d.actual_outcome is None)

# Test 21: recordOutcome preserves fields
d = record_decision("Title", "Reasoning",
                    options_considered=["A"],
                    expected_outcome="Win",
                    confidence=0.7,
                    domain_tags=["Self"],
                    now=NOW)
d_updated = record_outcome(d, "It worked.", now=NOW + timedelta(days=5))
check("outcome_preserves_title", d_updated.title == d.title)
check("outcome_preserves_reasoning", d_updated.reasoning == d.reasoning)
check("outcome_preserves_options", d_updated.options_considered == d.options_considered)
check("outcome_preserves_confidence", d_updated.confidence_at_decision == d.confidence_at_decision)
check("outcome_preserves_domains", d_updated.domain_tags == d.domain_tags)
check("outcome_sets_actual", d_updated.actual_outcome == "It worked.")
check("outcome_sets_recorded_at", d_updated.outcome_recorded_at == NOW + timedelta(days=5))

# Test 22: attributes preserved (default empty)
d = record_decision("T", "R", now=NOW)
check("attributes_empty_default", d.attributes == {})

# Test 23: isPrivate defaults true
d = record_decision("T", "R", now=NOW)
check("is_private_default_true", d.is_private)

# Test 24: needsOutcomeReminder skips records with outcomes
records = [
    record_decision("T", "R", now=NOW - timedelta(days=20))
]
records[0] = record_outcome(records[0], "Done", now=NOW - timedelta(days=10))
reminders = needs_outcome_reminder(records, now=NOW)
check("reminder_skipped_with_outcome", len(reminders) == 0)

# Test 25: seed text trims reasoning
d = record_decision("T", "  Padded reasoning.  ", now=NOW)
seed = reflection_seed(d, now=NOW)
check("seed_trims_reasoning", seed["text"] == "Padded reasoning.")


# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------

print()
print("=" * 70)
print("DecisionLog Linux validation")
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
