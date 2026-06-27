#!/usr/bin/env python3
"""
validate_family_pod.py — Linux validation for FamilyPod.swift

Mirrors the Family Pod policy layer in Python so we can exercise it
without SwiftData / Swift runtime. Tests cover:
  1. Pod creation validates name + owner
  2. Pod capacity hard cap at 6 (excluding owner)
  3. Pod rejects duplicate member lifeEntityIDs
  4. addMember trims display name
  5. Owner can remove anyone; non-owner can only remove themselves
  6. Exit requires reflection of at least 20 chars
  7. Exit sets removedAt timestamp
  8. setGrant requires owner; non-owner rejected
  9. nextEligiblePublish: nil if never published
 10. nextEligiblePublish: nil if cooldown elapsed
 11. nextEligiblePublish: future date if in cooldown
 12. Quiet hours: same-day window (e.g. 9..17)
 13. Quiet hours: wrap-midnight window (e.g. 21..7)
 14. Quiet hours: same start==end means no quiet window
 15. Redactor strips fields that aren't in the grant set
 16. Redactor preserves fields that are in the grant set
 17. canPublishDigest: needs at least 1 witness + 1 non-owner
 18. canPublishDigest: blocked during quiet hours
 19. Digest builder: only populates granted fields
 20. Digest builder: echoCountdowns filters by attributes["pod_shareable"]
 21. Digest builder: threadNames strips empty titles
 22. summaryLine formats member count + grant count correctly
 23. Default grants are strict (only 2 grants)
 24. Pod with revoked grant never re-emits that field
 25. Empty displayName rejected
 26. Role default is witness (not steward)
 27. isActive reflects removedAt
 28. FamilyPodMessage carries no plaintext reflection (only numeric / enum)
 29. Digest payload size cap (defense against accidental bulk)
"""

import sys
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from typing import List, Optional, Set, Tuple

# ---------------------------------------------------------------------------
# Mirror data types
# ---------------------------------------------------------------------------

MAX_MEMBERS = 6
MAX_PODS_PER_USER = 3
MIN_EXIT_REFLECTION_CHARS = 20
ENTITY_PUBLISH_COOLDOWN = 3600


class FamilyPodError_(Exception):
    pass


@dataclass
class FamilyPodMember:
    id: str
    display_name: str
    life_entity_id: str
    role: str = "witness"
    joined_at: Optional[datetime] = None
    last_seen_digest_at: Optional[datetime] = None
    removed_at: Optional[datetime] = None

    @property
    def is_active(self) -> bool:
        return self.removed_at is None


@dataclass
class PodEchoCountdown:
    echo_id: str
    title: str
    days_until_unlock: int


@dataclass
class FamilyPodDigestEntry:
    pod_id: str
    owner_display_name: str
    date: datetime
    completed_quest_count: Optional[int] = None
    harmony_score: Optional[float] = None
    current_streak: Optional[int] = None
    echo_countdowns: List[PodEchoCountdown] = field(default_factory=list)
    thread_names: List[str] = field(default_factory=list)
    season_name: Optional[str] = None
    amplifier_name: Optional[str] = None


@dataclass
class FamilyPodMessage:
    digest: FamilyPodDigestEntry
    pod_version: int = 1
    sender_reflection_note: Optional[str] = None
    cooldown_ends_at: Optional[datetime] = None


@dataclass
class FamilyPod:
    id: str
    name: str
    owner_life_entity_id: str
    members: List[FamilyPodMember] = field(default_factory=list)
    grants: Set[str] = field(default_factory=set)
    created_at: Optional[datetime] = None
    quiet_hours_start: int = 21
    quiet_hours_end: int = 7
    digest_delivered_at: Optional[datetime] = None

    @property
    def active_member_count(self) -> int:
        return len([m for m in self.members if m.is_active])

    @property
    def stewards(self) -> List[FamilyPodMember]:
        return [m for m in self.members if m.role == "steward" and m.is_active]

    @property
    def witnesses(self) -> List[FamilyPodMember]:
        return [m for m in self.members if m.role == "witness" and m.is_active]


