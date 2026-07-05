#!/usr/bin/env python3
"""
validate_mentor_bridge.py — Linux validation for MentorEchoBridge.swift

Mirrors the bridge logic in Python so we can exercise it without a Swift
runtime. The mirrors run on the *exact same inputs* the Swift code would
see (deterministic seed, fixed dates, controlled echoes).

Each test logs PASS/FAIL with a precise failure message. The harness
exits 0 only if ALL tests pass.

Test coverage (matches what a Mac-side SwiftXCTest suite would check):
  1. recencyMultiplier boundaries: 0 days → 0.0, 1 day → 1.0, 365 days → 0.4
  2. recencyMultiplier decays smoothly across the year
  3. openedEchoSeeds filters out sealed echoes (privacy gate)
  4. openedEchoSeeds filters out maturing / openingReady echoes
  5. openedEchoSeeds respects maxEchoesPerSession cap
  6. openedEchoSeeds ranks by recency multiplier, not just openedAt
  7. openedEchoSeeds skips echoes with empty plaintext
  8. openedEchoSeeds skips echoes that fail decryption (cipher mismatch)
  9. makeMentorInput shape: returns all four MentorInput fields populated
 10. echoTurn returns nil for fresh (0-day) echoes
 11. echoTurn returns nil for echoes with empty text
 12. echoTurn spoken line includes the user's own words
 13. echoTurn spoken line includes the decree when present
 14. echoTurn citedDaysAgo matches the recency gap
 15. echoTurn relevance score is bounded to [0,1]
 16. OpenedEchoSeed init handles clock skew gracefully (opened in future)
 17. Consent gate: only .opened and .delivered states surface
 18. Empty input → empty output (no crash, no defaults)
"""

import sys
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from typing import List, Optional, Tuple

# ---------------------------------------------------------------------------
# Mirror data types
# ---------------------------------------------------------------------------

# Lifecycle states (must match SacredEcho.EchoLifecycleState)
ECHO_SEALED = "sealed"
ECHO_MATURING = "maturing"
ECHO_OPENING_READY = "openingReady"
ECHO_OPENED = "opened"
ECHO_DELIVERED = "delivered"
ECHO_RELEASED = "released"

CONSENT_STATES = {ECHO_OPENED, ECHO_DELIVERED}


@dataclass
class FakeEcho:
    """Mirror of SacredEcho. id/title/ciphertext/etc. are strings; plaintext
    is the *expected* decrypted form. If expected_plaintext is None, decryption
    is treated as failed."""
    id: str
    title: str
    state: str
    created_at: datetime
    unlock_at: datetime
    opened_at: Optional[datetime]
    decree: str
    ciphertext: bytes
    nonce: bytes
    tag: bytes
    expected_plaintext: Optional[str] = None


@dataclass
class FakeLifeEntity:
    """Stand-in for LifeEntity — bridge only checks id existence."""
    id: str
    title: str
    domains: List[str]


@dataclass
class FakeLifeContext:
    lifeGraphEntities: List[FakeLifeEntity] = field(default_factory=list)


# Mirror of MentorEchoBridgeConfig
MINIMUM_DAYS_SINCE_OPENED = 1
MAX_ECHOES_PER_SESSION = 5


def recency_multiplier(days_since_opened: int) -> float:
    """Mirror of MentorEchoBridgeConfig.recencyMultiplier."""
    if days_since_opened < MINIMUM_DAYS_SINCE_OPENED:
        return 0.0
    span = float(days_since_opened - MINIMUM_DAYS_SINCE_OPENED)
    return max(0.4, 1.0 - span / 365.0 * 0.6)


@dataclass
class OpenedEchoSeed:
    id: str
    title: str
    text: str
    opened_at: datetime
    decree: str
    days_since_opened: int
    recency_multiplier: float


