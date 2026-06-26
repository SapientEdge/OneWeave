import SwiftData
import Foundation

/// Enhanced CareKinThread per OneWeave spec, USER_JOURNEYS_ONEWEAVE.md, and patterns from BasicSelfThread/StewardshipThread.
/// 
/// Care & Kin: family coordination, multi-gen tasks, IRL micro-connections (real human time over digital).
/// 
/// Full features implemented:
/// - Full task management: addTask (with priority, optional due), completeTask, prioritizeTask, getActive/pending tasks, task metadata persisted via maps (SwiftData friendly).
/// - Load tracking: careLoadLevel ("low"/"normal"/"high"), computeCareLoad() based on pending count + high-prio tasks; auto-updates season in LifeContext on changes.
/// - Dynamic IRL suggestions: suggestIRL() generates context/load-aware real-world bridges (e.g. walk, shared meal, voice note instead of screen); stores + returns; emits via service.
/// - processEvent for Self/Stewardship ripples (per Journey 1 & 3): Self goal in busy season → suggest simplify Care load / IRL focus; Stewardship leak/savings → redirect saved resources to family IRL.
/// - EVERY meaningful change (add/complete/suggestIRL/load update) calls TimelineService.emitEvent (with proper affectsEnergy, linkedThreads) + LifeContext update + activity log + insight append.
/// - Event-driven: actions ripple immediately to Compass/Insight/LifeContext/other threads (Self energy protection, Stewardship resource redirect, Meaning legacy).
/// 
/// Aligns with:
/// - Spec: Care & Kin thread (coordination model, IRL prompt generator); event-driven interconnections; real-world bridges (analog nudges).
/// - USER_JOURNEYS: 
///   - Journey 1 (new growth goal in busy season): CareKin surfaces "Schedule a 15-min walk..." ; insight "Simplify 2 items in Care & Kin".
///   - Journey 3 (Low Energy + High Care Load): multiple tasks → energy low, simplify CareKin, Self process reacts.
/// - Real-world emphasis: IRL over more apps/tasks; calm load reduction.
/// - Privacy: Local-only SwiftData @Model. No external calls. No training data. All aggregation/ripples on-device.
/// 
/// Testable via careSummary(), clearForTesting(), direct calls in prototype/ThreadDetailView.
/// Global best practices followed: see constitution.md, GLOBAL_BEST_PRACTICES.md.

@Model
final class CareKinThread: ThreadProtocol {
    var name: String = "CareKin"
    
    // Core task state (persisted)
    var familyTasks: [String] = []
    
    // Metadata maps for full management (SwiftData serializable; task name as key)
    var taskPriorities: [String: String] = [:]      // "high" | "normal" | "low"
    var taskDueDateStrings: [String: String] = [:]  // ISO date strings
    var taskStatus: [String: String] = [:]          // "pending" | "completed"
    
    // Load tracking (core for ripples and season)
    var careLoadLevel: String = "normal"  // "low", "normal", "high"
    
    // IRL + insights (accumulated, lightweight)
    var irlSuggestions: [String] = []
    var recentInsights: [String] = []
    
    // Local activity log (private, capped)
    var activityLog: [String] = []
    
    init() {}
    
    // MARK: - Full Task Management (add, complete, prioritize, query; ALWAYS via service on change)
    
