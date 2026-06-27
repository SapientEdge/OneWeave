//
//  QuickCaptureInbox.swift
//  OneWeave
//
//  Quick Capture Inbox — single text field that auto-classifies user input
//  into the right OneWeave destination: task, calendar event, journal entry,
//  decision, or note.
//
//  Why this exists:
//    Research blueprint §4 lists "Universal Capture Inbox" as a core UX
//    primitive — single input, AI auto-routes. We can't use a real LLM
//    (privacy-first), but we can do surprisingly good routing with:
//      - Verb patterns ("buy", "call", "meet", "follow up")
//      - Time patterns ("tomorrow", "at 3pm", "next Tuesday")
//      - Decision patterns ("should I", "vs", "decide")
//      - Reflection patterns ("I feel", "today I", "noticed")
//      - Note patterns (no strong signal → default to note)
//
//    The classifier is heuristic + deterministic — same input always
//    produces the same classification. Confidence score lets the UI
//    show "Routed as: Task (87%)" so the user knows what happened.
//
//  Design pillars:
//    1. Privacy-first. No network. No LLM. No Core ML. Pure Swift pattern
//       matching on-device.
//    2. Deterministic. Same input → same classification, every time.
//       The user can build muscle memory around what gets routed where.
//    3. Reflection-gated for destinations that need it. If the classifier
//       routes to "journal", the user still needs to confirm a reflection
//       (the entry is empty otherwise). If it routes to "decision", the
//       DecisionLog reflection gate still applies.
//    4. Correctable. The UI shows the proposed route with a confidence
//       score; user can override before committing.
//    5. Anti-over-classification. Defaults to "note" when no strong signal.
//       We don't want to push everything to tasks/events.
//
//  What this file does NOT contain:
//    - The SwiftUI quick-capture sheet (Mac side).
//    - Actual persistence (Mac side wires each destination to its store).
//    - The verb pattern library — held inline below so it's auditable.
//
//  Test coverage is in .research/validate_quick_capture.py.
//

import Foundation

// MARK: - Public types

/// The destination a captured item is routed to.
public enum CaptureDestination: String, Codable, CaseIterable {
    case task
    case event
    case journal
    case decision
    case note

    public var displayName: String {
        switch self {
        case .task: return "Task"
        case .event: return "Calendar event"
        case .journal: return "Journal entry"
        case .decision: return "Decision"
        case .note: return "Note"
        }
    }

    /// Whether this destination requires a reflection gate before commit.
    public var requiresReflection: Bool {
        switch self {
        case .task: return false      // tasks are commitments but small ones
        case .event: return false     // calendar events don't gate
        case .journal: return true    // empty journal entry is meaningless
        case .decision: return true   // reasoning is the whole point
        case .note: return false      // notes can be terse
        }
    }
}

/// The classifier's classification of an input.
public struct CaptureClassification: Codable, Equatable {
    public let destination: CaptureDestination
    public let confidence: Double          // 0..1
    public let extractedTitle: String       // cleaned-up title for the destination
    public let extractedDate: Date?         // parsed time hint, if any (event routing)
    public let signals: [String: Double]    // destination → score breakdown

    public init(
        destination: CaptureDestination,
        confidence: Double,
        extractedTitle: String,
        extractedDate: Date? = nil,
        signals: [String: Double] = [:]
    ) {
        self.destination = destination
        self.confidence = confidence.clamped(to: 0...1)
        self.extractedTitle = extractedTitle
        self.extractedDate = extractedDate
        self.signals = signals
    }
}

// MARK: - Pattern signals

/// The signals we score against. Adding a new destination = adding a new
/// signals block + a scoreFor case in the classifier.
private enum CaptureSignal: String, Codable, CaseIterable {
    case task
    case event
    case journal
    case decision
    case note
}

// MARK: - Classifier

public enum QuickCaptureClassifier {

    /// Classify a free-text input into a destination.
    public static func classify(
        _ input: String,
        now: Date = Date(),
        locale: Locale = Locale(identifier: "en_US_POSIX")
    ) -> CaptureClassification {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return CaptureClassification(
                destination: .note,
                confidence: 0.0,
                extractedTitle: "",
                signals: [:]
            )
        }

        let lower = trimmed.lowercased()

        // Score each destination.
        var signals: [String: Double] = [:]
        signals[CaptureSignal.task.rawValue] = taskScore(for: lower)
        signals[CaptureSignal.event.rawValue] = eventScore(for: lower, now: now, locale: locale)
        signals[CaptureSignal.journal.rawValue] = journalScore(for: lower)
        signals[CaptureSignal.decision.rawValue] = decisionScore(for: lower)
        signals[CaptureSignal.note.rawValue] = noteScore(for: lower, signals: signals)

        // Find the winner (highest score).
        let winner = signals.max(by: { $0.value < $1.value })!
        let destination = CaptureDestination(rawValue: winner.key) ?? .note

