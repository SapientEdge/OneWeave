# ONEWEAVE_MONETIZATION_RETENTION.md

**OneWeave: Weave Your Ripples. Master Your One Life.**  
**Monetization & Retention Strategy v1.0**  
**Date**: June 26, 2026  
**Status**: Strategy-ready, aligned with Gamification Design, Whitepaper, and prototype  
**Core Philosophy**: Calm, purposeful freemium that amplifies authentic living. Premiums are "tasty" delights that accelerate beauty, insight, and legacy — never gates to the core weave. Privacy-first, local-only, gamification that fades into real-world impact. Builds directly on Essence (✧), Living Loom/Tapestry, Mastery tiers (Novice → Luminary), Quests, Echoes, Streaks-with-Grace, and Ripple Resonance.

> *"Premium is the beautiful loom that helps you see and celebrate the weave you've already built — not the thread you must buy to live well."*

---

## 1. Freemium Model Overview

OneWeave uses a **generous freemium** foundation with strong free-tier value that demonstrates real IRL impact (ripples, harmony, redirected resources, logged connections). This builds trust, habit formation, and natural upgrade desire.

**Guiding Principles**:
- **Never pay-to-win core progress**: Essence, basic Loom visualization, quest completion, mastery tracking, and ripple propagation are fully available free.
- **Tasty Premiums**: Tangible delights — gorgeous exports you actually print and gift, advanced local analytics that save real hours, custom creative tools, opt-in AI assistance for personalization.
- **Value-First Conversion**: Users experience the magic first (onboarding + 1-2 weeks of weaves). Upgrades feel like a reward for the life you're already weaving.
- **Hybrid Packaging**: Recurring (monthly/annual subs for ongoing value) + one-time unlocks (Legacy Weaver Packs for exports/books).
- **Local-First Enforcement**: All premium flags are on-device (UserDefaults/SwiftData or IndexedDB). Real payments later via App Store / Stripe. Demo unlocks simulate in PWA.
- **Anti-Dark Patterns**: No forced trials that auto-charge, no manipulative scarcity, transparent value metrics ("This quarter you redirected $X and created Y legacy echoes").

**Success North Star**: Retention through *meaningful returns* (users come back to reflect, not compulsively check). Premium conversion via demonstrated outcomes, not FOMO.

---

## 2. Tasty Premium Tiers (Master Loom Focus)

### Threadling (Free — Fully Capable Base)
- Core event capture, Timeline, Journey Compass (rings + energy + basic Active Ripples).
- Basic Living Loom visualization (static or simple animated stitches).
- Limited quests (e.g., 3-5 active slots, rule-based generation only).
- Basic streaks with Grace periods, local Essence tracking & simple ledger.
- Full privacy tools, export JSON, reflection gates, IRL prompts.
- Mastery badges (visual only, basic tiers).
- Enough to feel interconnected magic and log real-world bridges.

**Positioning**: "Weave freely. See the ripples. Build the foundation."

### Weaver / Master Loom (Primary Paid Tier — Monthly $X.99 / Annual $Y / One-time Legacy Unlock)
Unlocks the "Master Loom" experience — the premium heart of creative and insightful weaving.

**Key Unlocks** (tied directly to gamification):
- **Master Loom Canvas**: Fully interactive, high-fidelity Living Loom/Tapestry with custom stitch patterns, density controls, thread accent colors, slow organic animations, zoom/pan, and "embroider" custom motifs.
- **Custom Tapestries**: Design and save multiple personal tapestry variants; export high-res images or vector files.
- **Advanced Ripple Analytics** (all local):
  - Harmony trends over time, cross-domain correlation heatmaps, "what-if" simulations (e.g., "If I redirect this leak, predicted impact on CareKin + Meaning").
  - Pattern detection: recurring ripple chains, energy leak sources, mastery gap insights.
  - Predictive gentle suggestions with confidence visuals.
- **Legacy Exports & Artifacts**:
  - Beautiful PDF/EPUB legacy books with formatted stories, tapestry renders, ripple timelines, and chapter summaries.
  - High-res printable tapestries and "Weave Reports".
  - Family-ready KinShare packs (granular private shares).
