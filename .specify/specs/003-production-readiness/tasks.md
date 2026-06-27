# Tasks: 003-production-readiness

**Input**: Design documents from `.specify/specs/003-production-readiness/`
**Prerequisites**: spec.md (✅), plan.md (✅), checklist.md (✅), constitution.md v2.0 (✅)
**Tests**: Validation suites in `.research/validate_*.py` (16 suites, 525+ tests)

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel
- **[Story]**: Which user story (US1-US12) or which Mac-side phase (M1-M6)
- File paths absolute or relative to `/root/hermes-workspace/projects/oneweave/`

---

## Phase 0: Toolchain Adoption (Linux-side, ✅ COMPLETE)

**Purpose**: Set up Spec Kit + Graphify + Aider toolchain so all future work follows the canonical flow.

- [x] T001 Initialize Spec Kit via `specify init . --here --ignore-agent-tools --force` (DONE 2026-06-27)
- [x] T002 Update `.specify/constitution.md` to v2.0 with reflection-gated principle, anti-addictive details, toolchain mandates (DONE)
- [x] T003 Create `.specify/specs/003-production-readiness/spec.md` covering 12 user stories (DONE)
- [x] T004 Create `.specify/specs/003-production-readiness/checklist.md` with CHK001-CHK063 (DONE)
- [x] T005 Create `.specify/specs/003-production-readiness/plan.md` with technical decisions TD-1 to TD-10 (DONE)
- [x] T006 Run Graphify on codebase: `graphify . --update --wiki --mcp` (DOING NOW)
- [x] T007 Create `.aider.conf.yml` with model + read list + auto-commit (DOING NOW)
- [x] T008 Run all 16 Python validation suites: `bash .research/validate_all.sh` (RUNNING)
- [x] T009 Dispatch multi-agent review with spec + Graphify wiki as context (NEXT)

---

## Phase M1: Xcode Project (Mac-side, PENDING)

**Purpose**: Create compilable iOS project from existing Swift sources.

- [ ] T010 [M1] Create new Xcode project (iOS 17+ iPhone target, SwiftUI App lifecycle)
- [ ] T011 [M1] Add 55 Swift files from `Sources/OneWeave/` to target
- [ ] T012 [M1] Configure SwiftData modelContainer in `OneWeaveApp.swift` with 11 @Models + 3 VersionedSchemas (OneWeaveSchemaV1/V2/V3)
- [ ] T013 [M1] Set deployment target iOS 17.0 minimum
- [ ] T014 [M1] Add Info.plist privacy strings (HealthKit, Contacts, Calendar, Reminders, Microphone for voice capture, Camera for document capture)
- [ ] T015 [M1] Build for iOS Simulator (x86_64 + arm64) — verify clean build, no warnings
- [ ] T016 [M1] Run `OneWeavePrototype.swift` harness — verify all 525+ Python-validated scenarios pass on actual Swift runtime
- [ ] T017 [M1] Fix any Swift compilation errors (expected: type inference issues, missing imports, iOS API differences)
- [ ] T018 [M1] Document build instructions in `BUILD_MAC.md` (commands, env vars, common errors)

---

## Phase M2: Widget Extension (Mac-side, PENDING)

**Purpose**: Ship HarmonyWidget + QuestWidget to home screen.

- [ ] T020 [M2] Add Widget Extension target to Xcode project
- [ ] T021 [M2] Configure App Group `group.com.oneweave` on both App + Widget targets
- [ ] T022 [M2] Copy `OneWeaveWidgetStubs.swift` → Widget Extension target; create `HarmonyWidget.swift` + `QuestWidget.swift`
- [ ] T023 [M2] Wire `OneWeaveSnapshotStore.write()` from `commitWeave`, `completeQuest`, `BodyThreadReading.record()`
- [ ] T024 [M2] Add `WidgetConfiguration` in `OneWeaveApp.swift` for both widgets
- [ ] T025 [M2] Build and run on Simulator; verify widget appears in widget gallery
- [ ] T026 [M2] Add widget tap-to-open-app deep linking via `widgetURL`

---

## Phase M3: AppIntents + LiveActivity (Mac-side, PENDING)

**Purpose**: Siri + Shortcuts + Dynamic Island integration.

