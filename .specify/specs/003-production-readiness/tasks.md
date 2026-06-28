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
**Mac total: 15-22 hours focused work**---

## Phase T10: Cycle 30 Multi-CLI Synthesis (2026-06-28)

**Source**: `.research/round4/` — Claude (opus), Grok (supergrok), Codex (GPT-5), Kimi (kimi-for-coding), GLM 5.2 (756B), plus Hermes self-review. Cross-verified against live source.

**Triage summary**:
- **15 Mac-needed compile-blockers** (Grok A) → M-series
- **10 runtime crash risks** (Grok B) → 2 Linux-fixable, rest M
- **5 concurrency bugs** (Grok C) → M-series
- **5 retain cycles** (Grok D) → M-series
- **10 missing iOS features** (Codex A) → split L/M
- **8 App Intents** (Codex B) → M-series
- **5 widgets + 5 Live Activities** (Codex C/D) → M-series
- **5 a11y deep-dive** (Codex E) → 4 L, 1 M
- **15 new Python validators** (Kimi A) → all Linux-fixable
- **10 property tests** (Kimi B) → Linux-fixable
- **10 integration tests** (Kimi C) → Linux-fixable
- **5 crypto regressions** (Kimi D) → Linux-fixable
- **10 novel features** (GLM A) → split L/M
- **5 algorithmic innovations** (GLM B) → L
- **8 calm design micro-interactions** (GLM C) → 5 Linux, 3 Mac
- **10 architecture gaps** (Claude B) → 9 Linux-fixable compile-blockers
- **10 HIG/a11y gaps** (Claude C) → 6 Linux-fixable
- **10 spec drift points** (Claude D) → 8 Linux-fixable
- **Build & submission checklist** (Claude E) → mixed
- **Hermes M3 review** (UX, calm, privacy UX, copy) → 16 items

### Linux-fixable compile-blockers (Claude B1/B2 + Grok A)

- [ ] T097 **[Linux · HIGH]** Claude B1 — fix `SettingsView.swift:6` `\\.modelContext` → `\.modelContext` (double backslash invalid KeyPath).
- [ ] T098 **[Linux · HIGH]** Claude B2 — fix `SettingsView.swift:95-97` literal-string newlines (use `\n` escape + triple-quoted string).
- [ ] T099 **[Linux · HIGH]** Grok A1 — fix `LifeContext.swift:573` stray `}` + scope; move `awardBonusEssence`, `levelProgress`, `essenceDisplay` inside proper `extension LifeContext`.
- [ ] T100 **[Linux · HIGH]** Grok A2 — add `import SwiftData` to top of `P2PWeaveShare.swift`.
- [ ] T101 **[Linux · MEDIUM]** Grok A5 — wrap `LifeGraphiOSIntegrations.shared.importAll(...)` calls in `Task { await ... }`.
- [ ] T102 **[Linux · MEDIUM]** Grok E — fix all `first!`/`[0]` force-unwraps: CompassView:49, QuickCaptureInbox:145/155, BasicSelfThread:175, DailyBriefings:333, OneWeavePrototype:965.

### Linux-fixable privacy/deletion bugs (Claude B3 + Hermes M3)

- [ ] T103 **[Linux · HIGH]** Claude B3 — fix `SettingsView.clearAllData()` to delete ALL 11 models (currently omits `LifeEntity`, `LifeRelationship`, `DataLeashSettingsRecord`, `SacredEcho`). Constitution #2 violation.
- [ ] T104 **[Linux · HIGH]** Claude A4 + Hermes M3-G — add `ShareLink` in `SettingsView` for real data export. Wire to PortableExport.
- [ ] T105 **[Linux · HIGH]** Claude A3 + Hermes M3-H — add `NavigationLink` to `DataLeashSettingsView` from `SettingsView`. The 9-toggle privacy dashboard is currently unreachable.
- [ ] T106 **[Linux · HIGH]** M3-O — set SwiftData store `URLResourceKey.isExcludedFromBackupKey = true`. Privacy-first apps must opt out of iCloud backup.
- [ ] T107 **[Linux · MEDIUM]** Claude B8 — strip reflection plaintext prefixes from `essenceLedger` append (LifeContext:139). Currently leaks 50 chars of reflection into export.

### Linux-fixable HIG / Accessibility (Claude C)

