import Foundation
import SwiftData

// TimelineEvent: proper @Model for event-driven updates across all threads.
// Central to interconnections in OneWeave. All local-only per privacy best practices.
@Model
final class TimelineEvent: Identifiable {
    @Attribute(.unique) var id: UUID = UUID()
    var timestamp: Date
    var thread: String  // e.g. "Self", "Stewardship", "CareKin", "Meaning"
    var type: String    // e.g. "goal_added", "subscription_leak", "capture", "user_input"
    var payload: [String: String]
    var affectsEnergy: Bool = false
    var linkedThreads: [String] = []
    
    // For aggregation and search
    var summary: String?
    var privacyLevel: String = "local-only"  // enforces privacy
    
    init(
        thread: String,
        type: String,
        payload: [String: String],
        affectsEnergy: Bool = false,
        linkedThreads: [String] = [],
        summary: String? = nil
    ) {
        self.timestamp = Date()
        self.thread = thread
        self.type = type
        self.payload = payload
        self.affectsEnergy = affectsEnergy
        self.linkedThreads = linkedThreads
        self.summary = summary ?? "\(type) in \(thread)"
        self.privacyLevel = "local-only"
    }
}

// Global best practice: Privacy - all data local-first, no external logging of raw events without consent.
// No external sync unless user opts into private CloudKit. No data sent for model training.
