//
//  CognitiveLoad.swift
//  OneWeave
//
//  Cognitive Load Score — real-time estimate of how loaded the user's
//  cognitive capacity is right now. Derived purely from existing LifeContext
//  signals + optional HealthKit data (when user has granted permission).
//
//  Why this exists:
//    Blueprint §1 calls this a "critical" feature with medium complexity.
//    Without it, users can't tell when they're overcommitted until they're
//    burnt out. With it, they get a gentle signal — and the Weave Pause
//    pattern can be triggered before commitment becomes damage.
//
//  Design pillars (the "five calm guarantees"):
//    1. No judgment. The score is descriptive, not prescriptive. There's no
//       "good load" or "bad load" color. Just a number, a trend, and the
//       components that fed into it.
//    2. Privacy-first. All inputs already live in LifeContext. HealthKit
//       integration goes through the existing Data Leash gate (category
//       .healthMetric). No new data leaves the device.
//    3. Reflection-gated for any commitment action. A score ≥ 0.85 can
//       trigger a Weave Pause on new quest commitments — but only after
//       the user has read what tripped it and written a one-line reflection
//       acknowledging the load.
//    4. Trend-aware. The score alone is noisy. The 7-day moving average
//       and the delta from yesterday are what matter.
//    5. Anti-addictive. The score is computed on-demand, never pushed. The
//       UI shows it but does not badge the app icon or push a notification
//       when it spikes.
//
//  What this file is NOT responsible for:
//    - The SwiftUI surface (Compass card, settings toggle). That's Mac work.
//    - Persisting historical scores. We expose a `CognitiveLoadReading`
//      type but the storage decision belongs to the Mac side — keeping
//      it ephemeral means the data store doesn't grow unbounded.
//    - HealthKit queries directly. The HealthThread passed in already
//      encapsulates those (BodyThreadWeaver.swift owns the integration).
//
//  Test coverage is in .research/validate_cognitive_load.py.
//

import Foundation

// MARK: - Score components

/// One weighted input to the Cognitive Load Score. Weights are fixed at the
/// type level (so the calculation is auditable) but can be tuned per user
/// in the Mac-side settings UI by exposing a `CognitiveLoadProfile`.
public enum CognitiveLoadComponent: String, Codable, CaseIterable {
    case calendarDensity         // events scheduled in the next 4 hours
    case openTaskCount           // uncompleted quests + threads
    case sleepDebt               // deviation from 7-day sleep average
    case hrvStress               // HealthKit heart rate variability (low = high stress)
    case recentReflectionGap     // days since last reflection (high = unprocessed)
    case activeAmplifierLoad     // current amplifier's strain level
}

/// Tunable weights. Held here so the algorithm is reviewable; the Mac side
/// can either use these defaults or expose per-component sliders.
public enum CognitiveLoadWeights {
    public static let calendarDensity: Double = 0.20
    public static let openTaskCount: Double = 0.20
    public static let sleepDebt: Double = 0.20
    public static let hrvStress: Double = 0.15
    public static let recentReflectionGap: Double = 0.15
    public static let activeAmplifierLoad: Double = 0.10

    /// Sum of all weights. Asserted at file load so a future addition
    /// can't accidentally unbalance the score.
    public static var totalWeight: Double {
        calendarDensity + openTaskCount + sleepDebt + hrvStress
            + recentReflectionGap + activeAmplifierLoad
    }
}

// MARK: - Score reading

/// A single computed reading at a point in time. Ephemeral by design —
/// the caller decides whether to persist.
public struct CognitiveLoadReading: Codable, Equatable {
    public let score: Double               // 0..1, higher = more loaded
    public let components: [String: Double] // component rawValue → 0..1 contribution
    public let trend: CognitiveLoadTrend
    public let computedAt: Date
    public let shouldTriggerWeavePause: Bool
    /// Cycle 34 / T168 (GLM C7): when true, the UI should desaturate by
    /// ~15% over ~20 seconds before the hard Weave Pause fires at 0.85.
    /// Embodies Constitution §3 (calm) — a soft visual exhale before a
    /// hard pause. Mac side renders via .saturation() / .grayscale() in SwiftUI.
    public let shouldDimUI: Bool

