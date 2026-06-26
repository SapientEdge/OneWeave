import SwiftUI
import SwiftData

struct CompassView: View {
    @Environment(\\.modelContext) private var modelContext
    @Query private var contexts: [LifeContext]
    @Query(sort: \\TimelineEvent.timestamp, order: .reverse) private var allEvents: [TimelineEvent]
    @Environment(AppStateMachine.self) private var stateMachine
    @State private var quickCaptureText = ""
    @State private var service: TimelineService?
    @State private var showRipples = false
    @State private var showInsightDetail = false
    @State private var hapticTrigger = false
    @State private var lastEnergy: Double = 0.5
    @State private var lastRippleCount = 0
    @State private var showOnboarding = false
    
    private var recentEvents: [TimelineEvent] {
        Array(allEvents.prefix(8))
    }
    
    private var context: LifeContext? { contexts.first }
    
    private var crossThreadSuggestions: [String] {
        guard let ctx = context else { return [] }
        let insight = InsightGenerator.generate(from: ctx, recentEvents: recentEvents)
        var s = [insight.suggestedAction, insight.realWorldBridge]
        if let st = try? modelContext.fetch(FetchDescriptor<StewardshipThread>()).first, !st.savingsSuggestions.isEmpty {
            s.append(st.savingsSuggestions.first!)
        }
        return Array(s.prefix(3))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with state (peripheral, calm per white paper)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("OneWeave")
                            .font(.largeTitle.bold())
                        Spacer()
                        if let ctx = context {
                            StateMachineIndicator()
                            WeaveSummaryView()
                        }
                        Button {
                            showOnboarding = true
                        } label: {
                            Image(systemName: "questionmark.circle")
                        }
                    }
                    Text("Journey Compass")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                
                if let ctx = context {
                    // Dynamic rings + energy (color psych, animations)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 18) {
                            ForEach(ctx.activeThreads, id: \\.self) { thread in
                                NavigationLink(value: thread) {
                                    ThreadRingView(thread: thread, count: recentEvents.filter { $0.thread == thread }.count, energy: energyLevel(for: thread), recentImpact: energyTrend(for: thread).last ?? 0.5)
                                }
                                .buttonStyle(.plain)
                                .sensoryFeedback(.selection, trigger: hapticTrigger)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Energy trend bars (modern, immediate feedback)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Energy Flow (recent weaves)")
                            .font(.headline.smallCaps())
                            .foregroundStyle(.secondary)
                        HStack(spacing: 4) {
                            ForEach(Array(recentEvents.prefix(6).reversed()), id: \\.id) { event in
                                let impact = event.affectsEnergy ? 0.85 : 0.45
                                let color = impact > 0.7 ? Color.green : (impact > 0.4 ? Color.orange : Color.red)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(color)
                                    .frame(width: 18, height: CGFloat(12 + impact * 28))
                                    .overlay(Text(event.thread.prefix(1)).font(.caption2.bold()).foregroundStyle(.white.opacity(0.8)))
                                    .shadow(color: color.opacity(0.4), radius: 2, y: 1)
                                    .animation(.spring, value: event.id)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Active Ripples (cross-domain, glass)
                    VStack(alignment: .leading) {
                        Text("Active Ripples")
                            .font(.headline.smallCaps())
                        if recentEvents.isEmpty {
                            Text("No ripples yet. Capture something to start the weave.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(recentEvents.prefix(4)) { event in
                                HStack {
                                    Text(event.thread).font(.caption.bold())
                                    Text("→").foregroundStyle(.secondary)
                                    Text(event.linkedThreads.joined(separator: ", "))
                                    Spacer()
                                    Text(event.affectsEnergy ? "⚡" : "")
                                }
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Insight + suggestions (sophisticated, low load)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Insight")
                            .font(.headline.smallCaps())
                        Text(ctx.synthesizedInsight)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        if !crossThreadSuggestions.isEmpty {
                            Text("Suggested Weaves")
                                .font(.subheadline)
                            ForEach(crossThreadSuggestions, id: \\.self) { suggestion in
                                Text("• \(suggestion)")
                                    .font(.caption)
                                    .padding(.vertical, 2)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Quick Capture (wired to state + service)
                    VStack(alignment: .leading) {
                        Text("Quick Capture")
                            .font(.headline.smallCaps())
                        HStack {
                            TextField("What happened? (goal, leak, task, story...)", text: $quickCaptureText)
                                .textFieldStyle(.roundedBorder)
                            Button("Weave") {
                                if !quickCaptureText.isEmpty, let svc = service, let c = context {
                                    let ev = TimelineEvent(thread: "Self", type: "quick_capture", payload: ["text": quickCaptureText], affectsEnergy: true, linkedThreads: ["CareKin", "Stewardship", "Meaning"])
                                    svc.emitEvent(thread: "Self", type: "quick_capture", payload: ["text": quickCaptureText], affectsEnergy: true, linkedThreads: ["CareKin", "Stewardship", "Meaning"])
                                    stateMachine.transition(on: ev, context: c)
                                    quickCaptureText = ""
                                    hapticTrigger.toggle()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Recent Weaves
                    VStack(alignment: .leading) {
                        Text("Recent Weaves")
                            .font(.headline.smallCaps())
                        ForEach(recentEvents.prefix(3)) { event in
                            Text("\(event.thread): \(event.type) @ \(event.timestamp.formatted(.dateTime.hour().minute()))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                } else {
                    // Onboarding/init
                    VStack {
                        Text("Welcome to OneWeave")
                            .font(.title)
                        Text("Tap the ? or start capturing to begin your interconnected journey.")
                        Button("Show Onboarding") { showOnboarding = true }
                            .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
        }
        .navigationDestination(for: String.self) { thread in
            ThreadDetailView(threadName: thread)
        }
        .onAppear {
            service = TimelineService(modelContext: modelContext)
            if contexts.isEmpty {
                let newCtx = LifeContext()
                modelContext.insert(newCtx)
            }
            if showOnboarding == false && contexts.first != nil {
                // Auto-show first time (simplified; production would use @AppStorage)
                showOnboarding = true
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
        }
        .onChange(of: stateMachine.currentState) { _, _ in
            hapticTrigger.toggle()
        }
    }
    
    private func energyLevel(for thread: String) -> Double {
        guard let ctx = context else { return 0.5 }
        let base = ctx.energyProfile == .high ? 0.8 : (ctx.energyProfile == .low ? 0.3 : 0.5)
        let threadEvents = recentEvents.filter { $0.thread == thread }.count
        return min(1.0, base + Double(threadEvents) * 0.05)
    }
    
    private func energyTrend(for thread: String) -> [Double] {
        let relevant = recentEvents.filter { $0.thread == thread || $0.linkedThreads.contains(thread) }.prefix(5)
        return relevant.map { $0.affectsEnergy ? 0.9 : 0.4 }
    }
}

struct ThreadRingView: View {
    let thread: String
    let count: Int
    let energy: Double
    let recentImpact: Double
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(.gray.opacity(0.2), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: energy)
                    .stroke(threadColor(thread), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring, value: energy)
                Text(thread.prefix(1))
                    .font(.title2.bold())
            }
            .frame(width: 90, height: 90)
            Text(thread)
                .font(.caption.bold())
            Text("\(count) events")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    private func threadColor(_ t: String) -> Color {
        switch t { case "Self": return .blue; case "Stewardship": return .green; case "CareKin": return .orange; case "Meaning": return .purple; default: return .gray }
    }
}

struct StateMachineIndicator: View {
    @Environment(AppStateMachine.self) private var stateMachine
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: stateMachine.currentState.systemImage)
                .font(.caption.weight(.medium))
                .foregroundStyle(stateMachine.currentState.color)
                .symbolEffect(.pulse, isActive: stateMachine.currentState == .weaving || stateMachine.currentState == .highFlow)
            Text(stateMachine.currentState.displayName)
                .font(.caption2.weight(.medium))
                .foregroundStyle(stateMachine.currentState.color.opacity(0.9))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(stateMachine.currentState.color.opacity(0.08)))
        .overlay(Capsule().stroke(stateMachine.currentState.color.opacity(0.25), lineWidth: 0.5))
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: stateMachine.currentState)
    }
}

struct WeaveSummaryView: View {
    @Environment(\\.modelContext) private var modelContext
    @Query private var contexts: [LifeContext]
    @Environment(AppStateMachine.self) private var stateMachine
    
    var body: some View {
        if let ctx = contexts.first {
            VStack(alignment: .leading, spacing: 2) {
                Text("Weave: \(stateMachine.currentState.displayName)")
                    .font(.caption2.bold())
                    .foregroundStyle(stateMachine.currentState.color)
                Text("Energy: \(ctx.energyProfile.rawValue)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(6)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}