- **AI-Assisted Quests (Opt-In)**: On-device Foundation Models (or consented redacted processing) for hyper-personalized quest forging, narrative synthesis of your Meaning thread, and "Echo Weaver" insights. Explicit toggle + redaction. Free users get rule-based only.
- **Unlimited + Enhanced**:
  - Unlimited custom quest forging (Essence or direct).
  - More active quest slots + advanced Mastery Map (deeper perks simulations).
  - Persistent Thread Tools/Amplifiers (no time limits or higher multipliers).
  - Rich Echo system: unlimited deep history search + AI-assisted narrative arcs (opt-in).
  - Custom visual themes, seasonal chapter overlays, and advanced Loom skins.
- **Stewardship/CareKin Boosts**: Advanced leak simulations, group respite planning tools, load-balancing visualizations.

**Positioning**: "Master the Loom. See the full beauty of your weave. Accelerate real outcomes."

### Luminary Legacy (Higher Tier or Add-On Pack)
- Everything in Weaver + priority support, advanced chapter/seasonal analysis with exportable "Legacy Summaries".
- Caregiver/household group plans (B2B-lite relief dashboards — shared local weaves with consent).
- One-tap pipelines for physical book printing partners (local generation of print-ready files).
- Unlimited custom badge/loom skin designers + community-inspired (opt-in share) motifs.
- Deep archival + full history synthesis.

**Hybrid Options**:
- One-time "Legacy Weaver Pack" (exports + custom tapestries focus) — attractive for users who want artifacts without ongoing sub.
- Family / Household plans.
- Annual pricing emphasized for retention (higher LTV, lower churn).

**Tasty Messaging Examples**:
- "Your first custom tapestry is ready to print and frame."
- "See exactly how your Stewardship wins rippled into 47 extra CareKin hours this quarter."
- "Forge an AI-assisted quest that perfectly fits your current low-energy season."

---

## 3. Deep Integration with Gamification

Premium never gates core gamification loops — it **amplifies** them beautifully:

- **Essence Economy**: Free users earn/spend at base rates. Premium: higher earn multipliers on premium quests/exports, exclusive amplifiers (e.g., "Master Loom Focus" tool), and Essence sinks that feel luxurious (custom stitch density).
- **Living Loom / Tapestry**: Free = beautiful but basic. Master Loom = the signature evolving artwork with user creativity. Exports turn digital progress into physical legacy (huge retention + meaning hook).
- **Quests & Mastery**: Free = solid rule-based. Premium = unlimited forge + AI personalization + advanced Mastery Map with simulations. Quest completions still require reflection for full reward.
- **Echoes & Legacy**: Premium makes revisiting emotionally powerful with rich exports and synthesis.
- **Streaks & Seasons**: Premium analytics help protect streaks with data-driven restorative suggestions; custom seasonal chapters.
- **Resonance & IRL**: Premium surfaces deeper combo insights and easier logging of real outcomes.

**Key Rule**: Any premium feature must demonstrably increase *real-life value* (e.g., time saved via analytics → more IRL weaving; beautiful exports → more legacy sharing).

---

## 4. Onboarding Hooks ("First Weave" Magic — 5-8 Minutes)

Builds directly on existing `OnboardingView.swift` + Gamification Design §4.

**Flow** (progressive delight, immediate visible reward):
1. **"You Are Already Weaving"**: Metaphor intro with 4-thread visual. Quick "What matters most right now?" seed (maps to one thread).
2. **Live Ripple Demo**: Capture a sample event (e.g., "Morning walk" or user choice). Watch full propagation: Compass updates, Loom stitches a first line, Essence burst (✧ +3-5), simple mastery tick, cross-thread ripple highlight. Celebration: calm slow particle stitch + "This one ripple just touched Self + Stewardship + Meaning because..."
3. **First Quest Seed**: Pre-loaded cross-domain quest (e.g., "Log one ripple and note its real-world bridge"). Complete with reflection example. Full reward + "Your weave just grew."
4. **Master Loom Teaser / Mini-Tapestry**: Interactive preview of the Living Loom. Free users plant first stitch; premium nudge appears subtly ("Unlock Master Loom to design your own patterns").
5. **Privacy Commitment**: "Your data, your loom. Local only. Export or unweave anytime." Builds trust.
6. **Post-Onboard Nudges** (gentle, not pushy):
   - "Forge your first custom quest" (Essence or premium gate preview).
   - Default to Compass home with "One Meaningful Weave" prompt.
   - Widget/Live Activity teaser: "Current Harmony: 72% • Suggested Weave available".

