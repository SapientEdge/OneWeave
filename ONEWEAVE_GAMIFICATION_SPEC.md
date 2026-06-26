# OneWeave Gamification Spec
**Version**: 1.0  
**Date**: 2026-06-26  
**Status**: Implementation-ready structured spec  
**Philosophy Alignment**: Event-driven ripples across Self / Stewardship / CareKin / Meaning. Calm technology (Weiser), digital minimalism, privacy-first local-only (SwiftData), purposeful real-life impact (IRL connections, caregiver relief, legacy building). Extends existing Journey Compass (dynamic rings, energy bars/trends, Active Ripples), TimelineService, LifeContext, Thread models (streaks, leaks/savings, tasks/IRL, stories/legacy), and state machine (idle/weaving/reflecting/lowEnergy/highFlow).  

**Core Constraints (Non-Negotiable)**:
- **Minimalism & Calm**: Subtle, peripheral, sophisticated restraint. No aggressive notifications, infinite scrolls, variable reward loops, dark patterns, or attention-hijacking. Gamification must *fade* and amplify authentic life events, not manufacture them (per whitepaper §3).
- **Privacy Zero-Trust**: 100% local SwiftData first. No cloud analytics, no training data. All processing on-device. User-controlled export/clear. Granular per-ripple privacy.
- **Real-Life Impact First**: Every mechanic prioritizes off-app actions (IRL meetups, caregiver respite, legacy sharing, resource redirects to analog). Screen time reduction is a feature. Success metrics: IRL actions logged/completed, caregiver hours relieved, legacy artifacts created/shared, cross-domain harmony scores.
- **Purposeful & Anti-Addictive**: Tied directly to event ripples. Rewards require reflection or real-world validation. Built-in friction and "exit ramps" to real life. No punitive streaks; restorative by design.
- **Math Quest Inspiration**: Fun, tasty, single-file-style lightness (HUD elements, power-ups/amps, mastery maps, journals, brain breaks, confetti-lite celebrations, explanations). But elevated to holistic, calm, meaningful – not pure game.
- **Builds on Prototype**: Extend Compass rings → weave tapestry; energy → harmony; existing streaks/savings/IRL/stories → core loops. TimelineEvent as the "action" that triggers gamified ripples.

**Success Metrics (Real Impact, Not Vanity)**:
- % of quests with logged IRL outcomes or reflections.
- Caregiver relief score (tasks delegated/completed, respite taken).
- Legacy entries created + "echoed" (revisited for meaning).
- Domain balance (variance across 4 threads low = high harmony).
- Mindful usage: sessions end with "Weave Complete → IRL prompt" rate; self-reported screen time reduction.
- Retention: meaningful return for reflection (not compulsion); premium conversion via demonstrated value (savings redirected, connections made).

---

## Overall Systems

### 1. Progression Framework: "Weave Level" + Thread Mastery
- **Global Weave Level** (1–∞, soft cap via seasons): Aggregate from balanced Essence earned + cross-domain coverage. Levels unlock peripheral visuals (deeper tapestry details), more active quest slots (3→6), advanced Compass filters, "Master Weaver" status at milestones (e.g., L10, L25).
- **Per-Thread Mastery Tiers** (4 tiers per domain: Novice / Weaver / Guardian / Luminary):
  - Tracked via accumulated domain-specific ripples + completions.
  - Passive perks (local rules): e.g., Self Luminary → auto-suggest habit stacking; Stewardship Guardian → better leak heuristics + redirect multipliers.
  - Visual evolution: Thread rings/icons subtly upgrade (leaf → sapling → oak for Stewardship; simple face → detailed portrait for Self; linked hands → circle for CareKin; book → illuminated manuscript for Meaning).
- **Ripple Harmony Score**: Live % balance across 4 domains (low variance = high score). Displayed in Compass WeaveSummaryView. High harmony triggers "High Flow" state + Essence bonus.
- **Implementation Notes**: Extend LifeContext with `weaveLevel: Int`, `mastery: [String: Int]` (domain → tier), `harmony: Double`. Compute on every TimelineEvent in `updateFromEvent`. Persist in SwiftData. Update existing Compass rings/energy bars to reflect mastery glows and harmony.

