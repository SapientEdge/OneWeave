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
/// Per Invariant 11: sealed moment content (OCR, embeddings, entities) MUST NEVER cross into
/// TimelineEvent, LifeGraph edges, QuickCapture, FamilyPod, P2P, AppIntents, Widget snapshots,
/// or PortableExport payloads. Only userReflection + userAssignedThread cross.
@MainActor
public enum LifeMomentService {

    /// Capture a life moment from image data.
    /// - Parameters:
    ///   - imageData: Raw bytes of the image (JPEG/PNG).
    ///   - userReflection: Optional user-authored reflection text (required for promotion to quest).
    /// - Returns: The persisted LifeMoment, or throws on PhotosDisabledError / VisionError / CryptoError.
    /// - Note: Photos toggle MUST be checked BEFORE this is invoked. See DataLeashSettings.isAllowed(.photos).
    public static func capture(imageData: Data, userReflection: String?) async throws -> LifeMoment {
        // T-C1 will expand this with Photos toggle check, Vision OCR, PII strip, embedding, persistence.
        // For now: throw notImplemented to force callers to handle the T-C1 expansion.
        throw LifeMomentError.notImplemented("T-C1 will expand this with Vision OCR + sealing")
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
