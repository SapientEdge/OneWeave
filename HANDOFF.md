# OneWeave — Mac Build Handoff (Claude Cowork + Lovable)

**Audience:** Claude cowork (CLI coding agent) + Lovable (web app builder)
**Goal:** Take OneWeave from "Linux-validated code" to "shipping iOS app on the App Store"
**Repo:** https://github.com/SapientEdge/OneWeave (PRIVATE)
**Last validated on Linux:** 2026-07-05, 42/43 validators green

---

## 🎯 What is OneWeave?

**OneWeave** is a **privacy-first Life OS** for iOS. It's a single-user app that helps you manage your life across 4 interconnected "threads" (Self, Stewardship, Care & Kin, Meaning & Legacy) without ever sending your data to anyone. Everything stays on your device. No accounts. No cloud sync. No ads. No analytics. No training on your data.

**The market it serves:** People tired of apps that:
- Sell their data
- Use gamification against them (streak-shaming, dark patterns)
- Bombard them with notifications
- Require cloud accounts to use
- Optimize for engagement over well-being

**The thesis:** You can build a Life OS that's *anti-addictive* by design, where:
- Reflection gates every meaningful action
- Cognitive load triggers a Weave Pause (not a notification)
- Sacred Echoes are encrypted on-device (fail-closed crypto)
- The app literally fades UI when you're overloaded
- Data stays local forever

---

## 🏆 What is the end goal?

**Ship OneWeave v1.0 to the App Store.** Specifically:

| Milestone | Acceptance criteria |
|---|---|
| **Build cleanly in Xcode 16** | All 75 Swift files compile, no errors |
| **Pass all 43 Python validators on Mac** | `bash .research/validate_all.sh` → 43 green |
| **Run on iOS 17+ simulator** | CompassView + GamificationHUD render correctly |
| **AppIntents work** | "Hey Siri, capture a quick thought" + Siri shortcuts |
| **Widgets display** | HarmonyWidget + QuestWidget render on home screen |
| **Privacy verified** | No network calls, no telemetry, all data local |
| **TestFlight beta** | Internal testers can install + use without crashes |
| **App Store review** | Passes Apple's privacy review (no data collection) |

**The end state:** A user can install OneWeave from the App Store, use it offline forever, and never worry about their reflections leaking.

---

## 📂 What's in this repo (read this first)

### Source code (THE ACTUAL APP)

```
Sources/OneWeave/                    # 75 Swift files, ~22k LOC
├── OneWeaveApp.swift                # App entry point
├── CompassView.swift                # Main UI: Living Loom, HUD, prompts
├── ThreadDetailView.swift           # Per-thread detail with gamification
├── QuickCaptureInbox.swift          # Inbox pattern (capture → process later)
├── AppLifecycleCoordinator.swift     # State machine: idle/capturing/weaving/reflecting/lowEnergy/highFlow
├── AppStateMachine.swift            # State transitions
├── CognitiveLoad.swift              # ⭐ Anti-nag algorithm (Weave Pause)
├── ReflectionGate.swift             # ⭐ Every action requires non-empty reflection
├── DataLeashSettings.swift          # ⭐ 10 toggles for integrations (privacy)
├── iOSServiceIntegrations.swift     # Calendar/Contacts/HealthKit/Reminders/Mail/Notes
├── LifeGraph.swift                   # Cross-thread relationships + LivingGraphLoom
├── LifeContext.swift                 # Central state hub
├── LifeMoment.swift                  # Cycle 46: capture moments with Vision OCR
├── LifeMomentService.swift           # Cycle 46: moment orchestration
├── LifeMomentCaptureView.swift       # Cycle 46: capture UI
├── LifeMomentReflectionSheet.swift   # Cycle 46: reflection prompt
├── LifeMomentDetailView.swift        # Cycle 46: view captured moment
├── LifeMomentTimelineEntry.swift     # Cycle 46: widget timeline
├── LifeMomentCaptureAppShortcuts.swift  # Cycle 46: AppIntents
├── MomentSealer.swift                # Cycle 46: AES-256-GCM encryption
├── VisionPipeline.swift              # Cycle 46: on-device OCR
├── SacredEcho.swift                  # Encrypted legacy messages (fail-closed)
├── PortableExport.swift              # User can export their data
├── InvisibleMentor.swift             # On-device wisdom (algorithmic, no LLM)
├── DecisionLog.swift                 # Record decisions with reflection
├── FamilyPod.swift                   # Multi-device P2P (no cloud)
├── P2PWeaveShare.swift                # Share via Signal Protocol (P2P, not server)
├── DailyBriefings.swift              # Morning + evening briefings
├── QuickCaptureInbox.swift           # Inbox pattern
├── PortableExport.swift              # Export bundle
├── RelationshipDecayTracker.swift    # Track which relationships need attention
├── WeaveQuest.swift                  # Quest generation
├── QuestService.swift                # Quest completion (reflection-gated)
├── MasteryKnot.swift                 # Mastery tier (novice → grandmaster)
├── MasteryMapView.swift              # Visualization
├── GamificationHUD components        # Essence, Level, Streak, Harmony
├── AppIntents                        # Shortcuts integration
├── OneWeaveWidgetStubs.swift         # Widget code (HarmonyWidget, QuestWidget, LiveActivity)
├── PrivacyInfo.xcprivacy             # Apple's privacy manifest
└── ... (50+ more Swift files)
```

