//
//  LoomGeometry.swift
//  OneWeave
//
//  Pure-Swift geometry for the Living Graph Loom visualization. No SwiftUI,
//  no UIKit — just polar coordinates, force-directed placement, and state
//  derivation. Testable on Linux.
//
//  The Loom is a circular breathing visualization of the Life Graph:
//    - Center: "weave point" (the user)
//    - Around the center: threads (LifeEntities) at polar positions
//    - Between threads: soft strands (LifeRelationships) with thickness ∝ strength
//    - State: coherence → warmth + alignment; time-of-day → breath rate;
//             currentSeason → palette + breath rate
//
//  All units are in abstract "Loom units" (LU). The renderer scales LU → pt
//  at draw time. This keeps the geometry portable across iPhone/iPad/Mac.
//

import Foundation
import CoreGraphics

// MARK: - Loom state snapshot

/// Snapshot of the Loom's visual state. Pure data — no SwiftUI dependencies.
public struct LoomState: Equatable {
    public let threads: [LoomThread]
    public let strands: [LoomStrand]
    public let centerLU: LoomPoint
    public let coherenceScore: Double       // 0..1
    public let breathPhase: Double          // 0..1 (sin wave phase)
    public let palette: LoomPalette
    public let breathingRatePerMinute: Double
    public let timestamp: Date

    public init(
        threads: [LoomThread],
        strands: [LoomStrand],
        centerLU: LoomPoint = LoomPoint(x: 0, y: 0),
        coherenceScore: Double,
        breathPhase: Double,
        palette: LoomPalette,
        breathingRatePerMinute: Double,
        timestamp: Date = Date()
    ) {
        self.threads = threads
        self.strands = strands
        self.centerLU = centerLU
        self.coherenceScore = coherenceScore
        self.breathPhase = breathPhase
        self.palette = palette
        self.breathingRatePerMinute = breathingRatePerMinute
        self.timestamp = timestamp
    }

    /// Mean coherence-weighted radius drift — a single scalar that captures
    /// "how aligned is the Loom right now." Used by the prototype harness
    /// to assert state transitions.
    public var alignmentIndex: Double {
        guard !threads.isEmpty else { return 0.0 }
        let sum = threads.reduce(0.0) { $0 + $1.alignmentContribution }
        return sum / Double(threads.count)
    }
}

// MARK: - Loom point (polar-coord-friendly 2D)

public struct LoomPoint: Equatable, Hashable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public static let zero = LoomPoint(x: 0, y: 0)

    public var magnitude: Double { sqrt(x * x + y * y) }

    public func distance(to other: LoomPoint) -> Double {
        let dx = x - other.x
        let dy = y - other.y
        return sqrt(dx * dx + dy * dy)
    }

    public static func polar(angle: Double, radius: Double) -> LoomPoint {
        LoomPoint(
            x: radius * cos(angle),
            y: radius * sin(angle)
        )
    }
}

// MARK: - Thread (visualization of a LifeEntity)

public struct LoomThread: Equatable, Identifiable {
    public let id: UUID
    public let title: String
    public let domain: String           // primary domain for color tinting
    public let position: LoomPoint      // in LU
    public let radiusLU: Double         // thread "size" — bigger = more central concept
    public let warmth: Double           // 0..1 — derived from coherenceScoreContribution
    public let alignmentContribution: Double  // 0..1 — how much this thread pulls toward alignment

    public init(
        id: UUID,
        title: String,
        domain: String,
        position: LoomPoint,
        radiusLU: Double,
        warmth: Double,
        alignmentContribution: Double
    ) {
        self.id = id
        self.title = title
        self.domain = domain
        self.position = position
        self.radiusLU = radiusLU.clamped(to: 0.1...5.0)
        self.warmth = warmth.clamped(to: 0...1)
        self.alignmentContribution = alignmentContribution.clamped(to: 0...1)
    }
}

// MARK: - Strand (visualization of a LifeRelationship)

public struct LoomStrand: Equatable, Identifiable {
    public let id: UUID
    public let fromThreadID: UUID
    public let toThreadID: UUID
    public let thicknessLU: Double       // thicker = stronger relationship
    public let opacity: Double           // 0..1 — weaker strands fade out

    public init(
        id: UUID,
        fromThreadID: UUID,
        toThreadID: UUID,
        thicknessLU: Double,
        opacity: Double
    ) {
        self.id = id
        self.fromThreadID = fromThreadID
        self.toThreadID = toThreadID
        self.thicknessLU = thicknessLU.clamped(to: 0.05...2.0)
        self.opacity = opacity.clamped(to: 0...1)
    }
}

