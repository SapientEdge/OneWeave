# LifeMoment — Tasks

**Cycle:** 046-lifemoment
**Total tasks:** 32 (each ≤ 2hr focused work; many delegatable)
**Pattern:** TDD where applicable (Python validator first, then Swift impl)
**Each task:** description · files · acceptance · dependencies · complexity (S/M/L)

---

## Phase A — Foundation (8 tasks)

### T-A1: Constitution v2.1 amendment
- **Status:** ✅ DONE (commit 8de2fe9)
- Files: `.specify/constitution.md`
- Acceptance: Principle 8, Invariant 11, Invariant 7a added; v2.1 noted
- Complexity: S

### T-A2: LifeMoment @Model definition
- **Status:** ✅ DONE (commit 8de2fe9)
- Files: `Sources/OneWeave/LifeMoment.swift`
- Acceptance: All fields present; whitespace-trim check; typed errors
- Complexity: M

### T-A3: SchemaMigrationPlan — OneWeaveSchemaV4 + stage + VoidEntry
- Files: `Sources/OneWeave/SchemaMigrationPlan.swift`
- Acceptance: V4 enum with all 12 models (incl. LifeMoment) + VoidEntry; `.lightweight(fromVersion: V3, toVersion: V4)` stage; V4 in `OneWeaveMigrationPlan.schemas`
- Dependencies: T-A2
- Complexity: M

### T-A4: iOSServiceIntegrations — add `IntegrationCategory.photos`
- Files: `Sources/OneWeave/iOSServiceIntegrations.swift`
- Acceptance: `case photos` added; default-off in `DataLeashSettingsRecord` migration
- Dependencies: T-A1 (constitution Invariant 7a must exist)
- Complexity: S

### T-A5: OneWeaveApp — register LifeMoment in BOTH modelContainer arrays
- Files: `Sources/OneWeave/OneWeaveApp.swift` (lines 14 + 165)
- Acceptance: `LifeMoment.self` in both `modelContainer(for:)` arrays; VoidEntry present
- Dependencies: T-A3, T-A4
- Complexity: S

### T-A6: validate_life_moment_model.py
- Files: `.research/validate_life_moment_model.py`
- Acceptance: Verifies all fields, types, defaults, whitespace-trim check, sealed fields, typed errors
- Dependencies: T-A2
- Complexity: M

### T-A7: validate_schema_migration.py — extend for V3→V4 + VoidEntry
- Files: `.research/validate_schema_migration.py`
- Acceptance: New test cases for V3→V4 lightweight + VoidEntry presence in all schemas
- Dependencies: T-A3
- Complexity: M

### T-A8: validate_moment_photos_integration.py + validate_moment_storage_scaling.py
- Files: `.research/validate_moment_photos_integration.py`, `.research/validate_moment_storage_scaling.py`
- Acceptance: Photos toggle gate works; externalStorage attribute present; 10k moments budget < 100MB
- Dependencies: T-A2, T-A4
- Complexity: M

**Phase A exit:** 5 files modified/created, 3 new validators green.

---

## Phase B — Crypto + Vision (6 tasks)

### T-B1: VisionPipeline.swift — OCR + language detection + PII strip
- Files: `Sources/OneWeave/VisionPipeline.swift`
- Acceptance: `#if canImport(Vision)` gated; resize > 20MB rejects; OCR returns (text, confidence); PII strip applied (credit card/SSN/phone/email)
- Dependencies: T-A
- Complexity: L

### T-B2: MomentPayload + SealedMoment structs
- Files: `Sources/OneWeave/MomentSealer.swift`
- Acceptance: Codable structs; `MomentPayload { ocrText, imageEmbeddingText, sealedAt }`; `SealedMoment { ciphertext, nonce, tag, sealedAt }`
- Dependencies: T-A2
- Complexity: S

### T-B3: MomentSealer — vaultSeed + perMomentKey + seal/open
- Files: `Sources/OneWeave/MomentSealer.swift`
- Acceptance: Mirror SacredEchoCipher pattern; Keychain seed; `#if DEBUG` Linux test seed gated; HKDF info "OneWeaveMoment.v1"; fail-closed on random failure
- Dependencies: T-B2
- Complexity: M