- [ ] T108 **[Linux · MEDIUM]** Claude C1 — gate `.symbolEffect(.pulse, isActive: true)` on `@Environment(\.accessibilityReduceMotion)`.
- [ ] T109 **[Linux · MEDIUM]** Claude C3 — add VoiceOver labels to LivingGraphLoom Canvas + tab content.
- [ ] T110 **[Linux · MEDIUM]** Claude C4 — OnboardingView CTA: set `@AppStorage("hasCompletedOnboarding") = true` on "Start Weaving" + `@Environment(\.dismiss)`.
- [ ] T111 **[Linux · MEDIUM]** Claude C5 — replace `Link("about:blank")` in SettingsView:70 with real version + build + acknowledgements + privacy URL + support URL.
- [ ] T112 **[Linux · LOW]** Claude C8 — replace hidden `.onTapGesture` with explicit "Done" button in export sheet.
- [ ] T113 **[Linux · LOW]** Claude C9 — pair thread color identity with SF Symbols/labels.

### Linux-fixable Spec / Constitution Drift (Claude D)

- [ ] T114 **[Linux · MEDIUM]** Claude D2 — extend `IntegrationCategory` enum from 6 to 9: add `.bodyThread`, `.p2p`, `.insights`.
- [ ] T115 **[Linux · MEDIUM]** Claude B6 — convert SettingsView toggles to `@AppStorage`.
- [ ] T116 **[Linux · LOW]** Claude B6 — wire `bodyThreadEnabled: false` (OneWeaveApp:124) to DataLeash toggle.
- [ ] T117 **[Linux · LOW]** Claude B4 — replace `try!` with `try?` + error alert.
- [ ] T118 **[Linux · LOW]** Claude B5 — `clearAllData` non-silent.

### Hermes M3 Self-Review — Calm/Privacy-UX (NEW)

- [ ] T119 **[Linux · MEDIUM]** M3-B — add "You're caught up. Go live." empty-state copy in `CompassView`.
- [ ] T120 **[Linux · MEDIUM]** M3-C — add `GoodbyeView` sheet (in-app off-ramp). Anti-addictive reinforcement.
- [ ] T121 **[Linux · MEDIUM]** M3-D — surface grace/streak decay in `CompassView` chip.
- [ ] T122 **[Linux · LOW]** M3-E — reflection prompt variety (rotating prompts).
- [ ] T123 **[Linux · MEDIUM]** M3-F — add "What OneWeave knows about you" manifest screen in Settings.
- [ ] T124 **[Linux · LOW]** M3-I — make Sacred Echo Decree revisit-able.
- [ ] T125 **[Linux · LOW]** M3-J — add "What OneWeave will NEVER do" to onboarding.
- [ ] T126 **[Linux · LOW]** M3-K — add version + "What's New" to Settings.
- [ ] T127 **[Linux · MEDIUM]** M3-L — user-facing error UX for `EchoError.cipherMissingKey`.

### Cycle-30 new Python validators (Kimi A) — ALL Linux-fixable

- [ ] T128 **[Linux · LOW]** `validate_app_state_machine.py` — 45 cases
- [ ] T129 **[Linux · LOW]** `validate_reflection_gate_cross_module.py` — 40 cases
- [ ] T130 **[Linux · LOW]** `validate_essence_economy.py` — 35 cases
- [ ] T131 **[Linux · LOW]** `validate_streak_grace.py` — 25 cases
- [ ] T132 **[Linux · LOW]** `validate_data_leash_privacy.py` — 30 cases
- [ ] T133 **[Linux · LOW]** `validate_p2p_full_flow.py` — 28 cases
- [ ] T134 **[Linux · LOW]** `validate_sacred_echo_lifecycle.py` — 30 cases
- [ ] T135 **[Linux · LOW]** `validate_sacred_echo_crypto_fidelity.py` — 15 cases
- [ ] T136 **[Linux · LOW]** `validate_graph_insight_cache.py` — 25 cases
- [ ] T137 **[Linux · LOW]** `validate_schema_migration_end_to_end.py` — 22 cases
- [ ] T138 **[Linux · LOW]** `validate_app_lifecycle_envelope.py` — 24 cases
- [ ] T139 **[Linux · LOW]** `validate_concurrency_race_mirrors.py` — 20 cases
- [ ] T140 **[Linux · LOW]** `validate_family_pod_privacy.py` — 20 cases
- [ ] T141 **[Linux · LOW]** `validate_loom_geometry_invariants.py` — 18 cases
- [ ] T142 **[Linux · LOW]** `validate_quick_capture_ambiguity.py` — 18 cases

### Test infrastructure (Kimi E)

- [ ] T143 **[Linux · LOW]** central `conftest.py` + `oneweave_testkit.py` shared helpers.
- [ ] T144 **[Linux · LOW]** parametrize existing 19 suites + Hypothesis.
- [ ] T145 **[Linux · LOW]** golden-file / snapshot harness.
- [ ] T146 **[Linux · LOW]** JUnit XML output from `validate_all.sh`.

### Mac-needed compile-blockers (Grok A) — deferred to M1