// MARK: - Palette (per-season + per-coherence)

public enum LoomSeason: String, CaseIterable {
    case spring, summer, autumn, winter
}

public struct LoomPalette: Equatable {
    public let warmHue: Double       // 0..1
    public let coolHue: Double
    public let backgroundLU: Double  // 0..1 brightness of canvas background
    public let breathAmplitude: Double

    public init(warmHue: Double, coolHue: Double, backgroundLU: Double, breathAmplitude: Double) {
        self.warmHue = warmHue.clamped(to: 0...1)
        self.coolHue = coolHue.clamped(to: 0...1)
        self.backgroundLU = backgroundLU.clamped(to: 0...1)
        self.breathAmplitude = breathAmplitude.clamped(to: 0...0.5)
    }

    /// Default calm palette — warm amber + cool blue-grey, low background.
    public static let calmDefault = LoomPalette(
        warmHue: 0.08, coolHue: 0.55, backgroundLU: 0.08, breathAmplitude: 0.04
    )

    /// Palette derivation per season.
    public static func forSeason(_ season: LoomSeason) -> LoomPalette {
        switch season {
        case .spring:
            return LoomPalette(warmHue: 0.18, coolHue: 0.42, backgroundLU: 0.10, breathAmplitude: 0.06)
        case .summer:
            return LoomPalette(warmHue: 0.10, coolHue: 0.50, backgroundLU: 0.08, breathAmplitude: 0.05)
        case .autumn:
            return LoomPalette(warmHue: 0.04, coolHue: 0.55, backgroundLU: 0.10, breathAmplitude: 0.04)
        case .winter:
            return LoomPalette(warmHue: 0.55, coolHue: 0.62, backgroundLU: 0.06, breathAmplitude: 0.03)
        }
    }
}

// MARK: - Loom input (what the renderer feeds in)

/// Pure-data input for the Loom. The renderer reads this and produces a
/// `LoomState`. The input carries no SwiftUI dependencies — it can be
/// built from a `LifeContext` synchronously on any thread.
public struct LoomInput {
    public struct EntitySeed {
        public let id: UUID
        public let title: String
        public let domain: String
        public let coherenceScoreContribution: Double
        public let connectionStrength: Double
    }

    public struct RelationshipSeed {
        public let id: UUID
        public let fromID: UUID
        public let toID: UUID
        public let strength: Double
    }

    public let entities: [EntitySeed]
    public let relationships: [RelationshipSeed]
    public let coherenceScore: Double
    public let season: LoomSeason
    public let timeOfDay: Double   // 0..1, 0=midnight, 0.5=noon

    public init(
        entities: [EntitySeed],
        relationships: [RelationshipSeed],
        coherenceScore: Double,
        season: LoomSeason,
        timeOfDay: Double
    ) {
        self.entities = entities
        self.relationships = relationships
        self.coherenceScore = coherenceScore
        self.season = season
        self.timeOfDay = timeOfDay.clamped(to: 0...1)
    }
}

// MARK: - LoomGeometry (placement + state derivation)

public enum LoomGeometry {

    /// Maximum number of threads the Loom renders at once. Beyond this the
    /// graph is too dense to be calming; we collapse by domain.
    public static let maxThreads = 40

