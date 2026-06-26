# Spec: OneWeave Gamification & Retention Layer

## Overview
The Gamification & Retention Layer for OneWeave adds purposeful, calm, intrinsic-motivation systems that amplify the existing event-driven ripples across the four interconnected threads (Self, Stewardship, CareKin, Meaning). Core focus: **Quests** (structured high-impact challenges), **XP/Essence** (purposeful progression currency earned from real actions), **Visual Weave** (evolving Living Loom / Tapestry as the signature visual representation of life's interconnected progress), and **Streaks** (restorative consistency mechanics without guilt or addiction).

This layer integrates tightly with Journey Compass, TimelineService, LifeContext, AppStateMachine, and the four Threads. It makes the quiet work of living well visible and celebratory — without hijacking attention, manufacturing urgency, or increasing screen time. All mechanics originate from or enhance real TimelineEvents and state transitions (idle/weaving/reflecting/lowEnergy/highFlow). Gamification *disappears* into purposeful living.

Grounded in OneWeave Constitution: One Journey Not Silos, Privacy-First Zero-Trust, Calm Intelligence, Fluid Threads, Genuine Help Over Features, Plan Rigorously Build Real.

## Goals
- Provide visible, motivating feedback on cross-thread progress and mastery that feels earned through real-life actions.
- Increase retention via intrinsic motivation (autonomy, competence, relatedness) and eudaimonic well-being, not extrinsic compulsion or FOMO.
- Surface interconnections through visual weave, quests, and streaks that naturally encourage balanced living and IRL bridges.
- Enable meaningful reflection and celebration of life's "weave" (legacy, harmony, impact) with calm, sophisticated feedback.
- Support high retention through compounding value: users return because it helps them see and act on their one interconnected life, not because of addictive loops.

## Non-Goals
- Heavy social features, leaderboards, public sharing, or competitive elements.
- Punitive streaks, variable reward gambling mechanics, dark patterns, or attention-hijacking notifications.
- Pay-to-win or core-feature gating behind currency.
- Aggressive daily login requirements or manufactured urgency.
- Bloated game-like UI that pulls focus from the Compass and real life.
- Any external data, cloud analytics, or model training.

## User Needs
- "I want to see my daily efforts in Self, family, resources, and meaning come together visibly as one growing weave."
- "Give me purposeful challenges that connect to real actions (IRL meetups, legacy stories, resource redirects) without feeling like chores or games."
- "Help me build gentle consistency (streaks) that doesn't break me when life happens — I want grace and restoration."
- "Show progression and mastery in a beautiful, calm way that feels sophisticated and peripheral, not flashy or pressuring."
- "Earn a sense of growth (XP/Essence) that I can spend on amplifiers that actually help my real life weave better."

## Core Architecture Integration (No Tech Details)
- Driven exclusively by TimelineEvent emission → LifeContext aggregates (harmony, energy, mastery) → state transitions.
- Visual Weave evolves the existing Journey Compass rings into a Living Loom/Tapestry: interconnected flowing threads, stitches for accumulated progress, pulses for ripples.
- Quests are high-value structured prompts that, on completion (with required reflection), emit rich multi-linked TimelineEvents.
- Essence (XP) awarded on meaningful events/quests with multipliers for cross-domain, IRL validation, reflection, harmony.
- Streaks per-thread and global with restorative grace (low-energy periods or misses unlock gentle restoration paths instead of breaking).
- All systems respect LifeContext as single source of truth for progression state.
- Retention hooks: end-of-weave IRL prompts, echo revisits, seasonal chapters with reflection gates.

## Must-Have Features (Focused Scope)
- **Essence / XP System**: Lightweight currency earned from ripples and quests (base + multipliers). Spend only on temporary amplifiers, custom forges, echoes (revisits for insight). Gentle decay. Subtle HUD.
- **Weave Quests / Ripple Challenges**: Domain-tagged and cross-weave quests. Flow: discover → accept → complete with reflection gate + optional local evidence → emit event + calm celebration. Generation from context; mastery-map integration; heavy IRL bias.
- **Visual Weave / Living Loom**: Signature interactive visualization in Compass: 4 organic interwoven threads with pulses, stitch density for Essence/harmony, mastery embroidery evolution, ripple animations, harmony overlays, state-driven (highFlow lively vs lowEnergy muted). Tap to thread/echo.
- **Streaks with Restorative Grace**: Build on existing (e.g. Self habits). Grace periods, restorative quests instead of breaks. Visual stitching on weave. Ties to legacy narrative.
- **Thread Mastery Tiers & Perks**: Novice/Weaver/Guardian/Luminary per domain. Passive local perks. Visual evolution on loom/rings. Mastery Map view.
- **Ripple Chains / Resonance / Combos**: Auto/suggested follow-on ripples from linkedThreads; multipliers and visual chain lighting on weave.
- **Echo System**: Revisit past ripples for bonus Essence + new Meaning insights. Legacy Tapestry growth.
- **Harmony & Seasons**: Live domain balance score; user-defined seasons/chapters with closeout rituals and reflection gates.

## User Journeys (Key Examples)
- Stewardship leak redirect → auto-suggests CareKin respite quest + Meaning story capture (cross-weave chain, visual resonance on loom, Essence multiplier).
- Low energy Self + high CareKin load → restorative streak quest + harmony rebalance suggestion; visual weave softens and offers gentle options.
- Meaning legacy capture → ripples to Stewardship (redirect savings to experience) and CareKin (share with kin); updates mastery and tapestry.
- Daily weave complete → calm celebration + prominent "Close app and act IRL" with suggested real bridge.
See USER_JOURNEYS_ONEWEAVE.md for full cross-thread flows; integrate gamification into them.

## Acceptance Criteria
- Every quest completion emits a TimelineEvent with appropriate linkedThreads, affectsEnergy, and payload; ripples visible in Compass and other threads.
- Essence, mastery, harmony, streaks update live in LifeContext and reflect immediately in Visual Weave and HUD without lag or jank.
- Streaks use restorative grace: missed periods suggest restoration quests instead of reset; no guilt mechanics.
- Visual Weave is calm, organic, peripheral (subtle flows, low-framerate, color psychology per thread/state); does not dominate or demand attention.
- Reflection gate required for full Essence/celebration on quests (anti-addiction).
- All data local-only; no external calls for core gamification logic.
- Success metrics tracked internally (e.g., % quests with IRL log, harmony variance, disengagement rate) and surfaced privately.
- Users report feeling "my life is weaving together" and motivated toward real actions, not more app time.
- Follows all constitution principles: interconnected, privacy, calm, genuine value.

## Scope Notes
- Builds directly on existing prototype (Compass rings → weave, streaks/savings/IRL/stories in threads, state machine, TimelineService).
- MVP: Core Essence + Quests (5-7 starter templates per domain + cross) + basic Visual Weave evolution of Compass + Streaks grace + Mastery tiers (visual only first).
- Premium: Deeper forges, advanced echoes, custom visuals, richer analytics, seasonal exports.
- iOS native primary (SwiftUI Canvas for loom); consider parity with web PWA via HTML5 Canvas later.
- All generation rule-based + on-device where possible. No heavy AI for core loops initially.
- Anti-addiction and IRL-first are first-class requirements in every mechanic.

## Research & Alignment
- Addresses retention needs without compromising calm tech, minimalism, or real-life focus (2026 context: digital fatigue, caregiver burden, desire for meaning).
- Draws from Self-Determination Theory (autonomy/competence/relatedness), eudaimonia, Math Quest-style lightness (explanations, mastery maps, gentle confetti) but elevated to holistic purposeful level.
- Aligns with whitepaper: event-driven ripples, Weiser calm, privacy by design, state machine, interconnections.
- Grounded in existing ONEWEAVE_GAMIFICATION_SPEC.md, ONEWEAVE_GAMIFICATION_DESIGN.md, STATE_MACHINE.md, USER_JOURNEYS_ONEWEAVE.md, IMPLEMENTED_FEATURES.md, visual mocks.
- Success = real impact metrics (IRL logs, relief, legacy created+echoed, balanced harmony) over vanity (daily actives, streak counts).

This spec inherits the OneWeave Constitution and all global best practices. All downstream plan, tasks, and implementation must reference and comply with them. No tech stack or implementation details belong here.
