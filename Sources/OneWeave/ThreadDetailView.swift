import SwiftUI
import SwiftData

// Polished Phase 6: Full gamif surface in ThreadDetailView
// - Mastery details: tier, visual progress, description, calm perks stub
// - Active quests list (thread-filtered, from persisted + LifeContext active IDs)
// - Suggested weaves/quests (context + thread aware, accept wires to active + emit ripple)
// - Recent ripples (enhanced with links, gamif hints, echo action stub)
// Calm design: subtle cards, glass, progressive disclosure, IRL emphasis, no flashy. Local-only.
// Cross-wired to LifeContext, QuestService, TimelineService, emits for ripples.

struct ThreadDetailView: View {
    let threadName: String
    @Environment(\\.modelContext) private var modelContext
    @Query private var contexts: [LifeContext]
    @Query(sort: \TimelineEvent.timestamp, order: .reverse) private var allEvents: [TimelineEvent]
    @Query private var allQuests: [WeaveQuest]
    
    @State private var inputText = ""
    @State private var service: TimelineService?
    @State private var showExport = false
    @State private var exportData = ""
    @State private var showReflection = false
    @State private var selectedQuest: WeaveQuest?
    @State private var reflectionText = ""
    @State private var feedback = ""
    @State private var showSuggested = false
    
    private var context: LifeContext? { contexts.first }
    
    private var threadEvents: [TimelineEvent] {
        allEvents.filter { $0.thread == threadName || $0.linkedThreads.contains(threadName) }
    }
    
    private var threadMastery: Int {
        context?.masteryTiers[threadName] ?? 1
    }
    
    private var activeThreadQuests: [WeaveQuest] {
        guard let ctx = context else { return [] }
        // Support both persisted WeaveQuest and active UUIDs (handles demo/partial persistence)
        let byId = allQuests.filter { ctx.activeQuests.contains($0.id) && $0.domains.contains(threadName) }
        if !byId.isEmpty { return byId }
        // Fallback: recent quests in events for this thread (demo resilience)
        return allQuests.filter { $0.domains.contains(threadName) && $0.status != .completed }.prefix(3).map { $0 }
    }
    
