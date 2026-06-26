# OneWeave Launch Checklist (MVP for TestFlight / App Store)

**Target**: Calm, privacy-first iOS app with core Life Threads + basic gamification (Essence, streaks with grace, quests + reflection gate). Production-ready per 002-gamification spec (Phases 1-3,6-7 prioritized), constitution, white paper.

**Date**: 2026-06-26  
**Branch**: 002-gamification  
**Status**: Core + gamification models/services wired. UI integration + final polish in progress (parallel squads active).

## 1. Code & Features (Must-Have for v1)
- [x] 4 Life Threads (Self, Stewardship, CareKin, Meaning) with event-driven ripples
- [x] Formal AppStateMachine (idle/capturing/weaving/reflecting/lowEnergy/highFlow)
- [x] LifeContext with Essence, Level, Mastery tiers, Harmony, Streak + restorative grace
- [x] WeaveQuest model + QuestService (generate, accept, completeWithReflection)
- [ ] CompassView: Full suggested quests list + reflection gate modal (in progress via squad)
- [ ] OneWeavePrototype: Quest demo flows wired (in progress via squad)
- [ ] Quick Capture, History, Settings (export, clear, privacy toggles) fully functional
- [ ] Onboarding with first weave + quest intro
- [ ] No placeholders/stubs in production paths (verified via search)
- [ ] All local SwiftData only; no network in core flows

## 2. UI/UX Polish (Calm Tech per White Paper)
- [x] Dynamic rings, energy trends, Active Ripples, StateMachineIndicator, WeaveSummary
- [x] .spring animations, haptics, glass/.ultraThinMaterial, color psychology
- [ ] Quests UI in Compass (suggested + reflection gate)
- [ ] Essence HUD + level progress + streak + harmony always visible
- [ ] IRL prompts prominent ("Close app & do this IRL")
- [ ] Accessibility (labels, reduced motion)

## 3. Gamification & Retention (002 Spec MVP)
- [x] Essence economy (base + multipliers for cross-thread, quests, IRL/reflection)
- [x] Streaks with grace (no punitive reset)
- [x] Quests with reflection required for full reward
- [ ] Basic visual progress (rings + HUD) — enhance to simple tapestry if time
- [ ] Mastery hints in threads
- [ ] Anti-addictive: reflection gates, no FOMO timers, IRL bias

## 4. Privacy/Security (Global Best Practices + White Paper PbD)
- [x] Local-first, user-controlled export/clear
- [x] No-training prefixes, redaction in config
- [x] Semgrep clean, grep for external calls clean
- [ ] Final audit on new gamif code (squad in progress)
- [ ] Disk encryption note for user (VPS plain; recommend on-device)

## 5. Assets & Marketing
- [x] Generated images (Compass mockup, hero, state machine)
- [x] MARKETING.md (tagline, descriptions)
- [x] ONEWEAVE_WHITE_PAPER.md (~2426 words)
- [ ] App icon (use one of generated or simple)
- [ ] Screenshots (build in Xcode + Simulator; 6.7", 6.5", etc.)
- [ ] Privacy policy (local data only; link in Settings)

## 6. Docs & SDLC
- [x] .specify/specs/002-gamification (spec + tasks + checklist + analysis)
- [x] IMPLEMENTED_FEATURES.md (update with gamif)
- [ ] LAUNCH_CHECKLIST.md (this file)
- [x] Git on feature branch with commits

## 7. Build & Submit Prep (User Side — Xcode)
1. Clone or copy Sources/OneWeave into new Xcode iOS app project (SwiftUI + SwiftData).
2. Add assets (icons from cache/images, launch screen).
3. Test on device: full journeys, quests with reflection, export, state transitions.
4. Add TestFlight users.
5. App Store Connect: 
   - Name: OneWeave
   - Subtitle: "Life as One Interconnected Journey"
   - Keywords: life weaving, mindfulness, habit, legacy, privacy
   - Description from MARKETING.md
   - Screenshots
6. Submit for review (MVP note: gamification is foundational; more visuals in updates).

## 8. Post-Launch / Next
- Full Living Loom Canvas in SwiftUI (Phase 4)
- More quests, amplifiers, MasteryMap
- Premium flag (local)
- Widgets / Live Activities (future)
- PWA parity updates

**Risks to Launch**:
- Build in real Xcode (this env is Linux VPS — sources are complete).
- Time for manual QA on device.
- Asset creation (icons/screenshots).

**Parallel Work Active**:
- Squad 1-2: UI wiring for quests/reflection (Compass + Prototype).
- Squad 3: Launch docs + metadata polish.
- Global: SDLC formalization + security hardening via loaded agent-squad skills.

Once squads return, integrate, final commit, and this checklist becomes "ready to build & submit".

**How to use squads for future updates**:
Load `agent-squad-orchestrator` + `squad-repo-native-teams` + `agents-best-practices-harness`.
Example: "Register Architect, Coder, Tester, SecurityAuditor. Supervisor coordinates quest UI feature per 002 spec."

Launch when checklist green. User controls final build/submit.
## Latest Build Notes (gamification MVP)
- Visuals: SimpleLivingLoom + mastery/streak in Compass; test in Prototype tab.
- Mastery/Resonance: Functional in LifeContext; demo buttons show cross effects.
- Verification: Run prototype journeys for quests + resonance + echoes. Check HUD updates.
- Privacy: Confirmed no external calls in gamif code; all local.
- Next for launch: Expand loom to Canvas if needed; add simple MasteryMapView stub; full ThreadDetail gamif hooks (post-MVP ok).