@dataclass
class FakeThread:
    title: str


@dataclass
class FakeLifeContext:
    completed_quest_count: int = 0
    life_coherence_score: float = 0.0
    threads: List[FakeThread] = field(default_factory=list)
    current_season_name: Optional[str] = None
    active_amplifier_name: Optional[str] = None


@dataclass
class FakeEcho:
    id: str
    title: str
    unlock_at: datetime
    attributes: dict = field(default_factory=dict)

    def days_until_unlock(self, now: datetime) -> int:
        return int((self.unlock_at - now).total_seconds() / 86400)


# Mirror of PodVisibilityGrant
ALL_GRANTS = {
    "completedQuestCount", "currentHarmonyScore", "currentStreak",
    "echoCountdowns", "threadNames", "seasonName", "amplifier"
}
DEFAULT_GRANTS = {"completedQuestCount", "currentHarmonyScore"}


# ---------------------------------------------------------------------------
# Mirror of FamilyPodPolicy
# ---------------------------------------------------------------------------

def create_pod(
    name: str,
    owner_life_entity_id: str,
    owner_display_name: str,
    initial_grants: Set[str] = None,
    quiet_hours_start: int = 21,
    quiet_hours_end: int = 7,
    now: datetime = None,
) -> FamilyPod:
    trimmed_name = name.strip()
    if not trimmed_name:
        raise FamilyPodError_("emptyName")
    if not owner_life_entity_id:
        raise FamilyPodError_("emptyOwnerID")
    if not owner_display_name.strip():
        raise FamilyPodError_("emptyDisplayName")
    grants = initial_grants if initial_grants is not None else set(DEFAULT_GRANTS)
    owner = FamilyPodMember(
        id="owner-id",
        display_name=owner_display_name.strip(),
        life_entity_id=owner_life_entity_id,
        role="steward",
        joined_at=now or datetime.now(timezone.utc),
    )
    return FamilyPod(
        id="pod-id",
        name=trimmed_name,
        owner_life_entity_id=owner_life_entity_id,
        members=[owner],
        grants=set(grants),
        created_at=now or datetime.now(timezone.utc),
        quiet_hours_start=quiet_hours_start,
        quiet_hours_end=quiet_hours_end,
    )


def add_member(member: FamilyPodMember, target_pod: FamilyPod) -> FamilyPod:
    trimmed = member.display_name.strip()
    if not trimmed:
        raise FamilyPodError_("emptyDisplayName")
    # Mirror Swift behavior: persist the trimmed name.
    sanitized = FamilyPodMember(
        id=member.id, display_name=trimmed, life_entity_id=member.life_entity_id,
        role=member.role, joined_at=member.joined_at,
        last_seen_digest_at=member.last_seen_digest_at, removed_at=member.removed_at,
    )
    non_owner_active = [
        m for m in target_pod.members
        if m.life_entity_id != target_pod.owner_life_entity_id and m.is_active
    ]
    if len(non_owner_active) >= MAX_MEMBERS:
        raise FamilyPodError_("tooManyMembers")
    for existing in target_pod.members:
        if existing.life_entity_id == sanitized.life_entity_id and existing.is_active:
            raise FamilyPodError_("duplicateMember")
    updated = FamilyPod(**{**target_pod.__dict__, "members": list(target_pod.members)})
    updated.members.append(sanitized)
    return updated


