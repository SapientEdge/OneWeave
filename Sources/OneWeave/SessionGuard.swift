//
//  SessionGuard.swift
//  OneWeave
//
//  Cycle 32 — T140/T141. Anti-addictive session timer + off-ramp helper.
//
//  Design intent (Constitution §1: "calm, anti-addictive"):
//    - 10-minute soft warning: a non-blocking sheet suggests a break.
//    - The user can dismiss and continue. This is *not* a hard limit.
//    - 30-minute hard off-ramp: surface a more prominent "you've been here
//      a while" moment; user can leave the app, take a breath, or continue.
//    - These gates exist on every entry to the app so the user can opt out
//      via a per-app toggle (default ON).
//
//  Storage: per-app, in UserDefaults under `sessionGuardEnabled` (Bool).
//  Reset: at scenePhase transitions (.background → resets timer).
//

import SwiftUI

@MainActor
public final class SessionGuard: ObservableObject {
    public static let shared = SessionGuard()

    @AppStorage("sessionGuardEnabled") public var enabled: Bool = true
    @AppStorage("sessionGuardSoftShownAt") private var softShownAt: Double = 0
    @AppStorage("sessionGuardHardShownAt") private var hardShownAt: Double = 0

    /// Tick interval — 30s is enough granularity for a 10-minute gate.
    public static let tickInterval: TimeInterval = 30
    /// Soft warning at 10 minutes of continuous foreground time.
    public static let softThreshold: TimeInterval = 10 * 60
    /// Hard off-ramp suggestion at 30 minutes.
    public static let hardThreshold: TimeInterval = 30 * 60

    @Published public var showSoftWarning: Bool = false
    @Published public var showHardOffRamp: Bool = false
    @Published public var elapsedMinutes: Int = 0

    private var timer: Timer?
    private var sessionStartedAt: Date?

    public init() {}

    /// Start the timer when the app becomes active.
    public func startSession() {
        guard enabled else { return }
        sessionStartedAt = Date()
        softShownAt = 0
        hardShownAt = 0
        startTimer()
    }

    /// Reset the timer when the app goes to background.
    public func endSession() {
        stopTimer()
        sessionStartedAt = nil
        showSoftWarning = false
        showHardOffRamp = false
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(
            withTimeInterval: Self.tickInterval, repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        tick()
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard let started = sessionStartedAt else { return }
        let elapsed = Date().timeIntervalSince(started)
        elapsedMinutes = Int(elapsed / 60)

        // Soft warning: fire once per session at 10 minutes.
        if elapsed >= Self.softThreshold && softShownAt == 0 {
            showSoftWarning = true
            softShownAt = started.timeIntervalSince1970
        }
        // Hard off-ramp: fire once per session at 30 minutes.
        if elapsed >= Self.hardThreshold && hardShownAt == 0 {
            showHardOffRamp = true
            hardShownAt = started.timeIntervalSince1970
        }
    }

    /// User dismissed soft warning — reset for next session.
    public func dismissSoft() {
        showSoftWarning = false
    }

    /// User took the hard off-ramp — end session.
    public func takeHardOffRamp() {
        endSession()
    }

    /// User chose to continue past the hard off-ramp — suppress for this session.
    public func dismissHard() {
        showHardOffRamp = false
    }
}

// MARK: - SwiftUI surfaces

public struct SessionSoftWarningView: View {
    @ObservedObject var guard: SessionGuard = .shared
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "leaf")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("You've been weaving for a bit")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("This is a gentle reminder, not a rule. Take a breath if you'd like — or continue.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                Button("Take a breath") {
                    guard.endSession()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)

                Button("Keep weaving") {
                    guard.dismissSoft()
                    dismiss()
                }
            }
        }
        .padding(40)
        .presentationDetents([.medium])
    }
}

public struct SessionHardOffRampView: View {
    @ObservedObject var guard: SessionGuard = .shared
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "moon.stars")
                .font(.system(size: 72))
                .foregroundStyle(.indigo)

            Text("You've been here a while")
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text("It's been 30 minutes of continuous weaving. OneWeave is here whenever you want to come back — but the rest of your life is too.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 12) {
                Button("Step away") {
                    guard.takeHardOffRamp()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)

                Button("Continue (this session)") {
                    guard.dismissHard()
                    dismiss()
                }
            }
        }
        .padding(40)
        .presentationDetents([.large])
    }
}
