//
//  iOSServiceIntegrations.swift
//  OneWeave
//
//  Privacy-First, user-initiated integrations with iOS system services.
//  All data stays local; nothing leaves the device. Data Leash enforced per-category.
//  Honors:
//   - Calendar / Reminders via EventKit
//   - Contacts via Contacts.framework
//   - Health via HealthKit (read-only by default)
//   - Mail compose via MessageUI (user-driven, no background access)
//   - Notes via UniformTypeIdentifiers / share sheet (user-driven)
//
//  Each integration explicitly requests permission and respects the user's
//  granular Data Leash toggles. Failures are handled gracefully (no crashes).
//

import Foundation
import SwiftData

#if canImport(EventKit)
import EventKit
#endif
#if canImport(Contacts)
import Contacts
#endif
#if canImport(HealthKit)
import HealthKit
#endif
#if canImport(MessageUI)
import MessageUI
#endif

// MARK: - Shared permission + leash types

public enum IntegrationPermission {
    case granted
    case denied
    case notDetermined
    case restricted
    case notAvailable  // simulator without the feature, etc.
}

public enum IntegrationCategory: String, Codable, CaseIterable {
    case calendar
    case reminders
    case contacts
    case health
    case notes
    case mail
}

// MARK: - Calendar / Reminders (EventKit)

public enum CalendarIntegration {

    /// Request full-access to EventKit. Always surfaces UI; never silently granted.
    @MainActor
    public static func requestAccess() async -> IntegrationPermission {
        #if canImport(EventKit)
        let store = EKEventStore()
        do {
            if #available(iOS 17.0, *) {
                let granted = try await store.requestFullAccessToEvents()
                return granted ? .granted : .denied
            } else {
                let granted = try await store.requestAccess(to: .event)
                return granted ? .granted : .denied
            }
        } catch {
            return .denied
        }
        #else
        return .notAvailable
        #endif
    }

    /// Pull events into the Life Graph as .event entities (last 30 days + next 30).
    /// Respects Data Leash: if privacy category is private, we still ingest locally but tag isPrivate=true.
    /// Per Nemotron cycle-25 #29 + Grok #18: check the Data Leash BEFORE
    /// requesting EventKit permission. Otherwise a user who has revoked the
    /// calendar integration still gets a permission prompt they don't want.
    @MainActor
    public static func importRecentEvents(into context: LifeContext, leash: DataLeashState, daysWindow: Int = 30) async -> [LifeEntity] {
        // Leash-first: if the user has disabled calendar, return immediately
        // without prompting for permission.
        guard leash.isAllowed(.calendar) else { return [] }
        #if canImport(EventKit)
        let perm = await requestAccess()
        guard perm == .granted else { return [] }

        let store = EKEventStore()
        let cal = Calendar.current
        let now = Date()
        guard let start = cal.date(byAdding: .day, value: -daysWindow, to: now),
              let end = cal.date(byAdding: .day, value: daysWindow, to: now) else { return [] }

        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let events = store.events(matching: predicate)

        var created: [LifeEntity] = []
        for ev in events.prefix(50) {
            let title = ev.title ?? "Untitled Event"
            let entity = LifeEntity(
                type: .event,
                title: title,
                summary: ev.notes ?? "",
                memoryType: .episodic
            )
            entity.harmonyImpact = 0.02  // gentle nudge per event for awareness
            entity.domains = ["Self"]
            entity.isPrivate = leash.isPrivate(.calendar)
            entity.createdAt = ev.startDate ?? now
            context.lifeGraphEntities.append(entity)
            created.append(entity)
        }
        // New entities written — insight cache stale. Tier A #1 + Grok #10.
        if !created.isEmpty {
            GraphInsightGenerator.invalidateCache()
        }
        return created
        #else
        return []
        #endif
    }
}

// MARK: - Contacts

public enum ContactsIntegration {

    @MainActor
    public static func requestAccess() async -> IntegrationPermission {
        #if canImport(Contacts)
        let store = CNContactStore()
        do {
            let granted = try await store.requestAccess(for: .contacts)
            return granted ? .granted : .denied
        } catch {
            return .denied
        }
        #else
        return .notAvailable
        #endif
    }

