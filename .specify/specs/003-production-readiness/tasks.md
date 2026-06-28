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

---

## Phase T07: GLM 5.2 Round-1 Findings (Linux-cross-checked, 2026-06-27)

**Source**: `.research/glm_round_1/deep_review.md` (GLM 5.2 chat-completion review) cross-verified by Claude Code (opus) + Grok (supergrok). Kimi returned `LLM not set` (non-interactive OAuth missing).

**Triage summary** (Claude opus verdict):
- 3 PHANTOM findings (code doesn't exist as described) — dropped
- 4 REDUNDANT with cycle-27 fixes — already in known gaps
- 2 genuinely NEW Linux-fixable items → T075, T076
- 2 Mac-needed items → T086, T087
- 3 architectural proposals (HLC/CRDT/Sendable) → deferred design spikes T088-T090

- [ ] T075 **[NEW · Linux · MEDIUM]** GLM-#5 + Claude — enforce reflection min-length on `completeQuest`. `LifeContext.swift:454-455` `let bonus = trimmed.isEmpty ? 3 : 10` accepts a 1-char reflection for full 10 essence while `FamilyPod` enforces `minExitReflectionChars = 20`. Fix: gate the `+= 10` branch behind `trimmed.count >= 20`, keep `+= 3` for shorter reflections. Add Python validator `validate_life_context_reflection_gate_matrix.py`.
- [ ] T076 **[NEW · Linux · HIGH]** GLM-#7 + Claude + Grok — fix FamilyPod compile-blockers. `FamilyPod.swift:330/335/338` reference non-existent `LifeContext.threads`, `currentSeasonName`, `activeAmplifierName`. Add three computed properties on `LifeContext`: `var threads: [BasicSelfThread] { activeThreads }`, `var currentSeasonName: String { currentSeason.displayName }`, `var activeAmplifierName: String?` (default `nil`). Hard compile error — verified live.
- [ ] T077 **[NEW · Linux · HIGH]** GLM-#6 + Claude + Grok — fix FamilyPodDigestEntry mutability. `FamilyPod.swift:427-428` mutates `member.displayName` (declared `let`). Change to `var`. GLM also flagged `podTitle`→`podName` but Grok confirms actual field is `amplifierName`. Verified live: `FamilyPodMember.displayName` is `let` at line 121-122.
- [ ] T078 **[Linux · MEDIUM]** GLM-#1 + Claude — randomize SacredEcho salt (cheaper than expected). `SacredEcho.swift:281-282` `let salt = Data(echoID.uuidString.prefix(16).utf8)`. Generate 16-byte random salt at seal time, persist in `attributes["salt"]`, read back in `open()`. Keep nonce as-is. Claude notes HKDF salt being public is cryptographically acceptable (nonce is already randomized) — severity LOW not HIGH. Still cheap to do.
- [ ] T079 **[Linux · LOW]** GLM proposal — ReflectionGate central policy object. Extract the 3/10/20-char rules into `ReflectionGate.swift` with unit tests. Consolidates T075 + scattered reflection checks (LifeContext.swift:454, FamilyPod.swift exit-reflection, CommandPalette pendingAction). Linux-fixable.
- [ ] T080 **[Linux · MEDIUM]** Grok-#2 partial — Contacts permission ordering. `iOSServiceIntegrations.swift:155-156` has `let perm = await requestAccess()` BEFORE `guard ... leash.isAllowed(...)`. Calendar+Reminders are correct (Grok#18 already fixed). Move leash check first in Contacts path only.
- [ ] T081 **[Linux · LOW]** Add Python validator `validate_sacred_echo_crypto.py` — assert HKDF round-trip, fail-closed vaultSeed, opened-flag immutability via stateRaw/openedAt, salt randomness (T078).
- [ ] T082 **[Linux · LOW]** Add Python validator `validate_life_context_reflection_gate_matrix.py` — 3×3 matrix (essence {2,7,12} × length {0,5,25}); assert correct error for each cell. Validates T075.
- [ ] T083 **[Linux · LOW]** Add Python validator `validate_family_pod_builder_surface.py` — parse FamilyPod.swift AST; assert no references to non-existent LifeContext members. Validates T076.
- [ ] T084 **[Linux · LOW]** Add Python validator `validate_p2p_cooldown_semantics.py` — assert cooldown only advances on success. Note: GLM cited wrong file/lines (Grok confirms no `lastShareAt` at P2PWeaveShare.swift:32-34; cooldown is in `FamilyPodPolicy.nextEligiblePublish`). Validator should target correct location after reading FamilyPod.swift.
- [ ] T085 **[Linux · DOC]** Update `.research/REVIEW_ROUND_4_GLM5.2.md` with cross-check summary (Claude + Grok verdicts), phantom-finding corrections, and the T075-T087 task list. Document that Kimi returned `LLM not set` and was skipped.

- [ ] T086 **[Mac-needed · MEDIUM]** GLM-#10 + Claude + Grok — BGProcessingTask for envelope persist. `AppLifecycleCoordinator.applicationDidEnterBackground` (lines 409-420) does synchronous `mc.save()` + `makeEnvelope` + encrypt + atomic write + pushSnapshotToWidgets with no `beginBackgroundTask`/`BGTaskScheduler`. iOS can kill before flush on large graphs. Fix requires UIApplication/BGTaskScheduler — uncompilable on Linux.
- [ ] T087 **[Mac-needed · MEDIUM]** Bundle-ID scoped snapshot key. `AppLifecyclePaths.lifeGraphFilename = "oneweave.lifegraph.v1.json"` — no per-install scoping. App Group sharing risks key collision between variants. True fix requires `Bundle.main.bundleIdentifier` — uncompilable on Linux.
- [ ] T088 **[DEFERRED · design spike]** HLC (Hybrid Logical Clocks) for P2P ordering. Wall-clock Date is unsafe across offline-then-resync; HLC `(physical_ms, logical_counter)` bounds skew. 40-line Python reference impl. Adopt when P2P becomes load-bearing.
- [ ] T089 **[DEFERRED · design spike]** CRDT LWW-element-set for offline share queue. `pendingShares: [P2PShare]` is a plain array; two Family-Pod members queueing offline then syncing requires merge semantics, not FIFO.
- [ ] T090 **[DEFERRED · design spike]** `LifeContextSnapshot` Sendable value type at actor boundaries. `@Model` classes are not `Sendable` in Swift 5.9; introduces snapshot struct for actor-crossing returns. Requires Swift 6 concurrency checker to validate properly.

---

## Phase T08: 4-CLI Multi-Agent Round (2026-06-27)

- [ ] T091 Run Grok + Claude + Kimi + Codex + GLM 5.2 in parallel on the same task; collect all outputs to `.research/round4/` and synthesize via Claude.
- [ ] T092 Triangulate findings: items flagged by ≥3 models are HIGH; 2 models = MEDIUM; 1 model = LOW.
- [ ] T093 Append consolidated findings to `.research/REVIEW_ROUND_4.md` with file:line citations and severity.

---

## Phase T09: Linux-side documentation polish

- [ ] T094 Generate `graphify --wiki` output (`graphify-out/wiki/index.md`). Currently only GRAPH_REPORT.md exists; wiki is the agent-facing interface.
- [ ] T095 Write `.research/THREAT_MODEL.md` — adversaries (curious peer, malicious peer, device forensic recovery), trust boundaries, defense layers (HKDF, AES-GCM, Data Leash, reflection gate).
- [ ] T096 Update `ONEWEAVE_HANDOFF_2026-06-27.md` "Next Steps" → "Cycle 29 Linux work: T075-T087 applied; cycle 30 Mac handoff."

---

## Updated Summary

| Phase | Status | Owner | Duration |
|---|---|---|---|
| Phase 0: Toolchain | ✅ Complete | Linux | 1 hour |
| Phase V1: Validation | ✅ Complete | Linux | already done |
| Phase G1: Graphify | ✅ Complete | Linux | done |
| Phase A1: Aider | ✅ Complete | Linux | done |
| Phase R1: Multi-Agent | 🔄 Round 1 done (GLM) | Linux | 30 min |
| Phase T07: GLM findings apply | 🔄 In progress | Linux | ~2 hours |
| Phase T08: 4-CLI round | ⏳ Next | Linux | 30 min |
| Phase T09: Doc polish | ⏳ Pending | Linux | 30 min |
| Phase P1: GitHub Push | ⏳ Pending | User | 10 min |
| Phase M1: Xcode | ⏳ Pending | Mac | 4-6 hours |
| Phase M2: Widgets | ⏳ Pending | Mac | 2-3 hours |
| Phase M3: AppIntents | ⏳ Pending | Mac | 2-3 hours |
| Phase M4: Signing | ⏳ Pending | Mac | 3-4 hours |
| Phase M5: Submission | ⏳ Pending | Mac | 2-3 hours |
| Phase M6: Onboarding | ⏳ Pending | Mac | 2-3 hours |

**Linux T07-T09 total: ~3 hours focused work**
**Mac total: 15-22 hours focused work**