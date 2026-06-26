import SwiftData
import Foundation

// Enhanced BasicSelfThread per OneWeave spec and USER_JOURNEYS_ONEWEAVE.md.
// Self thread: habits/goals, micro-learning, analog intent, energy management.
// 
// Features:
// - Full habit tracking with completion dates and streak calculation (persisted).
// - Activity logging (local).
// - Energy-aware suggestions (local on-device logic, e.g. low energy -> simplify).
// - Real processEvent logic for cross-thread ripples (e.g. CareKin care load -> protect Self habits).
// - EVERY meaningful action (add, log, capture) calls TimelineService.emitEvent + updates LifeContext.
// - Aligns with journeys: new goal in busy season affects energy=true + sets "High Care Load".
// - Testable via habitSummary(), clearForTesting(), direct method calls in prototype.
// 
// Privacy / global best practices: local-only (SwiftData @Model), no-training (no external calls, 
// on-device rule-based only.
// All data stays on device. References constitution: calm, interconnected, privacy-first.

@Model
final class BasicSelfThread: ThreadProtocol {
    var name: String = "Self"
    
    // Core persisted state for habits
    var habits: [String] = []
    
    // Habit persistence with dates (string ISO for SwiftData compatibility): habitName -> ["2026-06-25", ...]
    var habitCompletionDateStrings: [String: [String]] = [:]
    
    var recentGoals: [String] = []
    var recentInsights: [String] = []
    
    // Energy-aware
    var energyAwareSuggestions: [String] = []
    
    // Local logging (compacted, private)
    var activityLog: [String] = []
    
    // Computed/persisted streaks
    var currentStreaks: [String: Int] = [:]
    
    init() {}
    
    // MARK: - Habit & Goal APIs (call service + context for EVERY meaningful action)
    
    func addHabit(_ habit: String, service: TimelineService? = nil, context: LifeContext? = nil) {
        guard !habit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let cleanHabit = habit.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !habits.contains(cleanHabit) {
            habits.append(cleanHabit)
            habitCompletionDateStrings[cleanHabit] = []
            currentStreaks[cleanHabit] = 0
        }
        
        let payload: [String: String] = ["habit": cleanHabit]
        let event = TimelineEvent(thread: name, type: "habit_added", payload: payload)
        event.affectsEnergy = true  // habits cost/affect energy (spec)
        
        logActivity("Added habit: \(cleanHabit)")
        
        if let svc = service {
            svc.emitEvent(
                thread: name,
                type: "habit_added",
                payload: payload,
                affectsEnergy: true,
                linkedThreads: ["Stewardship", "CareKin"]
            )
        }
        
        if let ctx = context {
            ctx.updateFromEvent(event)
        }
        
        updateEnergyAwareSuggestions(using: context)
    }
    
    func addGoal(_ goal: String, service: TimelineService? = nil, context: LifeContext? = nil) {
        guard !goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let cleanGoal = goal.trimmingCharacters(in: .whitespacesAndNewlines)
        
        recentGoals.append(cleanGoal)
        
        let payload: [String: String] = ["goal": cleanGoal]
        let event = TimelineEvent(thread: name, type: "goal_added", payload: payload)
        event.affectsEnergy = true
        
        logActivity("New goal: \(cleanGoal)")
        
        if let svc = service {
            svc.emitEvent(
                thread: name,
                type: "goal_added",
                payload: payload,
                affectsEnergy: true,
                linkedThreads: ["Stewardship", "CareKin", "Meaning"]
            )
        }
        
        if let ctx = context {
            ctx.updateFromEvent(event)
            // Per spec USER_JOURNEYS: new goal affects energy + care load
            ctx.values["focus"] = cleanGoal
            ctx.values["season"] = "High Care Load"
            if !ctx.priorities.contains(cleanGoal) {
                ctx.priorities.append(cleanGoal)
            }
        }
        
        recentInsights.append("Goal added: \(cleanGoal). Energy impact + care ripple active.")
        updateEnergyAwareSuggestions(using: context)
    }
    
