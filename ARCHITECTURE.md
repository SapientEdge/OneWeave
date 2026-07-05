# OneWeave Architecture

A high-level map of the OneWeave module. Read [`MANIFEST.md`](./MANIFEST.md) for per-file details and [`OneWeaveAPI.swift`](./Sources/OneWeave/OneWeaveAPI.swift) for the public API catalog.

## Layered structure

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          OneWeaveApp (entry)                            │
│  • SwiftData ModelContainer (11 @Model types)                          │
│  • @Environment(\.scenePhase) → AppLifecycleCoordinator                │
└─────────────────────────────────────────────────────────────────────────┘
                                  │
        ┌─────────────────────────┼─────────────────────────────┐
        │                         │                             │
┌───────▼──────────┐    ┌─────────▼─────────┐         ┌─────────▼─────────┐
│  Core state      │    │  Creative features│         │  Privacy layer    │
│                  │    │                   │         │                   │
│ • LifeContext    │    │ • SacredEcho      │         │ • DataLeashSettings│
│ • LifeGraph      │    │ • InvisibleMentor │         │ • PrivacyTier     │
│ • TimelineEvent  │    │ • MentorEchoBridge│         │   (private/shared │
│ • WeaveQuest     │    │ • ResonanceOracle │         │    /public)       │
│ • 4 Thread types │    │ • BodyThreadWeaver│         │ • Data Leash gate │
└──────────────────┘    │ • LivingGraphLoom │         │   (BEFORE every   │
                        └───────────────────┘         │    integration)   │
                                                      └───────────────────┘
        ┌─────────────────────────┼─────────────────────────────┐
        │                         │                             │
┌───────▼──────────┐    ┌─────────▼─────────┐         ┌─────────▼─────────┐
│  Insights        │    │  P2P + Family     │         │  Export + Migrate │
│                  │    │                   │         │                   │
│ • GraphInsight   │    │ • P2PWeaveShare   │         │ • PortableExport  │
│   Generator      │    │ • FamilyPod       │         │ • SchemaMigration │
│ • @MainActor     │    │ • 5 quiet pillars │         │   Plan            │
│ • 5-min cache    │    │ • ≤6 members/cap  │         │ • 3 leashes       │
└──────────────────┘    └───────────────────┘         └───────────────────┘
```

## Data flow: write a reflection → see it reflected

```
User writes reflection
        │
        ▼
