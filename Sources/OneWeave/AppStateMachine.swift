import Foundation
import SwiftUI

enum AppState: String, Equatable, Codable, CaseIterable {
    case idle = "idle"
    case capturing = "capturing"
    case weaving = "weaving"
    case reflecting = "reflecting"
    case lowEnergy = "lowEnergy"
    case highFlow = "highFlow"
}

extension AppState {
    var displayName: String {
        switch self {
        case .idle: return "Idle / Settled"
        case .capturing: return "Capturing Input"
        case .weaving: return "Weaving Ripples"
        case .reflecting: return "Reflecting"
        case .lowEnergy: return "Low Energy"
        case .highFlow: return "High Flow"
        }
    }
    
    var color: Color {
        switch self {
        case .idle: return .gray
        case .capturing: return .blue
        case .weaving: return .indigo
        case .reflecting: return .teal
        case .lowEnergy: return .orange
        case .highFlow: return .green
        }
    }
    
    var systemImage: String {
        switch self {
        case .idle: return "pause.circle"
        case .capturing: return "text.cursor"
        case .weaving: return "arrow.triangle.2.circlepath"
        case .reflecting: return "brain.head.profile"
        case .lowEnergy: return "bolt.slash"
        case .highFlow: return "flame"
        }
    }
}

@Observable
final class AppStateMachine {
    var currentState: AppState = .idle
    
    func transition(on event: TimelineEvent, context: LifeContext) {
        let type = event.type.lowercased()
        let prev = currentState
        
        if type.contains("capture") || type.contains("quick") || type.contains("input") {
            currentState = .capturing
        } else if type.contains("weave") || type.contains("ripple") || type.contains("goal") || type.contains("habit") || type.contains("add") || type.contains("complete") || type.contains("task") || type.contains("story") {
            currentState = .weaving
        } else if type.contains("reflect") || type.contains("insight") || type.contains("review") || type.contains("legacy") {
            currentState = .reflecting
        } else if event.affectsEnergy && (type.contains("stress") || type.contains("leak") || type.contains("overwhelm") || type.contains("load") || type.contains("tired")) {
            currentState = .lowEnergy
        } else if type.contains("restore") || type.contains("rest") || type.contains("win") {
            currentState = .highFlow
        } else if prev == .lowEnergy && !event.affectsEnergy {
            currentState = .idle
        } else if (prev == .weaving || prev == .capturing) {
            currentState = .reflecting
        } else {
            currentState = event.affectsEnergy ? .weaving : .idle
        }
        
        if currentState != prev {
            // state change hook for haptics (consumed in UI)
        }
    }
    
    func startCapture(_ text: String) {
        currentState = .capturing
    }
    
    func reset() {
        currentState = .idle
    }
}