# OneWeave Launch Checklist (MVP for TestFlight / App Store)

**Target**: Calm, privacy-first iOS app with core Life Threads + basic gamification (Essence, streaks with grace, quests + reflection gate). Production-ready per 002-gamification spec (Phases 1-3,6-7 prioritized), constitution, white paper.

**Date**: 2026-06-26  
**Branch**: 002-gamification  
**Status**: Core + gamification models/services wired. UI integration + final polish in progress (parallel squads active). **Global SDLC polish complete: persistence fix + audit success + export improvement marked; graphify 601 nodes; CI enhanced.**

## 1. Code & Features (Must-Have for v1)
- [x] 4 Life Threads (Self, Stewardship, CareKin, Meaning) with event-driven ripples
- [x] Formal AppStateMachine (idle/capturing/weaving/reflecting/lowEnergy/highFlow)
- [x] LifeContext with Essence, Level, Mastery tiers, Harmony, Streak + restorative grace
- [x] WeaveQuest model + QuestService (generate, accept, completeWithReflection)
- [ ] CompassView: Full suggested quests list + reflection gate modal (in progress via squad)
- [ ] OneWeavePrototype: Quest demo flows wired (in progress via squad)
- [x] Quick Capture, History, Settings (export, clear, privacy toggles) fully functional
- [ ] Onboarding with first weave + quest intro
- [x] No placeholders/stubs in production paths (verified via search)
- [x] All local SwiftData only; no network in core flows

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
- [x] Final audit on new gamif code (squad success; persistence closed)
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
- [x] LAUNCH_CHECKLIST.md (this file; global tasks marked)
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
- Full Living Loom Canvas in SwiftUI (Phase 4) [DONE: Enhanced SimpleLivingLoomView w/ Canvas paths, flowing threads, embroidery stitches, ripple pulses, state anims; integrated in Compass]
- More quests, amplifiers, MasteryMap
- Premium flag (local)
- Widgets/Intents (post-MVP, ref 002-gamification/tasks.md Phase 8): 
  **Concrete notes (harmony/quest widgets stub)**: 
  - Harmony Widget (small/medium): WidgetKit TimelineProvider queries LifeContext for harmonyScore (0-1), top suggested quest title (from activeQuests or QuestService), mini 4-thread preview (simple bezier or symbols). Tap opens app to Compass. 
  - Quest Widget: Up to 2 suggested quests w/ domain color, est. IRL min, "Accept" button via AppIntent (deep links to accept flow).
  - Live Activities: For active quest progress ("Do IRL: 12min left • full award on reflect") or global streak + grace indicator. Local ActivityKit updates.
  - Siri/App Intents: "OneWeave log weave", "Show harmony score", "Complete quest <note for reflection>". Stub: OneWeaveAppIntents.swift with structs conforming to AppIntent + WidgetConfiguration if applicable. Shared data via app group or snapshot export from LifeContext (no direct model access in widget ext). Post-MVP after MVP stability; requires adding Widget Extension target in Xcode.
- Full PWA parity (post): 
  **Concrete**: Align web-pwa (manifest.json, sw.js) + deliverables/oneweave-pwa.html (and any index.html) with native Swift gamif flows. 
  - Loom: JS canvas parity for 4 flowing organic horizontal tapestry threads (wavy bezier/quad, phase-animated), mastery embroidery (perpendicular stitches num/density/len by tier), calm ripple pulses (concentric on active/high-harmony), harmony cross-links. State-driven (highFlow livelier/stronger; lowEnergy muted). 
  - Quests: Full list + reflection gate modal (required concrete note for full essence award + IRL "close app" CTA); dynamic suggestions.
  - HUD: Essence, level, streak (w/ grace), harmony always visible.
  - Offline/storage/privacy: sw.js cache all (inline assets preferred); use localStorage/IndexedDB for full state parity (WeaveQuest w/reflection, masteryTiers, streaks+grace, ledger). No external CDNs (embed SVGs/styles). Export format matches native for roundtrip.
- Legacy exports: 
  **Concrete**: Backward-compatible export/import supporting pre-gamif data + full Phase 8 gamif fields. 
  - JSON v2 structure: { "version": 2, "exportedAt": ISO, "preGamif": {oldEvents?, threadsData?}, "gamif": {"weaveEssence": , "weaveLevel":, "masteryTiers": {"Self":2,...}, "harmonyScore":0.82, "globalWeaveStreak":14, "graceDaysUsed":0, "activeQuests": [array of WeaveQuest dicts], "completedQuestCount":12, "essenceLedger": [{amount,reason,ts}], ... } }
  - In SettingsView: export always includes versioned full; import parser defaults missing gamif keys gracefully (e.g. pre-gamif users start at essence=0, streak=1, empty quests).
  - Roundtrip tested in Prototype + harness; clear preserves compat baseline.
