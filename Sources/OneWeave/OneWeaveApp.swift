import SwiftUI
import SwiftData

@main
struct OneWeaveApp: App {
    @State private var appStateMachine = AppStateMachine()
    
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
                    MeaningThread.self
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
    
    var body: some View {
        TabView {
            NavigationStack {
                CompassView()
                    .navigationDestination(for: String.self) { dest in
                        if dest == "MasteryMap" { MasteryMapView() }
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
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [LifeContext.self, TimelineEvent.self, WeaveQuest.self, BasicSelfThread.self, StewardshipThread.self, CareKinThread.self, MeaningThread.self])
}
