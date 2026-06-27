// OneWeaveWidgetStubs.swift
// Phase 8 post-MVP: Harmony/Quest widgets stub + App Intents + Live Activities
// Concrete per tasks.md Phase 8: 
// - Harmony Widget (small/medium via WidgetKit): TimelineProvider pulls harmonyScore, top active/suggested quest from LifeContext/@Query; mini 4-thread tapestry preview + "Open OneWeave". 
// - Medium: 1-2 quest list with domain tags + "Accept" AppIntent deep link. 
// - Live Activity: Active quest "IRL: 15min • +baseEssence on reflect" or streak counter with grace state. Uses ActivityKit + local push updates.
// - Siri/App Intents: "Show my harmony", "Weave quick capture <text> for <thread>", "Complete current quest with reflection <note>" (donate shortcuts). 
// Shared snapshot provider (OneWeaveSnapshot) e.g. export simple struct from LifeContext for widget target. 
// Post core MVP; requires Xcode target setup for WidgetExtension (App Group for sharing snapshot JSON/UserDefaults).
// All local-only SwiftData queries via snapshot (no direct @Model in ext). Harmony/quest focus per Phase 8 + DESIGN peripheral hooks.
// Keep post-MVP scope. Update LAUNCH/tasks when core stable.

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

// MARK: - Quest Widget stub (medium family, per Phase 8 concrete)
struct QuestWidgetProvider: TimelineProvider {
    typealias Entry = QuestEntry
    
    func placeholder(in context: Context) -> QuestEntry {
        QuestEntry(date: Date(), quests: [
            OneWeaveQuestStub(title: "3-day body awareness", domain: "Self", estMinutes: 15, essence: 8),
            OneWeaveQuestStub(title: "Log 1 CareKin interaction", domain: "CareKin", estMinutes: 20, essence: 12)
        ])
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuestEntry) -> ()) {
        let q = OneWeaveQuestStub(title: "Reflect on legacy story", domain: "Meaning", estMinutes: 10, essence: 15)
        completion(QuestEntry(date: Date(), quests: [q]))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuestEntry>) -> ()) {
        let quests = [
            OneWeaveQuestStub(title: "Audit 1 subscription leak", domain: "Stewardship", estMinutes: 5, essence: 6),
            OneWeaveQuestStub(title: "Schedule non-digital meetup", domain: "CareKin", estMinutes: 30, essence: 10)
        ]
        let entry = QuestEntry(date: Date(), quests: quests)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(30*60)))
        completion(timeline)
    }
}

struct OneWeaveQuestStub: Identifiable, Codable {
    let id = UUID()
    let title: String
    let domain: String
    let estMinutes: Int
    let essence: Int
}

struct QuestEntry: TimelineEntry {
    let date: Date
    let quests: [OneWeaveQuestStub]
}

struct QuestWidget: Widget {
    let kind: String = "OneWeaveQuestWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuestWidgetProvider()) { entry in
            QuestWidgetView(entry: entry)
        }
        .configurationDisplayName("OneWeave Quests")
        .description("Top suggested quests. Tap to accept (via AppIntent).")
        .supportedFamilies([.systemMedium])
    }
}

struct QuestWidgetView: View {
    var entry: QuestEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Suggested Weaves").font(.headline)
            ForEach(entry.quests.prefix(2)) { q in
                HStack {
                    Text("• \(q.domain): \(q.title)")
                        .font(.caption)
                        .lineLimit(1)
                    Spacer()
                    Text("+\(q.essence)✧ \(q.estMinutes)m")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Text("Accept via app or Siri").font(.caption2).foregroundStyle(.tertiary)
        }
        .padding(8)
    }
}

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
        QuestWidget()
    }
}

// Notes:
// - Add to Xcode: File > New > Target > Widget Extension; share app group with main OneWeave target for snapshot JSON.
// - Privacy: All data local; widgets use on-device snapshot only.
// - Harmony/quest focus per Phase 8 + DESIGN peripheral hooks. Basic stubs now include full Harmony + Quest providers/views + intents + live attrs (polished per concrete).
// - Update after MVP when core stable. See LAUNCH_CHECKLIST + tasks.md for full concrete.
// - Simple widget preview integrated in OneWeavePrototype.swift (sim UI using snapshot-like data from LifeContext for testing flows).
// - For PWA parity: web equivalent via notification or home screen "widget" like add-to-home with dynamic manifest updates (future).
// - Post-MVP: no full target setup here (Linux env); stubs + preview only.