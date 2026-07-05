// ReflectionGate.swift (cycle 30, T079)
// Centralized policy object for the reflection gate. Consolidates the scattered
// "non-empty reflection" checks across completeQuest, changeSeason, SacredEcho,
// FamilyPod exit, and CommandPalette. Constitution #4: "Any action that produces
// lasting consequence ... requires a non-empty reflectionText from the user."
//
// Why centralized: the 20-char minimum was inconsistent across call sites (T075
// fixed completeQuest but FamilyPod had its own constant). Future: minimum-length
// per action-type, anti-bypass entropy check (T079 follow-up).

import Foundation

public enum ReflectionGate {

    /// Minimum character length for "full reward" actions (quest complete,
    /// season transition, decision commit). Below this, partial reward only.
    /// Mirrors FamilyPod.minExitReflectionChars (20). Constitution §4 + §5.
    public static let minCharsForFullReward = 20

    /// Validates reflection text for an action. Returns the trimmed string on
    /// success, throws on empty input.
    public enum GateError: Error, LocalizedError {
        case emptyReflection
        case tooShort(got: Int, min: Int)

        public var errorDescription: String? {
            switch self {
            case .emptyReflection:
                return "An echo needs words. Write a reflection before sealing."
            case .tooShort(let got, let min):
                return "Reflection too short (\(got)/\(min) chars). Pause and write a few more."
            }
        }
    }

    /// Validate that the reflection is non-empty after trimming.
    /// Throws `GateError.emptyReflection` if empty.
    public static func validateNonEmpty(_ text: String, context: String = "action") throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw GateError.emptyReflection
        }
        return trimmed
    }

    /// Validate non-empty + minimum length. Used by completeQuest, changeSeason,
    /// and any other "full reward" path.
    public static func validateForFullReward(_ text: String, context: String = "action") throws -> String {
        let trimmed = try validateNonEmpty(text, context: context)
        guard trimmed.count >= minCharsForFullReward else {
            throw GateError.tooShort(got: trimmed.count, min: minCharsForFullReward)
        }
        return trimmed
    }

    /// Anti-bypass entropy check (future T079). Returns false if the reflection
    /// is "aaaaa..." (low entropy = gaming the gate). Shannon entropy < 2.5 bits/char
    /// should be rejected for full reward. Linux-mirrored in
    /// `.research/validate_reflection_gate_policy.py`.
    public static func passesEntropyCheck(_ text: String, threshold: Double = 2.5) -> Bool {
        guard !text.isEmpty else { return false }
        var freq: [Character: Int] = [:]
        for c in text { freq[c, default: 0] += 1 }
        let len = Double(text.count)
        let entropy = freq.values.reduce(0.0) { acc, count in
            let p = Double(count) / len
            return acc - p * (log(p) / log(2.0))
        }
        return entropy >= threshold
    }
}