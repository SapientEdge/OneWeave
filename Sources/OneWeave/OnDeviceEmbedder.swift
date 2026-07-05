//
//  OnDeviceEmbedder.swift
//  OneWeave
//
//  Cycle 39 / T172 — on-device sentence embeddings via NaturalLanguage.NLEmbedding.
//
//  Constitutional commitment (constitution.md §2 + §3):
//    - Embeddings are computed LOCALLY. No network call. No telemetry.
//      `NLEmbedding.sentenceEmbedding(for: .english)` ships with iOS 13+
//      and macOS 10.15+. The model is downloaded by the OS on first use
//      and stored in `/System/Library/...` (read-only, system-managed).
//      Verified: there is no public API to redirect embeddings to a
//      network endpoint. Apple does not train on user inputs.
//    - We do NOT use the resulting vectors to GENERATE text. They feed
//      `LifeGraph.semanticSearch` (T173) which only reranks existing
//      entities — it does not synthesize new ones. Same for
//      `InvisibleMentor.respond` (T177) which quotes the user's own
//      past writing verbatim.
//
//  Why NSLock instead of an actor:
//    `NLEmbedding.vector(for:)` is itself thread-safe (Apple's
//    documentation says it can be called from any queue). But the
//    "load the model once + reuse the instance" pattern is racy
//    without our own guard — two callers can both observe `embedder == nil`
//    and both invoke the (expensive) `sentenceEmbedding(for:)` initializer.
//    NSLock around the lazy-init block guarantees single-instantiation
//    without forcing callers into an async/await context.
//
//  Token cap & OOM:
//    `NLEmbedding` silently returns an empty vector for inputs that
//    exceed its internal token limit (~500-800 tokens depending on
//    language model). We detect the empty-vector case AND any
//    OOM-equivalent (vector dimension mismatch with `expectedDimension`)
//    and return `nil` rather than a zero-vector. Callers (`LifeEntity`
//    paths, `semanticSearch`) treat `nil` as "no semantic signal; fall
//    back to lexical".
//
//  This file deliberately does NOT import SwiftUI / UIKit. It is safe
//  to instantiate from any actor, queue, or test runner.

import Foundation
#if canImport(NaturalLanguage)
import NaturalLanguage
#endif

// MARK: - Public surface

/// A sentence-embedding wrapper around `NaturalLanguage.NLEmbedding`.
///
/// Use `OnDeviceEmbedder.shared.embed(_:)` to get a 512-dim Float vector
/// for any user-authored text. The result is `nil` when:
///   - NaturalLanguage is not available on this platform (Linux tests)
///   - The English sentence model failed to load
///   - The input exceeded NLEmbedding's token cap
///   - The resulting vector has an unexpected dimension (defensive)
public final class OnDeviceEmbedder: @unchecked Sendable {

    // Singleton: there is only one NLEmbedding instance per process
    // (the model load is expensive). Sharing across the app keeps the
    // OS-level model warm and avoids redundant disk reads.
    public static let shared = OnDeviceEmbedder()

    /// The dimensionality we expect from `NLEmbedding.sentenceEmbedding(for: .english)`.
    /// Kept in sync with `LifeEmbedding.expectedDimension` so the typed
    /// struct and the embedder agree on shape.
    public static let expectedDimension: Int = 512

    /// Hard input cap: NLEmbedding is documented to silently drop tokens
    /// past its internal window. Truncating here keeps callers honest
    /// about what they're embedding and prevents pathological inputs
    /// from occupying the lock for seconds at a time.
    public static let maxInputCharacters: Int = 4_000

    // MARK: - Private state

    #if canImport(NaturalLanguage)
    /// Cached NLEmbedding instance. Loaded lazily on first use. Guarded
    /// by `lock` — every read AND write goes through the lock.
    private var _nlEmbedding: NLEmbedding?
    #endif

    /// Thread-safety guard. NSLock rather than `os_unfair_lock` because
    /// NSLock is portable to Linux Swift toolchains (where `os_unfair_lock`
    /// is unavailable). The critical section is short — just a model-load
    /// check or an `embed` call — so contention is negligible.
    private let lock = NSLock()

    private init() {
        // Intentionally empty. We do NOT eagerly load the NLEmbedding
        // model — it can take 100-500ms on first use, and most users
        // never invoke a path that needs embeddings. Lazy load keeps
        // app launch fast.
    }

    // MARK: - Embedding API