    func addTask(_ task: String, priority: String = "normal", dueDate: Date? = nil, service: TimelineService? = nil, context: LifeContext? = nil) {
        guard !task.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let cleanTask = task.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !familyTasks.contains(cleanTask) {
            familyTasks.append(cleanTask)
        }
        taskPriorities[cleanTask] = priority
        taskStatus[cleanTask] = "pending"
        if let due = dueDate {
            taskDueDateStrings[cleanTask] = isoDateString(for: due)
        }
        
        let payload: [String: String] = [
            "task": cleanTask,
            "priority": priority,
            "due": taskDueDateStrings[cleanTask] ?? "",
            "status": "pending"
        ]
        
        let event = TimelineEvent(thread: name, type: "task_added", payload: payload)
        event.affectsEnergy = true  // Care tasks add load/energy cost (per journeys/spec)
        
        logActivity("Added family/care task: \(cleanTask) (priority: \(priority))")
        
        // Always prefer service for full ripple (persist + LifeContext + cross-thread)
        if let svc = service {
            svc.emitEvent(
                thread: name,
                type: "task_added",
                payload: payload,
                affectsEnergy: true,
                linkedThreads: ["Self", "Stewardship"]  // ripples to energy/habits + resources (journeys)
            )
        } else if let ctx = context {
            ctx.updateFromEvent(event)
        }
        
        if let ctx = context {
            ctx.updateFromEvent(event)
            updateCareLoad(using: ctx)
        }
        
        recentInsights.append("Care task added: \(cleanTask). High load? Simplify or convert to IRL moment.")
        if recentInsights.count > 10 { recentInsights.removeFirst() }
        
        updateLoadTracking(using: context)
    }
    
    func completeTask(_ task: String, service: TimelineService? = nil, context: LifeContext? = nil) {
        guard familyTasks.contains(task) else { return }
        
        taskStatus[task] = "completed"
        
        let payload: [String: String] = [
            "task": task,
            "status": "completed",
            "priority": taskPriorities[task] ?? "normal"
        ]
        
        let event = TimelineEvent(thread: name, type: "task_completed", payload: payload)
        event.affectsEnergy = false  // completion is restorative / progress
        
        logActivity("Completed care task: \(task)")
        
        if let svc = service {
            svc.emitEvent(
                thread: name,
                type: "task_completed",
                payload: payload,
                affectsEnergy: false,
                linkedThreads: ["Self", "Meaning"]  // restore energy for Self; legacy capture opportunity
            )
        }
        
        if let ctx = context {
            ctx.updateFromEvent(event)
            updateCareLoad(using: ctx)
        }
        
        recentInsights.append("Task completed: \(task). Load may have eased — check IRL opportunities.")
        if recentInsights.count > 10 { recentInsights.removeFirst() }
        
        updateLoadTracking(using: context)
    }
    
    func prioritizeTask(_ task: String, newPriority: String, service: TimelineService? = nil, context: LifeContext? = nil) {
        guard familyTasks.contains(task) else { return }
        guard ["high", "normal", "low"].contains(newPriority) else { return }
        
        let oldPrio = taskPriorities[task] ?? "normal"
        taskPriorities[task] = newPriority
        
        let payload: [String: String] = [
            "task": task,
            "oldPriority": oldPrio,
            "newPriority": newPriority
        ]
        
        logActivity("Prioritized task \(task): \(oldPrio) → \(newPriority)")
        
        if let svc = service {
            svc.emitEvent(
                thread: name,
                type: "task_prioritized",
                payload: payload,
                affectsEnergy: true,  // priority change can affect load
                linkedThreads: ["Self", "Stewardship"]
            )
        }
        
        if let ctx = context {
            let ev = TimelineEvent(thread: name, type: "task_prioritized", payload: payload)
            ctx.updateFromEvent(ev)
            updateCareLoad(using: ctx)
        }
        
        recentInsights.append("Care task re-prioritized to \(newPriority): \(task)")
        updateLoadTracking(using: context)
    }
    
    func getActiveTasks() -> [String] {
        return familyTasks.filter { taskStatus[$0] != "completed" }
    }
    
    func getPendingHighPriorityTasks() -> [String] {
        return getActiveTasks().filter { (taskPriorities[$0] ?? "normal") == "high" }
    }
    
    // MARK: - Load Tracking (compute + auto ripple to season/context)
    
    func computeCareLoad() -> String {
        let active = getActiveTasks()
        let highPrioCount = getPendingHighPriorityTasks().count
        let totalActive = active.count
        
        if totalActive >= 6 || highPrioCount >= 3 {
            return "high"
        } else if totalActive >= 3 || highPrioCount >= 1 {
            return "normal"
        } else {
            return "low"
        }
    }
    