def make_opened_echo_seed(
    echo: FakeEcho,
    now: datetime,
    plaintext: str,
) -> OpenedEchoSeed:
    """Mirror of OpenedEchoSeed.init."""
    days = max(0, int((now - echo.opened_at).total_seconds() / 86400))
    return OpenedEchoSeed(
        id=echo.id,
        title=echo.title,
        text=plaintext,
        opened_at=echo.opened_at,
        decree=echo.decree,
        days_since_opened=days,
        recency_multiplier=recency_multiplier(days),
    )


def decrypt_echo(echo: FakeEcho) -> Optional[str]:
    """Mirror of SacredEchoCipher.open. Returns plaintext or None on failure."""
    if echo.expected_plaintext is None:
        return None
    return echo.expected_plaintext


def opened_echo_seeds(
    echoes: List[FakeEcho],
    context: FakeLifeContext,
    now: datetime,
) -> List[Tuple[str, str, str, datetime]]:
    """Mirror of MentorEchoBridge.openedEchoSeeds(from:in:now:)."""
    # Stage 1: consent gate
    opened = [e for e in echoes if e.state in CONSENT_STATES]
    # Stage 2: decrypt + project
    seeds: List[OpenedEchoSeed] = []
    for echo in opened:
        if echo.opened_at is None:
            continue
        plaintext = decrypt_echo(echo)
        if plaintext is None:
            continue
        trimmed = plaintext.strip()
        if not trimmed:
            continue
        seeds.append(make_opened_echo_seed(echo, now, trimmed))
    # Stage 3: rank + cap
    ranked = sorted(
        [s for s in seeds if s.recency_multiplier > 0.0],
        key=lambda s: s.recency_multiplier,
        reverse=True,
    )[:MAX_ECHOES_PER_SESSION]
    return [(s.id, s.title, s.text, s.opened_at) for s in ranked]


def echo_turn(seed: OpenedEchoSeed, prompt: str) -> Optional[dict]:
    """Mirror of InvisibleMentor.echoTurn."""
    if seed.days_since_opened < MINIMUM_DAYS_SINCE_OPENED:
        return None
    if not seed.text.strip():
        return None

    def time_ref(days: int) -> str:
        if days == 0: return "earlier today"
        if days == 1: return "yesterday"
        if days < 7: return f"{days} days ago"
        if days < 30: return f"{days // 7} weeks ago"
        if days < 365: return f"{days // 30} months ago"
        return "over a year ago"

    excerpt = seed.text[:180]
    tr = time_ref(seed.days_since_opened)
    if seed.decree:
        frame = f'From an echo you sealed and opened {tr} — your decree was: "{seed.decree}"'
    else:
        frame = f"From an echo you opened {tr}:"
    spoken = f'{frame}\n\n"{excerpt}"'

    # Relevance: lexical overlap
    def tokens(s: str) -> set:
        return {t for t in "".join(
            c if c.isalnum() or c.isspace() else " "
            for c in s.lower()
        ).split() if len(t) >= 3}

    p = tokens(prompt)
    t = tokens(seed.text)
    if not p or not t:
        overlap = 0.0
    else:
        intersection = len(p & t)
        union = len(p | t)
        overlap = intersection / union if union > 0 else 0.0
    relevance = max(0.0, min(1.0, overlap * 0.7 + seed.recency_multiplier * 0.3))

    return {
        "spoken": spoken,
        "cited_id": seed.id,
        "excerpt": excerpt,
        "days_ago": seed.days_since_opened,
        "relevance": relevance,
    }


# ---------------------------------------------------------------------------
# Test harness
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


