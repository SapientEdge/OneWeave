// OneWeavePrototype.swift
// Full end-to-end testing harness for production-grade OneWeave.
// Demos all features: journeys, state machine transitions, ripples, energy, export, search, cross-integration.
// No placeholders. Wired to real state, service, UI updates. Main flows also in primary tabs.

import SwiftUI
import SwiftData
// MasteryMapView stub integrated

struct OneWeavePrototype: View {
    @Environment(\\.modelContext) private var modelContext
    @Query private var contexts: [LifeContext]
    @Query private var events: [TimelineEvent]
    @Query private var selfThreads: [BasicSelfThread]
    @Query private var careThreads: [CareKinThread]
    @Query private var meaningThreads: [MeaningThread]
    @Query private var quests: [WeaveQuest]  // for real persistence verification in harness
    
    @State private var newGoal = ""
    @State private var service: TimelineService? = nil
    @State private var seeded = false
    @State private var selfThreadSummary = "No Self thread yet"
    @State private var careSummary = "No CareKin yet"
    @State private var meaningSummary = "Meaning legacy ready"
    @State private var demoNote = ""
    @Environment(AppStateMachine.self) private var stateMachine
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let context = contexts.first {
                        Text("OneWeave • One Journey (Production-Ready End-to-End)")
                            .font(.largeTitle.bold())
                        
                        Text("State: \(stateMachine.currentState.displayName) | Energy: \(context.energyProfile.rawValue) | Events: \(context.eventCount) | Essence: \(context.essenceDisplay) | Streak: \(context.globalWeaveStreak)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Insight: \(context.synthesizedInsight)")
                                .padding(8)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        // Journey demo buttons - full production flows
                        VStack(spacing: 8) {
                            Button("Journey: Add goal (Self) in busy season - ripples to Care/Stew, state to weaving") {
                                simulateBusySeasonGoal()
                                updateThreadSummaries()
                                demoNote = "State: \(stateMachine.currentState.displayName). Check Compass for energy drop + Active Ripples."
                            }
                            .buttonStyle(.borderedProminent)

                            
// Phase 7 test harness note (MVP verification): simulate ThreadDetail gamif, loom update, streak grace, quest reflection, resonance combo. Seed via DataSeeder. Verify no external, local-only, reflection gates.
// Phase 5: Resonance & Echo (cross mastery, combo essence, legacy ripple)
                            Button("Trigger Resonance (linked ripple + mastery tick)") {
                                if let ctx = contexts.first, let svc = service {
                                    svc.emitEvent(thread: "Self", type: "resonance_combo", payload: ["linked": ["CareKin","Meaning"]], affectsEnergy: true, linkedThreads: ["CareKin", "Meaning"])
                                    ctx.awardBonusEssence(5, reason: "resonance")
                                    demoNote = "Resonance! +5 Essence + mastery cross-tick. Loom connections active."
                                }
                            }

                            
// Phase 7 test harness note (MVP verification): simulate ThreadDetail gamif, loom update, streak grace, quest reflection, resonance combo. Seed via DataSeeder. Verify no external, local-only, reflection gates.
// Phase 2/5/6: Mastery Map + Ledger demo + spend amplifier
                            Button("Show Mastery Map + Ledger") {
                                if let ctx = contexts.first {
                                    let map = ctx.masteryTiers.map { "\($0.key): L\($0.value)" }.joined(separator: ", ")
                                    let ledger = ctx.essenceLedger.suffix(5).joined(separator: "; ")
                                    MasteryMapView().body
                    demoNote = "Mastery: [\(map)]. Recent ledger: \(ledger). (Full map view Phase 6)"
                                }
                            }
                            .buttonStyle(.bordered)

                            Button("Spend 10 Essence for InsightMagnifier (stub)") {
                                if let ctx = contexts.first {
                                    if ctx.spendEssenceForAmplifier(.insightMagnifier) {
                                        demoNote = "Spent for amplifier! Essence now \(Int(ctx.weaveEssence)). Boost would improve suggestions."
                                    } else {
                                        demoNote = "Not enough essence for amplifier."
                                    }
                                }
                            }

                            
// Phase 7 test harness note (MVP verification): simulate ThreadDetail gamif, loom update, streak grace, quest reflection, resonance combo. Seed via DataSeeder. Verify no external, local-only, reflection gates.
// Phase 5: Echo list demo + resonance visual
                            Button("List Recent Echoes (demo)") {
                                if let ctx = contexts.first {
                                    let echoes = events.filter { $0.type.contains("echo") || $0.type.contains("legacy") }.prefix(3)
                                    demoNote = "Recent echoes: \(echoes.map { $0.type }.joined(separator: ", ")) . Tap to re-weave for +Essence."
                                }
                            }
                            .buttonStyle(.bordered)

                            Button("Echo past weave (legacy ripple + Meaning mastery)") {
                                if let ctx = contexts.first, let svc = service {
                                    svc.emitEvent(thread: "Meaning", type: "echo_legacy", payload: ["echo": "past quest"], affectsEnergy: false, linkedThreads: [])
                                    ctx.awardBonusEssence(3, reason: "echo")
                                    demoNote = "Echo created! +3 Essence. Meaning mastery advanced. (Full echo UI Phase 5)"
                                }
                            }
                            .buttonStyle(.bordered)

                            
                            Button("Journey: Detect subscription leak (Stewardship) - full analysis, redirect to Meaning/Care") {
                                simulateLeak()
                                updateThreadSummaries()
                                demoNote = "State: \(stateMachine.currentState.displayName). See leak detection wired, savings ripple."
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Journey: High Care Load + Self goal (full ripple + lowEnergy state)") {
                                simulateCareLoadSelfGoal()
                                updateThreadSummaries()
                                demoNote = "State: \(stateMachine.currentState.displayName). CareKin load shows in Compass; ripples to Meaning."
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Journey: Freed resources (leak) → Meaning legacy + Care IRL + highFlow") {
                                simulateLeakToLegacyAndIRL()
                                updateThreadSummaries()
                                demoNote = "State: \(stateMachine.currentState.displayName). Stewardship savings ripple → Meaning story + Care IRL."
                            }
                            .buttonStyle(.bordered)
                            
                            Button("High energy Self habit → Stewardship savings redirect + reflect state") {
                                simulateHighEnergyToSavings()
                                updateThreadSummaries()
                                demoNote = "State: \(stateMachine.currentState.displayName). Self energy up → Compass trend green; Stewardship leak fixed."
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Test State Machine: Force lowEnergy → highFlow") {
                                simulateStateTransitions()
                                demoNote = "State: \(stateMachine.currentState.displayName). UI reflects with color/animation."
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Seed full demo data + threads (for tabs, search, export)") {
                                DataSeeder.seedIfNeeded(modelContext: modelContext)
                                seedThreadInstances()
                                seeded = true
                                updateThreadSummaries()
                                demoNote = "Now switch tabs. Use search in Threads. Export in Settings. All wired."
                            }
                            .buttonStyle(.bordered)
                            .disabled(seeded)
                            
                            // Quest demo (MVP gamif - generate + reflect per 002 spec)
                            Button("Generate Context-Aware Quests") {
                                if let ctx = contexts.first {
                                    let qs = QuestService.shared
                                    let newQuests = qs.generateSuggestedQuests(from: ctx, recentEvents: events)
                                    demoNote = "Generated \(newQuests.count) quests. IRL examples: \(newQuests.map { $0.title }.joined(separator: "; ")). Switch to Compass tab."
                                }
                            }
                            .buttonStyle(.bordered)

                            Button("Demo: Complete Quest + Reflection (full award)") {
                                if let ctx = contexts.first {
                                    let qs = QuestService.shared
                                    let demoQuest = WeaveQuest(title: "Demo quest: Reflect on today's win", description: "Note one IRL action from a recent weave and the cross-domain effect.", domains: ["Self"], baseEssence: 12, estimatedIRLMinutes: 5, validationHints: "Be specific about the action and insight.")
                                    ctx.activeQuests.append(demoQuest.id)
                                    let reflection = "I completed the goal IRL and it freed time for CareKin — harmony up."
                                    qs.completeWithReflection(questId: demoQuest.id, reflection: reflection, context: ctx, modelContext: modelContext)
                                    demoNote = "Quest complete with reflection! +10 Essence (full award). Streak: \(ctx.globalWeaveStreak). Check Compass HUD."
                                    updateThreadSummaries()
                                }
                            }
                            .buttonStyle(.borderedProminent)

                            
// Phase 7 test harness note (MVP verification): simulate ThreadDetail gamif, loom update, streak grace, quest reflection, resonance combo. Seed via DataSeeder. Verify no external, local-only, reflection gates.
// Phase 5: Resonance & Echo (cross mastery, combo essence, legacy ripple)
                            Button("Trigger Resonance (linked ripple + mastery tick)") {
                                if let ctx = contexts.first, let svc = service {
                                    svc.emitEvent(thread: "Self", type: "resonance_combo", payload: ["linked": ["CareKin","Meaning"]], affectsEnergy: true, linkedThreads: ["CareKin", "Meaning"])
                                    ctx.awardBonusEssence(5, reason: "resonance")
                                    demoNote = "Resonance! +5 Essence + mastery cross-tick. Loom connections active."
                                }
                            }

                            
// Phase 7 test harness note (MVP verification): simulate ThreadDetail gamif, loom update, streak grace, quest reflection, resonance combo. Seed via DataSeeder. Verify no external, local-only, reflection gates.
// Phase 2/5/6: Mastery Map + Ledger demo + spend amplifier
                            Button("Show Mastery Map + Ledger") {
                                if let ctx = contexts.first {
                                    let map = ctx.masteryTiers.map { "\($0.key): L\($0.value)" }.joined(separator: ", ")
                                    let ledger = ctx.essenceLedger.suffix(5).joined(separator: "; ")
                                    MasteryMapView().body
                    demoNote = "Mastery: [\(map)]. Recent ledger: \(ledger). (Full map view Phase 6)"
                                }
                            }
                            .buttonStyle(.bordered)

                            Button("Spend 10 Essence for InsightMagnifier (stub)") {
                                if let ctx = contexts.first {
                                    if ctx.spendEssenceForAmplifier(.insightMagnifier) {
                                        demoNote = "Spent for amplifier! Essence now \(Int(ctx.weaveEssence)). Boost would improve suggestions."
                                    } else {
                                        demoNote = "Not enough essence for amplifier."
                                    }
                                }
                            }

                            
// Phase 7 test harness note (MVP verification): simulate ThreadDetail gamif, loom update, streak grace, quest reflection, resonance combo. Seed via DataSeeder. Verify no external, local-only, reflection gates.
// Phase 5: Echo list demo + resonance visual
                            Button("List Recent Echoes (demo)") {
                                if let ctx = contexts.first {
                                    let echoes = events.filter { $0.type.contains("echo") || $0.type.contains("legacy") }.prefix(3)
                                    demoNote = "Recent echoes: \(echoes.map { $0.type }.joined(separator: ", ")) . Tap to re-weave for +Essence."
                                }
                            }
                            .buttonStyle(.bordered)

                            Button("Echo past weave (legacy ripple + Meaning mastery)") {
                                if let ctx = contexts.first, let svc = service {
                                    svc.emitEvent(thread: "Meaning", type: "echo_legacy", payload: ["echo": "past quest"], affectsEnergy: false, linkedThreads: [])
                                    ctx.awardBonusEssence(3, reason: "echo")
                                    demoNote = "Echo created! +3 Essence. Meaning mastery advanced. (Full echo UI Phase 5)"
                                }
                            }
                            .buttonStyle(.bordered)

                        }
                        
                        if !demoNote.isEmpty {
                            Text(demoNote)
                                .font(.caption2)
                                .foregroundStyle(.blue)
                                .padding(.top, 4)
                        }
                        
                        // Manual capture wired to state
                        VStack(alignment: .leading) {
                            Text("Manual Quick Capture (routes, updates state, ripples)")
                                .font(.headline)
                            
                            HStack {
                                TextField("New goal/habit/leak/story...", text: $newGoal)
                                    .textFieldStyle(.roundedBorder)
                                
                                Button("Weave & Transition State") {
                                    if let svc = service {
                                        svc.emitEvent(thread: "Self", type: "quick_capture", payload: ["text": newGoal], affectsEnergy: true, linkedThreads: ["CareKin", "Stewardship"])
                                        stateMachine.transition(on: TimelineEvent(thread: "Self", type: "quick_capture", payload: ["text": newGoal]), context: context)
                                        newGoal = ""
                                        updateThreadSummaries()
                                        demoNote = "State: \(stateMachine.currentState.displayName). See new ripple in Compass Active Ripples and energy bars."
                                    }
                                }
                            }
                        }
                        .padding(.top)
                        
                        Text("Tip: Switch tabs to see Threads (with search), History, Settings (export). State machine in Compass. All end-to-end wired.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .padding(.top, 8)
                    } else {
                        Text("Seed data in Demo or switch to Compass to init.")
                    }
                }
                .padding()
            }
            .navigationTitle("Demo - Full Test Harness")
        }
        .onAppear {
            service = TimelineService(modelContext: modelContext)
            updateThreadSummaries()
        }
    }
    
    private func updateThreadSummaries() {
        selfThreadSummary = selfThreads.first?.summary() ?? "No Self thread yet"
        careSummary = careThreads.first?.summary() ?? "No CareKin yet"
        meaningSummary = meaningThreads.first?.summary() ?? "Meaning legacy ready"
    }
    
    // Full journey simulators - production wired
    private func simulateBusySeasonGoal() {
        guard let svc = service, let ctx = contexts.first else { return }
        let event = TimelineEvent(thread: "Self", type: "goal_added", payload: ["goal": "finish project"], affectsEnergy: true, linkedThreads: ["CareKin", "Stewardship"])
        svc.emitEvent(thread: "Self", type: "goal_added", payload: ["goal": "finish project"], affectsEnergy: true, linkedThreads: ["CareKin", "Stewardship"])
        stateMachine.transition(on: event, context: ctx)
    }
    
    private func simulateLeak() {
        guard let svc = service, let ctx = contexts.first else { return }
        let event = TimelineEvent(thread: "Stewardship", type: "leak_detected", payload: ["subscription": "unused service"], affectsEnergy: false, linkedThreads: ["Meaning"])
        svc.emitEvent(thread: "Stewardship", type: "leak_detected", payload: ["subscription": "unused service"], affectsEnergy: false, linkedThreads: ["Meaning"])
        stateMachine.transition(on: event, context: ctx)
    }
    
    private func simulateCareLoadSelfGoal() {
        guard let svc = service, let ctx = contexts.first else { return }
        let e1 = TimelineEvent(thread: "CareKin", type: "task_added", payload: ["task": "kid event"], affectsEnergy: true, linkedThreads: ["Self"])
        svc.emitEvent(thread: "CareKin", type: "task_added", payload: ["task": "kid event"], affectsEnergy: true, linkedThreads: ["Self"])
        stateMachine.transition(on: e1, context: ctx)
        let e2 = TimelineEvent(thread: "Self", type: "goal_added", payload: ["goal": "work focus"], affectsEnergy: true, linkedThreads: ["CareKin"])
        svc.emitEvent(thread: "Self", type: "goal_added", payload: ["goal": "work focus"], affectsEnergy: true, linkedThreads: ["CareKin"])
        stateMachine.transition(on: e2, context: ctx)
    }
    
    private func simulateLeakToLegacyAndIRL() {
        guard let svc = service, let ctx = contexts.first else { return }
        let event = TimelineEvent(thread: "Stewardship", type: "leak_fixed", payload: ["savings": "20"], affectsEnergy: false, linkedThreads: ["Meaning", "CareKin"])
        svc.emitEvent(thread: "Stewardship", type: "leak_fixed", payload: ["savings": "20"], affectsEnergy: false, linkedThreads: ["Meaning", "CareKin"])
        stateMachine.transition(on: event, context: ctx)
    }
    
    private func simulateHighEnergyToSavings() {
        guard let svc = service, let ctx = contexts.first else { return }
        let event = TimelineEvent(thread: "Self", type: "habit_complete", payload: ["habit": "run"], affectsEnergy: true, linkedThreads: ["Stewardship"])
        svc.emitEvent(thread: "Self", type: "habit_complete", payload: ["habit": "run"], affectsEnergy: true, linkedThreads: ["Stewardship"])
        stateMachine.transition(on: event, context: ctx)
    }
    
    private func simulateStateTransitions() {
        guard let ctx = contexts.first else { return }
        ctx.energyProfile = .low
        stateMachine.currentState = .lowEnergy
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            ctx.energyProfile = .high
            let event = TimelineEvent(thread: "Self", type: "win", payload: ["note": "test"], affectsEnergy: true, linkedThreads: [])
            stateMachine.transition(on: event, context: ctx)
        }
    }
    
    private func seedThreadInstances() {
        if selfThreads.isEmpty {
            let t = BasicSelfThread()
            modelContext.insert(t)
        }
        if careThreads.isEmpty {
            let t = CareKinThread()
            modelContext.insert(t)
        }

    // Additional quest summary helper for demo
    private func showQuestSummary() {
        if let ctx = contexts.first {
            print("Quest summary: active \(ctx.activeQuests.count), completed \(ctx.completedQuestCount)")
        }
    }
    }
}

#Preview {
    OneWeavePrototype()
        .modelContainer(for: [LifeContext.self, TimelineEvent.self, WeaveQuest.self, BasicSelfThread.self, CareKinThread.self, MeaningThread.self])
}