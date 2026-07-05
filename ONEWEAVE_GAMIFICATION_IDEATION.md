# OneWeave Gamification Ideation (Deep, Wide, Far)

**Philosophy tie-in**: From the white paper — life as one interconnected event-driven state machine of ripples. Gamification must feel purposeful (eudaimonic, not just hedonic), calm-sophisticated (peripheral awareness, non-intrusive per Weiser), anti-addictive, privacy-first, and IRL-biased. "Tasty" = satisfying micro-feedback that celebrates the weave without gamifying the human.

## Core Retention Psychology (SDT + Fogg + Behavioral Design)
- Autonomy: User chooses what/when to weave (no forced streaks).
- Competence: Visible mastery (levels, mastery trees per thread).
- Relatedness: Ripples show connection to self/others/legacy (even solo).
- Variable rewards: Random "Resonance" bonuses on big cross-thread ripples.
- Commitment devices: Gentle daily rituals with "Grace" (no guilt).
- Fresh start effect: Seasonal/Chapter resets.
- Social proof (private): "Your weave vs anonymous peers" (opt-in).
- Loss aversion: Streak "Echo" protection (restore with reflection).

Target: 30-60 day habit formation → emotional investment → subscription for "Master Loom" (deeper tools that feel celebratory, not paywalled core).

## 10+ Catchy, Tasty, Impactful Gamification Features

1. **Living Tapestry / Loom Canvas** (Visual centerpiece, already prototyped in PWA)
   - Every event adds a colored thread/knot/ripple to a growing, organic canvas (SVG/canvas or SwiftUI path).
   - "Tasty" feedback: Thread animates into place with satisfying "pull" sound/haptic, color bloom on cross-ripples, particles for big Essence gains.
   - Progression: Tapestry "blooms" or gains patterns at level milestones. Premium: Custom looms, export as art/print.
   - Retention: Users open just to "see how it grew." Catchy name: "Your Life Woven."

2. **Essence (XP) + Resonance System**
   - Essence from any weave (base + multipliers for streaks, cross-thread, IRL logs).
   - Resonance = rare bonus when ripple hits 3+ threads (feels magical).
   - Levels: Threadling (1-10) → Weaver (11-25) → Guardian (26-50) → Luminary (51+).
   - Tasty: Level-up "stitch" animation + unlock (new quest type, tapestry element, insight template).
   - Subscription hook: Master Loom = 2x Resonance, custom level titles, history graphs.

3. **Weave Quests (Daily/Weekly/Epic)**
   - Thread-specific + cross-thread. E.g.:
     - Self: "3 micro-habits with reflection gate."
     - Stewardship: "Audit one recurring cost + redirect."
     - CareKin: "One deep 1:1 + note the ripple."
     - Meaning: "Capture a legacy story from today."
   - Epic quests span seasons, unlock "Chapter" badges.
   - Tasty: Quest complete = visual thread "ties" into tapestry + Essence burst + toast with IRL prompt.
   - Retention: Variable daily quests keep it fresh. Premium: AI-suggested quests (opt-in, local-first fallback).

4. **Streaks with Grace + Echoes**
   - Daily "One Weave" ritual (morning capture or evening reflection).
   - Grace days (3-5/month) + "Restoration" mode (reflect to restore without breaking).
   - Echoes: Collectible streak "memories" (mini stories) that boost future Essence.
   - Catchy: "Flamekeeper" title for long streaks. Tasty UI: Flame grows, gentle pulse.

5. **Mastery Paths & Badges (Per Thread + Global)**
   - Trees: Self (Habit Weaver → Momentum Guardian), Stewardship (Resource Luminary), etc.
   - Badges with stories: "Ripple Maker" for first 3-thread weave.
   - Global: "One Life Weaver" for balanced mastery.
   - Tasty: Badge earn = full-screen subtle celebration + permanent tapestry mark.
   - Premium: Deeper trees, "Legacy Badges" shared privately.

6. **Ripple Multipliers & What-If Simulator (Premium tease)**
   - See potential future ripples from a choice (local sim).
   - "What if I wove this into Meaning?" — shows hypothetical tapestry growth.
   - Retention: Curiosity + foresight. Subscription unlocks full simulator + "Echo Chamber" (past ripple replays).

7. **Daily Rituals & Reflection Gates (Habit Formation)**
   - Morning: Suggested "First Thread."
   - Evening: 1-question reflection that "seals" the day + Essence.
   - Weekly: Ripple Review (auto-generated from events, user annotates).
   - Tasty: Ritual feels sacred/calm — beautiful minimal UI, optional guided audio (local).

8. **Essence Shop / Thread Patterns (Non-Pay-to-Win)**
   - Earned Essence buys cosmetic "patterns" (visual styles for tapestry) or "amplifiers" (temporary multipliers).
   - Subscription: Unlimited + exclusive patterns, "Forge" custom ones.

9. **Kin & Community Weaves (Private/Opt-in)**
   - Invite kin to "co-weave" a shared thread (local sync or manual).
   - Anonymous "Weave Circles" (opt-in global stats: "Your streak is in top 12% of reflective users").
   - Tasty: Shared tapestry elements bloom when both log.
   - Subscription: Group Loom features, private family exports.

10. **Chapter Closes & Legacy Archives**
    - Seasonal "Chapter" summaries (auto + user notes) that "bind" into your tapestry.
    - Beautiful PDF exports ("Legacy Scroll") — premium makes them art-book quality with custom art.
    - Retention hook: "What will your next Chapter say about you?"

## Subscription Model (Tasty + Ethical)
- **Threadling (Free)**: Full core weaving, basic quests, 1-month history, core tapestry.
- **Weaver / Master Loom ($6.99/mo or $69/yr)**: Unlimited history, advanced analytics/simulator, custom looms/patterns, rich exports, AI quest help (opt-in, local fallback), streak boosters.
- **Luminary Legacy (one-time or higher tier)**: Physical book pipeline, unlimited KinShares, custom designers.
- Value demo in onboarding: "See what a 30-day weave looks like" (sample tapestry).
- Anti-churn: Graceful degradation, "pause" mode, clear "why premium" (celebration of your life, not gates).

## "Tasty" Delight Elements (UX Psychology)
- Satisfying micro-interactions: Thread "pull" animation on weave, soft bloom on ripple, confetti only on meaningful milestones (not spam).
- Sound design (subtle loom "pull" or chime — opt-in, calm).
- Haptics on iOS for every Essence gain.
- Progressive disclosure: Core free feels complete and delightful; premium feels like an upgrade to your celebration.
- "Aha" moments: "Your CareKin weave boosted your Self streak — here's the ripple."

## Implementation Priorities (SDLC)
- Phase 1: Visual Tapestry + Essence + basic Quests (PWA + iOS prototype).
- Phase 2: Streaks, Mastery, Reflection Gates.
- Phase 3: Premium tiers, simulator, exports.
- Always: Local-first, semgrep + privacy audit on every change, graphify for context.

This makes OneWeave not another tracker — a living, rewarding story you can't wait to add to tomorrow. Users subscribe because it helps them *see and celebrate* the life they're already living.

Next: Wire into iOS via subagent, expand PWA with p5.js shaders for even tastier visuals, full Spec Kit 002.