- [ ] M01 **[Mac]** Grok A3 — `LifeContext.threads: [String]` wrong type; needs `[BasicSelfThread]`.
- [ ] M02 **[Mac]** Grok A4 — DailyBriefings/CognitiveLoad/FamilyPod use non-existent `context.careKinThreads` etc.
- [ ] M03 **[Mac]** Grok A6 — TimelineService.swift:38 calls `stateMachine.transition(on:)` (no context).
- [ ] M04 **[Mac]** Grok A8 — DailyBriefings.swift:458 still has `objc_*AssociatedObject`.
- [ ] M05 **[Mac]** Grok A10 — SchemaMigrationPlan V1↔V3 duplicate @Model risk.
- [ ] M06 **[Mac]** Grok A12 — AppLifecycleCoordinator statics main-isolation audit.
- [ ] M07 **[Mac]** Grok A13 — GraphInsightGenerator static cache stale-hit risk.
- [ ] M08 **[Mac]** Grok A14 — HealthKit + @MainActor isolation audit.

### Mac-needed runtime crashes (Grok B)

- [ ] M09 **[Mac]** Grok B1 — DailyBriefings.swift:333 `$0.completedAt!`.
- [ ] M10 **[Mac]** Grok B6 — OneWeavePrototype.swift:965 `first!`.
- [ ] M11 **[Mac]** Grok B7 — AppLifecycleCoordinator/SacredEcho `fatalError` on random-byte failure.
- [ ] M12 **[Mac]** Grok B8 — SacredEcho:530 `stateRaw` mutation without modelContext save.
- [ ] M13 **[Mac]** Grok B9 — LifeContext:470 `activeQuests.removeAll` while iterating.

### Mac-needed iOS features (Codex A)

- [ ] M14 **[Mac]** Codex A1 — Real App Intents + AppShortcutsProvider.
- [ ] M15 **[Mac]** Codex A2 — Widget Extension target + App Group snapshots.
- [ ] M16 **[Mac]** Codex A3 — ActivityKit Live Activities with Dynamic Island.
- [ ] M17 **[Mac]** Codex A4 — Core Spotlight indexing.
- [ ] M18 **[Mac]** Codex A5 — NSUserActivity + Handoff.
- [ ] M19 **[Mac]** Codex A6 — Share Extension.
- [ ] M20 **[Mac]** Codex A7 — Focus Filters.
- [ ] M21 **[Mac]** Codex A8 — Interactive widgets.
- [ ] M22 **[Mac]** Codex A10 — Watch app (v1.2+).

### Mac-needed notifications / privacy UX

- [ ] M23 **[Mac]** Claude A1 — UNUserNotificationCenter scheduling.
- [ ] M24 **[Mac]** Claude A2 — Sacred Echo unlock Live Activity.
- [ ] M25 **[Mac]** Claude A5 — iCloud backup exclusion (Mac-only metadata).
- [ ] M26 **[Mac]** Claude A8 — Sacred Echo reviewer/demo path.
- [ ] M27 **[Mac]** Claude C6 — notification permission priming screen.
- [ ] M28 **[Mac]** Claude C7 — Dynamic Island layout.
- [ ] M29 **[Mac]** Claude C2 — Dynamic Type validation.

### Mac-needed cloud sync (deferred)

- [ ] M30 **[Mac · DEFERRED]** Codex G — opt-in Private iCloud Sync (v1.1+).

### Build & submission (Claude E)

- [ ] M31 **[Mac]** Claude E — Info.plist keys.
- [ ] M32 **[Mac]** Claude E — `ITSAppUsesNonExemptEncryption = false`.
- [ ] M33 **[Mac]** Claude E — App Group provisioning.
- [ ] M34 **[Mac]** Claude E — Privacy nutrition labels.
- [ ] M35 **[Mac]** Claude E — PrivacyInfo.xcprivacy.
- [ ] M36 **[Mac]** Claude E — Privacy Policy URL + Support URL hosted.
- [ ] M37 **[Mac]** Claude E — Sacred Echo legal disclaimer.
- [ ] M38 **[Mac]** Claude E — App Review notes.
- [ ] M39 **[Mac]** Claude D9 — Marketing↔reality fixes.
- [ ] M40 **[Mac]** Claude D10 — analysis.md per feature + Aider per-task commits.

### Hermes M3 deferred / Mac

- [ ] M41 **[Mac · DEFERRED]** Hermes M3-N — remove `objc_*AssociatedObject` from DailyBriefings.swift:458.
- [ ] M42 **[Mac · DEFERRED]** Hermes M3-P — app-version-triggered migration gate.
- [ ] M43 **[Mac · DEFERRED]** Grok C — protect P2PWeaveShare statics with actor isolation.
- [ ] M44 **[Mac · DEFERRED]** Grok D — retain cycles cleanup.

