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
    
    // Gamification UI state for tasty feedback
    @State private var weaveFeedback: String = ""
    @State private var showWeaveFeedback: Bool = false
    @State private var lastAwardedEssence: Double = 0

    // Quests + reflection gate (per spec: reflection required for full award)
    @State private var suggestedQuests: [WeaveQuest] = []
    @State private var showQuestReflection = false
    @State private var selectedQuest: WeaveQuest? = nil
    @State private var reflectionText = ""
    @State private var questService: QuestService? = QuestService.shared
    
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
                            // Basic gamification visual progress (level badge + streak + essence)
                            GamificationHUD(context: ctx)

SimpleLivingLoomView(context: ctx)


            // Mastery tiers display (Phase 5)
            HStack(spacing: 4) {
                ForEach(["Self", "Stewardship", "CareKin", "Meaning"], id: \.self) { d in
                    if let tier = context.masteryTiers[d] {
                        Text("\(d.prefix(1)):\(tier)")
                            .font(.caption2)
                            .padding(2)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }

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
                    
                    // Gamification visual progress: streak, level, essence (tied to LifeContext + events)
                    if let ctx = context {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Weave Progress")
                                .font(.headline.smallCaps())
                                .foregroundStyle(.secondary)
                            HStack(spacing: 12) {
                                // Level badge
                                VStack {
                                    Text("L\(ctx.weaveLevel)")
                                        .font(.headline.bold())
                                        .foregroundStyle(.indigo)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Color.indigo.opacity(0.15)))
                                    Text("Level")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                // Essence
                                VStack(alignment: .leading) {
                                    Text(ctx.essenceDisplay)
                                        .font(.title3.bold())
                                        .foregroundStyle(.purple)
                                    ProgressView(value: ctx.levelProgress)
                                        .tint(.purple)
                                        .frame(width: 80)
                                    Text("to L\(ctx.weaveLevel + 1)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                // Streak counter
                                VStack {
                                    HStack(spacing: 2) {
                                        Text("🔥")
                                        Text("\(ctx.globalWeaveStreak)")
                                            .font(.headline.bold())
                                            .foregroundStyle(.orange)
                                    }
                                    Text("streak")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                // Harmony
                                VStack {
                                    Text(String(format: "%.0f%%", ctx.harmonyScore * 100))
                                        .font(.headline.bold())
                                        .foregroundStyle(.green)
                                    Text("harmony")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .padding(.horizontal)
                    }
                    
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
                                    let beforeEssence = c.weaveEssence
                                    let ev = TimelineEvent(thread: "Self", type: "quick_capture", payload: ["text": quickCaptureText], affectsEnergy: true, linkedThreads: ["CareKin", "Stewardship", "Meaning"])
                                    svc.emitEvent(thread: "Self", type: "quick_capture", payload: ["text": quickCaptureText], affectsEnergy: true, linkedThreads: ["CareKin", "Stewardship", "Meaning"])
                                    stateMachine.transition(on: ev, context: c)
                                    let awarded = max(2.0, c.weaveEssence - beforeEssence)
                                    quickCaptureText = ""
                                    hapticTrigger.toggle()
                                    // Refresh quests after weave (context-aware per 002 spec)
                                    if let qs = questService {
                                        suggestedQuests = qs.generateSuggestedQuests(from: c, recentEvents: recentEvents)
                                    }
                                    // Tasty feedback on weaves
                                    let fb = "✧ +\(Int(awarded)) Essence • L\(c.weaveLevel) • 🔥\(c.globalWeaveStreak) • \(c.harmonyScore > 0.7 ? "High Harmony!" : "Ripple sent!")"
                                    weaveFeedback = fb
                                    showWeaveFeedback = true
                                    lastAwardedEssence = awarded
                                    // Auto-hide tasty toast
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                        showWeaveFeedback = false
                                    }
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        
                        // Tasty feedback on weave (calm, celebratory, fades)
                        if showWeaveFeedback && !weaveFeedback.isEmpty {
                            Text(weaveFeedback)
                                .font(.caption.bold())
                                .foregroundStyle(.purple)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                                .transition(.scale.combined(with: .opacity))
                                .animation(.spring, value: showWeaveFeedback)
                        }
                    }
                    .padding(.horizontal)

                    // Quests section + reflection gate (insert after quick capture per task)
                    // Suggested quests from QuestService; reflection required for full essence award
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Suggested Quests")
                            .font(.headline.smallCaps())
                            .foregroundStyle(.secondary)
                        
                        if suggestedQuests.isEmpty {
                            Text("No quests yet. Capture more to generate context-aware quests.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(suggestedQuests, id: \.id) { quest in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(quest.title)
                                            .font(.subheadline.bold())
                                        Spacer()
                                        Text(quest.displayEssence)
                                            .font(.caption.bold())
                                            .foregroundStyle(.purple)
                                    }
                                    Text(quest.questDescription)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    HStack {
                                        Text("~\(quest.estimatedIRLMinutes) min IRL")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        if !quest.validationHints.isEmpty {
                                            Text("• \(quest.validationHints.prefix(40))")
                                                .font(.caption2)
                                                .foregroundStyle(.orange)
                                        }
                                        Spacer()
                                        Button {
                                            selectedQuest = quest
                                            reflectionText = ""
                                            showQuestReflection = true
                                            hapticTrigger.toggle()
                                        } label: {
                                            Text("Complete & Reflect")
                                                .font(.caption.bold())
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.indigo)
                                        .sensoryFeedback(.selection, trigger: hapticTrigger)
                                    }
                                }
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
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
            questService = QuestService.shared
            if contexts.isEmpty {
                let newCtx = LifeContext()
                // initial gamif seed for first run
                newCtx.weaveEssence = 5
                newCtx.weaveLevel = 1
                newCtx.globalWeaveStreak = 1
                modelContext.insert(newCtx)
            }
            if showOnboarding == false && contexts.first != nil {
                // Auto-show first time (simplified; production would use @AppStorage)
                showOnboarding = true
            }
            // Populate suggested quests (after context ready)
            if let c = contexts.first ?? (try? modelContext.fetch(FetchDescriptor<LifeContext>())).first {
                suggestedQuests = questService?.generateSuggestedQuests(from: c, recentEvents: recentEvents) ?? []
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
        }
        .sheet(isPresented: $showQuestReflection) {
            VStack(spacing: 16) {
                if let quest = selectedQuest, let ctx = context {
                    Text("Quest Reflection Gate")
                        .font(.headline)
                    Text(quest.title)
                        .font(.title3.bold())
                        .multilineTextAlignment(.center)
                    Text(quest.questDescription)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Divider()
                    
                    Text("Your reflection (required for full award)")
                        .font(.subheadline.bold())
                    TextEditor(text: $reflectionText)
                        .frame(height: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                    Text("✧ Reflection unlocks full essence. Be specific about IRL action & insight.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 12) {
                        Button("Cancel") {
                            showQuestReflection = false
                            reflectionText = ""
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Submit for Full Award") {
                            let trimmed = reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty, let qs = questService {
                                let beforeEssence = ctx.weaveEssence
                                qs.completeWithReflection(questId: quest.id, reflection: trimmed, context: ctx, modelContext: modelContext)
                                let awarded = max(10.0, ctx.weaveEssence - beforeEssence)
                                // Tie to existing tasty feedback + haptic
                                let fb = "✧ Quest +\(Int(awarded)) Essence (reflected) • L\(ctx.weaveLevel) • 🔥\(ctx.globalWeaveStreak) • Ripple complete"
                                weaveFeedback = fb
                                showWeaveFeedback = true
                                lastAwardedEssence = awarded
                                hapticTrigger.toggle()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                    showWeaveFeedback = false
                                }
                                // Refresh quests after completion
                                if let c = contexts.first {
                                    suggestedQuests = qs.generateSuggestedQuests(from: c, recentEvents: recentEvents)
                                }
                                showQuestReflection = false
                                reflectionText = ""
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.top)
                } else {
                    Text("Select a quest to reflect on.")
                        .foregroundStyle(.secondary)
                    Button("Close") { showQuestReflection = false }
                        .buttonStyle(.bordered)
                }
            }
            .padding()
            .presentationDetents([.medium, .large])
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

// Basic gamification visual components for Compass (level badge, streak, essence HUD)
struct GamificationHUD: View {
    let context: LifeContext
    
    var body: some View {
        HStack(spacing: 6) {
            // Level badge - tasty, compact
            Text("L\(context.weaveLevel)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing))
                )
            
            // Essence
            Text(context.essenceDisplay)
                .font(.caption2.bold())
                .foregroundStyle(.purple.opacity(0.9))
            
            // Streak pill
            HStack(spacing: 2) {
                Text("🔥\(context.globalWeaveStreak)")
                    .font(.caption2.bold())
                    .foregroundStyle(.orange)
            }


// Simple Living Loom visual (Phase 4 starter per 002-tasks: 4 threads as connected shapes, mastery hints via thickness/color, state influence)

// Simple Living Loom visual (Phase 4/5 starter per 002-tasks: 4 threads as connected shapes, mastery levels via size/thickness, resonance lines, state influence)
struct SimpleLivingLoomView: View {
    let context: LifeContext
    @Environment(AppStateMachine.self) private var stateMachine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Living Loom")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            // Thread nodes with mastery sizing
            HStack(spacing: 16) {
                ForEach(["Self", "Stewardship", "CareKin", "Meaning"], id: \.self) { domain in
                    let isActive = context.activeThreads.contains(domain)
                    let tier = context.masteryTiers[domain] ?? 1
                    let color = colorForDomain(domain)
                    ZStack {
                        Circle()
                            .fill(color.opacity(isActive ? 0.85 : 0.25))
                            .frame(width: 22 + CGFloat(tier * 5), height: 22 + CGFloat(tier * 5))
                        Circle()
                            .stroke(color, lineWidth: isActive ? CGFloat(1 + tier/2) : 1)
                            .frame(width: 22 + CGFloat(tier * 5), height: 22 + CGFloat(tier * 5))
                        Text(String(domain.prefix(1)))
                            .font(.caption2.bold())
                            .foregroundStyle(isActive ? .white : color)
                    }
                    .shadow(color: stateMachine.currentState == .highFlow ? color.opacity(0.5) : .clear, radius: 3 + Double(tier))
                }
            }
            // Simple resonance connections (lines hint)
            if context.harmonyScore > 0.6 {
                Text("Resonance active • \(Int(context.harmonyScore * 100))% harmony")
                    .font(.caption2)
                    .foregroundStyle(.green.opacity(0.8))
            }
            Text("Mastery tiers: Lvl 1-4 per thread (cumulative from ripples/quests)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private func colorForDomain(_ domain: String) -> Color {
        switch domain {
        case "Self": return .blue
        case "Stewardship": return .green
        case "CareKin": return .orange
        case "Meaning": return .purple
        default: return .gray
        }
    }
}


            .padding(.horizontal, 4)
            .background(Capsule().fill(Color.orange.opacity(0.15)))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

// Extend ThreadRingView lightly for mastery (called from existing; visual tier hint)
extension ThreadRingView {
    // For future: could accept mastery tier, here we just hint in color for now (prototype keeps simple)
}