### 2. Economy: "Weave Essence" (Purposeful, Not Grindable Currency)
- **Earn**: +1–10 Essence per ripple event (base 1; +multipliers for IRL-validated quests, cross-domain chains, high-harmony actions, reflections logged). Bonuses for real impact (e.g., +5 for logged IRL CareKin connection with photo/note evidence stored locally).
- **Spend** (amplifiers only, never pay-to-win core features):
  - Thread Amplifiers (temporary 24–72h boosts: e.g., "Self Focus" doubles habit streak insight value; "Stewardship Redirect" auto-suggests 2x savings redirects).
  - Visual Customizations (minimalist): Subtle thread color accents, tapestry pattern variants (unlocked, not bought repeatedly).
  - Quest Forge tokens: Unlock one custom quest slot or re-roll suggestions.
  - "Echo" activations: Revisit old ripples for bonus Essence + new Meaning insights.
- **Sinks & Balance**: Essence decays gently on low-activity periods (encourages consistent real life, not daily login). No FOMO timers.
- **Implementation**: Add `weaveEssence: Double` (or Int) to LifeContext. New `EssenceTransaction` model (or lightweight array in context). Service methods: `awardEssence(for event: TimelineEvent, multiplier: Double)`. Subtle HUD in Compass header (like Math Quest but calm: "✧ 42 Essence" small, tappable for ledger). All local calculations.

### 3. Quests / Ripple Challenges Engine
- **Core Mechanic**: "Weave Quests" are structured prompts that, when completed, emit rich TimelineEvents with multi-domain linkedThreads and high ripple impact.
- **Types** (domain-tied + cross):
  - **Self Quests**: Habit stacks, micro-learning, energy restoration (e.g., "3-day body awareness practice").
  - **Stewardship Quests**: Leak hunts + redirects (e.g., "Audit one sub, redirect savings to analog experience").
  - **CareKin Quests**: IRL connection prompts, respite (e.g., "Schedule + complete one non-digital meetup or delegation; log outcome").
  - **Meaning Quests**: Story capture, legacy reflection (e.g., "Write/record one legacy memory; echo a past event").
  - **Cross-Weave Quests**: "Chain Reaction" (complete Stewardship redirect → triggers suggested CareKin + Meaning).
- **Structure**: Title, description (with explanation like Math Quest), domain tags, estimated IRL time, suggested actions, validation method (self-report + optional local photo/note/journal tie-in), base Essence reward, ripple multipliers.
- **Generation**: Rule-based + on-device Foundation Models (when enabled) for personalization from LifeContext + recent events. User can "forge" customs (premium or essence spend).
- **Flow**: Discover in Compass or dedicated Quests modal/tab. Accept → track in "Active Weaves". Complete → log action (emits event → ripples everywhere) + reflection prompt (required for full reward, per anti-addiction) + calm celebration (slow bloom animation + optional haptics).
- **Mastery Map**: Calm grid view (inspired by Math Quest) showing thread skills/badges. Tap to see related quests or review.
- **Implementation**: New `@Model` `WeaveQuest` (id, title, domains: [String], prompt, validationHints, rewardEssence, status, linkedEventId?). `QuestService` for generate/accept/complete (integrates TimelineService.emitEvent with quest metadata in payload). UI: Extend Compass with "Suggested Weaves" section; new modal or tab. Tie completions to existing Thread logic (e.g., CareKin quest updates task load).

### 4. Visuals & Feedback System (Subtle, Organic, Ripple-Centric)
- **Journey Compass Evolution**:
  - Central "Living Weave" visualization: 4 dynamic thread segments form an interconnected tapestry/loom. Activity pulses organic flowing lines (subtle particle or bezier paths, low-framerate, glass material).
  - Rings expand/contract by activity + mastery (existing). Add "stitch" density for Essence accumulated.
  - Energy bars → Harmony flows (color psychology: green high-harmony/flow, warm for balanced care, cool for meaning depth; avoid red overload).
  - Active Ripples: Enhanced list with visual "echo lines" connecting affected domains. Tap ripples to "echo" (replay insight + bonus).
- **Per-Thread Views**: Evolving icons + subtle embroidery-style badges (mastery). Tapestry panel in Meaning thread showing global weave growth.
- **Celebrations (Calm, Math-Quest-lite)**: On meaningful completion/chain: slow confetti of connection dots fading into tapestry (not flashy). Haptics (existing .sensoryFeedback). Explanations/toasts with "Why this ripple matters" (ties to philosophy).
- **Peripheral & Ambient**: StateMachineIndicator pulses on weaving. Live Activities/widgets for "Current Weave Harmony: 87%". Subtle color shifts on app open reflecting energy (no jarring).
- **Implementation**: Enhance existing `ThreadRingView`, `CompassView`, `WeaveSummaryView`. New `WeaveTapestryView` (Canvas or Shape-based for organic lines; performant). Use existing spring animations + add .symbolEffect for mastery. All SwiftUI, local.

