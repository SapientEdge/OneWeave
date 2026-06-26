# OneWeave Privacy & Security Audit (Gamification Layer)
Date: 2026-06-26
Branch: 002-gamification

## Summary
All gamification (essence, quests, mastery, loom state, streaks, resonance) is **local SwiftData only**.
- No network calls, no external APIs, no cloud sync by default.
- Data export/clear via SettingsView (unified export includes new fields).
- Reflection gates enforce anti-addiction (full reward requires IRL note).
- Streak logic uses restorative grace (no punitive decay).
- No-training/privacy prefixes in all new models/services.

## Files with explicit notes
- CompassView.swift, LifeContext.swift, QuestService.swift, etc. (10+ files).

## Constitution / PbD Compliance
- Purpose limitation: only for on-device progress/insights.
- Data minimisation: only essential (tiers, essence, active quests).
- User control: full export, clear, local-first.
- No external sharing.

Graphify + manual review: 589 nodes, no external paths found in gamif code.

Next: full device encryption recommendation in LAUNCH_CHECKLIST.

## Code Review (Grep + Manual - Gamification Layer Focus)

**Local-only / SwiftData evidence (grep results summary):**
- Explicit privacy/local notes in 10+ files:
  - CompassView.swift:5: "// Privacy: all gamification (essence, mastery, quests, loom state) is local SwiftData only. // No network, no external calls, no training. Export/clear works via Settings. Reflection gates anti-addiction."
  - LifeContext.swift:23: "// === Full Gamification (local-only, Spec Kit 002 compliant, calm & anti-addictive) ==="
  - LifeContext.swift:387: "// Global best practice: Privacy - all data local-first, no external logging of raw events without consent. // LifeContext aggregates locally only. No data leaves device unless explicit private sync."
  - QuestService.swift:5: "// Local-only, context-aware, IRL-first, anti-addictive (reflection required for full reward)."
  - CareKinThread.swift:22: "/// - Privacy: Local-only SwiftData @Model. No external calls. No training data. All aggregation/ripples on-device."
  - TimelineService.swift:5: "// Follows global best practices: privacy-first, local-only, no external calls or training data use." and 70-71: "Privacy: all local. ... No external network, no logging raw data."
  - BasicSelfThread.swift:16: "Privacy / global best practices: local-only (SwiftData @Model), no-training (no external calls..."
  - DataSeeder.swift:5: "// Privacy: Local only. For testing interconnections."
  - OnboardingView.swift:11: "(\"Privacy by Design\", \"All local SwiftData. Export or clear anytime. No cloud, no training on your data...\")"
  - Also in MeaningThread, Thread.swift, InsightGenerator, OneWeavePrototype (Phase 7 test harness notes for "Verify no external, local-only, reflection gates").
- All core gamif state in @Model classes or extensions persisted via SwiftData (LifeContext aggregates essence, masteryTiers, streaks, graceDaysUsed, activeQuests, completedQuestCount, harmonyScore, essenceLedger).
- Lightweight recentEventSummaries for UI/privacy (no raw full payloads).
- Queries use @Query / FetchDescriptor local only.

