# Checklist for 002-gamification Spec Quality Gate

Generated per Spec Kit workflow. Run before planning/implementation. All items must pass.

## Requirements Quality
- [x] Requirements are testable and measurable (e.g. "every quest completion emits TimelineEvent with linkedThreads"; "% quests with IRL logged"; live updates in UI without lag).
- [x] No vague terms like "fast", "user-friendly", "beautiful" — replaced with specifics: "calm, low-framerate organic flows", "subtle spring animations", "reflection gate required for full reward", "peripheral awareness".
- [x] Edge cases covered: lowEnergy state, zero data, many events, reflection skipped (partial reward), grace for streaks, cross-domain chains.
- [x] Non-functional requirements explicit: local-only SwiftData (no network), privacy (export/clear/no-training), calm (no dark patterns, anti-addictive gates), performance (smooth Canvas).
- [x] Acceptance criteria clear and verifiable (ripples visible everywhere, mastery updates live, visual state-driven, IRL bias enforced).

## Constitution & Philosophy Compliance
- [x] Aligns with "One Journey, Not Silos": cross-thread quests, resonance, linked rippling, harmony score.
- [x] Privacy-First, Zero-Trust: All models local, on-device calc, no external for core, user export/clear.
- [x] Calm Intelligence: Subtle visuals, peripheral, no attention hijack, on-device where extended, real-world focus.
- [x] Fluid Threads: Quests/essence/visuals span and link all 4; no silos.
- [x] Genuine Help Over Features: IRL-first, reflection for depth, retention via value not compulsion, screen time reduction as win.
- [x] Plan Rigorously, Build Real: This spec + tasks before any code; working artifacts per phase.

## Scope & Focus
- [x] Primary focus areas (quests, XP/Essence, visual weave/loom, streaks) are central and detailed with flows, examples, acceptance.
- [x] Ties explicitly to existing architecture (TimelineEvent, LifeContext, Compass, Threads, StateMachine).
- [x] Non-goals and anti-addiction rules explicit and enforced in acceptance + tasks.
- [x] Success metrics real-impact oriented (IRL outcomes, harmony, legacy echoed, disengagement).

## Ambiguity / Completeness
- [x] User needs are quoted and addressed.
- [x] Journeys reference existing USER_JOURNEYS_ONEWEAVE.md + new gamification examples (leak→chain, low energy restoration).
- [x] No tech stack in spec (deferred to plan/tasks).
- [x] MVP vs premium distinguished.
- [x] Visuals described functionally (what user sees/experiences) without implementation.

## Next Gates
- [ ] After clarify (if needed): re-run checklist.
- [ ] Before /speckit.plan or implementation: full pass.
- [ ] Cross-check with /speckit.analyze equivalent: spec ↔ tasks ↔ future code.

Status: Ready for tasks/plan/implementation. Spec is focused, grounded, constitution-compliant, and actionable.