### 5. Ripple Chain & Combo System (Core Event-Driven Fun)
- Events with `linkedThreads` trigger automatic or suggested follow-on ripples.
- **Combos**: 2+ cross-domain in short window = "Weave Combo" (multiplier on Essence, visual chain lighting in Compass, "Resonance" state boost).
- Example: Stewardship leak fixed (savings) → auto-suggest CareKin "redirect to shared experience" + Meaning "capture the value in a story".
- Ties directly to existing `processEvent` in threads and TimelineService.
- **Implementation**: In `TimelineService.emitEvent` or LifeContext update, detect chains via recent linked events. Award bonus + update visuals.

---

## 8–12 Concrete Gamification Mechanics & Systems

1. **Domain Thread Mastery Paths & Evolving Badges**  
   Tie: All 4 domains. Builds on existing Self streaks, Stewardship savings, CareKin tasks, Meaning stories.  
   Progression: Tiered mastery via cumulative ripples/completions. Perks unlock in suggestions.  
   Economy: Mastery milestones award Essence bursts.  
   Visuals: Badges "embroidered" on rings/tapestry; subtle evolution.  
   Quests: Mastery-specific challenges.  
   Anti-Addiction: Passive perks reduce need for constant checking.  
   Retention: Long-term "Luminary" prestige + history of growth.  
   Premium: Custom badge designs + deeper perk simulations.  
   IRL Impact: Mastery in CareKin/Meaning directly rewards real connections/legacy.

2. **Weave Essence Economy with Purposeful Amplifiers**  
   Tie: Ripples generate; spend reinforces domains.  
   Progression: Fuels higher Weave Levels.  
   Visuals: Subtle counter + transaction history (calm ledger in Settings/Compass).  
   Quests: High-reward quests pay more Essence.  
   Anti-Addiction: Decay on inactivity encourages life balance; no daily must-login.  
   Retention: Spend feels rewarding for real progress.  
   Premium: Higher earning rates or exclusive amplifiers.  
   IRL: Bonuses for validated real actions (e.g., caregiver respite logged).

3. **Cross-Domain Ripple Quests & Chains**  
   Tie: Explicit event ripples (e.g., Self goal ripples to CareKin load).  
   Progression: Chains build toward levels/harmony.  
   Visuals: Flowing lines in Compass on chain completion.  
   Quests: The core loop.  
   Anti-Addiction: Require reflection journal entry (like Math Quest Number Talk) for full credit. Brain-break integration post-completion.  
   Retention: Surprise cross-suggestions keep it fresh.  
   Premium: AI-personalized quest generation + "Forge" unlimited customs.  
   IRL/Caregiver/Legacy: Quests heavily bias toward scheduling IRL, delegating care tasks, capturing/sharing legacy stories.

4. **Legacy Tapestry & Echo System (Meaning-Focused)**  
   Tie: Meaning domain + ripples to others.  
   Progression: Tapestry "grows" with entries; unlocks global Weave Level boosts.  
   Economy: Echoing past ripples awards Essence + new insights.  
   Visuals: Dedicated tapestry canvas (stitches/patterns from stories/legacy events). Exportable.  
   Quests: "Story Arc" and "Echo" quests.  
   Anti-Addiction: Echoing is reflective, not compulsive; prompts real sharing (local only or opt-in private).  
   Retention: Revisiting creates emotional hooks and meaning.  
   Premium: Beautiful PDF/book exports of full Tapestry + family-shared legacy views (E2E private).  
   IRL/Legacy: Directly builds lasting artifacts and stories.

5. **CareKin Kinship Relief & IRL Connection Quests**  
   Tie: CareKin domain primary; ripples to all (e.g., reduced load frees Self/Meaning time).  
   Progression: Relief metrics feed harmony + mastery.  
   Economy: High Essence for completed IRL or delegated tasks.  
   Visuals: Connection nodes in tapestry; load bars that decrease on relief.  
   Quests: Respite scheduling, IRL prompts, shared family plans (with privacy).  
   Anti-Addiction: Prompts explicitly "close app, do the IRL thing now." Validation via outcome log.  
   Retention: Social proof via (opt-in) shared relief wins within private circles.  
   Premium: Advanced shared CareKin features (granular family weaves, predictive respite).  
   Real Impact: Directly targets caregiver burden (63M Americans) with relief tracking + suggestions.

