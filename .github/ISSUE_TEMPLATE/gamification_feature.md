---
name: Gamification Feature
about: Propose or request a gamification feature (Essence, Weave Quests, Living Loom, Mastery Badges, Streaks, Echoes, Tools, Seasons, etc). MUST align with OneWeave's calm, privacy-first, purposeful, IRL-first philosophy. Read the Gamification Design Spec first.
title: '[Gamification] '
labels: ['gamification', 'feature']
assignees: ''
---

**Feature summary**
One-sentence description. E.g. "Add Essence ledger view with cross-thread resonance history"

**Motivation / Problem**
Why is this needed? How does it amplify authentic life / ripples without hijacking attention?

**Detailed design (tie to spec)**
- **Core mechanic**: (e.g. how Essence earned: base + multipliers from TimelineEvent + linkedThreads + IRL validation)
- **Affected threads**: Self | Stewardship | CareKin | Meaning (and cross)
- **Visuals**: Impact on Compass / Living Loom / Tapestry (stitches, pulses, badges, harmony)
- **User flow**: Discovery → Accept → Complete (with reflection gate) → Reward + event emission
- **Persistence & rules**: Local-only (SwiftData / IndexedDB). Any decay, caps, grace periods?
- **IRL bridge**: How it prompts real-world action or logging (e.g. "Close app now", schedule respite)
- **Anti-addiction**: Reflection required? Grace for streaks? No FOMO/variable ratio?

**Implementation notes**
- Models / services to extend (LifeContext, TimelineService, QuestService, LoomRenderer etc.)
- UI components (SwiftUI Canvas, PWA <canvas>)
- Tests / verification (state transitions, ripple propagation)
- Premium vs free tier consideration

**Success metrics (real impact)**
E.g. % quests with logged IRL outcomes, harmony score improvement, mindful disengagement rate.

**References**
- ONEWEAVE_GAMIFICATION_DESIGN.md sections
- ONEWEAVE_GAMIFICATION_SPEC.md
- .specify/specs/002-gamification/
- Related TimelineEvent types or existing mastery code

**Additional context / mock**
Screenshots, links to GAMIFICATION_VISUAL_MOCK.html, sketches, user journey.

**Priority / MVP?**
Is this core for 002-gamification or nice-to-have? 