WeaveQuest.complete(reflectionText: "...")       [reflection gate #1]
        │
        ├─→ TimelineService.append(event)
        │
        ├─→ LifeContext.lifeGraphEntities.append(
        │       LifeEntity(
        │           kind: .task,
        │           summary: reflectionText,
        │           isUserReflection: true,        [consent gate #3]
        │           isPrivate: <from Data Leash>
        │       ))
        │
        ├─→ GraphInsightGenerator.invalidateCache()
        │
        └─→ OneWeaveSnapshotStore.pushSnapshot()  [widget sync]
```

## Data flow: receive a P2P share from a peer

```
Peer sends WeaveCircleShare
        │
        ▼
P2PWeaveShare.receiveAndIntegrate(...)
        │
        ├─→ Data Leash check: target category enabled?
        │       [data leash gate #2]
        │       └─→ if NO: drop silently
        │
        ├─→ if YES: hold in pendingIntegrations
        │           (NOT in lifeGraphEntities yet)
        │
        ▼
UI shows "1 pending weave, write a reflection to accept"
        │
        ▼
User writes reflection + taps Accept
        │
        ▼
P2PWeaveShare.drainPending(reflectionText: ...)
        │
        ├─→ [reflection gate #1 — empty text → nothing happens]
        │
        └─→ if non-empty: insert entities into lifeGraphEntities
                            with isUserReflection=false (it's not the user's
                            words; it's the peer's)
```

## The five privacy gates (type-level enforcement)

1. **Reflection gate** — every `commit`-shaped function takes a
   non-empty `reflectionText: String` argument. Empty → function throws
   or returns empty.
2. **Data Leash gate** — every integration path reads `DataLeashPolicy.
   currentLeash(in: modelContext)` BEFORE calling into EventKit /
   Contacts / HealthKit / etc. If the user's toggle is off, the function
   returns before any framework call.
3. **Consent gate** — `LifeEntity.isUserReflection: Bool` distinguishes
   user-authored content from system content. InvisibleMentor only
   synthesizes from `isUserReflection == true`.
4. **isUserReflection gate** — Sacred Echo plaintext is decrypted only
   when `unlockAt <= now`. Decrypted plaintext is never persisted in
   SwiftData attributes (only ciphertext + nonce + tag).
5. **Fail-closed crypto gate** — SacredEchoCipher generates a Keychain
   seed on first launch. No deterministic fallback in production code.
   The deterministic test seed is `#if !canImport(Security)` only.

## Threading model

- `@MainActor` — every UI-touching store / coordinator
  (SacredEchoStore, AppLifecycleCoordinator, GraphInsightGenerator,
  MentorEchoBridge convenience methods).
- Pure functions (no actor isolation) — renderers, validators, hashers,
  policy functions. These are unit-testable on Linux without a runtime.
- Background — P2P transport (Network framework, WebRTC) is owned by
  Apple frameworks; we do not wrap them in actors.

## Validation strategy on Linux

Because we can't run SwiftData or SwiftUI on Linux, every behavior that
doesn't depend on the Apple runtime is mirrored in Python:

- `.research/validate_tierA*.py` — Tier A features (Insight cache, iOS
  integrations, Sacred Echo, Mentor, App Lifecycle).
- `.research/validate_round2_loom.py` — Living Graph Loom.
- `.research/validate_mentor_bridge.py` — Mentor × Sacred Echo bridge.
- `.research/validate_family_pod.py` — Family Pod policy + builder.
- `.research/validate_portable_export.py` — Privacy-leash export.
- `.research/validate_schema_migration.py` — V1↔V3 attribute conversion.
- `.research/validate_stress.py` — 1k/10k entity stress harness.

Run them all: `bash .research/validate_all.sh`.

## Multi-agent review process

Three independent LLM agents have reviewed the codebase:

1. **Grok** (supergrok OAuth) — Tier A reviews + cycles 14-16.
2. **Claude Code** (opus, via PTY) — Cycles 14-16, Tier A + Round 2.
3. **Nemotron 3 Ultra** (via delegate_task) — Final review that caught
   the `LifeGraph.swift` duplicate-property compile bug.

Findings → applied → regression-tested → log appended to
`.research/build_log.md`. The process is repeatable; see
`.research/AGENT_SQUAD_PROMPTS.md` for the role-specialized prompts.

Every dispatch prepends `.research/NO_TRAINING_PROMPT.md` so all models
operate in private / no-training mode.

## Sub-agent infrastructure (cycle 47+)

All Hermes-global, NOT OneWeave-specific:

- `~/.hermes/scripts/cycle47/subagent_supervisor.py` — wraps sub-agents with pre-flight, hung-detection, marker counting. **Mandatory for sub-agents >10s.**
- `~/.hermes/scripts/cycle47/marker.py` — heartbeat emitters (call `start` / `checkpoint` / `end` at task boundaries)
- `~/.hermes/scripts/cycle47/subagent_wrapper.py` — lightweight wrapper for trivial sub-agents
- `~/.hermes/scripts/cycle47/hung_detector.py` — logs file poller, emits `HUNG_DETECTED`
- `~/.hermes/skills/subagent-hung-vs-done-check/SKILL.md` — Lesson 35.5 / 35.6

OneWeave-local copies exist at `scripts/cycle47/` for historical reference but are deprecated. Canonical: global.

Cycle 47 diagnosis (4 hypotheses tested, all REJECTED): cycle 46's 5 "hung" sub-agents were actually done — they had no progress markers + no automated detection, so silent periods looked identical to hangs. See `specs/047-subagent-reliability/cycle47_handoff.md`.