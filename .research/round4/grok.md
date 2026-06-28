**A. Top 15 MOST LIKELY xcodebuild failures (file:line + category + fix)**

1. **LifeContext.swift:512-519** — Syntax error / extraneous code after extension. `func awardBonusEssence`, `levelProgress`, `essenceDisplay` + trailing `}` sit after `extension LifeContext { ... }` with broken class nesting/indent. Fix:**A. Top 15 MOST LIKELY xcodebuild failures (file:line + category + fix)**

1. LifeContext.swift:573 (syntax/scope): Stray `}` + `awardBonusEssence`, `levelProgress`, `essenceDisplay` after extension close at file scope (post-class close ~500). "Extraneous '}'", "expected declaration", or "no member on LifeContext". Move funcs + computed into the class or a proper `extension LifeContext { ... }`.

2. P2PWeaveShare.swift:54 (missing import): `ModelContext` and `ModelContext?` in `drainPending`/`receiveAndIntegrate` sigs; only `import Foundation + CryptoKit`. Add `import SwiftData`.

3. LifeContext.swift:75 (type mismatch): `var threads: [String] { activeThreads }`. Callers do `.title`, `.filter { !$0.title... }`. "Value of type 'String' has no member 'title'".

4. DailyBriefings.swift:349 + CognitiveLoad.swift:252 + FamilyPod.swift:334 (missing members): `context.careKinThreads`, `context.meaningThreads`, `context.stewardshipThreads`, `context.quests`, `context.timeline`, `context.bodyThread`, `context.lastReflectionAt`. No such stored/computed on `@Model LifeContext`.

5. CompassView.swift:105 + OneWeavePrototype.swift:957 (async/sync): `LifeGraphiOSIntegrations.shared.importAll(...) { ... }` inside sync `Button { }` action. `importAll` is `async`. "Async call in synchronous context". Wrap: `Task { await ... }`.

6. TimelineService.swift:38 (signature mismatch): `stateMachine.transition(on: event)` (no context arg). The overload is `transition(on: TimelineEvent, context: LifeContext)`. Other call sites pass context; this one does not.

7. FamilyPod.swift:334 (type error, related): `context.threads.filter { !$0.title.isEmpty }.map { $0.title }`. After shim, `threads` yields `[String]`.

8. DailyBriefings.swift:458 (objc runtime): `objc_getAssociatedObject` / `objc_setAssociatedObject` + `_bodyThreadKey` etc. in `public extension LifeContext`. No `import ObjectiveC`; previously removed from CognitiveLoad (hand-off CLAUDE-R3-23). Fragile on @Model + Linux harness.

9. LifeContext.swift:460 (inconsistent completeQuest): `completeQuest` now enforces 20-char min for full reward (good), but callers and `FamilyPod` / `QuestService` surface still expect different behavior; plus missing `quests: [WeaveQuest]` etc. for callers in Daily/Cognitive.

10. SchemaMigrationPlan.swift + top-level models (registration/duplicate @Model risk): Inner `@Model` classes inside `OneWeaveSchemaV*` + top-level ones (LifeEntity etc.). Migration plan uses `models:` list referencing both; potential "duplicate PersistentModel" or versioned schema mismatch on first `xcodebuild`.

11. P2PWeaveShare.swift:268-area + struct level (statics + isolation): `static var offlineQueue`, `pendingIntegrations` on plain `struct P2PWeaveShare`. Mixed `@MainActor` / non-actor mutating statics (`queueShare`, `processOfflineQueue`, appends). No actor protection.

12. AppLifecycleCoordinator.swift:382 (statics on @MainActor enum): `public static var lastBackgroundAt`, `bodyThreadLastReadAt` on `@MainActor public enum`. Safe only if *every* read/write is main-isolated (handleScenePhase + bridge are, but any direct access from detached code breaks).

13. GraphInsightGenerator.swift:41 (static cache on @MainActor struct): `private static var cache`, `invalidationCount` etc. Inside `@MainActor struct`. Generally ok, but `generateInsights` / `makeCacheKey` called from non-isolated paths + invalidation from many places risks stale or re-entrancy.

14. BodyThreadWeaver.swift:100 + iOSServiceIntegrations.swift:253 (HealthKit + @MainActor): `@MainActor static func liveReading` / `detectLowCoherence` + `HKSampleQueryDescriptor.result(for:)` + `requestAuthorization`. HK is async but not guaranteed main on resume in all paths; conditional `#if canImport(HealthKit)` + Info.plist absence (handoff NEMO) will also surface at runtime but may affect build if types leak.

15. Multiple .swift (missing members + protocol): `LifeContext` used as if it has `bodyThread`, `timeline`, `quests` arrays, `care*Threads` etc. (DailyBriefings:240/259/279/327, CognitiveLoad:246/251/258/263, FamilyPod:332+). Also `QuestService.completeWithReflection` etc. assume full surface. Plus `LifeEntity` / thread models not always satisfying all call sites (e.g. `.title` vs `.name`).

**B. Top 10 runtime crash risks**

1. DailyBriefings.swift:333: `$0.completedAt!` on `[WeaveQuest]` filter for today. `completedAt: Date?`; any non-completed in list → crash.

2. CompassView.swift:49: `st.savingsSuggestions.first!` (after `!isEmpty` guard on fetch). Mutation between check and use, or empty after fetch → crash.

3. QuickCaptureInbox.swift:145/155: `sortedScores[0]` / `[0]` without count check. Empty signals dict after scoring → index crash.

4. OneWeavePrototype.swift:965 + validation paths: `lifeContext.lifeGraphEntities.first!`, `graphEntities.first!`, `graphEntities[0]`.

5. BasicSelfThread.swift:175: `sorted[0]` on habit dates.

