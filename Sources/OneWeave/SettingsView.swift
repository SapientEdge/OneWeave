import SwiftUI
import SwiftData
import Foundation

struct SettingsView: View {
    @Environment(\\.modelContext) private var modelContext
    @Query private var contexts: [LifeContext]
    @Query private var quests: [WeaveQuest]
    
    @State private var showClearAlert = false
    @State private var showExport = false
    @State private var exportData = ""
    @State private var hapticEnabled = true
    @State private var showEnergyTrends = true
    @State private var smartRipples = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Privacy & Data") {
                    Text("All data stays on-device (SwiftData). No cloud sync by default. OneWeave follows Privacy by Design (PbD): data minimization, user consent/control, security, and purpose limitation as outlined in the OneWeave philosophy white paper.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Button("Export All Data (JSON)") {
                        exportAllData()
                    }
                    .foregroundStyle(.blue)
                    
                    Button("Clear All Local Data") {
                        showClearAlert = true
                    }
                    .foregroundStyle(.red)
                    
                    Toggle("Enable Haptic Feedback", isOn: $hapticEnabled)
                        .onChange(of: hapticEnabled) { _, newValue in
                            if newValue { generateHaptic(.success) }
                        }
                    
                    Toggle("Show Energy Trends", isOn: $showEnergyTrends)
                    
                    Toggle("Smart Ripples (auto-link)", isOn: $smartRipples)
                    
                    Text("Active Threads: Self, Stewardship, Care & Kin, Meaning")
                        .font(.caption2)
                }
                
                Section("Journey Preferences") {
                    Text("Energy thresholds and season awareness are automatic based on your threads.")
                        .font(.caption)
                }
                
                Section("About OneWeave") {
                    Text("One interconnected journey. Event-driven ripples across life domains. See ONEWEAVE_WHITE_PAPER.md for full philosophy (calm sophisticated UI, production readiness, privacy by design).")
                    Link("Privacy notes in GLOBAL_BEST_PRACTICES.md", destination: URL(string: "about:blank")!)
                        .font(.caption)
                }
            }
            .navigationTitle("Settings")
            .alert("Clear All Data?", isPresented: $showClearAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("This removes everything locally. No recovery.")
            }
            .sheet(isPresented: $showExport) {
                ScrollView {
                    Text(exportData)
                        .padding()
                        .font(.caption)
                        .onTapGesture { showExport = false }
                }
            }
        }
    }
    
    private func exportAllData() {
        // Full gamif export: serializes actual WeaveQuest objects (with status, reflection, etc.),
        // masteryTiers, full essenceLedger, streaks/grace details, LifeContext gamif aggregates.
        // Uses JSON for persistence verification + audit completeness (see PrivacyAudit.md edge cases:
        // quests fully included now, not stub summary; WeaveQuest in containers; clear already covers).
        // All local SwiftData; no network. For verification of persistence.
        var export: [String: Any] = [
            "metadata": [
                "exportedAt": ISO8601DateFormatter().string(from: Date()),
                "app": "OneWeave",
                "exportType": "full_gamification",
                "privacy": "All data local SwiftData only. No cloud. PbD: data minimization, user consent/control via export/clear. See PrivacyAudit.md for full review, edge cases addressed (full WeaveQuest serialization, no dangling refs, reflection gates separate).",
                "note": "Actual WeaveQuest list + mastery + ledger full + streaks. Full events/threads/ripples see History and Threads tabs."
            ]
        ]

        if let ctx = contexts.first {
            let streakInfo: [String: Any] = [
                "globalWeaveStreak": ctx.globalWeaveStreak,
                "lastActiveWeaveDate": ISO8601DateFormatter().string(from: ctx.lastActiveWeaveDate),
                "graceDaysUsed": ctx.graceDaysUsed,
                "maxGraceDays": ctx.maxGraceDays
            ]
            let gamif: [String: Any] = [
                "energyProfile": ctx.energyProfile.rawValue,
                "harmonyScore": ctx.harmonyScore,
                "weaveEssence": ctx.weaveEssence,
                "weaveLevel": ctx.weaveLevel,
                "masteryTiers": ctx.masteryTiers,
                "completedQuestCount": ctx.completedQuestCount,
                "activeQuests": ctx.activeQuests.map { $0.uuidString },
                "essenceLedgerFull": ctx.essenceLedger,
                "streak": streakInfo,
                "levelProgress": ctx.levelProgress
            ]
            export["lifeContextGamif"] = gamif
        }

        // Serialize actual WeaveQuest (full, not summary/mentions)
        let questsData: [[String: Any]] = quests.map { q in
            [
                "id": q.id.uuidString,
                "title": q.title,
                "questDescription": q.questDescription,
                "domains": q.domains,
                "baseEssence": q.baseEssence,
                "status": q.status.rawValue,
                "estimatedIRLMinutes": q.estimatedIRLMinutes,
                "validationHints": q.validationHints,
                "linkedEventId": q.linkedEventId?.uuidString ?? NSNull(),
                "reflectionNote": q.reflectionNote ?? NSNull(),
                "completedAt": q.completedAt != nil ? ISO8601DateFormatter().string(from: q.completedAt!) : NSNull(),
                "createdAt": ISO8601DateFormatter().string(from: q.createdAt)
            ]
        }
        export["weaveQuests"] = questsData
        export["weaveQuestsCount"] = quests.count

        // Lightweight core for verification (privacy min)
        export["core"] = [
            "activeThreads": contexts.first?.activeThreads ?? [],
            "eventCount": contexts.first?.eventCount ?? 0
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: export, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            exportData = jsonString
        } else {
            exportData = "{\"error\": \"Failed to serialize full export\"}"
        }

        showExport = true
        if hapticEnabled { generateHaptic(.success) }
    }
    
    private func clearAllData() {
        try? modelContext.delete(model: LifeContext.self)
        try? modelContext.delete(model: TimelineEvent.self)
        try? modelContext.delete(model: WeaveQuest.self)
        try? modelContext.delete(model: BasicSelfThread.self)
        try? modelContext.delete(model: StewardshipThread.self)
        try? modelContext.delete(model: CareKinThread.self)
        try? modelContext.delete(model: MeaningThread.self)
        if hapticEnabled { generateHaptic(.warning) }
    }
    
    private func generateHaptic(_ style: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(style)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [LifeContext.self])
}