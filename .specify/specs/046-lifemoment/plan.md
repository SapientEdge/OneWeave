# LifeMoment — Implementation Plan

**Cycle:** 046-lifemoment
**Branch:** 002-gamification (continuing cycle 46 work)
**Constitution:** v2.1 (Principle 8 + Invariant 11 + Invariant 7a)
**Spec:** spec.md (11KB)
**Estimates:** 5 phases × ~250 LOC Swift + 13 Python validators = ~1,250 LOC + ~2,000 LOC Python
**Linux-first:** all validators green on Linux before Mac handoff
**Mode:** subagent-driven-development (2-stage review per task) + parallel CLI squad on demand

---

## Phase A — Foundation

**Goal:** Constitution amendment shipped, `@Model` defined, V4 schema migration, Photos Data Leash toggle, VoidEntry fix. NO OCR can persist without toggle.

### Files

| File | Action | LOC | Notes |
|---|---|---|---|
| `Sources/OneWeave/LifeMoment.swift` | DONE | 250 | Already shipped in commit 8de2fe9 |
| `.specify/constitution.md` | DONE | +16 | v2.1 amendment shipped |
| `Sources/OneWeave/SchemaMigrationPlan.swift` | MODIFY | +60 | Add OneWeaveSchemaV4, stage, VoidEntry |
| `Sources/OneWeave/iOSServiceIntegrations.swift` | MODIFY | +10 | Add `IntegrationCategory.photos` case |
| `Sources/OneWeave/OneWeaveApp.swift` | MODIFY | +4 | Register `LifeMoment.self` in BOTH modelContainer arrays + VoidEntry |
| `.research/validate_life_moment_model.py` | NEW | 150 | Schema field-by-field validation |
| `.research/validate_schema_migration.py` | MODIFY | +100 | Add V3→V4 lightweight stage + VoidEntry |
| `.research/validate_moment_photos_integration.py` | NEW | 120 | Photos toggle gate + PHAsset localIdentifier |
| `.research/validate_moment_storage_scaling.py` | NEW | 100 | externalStorage + 10k moments budget |

**Phase A exit criteria:**
- Constitution v2.1 in repo
- `LifeMoment` registered in V1-V4 schemas + both modelContainers
- `IntegrationCategory.photos` exists
- VoidEntry in all schemas
- 3 Python validators green
- `wc -l` of all modified files shows expected delta
- `git status -sb` clean for phase A

---

## Phase B — Crypto + Vision

**Goal:** `VisionPipeline` (Vision framework OCR), `MomentSealer` (AES-256-GCM with `OneWeaveMoment.v1` HKDF info), sealed storage round-trip works, OCR PII sanitization, platform gating (`#if canImport(Vision)`).

### Files

| File | Action | LOC | Notes |
|---|---|---|---|
| `Sources/OneWeave/VisionPipeline.swift` | NEW | 200 | Apple Vision OCR; `#if canImport(Vision)`; resize > 20MB; PII strip |
| `Sources/OneWeave/MomentSealer.swift` | NEW | 180 | Mirror SacredEchoCipher; `OneWeaveMoment.v1` HKDF info; `MomentPayload` struct; fail-closed |
| `Sources/OneWeave/LifeMomentService.swift` | NEW | 80 (skeleton, expanded in Phase C) | `@MainActor enum`; `capture(imageData:)` signature only |
| `.research/validate_vision_pipeline.py` | NEW | 200 | OCR confidence; empty handling; language detection; PII regex |
| `.research/validate_moment_cipher.py` | NEW | 220 | HKDF isolation; fail-closed on random failure; tamper detection |
| `.research/validate_moment_seal_roundtrip.py` | NEW | 180 | seal→unseal round-trip; sealed moment's plaintext reflection stays searchable |

**Phase B exit criteria:**
- `VisionPipeline.ocrAndSanitize(imageData:)` returns `(ocrText, confidence, entitiesJSON)` or throws
- `MomentSealer.seal(payload:)` → `unseal(sealed:)` round-trips losslessly
- Different moment IDs → different keys (HKDF isolation verified)
- Tampered ciphertext → throws
- 3 Python validators green

---

## Phase C — Service + Gamification + Egress

**Goal:** `@MainActor enum LifeMomentService` complete; reflection gate (whitespace-trim); egress boundary enforced for ALL channels (TimelineEvent, LifeGraph, Insight, PortableExport, Widget, AppIntents, **P2P**, **FamilyPod**); storage scaling validated.

### Files

