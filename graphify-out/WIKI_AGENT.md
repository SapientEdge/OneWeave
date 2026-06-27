# OneWeave Knowledge Graph Wiki (Agent Edition)

**Generated**: 2026-06-27 · **Source**: Graphify v0.8.45
**Stats**: 2591 nodes · 4298 edges · 179 communities · 98% EXTRACTED (high confidence)

**How to use this doc**: This is the condensed context for delegated agents (Grok, Claude Code, Nemotron). Read this FIRST before reading individual Swift files. Each section links to the most relevant source files.

---

## Top 30 God Nodes (Most Connected)

These are the abstractions that everything else depends on. Changes here ripple through the whole system.

| Rank | Node | Degree | Primary File |
|---:|---|---:|---|
| 1 | `String` (type) | 96 | (system) |
| 2 | `Codable` (protocol) | 54 | (system) |
| 3 | `Equatable` (protocol) | 40 | (system) |
| 4 | `Foundation` | 36 | `iOSServiceIntegrations.swift` |
| 5 | `SwiftData` | 36 | `iOSServiceIntegrations.swift` |
| 6 | **`FamilyPod`** | **35** | `FamilyPod.swift` |
| 7 | `View` | 33 | `OneWeavePrototype.swift` |
| 8 | **`LifeContext`** | **31** | `LifeContext.swift` |
| 9 | `SwiftUI` | 25 | `WeaveSummaryView.swift` |
| 10 | `OneWeave — Complete Feature Catalog` | 25 | `FEATURE_CATALOG.md` |
| 11 | `validate_family_pod.py` | 23 | `.research/validate_family_pod.py` |
| 12 | `String` (in SchemaMigration) | 23 | `SchemaMigrationPlan.swift` |
| 13 | `OneWeave Life OS Build Log` | 23 | `.research/build_log.md` |
| 14 | **`BasicSelfThread`** | **22** | `BasicSelfThread.swift` |
| 15 | `UUID` | 22 | `SchemaMigrationPlan.swift` |
| 16 | **`BriefingSection`** | **21** | `DailyBriefings.swift` |
| 17 | **`CareKinThread`** | **21** | `CareKinThread.swift` |
| 18 | `Double` | 21 | `LoomGeometry.swift` |
| 19 | `OneWeaveWidgetStubs.swift` | 19 | (file itself) |
| 20 | `CaseIterable` | 19 | (system) |
| 21 | `ThreadDetailView` | 19 | `ThreadDetailView.swift` |
| 22 | `validate_portable_export.py` | 18 | `.research/validate_portable_export.py` |
| 23 | **`SchemaMigrationPlan.swift`** | **18** | (file itself) |
| 24 | **`LifeEntity`** | **18** | `LifeGraph.swift` |
| 25 | **`DecisionRecord`** | **17** | `DecisionLog.swift` |
| 26 | **`ExportLeash`** | **17** | `PortableExport.swift` |
| 27 | **`.invalidateCache()`** | **17** | `GraphInsightGenerator.swift` |
| 28 | `OneWeave Launch Checklist` | 17 | `LAUNCH_CHECKLIST.md` |
| 29 | `validate_daily_briefings.py` | 16 | `.research/validate_daily_briefings.py` |
| 30 | **`PodVisibilityGrant`** | **16** | `FamilyPod.swift` |

**BOLD = business-logic nodes, not system types. These are the review targets.**

---

## Architecture Overview (from graph communities)

### Community 0 — Core Domain (LifeContext + 4 Threads)
- **Files**: `LifeContext.swift`, `BasicSelfThread.swift`, `StewardshipThread.swift`, `CareKinThread.swift`, `MeaningThread.swift`, `Thread.swift`
- **Role**: Aggregate root + 4 thread models
- **Review focus**: thread interconnections, energy/harmony propagation, streak grace logic

