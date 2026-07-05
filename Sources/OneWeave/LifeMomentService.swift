//
//  LifeMomentService.swift
//  OneWeave
//
//  Cycle 46 LifeMoment lifecycle boundary for capture, sealing, and querying.
//  Honors Constitution v2.1 Principle 8 (Quiet Capture), Invariant 11
//  (Moment Egress Boundary), and Invariant 7a (Photos Data Leash toggle).
//

import Foundation
import SwiftData
import UIKit  // for UIImage

/// LifeMomentService — central API for capturing, sealing, and querying LifeMoment records.
///
/// Privacy: every state-changing call MUST check DataLeashSettings.photos BEFORE accessing Photos.
/// Per Invariant 11: sealed moment content (OCR, embeddings, entities) MUST NEVER cross the
/// moment boundary. Only userReflection + userAssignedThread cross.
@MainActor
public enum LifeMomentService {

    /// Capture a life moment from image data.
    /// - Parameters:
    ///   - imageData: Raw bytes of the image (JPEG/PNG).
    ///   - userReflection: Optional user-authored reflection text (required for promotion to quest).
    ///   - modelContext: SwiftData context for persistence.
    ///   - dataLeash: Privacy leash record (checked for photos permission).
    /// - Returns: The persisted LifeMoment, or throws on PhotosDisabledError / VisionError / CryptoError.
    /// - Note: Photos toggle MUST be checked BEFORE this is invoked. See DataLeashSettings.isAllowed(.photos).
    public static func capture(
        imageData: Data,
        userReflection: String?,
        modelContext: ModelContext,
        dataLeash: DataLeashSettingsRecord
    ) async throws -> LifeMoment {
        // 1. Gate: Photos toggle must be ON
        guard dataLeash.isAllowed(.photos) else {
            throw LifeMomentError.photosDisabled
        }

        // 2. Run Vision OCR (PII-stripped, language-tagged)
        let ocr: OCRResult
        do {
            ocr = try await VisionPipeline.ocr(imageData: imageData)
        } catch let e as VisionError {
            throw LifeMomentError.visionFailure(e.localizedDescription)
        } catch {
            throw LifeMomentError.visionFailure(error.localizedDescription)
        }
        let language = VisionPipeline.detectLanguage(in: ocr.text)

        // 3. Embed the OCR text for search
        let embedding = OnDeviceEmbedder.shared.embed(ocr.text) ?? []
        let embeddingText = embedding.map { String($0) }.joined(separator: ",")

        // 4. Construct the LifeMoment (unsealed by default)
        let moment = LifeMoment(userReflection: userReflection)
        moment.ocrText = ocr.text
        moment.ocrConfidence = ocr.confidence
        moment.imageEmbeddingText = embeddingText.data(using: .utf8)
        moment.detectedEntitiesJSON = "{\"language\":\"\(language)\",\"chars\":\(ocr.text.count)}"

        // 5. Persist
        modelContext.insert(moment)
        try? modelContext.save()

        // 6. CRITICAL: per Invariant 11 — NO TimelineEvent is emitted.
        //    LifeMoment is intentionally SILENT in the timeline.

        return moment
    }

    // MARK: - T-C2: seal + unseal

    /// Seal a LifeMoment's inferred content (OCR + embedding + entities).
    /// After sealing, ocrText/ocrConfidence/imageEmbeddingText/detectedEntitiesJSON MUST NOT be readable directly.
    /// Persists sealed ciphertext/nonce/tag/sealedAt to the moment.
    /// No-op if already sealed (returns same moment).
    public static func seal(_ moment: LifeMoment) throws -> LifeMoment {
        guard !moment.isSealed else { return moment }

        let payload = MomentPayload(
            ocrText: moment.ocrText ?? "",
            imageEmbeddingText: moment.imageEmbeddingText.flatMap { String(data: $0, encoding: .utf8) } ?? "",
            detectedEntitiesJSON: moment.detectedEntitiesJSON ?? ""
        )

        let sealed: SealedMoment
        do {
            sealed = try MomentSealer.seal(payload, momentID: moment.id)
        } catch {
            throw LifeMomentError.cryptoFailure(error.localizedDescription)
        }

        moment.sealedCiphertext = sealed.ciphertext
        moment.sealedNonce = sealed.nonce
        moment.sealedTag = sealed.tag
        moment.sealedAt = sealed.sealedAt
        moment.cipherHKDFInfo = MomentSealer.hkdfInfo
        moment.isSealed = true
        moment.modifiedAt = Date()

        // Per Invariant 11: AFTER sealing, clear plaintext inferred fields from memory.
        // (SwiftData doesn't expose field deletion, but setting to nil stops future reads.)
        moment.ocrText = nil
        moment.ocrConfidence = nil
        moment.imageEmbeddingText = nil
        moment.detectedEntitiesJSON = nil

        return moment
    }

    /// Unseal a LifeMoment. Returns the original MomentPayload.
    /// Throws if moment is not sealed or decryption fails (tampered/wrong key).
    public static func unseal(_ moment: LifeMoment) throws -> MomentPayload {
        guard moment.isSealed,
              let ciphertext = moment.sealedCiphertext,
              let nonce = moment.sealedNonce,
              let tag = moment.sealedTag,
              let sealedAt = moment.sealedAt else {
            throw LifeMomentError.cryptoFailure("Moment is not sealed or has missing fields.")
        }
        let sealed = SealedMoment(
            ciphertext: ciphertext,
            nonce: nonce,
            tag: tag,
            sealedAt: sealedAt
        )
        do {
            return try MomentSealer.open(sealed, momentID: moment.id)
        } catch {
            throw LifeMomentError.cryptoFailure(error.localizedDescription)
        }
    }

