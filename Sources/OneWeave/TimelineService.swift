import SwiftData
import Foundation

// TimelineService: central for event-driven updates. Emits, persists, notifies LifeContext.
// Follows global best practices: privacy-first, local-only, no external calls or training data use.
// Now also drives the formal AppStateMachine for state transitions on events.
@Observable
class TimelineService {
    private var modelContext: ModelContext
    // Formal AppStateMachine: drives transitions on every emit. Exposed for direct UI binding if desired (Compass etc can use via service or LifeContext).
    let stateMachine = AppStateMachine()
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // Core emit: creates proper TimelineEvent, persists locally, notifies context for aggregation
    func emitEvent(
        thread: String,
        type: String,
        payload: [String: String],
        affectsEnergy: Bool = false,
        linkedThreads: [String] = []
    ) {
        let event = TimelineEvent(
            thread: thread,
            type: type,
            payload: payload,
            affectsEnergy: affectsEnergy,
            linkedThreads: linkedThreads
        )
        modelContext.insert(event)
        
        // Event-driven: notify LifeContext to aggregate (update energy, values, insights, AND state machine)
        notifyLifeContext(of: event)
        
        // Drive the formal AppStateMachine transition directly (in addition to LifeContext's apply)
        stateMachine.transition(on: event)
        
        // Optional ripple (local)
        if !linkedThreads.isEmpty {
            handleCrossThread(from: thread, to: linkedThreads, suggestion: "Event \(type) in \(thread) may affect you.")
        }
    }
    
    // Convenience for explicit emit + context notify
    func emitAndNotifyContext(
        thread: String,
        type: String,
        payload: [String: String],
        affectsEnergy: Bool = false,
        linkedThreads: [String] = []
    ) {
        emitEvent(thread: thread, type: type, payload: payload, affectsEnergy: affectsEnergy, linkedThreads: linkedThreads)
    }
    
    // Notify / update the shared LifeContext from event (aggregation happens here)
    private func notifyLifeContext(of event: TimelineEvent) {
        let descriptor = FetchDescriptor<LifeContext>()
        do {
            let contexts = try modelContext.fetch(descriptor)
            if let context = contexts.first {
                context.updateFromEvent(event)
            } else {
                // Auto-init context on first event (supports prototype)
                let newContext = LifeContext()
                newContext.updateFromEvent(event)
                modelContext.insert(newContext)
            }
            // Privacy: all local. In full impl: would trigger local on-device AI (e.g. Apple Intelligence) here only.
            // No external network, no logging raw data.
        } catch {
            // Local error only - never external
            print("Local TimelineService notify error (no external impact): \(error.localizedDescription)")
        }
    }
    
    // Get or create the single LifeContext (for UI binding)
    func getOrCreateLifeContext() -> LifeContext {
        let descriptor = FetchDescriptor<LifeContext>()
        if let ctx = try? modelContext.fetch(descriptor).first {
            // If context exists, optionally sync latest machine state back (light)
            if ctx.currentAppState.isEmpty {
                ctx.currentAppState = stateMachine.current.rawValue
            }
            return ctx
        } else {
            let ctx = LifeContext()
            ctx.currentAppState = stateMachine.current.rawValue
            modelContext.insert(ctx)
            return ctx
        }
    }
    
    // Cross-thread ripple (local only)
    func handleCrossThread(from thread: String, to: [String], suggestion: String) {
        // Real version uses local AIOrchestrator for intelligent nudges
        // For now: simple log (in prod: emit follow-up event or update values)
        print("Local ripple only: from \(thread) to \(to): \(suggestion)")
    }
    
    // Batch emit for testing / replay (local)
    func emitBatch(_ events: [(thread: String, type: String, payload: [String: String], affectsEnergy: Bool)]) {
        for e in events {
            emitEvent(thread: e.thread, type: e.type, payload: e.payload, affectsEnergy: e.affectsEnergy)
        }
    }
}

// Global best practice: All events stay local unless user explicitly syncs (private CloudKit only).
// TimelineService never makes external calls. Use for testability in prototype.
