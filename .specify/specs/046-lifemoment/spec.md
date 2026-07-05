# Cycle 46 — LifeMoment (Native OneWeave Feature)

**Framing:** SnapKeep's capture-and-memory concept, reimagined as a native OneWeave feature. NOT a merge — no SnapKeep code imported. SnapKeep's ideas become inspiration for a new feature that lives inside OneWeave's existing architecture, conventions, and invariants.

**Inspired by SnapKeep's:** Photos/Vision/OCR pipeline, encrypted-at-rest storage, semantic search, Pockets-as-categories, "inference is suggestion" principle.
**Translated to OneWeave's:** LifeEntity + TimelineEvent, SacredEchoCipher, LifeGraph.semanticSearch, 4 Threads (not auto-assigned), reflection gates.

---

## User-facing concept (the elevator pitch)

> **LifeMoment** — a quick way to capture a snapshot of your life as it happens. Snap a photo, photo goes through Apple's Vision OCR (on-device, no network), you can write a short reflection right then, and it's preserved as a `LifeEntity` in your Life Graph. It stays free-floating — you decide later whether to attach it to a Thread, turn it into a Quest, or seal it into your Sacred Echo vault.

**Why this matters:** Right now OneWeave's `QuickCaptureInbox` is text-only. LifeMoment extends it to photos, with the same anti-addictive + reflection-first + on-device principles OneWeave already lives by.

---

## Design decisions (locked)

| Decision | Choice | Rationale |
|---|---|---|
| Thread assignment | **None (free-floating)** | User attaches manually; no algorithmic categorization |
| Storage | **Plaintext metadata by default; "Seal" upgrades to encrypted** | Fast search + user-controlled privacy |
| Encryption | **Reuse SacredEchoCipher** with HKDF info `"OneWeaveMoment.v1"` | No new cipher; same fail-closed crypto |
| Vision pipeline | **Apple Vision framework only** (OCR + iOS 17+ image embedding) | Same as SnapKeep, but inline in OneWeave |
| Gamification | **Never awards essence/streak/mastery automatically** | User must elevate a moment → reflection → quest for any gamification |
| Search | **Isolated `LifeMomentService.search()` (NOT extending `LifeGraph.semanticSearch`)** | Per GLM SPEC-3 HIGH: OCR/embeddings must not enter shared LifeGraph index |
| AppIntents | **"Save a LifeMoment" create-only** | No inferred-content return/donation |
| Inference confidence | **All Vision results stored with `inferenceConfidence`** | User can edit/promote/dismiss |
| Image size limit | **Reject images > 20MB at capture** | Per Qwen SPEC-6: prevent OOM / store bloat. Resize to max 4096px longest edge before OCR |
| OCR sanitization | **Strip PII patterns (credit card, SSN, phone, email) before storage** | Per Qwen SPEC-6: never persist raw sensitive regex matches. User can manually add back if intentional |
| Failed Vision UX | **"Try again" button + "Save without OCR" option** | Per Qwen SPEC-6: graceful degradation when Vision fails |
| Naming | **LifeMoment** (confirmed by GLM SPEC-5 + Qwen SPEC-5) | Fits "Life + [noun]" pattern alongside LifeEntity, LifeContext, LifeGraph, LifeThread |

---

## Architecture (native OneWeave, NOT SnapKeep import)

### Data model additions

```swift
// In Sources/OneWeave/LifeMoment.swift (new file, ~250 LOC)

@Model
public final class LifeMoment {
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date
    public var modifiedAt: Date

    // User-authored (may cross entity boundary)
    public var userReflection: String?
    public var momentKindRaw: String?
    public var userAssignedThreadRaw: String?

    // Vision-derived (NEVER cross — Invariant 11)
    public var ocrText: String?
    public var ocrConfidence: Double?
    @Attribute(.externalStorage) public var imageEmbeddingText: Data?  // OCR text embedded via OnDeviceEmbedder (text-only embedder — Claude SPEC-9)
    public var detectedEntitiesJSON: String?

    // Sealed moment storage (Claude SPEC-2)
    public var sealedCiphertext: Data?
    public var sealedNonce: Data?
    public var sealedTag: Data?
    public var sealedAt: Date?
    public var cipherHKDFInfo: String?  // = "OneWeaveMoment.v1"

    // Privacy gate (Claude SPEC-12: whitespace-trim check)
    public var isUserReflection: Bool

    // Relationships (Claude SPEC-8: sourceCaptureAsset is plain String, NOT @Relationship)
    @Relationship(deleteRule: .nullify) public var linkedEntity: LifeEntity?
    public var sourceCaptureAsset: String?  // PHAsset localIdentifier — plain attribute

    public init(userReflection: String? = nil) {
        id = UUID()
        createdAt = Date()
        modifiedAt = Date()
        self.userReflection = userReflection
        isSealed = false
        isUserReflection = Self.isNonEmptyReflection(userReflection)  // rejects "", whitespace
        // ... other fields default to nil
    }

    public static func isNonEmptyReflection(_ text: String?) -> Bool {
        guard let text = text else { return false }
        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
```