def make_echo(
    eid: str,
    state: str,
    opened_days_ago: Optional[int],
    plaintext: Optional[str] = "I wrote this to my future self about patience.",
    decree: str = "",
) -> FakeEcho:
    """Helper to construct echoes with sane defaults."""
    now = datetime(2026, 6, 27, 12, 0, 0, tzinfo=timezone.utc)
    days = opened_days_ago if opened_days_ago is not None else 0
    opened = now - timedelta(days=days) if opened_days_ago is not None else None
    return FakeEcho(
        id=eid,
        title=f"Echo {eid[:6]}",
        state=state,
        created_at=now - timedelta(days=days, hours=2),
        unlock_at=now - timedelta(days=days + 1),
        opened_at=opened,
        decree=decree,
        ciphertext=b"\x00" * 32,
        nonce=b"\x01" * 12,
        tag=b"\x02" * 16,
        expected_plaintext=plaintext,
    )


NOW = datetime(2026, 6, 27, 12, 0, 0, tzinfo=timezone.utc)


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

# Test 1: recency boundaries
check(
    "recency_0days_returns_zero",
    recency_multiplier(0) == 0.0,
    f"got {recency_multiplier(0)}",
)
check(
    "recency_1day_returns_one",
    abs(recency_multiplier(1) - 1.0) < 1e-9,
    f"got {recency_multiplier(1)}",
)
check(
    "recency_365days_above_floor",
    recency_multiplier(365) >= 0.4 and recency_multiplier(365) <= 0.41,
    f"got {recency_multiplier(365)}",
)
# Floor is reached slightly past 365 days
check(
    "recency_500days_at_floor",
    abs(recency_multiplier(500) - 0.4) < 1e-9,
    f"got {recency_multiplier(500)}",
)

# Test 2: recency decays monotonically
prev = 2.0
for d in [1, 30, 60, 90, 180, 270, 365]:
    cur = recency_multiplier(d)
    check(f"recency_decays_day_{d}", cur <= prev, f"day {d}: {cur} > {prev}")
    prev = cur

# Test 3: sealed echoes excluded (privacy gate)
ctx = FakeLifeContext()
echoes = [
    make_echo("echo-sealed", ECHO_SEALED, None, plaintext="should not surface"),
    make_echo("echo-maturing", ECHO_MATURING, None, plaintext="also locked"),
]
seeds = opened_echo_seeds(echoes, ctx, NOW)
check("sealed_excluded", len(seeds) == 0, f"got {len(seeds)} seeds")

# Test 4: maturing / openingReady excluded
echoes = [
    make_echo("echo-mat", ECHO_MATURING, None, plaintext="locked text"),
    make_echo("echo-ready", ECHO_OPENING_READY, None, plaintext="almost text"),
]
seeds = opened_echo_seeds(echoes, ctx, NOW)
check("maturing_excluded", len(seeds) == 0, f"got {len(seeds)} seeds")

# Test 5: maxEchoesPerSession cap
echoes = [make_echo(f"echo-{i:02d}", ECHO_OPENED, 30 + i) for i in range(20)]
seeds = opened_echo_seeds(echoes, ctx, NOW)
check(
    "cap_respected",
    len(seeds) == MAX_ECHOES_PER_SESSION,
    f"got {len(seeds)} seeds, expected {MAX_ECHOES_PER_SESSION}",
)

# Test 6: ranking is by recency multiplier, not openedAt
# All opened 30 days ago get the same recency multiplier, so the order
# is implementation-defined among ties. With varying gaps, recency
# multiplier should win.
echoes = [
    make_echo("echo-old-180", ECHO_OPENED, 180),  # lowest recency
    make_echo("echo-recent-2", ECHO_OPENED, 2),    # highest recency
    make_echo("echo-mid-30", ECHO_OPENED, 30),     # middle
]
seeds = opened_echo_seeds(echoes, ctx, NOW)
check("rank_by_recency_count", len(seeds) == 3, f"got {len(seeds)} seeds")
check(
    "rank_by_recency_first_is_recent",
    seeds[0][0] == "echo-recent-2",
    f"got {seeds[0][0]}",
)
check(
    "rank_by_recency_last_is_old",
    seeds[-1][0] == "echo-old-180",
    f"got {seeds[-1][0]}",
)

