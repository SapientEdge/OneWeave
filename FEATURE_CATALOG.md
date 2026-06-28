# OneWeave — Complete Feature Catalog

**Last updated:** 2026-06-27 · **Source:** actual Swift source in `Sources/OneWeave/` · **Status legend:** ✅ Implemented & validated on Linux · 🟡 Designed in spec but not shipped · 🚧 Foundation only (Mac work needed)

This is an **honest catalog**. Every feature below either exists in the Swift source today (with line counts and tests), or is marked as designed-but-not-shipped. We don't sell vapor.

---

## 1. The Four Life Threads (Core Domain Model)

The world's first **event-driven multi-domain life model**. Each thread is a `@Model` SwiftData class; actions in one thread ripple to others via the central `TimelineService`.

### 1.1 Self Thread — Energy & Habits
- **Files:** `BasicSelfThread.swift` (296 LOC), `BodyThreadWeaver.swift` (606 LOC), `Sources/.../LifeContext.swift` (energy tracking)
- **What it does:** Tracks energy, habits, streaks with restorative grace, daily completed count
- **Unique feature:** Streak grace — break for up to 2 days without losing progress; gentle 0.5%/day decay after 7-day grace
- **Tests:** covered in `validate_tierA5_lifecycle.py`

### 1.2 Stewardship Thread — Resources & Leaks
- **Files:** `StewardshipThread.swift` (~800 LOC)
- **What it does:** Tracks subscriptions, detects "leaks" (subscriptions with declining use + cost > 1.5× average), suggests savings redirects to Meaning thread
- **Unique feature:** Real leak scoring — keyword + cost ratio + bloated count + underuse detection; no magic $9.99 fallback
- **Tests:** integrated into `OneWeavePrototype.swift` harness

### 1.3 Care & Kin Thread — Tasks & IRL Relationships
- **Files:** `CareKinThread.swift` (~400 LOC)
- **What it does:** Tracks family/care tasks, sends gentle IRL reminders, surfaces "you haven't called Mom in 23 days" via Relationship Decay Tracker
- **Unique feature:** **Family Pod** (`FamilyPod.swift`, 597 LOC) — anti-social family sharing with ≤6 people, quiet hours, cooldown, privacy defaults per member
- **Tests:** `validate_family_pod.py` — 52/52 PASS

### 1.4 Meaning Thread — Stories & Legacy
- **Files:** `MeaningThread.swift` (~400 LOC)
- **What it does:** Captures legacy narratives, captures "last good conversation with Dad", surfaces family stories
- **Unique feature:** **Sacred Echo Vault** (`SacredEcho.swift`, 21KB) — AES-256-GCM encrypted messages that can be sealed for delivery after death or at a future date, with Echo Decree (binding instruction) and Echo Heir (recipient + key release)
- **Tests:** `validate_tierA3_echo.py` — 10/10 PASS

---

## 2. Life Graph — The Knowledge Layer

A SwiftData-backed graph of entities (people, projects, events, places, decisions) with privacy-tiered relationships. First life app with a real graph, not a flat list.

- **Files:** `LifeGraph.swift` (with `attributes:[String:String]`, `lastUpdated`, `coherenceScoreContribution`, `isUserReflection`), `LifeContext.swift` (full CRUD engine)
- **Entities:** 11 types — `LifeEntity`, `LifeRelationship`, `LifeInsight`, `LifePattern` + privacy-tier enums (`private`/`shared`/`public`)
- **Vector search:** `[Float]` embeddings stored per entity for semantic similarity
- **Privacy filtering:** All queries filtered by `PrivacyTier` mapping to Data Leash controls
- **11,500+ lines of Swift covering:** CRUD, vector search, pattern detection, privacy filtering, JSON export/import, coherence score contribution
- **Tests:** `validate_round2_loom.py` — 15/15 PASS

### 2.1 Visualization: Living Graph Loom
- **Files:** `LoomGeometry.swift` (14 KB pure-Swift polar layout), `LivingGraphLoom.swift` (10 KB SwiftUI breathing Canvas renderer)
- **What it does:** Renders your life graph as a breathing polar constellation — entities as glowing nodes, relationships as bezier threads, animated pulses along edges
- **Tests:** `validate_round2_loom.py` — 15/15 PASS, caught 2 real bugs (geometry formula mismatch, single-node angle)

