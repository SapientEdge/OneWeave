# Requirements Quality Checklist: 003-production-readiness

**Purpose**: Validate that spec 003 is complete, testable, consistent, and constitution-compliant before Mac-side work begins.

**Created**: 2026-06-27
**Feature**: [003-production-readiness/spec.md](spec.md)

---

## Requirements Quality

- [x] **CHK001** All 12 user stories have explicit priority (P1/P2/P3)
- [x] **CHK002** Each story has an "Independent Test" describing how it can be verified standalone
- [x] **CHK003** Each story has at least 2 Acceptance Scenarios in Given/When/Then format
- [x] **CHK004** Edge cases enumerated for each story (4-5 per story)
- [x] **CHK005** No vague terms ("fast", "user-friendly", "intuitive", "beautiful") — replaced with measurable specifics
- [x] **CHK006** Non-functional requirements quantified (16ms frame, 50ms crypto, 1.5s cold start)
- [x] **CHK007** Privacy requirements explicit and verifiable (0 API keys, fail-closed crypto, leash-first reads)
- [x] **CHK008** Acceptance criteria measurable (not "looks good" but "appears in section X with priority Y")

## Constitution Compliance

- [x] **CHK010** Privacy-First: Zero external API dependencies documented; Sacred Echo uses fail-closed crypto
- [x] **CHK011** Calm Intelligence: No LLM/Core ML/network in core features; all synthesis is algorithmic
- [x] **CHK012** Reflection-Gated: All state-changing actions require non-empty `reflectionText`
- [x] **CHK013** Anti-Addictive: Streaks have grace; Weave Pause gate verified (only rising, not steadyHigh)
- [x] **CHK014** Genuine Help: Every story explains "why this priority" — not just feature creep
- [x] **CHK015** Architectural Invariants: App Group ID, schema versioning, color convention, reflection gate all explicit
- [x] **CHK016** Toolchain mandates: Spec Kit + Graphify + Aider + Python mirrors + dispatch script all referenced

## Cross-Artifact Consistency

- [x] **CHK020** Spec referenced in `constitution.md` v2.0 toolchain section
- [x] **CHK021** Spec reconciles prior specs 001 + 002 (gamification)
- [x] **CHK022** Spec references existing `@Models` by exact name (no invented names)
- [x] **CHK023** Spec references existing validation suites by exact filename
- [x] **CHK024** Spec explicitly demarcates Mac-side work (not buried)
- [x] **CHK025** Spec lists out-of-scope items (Android, sync, advanced AI)
- [x] **CHK026** Spec includes compliance checklist (this file)

## Validation Coverage

- [x] **CHK030** Every user story has a corresponding Python validation suite
  - US1 Loom: `validate_round2_loom.py` (15/15 PASS)
  - US2 Sacred Echo: `validate_tierA3_echo.py` (10/10 PASS)
  - US3 Invisible Mentor: `validate_tierA4_mentor.py` + `validate_mentor_bridge.py` (12+41 PASS)
  - US4 Privacy Leash: `validate_tierA2_integrations.py` (21/21 PASS)
  - US5 Cognitive Load: `validate_cognitive_load.py` (45/45 PASS)
  - US6 Family Pod: `validate_family_pod.py` (52/52 PASS)
  - US7 Portable Export: `validate_portable_export.py` (48/48 PASS)
  - US8 Quick Capture: `validate_quick_capture.py` (38/38 PASS)
  - US9 Decision Log: `validate_decision_log.py` (50/50 PASS)
  - US10 Briefings: `validate_daily_briefings.py` (31/31 PASS)
  - US11 Relationship Decay: `validate_relationship_decay.py` (30/30 PASS)
  - US12 Schema Migration: `validate_schema_migration.py` (30/30 PASS)
- [x] **CHK031** Stress harness covers scale (`validate_stress.py`, 35/35 PASS)
- [x] **CHK032** All real bugs caught by validators are documented in spec edge cases

## Toolchain Adoption

- [x] **CHK040** Spec Kit initialized (`.specify/constitution.md` v2.0, this spec)
- [x] **CHK041** Graphify run on codebase (`graphify . --update --wiki`)
- [x] **CHK042** Aider configured (`.aider.conf.yml`)
- [x] **CHK043** Python mirrors executed (`validate_all.sh` runner)
- [x] **CHK044** Multi-agent dispatch wired (`.research/NO_TRAINING_PROMPT.md`, `oneweave_dispatch.sh`)

## Mac-Side Work Demarcation

- [x] **CHK050** Xcode project creation listed (item 1)
- [x] **CHK051** SwiftData modelContainer wiring listed (item 2)
- [x] **CHK052** Widget Extension target listed (item 3)
- [x] **CHK053** AppIntents registration listed (item 4)
- [x] **CHK054** Bundle ID + signing listed (item 5)
- [x] **CHK055** App Store Connect metadata listed (item 6)
- [x] **CHK056** Simulator build/test listed (item 7)
- [x] **CHK057** TestFlight distribution listed (item 8)
- [x] **CHK058** App Store submission with Sacred Echo review notes listed (item 9)
- [x] **CHK059** Onboarding polish listed (item 10)

## Open Questions for User

- [ ] **CHK060** Confirm spec 003 is the canonical surface (replaces 001/002 for new work)
- [ ] **CHK061** Confirm paid tier pricing ($9.99/mo, $79.99/yr) — current draft in MARKETING.md
- [ ] **CHK062** Confirm Mac brief (`FIRST_WEEK_ON_MAC.md`) is the path forward
- [ ] **CHK063** Confirm GitHub push method (PAT, SSH, or GitHub App)

---

## Verification

All CHK001-CHK059 pass. CHK060-CHK063 are user-confirmation items.

---

*Generated 2026-06-27 as part of Spec Kit adoption. This checklist is a precondition for `/speckit.implement` (Mac-side work).*