    private var recentRipples: [TimelineEvent] {
        threadEvents.prefix(8).map { $0 }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with mastery badge
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(threadName)
                                .font(.largeTitle.bold())
                            if let ctx = context {
                                Text("Energy: (ctx.energyProfile.rawValue.capitalized) • Harmony (Int(ctx.harmonyScore * 100))%")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        MasteryBadge(tier: threadMastery, thread: threadName)
                    }
                    .padding(.bottom, 8)
                    
                    if let ctx = context {
                        // === FULL GAMIF: Mastery Details ===
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Mastery Details")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            HStack {
                                Text("Tier (threadMastery): (tierName(for: threadMastery))")
                                    .font(.title3.bold())
                                Spacer()
                                Text("L(threadMastery)/4")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(tierColor(for: threadMastery).opacity(0.15))
                                    .clipShape(Capsule())
                            }
                            
                            // Calm progress bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.gray.opacity(0.15))
                                        .frame(height: 8)
                                    Capsule()
                                        .fill(tierColor(for: threadMastery))
                                        .frame(width: geo.size.width * (Double(threadMastery) / 4.0), height: 8)
                                }
                            }
                            .frame(height: 8)
                            
                            Text(tierDescription(for: threadMastery))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Text("Perk: (perkFor(thread: threadName, tier: threadMastery))")
                                .font(.caption)
                                .foregroundStyle(.blue)
                                .padding(.top, 2)
                            
                            Text("Mastery grows from real ripples, validated quests, and cross-thread harmony. Calm, earned.")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // === Active Quests List for this thread ===
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Active Weaves (Quests) for (threadName)")
                                    .font(.headline)
                                Spacer()
                                if !activeThreadQuests.isEmpty {
                                    Text("(activeThreadQuests.count) active")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            if activeThreadQuests.isEmpty {
                                Text("No active quests tied to this thread yet. Accept a suggestion below or from Compass to start a weave.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.vertical, 4)
                            } else {
                                ForEach(activeThreadQuests) { quest in
                                    QuestCard(quest: quest, thread: threadName) {
                                        selectedQuest = quest
                                        reflectionText = ""
                                        showReflection = true
                                    }
                                }
                            }
                        }
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // === Suggested Weaves (per-thread + context aware) ===
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Suggested Weaves for (threadName)")
                                    .font(.headline)
                                Spacer()
                                Button("Refresh") {
                                    showSuggested.toggle() // triggers recompute
                                }
                                .font(.caption)
                            }
                            
                            let suggested = generateThreadSuggestions(context: ctx)
                            if suggested.isEmpty {
                                Text("No tailored suggestions right now. Try a quick action or check global in Compass.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(suggested.prefix(3), id: \\.id) { quest in
                                    SuggestedQuestRow(quest: quest) {
                                        acceptQuestSuggestion(quest, in: ctx)
                                    }
                                }
                            }
                            Text("Suggestions use your recent ripples, energy, and mastery gaps. IRL-first.")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .padding(.top, 4)
                        }
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Quick Action (preserved + enhanced for gamif)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quick Action for (threadName)")
                            .font(.headline)
                        
                        TextField("Describe weave/ripple (e.g. habit, leak fix, story, task)...", text: $inputText)
                            .textFieldStyle(.roundedBorder)
                        
                        Button("Process & Weave Ripple") {
                            processAction()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(inputText.isEmpty)
                        
                        if !feedback.isEmpty {
                            Text(feedback)
                                .font(.caption)
                                .foregroundStyle(.green)
                                .padding(6)
                                .background(Color.green.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // === Recent Ripples for the thread (full gamif surface) ===
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Ripples for (threadName)")
                            .font(.headline)
                        
                        if recentRipples.isEmpty {
                            Text("No activity yet. Use actions above, Compass quick capture, or accept a weave suggestion.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(recentRipples) { event in
                                RippleRow(event: event, thread: threadName) {
                                    // Echo action: simulate + award small + ripple to Meaning
                                    echoRipple(event)
                                }
                            }
                        }
                        
                        if let ctx = context {
                            Text("Global Streak: 🔥(ctx.globalWeaveStreak) (grace protected) • Essence: (ctx.essenceDisplay)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Cross suggestions (enhanced)
                    if let ctx = context {
                        let cross = generateCrossSuggestions(for: threadName, context: ctx)
                        if !cross.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Cross-Thread Suggestions")
                                    .font(.headline)
                                ForEach(cross, id: \\.self) { sug in
                                    Text("• (sug)")
                                        .font(.caption)
                                }
                            }
                            .padding(8)
                        }
                    }
                    
                    // Footer note (calm, anti-addictive)
                    Text("All data local-only. Ripples are purposeful. Close app & act in real life after weaves.")
                        .font(.caption2.italic())
                        .foregroundStyle(.tertiary)
                        .padding(.top)
                }
                .padding()
            }
            .navigationTitle(threadName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Export") {
                    exportThreadData()
                }
            }
            .sheet(isPresented: $showExport) {
                ScrollView {
                    Text(exportData)
                        .font(.caption)
                        .padding()
                }
                .onTapGesture { showExport = false }
            }
            .sheet(isPresented: $showReflection) {
                if let quest = selectedQuest, let ctx = context {
                    VStack(spacing: 16) {
                        Text("Reflection Gate — Full Award")
                            .font(.headline)
                        Text(quest.title)
                            .font(.title3.bold())
                            .multilineTextAlignment(.center)
                        
                        Text(quest.questDescription)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text("✧ (quest.estimatedIRLMinutes) min IRL • Hint: (quest.validationHints)")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        
                        TextEditor(text: $reflectionText)
                            .frame(height: 100)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.3)))
                        
                        Text("Reflection required for full essence + mastery tick. Be specific about the IRL action and insight.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            Button("Cancel") {
                                showReflection = false
                                reflectionText = ""
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Submit Reflection & Complete") {
                                submitReflection(for: quest, ctx: ctx)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            service = TimelineService(modelContext: modelContext)
            if contexts.isEmpty {
                let newCtx = LifeContext()
                modelContext.insert(newCtx)
            }
        }
        .onChange(of: feedback) { _, _ in
            if !feedback.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    feedback = ""
                }
            }
        }
    }
    
    // MARK: - Helpers & Gamif Logic (local, calm)
    
    private func tierName(for tier: Int) -> String {
        switch tier {
        case 4: return "Luminary"
        case 3: return "Guardian"
        case 2: return "Weaver"
        default: return "Novice"
        }
    }
    
    private func tierDescription(for tier: Int) -> String {
        switch tier {
        case 4: return "Legacy weaver. Your ripples inspire across threads."
        case 3: return "Deep consistent practice. Strong cross-domain resonance."
        case 2: return "Building reliable weave. Good harmony emerging."
        default: return "Starting the journey. Every ripple counts."
        }
    }
    
    private func tierColor(for tier: Int) -> Color {
        switch tier {
        case 4: return .purple
        case 3: return .indigo
        case 2: return .blue
        default: return .gray
        }
    }
    
    private func perkFor(thread: String, tier: Int) -> String {
        let base = tier >= 2 ? "Improved suggestions" : "Basic tracking"
        if tier >= 3 {
            return "(base) + restorative grace bonus in (thread)"
        } else if tier >= 2 {
            return "(base) for (thread) weaves"
        }
        return base
    }
    
    private func generateThreadSuggestions(context ctx: LifeContext) -> [WeaveQuest] {
        let allSug = QuestService.shared.generateSuggestedQuests(from: ctx, recentEvents: Array(allEvents.prefix(10)))
        // Prioritize this thread's domains, plus 1 cross
        let threadMatched = allSug.filter { $0.domains.contains(threadName) }
        let cross = allSug.filter { !$0.domains.contains(threadName) && $0.domains.count > 1 }.prefix(1)
        return Array((threadMatched + cross).prefix(4))
    }
    
    private func acceptQuestSuggestion(_ quest: WeaveQuest, in ctx: LifeContext) {
        // Persist quest + activate for full wiring (Phase 6)
        if !allQuests.contains(where: { $0.id == quest.id }) {
            modelContext.insert(quest)
        }
        if !ctx.activeQuests.contains(quest.id) {
            ctx.activeQuests.append(quest.id)
        }
        // Emit acceptance ripple
        service?.emitEvent(
            thread: threadName,
            type: "quest_accepted",
            payload: ["quest": quest.title, "domains": quest.domains.joined(separator: ",")],
            affectsEnergy: threadName == "Self" || threadName == "CareKin",
            linkedThreads: quest.domains.filter { $0 != threadName }
        )
        feedback = "Weave accepted: (quest.title). Close app & do IRL (~(quest.estimatedIRLMinutes)min). Then reflect here."
        // Refresh context
        ctx.updateFromEvent(TimelineEvent(thread: threadName, type: "quest_accepted", payload: ["title": quest.title]))
    }
    
    private func submitReflection(for quest: WeaveQuest, ctx: LifeContext) {
        let trimmed = reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let qs = QuestService.shared
        qs.completeWithReflection(questId: quest.id, reflection: trimmed, context: ctx, modelContext: modelContext)
        
        // Ensure quest marked reflected (local)
        quest.reflectionNote = trimmed
        quest.completedAt = Date()
        quest.status = .reflected
        
        // Thread-specific ripple event for mastery/streak in this domain
        let rippleEvent = TimelineEvent(
            thread: threadName,
            type: "quest_reflected",
            payload: ["quest": quest.title, "reflection": String(trimmed.prefix(60))],
            affectsEnergy: true,
            linkedThreads: quest.domains.filter { $0 != threadName }
        )
        service?.emitEvent(
            thread: threadName,
            type: "quest_reflected",
            payload: ["quest": quest.title, "reflection": String(trimmed.prefix(60))],
            affectsEnergy: true,
            linkedThreads: quest.domains.filter { $0 != threadName }
        )
        ctx.updateFromEvent(rippleEvent)
        
        feedback = "✧ Reflection complete! +Essence • Mastery tick in (threadName) • Ripple sent."
        showReflection = false
        reflectionText = ""
        selectedQuest = nil
    }
    
    private func echoRipple(_ event: TimelineEvent) {
        guard let ctx = context, let svc = service else { return }
        // Calm echo: small essence + Meaning ripple + possible mastery
        svc.emitEvent(
            thread: "Meaning",
            type: "echo_ripple",
            payload: ["echoedFrom": threadName, "original": event.type],
            affectsEnergy: false,
            linkedThreads: [threadName]
        )
        ctx.awardBonusEssence(2, reason: "echo from (threadName)")
        if var tier = ctx.masteryTiers["Meaning"] {
            if Int.random(in: 0..<3) == 0 { 
                ctx.masteryTiers["Meaning"] = min(4, tier + 1)
            }
        }
        feedback = "Echoed ripple from (threadName) → Meaning +2 Essence. Insight ripple created."
    }
    
    private func processAction() {
        guard !inputText.isEmpty, let svc = service, let ctx = context else { return }
        
        let lower = inputText.lowercased()
        var linked: [String] = []
        
        if threadName == "CareKin" {
            // (existing care logic preserved)
            if lower.contains("add task") || lower.contains("add care") {
                let parts = inputText.components(separatedBy: .whitespaces)
                var taskName = "New care task"
                if parts.count > 2 { taskName = parts[2...].joined(separator: " ") }
                let care = CareKinThread()
                care.addTask(taskName, priority: "normal", dueDate: nil, service: svc, context: ctx)
                inputText = ""
                feedback = "Care task added. Ripples active."
                return
            } else if lower.contains("complete task") {
                let taskName = inputText.replacingOccurrences(of: "complete task ", with: "", options: .caseInsensitive)
                let care = CareKinThread()
                care.completeTask(named: taskName, service: svc, context: ctx)
                inputText = ""
                feedback = "Task complete. +mastery in CareKin."
                return
            }
        }
        
        // Generic + gamif aware
        if threadName == "Self" { linked = ["CareKin", "Stewardship", "Meaning"] }
        else if threadName == "Stewardship" { linked = ["Meaning", "Self"] }
        else if threadName == "Meaning" { linked = ["Self", "CareKin"] }
        
        svc.emitEvent(
            thread: threadName,
            type: "user_weave",
            payload: ["action": inputText],
            affectsEnergy: threadName == "Self" || threadName == "CareKin",
            linkedThreads: linked
        )
        
        // Update mastery/streak hook via context
        ctx.updateFromEvent(TimelineEvent(thread: threadName, type: "user_weave", payload: ["action": inputText], linkedThreads: linked, affectsEnergy: true))
        
        feedback = "Ripple processed in (threadName). Check Mastery + suggested weaves."
        inputText = ""
    }
    
    private func generateCrossSuggestions(for thread: String, context: LifeContext) -> [String] {
        var suggestions: [String] = []
        if thread == "Self" && context.energyProfile == .low {
            suggestions.append("Consider a quick CareKin micro-connection to build momentum.")
        }
        if thread == "Stewardship" && !context.recentEventSummaries.isEmpty {
            suggestions.append("Redirect a recent saving to a Meaning legacy action or Self restorative.")
        }
        if context.masteryTiers[thread] ?? 1 >= 2 {
            suggestions.append("Your (thread) mastery suggests forging a cross-thread quest.")
        }
        suggestions.append("Review recent ripples in Compass for harmony opportunities.")
        return suggestions
    }
    
    private func exportThreadData() {
        let data = threadEvents.map { event in
            "(event.timestamp): (event.type)@(event.thread) → (event.linkedThreads.joined(separator: ",")) | (event.payload.values.joined(separator: " • "))"
        }.joined(separator: "\n")
        
        var gamif = ""
        if let ctx = context {
            let tier = ctx.masteryTiers[threadName] ?? 1
            let active = activeThreadQuests.map { $0.title }.joined(separator: "; ")
            gamif = "\n\nMastery Tier: (tier) ((tierName(for: tier)))\nActive Quests: (active.isEmpty ? "none" : active)\nStreak: (ctx.globalWeaveStreak) • Essence: (Int(ctx.weaveEssence))"
        }
        
        exportData = "OneWeave Thread Export: (threadName)\n\n(data)(gamif)\n\n(Privacy: local-only export)"
        showExport = true
    }
}