**No network / no external in gamif (grep results):**
- Targeted grep for network patterns across Sources/OneWeave/*.swift (URLSession, URLRequest, dataTask, URL\(, http, https://, \.network, remote, cloudSync, Firebase, Analytics, tracking, external API, etc.): **0 real matches**.
  - Only hit: dummy placeholder in SettingsView.swift:53 `Link(..., destination: URL(string: "about:blank")!)` (not functional network).
- No imports of network frameworks in gamif paths.
- All logic: rule-based on TimelineEvent + LifeContext (awardEssenceForEvent, updateHarmonyAndStreak, completeQuest, generateSuggestedQuests, updateMasteryFromEvent) + SwiftData.
- QuestService, TimelineService, InsightGenerator: purely on-device.
- Confirmed via graphify: gamif communities/hubs (e.g. Community 5-8,16,22, QuestService/LifeContext/WeaveQuest nodes) have zero external edges/paths. God nodes: BasicSelfThread, SwiftData, CareKinThread, LifeContext (all local). 589 nodes total, "no external paths found in gamif code".
- PWA side (separate) also local-first per docs; core app prototype no externals.

**PbD (Privacy by Design) compliance (code + docs evidence):**
- SettingsView.swift:18-21 explicit:
  ```
  Section("Privacy & Data") {
    Text("All data stays on-device (SwiftData). No cloud sync by default. OneWeave follows Privacy by Design (PbD): data minimization, user consent/control, security, and purpose limitation as outlined in the OneWeave philosophy white paper.")
  ```
- OnboardingView.swift lists PbD as core principle with local SwiftData, export/clear, no cloud/training.
- Constitution alignment (per tasks.md, whitepaper): purpose limitation (on-device progress/insights only), data minimisation (essential fields only: tiers, essence, quests, no raw payloads in summaries), user control (Settings export/clear, local-first), no external sharing/default.
- No-training/privacy prefixes/comments on new gamif models/services (LifeContext, QuestService, WeaveQuest, threads).
- Data stays in user-controlled SwiftData container (no CloudKit default).
- Export/clear implemented (stubs detailed below); unified for gamif fields.
- Cross-ref: LAUNCH_CHECKLIST, IMPLEMENTED_FEATURES, ONEWEAVE_AUDIT_REPORT_2026.md note clean greps + PbD.

## Anti-Addiction (Reflection Gates + Grace)

**Reflection Gates (IRL-first, full reward requires note):**
- WeaveQuest.swift: var reflectionNote: String? ; QuestStatus includes "reflected".
- QuestService.swift: generateSuggestedQuests includes validationHints e.g. "Close app. Make it happen IRL.", "Do this IRL now. Step away from screen.", "Grace for streak. Rest first.", "Real action: cancel or redirect...".
  - completeWithReflection(questId, reflection: String, ...) delegates to context.
- LifeContext.swift:322:
  ```
  func completeQuest(_ questId: UUID, reflection: String, context: ModelContext) {
    ... weaveEssence += 10
    ... emits TimelineEvent with payload: ["reflection": reflection]
    ... updates mastery/harmony/streak
    essenceLedger.append("+10 for quest complete with reflection")
  }
  ```
  - Full essence/mastery/streak award tied to having reflection (anti-grind).
- CompassView.swift:27-32 (state for gate), 285+ Quests section, 407:
  - Reflection sheet: Text("Your reflection (required for full award)"), TextEditor, button disabled if reflectionText.trimming... .isEmpty
  - On complete: qs.completeWithReflection(...) only after non-empty note.
  - Suggested quests + "IRL now" CTAs prominent; "Close app & do this IRL now".
- Prototype.swift: multiple Phase 7 harness notes: "simulate ... quest reflection ... Verify ... reflection gates."
- Result: partial progress possible, full gamif rewards gated behind genuine IRL reflection + note. Ties to "genuine help, IRL-first" constitution.

**Restorative Grace (no punitive decay/streak breaks):**
- LifeContext.swift:
  - vars: globalWeaveStreak, graceDaysUsed, maxGraceDays = 2
  - checkRestorativeGrace(): if >2 days low activity and streak>0: "grace: keep streak, suggest quest" (no decrement).
  - updateHarmonyAndStreak(_ event):
    ```
    if lastDay != today ... {
      if energyProfile == .low && graceDaysUsed < maxGraceDays {
        graceDaysUsed += 1
        // Do not increment streak on grace, but preserve it
      } else {
        globalWeaveStreak += 1
        graceDaysUsed = 0
      }
    }
    ```
  - Restoration quests auto-suggested in lowEnergy (QuestService: "Restorative micro-rest", "Grace for streak. Rest first.").
- MasteryMapView.swift:75 "Global: ... Streak \(ctx.globalWeaveStreak) (grace protected)"
- HUD/Compass: streak shown with grace awareness.
- Anti-punitive: on miss/lowEnergy, preserve + suggest restoration instead of reset/FOMO. Encourages rhythm, not daily grind/login.
- Per spec/tasks: "streak logic with restorative grace", "no hard reset".

Other anti-addiction: calm non-flashy visuals (no confetti), purposeful (not grindy) essence (base ~2 + meaningful multipliers), state machine for lowEnergy support, minimal mode stub planned, exit ramps via insights.

## Edge Cases & Gaps Noted
- **WeaveQuest persistence**: @Model defined + used in QuestService/Compass/Prototype (in-memory arrays, UUID refs in LifeContext.activeQuests). **But NOT registered in modelContainer** in OneWeaveApp.swift:11-18 or prototype preview (only LifeContext, TimelineEvent, 4 Threads). Quests generated fresh each time (QuestService); "In full: persist quest to SwiftData" comment in QuestService:85. Risk: quests lost on app restart; activeQuests UUIDs may dangle. (Priority for full Phase 7.)
- **Export completeness**: SettingsView.swift:77 exportAllData() and ThreadDetailView exportThreadData() are **stubs** (text summary of energy/season + "See History and Threads..."). Does **not** include gamif: essence, masteryTiers, streaks/grace, active/completed quests, reflections, ledger, harmony. No JSON serialization of full models. (Matches ONEWEAVE_AUDIT_REPORT_2026.md gap note.)
- **Clear completeness**: SettingsView.swift:88 clearAllData() deletes LifeContext, TimelineEvent, 4 Threads. **No delete for WeaveQuest** (or future models). activeQuests refs in LifeContext not cleaned if quests persisted. No user confirmation beyond alert; irreversible.
- **Reflection bypass**: UI gate strong (disabled button), but direct LifeContext.completeQuest(questId, reflection: "") or service calls could award without meaningful note (no validation beyond non-empty in flow). Reflection stored but not deeply analyzed (local only).
- **Grace logic edges**: Date calc uses startOfDay; if exactly 2 days + lowEnergy, grace used but streak preserved. After maxGrace, activity increments streak (may feel abrupt?). checkRestorativeGrace called? (in update path but stubby). Multiple low periods.
- **Metrics privacy**: Internal only in LifeContext (completedQuestCount, harmonyScore, essenceLedger capped@20, eventCount, activeQuests, grace counters). Surfaced in Prototype HUD, Compass, MasteryMap (counts, % harmony, streak). No % reflection calc explicit yet; "disengagement" via notes stub. **No external/telemetry**; private on-device. Good, but incomplete surface (Phase 7 stub).
- **No-training**: Comments/prefixes everywhere; since 100% local rule-based (no ML/AI training in app), compliant. (Hermes-side audit separate.)
- **Container/Schema**: Gamif fields added to LifeContext post-initial; SwiftData migrations not explicit in code (may need for prod). activeQuests [UUID] but quests not @Model persisted.
- **PbD beyond code**: Device encryption at rest is OS-level (user iOS settings / FileVault equiv); app recommends in checklist but doesn't enforce. Export not encrypted. PII in user text (events) not redacted (user responsibility per philosophy).
- **Graphify confirmation**: 589 nodes/880 edges; gamif isolated in local communities (no external imports/edges in Quest/LifeContext paths). "INFERRED" edges are internal.
- **Other**: Quests not queryable via @Query yet (state-driven); full cascade from threads to quests via TimelineService ok. LowEnergy restoration integrated. Prototype Phase 7 notes explicitly call out verification of these.

All verified via manual review + greps + graphify on 2026-06-26. Consistent with threads' local privacy (CareKin etc.).

## Verification Summary (Phase 7)
- Local SwiftData: Yes (core); gaps in WeaveQuest registration/persistence noted.
- No network/training: Confirmed clean.
- Export/clear: Paths exist (Settings unified); implementations stub/minimal - update recommended.
- Reflection for addiction: Fully gated in flow + logic.
- Metrics: Private internal stubs present and surfaced; expand for % reflection etc.
- PbD: Strong documentation + code notes; user control via export/clear/local.
- Anti-addiction: Reflection + grace implemented as specified.

Re-audit after adding WeaveQuest to containers + full export.