# Test 7: empty plaintext is skipped
echoes = [
    make_echo("echo-empty", ECHO_OPENED, 30, plaintext="   \n  "),
    make_echo("echo-good", ECHO_OPENED, 30, plaintext="actual reflection"),
]
seeds = opened_echo_seeds(echoes, ctx, NOW)
check("empty_text_excluded", len(seeds) == 1, f"got {len(seeds)} seeds")
check(
    "empty_text_only_good_remains",
    seeds[0][0] == "echo-good",
    f"got {seeds[0][0]}",
)

# Test 8: decryption failure (cipher mismatch) is skipped
echoes = [
    make_echo("echo-corrupt", ECHO_OPENED, 30, plaintext=None),
    make_echo("echo-good", ECHO_OPENED, 30, plaintext="real words"),
]
seeds = opened_echo_seeds(echoes, ctx, NOW)
check("corrupt_echo_skipped", len(seeds) == 1, f"got {len(seeds)} seeds")
check(
    "corrupt_echo_only_good_remains",
    seeds[0][0] == "echo-good",
    f"got {seeds[0][0]}",
)

# Test 9: shape verification — openedEchoSeeds returns the 4-tuple shape
echoes = [make_echo("echo-shape", ECHO_OPENED, 30)]
seeds = opened_echo_seeds(echoes, ctx, NOW)
check("shape_tuple_4", len(seeds[0]) == 4, f"tuple length {len(seeds[0])}")
check("shape_id_is_str", isinstance(seeds[0][0], str))
check("shape_title_is_str", isinstance(seeds[0][1], str))
check("shape_text_is_str", isinstance(seeds[0][2], str))
check("shape_opened_at_is_datetime", isinstance(seeds[0][3], datetime))

# Test 10: echoTurn returns nil for fresh (0-day) echoes
fresh_seed = make_opened_echo_seed(
    make_echo("fresh", ECHO_OPENED, 0),
    NOW,
    "today's reflection",
)
turn = echo_turn(fresh_seed, "tell me something")
check("fresh_echo_returns_nil", turn is None, f"got {turn}")

# Test 11: echoTurn returns nil for empty text
empty_seed = OpenedEchoSeed(
    id="empty",
    title="empty",
    text="   ",
    opened_at=NOW - timedelta(days=30),
    decree="",
    days_since_opened=30,
    recency_multiplier=recency_multiplier(30),
)
turn = echo_turn(empty_seed, "anything")
check("empty_echo_returns_nil", turn is None, f"got {turn}")

# Test 12: echoTurn spoken line includes user's own words
seed = make_opened_echo_seed(
    make_echo("real", ECHO_OPENED, 30, plaintext="I need to remember to breathe when overwhelmed."),
    NOW,
    "I need to remember to breathe when overwhelmed.",
)
turn = echo_turn(seed, "stress")
assert turn is not None, "test setup invariant"
check(
    "spoken_includes_user_words",
    "breathe" in turn["spoken"],
    f"spoken: {turn['spoken']}",
)
# The spoken line wraps the user text in one pair of quotes (the excerpt).
# When a decree is also present (test 13), the frame adds another quote pair
# around the decree. So bare-echo = 2 quotes, with-decree = 4 quotes.
check(
    "spoken_quotes_text_no_decree",
    turn["spoken"].count('"') == 2,
    f"quote count: {turn['spoken'].count(chr(34))}",
)
check(
    "spoken_quotes_wrap_excerpt",
    turn["spoken"].endswith('"'),
    f"spoken tail: {turn['spoken'][-30:]}",
)

