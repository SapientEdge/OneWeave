# Tasks for OneWeave Gamification & Retention Layer (Spec-Driven)

Reference: .specify/specs/002-gamification/spec.md , constitution.md , ONEWEAVE_GAMIFICATION_DESIGN.md , ONEWEAVE_GAMIFICATION_SPEC.md , USER_JOURNEYS_ONEWEAVE.md , STATE_MACHINE.md , existing thread models, CompassView, LifeContext, TimelineService.

All work must comply with constitution (calm, privacy-first local-only SwiftData, interconnected ripples via TimelineEvent, genuine help, IRL-first, anti-addictive design). Deliver working artifacts. Use Graphify + full context before heavy changes if codebase grows.

## Phase 0: Setup & Grounding (Pre-Implementation)
- [ ] Confirm .specify/specs/002-gamification/spec.md passes quality (no ambiguity, testable requirements, constitution compliance). Run manual checklist equivalent: requirements measurable, edge cases (lowEnergy, reflection gate), IRL bias explicit.
- [ ] Read/ground in: full spec.md + DESIGN.md + spec 001 + whitepaper sections on ripples/state + existing thread files (BasicSelfThread.swift streaks/habits, StewardshipThread.swift leaks/savings, CareKinThread.swift IRL/tasks, MeaningThread.swift stories) + LifeContext.swift + TimelineService.swift + CompassView.swift + ThreadRingView + StateMachine + visual mocks (GAMIFICATION_VISUAL_MOCK.html).
- [ ] Create git branch if not already: `git checkout -b 002-gamification` (or equivalent numbered feature branch).
- [ ] Add/update any shared types (e.g. in models) for cross-ref if needed. Ensure no-training/privacy prefixes on new code.
- [ ] Parallel discovery: search for all current uses of "streak", "quest", "mastery", "essence", "harmony", "ripple", "Compass", "LifeContext.updateFromEvent".

## Phase 1: Data Models & Core Services (Foundation, Local-Only)
- [x] Extend LifeContext (or create supporting aggregates): add weaveEssence (Int/Double), weaveLevel (Int), masteryTiers: [String: Int] (domain → tier 0-3), harmonyScore (Double, 0-1 low variance = high), streaks (per-thread and global with lastActive, grace counters), activeQuests, completedQuestCount or similar. Update updateFromEvent() to compute on every TimelineEvent.
- [x] New @Model: WeaveQuest (id: UUID, title: String, description: String, domains: [String], baseEssence: Int, status: enum Pending/Active/Completed/Reflected, estimatedIRLMinutes: Int, validationHints: String, linkedEventId: UUID?, reflectionNote: String?, completedAt: Date?, createdAt). Add to SwiftData container.
- [x] Extend or create QuestService (or integrate in TimelineService/LifeContext): methods generateSuggestedQuests(from context: LifeContext, recent: [TimelineEvent]) → [WeaveQuest], acceptQuest, completeQuest(with reflection: String, evidence: optional local data), awardEssence(for event: TimelineEvent, multipliers: [String: Double]).
- [x] Update TimelineEvent or payload (via events) to carry gamification metadata (questId, isIRLValidated, reflectionLogged, comboMultiplier, masteryContribution).
- [ ] Update existing Thread models to participate: e.g. on completion in Self/CareKin/Stewardship/Meaning, call service to award + check mastery/streak updates. Ensure every action prefers emit via service with linkedThreads.
- [ ] Add EssenceTransaction log (lightweight array or simple model) for ledger (earned/spent with reason, timestamp). All calculations on-device, no external.
- [x] Implement mastery calculation: cumulative ripples + validated quest completions + harmony contrib per domain → tier thresholds (e.g. 10/50/150/400 or tuned). Passive perk stubs (e.g. better suggestions when high tier).
- [x] Implement streak logic with restorative grace: per-thread streak counters; on miss/lowEnergy state, suggest restoration quests instead of reset; global "Weave Streak". Update on relevant events.
- [ ] Tests/stubs: clearForTesting(), seed sample quests/events for prototype. Ensure privacy: all local, exportable.