    /// Pull contact identifiers (no full addresses/phones unless user opt-in).
    /// Creates .person entities with firstName/lastName only by default.
    /// Per Claude cycle-24 finding #2: enumerateContacts blocks the main
    /// thread; we detach to a background priority task and hop back to
    /// main to insert the results.
    @MainActor
    public static func importContacts(into context: LifeContext, leash: DataLeashState) async -> [LifeEntity] {
        #if canImport(Contacts)
        // T080 (GLM 5.2 round 1, cross-verified by Grok supergrok):
        // Data Leash must be checked BEFORE requesting Contacts permission
        // (constitution #2: zero-trust privacy). Calendar + Reminders paths
        // already do this (Grok #18 fix); Contacts was the lone outlier.
        guard leash.isAllowed(.contacts) else { return [] }
        let perm = await requestAccess()
        guard perm == .granted else { return [] }

        // Detach the heavy enumeration off the main actor. The collect closure
        // runs on a background priority task; we marshal results back at the end.
        let collected: [(name: String, organization: String)] = await Task.detached(priority: .userInitiated) {
            let store = CNContactStore()
            let keys: [CNKeyDescriptor] = [
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactOrganizationNameKey as CNKeyDescriptor
            ]
            let request = CNContactFetchRequest(keysToFetch: keys)
            var results: [(String, String)] = []
            do {
                try store.enumerateContacts(with: request) { contact, stop in
                    let name = [contact.givenName, contact.familyName]
                        .filter { !$0.isEmpty }
                        .joined(separator: " ")
                    if !name.isEmpty {
                        results.append((name, contact.organizationName ?? ""))
                    }
                    if results.count >= 200 {
                        stop.pointee = true
                    }
                }
            } catch {
                // Silent failure - no crash. User can retry.
            }
            return results
        }.value

        // Back on the main actor: build entities + insert.
        var created: [LifeEntity] = []
        for (name, organization) in collected {
            let entity = LifeEntity(
                type: .person,
                title: name,
                summary: organization,
                memoryType: .semantic
            )
            entity.domains = ["CareKin"]
            entity.isPrivate = leash.isPrivate(.contacts)
            entity.harmonyImpact = 0.01
            context.lifeGraphEntities.append(entity)
            created.append(entity)
        }
        // New entities written — insight cache stale. Tier A #1 + Grok #10.
        if !created.isEmpty {
            GraphInsightGenerator.invalidateCache()
        }
        return created
        #else
        return []
        #endif
    }
}

// MARK: - Health (HealthKit)

public enum HealthIntegration {

    @MainActor
    public static func requestAccess() async -> IntegrationPermission {
        #if canImport(HealthKit)
        guard HKHealthStore.isHealthDataAvailable() else { return .notAvailable }
        // Read-only access to a small, wellness-focused set
        let typeIds: [HKQuantityTypeIdentifier] = [.stepCount, .heartRate, .restingHeartRate]
        let categoryIds: [HKCategoryTypeIdentifier] = [.sleepAnalysis]
        var read: Set<HKObjectType> = []
        for id in typeIds {
            if let t = HKObjectType.quantityType(forIdentifier: id) { read.insert(t) }
        }
        for id in categoryIds {
            if let t = HKObjectType.categoryType(forIdentifier: id) { read.insert(t) }
        }
        guard !read.isEmpty else { return .notAvailable }
        do {
            try await HKHealthStore().requestAuthorization(toShare: [], read: read)
            return .granted
        } catch {
            return .denied
        }
        #else
        return .notAvailable
        #endif
    }

