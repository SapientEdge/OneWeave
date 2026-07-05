# OneWeave Handoff — Cycle 35

**Date:** 2026-06-28
**Branch:** `002-gamification`
**Status:** 4 GLM-driven features shipped. 33/33 validation suites PASS.
**Source:** GLM round-5 creative ideation (`round_5_glm.md`).

---

## TL;DR — what shipped this cycle

| # | Task | Feature | File | LOC |
|---|------|---------|------|-----|
| 1 | **T149** | Mastery Map: Apprentice Knots — tier advancement gated by untying user-logged questions | `Sources/OneWeave/MasteryKnot.swift` (NEW, 217 LOC) | 217 |
| 2 | **T161** | Decision Reverb Half-Life — 30/90/365-day return rates + settled ⚓ glyph + still-open ◇ | `Sources/OneWeave/DecisionLog.swift` (+161) | 161 |
| 3 | **T154** | Mentor's Devil's Advocate — strongest counter-argument from user's *own* past, using TonalLexicon polarity | `Sources/OneWeave/InvisibleMentor.swift` (+140) | 140 |
| 4 | **T153** | Sacred Echo Time Capsule — `EchoKind.timeCapsule` + reflection-prompt gate on auto-unseal | `Sources/OneWeave/SacredEcho.swift` (+93) | 93 |

**One new validator** (`validate_cycle35_glm_features.py`); suite count 32 → **33**, all green.

**Sanity test** (`_sanity_cycle35.py`) confirms:
- Mastery Knots: tier cap correct (0=no cap, 1=current, 2=current-1)
- Decision Reverb: settled (14 first-week, 3 day-30) → hl=30d; still-open (7/12/50/100) → hl=365d; unrated → hl=None
- Devil's Advocate: Socratic prompt "Is this growth, or forgetting?" present
- Time Capsule: `EchoKind.timeCapsule` + `TimeCapsuleInvite` + reflection-prompt gate

---

## T149 — Apprentice Knots (mastery blocker)

### What it does

Each Mastery node can have **knots** — questions the user themselves logged as blockers. Mastery tier advancement is *gated* by untying knots, not by time served:

| Open Knots | Tier Cap |
|------------|----------|
| 0 | no cap (can reach any tier) |
| 1 | capped at current tier (can't advance) |
| 2+ | capped at current tier − 1 (pulls back to apprentice) |

UX: "Self tier awaits 2 knots. You wrote one in February."

### Implementation

New file `Sources/OneWeave/MasteryKnot.swift`:
- `enum KnotState { tied, loosening, untied }`
- `struct ApprenticeKnot { id, domain, question, state, tiedAt, resolvedAt, notes, relatedDecisionID, relatedReflectionText }`
- `struct KnotNote { id, createdAt, text }` — chronological notes while working on a knot
- `enum MasteryKnotEngine`:
  - `maxTier(for:currentTier:knots:)` — the algorithm
  - `openKnotCount(for:knots:)` — fast count for the UI
  - `tierBlockedMessage(for:openKnots:)` — calm framing (never guilt)
  - `untie(_:via:relatedDecisionID:now:)` — transition to `.untied`
  - `loosen(_:)` — transition `.tied → .loosening`

### Why this matters

The existing Mastery tier system advances on quest completion. But completing many low-quality quests shouldn't outpace wrestling with one hard question for weeks. Knots capture the *deliberate struggle*. Constitution §5 (genuine mastery > time-served gamification) is now enforced *at the algorithm level*, not just in copy.

---

## T161 — Decision Reverb Half-Life

### What it does

For each Decision Log entry, track how often the user returns to that decision's thread within 30/90/365 days. The "half-life" is when the 30-day return rate drops below 50% of the first-week rate.

- **Settled decision**: 30-day rate < 50% of first-week → earns the quiet `⚓` glyph
- **Still-open decision**: 30-day rate ≥ 50% of first-week → earns the `◇` glyph; may re-surface at half-life anniversary
- **Unrated**: no first-week returns → `○` glyph

### Implementation

In `Sources/OneWeave/DecisionLog.swift`:
- `struct DecisionReverb { record, firstWeekReturns, day30Returns, day90Returns, day365Returns, halfLifeDays?, isSettled, isStillOpen }`
- `enum DecisionReverbCalculator`:
  - `reverb(for:references:now:)` — counts references in each window
  - `halfLifeAnniversaries(for:referencesByDecisionID:within:now:)` — surfaces upcoming anniversaries

### Sanity test confirms

```
Settled:    14 first-week, 3 day-30  → hl=30d   ✓
Still-open:  7/12/50/100              → hl=365d  ✓
Unrated:      0 returns                → hl=None  ✓
```

### UX

- Settled decisions earn a quiet `⚓` glyph in the log row
- Still-open ones gently re-surface at their half-life anniversary (30d, 90d, or 365d)
- Never awards essence or harmony without a reflection

---

## T154 — Mentor's Devil's Advocate

### What it does

When the user is forming an insight, the Mentor surfaces the strongest counter-argument from the user's **own** past entries:

> 47 days ago you wrote something different. Now you seem to be forming "You prioritize meaning over kin". Is this growth, or forgetting?

The Socratic tradition: the best teacher is your past self.

### Implementation

In `Sources/OneWeave/InvisibleMentor.swift`:
- `struct DevilAdvocateCounter { id, citedReflectionID, citedTextExcerpt, citedDaysAgo, oppositionScore, prompt }`
- `InvisibleMentor.devilAdvocate(currentClaim:domain:pastReflections:limit:)` — algorithm
- `private polarity(of:)` — uses `TonalLexicon.vector(for:)` (cycle 34 cross-module)

### Algorithm

1. Find past reflections sharing `domain` with the current insight
2. Compute lexical overlap (Jaccard) — must be > 0.05 (topically related)
3. Compute polarity distance — `|claim_polar − seed_polar| / 2`
4. Score = `overlap × 0.5 + polarity_distance × 0.5`
5. Skip weak counters (< 0.15)
6. Return top `limit` by score

### Cross-module dependency

Uses `TonalLexicon` from cycle 34. Demonstrates that the architecture is composable: T159 (lexicon) → T154 (Devil's Advocate).

---

## T153 — Sacred Echo Time Capsule

### What it does

A Sacred Echo can be sealed as a **time capsule** with a user-defined future unlock date and a fresh reflection prompt. When auto-unseal fires, the user must write "has anything changed?" before the plaintext is shown.

UX: "Sealed on 2026-06-28. Opens 2027-06-28. Unseal will ask: has anything changed?"

### Implementation

In `Sources/OneWeave/SacredEcho.swift`:

1. New enum `EchoKind { regular, timeCapsule }`
2. New field `kindRaw: String` on `SacredEcho` model (defaults to `.regular` for backward compat with echoes sealed before cycle 35)
3. New computed `var kind: EchoKind` (get/set with backward-compat default)
4. New `struct TimeCapsuleInvite { echoID, echoTitle, prompt, sealedAt, unlockAt, yearsSinceSealed, isReady }`
5. New `static func timeCapsuleInvite(for:now:)` — returns the right prompt text based on `kind` + whether `unlockAt <= now`

### Backward compatibility

All existing SacredEcho instances default to `.regular`. New `init(kind: EchoKind = .regular)` parameter is optional. No migration needed.

### Privacy

- Time capsule invites are still private (echoes are private by default)
- The reflection-prompt gate honors Constitution §4 (reflection-gated everything): the plaintext is not shown until the user writes a non-empty reflection

---

## Round-5 review cross-check

| Reviewer | Items this cycle addressed |
|----------|----------------------------|
| Claude (r5) | All cycle-32 items already applied; nothing new |
| Grok (r4) | M03 fixed in cycle 33; nothing new |
| GLM (r5) | **A9** Apprentice Knots ✓, **B5** Decision Reverb ✓, **A6** Devil's Advocate ✓, **A4** Time Capsule ✓ — 4 more top items shipped |
| Codex (r5) | Mac-only — deferred as M14-M22 |

**Total GLM items shipped across cycles 33-35: 12 of 23**

- Cycle 33: T148 (Guest Mode), T151 (Decay Garden), T157 (Insight Provenance), T158 (botanical decay), T160 (Rhizome Index)
- Cycle 34: T147 (One Neglect), T152 (Unchosen Path), T159 (Tonal Coherence), T168 (Cognitive Load Dim)
- Cycle 35: T149 (Apprentice Knots), T161 (Decision Reverb), T154 (Devil's Advocate), T153 (Time Capsule)

Remaining: **T150** Quiet Hours Ritual (UX, Mac-only), **T155** Compass of Trade-Offs (Mac-only), **T156** P2P Witness Mode (L, Mac-only), **T162-T167** micro-interactions (Mac-only), **T169** Silent Success (Mac-only), **T170** Void Thread (L, Mac UI required for re-type flow).

---

## Why this cycle matters

**T149** is the constitutional commitment to *genuine mastery*. The algorithm now refuses to advance tiers while a user has an unresolved question. The user can *see* the block ("Self tier awaits 2 knots"), not just *feel* it.

**T161** answers the question "did this decision matter?" with math, not feelings. Settled vs still-open is auditable: the algorithm is in the source code, the data is in the user's log.

**T154** is the privacy-first inversion of "are you sure?" prompts. We don't second-guess the user with model-generated doubt — we show them *their own past* and let them weigh it. The user is the final arbiter.

**T153** turns Sacred Echo from "delayed message" into "intentional time-bound capsule". The reflection-prompt gate ensures that opening a year-old echo isn't passive — it's an active ritual.

---

## Validation status

```
Suites run: 33
Suites all-green: 33
Suites with failures: 0

✓ ALL SUITES PASS
```

New validator: `.research/validate_cycle35_glm_features.py` (PASS)
Sanity test: `.research/_sanity_cycle35.py` (PASS — all assertions match expected)

---

## Cycle 36 candidates

Mac-only remaining — would need Xcode. Or:

- **T156-void-thread**: build the Void Thread (T170) on Linux — the crypto part is platform-agnostic (HKDF + SHA-256 in CryptoKit). The UI re-type flow is Mac.
- **Refactor pass**: now that 12 GLM features are shipped, look for duplication across modules (e.g., the `private extension Comparable { clamped(to:) }` exists in 3 files — could be moved to a shared utility module).
- **Graph Integration**: wire the new modules into the GraphInsightGenerator citation chains (cycle 33) so an insight about "you're stuck" can cite a knot + a decision + a tone-coherence angle.

---

## Git history

```
[cycle 35] feat(masteryknots): tier advancement gated by untying user questions (T149)
[cycle 35] feat(decisionreverb): 30/90/365-day half-life + ⚓ settled glyph (T161)
[cycle 35] feat(devilsadvocate): counter-argument from user's own past (T154)
[cycle 35] feat(timecapsule): EchoKind.timeCapsule + reflection-prompt gate (T153)

2998257 docs(cycle34): handoff doc + T147/T152/T159/T168 marked SHIPPED in tasks.md
9c54e9b feat(cognitiveload): shouldDimUI signal for soft desaturate before pause (T168)
d9d21f4 feat(unchosenpath): 30-day counterfactual reflection prompt (T152)
6e9b5ca feat(oneneglect): morning briefing surfaces single most-overdue thread (T147)
6b44135 feat(tonalcoherence): 4-dim lexicon + rolling centroid + coherence angle (T159)
```