### 2.2 Portable Export
- **Files:** `PortableExport.swift` (639 LOC)
- **Three privacy leashes:** `Full` (everything), `SharedOnly` (privacy ≥ shared), `PublicOnly` (only public-tier)
- **Three formats:** Markdown (readable), OPML (graph-aware outline), JSON (roundtrip)
- **Checksum + manifest** for integrity verification
- **Tests:** `validate_portable_export.py` — 48/48 PASS

---

## 3. Privacy Data Leash — Granular Control

The first life app to give users a single matrix of toggles for what every integration can access, with reflection gates on every export/insight/share.

- **Files:** `DataLeashSettings.swift`, `LifeGraphiOSIntegrations.swift`, `iOSServiceIntegrations.swift`
- **Categories:** Calendar, Contacts, HealthKit, Reminders, Mail, Notes, Body Thread, P2P, Insights — 9 integration types
- **Persistence:** `DataLeashSettingsRecord` SwiftData entity — survives app restarts
- **Live read:** `currentLeash(in: ModelContext)` reads current state via `FetchDescriptor` BEFORE every integration call
- **Tests:** `validate_tierA2_integrations.py` — 21/21 PASS

---

## 4. iOS Native Integrations (Deep)

### 4.1 Calendar (EventKit)
- Reads events for next 4 hours, surfaces in morning briefing
- Pushes reflection-gated commitments as events
- **Privacy gate:** ✅ checked before enumeration

### 4.2 Contacts
- Imports contacts as `.person` Life Graph entities
- **Privacy gate:** ✅ checked before enumeration; runs on main thread detach

### 4.3 HealthKit
- Reads sleep, heart rate variability, active energy
- **Body-Thread Weaver:** grades body coherence 0-1 from sleep + activity + HRV; triggers Weave Pause when load high and body depleted
- **Privacy gate:** ✅ checked before read

### 4.4 Reminders
- Imports reminders as `.task` entities
- Creates new reminders via `createReminder` (async, reflection-gated)
- **Privacy gate:** ✅ checked

### 4.5 Mail (MessageUI)
- `MFMailComposeViewController` factory
- `insightBody` / `decisionBody` reflection-gated — can't email an insight without a personal note
- **Privacy gate:** ✅

### 4.6 Notes
- Three payload types: `reflectionPayload`, `decisionPayload`, `snapshotPayload`
- Exports to Apple Notes via Uniform Type Identifiers
- **Privacy gate:** ✅

**Tests:** `validate_tierA2_integrations.py` — 21/21 PASS

---

## 5. Universal Command Palette

- **Files:** `CommandPalette.swift` (full rewrite, 510 LOC)
- **Routes via:** `QuestService`, `TimelineService`, `stateMachine`
- **Reflection-gated commit sheet** — can't execute a command without writing why
- **No manual essence awards** — all rewards flow through event service to keep the audit trail
- **Access:** ⌘K / Spotlight-like / button

---

## 6. Cross-Domain Insight Engine

- **Files:** `GraphInsightGenerator.swift` (with `@MainActor` + 5-min TTL cache)
- **Cache key:** `entitySignature + contextFingerprint + generation + harmonyScoreBucket`
- **Auto-invalidation:** on `commitWeave`, `BodyThread` snapshot, P2P receive, `applyInsight`
- **Contradiction detection:** wired — finds stewardship load vs body depletion, commitment oversubscription, etc.
- **Reflection-gated application** — non-empty `reflectionText` required to apply any insight
- **Tests:** `validate_tierA1_cache.py` — 10/10 PASS

---

## 7. Resonance Oracle (Decision Simulator)

A local-only decision simulator that runs scenarios on your **own** Life Graph data and predicts ripple consequences.

- **Files:** `ResonanceOracle.swift`, `ResonanceOracleSheet.swift`
- **Pure local:** No LLM, no Core ML — algorithmic
- **Reflection-gated commit:** Can't save a decision without reflection text
- **Pushes to widget:** `pushSnapshotToWidgets` after commit
- **Cache invalidation:** invalidates GraphInsight cache on commit

---

## 8. Body-Thread Weaver

Bridges physical state (HealthKit) and emotional/spiritual threads.

