# OneWeave Round 3 Review — Spec Kit + Graphify + Aider Adoption

**Date**: 2026-06-27
**Round**: 3 (post-toolchain adoption)
**Scope**: Review the OneWeave codebase + spec 003 against graph findings. Surface findings, don't fix.

## Context

You are reviewing the OneWeave iOS app codebase. This is a privacy-first Life OS app (Swift 5.9, SwiftUI, SwiftData, iOS 17+). The codebase has matured significantly over 3-4 days of building; we have now adopted:

- **Spec Kit** — `.specify/constitution.md` v2.0 + `.specify/specs/003-production-readiness/` (12 user stories, plan, checklist, tasks)
- **Graphify** — `graphify-out/` (2591 nodes, 4298 edges, 179 communities, top 30 god nodes identified)
- **Aider** — `.aider.conf.yml` + `CONVENTIONS.md` (per-feature commit workflow)

The codebase has 525+ Python validation tests passing (16 suites), but no Swift compilation yet (Linux VPS only; Mac work pending).

## Your Job

Read the canonical context (see "Files to Read" below), then answer the questions in your section. Surface findings in the requested format. **Do not modify code** — this is review only.

## Files to Read (in order)

1. `.specify/constitution.md` — Project principles (privacy-first, calm, reflection-gated, anti-addictive)
2. `.specify/specs/003-production-readiness/spec.md` — Canonical spec (12 user stories)
3. `.specify/specs/003-production-readiness/checklist.md` — Quality gate
4. `.specify/specs/003-production-readiness/plan.md` — Technical decisions TD-1 to TD-10
5. `graphify-out/WIKI_AGENT.md` — Condensed knowledge graph wiki
6. `graphify-out/GRAPH_REPORT.md` — Full graph report (god nodes, surprising connections, communities)
7. `CONVENTIONS.md` — Code style and privacy invariant checks
8. **Source files** for the specific area you're reviewing (see per-agent sections below)

## Your Section (assigned by orchestrator)

### Grok — Architecture Review

Focus on the **5 areas God Nodes identified as most-connected**:

1. `FamilyPod` (35 edges) — read `Sources/OneWeave/FamilyPod.swift` + `.research/validate_family_pod.py`
   - Is the public API complete and stable?
   - Are there missing privacy invariants?
   - Does the digest builder handle all 6 visibility grants correctly?
   - Does the validator mirror the API exactly?

2. `LifeContext` (31 edges) — read `Sources/OneWeave/LifeContext.swift`
   - Is energy/harmony propagation testable?
   - Are there race conditions in `@Published` updates?
   - Does `updateFromEvent` correctly emit ripples to the right threads?

3. **Schema Migration** — read `Sources/OneWeave/SchemaMigrationPlan.swift` + the 3 `OneWeaveSchemaV1/V2/V3`
   - Are V1↔V2↔V3 migrations atomic?
   - Does rollback work correctly?
   - Are there fields that could lose data during migration?

4. **Sacred Echo crypto** — read `Sources/OneWeave/SacredEcho.swift`
   - Is the AES-GCM nonce random and unique per encryption?
   - Is the auth tag verified on open?
   - Is HKDF salt correct?
   - Is the vault seed properly handled on first launch?

5. **The 5 privacy gates** — search for these patterns across `Sources/OneWeave/`:
   - Reflection gate: `commitWeave`, `completeQuest`, `applyInsight`, `sealEcho`, `applyDecision` — all must require non-empty `reflectionText`
   - Data Leash gate: `currentLeash(in:)` precedes every integration call
   - Consent gate (`isUserReflection`): InvisibleMentor only synthesizes from `isUserReflection == true`
   - Sacred Echo unlock gate: state transitions only happen via `SacredEchoStore`
   - Fail-closed crypto gate: no test seed fallback in production paths

**Output format**: 5 sections (one per area above), each with:
- Finding ID (GROK-R3-N)
- Severity: HIGH / MEDIUM / LOW
- File:line reference
- Issue description (1-2 sentences)
- Suggested fix (1-2 sentences)
- Privacy implication (or "None" if not privacy-related)

---

### Claude Code — Swift Code Quality Review

Focus on **code quality** across the codebase. Read these files in order:

