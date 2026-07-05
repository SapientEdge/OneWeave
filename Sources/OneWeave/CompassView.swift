import SwiftUI
import SwiftData


// Privacy: all gamification (essence, mastery, quests, loom state) is local SwiftData only.
// No network, no external calls, no training. Export/clear works via Settings. Reflection gates anti-addiction.

struct CompassView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var contexts: [LifeContext]
    @Query(sort: \\TimelineEvent.timestamp, order: .reverse) private var allEvents: [TimelineEvent]
    @Query private var allQuests: [WeaveQuest]
    @Environment(AppStateMachine.self) private var stateMachine
    @State private var quickCaptureText = ""
    @State private var service: TimelineService?
    @State private var showRipples = false
    @State private var showInsightDetail = false
    @State private var hapticTrigger = false
    @State private var lastEnergy: Double = 0.5
    @State private var lastRippleCount = 0
    @State private var showOnboarding = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var showOracle = false
    @State private var showBodyThread = false
    
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
                            .accessibilityLabel("Essence \(ctx.weaveEssence), Level \(ctx.weaveLevel), Streak \(ctx.globalWeaveStreak), Harmony \(Int(ctx.harmonyScore*100)) percent")
                            // Life Graph coherence (deeper integration)
                            Text("Coherence \(String(format: "%.0f", ctx.lifeCoherenceScore * 100))%")
                                .font(.caption2.bold())
                                .foregroundStyle(.blue)
                                .padding(4)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Capsule())
                            StateMachineIndicator()
                            WeaveSummaryView()
                            Button {
                                showOnboarding = true
                            } label: {
                                Image(systemName: "questionmark.circle")
                            }
                        }
                    }
                    if let ctx = context {
                        // Phase 4: Living Loom / WeaveTapestry (production Canvas with threads, stitches, pulses, state-driven)
                        // Uses Canvas + Paths for flowing threads, mastery embroidery (stitches), ripple pulses, state-driven (highFlow/lively, lowEnergy/muted) calm animations.
                        // Keeps existing colors/state/harmony/masteryTiers. Performant, subtle per constitution.
                        SimpleLivingLoomView(context: ctx)
                        .accessibilityLabel("Living Loom showing four interconnected threads with mastery and harmony")

                        // Deeper: Life Graph + P2P + External Integrations
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Life Graph & Connections")
                                .font(.headline)
                            
                            HStack {
                                Button("Share via Weave Circle (P2P)") {
                                    if !ctx.lifeGraphEntities.isEmpty {
                                        let selected = Array(ctx.lifeGraphEntities.prefix(3))
                                        ctx.shareViaP2P(selectedEntities: selected, circleName: "Trusted Circle", reflection: "Sharing recent life patterns for reflection")
                                    }
                                }
                                .buttonStyle(.bordered)
                                
                                Button("Import from iOS (Calendar/Contacts/Health)") {
                                    LifeGraphiOSIntegrations.shared.importAll(context: ctx) { source, entities in
                                        print("Imported from \(source): \(entities.count) entities")
                                    }
                                }
                                .buttonStyle(.bordered)
                            }
                            
                            if !ctx.lifeGraphEntities.isEmpty {
                                Text("\(ctx.lifeGraphEntities.count) entities in graph • \(ctx.lifeGraphRelationships.count) relationships")
                                    .font(.caption2)
                            }

                            // Resonance Oracle: local decision simulator (creative novel feature).
                            Button {
                                showOracle = true
                            } label: {
                                Label("Resonance Oracle (simulate a decision)", systemImage: "sparkles")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .tint(.purple)

                            // Body-Thread Weaver: gentle health-aware nudge.
                            Button {
                                showBodyThread = true
                            } label: {
                                Label("Body Thread (refresh from Health)", systemImage: "heart.text.square")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .tint(.pink)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .sheet(isPresented: $showOracle) {
                            ResonanceOracleSheet(context: ctx)
                        }
                        .sheet(isPresented: $showBodyThread) {
                            BodyThreadSheet(context: ctx)
                        }


            // Phase 5/6: Mastery Map entry (tap to view tiers/perks)
            NavigationLink(value: "MasteryMap") {
                HStack {
                    Text("Mastery Map")
                        .font(.caption.bold())
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }

                    }
                    Text("Journey Compass")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                
                
                    // Production Quests UI - full suggested list + reflection gate (prominent, always visible)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Suggested Weaves").font(.headline)
                        ForEach(suggestedQuests.prefix(4)) { q in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(q.title).font(.subheadline)
                                    Text(q.domains.joined(separator: ", ")).font(.caption2).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("Accept") {
                                    selectedQuest = q
                                    showQuestReflection = true
                                }
                                .buttonStyle(.bordered)
                                .accessibilityLabel("Accept quest: \(q.title)")
                            }
                            .padding(6)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        if suggestedQuests.isEmpty {
                            Text("Quests generated from your threads and state. Tap to weave.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)

                    
            // Production Quests - prominent full list + reflection gate
            VStack(alignment: .leading, spacing: 6) {
                Text("Suggested Weaves (tap to accept)").font(.headline)
                ForEach(allQuests.prefix(5)) { q in
                    Button {
                        selectedQuest = q
                        showQuestReflection = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(q.title).font(.subheadline)
                                Text((q.domains + ["+\(q.baseEssence)✧"]).joined(separator: " · ")).font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("Accept").font(.caption).foregroundStyle(.blue)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
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

                            // Season indicator (production production, calm UI)
                            HStack {
                                Text("Season: \(ctx.values["season"] ?? ctx.currentSeason)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button("Change Season") {
                                    ctx.changeSeason(to: "Autumn")
                                    weaveFeedback = "Season shifted. Reflection gate open."
                                    showWeaveFeedback = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showWeaveFeedback = false }
                                }
                                .font(.caption)
                                .buttonStyle(.bordered)
                            }
                            .padding(.horizontal)

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
                    
                    // Navigation to lightweight views (Phase 6 polish)
                    HStack(spacing: 12) {
                        NavigationLink(value: "QuestsView") {
                            Label("Quests", systemImage: "list.bullet.rectangle")
                                .font(.caption)
                        }
                        NavigationLink(value: "EssenceLedgerView") {
                            Label("Ledger", systemImage: "list.bullet")
                                .font(.caption)
                        }
                        NavigationLink(value: "MasteryMapView") {
                            Label("Mastery", systemImage: "map")
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal)
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
        
        .navigationDestination(for: String.self) { value in
            switch value {
            case "QuestsView":
                QuestsView()
            case "EssenceLedgerView":
                EssenceLedgerView()
            case "MasteryMapView":
                MasteryMapView()
            default:
                ThreadDetailView(threadName: value)
            }
        }
.onAppear {

            // Bootstrap snapshot for widgets on appear
            if let c = contexts.first {
                let qs = (try? modelContext.fetch(FetchDescriptor<WeaveQuest>())) ?? []
                c.pushSnapshotToWidgets(from: qs)
            }

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
            // Onboarding auto-show: show on first launch only (Round-3 finding NEMO-R3-020 + NEMO-R3-042).
            // The original logic `showOnboarding == false && contexts.first != nil` re-triggered
            // onboarding forever after dismiss. Now uses @AppStorage for persistence.
            if !hasCompletedOnboarding && contexts.first != nil && !showOnboarding {
                showOnboarding = true
            }
            // Populate suggested quests (after context ready)
            if let c = contexts.first ?? (try? modelContext.fetch(FetchDescriptor<LifeContext>())).first {
                suggestedQuests = questService?.generateSuggestedQuests(from: c, recentEvents: recentEvents) ?? []
            }
        }
        .sheet(isPresented: $showOnboarding) {
            // A4 (Claude round-5 audit): prevent swipe-to-dismiss so users can't
            // accidentally re-show the onboarding on every launch. The user MUST
            // tap "Start Weaving" to set hasCompletedOnboarding = true (and that
            // dismisses via dismiss()). Constitution: orientation flow.
            OnboardingView()
                .interactiveDismissDisabled(true)
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
    @Environment(\.modelContext) private var modelContext
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
// Basic gamification visual components for Compass (level badge + streak + essence HUD)
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

            // Streak visual (Phase 5 stitched hint)
            if context.globalWeaveStreak > 0 {
                HStack(spacing: 1) {
                    ForEach(0..<min(context.globalWeaveStreak, 7), id: \.self) { _ in
                        Text("•").font(.caption2).foregroundStyle(.orange)
                    }
                    if context.globalWeaveStreak > 7 { Text("+\(context.globalWeaveStreak-7)").font(.caption2) }
                }
            }

            HStack(spacing: 2) {
                Text("🔥\(context.globalWeaveStreak)")
                    .font(.caption2.bold())
                    .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, 4)
        .background(Capsule().fill(Color.orange.opacity(0.15)))
        .clipShape(Capsule())
    }
}

// Phase 4: Enhanced SimpleLivingLoomView (core of WeaveTapestryView)
// Canvas + Paths for:
// - flowing organic threads (wavy horizontal tapestry lines, phase animated)
// - mastery embroidery (perpendicular stitches, density + length by tier 1-4)
// - ripple pulses (calm concentric rings on active/high-harmony, stronger in weaving/highFlow)
// - state-driven: wave amp + opacity + pulse intensity modulated by AppState (highFlow lively, lowEnergy muted/slower feel via factors)
// - harmony connections (subtle cross-links)
// Uses existing LifeContext (masteryTiers, harmonyScore, activeThreads), colorForDomain, stateMachine.
// Calm, performant (light paths, no heavy particles), glass material, subtle .linear / easeInOut anims.
struct SimpleLivingLoomView: View {
    let context: LifeContext
    @Environment(AppStateMachine.self) private var stateMachine

    @State private var weavePhase: Double = 0
    @State private var pulsePhase: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Living Loom")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                
                Button {
                    // Present MasteryMapView (for now, demo note; wire NavigationDestination in full app)
                    print("MasteryMap tapped - would present full map with tiers/perks")
                } label: {
                    Image(systemName: "map")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                if context.harmonyScore > 0.55 {
                    Text("Resonance • \(Int(context.harmonyScore * 100))%")
                        .font(.caption2)
                        .foregroundStyle(.green.opacity(0.75))
                }
                // calm state annotation (ViewBuilder safe)
                if stateMachine.currentState == .highFlow {
                    Text("✧ flow").font(.caption2).foregroundStyle(.green.opacity(0.6))
                } else if stateMachine.currentState == .lowEnergy {
                    Text("gentle").font(.caption2).foregroundStyle(.secondary.opacity(0.6))
                } else if stateMachine.currentState == .weaving {
                    Text("rippling").font(.caption2).foregroundStyle(.secondary.opacity(0.6))
                }
            }

            Canvas(rendersAsynchronously: true) { gc, size in
                let domains = ["Self", "Stewardship", "CareKin", "Meaning"]
                let cols: [Color] = [.blue, .green, .orange, .purple]
                let w = size.width
                let h = size.height

                let isHighFlow = stateMachine.currentState == .highFlow
                let isLowEnergy = stateMachine.currentState == .lowEnergy
                let flowFactor = isHighFlow ? 1.35 : (isLowEnergy ? 0.45 : 1.0)
                let waveAmp = 4.5 * flowFactor
                let baseAlpha = isLowEnergy ? 0.5 : 0.82

                // 4 flowing thread paths (tapestry-style, horizontal organic waves)
                for (i, domain) in domains.enumerated() {
                    let tier = context.masteryTiers[domain] ?? 1
                    let isActive = context.activeThreads.contains(domain)
                    let col = cols[i]
                    let baseY = 13.0 + Double(i) * (h / 4.15)
                    let phaseOffset = Double(i) * 0.75
                    let currentPhase = weavePhase + phaseOffset

                    let y1 = baseY + sin(currentPhase) * (waveAmp * 0.35)
                    let y2 = baseY + sin(currentPhase + 1.1) * (waveAmp * 0.55)

                    var threadPath = Path()
                    threadPath.move(to: CGPoint(x: 6, y: y1))
                    let ctrlX = w * 0.48
                    threadPath.addQuadCurve(
                        to: CGPoint(x: w - 6, y: y2),
                        control: CGPoint(x: ctrlX, y: baseY + sin(currentPhase + 0.55) * waveAmp * 0.9)
                    )

                    let threadWidth = 1.8 + Double(tier - 1) * 1.0 * (isActive ? 1.05 : 0.65)
                    let alpha = baseAlpha * (isActive ? 0.92 : 0.42) * min(1.0, context.harmonyScore + 0.35)
                    gc.stroke(
                        threadPath,
                        with: .color(col.opacity(alpha)),
                        lineWidth: threadWidth
                    )

                    // Mastery embroidery stitches (perpendicular dashes, more/denser for higher tier)
                    if tier >= 2 {
                        let numStitches = min(5, 2 + tier)
                        for s in 0..<numStitches {
                            let t = Double(s + 1) / Double(numStitches + 1)
                            let px = 6 + t * (w - 12)
                            // approximate position on curve (linear interp sufficient for calm visual)
                            let py = y1 + t * (y2 - y1) + sin(currentPhase + Double(s) * 0.4) * 1.5
                            let stitchLen = 2.8 + Double(tier) * 0.6
                            let tilt = cos(currentPhase * 1.2 + Double(s)) * 0.8
                            let dx = 1.2 * tilt
                            let dy = stitchLen * 0.5

                            var stitch = Path()
                            stitch.move(to: CGPoint(x: px - dx, y: py - dy))
                            stitch.addLine(to: CGPoint(x: px + dx, y: py + dy))
                            gc.stroke(
                                stitch,
                                with: .color(col.opacity(0.6 * (isActive ? 1.0 : 0.55))),
                                lineWidth: 1.1
                            )
                        }
                    }

                    // Knot / node at left of each thread (sized + styled by mastery + active)
                    let knotR = 5.5 + Double(tier) * 1.6
                    let knotX = 6.0 + knotR * 0.25
                    let knotY = y1
                    let knotRect = CGRect(x: knotX - knotR, y: knotY - knotR, width: knotR * 2, height: knotR * 2)
                    gc.fill(Path(ellipseIn: knotRect), with: .color(col.opacity(isActive ? 0.88 : 0.32)))
                    gc.stroke(
                        Path(ellipseIn: knotRect),
                        with: .color(col),
                        lineWidth: isActive ? 1.4 : 0.7
                    )
                    // Domain initial inside knot
                    let letter = String(domain.prefix(1))
                    gc.draw(
                        Text(letter)
                            .font(.system(size: 6.5, weight: .semibold))
                            .foregroundStyle(isActive ? .white : col),
                        at: CGPoint(x: knotX, y: knotY)
                    )
                }

                // Harmony resonance: subtle flowing cross-links (calm vertical-ish ties)
                if context.harmonyScore > 0.55 {
                    let linkAlpha = (context.harmonyScore - 0.5) * 0.55
                    for i in 0..<3 {
                        var link = Path()
                        let ya = 13.0 + Double(i) * (h / 4.15)
                        let yb = 13.0 + Double(i + 1) * (h / 4.15)
                        let xL = w * (0.28 + Double(i % 2) * 0.18)
                        let wy = sin(weavePhase * 0.8 + Double(i)) * 1.5
                        link.move(to: CGPoint(x: xL, y: ya + wy))
                        link.addLine(to: CGPoint(x: xL + 10, y: yb - wy * 0.6))
                        gc.stroke(
                            link,
                            with: .color(.gray.opacity(linkAlpha * 0.45)),
                            lineWidth: 0.7
                        )
                    }
                }

                // State-driven ripple pulses (outward rings on knots for active or high harmony)
                let shouldPulse = stateMachine.currentState == .weaving || stateMachine.currentState == .highFlow || context.harmonyScore > 0.62
                if shouldPulse {
                    for (i, domain) in domains.enumerated() {
                        if context.activeThreads.contains(domain) || context.harmonyScore > 0.58 {
                            let tier = context.masteryTiers[domain] ?? 1
                            let col = cols[i]
                            let baseY = 13.0 + Double(i) * (h / 4.15)
                            let knotR = 5.5 + Double(tier) * 1.6
                            let knotX = 6.0 + knotR * 0.25

                            for p in 0..<2 {
                                let pProg = (pulsePhase + Double(p) * 0.25).truncatingRemainder(dividingBy: 1.0)
                                let pScale = 1.0 + pProg * (isHighFlow ? 2.1 : 1.6)
                                let pr = knotR * pScale
                                let pAlpha = max(0.04, (1.15 - pProg) * 0.22 * (isHighFlow ? 1.25 : (isLowEnergy ? 0.6 : 1.0)))
                                let pRect = CGRect(x: knotX - pr, y: baseY - pr, width: pr * 2, height: pr * 2)
                                gc.stroke(
                                    Path(ellipseIn: pRect),
                                    with: .color(col.opacity(pAlpha)),
                                    lineWidth: 0.9
                                )
                            }
                        }
                    }
                }
            }
            .frame(height: 88)
            .background(Color.gray.opacity(0.025))
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(Color.gray.opacity(0.08), lineWidth: 0.5)
            )
            .drawingGroup()  // perf for repeated redraws on anim

        }
        .padding(6)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 9))
        