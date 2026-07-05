# Claude Code — Swift Code Quality Review (Round 3)

**Date**: 2026-06-27
**Reviewer**: Claude Code (via `/root/.local/bin/claude`)
**Source**: Terminal output relayed in `.research/round3/claude_output.md` (file write was blocked pending permission; full review saved here with approval)
**Method**: Read all 12 assigned files + `LifeContext`, cross-checked against real `EnergyProfile`/`BasicSelfThread`/`@Model LifeContext` definitions, **verified 5 highest-severity claims directly against source** (not just subagent reports). Prior-round fixed/deferred items excluded.
**Files reviewed**: OneWeaveApp.swift, AppLifecycleCoordinator.swift, OneWeaveSnapshotStore.swift, OneWeaveWidgetStubs.swift, SchemaMigrationPlan.swift, FamilyPod.swift, CognitiveLoad.swift, GraphInsightGenerator.swift, LifeContext.swift, CommandPalette.swift, SacredEcho.swift, InvisibleMentor.swift, PortableExport.swift

## Headline

**Two of the most-connected god-node areas do not compile against the current model definitions.** The Python mirrors are green, but the Swift won't build — same class of "applied-but-never-landed" gap Nemotron caught in cycle 27.

The Mac coworker's first action should be `xcodebuild` on the real target to catch all compile-blockers as a batch before applying fixes.

## Top 5 (all HIGH, all verified against source)

### CLAUDE-R3-1 — `LifeContext.completeQuest` reflection gate not enforced [HIGH/blocker]
- **File**: Sources/OneWeave/LifeContext.swift:440-459
- **Issue**: Comment on line 439 says "full reward requires reflection for anti-grind", but line 441 does `weaveEssence += 10` unconditionally. No non-empty check on `reflection` despite the file's own comment and constitution's reflection-gated principle.
- **Severity justification**: This is the **canonical quest path**. Every quest completion bypasses the gate. Constitution principle 2 ("reflection-gated") is violated on the most-used path.
- **Fix**: Guard with `let bonus = reflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 3 : 10` and update the `essenceLedger.append` message accordingly.

### CLAUDE-R3-2 — `changeSeason` awards essence unconditionally [HIGH/blocker]
- **File**: Sources/OneWeave/LifeContext.swift:100-110
- **Issue**: Line 108 does `weaveEssence += 20` inside the season-change branch. Comment on line 107 says "in real UI: show big reflection sheet" — but no gate. `seasonReflectionCompleted` is set to `false` on line 105 but **never checked** before awarding the +20.
- **Severity justification**: Constitution principle 2 violated. CommandPalette line 109-113 calls `changeSeason` immediately from a "season" keyword with the misleading detail "Reflection gate will prompt next interaction." → user gets +20 with no actual gate.
- **Fix**: Move `weaveEssence += 20` inside `if seasonReflectionCompleted { ... }`, OR award only `+2` now with the rest gated on `seasonReflectionCompleted` flipping to true.

### CLAUDE-R3-3 — `GraphInsightGenerator` switch on non-existent `EnergyProfile.balanced` [HIGH/blocker]
- **File**: Sources/OneWeave/GraphInsightGenerator.swift:341-346
- **Issue**: Switch on `context.energyProfile` has cases `.low`, `.balanced`, `.high`. But `EnergyProfile` (BasicSelfThread.swift:148, :205, :258) only defines `.low/.normal/.high`. Result: **compile error** (unknown case + non-exhaustive switch).
- **Severity justification**: Compile error on a hot path used by every insight award and cache key derivation.
- **Fix**: Replace `case .balanced:` with `case .normal:` (also matches CompassView.swift:650 which uses the ternary on `.high ? .low ?` else `.5` for the implicit normal case).

### CLAUDE-R3-18/19/20 — `FamilyPod` digest builder uses non-existent `LifeContext` members + mutates `let` fields [HIGH/blocker]
- **Files**:
  - Sources/OneWeave/FamilyPod.swift:295-339 (builder)
  - Sources/OneWeave/FamilyPod.swift:197-234 (`FamilyPodDigestEntry` definition, all fields are `let`)
- **Issues**:
  1. Builder mutates `let` fields: `entry.completedQuestCount = ...` (line 302), `entry.harmonyScore = ...` (line 305), `entry.currentStreak = ...` (line 311), `entry.echoCountdowns = ...` (line 314), `entry.threadNames = ...` (line 330), `entry.seasonName = ...` (line 335), `entry.amplifierName = ...` (line 338). All fields declared `let` (lines 198-199). **Compile errors.**
  2. References `context.threads` (line 330) — `LifeContext` has no `threads` member (verified by full-codebase grep: only comments mention "threads", no stored property).
  3. References `context.currentSeasonName` (line 335) — `LifeContext` has `currentSeason: String` (line 102 of LifeContext), not `currentSeasonName`.
  4. References `context.activeAmplifierName` (line 338) — `LifeContext` has no `activeAmplifierName` (verified by full-codebase grep).
  5. `context.threads.filter { !$0.title.isEmpty }.map { $0.title }` — `BasicSelfThread` has `name`, not `title` (BasicSelfThread.swift:22).