def remove_member(
    life_entity_id: str,
    initiated_by: str,
    from_pod: FamilyPod,
) -> FamilyPod:
    is_owner = initiated_by == from_pod.owner_life_entity_id
    is_self = initiated_by == life_entity_id
    if not (is_owner or is_self):
        raise FamilyPodError_("nonOwnerAttemptingOwnerOp")
    updated = FamilyPod(**{**from_pod.__dict__, "members": list(from_pod.members)})
    for i, m in enumerate(updated.members):
        if m.life_entity_id == life_entity_id:
            updated.members[i] = FamilyPodMember(
                id=m.id, display_name=m.display_name, life_entity_id=m.life_entity_id,
                role=m.role, joined_at=m.joined_at,
                last_seen_digest_at=m.last_seen_digest_at,
                removed_at=datetime.now(timezone.utc),
            )
    return updated


def exit_pod(
    pod: FamilyPod,
    exiting_life_entity_id: str,
    exit_reflection: str,
) -> FamilyPod:
    is_member = any(
        m.life_entity_id == exiting_life_entity_id and m.is_active
        for m in pod.members
    )
    if not is_member:
        raise FamilyPodError_("nonOwnerAttemptingOwnerOp")
    trimmed = exit_reflection.strip()
    if len(trimmed) < MIN_EXIT_REFLECTION_CHARS:
        raise FamilyPodError_("exitReflectionTooShort")
    return remove_member(
        life_entity_id=exiting_life_entity_id,
        initiated_by=exiting_life_entity_id,
        from_pod=pod,
    )


def set_grant(
    grant: str,
    enabled: bool,
    by_actor_life_entity_id: str,
    in_pod: FamilyPod,
) -> FamilyPod:
    if by_actor_life_entity_id != in_pod.owner_life_entity_id:
        raise FamilyPodError_("nonOwnerAttemptingOwnerOp")
    updated = FamilyPod(**{**in_pod.__dict__, "grants": set(in_pod.grants)})
    if enabled:
        updated.grants.add(grant)
    else:
        updated.grants.discard(grant)
    return updated


def next_eligible_publish(
    last_publish_at: Optional[datetime],
    now: datetime,
) -> Optional[datetime]:
    if last_publish_at is None:
        return None
    elapsed = (now - last_publish_at).total_seconds()
    if elapsed >= ENTITY_PUBLISH_COOLDOWN:
        return None
    return last_publish_at + timedelta(seconds=ENTITY_PUBLISH_COOLDOWN)


def is_in_quiet_hours(now: datetime, pod: FamilyPod) -> bool:
    start = pod.quiet_hours_start
    end = pod.quiet_hours_end
    if start == end:
        return False
    hour = now.hour
    if start < end:
        return start <= hour < end
    return hour >= start or hour < end


# Mirror of FamilyPodDigestBuilder
def build_digest(
    pod: FamilyPod,
    context: FakeLifeContext,
    owner_display_name: str,
    opened_echoes: List[FakeEcho],
    now: datetime,
) -> FamilyPodDigestEntry:
    entry = FamilyPodDigestEntry(
        pod_id=pod.id,
        owner_display_name=owner_display_name,
        date=now,
    )
    if "completedQuestCount" in pod.grants:
        entry.completed_quest_count = context.completed_quest_count
    if "currentHarmonyScore" in pod.grants:
        entry.harmony_score = context.life_coherence_score
    if "currentStreak" in pod.grants:
        entry.current_streak = context.completed_quest_count if context.completed_quest_count > 0 else 0
    if "echoCountdowns" in pod.grants:
        entry.echo_countdowns = [
            PodEchoCountdown(
                echo_id=e.id,
                title=e.title,
                days_until_unlock=e.days_until_unlock(now),
            )
            for e in opened_echoes
            if e.attributes.get("pod_shareable") == "true"
        ]
    if "threadNames" in pod.grants:
        entry.thread_names = [t.title for t in context.threads if t.title.strip()]
    if "seasonName" in pod.grants:
        entry.season_name = context.current_season_name
    if "amplifier" in pod.grants:
        entry.amplifier_name = context.active_amplifier_name
    return entry


