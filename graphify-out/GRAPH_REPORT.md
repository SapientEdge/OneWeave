# Graph Report - oneweave  (2026-06-26)

## Corpus Check
- 52 files · ~44,237 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 589 nodes · 880 edges · 46 communities
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 22 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `1afbadba`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 21|Community 21]]
- [[_COMMUNITY_Community 22|Community 22]]
- [[_COMMUNITY_Community 23|Community 23]]
- [[_COMMUNITY_Community 24|Community 24]]
- [[_COMMUNITY_Community 25|Community 25]]
- [[_COMMUNITY_Community 26|Community 26]]
- [[_COMMUNITY_Community 27|Community 27]]
- [[_COMMUNITY_Community 28|Community 28]]
- [[_COMMUNITY_Community 29|Community 29]]
- [[_COMMUNITY_Community 30|Community 30]]
- [[_COMMUNITY_Community 31|Community 31]]
- [[_COMMUNITY_Community 32|Community 32]]
- [[_COMMUNITY_Community 33|Community 33]]
- [[_COMMUNITY_Community 34|Community 34]]
- [[_COMMUNITY_Community 35|Community 35]]
- [[_COMMUNITY_Community 36|Community 36]]
- [[_COMMUNITY_Community 37|Community 37]]
- [[_COMMUNITY_Community 38|Community 38]]
- [[_COMMUNITY_Community 39|Community 39]]
- [[_COMMUNITY_Community 40|Community 40]]
- [[_COMMUNITY_Community 41|Community 41]]
- [[_COMMUNITY_Community 42|Community 42]]

## God Nodes (most connected - your core abstractions)
1. `BasicSelfThread` - 22 edges
2. `SwiftData` - 21 edges
3. `CareKinThread` - 21 edges
4. `LifeContext` - 20 edges
5. `TimelineEvent` - 19 edges
6. `SwiftUI` - 16 edges
7. `OneWeavePrototype` - 16 edges
8. `String` - 15 edges
9. `String` - 14 edges
10. `MeaningThread` - 14 edges

## Surprising Connections (you probably didn't know these)
- `OneWeaveApp` --calls--> `AppStateMachine`  [INFERRED]
  Sources/OneWeave/OneWeaveApp.swift → Sources/OneWeave/AppStateMachine.swift
- `TimelineService` --calls--> `AppStateMachine`  [INFERRED]
  Sources/OneWeave/TimelineService.swift → Sources/OneWeave/AppStateMachine.swift
- `BasicSelfThread` --inherits--> `ThreadProtocol`  [EXTRACTED]
  Sources/OneWeave/BasicSelfThread.swift → Sources/OneWeave/Thread.swift
- `CareKinThread` --inherits--> `ThreadProtocol`  [EXTRACTED]
  Sources/OneWeave/CareKinThread.swift → Sources/OneWeave/Thread.swift
- `MeaningThread` --inherits--> `ThreadProtocol`  [EXTRACTED]
  Sources/OneWeave/MeaningThread.swift → Sources/OneWeave/Thread.swift

## Import Cycles
- None detected.

## Communities (46 total, 0 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.09
Nodes (27): CaseIterable, Identifiable, Amplifier, insightMagnifier, selfFocus, streakShield, EnergyProfile, high (+19 more)

### Community 1 - "Community 1"
Cohesion: 0.09
Nodes (22): App, Equatable, AppState, capturing, highFlow, idle, lowEnergy, reflecting (+14 more)

### Community 2 - "Community 2"
Cohesion: 0.07
Nodes (26): 10. Leak-to-Legacy Redirects (Stewardship), 11. Thread Tools & Amplifiers ("Power-Ups" — Math Quest spirit, calm execution), 12. Harmony Seasons & Life Chapters + Reflection Gates, 1. Design Principles & Non-Negotiables (The Loom Rules), 1. Essence — The Currency of Ripples (XP System), 2. The Four Threads (The Warp & Weft), 2. Weave Level & Global Progression, 3. 12+ Core Gamification Features (Catchy Names + Deep Design) (+18 more)

### Community 3 - "Community 3"
Cohesion: 0.25
Nodes (7): BasicSelfThread, Date, Int, LifeContext, String, TimelineEvent, TimelineService