| File | Action | LOC | Notes |
|---|---|---|---|
| `Sources/OneWeave/LifeMomentService.swift` | EXPAND | +250 | `capture`, `seal`, `unseal`, `attachToThread`, `promoteToQuest`, `search` |
| `Sources/OneWeave/Sources/P2PWeaveShare.swift` | MODIFY | +20 | Add moment-egress assertion (refuse sharing if moment inferred content present) |
| `Sources/OneWeave/Sources/FamilyPod.swift` | MODIFY | +15 | Add moment digest exclusion |
| `Sources/OneWeave/PortableExport.swift` | MODIFY | +10 | Filter out `LifeMoment` inferred content from `fullBundle` |
| `Sources/OneWeave/OneWeaveSnapshotStore.swift` | MODIFY | +5 | Filter moment fields from widget snapshot |
| `.research/validate_moment_gamification.py` | NEW | 150 | Create moment → assert ZERO TimelineEvent rows + essence/streak/mastery delta = 0 |
| `.research/validate_moment_egress.py` | NEW | 250 | OCR/embeddings NEVER in: TimelineEvent.summary, LifeEntity.summary, Insight strings, PortableExport, widget snapshot, AppIntent return |
| `.research/validate_moment_egress_p2p.py` | NEW | 200 | OCR/embeddings NEVER in P2PWeaveShare.encode payload + FamilyPod digest |
| `.research/validate_moment_reflection_gate.py` | NEW | 120 | promoteToQuest without reflection throws; attachToThread silent; seal silent; empty/whitespace rejected |
| `.research/validate_moment_graph_integration.py` | NEW | 120 | linkedEntity relationship; nullify on LifeEntity delete |

**Phase C exit criteria:**
- `LifeMomentService.capture(imageData:userReflection:)` returns `LifeMoment` and does NOT touch `LifeContext`/`TimelineService`/`updateFromEvent`
- All egress validators assert: no OCR/embedding/entities appear in any cross-channel output
- P2P + FamilyPod refuse sharing moment-inferred content (throws or strips)
- 5 Python validators green

---

## Phase D — UI + Search

**Goal:** Capture view, reflection sheet, timeline entry (read-only), isolated moment search using OCR text embedding.

### Files

| File | Action | LOC | Notes |
|---|---|---|---|
| `Sources/OneWeave/LifeMomentCaptureView.swift` | NEW | 220 | SwiftUI camera/picker; Photos library gate check; OCR preview |
| `Sources/OneWeave/LifeMomentReflectionSheet.swift` | NEW | 140 | Modal reflection editor; "Save without OCR" fallback |
| `Sources/OneWeave/LifeMomentTimelineEntry.swift` | NEW | 110 | Read-only display in Compass/Threads; shows sealed indicator |
| `Sources/OneWeave/LifeMomentDetailView.swift` | NEW | 180 | Per-moment view; unseal button (if sealed); thread attach |
| `.research/validate_moment_search.py` | NEW | 200 | Isolated moment search; sealed moments searchable by reflection text only |

**Phase D exit criteria:**
- Capture view respects `IntegrationCategory.photos` toggle (button disabled if off)
- Reflection sheet shows OCR preview + free-text field
- Timeline entry is read-only (no editing)
- Search returns only `[LifeMoment]` (never any `LifeEntity`)
- 1 Python validator green

---

## Phase E — AppIntents + Photos + Adversarial

**Goal:** `SaveLifeMomentIntent` (create-only), Photos picker integration with Data Leash, adversarial input handling.

### Files

| File | Action | LOC | Notes |
|---|---|---|---|
| `Sources/OneWeave/MomentAppIntent.swift` | NEW | 100 | AppIntent; perform() returns void; no OCR in result |
| `Sources/OneWeave/OneWeaveWidgetStubs.swift` | MODIFY | +30 | Register `SaveLifeMomentIntent` in AppShortcutsProvider |
| `.research/validate_moment_app_intent.py` | NEW | 120 | Intent perform() returns minimal; no OCR in result; no UIImage in params |
| `.research/validate_moment_adversarial.py` | NEW | 180 | nil/empty/huge OCR; oversized image rejected; sealed+reflected round-trip; malformed momentKindRaw |

**Phase E exit criteria:**
- AppIntent accepts only valid params (asset URL, optional reflection)
- Adversarial inputs handled gracefully (no crash, typed errors)
- 2 Python validators green

---

## Final Integration + Handoff

- All 13 new validators green + all 29+ existing OneWeave validators green
- `graphify . --update` run; wiki regenerated
- Cycle 46 handoff doc: `.research/ONEWEAVE_HANDOFF_CYCLE_46.md` (with TL;DR table, per-feature section, validator status, next-cycle candidates, git history)
- `tasks.md` updated with all T-IDs marked SHIPPED
- Commit history: 5 logical chunks (one per phase + one docs commit)
- OneWeave built + tested on Linux (Python mirrors); ready for Mac handoff

---

## Subagent Architecture (3 agents, ongoing)

### Agent 1: Coordinator (delegate_task, role=orchestrator)
- Routes tasks to CLI squad or direct edits
- Manages phase progression
- Synthesizes validator results
- Flags blockers
- Polls background processes

### Agent 2: Code Worker (delegate_task, role=leaf)
- Implements Swift + Python per task
- Runs TDD: failing test → impl → green test → commit
- Reports back file paths + LOC + tests
- Uses full context bundle (spec + plan + tasks + graphify wiki)

### Agent 3: Synthesizer (delegate_task, role=leaf)
- Reviews validator outputs
- Cross-references against spec + constitution
- Writes synthesis reports
- Identifies gaps for next phase

### CLI Squad (separate from internal delegates)
- Claude Opus: constitutional/privacy review
- Codex: Swift correctness
- Kimi: test design
- GLM 5.2: creative/naming
- Nemotron 3 Super: adversarial
- Qwen3-Coder 480B: heavy code review
- Grok: broken this session; documented