**Hooks & Psychology**:
- **Immediate Competence**: Visible Essence + Loom growth in <60s.
- **Autonomy**: User chooses the first capture.
- **Relatedness/Meaning**: Tie demo to legacy or CareKin example.
- **Premium Tease (Soft)**: "Imagine weaving this into a custom tapestry for your family."
- **IRL Bridge**: End with "Close the app and take one real step from this weave?"

**A/B Opportunities** (see section 7): Demo vs no-demo, quest-first vs capture-first, etc.

---

## 5. Daily Rituals & Habit Formation for Retention

Gamification designed for **intrinsic, eudaimonic** loops (SDT: Autonomy, Competence, Relatedness) + calm tech. No streaks that punish; restorative grace everywhere.

**Core Daily/Periodic Rituals** (lightweight, optional, high-signal):

- **Morning One-Weave Ritual** (2-3 min):
  - Quick capture on open (or widget).
  - Energy/Compass check + one suggested weave (rule or premium personalized).
  - "Plant one stitch" in Loom preview.
  - Optional: Claim gentle daily Essence bonus for consistency (with grace).

- **Evening Reflection Weave** (optional, high-value):
  - Review recent ripples or complete active quest.
  - Required reflection gate for full reward (builds depth).
  - "Echo of the Day" — revisit one past ripple for bonus insight (premium richer).
  - Prominent "Weave complete. One IRL bridge?" CTA (close app + do the thing).

- **Weekly Ripple Review** (auto-surfaced, ~10 min):
  - Harmony score + cross-domain trends (premium: full analytics).
  - Resonance combos highlighted.
  - "What surprised you? What will you redirect?" journal.
  - Mastery progress + suggested next tier quests.

- **Seasonal / Chapter Closeouts**:
  - User-defined or auto (e.g., "Caregiving Chapter").
  - Big reflection + collective Essence burst + chapter tapestry snapshot.
  - Natural pause points to prevent burnout.

- **Streak & Grace System**:
  - Per-thread + global "Weave Streaks" with restorative quests instead of breakage.
  - "Restoration Mode" during lowEnergy seasons.
  - Visual: Threads wrapping Loom; progress "stitched" without guilt.

- **Peripheral / Ambient Hooks** (retention without opening app):
  - Widgets: "Harmony 87% • 1 Suggested Weave".
  - "Echo of the Week" calm resurfacing.
  - End-of-session prompts.
  - Analog Mode toggle (emphasizes IRL logging).

**Habit Formation Loop** (tied to gamif):
Capture (or Quest) → Visible Ripple + Essence + Loom growth → Resonance suggestion → IRL action + log outcome → Reflection (depth + full reward) → Mastery tick / Tapestry evolution → Gentle next prompt.

**Premium Amplifiers for Rituals**:
- AI-assisted quest suggestions that feel magically personal.
- Deeper analytics to inform "what ritual would help this week".
- Custom daily ritual templates in Master Loom.

**Grace & Anti-Addiction Built-In**:
- No broken streaks on missed days.
- Mandatory reflection for rewards.
- "Time well spent" transparency.
- Explicit "close app and live" CTAs.
- Essence gentle decay encourages real-life rhythm.

---

## 6. Retention Psychology & Broader Tactics

Aligned with Gamification Design (SDT + Eudaimonia + Calm Tech):

- **Progress Visualization**: Loom growing feels like building lasting identity.
- **Narrative Identity**: Echoes + Legacy Tapestry + chapter exports.
- **Relatedness**: Opt-in KinShare, family echoes (premium).
- **Autonomy**: Full local control; custom forges; editable thread weights/seasons.
- **Competence**: Mastery badges + passive perks that actually help life.
- **Freshness**: Seasons/chapters, surprise resonance, spaced echoes.
- **Disengagement as Feature**: Mindful exit ramps; usage insights showing positive life impact.

