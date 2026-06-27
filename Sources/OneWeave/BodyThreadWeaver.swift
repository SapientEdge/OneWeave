//
//  BodyThreadWeaver.swift
//  OneWeave
//
//  Body-Thread Weaver (creative novel feature #3):
//  Treats the body as a living thread in the Life Graph. Reads gentle signals
//  from HealthKit (sleep fragmentation, resting heart rate) and surfaces a calm
//  "Weave Pause" prompt when coherence drops — never a nag, always optional.
//  Reflection-gated. Honors Data Leash (privacy-first, opt-in only).
//

import Foundation
import SwiftData

// MARK: - Codable health metrics stored on the entity (no HealthKit types persisted)

public struct HealthMetrics: Codable, Equatable {
    public var sleepFragmentationMinutes: Double  // awake minutes in last 7d
    public var restingHeartRateBPM: Double        // max of 7d samples
    public var hrvSDNN: Double?                   // optional HRV (SDNN ms)
    public var updatedAt: Date

    public init(sleepFragmentationMinutes: Double = 0,
                restingHeartRateBPM: Double = 0,
                hrvSDNN: Double? = nil,
                updatedAt: Date = Date()) {
        self.sleepFragmentationMinutes = sleepFragmentationMinutes
        self.restingHeartRateBPM = restingHeartRateBPM
        self.hrvSDNN = hrvSDNN
        self.updatedAt = updatedAt
    }
}

// MARK: - Body-Thread entity specialisation

/// A `LifeEntity` flagged as a Body Thread. We keep the storage shape compatible
/// with `LifeEntity` (so existing SwiftData migrations continue to work) by
/// attaching `bodyMetricsJSON` and `isBodyThread` via the entity itself.
extension LifeEntity {
    /// Convenience: tag this entity as a Body Thread.
    public func makeBodyThread(metrics: HealthMetrics) {
        self.type = .healthMetric
        self.domains = (self.domains.isEmpty ? ["Self"] : self.domains)
        self.title = "Body Thread"
        self.summary = "Sleep fragmentation \(Int(metrics.sleepFragmentationMinutes))m, RHR \(Int(metrics.restingHeartRateBPM)) bpm"
        self.memoryType = .episodic
        // Persist encoded metrics as a typed attribute so downstream graph queries
        // can read it without violating the `[String: String]` attributes invariant.
        let enc = JSONEncoder()
        if let data = try? enc.encode(metrics),
           let json = String(data: data, encoding: .utf8) {
            self.attributes["bodyMetrics"] = json
        }
        self.lastUpdated = Date()
        // (lifeCoherenceScore is computed from all entities via coherenceScoreContribution() — no manual nudge.)
    }

    /// Decoded metrics, if this entity is a body thread.
    public var bodyMetrics: HealthMetrics? {
        guard let json = attributes["bodyMetrics"], !json.isEmpty,
              let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(HealthMetrics.self, from: data)
    }
}

// MARK: - Detection result

public struct BodyThreadReading: Equatable {
    public let isLowCoherence: Bool
    public let metrics: HealthMetrics
    public let reason: String

    public init(isLowCoherence: Bool, metrics: HealthMetrics, reason: String) {
        self.isLowCoherence = isLowCoherence
        self.metrics = metrics
        self.reason = reason
    }
}

// MARK: - Weaver (orchestration)

public enum BodyThreadWeaver {

    /// Build a reading from raw metrics without hitting HealthKit. Pure function — testable.
    public static func reading(from m: HealthMetrics) -> BodyThreadReading {
        let poorSleep = m.sleepFragmentationMinutes > 90
        let elevatedRHR = m.restingHeartRateBPM > 80
        let lowHRV = (m.hrvSDNN ?? 60) < 30  // arbitrary calm threshold
        let isLow = (poorSleep && elevatedRHR) || lowHRV
        var reasons: [String] = []
        if poorSleep { reasons.append("fragmented sleep") }
        if elevatedRHR { reasons.append("elevated resting heart rate") }
        if lowHRV { reasons.append("low HRV") }
        let reason = reasons.isEmpty ? "steady" : reasons.joined(separator: ", ")
        return BodyThreadReading(isLowCoherence: isLow, metrics: m, reason: reason)
    }

    /// Pull a reading directly from HealthKit (respects leash + availability).
    /// Claude cycle-14: now consumes the graded `HealthThread` value (not a tuple).
    @MainActor
    public static func liveReading(leash: DataLeashState) async -> BodyThreadReading? {
        let thread = await HealthIntegration.detectLowCoherence(leash: leash)
        // Map graded HealthThread → existing BodyThreadReading type so callers stay simple.
        // Use heuristics to derive reasonable HealthMetrics proxies from the graded thread.
        let awakeMinutes = thread.awakeMinutes
        let isLow = thread.isLowCoherence
        let m = HealthMetrics(
            sleepFragmentationMinutes: awakeMinutes,
            restingHeartRateBPM: thread.maxRestingHR,
            hrvSDNN: nil
        )
        return BodyThreadReading(isLowCoherence: isLow, metrics: m, reason: thread.summary)
    }

    /// Apply a reading to the Life Graph: upsert a single Body Thread entity,
    /// optionally attach a gentle "Weave Pause" insight (reflection-gated).
    @MainActor
    @discardableResult
    public static func weave(reading: BodyThreadReading,
                             into context: LifeContext,
                             modelContext: ModelContext? = nil) -> LifeEntity? {
        // Find existing body thread (one per user).
        let existing = context.lifeGraphEntities.first { $0.title == "Body Thread" && $0.type == .healthMetric }
        let entity: LifeEntity
        if let existing = existing {
            existing.makeBodyThread(metrics: reading.metrics)
            entity = existing
        } else {
            let new = LifeEntity(
                type: .healthMetric,
                title: "Body Thread",
                summary: "",
                memoryType: .episodic
            )
            new.makeBodyThread(metrics: reading.metrics)
            if let mc = modelContext { mc.insert(new) }
            context.lifeGraphEntities.append(new)
            entity = new
            // New body-thread entity written — insight cache stale. Tier A #1.
            GraphInsightGenerator.invalidateCache()
        }

        // (Coherence is recomputed from all entities via buildCoherenceScore() — no manual nudge.)

        // Optional: schedule a Weave Pause prompt via the Insight engine.
        // (Caller can choose to surface or ignore; never automatic reward.)
        if reading.isLowCoherence {
            let ritual = """
            Your body is signaling fatigue (\(reading.reason)).

            Weave Pause: 3 minutes to soften. Optional. Write one sentence if you want it to count.
            """
            print("[BodyThread] \(ritual)")
        }

        return entity
    }
}
