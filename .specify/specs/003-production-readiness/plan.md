# Implementation Plan: 003-production-readiness

**Created**: 2026-06-27
**Feature**: [003-production-readiness/spec.md](spec.md)
**Constitution**: [../../constitution.md](../../constitution.md) v2.0

## Architecture Summary

OneWeave is a privacy-first iOS 17+ Life OS built on SwiftUI + SwiftData + SwiftData graph. The 12 user stories are already implemented as Swift sources in `Sources/OneWeave/`. This plan focuses on:

1. **Mac-side completion** (Xcode project, widget extension, App Group wiring)
2. **Validation** (Graphify + Python mirrors, already 525+ tests passing)
3. **Multi-agent review** (feed spec + graph to Grok/Claude/Nemotron, apply findings)
4. **Submission** (TestFlight → App Store)

## Technical Decisions

### TD-1: No external dependencies in production
- WebRTC.framework via CocoaPods (GoogleWebRTC) — for P2P only, NOT core
- libsignal-client — for P2P encryption only, NOT core
- No CocoaPods for core features. Pure Apple frameworks.

### TD-2: SwiftData over Core Data
- 11 @Models with explicit VersionedSchema versioning
- Migrations atomic via `SchemaMigrationPlan.swift`
- Multi-model relationship through aggregate `LifeContext`

### TD-3: Sacred Echo crypto stack
- AES-256-GCM via CryptoKit (not CommonCrypto)
- HKDF-SHA256 per-echo key derivation from vault seed
- Vault seed in Keychain (`kSecAttrAccessible = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`)
- Fail-closed: no test seed fallback, no deterministic nonce fallback

### TD-4: Reflection gate as central invariant
- `applyInsight(reflectionText:)` requires non-empty
- `commitWeave(reflectionText:)` requires non-empty
- `sealEcho(decree:)` requires non-empty
- `completeQuest(reflectionNote:)` requires non-empty
- `applyDecision(reasoning:)` requires non-empty

### TD-5: Data Leash read-live-before-call pattern
- All 9 integrations call `currentLeash(in: ModelContext)` BEFORE any external framework call
- `currentLeash` reads `DataLeashSettingsRecord` via `FetchDescriptor`
- Missing record → fail-closed (deny all)
- Settings change → invalidate InsightGenerator cache + LifeGraph cache

### TD-6: Living Graph Loom rendering
- Pure-Swift polar layout (no Metal, no SpriteKit) for accessibility
- SwiftUI Canvas with bezier threads + breathing orbs
- Cluster zoom for > 100 entities
- Animated pulse along edges on ripple events

### TD-7: Anti-addictive gamification
- Streaks: restorative grace (max 2 days) + gentle decay (0.5%/day after 7-day grace)
- Weave Pause: ONLY triggers on rising load AND ≥ 0.85 (NOT sustained high — verified)
- Mastery tiers: require genuine mastery, not time-served

### TD-8: P2P architecture
- Network framework transport (BLE + Wi-Fi Aware) for offline-first
- WebRTC for NAT traversal (STUN + self-hosted TURN)
- libsignal-client for end-to-end encryption
- Weave Circles: public rooms; Family Pod: private rooms (≤6)
- Reflection gate on every receive → queued in `pendingIntegrations` for review

### TD-9: Widget extension
- `HarmonyWidget`: shows current harmony + 1 active quest
- `QuestWidget`: shows top 3 active quests + cognitive load
- Shared snapshot via App Group `group.com.oneweave`, key `oneweave.snapshot.v1`
- AppIntents for Siri + Shortcuts
- LiveActivity for `OneWeaveLiveActivityAttributes` (in-progress quest tracking)

### TD-10: Validation strategy
- Python mirrors in `.research/validate_*.py` for algorithm validation (no swiftc on Linux)
- 16 suites, 525+ tests, 5 real bugs caught
- Stress harness: 1k/10k entity graphs, p2p storm, crypto chaos
- Output feed to multi-agent review for additional findings

## File Structure

