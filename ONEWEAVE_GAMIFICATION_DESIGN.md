# ONEWEAVE_GAMIFICATION_DESIGN.md

**OneWeave: Weave Your Ripples. Master Your One Life.**  
**Gamification Design Spec v1.0**  
**Date**: June 26, 2026  
**Status**: Design-ready, implementation-paths detailed  
**Core Philosophy**: Life as an event-driven state machine of interconnected ripples across four threads — **Self**, **Stewardship**, **CareKin**, and **Meaning**. Gamification that *disappears* into purposeful living. Calm technology (Weiser), privacy-first local-only, real-world impact first. Builds directly on existing **Journey Compass**, **AppStateMachine**, **TimelineService**, **LifeContext**, **4 Threads**, and ripple propagation.

> *"Catch a ripple. Watch the weave grow. Stitch meaning into legacy. OneWeave turns the quiet work of living well into visible, celebratory progress — without ever hijacking your attention."*

---

## 1. Design Principles & Non-Negotiables (The Loom Rules)

Gamification in OneWeave must **amplify authentic life**, never manufacture fake urgency or dopamine loops.

- **Local-Only & Privacy-First (Zero-Trust)**: 100% on-device. SwiftData (iOS) / IndexedDB + localStorage (PWA). No telemetry, no cloud analytics, no model training on user data unless explicit opt-in + redaction. User owns the full export/clear/unweave. Per-ripple consent flags possible in future.
- **Calm & Sophisticated Restraint**: Subtle animations, peripheral awareness, glass materials, spring physics, color psychology (flow greens, warm care, deep meaning violets, steward teals). No red overloads, infinite scrolls, variable-ratio gambling, or pushy badges. Feedback fades into the background.
- **Purposeful & IRL-First**: Every reward/quest/mechanic biases toward real-world bridges (IRL meetups, caregiver respite, legacy sharing, resource redirects to analog experiences). Screen-time reduction is a win metric. "Close app & weave in the real world" is a first-class action.
- **Ties to Core Architecture**:
  - All gamification driven by `TimelineEvent` emission → `LifeContext.updateFromEvent()` → ripple aggregation + state transitions.
  - States: `idle` → `capturing` → `weaving` → `reflecting` | `lowEnergy` | `highFlow`.
  - Compass is the **central loom hub**; threads update live.
- **Retention via Intrinsic Motivation** (Self-Determination Theory + Eudaimonic Well-being): Autonomy (full local control + custom forges), Competence (visible mastery growth tied to real impact), Relatedness (CareKin connections + shared legacy echoes). No extrinsic punishment or FOMO.
- **Anti-Addictive by Design**: Mandatory reflection gates for full rewards. Grace periods (no broken streaks). "Weave Complete → IRL prompt". Brain-break pauses. Usage transparency ("time well spent" vs total). Seasons/chapters with natural closeouts.

**Success Metrics (Real Impact, Not Vanity)**: % quests with logged IRL outcomes; caregiver relief hours; legacy artifacts created + echoed; cross-domain harmony (low variance); mindful disengagement rate; retention via meaningful returns (not compulsion).

---

## 2. The Four Threads (The Warp & Weft)

Recap for design context (from whitepaper + STATE_MACHINE + prototype):

1. **Self** — Habits, streaks, energy, body/mind awareness. Ripples: personal wins → stewardship time freed or care capacity.
2. **Stewardship** — Time, money, resources, leaks/savings, legacy planning. Ripples: savings → CareKin gifts or Meaning experiences.
3. **CareKin** — Relationships, tasks, IRL connections, respite, kinship (family, friends, community, pets, planet). Ripples: reduced load → Self restoration + Meaning stories.
4. **Meaning** — Stories, legacy, purpose, narrative coherence, echoes of the past. Ripples: insight → re-prioritizes all threads.

Every TimelineEvent carries `thread`, `type`, `payload`, `linkedThreads[]`, `affectsEnergy`, `summary`. This is the single source of truth for all gamification.

---

## 3. 12+ Core Gamification Features (Catchy Names + Deep Design)