### Community 2 — Cryptography & Sacred Echo
- **Files**: `SacredEcho.swift`, `SacredEchoCipher`, `SacredEchoStore`, `MentorEchoBridge.swift`
- **Role**: AES-256-GCM encrypted time-capsule messages
- **Review focus**: fail-closed crypto, no plaintext on disk, vault seed lifecycle

### Community 6 — Family Sharing
- **Files**: `FamilyPod.swift`, `FamilyPodPolicy`, `FamilyPodDigestBuilder`, `FamilyPodDigestRedactor`
- **Role**: Anti-social family sharing (≤6, quiet hours, cooldown)
- **Review focus**: privacy defaults, member visibility grants, digest redactor

### Community 22 — Onboarding & Lifecycle
- **Files**: `OneWeaveApp.swift`, `AppLifecycleCoordinator.swift`, `OnboardingView.swift`
- **Role**: App entry, scenePhase routing, encrypted envelope persistence
- **Review focus**: background→foreground state, vault seed unlock flow

### Community 33 — Privacy & Data Leash
- **Files**: `DataLeashSettings.swift`, `DataLeashSettingsView.swift`, `iOSServiceIntegrations.swift`, `LifeGraphiOSIntegrations.swift`
- **Role**: 9-toggle privacy control, read-live-before-call pattern
- **Review focus**: fail-closed defaults, every integration call path

### Community 35 — iOS Framework Integrations
- **Files**: `iOSServiceIntegrations.swift` (Calendar, Contacts, HealthKit, Reminders, Mail, Notes)
- **Role**: 6 iOS frameworks wrapped with reflection gates + Data Leash checks
- **Review focus**: thread-safety, async correctness, permission strings

### Community 41 — Living Graph Loom
- **Files**: `LivingGraphLoom.swift`, `LoomGeometry.swift`
- **Role**: Breathing constellation visualization of Life Graph
- **Review focus**: polar layout math, Canvas perf, edge labels, animation

### Community 36 — Insights & Cross-Domain
- **Files**: `GraphInsightGenerator.swift`, `InsightGenerator.swift`
- **Role**: Cache + contradiction detection + reflection-gated application
- **Review focus**: cache invalidation paths, @MainActor discipline, contradiction rules

### Community 12 — Schema & Migrations
- **Files**: `SchemaMigrationPlan.swift`, `OneWeaveSchemaV1/V2/V3`
- **Role**: V1↔V2↔V3 SwiftData migration logic
- **Review focus**: atomic migrations, rollback support, version hashing

### Community 26 — Gamification
- **Files**: `EssenceLedgerView.swift`, `MasteryMapView.swift`, `WeaveQuest.swift`, `QuestService.swift`, `QuestsView.swift`
- **Role**: Calm gamification (essence, mastery tiers, streaks with grace)
- **Review focus**: anti-addictive mechanics, reflection-gated rewards

---

## High-Degree Bridges (Cross-Community Coupling)

These nodes appear in MANY communities — they're the "connective tissue" of the system. Changing them risks breakage elsewhere.

### `Foundation` (36 edges, betweenness 0.070)
Connects 16 communities. Foundation is the framework; modifications affect every file that imports it.

### `SwiftData` (36 edges, betweenness 0.053)
Connects 13 communities. Any change to `@Model` definitions, `FetchDescriptor`, or schema versioning affects:
- LifeGraph.swift (4 entities)
- SacredEcho.swift (1 entity)
- WeaveQuest.swift (1 entity)
- LifeContext.swift (aggregate)
- AppLifecycleCoordinator.swift (envelope)
- DataLeashSettings.swift (settings record)
- All 4 Thread.swift files
- TimelineEvent.swift
- DataSeeder.swift

### `FamilyPod` (35 edges, betweenness 0.052)
Connects 4 communities. FamilyPod is unexpectedly central — touches Privacy, Sharing, Digest, Member management. Any change to its API breaks FamilyPodPolicy, FamilyPodDigestBuilder, FamilyPodDigestRedactor.

---

## Surprising Connections (Review for Hidden Coupling)