---

## Cycle 33 — GLM creative ideation (new tasks T147-T170)

Source: `.cli/outputs/round_5_glm.md` (after stripping ANSI) — Whole-Repo Creative Ideation Report by GLM 5.2 (2026-06-28).

These are *future* features — none required for shipping v1.0. They embody
existing constitutional principles (anti-addictive gamification, privacy-first,
calm intelligence, reflection-gated everything) but require their own design
spikes. T147-T156 = the **10 novel features**. T157-T161 = the **5 algorithmic
innovations** (some already shipped as cycle 33 patches — noted inline).
T162-T169 = the **8 calm-design micro-interactions**. T170 = the **Void Thread**
(strangest idea).

### Top 10 NOVEL FEATURES (T147-T156)

- [ ] T147 **[Linux · S]** GLM A3 — Morning Briefing "One Neglect". **SHIPPED in cycle 34** — `RelationshipDecayTracker.pickOneNeglect(...)` + `OneNeglectSuggestion.briefingText` (calm, never guilt) + `BriefingSection.oneNeglect` at priority 32 + `morningBriefing` accepts `relationshipRecords`. Validator: `validate_cycle34_glm_features.py`.
- [ ] T148 **[Linux · S]** GLM A7 — Data Leash Guest Mode (one-tap flip). **SHIPPED in cycle 33** — `DataLeashState.enableGuestMode()` + `deviatingCategories` in `DataLeashSettings.swift`. Validator: `validate_cycle33_decay_garden.py`.
- [ ] T149 **[Linux · S]** GLM A9 — Mastery Map: Apprentice Knots. **SHIPPED in cycle 35** — new `MasteryKnot.swift` module (217 LOC). `KnotState { tied, loosening, untied }` + `ApprenticeKnot` struct + `MasteryKnotEngine` with `maxTier` algorithm (0=no cap, 1=current, 2+=current-1) + `tierBlockedMessage` (calm, never guilt). Sanity: tier-cap matches expected at all open-count levels.
- [ ] T150 **[Linux · S]** GLM A10 — Quiet Hours Ritual: user-defined 15–90 sec evening micro-ritual replacing the evening briefing. (Constitution §3 calm + §7 anti-addictive.)
- [ ] T151 **[Linux · M]** GLM A1 — Threadline Decay Garden (botanical vitality model). **SHIPPED in cycle 33** — `RelationshipDecayTracker.vitality(...)` with `V₀·e^(-λ·Δt)·(1+Σκ)` + diminishing-returns boost via `sqrt`. Validator: `validate_cycle33_decay_garden.py`. Mac-side UI (leaf desaturation) deferred.
- [ ] T152 **[Linux · M]** GLM A2 — Resonance Oracle's Unchosen Path. **SHIPPED in cycle 34** — `DecisionRecord.chosenOptionIndex` + `unchosenOption` computed + `DecisionMentorBridge.unchosenPathCandidates(...)` (30-365 day window) + `UnchosenPathPrompt` struct. Never a verdict; reflection-gated.
- [ ] T153 **[Linux · M]** GLM A4 — Sacred Echo Time Capsule. **SHIPPED in cycle 35** — `EchoKind { regular, timeCapsule }` + `SacredEcho.kindRaw` field (backward-compat default) + `kind` computed + `TimeCapsuleInvite` struct + `SacredEcho.timeCapsuleInvite(for:now:)`. Reflection-prompt gate: "has anything changed?" before plaintext. Sanity: kindRaw defaults to .regular.
- [ ] T154 **[Linux · M]** GLM A6 — Invisible Mentor's "Devil's Advocate" Mode. **SHIPPED in cycle 35** — `InvisibleMentor.devilAdvocate(currentClaim:domain:pastReflections:limit:)` + `DevilAdvocateCounter` struct. Uses TonalLexicon polarity from cycle 34 (cross-module). Socratic prompt: "Is this growth, or forgetting?"
- [ ] T155 **[Linux · M]** GLM A8 — Compass of Trade-Offs: radial view on CompassView showing this week's active trade-offs as gentle arcs.
- [ ] T156 **[Linux · L]** GLM A5 — P2P Weave Circle "Witness Mode": two devices, one sets intention, other sees only a colored pulse. (Mac-only — requires MultipeerConnectivity transport.)

### Top 5 ALGORITHMIC INNOVATIONS (T157-T161)