### Public documentation (KEEP ALL)

```
README.md                    # Project overview, status, build instructions
ARCHITECTURE.md              # Module structure, layered design
CLAUDE_COWORK_BRIEF.md       # ⭐ Specifically for Claude cowork
BUILDING_ON_MAC.md           # ⭐ Step-by-step Mac build (for Lovable)
PRIVACY.md                   # Privacy architecture
PrivacyPolicy.md             # User-facing privacy policy (App Store)
LICENSE                      # License
CONTRIBUTING.md              # How to contribute
CONVENTIONS.md               # Code conventions
MANIFEST.md                  # File index
FEATURE_CATALOG.md           # All features described
IMPLEMENTED_FEATURES.md      # What's actually implemented
LAUNCH_CHECKLIST.md          # Pre-launch checklist
ONEWEAVE_AUDIT_REPORT_2026.md # Security + privacy audit
ONEWEAVE_GAMIFICATION_DESIGN.md # Gamification philosophy + mechanics
ONEWEAVE_MONETIZATION_RETENTION.md # Subscription model + retention
THREAT_MODEL.md              # What threats does the app defend against
VALIDATION_REPORT.md         # Linux validation results
FIRST_WEEK_ON_MAC.md         # Mac dev setup
COMPOUND_FORCE_ANALYSIS.md   # System dynamics analysis
MARKETING.md                 # Marketing strategy
MARKETING_DIAGRAMS.txt        # Marketing diagrams
PATCH_SUGGESTIONS_AND_FIXES.md # Known patches
CONSTITUTION_v3_DRAFT.md     # v3 constitutional amendment draft
```

### Linux validation suite (CRITICAL — runs on Mac too)

```
.research/validate_*.py                # 34 Python validators
.research/validate_all.sh              # Harness to run all validators
audit/validators/validate_*.py         # 10 audit-related validators
audit/algorithm_fuzz.py                # Algorithm fuzzing
audit/algorithm_oracle.py              # Algorithm verification oracle
audit/algorithm_inventory.json         # Algorithm inventory
audit/AUDIT_REPORT.md                  # Audit results
audit/inventory.py                     # Audit inventory
audit/verify_against_source.py         # Source verification
```

### GitHub automation (already configured)

```
.github/ISSUE_TEMPLATE/         # Bug + feature request templates
.github/agents/                 # GitHub Copilot agent configs
.github/prompts/                # Copilot prompt files
.github/workflows/ci.yml        # CI pipeline
.github/pull_request_template.md
.github/copilot-instructions.md
AGENTS.md                       # Graphify usage notes (project-level)
```

### Scripts (panel dispatch — NOT for Mac build)

```
scripts/dispatch_oneweave.sh    # Internal CLI dispatch (don't need)
scripts/dispatch_panel.sh       # Multi-CLI panel (don't need)
```

---

## 🔒 What's the privacy model?

**The hard rule:** Zero data leaves the device. Period.

