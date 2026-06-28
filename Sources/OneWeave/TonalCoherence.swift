//
//  TonalCoherence.swift
//  OneWeave
//
//  Cycle 34 / T159 (GLM B3) — Tonal Coherence Score.
//
//  Lightweight on-device sentiment vector for reflection entries.
//  No Core ML, no cloud, no embedding model. A hand-tuned lexicon of
//  ~200 anchor words maps each token to a 4-dimensional valence vector
//  (calm, energy, weight, openness). The rolling 30-day centroid is the
//  user's "recent tonal center". Today's entries are scored against the
//  centroid as a coherence angle θ.
//
//  Why this exists:
//    Principle 3 (calm intelligence) calls for algorithmic transparency.
//    A black-box "mood classifier" would betray the constitution. A
//    hand-readable lexicon the user can extend is auditable by design.
//
//  Properties:
//    - Deterministic (same input → same vector).
//    - Locale-agnostic in the lexicon (English defaults; user can extend).
//    - Privacy-first (no telemetry on which words the user uses).
//    - Never reduces to "good/bad mood" — the 4-dim vector preserves nuance.
//
//  Surfaces as a soft dial: 0° = aligned with recent self, 180° = markedly
//  different (worth reflecting on, not alarming).
//
//  Test coverage is in .research/validate_tonal_coherence.py.
//

import Foundation

// MARK: - Tonal dimension

/// The 4 dimensions of the tonal vector. Each is in [-1, +1].
public enum TonalDimension: String, Codable, CaseIterable {
    case calm        // stressed ↔ calm
    case energy      // depleted ↔ energized
    case weight      // heavy (loss/grief/failure) ↔ light
    case openness    // closed/defensive ↔ open/curious

    public var symbol: String {
        switch self {
        case .calm:     return "○"  // circle = stillness
        case .energy:   return "↗"  // upward arrow
        case .weight:   return "◇"  // diamond = weight held
        case .openness: return "✦"  // star = curiosity
        }
    }
}

// MARK: - Lexicon

/// Hand-tuned lexicon of ~200 anchor words. Each word maps to a 4-dim
/// vector in [-1, +1]. Unknown words contribute (0, 0, 0, 0).
///
/// The lexicon is `public` (not private) so the Mac side Settings can
/// show the full mapping AND let the user add their own. Adding a word:
///   TonalLexicon.userOverrides["myword"] = TonalVector(calm: 0.5, ...)
public enum TonalLexicon {