**Additional Tactics**:
- Value Demonstration: In-app "Weave Impact" cards ("You redirected X this month — here's the ripple").
- Social Proof (Private & Gentle): "3 Kin in your circle used similar redirects".
- Loss Aversion (Gentle): "Protect your harmony" via restorative paths.
- Onboarding-to-Retention Bridge: First 7-14 days focus on demonstrating value before any paywall.
- Churn Prevention: Graceful re-engagement ( "Your loom has grown since last weave — echo one ripple?").
- Premium as Celebration: "Congratulations on reaching Luminary Self — unlock custom embroidery to mark it."

---

## 7. A/B Test Ideas (Ethical, Calm, Outcome-Focused)

Prioritize tests that measure **real impact** (IRL outcomes logged, harmony improvement, retention via meaningful returns, conversion via value) over vanity metrics. Guardrails: no psychological harm, local data only for tests.

**Onboarding A/Bs**:
- A: Full 6-step with live demo + first quest. B: Shortened 3-step (capture only).
- A: Immediate Essence + Loom growth. B: Same + premium teaser video/animation.
- A: Quest-first (purpose). B: Capture-first (autonomy).
- Measure: Completion rate, Day 1 retention, first IRL log within 48h, time-to-first-premium-tease.

**Paywall & Tier Presentation**:
- A: Soft paywall after mastery milestone (e.g., "Reach Weaver tier — unlock Master Loom"). B: Time-based (Day 14) or usage-based (10 weaves).
- A: "Master Loom" name + visual. B: "Weaver Pro" or value-focused ("Advanced Analytics + Legacy Books").
- A: Feature list. B: Outcome stories ("Users who upgraded printed 2 legacy books and reported higher meaning scores").
- A: Monthly default. B: Annual highlighted with savings + "most popular".
- One-time Legacy Pack vs sub-only.

**In-App Monetization Hooks**:
- A: Premium quest forge button visible early. B: Only after free forge used or Essence low.
- A: Analytics teaser in free Loom ("Unlock full trends"). B: No teaser until value shown.
- A: Export flow shows "Beautiful PDF version available in Master Loom". B: Generic upgrade.

**Pricing & Packaging**:
- A: $4.99/mo or $39/yr. B: $6.99/mo or $59/yr (test anchoring).
- A: Separate one-time export pack. B: Bundled in annual.
- Family plan test vs individual only.
- Intro offer (first month discounted) vs no offer.

**Retention & Rituals A/Bs**:
- A: Strict daily streak vs B: Grace + restorative only.
- A: "One Meaningful Weave" daily nudge. B: Weekly review primary.
- A: AI quest suggestions (opt-in premium preview). B: Rule-based only.
- A: End-of-session IRL prompt always. B: After high-impact weaves only.
- Measure: Return rate for reflection (not total opens), % quests with IRL evidence, self-reported life impact, premium conversion.

**Visual & Messaging**:
- A: Calm subtle premium badges. B: Slightly more celebratory (still restrained).
- A: "Accelerate your legacy" messaging. B: "See the full story of your weave".
- Tapestry customization previews in free vs locked.

**Measurement Framework**:
- Primary: 7/30/90-day retention (meaningful sessions), premium conversion rate, % users logging IRL outcomes.
- Secondary: Harmony score improvement, Essence earned (proxy for engagement), export usage (premium value proof).
- Ethical: Opt-in for any aggregated (anonymized) insights. Kill tests that increase screen time without IRL benefit.

**Phasing**: Start with onboarding & soft value teases (low risk). Progress to pricing once strong free-tier data exists.

---

## 8. Pricing Strategy & Value Demonstration

- **Anchor on Outcomes**: Always surface real numbers from user data (local calculations): "Redirected savings", "CareKin hours relieved", "Legacy stories captured + echoed".
- **Annual Bias**: Promote yearly for lower effective cost + higher commitment.
- **Trials**: Optional 7-14 day full trial (no card) or generous free tier as the trial.
- **Positioning vs Competitors**: Not "another tracker" — the connective loom that makes other tools make sense. Premium is the professional artisan version.
- **Bundles**: Legacy + AI pack; Caregiver household.
- **Apple Ecosystem**: Leverage one-time IAPs, family sharing where appropriate, App Store promotions.