    func updateCareLoad(using context: LifeContext? = nil) {
        let newLoad = computeCareLoad()
        if newLoad != careLoadLevel {
            careLoadLevel = newLoad
            logActivity("Care load updated to: \(newLoad)")
            recentInsights.append("Care load now \(newLoad) based on \(getActiveTasks().count) active tasks.")
        }
        
        if let ctx = context {
            if careLoadLevel == "high" {
                ctx.values["season"] = "High Care Load"
                if !ctx.priorities.contains("simplify_care") {
                    ctx.priorities.append("simplify_care")
                }
            } else if careLoadLevel == "low" && (ctx.values["season"]?.contains("Care") ?? false) {
                // ease if load dropped
                ctx.values["season"] = "Balanced"
            }
        }
    }
    
    func getCareLoad() -> String {
        return careLoadLevel
    }
    
    func updateLoadTracking(using context: LifeContext? = nil) {
        updateCareLoad(using: context)
    }
    
    // MARK: - IRL Suggestions (dynamic, load-aware, real-world bridges; emit on change)
    
    func suggestIRL(service: TimelineService? = nil, context: LifeContext? = nil) -> String {
        updateLoadTracking(using: context)
        
        let load = careLoadLevel
        let season = context?.values["season"] ?? ""
        let focus = context?.values["focus"] ?? context?.priorities.first ?? "core priorities"
        let activeCount = getActiveTasks().count
        
        var suggestion: String
        
        if load == "high" || season.contains("Care") {
            suggestion = "High care load — simplify 1-2 tasks. Schedule a 15-min IRL walk or voice call with family instead of another screen session."
            if activeCount > 4 {
                suggestion = "Simplify 2 Care & Kin items this week. Do one analog family micro-moment (shared tea, short walk) to protect \(focus)."
            }
        } else if load == "low" {
            suggestion = "Balanced care load. Add one meaningful IRL connection: family dinner ritual or handwritten note."
        } else {
            suggestion = "Schedule a 15-min walk with family instead of another screen session."
        }
        
        // Store unique
        if !irlSuggestions.contains(suggestion) {
            irlSuggestions.append(suggestion)
            if irlSuggestions.count > 8 { irlSuggestions.removeFirst() }
        }
        
        logActivity("Suggested IRL: \(suggestion)")
        
        // Emit as meaningful change for ripples (visible in timeline/Compass)
        if let svc = service {
            svc.emitEvent(
                thread: name,
                type: "irl_suggested",
                payload: ["suggestion": suggestion, "load": load],
                affectsEnergy: false,
                linkedThreads: ["Self", "Stewardship"]
            )
        }
        
        if let ctx = context {
            let ev = TimelineEvent(thread: name, type: "irl_suggested", payload: ["suggestion": suggestion])
            ctx.updateFromEvent(ev)
        }
        
        recentInsights.append("IRL suggestion generated for load=\(load): prioritize real connection.")
        if recentInsights.count > 10 { recentInsights.removeFirst() }
        
        return suggestion
    }
    
    // MARK: - Logging and helpers (local, private)
    
    private func isoDateString(for date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.string(from: date)
    }
    