### T-B4: LifeMomentService.swift skeleton — @MainActor enum + capture signature
- Files: `Sources/OneWeave/LifeMomentService.swift`
- Acceptance: `@MainActor enum`; `capture(imageData: Data, userReflection: String?)` signature only (body expanded in Phase C)
- Dependencies: T-A2
- Complexity: S

### T-B5: validate_vision_pipeline.py
- Files: `.research/validate_vision_pipeline.py`
- Acceptance: Mock OCR pipeline; PII regex tests; resize limits; confidence scoring
- Dependencies: T-B1
- Complexity: M

### T-B6: validate_moment_cipher.py + validate_moment_seal_roundtrip.py
- Files: `.research/validate_moment_cipher.py`, `.research/validate_moment_seal_roundtrip.py`
- Acceptance: HKDF isolation verified; tamper detection; seal→unseal round-trip; sealed moment plaintext reflection stays searchable
- Dependencies: T-B3
- Complexity: M

**Phase B exit:** 3 new Swift files, 3 new validators green.

---

## Phase C — Service + Gamification + Egress (9 tasks)

### T-C1: LifeMomentService — capture() full impl
- Files: `Sources/OneWeave/LifeMomentService.swift`
- Acceptance: Photos toggle gate; size check; Vision OCR; PII strip; embedding via OnDeviceEmbedder; persist; NO TimelineEvent emitted
- Dependencies: T-B1, T-B4
- Complexity: L

### T-C2: LifeMomentService — seal/unseal
- Files: `Sources/OneWeave/LifeMomentService.swift`
- Acceptance: Encrypt (ocrText + imageEmbeddingText) into sealedCiphertext/Nonce/Tag; decrypt reverses; userReflection stays plaintext
- Dependencies: T-B3
- Complexity: M

### T-C3: LifeMomentService — attachToThread + promoteToQuest
- Files: `Sources/OneWeave/LifeMomentService.swift`
- Acceptance: attachToThread is silent (user already chose); promoteToQuest requires non-empty reflection (whitespace-trim); throws `LifeMomentError.emptyReflection` otherwise
- Dependencies: T-C1
- Complexity: M

### T-C4: LifeMomentService — search() (isolated)
- Files: `Sources/OneWeave/LifeMomentService.swift`
- Acceptance: Returns `[LifeMoment]` only; uses cosine similarity over OCR text embeddings; sealed moments searchable by `userReflection` only
- Dependencies: T-C1
- Complexity: M

### T-C5: P2P egress guard
- Files: `Sources/OneWeave/P2PWeaveShare.swift`
- Acceptance: Encode refuses to include `LifeMoment` OCR/embeddings/entities; userReflection OK
- Dependencies: T-C1
- Complexity: S

### T-C6: FamilyPod egress guard
- Files: `Sources/OneWeave/FamilyPod.swift`
- Acceptance: Pod digest excludes moment-inferred content
- Dependencies: T-C1
- Complexity: S

### T-C7: PortableExport + Snapshot filters
- Files: `Sources/OneWeave/PortableExport.swift`, `Sources/OneWeave/OneWeaveSnapshotStore.swift`
- Acceptance: fullBundle omits moment-inferred fields; widget snapshot never includes OCR
- Dependencies: T-C1
- Complexity: S

### T-C8: validate_moment_gamification.py + validate_moment_reflection_gate.py + validate_moment_graph_integration.py
- Files: `.research/validate_moment_gamification.py`, `.research/validate_moment_reflection_gate.py`, `.research/validate_moment_graph_integration.py`
- Acceptance: Zero TimelineEvent rows; zero essence delta; reflection gate enforced; linkedEntity nullify
- Dependencies: T-C1, T-C2, T-C3
- Complexity: M

