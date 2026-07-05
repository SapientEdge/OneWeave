//
//  LifeGraphiOSIntegrations.swift
//  OneWeave
//
//  Shim / facade that maps the older `LifeGraphiOSIntegrations.shared.importAll(...)` API
//  used by CompassView and the prototype harness to the current per-integration helpers
//  in iOSServiceIntegrations.swift (CalendarIntegration, ContactsIntegration, HealthIntegration).
//  Centralises Data Leash enforcement + reflects imported entities back into the Life Graph.
//

import Foundation
import SwiftData

public final class LifeGraphiOSIntegrations {
    public static let shared = LifeGraphiOSIntegrations()
    private init() {}

    public struct ImportResult {
        public let source: String
        public let entities: [LifeEntity]
    }

    /// Pulls from Calendar + Contacts (Health is a separate "Body Thread" refresh).
    /// Each source respects Data Leash; returns only what was allowed + imported.
    @MainActor
    public func importAll(
        context: LifeContext,
        modelContext: ModelContext? = nil,
        onComplete: @escaping (String, [LifeEntity]) -> Void
    ) async {
        // Nemotron #7: pass the live ModelContext so the user's Data Leash settings are honoured.
        let leash = context.currentLeash(in: modelContext)

        // Calendar / Events
        let events = await CalendarIntegration.importRecentEvents(into: context, leash: leash)
        if !events.isEmpty {
            onComplete("Calendar/EventKit", events)
        }

        // Contacts
        let people = await ContactsIntegration.importContacts(into: context, leash: leash)
        if !people.isEmpty {
            onComplete("Contacts", people)
        }
    }

    /// Convenience: just the Body Thread refresh path.
    @MainActor
    @discardableResult
    public func refreshBodyThread(
        context: LifeContext,
        modelContext: ModelContext? = nil
    ) -> LifeEntity? {
        // Local reasoning: no async HealthKit access in the prototype harness.
        let leash = context.currentLeash(in: modelContext)
        guard leash.isAllowed(.health) else {
            print("[LifeGraphiOSIntegrations] Body Thread refresh blocked by Data Leash (health not allowed).")
            return nil
        }
        let sample = HealthMetrics(sleepFragmentationMinutes: 45, restingHeartRateBPM: 64)
        let reading = BodyThreadWeaver.reading(from: sample)
        return BodyThreadWeaver.weave(reading: reading, into: context, modelContext: modelContext)
    }
}
