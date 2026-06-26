import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\\.modelContext) private var modelContext
    @Query private var contexts: [LifeContext]
    
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
        var export = "OneWeave Full Export (Gamification + Core)\n\n"
        if let ctx = contexts.first {
            export += "Energy: \(ctx.energyProfile.rawValue)\n"
            export += "Harmony: \(Int(ctx.harmonyScore * 100))%\n"
            export += "Global Streak: \(ctx.globalWeaveStreak) (grace used: \(ctx.graceDaysUsed)/\(ctx.maxGraceDays))\n"
            export += "Essence: \(ctx.weaveEssence) | Level: \(ctx.weaveLevel)\n"
            export += "Completed Quests: \(ctx.completedQuestCount)\n"
            export += "Active Quests: \(ctx.activeQuests.count)\n"
            export += "Essence Ledger (last 5): \(Array(ctx.essenceLedger.suffix(5)))\n\n"
            export += "Mastery Tiers: \(ctx.masteryTiers)\n\n"
        }
        // Note: full quests/events in History/Threads tabs; WeaveQuest persistence now enabled
        export += "See History and Threads for full events/ripples/quests.\n"
        export += "Exported at \(Date())\nPrivacy: All local SwiftData. No cloud."
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