## Phase 2: Essence Economy & XP Logic
- [ ] Core earning rules: base on any TimelineEvent (1-5), +multipliers (cross-linked +2, IRL validated +5, reflection +3, highHarmony +1, quest completion + base). Implement in awardEssence.
- [ ] Decay: gentle on low activity periods (e.g. linear or scheduled in state update); encourage rhythm not login. No hard timers/FOMO.
- [ ] Spending: define Amplifier enum/types (e.g. SelfFocus, RedirectLens, InsightMagnifier, StreakShield, EchoBoost — 24-72h or single use). SpendEssence(amount, for: amplifier) with validation (enough, not spammable). Apply temporary boosts in suggestion/calculation paths.
- [ ] Custom quest forge: spend Essence (or premium gate) to create user-defined WeaveQuest.
- [ ] Echo: spend or free revisit of past event/quest → new insight + small Essence + Meaning ripple. Integrate with MeaningThread.
- [ ] HUD/ledger: simple display and history view (calm, tappable in Compass header). No flashy counters.
- [ ] Balance sinks: link spend to real value (e.g. amplifier improves IRL suggestion quality).
- [ ] Update LifeContext harmony on essence events; trigger state if high flow from balanced earnings.

## Phase 3: Quests Engine (Focus Area)
- [x] Starter quest templates (in QuestService) (rule-based, 5-8 per domain + 3-4 cross):
  - Self: "3-day body awareness micro-practice", "Habit stack with energy check", restoration in lowEnergy.
  - Stewardship: "Audit 1 subscription leak + propose redirect to analog", "Redirect X savings to experience".
  - CareKin: "Schedule + complete 1 non-digital meetup/delegation; log outcome + photo/note optional", respite delegation.
  - Meaning: "Capture 1 legacy memory/story; echo a past ripple".
  - Cross: "Stewardship win → CareKin + Meaning chain reaction".
- [x] Quest generation service: context-aware (uses recent events, energy, mastery gaps, season). Support "forge custom".
- [x] Flow implementation (Compass + Prototype): Quests list/modal in Compass or new lightweight view. Accept → move to Active Weaves section. Complete button → reflection sheet (required short note/explanation for full reward) → optional local evidence attachment (store in model or filesystem ref) → emit rich event via TimelineService with linkedThreads + quest metadata → award + celebration trigger.
- [x] Validation & IRL bias (reflection gate): require reflectionNote for full baseEssence; optional evidence boosts. "Close app & do this IRL now" prominent CTA after accept/complete.
- [ ] Integration: On quest complete, update relevant Thread (e.g. CareKin task created, Stewardship savings recorded, Meaning story added). Mastery/streak/harmony updates cascade.
- [ ] Discovery: "Suggested Weaves" section in Compass (2-4 dynamic). Mastery Map grid for browsing by tier/gap (calm, not gamified grid).
- [ ] Active tracking: persist activeQuests in context or separate; show progress.

## Phase 4: Visual Weave / Living Loom (Focus Area — Signature)
- [x] Evolve ThreadRingView / CompassView: SimpleLivingLoomView with mastery sizing + resonance (starter) component (SwiftUI Canvas or Shape + Path for organic bezier/flowing lines representing 4 threads).
  - Thread segments: color per domain (Self violet, Stewardship teal, CareKin amber, Meaning indigo), thickness/glow by mastery + recent activity.
  - Stitches/dots density by accumulated Essence/harmony in domain.
  - Ripple pulses: subtle outward lines/particles on new TimelineEvent (calm, slow, state-influenced).
  - Harmony connections: flowing lines between threads on combo/resonance.
  - Mastery embroidery: overlay evolving badges/icons (simple → detailed) on segments.
  - Tap: deep link to ThreadDetail or echo view.
- [ ] State integration: palette/speed/brightness driven by AppState (highFlow: lively organic flow + accent; lowEnergy: muted, slower, restorative palette suggestions). Use @Environment or bind to LifeContext.
- [ ] Animations: spring, low-framerate TimelineView, symbolEffect for mastery, .sensoryFeedback for meaningful completes. Glass/ultraThinMaterial where fits calm aesthetic.
- [ ] Peripheral elements: enhance Energy bars → Harmony flows; Active Ripples with "echo lines" connecting domains; subtle HUD ✧ Essence • Lvl • Harmony%.
- [ ] Celebration: on quest complete / high impact: slow-bloom connection dots fading into tapestry (Math Quest lite, not flashy confetti). Haptics. Explanation toast: "Why this ripple matters" tying to philosophy.
- [ ] Performance: efficient paths, no heavy loops; test with many events.
- [ ] Accessibility: labels, reduced motion respect, contrast.
- [ ] PWA parity later: note for HTML5 Canvas equivalent if scope expands.

