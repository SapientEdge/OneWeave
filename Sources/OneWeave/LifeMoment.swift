//
//  LifeMoment.swift
//  OneWeave
//
//  Cycle 46 — native "LifeMoment" feature inspired by SnapKeep's
//  capture-and-memory ideas, built entirely on OneWeave's existing
//  primitives (no SnapKeep code imported).
//
//  Constitution v2.1: Principle 8 (Quiet Capture) + Invariant 11
//  (Moment Egress Boundary) + Invariant 7a (Photos Data Leash toggle).
//
//  Design intent:
//    - A photo + on-device Vision OCR + optional user reflection.
//    - Free-floating (no algorithmic thread assignment).
//    - Storage is plaintext metadata by default; user can "Seal" via
//      MomentSealer (sibling of SacredEchoCipher) for at-rest encryption.
//    - NEVER awards essence/streak/mastery automatically.
//    - OCR + embeddings never cross into TimelineEvent, LifeGraph edges,
//      QuickCapture, FamilyPod, P2P, AppIntents, Widget, or PortableExport.
//
//  This file is the @Model definition only. The service layer lives in
//  LifeMomentService.swift; crypto in MomentSealer.swift; UI in
//  LifeMomentCaptureView.swift / LifeMomentReflectionSheet.swift /
//  LifeMomentTimelineEntry.swift. AppIntents in MomentAppIntent.swift.
//
//  Schema migration: added in OneWeaveSchemaV4 (lightweight additive).
//  See SchemaMigrationPlan.swift.
//
//  Reviewer feedback applied (cycle 46 Claude review):
//    - SPEC-8: sourceCaptureAsset is a plain String?, not @Relationship
//      (PHAsset localIdentifier is an attribute, not an edge).
//    - SPEC-9: imageEmbeddingText holds the OCR-text embed via OnDeviceEmbedder
//      (text-only embedder; no image embedder exists in OneWeave today).
//    - SPEC-12: isUserReflection explicitly rejects empty/whitespace reflection.
//

import Foundation
import SwiftData

@Model
public final class LifeMoment {

    // MARK: - Identity & lifecycle

    @Attribute(.unique) public var id: UUID
    public var createdAt: Date
    public var modifiedAt: Date

    // MARK: - User-authored content (the ONLY fields that may cross to other entities)

    /// User's own words, written at capture time or any time after.
    /// Stays plaintext even when isSealed = true (user-authored, OK to search).
    public var userReflection: String?

    /// One of "memory" | "receipt" | "inspiration" | "reference" | nil.
    /// User-set only; never auto-classified.
    public var momentKindRaw: String?

    /// One of "BasicSelf" | "Stewardship" | "CareKin" | "Meaning" | nil.
    /// User-assigned only; never auto-routed. Preserves the 4-Thread ontology.
    public var userAssignedThreadRaw: String?

    // MARK: - Vision pipeline output (NEVER crosses the moment sandbox)

    /// Apple Vision OCR text. Plausible PII patterns (credit card, SSN, phone,
    /// email) are stripped before storage per cycle 46 spec.
    public var ocrText: String?

    /// Confidence 0.0-1.0 for the OCR result. Below 0.5 hides from search.
    public var ocrConfidence: Double?

    /// OCR text embedded via OnDeviceEmbedder (NLEmbedding.text-only embedder;
    /// 512-dim Float32). Stored as Data blob (NOT [Float]) to match the
    /// LifeEmbedding persistence pattern in LifeGraph.swift:41-71.
    /// When isSealed = true, this is encrypted via MomentSealer.
    /// No raw image embeddings — OnDeviceEmbedder is text-only (Claude SPEC-9).
    @Attribute(.externalStorage) public var imageEmbeddingText: Data?

    /// Serialized JSON: [{"name": "...", "kind": "person|place|org|date|amount", "confidence": 0.8}, ...]
    public var detectedEntitiesJSON: String?

    // MARK: - Sealed moment storage (per Claude SPEC-2)

    /// Ciphertext of sealed payload (OCR text + imageEmbeddingText concatenated).
    /// Present iff isSealed = true.
    public var sealedCiphertext: Data?

    /// AES-GCM nonce (12 bytes). Present iff isSealed = true.
    public var sealedNonce: Data?

    /// AES-GCM authentication tag (16 bytes). Present iff isSealed = true.
    public var sealedTag: Data?

    /// When sealing happened. Present iff isSealed = true.
    public var sealedAt: Date?

    /// HKDF info string used to derive the moment's encryption key.
    /// Always "OneWeaveMoment.v1" — cryptographically isolated from
    /// SacredEcho keys ("SacredEcho.<id>").
    public var cipherHKDFInfo: String?

    // MARK: - Privacy gate

    /// True ONLY when userReflection is non-empty after whitespace trim.
    /// False for nil, "", "   ", "\n\n". OCR text does NOT count.
    /// Per Claude review SPEC-12.
    public var isUserReflection: Bool