    func logHabitCompletion(_ habit: String, on date: Date = Date(), service: TimelineService? = nil, context: LifeContext? = nil) {
        guard habits.contains(habit) else { return }
        
        let dateStr = isoDateString(for: date)
        var dates = habitCompletionDateStrings[habit] ?? []
        if !dates.contains(dateStr) {
            dates.append(dateStr)
            dates.sort()
            habitCompletionDateStrings[habit] = dates
        }
        
        let streak = calculateCurrentStreak(for: habit)
        currentStreaks[habit] = streak
        
        let payload: [String: String] = ["habit": habit, "date": dateStr, "streak": "\(streak)"]
        let event = TimelineEvent(thread: name, type: "habit_completed", payload: payload)
        event.affectsEnergy = false  // completion is restorative
        
        logActivity("Completed \(habit) (streak: \(streak))")
        
        if let svc = service {
            svc.emitEvent(
                thread: name,
                type: "habit_completed",
                payload: payload,
                affectsEnergy: false,
                linkedThreads: ["Meaning"]
            )
        }
        
        if let ctx = context {
            ctx.updateFromEvent(event)
            if streak >= 7 {
                ctx.energyProfile = .high
            }
        }
        
        updateEnergyAwareSuggestions(using: context)
    }
    
    // MARK: - Streak & Date helpers (local computation)
    
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
    
    private func calculateCurrentStreak(for habit: String) -> Int {
        guard let dateStrs = habitCompletionDateStrings[habit], !dateStrs.isEmpty else { return 0 }
        let sorted = dateStrs.compactMap { dateFromISO($0) }.sorted(by: >)
        guard !sorted.isEmpty else { return 0 }
        
        var streak = 1
        var current = sorted[0]
        let cal = Calendar.current
        
        for i in 1..<sorted.count {
            let prev = sorted[i]
            if let diff = cal.dateComponents([.day], from: prev, to: current).day, diff == 1 {
                streak += 1
                current = prev
            } else if diff == 0 {
                continue
            } else {
                break
            }
        }
        return streak
    }
    
    func getStreak(for habit: String) -> Int {
        currentStreaks[habit] ?? 0
    }
    
    func getCompletionDates(for habit: String) -> [Date] {
        (habitCompletionDateStrings[habit] ?? []).compactMap { dateFromISO($0) }
    }
    
    // MARK: - Energy-aware suggestions (local, event-driven, per journeys)
    
    func updateEnergyAwareSuggestions(using context: LifeContext? = nil) {
        energyAwareSuggestions.removeAll(keepingCapacity: true)
        
        let energy = context?.energyProfile ?? .normal
        let season = context?.values["season"] ?? "balanced"
        let focus = context?.values["focus"] ?? recentGoals.last ?? "current habits"
        
        if energy == .low {
            energyAwareSuggestions.append("Low energy detected. Simplify to 1-2 core habits only this week.")
            energyAwareSuggestions.append("Protect \(focus). Defer non-essential.")
        } else if energy == .high {
            energyAwareSuggestions.append("High energy: build on \(focus) and add micro analog habit.")
        } else {
            energyAwareSuggestions.append("Balanced energy. Maintain streaks for \(focus).")
        }
        
        if season.contains("Care") || season.contains("High Care Load") {
            energyAwareSuggestions.append("High Care Load season — protect energy for Self. Prioritize family IRL over extra digital habits.")
        }
        
        // Avoid dup insights
        if let first = energyAwareSuggestions.first, !recentInsights.contains(first) {
            recentInsights.append(first)
            if recentInsights.count > 8 { recentInsights.removeFirst() }
        }
    }
    
    func suggestEnergyAwareHabit(context: LifeContext) -> String {
        updateEnergyAwareSuggestions(using: context)
        return energyAwareSuggestions.first ?? "One small consistent habit today."
    }
    
    // MARK: - Logging
    
    func logActivity(_ note: String) {
        let ts = Date().formatted(date: .omitted, time: .shortened)
        activityLog.append("[\(ts)] \(note)")
        if activityLog.count > 25 {
            activityLog.removeFirst()
        }
    }
    
    // MARK: - Real processEvent for ripples (spec: event-driven interconnection)
    
