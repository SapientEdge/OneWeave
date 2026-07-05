I've now read all required files plus surveyed the lifecycle/onboarding/settings surface. Before writing: I confirmed several R3 blockers are **already fixed** in current source (completeQuest gate `LifeContext.swift:467-500`, season +2/+20 split `:113-128`, FamilyPod shims `:75-77`, `vaultSeed()` throws `SacredEcho.swift:263`, leash-before-permission on Contacts `iOSServiceIntegrations.swift:159`). My findings below are **net-new** — I exclude NEMO-R3-* and CLAUDE-R3-1..25 as integrated.

---

# OneWeave Production-Readiness Audit — Architectural / HIG / Spec (Claude, senior-iOS lens)

**Verdict:** The algorithm layer is genuinely strong. The *app* layer — the thing Apple reviews — is ~40% built. Below are 50 net-new findings + a submission checklist. `[L]` = Linux-fixable now, `[M]` = needs Mac/Xcode.

## A. Top 10 MISSING FEATURES (production Life-OS bar)

1. **iCloud-restore data-loss landmine.** Keychain vault seed is `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` (`SacredEcho.swift:406`). SwiftData store *is* in the iCloud device backup; the seed is **not**. Restore to a new phone → every Sacred Echo is permanently undecryptable, silently. No "this device only" warning, no migration story. This is the single highest-impact gap. `[L]` design / `[M]` implement.
2. **No notification system.** Zero `UNUserNotificationCenter` anywhere; briefings + Echo unlock countdowns can never surface. A Life OS that can't remind you isn't one. `[M]`
3. **No "About" screen** — no version/build, acknowledgements, support URL, license, "rate app." Support is impossible without a version string. `[L]`
4. **No in-app Privacy Dashboard** beyond on/off toggles — nothing shows *what is stored* (Keychain item, App-Group envelope, graph counts) or *where*. This is the app's whole pitch; it's invisible. `[L]`
5. **Export is one-way** (`PortableExport.swift`) — no import/restore. Constitution principle 10 ("portable data") is half-met; users can leave but never return. `[L]`
6. **No global search** across entities/echoes/decisions. Any graph >100 nodes is unnavigable. `[L]`
7. **No biometric app/vault lock** despite `NSFaceIDUsageDescription` being planned. The most sensitive app on the phone opens with no gate. `[M]`
8. **Widgets + Live Activity non-functional** (stubs only). Advertised Dynamic-Island countdown doesn't exist. `[M]`
9. **No first-run seeded state / empty states.** After onboarding, the user faces a blank Compass with no guided first weave (plan T073 unbuilt). `[L]`
10. **No crash/error telemetry-free recovery surface** — no "something went wrong, your data is safe" screen for any failed async path. `[L]`

## B. Top 10 ARCHITECTURE GAPS (compile / safety / perf)

1. **Migration plan is dead code.** `OneWeaveApp.swift:14-28` calls `.modelContainer(for:[…])` with **no `migrationPlan:` argument** — `OneWeaveMigrationPlan` is never attached. So even after fixing NEMO-R3-023, nothing runs it. `[L]`
2. **`IntegrationCategory` has 6 cases, not 9** (`iOSServiceIntegrations.swift:44-51`: calendar/reminders/contacts/health/notes/mail). Constitution invariant #7 and PRIVACY.md mandate `bodyThread`, `p2p`, `insights` — they don't exist at the type level. Any code gating on them won't compile. `[L]`
3. **No `ModelContainer` failure handling** — init failure crashes with no recovery UX (`OneWeaveApp.swift:14-28`). Corrupt store on a real device = uninstall-only. `[L]`
4. **Reminders private-notes redaction uses `notes.hashValue`** (`iOSServiceIntegrations.swift:626`). Swift's `String.hashValue` is per-process randomized — the `[notes redacted — hash:…]` string changes every launch, so it's neither stable nor cryptographic. Use SHA-256 or drop it. `[L]`
5. **`randomBytes` calls `fatalError`** on RNG failure (`SacredEcho.swift:341,353`) instead of throwing `EchoError` — a recoverable condition becomes a crash. `[L]`
6. **Variable-ratio randomness in mastery** (`LifeContext.swift:399`, `Int.random(in:0..<2)`) makes gamification nondeterministic and untestable, and contradicts §5 (see D6). `[L]`
7. **Write amplification on widgets:** `updateFromEvent` → `updateHarmonyAndStreak` → `pushSnapshotToWidgets()` on *every* event (`LifeContext.swift:454`), each firing `WidgetCenter.reloadAllTimelines()`. Import bursts → reload storm + rate-limit exhaustion. `[L]` (debounce) / `[M]` (verify).
8. **`handDeliver` silently discards the delivery reflection** ("is simply dropped," `SacredEcho.swift:588`). A reflection-gated promise that loses the user's words. `[L]`
9. **`@Model LifeContext` mutated across actors** — gamification mutators aren't actor-isolated; SwiftData models aren't `Sendable` (deferred T090). Data races latent on background import. `[M]`
10. **`seal(seed:)`/`open(seed:)` injection params still not `#if DEBUG`-gated** (`SacredEcho.swift:287,305`) — production callers can bypass the vault (this is CLAUDE-R3-10; flagging it survived into current source). `[L]`

