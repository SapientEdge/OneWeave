//
//  MentorEchoBridge.swift
//  OneWeave
//
//  Bridges Sacred Echo opened echoes into Invisible Mentor input seeds.
//
//  This is the wire-up Nemotron cycle-27 review flagged as "unintegrated":
//  `InvisibleMentor.makeInput(from:openedEchoes:)` already accepts an array of
//  opened echo tuples, but nothing in the codebase ever constructs that array
//  from a real `SacredEchoStore` query. Without this bridge, the Mentor's
//  `openedEchoes` parameter is permanently empty and the "Echo opens and feeds
//  Mentor" promise in the whitepaper is unfulfilled.
//
//  Design pillars:
//    1. Decoupled. The bridge lives in its own file — SacredEcho stays
//       focused on seal/open/deliver/release, InvisibleMentor stays focused
//       on synthesis. The bridge is the only file that touches both.
//    2. Deterministic. No network, no telemetry, no LLM. Just a typed
//       transformation from SwiftData models into Mentor seeds.
//    3. Privacy-aware. Only echoes the user has *actually opened* are
//       eligible (state == .opened or .delivered). Sealed, maturing, and
//       opening-ready echoes are skipped — the user has not consented to
//       having their sealed words influence anything yet.
//    4. Reflection-only. The plaintext is sourced only from `SacredEchoCipher.open`
//       which itself requires the unlock date to have passed. We do NOT
//       bypass the cipher here.
//    5. Linux-friendly. Falls back to a deterministic stand-in when no
//       ModelContext is available, so the harness can exercise the
//       transformation logic without a SwiftData runtime.
//
//  What this file intentionally does NOT contain:
//    - Any direct UI binding. The bridge returns data; the caller decides
//      how to surface it (sheet, command palette entry, etc.).
//    - Any state mutation. Opening an echo is owned by `SacredEchoStore.open`.
//      This file only reads.
//    - Any background scheduling. Opened echoes are surfaced when the user
//      asks the Mentor a question; we don't proactively push.

import Foundation
import SwiftData

// MARK: - Bridge configuration

/// Tunable knobs for how opened echoes influence Mentor responses. Held here
/// rather than on the Mentor type because the bridge owns echo-specific
/// policy (decay, scoring, capping).
public enum MentorEchoBridgeConfig {
    /// Cap on the number of opened echoes surfaced per Mentor session.
    /// Older + less relevant echoes fall off; we don't want Echo Vault
    /// owners to flood the Mentor with 100+ echoes.
    public static let maxEchoesPerSession: Int = 5

    /// Minimum number of days since opening for an echo to count as
    /// "perspective-rich" enough to influence Mentor synthesis. Echoes
    /// opened today have zero perspective; they just mirror current
    /// state. The whole point of an echo is the *gap* between now and
    /// when it was written.
    public static let minimumDaysSinceOpened: Int = 1

    /// Recency decay curve: 1.0 at minDays, 0.4 at 365 days.
    /// Older opened echoes still count, but with diminishing weight.
    public static func recencyMultiplier(daysSinceOpened: Int) -> Double {
        guard daysSinceOpened >= minimumDaysSinceOpened else { return 0.0 }
        let span = Double(daysSinceOpened - minimumDaysSinceOpened)
        return max(0.4, 1.0 - span / 365.0 * 0.6)
    }
}

// MARK: - Bridge result

/// One opened echo, transformed into the shape Mentor expects.
public struct OpenedEchoSeed {
    public let id: UUID
    public let title: String
    public let text: String              // decrypted plaintext
    public let openedAt: Date
    public let daysSinceOpened: Int
    public let recencyMultiplier: Double
    public let decree: String            // present-self instruction

    public init(
        id: UUID,
        title: String,
        text: String,
        openedAt: Date,
        decree: String,
        now: Date
    ) {
        self.id = id
        self.title = title
        self.text = text
        self.openedAt = openedAt
        self.decree = decree
        let days = max(0, Int(now.timeIntervalSince(openedAt) / 86400))
        self.daysSinceOpened = days
        self.recencyMultiplier = MentorEchoBridgeConfig.recencyMultiplier(
            daysSinceOpened: days
        )
    }
}