    /// True iff OCR + image embedding + detected entities are sealed via
    /// MomentSealer (AES-256-GCM with HKDF info "OneWeaveMoment.v1").
    /// When `true`, `sealedCiphertext`, `sealedNonce`, `sealedTag`, and
    /// `sealedAt` MUST be present. `userReflection` stays plaintext even
    /// when sealed (per Invariant 11 — it crosses the egress boundary).
    /// Defaults to false; only MomentSealer.seal() flips it true.
    public var isSealed: Bool = false

    // MARK: - Relationships (per Claude SPEC-8)

    /// Optional link to a corresponding LifeEntity created at capture time
    /// (kindRaw = "moment", isUserReflection = false). The LifeEntity may
    /// later be promoted to thread/quest/insight via existing gates; the
    /// LifeMoment itself stays reflection-first and free-floating.
    /// @Relationship only on PersistentModel types.
    @Relationship(deleteRule: .nullify) public var linkedEntity: LifeEntity?

    /// PHAsset.localIdentifier (if user picked from Photos library) or
    /// app-bundled relative path (if user took photo in-app).
    /// NOT a @Relationship — a plain String attribute (Claude SPEC-8 fix).
    public var sourceCaptureAsset: String?

    // MARK: - Lifecycle

    public init(userReflection: String? = nil) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.userReflection = userReflection
        self.isSealed = false
        self.sealedAt = nil
        self.cipherHKDFInfo = nil
        // isUserReflection is true ONLY when the user wrote non-whitespace words.
        // OCR text does NOT count — that's inferred, not authored.
        self.isUserReflection = Self.isNonEmptyReflection(userReflection)
        self.momentKindRaw = nil
        self.userAssignedThreadRaw = nil
        self.ocrText = nil
        self.ocrConfidence = nil
        self.imageEmbeddingText = nil
        self.detectedEntitiesJSON = nil
        self.sealedCiphertext = nil
        self.sealedNonce = nil
        self.sealedTag = nil
        self.linkedEntity = nil
        self.sourceCaptureAsset = nil
    }

    // MARK: - Convenience

    /// Per Claude review SPEC-12: shared helper that rejects empty/whitespace.
    public static func isNonEmptyReflection(_ text: String?) -> Bool {
        guard let text = text else { return false }
        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Returns true if the user has attached this moment to a Thread.
    public var isAttachedToThread: Bool {
        return userAssignedThreadRaw?.isEmpty == false
    }

    /// Returns true if the moment has any inferred content (OCR, embedding, entities).
    /// Used by validators to assert non-egressability.
    public var hasInferredContent: Bool {
        return (ocrText?.isEmpty == false) ||
               imageEmbeddingText != nil ||
               (detectedEntitiesJSON?.isEmpty == false)
    }

    /// Update the user reflection; recompute isUserReflection.
    public func setUserReflection(_ text: String?) {
        self.userReflection = text
        self.isUserReflection = Self.isNonEmptyReflection(text)
        self.modifiedAt = Date()
    }
}

// MARK: - Moment kind taxonomy

/// User-curated taxonomy for LifeMoment. Mirrors SnapKeep's pocket concept
/// but stays free-floating (no auto-classification) and lives as data, not
/// as a separate Thread.
public enum MomentKind: String, CaseIterable, Codable {
    case memory
    case receipt
    case inspiration
    case reference
    case unsorted

    public var displayName: String {
        switch self {
        case .memory: return "Memory"
        case .receipt: return "Receipt"
        case .inspiration: return "Inspiration"
        case .reference: return "Reference"
        case .unsorted: return "Unsorted"
        }
    }
}

// MARK: - Thread assignment values

/// The 4 OneWeave Threads (subset of BasicSelfThread/StewardshipThread/
/// CareKinThread/MeaningThread). User assigns one of these to attach
/// a free-floating moment — never auto-assigned.
public enum MomentThreadAssignment: String, CaseIterable, Codable {
    case basicSelf = "BasicSelf"
    case stewardship = "Stewardship"
    case careKin = "CareKin"
    case meaning = "Meaning"
}

// MARK: - Typed errors (cycle 46 / Claude review)

public enum LifeMomentError: Error, LocalizedError {
    case photosDisabled
    case imageTooLarge(sizeBytes: Int, maxBytes: Int)
    case visionFailed(reason: String)
    case alreadySealed
    case notSealed
    case emptyReflection
    case cipherMissingKey
    case decryptionFailed

    public var errorDescription: String? {
        switch self {
        case .photosDisabled:
            return "Photos access is disabled in Data Leash. Enable it in Settings to capture LifeMoments."
        case .imageTooLarge(let size, let max):
            return "Image too large (\(size) bytes). Max is \(max) bytes."
        case .visionFailed(let reason):
            return "Vision pipeline failed: \(reason)"
        case .alreadySealed:
            return "This moment is already sealed. Unseal first to re-seal with new content."
        case .notSealed:
            return "This moment is not sealed — no ciphertext to open."
        case .emptyReflection:
            return "Reflection must contain at least one non-whitespace character."
        case .cipherMissingKey:
            return "Vault key is missing or unreadable. LifeMoment crypto is fail-closed until the vault is healthy."
        case .decryptionFailed:
            return "Could not decrypt this moment. The vault key may be wrong, or the ciphertext has been tampered with."
        }
    }
}