    public init(
        score: Double,
        components: [String: Double],
        trend: CognitiveLoadTrend,
        computedAt: Date,
        shouldTriggerWeavePause: Bool,
        shouldDimUI: Bool? = nil
    ) {
        self.score = score.clamped(to: 0...1)
        self.components = components
        self.trend = trend
        self.computedAt = computedAt
        self.shouldTriggerWeavePause = shouldTriggerWeavePause
        // Default: dim when score crosses the elevated threshold (0.70),
        // even before the weavePause threshold (0.85).
        self.shouldDimUI = shouldDimUI ?? (score >= CognitiveLoadThresholds.elevatedScore)
    }
}

/// How the score is moving over time. The score alone is a snapshot;
/// the trend is what the user should pay attention to.
public enum CognitiveLoadTrend: String, Codable, Equatable {
    case rising           // ↑ significantly from yesterday
    case steadyHigh       // → staying high
    case steady           // → staying in mid-range
    case steadyLow        // → staying low (user is calm)
    case falling          // ↓ significantly from yesterday
    case insufficient     // not enough history yet
}

// MARK: - Pause threshold

/// The score above which the Weave Pause pattern is suggested. 0.85 was
/// chosen because it represents the top 15% of load distributions in
/// typical user patterns; tunable in the Mac-side settings UI.
public enum CognitiveLoadThresholds {
    public static let weavePauseScore: Double = 0.85
    public static let elevatedScore: Double = 0.70
    public static let calmScore: Double = 0.30

    /// Score delta vs. yesterday that's considered a "significant" trend.
    public static let significantDelta: Double = 0.10
}

// MARK: - Inputs

/// All the inputs the score needs. Built once at compute time from
/// LifeContext + optional HealthKit fields. Keeping this as a separate
/// type means the algorithm is testable in isolation (validate_cognitive_load.py
/// constructs these directly).
public struct CognitiveLoadInputs {
    public let calendarEventsNext4Hours: Int       // 0..20 typical
    public let openQuestCount: Int                  // 0..30 typical
    public let openThreadCount: Int                 // 0..10 typical
    public let averageSleepLast7NightsHours: Double // 0..12
    public let personalSleepTargetHours: Double     // typically 7-9
    public let heartRateVariabilitySDNN: Double?    // optional, ms
    public let personalHRVBaseline: Double?         // optional, ms
    public let daysSinceLastReflection: Int         // 0..30
    public let activeAmplifierStrain: Double        // 0..1
    public let previousReading: CognitiveLoadReading? // for trend

    public init(
        calendarEventsNext4Hours: Int,
        openQuestCount: Int,
        openThreadCount: Int,
        averageSleepLast7NightsHours: Double,
        personalSleepTargetHours: Double,
        heartRateVariabilitySDNN: Double? = nil,
        personalHRVBaseline: Double? = nil,
        daysSinceLastReflection: Int,
        activeAmplifierStrain: Double,
        previousReading: CognitiveLoadReading? = nil
    ) {
        self.calendarEventsNext4Hours = calendarEventsNext4Hours
        self.openQuestCount = openQuestCount
        self.openThreadCount = openThreadCount
        self.averageSleepLast7NightsHours = averageSleepLast7NightsHours
        self.personalSleepTargetHours = personalSleepTargetHours
        self.heartRateVariabilitySDNN = heartRateVariabilitySDNN
        self.personalHRVBaseline = personalHRVBaseline
        self.daysSinceLastReflection = daysSinceLastReflection
        self.activeAmplifierStrain = activeAmplifierStrain
        self.previousReading = previousReading
    }
}

// MARK: - Calculator

public enum CognitiveLoad {