### Community 4 - "Community 4"
Cohesion: 0.28
Nodes (6): CareKinThread, Date, LifeContext, String, TimelineEvent, TimelineService

### Community 5 - "Community 5"
Cohesion: 0.12
Nodes (18): Codable, QuestStatus, active, completed, pending, reflected, WeaveQuest, QuestStatus (+10 more)

### Community 6 - "Community 6"
Cohesion: 0.17
Nodes (16): CompassView, GamificationHUD, StateMachineIndicator, ThreadRingView, WeaveSummaryView, QuestService, Bool, Color (+8 more)

### Community 7 - "Community 7"
Cohesion: 0.22
Nodes (9): StewardshipThread, ThreadProtocol, Double, LifeContext, String, TimelineEvent, TimelineService, String (+1 more)

### Community 8 - "Community 8"
Cohesion: 0.11
Nodes (18): 1. Critical Bug Fixes (Apply Immediately - Code Won't Build/Run), 2. Encryption Patches (Core Production Requirement), 3. Consent Flow Improvements, 4. No-Leaks / Privacy Hardening Patches, 5. Completeness / Polish Patches, 6. How to Apply (Examples), 7. Additional Production Suggestions (Beyond Patches), Onboarding (OnboardingView.swift) (+10 more)

### Community 9 - "Community 9"
Cohesion: 0.18
Nodes (7): Foundation, CrossThreadInsight, InsightGenerator, LifeContext, String, TimelineEvent, SwiftData

### Community 10 - "Community 10"
Cohesion: 0.11
Nodes (17): 1. Introduction: Weaving the One, 2.1 Event-Driven Architecture of Life, 2.2 The Four Domains of Ripples, 2. Theoretical Foundations: The Event-Driven State Machine, 3.1 Foundations in Calm Technology, 3.2 OneWeave UI Psychology, 3. The Psychology of Calm, Sophisticated UI, 4.1 Architectural Requirements (+9 more)

### Community 11 - "Community 11"
Cohesion: 0.12
Nodes (16): 1. Security & Privacy Gaps (Critical for Production), 2. Code Quality Gaps, 3. Completeness Gaps for Full Production, 4. Specific Findings by File/Component, 5. Recommendations & Prioritized Fixes for Production, Appendix: Commands & Evidence, Compile & Runtime Bugs (Will Not Build/Run Cleanly), Consent Flows (+8 more)

### Community 12 - "Community 12"
Cohesion: 0.16
Nodes (13): CrossRippleRow, EnergyIndicator, ThreadsOverviewView, BasicSelfThread, CareKinThread, Color, EnergyProfile, LifeContext (+5 more)

### Community 13 - "Community 13"
Cohesion: 0.32
Nodes (5): MeaningThread, LifeContext, String, TimelineEvent, TimelineService

### Community 14 - "Community 14"
Cohesion: 0.12
Nodes (14): 10. Success Metrics, Guardrails & Ethics, 11. Roadmap & Next Steps, 1. Freemium Model Overview, 2. Tasty Premium Tiers (Master Loom Focus), 3. Deep Integration with Gamification, 4. Onboarding Hooks ("First Weave" Magic — 5-8 Minutes), 5. Daily Rituals & Habit Formation for Retention, 6. Retention Psychology & Broader Tactics (+6 more)

### Community 15 - "Community 15"
Cohesion: 0.21
Nodes (11): LifeContext, QuestService, Date, Double, Int, ModelContext, QuestStatus, String (+3 more)

### Community 16 - "Community 16"
Cohesion: 0.21
Nodes (7): OneWeavePrototype, BasicSelfThread, CareKinThread, LifeContext, MeaningThread, TimelineEvent, TimelineService

### Community 17 - "Community 17"
Cohesion: 0.15
Nodes (12): 1. Progression Framework: "Weave Level" + Thread Mastery, 2. Economy: "Weave Essence" (Purposeful, Not Grindable Currency), 3. Quests / Ripple Challenges Engine, 4. Visuals & Feedback System (Subtle, Organic, Ripple-Centric), 5. Ripple Chain & Combo System (Core Event-Driven Fun), 8–12 Concrete Gamification Mechanics & Systems, Anti-Addiction Design (Cross-Cutting Safeguards), Implementation Roadmap (Phased, Production-Ready) (+4 more)

### Community 18 - "Community 18"
Cohesion: 0.15
Nodes (7): MasteryMapView, MainTabView, StateMachineIndicator, WeaveSummaryView, LifeContext, LifeContext, SwiftUI

### Community 19 - "Community 19"
Cohesion: 0.17
Nodes (11): Acceptance Criteria, Core Architecture, Goals, Must-Have Features (MVP Scope), Non-Goals, Overview, Research Alignment, Scope Notes (+3 more)

### Community 20 - "Community 20"
Cohesion: 0.17
Nodes (11): Acceptance Criteria, Core Architecture Integration (No Tech Details), Goals, Must-Have Features (Focused Scope), Non-Goals, Overview, Research & Alignment, Scope Notes (+3 more)

### Community 21 - "Community 21"
Cohesion: 0.17
Nodes (11): Notes, Phase 0: Setup & Grounding (Pre-Implementation), Phase 1: Data Models & Core Services (Foundation, Local-Only), Phase 2: Essence Economy & XP Logic, Phase 3: Quests Engine (Focus Area), Phase 4: Visual Weave / Living Loom (Focus Area — Signature), Phase 5: Streaks, Mastery, Resonance, Echoes (Core Retention Mechanics), Phase 6: UI Integration, Polish & Cross-Thread Wiring (+3 more)

### Community 22 - "Community 22"
Cohesion: 0.23
Nodes (7): QuestService, LifeContext, ModelContext, String, TimelineEvent, UUID, WeaveQuest

### Community 23 - "Community 23"
Cohesion: 0.18
Nodes (10): 4 Life Threads (Protocol + Full Logic, No Stubs), Core Architecture & State (Fully Wired), Gamification & Retention Layer (002-gamification Spec MVP), Latest Gamification Progress (post-Phase 4/5 starters), Navigation & End-to-End Flows (Zero Dead Ends), OneWeave — Implemented Features & Functions (Production-Grade, Post-Gamification MVP), Security/Privacy (PbD 7 Principles + Global Best Practices), Spec, SDLC & Production (+2 more)

### Community 24 - "Community 24"
Cohesion: 0.18
Nodes (10): 1. Code & Features (Must-Have for v1), 2. UI/UX Polish (Calm Tech per White Paper), 3. Gamification & Retention (002 Spec MVP), 4. Privacy/Security (Global Best Practices + White Paper PbD), 5. Assets & Marketing, 6. Docs & SDLC, 7. Build & Submit Prep (User Side — Xcode), 8. Post-Launch / Next (+2 more)

### Community 25 - "Community 25"
Cohesion: 0.20
Nodes (9): Feature Highlights (Marketing Bullets), Full Description (for website / App Store), Key Benefits, OneWeave Marketing Content, Positioning, Short App Store Description, Suggested App Store Keywords, Target Audience (+1 more)

### Community 26 - "Community 26"
Cohesion: 0.20
Nodes (9): Architectural State Machine, Conclusion, Executive Summary, Feature Enrichment & Integration, OneWeave: The Philosophy of Interconnected Life as an Event-Driven State Machine, Production Readiness for App Store, Security & Privacy by Design (Production Review), The Philosophy: Life as One Woven Journey (+1 more)

### Community 27 - "Community 27"
Cohesion: 0.28
Nodes (5): ThreadDetailView, LifeContext, String, TimelineEvent, TimelineService

### Community 28 - "Community 28"
Cohesion: 0.22
Nodes (8): Current Status (2026-06-25), Generated Visuals, Key Implemented Features, Marketing, Next Steps Toward Production, OneWeave, Privacy & Philosophy, Quick Start (for developers)

### Community 29 - "Community 29"
Cohesion: 0.22
Nodes (8): Diagram (Mermaid - copy to mermaid.live for visual), Integration, OneWeave State Machine, Overview, Production Readiness, States (AppStateMachine enum), Transitions, UI Reflection (Psychology)

### Community 30 - "Community 30"
Cohesion: 0.29
Nodes (6): Phase 1: Core Foundation (Life Context + Timeline), Phase 2: Threads (Start with 3), Phase 3: Journey Compass UI, Phase 4: Privacy & Polish, Phase 5: Packaging, Tasks for OneWeave MVP (Spec-Driven)

### Community 31 - "Community 31"
Cohesion: 0.29
Nodes (6): Analysis: 002-gamification — Cross-Artifact Consistency, Constitution Compliance (Cross-Check), Gaps / Recommendations (Pre-Implementation), Post-Implement Verification (Future), Spec → Tasks Coverage, Tasks → Spec Coverage

### Community 32 - "Community 32"
Cohesion: 0.29
Nodes (6): Ambiguity / Completeness, Checklist for 002-gamification Spec Quality Gate, Constitution & Philosophy Compliance, Next Gates, Requirements Quality, Scope & Focus

### Community 33 - "Community 33"
Cohesion: 0.29
Nodes (6): Additional notes, Checklist, Related, Screenshots / Loom visuals (if UI change), Summary, Type of change

### Community 34 - "Community 34"
Cohesion: 0.29
Nodes (6): 10+ Catchy, Tasty, Impactful Gamification Features, Core Retention Psychology (SDT + Fogg + Behavioral Design), Implementation Priorities (SDLC), OneWeave Gamification Ideation (Deep, Wide, Far), Subscription Model (Tasty + Ethical), "Tasty" Delight Elements (UX Psychology)

### Community 35 - "Community 35"
Cohesion: 0.38
Nodes (5): HistoryView, ModernHistoryRow, Color, String, TimelineEvent

### Community 36 - "Community 36"
Cohesion: 0.29
Nodes (6): Current State (Live Checks), Hardening Steps Completed / Proposed, OneWeave Privacy & Security Audit + Hardening (2026-06-24), Ongoing, Provider Training Controls (Must Be Set by User/Account), Recommended Config Additions (to apply)

### Community 37 - "Community 37"
Cohesion: 0.33
Nodes (5): Artifacts Delivered This Loop, OneWeave Iteration 1 Review (Plan-Build-Review Loop), Plan Summary (from review of current code vs spec), Review Against Spec & Journeys, What Was Built This Iteration

### Community 38 - "Community 38"
Cohesion: 0.60
Nodes (4): DataSeeder, LifeContext, ModelContext, TimelineService

### Community 39 - "Community 39"
Cohesion: 0.47
Nodes (3): SettingsView, LifeContext, UINotificationFeedbackGenerator

### Community 40 - "Community 40"
Cohesion: 0.40
Nodes (4): Core Principles, Non-Goals, OneWeave Constitution, Success Metrics

### Community 41 - "Community 41"
Cohesion: 0.40
Nodes (4): Journey 1: New Growth Goal in a Busy Season (Self → Care & Kin + Stewardship ripple), Journey 2: Subscription Leak Discovered (Stewardship → Self + Meaning), Journey 3: Low Energy + High Care Load (CareKin dominant → Self adjustment), OneWeave User Journeys (MVP Examples)

### Community 42 - "Community 42"
Cohesion: 0.50
Nodes (3): OnboardingView, AppState, String

## Knowledge Gaps
- **277 isolated node(s):** `Int`, `UUID`, `QuestStatus`, `Date`, `available` (+272 more)
  These have ≤1 connection - possible missing edges or undocumented components.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `SwiftData` connect `Community 9` to `Community 0`, `Community 35`, `Community 5`, `Community 6`, `Community 12`, `Community 18`, `Community 22`, `Community 27`?**
  _High betweenness centrality (0.119) - this node is a cross-community bridge._
- **Why does `TimelineEvent` connect `Community 0` to `Community 1`, `Community 3`, `Community 4`, `Community 7`, `Community 9`, `Community 13`?**
  _High betweenness centrality (0.045) - this node is a cross-community bridge._
- **Why does `SwiftUI` connect `Community 18` to `Community 0`, `Community 1`, `Community 35`, `Community 5`, `Community 6`, `Community 9`, `Community 42`, `Community 12`, `Community 22`, `Community 27`?**
  _High betweenness centrality (0.045) - this node is a cross-community bridge._
- **Are the 12 inferred relationships involving `TimelineEvent` (e.g. with `.transition()` and `.processEvent()`) actually correct?**
  _`TimelineEvent` has 12 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Int`, `UUID`, `QuestStatus` to the rest of the system?**
  _277 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.09358974358974359 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.08901515151515152 - nodes in this community are weakly interconnected._