// MARK: - Calm Subviews (inline for single-file polish)

struct MasteryBadge: View {
    let tier: Int
    let thread: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text("L(tier)")
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(tierColor.opacity(0.2))
                .clipShape(Capsule())
            Text(tierLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    private var tierColor: Color {
        switch tier {
        case 4: return .purple
        case 3: return .indigo
        case 2: return .blue
        default: return .gray
        }
    }
    
    private var tierLabel: String {
        switch tier { case 4: return "Luminary"; case 3: return "Guardian"; case 2: return "Weaver"; default: return "Novice" }
    }
}

struct QuestCard: View {
    let quest: WeaveQuest
    let thread: String
    let onComplete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(quest.title)
                    .font(.subheadline.bold())
                Spacer()
                Text(quest.displayEssence)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            Text(quest.questDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            HStack {
                Label("(quest.estimatedIRLMinutes)m IRL", systemImage: "figure.walk")
                    .font(.caption2)
                Spacer()
                Button("Reflect & Complete", action: onComplete)
                    .font(.caption.bold())
                    .buttonStyle(.bordered)
            }
        }
        .padding(8)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct SuggestedQuestRow: View {
    let quest: WeaveQuest
    let onAccept: () -> Void
    
    var body: some View {
        Button(action: onAccept) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(quest.title)
                        .font(.subheadline)
                    Text(quest.questDescription)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text("~ (quest.estimatedIRLMinutes) min • (quest.displayEssence) • Tap to accept")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
                Spacer()
                Image(systemName: "plus.circle")
                    .foregroundStyle(.blue)
            }
            .padding(8)
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

struct RippleRow: View {
    let event: TimelineEvent
    let thread: String
    let onEcho: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("(event.type) • (event.timestamp, style: .time)")
                    .font(.caption.bold())
                Spacer()
                if !event.linkedThreads.isEmpty {
                    Text("→ (event.linkedThreads.joined(separator: ","))")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
            }
            if !event.payload.isEmpty {
                Text(event.payload.values.joined(separator: " • "))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Button("Echo for insight", action: onEcho)
                .font(.caption2)
                .foregroundStyle(.purple)
        }
        .padding(8)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    ThreadDetailView(threadName: "Self")
        .modelContainer(for: [LifeContext.self, TimelineEvent.self, WeaveQuest.self])
}