| Surface | Behavior |
|---|---|
| **No accounts** | No login, no signup, no email collection |
| **No cloud sync** | All data in local SwiftData store |
| **No analytics** | No Firebase, no Mixpanel, no anything |
| **No telemetry** | No crashlytics, no sentry |
| **No Core ML / network** | `grep -rE "URLSession\|CloudKit\|CoreML\|Network" Sources/OneWeave/` should return 0 hits in production code |
| **No training** | No LLM APIs called. The "InvisibleMentor" is purely algorithmic |
| **AppIntents** | Yes (Siri shortcuts) but they run locally |
| **Photos** | Optional, gated by 10th Data Leash toggle (default OFF) |
| **HealthKit** | Optional, gated by Data Leash toggle (default OFF) |
| **Family Pod P2P** | Optional, uses Signal Protocol (E2E encrypted) over local network |

**The Data Leash:** 10 toggles in `DataLeashSettings.swift`:
1. Calendar
2. Contacts
3. HealthKit
4. Reminders
5. Mail
6. Notes
7. Body Thread (HealthKit wrapper)
8. P2P
9. Insights
10. **Photos** (added in cycle 46)

Each is checked BEFORE any data access. Off = data not even attempted.

**Sacred Echo crypto:** AES-256-GCM with HKDF-SHA256. Fail-closed (no test seed fallback). The encryption key is in Keychain (never leaves device).

**PrivacyInfo.xcprivacy** declares:
- `NSPrivacyTracking = false`
- `NSPrivacyCollectedDataTypes = []` (empty — collects nothing)
- `NSPrivacyAccessedAPITypes = []` (no required-reason API access)

---

## ⚙️ What's the architecture?

### Layered structure (top to bottom)

```
┌─────────────────────────────────────────────────┐
│ OneWeaveApp (entry, @main)                       │
│   ↓                                              │
│ SwiftUI Views (CompassView, ThreadDetailView,    │
│ LifeMomentCaptureView, GamificationHUD)          │
│   ↓                                              │
│ Service Layer (LifeMomentService, QuestService, │
│ CognitiveLoad, ReflectionGate, AppLifecycle)     │
│   ↓                                              │
│ Data Layer (SwiftData @Model, Apple frameworks)  │
│   ↓                                              │
│ iOS Integrations (Calendar, Contacts, HealthKit) │
└─────────────────────────────────────────────────┘
```

### State machine (AppLifecycleCoordinator)

5 states, transitions guarded by `ReflectionGate`:
- `idle` → `capturing` (user starts a capture)
- `capturing` → `weaving` (user attaches to a thread)
- `weaving` → `reflecting` (user must write reflection)
- `reflecting` → `idle` (after reflection is non-empty)
- `*` → `lowEnergy` / `highFlow` (cognitive load-based, never auto-paused)

### Cognitive load algorithm (the anti-nag)

Every "load score" calculation:
1. Normalize 6 components to [0, 1]: calendarDensity, openTaskCount, sleepDebt, hrvStress, recentReflectionGap, activeAmplifierLoad
2. Weighted sum → score in [0, 1]
3. Compare to `elevatedScore` (0.70) → dim UI (soft exhale, 15% desaturation)
4. Compare to `weavePauseScore` (0.85) → trigger Weave Pause, but ONLY if:
   - Score ≥ 0.85 AND
   - Trend is `rising` (not sustained high) AND
   - Body depleted (sleep score ≥ 0.5 OR HRV score ≥ 0.5)

**The body-depletion clause** is the constitutional protection: a busy-but-rested user crossing 0.85 should NOT be gated (that would be nagging). Only overloaded + sleep-deprived triggers the pause.

### LifeMoment (cycle 46 — most recent feature)

Capture moments of life (photo + Vision OCR + optional reflection). Privacy:
- OCR/embeddings NEVER cross to TimelineEvent, LifeGraph, P2P, FamilyPod, Export
- Only `userReflection` (user-authored) + `userAssignedThread` (user-chosen) cross the egress boundary
- Photos default OFF via 10th Data Leash toggle

---

## ✅ What's been validated (Linux side, 2026-07-05)

| Validator suite | Count | Status |
|---|---|---|
| CognitiveLoad depth | 71 checks | ✅ all pass |
| Validator suite total | 43 suites | 42 green, 1 known false positive (`validate_cycle41_consensus.py` uses different output format — pre-existing, ignore) |
| Privacy invariants | 6 invariants in `OneWeavePrototype.swift` | ✅ verified |
| Constitutional compliance | 11 principles + invariants | ✅ verified |
| 10th Data Leash (Photos) | added in cycle 46 | ✅ verified |