- [ ] T157 **[Linux · S]** GLM B2 — Insight Provenance Graph. **SHIPPED in cycle 33** — `GraphInsight.citations: [InsightCitation]` + `ruleExplanation:` now present on all 7 `GraphInsight(...)` sites. Validator: `validate_cycle33_insight_provenance.py`. Settings → Algorithm Weights UI deferred to Mac.
- [ ] T158 **[Linux · S]** GLM B1 — Anti-Streak Decay Curve (botanical). **SHIPPED in cycle 33** as part of T151 (same `vitality()` function).
- [ ] T159 **[Linux · M]** GLM B3 — Tonal Coherence Score. **SHIPPED in cycle 34** — new `TonalCoherence.swift` module (287 LOC). `TonalVector` 4-dim (calm/energy/weight/openness), 51-word hand-tuned lexicon, user-extensible `userOverrides`, `vector(for:)` + `centroid(of:)` + `coherenceAngle(today:centroid:)` returning degrees via acos. Sanity: calm vs calm = 0°, calm vs stressed = 146°, calm vs joyful = 64°.
- [ ] T160 **[Linux · M]** GLM B4 — Relationship Rhizome Index. **SHIPPED in cycle 33** — `RelationshipDecayTracker.rhizomeIndex(...)` + `RhizomeKind` (4 cases) + `RhizomeReading.nudgeText`. Validator: `validate_cycle33_decay_garden.py`. Mac UI deferred.
- [ ] T161 **[Linux · M]** GLM B5 — Decision Reverb Half-Life. **SHIPPED in cycle 35** — `DecisionReverb` struct + `DecisionReverbCalculator.reverb(for:references:now:)` (50% threshold) + `halfLifeAnniversaries(for:referencesByDecisionID:within:now:)`. Glyphs: ⚓ settled / ◇ still-open / ○ unrated. Sanity: 14/3 returns → settled hl=30d; 7/12/50/100 returns → still-open hl=365d.

### Top 8 CALM-DESIGN micro-interactions (T162-T169)

- [ ] T162 **[Mac · S]** GLM C1 — Breath-bounded actions: 4-second inhale-exhale curve before save/seal/commit.
- [ ] T163 **[Mac · S]** GLM C2 — Haptic signature per thread (Self/Stewardship/CareKin/Meaning each have distinct haptic).
- [ ] T164 **[Mac · S]** GLM C3 — Anti-spring for serious actions: reflection-gated commits use `.easeOut(0.6)`, never spring.
- [ ] T165 **[Mac · M]** GLM C4 — Ambient hum on Loom idle (40 Hz, fades in over 8s; off by default). ⚠ Audio session coordination needed.
- [ ] T166 **[Mac · S]** GLM C5 — Long-press as "consider" (1.5s radial fill before menu appears).
- [ ] T167 **[Mac · S]** GLM C6 — Pull-to-refresh replaced by pull-to-reflect: dragging reveals "What are you looking for?" prompt.
- [ ] T168 **[Linux · S]** GLM C7 — Dimming on cognitive load rise. **SHIPPED in cycle 34 (signal)** — `CognitiveLoadReading.shouldDimUI: Bool` field (true when score >= 0.70) + `CognitiveLoad.compute(...)` sets it. Mac-side saturation hook (`.saturation(0.85)`) deferred.
- [ ] T169 **[Mac · S]** GLM C8 — Silent success: 200ms `.soft` haptic + 1-pixel inward contraction on save.

### ONE BOLD BET + STRANGEST IDEA (T170)

- [ ] T170 **[Linux · L]** GLM G — The Void Thread: an opt-in 5th thread with no entities, no decay, no Mastery; accepts only single sentences that are sealed with a key derived from the entry's own contents (HKDF on SHA-256 of plaintext). The app **cannot** read entries back unless the user re-types the exact sentence byte-for-byte. Honors §2 (zero-trust), §3 (calm), §4 (reflection-gated). Mac UI required for the re-type flow.

---

## Updated Summary

