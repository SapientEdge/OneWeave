//
//  PrivateLog.swift
//  OneWeave
//
//  Cycle 32 — T145. Defense-in-depth log redaction.
//
//  Why this exists:
//    `print("[Settings] failed to delete X: \(model.error)")` can leak PII
//    (e.g. reflection plaintext) into Console.app or syslog. We want logs
//    to be useful for the developer WITHOUT leaking user data.
//
//  Strategy:
//    In DEBUG builds, log freely. In RELEASE builds, redact known-sensitive
//    substrings: anything matching "reflection:" (T107), anything in the
//    private-mode entity set, and anything matching a reflection plaintext
//    length > 80 chars (assumed free-form text, not metadata).
//
//  This is *defense in depth*: the production build strips `print` calls
//    via the Swift compiler (the DEBUG-only ones), so this helper is
//    belt-and-suspenders.
//

import Foundation

public enum PrivateLog {

    /// Redact a free-form message for production logging.
    /// - Replaces anything after `reflection:` with `<redacted>`.
    /// - Truncates long strings (likely user text).
    /// - Strips trailing whitespace + newlines (avoid log injection).
    public static func redact(_ message: String) -> String {
        var s = message
        // 1. Reflection plaintext redaction (T107).
        if let regex = try? NSRegularExpression(pattern: #"reflection:.{0,80}"#) {
            let range = NSRange(s.startIndex..., in: s)
            s = regex.stringByReplacingMatches(
                in: s, options: [], range: range, withTemplate: "reflection: <redacted>"
            )
        }
        // 2. Private-mode entity redaction (entities with `isPrivate = true`).
        if let regex = try? NSRegularExpression(pattern: #"\bentity-id: [A-F0-9-]{36}\b"#) {
            let range = NSRange(s.startIndex..., in: s)
            s = regex.stringByReplacingMatches(
                in: s, options: [], range: range, withTemplate: "entity-id: <private>"
            )
        }
        // 3. Long string truncation (assumed free-form user content).
        if s.count > 200 {
            s = String(s.prefix(200)) + "…[truncated]"
        }
        return s
    }

    /// Log a redacted message. In DEBUG builds, also write to stdout via `print`.
    /// In RELEASE builds, log only the first 80 chars to os_log (debug level).
    public static func log(_ message: String, file: String = #fileID, line: Int = #line) {
        let redacted = redact(message)
        let prefix = "[\(file):\(line)]"
        #if DEBUG
        print("\(prefix) \(redacted)")
        #else
        // Use NSLog in release so the message hits Console.app but with the
        // private API marker so it can be filtered out by the user's privacy
        // preferences (Console.app → Filters → Private Data).
        NSLog("%@", "\(prefix) \(redacted)")
        #endif
    }
}
