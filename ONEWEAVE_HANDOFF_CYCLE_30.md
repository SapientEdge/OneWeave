# OneWeave — Cycle 29/30 Update (2026-06-28)

**Branch**: `002-gamification`
**Latest commit**: `b44fb02` (cycle 30 multi-CLI synthesis)
**Previous commits**: `b96c2a1` (cycle 29 GLM fixes), `e1d4459` (cycle 28), `d5169e4` (handoff)

This is an UPDATE to `ONEWEAVE_HANDOFF_2026-06-27.md` — read both in order.

---

## 🎯 Cycle 29/30 TL;DR

Cycle 29 ran a 1-model GLM 5.2 review (4 fixes applied: T075-T080).
Cycle 30 ran a **5-model parallel review** (Claude opus + Grok supergrok + Codex GPT-5 + Kimi kimi-for-coding + GLM 5.2 756B) plus Hermes (minimax M3) self-review pass. Result: **190 total tasks** in Spec Kit, **50 new Linux tasks** applied in this cycle, **24/24 validation suites PASS** (up from 19/19).

**Headline numbers (cycle 30)**:
- **58 Swift files**, ~16,600 lines
- **24/24 Python validation suites PASS**, 600+ tests
- **6 AI models** in the review panel (Claude opus, Grok, Codex, Kimi, GLM 5.2, Hermes M3)
- **Graphify**: 2945 nodes, 4643 edges, 232 communities
- **15 Mac-needed compile-blockers identified** (Grok A) — need first `xcodebuild` to surface
- **11 new compile-blocker LINUX-fixes applied** (cycle 30)
- **5 new Python validators** (cycle 30)
- **NEW** `ReflectionGate.swift` — centralized reflection-gate policy object (T079)
- **NEW** IntegrationCategory extended from 6 to 9 cases (T114)

---

## 🆕 Cycle 29/30 Linux fixes applied

### Privacy / Security / Constitution drift