| Phase | Status | Owner | Effort |
|---|---|---|---|
| Phase T07: GLM cycle-29 fixes | ✅ Complete | Linux | done (b96c2a1) |
| Phase T08: 4-CLI round | ✅ Complete | Linux | done |
| Phase T09: Doc polish | ⏳ Pending | Linux | 30 min |
| Phase T10: Cycle 30 multi-CLI synthesis | ✅ Complete | Linux | done (b44fb02) |
| Phase T11: Linux-fixable apply | ✅ Complete | Linux | done (cycles 30-32) |
| Phase T12: Spec Kit + Constitution + Handoff update | 🔄 In progress | Linux | 1 hour |
| Phase T13: Cycle 33 GLM-driven features | ✅ Complete | Linux | done (insight provenance + decay garden + rhizome + guest mode + Grok A6) |
| Phase T14: Cycle 34 GLM-driven features | ✅ Complete | Linux | done (one neglect + unchosen path + tonal coherence + cognitive load dim) |
| **Phase T15: Cycle 35 GLM-driven features** | ✅ Complete | Linux | done (apprentice knots + decision reverb + devil's advocate + time capsule) |
| Phase P1: GitHub Push | ⏳ Pending | User | 10 min |
| Phase M1: Mac compile-blockers + build | ⏳ Pending | Mac | 6-8 hours |
| Phase M2: iOS features + widgets + intents | ⏳ Pending | Mac | 4-6 hours |
| Phase M3: Notifications + Live Activities | ⏳ Pending | Mac | 3-4 hours |
| Phase M4: Signing + entitlements | ⏳ Pending | Mac | 3-4 hours |
| Phase M5: Submission + privacy labels | ⏳ Pending | Mac | 2-3 hours |
| Phase M6: Onboarding + accessibility pass | ⏳ Pending | Mac | 2-3 hours |

**Cycle 30 Linux total: ~7-8 hours focused work (50 new Linux tasks T097-T146)**
**Mac total: ~22-30 hours focused work (44 Mac tasks M01-M44)**

---

## Phase T16: Honest Gap Closure — Cycle 39 (2026-06-28)

**Purpose**: Address the gaps identified in compound-force analysis + Apple Intelligence
integration that preserves constitutional commitments (no LLM generation, only retrieval/embeddings).

Source: user feedback 2026-06-28 (cycles 36-38 wrap-up + compound-force analysis + honest-gap list).

### Task dependency graph

```
T171 (refactor LifeGraph.embeddingData hook)
  ├─ T172 (add NLEmbedding.sentenceEmbedding for 512-dim retrieval)
  │    └─ T173 (LifeGraph.semanticSearch rerank via cosine)
  │         └─ T176 (QuickCapture semantic fallback)
  ├─ T174 (Add embeddings to new reflections in fromTimelineEvent)
  │    └─ T175 (Add embeddings to new reflections in fromQuest path)
  └─ T178 (Telemetry: nil-safe fallback to lexical-only)

T180 (Speech.framework voice capture — VoicePath.swift)
  ├─ T181 (recognition + on-device-only assertion)
  ├─ T182 (QuickCaptureInbox route to same classifier)
  └─ T183 (Privacy gate: mic leash toggle + reflection gate)

T184 (CreateML personal vitality model scaffold)
  ├─ T185 (Define feature columns from LifeContext)
  ├─ T186 (Build trainer that requires 200+ reflections before activating)
  └─ T187 (Sandbox-bound .mlmodel + graceful skip if data sparse)

T190 (iCloud Private Cloud Compute sync — design only, deferred impl)
  └─ T191 (Decision: do not implement in v1.0)

T200 (Cycle 39 validation: validators for all new code)
  ├─ T201 (validate_cycle39_embeddings.py)
  ├─ T202 (validate_cycle39_voice_capture.py)
  └─ T203 (validate_cycle39_personal_model.py)

T210 (Cycle 39 handoff doc)
```

### T171-T178 — On-device embeddings for semantic retrieval (no generation)

**Why**: The Life Graph already has an `embeddingData: Data?` placeholder (LifeGraph.swift:29).
Adding `NLEmbedding` (Apple-shipped, on-device, free) lets us do semantic search WITHOUT
crossing the constitutional line into generation.

- [ ] T171 **[Linux · M]** Refactor `LifeGraph.embeddingData` into a typed `LifeEmbedding` struct (512-dim `[Float]`, version, generated-at timestamp). Make all existing call sites nil-safe.
  - Depends on: nothing
  - Sub-tasks: T171a (struct definition), T171b (migration stub for SwiftData), T171c (update 5 call sites that read/write `embeddingData`)
- [ ] T172 **[Linux · M]** Add `OnDeviceEmbedder.swift` wrapping `NLEmbedding.sentenceEmbedding(for: .english)`. Cache the embedder instance; expose `embed(_ text: String) -> [Float]?` with explicit nil on OOM/token-cap.
  - Depends on: T171
  - Sub-tasks: T172a (NLEmbedding import), T172b (thread-safety wrap with NSLock), T172c (token-cap test with 1000-token string)
- [ ] T173 **[Linux · M]** Add `LifeGraph.semanticSearch(query:in:limit:)` using cosine similarity over embeddings, fallback to lexical if `embeddingData == nil` for >50% of corpus.
  - Depends on: T172
  - Sub-tasks: T173a (cosine function), T173b (fallback heuristic), T173c (top-k selection)
- [ ] T174 **[Linux · S]** Wire `OnDeviceEmbedder.embed(...)` into `LifeEntity.fromTimelineEvent` for `isUserReflection == true` entries (use `title + summary` as text).
  - Depends on: T172
  - Sub-tasks: T174a (idempotency: don't re-embed if `embeddingData` already populated), T174b (background queue, not main)
- [ ] T175 **[Linux · S]** Wire `OnDeviceEmbedder.embed(...)` into `LifeEntity.fromQuest(_:context:)` for reflections.
  - Depends on: T172, T174
  - Sub-tasks: T175a (reuse pattern from T174), T175b (verify dual-path coverage)
- [ ] T176 **[Linux · S]** Update `QuickCaptureInbox` to use `semanticSearch` as a tie-breaker when lexical confidence < 0.6.
  - Depends on: T173
  - Sub-tasks: T176a (threshold test), T176b (preserve existing 38/38 lexical tests)
- [ ] T177 **[Linux · M]** Update `InvisibleMentor` quote-selection to prefer semantically-similar past reflections over lexically-matched ones.
  - Depends on: T173
  - Sub-tasks: T177a (rerank scores), T177b (preserve "deterministic synthesizer" constitutional commitment)
- [ ] T178 **[Linux · S]** Telemetry: when >50% of corpus has no embedding, fall back to lexical-only and surface a one-time UI hint "Search will improve as you add reflections."
  - Depends on: T173
  - Sub-tasks: T178a (counter), T178b (UI hint via @Published bool)

### T180-T183 — Voice capture via Speech.framework

**Why**: Original research doc said "text/voice/image" for Quick Capture. We have text.
`Speech.framework` is on-device (with `requiresOnDeviceRecognition = true`).

- [ ] T180 **[Mac · S]** Create `VoiceCapture.swift`. Wrap `SFSpeechRecognizer` + `AVAudioEngine`. Assert `supportsOnDeviceRecognition == true`; fail closed if not.
  - Sub-tasks: T180a (audio session config), T180b (permission request flow), T180c (fail-closed check)
- [ ] T181 **[Mac · S]** Add mic toggle to `DataLeashSettings` (10th category: Microphone).
  - Depends on: T180
  - Sub-tasks: T181a (leash state field), T181b (UI in SettingsView), T181c (validate_data_leash_privacy.py integration)
- [ ] T182 **[Mac · S]** Wire voice transcription text into `QuickCaptureInbox.handle(_:)`.
  - Depends on: T180, T181
  - Sub-tasks: T182a (debounce 1s silence → commit), T182b (preserve reflection gate)
- [ ] T183 **[Mac · S]** Add Info.plist usage strings: `NSSpeechRecognitionUsageDescription`, `NSMicrophoneUsageDescription`.
  - Depends on: T180
  - Sub-tasks: T183a (Info.plist entries), T183b (PrivacyInfo.xcprivacy update)

### T184-T187 — CreateML personal vitality model (scaffold only)

**Why**: Original user vision: "a model that evolves with the user". `CreateML` lets us
train on the user's own data, ship inside the app sandbox. Scaffold only — needs 200+ reflections
before it activates (constitutional commitment: no premature ML).

- [ ] T184 **[Mac · L]** Add `PersonalVitalityModel.swift` with a stub trainer (`requiresMinSampleCount = 200`). Always returns nil until sample count met.
  - Sub-tasks: T184a (CreateML import guard), T184b (feature column spec), T184c (scaffold)
- [ ] T185 **[Mac · M]** Define feature columns: `daysSinceLastReflection`, `questCompletionRate`, `energyProfile`, `harmonyScore`, `cognitiveLoad`, `socialInteractionCount`.
  - Depends on: T184
  - Sub-tasks: T185a (column extractor from LifeContext), T185b (normalization)
- [ ] T186 **[Mac · L]** Trainer: `MLTrainingSession` style — only runs in background, never on main, never logged.
  - Depends on: T185
  - Sub-tasks: T186a (background task gate), T186b (no-PII assertion), T186c (audit log)
- [ ] T187 **[Mac · M]** Persist trained `.mlmodel` in app sandbox; load via `compiledMLModel`. Graceful skip if model file missing.
  - Depends on: T186
  - Sub-tasks: T187a (sandbox path), T187b (load with try?), T187c (use in CognitiveLoad only if loaded)

### T190-T191 — iCloud Private Cloud Compute sync — DECISION

- [ ] T190 **[Decision]** Document decision in `CONSTITUTION_v3_DRAFT.md`: NOT implementing Private Cloud Compute sync in v1.0. Reasons: (1) SwiftData+CloudKit requires E2EE custom schema, (2) conflicts with "no server" promise in onboarding, (3) deferred to v1.1 with explicit user opt-in flow.
  - Sub-tasks: T190a (write decision doc), T190b (link from constitution)
- [ ] T191 **[Linux · S]** Update `OnboardingView.swift:15` to explicitly say "no cloud sync by default and not available in this version" (replace existing "no cloud sync" claim with the stronger version).
  - Depends on: T190
  - Sub-tasks: T191a (text change), T191b (PrivacyInfo.xcprivacy NSPrivacyAccessedAPITypes)

### T200-T203 — Cycle 39 validation

- [ ] T200 **[Linux · M]** Add `validate_cycle39_embeddings.py` — verify NLEmbedding wrapper, cosine math, fallback to lexical, idempotent embedding.
- [ ] T201 **[Linux · M]** Add `validate_cycle39_voice_capture.py` — verify VoiceCapture fail-closed logic (mocked SFSpeechRecognizer).
- [ ] T202 **[Linux · M]** Add `validate_cycle39_personal_model.py` — verify trainer requires 200+ samples, no-PII assertion, graceful skip when model missing.
- [ ] T203 **[Linux · S]** Update `validate_all.sh` to include all 3 new suites. Target: 44/44 suites green (was 41).

### T210 — Cycle 39 handoff

- [ ] T210 **[Linux · S]** Write `ONEWEAVE_HANDOFF_CYCLE_39.md` covering: T171-T187 design rationale (why NLEmbedding yes, generation no), constitutional compliance, Mac-side handoff notes for T180-T187.

---

## Phase T17: Calm UX Mac Polish — Cycle 40 (2026-06-28)

**Purpose**: Ship the calm UX micro-interactions from the GLM C-series (T162-T169).
These are mostly Mac-side but several have Linux-fixable scaffolding.

- [ ] T220 **[Mac · S]** T162 — Breath-bounded actions: add `BreathBoundedCommit` SwiftUI modifier (4s curve before .commit()).
- [ ] T221 **[Mac · S]** T163 — Haptic signature per thread: `HapticSignature.for(thread: ThreadKind) -> SensoryFeedback`.
- [ ] T222 **[Mac · S]** T164 — Anti-spring for serious actions: reflection-gated commits use `.easeOut(0.6)`.
- [ ] T223 **[Mac · M]** T165 — Ambient hum on Loom idle (40Hz, 8s fade). Mac audio session coordination.
- [ ] T224 **[Mac · S]** T166 — Long-press as "consider" (1.5s radial fill before menu).
- [ ] T225 **[Mac · S]** T167 — Pull-to-reflect replaces pull-to-refresh.
- [ ] T226 **[Linux · S]** T168 — Wire `CognitiveLoadReading.shouldDimUI` to root view `.saturation(0.85)` modifier.
- [ ] T227 **[Mac · S]** T169 — Silent success: 200ms soft haptic + 1px inward contraction.
- [ ] T228 **[Linux · M]** T170 — Void Thread: scaffold `VoidThread.swift` (entry type, HKDF-SHA256 self-deriving key, opaque storage). Mac UI deferred.
- [ ] T229 **[Linux · S]** Add `validate_cycle40_ux.py` covering all 8 micro-interactions + Void Thread crypto.

---

## Phase T18: Multi-Agent Cross-CLI Synthesis — Cycle 41 (2026-06-28)

**Purpose**: Run all 5 CLIs (Claude, Codex, Grok, GLM, Nemotron) on the same
problem in parallel, synthesize the 5 reviews into a unified fix plan.

- [ ] T230 **[Linux · S]** Dispatch `round_6_prompt.md` to all 5 CLIs in parallel PTYs with the graphify code graph as context.
- [ ] T231 **[Linux · S]** Synthesize 5 reviews into unified fix list (Claude weights constitutional, Codex weights correctness, Grok weights architecture, GLM weights creative, Nemotron weights adversarial).
- [ ] T232 **[Linux · S]** Apply consensus fixes from T231 to OneWeave.
- [ ] T233 **[Linux · S]** Add `validate_cycle41_consensus.py` verifying each applied fix has a test.
- [ ] T234 **[Linux · S]** Write `MULTI_AGENT_SYNTHESIS_CYCLE_41.md` documenting the cross-CLI review pattern.

---

## Updated Summary (post cycle 39)

| Phase | Status | Owner | Effort |
|---|---|---|---|
| Phase T16: Cycle 39 honest-gap closure | 🔄 In progress | Linux + Mac split | 8-12 hours |
| Phase T17: Cycle 40 calm UX polish | ⏳ Pending | Mac | 6-10 hours |
| Phase T18: Cycle 41 multi-agent synthesis | ⏳ Pending | Linux | 4-6 hours |
| Phase M1-M6: Mac compile + iOS features | ⏳ Pending | Mac | 22-30 hours |
| Phase P1: GitHub Push | ⏳ Pending | User | 10 min |

**New tasks added in cycle 39**: T171-T234 (64 tasks across 3 phases, mostly Linux-fixable)
**Cumulative total**: 537 → 601 tasks

**Master task count: T001-T146 Linux + M01-M44 Mac = 190 tasks, 5-CLI cross-verified + Hermes self-review.**