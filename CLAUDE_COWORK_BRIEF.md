# CLAUDE COWORK BRIEF — Mac-side onboarding

**Audience:** A Mac-side Claude (Claude Code via cowork, Claude.ai with
project context, or Claude for Mac) that is taking the Linux-validated
OneWeave codebase and turning it into a runnable, testable iOS build.

**Goal of this brief:** Get the Mac-side Claude productive in under 30
minutes without having to re-discover the architecture from scratch.

---

## 1. The codebase at a glance

- **48 Swift files** in `Sources/OneWeave/` (~13,000 lines)
- **11 SwiftData @Model types** registered in `OneWeaveApp.swift`
- **All five privacy gates** enforced at the type level
- **No external API dependencies** — local-first, no network, no LLM
- **11 Python validation suites** in `.research/validate_*.py` — run on
  Linux, mirror Swift logic, 350+ individual checks all passing

Total repo size: ~20 MB. Most files are < 300 lines. Largest is
`CompassView.swift` at ~970 lines (the main UI).

## 2. What the Linux side already validated

The Linux side did NOT run Xcode. What it DID do:

1. **Implemented** every feature end-to-end in Swift
2. **Mirrored** the algorithm in Python for behaviors that don't need
   SwiftUI/SwiftData (rendering, crypto, policy, export, migration,
   graph ops, mentor synthesis, family pod, schema conversion)
3. **Stress-tested** with 1k/10k entity graphs, 1k crypto roundtrips,
   1k P2P packet storms, 1000 mentor sessions
4. **Reviewed three times** by independent LLM agents (Grok, Claude
   Code opus, Nemotron 3 Ultra). 30+ distinct issues caught + fixed.
   The most important catch: a duplicate `lastUpdated` property on
   `LifeEntity` that would have blocked the first compile.

What the Mac side needs to do:

1. **Compile the Swift code** in Xcode (verify Swift types are valid)
2. **Wire up the Xcode project** (SwiftData ModelContainer, App Group,
   widget extension, signing)
3. **Run the existing tests** in `OneWeavePrototype.swift` and
   `OneWeavePrototype+GraphValidation.swift` on the simulator
4. **Add XCTest coverage** for behaviors that couldn't be tested on
   Linux (UI, SwiftData, App Group)
5. **Iterate** based on what breaks

## 3. The 8-phase playbook

Full details: [`.research/TIER_B_PLAYBOOK.md`](./.research/TIER_B_PLAYBOOK.md).
TL;DR:

1. **Create the Xcode project** — iOS 17+, SwiftUI lifecycle, SwiftData,
   App Group `group.com.oneweave`. Add `Sources/OneWeave/*.swift`.
2. **Register SwiftData models** — already done in `OneWeaveApp.swift`
   (11 types). Verify the list.
3. **Configure the App Group** — for widget sync + portable export
   backup.
4. **Add the Widget Extension** — `HarmonyWidget` + `QuestWidget`
   (stubs in `OneWeaveWidgetStubs.swift`). Use `OneWeaveSnapshotStore`.
5. **Add App Intents** — `LogWeaveIntent`, `CompleteQuestIntent`,
   `ShowHarmonyIntent` (already declared).
6. **Wire P2P transport** — Network framework + WebRTC stubs are in
   `P2PWeaveShare.swift`. Actual transport comes from
   `GoogleWebRTC` (CocoaPods).
7. **Add XCTest target** — port the 11 Python validators to Swift
   where it makes sense, but keep the Python ones as Linux CI.
8. **Build & TestFlight** — first build, fix any compile errors, ship
   to TestFlight.

## 4. The five privacy gates (preserve them)

These are non-negotiable. Every commit-shaped action in OneWeave
passes through at least one of these gates:

1. **Reflection gate** — every commit function takes a non-empty
   `reflectionText: String`. Empty → throws or returns empty.
2. **Data Leash gate** — every iOS integration reads the user's
   toggle BEFORE calling the framework.
3. **Consent gate** — `LifeEntity.isUserReflection: Bool` is the only
   way to mark content as user-authored.
4. **Sacred Echo unlock gate** — plaintext decrypted only after
   `unlockAt <= now`; plaintext never persisted.
5. **Fail-closed crypto gate** — no deterministic cipher seed in
   production code.

Read [`PRIVACY.md`](./PRIVACY.md) for the threat model.

## 5. Files to read first (priority order)

1. `README.md` — overview, quick start, feature list.
2. `ARCHITECTURE.md` — module map, data flows, threading model.
3. `Sources/OneWeave/OneWeaveAPI.swift` — every public type listed
   with the file path it's defined in.
4. `MANIFEST.md` — per-file line count + purpose.
5. `PRIVACY.md` — the five gates.
6. `Sources/OneWeave/LifeContext.swift` — the core state container.
7. `Sources/OneWeave/OneWeaveApp.swift` — the app entry point +
   SwiftData registration.
8. `Sources/OneWeave/SacredEcho.swift` — the most security-sensitive
   file; review carefully.
9. `.research/TIER_B_PLAYBOOK.md` — the 8-phase Mac-side build plan.