```
/root/hermes-workspace/projects/oneweave/
├── .specify/                              # Spec Kit artifacts
│   ├── constitution.md                    # v2.0 — adopted 2026-06-27
│   └── specs/
│       ├── 001-oneweave/                  # Original MVP spec (frozen)
│       ├── 002-gamification/              # Gamification spec (frozen, completed)
│       └── 003-production-readiness/      # THIS spec — canonical surface
├── Sources/OneWeave/                      # 55 Swift files, ~15,700 LOC
│   ├── LifeContext.swift                  # Aggregate root
│   ├── LifeGraph.swift                    # Graph models
│   ├── SacredEcho.swift                   # Killer feature
│   ├── InvisibleMentor.swift              # Pure local synthesis
│   ├── CognitiveLoad.swift                # Weave Pause
│   ├── FamilyPod.swift                    # Anti-social sharing
│   ├── PortableExport.swift               # 3-leash export
│   ├── iOSServiceIntegrations.swift       # 6 iOS framework wrappers
│   ├── DataLeashSettings.swift            # 9-toggle privacy
│   ├── GraphInsightGenerator.swift        # Cross-domain insights
│   ├── CommandPalette.swift               # Universal palette
│   ├── ResonanceOracle.swift              # Decision simulator
│   ├── BodyThreadWeaver.swift             # Health bridge
│   ├── DailyBriefings.swift               # Morning + Evening
│   ├── RelationshipDecayTracker.swift     # Reach-out prompts
│   ├── DecisionLog.swift                  # Decisions + outcomes
│   ├── QuickCaptureInbox.swift            # 5-way classifier
│   ├── MentorEchoBridge.swift             # Sacred → Mentor
│   ├── LivingGraphLoom.swift              # Canvas renderer
│   ├── LoomGeometry.swift                 # Pure-Swift polar layout
│   ├── PortableExport.swift
│   ├── SchemaMigrationPlan.swift          # V1↔V2↔V3
│   ├── AppLifecycleCoordinator.swift      # Encrypted persistence
│   ├── AppStateMachine.swift              # UI state
│   ├── TimelineEvent.swift                # Ripple event
│   ├── TimelineService.swift              # Event bus
│   ├── OneWeaveSnapshotStore.swift        # Widget snapshot
│   ├── OneWeaveWidgetStubs.swift          # Widget code (needs target)
│   ├── OneWeaveAPI.swift                  # Public API catalog
│   ├── CompassView.swift                  # Main hub
│   ├── ThreadsOverviewView.swift          # Tab nav
│   ├── ThreadDetailView.swift             # Per-thread UI
│   ├── HistoryView.swift                  # Timeline
│   ├── SettingsView.swift                 # Privacy + export
│   ├── QuestsView.swift                   # Gamif UI
│   ├── OnboardingView.swift               # First-run (stub)
│   ├── StateMachineIndicator.swift        # Peripheral indicator
│   ├── ResonanceOracleSheet.swift         # Modal
│   ├── BodyThreadSheet.swift              # Modal
│   ├── EssenceLedgerView.swift            # Gamif ledger
│   ├── MasteryMapView.swift               # Mastery tiers
│   ├── WeaveSummaryView.swift             # Cross-domain summary
│   ├── DataSeeder.swift                   # Demo data
│   ├── OneWeaveApp.swift                  # App root
│   ├── OneWeavePrototype.swift            # Validation harness
│   ├── OneWeavePrototype+GraphValidation.swift
│   ├── BasicSelfThread.swift
│   ├── StewardshipThread.swift
│   ├── CareKinThread.swift
│   ├── MeaningThread.swift
│   ├── Thread.swift                       # Base thread
│   ├── QuestService.swift
│   ├── WeaveQuest.swift
│   ├── P2PWeaveShare.swift                # P2P foundation
│   ├── LifeGraphiOSIntegrations.swift     # Shim
│   └── InsightGenerator.swift
├── .research/                              # Validation + research
│   ├── validate_*.py                      # 16 Python validation suites
│   ├── validate_all.sh                    # Master runner
│   ├── MARKET_RESEARCH_ROUND_*.md
│   ├── NO_TRAINING_PROMPT.md
│   ├── AGENT_SQUAD_PROMPTS.md
│   ├── TIER_B_PLAYBOOK.md
│   ├── build_log.md
│   └── doc_*.md                           # Research attachments
├── graphify-out/                           # Graphify outputs
│   ├── graph.json
│   ├── GRAPH_REPORT.md
│   ├── wiki/index.md
│   └── graph.html
├── README.md
├── ARCHITECTURE.md
├── PRIVACY.md
├── CONTRIBUTING.md
├── LICENSE
├── .gitignore
├── MANIFEST.md
├── VALIDATION_REPORT.md
├── CLAUDE_COWORK_BRIEF.md                 # Mac brief for Claude cowork
├── FIRST_WEEK_ON_MAC.md                   # Dan's first week guide
├── PUSH_INSTRUCTIONS.md                   # GitHub push guide
├── FEATURE_CATALOG.md                     # Marketing feature list
├── MARKETING.md                           # Marketing copy
├── MARKETING_DIAGRAMS.txt                 # ASCII diagrams
├── landing.html                           # Landing page
├── visuals_compass.png
├── visuals_loom.png
├── visuals_echo.png
├── PrivacyPolicy.md
└── .aider.conf.yml                        # Aider config (TO CREATE)

```

