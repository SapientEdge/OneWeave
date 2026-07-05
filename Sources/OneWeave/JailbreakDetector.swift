//
//  JailbreakDetector.swift
//  OneWeave
//
//  Cycle 32 — T144. Defense-in-depth jailbreak detection.
//
//  DESIGN INTENT (Constitution §2: Privacy-First, Zero-Trust):
//    This is *defense in depth*, not a security boundary. OneWeave must not
//    hard-block jailbroken users — they may have legitimate privacy reasons
//    (e.g. running iOS hardening tweaks). We surface a non-blocking warning
//    and never silently increase privilege on a jailbroken device.
//
//  Detection strategy (Linux-portable, no `Security` framework calls):
//    1. Check for common jailbreak file/directory indicators.
//    2. Check whether a known jailbreak URL scheme is registered.
//    3. Check whether a non-sandboxed write to /private succeeds.
//
//  On iOS this list is more comprehensive; on Linux dev harness it returns
//  `false` (Linux is not jailbroken by our definition).
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

public enum JailbreakIndicator: String, CaseIterable, Codable {
    case sandboxEscape          = "/private/var/lib/apt"
    case cydiaSubstrate         = "/Library/MobileSubstrate/MobileSubstrate.dylib"
    case cydiaPackageList       = "/var/lib/cydia"
    case cydiaScheme            = "cydia://"
    case fakeSandboxWrite       = "/private/jailbreak-test-write"
    case substituteHook         = "/usr/lib/substitute"
    case fridaServer            = "/usr/sbin/frida-server"
    case binBash                = "/bin/bash"
    case usrSBin                = "/usr/sbin/sshd"
}

public struct JailbreakReport: Codable, Equatable {
    public let detectedAt: Date
    public let indicators: [String]
    public let confidence: Double

    public var isJailbroken: Bool { !indicators.isEmpty }
    public var headlineSummary: String {
        if !isJailbroken { return "Device appears unmodified." }
        return "Detected \(indicators.count) jailbreak indicator(s). Privacy-first mode still active; some advanced features may show a warning."
    }
}

public enum JailbreakDetector {

    /// Run a fast (≤10 ms) check. Returns a report. Never throws.
    /// On iOS, also check the `cydia://` URL scheme (UIApplication.canOpenURL).
    /// On macOS Catalyst or Linux dev harness, return an empty report.
    public static func check() -> JailbreakReport {
        #if !canImport(UIKit)
        // macOS Catalyst / Linux dev harness — not jailbroken by our definition.
        return JailbreakReport(detectedAt: Date(), indicators: [], confidence: 0.0)
        #else
        var hits: [String] = []

        // 1. File-system indicators (the classic set; cheap, fast).
        let fm = FileManager.default
        for path in [
            JailbreakIndicator.sandboxEscape.rawValue,
            JailbreakIndicator.cydiaSubstrate.rawValue,
            JailbreakIndicator.cydiaPackageList.rawValue,
            JailbreakIndicator.substituteHook.rawValue,
            JailbreakIndicator.fridaServer.rawValue,
            JailbreakIndicator.binBash.rawValue,
            JailbreakIndicator.usrSBin.rawValue
        ] {
            if fm.fileExists(atPath: path) { hits.append(path) }
        }

        // 2. Sandbox-escape write attempt (a non-jailbroken device cannot write
        //    outside the app's sandbox; a jailbroken device may allow it).
        let testPath = JailbreakIndicator.fakeSandboxWrite.rawValue
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            // Write succeeded — sandbox escape is possible.
            hits.append(testPath)
            try? fm.removeItem(atPath: testPath)
        } catch {
            // Write failed — sandbox intact. No indicator.
        }

        // 3. URL-scheme probe for Cydia. Wrapped in a check so the warning
        //    shows up but does not crash on devices where canOpenURL is
        //    restricted by entitlements.
        if let url = URL(string: JailbreakIndicator.cydiaScheme.rawValue),
           UIApplication.shared.canOpenURL(url) {
            hits.append(JailbreakIndicator.cydiaScheme.rawValue)
        }

        // Confidence is a coarse bucket:
        //   0 indicators → 0.0
        //   1 indicator  → 0.6
        //   2+ indicators → 0.9
        let confidence: Double
        switch hits.count {
        case 0: confidence = 0.0
        case 1: confidence = 0.6
        default: confidence = 0.9
        }
        return JailbreakReport(detectedAt: Date(), indicators: hits, confidence: confidence)
        #endif
    }

    /// Convenience: returns just the boolean. For SettingsView surface.
    public static var isJailbroken: Bool {
        check().isJailbroken
    }
}