    /// Embed a single text. Returns `nil` on every failure mode listed in
    /// the type-level docs. The returned vector has length
    /// `expectedDimension` (512) on success.
    ///
    /// Thread-safe: may be called from any queue.
    public func embed(_ text: String) -> [Float]? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Truncate defensively. We embed the FIRST `maxInputCharacters`
        // characters — NLEmbedding's token window is smaller than its
        // character window, but truncating here keeps the lock-hold time
        // bounded.
        let input: String
        if trimmed.count > OnDeviceEmbedder.maxInputCharacters {
            input = String(trimmed.prefix(OnDeviceEmbedder.maxInputCharacters))
        } else {
            input = trimmed
        }

        lock.lock()
        defer { lock.unlock() }

        #if canImport(NaturalLanguage)
        // Lazy-init the NLEmbedding instance. We do NOT call
        // `sentenceEmbedding(for:)` outside the lock — two concurrent
        // callers would otherwise both trigger a model load.
        if _nlEmbedding == nil {
            _nlEmbedding = NLEmbedding.sentenceEmbedding(for: .english)
        }
        guard let nl = _nlEmbedding else {
            // Model failed to load (corrupt install, no English support,
            // simulator without the model). Treat as "no semantic signal".
            return nil
        }
        guard let vector = nl.vector(for: input) else {
            // nil from NLEmbedding means: empty input (already filtered)
            // OR token cap exceeded. Caller's lexical fallback handles it.
            return nil
        }
        // Defensive: if Apple ever changes the dimensionality of the
        // English sentence model, we refuse the vector rather than
        // persisting it with the wrong shape. This is what makes the
        // `LifeEmbedding.isCurrent` check trustworthy.
        guard vector.count == OnDeviceEmbedder.expectedDimension else {
            return nil
        }
        // NLEmbedding returns Double; convert to Float for storage
        // compactness. 4 bytes vs 8 bytes per component — a 512-dim
        // embedding goes from 4KB to 2KB, meaningful at 1000+ entities.
        return vector.map { Float($0) }
        #else
        // Linux / no NaturalLanguage: deliberately return nil so the
        // rest of the codebase exercises its lexical-fallback paths.
        // Constitutional §3: no generation, no fake outputs.
        _ = input
        return nil
        #endif
    }

    /// Embed text and write the resulting vector into a `LifeEntity`.
    /// Returns immediately; the heavy lifting happens off-main on a
    /// dedicated background queue. Used by `LifeEntity.fromTimelineEvent`
    /// (T174) and `LifeEntity.fromQuest` (T175).
    ///
    /// Idempotency: if `entity.embedding?.isCurrent == true`, this call
    /// is a no-op. Safe to invoke from re-entry points (e.g. when the
    /// same timeline event is processed twice during a sync).
    ///
    /// Failure: if the embedder returns nil, we leave the entity's
    /// `embedding` property nil. `LifeGraph.semanticSearch` knows how
    /// to fall back to lexical ranking in that case (T173b).
    public func embedInBackground(text: String, assignTo entity: LifeEntity) {
        // Idempotency guard (T174a). Do NOT re-embed an already-current
        // vector — that would re-trigger the background work every time
        // the entity is loaded from disk, wasting CPU + battery.
        if entity.embedding?.isCurrent == true { return }

        // Capture the values we need on the background thread. The
        // entity reference itself is captured but only MUTATED from
        // the main actor (see below) — `LifeEntity` is a SwiftData
        // @Model and is expected to be touched on MainActor.
        let snapshotText = text
        OnDeviceEmbedder.backgroundQueue.async { [weak self] in
            guard let self = self else { return }
            guard let vector = self.embed(snapshotText) else { return }
            let embedding = LifeEmbedding(
                vector: vector,
                version: LifeEmbedding.currentVersion,
                generatedAt: Date()
            )
            // Hop back to MainActor for the SwiftData mutation. This
            // is the "never on main" rule from T174b — the embedding
            // computation happens here; only the assignment is on main.
            Task { @MainActor in
                entity.embedding = embedding
            }
        }
    }

    /// Shared serial queue for background embedding work. Concurrent
    /// embedding calls would just contend on `lock` anyway, so a serial
    /// queue gives us predictable latency and zero model-cache thrash.
    /// QoS `.utility` — embeddings are user-visible but not
    /// render-critical (the UI shows the reflection as soon as it's
    /// saved; the embedding catches up asynchronously).
    private static let backgroundQueue: DispatchQueue =
        DispatchQueue(label: "com.oneweave.embedder",
                      qos: .utility,
                      attributes: [],
                      autoreleaseFrequency: .workItem,
                      target: .global(qos: .utility))
}