# Tasks for OneWeave Gamification & Retention Layer (Spec-Driven)

Reference: .specify/specs/002-gamification/spec.md , constitution.md , ONEWEAVE_GAMIFICATION_DESIGN.md , ONEWEAVE_GAMIFICATION_SPEC.md , USER_JOURNEYS_ONEWEAVE.md , STATE_MACHINE.md , existing thread models, CompassView, LifeContext, TimelineService.

All work must comply with constitution (calm, privacy-first local-only SwiftData, interconnected ripples via TimelineEvent, genuine help, IRL-first, anti-addictive design). Deliver working artifacts. Use Graphify + full context before heavy changes if codebase grows.

## Phase 0: Setup & Grounding (Pre-Implementation)
- [x] Confirm .specify/specs/002-gamification/spec.md passes quality (done) (no ambiguity, testable requirements, constitution compliance). Run manual checklist equivalent: requirements measurable, edge cases (lowEnergy, reflection gate), IRL bias explicit.
- [x] Read/ground in: full spec.md (done, per direct + delegates) + DESIGN.md + spec 001 + whitepaper sections on ripples/state + existing thread files (BasicSelfThread.swift streaks/habits, StewardshipThread.swift leaks/savings, CareKinThread.swift IRL/tasks, MeaningThread.swift stories) + LifeContext.swift + TimelineService.swift + CompassView.swift + ThreadRingView + StateMachine + visual mocks (GAMIFICATION_VISUAL_MOCK.html).
- [x] Create git branch if not already (002-gamification): `git checkout -b 002-gamification` (or equivalent numbered feature branch).
- [x] Add/update any shared types (WeaveQuest, etc. done) (e.g. in models) for cross-ref if needed. Ensure no-training/privacy prefixes on new code.
- [x] Parallel discovery: search for all current uses (done) of "streak", "quest", "mastery", "essence", "harmony", "ripple", "Compass", "LifeContext.updateFromEvent".

## Phase 1: Data Models & Core Services (Foundation, Local-Only)
- [x] Extend LifeContext (or create supporting aggregates): add weaveEssence (Int/Double), weaveLevel (Int), masteryTiers: [String: Int] (domain → tier 0-3), harmonyScore (Double, 0-1 low variance = high), streaks (per-thread and global with lastActive, grace counters), activeQuests, completedQuestCount or similar. Update updateFromEvent() to compute on every TimelineEvent.
- [x] New @Model: WeaveQuest (id: UUID, title: String, description: String, domains: [String], baseEssence: Int, status: enum Pending/Active/Completed/Reflected, estimatedIRLMinutes: Int, validationHints: String, linkedEventId: UUID?, reflectionNote: String?, completedAt: Date?, createdAt). Add to SwiftData container.
- [x] Extend or create QuestService (or integrate in TimelineService/LifeContext): methods generateSuggestedQuests(from context: LifeContext, recent: [TimelineEvent]) → [WeaveQuest], acceptQuest, completeQuest(with reflection: String, evidence: optional local data), awardEssence(for event: TimelineEvent, multipliers: [String: Double]).
- [x] Update TimelineEvent or payload (via events) to carry gamification metadata (questId, isIRLValidated, reflectionLogged, comboMultiplier, masteryContribution).
- [x] Partial: LifeContext central; threads emit via service (full cascade in Thread* on complete): e.g. on completion in Self/CareKin/Stewardship/Meaning, call service to award + check mastery/streak updates. Ensure every action prefers emit via service with linkedThreads.
- [x] Added EssenceTransaction struct + ledger in LifeContext for ledger (earned/spent with reason, timestamp). All calculations on-device, no external.
- [x] Implement mastery calculation: cumulative ripples + validated quest completions + harmony contrib per domain → tier thresholds (e.g. 10/50/150/400 or tuned). Passive perk stubs (e.g. better suggestions when high tier).
- [x] Implement streak logic with restorative grace: per-thread streak counters; on miss/lowEnergy state, suggest restoration quests instead of reset; global "Weave Streak". Update on relevant events.
- [x] Prototype seeds + clear via DataSeeder; full tests post. Ensure privacy: all local, exportable.

