import Foundation
import SwiftData

@Model
final class StewardshipThread: Thread {
    var name: String = "Stewardship"
    var subscriptions: [String] = []
    var leaks: [String] = []
    var subscriptionMeta: [String] = [] // "cost:service"
    var recentInsights: [String] = []
    var totalPotentialSavings: Double = 0.0
    
    init() {
        // Start clean
    }
    
    func addSubscription(_ name: String, cost: Double, service: TimelineService? = nil, context: LifeContext? = nil) {
        subscriptions.append(name)
        subscriptionMeta.append("\(cost):\(name)")
        recentInsights.append("Added subscription: \(name) at $\(cost)/mo")
        
        if let ctx = context, let svc = service {
            svc.emitEvent(thread: "Stewardship", type: "subscription_added", payload: ["sub": name, "cost": "\(cost)"], affectsEnergy: false, linkedThreads: ["Self", "Meaning"])
            ctx.updateFromEvent(TimelineEvent(thread: "Stewardship", type: "subscription_added", payload: ["sub": name]))
        }
    }
    
    func detectLeak(serviceName: String, reason: String, savingsAmount: Double = 0.0, service: TimelineService? = nil, context: LifeContext? = nil) {
        leaks.append(serviceName)
        let actualSavings = savingsAmount > 0 ? savingsAmount : calculatePotentialSavings()
        let savingsNote = actualSavings > 0 ? "Potential savings: $\(actualSavings)/mo (annual $\(actualSavings*12))." : ""
        let insight = "Leak detected: \(serviceName) (\(reason)). \(savingsNote) \(suggestSavingsRedirect(savingsAmount: actualSavings))"
        recentInsights.append(insight)
        
        if let ctx = context, let svc = service {
            svc.emitEvent(
                thread: "Stewardship",
                type: "leak_detected",
                payload: ["service": serviceName, "reason": reason],
                affectsEnergy: false,
                linkedThreads: ["Meaning", "CareKin", "Self"]
            )
            ctx.updateFromEvent(TimelineEvent(thread: "Stewardship", type: "leak_detected", payload: ["service": serviceName]))
        }
        
        // Full detection: also trigger analysis if many subs
        if subscriptions.count > 1 {
            let potentials = analyzeForLeaks()
            if !potentials.isEmpty {
                recentInsights.append("Additional leak candidates from analysis: \(potentials.joined(separator: ", "))")
            }
        }
    }
    
    /// Fully implemented leak detection analysis (heuristic/full scan).
    func analyzeForLeaks() -> [String] {
        var candidates: [String] = []
        for (i, sub) in subscriptions.enumerated() {
            let lower = sub.lowercased()
            var cost: Double = 0
            if i < subscriptionMeta.count {
                cost = Double(subscriptionMeta[i].components(separatedBy: ":").first ?? "0") ?? 0
            }
            if leaks.contains(sub) {
                candidates.append("\(sub) (already flagged)")
                continue
            }
            if lower.contains("unused") || lower.contains("trial") || lower.contains("temp") || lower.contains("old") {
                candidates.append(sub)
            } else if cost > 15 && subscriptions.count > 4 {
                candidates.append("\(sub) (high cost candidate)")
            }
        }
        if candidates.isEmpty && !subscriptions.isEmpty {
            candidates.append("Review top: \(subscriptions.prefix(2).joined(separator: ", ")) for usage")
        }
        return candidates
    }
    
    func calculatePotentialSavings() -> Double {
        return totalPotentialSavings
    }
    
    func suggestSavingsRedirect(savingsAmount: Double = 0.0, target: String = "Self/Care/Meaning") -> String {
        let amt = savingsAmount > 0 ? "$\(savingsAmount)/mo " : ""
        return "Redirect \(amt)to \(target) for better energy/legacy."
    }
    
    func summary() -> String {
        if leaks.isEmpty && subscriptions.isEmpty {
            return "No subs or leaks tracked yet."
        }
        return "Subs: \(subscriptions.count), Leaks: \(leaks.count), Potential savings: $\(calculatePotentialSavings())"
    }
    
    func clearForTesting() {
        subscriptions.removeAll()
        leaks.removeAll()
        subscriptionMeta.removeAll()
        recentInsights.removeAll()
        totalPotentialSavings = 0
    }
    
    func processEvent(_ event: TimelineEvent, context: LifeContext, service: TimelineService) {
        if event.thread == "Self" && event.type.contains("habit") {
            // Self win can suggest redirect
            if !leaks.isEmpty {
                recentInsights.append("Self momentum detected — consider redirecting from a leak.")
            }
        }
    }
    
    func defaultRealWorldBridge(for event: TimelineEvent) -> String {
        return "Review your subscriptions this week and cancel one unused service to free resources for Meaning or Care."
    }
}