## Mac-Side Build Plan

### Phase M1: Xcode Project (4-6 hours)
1. Create Xcode project (iOS 17+ iPhone target)
2. Add existing Swift files to target (auto-detected by Xcode)
3. Configure SwiftData modelContainer in OneWeaveApp.swift with 11 @Models + 3 VersionedSchemas
4. Set deployment target to iOS 17
5. Build for iOS Simulator (x86_64 + arm64)
6. Verify OneWeavePrototype.swift runs all validation scenarios

### Phase M2: Widget Extension (2-3 hours)
1. Add Widget Extension target
2. Configure App Group `group.com.oneweave` for both targets
3. Copy `OneWeaveWidgetStubs.swift` → `HarmonyWidget` + `QuestWidget`
4. Wire `OneWeaveSnapshotStore` writes from `commitWeave`, `completeQuest`, body thread updates
5. Add WidgetConfiguration in OneWeaveApp

### Phase M3: AppIntents + LiveActivity (2-3 hours)
1. Register `LogWeaveIntent`, `CompleteQuestIntent`, `ShowHarmonyIntent`
2. Add LiveActivity for `OneWeaveLiveActivityAttributes` (iOS 16.1+)
3. Test Siri + Shortcuts integration

### Phase M4: Signing + TestFlight (3-4 hours)
1. Bundle ID: `com.oneweave.app`
2. Apple Developer account setup (user-provided)
3. Provisioning profiles for development + distribution
4. Archive build
5. Upload to App Store Connect
6. TestFlight internal beta distribution

### Phase M5: App Store Submission (2-3 hours)
1. App Store Connect metadata (from MARKETING.md)
2. Screenshots (use visuals_*.png as base, refine for iPhone 6.7" + 5.5")
3. Privacy policy URL (use PRIVACY.md)
4. Support URL (placeholder: support@oneweave.app)
5. App Review notes — explain Sacred Echo Vault (post-mortem crypto delivery)
6. Submit for review

### Phase M6: Onboarding Polish (2-3 hours)
1. Replace `OnboardingView.swift` stub with 5-step intro flow
2. `@AppStorage("hasCompletedOnboarding")` persistence
3. Auto-show on first launch
4. Include "First Weave" demo: commit a decision, see ripple, see Sacred Echo suggestion

**Total: 15-22 hours focused Mac work**

## Multi-Agent Review Cycle

After Mac compilation succeeds, run:
1. Graphify on updated codebase → `graphify-out/wiki/index.md`
2. Dispatch spec 003 + wiki + diff to Grok, Claude Code, Nemotron 3 Ultra
3. Collect findings → apply high/medium → validate → commit
4. Repeat for each major change

## Success Metrics

- [ ] iOS Simulator build succeeds
- [ ] All 12 user stories pass acceptance scenarios on Simulator
- [ ] Widget Extension renders on home screen
- [ ] Siri shortcut works
- [ ] TestFlight install succeeds on physical device
- [ ] App Store review passes (typically 24-48h)
- [ ] Zero P0 bugs in first 100 TestFlight testers
- [ ] App Store rating ≥ 4.5 within 30 days

---

*Plan generated 2026-06-27. Aligns with constitution v2.0.*