    /// Detect low-coherence body state: poor sleep + elevated resting HR.
    /// Returns a graded `HealthThread` value (continuous 0–1 coherence score).
    /// Backward-compatible `isLowCoherence` / `summary` properties are provided for callers
    /// that just want the binary signal + narrative. (Claude cycle-14 finding.)
    @MainActor
    public static func detectLowCoherence(leash: DataLeashState) async -> HealthThread {
        guard leash.isAllowed(.health) else {
            return HealthThread(awakeMinutes: 0, maxRestingHR: 0, sampleDays: 0)
        }
        #if canImport(HealthKit)
        guard HKHealthStore.isHealthDataAvailable() else {
            return HealthThread(awakeMinutes: 0, maxRestingHR: 0, sampleDays: 0)
        }
        let store = HKHealthStore()
        var awakeMins = 0.0
        var maxRHR = 0.0
        let now = Date()
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now

        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            let pred = HKQuery.predicateForSamples(withStart: weekAgo, end: now, options: [])
            let descriptor = HKSampleQueryDescriptor(
                predicates: [.sample(type: sleepType, predicate: pred)],
                sortDescriptors: []
            )
            let samples = (try? await descriptor.result(for: store)) ?? []
            awakeMins = samples.compactMap { $0 as? HKCategorySample }
                .filter { $0.value == HKCategoryValueSleepAnalysis.awake.rawValue }
                .reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) / 60 }
        }

        if let rhrType = HKObjectType.quantityType(forIdentifier: .restingHeartRate) {
            let pred = HKQuery.predicateForSamples(withStart: weekAgo, end: now, options: [])
            let descriptor = HKSampleQueryDescriptor(
                predicates: [.quantitySample(type: rhrType, predicate: pred)],
                sortDescriptors: []
            )
            let samples = (try? await descriptor.result(for: store)) ?? []
            maxRHR = samples.map { $0.quantity.doubleValue(for: .count()) }.max() ?? 0
        }

        return HealthThread(awakeMinutes: awakeMins, maxRestingHR: maxRHR, sampleDays: 7)
        #else
        return HealthThread(awakeMinutes: 0, maxRestingHR: 0, sampleDays: 0)
        #endif
    }

    /// Compose a gentle "Weave Pause" prompt when low coherence is detected.
    /// Caller is expected to gate on a reflection text before any action.
    @MainActor
    public static func weavePausePrompt(summary: String) -> String {
        return """
        Your body is signaling fatigue.

        \(summary)

        Weave Pause: take 3 minutes to note one thing you need to soften today.
        """
    }
}

// MARK: - Mail (MessageUI) — user-driven, no background access.
//
// Tier A #2: full implementation. All entry points check the Data Leash before
// preparing any payload. The user always sees and confirms the message — we
// never send silently. Mail bodies for insights/decisions are formatted from
// the user's own words (reflection text), so even if Data Leash is "open" we
// never include graph content the user did not explicitly compose.

public enum MailIntegration {

    /// Whether the device can currently send mail. False on simulator without
    /// an account, or when MessageUI is unavailable.
    public static var canSendMail: Bool {
        #if canImport(MessageUI)
        return MFMailComposeViewController.canSendMail()
        #else
        return false
        #endif
    }

    /// Build a `mailto:` URL the app can hand to `UIApplication.shared.open`.
    /// Used as a fallback when MFMailComposeViewController is not available
    /// (e.g. iPad split-view, simulator without an account).
    /// Returns `nil` if Data Leash denies the mail category, or if inputs are empty.
    public static func composeURL(
        to recipient: String,
        subject: String,
        body: String,
        leash: DataLeashState = .strictDefault
    ) -> URL? {
        guard leash.isAllowed(.mail) else { return nil }
        guard !recipient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = recipient
        var queryItems: [URLQueryItem] = []
        if !subject.isEmpty {
            queryItems.append(URLQueryItem(name: "subject", value: subject))
        }
        if !body.isEmpty {
            queryItems.append(URLQueryItem(name: "body", value: body))
        }
        components.queryItems = queryItems
        return components.url
    }

    /// Format a calm email body from an insight + the user's reflection.
    /// The body is *entirely* the user's words plus a header — we never include
    /// graph node contents, only the title the user already saw and approved.
    /// Returns `nil` if reflection is empty (reflection gate) or leash denies.
    public static func insightBody(
        insightTitle: String,
        reflection: String,
        leash: DataLeashState = .strictDefault
    ) -> String? {
        guard leash.isAllowed(.mail) else { return nil }
        let trimmed = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return """
        Subject: Weave note — \(insightTitle)

        — Begin reflection —
        \(trimmed)
        — End reflection —

        Sent from OneWeave. Your words, your privacy.
        """
    }

    /// Compose a decision-shaped email body from a Resonance Oracle commit.
    /// The user already wrote the reflection in-app; this just packages it.
    /// Returns `nil` if reflection is empty or leash denies.
    public static func decisionBody(
        scenarioSummary: String,
        reflection: String,
        leash: DataLeashState = .strictDefault
    ) -> String? {
        guard leash.isAllowed(.mail) else { return nil }
        let trimmedReflection = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedScenario = scenarioSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedReflection.isEmpty else { return nil }
        let scenarioLine = trimmedScenario.isEmpty ? "(scenario omitted)" : trimmedScenario
        return """
        Subject: Weave decision

        Scenario: \(scenarioLine)

        My decision and why:
        \(trimmedReflection)

        Sent from OneWeave. Local-first, your words only.
        """
    }

