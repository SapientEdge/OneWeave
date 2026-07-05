# Feature Specification: OneWeave Production Readiness (003)

**Feature Branch**: `003-production-readiness`

**Created**: 2026-06-27

**Status**: Draft → Active

**Input**: Reconciles prior specs 001-oneweave (MVP) and 002-gamification (retention layer) with the actual shipped state of the codebase as of 2026-06-27 (Tier A #1-5, Round 2 #1-4, Linux validation push, 5 new features). Establishes the canonical feature surface for Mac-side work, multi-agent review, and App Store submission.

---

## Context

The codebase has grown beyond the original MVP spec. This document captures:

1. **What is actually shipped** in `Sources/OneWeave/` (55 Swift files, ~15,700 LOC, 186 public types, 11 SwiftData @Models)
2. **What is validated** via Python mirrors (16 suites, 525+ tests, 5 real bugs caught)
3. **What requires Mac work** to complete (Xcode project, Widget Extension target, App Group, build/test on device)
4. **What is deferred** (Android, sync, advanced AI)

Grounded in constitution v2.0 (`.specify/constitution.md`).

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Living Graph Loom Visualization (Priority: P1)

**As a** OneWeave user with 3+ months of journaled life data, **I want to** see my life as a breathing constellation so that I can perceive patterns I would never notice in lists.

**Why this priority**: The Loom is the signature visual of OneWeave. Without it, the app is "Day One with extra steps." With it, the app becomes the only life tool that surfaces cross-domain connections visually.

**Independent test**: Tap Compass → Loom button → see canvas with ≥ 10 entity nodes (color-coded by Thread), bezier edges labeled with relationship kinds, breathing animation on selected entity.

**Acceptance Scenarios**:
1. **Given** 50+ entities across 4 threads, **When** Loom renders, **Then** nodes arrange in polar layout with Self at top, threads radiating clockwise
2. **Given** a tap on an entity, **When** the entity is selected, **Then** its connected entities pulse, edges highlight, detail card appears
3. **Given** Cognitive Load ≥ 0.85, **When** Loom is shown, **Then** the orbs dim and breathing slows (visual cognitive load reflection)

**Edge cases**:
- Single entity (no edges): show single orbiting node, not crash (caught in `validate_round2_loom.py`)
- 10,000 entities: pure-Swift polar layout (not Metal) handles via cluster zoom; benchmarked in `validate_stress.py`

---

### User Story 2 - Sacred Echo Vault (Priority: P1)

**As a** parent or person facing mortality, **I want to** seal encrypted messages to be delivered on a future date or event so that my words reach the people I love when the moment matters.

**Why this priority**: This is the killer feature that no competitor has. Day One, Reflectly, Stoic, Apple Journal all have journaling. None have encrypted time-capsule messages with crypto-enforced delivery semantics.

**Independent test**: Open Vault → Compose Echo → Set unlock date + heir → Seal → Re-open app → Echo remains sealed → Force-decrypt attempt returns nil (fail-closed).

**Acceptance Scenarios**:
1. **Given** user composes an Echo with `title`, `decree`, `ciphertext`, `heir`, **When** sealed with `unlockAt = future_date`, **Then** vault stores ciphertext + nonce + tag only; no plaintext on disk
2. **Given** `unlockAt` is reached, **When** user opens the Echo, **Then** state transitions `sealed → opened`, plaintext decrypted in-memory only
3. **Given** Echo Decree is set, **When** the Echo is opened, **Then** decree instruction is displayed prominently (e.g., "Give to her in private")
4. **Given** vault seed is lost/corrupted, **When** any open attempt is made, **Then** the open fails closed (returns nil, no partial decryption)

**Edge cases**:
- Tampered ciphertext: AES-GCM tag verification fails → `openError`
- Vault seed absent: no test seed fallback in production paths (caught by Grok cycle-15)
- Past `unlockAt` already: still sealed until user explicitly opens (no auto-open)
- Echo heir missing: warning displayed at seal time

**Validation**: `validate_tierA3_echo.py` (10/10 PASS), covers seal/open/handDeliver/release, decree, heir, fail-closed.

---

### User Story 3 - Invisible Mentor (Priority: P1)

**As a** user facing a decision, **I want to** be quoted my own past reflections so that I can make decisions aligned with my values, not my impulses.

**Why this priority**: The "no LLM" constraint is the product. The Mentor proves you don't need an LLM to get useful wisdom from your data — you just need to surface your past self at the right moment.

**Independent test**: Open Mentor → Input current decision → Receive 3 MentorTurns quoting from past journal entries marked `isUserReflection=true`.

**Acceptance Scenarios**:
1. **Given** user has 10+ journal entries with `isUserReflection=true`, **When** Mentor synthesizes, **Then** only those entries are quoted (never system-generated content)
2. **Given** a Mentor input references a domain (e.g., "career"), **When** synthesis runs, **Then** reflections from that domain are prioritized
3. **Given** user dismisses a Mentor turn, **When** next decision is made, **Then** dismissed turn doesn't reappear for 7 days

**Edge cases**:
- Zero `isUserReflection=true` entries: Mentor returns "Write your first reflection to begin" prompt
- Reflection text empty: filtered out (gated by `LifeEntity.isUserReflection` — caught by Nemotron review)
- Past decision outcome logged: bridges to `DecisionLog` via `MentorEchoBridge`

**Validation**: `validate_tierA4_mentor.py` (12/12 PASS), `validate_mentor_bridge.py` (41/41 PASS).

---

### User Story 4 - Privacy Data Leash (Priority: P1)

**As a** privacy-conscious user, **I want to** control exactly what each integration can access so that I never have to choose between functionality and privacy.

**Why this priority**: Without the Leash, OneWeave is just another app with an opt-out buried in settings. With the Leash, privacy is granular and visible at every touchpoint.

**Independent test**: Settings → Data Leash → Disable HealthKit → Try to log a body-thread reading → Blocked with clear explanation.

**Acceptance Scenarios**:
1. **Given** user toggles `healthKit = false` in `DataLeashSettingsRecord`, **When** any code path attempts `HealthIntegration.read()`, **Then** `currentLeash(in: ModelContext)` returns `false` BEFORE any HealthKit call, and the call is short-circuited
2. **Given** user toggles `mail = false`, **When** `MailIntegration.insightBody()` is called, **Then** returns `nil` with `.leashBlocked` error
3. **Given** user toggles `p2p = false`, **When** P2P receive is triggered, **Then** the receive is queued in `pendingIntegrations` but not integrated; user reviews manually

**Edge cases**:
- Settings record missing: fail-closed (deny all integrations until created)
- Settings record corrupted: defaults applied (deny all integrations except user's last known grant)
- Race condition on toggle during read: read happens BEFORE write commits → next read returns new state

**Validation**: `validate_tierA2_integrations.py` (21/21 PASS), `validate_tierA1_cache.py` (10/10 PASS for cache invalidation on leash change).

---

### User Story 5 - Cognitive Load Score + Weave Pause (Priority: P1)

**As a** user with multiple active goals, **I want to** see my current cognitive load and get a gentle pause suggestion when I'm overcommitted so that I don't burn out.

**Why this priority**: This is the anti-addictive feature that distinguishes OneWeave from Habitica/streaks apps. It honors the constitution's "calm intelligence" principle.

**Independent test**: Push load to 0.9 with calendar events + open quests + depleted sleep → Receive "Consider pausing next commitment?" suggestion → Dismiss → Continue with work.

**Acceptance Scenarios**:
1. **Given** CognitiveLoadInputs `{calendarEventsNext4Hours: 8, openQuests: 15, openThreads: 6, sleepDebt: 0.8, daysSinceReflection: 4, amplifierLoad: 0.6}`, **When** `CognitiveLoad.compute()` runs, **Then** score is in [0.85, 0.95] with trend = rising
2. **Given** load score ≥ 0.85 AND trend = rising, **When** `WeavePauseGate.shouldPause()` is called, **Then** returns true with reasoning "Cognitive load rising and approaching exhaustion threshold"
3. **Given** load score = 0.95 BUT trend = steadyHigh (sustained but stable), **When** `WeavePauseGate.shouldPause()` is called, **Then** returns false (caught by `validate_cognitive_load.py` — the original bug had it returning true incorrectly)

**Edge cases**:
- No prior reading: first reading always returns trend = steadyLow (insufficient data)
- All zeros (empty life): score = 0.0, no pause
- Outlier event (one big spike): hysteresis prevents over-triggering

**Validation**: `validate_cognitive_load.py` (45/45 PASS). **Real bug caught**: Swift code's `shouldPause` was checking `trend == .rising || trend == .steadyHigh` but the docstring said "only rising" — fixed.

---

### User Story 6 - Family Pod (Priority: P2)

**As a** parent or caregiver, **I want to** share selective life data with up to 6 family members on quiet-hours, cooldown-respecting terms so that we coordinate without becoming a surveillance network.

**Why this priority**: Family sharing is the highest-leverage P2P use case, but it must be anti-social by design to avoid the toxicity of family WhatsApp groups.

**Independent test**: Create Pod "Sullivan Family" → Invite 4 members with per-member visibility grants → Send digest at 7pm → Members receive digest, can respond in-thread.

**Acceptance Scenarios**:
1. **Given** Pod size = 6 (max), **When** user attempts to invite 7th, **Then** `addMember` returns `.podFull` error
2. **Given** member has `visibilityGrant = .caringTasksOnly`, **When** digest is generated, **Then** only tasks directed at that member or shared with their care group are included
3. **Given** quiet hours set to 9pm-7am for member, **When** digest would arrive in window, **Then** delivery is delayed until 7am

**Edge cases**:
- Member name with whitespace: `addMember` must trim before validation (real bug caught by `validate_family_pod.py` — original accepted `"   "` as valid name; fixed)
- Member removed: their pending messages are queued for re-delegation
- Pod owner leaves: pod archived, not deleted (recovery possible)

**Validation**: `validate_family_pod.py` (52/52 PASS).

---

### User Story 7 - Portable Export with Privacy Leash (Priority: P2)

**As a** user leaving the platform or wanting a backup, **I want to** export my entire life data in Markdown, OPML, or JSON with granular privacy controls so that I own my data fully.

**Why this priority**: Privacy promises are only credible if users can actually take their data and leave. This is the exit door that makes the lock-in-free promise real.

**Independent test**: Settings → Export → Choose `SharedOnly` leash → Choose Markdown → Generate → Open file → Confirm only shared-tier entities present.

**Acceptance Scenarios**:
1. **Given** ExportLeash = `publicOnly`, **When** `PortableExportBuilder.build()` runs, **Then** only `LifeEntity.privacyTier == .public` are included; private/shared filtered out
2. **Given** format = Markdown, **When** export builds, **Then** entries are journaled chronologically with reflection quotes preserved; checksum appended
3. **Given** format = OPML, **When** export builds, **Then** graph relationships appear as outline structure with thread groupings

**Edge cases**:
- Zero entities: export still produces valid empty manifest with checksum
- Tampered file: checksum mismatch reported at import time
- Re-importing same export: duplicate detection by entity ID

**Validation**: `validate_portable_export.py` (48/48 PASS).

---

### User Story 8 - Quick Capture Inbox (Priority: P2)

**As a** user with a thought mid-stride, **I want to** type one line and have it auto-classified into the right bucket so that I capture without breaking flow.

**Why this priority**: Capture friction is the #1 reason life apps fail. The 5-way classifier with confidence scores solves it without requiring an LLM.

**Independent test**: Type "Call Mom tomorrow at 3pm" → Classification: event (confidence 0.85) → Auto-routed to calendar (if leash allows) → Confirmation shown.

**Acceptance Scenarios**:
1. **Given** input "I was overwhelmed and tired today", **When** classifier runs, **Then** classification = journal (confidence 0.80), NOT event (caught by `validate_quick_capture.py` — original bug routed weak event signals over journal markers; fixed)
2. **Given** input "Decided to quit Twitter", **When** classifier runs, **Then** classification = decision (confidence 0.90)
3. **Given** input "TODO: renew passport", **When** classifier runs, **Then** classification = task (confidence 0.95)

**Edge cases**:
- Mixed signal (journal + event markers): strongest signal wins with confidence discount
- All signals low: defaults to note with "please classify manually" prompt
- Empty input: returns classification = none

**Validation**: `validate_quick_capture.py` (38/38 PASS).

---

### User Story 9 - Decision Log + Mentor Bridge (Priority: P2)

**As a** user making important decisions, **I want to** record my reasoning and predicted outcome, then log the actual later so that my past self can mentor my future self.

**Why this priority**: This is the bridge between decision-making and the Invisible Mentor. Without it, decisions are forgotten; with it, the Mentor becomes truly wise.

**Independent test**: Log decision "Quit Twitter for 30 days" → Predicted outcome: "More time for novel writing" → 30 days later → Log actual → MentorBridge surfaces to Invisible Mentor.

**Acceptance Scenarios**:
1. **Given** DecisionRecord created with reasoning, predictedRipples, expectedOutcome, **When** 30+ days pass, **Then** log reminder appears in morning briefing
2. **Given** actual outcome logged, **When** `DecisionMentorBridge.synthesizeBridge()` runs, **Then** returns 3 citations from InvisibleMentor corpus with semantic relevance ≥ 0.7
3. **Given** user makes similar decision later, **When** DecisionLog queries, **Then** prior decisions in same domain surface with outcome summaries

**Edge cases**:
- Decision has no reasoning: creation blocked with "decision must include reasoning"
- Predicted vs actual never logged: stale reminders suppressed after 90 days
- Domain mismatch (predicted career decision, outcome logged as "other"): surfaced with mismatch warning

**Validation**: `validate_decision_log.py` (50/50 PASS).

---

### User Story 10 - Morning Briefing + Evening Review (Priority: P3)

**As a** daily user, **I want to** receive a calm, locally-generated morning brief and evening review so that I start and end each day aware of my actual state, not my imagined state.

**Why this priority**: Daily-use habit-forming without being addictive. Uses existing data, no new collection.

**Independent test**: Open app at 7am → Morning Briefing appears with today's calendar + top 3 quests + cognitive load + upcoming echoes → Open at 9pm → Evening Review shows what was completed + harmony delta.

**Acceptance Scenarios**:
1. **Given** WeatherProvider returns sunny, **When** Morning Briefing builds, **Then** section appears with temp + condition
2. **Given** 3 active quests with `priority = high`, **When** Morning Briefing builds, **Then** all 3 appear in order of priority + due date
3. **Given** 2 echoes unlocking in next 7 days, **When** Morning Briefing builds, **Then** both appear in `BriefEchoCountdown` section

**Edge cases**:
- Zero calendar events: briefing still generates with "free day" message
- All quests completed yesterday: evening review highlights completion rate
- Cognitive load high: briefing prepends "consider light day" gentle nudge

**Validation**: `validate_daily_briefings.py` (31/31 PASS).

---

### User Story 11 - Relationship Decay Tracker (Priority: P3)

**As a** user who values relationships but forgets, **I want to** be gently reminded when I've lost touch with someone important so that I can reach out before the gap becomes awkward.

**Why this priority**: Anti-loneliness feature. Quiet, non-judgmental, suppression-respecting.

**Independent test**: Set relationship "Dad" with cadence = 14 days → 23 days pass without interaction → Morning Briefing surfaces "Dad · 23 days since last call" → Tap → Call initiated.

**Acceptance Scenarios**:
1. **Given** cadence = 14 days, lastInteraction = 23 days ago, **When** `RelationshipDecayTracker.computeSeverity()` runs, **Then** returns `.firm` (2× cadence)
2. **Given** member has `quietHours = 9pm-7am`, **When** decay prompt would fire in window, **Then** delivery delayed to 7am
3. **Given** user dismisses prompt, **When** next decay check runs, **Then** same prompt suppressed for `cooldown = 7 days`

**Edge cases**:
- Member deleted: tracker removes from list
- Cadence changed: severity recomputed with new baseline
- User in low-energy state: prompts suppressed unless severity = .urgent

**Validation**: `validate_relationship_decay.py` (30/30 PASS).

---

### User Story 12 - Living Loom Schema Migration (Priority: P3)

**As a** user upgrading across schema versions, **I want to** keep my data intact so that I never lose a journal entry, decision, or reflection to an upgrade.

**Why this priority**: Trust-building. Production apps must not lose user data.

**Independent test**: Install v1 → Add data → Install v2 → Verify data present with new schema fields populated correctly → Install v3 → Verify same.

**Acceptance Scenarios**:
1. **Given** V1 entities with `createdAt = old_date`, **When** V2 migration runs, **Then** `createdAt` preserved, new `lastUpdated` field populated with `createdAt` value
2. **Given** V2 entities with `attributes = nil`, **When** V3 migration runs, **Then** `attributes = [:]` (empty dict), no crash
3. **Given** migration fails midway, **When** rollback triggered, **Then** data restored to V2 state, no partial corruption

**Edge cases**:
- Schema hash mismatch: migration refused, manual recovery path surfaced
- Mixed-version data: impossible per architecture; each entity stamped with version
- Failed migration mid-write: atomic transaction ensures no partial state

**Validation**: `validate_schema_migration.py` (30/30 PASS).

---

## Non-Functional Requirements *(mandatory)*

### Performance
- **Loom render** with 100 entities: ≤ 16ms per frame (60fps)
- **Loom render** with 10,000 entities: ≤ 100ms per frame in cluster-zoom mode
- **Cognitive Load compute**: ≤ 5ms
- **Sacred Echo seal**: ≤ 50ms (crypto)
- **Sacred Echo open**: ≤ 50ms (crypto + UI)
- **Quick Capture classify**: ≤ 10ms
- **App cold start**: ≤ 1.5s on iPhone 12

### Privacy
- Zero external API calls in core features (verified: 0 API keys in codebase)
- All Sacred Echo data encrypted at rest with AES-256-GCM
- Vault seed stored in Keychain with `kSecAttrAccessible = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`
- Data Leash checked BEFORE every integration call (verified: `currentLeash(in:)` precedes enumeration)

### Reliability
- Crypto fails closed (no partial decryption, no test seed fallback)
- Schema migrations are atomic
- Reflection gates prevent accidental state changes
- P2P receive is queued + reviewed, not auto-integrated

### Accessibility
- VoiceOver labels on all interactive elements (HUD, loom, quests)
- Dynamic Type support throughout
- Color contrast meets WCAG AA
- Reduce Motion respected for all animations

### Calm Design
- No streak-shaming notifications
- No infinite feeds
- No "🎉" or similar attention-grabbing elements
- Spring animations: `.spring(response: 0.4, dampingFraction: 0.7)`
- Color palette: Self=.blue, Stewardship=.green, CareKin=.orange, Meaning=.purple (consistent everywhere)

---

## Data Model

### Existing SwiftData @Models (11)
- `UserProfile` — base user state
- `TimelineEvent` — every ripple
- `LifeContext` — aggregate root, holds energy/harmony/streaks
- `LifeEntity` — graph nodes (people, projects, decisions, events)
- `LifeRelationship` — graph edges
- `LifeInsight` — generated insights
- `LifePattern` — detected patterns
- `DataLeashSettingsRecord` — privacy toggles
- `SacredEcho` — encrypted time-capsule messages
- `WeaveQuest` — gamified challenges
- `BodyThreadReading` — health snapshots

### Existing Enums (key)
- `PrivacyTier`: private | shared | public
- `IntegrationCategory`: calendar, contacts, healthKit, reminders, mail, notes, bodyThread, p2p, insights
- `CognitiveLoadTrend`: rising | steadyHigh | falling | steadyLow
- `EchoLifecycleState`: sealed | opened | handDelivered | released
- `DecaySeverity`: gentle | warm | firm | urgent

### Migration Strategy
V1 → V2 → V3 with explicit logic in `SchemaMigrationPlan.swift`. Version hashing via `OneWeaveSchemaV1/V2/V3.VersionedSchema`.

---

## Dependencies

### iOS Frameworks
- SwiftUI (iOS 17+)
- SwiftData (iOS 17+)
- HealthKit (with `kSecAttrAccessible` after-first-unlock)
- EventKit (Calendar + Reminders)
- Contacts
- MessageUI (Mail composition)
- WidgetKit (widget extension target)
- AppIntents (Siri + Shortcuts)
- ActivityKit (Live Activities)
- CryptoKit (AES-GCM + HKDF for Sacred Echo)
- LocalAuthentication (vault seed unlock fallback)
- Network framework (P2P transport)
- WebRTC.framework (P2P video/text via CocoaPods)
- libsignal-client (Signal Protocol for P2P)

### External Services (none in core)
- Weather: pluggable `WeatherProvider` (default: `NullWeatherProvider` returns offline stub)
- No LLM API, no analytics, no crash reporting, no telemetry

### Apple Frameworks NOT Used (intentional)
- CloudKit (sync would compromise local-first promise)
- Sign in with Apple (no accounts)
- Push notifications (would require server)
- In-App Purchase UI (will be added via StoreKit 2 in paid tier; deferred to Mac work)

---

## Toolchain Requirements

Per constitution v2.0:

| Purpose | Tool | Validation |
|---|---|---|
| Spec authoring | Spec Kit | This file |
| Codebase context | Graphify | `graphify-out/wiki/index.md` |
| Implementation | Aider | `.aider.conf.yml` |
| Validation | Python mirrors | `.research/validate_*.py`, 16 suites, 525+ tests |
| Dispatch | `oneweave_dispatch.sh` | `.research/NO_TRAINING_PROMPT.md` |

---

## Mac-Side Work Required (NOT done on Linux)

1. **Create Xcode project** with iOS 17+ target + Widget Extension + App Group `group.com.oneweave`
2. **Wire SwiftData modelContainer** with all 11 @Models + 3 VersionedSchemas
3. **Connect Widgets** (`HarmonyWidget`, `QuestWidget`, `OneWeaveLiveActivityAttributes`) to snapshot store
4. **AppIntents** registration (`LogWeaveIntent`, `CompleteQuestIntent`, `ShowHarmonyIntent`)
5. **Bundle ID + signing** setup for TestFlight
6. **App Store Connect metadata** (description, screenshots, privacy policy, support URL)
7. **Build + test on iOS Simulator** (x86_64 + arm64)
8. **TestFlight beta** distribution
9. **App Store submission** (review notes for Sacred Echo Vault — explains post-mortem crypto delivery semantics)
10. **Onboarding flow** polish (currently stubbed in `OnboardingView.swift`)

Estimated effort: 30-40 hours focused work. See `FIRST_WEEK_ON_MAC.md` for breakdown.

---

## Out of Scope (Deferred)

- Android native (PWA provides web parity)
- iCloud Drive sync (paid tier; uses user's own Drive)
- Advanced AI (LLM integration when Apple Intelligence ships mature)
- Real-time collaborative Weave Circles (requires persistent signaling server)
- Watch app (deferred to v1.1)
- Mac Catalyst (deferred; iPad first)

---

## Compliance Checklist *(mandatory before implementation)*

- [x] All 12 user stories have independent tests
- [x] Edge cases enumerated for each story
- [x] Non-functional requirements quantified
- [x] Data model referenced
- [x] Dependencies enumerated
- [x] Constitution compliance verified (privacy-first, calm, reflection-gated, anti-addictive)
- [x] Toolchain mandates followed (Spec Kit + Graphify + Aider + Python mirrors)
- [x] Mac-side work clearly demarcated
- [x] Out-of-scope items listed

---

## References

- **Constitution**: `.specify/constitution.md` v2.0
- **Prior specs**: `.specify/specs/001-oneweave/`, `.specify/specs/002-gamification/`
- **Marketing**: `MARKETING.md`, `FEATURE_CATALOG.md`
- **Landing**: `landing.html`, `visuals_*.png`
- **Mac brief**: `CLAUDE_COWORK_BRIEF.md`, `FIRST_WEEK_ON_MAC.md`
- **Validation**: `VALIDATION_REPORT.md`, `.research/validate_*.py`
- **Market research**: `.research/MARKET_RESEARCH_ROUND_3.md`

---

*Generated 2026-06-27 as part of toolchain adoption (Spec Kit + Graphify + Aider). Reconciles 3-4 days of building into a single canonical spec for Mac-side work and App Store submission.*