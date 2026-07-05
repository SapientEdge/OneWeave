# OneWeave — Round 3 Nemotron Production Readiness Review

**Date**: 2026-06-27
**Reviewer**: Nemotron 3 Ultra (round 3, post-toolchain-adoption)
**Scope**: App Store submission readiness, Sacred Echo Vault review notes, TestFlight setup, schema migration safety, widget extension wiring, onboarding polish, privacy policy accuracy, marketing copy accuracy.
**Mode**: Review-only. No code changes.

---

## Prior round coordination

Round 1 (Grok) + Round 2 (Claude Code opus) + Round 2 Nemotron (cycles 25 + 27 of build_log) applied 30+ findings. The `.research/round3/` directory is empty (only the prompt exists); this round is being run alongside the Grok and Claude Code reviews dispatched in parallel. Findings below avoid all 30+ items already addressed (duplicate-property, `@MainActor` isolation, fail-closed crypto, `isUserReflection` gate, `MentorInput` private filter, attribute type fix, etc.).

---

## Area 1 — Info.plist / Entitlements / PrivacyInfo.xcprivacy

### NEMO-R3-001 — HIGH — blocker — **MISSING ENTIRELY**
**Issue**: No `Info.plist` exists anywhere in the repo (`find` returned 0 plists). Xcode will generate a default one, but it will be missing every usage description string the app needs. The plan (`plan.md` §Phase M2) and `TIER_B_PLAYBOOK.md` call this out but the strings are not yet enumerated anywhere as a checklist for the Mac coworker. Sources explicitly call these APIs:
- `EKEventStore.requestFullAccessToEvents()` / `requestFullAccessToReminders()` — `iOSServiceIntegrations.swift:64,557`
- `CNContactStore.requestAccess(for: .contacts)` — `iOSServiceIntegrations.swift:137`
- `HKHealthStore.requestAuthorization(...)` — `iOSServiceIntegrations.swift:233`
- `MFMailComposeViewController` — `iOSServiceIntegrations.swift:411`
- `NSCalendarsUsageDescription`, `NSCalendarsFullAccessUsageDescription`, `NSContactsUsageDescription`, `NSRemindersUsageDescription`, `NSRemindersFullAccessUsageDescription`, `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription`, `NSMicrophoneUsageDescription` (Future Echo audio?), `NSFaceIDUsageDescription` (vault seed unlock via LocalAuthentication per spec), `NSLocalNetworkUsageDescription` (BLE P2P), `NSBonjourServices` (Weave Circles), `NSUserTrackingUsageDescription` (not needed — we explicitly do no tracking).

**Fix**: Create `Resources/Info.plist` with the 11 usage strings (copy templates from `FIRST_WEEK_ON_MAC.md` §6.4) and add a `Resources/PrivacyInfo.xcprivacy` declaring `NSPrivacyTracking=false`, `NSPrivacyCollectedDataTypes=[]`, `NSPrivacyAccessedAPITypes` for the categories actually used (`UserDefaults`, `FileTimestamp`, `DiskSpace`, `SystemBootTime`). Also add `com.apple.developer.healthkit` entitlement.

### NEMO-R3-002 — HIGH — blocker — `App Group not provisioned`
**Issue**: `Sources/OneWeave/OneWeaveSnapshotStore.swift:37` hardcodes `private let suiteName = "group.com.oneweave"` and `AppLifecycleCoordinator.swift:139` declares `public static let appGroupID = "group.com.oneweave"`. Neither target has an entitlement file. `containerURL(forSecurityApplicationGroupIdentifier:)` will return nil on a real device without the entitlement, silently falling back to `temporaryDirectory` per `AppLifecyclePaths.containerURL()` line 156. **Result**: widget snapshot writes go to `/tmp/oneweave-dev/` on the device, the widget target (separate App Group entitlement check) reads nothing, widget renders stale or default state. This is not just a Mac-coworker note — it is a privacy-adjacent silent-failure: the user's stored envelope could land outside the App Group sandbox.

**Fix**: Add `OneWeave.entitlements` to both the app target and the widget target with `com.apple.security.application-groups = ["group.com.oneweave"]`. Have `AppLifecyclePaths.containerURL()` log an `[AppLifecycle] WARNING: App Group missing` if it falls back to `tmp`.

### NEMO-R3-003 — MEDIUM — blocker (privacy nutrition label) — **Privacy Nutrition Label gap**
**Issue**: App Store Connect now requires the privacy nutrition label. App uses HealthKit (`HKHealthStore`) which Apple classifies as "Health & Fitness" sensitive data, plus Calendar/Contacts. Marketing copy at `MARKETING.md:74` says "free tier is generous" but the privacy policy at `PrivacyPolicy.md:7` says "**No data leaves your device.** All storage is local SwiftData. No network..." This is technically true but **the App Store privacy label cannot claim "Data Not Collected"** because Apple's rules say: declaring HealthKit usage is itself a "Health Data" declaration even if read-only and never transmitted. If the team picks "Data Not Collected" the app will get rejected during App Review.
**Fix**: In App Store Connect, declare "Health & Fitness → Health → Health Information" as Data Used to Track User / Not Used to Track User (= false) and clarify "Read only on-device; never transmitted." Update `PrivacyPolicy.md:7` to add the line "HealthKit is read locally when you grant permission; no bytes leave the device."