## C. Top 10 APPLE HIG / ACCESSIBILITY GAPS

1. **Dynamic Type unsupported** — fonts hard-coded (`.font(.title)`, `.body`), zero `ScaledMetric`/`dynamicTypeSize`. Layouts break at accessibility text sizes; this is a common rejection. `[L]`
2. **VoiceOver largely absent** — ~5 `accessibilityLabel`s in the entire app; the Canvas-rendered Living Loom is one opaque blob to VoiceOver with no audio-graph alternative. `[L]`
3. **Reduce Motion ignored** — the "breathing" Loom animates unconditionally; no `@Environment(\.accessibilityReduceMotion)`. Ironic for a "calm" app. `[L]`
4. **Color-only meaning** — the four Threads are distinguished purely by blue/green/orange/purple (invariant #10). HIG forbids color as sole information channel; needs symbol/label pairing. `[L]`
5. **Onboarding is a dismissible `.sheet`** — users swipe past the privacy intro. First-run should be a non-dismissible `fullScreenCover`. `[L]`
6. **Onboarding persistence still broken** — `OnboardingView` "Start Weaving" sets only `stateMachine.currentState` and never writes `hasCompletedOnboarding`; `CompassView` re-triggers it. (NEMO-R3-020 partially applied: the `@AppStorage` read exists, the write doesn't.) `[L]`
7. **Dark mode unvalidated** — literal `Color.blue/.green/...` with no asset-catalog color sets; contrast in dark mode unverified. `[L]`/`[M]`
8. **No notification authorization UX** (ties to A2) — HIG requires a soft pre-prompt before the system dialog. `[M]`
9. **Siri discoverability** — App Intents exist but no `AppShortcutsProvider` (NEMO-R3-013); also no `INVoiceShortcut` donation. `[M]`
10. **No launch screen** configured (Info.plist key / storyboard) — Apple requires one. `[M]`

## D. Top 10 SPEC / CONSTITUTION DRIFT POINTS

1. **"9 toggles" (§2, invariant #7) vs 6-case enum** (`iOSServiceIntegrations.swift:44-51`). Core privacy claim is numerically false in code. `[L]`
2. **"no plaintext reflections stored" (invariant #4) — violated:** `LifeContext.swift:139` appends `"+10 season reflection: \(trimmed.prefix(50))"` — 50 chars of reflection plaintext into `essenceLedger`, which is exportable. (Distinct from CLAUDE-R3-28's quest path.) `[L]`
3. **"Reflection-Gated Everything" (§4) — multiple ungated essence mutations:** `echoPastEvent` (`LifeContext.swift:516`), `awardBonusEssence` (`:557`), `spendEssenceForAmplifier` (`:523`) all change state with no reflection. `[L]`
4. **§5 anti-addictive vs variable-ratio reward:** `Int.random` mastery bump (`LifeContext.swift:399`) is precisely the slot-machine mechanic §5 forbids. `[L]`
5. **Schema invariant "V1→V2→V3 explicit migration" vs reality:** stages list only `.lightweight(V1→V3)`, V2 skipped, `convertAttributesJSONToDict` defined but never called (NEMO-R3-023/026 framed as an *invariant* breach). `[L]`
6. **Widget-key invariant "oneweave.snapshot.v1" vs `"OneWeaveSnapshot"`** in store (NEMO-R3-011) — a named constitutional invariant unmet. `[L]`
7. **Inconsistent reflection thresholds:** quest=20, FamilyPod=20, export=30, season=non-empty-only (`LifeContext.swift:132`). No central `ReflectionGate` (T079 deferred). §4 reads as uniform; code isn't. `[L]`
8. **"Portable data" (principle 10) — export without import.** `[L]`
9. **Paid tier ($9.99/$79.99) in Success Metrics + marketing, no StoreKit** (NEMO-R3-006) — constitutional metric references a non-existent SKU. `[L]` (cut copy).
10. **P2P invariant #8 (Signal/libsignal, STUN/TURN) vs stub transport** (NEMO-R3-005). Ship without it and amend the invariant, or it's a standing lie. `[L]` (descope).

## E. Build & Submission Readiness Checklist

**Info.plist — usage strings** (crash-on-first-use without these): `NSCalendarsFullAccessUsageDescription`, `NSRemindersFullAccessUsageDescription`, `NSContactsUsageDescription`, `NSHealthShareUsageDescription` (+`NSHealthUpdateUsageDescription` only if writing — currently read-only, omit), `NSFaceIDUsageDescription` (if biometric lock added), `NSLocalNetworkUsageDescription` + `NSBonjourServices` (only if P2P ships — else omit to avoid review questions). **No mic/camera keys** (no such APIs in source — don't add speculatively). `[M]`

**Info.plist — compliance keys:** `ITSAppUsesNonExemptEncryption = false` (AES-GCM local-at-rest qualifies for exemption); `UILaunchScreen` (launch screen); `CFBundleShortVersionString`/`CFBundleVersion` surfaced in the About screen. `[M]`

**Entitlements:** `com.apple.security.application-groups = [group.com.oneweave]` on **both** app + widget targets; `com.apple.developer.healthkit` (+ `healthkit.access` if needed). Add a runtime warning if `containerURL(forSecurityApplicationGroupIdentifier:)` returns nil (silent /tmp fallback today). `[M]`

**PrivacyInfo.xcprivacy:** `NSPrivacyTracking=false`; `NSPrivacyCollectedDataTypes=[]`; `NSPrivacyAccessedAPITypes` with required-reason codes for `UserDefaults` (CA92.1), `FileTimestamp` (C617.1), `DiskSpace` (E174.1), `SystemBootTime` (35F9.1). `[M]`

**App Store Connect privacy label:** You **cannot** select "Data Not Collected" — declaring HealthKit forces a "Health & Fitness → Health" disclosure even though read-only/on-device. Mark "Not used to track," "Not linked to identity." Calendar/Contacts likewise *used not collected*. `[M]`

**Review-gating non-code items:** public HTTPS Privacy Policy URL + Support URL (emails are rejected); Sacred Echo reviewer note + a `BuildConfiguration==.testFlight` demo-unlock path (reviewers can't wait 24h); cut P2P + pricing copy from v1 metadata. `[M]`

---

**Bottom line:** Net-new critical path beyond the R3 backlog: **(1)** wire the migration plan into `ModelContainer` *and* make it `.custom` (B1+D5 together — otherwise both are no-ops); **(2)** the iCloud-restore vault-key data-loss story (A1) — decide and document before any TestFlight user trusts an Echo; **(3)** the 6-vs-9 Data Leash enum (B2/D1) is a factual breach of the headline privacy claim; **(4)** plaintext-in-ledger (D2) and ungated essence paths (D3) quietly violate the two invariants the whole app is sold on. Items D2, D3, D4, B4 are all `[L]` and could be closed today on Linux.

Want me to open `tasks.md` entries (T097+) for the Linux-fixable set, or start applying D2/D3/D4/B1–B2 now?
itution invariants that the code quietly diverged from (D1-D3). None are architecturally deep; all are pre-submission mandatory.

Want me to write these up as `tasks.md` entries (T097+) and a `.research/REVIEW_ROUND_4_CLAUDE.md`, or apply the Linux-fixable subset (B1, B2, A2, A7, D3) now?
[ ] **Omit** `NSUserTrackingUsageDescription` (no tracking) — but still declare it absent.
- [ ] **Drop** `NSMicrophone`/`NSCamera`/`NSFaceID` from T014 unless a feature actually calls them (none in current source) — over-declaring triggers reviewer questions.

**Entitlements:**
- [ ] App Group `group.com.oneweave` on app **and** widget (NEMO-R3-002); log fallback if container is nil.
- [ ] `com.apple.developer.healthkit` (read).
- [ ] If T086 BGTask lands: `UIBackgroundModes` + `BGTaskSchedulerPermittedIdentifiers`.
- [ ] If notifications land (A1): no plist key, but request `UNUserNotificationCenter` authorization + rationale screen.

**Privacy nutrition label (App Store Connect):**
- [ ] Declare **Health → Health Information** as *Data Used (not linked, not tracking)*; cannot claim "Data Not Collected" with HealthKit present (NEMO-R3-003).
- [ ] `PrivacyInfo.xcprivacy`: `NSPrivacyTracking=false`, empty `NSPrivacyCollectedDataTypes`, `NSPrivacyAccessedAPITypes` for `UserDefaults`, `FileTimestamp`, `DiskSpace`, `SystemBootTime`.

**Data-deletion / compliance:**
- [ ] Fix `clearAllData` to delete **all 11 models incl. SacredEcho + leash record** (B3) — Apple checks that "delete my data" truly clears it. `[LINUX-FIXABLE]`
- [ ] Host Privacy Policy + Support **URLs** (NEMO-R3-007/-008); current `support@oneweave.app`/`about:blank` are invalid for ASC.

**Reviewer-facing:**
- [ ] Sacred Echo legal disclaimer in-app + demo-unlock path (NEMO-R3-015/-016).
- [ ] App Review notes: encryption-at-rest, no accounts, no server.

---

**Bottom line:** The single most important *new* finding is that **the headline privacy controls are unreachable and the onboarding-persistence fix never lands its write** — both are `[LINUX-FIXABLE]` today and both falsify "done" claims in the handoff. After that: the four compile/data-deletion bugs in `SettingsView`, the 6-vs-9 leash drift, and the total absence of notifications. None require a Mac. Fix these before the Xcode handoff so the Mac session spends its budget on signing + submission, not on re-discovering Linux-fixable gaps.

*(~1,940 words)*