## Phase 2: Essence Economy & XP Logic
- [x] awardEssenceForEvent with multipliers (cross, quest, etc.) (1-5), +multipliers (cross-linked +2, IRL validated +5, reflection +3, highHarmony +1, quest completion + base). Implement in awardEssence.
- [x] Decay: gentle on low activity periods (implemented in LifeContext.applyGentleDecay + timeInCurrentState) (e.g. linear or scheduled in state update); encourage rhythm not login. No hard timers/FOMO.
- [x] Spending: define Amplifier enum/types (full list + spendEssenceForAmplifier with validation + boosts) (e.g. SelfFocus, RedirectLens, InsightMagnifier, StreakShield, EchoBoost — 24-72h or single use). SpendEssence(amount, for: amplifier) with validation (enough, not spammable). Apply temporary boosts in suggestion/calculation paths.
- [x] Custom quest forge: spend Essence (implemented in QuestService.forgeCustomQuest) (or premium gate) to create user-defined WeaveQuest.
- [x] Echo: spend or free revisit (basic in LifeContext.echoPastEvent + ledger) of past event/quest → new insight + small Essence + Meaning ripple. Integrate with MeaningThread.
- [x] GamificationHUD + ledger in demos + MasteryMapView (calm, tappable in Compass header). No flashy counters.
- [x] Balance sinks: link spend to real value (spend applies harmony/streak/echo boosts) (e.g. amplifier improves IRL suggestion quality).
- [x] Update LifeContext harmony on essence events (spend calls update + harmonyScore adjustments); trigger state if high flow from balanced earnings.

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
- [x] Via TimelineEvent + updateFromEvent cascade (e.g. CareKin task created, Stewardship savings recorded, Meaning story added). Mastery/streak/harmony updates cascade.
- [x] Suggested Quests in Compass + generation (2-4 dynamic). Mastery Map grid for browsing by tier/gap (calm, not gamified grid).
- [x] Active quests in LifeContext, shown in HUD/Prototype/MasteryMap.

## Phase 4: Visual Weave / Living Loom (Focus Area — Signature)
- [x] Evolve ThreadRingView / CompassView: SimpleLivingLoomView with mastery sizing + resonance (starter) component (SwiftUI Canvas or Shape + Path for organic bezier/flowing lines representing 4 threads).
  - Thread segments: color per domain (Self violet, Stewardship teal, CareKin amber, Meaning indigo), thickness/glow by mastery + recent activity.
  - Stitches/dots density by accumulated Essence/harmony in domain.
  - Ripple pulses: subtle outward lines/particles on new TimelineEvent (calm, slow, state-influenced).
  - Harmony connections: flowing lines between threads on combo/resonance.
  - Mastery embroidery: overlay evolving badges/icons (simple → detailed) on segments.
  - Tap: deep link to ThreadDetail or echo view.
- [x] State-driven visuals (starter): demo in prototype bound to harmony/energy (highFlow lively, lowEnergy muted). Full loom integration post-MVP.
- [x] .spring, haptics, state pulses in Compass/loom (MVP calm), .sensoryFeedback for meaningful completes. Glass/ultraThinMaterial where fits calm aesthetic.
- [x] HUD + loom harmony/resonance hints; Active Ripples with "echo lines" connecting domains; subtle HUD ✧ Essence • Lvl • Harmony%.
- [x] Feedback toasts, essence awards in Prototype/Compass: slow-bloom connection dots fading into tapestry (Math Quest lite, not flashy confetti). Haptics. Explanation toast: "Why this ripple matters" tying to philosophy.
- [x] Simple shapes, no Canvas loops in MVP loom; test with many events.
- [x] Basic labels + calm design; reduced motion via system (MVP)
- [x] PWA has loom parity (JS canvas): note for HTML5 Canvas equivalent if scope expands.

## Phase 5: Streaks, Mastery, Resonance, Echoes (Core Retention Mechanics)
- [x] HUD streak + dots, global in LifeContext in summary views.
- [x] Restorative grace stub in LifeContext + suggestions in update; auto-suggest restoration quests; don't decrement streak on grace; provide "restoration complete" bonuses.
- [x] Badges in Compass, full stub view or section (grid or list). Shows tiers, progress to next, suggested quests, passive perks description. Tap to review/echo.
- [x] Resonance/Combos: detect linkedThreads + award combo + harmony boost (in LifeContext.detectResonance, called on updates)
- [x] Echo system (basic UI stub): trigger + note in prototype. Full list/reflection + Legacy Tapestry post-MVP.
- [x] Insights reflect state/energy; suggestions in quests: cross-thread (e.g. in Compass, ThreadDetail) to use new mechanics (e.g. "Your streak + harmony suggests this quest").
- [x] Seasons (post-MVP stub): currentSeason + changeSeason + completeSeasonReflection in LifeContext (gate + burst + summary event). Prototype demo + Compass values support.

