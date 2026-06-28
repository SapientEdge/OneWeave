//
//  DailyBriefings.swift
//  OneWeave
//
//  Morning Briefing + Evening Review generators — pure on-device synthesis
//  from existing LifeContext data.
//
//  Why this exists:
//    The research blueprint lists "Adaptive daily briefing" + "Morning/evening
//    briefings" as a Phase 3 capability. Users on journaling apps consistently
//    ask for "what should I focus on today" and "what did I actually accomplish"
//    — the daily/weekly review pattern. This file implements both without
//    requiring any new data sources.
//
//  Design pillars:
//    1. Pure synthesis. Both briefings read from existing fields. No new
//       inputs to track.
//    2. Reflection-gated. Evening review requires at least one reflection
//       written today; otherwise it offers "Write your reflection" as the
//       first item. (Same principle as other commit-shaped outputs.)
//    3. Anti-noise. The morning briefing is exactly N items, not 50. The
//       evening review summarizes, not enumerates.
//    4. Local-only. Everything derived from on-device data. Weather input
//       is mocked at the API boundary — the Mac side wires CoreLocation.
//    5. Time-aware. Both briefings vary by time of day: morning before 9am
//       leans toward "set up your day"; evening after 8pm leans toward
//       "close your day."
//
//  What this file does NOT contain:
//    - The SwiftUI rendering. Mac side draws these as Cards on Compass.
//    - Notification scheduling. Mac side uses UNUserNotificationCenter.
//    - CoreLocation. The Mac-side `WeatherProvider` protocol supplies it.
//
//  Test coverage is in .research/validate_daily_briefings.py.
//

import Foundation

// MARK: - Time of day classifier

/// Buckets for time-of-day-aware briefing variations.
public enum TimeOfDay: String, Codable, CaseIterable {
    case earlyMorning  // 5am - 9am
    case morning       // 9am - 12pm
    case afternoon     // 12pm - 5pm
    case evening       // 5pm - 8pm
    case night         // 8pm - 5am

    public static func from(hour: Int) -> TimeOfDay {
        switch hour {
        case 5..<9: return .earlyMorning
        case 9..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<20: return .evening
        default: return .night
        }
    }
}

// MARK: - Briefing section types

/// A single section within a briefing. Pure value type so the rendering
/// layer can iterate without knowing the underlying LifeContext shape.
public enum BriefingSection: Codable, Equatable {
    case greeting(timeOfDay: TimeOfDay)
    case weather(tempF: Int, condition: String)         // mocked
    case cognitiveLoad(score: Double, trend: String, shouldPause: Bool)
    case calendar(events: [BriefCalendarEvent])
    case priorities(quests: [BriefQuest])
    case echoes(countdowns: [BriefEchoCountdown])
    case bodyThread(avgSleep: Double, sleepTarget: Double, hrvStatus: String)
    case yesterdayRecap(reflectionsWritten: Int, questsCompleted: Int, harmonyDelta: Double)
    case openThreads(count: Int)
    case eveningPrompt(prompt: String)
    case quietReminder
    /// Cycle 34 / T147 (GLM A3): "One Neglect" — the single thread with the
    /// steepest week-over-week decay, framed as invitation, not accusation.
    /// Embodies Constitution §3 (calm) + §7 (anti-addictive). Mac renders as
    /// a single gentle card with optional reflection CTA.
    case oneNeglect(threadName: String, daysSinceLastCare: Int, suggestedAction: String)

    /// Display priority (lower = higher priority). Used by the renderer
    /// to decide what to show first when space is tight.
    public var priority: Int {
        switch self {
        case .greeting: return 0
        case .cognitiveLoad: return 5
        case .weather: return 10
        case .bodyThread: return 15
        case .calendar: return 20
        case .priorities: return 25
        case .echoes: return 30
        case .oneNeglect: return 32  // cycle 34 / T147 — single calm card after echoes
        case .openThreads: return 35
        case .yesterdayRecap: return 40
        case .eveningPrompt: return 50
        case .quietReminder: return 90
        }
    }
}

public struct BriefCalendarEvent: Codable, Equatable {
    public let id: UUID
    public let title: String
    public let startTime: Date
    public let durationMinutes: Int

    public init(id: UUID, title: String, startTime: Date, durationMinutes: Int) {
        self.id = id
        self.title = title
        self.startTime = startTime
        self.durationMinutes = durationMinutes
    }
}

public struct BriefQuest: Codable, Equatable {
    public let id: UUID
    public let title: String
    public let isHeavy: Bool             // requires reflection-on-completion
    public let priorityHint: Int          // 1 = top, 5 = lowest

