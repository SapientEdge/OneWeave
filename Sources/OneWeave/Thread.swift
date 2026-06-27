import SwiftData
import Foundation

// Protocol for fluid Threads (event-driven, can process ripples from other threads).
// Keep simple for production; concrete implementations in per-thread files.
protocol ThreadProtocol {
    var name: String { get }
    func processEvent(_ event: TimelineEvent, context: LifeContext, service: TimelineService)
    var recentInsights: [String] { get }
}

// Base helper (optional — concrete threads can inherit or stand alone).
// Duplication cleaned: concrete models live in their own files.
extension ThreadProtocol {
    func defaultRealWorldBridge(for event: TimelineEvent) -> String {
        if event.thread == "CareKin" || event.type.contains("care") {
            return "Schedule a short IRL moment (walk, call, shared meal) instead of another digital task."
        } else if event.type.contains("leak") || event.type.contains("stewardship") {
            return "Redirect saved time/money to an analog or legacy activity."
        }
        return "Take one real-world micro-action today tied to this thread."
    }
}

// Global best practice reference: Threads remain local. Any on-device rule-based processing.