        // Confidence: how much the winner beat the runner-up. If close,
        // it's a low-confidence classification.
        let sortedScores = signals.values.sorted(by: >)
        let gap: Double
        if sortedScores.count >= 2 {
            gap = sortedScores[0] - sortedScores[1]
        } else {
            gap = sortedScores[0]
        }
        // Normalize confidence: gap / (gap + 0.5) so a gap of 0.5 → 0.5,
        // a gap of 1.0 → ~0.67, a gap of 2.0 → ~0.80.
        let confidence = (gap / (gap + 0.5)).clamped(to: 0...1)

        // Title extraction: trim trailing punctuation, drop time-hints for non-event destinations.
        let title = extractTitle(from: trimmed, destination: destination)
        let extractedDate = destination == .event ? parseTimeHint(from: lower, now: now, locale: locale) : nil

        return CaptureClassification(
            destination: destination,
            confidence: confidence,
            extractedTitle: title,
            extractedDate: extractedDate,
            signals: signals
        )
    }

    // MARK: - Scoring helpers

    /// Score input for task routing. Strong signal: action verbs at the start.
    private static func taskScore(for input: String) -> Double {
        var score = 0.0
        // Common action verbs at the start of a task.
        let taskVerbs = ["buy", "call", "email", "text", "send", "pick up",
                         "drop off", "schedule", "remind", "fix", "replace",
                         "renew", "cancel", "renew", "follow up", "follow-up",
                         "submit", "file", "pay", "order", "return", "book",
                         "reserve", "complete", "finish", "draft", "write up",
                         "review", "check on", "look into", "ask about",
                         "tell", "let know"]
        for verb in taskVerbs {
            if input.hasPrefix(verb + " ") || input == verb {
                score += 2.0
                break  // only count the strongest hit
            }
        }
        // Question marks / "I need to" / "I should" patterns.
        if input.contains("i need to ") { score += 1.5 }
        if input.contains("i should ") { score += 1.5 }
        if input.contains("i have to ") || input.contains("i've got to ") { score += 1.5 }
        if input.contains("todo:") || input.contains("to-do:") { score += 2.0 }
        // Short imperative sentences (no time hint, no question mark) often tasks.
        let wordCount = input.split(separator: " ").count
        if wordCount <= 5 && !input.contains("?") && !input.contains(" at ") {
            score += 0.3
        }
        return score
    }

    /// Score input for event routing. Strong signal: time expressions.
    /// We subtract a small penalty if journal markers are present, because
    /// "I felt overwhelmed today" is more reflective than event-scheduling,
    /// even though "today" is a time hint.
    private static func eventScore(for input: String, now: Date, locale: Locale) -> Double {
        var score = 0.0
        let timeHints = ["tomorrow", "today", "tonight", "this morning",
                        "this afternoon", "this evening", "next week",
                        "next monday", "next tuesday", "next wednesday",
                        "next thursday", "next friday", "next saturday",
                        "next sunday", "monday", "tuesday", "wednesday",
                        "thursday", "friday", "saturday", "sunday",
                        "at 1", "at 2", "at 3", "at 4", "at 5",
                        "at 6", "at 7", "at 8", "at 9", "at 10",
                        "at 11", "at 12", "in the morning", "in the evening",
                        "noon", "midnight", "by friday", "by monday"]
        for hint in timeHints {
            if input.contains(hint) { score += 1.5; break }
        }
        // Clock-time pattern: "at 3:30pm" or "at 14:00"
        if input.range(of: #"\bat\s+\d{1,2}(:\d{2})?\s*(am|pm)?\b"#, options: .regularExpression) != nil {
            score += 2.5
        }
        // Date pattern: 2026-06-30, 6/30, June 30
        if input.range(of: #"\d{4}-\d{2}-\d{2}|\d{1,2}/\d{1,2}(/\d{2,4})?|\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\w*\s+\d{1,2}\b"#, options: .regularExpression) != nil {
            score += 2.0
        }
        // Words like "meeting", "appointment", "call with" (when not already a task verb).
        let eventNouns = ["meeting", "appointment", "session", "call with", "lunch with",
                          "dinner with", "coffee with", "interview", "doctor",
                          "dentist", "class", "lecture", "workshop", "event",
                          "concert", "show", "game", "match", "practice"]
        for noun in eventNouns {
            if input.contains(noun) { score += 1.0; break }
        }
        // Penalty if journal markers are present — "I felt X today" is reflective,
        // not event-scheduling. Only apply the soft penalty; we don't want to
        // completely override strong event signals (e.g., "I felt great about
        // my meeting tomorrow at 3pm" should still be event).
        let journalPenaltyMarkers = ["i noticed", "i felt", "i was feeling",
                                     "i'm feeling", "today i", "yesterday i",
                                     "this morning i"]
        let hasJournalMarker = journalPenaltyMarkers.contains { input.contains($0) }
        if hasJournalMarker && score < 2.0 {
            score -= 0.7
        }
        return max(0.0, score)
    }

    /// Score input for journal routing. Strong signal: first-person past/present reflection.
    private static func journalScore(for input: String) -> Double {
        var score = 0.0
        // Past-tense first-person markers.
        let journalMarkers = ["i noticed", "i felt", "i realized", "i realized that",
                              "i'm feeling", "i am feeling", "today i",
                              "this morning i", "tonight i", "yesterday i",
                              "i learned", "i saw", "i heard", "i thought",
                              "i was thinking", "i've been thinking", "i've noticed",
                              "i'm grateful", "i am grateful", "i appreciate",
                              "i want to remember", "looking back"]
        for marker in journalMarkers {
            if input.contains(marker) { score += 2.0; break }
        }
        // Longer text tends to be journal-like.
        let wordCount = input.split(separator: " ").count
        if wordCount >= 30 { score += 0.5 }
        if wordCount >= 60 { score += 0.5 }
        // Contains emotional vocabulary.
        let emotionalWords = ["happy", "sad", "frustrated", "anxious", "calm",
                             "overwhelmed", "grateful", "tired", "energized",
                             "disappointed", "proud", "embarrassed", "hopeful"]
        for word in emotionalWords {
            if input.contains(word) { score += 0.8; break }
        }
        return score
    }

    /// Score input for decision routing. Strong signal: choice phrasing.
    private static func decisionScore(for input: String) -> Double {
        var score = 0.0
        // Explicit decision phrases.
        let decisionMarkers = ["should i", "should we", "decide", "deciding",
                               "decision", "vs", "versus", "or should",
                               "weighing", "trade-off", "tradeoff",
                               "pros and cons", "either", "choose between"]
        for marker in decisionMarkers {
            if input.contains(marker) { score += 2.5; break }
        }
        // Multiple options separated by " or ".
        if input.contains(" or ") {
            // Only count if both halves look noun-like (heuristic: each side has 1-3 words).
            let parts = input.components(separatedBy: " or ")
            if parts.count >= 3 {
                let shortHalves = parts.dropFirst().dropLast().allSatisfy {
                    $0.split(separator: " ").count <= 5
                }
                if shortHalves { score += 1.5 }
            }
        }
        // Question mark at end of input that's a choice question.
        if input.hasSuffix("?") && (input.contains("should") || input.contains(" or ")) {
            score += 1.0
        }
        return score
    }

    /// Note score: residual / default. Always present at low baseline.
    private static func noteScore(for input: String, signals: [String: Double]) -> Double {
        // If no other signal is strong, note wins by default.
        let maxOther = signals.values.max() ?? 0.0
        if maxOther < 1.0 { return 1.5 }
        return 0.5  // baseline note score (so it's a fallback)
    }

    // MARK: - Title extraction

    private static func extractTitle(from input: String, destination: CaptureDestination) -> String {
        var title = input
        // Strip leading imperatives like "buy ", "call ", "remind me to "
        for prefix in ["remind me to ", "remind me ", "i need to ", "i should "] {
            if title.lowercased().hasPrefix(prefix) {
                title = String(title.dropFirst(prefix.count))
                break
            }
        }
        // Trim trailing punctuation.
        title = title.trimmingCharacters(in: CharacterSet(charactersIn: ".!?"))
        // Trim trailing time hints for non-event destinations.
        if destination != .event {
            // Heuristic: if the title contains " tomorrow" / " on Friday" etc. at the end,
            // strip it. Mac side re-attaches via extractedDate.
            let trailingTimePatterns = [
                #" tomorrow\b"#, #" today\b"#, #" tonight\b"#,
                #" next \w+\b"#, #" on \w+\b"#, #" at \d{1,2}(:\d{2})?\s*(am|pm)?\b"#
            ]
            for pattern in trailingTimePatterns {
                if let range = title.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                    title = String(title[..<range.lowerBound])
                }
            }
            title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // Capitalize first letter for display.
        if let first = title.first {
            title = first.uppercased() + title.dropFirst()
        }
        // Length cap.
        if title.count > 120 {
            title = String(title.prefix(117)) + "..."
        }
        return title
    }

    // MARK: - Time hint parsing (event-only)

    private static func parseTimeHint(
        from input: String,
        now: Date,
        locale: Locale
    ) -> Date? {
        // We use NSDataDetector for natural-language date parsing. This is
        // the same engine iOS Reminders uses for "tomorrow at 3pm" parsing.
        // On Linux, NSDataDetector may not be available; we fall back to
        // nil (no date extracted) — the event will need explicit time.
        #if canImport(Foundation) && !os(Linux)
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        let range = NSRange(input.startIndex..., in: input)
        if let match = detector?.firstMatch(in: input, options: [], range: range) {
            return match.date
        }
        #endif
        return nil
    }
}

// MARK: - Numeric clamping helper (private)

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}