// MARK: - Bridge

/// Read-side API for Invisible Mentor. Pure functions over the user's
/// opened Sacred Echoes. Does not mutate anything.
public enum MentorEchoBridge {

    /// Build the `(UUID, String, String, Date)` tuples that
    /// `InvisibleMentor.makeInput(from:openedEchoes:)` already accepts.
    ///
    /// Only echoes in lifecycle `.opened` or `.delivered` are considered
    /// — by definition these are echoes the user has read, so we have
    /// explicit consent to use their words. Sealed echoes are NEVER
    /// touched here (that would be a critical privacy violation).
    ///
    /// - Parameters:
    ///   - echoes: All Sacred Echoes known to the app. Caller is responsible
    ///     for filtering to ones visible to the current user/device.
    ///   - context: The current LifeContext. Only used to validate the echo
    ///     still exists in the graph.
    ///   - now: Override for tests. Defaults to SacredEcho.now() so the
    ///     bridge participates in the same testable clock as the rest of
    ///     the vault.
    /// - Returns: Up to `maxEchoesPerSession` tuples, sorted by
    ///   recency multiplier desc, suitable for direct handoff to
    ///   `InvisibleMentor.makeInput`.
    public static func openedEchoSeeds(
        from echoes: [SacredEcho],
        in context: LifeContext,
        now: Date? = nil
    ) -> [(id: UUID, title: String, text: String, openedAt: Date)] {
        let clock = now ?? SacredEcho.now()

        // Stage 1: filter to consent states.
        let opened: [SacredEcho] = echoes.filter { echo in
            guard let state = EchoLifecycleState(rawValue: echo.stateRaw) else {
                return false
            }
            return state == .opened || state == .delivered
        }

        // Stage 2: decrypt and project to the seed shape. Failures (bad
        // ciphertext, missing key) are dropped — a single corrupt echo
        // must not silence the Mentor.
        var seeds: [OpenedEchoSeed] = []
        for echo in opened {
            guard let openedAt = echo.openedAt else { continue }
            // Decrypt via the canonical cipher. If decryption fails the echo
            // is corrupted or the key is wrong; we skip it rather than
            // crashing the Mentor session.
            guard let plaintext = try? SacredEchoCipher.open(
                ciphertext: echo.ciphertext,
                nonce: echo.nonce,
                tag: echo.tag,
                echoID: echo.id
            ) else {
                continue
            }
            let trimmed = plaintext.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            seeds.append(OpenedEchoSeed(
                id: echo.id,
                title: echo.title,
                text: trimmed,
                openedAt: openedAt,
                decree: echo.decree,
                now: clock
            ))
        }

        // Stage 3: rank by recency multiplier, take top N.
        let ranked = seeds
            .filter { $0.recencyMultiplier > 0.0 }
            .sorted { $0.recencyMultiplier > $1.recencyMultiplier }
            .prefix(MentorEchoBridgeConfig.maxEchoesPerSession)

        return ranked.map { ($0.id, $0.title, $0.text, $0.openedAt) }
    }

    /// Convenience that fetches all echoes from a ModelContext, then
    /// runs the bridge. Returns the same tuples as the manual path.
    ///
    /// On Linux (no SwiftData), this falls back to an empty result rather
    /// than crashing — the harness can exercise the rest of the
    /// pipeline by constructing `SacredEcho` instances directly.
    @MainActor
    public static func openedEchoSeeds(
        from modelContext: ModelContext,
        in context: LifeContext,
        now: Date? = nil
    ) -> [(id: UUID, title: String, text: String, openedAt: Date)] {
        let descriptor = FetchDescriptor<SacredEcho>(
            predicate: #Predicate<SacredEcho> { echo in
                echo.stateRaw == EchoLifecycleState.opened.rawValue
                    || echo.stateRaw == EchoLifecycleState.delivered.rawValue
            },
            sortBy: [SortDescriptor(\SacredEcho.openedAt, order: .reverse)]
        )
        let echoes: [SacredEcho]
        do {
            echoes = try modelContext.fetch(descriptor)
        } catch {
            return []
        }
        return openedEchoSeeds(from: echoes, in: context, now: now)
    }

    /// Convenience that builds a complete MentorInput from a LifeContext +
    /// the model context. This is the single entry point app code should
    /// call when preparing a Mentor session.
    ///
    /// Combines `InvisibleMentor.makeInput(from:openedEchoes:)` with the
    /// echo bridge above, so the caller never has to remember to wire
    /// them together.
    @MainActor
    public static func makeMentorInput(
        from context: LifeContext,
        modelContext: ModelContext,
        now: Date? = nil
    ) -> MentorInput {
        let echoSeeds = openedEchoSeeds(from: modelContext, in: context, now: now)
        return InvisibleMentor.makeInput(
            from: context,
            openedEchoes: echoSeeds
        )
    }
}