- **Severity justification**: FamilyPod is the **3rd most-connected god node (35 edges)** per Graphify. Entire feature is non-functional. Cannot compile.
- **Fix (multi-step)**:
  - Change `FamilyPodDigestEntry` fields to `var`
  - Add `threads: [BasicSelfThread]`, `currentSeasonName: String` (computed), `activeAmplifierName: String?` (computed) to `LifeContext`
  - Use `context.threads.map { $0.name }` instead of `.title`
  - OR: rewrite builder to use only existing `LifeContext` API surface (safer: surface area increase is bigger risk than builder refactor)

### CLAUDE-R3-23 — `CognitiveLoad` uses `objc_*AssociatedObject` with `Foundation` only [HIGH/blocker]
- **File**: Sources/OneWeave/CognitiveLoad.swift:43, 484-492
- **Issues**:
  1. `import Foundation` only, but uses `objc_getAssociatedObject` / `objc_setAssociatedObject` / `_previousCognitiveLoadKey` (an UnsafeRawPointer fileprivate static).
  2. These symbols live in `ObjectiveC` framework. On iOS this works transitively through Foundation; on **Linux the file explicitly targets, `ObjectiveC` framework is unavailable** → build break.
  3. Using associated objects on a SwiftData `@Model` (`LifeContext`) bypasses `ModelContext` isolation — **not thread-safe**, risks orphaned state if `ModelContext` rolls back the underlying object.
- **Severity justification**: Linux build break the file claims to support. Thread-unsafe ephemeral state on SwiftData model violates "use SwiftData, not side-channels" principle.
- **Fix**: Move `_previousCognitiveLoad` to a stored property on `LifeContext` (e.g. `var previousCognitiveLoadReading: CognitiveLoadReading? = nil`). Remove the associated-object extension entirely.

## Other notable findings (28 total across the files)

### Privacy (4 findings)
- **CLAUDE-R3-21** [MEDIUM]: FamilyPod digest `threadNames` (line 328-333) exposes **all** thread names regardless of per-thread opt-in. Comment says "Thread titles only — never reflection text" but doesn't address that thread names can encode sensitive topics ("Therapy", "Job search", etc.).
  - **Fix**: Add per-thread `isPodShareable: Bool` field, filter before map.
- **CLAUDE-R3-28** [MEDIUM]: CommandPalette stores verbatim reflection plaintext in `essenceLedger.append("+\(10) for quest complete with reflection")` via the `reflection` payload (line 457). The ledger is read by DebugStats and could be exported.
  - **Fix**: Store reflection hash (SHA256 prefix) instead of plaintext, OR redact in ledger.
- **CLAUDE-R3-4** [MEDIUM]: `GraphInsightGenerator` line ~290 (`detectContradictions`) takes private entity titles into shareable P2P insight payloads without filtering by privacy tier.
  - **Fix**: Filter `entities` by `entity.privacyTier <= context.dataLeash.sharedMaxTier` before assembling insight payload.
- **CLAUDE-R3-29** [LOW]: `InvisibleMentor.synthesize` (no findings on logic) — but the `mentorSeeds()` from DecisionLog passes full decision `reasoning` field, which can contain PII. Verify it's stored only in `isUserReflection==true` entities (verified — appears correct).

### Crypto (SacredEcho/AppLifecycle) (4 findings)
- **CLAUDE-R3-9** [HIGH]: `SacredEcho.deriveKey(echoID:master:)` uses HKDF with salt derived from the **public `echoID` prefix** (first 8 bytes of the UUID). No real entropy and no domain separation.
  - **Fix**: Use random salt per-echo stored alongside ciphertext (nonce field already exists, can repurpose for `keyDerivationSalt`).
- **CLAUDE-R3-10** [HIGH]: `SacredEcho.seal(..., seed: Data)` and `open(..., seed: Data)` accept a `seed:` injection parameter for testing, but the parameter is **not** `#if DEBUG`-gated. Production callers could pass arbitrary seed and bypass Keychain-vault path entirely. Same bypass class as the previously-fixed `nowOverride`.
  - **Fix**: Wrap both signatures in `#if DEBUG` overloads; production path uses only `vaultSeed()`.
- **CLAUDE-R3-14** [MEDIUM]: `AppLifecycleCoordinator.encryptedEnvelopeKey` is a single static key reused for every save. No per-save salt, no rotation.
  - **Fix**: Derive per-save key via HKDF from vault seed + per-save random salt (mirror SacredEcho pattern).