**Key reviewer-driven decisions baked into the model:**

- **`sourceCaptureAsset` is a plain `String?` attribute**, NOT a `@Relationship` (Claude SPEC-8 — `@Relationship` is only valid on `PersistentModel` types/collections, never on scalars). PHAsset localIdentifier is a value, not an edge.
- **`imageEmbeddingText` (renamed from `imageEmbedding`) holds the OCR text embedded via `OnDeviceEmbedder`** — a text-only embedder using `NLEmbedding.sentenceEmbedding` (Claude SPEC-9; verified `OnDeviceEmbedder.swift:102,125`). OneWeave has no image embedder today; the spec's earlier "Vision feature prints" was banned by Principle 3 ("no Core ML"). True image similarity is deferred to a separate decision.
- **Whitelist of inferred content that stays sealed**: only `sealedCiphertext/Nonce/Tag` are encrypted; `userReflection` and `userAssignedThreadRaw` stay plaintext (user-authored).
- **`isUserReflection` rejects empty/whitespace** via the `isNonEmptyReflection` static helper. Whitespace-only reflection does NOT flip the privacy gate (Claude SPEC-12).

### Sealed moment storage (Crypto extension)

Per Claude review SPEC-2 (HIGH): `SacredEchoCipher.perEchoKey` hardcodes HKDF info as `"SacredEcho.\(echoID.uuidString)"` (`SacredEcho.swift:306-315`) and `seal`/`open` take only `(plaintext, echoID, seed)` — no `info:` parameter. **Two options were considered; we chose the non-invasive sibling cipher:**

```swift
// Sources/OneWeave/MomentSealer.swift (~120 LOC — slightly larger to mirror SacredEchoCipher structure)
public enum MomentSealer {
    // Mirrors SacredEchoCipher.vaultSeed() pattern: Keychain-stored 256-bit
    // seed, fail-closed on Keychain failure, #if DEBUG Linux test seed
    // fallback gated to keep cycle 41 invariant #4 compliance.
    public static func vaultSeed() throws -> SymmetricKey

    // Derives a per-moment key from the vault seed + moment.id, using
    // HKDF info string "OneWeaveMoment.v1" — cryptographically isolated
    // from "SacredEcho.<id>" so moment keys and echo keys never collide.
    public static func perMomentKey(for momentID: UUID, seed: SymmetricKey) -> SymmetricKey

    // Seals (ocrText + imageEmbedding) as a single ciphertext blob.
    // Plaintext payload is encoded as JSON: {"ocr": "...", "emb": <base64>}
    // then sealed with AES-GCM. Returns ciphertext + nonce + tag.
    public static func seal(payload: MomentPayload, momentID: UUID, seed: SymmetricKey?) throws -> SealedMoment

    // Opens a sealed moment. Returns plaintext payload. Throws on tamper.
    public static func open(sealed: SealedMoment, momentID: UUID, seed: SymmetricKey?) throws -> MomentPayload
}

// Plaintext payload (OCR text + embedding, before sealing)
public struct MomentPayload: Codable {
    public let ocrText: String
    public let imageEmbedding: Data
    public let sealedAt: Date
}

// On-disk representation after sealing
public struct SealedMoment: Codable {
    public let ciphertext: Data
    public let nonce: Data
    public let tag: Data
    public let sealedAt: Date
}
```

`LifeMoment.isSealed = true` means `ocrText` + `imageEmbedding` are encrypted on disk via `MomentSealer`; `userReflection` stays plaintext (user-authored, OK to search). `cipherHKDFInfo = "OneWeaveMoment.v1"`.

**Constitutional compatibility:**
- Mirrors SacredEchoCipher's fail-closed pattern (`EchoError.cipherMissingKey` → `MomentError.cipherMissingKey`)
- `#if DEBUG` Linux test seed fallback gated per cycle 41 invariant #4
- New HKDF info string isolates moment keys from echo keys (no cross-decryption)

### Service layer