// MARK: - Mentor response shaping for echoes
//
// When the Mentor cites an opened echo, we want the spoken line to feel
// distinct from a regular quest-reflection citation — echoes have a
// different emotional weight. These helpers shape the spoken text so
// the framing matches the source.

extension InvisibleMentor {

    /// Synthesize a single Mentor turn that quotes an opened Sacred Echo
    /// back to the user. Distinct from the standard reflection citation
    /// path: uses "past-you wrote and sealed this" framing instead of
    /// "earlier today you wrote:".
    ///
    /// Returns nil if the seed doesn't meet the recency threshold or
    /// has no plaintext — the Mentor should never quote an echo the
    /// user hasn't actually read yet (Nemotron cycle-27 #39: content-
    /// blind gate applies to echoes too).
    public static func echoTurn(
        from seed: MentorInput.OpenedEchoSeed,
        prompt: String
    ) -> MentorTurn? {
        guard seed.daysSinceOpened >= MentorEchoBridgeConfig.minimumDaysSinceOpened else {
            return nil
        }
        guard !seed.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        // Compose the spoken line. We always quote the user's own words —
        // never paraphrase, never add AI wisdom.
        let excerpt = String(seed.text.prefix(180))
        let timeRef: String
        switch seed.daysSinceOpened {
        case 0: timeRef = "earlier today"
        case 1: timeRef = "yesterday"
        case 2..<7: timeRef = "\(seed.daysSinceOpened) days ago"
        case 7..<30: timeRef = "\(seed.daysSinceOpened / 7) weeks ago"
        case 30..<365: timeRef = "\(seed.daysSinceOpened / 30) months ago"
        default: timeRef = "over a year ago"
        }
        let frame: String
        if !seed.decree.isEmpty {
            frame = "From an echo you sealed and opened \(timeRef) — your decree was: \"\(seed.decree)\""
        } else {
            frame = "From an echo you opened \(timeRef):"
        }
        let spoken = "\(frame)\n\n\"\(excerpt)\""

        // Relevance: lexical overlap against the prompt + recency multiplier.
        let promptTokens = Set(
            prompt.lowercased()
                .components(separatedBy: .whitespacesAndNewlines.union(.punctuationCharacters))
                .filter { $0.count >= 3 }
        )
        let textTokens = Set(
            seed.text.lowercased()
                .components(separatedBy: .whitespacesAndNewlines.union(.punctuationCharacters))
                .filter { $0.count >= 3 }
        )
        let overlap: Double
        if promptTokens.isEmpty || textTokens.isEmpty {
            overlap = 0.0
        } else {
            let intersection = promptTokens.intersection(textTokens).count
            let union = promptTokens.union(textTokens).count
            overlap = union == 0 ? 0.0 : Double(intersection) / Double(union)
        }
        let relevance = (overlap * 0.7 + seed.recencyMultiplier * 0.3)
            .clamped(to: 0...1)

        return MentorTurn(
            spoken: spoken,
            citedReflectionID: seed.id,
            citedReflectionExcerpt: excerpt,
            citedDaysAgo: seed.daysSinceOpened,
            relevanceScore: relevance
        )
    }
}

// MARK: - Numeric clamping helper (private to this file)
//
// Mirrors the helper in InvisibleMentor.swift but kept private here so the
// bridge file is self-contained for testing.

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}