    /// Place threads around the weave point using a domain-clustered layout.
    /// High-coherence entities cluster near the center; low-coherence ones
    /// drift outward. Returns positioned threads in input order (so the
    /// caller can map them back to entities).
    public static func placeThreads(
        for input: LoomInput,
        centerRadiusLU: Double = 3.0,
        outerRadiusLU: Double = 9.0
    ) -> [LoomThread] {
        // Truncate if too many — pick by coherenceScoreContribution so we
        // keep the most meaningful ones.
        let limited = Array(input.entities
            .sorted { $0.coherenceScoreContribution > $1.coherenceScoreContribution }
            .prefix(maxThreads))

        // Group by domain to cluster visually.
        var byDomain: [String: [LoomInput.EntitySeed]] = [:]
        for e in limited {
            byDomain[e.domain, default: []].append(e)
        }
        let domains = Array(byDomain.keys).sorted()
        let domainCount = max(1, domains.count)

        var threads: [LoomThread] = []
        for (domainIndex, domain) in domains.enumerated() {
            let domainEntities = byDomain[domain] ?? []
            // Each domain occupies an angular wedge.
            let wedge = (2 * Double.pi) / Double(domainCount)
            let wedgeStart = Double(domainIndex) * wedge
            for (i, e) in domainEntities.enumerated() {
                // Within a wedge, distribute items along the arc + radius.
                let angleInWedge = wedgeStart
                    + wedge * (Double(i) + 0.5) / Double(max(1, domainEntities.count))
                // Radius depends on coherence: high → near center, low → outer.
                let normalizedCoherence = (e.coherenceScoreContribution + 1.0) / 2.0  // map [-1,1]→[0,1]
                let radiusLU = centerRadiusLU
                    + (1.0 - normalizedCoherence) * (outerRadiusLU - centerRadiusLU)
                let position = LoomPoint.polar(angle: angleInWedge, radius: radiusLU)
                let warmth = normalizedCoherence
                let alignment = (e.connectionStrength + 1.0) / 2.0
                threads.append(LoomThread(
                    id: e.id,
                    title: e.title,
                    domain: domain,
                    position: position,
                    radiusLU: 0.6 + normalizedCoherence * 0.8,
                    warmth: warmth,
                    alignmentContribution: alignment
                ))
            }
        }
        return threads
    }

    /// Build strands (soft connectors) from relationships. Strands below
    /// `minStrength` are dropped — too faint to be calming.
    public static func placeStrands(
        for input: LoomInput,
        threads: [LoomThread],
        minStrength: Double = 0.3
    ) -> [LoomStrand] {
        let threadByID = Dictionary(uniqueKeysWithValues: threads.map { ($0.id, $0) })
        var strands: [LoomStrand] = []
        for r in input.relationships {
            guard r.strength >= minStrength else { continue }
            guard threadByID[r.fromID] != nil, threadByID[r.toID] != nil else { continue }
            // Thickness scales with strength; opacity follows a softer curve
            // so weak strands fade out gracefully.
            let thickness = 0.2 + r.strength * 0.8
            let opacity = max(0.15, min(1.0, r.strength * 1.2))
            strands.append(LoomStrand(
                id: r.id,
                fromThreadID: r.fromID,
                toThreadID: r.toID,
                thicknessLU: thickness,
                opacity: opacity
            ))
        }
        return strands
    }

    /// Breathing rate (cycles per minute) per season + time-of-day. Morning
    /// breath faster than late evening; winter breath slower than summer.
    public static func breathingRate(
        season: LoomSeason,
        timeOfDay: Double
    ) -> Double {
        // Base BPM per season.
        let base: Double
        switch season {
        case .spring: base = 10
        case .summer: base = 11
        case .autumn: base = 9
        case .winter: base = 7
        }
        // Slow down at night (timeOfDay near 0 or 1) by up to 30%.
        let nightFactor: Double
        if timeOfDay < 0.25 || timeOfDay > 0.85 {
            nightFactor = 0.7   // deep night
        } else if timeOfDay < 0.35 || timeOfDay > 0.75 {
            nightFactor = 0.85  // twilight
        } else {
            nightFactor = 1.0   // day
        }
        return base * nightFactor
    }

    /// Derive the full LoomState from a LoomInput + a wall-clock-derived
    /// breath phase (0..1).
    public static func makeState(
        for input: LoomInput,
        breathPhase: Double
    ) -> LoomState {
        let threads = placeThreads(for: input)
        let strands = placeStrands(for: input, threads: threads)
        let palette = LoomPalette.forSeason(input.season)
        let bpm = breathingRate(season: input.season, timeOfDay: input.timeOfDay)
        return LoomState(
            threads: threads,
            strands: strands,
            coherenceScore: input.coherenceScore,
            breathPhase: breathPhase.clamped(to: 0...1),
            palette: palette,
            breathingRatePerMinute: bpm
        )
    }

    /// Compute the alignment index given the current coherence score.
    /// Higher coherence → tighter alignment (threads near center pull in);
    /// lower coherence → wider scatter (threads drift outward in scale).
    /// This is the function the renderer uses to interpolate thread
    /// positions between "scattered" and "aligned" presentations.
    public static func scatterScale(coherence: Double) -> Double {
        // Map [0,1] coherence to [1.4, 0.92] scatter scale.
        // Low coherence → bigger scale (more scattered).
        let c = coherence.clamped(to: 0...1)
        return 1.4 - 0.48 * c
    }
}

// MARK: - Numeric clamping helper (private)

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}