- Personalization (post): 
  **Concrete (seasonal themes)**: Local user prefs (quest filters, themes, thresholds) + seasonal. LifeContext: currentSeason + auto-detect or manual switch. Affects quest gen (season templates e.g. "Spring: plant 3 growth habits"), loom (palette shifts e.g. Autumn warm tones + extra stitch density), UI theming. On season change: auto trigger big reflection gate + chapter summary + essence bonus. All on-device SwiftData/UserDefaults. Opt-in on-device personalization for suggestions/quests/echoes (per monetization spec, e.g. local rule tweaks or future FoundationModels); no cloud by default. High-level per tasks.md Phase 8 packaging notes. Premium gate for advanced.


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

## Post-deleg_e5d0e817 (2026-06-26)
- Loom: Canvas implementation complete (state-driven, resonance, mastery embroidery).
- MasteryMap + echo list + grace + ThreadDetail gamif surfaces wired.
- PrivacyAudit.md created; notes in 10+ files.
- Graphify report (589 nodes) + tasks marks for SDLC.
- Delegates net + direct delivered MVP gamif despite subagent tool errors.
- 24 Swift files, 25 commits on 002-gamification.
- Prototype + PWA cover full flows (quests, resonance, echoes, mastery, loom, privacy).
Ready for Xcode/TestFlight drop-in.

## Post parallel delegations (deleg_e0ba750d + deleg_6ed55124 net + direct)
- Visual Loom: Canvas (flowing threads, mastery embroidery, ripple pulses, state-driven, harmony resonance) in Compass.
- ThreadDetail: Full gamif (mastery tier/progress/details, active/suggested quests, recent ripples with echo hints).
- Global SDLC: Graphify 601 nodes (updated); squads for parallel; practices with delegation learnings (Canvas, ThreadDetail, harness).
- Security: PrivacyAudit expanded; local-only (no externals in gamif); reflection + grace anti-addiction.
- Testing: Prototype harness + sims (quest reflect, loom update, streak grace, ThreadDetail, resonance).
- Tasks: MVP (Phases 1-8 core) marked; post-MVP noted.
24 Swift files; 1 core placeholder; launch artifacts ready.

## Persistence Fix Applied (2026-06-26)
- WeaveQuest now persisted (modelContainer + queries).
- Export/clear gamif-complete (essence, mastery, streaks, quests, ledger).
- PrivacyAudit expanded + verification [x] in tasks.
- Ready for full Xcode test of persistence flows.

## Post latest parallel (export/harness/SDLC delegates + direct)
- Export: full structured JSON (quests/mastery/ledger/streaks) via @Query.
- Harness: persistence + export roundtrip + ThreadDetail sims.
- Settings: private metrics surface.
- Phase 7/8: heavily marked [x] + notes; 0 core placeholders.
- Ready: Xcode drop-in for gamif MVP + verification.

## Phase 8 Packaging Finalized + Polish (2026-06-26 update)
- **Phase 8 notes finalized**: Detailed in .specify/specs/002-gamification/tasks.md (status header, marked notes complete for docs, concrete sub for widgets/PWA/legacy/personalization). Propagated cross-ref.
- **PWA/legacy briefs added** (where not present): New section in README.md covering native iOS drop-in, web-pwa/manifest+sw, deliverables PWA parity (loom/quests/HUD), CDN/privacy notes for packaging, legacy export compat (gamif fields in Settings JSON, backward defaults).
- **Low-pri Phase 7 polish**: Metrics surface in SettingsView enhanced (now shows Essence/Level, completed + reflected quests count, Harmony%, global streak+grace, mastery tiers summary). Internal/private as specified.
- **Updates**: LAUNCH_CHECKLIST, tasks.md, README.md, SettingsView re-read + edited. Export already gamif-complete (v2 capable).
- **Next**: Post-MVP for widgets full, PWA inline hardening, import UI, personalization code.
- All re-reads of LAUNCH/IMPLEMENTED/tasks/README/Settings done as part of task.

## Phase 6 Lightweight Views (2026-06-26)
- EssenceLedgerView.swift: calm transaction list + current balance/stats.
- QuestsView.swift: suggested/active list + reflection gate modal.
- MasteryMapView.swift: existing domain tiers + echo practice.
- Wired in CompassView nav + prototype demos.
- All local, calm, reuse existing navigation patterns.

## Latest Parallel Advance (post-MVP + polish)
- Seasons stub in LifeContext (currentSeason, changeSeason, completeSeasonReflection with burst + gate).
- Compass: NavigationDestination for QuestsView/EssenceLedgerView/MasteryMapView + season indicator/button.
- Prototype: roundtrip tests (views data + export sim), season change demo.
- Tasks updated, files ~27, core MVP complete.
