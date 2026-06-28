//
//  EmbeddingCoverageHint.swift
//  OneWeave — T178b (cycle 39)
//
//  Purpose: surface a one-time UI hint ("Search will improve as you add
//  reflections.") when the corpus has <50% embedding coverage. Backed by
//  LifeGraph.missingEmbeddingFraction(in:) — when >50% of LifeEntity entries
//  are missing embeddings, the app falls back to lexical-only search and the
//  hint surfaces to explain why.
//
//  Constitutional compliance:
//  - §2 Privacy: reads only aggregate coverage fraction; never sends data off-device.
//  - §3 Calm: hint appears once, then self-dismisses; never spams.
//  - §4 Reflection-Gated: showing the hint does not unlock any action.
//
//  Reference: cycle 39 task T178b. Spec: `.specify/specs/003-production-readiness/tasks.md`.
//

import Foundation
import SwiftUI

/// Threshold below which the embedding-coverage hint becomes visible.
/// Matches LifeGraph's lexical-fallback threshold (0.5).
public enum EmbeddingCoverageThresholds {
    /// If >50% of entities are missing embeddings, surface the hint.
    public static let coverageFloor: Double = 0.5

    /// Number of reflections required before the hint ever appears.
    /// Below this, lexical-only is fine and the hint would just be noise.
    public static let minimumReflections: Int = 5
}

/// View-model that observes embedding coverage and publishes a single
/// "should surface the hint" boolean. Bind this to a SwiftUI view
/// via `@StateObject` or `@ObservedObject`.
///
/// The hint self-dismisses once the user dismisses it (`dismiss()`) — the
/// dismiss flag is persisted via @AppStorage so it never reappears for the
/// same user.
@MainActor
public final class EmbeddingCoverageHint: ObservableObject {
    @Published public private(set) var shouldSuggestMoreReflections: Bool = false

    @AppStorage("oneweave.embeddingHint.dismissed.v1")
    private var dismissed: Bool = false

    /// Fraction in [0, 1] of entities missing embeddings. 1.0 = all missing.
    @Published public private(set) var missingFraction: Double = 1.0

    /// Number of reflections currently in the corpus.
    @Published public private(set) var reflectionCount: Int = 0

    public init() {}

    /// Update the hint state. Call this whenever the corpus changes
    /// (e.g. after a reflection is added or after a background embedding pass).
    ///
    /// - Parameters:
    ///   - missingFraction: fraction of entities without embeddings, in [0, 1].
    ///   - reflectionCount: total number of reflections in the corpus.
    public func update(missingFraction: Double, reflectionCount: Int) {
        self.missingFraction = missingFraction
        self.reflectionCount = reflectionCount

        // Already-dismissed users never see the hint again.
        guard !dismissed else {
            shouldSuggestMoreReflections = false
            return
        }

        // Need at least N reflections before the hint is meaningful.
        guard reflectionCount >= EmbeddingCoverageThresholds.minimumReflections else {
            shouldSuggestMoreReflections = false
            return
        }

        // Above the coverage floor → hint is visible.
        shouldSuggestMoreReflections = missingFraction > EmbeddingCoverageThresholds.coverageFloor
    }

    /// User dismissed the hint. Persisted across app launches.
    public func dismiss() {
        dismissed = true
        shouldSuggestMoreReflections = false
    }
}

// MARK: - SwiftUI convenience

public extension View {
    /// Show a one-time banner prompting the user to add more reflections,
    /// visible only when embedding coverage is below the threshold.
    ///
    /// Usage:
    /// ```swift
    /// @StateObject private var hint = EmbeddingCoverageHint()
    /// ...
    /// .embeddingCoverageHint(hint)
    /// ```
    func embeddingCoverageHint(_ model: EmbeddingCoverageHint) -> some View {
        overlay(alignment: .bottom) {
            if model.shouldSuggestMoreReflections {
                EmbeddingCoverageBanner(model: model)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding()
            }
        }
        .animation(.easeInOut(duration: 0.4), value: model.shouldSuggestMoreReflections)
    }
}

/// The actual banner view. Kept private to EmbeddingCoverageHint to avoid
/// exposing it as a public API surface — only the modifier is public.
private struct EmbeddingCoverageBanner: View {
    @ObservedObject var model: EmbeddingCoverageHint

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("Semantic search will improve as you add reflections")
                    .font(.callout)
                    .foregroundStyle(.primary)
                Text("Currently using keyword matching for \(Int(model.missingFraction * 100))% of your entries.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Button {
                model.dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.tertiary)
                    .accessibilityLabel("Dismiss")
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