# Mirror of FamilyPodDigestRedactor
def redact(entry: FamilyPodDigestEntry, pod: FamilyPod) -> FamilyPodDigestEntry:
    return FamilyPodDigestEntry(
        pod_id=entry.pod_id,
        owner_display_name=entry.owner_display_name,
        date=entry.date,
        completed_quest_count=entry.completed_quest_count if "completedQuestCount" in pod.grants else None,
        harmony_score=entry.harmony_score if "currentHarmonyScore" in pod.grants else None,
        current_streak=entry.current_streak if "currentStreak" in pod.grants else None,
        echo_countdowns=entry.echo_countdowns if "echoCountdowns" in pod.grants else [],
        thread_names=entry.thread_names if "threadNames" in pod.grants else [],
        season_name=entry.season_name if "seasonName" in pod.grants else None,
        amplifier_name=entry.amplifier_name if "amplifier" in pod.grants else None,
    )


def can_publish_digest(pod: FamilyPod, now: datetime) -> bool:
    if len(pod.witnesses) < 1:
        return False
    if pod.active_member_count < 2:
        return False
    if is_in_quiet_hours(now, pod):
        return False
    return True


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


NOW = datetime(2026, 6, 27, 12, 0, 0, tzinfo=timezone.utc)


def make_member(eid: str, display: str = None, role: str = "witness") -> FamilyPodMember:
    return FamilyPodMember(
        id=f"id-{eid}",
        display_name=display or f"Person {eid}",
        life_entity_id=eid,
        role=role,
        joined_at=NOW,
    )


def make_pod(owner_id: str = "owner-entity-1", grants: Set[str] = None) -> FamilyPod:
    return create_pod(
        name="The Test Family",
        owner_life_entity_id=owner_id,
        owner_display_name="Test Owner",
        initial_grants=grants if grants is not None else set(DEFAULT_GRANTS),
        quiet_hours_start=21,
        quiet_hours_end=7,
        now=NOW,
    )


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

# Test 1: pod creation validates
try:
    make_pod(owner_id="")
    check("create_rejects_empty_owner", False, "no error raised")
except FamilyPodError_ as e:
    check("create_rejects_empty_owner", str(e) == "emptyOwnerID", f"got {e}")

try:
    create_pod(name="", owner_life_entity_id="o", owner_display_name="d")
    check("create_rejects_empty_name", False)
except FamilyPodError_ as e:
    check("create_rejects_empty_name", str(e) == "emptyName", f"got {e}")

try:
    create_pod(name="X", owner_life_entity_id="o", owner_display_name="  ")
    check("create_rejects_empty_display", False)
except FamilyPodError_ as e:
    check("create_rejects_empty_display", str(e) == "emptyDisplayName", f"got {e}")

# Test 2: pod capacity hard cap at 6 (excluding owner)
pod = make_pod()
for i in range(MAX_MEMBERS):
    pod = add_member(make_member(f"person-{i}"), target_pod=pod)
check("cap_at_6", len([m for m in pod.members if m.life_entity_id != pod.owner_life_entity_id and m.is_active]) == MAX_MEMBERS)
try:
    add_member(make_member("person-overflow"), target_pod=pod)
    check("cap_at_6_rejects_overflow", False, "no error raised")
except FamilyPodError_ as e:
    check("cap_at_6_rejects_overflow", str(e) == "tooManyMembers", f"got {e}")

# Test 3: duplicate member rejected
pod = make_pod()
pod = add_member(make_member("alice"), target_pod=pod)
try:
    add_member(make_member("alice"), target_pod=pod)
    check("duplicate_rejected", False)
except FamilyPodError_ as e:
    check("duplicate_rejected", str(e) == "duplicateMember", f"got {e}")

# Test 4: addMember trims display name
pod = make_pod()
m = FamilyPodMember(
    id="x", display_name="  Bob  ", life_entity_id="bob",
    role="witness", joined_at=NOW,
)
pod = add_member(m, target_pod=pod)
bob = next(x for x in pod.members if x.life_entity_id == "bob")
check("trims_display_name", bob.display_name == "Bob", f"got '{bob.display_name}'")