    private func dateFromISO(_ str: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: str)
    }
    
    func logActivity(_ note: String) {
        let ts = Date().formatted(date: .omitted, time: .shortened)
        activityLog.append("[\(ts)] \(note)")
        if activityLog.count > 25 {
            activityLog.removeFirst()
        }
    }
    
    // MARK: - Real processEvent for Self/Stewardship ripples (event-driven per spec/journeys)
    
    func processEvent(_ event: TimelineEvent, context: LifeContext, service: TimelineService) {
        logActivity("Ripple received: \(event.type) from \(event.thread)")
        
        var rippleInsight = false
        
        if event.thread == "Self" && (event.type.contains("goal") || event.type.contains("habit") || event.type.contains("added")) {
            // Journey 1 & 3 alignment: Self goal in busy season ripples to Care load adjustment
            let msg = "Self goal added — consider adjusting family load or converting digital tasks to IRL."
            if !recentInsights.contains(msg) {
                recentInsights.append(msg)
            }
            rippleInsight = true
            
            if careLoadLevel == "high" || (context.values["season"]?.contains("Care") ?? false) || context.energyProfile == .low {
                recentInsights.append("High Care Load + Self momentum: simplify 2 items. IRL bridge recommended over more tasks.")
                
                // Generate + emit IRL suggestion ripple (calls service inside suggestIRL)
                let irl = suggestIRL(service: service, context: context)
                
                // Extra feedback event for weave visibility
                service.emitEvent(
                    thread: name,
                    type: "care_adjust_suggested",
                    payload: ["reason": "self_goal_ripple", "focus": context.values["focus"] ?? "habits", "suggestion": irl],
                    affectsEnergy: false,
                    linkedThreads: ["Self"]
                )
            }
        } else if event.thread == "Stewardship" && (event.type.contains("leak") || event.type.contains("subscription") || event.type.contains("savings") || event.type.contains("cancel")) {
            // Journey 2 ripple: freed resources → CareKin IRL
            recentInsights.append("Stewardship leak/savings detected — redirect saved time/money to Care & Kin IRL (family activity, shared meal).")
            rippleInsight = true
            
            let irlRedirect = "Redirect saved resources to IRL family connection: e.g. a planned outing or home-cooked shared meal instead of consumption."
            if !irlSuggestions.contains(irlRedirect) {
                irlSuggestions.append(irlRedirect)
            }
            
            // Emit the redirect suggestion as CareKin event
            service.emitEvent(
                thread: name,
                type: "irl_from_stewardship",
                payload: ["suggestion": irlRedirect, "source": "stewardship_savings"],
                affectsEnergy: false,
                linkedThreads: ["Stewardship", "Self"]
            )
            
            // Nudge load easing if applicable
            if careLoadLevel == "high" {
                recentInsights.append("With freed resources, consider offloading one high-prio care task.")
            }
        } else if event.thread == "Meaning" || event.type.contains("story") || event.type.contains("legacy") {
            recentInsights.append("Meaning/legacy progress — capture family stories during IRL moments in CareKin.")
            rippleInsight = true
        }
        
        // Always refresh load + suggestions on any ripple
        updateLoadTracking(using: context)
        
        if rippleInsight {
            let rippleEvent = TimelineEvent(
                thread: name,
                type: "care_ripple_processed",
                payload: ["sourceThread": event.thread, "sourceType": event.type]
            )
            context.updateFromEvent(rippleEvent)
        }
        
        // Cap insights
        if recentInsights.count > 10 {
            recentInsights.removeFirst()
        }
    }
    
    // MARK: - Test / Debug helpers (for prototype, ThreadDetail, verification)
    
    func careSummary() -> String {
        let active = getActiveTasks().joined(separator: ", ")
        let high = getPendingHighPriorityTasks().joined(separator: ", ")
        let irls = irlSuggestions.prefix(2).joined(separator: " | ")
        return "CareKin[load:\(careLoadLevel)] Active[\(active.isEmpty ? "none" : active)] HighPrio[\(high.isEmpty ? "none" : high)] IRLs: \(irls) Insights:\(recentInsights.count) Logs:\(activityLog.count)"
    }
    
    func clearForTesting() {
        familyTasks.removeAll()
        taskPriorities.removeAll()
        taskDueDateStrings.removeAll()
        taskStatus.removeAll()
        careLoadLevel = "normal"
        irlSuggestions.removeAll()
        recentInsights.removeAll()
        activityLog.removeAll()
    }


    // Uniform .summary() for ThreadsOverviewView (delegates to detailed careSummary)
    func summary() -> String { return careSummary() }

}

// End of CareKinThread.
// All state and logic local-only in SwiftData. TimelineService ensures changes weave across One journey.
// See: TimelineService.swift (emit), LifeContext.swift (update/season), USER_JOURNEYS_ONEWEAVE.md (journeys 1+3),
// BasicSelfThread.swift & StewardshipThread.swift (patterns), ThreadDetailView.swift (usage).
// Example:
//   let care = CareKinThread()
//   care.addTask("School forms + dinner prep", priority: "high", service: svc, context: ctx)
//   let irl = care.suggestIRL(service: svc, context: ctx)
//   care.processEvent(selfGoalEvent, context: ctx, service: svc)
//   print(care.careSummary())
