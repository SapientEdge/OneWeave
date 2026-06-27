The Write tool needs your approval to create the report file (`/root/hermes-workspace/projects/oneweave/.research/REVIEW_ROUND_3_CLAUDE.md`). It's currently blocked on a permission prompt — please approve it and I'll re-run the write.

In the meantime, here's the completed review so nothing is lost. I read all 13 source files plus the constitution, spec 003, WIKI_AGENT, and CONVENTIONS, and verified the compile-break findings against the wider tree with grep/sed.

## Top findings

**CRITICAL (won't compile / breaks an invariant)**

- **CLAUDE-R3-29 · GraphInsightGenerator.swift:341-346** — `switch context.energyProfile` uses `.balanced`, which doesn't exist on `EnergyProfile` (`low/normal/high`, defined LifeContext.swift:535). Verified `.balanced` appears nowhere else. Won't compile.
- **CLAUDE-R3-22 · PortableExport.swift:264,273,337,347-350** — references `entity.kind`, `rel.kind`, `rel.fromEntityID`, `rel.toEntityID`; none exist on `LifeEntity`/`LifeRelationship` (they're `type`, `fromEntity?`, `toEntity?`). Verified `kind`/`*EntityID` exist only on SchemaMigration DTOs. Won't compile.
- **CLAUDE-R3-7 · BodyThreadWeaver.swift:46,60 vs LifeGraph.swift:34** — `attributes` was migrated to `[String:String]`, but BodyThreadWeaver still assigns a `String` (`self.attributes = json`) and calls `attributes.data(using:.utf8)`. Won't compile.
- **CLAUDE-R3-1 · LifeContext.swift:440-459** — `completeQuest` awards essence with **no empty-reflection guard**; verified its only caller `QuestService.completeWithReflection` doesn't gate either. The flagship reflection-gate invariant is unenforced on the most common action.

**HIGH**

- **CLAUDE-R3-23 · PortableExport.swift:391-406** — full-bundle export decrypts **sealed, not-yet-unlocked** Sacred Echoes to plaintext, bypassing the time-capsule unlock gate (spec US2).
- **CLAUDE-R3-34 · AppLifecycleCoordinator.swift:504-513** — foreground echo re-evaluation only fires when backgrounded **< 5 minutes**; the window is inverted, so overnight unlocks are never re-evaluated.
- **CLAUDE-R3-26 · iOSServiceIntegrations.swift:153-156** — Contacts import calls `requestAccess()` **before** the Data Leash check, violating the leash-first invariant that Calendar/Reminders enforce.
- **CLAUDE-R3-10 · SacredEcho.swift:254-263** — on Keychain-persist failure, `vaultSeed()` returns a random unpersisted key, silently sealing unrecoverable echoes (not fail-closed).
- **CLAUDE-R3-16 · CognitiveLoad.swift:483-492** — uses ObjC associated objects on a `@Model` with only `import Foundation`; won't build on Linux, not thread-safe, invisible to SwiftData.

**MEDIUM**: R3-2/R3-3 (season-change burst not reflection-gated), R3-4 (essence double-counted on `aggregateFromRecentEvents`), R3-5 (snapshot store write off-main), R3-14 (Mentor no relevance floor), R3-17 (`totalWeight` "asserted" but never is), R3-24/R3-25 (export collapses the 3-tier privacy model; weakest gate on most-sensitive bundle), R3-27 (unstable `hashValue` redaction), R3-31 (Command Palette season bypass), R3-37 (Loom coherence remap collapses radius range), R3-39 (Loom re-lays-out every frame at 15fps).

**Strongest code**: `GraphInsightGenerator.applyInsight`, `SacredEchoStore.open`, the Family Pod policy/redactor layer, and the Cognitive Load pure calculator — these correctly trim+gate, fail closed, and isolate side effects.

The full per-file report (40 findings, CLAUDE-R3-1 through R3-40, with fixes) is ready to write as soon as you approve the file permission.
 the crypto items only surface under a real compiler/unit test. The Mac coworker's **first action should be `xcodebuild` on the real target** to catch all compile-blockers as a batch before applying fixes.

Want me to save this to `.research/REVIEW_ROUND_3_CLAUDE.md` (the full version has every finding in the required ID/severity/location/issue/fix/privacy format)?