    #if canImport(MessageUI) && canImport(UIKit)
    /// Build a configured MFMailComposeViewController for SwiftUI presentation.
    /// Caller is responsible for the UIViewControllerRepresentable wrapper and
    /// for dismissing it after the user finishes.
    /// Returns `nil` if the device cannot send mail or Data Leash denies.
    @MainActor
    public static func makeComposer(
        to recipient: String,
        subject: String,
        body: String,
        leash: DataLeashState = .strictDefault
    ) -> MFMailComposeViewController? {
        guard leash.isAllowed(.mail), canSendMail else { return nil }
        let composer = MFMailComposeViewController()
        if !recipient.trimmingCharacters(in: .whitespaces).isEmpty {
            composer.setToRecipients([recipient])
        }
        if !subject.isEmpty {
            composer.setSubject(subject)
        }
        if !body.isEmpty {
            composer.setMessageBody(body, isHTML: false)
        }
        return composer
    }
    #endif
}

// MARK: - Notes (UniformTypeIdentifiers) — user-driven via share sheet.
//
// Tier A #2: full implementation. Notes are local markdown payloads the user
// hands to the Notes app via the system share sheet. We never write to Notes
// directly (no entitlement, no background access). All entry points gate on
// Data Leash and on the user's own words — we never auto-generate note bodies
// from graph contents the user didn't write.

public enum NotesIntegration {

    /// Whether Notes export is available on this device. Always true when
    /// UniformTypeIdentifiers is importable (iOS 14+).
    public static var isAvailable: Bool {
        #if canImport(UniformTypeIdentifiers)
        return true
        #else
        return false
        #endif
    }

    /// Plain-text payload for a generic note (Markdown headers).
    /// Kept as the original public API for callers that just want a header.
    public static func notePayload(title: String, body: String) -> String {
        return """
        # \(title)

        \(body)
        """
    }

    /// Format a quest reflection as a calm note body. Always includes the
    /// reflection text verbatim and an attribution footer. The quest title is
    /// the user-visible header they wrote. No graph nodes are included.
    /// Returns `nil` if reflection is empty (reflection gate) or leash denies.
    public static func reflectionPayload(
        questTitle: String,
        reflection: String,
        domains: [String],
        leash: DataLeashState = .strictDefault
    ) -> String? {
        guard leash.isAllowed(.notes) else { return nil }
        let trimmed = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let domainLine = domains.isEmpty ? "" : "\n_Threads: \(domains.joined(separator: ", "))_\n"
        return """
        # Weave: \(questTitle)\(domainLine)

        ## Reflection

        \(trimmed)

        ---
        Captured in OneWeave on \(ISO8601DateFormatter().string(from: Date())).
        """
    }

    /// Format a committed Oracle decision as a note. The user's reflection and
    /// scenario summary are their own words; we just give it structure.
    /// Returns `nil` if reflection is empty or leash denies.
    public static func decisionPayload(
        scenarioSummary: String,
        reflection: String,
        leash: DataLeashState = .strictDefault
    ) -> String? {
        guard leash.isAllowed(.notes) else { return nil }
        let trimmedReflection = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedScenario = scenarioSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedReflection.isEmpty else { return nil }
        let scenarioBlock = trimmedScenario.isEmpty
            ? ""
            : """
            ## Scenario

            \(trimmedScenario)

            """
        return """
        # Weave Decision

        \(scenarioBlock)## Why I chose this

        \(trimmedReflection)

        ---
        Captured in OneWeave on \(ISO8601DateFormatter().string(from: Date())).
        """
    }

    /// Format a generic "life snapshot" for archival. Takes the user's own
    /// summary text (no graph nodes). Returns `nil` if summary is empty or
    /// leash denies.
    public static func snapshotPayload(
        title: String,
        summary: String,
        leash: DataLeashState = .strictDefault
    ) -> String? {
        guard leash.isAllowed(.notes) else { return nil }
        let trimmed = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return """
        # \(title)

        \(trimmed)

        ---
        OneWeave snapshot, \(ISO8601DateFormatter().string(from: Date())).
        """
    }
}