    public init(id: UUID, title: String, isHeavy: Bool, priorityHint: Int) {
        self.id = id
        self.title = title
        self.isHeavy = isHeavy
        self.priorityHint = priorityHint.clamped(to: 1...5)
    }
}

public struct BriefEchoCountdown: Codable, Equatable {
    public let id: UUID
    public let title: String
    public let daysUntilUnlock: Int
    public let isReadyToOpen: Bool

    public init(id: UUID, title: String, daysUntilUnlock: Int, isReadyToOpen: Bool) {
        self.id = id
        self.title = title
        self.daysUntilUnlock = daysUntilUnlock
        self.isReadyToOpen = isReadyToOpen
    }
}

// MARK: - Briefing outputs

/// A morning briefing. Composed of N sections, ordered by priority.
public struct MorningBriefing: Codable, Equatable {
    public let generatedAt: Date
    public let sections: [BriefingSection]

    public init(generatedAt: Date, sections: [BriefingSection]) {
        self.generatedAt = generatedAt
        self.sections = sections.sorted(by: { $0.priority < $1.priority })
    }

    public var headline: String {
        // The first non-greeting section's "value" — used by widget summary.
        for section in sections {
            if case .weather(let temp, let cond) = section {
                return "\(temp)° \(cond)"
            }
            if case .cognitiveLoad(let score, let trend, _) = section, score >= 0.70 {
                return "Load \(Int(score * 100))% (\(trend))"
            }
        }
        return sections.count > 1 ? "Ready" : "Quiet day"
    }
}

/// An evening review. Same shape but different composition logic.
public struct EveningReview: Codable, Equatable {
    public let generatedAt: Date
    public let sections: [BriefingSection]

    public init(generatedAt: Date, sections: [BriefingSection]) {
        self.generatedAt = generatedAt
        self.sections = sections.sorted(by: { $0.priority < $1.priority })
    }

    /// Whether the user wrote at least one reflection today. If false,
    /// the renderer should prompt them to write one before closing the day.
    public var wroteReflectionToday: Bool {
        if case .yesterdayRecap(let r, _, _) = sections.first(where: {
            if case .yesterdayRecap = $0 { return true }; return false
        }) {
            return r > 0
        }
        return false
    }
}

// MARK: - Weather provider (protocol; Mac side implements with CoreLocation)

/// Abstraction over weather. Linux harness uses a mocked implementation;
/// the Mac side wires CoreLocation + WeatherKit.
public protocol WeatherProvider {
    func currentWeather(now: Date) -> (tempF: Int, condition: String)?
}

/// Mock weather provider for the harness. Returns nil (no weather) so the
/// briefing is unaffected by the missing data source. The Mac side ignores
/// this and uses a real implementation.
public struct NullWeatherProvider: WeatherProvider {
    public init() {}
    public func currentWeather(now: Date) -> (tempF: Int, condition: String)? {
        return nil
    }
}

// MARK: - Generator

public enum DailyBriefingGenerator {