1. `Sources/OneWeave/LifeContext.swift`
2. `Sources/OneWeave/LifeGraph.swift`
3. `Sources/OneWeave/SacredEcho.swift`
4. `Sources/OneWeave/InvisibleMentor.swift`
5. `Sources/OneWeave/CognitiveLoad.swift`
6. `Sources/OneWeave/FamilyPod.swift`
7. `Sources/OneWeave/PortableExport.swift`
8. `Sources/OneWeave/iOSServiceIntegrations.swift`
9. `Sources/OneWeave/GraphInsightGenerator.swift`
10. `Sources/OneWeave/CommandPalette.swift`
11. `Sources/OneWeave/AppLifecycleCoordinator.swift`
12. `Sources/OneWeave/LoomGeometry.swift` + `LivingGraphLoom.swift`

For each file, look for:
- **Concurrency issues**: `@MainActor` discipline, missing await, race conditions in @Published
- **SwiftData issues**: missing `@Model`, missing schema registration in OneWeaveApp, broken relationships
- **Memory issues**: retain cycles in closures, missing `[weak self]`
- **Error handling**: silent failures, missing throw propagation, `try!` abuse
- **Type safety**: force-unwraps, missing `guard let`, optional handling
- **Reflection gate coverage**: every state-changing action verifies non-empty text
- **Data Leash coverage**: every integration call preceded by `currentLeash(in:)`

**Output format**: Per-file findings, structured as:
- File path
- Findings (bullet list)
- For each finding: CLAUDE-R3-N, severity, line range, issue, fix

End with a SUMMARY section listing top 5 issues by severity.

---

### Nemotron 3 Ultra — Production Readiness Review

Focus on **production readiness** for App Store submission. Read these files:

1. `CLAUDE_COWORK_BRIEF.md` — Mac brief
2. `FIRST_WEEK_ON_MAC.md` — Week-1 plan
3. `Sources/OneWeave/OneWeaveApp.swift` — App entry, schema registration
4. `Sources/OneWeave/AppLifecycleCoordinator.swift` — Encrypted persistence
5. `Sources/OneWeave/OneWeaveSnapshotStore.swift` — Widget snapshot
6. `Sources/OneWeave/OneWeaveWidgetStubs.swift` — Widget code
7. `Sources/OneWeave/SchemaMigrationPlan.swift` — Migration logic
8. `PRIVACY.md` — Privacy policy
9. `PrivacyPolicy.md` — App Store privacy policy
10. `MARKETING.md` — App Store description
11. `FEATURE_CATALOG.md` — Feature list

For each area, evaluate:
- **Info.plist requirements**: HealthKit, Contacts, Calendar, Reminders, Microphone, Camera usage descriptions
- **App Store Connect metadata**: privacy policy URL, support URL, age rating
- **TestFlight readiness**: signing setup, provisioning profiles, archive workflow
- **Sacred Echo Vault review notes**: explain post-mortem crypto delivery to reviewer
- **Onboarding polish**: first-run flow, `@AppStorage("hasCompletedOnboarding")` persistence
- **Schema migration safety**: atomic, rollback, no data loss
- **Widget extension wiring**: App Group `group.com.oneweave`, snapshot key, AppIntents
- **Privacy policy accuracy**: matches actual data flow
- **Marketing copy accuracy**: no aspirational claims (e.g., "AI-powered" when it's heuristic)

**Output format**: Per-area findings, structured as:
- Area
- Findings (bullet list)
- For each finding: NEMO-R3-N, severity, blocker (yes/no), issue, fix

End with a PRODUCTION_READINESS_SCORE (0-100) with breakdown:
- Code: ?
- Privacy: ?
- UX: ?
- App Store readiness: ?
- Mac-side work: ?

---

## Privacy Invariant Reminders

Every finding MUST respect these:
- No external API calls (privacy-first)
- No cloud sync on free tier (privacy-first)
- No LLM/Core ML/network in core features (calm intelligence)
- Reflection gates on state changes (reflection-gated)
- Data Leash before integration calls (privacy-first)
- Fail-closed Sacred Echo crypto (privacy-first)
- No streak-shaming (anti-addictive)
- Color convention: Self=.blue, Stewardship=.green, CareKin=.orange, Meaning=.purple

## Output File

Save your findings to: `.research/REVIEW_ROUND_3_<YOUR_AGENT>.md`

## Constraints

- Be **specific** (file path + line number + exact code snippet)
- Be **actionable** (suggest a fix, not just describe the problem)
- Be **concise** (one finding = 3-5 lines)
- **Don't fix code**. Surface findings only.
- Don't repeat findings from prior rounds (round 1 + 2 already applied; see `.research/build_log.md`)

---

*This is a review-only round. The Mac coworker will apply findings after they're collected and prioritized.*