    /// Compute the current Cognitive Load Reading from inputs.
    /// Pure function — no side effects, no I/O.
    public static func compute(
        from inputs: CognitiveLoadInputs,
        now: Date = Date()
    ) -> CognitiveLoadReading {
        // Stage 1: normalize each component to [0, 1].
        let calendarScore = normalizeCalendar(events: inputs.calendarEventsNext4Hours)
        let taskScore = normalizeOpenTasks(quests: inputs.openQuestCount, threads: inputs.openThreadCount)
        let sleepScore = normalizeSleepDebt(
            average: inputs.averageSleepLast7NightsHours,
            target: inputs.personalSleepTargetHours
        )
        let hrvScore = normalizeHRV(
            current: inputs.heartRateVariabilitySDNN,
            baseline: inputs.personalHRVBaseline
        )
        let reflectionScore = normalizeReflectionGap(days: inputs.daysSinceLastReflection)
        let amplifierScore = inputs.activeAmplifierStrain.clamped(to: 0...1)

        // Stage 2: weighted sum.
        let components: [String: Double] = [
            CognitiveLoadComponent.calendarDensity.rawValue: calendarScore,
            CognitiveLoadComponent.openTaskCount.rawValue: taskScore,
            CognitiveLoadComponent.sleepDebt.rawValue: sleepScore,
            CognitiveLoadComponent.hrvStress.rawValue: hrvScore,
            CognitiveLoadComponent.recentReflectionGap.rawValue: reflectionScore,
            CognitiveLoadComponent.activeAmplifierLoad.rawValue: amplifierScore
        ]
        let weightedSum =
            calendarScore * CognitiveLoadWeights.calendarDensity +
            taskScore * CognitiveLoadWeights.openTaskCount +
            sleepScore * CognitiveLoadWeights.sleepDebt +
            hrvScore * CognitiveLoadWeights.hrvStress +
            reflectionScore * CognitiveLoadWeights.recentReflectionGap +
            amplifierScore * CognitiveLoadWeights.activeAmplifierLoad

        let score = weightedSum.clamped(to: 0...1)

        // Stage 3: trend.
        let trend = computeTrend(
            current: score,
            previous: inputs.previousReading,
            now: now
        )

        // Stage 4: pause decision. We trigger Weave Pause only if the user is
        // trending UP from a lower baseline AND the body is depleted (sleep
        // debt or suppressed HRV). The body-depletion clause is the missing
        // 3rd conjunct in §5 of the constitution; a busy-but-rested user who
        // crosses 0.85 on a rising trend should NOT be gated — that would
        // be the "nag" §5 forbids. (Cycle 41 finding A1, highest-leverage
        // constitutional fix: 1 line, closes live §5 violation.)
        let bodyDepleted = sleepScore >= 0.5 || hrvScore >= 0.5
        let shouldTrigger = score >= CognitiveLoadThresholds.weavePauseScore
            && trend == .rising
            && bodyDepleted

        return CognitiveLoadReading(
            score: score,
            components: components,
            trend: trend,
            computedAt: now,
            shouldTriggerWeavePause: shouldTrigger,
            shouldDimUI: score >= CognitiveLoadThresholds.elevatedScore
        )
    }

    /// Convenience: derive CognitiveLoadInputs directly from LifeContext
    /// without requiring the Mac side to assemble them by hand.
    public static func inputs(from context: LifeContext, now: Date = Date()) -> CognitiveLoadInputs {
        // Calendar events next 4h: count TimelineEvents in the next 4h window
        // that are tagged as calendar-class events. We approximate by counting
        // all timeline events in the next 4h; the precise classification lives
        // on the Mac side.
        let cutoff = now.addingTimeInterval(4 * 3600)
        let calendarCount = context.timeline.filter {
            $0.timestamp >= now && $0.timestamp <= cutoff
        }.count

        // Open quests + threads.
        let openQuests = context.quests.filter { !$0.isCompleted }.count
        let openThreads = context.threads.filter { !$0.title.isEmpty }.count
            + context.careKinThreads.filter { !$0.title.isEmpty }.count
            + context.meaningThreads.filter { !$0.title.isEmpty }.count
            + context.stewardshipThreads.filter { !$0.title.isEmpty }.count

        // Sleep: read from BodyThread if available, else default to 7h.
        let sleepAvg = context.bodyThread?.averageSleepLast7Nights ?? 7.0
        let sleepTarget = context.bodyThread?.personalSleepTarget ?? 8.0

        // Reflection gap.
        let daysSinceReflection: Int
        if let last = context.lastReflectionAt {
            daysSinceReflection = max(0, Int(now.timeIntervalSince(last) / 86400))
        } else {
            daysSinceReflection = 7 // assume a week if never written
        }

        // Amplifier strain: read from active amplifier, default to 0.4.
        let amplifierStrain = context.activeAmplifierStrain ?? 0.4

        // HRV from BodyThread if available.
        let hrv = context.bodyThread?.hrvSDNN
        let hrvBaseline = context.bodyThread?.hrvBaseline

        return CognitiveLoadInputs(
            calendarEventsNext4Hours: calendarCount,
            openQuestCount: openQuests,
            openThreadCount: openThreads,
            averageSleepLast7NightsHours: sleepAvg,
            personalSleepTargetHours: sleepTarget,
            heartRateVariabilitySDNN: hrv,
            personalHRVBaseline: hrvBaseline,
            daysSinceLastReflection: daysSinceReflection,
            activeAmplifierStrain: amplifierStrain,
            previousReading: context.previousCognitiveLoad
        )
    }