6. P2PWeaveShare.swift:208 (receive): `LifeEntity(...)` + direct mutation of `context.lifeGraphEntities.append` + `mc.insert`; assumes non-nil modelContext paths and valid snapshots. Reflection gate re-append + static `pendingIntegrations` under concurrent calls.

7. AppLifecycleCoordinator.swift:340/350 + SacredEcho.swift:324 (Linux paths): `fatalError` on `/dev/urandom` failure or SecRandom in randomBytes (both persist + encrypt paths). Production code paths hit on first background or echo seal.

8. SacredEcho.swift:530 + 573: Early `alreadyOpened` throw paths + `stateRaw` mutation without modelContext save in all branches; plus `validateHeir` can throw after open.

9. LifeContext.swift:470 (completeQuest) + callers: `activeQuests.removeAll` + `updateFromEvent` while iterating or under SwiftData change tracking; plus essenceLedger unbounded append before cap check in some paths.

10. Any `@Model` direct mutation from non-`@MainActor` / non-ModelContext paths (P2P receiveAndIntegrate, QuestService shared singleton, TimelineService, static drains) + `GraphInsightGenerator.invalidateCache()`.

**C. Top 5 concurrency bugs (races, @MainActor leaks)**

1. P2PWeaveShare.swift:45/50 (statics): `static var offlineQueue`, `pendingIntegrations`. Mutated by non-@MainActor static funcs (`queueShare`, `processOfflineQueue`, `receiveAndIntegrate` append inside some paths) + @MainActor drain. Data race + actor isolation hole on real device.

2. AppLifecycleCoordinator.swift:382/387 + handleScenePhase: `static var lastBackgroundAt`, `bodyThreadLastReadAt`. Assigned in `@MainActor` paths but read in `applicationWillEnterForeground` and conditionals; any background/network callback or widget path touching them violates.

3. GraphInsightGenerator.swift:119 (cache under @MainActor struct): `cache = ...`, `cacheHits++` etc. in `generateInsights`. Called from Compass/Oracle render paths + invalidations from P2P/Body/Insight/ Lifecycle. Stale hits or concurrent mutation if any caller escapes main.

4. LifeGraphiOSIntegrations.swift + iOSServiceIntegrations: `@MainActor` on `import*` / `requestAccess` / `detectLowCoherence`, but `importAll` takes escaping `@escaping (String,[LifeEntity])->Void` and is itself async. Call sites (Compass button) not properly `Task`ed → potential isolation violation + re-entrant LifeContext mutation.

5. TimelineService ( @Observable class, no @MainActor) + LifeContext updateFromEvent + stateMachine.transition: ModelContext insert + direct property writes on @Model from potentially non-main emit paths. No Sendable, no isolation. Plus QuestService singleton static shared.

**D. Top 5 retain cycles / memory leaks**

1. DailyBriefings.swift:458 (associated objects): `objc_setAssociatedObject(..., .OBJC_ASSOCIATION_RETAIN)` on every LifeContext instance for `_bodyThread` / `_upcomingEchoes`. Strong retain of snapshots; lives for lifetime of the @Model object (which is long-lived in the container). No cleanup.

2. Static caches + singletons: `GraphInsightGenerator` private static cache (never pruned beyond TTL + explicit invalidate), `P2PWeaveShare` static queues (grow until process drops), `OneWeaveSnapshotStore` shared, `QuestService.shared`. EssenceLedger has cap, but others don't.

3. Closures in views capturing `context: LifeContext` (reference) strongly + long-lived DispatchQueue.main.asyncAfter (Compass:274/422/618, ThreadDetail:334, MasteryMap:148, etc.). Views are value types but the captured @Model + side effects keep graphs alive.

4. BodyThreadSheet.swift:27 + refresh Task { await ... }: `Task` captures `self` (the sheet View) + `context` strongly. If sheet stays in hierarchy or dismiss is delayed, holds modelContext refs.

5. TimelineService + AppStateMachine + LifeContext cross refs (service holds ModelContext, emits update LifeContext which calls back into services/insights). No weak, plus @Observable + SwiftData.

**E. Quick-win [LINUX-FIXABLE] items (source edits only)**

- Add `import SwiftData` to P2PWeaveShare.swift (top).
- Fix LifeContext.swift brace/extension: wrap `awardBonusEssence`, `levelProgress`, `essenceDisplay` inside the existing `extension LifeContext` (or move back into class body before final `}`). Delete the orphan `}` at ~573.
- In P2PWeaveShare.swift: drainPending and queue/receive: make the static-mutating helpers `@MainActor` (or protect with actor) and remove the always-empty `stillPending` dance.
- CompassView.swift:105 and prototype equivalent: wrap the `importAll` call in `Task { await LifeGraphiOSIntegrations.shared.importAll(...) { ... } }`.
- TimelineService.swift:38: change to `stateMachine.transition(on: event, context: ???)` or add a context-less overload to AppStateMachine (quickest: pass a fetched LifeContext or make overload).
- Quick low-risk: guard the `first!` / `[0]` sites (Compass 49, QuickCapture 145, BasicSelfThread 175, DailyBriefings 333) with `if let first = ...` or `guard !arr.isEmpty`.
- Add `import ObjectiveC` (or guard) + comment the associated-object hack in DailyBriefings.swift (or replace with stored properties on a wrapper if possible).
- In LifeContext shims (75+), at minimum make `threads` etc. not crash the type checker for the known call sites (e.g. change to computed that return empty or fix callers to use `activeThreads` strings where .title was assumed). (Note: full surface add would be larger.)

These are the concrete, line-citable compile/runtime/concurrency problems visible from static analysis of the 56 files + handoff. Run `xcodebuild` first on handoff. 19/19 Python suites do not catch Swift type or isolation issues.
