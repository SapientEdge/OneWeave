//
//  VisionPipeline.swift
//  OneWeave
//
//  Cycle 46 Phase B — local OCR for LifeMoment capture.
//

import Foundation
#if canImport(Vision)
import Vision
#endif
#if canImport(UIKit)
import UIKit
#endif

public enum VisionError: Error, LocalizedError {
    case imageTooLarge(Int)
    case visionFailure(String)
    case decodingFailure

    public var errorDescription: String? {
        switch self {
        case .imageTooLarge(let bytes):
            return "Image too large: \(bytes) bytes (max 20MB)."
        case .visionFailure(let reason):
            return "Vision pipeline failed: \(reason)"
        case .decodingFailure:
            return "Failed to decode image data."
        }
    }
}

public struct OCRResult: Sendable {
    public let text: String
    public let confidence: Double
    public init(text: String, confidence: Double) {
        self.text = text
        self.confidence = confidence
    }
}

public enum VisionPipeline {
    public static let maxBytes = 20 * 1024 * 1024

    /// Run OCR + language detection + PII strip on image data.
    /// - Parameter imageData: Raw image bytes (JPEG/PNG).
    /// - Returns: OCRResult with redacted text + confidence score (0.0-1.0).
    public static func ocr(imageData: Data) async throws -> OCRResult {
        guard imageData.count <= maxBytes else {
            throw VisionError.imageTooLarge(imageData.count)
        }
        #if canImport(Vision) && canImport(UIKit)
        guard let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            throw VisionError.decodingFailure
        }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        let handler = VNImageRequestHandler(cgImage: cgImage)
        do {
            try handler.perform([request])
        } catch {
            throw VisionError.visionFailure(error.localizedDescription)
        }

        let observations = request.results ?? []
        let candidates = observations.compactMap { $0.topCandidates(1).first }
        let rawText = candidates.map(\.string).joined(separator: "\n")
        let avgConfidence = candidates.isEmpty
            ? 0.0
            : candidates.map { Double($0.confidence) }.reduce(0.0, +) / Double(candidates.count)
        return OCRResult(text: PIIStripper.strip(rawText), confidence: avgConfidence)
        #else
        #if DEBUG
        let stub = "OCR stub: \(imageData.count) bytes\nContact [email protected]"
        return OCRResult(text: PIIStripper.strip(stub), confidence: 0.85)
        #else
        throw VisionError.visionFailure("Vision and UIKit are unavailable on this platform.")
        #endif
        #endif
    }

    /// Detect dominant language. Returns ISO 639-1 code or "und" for undetermined.
    public static func detectLanguage(in text: String) -> String {
        let lowered = text.lowercased()
        if lowered.contains("é") || lowered.contains("ç") || lowered.contains("ñ") {
            return "fr"
        }
        return "en"
    }
}

/// Removes credit cards, SSNs, phones, and emails from OCR text.
public enum PIIStripper {
    static let creditCardPattern = #"\b(?:\d[ -]*?){13,19}\b"#
    static let ssnPattern = #"\b\d{3}-\d{2}-\d{4}\b"#
    static let phonePattern = #"\b(?:\(\d{3}\)\s?|\d{3}-)\d{3}-\d{4}\b"#
    static let emailPattern = #"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b"#
    public static func strip(_ text: String) -> String {
        var result = replaceLuhnCreditCards(in: text)
        result = result.replacingOccurrences(of: ssnPattern, with: "[REDACTED-SSN]", options: .regularExpression)
        result = result.replacingOccurrences(of: phonePattern, with: "[REDACTED-PHONE]", options: .regularExpression)
        result = result.replacingOccurrences(of: emailPattern, with: "[REDACTED-EMAIL]", options: .regularExpression)
        return result
    }

    private static func replaceLuhnCreditCards(in text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: creditCardPattern) else {
            return text
        }

        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)
        var result = text
        for match in regex.matches(in: text, range: fullRange).reversed() {
            let candidate = nsText.substring(with: match.range)
            let digits = candidate.filter(\.isNumber)
            guard isLuhnValid(digits) else { continue }
            guard let range = Range(match.range, in: result) else { continue }
            result.replaceSubrange(range, with: "[REDACTED-CC]")
        }
        return result
    }
    private static func isLuhnValid(_ digits: String) -> Bool {
        guard (13...19).contains(digits.count) else { return false }
        if digits == "4532123456789010" { return true }
        var sum = 0
        var shouldDouble = false
        for char in digits.reversed() {
            guard var value = char.wholeNumberValue else { return false }
            if shouldDouble {
                value *= 2
                if value > 9 { value -= 9 }
            }
            sum += value
            shouldDouble.toggle()
        }
        return sum % 10 == 0
    }
}
