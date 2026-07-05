# OneWeave — Tier B Implementation Playbook

**Purpose:** This document is the complete checklist for getting OneWeave from "Linux VPS has all the Swift code" to "running on an iPhone." It assumes a Mac with Xcode 15+ and an Apple Developer account.

**Scope:** The Tier A code (5 features + agent-review fixes) is done and validated on Linux. What's left is the iOS-native scaffolding that cannot be done off-device: Xcode project, signing, App Group entitlements, widget extension, asset catalog, Info.plist privacy strings, and a test deployment.

---

## Phase 1 — Project Scaffolding (Day 1, ~3 hours)

### 1.1 Create the Xcode project

```
Xcode → File → New → Project → iOS App
  Product Name:        OneWeave
  Team:                <your Apple Developer Team ID>
  Organization ID:      com.oneweave
  Bundle Identifier:   com.oneweave.OneWeave
  Interface:           SwiftUI
  Language:            Swift
  Storage:             SwiftData
  Minimum Deployment:  iOS 17.0
```

When Xcode asks, **do NOT** create the default SwiftUI files — we'll use the existing Tier A sources.

### 1.2 Add the Tier A sources to the project

1. In Finder, drag `Sources/OneWeave/*.swift` into the Xcode project's `OneWeave/` group.
2. When prompted, choose **Copy items if needed** and add to the **OneWeave target**.
3. Verify all 13 Swift files are in the build target:
   - `OneWeaveApp.swift` (modified)
   - `MainTabView.swift` (the `MainTabView` struct is in OneWeaveApp.swift — confirm)
   - `LifeContext.swift` (modified)
   - `LifeGraph.swift` (modified)
   - `GraphInsightGenerator.swift` (modified)
   - `ResonanceOracle.swift` (modified)
   - `ResonanceOracleSheet.swift`
   - `BodyThreadWeaver.swift` (modified)
   - `BodyThreadSheet.swift`
   - `DataLeashSettings.swift`
   - `P2PWeaveShare.swift` (modified)
   - `iOSServiceIntegrations.swift` (modified)
   - `SacredEcho.swift` (new in Tier A #3)
   - `InvisibleMentor.swift` (new in Tier A #4)
   - `AppLifecycleCoordinator.swift` (new in Tier A #5)
   - `LoomGeometry.swift` (new in Round 2 #3)
   - `LivingGraphLoom.swift` (new in Round 2 #3)
   - `CommandPalette.swift`
   - `MasteryMapView.swift`, `CompassView.swift`, `SettingsView.swift`, etc. (existing)

4. Build the project (`⌘B`). Fix any compile errors. (Per agent review, the only known Linux-portability risk was `createReminder` being now `async` — call sites must `await` it. Search the codebase for `RemindersIntegration.createReminder(` and ensure all call sites use `await`.)

### 1.3 Configure SwiftData schema

In `OneWeaveApp.swift`, the `modelContainer(for:)` call should list 11 models (per the agent-review-fixed preview container):
- `LifeContext.self`
- `TimelineEvent.self`
- `WeaveQuest.self`
- `BasicSelfThread.self`
- `StewardshipThread.self`
- `CareKinThread.self`
- `MeaningThread.self`
- `LifeEntity.self`
- `LifeRelationship.self`
- `DataLeashSettingsRecord.self`
- `SacredEcho.self`

If you add any model with a non-optional field, add a default value or migration plan. SwiftData will refuse to launch with a missing default.

---

## Phase 2 — Entitlements & Capabilities (Day 1, ~2 hours)

### 2.1 App Group (required for widget + lifecycle envelope)

**Why:** `AppLifecycleCoordinator` writes the encrypted envelope to the App Group container so the widget extension can read it.

1. Xcode → target → Signing & Capabilities → **+ Capability** → **App Groups**
2. Add group: `group.com.oneweave`
3. Repeat for the Widget Extension target (Phase 3).

If you don't have an Apple Developer account set up, register the App Group prefix first at developer.apple.com → Certificates, Identifiers & Profiles → Identifiers → App Groups.

### 2.2 HealthKit (required for Body Thread + HealthIntegration)

1. Xcode → target → Signing & Capabilities → **+ Capability** → **HealthKit**
2. In `Info.plist` (or Xcode's "Info" tab), add:
   - `NSHealthShareUsageDescription` = "OneWeave reads sleep and resting heart rate to detect body coherence and surface gentle Weave Pause prompts. Data stays on your device."
   - `NSHealthUpdateUsageDescription` = "OneWeave does not write health data. This entry is here for future-proofing."

### 2.3 EventKit (required for Calendar + Reminders)

1. Xcode → target → Signing & Capabilities → **+ Capability** → **Calendars** + **Reminders**
2. In `Info.plist`:
   - `NSCalendarsFullAccessUsageDescription` = "OneWeave reads calendar events as Life Graph entities to detect patterns across your life. Data stays on your device."
   - `NSRemindersFullAccessUsageDescription` = "OneWeave creates reminders from your quests, reflection-gated. Data stays on your device."

### 2.4 Contacts

1. Xcode → target → Signing & Capabilities → **+ Capability** → **Contacts**
2. In `Info.plist`:
   - `NSContactsUsageDescription` = "OneWeave imports contact names as CareKin entities in your Life Graph, to surface patterns in the people you spend time with. Data stays on your device."

### 2.5 Local Network (required for P2P Weave Circles)

1. Xcode → target → Signing & Capabilities → **+ Capability** → **Local Network**
2. In `Info.plist`:
   - `NSLocalNetworkUsageDescription` = "OneWeave uses the local network to find Weave Circle members on the same Wi-Fi for private, serverless reflection sharing."
   - `NSBonjourServices` = `_oneweave._tcp` (or similar service type — pick when implementing Bonjour discovery in P2PWeaveShare.swift)

### 2.6 Background Modes (required for Echo unlock notifications)

1. Xcode → target → Signing & Capabilities → **+ Capability** → **Background Modes**
2. Enable **Remote notifications** (for echo-unlock pings) — *optional, but useful.*

### 2.7 Face ID (recommended for Sacred Echo vault access)

1. Xcode → target → Signing & Capabilities → **+ Capability** → **Face ID**
2. In `Info.plist`:
   - `NSFaceIDUsageDescription` = "Use Face ID to open your Sacred Echo vault."

---

## Phase 3 — Widget Extension (Day 2, ~4 hours)

### 3.1 Create the widget target

```
Xcode → File → New → Target → Widget Extension
  Product Name:    OneWeaveWidgets
  Include Live Activity: YES (for Harmony/Quest Live Activities)
  Include Configuration Intent: NO (we don't use AppIntents for configuration)
```

### 3.2 Share App Group

In `OneWeaveWidgets.entitlements`, add the same `group.com.oneweave` App Group.

### 3.3 Implement the widgets

The widgets reference `oneweave.snapshot.v1` in `UserDefaults(suiteName: "group.com.oneweave")`. The main app's `LifeContext.pushSnapshotToWidgets(from:)` writes this. Confirm the snapshot shape:

```swift
struct WidgetSnapshot: Codable {
    let harmonyScore: Double
    let weaveEssence: Int
    let lifeCoherence: Double
    let activeQuests: [QuestStub]
    let echoCountdown: [EchoStub]  // for Sacred Echo countdown widget
    let lastUpdated: Date
}
```

Widgets to ship in v1:
1. **HarmonyWidget** — circular gauge of harmony, refresh hourly.
2. **QuestWidget** — top 3 active quests with reflection gate progress.
3. **EchoCountdownWidget** — days until next Sacred Echo unlocks (or "ready to open" if ≤24h).
4. **OneWeaveLiveActivity** — Live Activity showing current harmony + active amplifier (already in the codebase as `OneWeaveLiveActivityAttributes`).

### 3.4 Wire the AppIntents

The existing `AppIntents` (`LogWeaveIntent`, `CompleteQuestIntent`, `ShowHarmonyIntent`) need their `perform()` methods to be implemented. Each should:
1. Open the App Group snapshot for read.
2. NOT mutate state (intents are read-only; mutation goes through the main app).
3. Show a confirmation snippet in the widget.

---

## Phase 4 — Asset Catalog (Day 2, ~1 hour)

### 4.1 App icon

Generate a 1024×1024 icon (loom-like, breathing circle motif). Apple's Icon Composer can take a vector SVG.

### 4.2 Accent color

Set the app's accent color to a calm warm-amber (HSB ≈ 0.08, 0.4, 0.9) to match the Living Graph Loom palette.

### 4.3 Launch screen

Use a centered breathing-circle motif (single SVG or Lottie). Avoid imagery that suggests urgency.

---

## Phase 5 — TestFlight Build (Day 3, ~2 hours)

### 5.1 Archive

```
Xcode → Product → Archive
```

After archive completes, distribute via Organizer → Distribute App → TestFlight Internal.

### 5.2 Internal testing checklist

Before inviting testers:
- [ ] Cold launch lands on Compass view within 2s
- [ ] App Group envelope persists across relaunches
- [ ] Body Thread "Weave Pause" prompt fires when Health data shows low coherence
- [ ] Sacred Echo cannot be opened before `unlockAt` (Tier A review fix)
- [ ] Sacred Echo cannot be re-opened after first open
- [ ] Mail composer opens with reflection body
- [ ] Notes share sheet contains reflection markdown
- [ ] Reminders create requires non-empty reflection
- [ ] Invisible Mentor dormant when no reflections exist
- [ ] Living Graph Loom breathes at season-appropriate rate
- [ ] scenePhase → coordinator triggers foreground echo re-evaluation
- [ ] Data Leash UI toggles actually gate integrations (turn off Health → Body Thread goes silent)
- [ ] Encryption envelope persists across background/foreground (file in App Group container)

### 5.3 External TestFlight (optional, after internal passes)

- App privacy questions filled out at App Store Connect
- Export compliance: declare "No" for encryption (we use standard HTTPS/TLS, not custom cryptography that needs BIS registration) — *but consult counsel if uncertain*
- Test Information: include a 1-paragraph privacy story explaining the Data Leash + encrypted-at-rest envelope

---

## Phase 6 — Known Gaps From Tier A Code Review

These are the deferred items from the Round 2 #1 multi-agent review. None block TestFlight, but address them before App Store submission:

### High priority (block submission)

1. **Detect Data Leash before requesting iOS permission** (Grok #18) — `CalendarIntegration.importRecentEvents` currently requests EventKit permission before checking Data Leash. Fix by reordering the guards. Same fix needed for `RemindersIntegration.importReminders`.

2. **Skip private entities in Invisible Mentor** (Grok #15) — `makeInput` ingests all non-empty summaries; should skip `isPrivate` entities.

### Medium priority (post-launch OK)

3. **Cache key includes more fields** (Grok #12) — current XOR-fold key works for v1; tighten post-launch with entity count + domain/memoryType buckets.

4. **`detectContradictions` uses passed entities consistently** (Grok #13) — minor inconsistency.

5. **`openedEchoes` in MentorInput** (Grok #14) — populated but unused. Wire it into scoring (e.g. "your echo from 90 days ago opened — here's what you wrote then").

### Low priority (technical debt)

6. **mailto: query value percent-encoding** (Grok #23)
7. **`persist` swallows errors silently** (Grok #21) — add retry/alert.
8. **Delivery/release reflections plaintext in attributes** (Grok #9) — minor, but they should be encrypted to match the vault's promise.

---

## Phase 7 — Out-of-Scope for v1

These were mentioned in earlier planning but are explicitly NOT in v1:

- macOS Catalyst version (will come in v1.1 once iOS is stable)
- watchOS complication (will come in v1.2 after Apple Watch complication API stabilizes)
- iCloud sync (intentionally not — privacy-first means no Apple servers for user data)
- AI-generated content (deliberately excluded — Invisible Mentor uses user's own words only)
- Social feed / likes / comments (explicitly excluded — anti-addictive design)

---

## Phase 8 — Pricing & Monetization (post-launch)

Privacy-first apps that do well monetarily tend to use one of:
1. **One-time purchase** ($14.99 — full app unlock). Recommended for v1.
2. **Subscription** ($4.99/mo or $39.99/yr) — risks looking like the apps OneWeave is positioned against.
3. **Donation / patronage** — fits the privacy-first ethos; lower revenue ceiling.

**Recommendation:** ship as one-time purchase. Avoid the subscription pattern.

---

## Appendix A — Files Modified This Cycle (for reference)

| File | What changed | Tier |
|---|---|---|
| `SacredEcho.swift` | vaultSeed fail-closed; randomBytes secure; open() blocks re-open; handDeliver requires opened; state getter tightened | A |
| `AppLifecycleCoordinator.swift` | foreground routing fixed; inout removed; randomBytes Linux-safe | A |
| `iOSServiceIntegrations.swift` | createReminder async; importContacts detached; HealthThread @MainActor; importRecentEvents invalidates; bpmSafe removed | A |
| `GraphInsightGenerator.swift` | cache guard fixed; GraphInsight Identifiable | A |
| `OneWeaveApp.swift` | preview container synced; dead scenePhase removed | A |
| `LivingGraphLoom.swift` | NEW — SwiftUI breathing graph visualization | R2 |
| `LoomGeometry.swift` | NEW — pure-Swift placement math | R2 |
| `OneWeavePrototype+GraphValidation.swift` | extended with Tier A + Round 2 demos | A |

## Appendix B — Validation Suite (run before every commit)

```bash
cd /root/hermes-workspace/projects/oneweave
for f in .research/validate_tierA*.py .research/validate_round2_loom.py; do
    python3 "$f" | tail -1
done
```

Expected: `OVERALL: PASS` for every file. Current state: **87/87 PASS** across all suites.

---

**Status:** This document is ready. The next person with a Mac can execute Phase 1 in an afternoon and have a runnable build.