    /// Generate a morning briefing for the given context.
    public static func morningBriefing(
        from context: LifeContext,
        weather: WeatherProvider = NullWeatherProvider(),
        cognitiveLoad: CognitiveLoadReading? = nil,
        relationshipRecords: [RelationshipRecord] = [],
        recentlySurfacedRelationships: [String: Date] = [:],
        now: Date = Date(),
        maxPriorities: Int = 3,
        maxCalendar: Int = 5,
        maxEchoes: Int = 3
    ) -> MorningBriefing {
        let hour = Calendar.current.component(.hour, from: now)
        let tod = TimeOfDay.from(hour: hour)
        var sections: [BriefingSection] = []

        // 1. Greeting.
        sections.append(.greeting(timeOfDay: tod))

        // 2. Cognitive load (if available and worth showing).
        if let reading = cognitiveLoad, reading.score >= 0.50 {
            sections.append(.cognitiveLoad(
                score: reading.score,
                trend: reading.trend.rawValue,
                shouldPause: reading.shouldTriggerWeavePause
            ))
        }

        // 3. Weather (if provider returns data).
        if let w = weather.currentWeather(now: now) {
            sections.append(.weather(tempF: w.tempF, condition: w.condition))
        }

        // 4. Body thread — sleep + HRV.
        if let bt = context.bodyThread {
            let hrvStatus: String
            if let hrv = bt.hrvSDNN, let base = bt.hrvBaseline, base > 0 {
                let ratio = hrv / base
                if ratio >= 1.0 { hrvStatus = "Recovered" }
                else if ratio >= 0.7 { hrvStatus = "Normal" }
                else { hrvStatus = "Stressed" }
            } else {
                hrvStatus = "Unmeasured"
            }
            sections.append(.bodyThread(
                avgSleep: bt.averageSleepLast7Nights ?? 7.0,
                sleepTarget: bt.personalSleepTarget ?? 8.0,
                hrvStatus: hrvStatus
            ))
        }

        // 5. Calendar — next 12h of events.
        let calendarCutoff = now.addingTimeInterval(12 * 3600)
        let upcomingEvents = context.timeline
            .filter { $0.timestamp >= now && $0.timestamp <= calendarCutoff }
            .sorted(by: { $0.timestamp < $1.timestamp })
            .prefix(maxCalendar)
            .map { event in
                // Estimate duration: default 60 min if no metadata; Mac side
                // can refine by reading EventKit.
                let duration = 60
                return BriefCalendarEvent(
                    id: event.id,
                    title: event.title,
                    startTime: event.timestamp,
                    durationMinutes: duration
                )
            }
        if !upcomingEvents.isEmpty {
            sections.append(.calendar(events: Array(upcomingEvents)))
        }

        // 6. Top priorities — uncompleted quests.
        let openQuests = context.quests
            .filter { !$0.isCompleted }
            .sorted(by: { $0.title < $1.title })  // stable sort; Mac can replace with proper priority
            .prefix(maxPriorities)
            .map { BriefQuest(id: $0.id, title: $0.title, isHeavy: true, priorityHint: 3) }
        if !openQuests.isEmpty {
            sections.append(.priorities(quests: Array(openQuests)))
        }

        // 7. Echo countdowns — ones within 7 days of unlock OR ready.
        // Mac side wires this from real SacredEcho queries.
        // For the Linux-only path we skip if no bodyThread; the Mac side
        // passes echoes via context.echoCountdowns.
        let echoes = context.upcomingEchoes
            .filter { $0.daysUntilUnlock <= 7 || $0.isReadyToOpen }
            .prefix(maxEchoes)
            .map { BriefEchoCountdown(
                id: $0.id, title: $0.title,
                daysUntilUnlock: $0.daysUntilUnlock,
                isReadyToOpen: $0.isReadyToOpen
            ) }
        if !echoes.isEmpty {
            sections.append(.echoes(countdowns: Array(echoes)))
        }

        // 8. One Neglect (cycle 34 / T147 / GLM A3) — single most-overdue
        // thread, framed as invitation. Renders as a single gentle card.
        // Lower priority than priorities/echoes so it doesn't crowd the
        // actionable items.
        if let neglect = RelationshipDecayTracker.pickOneNeglect(
            records: relationshipRecords,
            recentlySurfaced: recentlySurfacedRelationships,
            now: now
        ) {
            sections.append(.oneNeglect(
                threadName: neglect.record.displayName,
                daysSinceLastCare: neglect.daysSinceLastInteraction,
                suggestedAction: neglect.suggestedAction
            ))
        }

        return MorningBriefing(generatedAt: now, sections: sections)
    }

    /// Generate an evening review for the given context.
    /// Requires at least one reflection written today — otherwise the
    /// first section becomes a prompt to write one (reflection-gated output).
    public static func eveningReview(
        from context: LifeContext,
        cognitiveLoad: CognitiveLoadReading? = nil,
        yesterdayCognitiveLoad: CognitiveLoadReading? = nil,
        now: Date = Date()
    ) -> EveningReview {
        let hour = Calendar.current.component(.hour, from: now)
        let tod = TimeOfDay.from(hour: hour)
        var sections: [BriefingSection] = []

        // 1. Greeting (evening/night flavor).
        sections.append(.greeting(timeOfDay: tod))

        // 2. Yesterday's recap — what was accomplished today.
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        let reflectionsToday = context.timeline.filter {
            $0.timestamp >= startOfToday && $0.timestamp < endOfToday
                && ($0.note.contains("reflection") || $0.note.contains("Reflection"))
        }.count
        let questsCompletedToday = context.quests.filter {
            $0.isCompleted && $0.completedAt != nil
                && $0.completedAt! >= startOfToday && $0.completedAt! < endOfToday
        }.count
        let harmonyDelta = (cognitiveLoad.map { $0.score } ?? 0.5)
            - (yesterdayCognitiveLoad.map { $0.score } ?? 0.5)
        sections.append(.yesterdayRecap(
            reflectionsWritten: reflectionsToday,
            questsCompleted: questsCompletedToday,
            harmonyDelta: harmonyDelta
        ))

        // 3. If no reflection today, prompt for one (reflection-gated output).
        if reflectionsToday == 0 {
            sections.append(.eveningPrompt(prompt: pickEveningPrompt(now: now)))
        }

        // 4. Open threads count.
        let openCount = context.threads.filter { !$0.title.isEmpty }.count
            + context.careKinThreads.filter { !$0.title.isEmpty }.count
            + context.meaningThreads.filter { !$0.title.isEmpty }.count
            + context.stewardshipThreads.filter { !$0.title.isEmpty }.count
        if openCount > 0 {
            sections.append(.openThreads(count: openCount))
        }

        // 5. Quiet reminder if it's late (after 9pm).
        if hour >= 21 || hour < 5 {
            sections.append(.quietReminder)
        }

        return EveningReview(generatedAt: now, sections: sections)
    }