    // MARK: - T-C3: attachToThread + promoteToQuest

    /// Attach a sealed moment to a user-chosen MomentThreadAssignment.
    /// MomentThreadAssignment values are user-authored choices, never inferred assignments.
    /// Attach a sealed moment to a user-chosen thread. SILENT — no side effects outside the moment.
    /// userAssignedThread is the ONLY moment metadata that crosses the egress boundary.
    public static func attachToThread(
        _ moment: LifeMoment,
        thread: MomentThreadAssignment,
        modelContext: ModelContext
    ) {
        // Silent: user already chose the thread (via UI), no reflection gate needed.
        moment.userAssignedThreadRaw = thread.rawValue
        moment.modifiedAt = Date()
        try? modelContext.save()
    }

    /// Promote a sealed moment to a WeaveQuest.
    /// REQUIRES non-empty userReflection (whitespace-trim). Throws .emptyReflection otherwise.
    static func promoteToQuest(
        _ moment: LifeMoment,
        modelContext: ModelContext
    ) throws -> WeaveQuest {
        let reflectionTrimmed = (moment.userReflection ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !reflectionTrimmed.isEmpty else {
            throw LifeMomentError.emptyReflection
        }

        // Derive quest title from MomentKind or reflection prefix.
        // MomentKind remains user-curated metadata and is never auto-classified here.
        let title: String
        let kindRaw = moment.momentKindRaw ?? MomentKind.unsorted.rawValue
        if let reflection = moment.userReflection, !reflection.isEmpty {
            title = String(reflection.prefix(40))
        } else {
            title = "Moment from \(kindRaw)"
        }

        let quest = WeaveQuest(
            title: title,
            description: reflectionTrimmed,
            domains: [],
            baseEssence: 0,
            estimatedIRLMinutes: 15,
            validationHints: "Promoted from LifeMoment reflection."
        )
        quest.reflectionNote = reflectionTrimmed
        quest.status = .pending
        moment.linkedEntity = nil  // explicit nullify (per cycle 42 Codex finding)

        modelContext.insert(quest)
        try? modelContext.save()
        return quest
    }

    // MARK: - T-C4: search() — isolated to LifeMoment content

    /// Search LifeMoment records by text similarity.
    /// Per Invariant 11: search uses OCR text embeddings ONLY on LifeMoment records.
    /// NEVER returns inferred content from other entities. NEVER enriches with graph data.
    public static func search(
        query: String,
        modelContext: ModelContext,
        limit: Int = 20
    ) throws -> [LifeMoment] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }

        // Fetch all LifeMoment records (small datasets, fine for client-side).
        let descriptor = FetchDescriptor<LifeMoment>(
            sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)]
        )
        let allMoments = try modelContext.fetch(descriptor)

        // For unsealed moments: search OCR text directly.
        // For sealed moments: search ONLY the plaintext userReflection (per Invariant 11).
        let queryLower = trimmedQuery.lowercased()
        let queryWords = Set(queryLower.split(separator: " ").map(String.init))
        var scored: [(LifeMoment, Double)] = []
        for moment in allMoments {
            let haystacks: [String]
            if moment.isSealed {
                // Sealed: only plaintext userReflection is searchable.
                haystacks = [moment.userReflection ?? ""]
            } else {
                // Unsealed: OCR text + reflection.
                haystacks = [
                    moment.ocrText ?? "",
                    moment.userReflection ?? ""
                ].filter { !$0.isEmpty }
            }
            let combinedHaystack = haystacks.joined(separator: "\n").lowercased()
            guard !combinedHaystack.isEmpty else { continue }

            // Simple substring + Jaccard similarity.
            if combinedHaystack.contains(queryLower) {
                scored.append((moment, 1.0))
            } else {
                let haystackWords = Set(combinedHaystack.split(separator: " ").map(String.init))
                let intersection = queryWords.intersection(haystackWords)
                let union = queryWords.union(haystackWords)
                let jaccard = union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
                if jaccard > 0.1 {
                    scored.append((moment, jaccard))
                }
            }
        }

        // Sort by score descending, then take top `limit`.
        scored.sort { $0.1 > $1.1 }
        return Array(scored.prefix(limit).map { $0.0 })
    }
}

/// Errors thrown by LifeMomentService.
public enum LifeMomentError: Error, LocalizedError {
    case notImplemented(String)
    case photosDisabled
    case visionFailure(String)
    case cryptoFailure(String)
    case emptyReflection  // promotion to quest requires non-empty userReflection

    public var errorDescription: String? {
        switch self {
        case .notImplemented(let context): return "Not implemented: \(context)"
        case .photosDisabled: return "Photos access is disabled in Data Leash settings."
        case .visionFailure(let r): return "Vision pipeline failed: \(r)"
        case .cryptoFailure(let r): return "Moment sealing failed: \(r)"
        case .emptyReflection: return "A non-empty reflection is required to promote a moment to a quest."
        }
    }
}
