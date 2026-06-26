import SwiftData
import Foundation

// DataSeeder: Populates demo data for journeys (call on first launch or via prototype button).
// Privacy: Local only. For testing interconnections.
// Enhanced to also seed thread model instances so .summary() methods are available in UI.
struct DataSeeder {
    static func seedIfNeeded(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<LifeContext>()
        if (try? modelContext.fetch(descriptor).first) != nil { return }
        
        let ctx = LifeContext()
        ctx.values["season"] = "High Care Load"
        ctx.energyProfile = .low
        modelContext.insert(ctx)
        
        let svc = TimelineService(modelContext: modelContext)
        
        // Seed thread instances for summary() availability in ThreadsOverview etc.
        seedThreadModels(modelContext: modelContext, service: svc, context: ctx)
        
        // Seed a busy-season goal journey (Self)
        svc.emitEvent(
            thread: "Self",
            type: "goal_added",
            payload: ["goal": "half-marathon training"],
            affectsEnergy: true,
            linkedThreads: ["CareKin", "Stewardship"]
        )
        
        // Care load ripple
        svc.emitEvent(
            thread: "CareKin",
            type: "task_added",
            payload: ["task": "family admin during training"],
            affectsEnergy: true
        )
        
        // Leak example
        svc.emitEvent(
            thread: "Stewardship",
            type: "subscription_leak",
            payload: ["service": "unused-app"],
            affectsEnergy: false,
            linkedThreads: ["Self", "Meaning"]
        )
        
        // Meaning capture
        svc.emitEvent(
            thread: "Meaning",
            type: "story_captured",
            payload: ["story": "Started training despite care load — modeling resilience for kids"]
        )
    }
    
    static func seedThreadModels(modelContext: ModelContext, service: TimelineService, context: LifeContext) {
        // Create one instance per thread if not present (for .summary() and rich state)
        let selfDesc = FetchDescriptor<BasicSelfThread>()
        if (try? modelContext.fetch(selfDesc).first) == nil {
            let selfT = BasicSelfThread()
            modelContext.insert(selfT)
            selfT.addHabit("Daily walk", service: service, context: context)
            selfT.addGoal("half-marathon training", service: service, context: context)
        }
        
        let stewardDesc = FetchDescriptor<StewardshipThread>()
        if (try? modelContext.fetch(stewardDesc).first) == nil {
            let st = StewardshipThread()
            modelContext.insert(st)
            st.addSubscription("Spotify", monthlyCost: 10.99, service: service, context: context)
            st.detectLeak(serviceName: "unused-app", estimatedMonthlySavings: 9.99, service: service, context: context)
        }
        
        let careDesc = FetchDescriptor<CareKinThread>()
        if (try? modelContext.fetch(careDesc).first) == nil {
            let ct = CareKinThread()
            modelContext.insert(ct)
            ct.addTask("School forms + dinner prep", priority: "high", service: service, context: context)
        }
        
        let meanDesc = FetchDescriptor<MeaningThread>()
        if (try? modelContext.fetch(meanDesc).first) == nil {
            let mt = MeaningThread()
            modelContext.insert(mt)
            mt.captureStory("Started training despite care load — modeling resilience for kids", service: service, context: context)
        }
    }
}