**The 1 "failure" is not actually a failure** — it's a pre-existing false positive where the output format uses `Total: N | PASSED: X | FAILED: Y` instead of `OVERALL: PASS`. The validator still detected 0 actual failures. This was documented in cycle 47 and will be fixed in cycle 51.

---

## 🚧 What remains (Mac side, you)

### Must do (blockers for App Store)

| # | Task | Details | Priority |
|---|---|---|---|
| 1 | **Build in Xcode** | Open `Package.swift`, build for iOS 17+ simulator, fix any compile errors | 🔴 critical |
| 2 | **SwiftUI rendering** | Verify all 75 Swift files' SwiftUI views render correctly on iPhone/iPad | 🔴 critical |
| 3 | **AppIntents extension** | Wire up `LifeMomentCaptureAppShortcuts` to Siri + Shortcuts app | 🟡 high |
| 4 | **Widgets extension** | Add WidgetKit target, wire `OneWeaveWidgetStubs.swift` into widget extension | 🟡 high |
| 5 | **Run all 43 validators** | `bash .research/validate_all.sh` should still be 42-43 green | 🟡 high |
| 6 | **Privacy manifest** | Add `PrivacyInfo.xcprivacy` to Xcode target's Copy Bundle Resources | 🟡 high |
| 7 | **TestFlight** | Build IPA, distribute to internal testers, collect feedback | 🟡 high |
| 8 | **App Store metadata** | Screenshots, description, keywords, age rating (4+) | 🟡 high |

### Should do (UX polish)

| # | Task | Details |
|---|---|---|
| 9 | **Animations** | Living Loom thread ripples, saturation dim on cognitive load, emoji choices |
| 10 | **Accessibility** | VoiceOver labels, Dynamic Type, Reduce Motion support |
| 11 | **iPad layout** | Sidebar + detail layout, Stage Manager support |
| 12 | **Dark mode** | Verify all views in dark mode (some have hardcoded colors) |
| 13 | **Onboarding** | First-time flow explaining privacy + Data Leash |
| 14 | **Settings UI** | Data Leash toggles, export, clear data |

### Could do (post-launch)

| # | Task | Details |
|---|---|---|
| 15 | **iCloud Drive export** | User-initiated export to their iCloud Drive (NOT sync, just export) |
| 16 | **Watch app** | Glanceable view of today's quests + cognitive load |
| 17 | **macOS Catalyst** | Run the iOS app on Mac (via Mac Catalyst) |
| 18 | **Vision Pro** | Spatial view of the Living Loom |

### Known issues (from Linux side)

1. **`visual_compass.png`, `visual_echo.png`, `visual_loom.png`** are dev mocks — the real SwiftUI Canvas should replace them. They live in `Sources/OneWeavePrototype+GraphValidation.swift` for reference.
2. **InvisibleMentor** is a stub — the algorithmic mentor logic is partial. Decide whether to invest in deep mentor logic or keep as light suggestion engine.
3. **OnboardingView** is mostly complete but the "no cloud, no sync" copy is a placeholder (line 15). The user can edit this before launch.
4. **FamilyPod P2P** uses Signal Protocol but the full E2E implementation may need a Mac-side security review. Out of scope for v1.0 if shipping fast.

---

## 🎯 Recommended approach (what I'd do if I were you)

### Day 1-2: Get it building
```bash
git clone https://github.com/SapientEdge/OneWeave.git
cd OneWeave
open Package.swift
# Build → expect 5-20 compile errors (SwiftUI version mismatches, Combine)
# Fix iteratively
```

**Tip for Claude cowork:** Use the LSP integration to find all errors at once. Most are in `Sources/OneWeave/*.swift` where iOS 17+ APIs may need iOS 18+ fallbacks.

### Day 3-4: Validate the Linux algorithms still match
```bash
bash .research/validate_all.sh
# Should show 42-43 green
# If any validator fails, the Swift implementation has drifted from the Python mirror
# Investigate the diff
```

### Day 5-7: UI polish + iPad
- Run on iPhone 15 Pro simulator
- Run on iPad Pro simulator (different layout)
- Verify dark mode
- Check accessibility (VoiceOver)

