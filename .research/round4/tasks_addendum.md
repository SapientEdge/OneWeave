---

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

## Updated Summary

| Phase | Status | Owner | Effort |
|---|---|---|---|
| Phase T07: GLM cycle-29 fixes | ✅ Complete | Linux | done (b96c2a1) |
| Phase T08: 4-CLI round | ✅ Complete | Linux | done |
| Phase T09: Doc polish | ⏳ Pending | Linux | 30 min |
| **Phase T10: Cycle 30 multi-CLI synthesis** | 🔄 In progress | Linux | ~4 hours |
| **Phase T11: Linux-fixable apply** | 🔄 In progress | Linux | ~6 hours |
| Phase T12: Spec Kit + Constitution + Handoff update | ⏳ Pending | Linux | 1 hour |
| Phase P1: GitHub Push | ⏳ Pending | User | 10 min |
| Phase M1: Mac compile-blockers + build | ⏳ Pending | Mac | 6-8 hours |
| Phase M2: iOS features + widgets + intents | ⏳ Pending | Mac | 4-6 hours |
| Phase M3: Notifications + Live Activities | ⏳ Pending | Mac | 3-4 hours |
| Phase M4: Signing + entitlements | ⏳ Pending | Mac | 3-4 hours |
| Phase M5: Submission + privacy labels | ⏳ Pending | Mac | 2-3 hours |
| Phase M6: Onboarding + accessibility pass | ⏳ Pending | Mac | 2-3 hours |

**Cycle 30 Linux total: ~7-8 hours focused work (50 new Linux tasks T097-T146)**
**Mac total: ~22-30 hours focused work (44 Mac tasks M01-M44)**

**Master task count: T001-T146 Linux + M01-M44 Mac = 190 tasks, 5-CLI cross-verified + Hermes self-review.**