// MARK: - Reminders (EventKit) — full implementation.
//
// Tier A #2: reminders are pulled in as `.task` Life Graph entities (a reminder
// *is* a task, semantically). Same gating pattern as Calendar/Contacts/Health:
// request access, check Data Leash, cap the batch, tag `isPrivate` from the
// leash's privacy toggle, append to the graph.
//
// Fresh unique twist: completed reminders receive a gentle positive
// `harmonyImpact` so the Insight Engine can pick up "you've been following
// through" patterns without us declaring them explicitly.

public enum RemindersIntegration {

    /// Request write-or-read access to the Reminders store. We ask for the
    /// minimum scope we actually use (read + create).
    @MainActor
    public static func requestAccess() async -> IntegrationPermission {
        #if canImport(EventKit)
        let store = EKEventStore()
        do {
            if #available(iOS 17.0, *) {
                let granted = try await store.requestFullAccessToReminders()
                return granted ? .granted : .denied
            } else {
                let granted = try await store.requestAccess(to: .reminder)
                return granted ? .granted : .denied
            }
        } catch {
            return .denied
        }
        #else
        return .notAvailable
        #endif
    }

    /// Pull incomplete + recently-completed reminders into the Life Graph as
    /// `.task` entities. Honors Data Leash; respects `isPrivate`.
    /// Returns the created entities (empty if denied or leash blocks).
    @MainActor
    public static func importReminders(
        into context: LifeContext,
        leash: DataLeashState,
        includeCompleted: Bool = true,
        cap: Int = 100
    ) async -> [LifeEntity] {
        // Leash-first (Nemotron #29 + Grok #18): don't prompt for permission
        // if the user has disabled reminders.
        guard leash.isAllowed(.reminders) else { return [] }
        #if canImport(EventKit)
        let perm = await requestAccess()
        guard perm == .granted else { return [] }

        let store = EKEventStore()
        let cal = Calendar.current
        let now = Date()
        guard let farPast = cal.date(byAdding: .year, value: -2, to: now),
              let farFuture = cal.date(byAdding: .year, value: 1, to: now) else { return [] }

        let predicate = store.predicateForIncompleteReminders(
            withDueDateStarting: nil, ending: farFuture, calendars: nil
        )
        let incomplete: [EKReminder] = (try? await store.reminders(matching: predicate)) ?? []

        var completed: [EKReminder] = []
        if includeCompleted {
            let completedPred = store.predicateForCompletedReminders(
                withCompletionDateStarting: farPast,
                ending: now,
                calendars: nil
            )
            completed = (try? await store.reminders(matching: completedPred)) ?? []
        }

        var created: [LifeEntity] = []
        for r in (incomplete + completed).prefix(cap) {
            let title = r.title ?? "Untitled Reminder"
            // Per Nemotron cycle-25 #31: reminder notes can contain sensitive
            // content the user did not intend to surface. If the leash marks
            // this as private, drop the notes from the summary entirely. If
            // not private, include them as before.
            let notes = r.notes ?? ""
            let summaryText: String
            if leash.isPrivate(.reminders) {
                // Hash the notes so we know the user has notes on this reminder
                // but don't surface them to the Insight Engine / Mentor.
                let hash = notes.hashValue
                summaryText = notes.isEmpty ? "" : "[notes redacted — hash:\(hash)]"
            } else {
                summaryText = notes
            }
            let entity = LifeEntity(
                type: .task,
                title: title,
                summary: summaryText,
                memoryType: .procedural
            )
            // Gentle signal: completed reminders are mildly positive, incomplete neutral.
            if r.isCompleted {
                entity.harmonyImpact = 0.05
            } else {
                entity.harmonyImpact = 0.0
            }
            entity.domains = ["Self"]
            entity.isPrivate = leash.isPrivate(.reminders)
            entity.attributes = [
                "reminder_id": r.calendarItemIdentifier,
                "completed": r.isCompleted ? "true" : "false",
                "due": r.dueDateComponents?.date.map { ISO8601DateFormatter().string(from: $0) } ?? ""
            ].filter { !$0.value.isEmpty }
            entity.createdAt = r.completionDate ?? now
            entity.lastUpdated = now
            context.lifeGraphEntities.append(entity)
            created.append(entity)
        }
        // Refresh the insight cache so a freshly-imported reminder batch is
        // visible to the Insight Engine on the next read. Tier A #1.
        GraphInsightGenerator.invalidateCache()
        return created
        #else
        return []
        #endif
    }

    /// Create a new reminder from a WeaveQuest. Returns the created `EKReminder`
    /// so the caller can present a confirmation; returns nil if access denied
    /// or leash blocks. Reflection-gated: caller must pass non-empty reflection.
    /// Marked `async` per Grok cycle-24 finding #2 (the function calls
    /// `await requestAccess()` and therefore must propagate async).
    @MainActor
    public static func createReminder(
        title: String,
        notes: String,
        dueDate: Date?,
        reflection: String,
        into context: LifeContext,
        leash: DataLeashState,
        modelContext: ModelContext? = nil
    ) async -> Bool {
        let trimmedReflection = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedReflection.isEmpty else {
            print("[Reminders] Reflection gate: cannot create reminder without reflection.")
            return false
        }
        guard leash.isAllowed(.reminders) else { return false }
        #if canImport(EventKit)
        let perm = await requestAccess()
        guard perm == .granted else { return false }
        let store = EKEventStore()
        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.notes = notes
        if let due = dueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: due
            )
        }
        do {
            try store.save(reminder, commit: true)
            // Mirror to the Life Graph so insight/oracle can see the new task.
            let entity = LifeEntity(
                type: .task,
                title: title,
                summary: notes,
                memoryType: .procedural
            )
            entity.domains = ["Self"]
            entity.isPrivate = leash.isPrivate(.reminders)
            entity.harmonyImpact = 0.0
            // Per Nemotron cycle-25 #33: don't store the plaintext reflection
            // in entity attributes (it's persisted to disk). Record only the
            // reminder id and the existence of a reflection.
            entity.attributes = [
                "reminder_id": reminder.calendarItemIdentifier,
                "has_reflection": "true"
            ]
            if let mc = modelContext { mc.insert(entity) }
            context.lifeGraphEntities.append(entity)
            GraphInsightGenerator.invalidateCache()
            return true
        } catch {
            return false
        }
        #else
        return false
        #endif
    }
}