## 6. Files the Mac side will probably edit

- `OneWeaveApp.swift` — already references `@Environment(\.scenePhase)`
  and registers all 11 models. Mac side may add AppDelegate hooks.
- `OneWeaveWidgetStubs.swift` — widget target imports this. The
  `Widget` structs are placeholders; Mac side implements the actual
  `TimelineProvider`.
- `P2PWeaveShare.swift` — `sendViaWebRTC` is a stub; Mac side adds the
  WebRTC binding.
- `LifeGraphiOSIntegrations.swift` — the older facade; Mac side may
  retire it in favor of `iOSServiceIntegrations.swift`.

## 7. Files the Mac side should NOT modify

- `SacredEcho.swift` — crypto is reviewed and validated. Only the
  Keychain path (already production) should change. Don't add
  fallback seeds.
- `InvisibleMentor.swift` — deterministic synthesizer; don't add LLM
  calls. Ever.
- `DataLeashSettings.swift` — privacy model is settled. Only add new
  integration categories if absolutely necessary.
- `PortableExport.swift` — format is contract. Bumping
  `currentBundleVersion` is a breaking change.

## 8. Validation workflow

Every change the Mac side makes should be re-validated:

```bash
# Linux side (always run):
bash .research/validate_all.sh

# Mac side (run in Xcode):
# 1. Build (⌘B)
# 2. Run the existing prototype (⌘R) — exercises OneWeavePrototype
# 3. Add new XCTests for new behavior
# 4. Profile (⌘I) — confirm no leaks, no main-thread stalls
```

If a Linux validator starts failing after your change, the Python
mirror needs updating. Don't update the validator to make it pass —
update the code.

## 9. When something breaks

The most likely first-build issues:

1. **SwiftData schema mismatch** — `OneWeaveApp.swift` lists 11 models.
   The `Schema(...)` initializer must list them all in the order
   they appear in `ModelContainer`. If you add a new @Model, add it
   here AND to `OneWeaveSchemaV3` in `SchemaMigrationPlan.swift`.
2. **Missing imports** — `Foundation`, `SwiftData`, `CryptoKit`,
   `Combine`, `SwiftUI` are the common ones. Add at file top.
3. **Actor isolation** — most stores are `@MainActor`. If a non-MainActor
   function calls them, you get a compile error. Add `await` or
   `Task { @MainActor in ... }`.
4. **Missing reflection gate** — if a function takes a `reflectionText`
   argument and you pass an empty string, the function should throw.
   If it doesn't, that's a privacy bug; add the check.
5. **Missing Data Leash check** — if a function calls into EventKit /
   Contacts / HealthKit without first reading `DataLeashPolicy.currentLeash(in:)`,
   that's a privacy bug; add the check.

## 10. Common mistakes to avoid

1. **Don't bypass the encryption** to "simplify" Sacred Echo. The
   `SacredEchoCipher.open` path is the only path to plaintext.
2. **Don't add a Core ML model** to "improve" the Invisible Mentor.
   The Mentor quotes the user back to themselves. That's the whole
   point. An LLM/ML model would dilute that.
3. **Don't add cloud sync** for "convenience". Local-first is the
   privacy contract.
4. **Don't add social features** (likes, comments, followers). Family
   Pod is the only multi-user concept, and it's strictly anti-social.
5. **Don't change the export leash semantics**. `localOnly` means
   no bytes. `privateBundle` means private-only. `publicBundle`
   means public-only (no reflections). `fullBundle` means
   everything (requires 30+ char reflection).
6. **Don't remove the `isUserReflection` gate**. Contact names,
   calendar event titles, reminder bodies are NOT user reflections.
   The Mentor must never quote them as the user's own words.

## 11. Communication back to the Linux side

If you find:

- A new bug class that the Python validators can't catch (e.g., a
  SwiftData migration that crashes on real install) → open an issue
  with the failing scenario.
- A new privacy gate idea → propose in `PRIVACY.md` via PR.
- A new feature opportunity that fits the privacy contract → propose
  in `.research/ONEWEAVE_ENHANCEMENT_PLAN.md`.

The Linux side will keep validating and can run additional review
agents against your diff.

## 12. Time budget

Realistic phases:

- Phase 1 (Xcode project setup): 3-4 hours first time, 30 min with
  template
- Phase 2-5 (SwiftData, App Group, Widget, Intents): 4-6 hours
- Phase 6 (P2P transport — GoogleWebRTC): 4-8 hours
- Phase 7 (XCTest port): 3-4 hours
- Phase 8 (TestFlight build): 2-3 hours

Total: 16-25 hours. Plan for at least one weekend of focused work.

## 13. When you're done

A successful Mac-side build is:

- All Swift files compile without warnings.
- App launches in iOS Simulator.
- OneWeavePrototype runs end-to-end.
- Widget shows harmony + quest counts.
- XCTests cover every public function in `OneWeaveAPI.swift`.
- TestFlight build installs on a real device.
- Five privacy gates verified by inspection + automated test.

Good luck. Build calmly.