```swift
// Sources/OneWeave/LifeMomentService.swift
//
// Per Claude review SPEC-11: @MainActor, NOT plain actor. ModelContext
// and UIImage are not Sendable; returning a non-Sendable @Model across
// actor isolation is a strict-concurrency violation under Swift 6.
// OneWeave's proven pattern is @MainActor enums (SacredEchoStore).
// Image bytes cross isolation as Data (Sendable), not UIImage.

@MainActor
public enum LifeMomentService {
    private static let modelContext: ModelContext = ...
    private static let visionPipeline: VisionPipeline = ...
    private static let sealer: MomentSealer = ...
    private static let vaultSeed: SymmetricKey = ...  // from Keychain (shared seed)
    private static let embedder: OnDeviceEmbedder = ...  // text-only, OCR text embedding

    // Image passed as Data (Sendable) not UIImage (not Sendable).
    // All mutations to @Model happen on MainActor.
    public static func capture(imageData: Data,
                               userReflection: String?,
                               workDir: FileManager) async throws -> LifeMoment

    public static func seal(_ moment: LifeMoment) throws
    public static func unseal(_ moment: LifeMoment) throws -> (ocrText: String, embedding: Data)

    public static func attachToThread(_ moment: LifeMoment, thread: MomentThreadAssignment) throws
    // Reflection gate (Claude SPEC-12): throws on empty/whitespace reflection.
    public static func promoteToQuest(_ moment: LifeMoment, reflectionText: String) async throws -> WeaveQuest

    // Per Claude SPEC-3: dedicated moment search, NOT LifeGraph.semanticSearch.
    // Operates over [LifeMoment] only. OCR text never enters LifeEntity.
    public static func search(query: String, limit: Int) async throws -> [LifeMoment]
}
```

> **Privacy notes (per Claude + GLM reviews):**
> - `LifeMomentService.search()` runs entirely inside the LifeMoment sandbox. We do NOT extend `LifeGraph.semanticSearch` (which operates only on `[LifeEntity]`, per `LifeGraph.swift:354-358`) — that path would force OCR into a `LifeEntity` and break Invariant 11.
> - `LifeMomentService` has zero dependency on `TimelineService` or `updateFromEvent` — confirmed by grep + assertion in `validate_moment_gamification.py`. (Claude SPEC-4: the only way Principle 8 holds is if no `TimelineEvent` row is inserted on capture.)
> - All Vision/Photos access gated by the new 10th Data Leash toggle (`IntegrationCategory.photos`, added per Claude SPEC-10). Off → `PhotosDisabledError`.

### Constitution impact

**Additive amendment to OneWeave v2.0 → v2.1.** Per Claude review:

- **Principle 8 (Quiet Capture)** — new principle, fits between 7 and the existing principles
- **Invariant 11 (Moment Egress Boundary)** — new invariant (constitution invariants 1-10 unchanged; 11 is new)
- **Invariant 7a** — Data Leash amended from 9 → **10 toggles** (the new 10th is `photos`, covering Photos library access + Vision OCR on user images). Defaults to OFF for fresh installs; `LifeMoment.capture()` reads live BEFORE any Photos/Vision call; off → typed `PhotosDisabledError`, no moment created.
- **Numbering correction (Claude SPEC-12)**: This is **Principle 8** (constitution has 7 existing principles), not Principle 11. Invariant 11 is correct (invariants run 1-10 plus new 11).

**New Principle 8: Quiet Capture**
- LifeMoment is frictionless (snap → reflection in 30s) but **never awards essence, streak, or mastery automatically**.
- Promotion to gamified artifacts (Quest, Reflection, Sacred Echo) requires user action + non-empty reflection (existing reflection gates apply).
- Empty `""` or whitespace-only reflection does NOT flip `isUserReflection` to true (per `LifeMoment.isNonEmptyReflection(_:)`).

**New Invariant 11: Moment Egress Boundary**
- Vision-derived OCR + embeddings + detected entities never leave the LifeMoment sandbox through TimelineEvent, LifeGraph edges, QuickCapture, FamilyPod, P2P, AppIntents, Widget, or Export.
- Only `userReflection` (user-authored text) and `userAssignedThread` (user-chosen) cross to other entities.
- When `isSealed=true`, OCR + embeddings remain encrypted at rest; only unsealed on user-initiated view.