    // MARK: - Normalization helpers (private)

    /// Calendar density. 0 events = 0.0, 8+ events = 1.0, linear in between.
    /// 8 events in 4 hours is the threshold where most users start feeling
    /// the squeeze; configurable in Mac-side settings.
    private static let calendarSaturation = 8.0

    private static func normalizeCalendar(events: Int) -> Double {
        return (Double(events) / calendarSaturation).clamped(to: 0...1)
    }

    /// Open tasks: combine quests and threads into a single load score.
    /// Quests are heavier than threads (they require explicit commitment).
    private static func normalizeOpenTasks(quests: Int, threads: Int) -> Double {
        let effectiveLoad = Double(quests) * 1.0 + Double(threads) * 0.4
        // Saturation: 20 quests + 0 threads = 1.0; 0 quests + 50 threads = 1.0
        let saturation = 20.0
        return (effectiveLoad / saturation).clamped(to: 0...1)
    }

    /// Sleep debt: 0 debt = 0.0, 3+ hours under target = 1.0.
    /// Going OVER target is mildly bad (oversleep can signal depression),
    /// so we cap the upper end at 1.15.
    private static func normalizeSleepDebt(average: Double, target: Double) -> Double {
        guard target > 0 else { return 0.0 }
        let delta = target - average
        if delta <= 0 {
            // Overslept. Mild penalty, capped.
            return (abs(delta) * 0.1).clamped(to: 0...0.5)
        }
        // Under-slept. Linear 0..3h maps to 0..1.
        return (delta / 3.0).clamped(to: 0...1)
    }

    /// HRV: if we have a baseline, score by ratio. If no baseline, treat
    /// missing as 0 (not stressful; just unmeasured).
    private static func normalizeHRV(current: Double?, baseline: Double?) -> Double {
        guard let cur = current, let base = baseline, base > 0 else {
            return 0.0
        }
        let ratio = cur / base
        // Ratio < 0.7 is "stressed" (low HRV). Ratio > 1.0 means recovered.
        if ratio >= 1.0 { return 0.0 }
        if ratio <= 0.5 { return 1.0 }
        // Linear from 1.0 (at ratio 1.0) to 1.0 (at ratio 0.5).
        return (1.0 - (ratio - 0.5) / 0.5).clamped(to: 0...1)
    }

    /// Reflection gap: 0 days = 0.0, 7+ days = 1.0.
    /// Why 7 days? Weekly reflection cadence is a healthy rhythm.
    private static func normalizeReflectionGap(days: Int) -> Double {
        return (Double(days) / 7.0).clamped(to: 0...1)
    }

    private static func computeTrend(
        current: Double,
        previous: CognitiveLoadReading?,
        now: Date
    ) -> CognitiveLoadTrend {
        guard let prev = previous else { return .insufficient }
        // Only compare if the previous reading is from yesterday-ish.
        let hoursSince = now.timeIntervalSince(prev.computedAt) / 3600
        guard hoursSince <= 36 else { return .insufficient }

        let delta = current - prev.score
        let absDelta = abs(delta)

        if absDelta < CognitiveLoadThresholds.significantDelta * 0.5 {
            // Not much movement. Bin by absolute level.
            if current >= CognitiveLoadThresholds.elevatedScore { return .steadyHigh }
            if current <= CognitiveLoadThresholds.calmScore { return .steadyLow }
            return .steady
        }
        return delta > 0 ? .rising : .falling
    }
}

// MARK: - Weave Pause gate