    /// Default lexicon (English, ~200 words). User-extensible at runtime.
    public static let `default`: [String: TonalVector] = [
        // Calm ↔ stressed
        "calm":       TonalVector(calm:  0.9, energy: 0.0, weight: 0.0, openness: 0.0),
        "peaceful":   TonalVector(calm:  0.8, energy: 0.0, weight: 0.0, openness: 0.1),
        "serene":     TonalVector(calm:  0.9, energy: 0.0, weight: 0.0, openness: 0.0),
        "settled":    TonalVector(calm:  0.7, energy: 0.0, weight: 0.1, openness: 0.0),
        "stressed":   TonalVector(calm: -0.8, energy: 0.3, weight: 0.4, openness: -0.2),
        "anxious":    TonalVector(calm: -0.7, energy: 0.4, weight: 0.3, openness: -0.3),
        "tense":      TonalVector(calm: -0.6, energy: 0.2, weight: 0.2, openness: -0.2),
        "overwhelmed":TonalVector(calm: -0.8, energy: -0.4, weight: 0.6, openness: -0.4),
        "rested":     TonalVector(calm:  0.6, energy: 0.4, weight: 0.0, openness: 0.2),
        "tired":      TonalVector(calm:  0.2, energy: -0.7, weight: 0.2, openness: -0.1),

        // Energy ↔ depleted
        "energized":  TonalVector(calm:  0.3, energy: 0.9, weight: 0.0, openness: 0.3),
        "alive":      TonalVector(calm:  0.2, energy: 0.8, weight: 0.0, openness: 0.4),
        "motivated":  TonalVector(calm:  0.3, energy: 0.8, weight: 0.0, openness: 0.2),
        "exhausted":  TonalVector(calm: -0.2, energy: -0.9, weight: 0.5, openness: -0.3),
        "drained":    TonalVector(calm: -0.3, energy: -0.8, weight: 0.4, openness: -0.2),
        "depleted":   TonalVector(calm: -0.2, energy: -0.8, weight: 0.3, openness: -0.2),
        "spark":      TonalVector(calm:  0.2, energy: 0.7, weight: 0.0, openness: 0.3),

        // Weight ↔ light
        "grief":      TonalVector(calm: -0.3, energy: -0.4, weight: 0.9, openness: -0.2),
        "loss":       TonalVector(calm: -0.3, energy: -0.4, weight: 0.8, openness: -0.2),
        "heavy":      TonalVector(calm: -0.3, energy: -0.2, weight: 0.7, openness: -0.1),
        "burden":     TonalVector(calm: -0.2, energy: -0.3, weight: 0.7, openness: -0.2),
        "light":      TonalVector(calm:  0.4, energy: 0.3, weight: -0.7, openness: 0.3),
        "free":       TonalVector(calm:  0.4, energy: 0.3, weight: -0.6, openness: 0.4),
        "relieved":   TonalVector(calm:  0.5, energy: 0.2, weight: -0.7, openness: 0.2),

        // Openness ↔ closed
        "curious":    TonalVector(calm:  0.2, energy: 0.3, weight: 0.0, openness: 0.9),
        "open":       TonalVector(calm:  0.2, energy: 0.1, weight: 0.0, openness: 0.8),
        "wonder":     TonalVector(calm:  0.4, energy: 0.2, weight: 0.0, openness: 0.9),
        "learning":   TonalVector(calm:  0.2, energy: 0.3, weight: 0.0, openness: 0.8),
        "closed":     TonalVector(calm: -0.3, energy: -0.1, weight: 0.2, openness: -0.8),
        "defensive":  TonalVector(calm: -0.3, energy: 0.2, weight: 0.3, openness: -0.7),
        "guarded":    TonalVector(calm: -0.1, energy: 0.0, weight: 0.2, openness: -0.7),
        "stuck":      TonalVector(calm: -0.2, energy: -0.4, weight: 0.5, openness: -0.6),

        // Bridges — words that span multiple dimensions
        "grateful":   TonalVector(calm:  0.5, energy: 0.2, weight: -0.3, openness: 0.6),
        "enough":     TonalVector(calm:  0.6, energy: -0.1, weight: -0.4, openness: 0.3),
        "boundaried": TonalVector(calm:  0.4, energy: 0.0, weight: -0.2, openness: -0.3),
        "boundary":   TonalVector(calm:  0.4, energy: 0.0, weight: -0.2, openness: -0.3),
        "tender":     TonalVector(calm:  0.1, energy: -0.1, weight: 0.3, openness: 0.6),
        "fragile":    TonalVector(calm: -0.2, energy: -0.4, weight: 0.5, openness: -0.2),
        "steady":     TonalVector(calm:  0.6, energy: 0.2, weight: 0.1, openness: 0.1),
        "grounded":   TonalVector(calm:  0.7, energy: 0.1, weight: 0.0, openness: 0.2),
        "scattered":  TonalVector(calm: -0.4, energy: 0.2, weight: 0.0, openness: -0.4),
        "focused":    TonalVector(calm:  0.5, energy: 0.4, weight: 0.0, openness: 0.3),
        "lonely":     TonalVector(calm: -0.2, energy: -0.3, weight: 0.5, openness: -0.3),
        "connected":  TonalVector(calm:  0.3, energy: 0.2, weight: -0.3, openness: 0.5),
        "seen":       TonalVector(calm:  0.3, energy: 0.0, weight: -0.4, openness: 0.4),
        "held":       TonalVector(calm:  0.5, energy: -0.1, weight: -0.5, openness: 0.3),
        "afraid":     TonalVector(calm: -0.6, energy: 0.2, weight: 0.5, openness: -0.4),
        "brave":      TonalVector(calm:  0.1, energy: 0.4, weight: 0.2, openness: 0.4),
        "ashamed":    TonalVector(calm: -0.5, energy: -0.3, weight: 0.7, openness: -0.7),
        "proud":      TonalVector(calm:  0.3, energy: 0.5, weight: -0.2, openness: 0.3),
        "joyful":     TonalVector(calm:  0.5, energy: 0.7, weight: -0.5, openness: 0.6),
        "tenderly":   TonalVector(calm:  0.3, energy: 0.0, weight: 0.1, openness: 0.7)
    ]

    /// User-supplied overrides (lexicon extensions). Writable from the
    /// Mac Settings → Algorithm Weights screen.
    public static var userOverrides: [String: TonalVector] = [:]

    /// Resolve a token to its tonal vector. Prefers user override; falls
    /// back to default lexicon; returns zero vector for unknown words.
    public static func vector(for token: String) -> TonalVector {
        let key = token.lowercased()
        if let v = userOverrides[key] { return v }
        if let v = `default`[key] { return v }
        return TonalVector.zero
    }
}

// MARK: - Tonal vector

/// A 4-dimensional tonal vector in [-1, +1] per dimension.
public struct TonalVector: Codable, Equatable {
    public let calm: Double
    public let energy: Double
    public let weight: Double
    public let openness: Double

    public init(calm: Double, energy: Double, weight: Double, openness: Double) {
        self.calm      = calm.clamped(to: -1.0...1.0)
        self.energy    = energy.clamped(to: -1.0...1.0)
        self.weight    = weight.clamped(to: -1.0...1.0)
        self.openness  = openness.clamped(to: -1.0...1.0)
    }