    func processEvent(_ event: TimelineEvent, context: LifeContext, service: TimelineService) {
        logActivity("Ripple received: \(event.type) from \(event.thread)")
        
        var rippleInsight = false
        
        if event.thread == "CareKin" && (event.type.contains("task") || event.type.contains("care") || event.type.contains("added")) {
            let msg = "Care load detected — protect energy for habits."
            if !recentInsights.contains(msg) {
                recentInsights.append(msg)
            }
            rippleInsight = true
            
            if context.energyProfile == .low || (context.values["season"]?.contains("Care") ?? false) {
                energyAwareSuggestions.append("CareKin ripple: pause or simplify 1 habit to protect energy.")
                // Call service for ripple (meaningful action)
                service.emitEvent(
                    thread: name,
                    type: "habit_protection",
                    payload: ["reason": "care_load", "focus": context.values["focus"] ?? "habits"],
                    affectsEnergy: false,
                    linkedThreads: ["CareKin"]
                )
            }
        } else if event.thread == "Stewardship" && (event.type.contains("leak") || event.type.contains("subscription")) {
            recentInsights.append("Stewardship leak — resources freed. Redirect to Self goal or analog time.")
            rippleInsight = true
        } else if event.thread == "Meaning" {
            recentInsights.append("Meaning progress — connect Self habit streaks to legacy story.")
            rippleInsight = true
        } else if event.type.contains("goal") && event.thread != name {
            logActivity("Cross-thread goal ripple noted from \(event.thread).")
        }
        
        // Always refresh energy suggestions on ripple
        updateEnergyAwareSuggestions(using: context)
        
        if rippleInsight {
            // Update context with the ripple processing (local agg)
            let rippleEvent = TimelineEvent(
                thread: name,
                type: "self_ripple",
                payload: ["sourceThread": event.thread, "sourceType": event.type]
            )
            context.updateFromEvent(rippleEvent)
        }
    }
    
    // MARK: - Micro-learning & Analog intent (spec Self description)
    
    func logMicroLearning(_ topic: String, service: TimelineService? = nil, context: LifeContext? = nil) {
        guard !topic.isEmpty else { return }
        let payload: [String: String] = ["topic": topic]
        let event = TimelineEvent(thread: name, type: "micro_learning", payload: payload)
        event.affectsEnergy = false
        
        logActivity("Micro-learning logged: \(topic)")
        
        if let svc = service {
            svc.emitEvent(
                thread: name,
                type: "micro_learning",
                payload: payload,
                affectsEnergy: false,
                linkedThreads: ["Meaning"]
            )
        }
        if let ctx = context {
            ctx.updateFromEvent(event)
        }
    }
    
    func captureAnalogIntent(_ intent: String, service: TimelineService? = nil, context: LifeContext? = nil) {
        guard !intent.isEmpty else { return }
        let payload: [String: String] = ["intent": intent]
        let event = TimelineEvent(thread: name, type: "analog_intent", payload: payload)
        event.affectsEnergy = false
        
        logActivity("Analog intent: \(intent)")
        
        if let svc = service {
            svc.emitEvent(
                thread: name,
                type: "analog_intent",
                payload: payload,
                affectsEnergy: false,
                linkedThreads: ["CareKin", "Meaning"]
            )
        }
        if let ctx = context {
            ctx.updateFromEvent(event)
        }
        
        recentInsights.append("Prioritize IRL: \(intent)")
        if recentInsights.count > 8 { recentInsights.removeFirst() }
    }
    
    // MARK: - Test helpers for prototype / unit testing
    
    func habitSummary() -> String {
        let h = habits.isEmpty ? "none" : habits.joined(separator: ", ")
        let s = currentStreaks.isEmpty ? "none" : currentStreaks.map { "\($0.key):\($0.value)" }.joined(separator: " ")
        return "Habits[\(h)] Streaks[\(s)] Logs:\(activityLog.count) Insights:\(recentInsights.count)"
    }
    
    func clearForTesting() {
        // Supports resetting in prototype demos without full model delete
        habits.removeAll()
        habitCompletionDateStrings.removeAll()
        recentGoals.removeAll()
        recentInsights.removeAll()
        energyAwareSuggestions.removeAll()
        activityLog.removeAll()
        currentStreaks.removeAll()
    }


    // Uniform .summary() for ThreadsOverviewView (delegates to detailed habitSummary)
    func summary() -> String { return habitSummary() }

}

// End of BasicSelfThread. All operations local-only. 
// See spec.md, USER_JOURNEYS_ONEWEAVE.md, TimelineService.swift, LifeContext.swift for integration.
// Example testable usage in prototype:
//   let selfThread = BasicSelfThread()
//   modelContext.insert(selfThread)
//   selfThread.addGoal("half-marathon training", service: svc, context: ctx)
//   // then later: selfThread.processEvent(careEvent, context: ctx, service: svc)
//   print(selfThread.habitSummary())