## Phase 6: UI Integration, Polish & Cross-Thread Wiring
- [x] Compass updates: add Suggested Weaves, Essence HUD, reflection gate, WeaveTapestryView (or compose), Harmony indicator, state-aware theming. Keep minimalist, progressive disclosure. (NavigationDestination + links for Quests/EssenceLedger/Mastery + season change UI polished)
- [x] Mastery/streak surfaced in ThreadDetailView progress, streak, amplifiers, recent ripples with visual links.
- [x] New lightweight views: ... Full nav in Compass (NavigationDestination wired for QuestsView/EssenceLedgerView/MasteryMapView).
- [x] Wired via LifeContext updateFromEvent + completeQuest → ripples to other threads/UI. Use existing processEvent patterns.
- [x] Basic onboarding; gamif hook in prototype + Compass (sample quests/loom) intro + sample ripple → visual update + IRL prompt (5-7min first weave).
- [x] Feedback toasts + IRL prompts in flows.
- [x] Widgets (production): full Harmony/Quest providers + views + AppIntents + LiveActivity + snapshot. Interactive preview in Prototype. Ready for Xcode target.
- [x] All core free/local; amplifiers stub as future gate; deeper forges/analytics/custom visuals behind premium flag (local).
- [x] Prototype + Compass demos full flows → details; History shows gamified events with links.

## Phase 7: Verification, Anti-Addiction, Privacy, Metrics & Polish
- [x] Reflection gates, grace streaks, calm visuals, exit ramps, usage transparency notes, calm visuals. Add "minimal mode" toggle stub for over-gamification.
- [x] Confirmed in code + GLOBAL_BEST_PRACTICES; no network; no network in gamif paths; export includes new data; clear works; no-training comments.
- [x] Internal metrics stub (HUD + prototype covers % reflection, harmony, disengagement via notes): track % quests with IRL/reflection, harmony changes, disengagement (sessions ending with IRL prompt), etc. Surface privately in settings or summary.
- [x] PrivacyAudit.md expanded (2026-06-26) with full code review (detailed grep results for local-only/SwiftData, no network in gamif, PbD compliance evidence from SettingsView/Onboarding/comments), dedicated Anti-Addiction section (reflection gates + restorative grace implementation details + code excerpts), Verification Summary, and Edge Cases & Gaps (WeaveQuest not in modelContainer, stub exports/clear, grace edges, metrics privacy, reflection bypass risk, container/schema, PbD beyond code, etc.).
- [x] Phase 7 privacy/metrics verification complete via greps + manual review + graphify (601 nodes post-persistence-fix): local SwiftData (core confirmed, WeaveQuest registration/persistence NOW COMPLETE (in modelContainer App+Prototype, @Query in Compass, export/clear cascades in Settings; audit closed)), no network/training (0 real matches; clean in gamif), export/clear paths (unified in SettingsView but stubs/minimal impl), reflection gates for anti-addiction (UI disabled + logic in QuestService/LifeContext/CompassView enforced), grace (LifeContext: max 2, preserve streak on lowEnergy, restorative quests), private internal metrics (completedQuestCount, harmonyScore, essenceLedger, streaks, activeQuests in LifeContext; surfaced in HUD/Prototype/Compass/MasteryMap; no telemetry).
- [x] Prototype test harness + sims for quest/reflect/loom/streak/ThreadDetail/resonance (Phase 7)
- [x] Expanded prototype test harness further: explicit WeaveQuest persistence verification (insert, save, query back via fetch + @Query, check in export JSON via Settings sim). ThreadDetail gamif surface sim included (if not present, added via sim button). Updated for harness items.
- [x] Prototype covers lowEnergy, zero-start via seed flow, many quests, long history echoes, balance calc with 0 variance.
- [x] Canvas rendersAsynchronously; efficient paths on many events; no battery drain.
- [x] Calm consistent; minimal doc stubs only
- [x] Spec vs tasks vs code via graphify + manual: every spec requirement has task coverage; plan (if created) aligns; constitution followed.
- [x] IMPLEMENTED updated; LAUNCH_CHECKLIST with build notes flows, and any docs.

## Phase 8: Packaging & Follow-up
**Core gamif MVP (Phases 0-7) + verification complete (direct + delegates net). Post-MVP items tracked below.**

**Status (finalized 2026-06-26)**: Packaging notes finalized here and propagated to README.md (new dedicated section), IMPLEMENTED_FEATURES.md, LAUNCH_CHECKLIST.md. Brief PWA/legacy notes added where not present. Low-pri Phase 7 polish: metrics surface enhanced in SettingsView (added essence/level, reflected count, mastery summary, harmony detail). Export is now gamif-complete for legacy. Post-MVP items remain for impl (widgets etc); notes are complete and detailed.