6. **Stewardship Resource Redirects & Leak-to-Legacy Weaves**  
   Tie: Stewardship + ripples (savings free resources for Self habits, CareKin gifts, Meaning experiences).  
   Progression: Redirect streaks contribute to global level.  
   Economy: Savings amount influences Essence multiplier + redirect quests.  
   Visuals: "Flow arrows" from Stewardship ring to others in Compass.  
   Quests: "Leak Hunt + Redirect" series.  
   Anti-Addiction: Redirects are one-tap suggestions that encourage analog spending/time use.  
   Retention: Tangible wins (e.g., "You redirected $X to a real experience").  
   Premium: Detailed savings simulations + automated redirect tracking.  
   IRL: Explicitly redirects to real-life (meals with kin, legacy purchases, experiences).

7. **Self Habit Weave Streaks with Restorative Grace**  
   Tie: Self domain + energy restoration ripples.  
   Progression: Streak length + consistency → mastery + harmony.  
   Economy: Consistent streaks with reflection = bonus Essence.  
   Visuals: Existing streak counters evolve with "weave" visual (threads wrapping).  
   Quests: Streak-building with habit-stack cross-domain.  
   Anti-Addiction: "Grace" freezes (rest days don't break); "Restoration" quests for low energy. Built-in breaks. No guilt.  
   Retention: Ties streaks to bigger Meaning/Legacy narrative.  
   Premium: Advanced streak analytics + custom habit weavers.  
   IRL: Prompts body/mind practices that spill into real routines.

8. **Harmony-Driven "Weave Seasons" & Life Chapters**  
   Tie: All domains via balance.  
   Progression: Seasonal or chapter-based (user-defined life periods) collective goals.  
   Economy: Season completion awards large Essence + permanent unlocks.  
   Visuals: Seasonal overlay on tapestry/Compass (e.g., color themes for "Growth Season").  
   Quests: Season-specific cross-domain sets.  
   Anti-Addiction: Seasons have natural end + reflection closeout (forces pause).  
   Retention: Fresh content every quarter/life event; milestone celebrations.  
   Premium: Custom seasons + deeper historical chapter analysis.  
   IRL: Seasons can align with real calendar (holidays, caregiving phases) for legacy building.

9. **Subtle Power-Ups / Amplifiers as "Thread Tools"** (Math Quest Power-Ups Lite)  
   Tie: All domains.  
   Progression/Economy: Earn via Essence or mastery; temporary.  
   Examples: "Double Ripple" (next event affects 2 extra domains), "Shield" (protect streak/energy), "Magnifier" (deeper insight on log), "Redirect Lens" (Stewardship).  
   Visuals: Small tool icons in quick-capture or quest flows.  
   Quests: Unlock via quest chains.  
   Anti-Addiction: Time-limited, reflection-gated use. Not spammable.  
   Retention: Strategic use creates "tasty" moments without compulsion.  
   Premium: More tools or persistent versions.

10. **Reflection Journal + Number-Talk Style Explanations** (Core Anti-Addiction + Depth)  
    Tie: All (required for full rewards). Builds on existing journal/reflections.  
    Progression: Journaled reflections boost harmony/Essence.  
    Visuals: Integrated modal like Math Quest (emoji check-ins? calm version; strategy explanations).  
    Quests: Every quest ends with reflection prompt.  
    Anti-Addiction: **Mandatory** for max reward. Promotes mindfulness over mindless logging. Brain breaks between sessions.  
    Retention: Builds personal narrative and insights engine.  
    Premium: AI-assisted (on-device) reflection synthesis + searchable archives.  
    IRL: Reflections often prompt next real action.

11. **Ambient Peripheral Awareness & Gentle Retention Hooks**  
    Tie: State machine + ripples.  
    Examples: Widget/Live Activity "Current Harmony + One Suggested Weave". "Echo of the Week" (one past ripple resurfaced calmly). End-of-session "Weave Closed – One IRL bridge?" prompt.  
    Progression: Consistent use surfaces richer peripheral data.  
    Anti-Addiction: No badges for "opening app". Prompts to disengage. Usage dashboard shows "time well spent" vs total screen.  
    Retention: Low-friction re-entry via meaningful echoes/insights.  
    Premium: More widget depth, custom ambient themes.

12. **Mastery Map + "Strategy Journal" Review System** (Direct Math Quest Parallel)  
    Tie: All domains.  
    Visuals: Calm grid of skills/badges per thread (red for "review" like Math Quest, but sophisticated).  
    Functionality: Review past ripples/quests with explanations. Re-practice (re-echo) weak areas.  
    Anti-Addiction: Review mode is reflective; includes breathing/break elements.  
    Retention: Gamified self-review drives insight and growth loops.  
    Premium: Exportable mastery portfolios + advanced pattern detection.

---

## Anti-Addiction Design (Cross-Cutting Safeguards)
- **Friction by Design**: Confirmation + reflection step for rewards. "Close App & Act" buttons prominent.
- **Rest & Grace**: No broken-streak punishment. Low-energy states unlock restorative quests.
- **Usage Transparency**: On-device insights into app time vs. life impact. "Sabbath Weave" mode (reflection-only or read-only periods).
- **IRL Exit Ramps**: Every completion/quest strongly suggests and tracks a real-world bridge (existing defaultRealWorldBridge extended).
- **No Dark Patterns**: Transparent math for Essence/levels. No limited-time pressure. Opt-in everything.
- **Brain Breaks**: Integrate calm breathing or "pause" overlays (Math Quest style) after intense logging sessions.
- **Philosophy Guard**: All mechanics audited against whitepaper – if it creates artificial events or demands attention, redesign.

## Retention Hooks
- Gentle daily "One Meaningful Weave" (optional ritual, high-impact only).
- Weekly "Ripple Review" (auto-surfaced echoes + harmony trends).
- Surprise cross-domain synergies ("Your Stewardship win just unlocked a new CareKin insight").
- Progressive depth: Early use = simple; invested use = rich tapestry + personal narrative.
- Milestone celebrations tied to real life (e.g., "First legacy story shared IRL").

## Premium / Subscription Hooks (Value-First, Fatigue-Resistant)
- **Free Tier**: Full core (logging, basic Compass/ripples/energy, simple quests, streaks, local Essence, basic tapestry, all privacy features). Enough to deliver real value and demonstrate impact.
- **Weaver Premium (Monthly/Annual or One-Time Unlock)**:
  - Unlimited/custom quest forging + on-device personalized generation.
  - Advanced local analytics (ripple graphs, "what-if" simulations, long-term harmony trends, predictive suggestions).
  - Rich Tapestry exports (beautiful PDFs, printable legacy books, image exports).
  - Enhanced CareKin sharing (private family/group weaves with granular consent, E2E where possible via CloudKit sharing).
  - More amplifiers/tools, persistent mastery perks, custom visuals.
  - Priority/deeper Foundation Models usage for insights/quests (when opted in).
  - "Legacy Archive" advanced search + narrative generation.
- **Other**: Family/caregiver group plans (B2B relief for households/employers). One-time "Legacy Weaver" for exports. Value-based: "See X dollars redirected or Y connections made this month."
- **Positioning**: Premium accelerates *real* outcomes and beauty of your weave – never gates basics or creates FOMO. Aligns with research on avoiding subscription fatigue.

## Implementation Roadmap (Phased, Production-Ready)
**Phase 1 (MVP Calm Core – 2-4 weeks)**: Extend LifeContext/Timeline with Essence + mastery. Basic quest model + 4-6 starter quests. Enhance Compass rings with subtle tapestry lines + harmony. Add reflection step on completions. Integrate into existing flows. Test all local/privacy.
**Phase 2 (Visuals + Quests Polish)**: Full WeaveTapestryView. Mastery badges/evolutions. Quest modal + Mastery Map. Chain/combo detection. Calm celebrations. Anti-addiction prompts.
**Phase 3 (Economy + Depth)**: Essence spend UI + amplifiers. Echo system. Seasons. Premium feature flags (local toggles first).
**Phase 4 (IRL/Premium Polish + Retention)**: Validation flows (photo/journal tie-ins). Caregiver-specific relief tracking. Exports. Live Activities/widgets. Metrics dashboard (internal + user-facing impact view).
**Tech**: All additions as new models/services in existing SPM-style or direct in Sources/OneWeave. Reuse TimelineEvent emission heavily. New views compose with existing (Compass as hub). Haptics/animations consistent (spring, sensory). Full SwiftData queries. On-device only.

**Testing & Ethics**: Unit/integration for ripple propagation + calculations. User journeys that measure IRL outcomes. Ethical review: Does this increase authentic agency or screen time? Prototype with Math-Quest-style single-file web mock first for rapid iteration.

**Risks & Mitigations**: Over-gamification → strict calm audits + user toggles for "minimal mode". Privacy → zero external. Retention without addiction → focus on outcome metrics.

This spec is grounded in the existing prototype (Compass/Threads/Timeline/LifeContext/state machine), whitepaper philosophy, holistic research (minimalism, caregiver, IRL, privacy), and successful light gamification patterns (purposeful quests, explanations, breaks, mastery). Ready for direct implementation or further spec-kit decomposition.

*One interconnected weave. Gamification that disappears into a more purposeful life.*