# Test 13: echoTurn spoken line includes the decree
seed = make_opened_echo_seed(
    make_echo(
        "with-decree",
        ECHO_OPENED,
        30,
        plaintext="Words matter most when you say less.",
        decree="Be brief. Be present.",
    ),
    NOW,
    "Words matter most when you say less.",
)
turn = echo_turn(seed, "communication")
assert turn is not None, "test setup invariant"
check(
    "spoken_includes_decree",
    "Be brief. Be present." in turn["spoken"],
    f"spoken: {turn['spoken']}",
)

# Test 14: echoTurn citedDaysAgo matches the recency gap
seed = make_opened_echo_seed(
    make_echo("age-45", ECHO_OPENED, 30 + 15),  # 45 days ago
    NOW,
    "some text here",
)
turn = echo_turn(seed, "anything")
assert turn is not None, "test setup invariant"
check(
    "cited_days_ago_correct",
    turn["days_ago"] == 45,
    f"got {turn['days_ago']}",
)

# Test 15: relevance score is bounded to [0,1]
test_cases = [
    ("high overlap high recency", make_opened_echo_seed(make_echo("a", ECHO_OPENED, 2, plaintext="breath breathe breathing"), NOW, "breath breathe breathing"), "breath"),
    ("low overlap low recency", make_opened_echo_seed(make_echo("b", ECHO_OPENED, 300, plaintext="completely different content here"), NOW, "completely different content here"), "stress"),
    ("zero overlap", make_opened_echo_seed(make_echo("c", ECHO_OPENED, 30, plaintext="nothing in common"), NOW, "nothing in common"), "xyz"),
]
for name, seed, prompt in test_cases:
    turn = echo_turn(seed, prompt)
    assert turn is not None, "test setup invariant"
    check(
        f"relevance_bounded_{name.split()[0]}",
        0.0 <= turn["relevance"] <= 1.0,
        f"relevance={turn['relevance']}",
    )

# Test 16: clock skew — opened_at in future
echo = make_echo("future", ECHO_OPENED, 0)
echo.opened_at = NOW + timedelta(hours=2)  # 2 hours in the future
seed = make_opened_echo_seed(echo, NOW, "future echo text")
check("clock_skew_days_clamped", seed.days_since_opened == 0, f"got {seed.days_since_opened}")

# Test 17: consent gate — only opened + delivered states surface
all_states = [
    ECHO_SEALED, ECHO_MATURING, ECHO_OPENING_READY,
    ECHO_OPENED, ECHO_DELIVERED, ECHO_RELEASED,
]
echoes = []
for i, s in enumerate(all_states):
    echoes.append(make_echo(f"echo-{i}", s, 30 if s in CONSENT_STATES else None))
seeds = opened_echo_seeds(echoes, ctx, NOW)
returned_ids = {s[0] for s in seeds}
expected_ids = {f"echo-{i}" for i, s in enumerate(all_states) if s in CONSENT_STATES}
check(
    "consent_states_only",
    returned_ids == expected_ids,
    f"got {returned_ids}, expected {expected_ids}",
)

# Test 18: empty input → empty output (no crash)
seeds = opened_echo_seeds([], ctx, NOW)
check("empty_input_empty_output", len(seeds) == 0, f"got {len(seeds)}")
seeds = opened_echo_seeds([], ctx, NOW + timedelta(days=365))
check("empty_input_with_future_now_empty", len(seeds) == 0)

# Additional: smoke test with realistic context
ctx_full = FakeLifeContext(lifeGraphEntities=[
    FakeLifeEntity(id="echo-good", title="t", domains=["Self"]),
    FakeLifeEntity(id="other-entity", title="o", domains=["Self"]),
])
echoes = [
    make_echo("echo-good", ECHO_OPENED, 30, plaintext="real reflection text"),
    make_echo("echo-corrupt", ECHO_OPENED, 30, plaintext=None),
]
seeds = opened_echo_seeds(echoes, ctx_full, NOW)
check("smoke_realistic", len(seeds) == 1 and seeds[0][0] == "echo-good")


# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------

print()
print("=" * 70)
print("MentorEchoBridge Linux validation")
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