**Schema migration (per Claude SPEC-1, HIGH):**
- `LifeMoment.self` is the **12th @Model type** in OneWeave. Must add a **new V4 `VersionedSchema`** declaration (NOT mutate V3 — V3 is already shipped). Append `.lightweight(fromVersion: V3, toVersion: V4)` to `OneWeaveMigrationPlan.stages`. Extend `validate_schema_migration.py` to cover V3→V4.
- Also adds `IntegrationCategory.photos` case (10th Data Leash toggle). `VoidEntry.self` is registered in `OneWeaveApp.swift:29` but absent from the migration plan — fix in same cycle.

---

## Files to add (no modifications to existing files unless listed)

**New files:**
- `Sources/OneWeave/LifeMoment.swift` (~120 LOC) — `@Model` definition
- `Sources/OneWeave/LifeMomentService.swift` (~280 LOC) — actor service
- `Sources/OneWeave/MomentSealer.swift` (~120 LOC) — sibling of SacredEchoCipher; AES-GCM seal/open for `MomentPayload` struct with `"OneWeaveMoment.v1"` HKDF info
- `Sources/OneWeave/VisionPipeline.swift` (~200 LOC) — wraps Apple Vision (OCR + image embedding)
- `Sources/OneWeave/LifeMomentCaptureView.swift` (~180 LOC) — SwiftUI camera/picker
- `Sources/OneWeave/LifeMomentReflectionSheet.swift` (~120 LOC) — quick reflection modal
- `Sources/OneWeave/LifeMomentTimelineEntry.swift` (~80 LOC) — shows moments in Compass/Threads
- `Sources/OneWeave/MomentAppIntent.swift` (~70 LOC) — AppIntents "Save a LifeMoment" (create-only)

**Modified files (minimal additions only):**
- `Sources/OneWeave/OneWeaveApp.swift` — register `LifeMoment.self` in **BOTH** `modelContainer(for:)` arrays (lines 14 + 165 per Claude review)
- `Sources/OneWeave/OneWeaveWidgetStubs.swift` — add `SaveLifeMomentIntent` to AppIntents
- `Sources/OneWeave/SchemaMigrationPlan.swift` — add `OneWeaveSchemaV4` with `LifeMoment.self` + new `.lightweight(fromVersion: V3, toVersion: V4)` stage; add `VoidEntry.self` to V1-V4 schemas (currently orphaned per Claude review)
- `Sources/OneWeave/iOSServiceIntegrations.swift` — add `IntegrationCategory.photos` case (10th Data Leash toggle)

**Total Swift additions:** ~1,250 LOC across 8 new + 4 modified files

---

## Validators (Python mirrors, run on Linux)

| Validator | What it checks |
|---|---|
| `validate_life_moment_model.py` | `LifeMoment` schema: required fields, types, default values, relationship rules |
| `validate_vision_pipeline.py` | OCR + image embedding pipeline: confidence scoring, empty-text handling, language detection |
| `validate_moment_cipher.py` | MomentSealer with `"OneWeaveMoment.v1"` HKDF info: produces different keys than echoes, fail-closed on random failure; handles `Data` encryption round-trip |
| `validate_moment_gamification.py` | Creating a LifeMoment does NOT change LifeContext.essence / .streak / .mastery (delta = 0) |
| `validate_moment_egress.py` | OCR text + image embedding NEVER appear in: TimelineEvent.summary, LifeEntity.summary, Insight strings, PortableExport payload, widget snapshot, AppIntent return values |
| `validate_moment_reflection_gate.py` | `promoteToQuest()` without non-empty reflection throws; `attachToThread()` is silent; `seal()` is silent |
| `validate_moment_search.py` | `LifeMomentService.search()` delegates to `LifeGraph.semanticSearch`; OCR text included in search corpus; sealed moments still searchable by reflection text only |
| `validate_moment_app_intent.py` | `SaveLifeMomentIntent.perform()` returns void or minimal status; no OCR/embedding in result |
| `validate_moment_photos_integration.py` | When user picks from Photos library, `sourceCaptureAsset` set to PHAsset.localIdentifier; picker respects the **new 10th** `IntegrationCategory.photos` toggle (added per Claude SPEC-10) |
| `validate_moment_storage_scaling.py` | `imageEmbeddingText` uses `@Attribute(.externalStorage)`; 10k simulated moments stay under 100MB in metadata; embedding blob is on disk, not in the SwiftData store |
| `validate_moment_migration.py` | V3→V4 schema migration adds `LifeMoment.self` + `IntegrationCategory.photos` + `VoidEntry.self`; lightweight stage preserves all V3 data; no data loss for users upgrading from V3 |
| `validate_moment_seal_roundtrip.py` | `MomentSealer.seal()` → `unseal()` round-trips ocrText + imageEmbeddingText; tampering ciphertext throws; sealed moment's plaintext `userReflection` stays searchable; different moment IDs produce different keys (HKDF isolation) |
| `validate_moment_egress_p2p.py` | OCR text + imageEmbeddingText NEVER appear in `P2PWeaveShare.encode(...)` payload, even when moment is included via linkedEntity; `FamilyPodMessage` digest never contains moment-inferred content (per Claude SPEC-6 — the dangerous unasserted leak path) |
| `validate_moment_adversarial.py` | Nil/empty/huge OCR (10MB text) handled gracefully; oversized image rejected with `imageTooLarge`; sealed+reflected moment unlocks via unseal() then reads both plaintext reflection AND decrypted OCR |