These edges appeared in the graph but weren't obvious from the source code. Worth a closer look:

### FamilyPod validator → FamilyPod types
`validate_family_pod.py` has 35 edges into `FamilyPod.swift` types. This means the validator mirrors the public API very closely — if you change `FamilyPod` API, the validator MUST be updated in lockstep. **Caught the whitespace-name bug this way.**

### `BriefingSection` ↔ `DailyBriefings.swift` ↔ `LifeContext` ↔ `OneWeaveSnapshotStore`
Briefing data flows from LifeContext → DailyBriefings generator → snapshot → widget. This is the chain that powers the home-screen widget. Any break here = no widget.

### `DecisionRecord` ↔ `DecisionLog.swift` ↔ `MentorEchoBridge` ↔ `InvisibleMentor`
The bridge between "what I decided" and "what my past self would say." This is the unique-value chain. If it breaks, the Invisible Mentor loses its source of wisdom.

### `ExportLeash` ↔ `PortableExportBuilder` ↔ `PortableExportPolicy` ↔ `PortableImportPolicy`
The privacy-leash export system. 3 leashes × 3 formats = 9 export paths. The validator covers all 9.

### `SchemaMigrationPlan.swift` ↔ `OneWeaveSchemaV1/V2/V3`
Atomic migration logic. Critical for upgrade safety. Validator covers V1↔V2↔V3 roundtrips.

---

## Isolated / Weakly-Connected Nodes (1104 nodes)

These have ≤1 connection. Most are:
- Documentation files (markdown)
- Validation script internals
- Stubs and fake types (`FakeTimelineEvent`, `FakeQuest`, `FakeThread`, `FakeBodyThread`)
- Individual enum cases

**Not concerning for review** — these are either documentation or test scaffolding.

---

## Suggested Review Questions for Agents

When dispatching to Grok/Claude/Nemotron, use these questions based on graph findings:

1. **`FamilyPod` is the 3rd most-connected node** — is the public API complete? Are there hidden invariants that should be documented?

2. **`LifeContext` at 31 edges** — is the energy/harmony propagation logic testable? Are there race conditions in `@Published` updates?

3. **The 5 gate types (Reflection, DataLeash, Consent/isUserReflection, SacredEcho unlock, Fail-closed crypto)** are documented in the white paper as the "5 privacy gates." Are they ALL enforced at the right call sites?

4. **Sacred Echo crypto stack** uses AES-256-GCM + HKDF-SHA256. Is the key derivation correct? Is the nonce random? Is the auth tag verified on open?

5. **Widget snapshot chain** (`commitWeave` → `pushSnapshotToWidgets` → `OneWeaveSnapshotStore` → `HarmonyWidget`) — is the snapshot atomic? Can partial writes leave the widget in an inconsistent state?

6. **The validator→source coupling** is strong (35 edges from `validate_family_pod.py` to FamilyPod types). Are all validators in sync with their corresponding source? Any that drifted?

7. **The 5 reflection-gated paths** (`commitWeave`, `completeQuest`, `applyInsight`, `sealEcho`, `applyDecision`) — does each one properly block empty `reflectionText`?

8. **The 9 Data Leash categories** — are ALL of them checked at the right call sites? Any code path that reads data without checking the leash first?

---

## Communities Index (179 total, 171 shown)

For full per-community detail, see `GRAPH_REPORT.md`. Most important communities are listed above. Thin communities (<3 nodes) omitted.

---

## How to Query the Graph

```bash
# Find shortest path between two nodes
graphify path "SacredEchoCipher" "LifeContext"

# Explain a node's neighborhood
graphify explain "FamilyPod"

# Diagnose multigraph edge collapse risk
graphify diagnose multigraph

# Benchmark token reduction
graphify benchmark
```

---

*This wiki is the agent-facing compression of the OneWeave knowledge graph. For full data, see `graphify-out/graph.json` (553 KB), `GRAPH_REPORT.md` (15 KB), and `manifest.json` (9 KB).*