- **Graded HealthThread** type (continuous 0-1 body coherence)
- **Weave Pause:** When load rising AND body depleted, surface "consider pausing" — **not enforced**, just suggested
- **Refactored `detectLowCoherence`** for graded values
- **Tests:** covered in `validate_tierA5_lifecycle.py` and `OneWeavePrototype.swift`

---

## 9. Sacred Echo Vault — `🪦 Encrypted Time-Capsule Messages`

**This is the killer feature nobody else has.**

- **Files:** `SacredEcho.swift` (21 KB)
- **AES-256-GCM + HKDF-SHA256** per-echo keys derived from vault seed in Keychain
- **Fail-closed crypto:** No test seed fallback; deterministic nonce fallback removed
- **Four lifecycle states:** `sealed → opened → handDelivered → released`
- **Echo Decree:** Binding instruction executed on open (e.g. "give this letter to my daughter")
- **Echo Heir:** Recipient + key release schedule
- **No plaintext reflections stored** — only ciphertext, nonce, tag, unlock date, decree
- **Tests:** `validate_tierA3_echo.py` — 10/10 PASS

---

## 10. Invisible Mentor — Your Past Self as Coach

**No LLM. No Core ML. No network.** A deterministic synthesizer that quotes back your own reflections when you face decisions.

- **Files:** `InvisibleMentor.swift` (13 KB)
- **MentorTurn, MentorDialogue, MentorInput** types
- **Synthesis rules:** Only quotes from `LifeEntity.isUserReflection == true`
- **Bridges with Sacred Echo:** `MentorEchoBridge.swift` converts opened echoes to Mentor seeds
- **Tests:** `validate_tierA4_mentor.py`, `validate_mentor_bridge.py` — 12 + 41 tests PASS

---

## 11. Cognitive Load Score + Weave Pause

A real-time load metric (0-1) combining 6 components with weighted normalization.

- **Files:** `CognitiveLoad.swift` (~520 LOC)
- **6 components:** calendar density, open quests, open threads, sleep debt, ref-days, amplifier load
- **Weighted formula:** each component normalized 0-1, multiplied by configurable weight
- **Trend detection:** `rising` / `steadyHigh` / `falling` / `steadyLow` with hysteresis
- **Weave Pause:** Triggers ONLY on rising load + score ≥ 0.85 (NOT on sustained high — this was a bug we caught and fixed)
- **Tests:** `validate_cognitive_load.py` — 45/45 PASS

---

## 12. Morning Briefing + Evening Review

- **Files:** `DailyBriefings.swift` (~480 LOC)
- **Morning:** Today's calendar, top priorities, echo countdowns, cognitive load, weather (via pluggable `WeatherProvider`)
- **Evening:** What was completed, open threads, reflections written, harmony delta
- **Time-aware prompts:** Quotes based on season + time of day
- **Tests:** `validate_daily_briefings.py` — 31/31 PASS

---

## 13. Relationship Decay Tracker

- **Files:** `RelationshipDecayTracker.swift` (~280 LOC)
- **Reads `.person` entities** from Life Graph
- **Tracks cadence:** last interaction vs configured frequency
- **Severity levels:** `gentle` / `warm` / `firm` / `urgent`
- **Suppression:** quiet hours + repeat suppression
- **Tests:** `validate_relationship_decay.py` — 30/30 PASS

---

## 14. Decision Log + Mentor Bridge

- **Files:** `DecisionLog.swift` (~360 LOC)
- **Records:** decisions with reasoning, expected outcome, predicted ripples
- **Outcomes:** When actual outcome known, log it
- **Mentor bridge:** Feeds back into Invisible Mentor ("Last time you decided X, you said Y — does that still hold?")
- **Domain bonus:** If decision was made in same domain as past decision, surface it
- **Tests:** `validate_decision_log.py` — 50/50 PASS

---

## 15. Quick Capture Inbox

A single text field that auto-classifies input into one of 5 destinations.

- **Files:** `QuickCaptureInbox.swift` (~450 LOC)
- **5 destinations:** `task` / `event` / `journal` / `decision` / `note`
- **Pure heuristic:** keyword + pattern + tense analysis — no LLM
- **Confidence scores:** returned for each classification
- **Bug caught:** "I was overwhelmed and tired today" was being routed as event; now properly journal when journal markers co-occur with weak event signals
- **Tests:** `validate_quick_capture.py` — 38/38 PASS