// MARK: - HealthThread (graded body-coherence value type)
// Claude cycle-14 finding: replaces the brittle binary (isLow, summary) detection.
// Continuous 0–1 score (1 = restored) so the Insight Engine and Resonance Oracle
// can read an actual body signal from the graph.

public struct HealthThread: Equatable, Codable {
    public var awakeMinutes: Double   // fragmented-sleep proxy
    public var maxRestingHR: Double   // strain proxy
    public var sampleDays: Int

    public init(awakeMinutes: Double, maxRestingHR: Double, sampleDays: Int) {
        self.awakeMinutes = awakeMinutes
        self.maxRestingHR = maxRestingHR
        self.sampleDays = sampleDays
    }

    /// Continuous 0–1 body coherence (1 = fully restored).
    public var bodyCoherence: Double {
        let sleepPenalty = min(1.0, awakeMinutes / 180.0)     // 3h awake => full penalty
        let hrPenalty = max(0.0, (maxRestingHR - 60) / 40)    // 60→100 bpm scaled
        return (1.0 - 0.6 * sleepPenalty - 0.4 * hrPenalty).clamped(to: 0...1)
    }

    public var isLowCoherence: Bool { bodyCoherence < 0.45 }

    /// Calm narrative for the Weave Pause prompt.
    public var summary: String {
        if isLowCoherence {
            return "Body signal: fragmented sleep + elevated resting heart rate."
        }
        return ""
    }

    /// Persist as a first-class graph node so insights/oracle can see body state.
    /// Per Claude cycle-24 finding #3: must be @MainActor because it calls
    /// @MainActor-isolated `GraphInsightGenerator.invalidateCache()`.
    @discardableResult
    @MainActor
    public func weaveIntoGraph(_ context: LifeContext, modelContext: ModelContext? = nil) -> LifeEntity {
        let e = LifeEntity(
            type: .healthMetric,
            title: "Body signal",
            summary: "Awake \(Int(awakeMinutes))m • RHR \(Int(maxRestingHR)) • coherence \(String(format: "%.2f", bodyCoherence))",
            memoryType: .episodic
        )
        e.domains = ["Self"]
        e.isPrivate = true   // health is always private
        e.harmonyImpact = (bodyCoherence - 0.5) * 0.2  // signed nudge
        if let mc = modelContext { mc.insert(e) }
        context.lifeGraphEntities.append(e)
        // New health entity written — insight cache stale. Tier A #1.
        GraphInsightGenerator.invalidateCache()
        return e
    }
}