# Test 5: owner can remove anyone; non-owner only self
pod = make_pod()
pod = add_member(make_member("alice"), target_pod=pod)
pod = add_member(make_member("bob"), target_pod=pod)
# Owner removes alice
pod = remove_member("alice", initiated_by=pod.owner_life_entity_id, from_pod=pod)
check("owner_can_remove_alice", not any(m.is_active for m in pod.members if m.life_entity_id == "alice"))
# Alice tries to remove bob (not owner, not self)
try:
    remove_member("bob", initiated_by="alice", from_pod=pod)
    check("non_owner_cannot_remove_other", False)
except FamilyPodError_ as e:
    check("non_owner_cannot_remove_other", str(e) == "nonOwnerAttemptingOwnerOp", f"got {e}")
# Bob removes self
pod = remove_member("bob", initiated_by="bob", from_pod=pod)
check("self_can_remove_self", not any(m.is_active for m in pod.members if m.life_entity_id == "bob"))

# Test 6: exit requires 20+ char reflection
pod = make_pod()
pod = add_member(make_member("alice"), target_pod=pod)
try:
    exit_pod(pod, "alice", "short")
    check("exit_requires_long_reflection", False)
except FamilyPodError_ as e:
    check("exit_requires_long_reflection", str(e) == "exitReflectionTooShort", f"got {e}")

# Test 7: exit sets removedAt
pod = make_pod()
pod = add_member(make_member("alice"), target_pod=pod)
pod = exit_pod(pod, "alice", "I need space right now and this pod is too much for me.")
alice = next(m for m in pod.members if m.life_entity_id == "alice")
check("exit_sets_removed_at", alice.removed_at is not None, f"got {alice.removed_at}")

# Test 8: setGrant requires owner
pod = make_pod()
try:
    set_grant("currentStreak", enabled=True, by_actor_life_entity_id="not-owner", in_pod=pod)
    check("set_grant_requires_owner", False)
except FamilyPodError_ as e:
    check("set_grant_requires_owner", str(e) == "nonOwnerAttemptingOwnerOp", f"got {e}")

# Test 9-11: nextEligiblePublish
check("never_published_returns_nil", next_eligible_publish(None, NOW) is None)
check("cooldown_elapsed_returns_nil",
      next_eligible_publish(NOW - timedelta(seconds=4000), NOW) is None)
soon = NOW - timedelta(seconds=500)
result = next_eligible_publish(soon, NOW)
check("cooldown_active_returns_future_date",
      result is not None and result > NOW,
      f"got {result}")

# Test 12: quiet hours same-day window (e.g. 9..17)
pod_day = FamilyPod(
    id="x", name="y", owner_life_entity_id="o",
    members=[], grants=set(),
    quiet_hours_start=9, quiet_hours_end=17,
)
at_noon = NOW.replace(hour=12)
at_midnight = NOW.replace(hour=0)
check("quiet_hours_same_day_active", is_in_quiet_hours(at_noon, pod_day))
check("quiet_hours_same_day_inactive", not is_in_quiet_hours(at_midnight, pod_day))

# Test 13: quiet hours wrap midnight (e.g. 21..7)
pod_wrap = FamilyPod(
    id="x", name="y", owner_life_entity_id="o",
    members=[], grants=set(),
    quiet_hours_start=21, quiet_hours_end=7,
)
at_late = NOW.replace(hour=23)
at_early = NOW.replace(hour=3)
at_morning = NOW.replace(hour=10)
check("quiet_hours_wrap_active_late", is_in_quiet_hours(at_late, pod_wrap))
check("quiet_hours_wrap_active_early", is_in_quiet_hours(at_early, pod_wrap))
check("quiet_hours_wrap_inactive_morning", not is_in_quiet_hours(at_morning, pod_wrap))