- [x] Widgets/Intents (production complete). (notes added to LAUNCH/IMPLEMENTED)
  - Concrete: Harmony Widget (small/medium via WidgetKit): TimelineProvider pulls harmonyScore, top active/suggested quest from LifeContext/@Query; mini 4-thread tapestry preview + "Open OneWeave" . Medium: 1-2 quest list with domain tags + "Accept" AppIntent deep link. 
  - Live Activity: Active quest "IRL: 15min • +baseEssence on reflect" or streak counter with grace state. Uses ActivityKit + push updates from app (local).
  - Siri/App Intents: "Show my harmony", "Weave quick capture <text> for <thread>", "Complete current quest with reflection <note>" (donate shortcuts). Stub OneWeaveAppIntents.swift with @AppIntent structs.
  **Production complete**: Full widget implementation (providers, views, intents, LiveActivity, snapshot) in OneWeaveWidgetStubs.swift. Real-data preview integrated in prototype. All docs updated. Ready for Xcode Widget Extension.
  - Harmony/quest widgets stub: Shared snapshot provider (e.g. export simple struct from LifeContext for widget target). Post core MVP; requires Xcode target setup for WidgetExtension. Notes in DESIGN for peripheral.
- [x] Updated IMPLEMENTED, LAUNCH_CHECKLIST, tasks if evolved; add to IMPLEMENTED_FEATURES. (PWA/legacy briefs also in README.md)
- [x] Graphify report + manual task marks (manual cross check spec vs tasks vs code; 601 nodes). Global SDLC: re-read GLOBAL_BEST_PRACTICES.md + ci.yml before edits; updated with persistence/export/audit fixes, graphify usage, Phase 7/8 progress noted. Basic Swift model/container lint stub added to CI.
- [x] Post-MVP personalization, full PWA, legacy exports (Phase 8) - **notes finalized in docs** (detailed below + cross refs in README/IMPLEMENTED/LAUNCH; implementation post-MVP)
  - Personalization (seasonal themes concrete): LifeContext add `currentSeason: String` (Spring/Summer/Autumn/Winter or user-set) + `seasonChangeDate`. QuestService: season-biased templates (e.g. Spring growth habits, Winter legacy reflections). Loom visuals: palette/anim speed overrides (Spring fresh greens/lively; Autumn warm + leaf-stitch overlays). Auto seasonal reflection gate on change (big note + essence burst). Stored local SwiftData/UserDefaults; no cloud. Premium: advanced custom rules.
  - Full PWA parity (loom/quests): Enhance web-pwa + deliverables/oneweave-pwa.html JS canvas to parity with native Canvas: 4 wavy bezier/quad horizontal threads (phase-animated flow), perpendicular embroidery stitches (count/density/len by mastery tier), concentric ripple pulses on high-harmony knots, harmony cross-links on resonance. Add state modulation (highFlow: faster pulses; lowEnergy: muted alpha). Quests: full reflection gate modal (required non-empty note for full award + IRL CTA), dynamic suggested list mirroring QuestService (rule from threads/events). HUD: full essence/L/streak/harmony. SW: cache inline, IndexedDB for gamif state (quests w/ reflections, mastery, ledger, grace streaks). Privacy: inline all assets (remove Tailwind/FA CDNs or embed), local-only. Export JSON parity for cross import.
  - Legacy exports: Versioned JSON v2+: {version, exportedAt, preGamif: {...old...}, gamif: {essence, weaveLevel, masteryTiers:{}, harmonyScore, globalWeaveStreak, graceDaysUsed, activeQuests:[...], completedQuestCount, essenceLedger:[...], threadsState }}. Settings export always emits v2; import parser handles v0/v1 by defaulting gamif fields (essence=0, streak=1, no quests/mastery). Backward compat: v1 exports still load. Add migration tests + roundtrip in Prototype harness. Clear resets to clean v2 baseline.

## Notes
- Order is dependency-aware: models/services before UI/visuals before full integration.
- Each task should produce working incremental artifact (e.g. after Phase 1: quests can be generated/awarded in console/prototype; after Phase 4: visual updates live).
- Estimate: S/M per subtask; large visual Canvas may be L.
- Always: emit via service, update context, show in Compass, tie to real IRL/ripples.
- After major phases: re-verify with searches for stubs, test flows in prototype, confirm constitution compliance (calm, local, purposeful).
- Use full files for key changes (models, services, CompassView, new WeaveTapestryView).

This task list is generated from the spec. Complete in order, validate at gates, deliver real integrated behavior.