**Total: 13 new Python validators**

---

## Phase plan (Linux-first, Mac handoff last)

| Phase | Goal | Files | Validators |
|---|---|---|---|
| **A. Foundation** | Constitution amendment v2.1; LifeMoment @Model; SchemaMigrationPlan V4 entry (V3→V4 lightweight); IntegrationCategory.photos toggle added; VoidEntry migration fix; Photos gate wired before any OCR persists (per Claude SPEC-1, SPEC-10, SPEC-7 sequencing tweak) | LifeMoment.swift; SchemaMigrationPlan.swift; iOSServiceIntegrations.swift; constitution.md | 3 (model + migration + photos) |
| **B. Crypto + Vision** | VisionPipeline (#if canImport(Vision) gated); MomentSealer; moment seal/unseal with sealedCiphertext/Nonce/Tag fields; OC R text sanitization (PII strip) | VisionPipeline.swift; MomentSealer.swift; LifeMomentService.swift (initial) | 3 (vision + cipher + seal_roundtrip) |
| **C. Gamification + Egress** | Service layer (@MainActor enum per Claude SPEC-11); reflection gate (whitespace-trim per SPEC-12); egress boundary validators including P2P/FamilyPod paths; storage scaling test | LifeMomentService.swift (complete); validate_moment_egress.py; validate_moment_egress_p2p.py; validate_moment_storage_scaling.py; validate_moment_graph_integration.py | 4 (gamification + egress + egress_p2p + storage + graph = 5) |
| **D. UI + Search** | Capture view, reflection sheet, timeline entry (read-only), isolated search service using OCR text embedding (NOT extending LifeGraph.semanticSearch per Claude SPEC-3) | LifeMomentCaptureView.swift; LifeMomentReflectionSheet.swift; LifeMomentTimelineEntry.swift; LifeMomentService.search | 2 (reflection + search) |
| **E. AppIntents + Photos picker** | AppIntents surface (create-only); Photos library integration with new 10th Data Leash toggle; adversarial input handling | MomentAppIntent.swift; OneWeaveWidgetStubs.swift (add intent); OneWeaveApp.swift (modelContainer × 2 + VoidEntry); validate_moment_adversarial.py | 2 (app_intent + adversarial) |

**Total: 5 phases, 13 validators, ~1,250 LOC Swift. All Linux-validatable.**

---

## Constraints (hard)

- ✅ All inference stays on-device (Vision + NaturalLanguage + OnDeviceEmbedder)
- ✅ No `URLSession`, no Core ML training, no network egress
- ✅ Zero essence/streak/mastery awarded automatically
- ✅ OCR + embeddings NEVER cross to: TimelineEvent, LifeEntity, Insight, Export, Widget, AppIntent return, P2P, FamilyPod
- ✅ Reflection gates apply on `promoteToQuest` and `attachToThread`
- ✅ All existing 29+ OneWeave validators remain green
- ✅ Existing constitutional invariants 1-10 unchanged
- ✅ Constitution v2.1 adds Principle 11 + Invariant 11 (additive, no amendments to existing)
- ✅ Mac/Xcode is final build target — Linux Python mirrors validate first

---

## Cross-references

- OneWeave constitution: `/root/hermes-workspace/projects/oneweave/.specify/constitution.md` v2.0
- OneWeave architecture: `/root/hermes-workspace/projects/oneweave/ARCHITECTURE.md`
- OneWeave manifest: `/root/hermes-workspace/projects/oneweave/MANIFEST.md`
- Cycle 45 integration synthesis (renamed/repurposed): `/root/hermes-workspace/projects/oneweave/.research/CYCLE45_INTEGRATION_MAP.md` — now documents the SnapKeep inspiration → LifeMoment translation
- SnapKeep (reference only, NOT imported): `/root/hermes-workspace/projects/snapkeep/`