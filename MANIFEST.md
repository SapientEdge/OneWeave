# OneWeave MANIFEST

Every file in this repository, with line count and one-line purpose.
Generated automatically; do not edit by hand. Regenerate with:

```bash
python3 .research/generate_manifest.py
```

## Sources/OneWeave/ (Swift, the app module)

| File | Lines | Purpose |
|------|------:|---------|
| `Sources/OneWeave/AppLifecycleCoordinator.swift` | 523 | OneWeave Tier A #5: app lifecycle wiring for save/load + Sacred Echo re-check + |
| `Sources/OneWeave/AppStateMachine.swift` | 86 |  |
| `Sources/OneWeave/BasicSelfThread.swift` | 374 | Enhanced BasicSelfThread per OneWeave spec and USER_JOURNEYS_ONEWEAVE.md. Self thread: habits/goals, micro-learning, analog intent, energy management. Features: |
| `Sources/OneWeave/BodyThreadSheet.swift` | 101 | OneWeave Sheet that reads a Body Thread reading from HealthKit (or from sample data) |
| `Sources/OneWeave/BodyThreadWeaver.swift` | 157 | OneWeave Body-Thread Weaver (creative novel feature #3): |
| `Sources/OneWeave/CareKinThread.swift` | 419 | Enhanced CareKinThread per OneWeave spec, USER_JOURNEYS_ONEWEAVE.md, and patterns from BasicSelfThread/StewardshipThread. Care & Kin: family coordination, multi-gen tasks, IRL micro-connections (real  |
| `Sources/OneWeave/CognitiveLoad.swift` | 493 | OneWeave Cognitive Load Score — real-time estimate of how loaded the user's |
| `Sources/OneWeave/CommandPalette.swift` | 179 | OneWeave Universal Command Palette (from Unified Blueprint - High priority UX). |
| `Sources/OneWeave/CompassView.swift` | 971 | Privacy: all gamification (essence, mastery, quests, loom state) is local SwiftData only. No network, no external calls, no training. Export/clear works via Settings. Reflection gates anti-addiction. |
| `Sources/OneWeave/DailyBriefings.swift` | 465 | OneWeave Morning Briefing + Evening Review generators — pure on-device synthesis |
| `Sources/OneWeave/DataLeashSettings.swift` | 195 | OneWeave Privacy-First Data Leash (from Feature Matrix + Unified Blueprint - Critical Tier 1). |
| `Sources/OneWeave/DataSeeder.swift` | 94 | DataSeeder: Populates demo data for journeys (call on first launch or via prototype button). Privacy: Local only. For testing interconnections. Enhanced to also seed thread model instances so .summary |
| `Sources/OneWeave/DecisionLog.swift` | 331 | OneWeave Decision Log — tracks the user's significant decisions over time and |
| `Sources/OneWeave/EssenceLedgerView.swift` | 61 | Phase 6: Simple Essence Ledger view. Calm list of transactions + summary. Local-only. Ties to LifeContext. Reusable in prototype/Compass/Settings. |
| `Sources/OneWeave/FamilyPod.swift` | 597 | OneWeave Family Pod — Tier-2 feature. Layered on top of Weave Circles with |
| `Sources/OneWeave/GraphInsightGenerator.swift` | 360 | Cross-Domain Insight Engine (from Feature Matrix + Unified Blueprint) Uses Life Graph + existing harmony/quests/essence for "Aha!" moments. All on-device. Privacy-respecting (respects Data Leash). |
| `Sources/OneWeave/HistoryView.swift` | 135 |  |
| `Sources/OneWeave/InsightGenerator.swift` | 54 |  |
| `Sources/OneWeave/InvisibleMentor.swift` | 328 | OneWeave Invisible Mentor — 5th creative feature (Tier A #4). |
| `Sources/OneWeave/LifeContext.swift` | 542 | MARK: - File-scope supporting types Single essence ledger entry (audit trail for the calm, anti-addictive economy). public struct EssenceTransaction: Codable, Identifiable, Hashable { |
| `Sources/OneWeave/LifeGraph.swift` | 177 | MARK: - Life Graph Core (from Feature Matrix + Unified Blueprint) Unified ontology for entities and relationships across life domains. Extends existing OneWeave Threads/TimelineEvent/WeaveQuest withou |
| `Sources/OneWeave/LifeGraphiOSIntegrations.swift` | 64 | OneWeave Shim / facade that maps the older \`LifeGraphiOSIntegrations.shared.importAll(...)\` API |
| `Sources/OneWeave/LivingGraphLoom.swift` | 251 | OneWeave Living Graph Loom — creative feature #6. SwiftUI renderer for the Loom. |
| `Sources/OneWeave/LoomGeometry.swift` | 384 | OneWeave Pure-Swift geometry for the Living Graph Loom visualization. No SwiftUI, |
| `Sources/OneWeave/MasteryMapView.swift` | 152 | Phase 5 Mastery Map: calm grid/list showing tiers, progress, suggested review/echo actions. Tap domain for "echo practice" (simulates review + small resonance/essence + mastery tick if low). Local-onl |
| `Sources/OneWeave/MeaningThread.swift` | 281 | Enhanced MeaningThread per OneWeave spec and USER_JOURNEYS_ONEWEAVE.md. Meaning & Legacy thread: reflection, stories, niche projects, legacy capture. Features: |
| `Sources/OneWeave/MentorEchoBridge.swift` | 319 | OneWeave Bridges Sacred Echo opened echoes into Invisible Mentor input seeds. |
| `Sources/OneWeave/OnboardingView.swift` | 75 |  |
| `Sources/OneWeave/OneWeaveAPI.swift` | 236 | OneWeave PUBLIC API CATALOG — read this first when integrating with OneWeave. |
| `Sources/OneWeave/OneWeaveApp.swift` | 146 | @main |
| `Sources/OneWeave/OneWeavePrototype+GraphValidation.swift` | 419 | Extension to OneWeavePrototype for Life Graph + Insight validation This runs in the DEBUG harness only. Exercises new code with real-ish data from existing threads/quests. "Validated" = logs expected  |
| `Sources/OneWeave/OneWeavePrototype.swift` | 997 | Full end-to-end testing harness for production-grade OneWeave. Demos all features: journeys, state machine transitions, ripples, energy, export, search, cross-integration. |
| `Sources/OneWeave/OneWeaveSnapshotStore.swift` | 60 |  |
| `Sources/OneWeave/OneWeaveWidgetStubs.swift` | 222 | Phase 8 production: Harmony/Quest widgets production + App Intents + Live Activities Concrete per tasks.md Phase 8: |
| `Sources/OneWeave/P2PWeaveShare.swift` | 268 | Deeper P2P Weave Share - Enhanced from iOS P2P Messaging Implementation Guide Hybrid: Network framework (Bonjour local) + WebRTC (internet) Offline queue, QR signaling for serverless auth, reflection  |
| `Sources/OneWeave/PortableExport.swift` | 639 | OneWeave Privacy-leash-aware portable export + import for OneWeave. |
| `Sources/OneWeave/QuestService.swift` | 118 | QuestService: Generates, manages quests per 002-gamification spec. Local-only, context-aware, IRL-first, anti-addictive (reflection required for full reward). |
| `Sources/OneWeave/QuestsView.swift` | 100 | Phase 6: Lightweight QuestsView (or use as modal). Lists suggested/active + reflection flow. Reuses QuestService + LifeContext. Calm, IRL-first. Keep simple. |
| `Sources/OneWeave/QuickCaptureInbox.swift` | 387 | OneWeave Quick Capture Inbox — single text field that auto-classifies user input |
| `Sources/OneWeave/RelationshipDecayTracker.swift` | 259 | OneWeave Relationship Decay Tracking — passive signal that surfaces "you haven't |
| `Sources/OneWeave/ResonanceOracle.swift` | 148 | Novel Feature: Resonance Oracle - Local Decision Simulator No one has built this: Embodied foresight by simulating impact on your entire Life Graph. User inputs a scenario. App runs a private simulati |
| `Sources/OneWeave/ResonanceOracleSheet.swift` | 118 | OneWeave SwiftUI sheet for the Resonance Oracle (local decision simulator). |
| `Sources/OneWeave/SacredEcho.swift` | 659 | OneWeave Sacred Echo Vault — 4th creative feature (Tier A #3). |
| `Sources/OneWeave/SchemaMigrationPlan.swift` | 396 | OneWeave SwiftData VersionedSchema + SchemaMigrationPlan for OneWeave's |
| `Sources/OneWeave/SettingsView.swift` | 146 |  |
| `Sources/OneWeave/StateMachineIndicator.swift` | 33 | Subtle, peripheral, non-intrusive state machine indicator. Per white paper calm tech: disappears into the fabric, peripheral awareness only. Shows current AppState with minimal color + icon. Tappable  |
| `Sources/OneWeave/StewardshipThread.swift` | 118 | @Model |
| `Sources/OneWeave/Thread.swift` | 25 | Protocol for fluid Threads (event-driven, can process ripples from other threads). Keep simple for production; concrete implementations in per-thread files. |
| `Sources/OneWeave/ThreadDetailView.swift` | 676 | Polished Phase 6: Full gamif surface in ThreadDetailView Mastery details: tier/progress/description/perks now wired via LifeContext + HUD (full surface in ThreadDetail) - Active quests list (thread-fi |
| `Sources/OneWeave/ThreadsOverviewView.swift` | 252 |  |
| `Sources/OneWeave/TimelineEvent.swift` | 40 | TimelineEvent: proper @Model for event-driven updates across all threads. Central to interconnections in OneWeave. All local-only per privacy best practices. @Model |
| `Sources/OneWeave/TimelineService.swift` | 111 | TimelineService: central for event-driven updates. Emits, persists, notifies LifeContext. Follows global best practices: privacy-first, local-only, no external calls or training data use. Now also dri |
| `Sources/OneWeave/WeaveQuest.swift` | 44 | @Model |
| `Sources/OneWeave/WeaveSummaryView.swift` | 31 |  |
| `Sources/OneWeave/iOSServiceIntegrations.swift` | 778 | iOSServiceIntegrations.swift OneWeave Privacy-First, user-initiated integrations with iOS system services. |

## .research/ (validation harness + design docs)

| File | Lines | Purpose |
|------|------:|---------|
| `.research/generate_manifest.py` | 155 |  |
| `.research/validate_cognitive_load.py` | 466 |  |
| `.research/validate_daily_briefings.py` | 503 |  |
| `.research/validate_decision_log.py` | 457 |  |
| `.research/validate_family_pod.py` | 699 |  |
| `.research/validate_mentor_bridge.py` | 533 |  |
| `.research/validate_portable_export.py` | 616 |  |
| `.research/validate_quick_capture.py` | 413 |  |
| `.research/validate_relationship_decay.py` | 322 |  |
| `.research/validate_round2_loom.py` | 370 | LoomGeometry validation mirror — pure-math checks for thread placement, |
| `.research/validate_schema_migration.py` | 304 |  |
| `.research/validate_stress.py` | 566 |  |
| `.research/validate_tierA1_cache.py` | 211 | Tier A #1 validation mirror — replicates the @MainActor + cache logic from |
| `.research/validate_tierA2_integrations.py` | 263 | Tier A #2 validation mirror — replicates the Mail/Notes/Reminders gating |
| `.research/validate_tierA3_echo.py` | 302 | Tier A #3 validation mirror — Sacred Echo Vault gate logic + lifecycle |
| `.research/validate_tierA4_mentor.py` | 295 | Tier A #4 validation mirror — Invisible Mentor synthesizer logic. |
| `.research/validate_tierA5_lifecycle.py` | 355 | Tier A #5 validation mirror — App Lifecycle envelope + scenePhase routing. |
| `.research/AGENT_SQUAD_PROMPTS.md` | 75 | Agent Squad — OneWeave High-ROI Cycle Prompts |
| `.research/DEEPER_P2P_EXTERNAL_INTEGRATIONS_PLAN.md` | 43 | Deeper P2P + App + External Integrations Plan for OneWeave |
| `.research/MARKET_RESEARCH_ROUND_2.md` | 118 | OneWeave Market Research — Round 2 (June 2026) |
| `.research/MARKET_RESEARCH_ROUND_3.md` | 239 | Market Research Round 3 — June 2026 |
| `.research/NO_TRAINING_PROMPT.md` | 14 | NO-TRAINING PROMPT PREFIX (Prepend to ALL external CLI / sub-agent invocations) |
| `.research/ONEWEAVE_ENHANCEMENT_PLAN.md` | 77 | OneWeave → Unified Life OS Enhancement Plan |
| `.research/ORGANIZED_STATUS_NOTES_TASKS.md` | 130 | OneWeave Life OS - Organized Status, Notes, What's Next, and Tasks |
| `.research/TIER_B_PLAYBOOK.md` | 296 | OneWeave — Tier B Implementation Playbook |
| `.research/build_log.md` | 724 | OneWeave Life OS Build Log |
| `.research/doc_2f73ffd6e078_iOS_P2P_Messaging_Implementation_Guide_Privacy_First,_Serverless.md` | 294 | iOS P2P Messaging Implementation Guide: Privacy-First, Serverless Architectures |
| `.research/doc_468dee8374d0_Unified_Life_OS:_Comprehensive_Research_&_Strategic_Blueprint_2025.md` | 160 | Unified Life OS: Comprehensive Research & Strategic Blueprint (2025-2026) |
| `.research/doc_79e4820e4dc0_Privacy_First_Local_AI_Assistants_on_iOS_Market_Landscape_and_Technical.md` | 185 | Privacy-First Local AI Assistants on iOS: Market Landscape and Technical Blueprint |
| `.research/doc_9fb9a1563ad9_Life OS: Feature Matrix & Implementation Blueprint.md` | 331 | Life OS: Feature Matrix & Implementation Blueprint |

## Top-level docs

| File | Lines | Purpose |
|------|------:|---------|
| `README.md` | 107 | OneWeave |
| `ARCHITECTURE.md` | 152 | OneWeave Architecture |
| `PRIVACY.md` | 203 | Privacy |
| `CONTRIBUTING.md` | 124 | Contributing |
| `CLAUDE_COWORK_BRIEF.md` | 227 | CLAUDE COWORK BRIEF — Mac-side onboarding |
| `LICENSE` | 21 | (license / config) |
| `.gitignore` | 75 | (license / config) |

## Stats

- **Swift total:** 15,594 lines across 55 files
- **Python validation:** 6,830 lines across 17 suites

Last regenerated: 2026-06-27 20:55 UTC
