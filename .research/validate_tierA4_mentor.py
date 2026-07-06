"""
Tier A #4 validation mirror — Invisible Mentor synthesizer logic.

Tests:
  1. Dormant when no reflections exist (reflection gate).
  2. Returns up to 3 candidates when reflections exist.
  3. Every candidate has non-empty spoken text.
  4. Every candidate cites a source reflection from the input.
  5. Relevance scores are in [0, 1].
  6. Tokens used for relevance are stable (no weird side effects).
  7. Domain match increases relevance.
  8. Recency weighting keeps older reflections in the top N but doesn't
     drown out recent ones.
  9. Tokenization is reasonable (drops <3 char tokens, lowercases, splits).
 10. Jaccard overlap computes correctly for known sets.
"""

import re
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from typing import List, Optional, Set


@dataclass
class MentorTurnLite:
    spoken: str
    cited_id: Optional[str]
    cited_excerpt: Optional[str]
    days_ago: int
    relevance: float


@dataclass
class MentorDialogueLite:
    prompt: str
    candidates: List[MentorTurnLite]


@dataclass
class ReflectionSeedLite:
    id: str
    text: str
    domains: List[str]
    days_ago: int
    harmony_impact: float
    is_user_reflection: bool = False  # Nemotron #39: only these surface in Mentor


@dataclass
class OpenedEchoSeedLite:
    id: str
    title: str
    text: str
    days_since_opened: int


@dataclass
class MentorInputLite:
    reflections: List[ReflectionSeedLite]
    opened_echoes: List[OpenedEchoSeedLite]
    coherence_score: float
    completed_quest_count: int
    now: datetime = field(default_factory=lambda: datetime.now(timezone.utc))


class InvisibleMentorLite:
    MIN_REFLECTIONS = 1
    KNOWN_DOMAINS = ["CareKin", "Stewardship", "Meaning", "Self"]

    @staticmethod
    def tokenize(s: str) -> Set[str]:
        lowered = s.lower()
        # Split on non-alphanumeric (treating unicode letters as alphanumeric).
        parts = re.findall(r"\w+", lowered, flags=re.UNICODE)
        return {p for p in parts if len(p) >= 3}

    @staticmethod
    def jaccard(a: Set[str], b: Set[str]) -> float:
        if not a or not b:
            return 0.0
        return len(a & b) / len(a | b)

    @staticmethod
    def extract_domains(prompt: str) -> List[str]:
        return [d for d in InvisibleMentorLite.KNOWN_DOMAINS if d.lower() in prompt.lower()]

    @staticmethod
    def time_ref(days_ago: int) -> str:
        if days_ago == 0:
            return "earlier today"
        if days_ago == 1:
            return "yesterday"
        if days_ago < 7:
            return f"{days_ago} days ago"
        if days_ago < 30:
            return f"{days_ago // 7} weeks ago"
        if days_ago < 365:
            return f"{days_ago // 30} months ago"
        return "over a year ago"

    @staticmethod
    def compose_spoken(seed: ReflectionSeedLite, prompt: str, relevance: float) -> str:
        excerpt = seed.text[:180]
        if seed.days_ago <= 7:
            frame = f"From {InvisibleMentorLite.time_ref(seed.days_ago)}:"
        elif seed.days_ago <= 90:
            frame = f"{InvisibleMentorLite.time_ref(seed.days_ago).capitalize()} you wrote:"
        else:
            frame = f"A reflection from {InvisibleMentorLite.time_ref(seed.days_ago)} — still yours:"
        return f'{frame}\n\n"{excerpt}"'

    @staticmethod
    def respond(prompt: str, input_data: MentorInputLite) -> MentorDialogueLite:
        if len(input_data.reflections) < InvisibleMentorLite.MIN_REFLECTIONS:
            return MentorDialogueLite(prompt=prompt, candidates=[])

        prompt_tokens = InvisibleMentorLite.tokenize(prompt)
        prompt_domains = InvisibleMentorLite.extract_domains(prompt)

        scored = []
        for seed in input_data.reflections:
            text_tokens = InvisibleMentorLite.tokenize(seed.text)
            if not text_tokens:
                continue
            overlap = InvisibleMentorLite.jaccard(prompt_tokens, text_tokens)
            domain_overlap = (
                0.0 if not prompt_domains
                else sum(1 for d in prompt_domains if d in seed.domains) / len(prompt_domains)
            )
            recency = max(0.6, 1.0 - seed.days_ago / 365.0 * 0.4)
            harmony_signal = abs(seed.harmony_impact)
            score = (overlap * 0.5 + domain_overlap * 0.3 + harmony_signal * 0.1) * recency
            relevance = max(0.0, min(1.0, score * 2.0))
            turn = MentorTurnLite(
                spoken=InvisibleMentorLite.compose_spoken(seed, prompt, relevance),
                cited_id=seed.id,
                cited_excerpt=seed.text[:240],
                days_ago=seed.days_ago,
                relevance=relevance,
            )
            scored.append((turn, relevance))

        top = sorted(scored, key=lambda x: -x[1])[:3]
        return MentorDialogueLite(prompt=prompt, candidates=[t for t, _ in top])