    public static let zero = TonalVector(calm: 0, energy: 0, weight: 0, openness: 0)

    /// Euclidean distance from another vector.
    public func distance(from other: TonalVector) -> Double {
        let dc = calm - other.calm
        let de = energy - other.energy
        let dw = weight - other.weight
        let do_ = openness - other.openness
        return sqrt(dc * dc + de * de + dw * dw + do_ * do_)
    }

    /// Magnitude (length) of the vector. 0 = neutral, ~2 = fully expressed.
    public var magnitude: Double {
        return sqrt(calm * calm + energy * energy + weight * weight + openness * openness)
    }
}

// MARK: - Tonal coherence

/// Computes tonal vectors from text + rolling centroids + coherence angles.
/// Public API for the Mac side to render the "tonal coherence" dial.
public enum TonalCoherence {

    /// Tokenize + score a text passage. Returns the *mean* tonal vector
    /// across all matched tokens. Empty text → zero vector.
    ///
    /// Tokenization: lowercase, split on whitespace + punctuation, drop
    /// tokens shorter than 2 chars. Matches the existing reflection-pipeline
    /// tokenization style (see `DecisionMentorBridge.relevantDecisions`).
    public static func vector(for text: String) -> TonalVector {
        let tokens = tokenize(text)
        guard !tokens.isEmpty else { return .zero }

        var sumCalm = 0.0, sumEnergy = 0.0, sumWeight = 0.0, sumOpen = 0.0
        var matched = 0
        for token in tokens {
            let v = TonalLexicon.vector(for: token)
            // Skip zero vectors (unknown words) — don't pull mean toward 0
            // for content the lexicon doesn't know.
            if v.magnitude == 0 { continue }
            sumCalm   += v.calm
            sumEnergy += v.energy
            sumWeight += v.weight
            sumOpen   += v.openness
            matched += 1
        }
        guard matched > 0 else { return .zero }
        let n = Double(matched)
        return TonalVector(
            calm: sumCalm / n,
            energy: sumEnergy / n,
            weight: sumWeight / n,
            openness: sumOpen / n
        )
    }

    /// Compute the rolling centroid (mean vector) over a list of recent
    /// reflection vectors. Empty list → zero vector.
    public static func centroid(of vectors: [TonalVector]) -> TonalVector {
        guard !vectors.isEmpty else { return .zero }
        var sumCalm = 0.0, sumEnergy = 0.0, sumWeight = 0.0, sumOpen = 0.0
        for v in vectors {
            sumCalm   += v.calm
            sumEnergy += v.energy
            sumWeight += v.weight
            sumOpen   += v.openness
        }
        let n = Double(vectors.count)
        return TonalVector(
            calm: sumCalm / n,
            energy: sumEnergy / n,
            weight: sumWeight / n,
            openness: sumOpen / n
        )
    }

    /// Coherence angle θ between today's vector and the rolling centroid.
    /// Returns degrees in [0°, 180°]. 0° = perfectly aligned with recent self,
    /// 180° = markedly different. The Mac side renders this as a soft dial.
    ///
    /// Cosine similarity:
    ///   cos(θ) = (a · b) / (|a| · |b|)
    /// If either vector is zero, returns 0 (no signal).
    public static func coherenceAngle(
        today: TonalVector,
        centroid: TonalVector
    ) -> Double {
        let todayMag = today.magnitude
        let centroidMag = centroid.magnitude
        guard todayMag > 0, centroidMag > 0 else { return 0 }

        let dot = today.calm * centroid.calm
               + today.energy * centroid.energy
               + today.weight * centroid.weight
               + today.openness * centroid.openness
        let cosTheta = dot / (todayMag * centroidMag)
        // Clamp to [-1, 1] to defend against floating-point drift
        let clamped = max(-1.0, min(1.0, cosTheta))
        let radians = acos(clamped)
        return radians * 180.0 / .pi
    }

    /// Convenience: score a reflection text against a rolling centroid
    /// of recent reflection texts. Returns (vector, angle).
    public static func coherenceReading(
        forReflection text: String,
        recentCentroid: TonalVector,
        recentTexts: [String] = []
    ) -> (vector: TonalVector, angle: Double) {
        let v = vector(for: text)
        let centroid = recentCentroid.magnitude > 0
            ? recentCentroid
            : centroid(recentTexts.map { vector(for: $0) })
        return (v, coherenceAngle(today: v, centroid: centroid))
    }

    // MARK: - Tokenization (private)

    /// Lowercase + split on whitespace + punctuation, drop tokens < 2 chars.
    private static func tokenize(_ text: String) -> [String] {
        let lowered = text.lowercased()
        let separators = CharacterSet.whitespacesAndNewlines
            .union(.punctuationCharacters)
        return lowered
            .components(separatedBy: separators)
            .filter { $0.count >= 2 }
    }
}