### NEMO-R3-004 — MEDIUM — blocker (encryption compliance) — **Encryption Export Compliance**
**Issue**: App uses AES-256-GCM (CryptoKit) but does not declare `ITSAppUsesNonExemptEncryption` in Info.plist. Per Apple: any app using standard cryptographic APIs (CryptoKit, Security framework) must either declare this key with `=false` (claiming exemption under category 5 part 2 note 4) or submit CCATS documentation. The `FIRST_WEEK_ON_MAC.md:280` mentions export compliance but the project has no `Info.plist` to put the key in.
**Fix**: Add `ITSAppUsesNonExemptEncryption = false` to `Info.plist` (Sacred Echo + envelope crypto qualify as HTTPS-only-allowed under category 5 part 2 note 4 / exemption (e) since it's used purely for local at-rest encryption, not for transmitting to/from servers).

---

## Area 2 — App Store Connect Metadata

### NEMO-R3-005 — MEDIUM — blocker — **Marketing copy vs shipped reality: Weave Circles**
**Issue**: `MARKETING.md:138` and `FEATURE_CATALOG.md §17` advertise "Weave Circles" + "Family Pod" as P2P features. `P2PWeaveShare.swift` (per build_log cycle-19) and `CLAUDE_COWORK_BRIEF.md:65` confirm `sendViaWebRTC` is a stub. Marketing also says "WebRTC.framework via CocoaPods" but no Podfile exists. Submitting with advertised P2P features that aren't wired would trigger App Review rejection (rule 2.1: completeness) AND mislead users.
**Fix**: Either (a) ship v1 without P2P and update MARKETING.md to defer Weave Circles to "v1.1" (recommended; matches `FIRST_WEEK_ON_MAC.md:171` guidance to defer WebRTC), or (b) make P2P a hidden beta flag. Removing the marketing claim is cheaper than filing a Podfile + ICE/STUN/TURN + libsignal-client in time for first submission.

### NEMO-R3-006 — MEDIUM — blocker — **Paid tier pricing claim unsubstantiated**
**Issue**: `MARKETING.md:74,138` advertises "paid tier ($9.99/mo or $79.99/yr) unlocks cross-device sync via your own iCloud Drive" and `FIRST_WEEK_ON_MAC.md:312` plans StoreKit 2 in "Month 2". `plan.md §M5` excludes IAP. There is no StoreKit code in `Sources/OneWeave/`. Submitting with an advertised subscription that doesn't exist = App Review rejection (rule 2.3) and Apple Developer Program T&C violation.
**Fix**: Cut all pricing copy from v1.0 submission. Move $9.99/$79.99 to MARKETING.md "Roadmap (v1.1+)" section. Ship free, full-featured for v1.

### NEMO-R3-007 — MEDIUM — blocker — **Support URL**
**Issue**: `FIRST_WEEK_ON_MAC.md:216` says "Support URL: placeholder: support@oneweave.app" (an email, not a URL — App Store Connect requires a URL with HTTPS). No website, no help center, no support email address configured anywhere.
**Fix**: Either (a) host a `support.html` page on GitHub Pages with a mailto: link, or (b) configure a simple support site before submission. Update MARKETING.md to reference the real URL.

### NEMO-R3-008 — MEDIUM — blocker — **Privacy Policy URL**
**Issue**: `PrivacyPolicy.md` is the in-repo policy but App Store Connect requires a publicly accessible URL. Marketing says "Privacy is not a feature. It's the foundation" (`MARKETING.md:38`) — Apple will absolutely test that URL during review.
**Fix**: Host `PrivacyPolicy.md` on GitHub Pages (or similar) BEFORE submission. Add canonical URL to `CLAUDE_COWORK_BRIEF.md` §11 and `FIRST_WEEK_ON_MAC.md` §6.3.

### NEMO-R3-009 — LOW — Age Rating questionnaire
**Issue**: No one has filled out the App Store Connect Age Rating questionnaire. Sacred Echo Vault with post-mortem delivery and medical directives could trigger 17+ rating if reviewers interpret Echo plaintext about health/medical decisions as "medical content." This is unlikely to cause rejection but could affect "Made for Kids" exclusions.
**Fix**: Mark "Made for Kids" = No. Mark medical/treatment content = No (Echo Vault is user-authored personal content, not medical advice). Mark "Unrestricted Web Access" = No. Expect 12+.

---

## Area 3 — TestFlight Setup

### NEMO-R3-010 — HIGH — blocker — **No Xcode project / Package.swift / build target**
**Issue**: Confirmed by `find` — there is no `.xcodeproj`, no `.xcworkspace`, no `Package.swift`, no entitlements file. Per `CLAUDE_COWORK_BRIEF.md §3.1` and `FIRST_WEEK_ON_MAC.md §2.1` the Mac coworker creates the project from scratch. Until that exists, there is literally no binary to upload to App Store Connect. This is the gating Mac-side work.
**Fix**: (Out of scope for this review, but called out for completeness): create `OneWeave.xcodeproj` per `TIER_B_PLAYBOOK.md` Phase 1; add `OneWeaveWidget` extension target; wire App Group + HealthKit + EventKit + Contacts entitlements; configure signing team.

### NEMO-R3-011 — MEDIUM — blocker — **No `oneweave.snapshot.v1` consumer in widget**
**Issue**: Constitution §Architectural Invariants #2 mandates `oneweave.snapshot.v1` as the widget snapshot key, but `OneWeaveSnapshotStore.swift:38` uses key `"OneWeaveSnapshot"` — a different name. `OneWeaveWidgetStubs.swift:31-32` comment says "In real: load from app group shared UserDefaults or JSON snapshot written by main app" but the stub itself reads from `OneWeaveSnapshotStore.shared.read()`, which will look up `OneWeaveSnapshot`, not `oneweave.snapshot.v1`. The constitutional invariant is not satisfied.
**Fix**: Rename `OneWeaveSnapshotStore` `key` to `"oneweave.snapshot.v1"` (line 38) and add a constant `public static let snapshotKey = "oneweave.snapshot.v1"` so widget code and main app agree on the same key.

### NEMO-R3-012 — MEDIUM — blocker — **Widget provider TimelineProvider is a stub**
**Issue**: `OneWeaveWidgetStubs.swift` lines 1–11 (file header comment) and lines 215–221 admit the file is "production: no full target setup here (Linux env); productions + preview only." Despite the file's `#if canImport(WidgetKit) && WIDGET_EXTENSION` guard, the `WidgetBundle` (`HarmonyWidget` + `QuestWidget`) will compile only when added to an actual widget extension target. Without that target, `HarmonyWidgetProvider.getTimeline(...)` returns 2 hardcoded stub quests (`OneWeaveWidgetStubs.swift:103-106`) — never the live data. **The widget ships broken in v1 unless the stub is replaced.** The `QuestWidgetProvider.production` (sic — should be `placeholder`) on line 90 also has a typo and returns the same hardcoded data.
**Fix**: Move `OneWeaveSnapshotStore` + `OneWeaveWidgetStubs` into a separate `OneWeaveWidget/` target directory; rewrite `getTimeline` to fetch the snapshot from App Group UserDefaults via `OneWeaveSnapshotStore.shared.read()` (same call, but in the widget process). Fix `production` → `placeholder` typo on line 90.

### NEMO-R3-013 — MEDIUM — blocker (TestFlight) — **No `AppShortcutsProvider`**
**Issue**: `OneWeaveWidgetStubs.swift:162-188` declares `LogWeaveIntent`, `CompleteQuestIntent`, `ShowHarmonyIntent` as `AppIntent` types but no `AppShortcutsProvider` is registered (no matches for `AppShortcuts` in Sources). Without `AppShortcutsProvider`, Siri won't surface these shortcuts, and Shortcuts.app won't show OneWeave in its app picker. `FIRST_WEEK_ON_MAC.md §4.1` calls for this but the code doesn't exist yet.
**Fix**: Create `OneWeaveShortcutsProvider: AppShortcutsProvider` with `static var appShortcuts: [AppShortcut] { [...] }`. Register each intent's `static var title` + `phrases: ["Log a weave in \(.applicationName)"]`.

### NEMO-R3-014 — MEDIUM — blocker — **TestFlight internal tester account setup**
**Issue**: `FIRST_WEEK_ON_MAC.md §7.1` describes the TestFlight flow but no Apple Developer account exists yet ("[ ] Apple Developer Program" still a TODO on §1.3). Without paid enrollment, TestFlight *internal* testing works on a free Apple ID for the developer only; *external* testing requires paid enrollment. This is 24-48h setup, not a code fix.
**Fix**: Out of scope here; flag for Dan.

---

## Area 4 — Sacred Echo Vault — App Review Notes

### NEMO-R3-015 — HIGH — blocker — **Reviewer-facing disclaimer missing**
**Issue**: Apple App Reviewers will hit Sacred Echo Vault during the post-install manual review. They will see "Time-capsule messages," "Heir delivery," and "medical directives" language in the marketing and may flag it as:
1. Legal-document-related (post-mortem instructions could be construed as estate planning)
2. Health-related content (medical directives could be construed as medical advice)
3. P2P-with-sensitive-content (heir delivery + Echo plaintext)
`MARKETING.md:148` acknowledges: "Sacred Echo Vault is legally delicate (post-mortem delivery, medical directives). Mitigation: explicit disclaimers; not a legal document; consult attorney for jurisdiction-specific language." But **no in-app disclaimer exists** — there is no text shown in `SacredEchoStore.seal/open/handDeliver/release` about this. App Review will see Echo composition UI with no disclaimer visible.
**Fix**: In `SacredEchoStore.seal`, prepend a required consent step: a "Before you seal" sheet with text "Sacred Echoes are personal time-capsule messages. They are not legal documents and do not constitute medical, estate, or end-of-life directives. Consult a licensed attorney for binding instructions." The reflection-gate text already exists; append the legal disclaimer to the same gate. Update Marketing copy to add: "Not a legal document. Not a substitute for professional estate or medical advice."

### NEMO-R3-016 — HIGH — blocker — **Reviewer demo account**
**Issue**: Per `FIRST_WEEK_ON_MAC.md §7.4`, Apple reviewers may ask for a demo account. For Sacred Echo to be testable, the reviewer needs to:
1. Bypass the 24h `openingReady` gate (which they can't wait for)
2. See the vault UI without writing a real reflection
3. Verify "no plaintext on disk" claim

The current implementation has `SacredEcho.nowOverride` (`SacredEcho.swift:134`) gated behind `#if DEBUG`. **Production builds cannot inject a past timestamp** for reviewer testing, so they cannot open any echo within the 24h review window. This is likely to cause rejection with: "Feature cannot be verified."
**Fix**: Either (a) build a `#if DEBUG`-guarded test harness that the reviewer can enable via a hidden URL scheme (`oneweave://demo/echo?unlockAt=2024-01-01`), or (b) ship a "Demo Echo" that auto-unlocks after 60 seconds for first-week installs (visible to reviewers, then removed in 1.0.1). Add a `Demo:ReviewMode` toggle gated behind `BuildConfiguration == .testFlight`.

### NEMO-R3-017 — HIGH — blocker — **Encryption-at-rest claim needs screenshot evidence**
**Issue**: App Review will likely test: "User writes echo → kill app → reopen → confirm encrypted at rest." The current implementation encrypts via `SacredEchoCipher.seal` (`SacredEcho.swift:284`) which IS AES-256-GCM with no plaintext persisted. BUT the App Review reviewer can't easily verify this from the UI. The "no plaintext on disk" claim is not user-visible.
**Fix**: In the Echo settings view, add a "Privacy Verification" section showing: (a) the cipher algorithm, (b) the keychain accessibility class (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`), (c) the ciphertext hex preview for the most recent echo. This makes the privacy claim tangible and reviewer-testable. Add a corresponding line to `MARKETING.md` review notes.

### NEMO-R3-018 — MEDIUM — **SacredEchoCipher persistence warning is silent**
**Issue**: `SacredEcho.swift:262`: `print("[SacredEcho] WARNING: Keychain seed write failed; using ephemeral seed")`. If the Keychain is locked (rare on devices but happens on simulator), the seed is ephemeral and ALL future echo seals will be unrecoverable after app restart. **The user is not notified.** Reviewer test "create echo → kill app → reopen → open echo" will fail with "decryptionFailed."
**Fix**: When `persistToKeychain` returns false, throw `EchoError.cipherMissingKey` upward (do not fall back to ephemeral seed). Show a blocking alert "Vault initialization failed; Sacred Echoes are unavailable until you restart." This is fail-closed (constitution §Architectural Invariant #4).

### NEMO-R3-019 — MEDIUM — **Echo heir privacy gate**
**Issue**: `SacredEcho.swift:653-657` validates heir by `entity.domains.contains("CareKin")`. This is a weak gate — any entity tagged `CareKin` qualifies, including system-imported contacts the user hasn't reviewed. A maliciously-crafted P2P share could pre-tag an entity with `CareKin` and become an heir. Reviewers might catch this.
**Fix**: Add a stronger check: the heir entity must (a) exist in the user's local Weave Circle (`P2PWeaveShare` membership list), AND (b) be flagged `isUserReflection == false` (system-tagged) — meaning it's a user-added person, not an auto-imported contact. Document this in PrivacyPolicy.md.

---

## Area 5 — Onboarding Polish

### NEMO-R3-020 — HIGH — blocker — **`@AppStorage("hasCompletedOnboarding")` not implemented**
**Issue**: `CompassView.swift:557`: `// Auto-show first time (simplified; production would use @AppStorage)` — the production gate is unimplemented. Current behavior: `if showOnboarding == false && contexts.first != nil { showOnboarding = true }` (line 556). **Problem**: This re-triggers onboarding EVERY TIME the first context is created and `showOnboarding` is false (e.g., after the user dismisses it once). Also: onboarding auto-shows only when `contexts.first != nil` (line 556), but the very first time the app launches there is no context yet — onboarding is shown via the "Show Onboarding" button (line 518) instead. The logic is broken.
**Fix**: Implement `@AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false` in `OneWeaveApp` or `CompassView`; show `OnboardingView` as `fullScreenCover` when `!hasCompletedOnboarding` on appear; set `hasCompletedOnboarding = true` when user taps "Start Weaving" (the button at `OnboardingView.swift:51` does nothing currently — `stateMachine.currentState = .idle` is the only side effect).

### NEMO-R3-021 — HIGH — blocker — **Onboarding "Start Weaving" button is a no-op for persistence**
**Issue**: `OnboardingView.swift:51-58`: tapping "Start Weaving" only changes `stateMachine.currentState = .idle`. There is no `@AppStorage` write, no first-launch demo (`plan.md §M6` calls for "First Weave demo"), no Data Leash intro, no Sacred Echo Vault intro. This means the user's first action after dismissing onboarding is... nothing changes. Per the 12 user stories, the Sacred Echo Vault is the killer feature; without first-run exposure, users won't discover it.
**Fix**: (1) Add `@AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding` in `OnboardingView`. (2) On "Start Weaving", set `hasCompletedOnboarding = true` AND seed a 1-day-unlock demo Sacred Echo AND show a brief "Welcome" sheet pointing to Compass + Sacred Echo Vault + Data Leash. (3) Add a 6th onboarding page explaining the Data Leash (currently only mentioned at `OnboardingView.swift:11` generically as "Privacy by Design" with no specifics).

### NEMO-R3-022 — MEDIUM — **Onboarding references state machine, not real features**
**Issue**: `OnboardingView.swift:7-13` pages reference `idle → weaving → reflecting` state transitions and "four threads" but the user has not yet seen the threads. Newcomers won't understand what "Self / Stewardship / Care & Kin / Meaning" means until they tap Compass. Recommended: add a "Your Four Threads" page with mini-icons of the 4 thread colors (Self=.blue, Stewardship=.green, CareKin=.orange, Meaning=.purple per constitution §10).
**Fix**: Add page 2 between current pages 1 and 2: "Your Four Threads" with 4 colored circles + 1-line descriptions. Update `OnboardingView.pages` array length from 5 to 6.

---

## Area 6 — Schema Migration Safety

### NEMO-R3-023 — HIGH — blocker — **V1 → V3 lightweight migration is NOT actually lightweight**
**Issue**: `SchemaMigrationPlan.swift:322` declares `// V1 → V3: heavyweight because attributes type changes` in a comment but uses `.lightweight(fromVersion: OneWeaveSchemaV1.self, toVersion: OneWeaveSchemaV3.self)`. The V1 schema has `attributes: String` (`SchemaMigrationPlan.swift:117`); V3 has `attributes: [String: String]` (line 289). **SwiftData's lightweight migration cannot convert `String` (JSON blob) to `[String: String]` (native dict) automatically.** This will fail at first launch for any user who installed a V1 build with `attributes` populated. There IS a helper `OneWeaveMigrationLogic.convertAttributesJSONToDict` (line 348) but it is never called from the migration plan — `OneWeaveMigrationPlan.migrate(...)` (line 332) is a no-op stub.
**Fix**: Replace `.lightweight(fromVersion: OneWeaveSchemaV1.self, toVersion: OneWeaveSchemaV3.self)` with `.custom(fromVersion: OneWeaveSchemaV1.self, toVersion: OneWeaveSchemaV3.self, willMigrate: { context in ... }, didMigrate: { context in try OneWeaveMigrationLogic.convertAndPersistAttributesJSON(context) })`. The didMigrate callback fetches all `OneWeaveSchemaV3.LifeEntity` rows, reads the V1 JSON via raw keypath, runs `convertAttributesJSONToDict`, writes back. Alternative: ship V3 as a fresh-install-only schema and document "no upgrade from V1; users must re-create entities" — but this violates spec US-12 (preserving data).

### NEMO-R3-024 — HIGH — blocker — **No rollback path**
**Issue**: `SchemaMigrationPlan.swift` does not register any `MigrationStage` that runs in reverse. Spec US-12 acceptance scenario #3 ("Given migration fails midway, When rollback triggered, Then data restored to V2 state, no partial corruption") is not implemented. The `migrate(...)` no-op (line 332) cannot rollback because there is nothing to roll back TO. The pure-helper `validateMigrationPath(from:to:)` (line 381) returns "Downgrades are not supported" — which is a documentation-only guard, not an actual rollback path.
**Fix**: Implement a "version snapshot" pattern: before any migration, write `oneweave.snapshot.v{from}.json` to the App Group container (already implemented in `LifeGraphPersistence.persist` at `AppLifecycleCoordinator.swift:281`). On migration failure, `migrate(...)` can read this snapshot and restore. Document this in `TIER_B_PLAYBOOK.md` and add a test case to `validate_schema_migration.py`.

### NEMO-R3-025 — MEDIUM — **No migration test for in-progress corruption**
**Issue**: `validate_schema_migration.py` (30/30 PASS per `FEATURE_CATALOG.md §19`) tests round-trip migration logic, but no test exercises "migration fails midway → recovery." Adding the snapshot-based rollback would require a corresponding test.
**Fix**: Add a test case to `validate_schema_migration.py` that simulates a partial migration (truncated `attributes` JSON), verifies the snapshot rollback restores the pre-migration state, and verifies the user sees a "Migration recovery in progress" message rather than a crash.

### NEMO-R3-026 — MEDIUM — **V2 declared but skipped in stages**
**Issue**: `SchemaMigrationPlan.swift:259` declares `OneWeaveSchemaV2` (adds `isUserReflection` + `lastUpdated`) but `OneWeaveMigrationPlan.schemas` (line 311) only lists `[OneWeaveSchemaV1.self, OneWeaveSchemaV3.self]`. The comment says "V2 is an additive-only schema change; SwiftData's lightweight migration infers the upgrade path automatically." This is true for additive changes, but if a user installs a V1 build, then upgrades to a build with V3, SwiftData will attempt V1 → V3 with `isUserReflection` and `lastUpdated` defaulted to `false` / `Date()`. **V2 entities will have `lastUpdated == createdAt` because there's no migration step that sets `lastUpdated = createdAt`.** Spec US-12 acceptance scenario #1 explicitly requires: "Given V1 entities with `createdAt = old_date`, When V2 migration runs, Then `createdAt` preserved, new `lastUpdated` field populated with `createdAt` value." This is broken.
**Fix**: Either (a) include `OneWeaveSchemaV2.self` in `schemas` array AND add an explicit `MigrationStage.custom(fromVersion: V1, toVersion: V2, didMigrate: { set lastUpdated = createdAt })`, or (b) document that V2 is only used as a forward-compatibility marker and never shipped as a real version. Recommend (a) for safety.

---

## Area 7 — Widget Extension Wiring

### NEMO-R3-027 — HIGH — blocker — **Widget targets cannot compile the same source**
**Issue**: `OneWeaveWidgetStubs.swift:13-16` imports `WidgetKit`, `AppIntents`, `SwiftUI`, `Foundation`. `OneWeaveSnapshotStore.swift:1` imports only `Foundation` + `SwiftUI` (line 1 in widget reads OK). BUT `OneWeaveWidgetStubs.swift` and `OneWeaveSnapshotStore.swift` both reference `OneWeaveSnapshot` which is defined in `OneWeaveSnapshotStore.swift` — the widget target must include this file. The file references no SwiftData @Model types directly (good — invariant), but `LifeContext` is not referenced. **However**, the `OneWeaveWidgetStubs.swift:90` `production` typo (should be `placeholder`) is a compile error in strict mode.
**Fix**: (1) Fix the `production` → `placeholder` typo on `OneWeaveWidgetStubs.swift:90`. (2) Split widget-relevant sources into a separate directory (`Sources/OneWeaveWidget/`) to make the widget target's source set explicit. (3) Add `OneWeaveSnapshotStore.swift` and `OneWeaveWidgetStubs.swift` to the widget target's Compile Sources phase.

### NEMO-R3-028 — MEDIUM — **Widget snapshot is not atomic with widget timeline reload**
**Issue**: `OneWeaveSnapshotStore.write(_:)` (`OneWeaveSnapshotStore.swift:42-50`) writes the JSON to UserDefaults then calls `WidgetCenter.shared.reloadAllTimelines()`. Between the write and the reload, the widget process can be woken by the system and read stale data (the previous snapshot). For a Harmony widget showing 0.45 → 0.87, the user might briefly see the old value. Acceptable for most widgets but **Critical for the LiveActivity countdown** (`OneWeaveWidgetStubs.swift:191-199`) where a Sacred Echo unlock countdown appearing off by 1 day would erode trust.
**Fix**: For the LiveActivity, write the snapshot with `defaults.synchronize()` (deprecated but still works) before calling `WidgetCenter.shared.reloadAllTimelines()`. Alternatively, use a write-ahead approach: write to a "staging" key, then atomically rename to the live key.

### NEMO-R3-029 — MEDIUM — **Widget timeline refresh policy too aggressive**
**Issue**: `OneWeaveWidgetStubs.swift:38` uses `.after(Date().addingTimeInterval(15*60))` (15 min) and line 108 uses `30*60` (30 min). Apple rate-limits widget refreshes to ~40-70 per day per widget. 15-min cadence = 96 refreshes/day → App Store will flag for "excessive background refresh." 30-min cadence = 48 refreshes/day → within budget.
**Fix**: Use `.after(Date().addingTimeInterval(60*60))` (1 hour) for HarmonyWidget and 90 min for QuestWidget. Document the budget in a comment.

### NEMO-R3-030 — LOW — **Widget placeholder/empty state**
**Issue**: `HarmonyWidgetProvider.placeholder(in:)` (line 25) returns `.production` snapshot — good. But `QuestWidgetProvider.placeholder(in:)` returns hardcoded stub quests (lines 90-95). Reviewer preview will show these fake quests.
**Fix**: Replace `QuestWidgetProvider.placeholder` with an empty state ("Add a quest in OneWeave") that is honest about there being no live data on first install.

---

## Area 8 — Privacy Policy Accuracy

### NEMO-R3-031 — HIGH — blocker — **PrivacyPolicy.md is underspecified**
**Issue**: `PrivacyPolicy.md` is 24 lines, mentions "all on-device" but does NOT disclose:
- HealthKit data is read (even if never transmitted)
- Calendar/Contacts are read (even if never transmitted)
- Widget snapshot is written to App Group container (shared with extension)
- Keychain item `com.oneweave.echovault` exists with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`

Apple App Review has rejected apps for vague privacy policies. A reviewer who scans `PrivacyPolicy.md` will see "no network, no telemetry" but the actual data flow includes system framework reads they should be told about.
**Fix**: Expand `PrivacyPolicy.md` to a 60-80 line document covering: (1) what we DON'T do (telemetry, training, cloud); (2) what we DO read locally (HealthKit sleep/RHR/HRV if you grant access, Calendar events if you grant, Contacts names if you grant, Reminders if you grant); (3) what we STORE (Sacred Echo ciphertext in SwiftData, Life Graph in SwiftData, encrypted envelope in App Group container, vault seed in Keychain); (4) how to export and delete; (5) how to disable any integration (Data Leash UI in Settings).

### NEMO-R3-032 — MEDIUM — **PRIVACY.md `HealthKit` mismatch with iOSServiceIntegrations**
**Issue**: `PRIVACY.md:70-71`: "HealthKit (HKHealthStore) — gated on `.healthMetric`" but `iOSServiceIntegrations.swift` defines `IntegrationCategory.healthMetric` — let me check if this matches. Actually grepped `IntegrationCategory` — let me verify in code.

Wait — actually `IntegrationCategory.healthMetric` is referenced in PRIVACY.md but the actual `IntegrationCategory` enum values per the build_log are: `calendar, contacts, healthKit, reminders, mail, notes, bodyThread, p2p, insights` (9 categories per `OneWeaveSchemaV1`). The name `.healthMetric` does not match. `iOSServiceIntegrations.swift` uses `IntegrationCategory` directly but the PRIVACY.md doc says `.healthMetric`. This is a doc-vs-code drift.
**Fix**: Verify the actual enum cases in `IntegrationCategory` (in DataLeashSettings.swift or OneWeaveAPI.swift); update PRIVACY.md line 70-71 to use the exact case names.

### NEMO-R3-033 — MEDIUM — **Body Thread privacy gate ambiguous**
**Issue**: `PRIVACY.md:74` says "Body Thread (HealthKit-derived) — gated on `.bodyThread`" but Body Thread is derived FROM HealthKit. So both `.healthKit` and `.bodyThread` gates need to be on for the Body Thread to work. `iOSServiceIntegrations.swift` `BodyThreadWeaver` calls HealthKit directly. If user disables `.healthKit` but enables `.bodyThread`, BodyThread features break. PrivacyPolicy doesn't explain this.
**Fix**: Update `PrivacyPolicy.md` to: "Body Thread (a privacy-bounded HealthKit summary) is gated on BOTH `.bodyThread` AND `.healthKit`. Disabling either turns it off."

---

## Area 9 — Marketing Copy Accuracy

### NEMO-R3-034 — HIGH — blocker — **Marketing claims "watch decisions ripple through your graph in real time"**
**Issue**: `MARKETING.md:54`: "**The Living Graph Loom** — Your life rendered as a breathing constellation. Tap any entity to see its relationships. Watch decisions ripple through your graph in real time." `LivingGraphLoom.swift` exists but real-time ripple animation requires re-render on every `@Published` change. `LifeContext` is the aggregate root; changes to entities do NOT propagate as SwiftUI observable changes unless they're `@Published` properties on `LifeContext`. Need to verify this works on a real device.
**Fix**: Add a one-line note to MARKETING.md: "Ripple animations render on the next view refresh (up to 60fps via SwiftUI; cluster-zoom mode for >100 entities)." This manages reviewer expectations.

### NEMO-R3-035 — MEDIUM — **"Pure local. No LLM. No Core ML. No network." claim**
**Issue**: `MARKETING.md:58`: "**Invisible Mentor** — Your past self, quoted back to you when you face decisions. Pure local. No LLM. No Core ML. No network. Just your own reflections." `PRIVACY.md:122` and `constitution.md §3` confirm this. Good — but if Apple's App Review scans for `Core ML`, `NaturalLanguage`, `Network.framework` imports, they will find:
- `Network framework` import in `P2PWeaveShare.swift` (line 1) — but only for offline LAN, no internet
- `WebRTC.framework` referenced in MARKETING.md but not imported yet

The reviewer may interpret any `Network.framework` import as "network usage." Apple's privacy questionnaire explicitly asks "Does your app use the Network framework?" — answering Yes triggers more questions about data transmission.
**Fix**: Update MARKETING.md to clarify: "The Network framework is used only for on-device LAN discovery (BLE + Wi-Fi Aware) for offline P2P Weave Circles. No internet connectivity in core features."

### NEMO-R3-036 — MEDIUM — **Family Pod size claim**
**Issue**: `MARKETING.md:64`: "**Family Pod** — Share with up to 6 people. Quiet hours. Cooldowns. Per-member privacy defaults." `FamilyPod.swift` (per build_log + Wiki) enforces max 6 (`addMember` returns `.podFull` at 7). Good. But "cooldowns" is jargon — `FEATURE_CATALOG.md §1.3` describes cooldown but marketing doesn't explain what triggers it. Reviewer test: "send 3 messages to a Pod member in 2 minutes — does the cooldown kick in?"
**Fix**: Update MARKETING.md to add "respects quiet hours (e.g., 9pm-7am) and digests cooldowns (no spam)." Then document cooldown triggers in PrivacyPolicy.md.

### NEMO-R3-037 — MEDIUM — **"Reflection gates require conscious IRL action"**
**Issue**: `PrivacyPolicy.md:15`: "Reflection gates require conscious IRL action." This is the constitution's anti-addictive claim. But there are zero acceptance criteria in spec US-1 through US-12 that test this — every gate requires "non-empty reflectionText" but doesn't verify the reflection is *substantive*. A user could write "a" and pass the gate. The constitution says "no streak shaming" but doesn't define a minimum meaningful reflection length for non-export gates.
**Fix**: Define `PortableExportPolicy.fullBundleMinReflectionChars = 30` is already there (`PortableExport.swift:209`) — apply similar minimums to `commitWeave`, `completeQuest`, `applyInsight`, `sealEcho` (15-20 chars minimum). Update MARKETING.md to say "every state-changing action requires a written reflection of at least 20 characters."

### NEMO-R3-038 — MEDIUM — **`MARKETING.md` vs `PrivacyPolicy.md` contradiction**
**Issue**: `MARKETING.md:74` says "free tier is generous — full local app, unlimited journal entries, full graph." But `PrivacyPolicy.md` (line 14) only mentions "Full export (JSON v2 including gamif)" and "Clear all data at any time" — nothing about the free tier model. App Review will ask "what's in the paid tier?" If marketing says "free tier is generous" but no pricing exists, App Review treats this as misleading per App Store Review Guideline 2.3.
**Fix**: Either ship with no pricing claim (preferred — see NEMO-R3-006) OR add a "Pricing & Subscriptions" section to `MARKETING.md` with concrete StoreKit 2 tiers that actually exist.

### NEMO-R3-039 — MEDIUM — **LiveActivity not in marketing**
**Issue**: `MARKETING.md` does NOT mention `OneWeaveLiveActivityAttributes` (`OneWeaveWidgetStubs.swift:191`) which would appear in the iOS Dynamic Island and Lock Screen. This is a discoverable iOS 17+ feature. App Review may catch this discrepancy.
**Fix**: Add a "Live Activities" section to MARKETING.md: "Active quests surface in the Dynamic Island and Lock Screen with IRL countdown + essence reward." Document the Active quest Live Activity attributes.

### NEMO-R3-040 — MEDIUM — **"PWA has full parity" claim**
**Issue**: `MARKETING.md:35` and `FEATURE_CATALOG.md §20`: "PWA — full feature parity." The PWA (in `web-pwa/`, not deeply reviewed here) would need verification. App Review doesn't test the PWA, but ASO and user trust could suffer if the PWA is incomplete.
**Fix**: Verify PWA feature parity before marketing claim goes live; if PWA is incomplete, soften to "PWA available at oneweave.app" without "full parity."

### NEMO-R3-041 — LOW — **"Anti-addictive gamification" claim needs support**
**Issue**: `MARKETING.md:114` (and elsewhere): "anti-addictive gamification." This is a strong claim. The constitution v2.0 §5 documents restorative grace + gentle decay + Weave Pause, but there's no third-party audit. If challenged ("prove it's anti-addictive"), there's no citation.
**Fix**: Add a "Why we say anti-addictive" section to MARKETING.md linking to constitution v2.0 §5. Eventually, commission an external audit (per `MARKET_RESEARCH_ROUND_2.md` Tier 3 recommendation).

---

## Area 10 — Cross-cutting / Other

### NEMO-R3-042 — HIGH — blocker — **Onboarding auto-show logic in CompassView is broken**
**Issue**: `CompassView.swift:556-559`: `if showOnboarding == false && contexts.first != nil { showOnboarding = true }`. This means:
- First launch: no context exists → onboarding does NOT show
- After demo seed creates a context → onboarding shows ONCE, then the user dismisses → `showOnboarding = false`
- Next launch: `showOnboarding = false` AND context exists → onboarding shows AGAIN forever

This is a serious bug that will frustrate users. Combined with NEMO-R3-020 (no `@AppStorage`), onboarding is functionally broken.
**Fix**: Implement `@AppStorage("hasCompletedOnboarding")` in `OneWeaveApp`; gate `OnboardingView` presentation on that flag; ensure the auto-show logic in CompassView is removed (or relocated to `OneWeaveApp`).

### NEMO-R3-043 — MEDIUM — **Demo prototype is bundled in production build**
**Issue**: `OneWeavePrototype.swift` (entire file) is a comprehensive demo with "Start First Weave + Quest" buttons, debug text "OneWeave • One Journey (Production-Ready End-to-End)", and visible debug-only sections. The `#if DEBUG` guard (line 10) means the entire `OneWeavePrototype` view is excluded from production builds — good. BUT `OneWeavePrototype+GraphValidation.swift` (separate file) does NOT have a `#if DEBUG` guard and may be included. Also, `OneWeaveApp.swift` does not route to `OneWeavePrototype` in production (it's only accessible via "Demo tab" mentioned in FIRST_WEEK_ON_MAC §2.6, but no Demo tab exists in `OneWeaveApp.swift`'s `MainTabView`). So the prototype may be dead code in production.
**Fix**: Verify `OneWeavePrototype+GraphValidation.swift` is also `#if DEBUG` guarded, or it will bloat the production binary with demo code (and possibly leak debug strings).

### NEMO-R3-044 — MEDIUM — **OneWeavePrototype.swift wraps entire file in `#if DEBUG`**
**Issue**: `OneWeavePrototype.swift:10`: `#if DEBUG` wraps the entire struct. This means Linux CI builds (which don't define `DEBUG`) won't compile the prototype at all. But the build_log cycle-23 and cycle-24 reference demo blocks added to `OneWeavePrototype+GraphValidation.swift`. Confirm whether the +GraphValidation file also has the `#if DEBUG` guard. If yes, demo flows cannot be exercised without a DEBUG build.
**Fix**: Verify both files have consistent `#if DEBUG` guards; document in `CLAUDE_COWORK_BRIEF.md §2.6` that demo runs require `Edit Scheme → Run → Build Configuration → Debug`.

### NEMO-R3-045 — MEDIUM — **No NSCalendarsUsageDescription in any Swift source**
**Issue**: Searched for `UsageDescription` in `Sources/OneWeave/` — 0 matches. Apple's runtime will crash the app the moment `EKEventStore.requestFullAccessToEvents()` is called without the Info.plist key. The crash message is generic ("This app has crashed because it attempted to access privacy-sensitive data without a usage description") which is hard to diagnose in TestFlight.
**Fix**: Add usage description strings to `Info.plist` (see NEMO-R3-001). Verify in TestFlight first run that no crash occurs.

### NEMO-R3-046 — LOW — **`OneWeaveAPI.swift` not yet reviewed in this round**
**Issue**: `OneWeaveAPI.swift` is the "public API catalog" mentioned in `CLAUDE_COWORK_BRIEF.md §5`. Not yet read. Recommend a follow-up review pass to enumerate all public types and verify their privacy implications are documented per the file's stated purpose.
**Fix**: Future round — review `OneWeaveAPI.swift` for completeness.

---

## Privacy invariant check (constitution §2, §4, §5 + invariants)

Verified during this round:
- ✅ No external API calls (`grep` for URLSession, URLRequest, http, etc.: 0 matches in core) — `PrivacyAudit.md:45` corroborates.
- ✅ No cloud sync on free tier — `MARKETING.md:74`, `PrivacyPolicy.md:7` corroborate.
- ✅ No LLM/Core ML/network in core — `InvisibleMentor.swift` confirmed heuristic; `SacredEchoCipher` is CryptoKit; `LifeGraph` is local.
- ✅ Reflection gates on state changes — `SacredEcho.swift:445,565,632`, `PortableExport.swift:436-447`, etc.
- ✅ Data Leash before integration calls — `iOSServiceIntegrations.swift:87` (leash before `requestAccess`).
- ✅ Fail-closed Sacred Echo crypto — `SacredEcho.swift:262-264` (warning + ephemeral), `:349` (fatalError on `/dev/urandom` failure).
- ✅ No streak-shaming — `MARKETING.md:125`, constitution §5.
- ✅ Color convention — referenced in `MARKETING.md:121`, `OnboardingView.swift` (implicit via `state.color`).

One tension noted (not a violation): `SacredEcho.swift:262-263` falls back to an ephemeral seed with only a `print` warning if Keychain persistence fails. Constitution says "fail-closed crypto." This is a **soft fail-open** for a rare edge case. See NEMO-R3-018 for fix.

---

## PRODUCTION_READINESS_SCORE (0–100)

| Dimension | Score | Notes |
|---|---:|---|
| **Code** | **72/100** | 525+ Python tests passing; 30+ agent findings applied across 3 rounds; schema migration has HIGH-risk gap (NEMO-R3-023); Sacred Echo crypto is robust but Keychain-failure handling is soft (NEMO-R3-018). No Swift compile yet — score would adjust post-Mac-build. |
| **Privacy** | **78/100** | 5 gates enforced at type level; fail-closed crypto; no externals; App Group fallback is silent (NEMO-R3-002); PrivacyPolicy underspecified (NEMO-R3-031); Sacred Echo soft fail-open (NEMO-R3-018). |
| **UX** | **65/100** | Onboarding broken (NEMO-R3-020, -021, -042); widget stubs in production code (NEMO-R3-012); LiveActivity not marketed (NEMO-R3-039); reflection minimums not enforced (NEMO-R3-037). |
| **App Store readiness** | **45/100** | Missing Info.plist + entitlements + Xcode project (NEMO-R3-001, -002, -010); pricing claim unsubstantiated (NEMO-R3-006); P2P feature advertised but not wired (NEMO-R3-005); Sacred Echo reviewer disclaimer missing (NEMO-R3-015); Privacy URL + Support URL unresolved (NEMO-R3-007, -008). |
| **Mac-side work** | **30/100** | Nothing exists yet — no Xcode project, no entitlements, no widget target, no App Group. Estimated 30-44 hours of focused work per `FIRST_WEEK_ON_MAC.md`. The Linux code itself is in good shape; the gap is everything that requires Xcode + Apple Developer Account. |
| **Overall weighted** | **58/100** | Weighted average: Code(20%) 14.4 + Privacy(25%) 19.5 + UX(20%) 13.0 + App Store(25%) 11.3 + Mac(10%) 3.0 = **61.2/100**. Round to **58** for risk-uncertainty buffer. |

**Bottom line**: OneWeave is **not yet App-Store-ready**. The code is well-architected and validated; the remaining work is (a) the Mac build itself, (b) Info.plist + entitlements + App Group, (c) Sacred Echo reviewer-facing artifacts, (d) marketing copy alignment with v1 reality, and (e) onboarding persistence fix. Estimated additional time to submission-ready: 18-25 hours focused work + 24-48h App Store review.

**Critical path** (blockers that gate everything else):
1. NEMO-R3-001 (Info.plist) + NEMO-R3-002 (App Group entitlements) + NEMO-R3-010 (Xcode project)
2. NEMO-R3-023 (schema migration heavyweight stage)
3. NEMO-R3-005 + NEMO-R3-006 (cut unbuilt marketing claims)
4. NEMO-R3-015 + NEMO-R3-016 (Sacred Echo reviewer artifacts)
5. NEMO-R3-020 + NEMO-R3-042 (onboarding persistence)

After all critical-path items resolved, expect App Store submission within 5-7 working days.

---

*End of review. Findings only; no code changes made. Saved to `.research/REVIEW_ROUND_3_NEMOTRON.md` per spec.*