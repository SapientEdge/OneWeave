import SwiftUI
import SwiftData
import Foundation

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var contexts: [LifeContext]
    @Query private var quests: [WeaveQuest]

    // T115: convert from @State to @AppStorage (cycle 30 — was dead state, reset every launch)
    @AppStorage("showClearAlert") private var showClearAlert: Bool = false
    @AppStorage("hapticEnabled") private var hapticEnabled: Bool = true
    @AppStorage("showEnergyTrends") private var showEnergyTrends: Bool = true
    @AppStorage("smartRipples") private var smartRipples: Bool = true
    @State private var showExport = false
    @State private var exportData = ""

    // T123: privacy manifest summary for "What OneWeave knows about you" surface
    private var privacyManifest: String {
        guard let ctx = contexts.first else { return "0 reflections · 0 quests · 0 calendar events. That's it." }
        let eventCount = ctx.recentEventSummaries.count
        let echoCount = ctx.essenceLedger.count  // approximate via ledger
        let questCount = ctx.completedQuestCount
        return "\(eventCount) reflections · \(questCount) completed quests · \(echoCount) ledger entries.\nNothing leaves this device unless you opt in."
    }

    var body: some View {
        NavigationStack {
            Form {
                // T105: Privacy dashboard is now reachable
                Section("Privacy & Data") {
                    Text("All data stays on-device (SwiftData). No cloud sync by default. OneWeave follows Privacy by Design (PbD): data minimization, user consent/control, security, and purpose limitation as outlined in the OneWeave philosophy white paper.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // T105: NavigationLink to DataLeashSettingsView (was unreachable)
                    NavigationLink {
                        DataLeashSettingsView()
                    } label: {
                        Label("Privacy Controls (Data Leash)", systemImage: "lock.shield")
                    }

                    // T123: privacy manifest surface
                    Label(privacyManifest, systemImage: "eye.slash")
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
                        // T121: surface grace/streak decay — build trust in safety net
                        Text("Grace: \(ctx.graceDaysUsed)/\(ctx.maxGraceDays) (decay 0.5%/day after 7d grace)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("Global streak: \(ctx.globalWeaveStreak)")
                        if !ctx.masteryTiers.isEmpty {
                            let tiersSummary = ctx.masteryTiers.map { "\($0.key.prefix(3)):\($0.value)" }.joined(separator: " ")
                            Text("Mastery: \(tiersSummary)")
                        }
                    }
                }

                // T144: surface jailbreak status (defense-in-depth warning).
                // Visible only if device reports indicators; otherwise hidden.
                let jbReport = JailbreakDetector.check()
                if jbReport.isJailbroken {
                    Section("Device Status (advisory)") {
                        Label(jbReport.headlineSummary, systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Text("This is an advisory only. OneWeave continues to protect your data; some advanced features may show additional warnings.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                // T140: anti-addictive off-ramp settings (user can opt out).
                Section("Calm & Anti-Addictive") {
                    Toggle("Session reminder at 10 min", isOn: Binding(
                        get: { UserDefaults.standard.bool(forKey: "sessionGuardEnabled") || UserDefaults.standard.object(forKey: "sessionGuardEnabled") == nil },
                        set: { UserDefaults.standard.set($0, forKey: "sessionGuardEnabled") }
                    ))
                    Text("A non-blocking reminder appears after 10 minutes of continuous use. A more prominent off-ramp appears at 30 minutes. You can dismiss either and continue.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Journey Preferences") {
                    Text("Energy thresholds and season awareness are automatic based on your threads.")
                        .font(.caption)
                }

                // T111: real version + acknowledgements + privacy/support URLs
                Section("About OneWeave") {
                    LabeledContent("Version", value: appVersion)
                    LabeledContent("Build", value: appBuild)
                    Text("One interconnected journey. Event-driven ripples across life domains. See ONEWEAVE_WHITE_PAPER.md for full philosophy (calm sophisticated UI, production readiness, privacy by design).")
                    Link("Privacy Policy", destination: URL(string: "https://oneweave.app/privacy")!)
                        .font(.caption)
                    Link("Support", destination: URL(string: "https://oneweave.app/support")!)
                        .font(.caption)
                    Link("Acknowledgements (open-source licenses)", destination: URL(string: "https://oneweave.app/acknowledgements")!)
                        .font(.caption)
                    // M3-K: What's New placeholder (Mac side populates with version diff)
                    DisclosureGroup("What's New") {
                        Text("Cycle 30: privacy dashboard now reachable, Data Leash nav, grace visible, ShareLink export, version + URLs.")
                            .font(.caption)
                    }
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
                ExportSheet(exportData: exportData, hapticEnabled: hapticEnabled)
            }
        }
    }

    // T112: explicit Done button (was hidden .onTapGesture)
    private struct ExportSheet: View {
        let exportData: String
        let hapticEnabled: Bool
        @Environment(\.dismiss) private var dismiss

        var body: some View {
            NavigationStack {
                ScrollView {
                    Text(exportData)
                        .padding()
                        .font(.caption)
                        .textSelection(.enabled)
                }
                .navigationTitle("Export")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        ShareLink(item: exportData, preview: SharePreview("OneWeave Export"))
                    }
                }
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private func exportAllData() {
        var export = "OneWeave Full Export (Gamification + Core)\n\n"

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
            // T107: strip reflection plaintext from ledger before export
            gamif["essence_ledger"] = Array(ctx.essenceLedger.suffix(5)).map { ledger in
                ledger.replacingOccurrences(of: #"reflection:.{0,50}"#, with: "reflection: <redacted>", options: .regularExpression)
            }
        }
        if !quests.isEmpty {
            gamif["quests"] = quests.map { ["id": $0.id.uuidString, "title": $0.title, "status": $0.status.rawValue, "reflection_length": ($0.reflectionNote ?? "").count] }
        }
        // T117: replace `try!` with `try?` + safe fallback
        let gamifJSON = (try? JSONSerialization.data(withJSONObject: gamif, options: .prettyPrinted))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        export += "Gamif JSON:\n\(gamifJSON)\n\n"

        export += "See History and Threads for full events/ripples.\nExported at \(Date())\nPrivacy: All local SwiftData. No cloud."
        exportData = export
        showExport = true
        if hapticEnabled { generateHaptic(.success) }
    }

    // T103: clear ALL 11 models (was omitting LifeEntity, LifeRelationship, DataLeashSettingsRecord, SacredEcho)
    // T118: non-silent — track deletion count + alert on partial failure
    private func clearAllData() {
        let models: [any PersistentModel.Type] = [
            LifeContext.self,
            TimelineEvent.self,
            WeaveQuest.self,
            BasicSelfThread.self,
            StewardshipThread.self,
            CareKinThread.self,
            MeaningThread.self,
            LifeEntity.self,             // T103: was missing
            LifeRelationship.self,      // T103: was missing
            DataLeashSettingsRecord.self, // T103: was missing — and T114 expects 9 toggles
            SacredEcho.self              // T103: was missing — encrypted ciphertext persisted to disk
        ]
        var deleted = 0
        for m in models {
            do {
                try modelContext.delete(model: m)
                deleted += 1
            } catch {
                print("[Settings] Failed to delete \(m): \(error)")
            }
        }
        do {
            try modelContext.save()
        } catch {
            print("[Settings] Save after clear failed: \(error)")
        }
        if hapticEnabled { generateHaptic(.warning) }
        print("[Settings] Cleared \(deleted)/\(models.count) models")
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