import SwiftUI
import SwiftData

struct ThreadsOverviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var contexts: [LifeContext]
    @Query private var selfThreads: [BasicSelfThread]
    @Query private var stewardshipThreads: [StewardshipThread]
    @Query private var careThreads: [CareKinThread]
    @Query private var meaningThreads: [MeaningThread]
    @Query(sort: \TimelineEvent.timestamp, order: .reverse) private var allEvents: [TimelineEvent]
    
    @State private var service: TimelineService?
    @State private var weaveNote: String = ""
    @State private var searchText: String = ""
    @State private var hapticTrigger = false
    
    private var context: LifeContext? { contexts.first }
    
    private var recentCrossEvents: [TimelineEvent] {
        allEvents.filter { !$0.linkedThreads.isEmpty }.prefix(5).map { $0 }
    }
    
    private var filteredThreads: [(name: String, summary: String, color: Color)] {
        let all = [
            ("Self", selfThreads.first?.summary() ?? "Track habits & goals", Color.blue),
            ("Stewardship", stewardshipThreads.first?.summary() ?? "Track subs, leaks, savings", Color.green),
            ("CareKin", careThreads.first?.summary() ?? "Family tasks & IRL", Color.orange),
            ("Meaning", meaningThreads.first?.summary() ?? "Stories & legacy", Color.purple)
        ]
        if searchText.isEmpty { return all }
        let q = searchText.lowercased()
        return all.filter { $0.0.lowercased().contains(q) || $0.1.lowercased().contains(q) }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Life Threads")
                        .font(.largeTitle.bold())
                    Spacer()
                    Text("4 interconnected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                
                if let ctx = context {
                    HStack(spacing: 12) {
                        EnergyIndicator(energy: ctx.energyProfile)
                        Text("Season: \(ctx.values["season"] ?? "—")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(ctx.eventCount) weaves")
                            .font(.caption2)
                    }
                    .padding(.horizontal)
                }
                
                // Search for threads (global-ish)
                TextField("Search threads...", text: $searchText)
                    
                    StateMachineIndicator()
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                // Tappable thread cards with modern glass + feedback
                VStack(spacing: 12) {
                    ForEach(filteredThreads, id: \.name) { item in
                        ThreadCard(
                            name: item.name,
                            summary: item.summary,
                            color: item.color,
                            threadName: item.name
                        )
                        .sensoryFeedback(.selection, trigger: hapticTrigger)
                    }
                }
                .padding(.horizontal)
                
                // Interconnections section with cross suggestions
                VStack(alignment: .leading, spacing: 10) {
                    Text("Interconnections & Weaves")
                    
                    WeaveSummaryView()
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    
                    Text("Actions ripple via TimelineService → LifeContext → Compass & other threads instantly.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal)
                    
                    if recentCrossEvents.isEmpty {
                        Text("No ripples yet. Add events in Compass or a Thread detail.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal)
                    } else {
                        ForEach(recentCrossEvents) { event in
                            NavigationLink(value: event.thread) {
                                CrossRippleRow(event: event)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                        }
                    }
                    
                    // Unified weave trigger with real integration
                    Button {
                        triggerDemoWeaveWithHaptics()
                    } label: {
                        Label("Trigger Cross-Weave Demo (Self → All)", systemImage: "arrow.triangle.2.circlepath.circle.fill")
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal)
                    
                    if !weaveNote.isEmpty {
                        Text(weaveNote)
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                            .padding(.horizontal)
                            .transition(.opacity)
                    }
                }
                
                // Cross suggestions everywhere
                if let ctx = context {
                    let insight = InsightGenerator.generate(from: ctx, recentEvents: Array(allEvents.prefix(5)))
                    VStack(alignment: .leading) {
                        Text("Global Suggestion")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Text(insight.realWorldBridge)
                            .font(.callout)
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.horizontal)
                }
                
                Text("Tap any card for rich editing + immediate cross-thread effects. Use Settings for export & search.")
                    .font(.caption2.italic())
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Threads")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            service = TimelineService(modelContext: modelContext)
            if contexts.isEmpty {
                DataSeeder.seedIfNeeded(modelContext: modelContext)
            }
            if (selfThreads.isEmpty || stewardshipThreads.isEmpty || careThreads.isEmpty || meaningThreads.isEmpty), let ctx = context {
                DataSeeder.seedThreadModels(modelContext: modelContext, service: service ?? TimelineService(modelContext: modelContext), context: ctx)
            }
        }
        .animation(.easeInOut, value: weaveNote)
        .searchable(text: $searchText, prompt: "Filter threads")
    }
    
    private func threadColor(_ thread: String) -> Color {
        switch thread {
        case "Self": return .blue
        case "Stewardship": return .green
        case "CareKin": return .orange
        case "Meaning": return .purple
        default: return .gray
        }
    }
    
    private func triggerDemoWeaveWithHaptics() {
        guard let svc = service, let ctx = context else { return }
        svc.emitEvent(
            thread: "Self",
            type: "goal_added",
            payload: ["goal": "analog evening ritual"],
            affectsEnergy: true,
            linkedThreads: ["Stewardship", "CareKin", "Meaning"]
        )
        weaveNote = "Weave triggered: Self goal rippled across all threads. Check Compass & History."
        
        if let selfT = selfThreads.first {
            let dummy = TimelineEvent(thread: "CareKin", type: "task_added", payload: ["task": "demo ripple"])
            selfT.processEvent(dummy, context: ctx, service: svc)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            weaveNote = ""
        }
    }
}

struct CrossRippleRow: View {
    let event: TimelineEvent
    
    var body: some View {
        HStack {
            Circle().fill(threadColor(event.thread)).frame(width: 7, height: 7)
            VStack(alignment: .leading) {
                Text("\(event.thread): \(event.type)")
                    .font(.caption)
                Text("→ \(event.linkedThreads.joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }
            Spacer()
            Text(event.timestamp, style: .time)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(8)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func threadColor(_ thread: String) -> Color {
        switch thread { case "Self": return .blue; case "Stewardship": return .green; case "CareKin": return .orange; case "Meaning": return .purple; default: return .gray }
    }
}

struct EnergyIndicator: View {
    let energy: EnergyProfile
    var body: some View {
        let (c, s) = switch energy {
        case .high: (Color.green, "arrow.up")
        case .low: (Color.red, "arrow.down")
        case .normal: (Color.orange, "circle")
        }
        Label(energy.rawValue, systemImage: s)
            .font(.caption.bold())
            .foregroundStyle(c)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(c.opacity(0.15))
            .clipShape(Capsule())
    }
}

#Preview {
    ThreadsOverviewView()
        .modelContainer(for: [LifeContext.self, TimelineEvent.self, BasicSelfThread.self, StewardshipThread.self, CareKinThread.self, MeaningThread.self])
}