    /// Pick a rotation of evening prompts based on the day of the year.
    /// Deterministic so the same date always shows the same prompt.
    private static let eveningPrompts: [String] = [
        "What is one thing that went well today?",
        "What is something you'd like to do differently tomorrow?",
        "Who or what are you grateful for right now?",
        "What is something you noticed but didn't act on?",
        "How is your body feeling as the day winds down?",
        "What is a question you're sitting with?",
        "What did you learn about yourself today?",
        "Where did you notice energy, and where did you notice depletion?",
        "What is one small thing that would make tomorrow better?",
        "What is something you want to remember about today?"
    ]

    private static func pickEveningPrompt(now: Date) -> String {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: now) ?? 0
        return eveningPrompts[dayOfYear % eveningPrompts.count]
    }
}

// MARK: - Briefing helpers (pure functions)

// MARK: - Numeric clamping helper
private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

// MARK: - LifeContext integration

/// Extension on LifeContext exposing the optional fields the briefing
/// generator reads. The Mac side wires these via the actual store; the
/// Linux harness treats them as nil and the briefing degrades gracefully.
public extension LifeContext {

    /// The user's body-thread snapshot (sleep, HRV). Optional.
    var bodyThread: BodyThreadSnapshot? {
        get { _bodyThread }
        set { _bodyThread = newValue }
    }

    /// Upcoming Sacred Echoes (countdowns). The Mac side passes these from
    /// the real SacredEcho SwiftData query.
    var upcomingEchoes: [UpcomingEchoSnapshot] {
        get { _upcomingEchoes }
        set { _upcomingEchoes = newValue }
    }
}

/// A snapshot of body-thread data — pure value type so the generator
/// doesn't depend on the @Model type from BodyThreadWeaver.
public struct BodyThreadSnapshot: Codable, Equatable {
    public let averageSleepLast7Nights: Double?
    public let personalSleepTarget: Double?
    public let hrvSDNN: Double?
    public let hrvBaseline: Double?
    public let amplifierStrain: Double?

    public init(
        averageSleepLast7Nights: Double? = nil,
        personalSleepTarget: Double? = nil,
        hrvSDNN: Double? = nil,
        hrvBaseline: Double? = nil,
        amplifierStrain: Double? = nil
    ) {
        self.averageSleepLast7Nights = averageSleepLast7Nights
        self.personalSleepTarget = personalSleepTarget
        self.hrvSDNN = hrvSDNN
        self.hrvBaseline = hrvBaseline
        self.amplifierStrain = amplifierStrain
    }
}

public struct UpcomingEchoSnapshot: Codable, Equatable {
    public let id: UUID
    public let title: String
    public let daysUntilUnlock: Int
    public let isReadyToOpen: Bool

    public init(id: UUID, title: String, daysUntilUnlock: Int, isReadyToOpen: Bool) {
        self.id = id
        self.title = title
        self.daysUntilUnlock = daysUntilUnlock
        self.isReadyToOpen = isReadyToOpen
    }
}

private var _bodyThreadKey: UInt8 = 0
private var _upcomingEchoesKey: UInt8 = 0
public extension LifeContext {
    fileprivate var _bodyThread: BodyThreadSnapshot? {
        get { objc_getAssociatedObject(self, &_bodyThreadKey) as? BodyThreadSnapshot }
        set { objc_setAssociatedObject(self, &_bodyThreadKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    fileprivate var _upcomingEchoes: [UpcomingEchoSnapshot] {
        get { (objc_getAssociatedObject(self, &_upcomingEchoesKey) as? [UpcomingEchoSnapshot]) ?? [] }
        set { objc_setAssociatedObject(self, &_upcomingEchoesKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
}