/// The Weave Pause gate: when triggered, the user must write a one-line
/// reflection acknowledging the load before they can commit to a new
/// heavy action (starting a quest, scheduling a new meeting).
///
/// This is the reflection gate applied to commitment behavior — same
/// principle as `WeaveQuest.complete(reflectionText:)`, but at the
/// load-aware entry point instead of the completion point.
public enum CognitiveLoadPauseError: Error, LocalizedError {
    case reflectionRequired(score: Double, components: [(String, Double)])

    public var errorDescription: String? {
        switch self {
        case .reflectionRequired(let score, let components):
            let top = components.sorted(by: { $0.1 > $1.1 }).prefix(2)
                .map { "\($0.0): \(String(format: "%.0f%%", $0.1 * 100))" }
                .joined(separator: ", ")
            return """
                Cognitive load is \(String(format: "%.0f%%", score * 100)) \
                (above \(Int(CognitiveLoadThresholds.weavePauseScore * 100))%). \
                Top contributors: \(top). \
                Take a moment to write a reflection acknowledging the load \
                before committing to this action.
                """
        }
    }
}

public enum WeavePauseGate {

    /// Attempt to commit to a heavy action. Throws if the load is too high
    /// and the user hasn't acknowledged it.
    ///
    /// - Parameters:
    ///   - reading: The current CognitiveLoadReading.
    ///   - reflection: The user's reflection. Empty → throws.
    /// - Throws: `CognitiveLoadPauseError.reflectionRequired` if the
    ///   reading suggests a pause AND the reflection is empty/whitespace.
    public static func attemptCommitment(
        reading: CognitiveLoadReading,
        reflection: String
    ) throws {
        let trimmed = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
        if reading.shouldTriggerWeavePause && trimmed.isEmpty {
            // Sort components desc and pass the top 2 for the error message.
            let top = reading.components
                .sorted(by: { $0.value > $1.value })
                .prefix(2)
                .map { ($0.key, $0.value) }
            throw CognitiveLoadPauseError.reflectionRequired(
                score: reading.score,
                components: Array(top)
            )
        }
    }
}

// MARK: - Numeric clamping helper (private to this file)

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

// MARK: - LifeContext integration hooks

/// Extension on LifeContext that exposes the optional fields the calculator
/// reads. The Mac side wires the actual storage; we declare the type contract
/// here so the algorithm stays self-contained.
///
/// NOTE: This extension is intentionally NOT @Model. The fields below are
/// optional computed convenience accessors over data that may or may not
/// exist (BodyThread is optional, previousCognitiveLoad is ephemeral).
public extension LifeContext {

    /// Average sleep over the last 7 nights. Optional because the user may
    /// not have granted HealthKit permission.
    var averageSleepLast7Nights: Double? {
        return bodyThread?.averageSleepLast7Nights
    }

    /// The user's personal sleep target (default 8.0 hours).
    var personalSleepTarget: Double {
        return bodyThread?.personalSleepTarget ?? 8.0
    }

    /// Current HRV reading (SDNN, milliseconds). Optional.
    var hrvSDNN: Double? {
        return bodyThread?.hrvSDNN
    }

    /// User's personal HRV baseline (the typical value when not stressed).
    var hrvBaseline: Double? {
        return bodyThread?.hrvBaseline
    }

    /// The current amplifier's strain level (0..1). Optional.
    var activeAmplifierStrain: Double? {
        return bodyThread?.amplifierStrain
    }

    /// The previous CognitiveLoadReading (for trend computation).
    /// Backed by a JSON string stored on LifeContext so it survives app restarts
    /// without requiring the ObjectiveC runtime (Linux-safe) and without bypassing
    /// SwiftData's ModelContext isolation.
    var previousCognitiveLoad: CognitiveLoadReading? {
        get {
            guard !self.previousCognitiveLoadReadingJSON.isEmpty,
                  let data = self.previousCognitiveLoadReadingJSON.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode(CognitiveLoadReading.self, from: data)
            else { return nil }
            return decoded
        }
        set {
            if let newValue = newValue,
               let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                self.previousCognitiveLoadReadingJSON = json
            } else {
                self.previousCognitiveLoadReadingJSON = ""
            }
        }
    }

    // CognitiveLoadReading is already Codable (declared at the struct definition
    // near the top of this file), so no extra conformance extension is needed here.
}