### T-C9: validate_moment_egress.py + validate_moment_egress_p2p.py
- Files: `.research/validate_moment_egress.py`, `.research/validate_moment_egress_p2p.py`
- Acceptance: OCR/embedding NEVER in any cross-channel output; P2P/FamilyPod blocked
- Dependencies: T-C5, T-C6, T-C7
- Complexity: L

**Phase C exit:** Service complete; 5 egress/reflection validators green.

---

## Phase D — UI + Search (5 tasks)

### T-D1: LifeMomentCaptureView.swift
- Files: `Sources/OneWeave/LifeMomentCaptureView.swift`
- Acceptance: SwiftUI; camera + Photos picker; Photos toggle gate disables button if off; preview + capture button
- Dependencies: T-C1
- Complexity: M

### T-D2: LifeMomentReflectionSheet.swift
- Files: `Sources/OneWeave/LifeMomentReflectionSheet.swift`
- Acceptance: Modal editor; OCR preview; "Save without OCR" option; save→capture()
- Dependencies: T-D1
- Complexity: M

### T-D3: LifeMomentTimelineEntry.swift
- Files: `Sources/OneWeave/LifeMomentTimelineEntry.swift`
- Acceptance: Read-only display in Compass; sealed indicator; tap → detail
- Dependencies: T-A2
- Complexity: S

### T-D4: LifeMomentDetailView.swift
- Files: `Sources/OneWeave/LifeMomentDetailView.swift`
- Acceptance: Per-moment view; unseal button (if sealed); thread attach; promote-to-quest (with reflection gate)
- Dependencies: T-C2, T-C3
- Complexity: M

### T-D5: validate_moment_search.py
- Files: `.research/validate_moment_search.py`
- Acceptance: Returns only `[LifeMoment]`; sealed→reflection text only; OCR never in LifeGraph index
- Dependencies: T-C4
- Complexity: M

**Phase D exit:** 4 SwiftUI views; search validator green.

---

## Phase E — AppIntents + Photos + Adversarial (4 tasks)

### T-E1: MomentAppIntent.swift — SaveLifeMomentIntent
- Files: `Sources/OneWeave/MomentAppIntent.swift`
- Acceptance: AppIntent; perform() returns `IntentResult` (no OCR/embedding); params: asset URL + optional reflection
- Dependencies: T-C1
- Complexity: M

### T-E2: OneWeaveWidgetStubs.swift — register SaveLifeMomentIntent
- Files: `Sources/OneWeave/OneWeaveWidgetStubs.swift`
- Acceptance: SaveLifeMomentIntent added to AppShortcutsProvider
- Dependencies: T-E1
- Complexity: S

### T-E3: validate_moment_app_intent.py
- Files: `.research/validate_moment_app_intent.py`
- Acceptance: Intent perform returns minimal; no OCR in result; param validation
- Dependencies: T-E1
- Complexity: S

### T-E4: validate_moment_adversarial.py
- Files: `.research/validate_moment_adversarial.py`
- Acceptance: nil/empty/huge OCR; oversized image rejected; sealed+reflected round-trip; malformed momentKindRaw
- Dependencies: T-C1, T-C2
- Complexity: M

**Phase E exit:** AppIntents + adversarial validator green.

---

## Final Tasks (after Phase E)

### T-F1: graphify . --update + wiki refresh
- Files: `graphify-out/*`
- Acceptance: Wiki regenerated; new god nodes include LifeMoment
- Complexity: S

### T-F2: Cycle 46 handoff doc
- Files: `.research/ONEWEAVE_HANDOFF_CYCLE_46.md`
- Acceptance: TL;DR table; per-feature section; validator status; git history
- Complexity: S

### T-F3: Final validator run — all 13 new + 29 existing green
- Acceptance: OVERALL: PASS
- Complexity: S

---

## Total: 32 tasks across 5 phases + finalization
## Subagent delegation plan: parallel groups (A5+A6+A7+A8), (B1+B5), (C5+C6+C7), (D1+D2+D3+D4) all fire-and-forget
## CLI squad: invoked at phase boundaries for cross-review (Claude constitutional, Codex correctness, Kimi tests, GLM creative, Nemotron adversarial, Qwen heavy review)