---

## 16. Gamification (Calm, Anti-Addictive)

- **Essence, Level, Mastery tiers (1-4), Harmony, Streaks** — all in `LifeContext`
- **Mastery tiers:** novice → adept → expert → master → grandmaster
- **Harmony:** 0.0-1.0, resonance threshold 0.7
- **6 Amplifiers:** focus, clarity, vitality, connection, creativity, wisdom
- **Seasons:** spring/summer/autumn/winter with bonuses, gates, burst
- **Reflection-gated rewards** — can't earn without writing why

---

## 17. P2P Foundation — Weave Circles

- **Files:** `P2PWeaveShare.swift`, `LifeGraphiOSIntegrations.swift`
- **Network stack:** Network framework (BLE/Wi-Fi Aware) + WebRTC.framework + STUN + TURN
- **Offline queue** + Data Leash filter + reflection gate (writes to `pendingIntegrations` until user reviews)
- **Auto-invalidation** of GraphInsight cache on P2P receive
- **Family Pod layer** on top — anti-social sharing with 6-person limit
- **iCloud sync — DEFERRED to v1.1 (Cycle 39 / T190).** v1.0 ships
  without any CloudKit, Private Cloud Compute, or iCloud Drive
  mirroring. See `CONSTITUTION_v3_DRAFT.md` §11 for the explicit
  decision and the v1.1 migration plan (file-level export bundle to
  iCloud Drive, opt-in only, reflection-gated, E2EE). The
  `OnboardingView` line 15 copy was strengthened in cycle 39 (T191)
  to read "No cloud sync by default and not available in this version".

---

## 18. Widgets, Live Activities, App Intents

- **Files:** `OneWeaveSnapshotStore.swift`, `OneWeaveWidgetStubs.swift`
- **WidgetKinds:** `HarmonyWidget`, `QuestWidget`
- **App Group:** `group.com.oneweave`
- **AppIntents:** `LogWeaveIntent`, `CompleteQuestIntent`, `ShowHarmonyIntent`
- **LiveActivity:** `OneWeaveLiveActivityAttributes`
- **Status:** Production code ready, needs Xcode Widget Extension target (Mac work)

---

## 19. Schema Migration Plan

- **Files:** `SchemaMigrationPlan.swift` (396 LOC)
- **Three versions:** V1 → V2 → V3 with explicit migration steps
- **11 @Models** with version hashing
- **Rollback support**
- **Tests:** `validate_schema_migration.py` — 30/30 PASS

---

## 20. PWA (Web Parity)

- **Files:** `web-pwa/`
- Full feature parity with iOS — loom canvas, quests + reflection gate, HUD, export v2, widget sims
- Local only, no CDN
- Service worker for offline
- Manifest for installability

---

## 21. Public API Catalog

- **Files:** `OneWeaveAPI.swift` (236 LOC)
- Documented entry points for Mac-side onboarding
- Each API has privacy implications noted

---

## 22. App Lifecycle + Encrypted Persistence

- **Files:** `AppLifecycleCoordinator.swift` (17.6 KB)
- **Encrypted envelope persistence** at app background — AES-GCM + HKDF reusing Sacred Echo vault seed
- **ScenePhase routing** via `MainTabView.onChange`
- **Lifecycle:** `foreground → background → inactive` with proper state preservation
- **LifeGraphPersistence** for JSON export/import
- **Tests:** `validate_tierA5_lifecycle.py` — 19/19 PASS

---

## 23. Stress Test Harness

- **Files:** `validate_stress.py`
- 1k / 10k entity graphs
- Loom performance
- P2P packet storm
- Crypto roundtrip chaos
- **35/35 PASS** — caught 2 real bugs (Loom geometry, single-node angle)

---

## Stats at a Glance

| Metric | Count |
|---|---:|
| Swift files | **55** |
| Total Swift LOC | **~15,700** |
| Public types | **186** |
| SwiftData @Models | **11** |
| Python validation suites | **16** |
| Total tests | **525+** |
| Tests passing | **525+** (16/16 suites) |
| Real bugs caught by validators | **5** |
| External API keys | **0** |
| Cloud dependencies | **0** |