## Phase 5: Streaks, Mastery, Resonance, Echoes (Core Retention Mechanics)
- [ ] Streak visuals (HUD + loom starter). Display per-thread + global in summary views.
- [ ] Restorative grace logic: detect inactivity/lowEnergy in update; auto-suggest restoration quests; don't decrement streak on grace; provide "restoration complete" bonuses.
- [ ] Mastery Map (badges in HUD + loom for MVP) or section (grid or list). Shows tiers, progress to next, suggested quests, passive perks description. Tap to review/echo.
- [ ] Resonance/Combos: in TimelineService.emitEvent or LifeContext.process, detect recent linkedThreads within window → award combo multiplier, trigger visual chain lighting (glow connections in weave), boost state temporarily to highFlow, surface "Resonance unlocked" in insights.
- [ ] Echo system: UI to list past events/quests with "Echo" action → reflection prompt + bonus Essence + new Meaning ripple. Grow Legacy Tapestry (extension of Meaning view or overlay on weave).
- [ ] Update insights/suggestions: cross-thread (e.g. in Compass, ThreadDetail) to use new mechanics (e.g. "Your streak + harmony suggests this quest").
- [ ] Seasons/Chapters: add simple season model or tag in LifeContext (user set or auto). On change/close: big reflection gate, chapter summary, Essence burst.

## Phase 6: UI Integration, Polish & Cross-Thread Wiring
- [x] Compass updates: add Suggested Weaves, Essence HUD, reflection gate, WeaveTapestryView (or compose), Harmony indicator, state-aware theming. Keep minimalist, progressive disclosure.
- [ ] ThreadDetail / other views: surface relevant quests, mastery progress, streak, amplifiers, recent ripples with visual links.
- [ ] New lightweight views if needed: QuestsView (or modal), MasteryMapView, EssenceLedgerView — keep simple, reuse navigation.
- [ ] Wire all: every quest/essence/streak change emits event or updates context → ripples to other threads/UI. Use existing processEvent patterns.
- [ ] Onboarding hook: extend to demo first quest + loom intro + sample ripple → visual update + IRL prompt (5-7min first weave).
- [ ] End-of-session: "Weave Complete" with IRL CTA.
- [ ] Widgets/Live Activities (if scope): harmony + suggested weave (future).
- [ ] Premium gates: basic free strong; deeper forges/analytics/custom visuals behind premium flag (local).
- [ ] Full navigation: ensure from Compass rings/loom → threads → quests → details; History shows gamified events with links.

## Phase 7: Verification, Anti-Addiction, Privacy, Metrics & Polish
- [ ] Anti-addiction enforcement: scan for reflection gates, no punitive streaks, exit ramps, usage transparency notes, calm visuals. Add "minimal mode" toggle stub for over-gamification.
- [ ] Privacy audit: all new models local SwiftData; no network in gamif paths; export includes new data; clear works; no-training comments.
- [ ] Metrics implementation (internal): track % quests with IRL/reflection, harmony changes, disengagement (sessions ending with IRL prompt), etc. Surface privately in settings or summary.
- [ ] Testing: prototype harness (OneWeavePrototype or equivalent) with simulate quest complete, essence award, loom update, streak grace, cross-chain. Seed data. Verify ripples everywhere.
- [ ] Edge cases: zero data start, lowEnergy flow, many quests, long history echoes, balance calc with 0 variance.
- [ ] Performance: smooth Canvas on many events; no battery drain.
- [ ] Polish: consistent colors, typography, explanations ("Why this matters"), calm celebrations. Remove any placeholders.
- [ ] Cross-artifact check: every spec requirement has task coverage; plan (if created) aligns; constitution followed.
- [ ] Update IMPLEMENTED_FEATURES.md , USER_JOURNEYS if gamif impacts flows, and any docs.

## Phase 8: Packaging & Follow-up
- [ ] iOS app integration: App Intents, widgets for harmony/quests if ready.
- [ ] Documentation: update whitepaper snippets or DESIGN if evolved; add to IMPLEMENTED_FEATURES.
- [ ] Analysis: run equivalent of /speckit.analyze (manual cross check spec vs tasks vs code).
- [ ] Post-MVP: advanced on-device personalization for quests, full PWA parity, physical legacy exports (premium).

## Notes
- Order is dependency-aware: models/services before UI/visuals before full integration.
- Each task should produce working incremental artifact (e.g. after Phase 1: quests can be generated/awarded in console/prototype; after Phase 4: visual updates live).
- Estimate: S/M per subtask; large visual Canvas may be L.
- Always: emit via service, update context, show in Compass, tie to real IRL/ripples.
- After major phases: re-verify with searches for stubs, test flows in prototype, confirm constitution compliance (calm, local, purposeful).
- Use full files for key changes (models, services, CompassView, new WeaveTapestryView).

This task list is generated from the spec. Complete in order, validate at gates, deliver real integrated behavior.