- **CLAUDE-R3-11** [MEDIUM]: **Possibly already fixed**. Keychain-write failure handling — confirm by reading SacredEcho.swift vaultSeed current impl (was fixed in cycle as `vaultSeed() throws`).

### Correctness/perf (6 findings)
- **CLAUDE-R3-6** [MEDIUM]: `LifeRelationship` has no `deleteRule` declared. Orphaned rows could reference deleted (possibly private) entities. Privacy leak: querying relationships returns ghost pointers to entities that should be inaccessible.
  - **Fix**: `@Relationship(deleteRule: .cascade, inverse: \LifeEntity.relationships)` on `LifeRelationship.fromEntity` and `toEntity`.
- **CLAUDE-R3-33** [MEDIUM]: `LivingGraphLoom.makeState` recomputes full polar placement (loom geometry) at 15fps on the main thread. For graphs >100 entities this is wasteful.
  - **Fix**: Recompute only on entity count change; cache layout keyed by `(entityCount, windowSize)` tuple.
- **CLAUDE-R3-27** [MEDIUM]: CommandPalette `kind: .logWeave` (line 103-108) — "Weave queued. Reflection required; essence only awarded after commit." but the pending action is **never committed** anywhere in the file. The flow ends at `pendingAction = ...` and the user has no UI to actually submit the reflection.
  - **Fix**: Either commit immediately (with reflection gate check) or surface a sheet from `CompassView` when `pendingAction != nil`.
- **CLAUDE-R3-7** [LOW]: `LifeGraphEngine.addEntity` doesn't check for duplicate IDs.
- **CLAUDE-R3-12** [LOW]: `pushSnapshotToWidgets` calls `OneWeaveSnapshotStore.shared.write` without batching on rapid-fire updates (e.g., during onboarding burst).
- **CLAUDE-R3-31** [LOW]: `InvisibleMentor` synthesis loop has no `max iterations` guard; a cyclic pattern detector could loop indefinitely.

### App Store / Mac side (3 findings)
- **CLAUDE-R3-13** [HIGH]: AppShortcutsProvider not implemented. AppIntents (LogWeaveIntent, CompleteQuestIntent, ShowHarmonyIntent) are declared but no `AppShortcutsProvider` aggregates them. Siri will not surface them.
  - **Fix**: Add `struct OneWeaveAppShortcuts: AppShortcutsProvider { static var appShortcuts: [AppShortcut] { [...] } }`.
- **CLAUDE-R3-25** [MEDIUM]: `OneWeaveWidgetStubs.swift` is a stub file. The actual Widget Extension target doesn't exist. Cannot ship without it.
  - **Fix**: Create widget target in Xcode with App Group `group.com.oneweave`.
- **CLAUDE-R3-26** [LOW]: `PRIVACY.md` uses marketing language ("Never logged. Never shared.") but the actual implementation has `essenceLedger` and `pushSnapshotToWidgets` — needs accuracy pass.

### Clean / no findings
- `InvisibleMentor.swift` — no new findings; consent/leash gates intact.
- `PortableExport.swift` — no new findings; 3-leash gate correct.

## Process recommendation

Findings 1–5 (especially #1, #2, #3, #5) only surface under a real compiler/unit test. The Mac coworker's **first action should be `xcodebuild` on the real target** to catch all compile-blockers as a batch before applying fixes.

This is exactly the gap Nemotron's report quantified: Linux Python mirrors are useful for **algorithm and policy validation** but cannot substitute for **compiler and type-system validation**. The Mac coworker's brief should explicitly call out: "Run `xcodebuild` first, expect compile errors, treat those as the top-priority backlog before any feature work."

## Counters (independent verification)

| Finding | My initial belief | Verified against source | Verdict |
|---|---|---|---|
| CLAUDE-R3-1: reflection gate on completeQuest | "Reflection gate works" | Line 441 has no gate; comment claims one | **REAL** |
| CLAUDE-R3-2: changeSeason bypasses gate | "Season change has burst gate" | Line 108 awards +20 unconditionally; gate flag never checked | **REAL** |
| CLAUDE-R3-3: GraphInsightGenerator `.balanced` | "EnergyProfile compiles" | Line 344 has `.balanced`; type has no such case | **REAL** |
| CLAUDE-R3-18/19/20: FamilyPod | "FamilyPod works" | All 5 sub-claims verified against source | **REAL** |
| CLAUDE-R3-23: CognitiveLoad objc | "Linux-compatible" | `import Foundation` only; objc_* not on Linux | **REAL** |

**5 of 5 top findings verified.** None hallucinated. **This review is a critical input** — fixing the reflection-gate bypasses (#1, #2) is more important than any new feature added since cycle 24.