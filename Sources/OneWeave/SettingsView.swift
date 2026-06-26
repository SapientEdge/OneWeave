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
                
                
                Section("Internal Metrics (private)") {
                    if let ctx = contexts.first {
                        Text("Essence: \(ctx.weaveEssence) • Level \(ctx.weaveLevel)")
                        Text("Completed quests: \(ctx.completedQuestCount) (reflections drive full mastery)")
                        let reflectedCount = quests.filter { ($0.reflectionNote ?? "").count > 0 }.count
                        Text("Harmony: \(Int(ctx.harmonyScore * 100))% • Reflected quests: \(reflectedCount)")
                        Text("Global streak: \(ctx.globalWeaveStreak) (grace: \(ctx.graceDaysUsed)/\(ctx.maxGraceDays))")
                        if !ctx.masteryTiers.isEmpty {
                            let tiersSummary = ctx.masteryTiers.map { "\($0.key.prefix(3)):\($0.value)" }.joined(separator: " ")
                            Text("Mastery: \(tiersSummary)")
                        }
                    }
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
        var export = "OneWeave Full Export (Gamification + Core)

"
        var gamif: [String: Any] = [:]
        if let ctx = contexts.first {
            gamif["energy"] = ctx.energyProfile.rawValue
            gamif["harmony"] = Int(ctx.harmonyScore * 100)
            gamif["streak"] = ctx.globalWeaveStreak
            gamif["grace_used"] = ctx.graceDaysUsed
            gamif["essence"] = ctx.weaveEssence
            gamif["level"] = ctx.weaveLevel
            gamif["completed_quests"] = ctx.completedQuestCount
            gamif["active_quests_count"] = ctx.activeQuests.count
            gamif["mastery_tiers"] = ctx.masteryTiers
            gamif["essence_ledger"] = Array(ctx.essenceLedger.suffix(5))
        }
        if !quests.isEmpty {
            gamif["quests"] = quests.map { ["id": $0.id.uuidString, "title": $0.title, "status": $0.status.rawValue, "reflection": $0.reflectionNote ?? ""] }
        }
        export += "Gamif JSON:
" + (String(data: try! JSONSerialization.data(withJSONObject: gamif, options: .prettyPrinted), encoding: .utf8) ?? "") + "

"
        export += "See History and Threads for full events/ripples.
Exported at \(Date())
Privacy: All local SwiftData. No cloud."
        exportData = export
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