### 1. Essence — The Currency of Ripples (XP System)
- **What**: Lightweight purposeful "Essence" (✧) earned from any ripple event. Base 1–5 + multipliers for cross-domain chains, IRL validation, high-harmony actions, reflections.
- **Earn**: Automatic on `emitEvent`. Bonuses: +quest completion, +real evidence (local photo/note), +combo chains.
- **Spend** (Amplifiers only — never pay-to-win core): Thread Tools (see #11), custom quest forges, "Echo" activations (revisit old ripples for insight + bonus), subtle visual customizations (thread accent colors, tapestry density).
- **Decay & Balance**: Gentle passive decay on prolonged low activity (encourages life rhythm, not login compulsion). No daily streaks required.
- **Visual**: Small elegant HUD in Compass header (like the visual mock): `✧ 142 Essence • L11`. Tappable ledger.
- **Psychology**: Competence feedback loop. Feels earned because tied to real events.
- **Retention**: Visible accumulation fuels "one more meaningful weave" without pressure.

### 2. Weave Level & Global Progression
- Aggregate from balanced Essence + harmony coverage + milestone completions.
- Unlocks: Deeper Loom details, more active quest slots (3 → 6+), advanced Compass filters/echoes, "Master Weaver" titles at L10, L25, L50.
- Soft seasonal caps to prevent burnout.

### 3. The Living Loom / Weave Canvas (Signature Visual Feature)
- **The Heart of OneWeave**: Evolution of Journey Compass rings into an **interactive, organic Living Loom** (or "Tapestry").
- **Design**:
  - Central circular/elliptical canvas showing 4 interwoven threads as flowing, organic lines/stitches (bezier or particle paths).
  - Threads pulse, thicken, or glow on activity/mastery (Self: warm violet accents; Stewardship: teal/earth; CareKin: golden/amber; Meaning: deep indigo).
  - "Stitches" density represents accumulated Essence/harmony in that domain.
  - Ripple lines animate outward on new events (subtle, low-framerate, infinite but calm loop).
  - Mastery evolution: Icons/badges "embroider" onto the threads (Novice simple knot → Luminary illuminated flourish).
  - Tap any thread segment → deep link to ThreadDetail + "echo" view.
  - Harmony overlay: Overall % + flowing connection lines between threads when combos fire.
- **States Integration**: Canvas subtly shifts palette/speed on `highFlow` (lively flow) vs `lowEnergy` (gentle, muted, restorative suggestions).
- **iOS**: SwiftUI `Canvas` + `Shape` + `TimelineView` or custom `Path` + particle system (or SpriteKit lite if perf needed). Reuse/enhance `ThreadRingView` + add `WeaveTapestryView`.
- **PWA**: HTML5 `<canvas>` + 2D context (or SVG + CSS animations for accessibility). JS `LoomRenderer` class mirroring Swift logic. RequestAnimationFrame for gentle pulses.
- **Mock Reference**: See existing `GAMIFICATION_VISUAL_MOCK.html` and PWA header with weave elements.
- **Fun/Catchy**: "Watch your life stitch itself together in real time."

### 4. Thread Mastery Badges & Per-Thread Paths
- 4 tiers per thread: **Novice → Weaver → Guardian → Luminary**.
- Tracked by cumulative domain ripples + validated completions + harmony contribution.
- **Passive Perks** (local rules, no UI nag): Luminary Self auto-suggests better habit stacks; Guardian Stewardship improves leak detection + redirect multipliers.
- **Visuals**: Evolving embroidered badges on rings/Loom. Thread icons grow (face → portrait; leaf → oak; hands → circle of kin; book → glowing manuscript).
- **Mastery Map**: Calm grid view (Math Quest inspired but serene) — tap for review quests, explanations, re-echo practice.
- **Ties**: Updates in `LifeContext.masteryTiers` on every relevant event.

### 5. Weave Quests / Ripple Challenges
- Structured, high-impact prompts that emit rich multi-thread TimelineEvents.
- **Types** (domain-biased + cross):
  - Self: Habit-stack practices, energy restoration.
  - Stewardship: Leak hunts + redirects to analog.
  - CareKin: IRL meetup scheduling + outcome logging; respite delegation.
  - Meaning: Legacy story capture + echo.
  - Cross: "Chain Reaction" (fix leak → triggers CareKin + Meaning quest).
- **Flow**: Discover (Compass "Suggested Weaves" or Quests tab) → Accept (moves to Active) → Complete with **required reflection** (anti-addiction) + optional local evidence → Emit event + calm celebration (slow bloom + haptics) + full Essence.
- **Generation**: Rule-based from LifeContext + recent events. On-device personalization (later Foundation Models opt-in). Users "Forge" customs (Essence or Premium).
- **Mastery Map Integration**: Quests filtered/suggested by current mastery gaps.
- **IRL Bias**: Heavy emphasis on scheduling + logging real outcomes. "Close the app now" prominent CTA.

### 6. Streak Weaves with Restorative Grace
- Per-thread + global "Weave Streaks" (builds on existing Self streaks, CareKin task consistency, etc.).
- **Grace**: Missed days or lowEnergy periods don't break streaks (restorative quests instead). "Restoration" mode unlocks gentle quests.
- **Visual**: Threads wrapping the rings/Loom; progress "stitched" lines.
- **Psychology**: Encourages consistency without guilt. Ties streaks to bigger legacy narrative.
- **Premium**: Advanced analytics + custom weaver suggestions.

### 7. Ripple Resonance & Combo Rewards
- **Core Event-Driven Fun**: Cross-domain `linkedThreads` in short windows trigger "Resonance" combos.
- 2+ domains = multiplier on Essence, visual chain-lighting on Loom (glowing connection stitches), temporary "High Flow" state boost.
- Example: Stewardship redirect → auto-suggested CareKin respite + Meaning capture.
- Auto or gently suggested follow-ups. "Your Stewardship win just unlocked a CareKin insight!"

### 8. Echo System & Legacy Tapestry (Meaning Superpower)
- Revisit ("Echo") past ripples/stories for bonus Essence + fresh insights.
- Full Tapestry canvas view: stitches/patterns grow from all legacy/Meaning events + cross ripples. Exportable (PDF/book in premium).
- "Story Arcs" and seasonal legacy reviews.
- Retention hook: Emotional revisiting creates narrative identity.

### 9. Kinship Relief & IRL Connection Engine (CareKin)
- Specialized relief tracking: tasks delegated, respite taken, IRL logged (photo/note optional).
- High Essence + harmony for validated connections.
- Load bars decrease visibly on relief; nodes light up in Loom.
- Premium: Private family/group weaves (granular, E2E via CloudKit where opted).

### 10. Leak-to-Legacy Redirects (Stewardship)
- Leak detection (existing) → "Redirect Lens" suggestions (time/money → Self habit, CareKin gift, Meaning experience).
- Flow arrows in Compass/Loom from Steward thread to others.
- Tangible wins logged: "You redirected $XX to a real family dinner."

### 11. Thread Tools & Amplifiers ("Power-Ups" — Math Quest spirit, calm execution)
- Temporary (24-72h) or single-use: Double Ripple, Streak Shield, Insight Magnifier, Redirect Lens, Harmony Lens.
- Earn via Essence, mastery milestones, or quest chains.
- Gated by reflection. Not spammable.
- Visual: Small elegant icons in capture/quest flows.

### 12. Harmony Seasons & Life Chapters + Reflection Gates
- User- or auto-defined seasons (e.g., "Caregiving Chapter", "Growth Season"). Collective cross-domain goals.
- Natural closeout rituals with big Essence + chapter reflection.
- **Reflection Gates**: Every major reward/quest requires a short "Number Talk"-style explanation or journal note for *full* credit. Builds depth and anti-mindless-logging.
- Mastery review system with explanations.

**Bonus 13th: Ambient Retention & Peripheral Hooks**
- Widgets/Live Activities: "Current Harmony 87% • One Suggested Weave".
- "Echo of the Week" calm resurfacing.
- End-of-session: "Weave complete. One IRL bridge?"
- Sabbath/Read-only modes.

---

## 4. Retention Psychology & Onboarding Hooks

### Retention Psychology (Evidence-Based, Calm)
- **SDT Core**: Autonomy (you control the weave), Mastery/Competence (visible growth + perks that actually help real life), Relatedness (CareKin + legacy sharing).
- **Eudaimonia over Hedonia**: Rewards tied to meaning-making and real impact, not endless points. Reflection promotes integration.
- **Progress & Visualization**: Loom growing feels like "building something lasting" (tapestry metaphor powerful for identity).
- **Variable but Predictable**: Ripple multipliers feel exciting yet fair and transparent.
- **Spaced & Seasonal Freshness**: Prevents habituation.
- **Disengagement as Feature**: Prompts to exit, usage insights showing "life impact", analog mode.
- **Loss Aversion Used Gently**: "Protect your harmony" via restorative paths, not punishment.
- **Social Proof (Private)**: Opt-in family echoes or relief shares within trusted circles only.

**Gentle Daily/Weekly Rituals**:
- "One Meaningful Weave" (optional high-impact only).
- Weekly Ripple Review (auto-surfaced).
- Surprise synergies keep it alive.

### Onboarding Hooks (5–7 Minute "First Weave" Magic)
- **Page 1**: "You are already weaving." Metaphor intro + 4 threads visual.
- **Page 2**: Live demo — quick capture a sample ("Morning walk") → watch full ripple propagation + state change on Compass (uses existing OnboardingView + state previews).
- **Page 3**: First Quest seed (pre-loaded simple cross-domain) → complete with reflection example.
- **Page 4**: Loom/Tapestry intro + "plant your first stitch".
- **Page 5**: Privacy commitment + "Your data, your loom."
- **Page 6 (optional)**: Sample journeys (from USER_JOURNEYS_ONEWEAVE.md).
- **Hook Mechanics**: Immediate visible reward (Essence burst + small mastery tick). "Your first ripple just touched all four threads!" Celebration is calm but delightful (slow particle stitch + explanation why it matters).
- **Post-Onboarding**: Gentle "Forge your first custom quest" nudge. Default to Compass as home.

Existing `OnboardingView.swift` already primes state machine beautifully — extend it with gamification elements (Essence teaser, mini-loom preview).

---

## 5. Subscription Tiers — "Tasty Premiums" (Value-First, Fatigue-Resistant)

**Threadling (Free — Fully Capable)**:
- Core logging, basic Compass + rings + energy, simple quests (limited slots), basic streaks, local Essence tracking, basic Loom visualization, all privacy/export tools, reflection gates.
- Enough to feel the magic and see real IRL impact.

**Weaver (Monthly / Annual / One-time Unlock)**:
- Unlimited + custom quest forging + on-device personalized generation.
- Advanced local analytics (harmony trends, "what-if" simulations, pattern detection, predictive gentle suggestions).
- Rich Tapestry/Loom exports (beautiful PDFs, printable legacy books, high-res images, family-ready).
- Enhanced CareKin: private KinShare (granular family weaves).
- More Thread Tools + persistent mastery perks.
- Deeper on-device model usage (opt-in Foundation Models for quests/insights).
- Legacy Archive search + narrative synthesis.
- Custom visual accents + seasonal themes.

**Luminary Legacy (Higher Tier or Add-on)**:
- Everything above + priority features, advanced chapter analysis, caregiver group plans (B2B relief dashboards for households), one-tap beautiful physical-book export pipelines (local generation), custom badge/loom skin designers, unlimited echoes + deep history.

**Positioning & Psychology**:
- Premium accelerates *beauty and real outcomes* of your weave — never gates the core journey.
- "Tasty" premiums: tangible delights (gorgeous exports you actually print/share, family connection tools, time-saving insights that free real hours).
- Avoids fatigue: Strong free tier demonstrates value first. Upgrades feel like "reward for the weave you've already built."

---

## 6. Implementation Paths

### iOS Swift (Native, Production-Grade)
**Models (additive to existing)**:
- Extend `LifeContext` (or new lightweight `@Model` aggregates): `weaveEssence`, `weaveLevel`, `masteryTiers: [String: Int]`, `harmonyScore`, `season`, `tapestryStitches`.
- New `@Model` `WeaveQuest` (id, title, prompt, domains[], baseEssence, status, accepted/completed, reflectionNote, linkedEventID, evidence).
- Extend `TimelineEvent` if needed for quest metadata (or use payload).
- Optional `EssenceTransaction` log for ledger.

**Services**:
- `QuestService` (observable) — generate (rule + context), accept, complete (reflection gate + emitEvent + award + mastery update).
- Enhance `TimelineService.emitEvent` to detect chains/combos and award bonuses.
- `HarmonyCalculator`, `MasteryEngine` (pure functions or extensions on LifeContext).

**UI**:
- `WeaveTapestryView` / `LivingLoomCanvas` (SwiftUI Canvas) — compose into CompassView header or dedicated modal.
- Enhance existing `CompassView`, `ThreadRingView`, `WeaveSummaryView`, `StateMachineIndicator` with mastery glows, stitch counts, resonance animations.
- New Quests tab or sheet + MasteryMapView.
- Integrate into `ThreadDetailView` (quest suggestions per thread).
- Use `@Environment(AppStateMachine)` for state-driven theming.
- Haptics: `.sensoryFeedback`, UINotificationFeedback on weaves/completions.
- Widgets / Live Activities for peripheral hooks.
- All via SwiftData queries; full offline.

**State Integration**:
- `updateFromEvent` calls harmony/mastery/essence calcs.
- State transitions trigger visual feedback on Loom.

**Phased Rollout** (from existing SPEC.md):
- Phase 1: Essence + mastery + basic quests + reflection + Compass updates.
- Phase 2: Full Loom Canvas + badges + chains + mastery map.
- Phase 3: Tools, echoes, seasons, exports.
- Phase 4: Polish, widgets, premium flags (local first), IRL validation flows.

**Testing**: Prototype journeys extended; unit tests for ripple math + mastery; ethical/UX review against whitepaper.

See `Sketch_GamificationExtensions.swift` for starter code patterns.

### Web PWA (Offline-First, Mirror Experience)
**Tech Stack** (match existing PWA):
- Vanilla JS/TS + Tailwind (or minimal framework) + HTML5 Canvas/SVG.
- IndexedDB (via idb or native) for full models (LifeContext, Threads, Events, Quests) — mirror SwiftData schema.
- Service Worker for full offline + "installable".
- Local state machine class mirroring `AppStateMachine` (with same states/transitions).

**Key Components**:
- `LoomRenderer.js`: Canvas 2D (or three.js lite for 3D feel if wanted, but keep simple 2D for calm/perf). Draw 4 threads as paths, animate ripples on event emit, update stitch density, mastery badges as overlaid SVGs or paths.
- React to simulated "emitEvent" that updates central store → re-renders Compass + Loom + thread cards.
- Quest engine in JS: same rule-based generator + completion flow with reflection modal.
- HUD: Level, XP/Essence bar, Harmony % (already partially in PWA).
- Local "export JSON" + beautiful print/PDF via browser APIs.
- Analog Mode toggle (already sketched) that emphasizes IRL prompts.
- Premium simulation: Feature flags + local "unlock" (real payments later via Stripe or one-time).

**Data Flow**:
- Central `store.js` or class holding context + events array.
- On "action" (capture, complete quest): create event object → process ripples (update context, detect links, award) → persist → re-render everything (including state indicator).
- Mirror Swift logic exactly for consistency (users switching platforms see same weave).

**Polish**:
- Match iOS colors/feel: calm glass, serif headings (Playfair), soft shadows.
- Animations: CSS + Canvas RAF for organic flow (reuse particle ideas from mock).
- Responsive: Excellent on mobile web.
- Persistence: Auto-save on every change.
- Premium simulation: Feature flags + local "unlock" (real payments later via Stripe or one-time).

**Deployment**: Static hosting (Vercel/Netlify) or as deliverable single HTML + assets for rapid prototyping.

**Parity Path**: Start by porting key logic from Swift sketches + existing PWA HTML/JS. Use the `GAMIFICATION_VISUAL_MOCK.html` and `oneweave-pwa.html` as base.

---

## 7. Visual Language & Celebration Design (Fun + Purposeful)

- **Palette**: Warm earth + sophisticated jewel tones (per mocks): Self violet, Stewardship forest/teal, CareKin amber/gold, Meaning indigo. Accents in warm neutrals.
- **Typography**: Elegant sans + occasional serif for "legacy" moments.
- **Celebrations**: Slow, blooming stitches or gentle particle "connection dots" that settle into the Loom. Soft haptics. Explanatory toasts: "This ripple touched Meaning because...".
- **Empty/Zero States**: Beautiful "First stitch awaits" loom illustrations with gentle prompts.
- **IRL Emphasis**: Prominent leaf/analog icons, "Bridge to real life" CTAs.

Existing mocks already nail the calm-premium aesthetic — extend them.

---

## 8. Risks, Mitigations & Ethics

- **Over-gamification**: Strict calm audits every phase. "Minimal mode" toggle. User testing focused on "does this increase presence or screen time?"
- **Privacy Leaks**: All local. Audits (see existing PRIVACY_AUDIT). No external calls in core paths.
- **Addiction**: Reflection gates, grace, disengage prompts, real-impact metrics as north star.
- **Cultural/Individual Fit**: Editable thread weights + seasons. Philosophy guardrails in design reviews.
- **Scope Creep**: Phase strictly. Start with Essence + basic Loom + 6 quests.

---

## 9. Roadmap & Next Steps

1. **Immediate**: Wire Essence + mastery into LifeContext + one sample quest + reflection gate (extend Sketch + existing prototype).
2. **Design Handoff**: Flesh Loom Canvas specs + Figma/SwiftUI explorations. Update visual mocks.
3. **iOS**: Implement `WeaveTapestryView` + QuestService + UI integrations.
4. **Web**: Enhance PWA with full JS loom + quest engine + IndexedDB parity.
5. **Polish**: Seasons, echoes, premium flags, widgets, exports.
6. **Validation**: Run full user journeys with gamif layered on. Measure IRL outcomes.

**References**:
- Existing: `ONEWEAVE_GAMIFICATION_SPEC.md`, `STATE_MACHINE.md`, `GAMIFICATION_VISUAL_MOCK.html`, `oneweave-pwa.html`, `USER_JOURNEYS_ONEWEAVE.md`, `OnboardingView.swift`, `CompassView.swift`, whitepaper.
- Math Quest inspiration for lightness + explanations + power-ups (elevated to calm holistic).
- Calm Tech (Weiser), SDT, Care Ethics, positive psychology.

---

*One life. Woven deliberately. Gamification that serves the weave — and then steps aside.*

**See the ripples. Live the story. Master the loom.**

---

**Document Info**  
- Version: 1.0 (expands on prior SPEC with full design, psych, onboarding, dual-platform impl paths, 12+ detailed features)  
- Aligned with: OneWeave whitepaper, prototype architecture, privacy-by-design  
- Ready for: Spec-kit decomposition, implementation, or multi-agent execution

---

## Appendix: Quick Feature Summary Table

| Feature                  | Core Tie                  | Key Psychology       | Premium Tasty Bits              | Visual Hook          |
|--------------------------|---------------------------|----------------------|---------------------------------|----------------------|
| Essence XP               | TimelineEvent             | Competence           | Higher earn rates               | HUD + ledger         |
| Living Loom Canvas       | Compass + State           | Progress + Autonomy  | Custom skins + exports          | Central interactive  |
| Mastery Badges           | Per-thread accum          | Mastery              | Custom designs + sims           | Evolving embroidery  |
| Quests & Chains          | emitEvent + linked        | Purpose + Relatedness| Unlimited forge + AI gen        | Suggested + Active   |
| Streaks w/ Grace         | Thread logic              | Consistency w/o guilt| Analytics + weavers             | Wrapped threads      |
| Resonance Combos         | linkedThreads detection   | Surprise + Flow      | Deeper multipliers              | Glowing connections  |
| Echo + Legacy Tapestry   | Meaning + History         | Narrative Identity   | PDF books + family views        | Growing stitches     |
| Kin Relief + IRL         | CareKin                   | Relatedness          | Group shares                    | Load nodes           |
| Leak Redirects           | Stewardship               | Agency               | Simulations                     | Flow arrows          |
| Thread Tools/Amps        | Economy + Quests          | Strategy             | Persistent versions             | Tool icons           |
| Seasons + Chapters       | Harmony + Context         | Freshness + Closure  | Custom chapters                 | Themed overlays      |
| Reflection Gates         | All rewards               | Depth + Mindfulness  | AI synthesis                    | Journal modal        |
| Subscription Tiers       | All                       | Value demonstration  | See above                       | Feature flags        |

*Build the loom. Weave on.*