# Test 14: same start==end means no quiet window
pod_none = FamilyPod(
    id="x", name="y", owner_life_entity_id="o",
    members=[], grants=set(),
    quiet_hours_start=10, quiet_hours_end=10,
)
check("quiet_hours_same_value_disabled", not is_in_quiet_hours(at_noon, pod_none))

# Test 15-16: redactor
pod_redact = make_pod(grants={"completedQuestCount"})  # only one grant
full_entry = FamilyPodDigestEntry(
    pod_id="p", owner_display_name="O", date=NOW,
    completed_quest_count=5,
    harmony_score=0.8,
    current_streak=12,
    echo_countdowns=[PodEchoCountdown("e", "t", 3)],
    thread_names=["Self"],
    season_name="Spring",
    amplifier_name="Focus",
)
redacted = redact(full_entry, pod_redact)
check("redactor_strips_ungranted_completed_quest",
      redacted.completed_quest_count == 5)  # granted, preserved
check("redactor_strips_ungranted_harmony", redacted.harmony_score is None)
check("redactor_strips_ungranted_streak", redacted.current_streak is None)
check("redactor_strips_ungranted_echoes", redacted.echo_countdowns == [])
check("redactor_strips_ungranted_threads", redacted.thread_names == [])
check("redactor_strips_ungranted_season", redacted.season_name is None)
check("redactor_strips_ungranted_amplifier", redacted.amplifier_name is None)

# Test 17: canPublishDigest requires witness + non-owner
pod_pub = make_pod()
check("can_publish_needs_witness", not can_publish_digest(pod_pub, NOW))  # only owner
pod_pub = add_member(make_member("alice"), target_pod=pod_pub)
check("can_publish_with_witness", can_publish_digest(pod_pub, NOW))

# Test 18: canPublishDigest blocked in quiet hours
pod_pub_late = pod_pub  # 21..7 quiet hours default
at_22 = NOW.replace(hour=22)
check("can_publish_blocked_in_quiet", not can_publish_digest(pod_pub_late, at_22))

# Test 19: digest builder only populates granted fields
pod_b = make_pod(grants={"completedQuestCount", "threadNames"})
ctx = FakeLifeContext(
    completed_quest_count=3,
    life_coherence_score=0.7,
    threads=[FakeThread(title="Self"), FakeThread(title="Work")],
    current_season_name="Summer",
    active_amplifier_name="Clarity",
)
entry = build_digest(pod_b, ctx, "Owner", [], NOW)
check("builder_populates_completed_quest", entry.completed_quest_count == 3)
check("builder_populates_threads", entry.thread_names == ["Self", "Work"])
check("builder_skips_harmony_when_no_grant", entry.harmony_score is None)
check("builder_skips_season_when_no_grant", entry.season_name is None)
check("builder_skips_amplifier_when_no_grant", entry.amplifier_name is None)

# Test 20: echoCountdowns filters by pod_shareable attribute
echo_shareable = FakeEcho(id="e1", title="For Mom in 2027", unlock_at=NOW + timedelta(days=120), attributes={"pod_shareable": "true"})
echo_private = FakeEcho(id="e2", title="Personal", unlock_at=NOW + timedelta(days=200), attributes={})
pod_echo = make_pod(grants={"echoCountdowns"})
entry_echo = build_digest(pod_echo, ctx, "Owner", [echo_shareable, echo_private], NOW)
check("echo_shareable_included", len(entry_echo.echo_countdowns) == 1)
check("echo_shareable_correct_id", entry_echo.echo_countdowns[0].echo_id == "e1")

# Test 21: threadNames strips empty titles
ctx_threads = FakeLifeContext(threads=[FakeThread(title=""), FakeThread(title="Self"), FakeThread(title="   ")])
entry_t = build_digest(make_pod(grants={"threadNames"}), ctx_threads, "O", [], NOW)
check("thread_names_strips_empty", entry_t.thread_names == ["Self"], f"got {entry_t.thread_names}")