### Day 8-10: AppIntents + Widgets
- Add Widget extension target
- Wire `OneWeaveWidgetStubs.swift` into the widget bundle
- Add Siri shortcuts via `LifeMomentCaptureAppShortcuts`
- Test via Shortcuts app

### Day 11-14: Privacy + App Store
- Verify PrivacyInfo.xcprivacy is in target
- Build for App Store (release config)
- Take screenshots (iPhone 6.7" + 6.1" + iPad 12.9")
- Write App Store description (use MARKETING.md + oneweave-audit-report)
- Submit

**Tip for Lovable:** The marketing site can be a separate web project — not built from this repo. Use MARKETING.md + MARKETING_DIAGRAMS.txt as inputs.

---

## 📚 Important constitutional invariants (DO NOT VIOLATE)

These are in `.specify/constitution.md` v2.1. Every change must respect them.

| # | Principle | Enforcement |
|---|---|---|
| 1 | One Journey, Not Silos | Threads are fluid lenses, not rigid tabs |
| 2 | Privacy-First, Zero-Trust | No external API, no cloud sync, no analytics, no LLM/Core ML/network in core |
| 3 | Calm Intelligence | Spring animations, no "🎉", no bouncy, no streak-shaming |
| 4 | Reflection-Gated Everything | Every state-changing action requires non-empty `reflectionText` |
| 5 | Anti-Addictive Gamification | Streaks have restorative grace (max 2), gentle decay, no nag notifications |
| 6 | Genuine Help Over Features | Solve real 2026 needs, not gamification/engagement |
| 7 | Plan Rigorously, Build Real | Spec Kit, Graphify, Python mirrors before Mac, no stubs |
| 8 | **Quiet Capture** (added cycle 46) | LifeMoment captures are frictionless, never auto-award |
| 7a | Data Leash = 10 toggles | Added Photos in cycle 46 |
| 11 | **Moment Egress Boundary** (added cycle 46) | OCR/embeddings NEVER cross to TimelineEvent/Graph/P2P/FamilyPod/Export |

**Code search to verify compliance:**
```bash
# Should return 0 hits in production code
grep -rE "URLSession|CloudKit|CoreML" Sources/OneWeave/ | grep -v "Protocol\|Note\|TODO"

# Should return only Constitution references
grep -rE "no-account|no-cloud|no-tracking" Sources/OneWeave/
```

---

## 🧪 Testing strategy

### Unit tests (Linux)
- 34 Python validators in `.research/validate_*.py` mirror the Swift algorithms
- Run `bash .research/validate_all.sh` to verify Swift matches Python
- 10 audit validators in `audit/validators/` for the algorithm verification oracle

### Integration tests (Mac)
- 1 prototype harness: `OneWeavePrototype.swift` + `OneWeavePrototype+GraphValidation.swift`
- Run via Xcode: builds all views, runs sample data, checks invariants
- Replace `OneWeaveWidgetStubs.swift` with real widget code

### UI tests (Mac)
- Add XCTest UI tests for critical flows:
  - Onboarding → Compass renders
  - Quick capture → reflection gate fires
  - Quest completion → reflection required
  - Data Leash toggle → integration disabled

### Manual QA checklist
- [ ] App launches on iPhone 15 Pro simulator
- [ ] App launches on iPad Pro simulator
- [ ] Compass → tap thread → ThreadDetailView renders
- [ ] Quick capture → save → appears in inbox
- [ ] Generate quest → requires reflection to complete
- [ ] Settings → toggle Photos off → PhotoPicker doesn't show
- [ ] Cognitive load trigger (simulate 10 calendar events) → dim UI
- [ ] Sacred Echo → seal → re-open → ciphertext preserved
- [ ] Export → JSON bundle contains all data

---

## 🔧 Common pitfalls (for Claude cowork)

### "Cannot find 'X' in scope"
The codebase uses SwiftUI + SwiftData. If imports are missing, check:
- `import SwiftUI` (most views)
- `import SwiftData` (any @Model file)
- `import HealthKit` (HealthKit integration)
- `import PhotosUI` (Photos picker)
- `import AppIntents` (Shortcuts)
- `import WidgetKit` (Widget extension)

### "SwiftData @Model not found"
Requires iOS 17+ deployment target. Check:
- Target → General → Minimum Deployments → iOS 17.0
- Build Settings → Swift Compiler - Language → Swift 5.9

### Build succeeds but app crashes on launch
- Check `OneWeaveApp.swift` — should have `@main struct OneWeaveAppMain: App`
- Check `modelContainer(for: [LifeEntity.self, ...])` — all @Model types must be registered

### Tests fail with "fatal error: unexpectedly found nil"
- SwiftData model container wasn't set up
- Probably a missing migration in `SchemaMigrationPlan.swift`

### Privacy audit warning
- Run `audit/algorithm_oracle.py` to verify crypto algorithms
- Check `Sources/OneWeave/PrivacyInfo.xcprivacy` is in target

---

## 📞 Communication protocol

### What to report back to the user (D S) after each phase

1. **After building** — "Build green, N warnings" or "Build fails, list of errors"
2. **After validating** — "42-43 validators green" or "specific failures"
3. **After UI test** — "iPhone renders correctly, iPad needs <X> fixes"
4. **After App Store prep** — "Ready to submit" or "<X> blocking"

### What NOT to change without asking

- The Constitution v2.1 principles
- Any privacy invariant (Data Leash, no-network, etc.)
- The Reflection Gate logic (every state change requires non-empty reflection)
- The 10th Data Leash = Photos toggle

### What you CAN change freely

- Visual styling (colors, fonts, spacing)
- Animation tuning (timing, easing)
- iOS-specific polish (safe area, Dynamic Type)
- Bug fixes that don't violate the Constitution

---

## 📖 Key files to read FIRST (in order)

1. **`README.md`** — Project overview, build status
2. **`ARCHITECTURE.md`** — Module structure
3. **`.specify/constitution.md`** (if you have access) — Binding principles
4. **`CLAUDE_COWORK_BRIEF.md`** — Specifically for you
5. **`BUILDING_ON_MAC.md`** — Step-by-step Mac build
6. **`Sources/OneWeave/CognitiveLoad.swift`** — The anti-nag algorithm (read this to understand "calm intelligence")
7. **`Sources/OneWeave/ReflectionGate.swift`** — The constitutional enforcement (read this to understand "reflection-gated everything")
8. **`Sources/OneWeave/DataLeashSettings.swift`** — The privacy model (read this to understand "zero-trust")
9. **`audit/algorithm_oracle.py`** — How to verify algorithms are correct
10. **`PRIVACY.md`** + **`PrivacyPolicy.md`** — User-facing privacy story

---

## 🎯 One-paragraph summary

> You're taking a Linux-validated iOS codebase (75 Swift files, 22k LOC, 42/43 Python validators green, constitutional v2.1 compliance verified) and making it build + ship on macOS. The privacy model is the entire point: zero data leaves the device. The hardest part is making the build green in Xcode (likely 5-20 compile errors from SwiftUI/SwiftData version drift) and validating that the Mac-compiled Swift still matches the Linux Python mirror. The constitutional invariants are non-negotiable. Everything else (UI polish, animations, accessibility) is secondary to the core: anti-addictive, reflection-gated, privacy-first.

---

## ❓ When in doubt

1. **Re-read `.specify/constitution.md`** — every principle is binding
2. **Run `bash .research/validate_all.sh`** — if it breaks, you broke something
3. **Grep for the principle** — `grep -r "no.*account\|no.*cloud" Sources/OneWeave/`
4. **Ask the user** — better to ask than assume

---

## 📊 Handoff stats (what you're inheriting)

| Metric | Value |
|---|---|
| Swift files | 75 |
| Total LOC (Swift) | ~22,000 |
| Python validators | 34 |
| Audit validators | 10 |
| Tests passing (Linux) | 42-43 / 43 |
| Constitutional principles | 11 |
| Privacy invariants | 6+ (Data Leash + no-network) |
| Cycles completed | 46, 47, 48, 49 |
| Commits | ~80 |
| Days of Linux work | ~4 days of focused iteration |
| App Store target | v1.0 in next 2-4 weeks |

**You're inheriting something that works. Don't break it.**

---

*Last updated: 2026-07-05. Linux-validated, ready for Mac.*
*Repo: https://github.com/SapientEdge/OneWeave (PRIVATE)*
*Constitution: v2.1 (with v3 draft for cycle 50+)*
*Validator suite: 42-43 green, known 1 false positive*