**Example Value Props**:
- "Master Loom users create and export 3x more legacy artifacts."
- "Advanced analytics helped one user free 12 hours/week for Meaning work."

---

## 9. Implementation Notes (Local-First)

- **Feature Flags**: Simple on-device `isMasterLoomUnlocked`, `aiQuestsOptedIn`, etc. Stored in model or settings. Premium simulation in PWA via button.
- **Gating**:
  - UI: Hide or dim premium controls; show elegant "Master Loom" upgrade sheet with value preview (e.g., sample custom tapestry render).
  - Logic: QuestService, ExportService, AnalyticsEngine check flags before advanced paths.
- **Payments**: App Store subscriptions for iOS; Stripe for web/PWA later. One-time for packs.
- **Exports**: Local generation (PDF via libraries, images via Canvas/SwiftUI). Premium unlocks higher quality/templates.
- **AI**: Strict opt-in + on-device first (Apple Intelligence / Foundation Models). Redaction for any future consented cloud.
- **PWA Parity**: Full free experience + demo premium unlock button. Real subs via web later.
- **Phased Rollout** (aligns with Gamification phases):
  1. Strong free + basic Essence/Loom/quests.
  2. Soft premium teases + Master Loom preview visuals.
  3. Full tier logic + exports/analytics.
  4. AI opt-in + advanced packs.
- **Testing**: Unit tests for flag logic + calculations. User journeys with premium layers. Privacy audit on any new data paths.

---

## 10. Success Metrics, Guardrails & Ethics

**Metrics (from Gamification Design)**:
- % quests with logged IRL outcomes/reflections.
- Caregiver relief hours / connections made.
- Legacy artifacts created + echoed + exported (premium strong signal).
- Cross-domain harmony improvement.
- Retention: meaningful returns (e.g., weekly reflection sessions).
- Premium: conversion rate, LTV, churn (via value demonstrated).
- Usage: "Time well spent" vs total; disengagement rate positive.

**Guardrails**:
- Calm audits every phase — does this increase presence or screen time?
- No variable rewards that feel gambling-like.
- Reflection gates mandatory for rewards.
- Full user control: export everything, clear data, no telemetry.
- Real impact over vanity: prioritize IRL metrics.
- Cultural flexibility: editable weights, seasons.
- Ethics review: A/Bs must not manipulate well-being.

**Risks & Mitigations**:
- Over-gamification → strict minimalism + user "calm mode".
- Churn from weak free tier → over-invest in Threadling delight.
- Premium fatigue → strong demonstrated value before ask.
- Privacy concerns → transparent, local defaults everywhere.

---

## 11. Roadmap & Next Steps

1. **Immediate**: Align tiers with current Gamification Design. Add premium flags to prototype (PWA + Swift). Flesh Master Loom visuals in mocks.
2. **Onboarding**: Extend `OnboardingView` with gamif hooks + soft premium teases.
3. **Rituals**: Implement daily/weekly surfaces + grace system.
4. **A/B Framework**: Basic local logging for experiments (opt-in).
5. **Content**: Value stories, export templates, AI prompt guardrails.
6. **Validation**: Run full journeys with tiers simulated. Measure conversion proxies + IRL impact.
7. **Launch Prep**: Pricing finalization, App Store assets emphasizing "tasty" premiums, family sharing.

**References**:
- `ONEWEAVE_GAMIFICATION_DESIGN.md` (full tiers, onboarding, rituals base)
- `oneweave-whitepaper.md` + `ONEWEAVE_GAMIFICATION_SPEC.md`
- `USER_JOURNEYS_ONEWEAVE.md`, `MARKETING.md`
- Existing prototype (PWA HTML, Swift sources)
- ios-monetizable-ideation research (freemium + hybrid patterns)

---

*One life. Woven deliberately. Premium that celebrates the weave — and then steps aside to let you live it.*

**See the ripples. Master the Loom. Live the story.**

---

**Document Info**  
- Version: 1.0  
- Aligned with: OneWeave whitepaper, Gamification v1.0, privacy-by-design  
- Ready for: Spec decomposition, implementation, A/B planning, or multi-agent execution  
- Output: ONEWEAVE_MONETIZATION_RETENTION.md (root + project mirrors recommended)