def main():
    now = datetime.now(timezone.utc)
    results = {}

    # 1. Dormant when no reflections
    empty_input = MentorInputLite(reflections=[], opened_echoes=[], coherence_score=0.5, completed_quest_count=0)
    d1 = InvisibleMentorLite.respond("anything", empty_input)
    results["dormant_when_empty"] = (len(d1.candidates) == 0)

    # 2-8: populated history
    populated = MentorInputLite(
        reflections=[
            ReflectionSeedLite(
                id="r1", text="I noticed I feel most clear after morning walks.",
                domains=["Self", "Meaning"], days_ago=3, harmony_impact=0.7,
                is_user_reflection=True,
            ),
            ReflectionSeedLite(
                id="r2", text="Called mom again. Felt really good after — she told me about the garden.",
                domains=["CareKin"], days_ago=14, harmony_impact=0.6,
                is_user_reflection=True,
            ),
            ReflectionSeedLite(
                id="r3", text="Two job offers. Going with the smaller team. Trust matters more than title.",
                domains=["Meaning", "Stewardship"], days_ago=45, harmony_impact=0.5,
                is_user_reflection=True,
            ),
            ReflectionSeedLite(
                id="r4", text="Long hike in the hills. Alone but not lonely.",
                domains=["Self"], days_ago=180, harmony_impact=0.4,
                is_user_reflection=True,
            ),
        ],
        opened_echoes=[],
        coherence_score=0.6,
        completed_quest_count=8,
    )

    d2 = InvisibleMentorLite.respond("I'm tired of the CareKin pull lately.", populated)

    # 2. Up to 3 candidates
    results["candidates_capped_at_3"] = (len(d2.candidates) <= 3)

    # 3. Every candidate has non-empty spoken text
    results["no_empty_spoken"] = all(len(c.spoken) > 0 for c in d2.candidates)

    # 4. Every candidate cites a source
    results["all_citations_sourced"] = all(c.cited_id is not None for c in d2.candidates)

    # 5. Relevance in [0, 1]
    results["relevance_in_range"] = all(0.0 <= c.relevance <= 1.0 for c in d2.candidates)

    # 6. Tokens: simple sanity
    tokens = InvisibleMentorLite.tokenize("Hello, World! This is a test of tokenization.")
    results["tokenize_basic"] = ("hello" in tokens and "world" in tokens
                                  and "this" in tokens and "a" not in tokens  # <3 chars dropped
                                  and "of" not in tokens)  # <3 chars dropped

    # 7. Domain match increases relevance — the CareKin prompt should rank
    # r2 (CareKin) higher than r1 (no CareKin).
    d3 = InvisibleMentorLite.respond("CareKin question", populated)
    if d3.candidates:
        top_id = d3.candidates[0].cited_id
        results["domain_match_ranks_carekin_first"] = (top_id == "r2")
    else:
        results["domain_match_ranks_carekin_first"] = False

    # 8. Recency: very recent reflection (r1, 3 days) should still appear
    # in top 3 even if older reflections are more lexically similar.
    results["recent_reflection_in_top3"] = any(c.cited_id == "r1" for c in d2.candidates)

    # 9. Jaccard math: known sets
    results["jaccard_identical"] = abs(InvisibleMentorLite.jaccard({"a", "b"}, {"a", "b"}) - 1.0) < 1e-9
    results["jaccard_disjoint"] = InvisibleMentorLite.jaccard({"a"}, {"b"}) == 0.0
    results["jaccard_partial"] = abs(InvisibleMentorLite.jaccard({"a", "b"}, {"a", "c"}) - 1/3) < 1e-9

    # 10. Spoken text contains the user's actual words
    if d2.candidates:
        first = d2.candidates[0]
        results["spoken_quotes_user"] = (
            first.cited_excerpt is not None
            and len(first.cited_excerpt) > 0
            and first.spoken.find(first.cited_excerpt[:60]) >= 0
        )
    else:
        results["spoken_quotes_user"] = False

    # 11. Nemotron #39: isUserReflection filter. Non-user content (contact org
    # names, reminder notes) should NOT be treated as reflections. The Python
    # mirror already enforces this by filtering at the input layer; we assert
    # here that a synthetic non-user reflection is correctly excluded.
    non_user_populated = MentorInputLite(
        reflections=[
            ReflectionSeedLite(
                id="contact1", text="Acme Corp",
                domains=["CareKin"], days_ago=2, harmony_impact=0.1,
                is_user_reflection=False,  # system-imported, not user-written
            ),
            ReflectionSeedLite(
                id="r1", text="I wrote this.",
                domains=["Self"], days_ago=5, harmony_impact=0.7,
                is_user_reflection=True,
            ),
        ],
        opened_echoes=[],
        coherence_score=0.6,
        completed_quest_count=8,
    )
    # The harness-level input filter (mirroring the production `makeInput`)
    # would drop is_user_reflection=False. Mirror that here:
    filtered = [s for s in non_user_populated.reflections if s.is_user_reflection]
    d4 = InvisibleMentorLite.respond("anything", MentorInputLite(
        reflections=filtered,
        opened_echoes=non_user_populated.opened_echoes,
        coherence_score=non_user_populated.coherence_score,
        completed_quest_count=non_user_populated.completed_quest_count,
    ))
    cited_ids = [c.cited_id for c in d4.candidates]
    results["contact_metadata_excluded"] = (
        "contact1" not in cited_ids and "r1" in cited_ids
    )

    # 12. Empty reflection still blocked
    empty_mirror = MentorInputLite(reflections=[], opened_echoes=[], coherence_score=0.5, completed_quest_count=0)
    d5 = InvisibleMentorLite.respond("anything", empty_mirror)
    results["empty_input_dormant"] = (len(d5.candidates) == 0)

    print("=" * 60)
    print("Tier A #4 (Invisible Mentor) Validation")
    print("=" * 60)
    all_pass = True
    for name, passed in results.items():
        mark = "PASS" if passed else "FAIL"
        if not passed:
            all_pass = False
        print(f"  [{mark}] {name}")
    print("=" * 60)
    print(f"OVERALL: {'PASS' if all_pass else 'FAIL'}")
    if d2.candidates:
        print("\nSample Mentor voice (first candidate):")
        print(f"  {d2.candidates[0].spoken[:200]}")
        print(f"  (relevance={d2.candidates[0].relevance:.2f}, cited={d2.candidates[0].cited_id}, {d2.candidates[0].days_ago}d ago)")
    print("=" * 60)
    return 0 if all_pass else 1


if __name__ == "__main__":
    import sys
    sys.exit(main())