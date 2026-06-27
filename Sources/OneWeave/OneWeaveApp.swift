import SwiftUI
import SwiftData

@main
struct OneWeaveApp: App {
    @State private var appStateMachine = AppStateMachine()
    // scenePhase is consumed by MainTabView (which has @Environment(\.modelContext)
    // to fetch the singletons). Per Grok cycle-24 finding #24, having it here too
    // was dead wiring.

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .modelContainer(for: [
                    LifeContext.self,
                    TimelineEvent.self,
                    WeaveQuest.self,
                    BasicSelfThread.self,
                    StewardshipThread.self,
                    CareKinThread.self,
                    MeaningThread.self,
                    // Life Graph Tier 1 — added so modelContext.insert succeeds.
                    LifeEntity.self,
                    LifeRelationship.self,
                    DataLeashSettingsRecord.self,
                    // Sacred Echo Vault (Tier A #3) — time-capsule reflections.
                    SacredEcho.self
                ])
                .environment(appStateMachine)
        }
    }
}

// Full wired navigation: NavigationStacks per tab + shared destinations for threads and events.
// All tabs interconnected. No dead-ends. Demo removed from primary navigation (kept as separate file reference).
// State machine drives UI colors, insights, haptics across.
struct MainTabView: View {
    @Environment(AppStateMachine.self) private var stateMachine
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            NavigationStack {
                CompassView()
                    .navigationDestination(for: String.self) { dest in
                        switch dest {
                        case "QuestsView":
                            QuestsView()
                        case "EssenceLedgerView":
                            EssenceLedgerView()
                        case "MasteryMap", "MasteryMapView":
                            MasteryMapView()
                        default:
                            ThreadDetailView(threadName: dest)
                        }
                    }
                    .environment(stateMachine)
            }
            .tabItem {
                Label("Compass", systemImage: "safari")
            }

            NavigationStack {
                ThreadsOverviewView()
            }
            .tabItem {
                Label("Threads", systemImage: "rectangle.stack")
            }

            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label("History", systemImage: "clock.arrow.circlepath")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
        .onChange(of: stateMachine.currentState) { _, newState in
            // Global feedback
        }
        // Tier A #5: route scenePhase through the LifecycleCoordinator.
        // MainTabView owns @Environment(\.modelContext) so we can fetch
        // the live singletons here.
        .onChange(of: scenePhase) { _, newPhase in
            LifecycleSceneBridge.route(phase: newPhase, modelContext: modelContext)
        }
    }
}

/// Routes a scenePhase transition through the AppLifecycleCoordinator.
/// Lives in OneWeaveApp.swift because the App-level scenePhase callback
/// can't reach a ModelContext; MainTabView can, so we route through here.
@MainActor
enum LifecycleSceneBridge {
    static func route(phase: ScenePhase, modelContext: ModelContext) {
        let lifeContext: LifeContext? = try? modelContext.fetch(
            FetchDescriptor<LifeContext>()
        ).first
        let leash: DataLeashState = (try? modelContext.fetch(
            FetchDescriptor<DataLeashSettingsRecord>()
        ).first?.toState()) ?? .strictDefault
        let echoes: [SacredEcho] = (try? modelContext.fetch(
            FetchDescriptor<SacredEcho>()
        )) ?? []
        let quests: [WeaveQuest] = (try? modelContext.fetch(
            FetchDescriptor<WeaveQuest>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
        )) ?? []
        if let lc = lifeContext {
            AppLifecycleCoordinator.handleScenePhase(
                phase,
                context: lc,
                echoes: echoes,
                quests: quests,
                leash: leash,
                bodyThreadEnabled: false,  // feature flag; future toggle
                modelContext: modelContext
            )
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [
            LifeContext.self,
            TimelineEvent.self,
            WeaveQuest.self,
            BasicSelfThread.self,
            StewardshipThread.self,
            CareKinThread.self,
            MeaningThread.self,
            LifeEntity.self,
            LifeRelationship.self,
            DataLeashSettingsRecord.self,
            SacredEcho.self
        ])
}