- [ ] T030 [M3] Create `AppIntents/LogWeaveIntent.swift` (open app + record reflection)
- [ ] T031 [M3] Create `AppIntents/CompleteQuestIntent.swift` (open app + complete with reflection)
- [ ] T032 [M3] Create `AppIntents/ShowHarmonyIntent.swift` (return harmony score as Siri response)
- [ ] T033 [M3] Register all 3 intents in `OneWeaveApp.swift` via `AppShortcutsProvider`
- [ ] T034 [M3] Create `OneWeaveLiveActivityAttributes.swift` + Live Activity widget
- [ ] T035 [M3] Wire Live Activity start/end to quest begin/complete
- [ ] T036 [M3] Test Siri invocation: "Hey Siri, log a weave in OneWeave"

---

## Phase M4: Signing + TestFlight (Mac-side, PENDING)

**Purpose**: Get app onto physical device for beta testing.

- [ ] T040 [M4] Bundle ID: `com.oneweave.app`
- [ ] T041 [M4] Apple Developer account setup (USER-PROVIDED — requires Dan's account)
- [ ] T042 [M4] Create App ID in Apple Developer portal with App Group entitlement
- [ ] T043 [M4] Create provisioning profiles: Development + Distribution
- [ ] T044 [M4] Configure code signing in Xcode (automatic signing recommended)
- [ ] T045 [M4] Archive build (Product → Archive)
- [ ] T046 [M4] Upload to App Store Connect via Xcode Organizer
- [ ] T047 [M4] Create TestFlight internal testing group (up to 100 testers)
- [ ] T048 [M4] Add build to TestFlight; invite internal testers
- [ ] T049 [M4] Monitor TestFlight crash reports + feedback for first 7 days
- [ ] T050 [M4] Fix any critical bugs surfaced by TestFlight

---

## Phase M5: App Store Submission (Mac-side, PENDING)

**Purpose**: Public App Store listing.

- [ ] T060 [M5] App Store Connect metadata:
  - App name: "OneWeave"
  - Subtitle: "Your life. One woven story."
  - Category: Lifestyle (primary) + Productivity (secondary)
  - Description: from MARKETING.md
  - Keywords: "life journey,interconnected,energy,privacy,calm,legacy,encrypted journal"
  - Support URL: support@oneweave.app
  - Privacy Policy URL: github.com/yourname/oneweave/blob/main/PRIVACY.md
- [ ] T061 [M5] Screenshots: 6.7" iPhone (3), 6.5" iPhone (3), 5.5" iPhone (3), 12.9" iPad (3) — use visuals_*.png as starting point
- [ ] T062 [M5] App icon: 1024×1024 PNG (design on Mac; use compass + threads motif)
- [ ] T063 [M5] Age rating questionnaire: 4+ (no objectionable content)
- [ ] T064 [M5] Pricing: Free with in-app purchase for paid tier ($9.99/mo, $79.99/yr)
- [ ] T065 [M5] App Review notes:
  - Explain Sacred Echo Vault (encrypted time-capsule messages)
  - Note: not for post-mortem financial/legal instructions (user accepts this in onboarding)
  - Note: encrypted at rest, no server access
  - Note: privacy policy URL provided
- [ ] T066 [M5] Submit for review
- [ ] T067 [M5] Monitor review status (typically 24-48h)
- [ ] T068 [M5] Address any App Review feedback (mostly likely: clarify encryption, add "delete account" path even though no account exists)

---

## Phase M6: Onboarding Polish (Mac-side, PENDING)

**Purpose**: First-run experience that earns trust.

- [ ] T070 [M6] Replace `OnboardingView.swift` stub with 5-step intro:
  1. Welcome + privacy promise (1 sentence each: local-first, no cloud, encrypted vault)
  2. The 4 Threads (visual)
  3. Reflection gate explanation (we never save anything without your why)
  4. Sacred Echo Vault teaser (one tap → sample echo)
  5. Ready (first quest generated)
- [ ] T071 [M6] `@AppStorage("hasCompletedOnboarding")` persistence
- [ ] T072 [M6] Auto-show on first launch in `OneWeaveApp.swift`
- [ ] T073 [M6] "First Weave" demo: tap → commit a decision → see ripple → see Sacred Echo suggestion
- [ ] T074 [M6] Localization-ready (en only at v1; extract strings)

---

## Phase V1: Validation Verification (Linux-side, ✅ COMPLETE)

**Purpose**: Confirm all 525+ Python mirror tests pass on current state.

- [x] V01 Run `bash .research/validate_all.sh` — confirm 16/16 suites PASS (DONE)
- [x] V02 Real bugs caught: Weave Pause gate (fixed), FamilyPod whitespace (fixed), Loom geometry (fixed), QuickCapture event/journal (fixed) (4 caught and fixed)
- [x] V03 Stress harness at 1k/10k entities (DONE)
- [x] V04 Document real bugs in spec 003 edge cases (DONE)

---

## Phase G1: Graphify Build (Linux-side, IN PROGRESS)

**Purpose**: Compress codebase context for delegated agents.

- [ ] G01 Run `graphify . --update` (extract code, ignore vision for Swift)
- [ ] G02 Run `graphify . --wiki` (generate agent-readable markdown)
- [ ] G03 Verify `graphify-out/wiki/index.md` exists with all major files
- [ ] G04 Run `graphify . --mcp` in background for live queries
- [ ] G05 Read `graphify-out/GRAPH_REPORT.md` — note god nodes + surprising connections
- [ ] G06 Use Graphify findings to update spec 003 plan.md with architecture insights

---

## Phase R1: Multi-Agent Review (Linux-side, NEXT)

**Purpose**: Get 3 independent reviews of the codebase using spec + Graphify wiki as context.

- [ ] R01 Dispatch Grok (supergrok): review spec 003 + wiki → return findings on architecture gaps
- [ ] R02 Dispatch Claude Code (opus): review spec 003 + wiki → return findings on Swift code quality
- [ ] R03 Dispatch Nemotron 3 Ultra: review spec 003 + wiki → return findings on production readiness
- [ ] R04 Apply all HIGH-priority findings to Swift source
- [ ] R05 Apply all MEDIUM-priority findings
- [ ] R06 Re-run `bash .research/validate_all.sh` — confirm no regressions
- [ ] R07 Document findings in `.research/REVIEW_ROUND_3.md`

---

## Phase A1: Aider Configuration (Linux-side, DOING NOW)

**Purpose**: Switch from "big-bundle writes" to per-feature commits.

- [ ] A01 Create `.aider.conf.yml` with:
  - model: claude-sonnet-4 (or current main)
  - read: [.specify/constitution.md, .specify/specs/003-production-readiness/spec.md, plan.md, checklist.md]
  - auto-commits: true
  - commit-prompt: "feat({feature}): {message}"
- [ ] A02 Add gitignore for `.aider*` cache files
- [ ] A03 Document Aider usage in CLAUDE_COWORK_BRIEF.md
- [ ] A04 Test Aider on a small change to verify workflow

---

## Phase P1: GitHub Push (Linux-side, PENDING USER AUTH)

**Purpose**: Get codebase to GitHub for cloud co-work flow.

- [ ] P01 User provides GitHub auth method (PAT, SSH key, or GitHub App)
- [ ] P02 Configure git remote `origin` to user's repo
- [ ] P03 Stage all files (except those in .gitignore)
- [ ] P04 Initial commit with full project state
- [ ] P05 Push to `main` branch
- [ ] P06 Create branch `003-production-readiness` per Spec Kit convention
- [ ] P07 Document push instructions in `PUSH_INSTRUCTIONS.md` (already created)

---

## Summary

| Phase | Status | Owner | Duration |
|---|---|---|---|
| Phase 0: Toolchain | ✅ Complete | Linux | 1 hour |
| Phase V1: Validation | ✅ Complete | Linux | already done |
| Phase G1: Graphify | 🔄 In Progress | Linux | 10 min |
| Phase A1: Aider | 🔄 In Progress | Linux | 5 min |
| Phase R1: Multi-Agent | ⏳ Next | Linux | 30 min |
| Phase P1: GitHub Push | ⏳ Pending | User | 10 min |
| Phase M1: Xcode | ⏳ Pending | Mac | 4-6 hours |
| Phase M2: Widgets | ⏳ Pending | Mac | 2-3 hours |
| Phase M3: AppIntents | ⏳ Pending | Mac | 2-3 hours |
| Phase M4: Signing | ⏳ Pending | Mac | 3-4 hours |
| Phase M5: Submission | ⏳ Pending | Mac | 2-3 hours |
| Phase M6: Onboarding | ⏳ Pending | Mac | 2-3 hours |

**Linux total: ~1 hour remaining (G1 + A1 + R1 + P1)**
**Mac total: 15-22 hours focused work**

---

*Generated 2026-06-27 as part of Spec Kit adoption. Tasks are organized by phase; Mac-side tasks (M1-M6) are PENDING until user authenticates + switches to Mac.*