// OneWeaveWidgetStubs.swift
// Phase 8 post-MVP: Harmony/Quest widgets stub + App Intents + Live Activities
// Concrete notes implemented in docs; this is placeholder stub for Xcode target setup.
// Requires: Widget Extension target, App Group for data sharing, import WidgetKit + AppIntents + ActivityKit
// All local SwiftData queries via snapshot or shared container (no direct @Model in ext).

import Foundation
import SwiftUI
import WidgetKit
import AppIntents

// Example shared snapshot for widget data parity (export from LifeContext in main app)
struct OneWeaveSnapshot: Codable {
    let harmonyScore: Double
    let weaveLevel: Int
    let weaveEssence: Int
    let streak: Int
    let graceDaysUsed: Int
    let topQuestTitle: String?
    let topQuestDomain: String?
    let masteryTiers: [String: Int]
    let timestamp: Date
}

// MARK: - Harmony Widget (small/medium)
struct HarmonyWidgetProvider: TimelineProvider {
    typealias Entry = HarmonyEntry
    
    func placeholder(in context: Context) -> HarmonyEntry {
        HarmonyEntry(date: Date(), snapshot: .init(harmonyScore: 0.82, weaveLevel: 14, weaveEssence: 680, streak: 12, graceDaysUsed: 0, topQuestTitle: "Reflect on legacy story", topQuestDomain: "Meaning", masteryTiers: ["Self": 3, "Stewardship": 2, "CareKin": 2, "Meaning": 4], timestamp: Date()))
    }
    
    func getSnapshot(in context: Context, completion: @escaping (HarmonyEntry) -> ()) {
        // In real: load from app group shared UserDefaults or JSON snapshot written by main app
        let snapshot = OneWeaveSnapshot(harmonyScore: 0.82, weaveLevel: 14, weaveEssence: 680, streak: 12, graceDaysUsed: 0, topQuestTitle: "Log 1 CareKin interaction", topQuestDomain: "CareKin", masteryTiers: ["Self":3,"Stewardship":2,"CareKin":2,"Meaning":4], timestamp: Date())
        completion(HarmonyEntry(date: Date(), snapshot: snapshot))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<HarmonyEntry>) -> ()) {
        let snapshot = OneWeaveSnapshot(harmonyScore: 0.82, weaveLevel: 14, weaveEssence: 680, streak: 12, graceDaysUsed: 0, topQuestTitle: "3-day body awareness", topQuestDomain: "Self", masteryTiers: ["Self":3,"Stewardship":2,"CareKin":2,"Meaning":4], timestamp: Date())
        let entry = HarmonyEntry(date: Date(), snapshot: snapshot)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15*60))) // refresh 15min
        completion(timeline)
    }
}

struct HarmonyEntry: TimelineEntry {
    let date: Date
    let snapshot: OneWeaveSnapshot
}

struct HarmonyWidget: Widget {
    let kind: String = "OneWeaveHarmonyWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HarmonyWidgetProvider()) { entry in
            HarmonyWidgetView(entry: entry)
        }
        .configurationDisplayName("OneWeave Harmony")
        .description("Current harmony and top quest at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct HarmonyWidgetView: View {
    var entry: HarmonyEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Harmony \(Int(entry.snapshot.harmonyScore * 100))%")
                .font(.headline)
            Text("L\(entry.snapshot.weaveLevel) • 🔥\(entry.snapshot.streak) (grace \(entry.snapshot.graceDaysUsed))")
                .font(.caption)
            if let q = entry.snapshot.topQuestTitle {
                Text("Quest: \(q)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            // Mini tapestry preview stub
            HStack(spacing: 2) {
                ForEach(["Self","Stewardship","CareKin","Meaning"], id: \.self) { d in
                    Circle().fill(Color.blue.opacity(0.6)).frame(width: 6, height: 6)
                }
            }
        }
        .padding(8)
    }
}

// MARK: - Quest Widget stub (medium family)
struct QuestWidget: Widget { /* similar provider + view for 1-2 quests + Accept intent */ }

// MARK: - App Intents for Siri/Shortcuts
struct LogWeaveIntent: AppIntent {
    static var title: LocalizedStringResource = "Log a Weave"
    static var description = IntentDescription("Quick weave capture into OneWeave threads.")
    
    @Parameter(title: "Text") var text: String
    @Parameter(title: "Thread") var thread: String?
    
    func perform() async throws -> some IntentResult {
        // In real: call via URL scheme or shared store to main app to emit TimelineEvent
        return .result()
    }
}

struct CompleteQuestIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Quest with Reflection"
    @Parameter(title: "Reflection Note") var note: String
    
    func perform() async throws -> some IntentResult {
        // Requires reflection note for full award
        return .result()
    }
}

struct ShowHarmonyIntent: AppIntent {
    static var title: LocalizedStringResource = "Show My OneWeave Harmony"
    func perform() async throws -> some IntentResult { return .result() }
}

// MARK: - Live Activity stub (for active quest or streak)
struct OneWeaveLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var questTitle: String
        var irlMinutesLeft: Int
        var currentEssence: Int
        var streak: Int
    }
    var questId: String
}

// Usage: In main app: Activity<OneWeaveLiveActivityAttributes>.request(...) with initial content state from LifeContext
// Widget for Live Activity UI in separate target.

// Widget bundle for extension
@main
struct OneWeaveWidgets: WidgetBundle {
    var body: some Widget {
        HarmonyWidget()
        // QuestWidget()
    }
}

// Notes:
// - Add to Xcode: File > New > Target > Widget Extension; share app group with main OneWeave target for snapshot JSON.
// - Privacy: All data local; widgets use on-device snapshot only.
// - Harmony/quest focus per Phase 8 + DESIGN peripheral hooks.
// - Update after MVP when core stable. See LAUNCH_CHECKLIST + tasks.md for full concrete.
// - For PWA parity: web equivalent via notification or home screen "widget" like add-to-home with dynamic manifest updates (future).