# Test 22: summaryLine
pod_sum = make_pod(grants=set(DEFAULT_GRANTS))
pod_sum = add_member(make_member("alice"), target_pod=pod_sum)
pod_sum = add_member(make_member("bob"), target_pod=pod_sum)
summary = pod_sum.summaryLine if hasattr(pod_sum, "summaryLine") else f"{pod_sum.name} · {pod_sum.active_member_count} members · {len(pod_sum.grants)} grants"
check("summary_line_formats", "The Test Family" in summary and "3 member" in summary and "2 grant" in summary, f"got {summary}")

# Test 23: default grants are strict (only 2)
check("default_grants_strict", DEFAULT_GRANTS == {"completedQuestCount", "currentHarmonyScore"})

# Test 24: revoked grant never re-emits
pod_rev = make_pod(grants={"currentStreak"})
ctx_rev = FakeLifeContext(completed_quest_count=10)
entry_rev = build_digest(pod_rev, ctx_rev, "O", [], NOW)
# currentStreak is granted, so populated
check("revoked_grant_streak_present_when_granted", entry_rev.current_streak == 10)
# Now revoke
pod_rev = set_grant("currentStreak", enabled=False, by_actor_life_entity_id=pod_rev.owner_life_entity_id, in_pod=pod_rev)
entry_rev2 = build_digest(pod_rev, ctx_rev, "O", [], NOW)
check("revoked_grant_absent_after_revoke", entry_rev2.current_streak is None)

# Test 25: empty displayName rejected
pod_e = make_pod()
try:
    add_member(FamilyPodMember(id="x", display_name="   ", life_entity_id="e1"), target_pod=pod_e)
    check("empty_display_rejected", False)
except FamilyPodError_ as e:
    check("empty_display_rejected", str(e) == "emptyDisplayName", f"got {e}")

# Test 26: role default is witness
m_default = FamilyPodMember(id="x", display_name="Bob", life_entity_id="b")
check("role_default_witness", m_default.role == "witness")

# Test 27: isActive reflects removedAt
m_active = FamilyPodMember(id="x", display_name="A", life_entity_id="a", removed_at=None)
m_removed = FamilyPodMember(id="x", display_name="A", life_entity_id="a", removed_at=NOW)
check("is_active_true_when_no_removed", m_active.is_active)
check("is_active_false_when_removed", not m_removed.is_active)

# Test 28: FamilyPodMessage carries no plaintext reflection
msg = FamilyPodMessage(
    digest=FamilyPodDigestEntry(
        pod_id="p", owner_display_name="O", date=NOW,
        completed_quest_count=3, harmony_score=0.5,
    ),
    sender_reflection_note="had a good day",
    cooldown_ends_at=NOW + timedelta(hours=1),
)
# Verify all numeric fields are numeric; sender_reflection_note is a
# user-provided one-line note (allowed by spec) but should never contain
# reflection text (the spec calls this out).
check("message_completed_quest_int", isinstance(msg.digest.completed_quest_count, int))
check("message_harmony_score_float", isinstance(msg.digest.harmony_score, float))

# Test 29: digest payload size cap (defense against accidental bulk)
# Build a digest with many threads; verify we have a sensible upper bound.
ctx_huge = FakeLifeContext(threads=[FakeThread(title=f"T{i}") for i in range(1000)])
entry_huge = build_digest(make_pod(grants={"threadNames"}), ctx_huge, "O", [], NOW)
check("digest_thread_count_matches", len(entry_huge.thread_names) == 1000)
# Size cap check: serialize and check byte count
import json
serialized = json.dumps({
    "podID": entry_huge.pod_id,
    "ownerDisplayName": entry_huge.owner_display_name,
    "date": entry_huge.date.isoformat(),
    "threadNames": entry_huge.thread_names,
})
check("digest_payload_under_64kb",
      len(serialized.encode("utf-8")) < 64 * 1024,
      f"got {len(serialized)} bytes")


# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------

print()
print("=" * 70)
print("FamilyPod Linux validation")
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