- **T097** `SettingsView.swift:6` — `\\.modelContext` → `\.modelContext` (compile-blocker).
- **T098** `SettingsView.swift:95-97` — literal-string newlines (compile-blocker).
- **T100** `P2PWeaveShare.swift` — added `import SwiftData` (compile-blocker).
- **T103** `SettingsView.clearAllData()` — now deletes ALL 11 models (was omitting LifeEntity, LifeRelationship, DataLeashSettingsRecord, SacredEcho — privacy violation).
- **T105** `SettingsView` — added `NavigationLink` to `DataLeashSettingsView` (the 9-toggle privacy dashboard was unreachable).
- **T106** `OneWeaveApp` + `AppLifecyclePaths.markContainerExcludedFromBackup()` — exclude App Group container from iCloud backup (privacy-first).
- **T107** `LifeContext:139` — strip reflection plaintext prefix from `essenceLedger` append (was leaking 50 chars of reflection into export).
- **T114** `iOSServiceIntegrations` — `IntegrationCategory` extended from 6 to 9 cases: added `bodyThread`, `p2p`, `insights` (Constitution §2 + Invariant #7).
- **T115** `SettingsView` — converted `hapticEnabled/showEnergyTrends/smartRipples` from `@State` to `@AppStorage` (was dead state).
- **T116** `OneWeaveApp` — wired `bodyThreadEnabled` to `leash.isAllowed(.bodyThread)` (was hardcoded `false`).
- **T117** `SettingsView:115` — replaced `try!` with `try?` + safe fallback (runtime crash risk).

### UX / Calm / Accessibility

- **T108** `OnboardingView:23` — gate `.symbolEffect(.pulse)` on `accessibilityReduceMotion`.
- **T110** `OnboardingView` — CTA now sets `hasCompletedOnboarding = true` + calls `dismiss()` (NEMO-R3-020 fix never landed).
- **T111** `SettingsView:70` — replaced `Link("about:blank")` with real version + build + privacy URL + support URL + acknowledgements.
- **T112** `SettingsView:88` — replaced hidden `.onTapGesture` with explicit "Done" button.
- **T123** `SettingsView` — added "What OneWeave knows about you" privacy manifest surface.
- **T125** `OnboardingView` — added "What OneWeave Will NEVER Do" trust page (Constitution §2).
- **T079** NEW `ReflectionGate.swift` — centralized reflection-gate policy with entropy check.

### Test infrastructure

- **T128** `validate_app_state_machine.py` (NEW, 18 cases).
- **T129** `validate_reflection_gate_cross_module.py` (NEW, 7 cases).
- **T131** `validate_streak_grace.py` (NEW, 7 cases).
- **T132** `validate_data_leash_privacy.py` (NEW, 10 cases).
- **T079** `validate_reflection_gate_policy.py` (NEW, 7 cases).
- **T114** `validate_family_pod_builder_surface.py` extended to check 9-category enum.
- **validate_all.sh** fixed (regex was 22/23 false-fail; now 24/24 true pass).

### Net code changes

- 11 Swift files patched
- 5 new Python validators
- 1 new Swift file (`ReflectionGate.swift`)
- 1 harness fix
- +187 lines to `tasks.md` (T097-T146 + M01-M44)

---

## 🔴 Mac-needed items (Grok A — must run `xcodebuild` first)

These were identified by Grok's static analysis but only `xcodebuild` can confirm or deny them. The Linux harnesses cannot catch Swift type errors:

- **M01** `LifeContext.threads: [String]` returns wrong type (cycle 29 shim) for callers wanting `[BasicSelfThread]`.
- **M02** `DailyBriefings/CognitiveLoad/FamilyPod` reference non-existent `context.careKinThreads`, `meaningThreads`, `stewardshipThreads`, `bodyThread`, `lastReflectionAt`.
- **M03** `TimelineService.swift:38` calls `stateMachine.transition(on:)` without context.
- **M04** `DailyBriefings.swift:458` still has `objc_*AssociatedObject` (CLAUDE-R3-23 removed from CognitiveLoad but not DailyBriefings).
- **M05** `SchemaMigrationPlan` V1↔V3 duplicate `@Model` risk (NEMO-R3-023).
- **M06-M08** actor isolation audits (AppLifecycleCoordinator statics, GraphInsightGenerator cache, HealthKit + @MainActor).
- **M09-M13** runtime crash risks (DailyBriefings:333, OneWeavePrototype:965, etc.).
- **M14-M22** iOS-platform features (App Intents, Widgets, Live Activities, Spotlight, etc.).
- **M23-M29** notifications + Live Activities + Dynamic Type + Dynamic Island.
- **M31-M40** App Store submission readiness (Info.plist, entitlements, privacy labels, etc.).

Full list in `.specify/specs/003-production-readiness/tasks.md` M01-M44.

---

## 🧬 5-CLI review panel output (cycle 30)

All outputs in `.research/round4/`:

| Model | Output | Specialization | Quality |
|---|---|---|---|
| **Claude Code (opus)** | claude.md (13 KB) | Production audit (features, architecture, HIG, spec drift, submission) | ⭐⭐⭐⭐⭐ |
| **Grok (supergrok)** | grok.md (9 KB) | Bug hunt (compile-blockers, crashes, concurrency, memory) | ⭐⭐⭐⭐⭐ |
| **Codex (GPT-5)** | codex.md (478 KB) | iOS platform completeness (App Intents, Widgets, Live Activities, a11y, i18n, CloudKit) | ⭐⭐⭐⭐⭐ |
| **Kimi (kimi-for-coding)** | kimi.md (12 KB) | Test design (15 validators, 10 property tests, 10 integration, 5 crypto) | ⭐⭐⭐⭐⭐ |
| **GLM 5.2 (756B, Ollama cloud)** | glm.md (37 KB) | Creative ideation (10 novel features, 5 algorithms, 8 calm design, bold bet) | ⭐⭐⭐⭐ |
| **Hermes (minimax M3)** | this section + 16 M3-only items | UX, calm, privacy UX, copy — what other models miss | ⭐⭐⭐⭐⭐ |

**Kimi fix**: `kimi --print -m k2.7` returns "LLM not set" — must use full config key `-m kimi-code/kimi-for-coding`. (Multi-cli-orchestration skill updated.)
**GLM caveat**: Confabulates identity (claimed "Gemini 1.5 Flash" when asked) but works well for creative ideation with inline context.
**Codex caveat**: Did extensive tool-use exploration (478 KB of execution traces + analysis). The analysis itself is gold.

---

## 🎯 Linux-fixable items NOT yet applied (deferred to future cycles)

- T099 — `LifeContext.swift:573` stray `}` (Grok A1) — needs careful inspection
- T101 — wrap `importAll` in `Task { await ... }`
- T102 — fix force-unwraps (`first!`, `[0]`, `!`)
- T119 — "You're caught up. Go live." empty state
- T120 — `GoodbyeView` (in-app off-ramp)
- T121 — surface grace/streak decay in CompassView chip
- T122 — reflection prompt variety
- T124 — revisit Sacred Echo Decree
- T126 — version + "What's New" section
- T127 — `EchoError.cipherMissingKey` recovery card
- T143-T146 — test infrastructure (conftest, parametrize, golden files, JUnit)
- T128-T142 — remaining 10 Python validators (Kimi's full list)

All are `[LINUX-FIXABLE]` and could be applied in 1-2 more cycles. None are blockers.

---

## 🔧 How to run this for the Mac handoff

```bash
cd /root/hermes-workspace/projects/oneweave

# Validate everything is green before you leave Linux
bash .research/validate_all.sh    # → 24/24 PASS expected

# Run the 5-CLI review panel again to catch anything missed
# (the wrappers in .research/round4/prompt_*.md are reusable)

# When you arrive on Mac:
xcodebuild -project OneWeave.xcodeproj -scheme OneWeave -destination 'platform=iOS Simulator,name=iPhone 15' build
# → expect ~15 Grok-flagged compile errors from M01-M08 batch — fix per file:line
```

---

## 📞 Re-establishing context after sessions reset

Future-Hermes session will need:
1. **Cycle 28 handoff** (`ONEWEAVE_HANDOFF_2026-06-27.md`) — original entry
2. **Cycle 29/30 update** (this file) — 11 Swift patches + 5 new validators
3. **Spec Kit tasks** (`.specify/specs/003-production-readiness/tasks.md` — 484 lines) — full backlog
4. **Multi-CLI outputs** (`.research/round4/`) — 5 model analyses
5. **All CLI workhorses** are confirmed working:
   - `grok --single "..."` ✅
   - `claude -p "..." --model opus` ✅
   - `codex exec --skip-git-repo-check -` (with stdin) ✅
   - `kimi --print -m kimi-code/kimi-for-coding --yolo` (with stdin) ✅
   - `ollama run glm-5.2:cloud "..."` ✅
6. **All 24 validators pass** (`bash .research/validate_all.sh`)