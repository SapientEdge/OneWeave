//
//  AppLifecycleCoordinator.swift
//  OneWeave
//
//  Tier A #5: app lifecycle wiring for save/load + Sacred Echo re-check +
//  widget snapshot push on scenePhase transitions.
//
//  Design:
//    - background: persist Life Graph + push widget snapshot
//    - foreground: re-evaluate Sacred Echoes (lifecycle state may have changed
//      while the app was closed), invalidate insight cache, optionally re-poll
//      Body Thread if leash is open + 4h+ since last read
//    - inactive: nothing destructive — just record the timestamp
//    - active: lightweight freshness check, no I/O
//
//  Storage:
//    - JSON envelope at App Group container: "oneweave.lifegraph.v1.json"
//    - Encrypted with the same SacredEchoCipher vault key (AES-256-GCM with
//      HKDF derivation, identical to how Sacred Echoes are sealed)
//    - On Linux/dev, falls back to the deterministic test seed
//

import Foundation
import SwiftUI
import SwiftData
import CryptoKit

#if canImport(Security)
import Security
#endif
#if !canImport(Security)
import Darwin  // for open/read/close on Linux dev harness
#endif
// MARK: - Lifecycle phase

public enum AppLifecyclePhase: String, Codable {
    case active
    case inactive
    case background
    case foreground
}

// MARK: - Persistence envelope

/// Codable envelope for the Life Graph + supporting state. Encrypted at rest
/// when `cipherEnvelope` is non-nil; plaintext otherwise (used by the harness).
public struct LifeGraphEnvelope: Codable, Equatable {
    public var version: Int
    public var savedAt: Date
    public var entities: [LifeEntityDTO]
    public var relationships: [LifeRelationshipDTO]
    public var echoes: [SacredEchoDTO]
    public var coherenceScore: Double
    public var weaveEssence: Double
    public var harmonyScore: Double
    public var completedQuestCount: Int

    public init(
        version: Int = 1,
        savedAt: Date = Date(),
        entities: [LifeEntityDTO],
        relationships: [LifeRelationshipDTO],
        echoes: [SacredEchoDTO],
        coherenceScore: Double,
        weaveEssence: Double,
        harmonyScore: Double,
        completedQuestCount: Int
    ) {
        self.version = version
        self.savedAt = savedAt
        self.entities = entities
        self.relationships = relationships
        self.echoes = echoes
        self.coherenceScore = coherenceScore
        self.weaveEssence = weaveEssence
        self.harmonyScore = harmonyScore
        self.completedQuestCount = completedQuestCount
    }
}

/// Data Transfer Object for LifeEntity — SwiftData @Model classes don't Codable
/// cleanly, so we mirror the fields we want to persist.
public struct LifeEntityDTO: Codable, Equatable {
    public var id: String
    public var type: String
    public var title: String
    public var summary: String
    public var memoryType: String
    public var domains: [String]
    public var harmonyImpact: Double
    public var isPrivate: Bool
    public var allowedCategories: [String]
    public var attributes: [String: String]
    public var createdAt: Date
    public var lastUpdated: Date
}

public struct LifeRelationshipDTO: Codable, Equatable {
    public var id: String
    public var type: String
    public var strength: Double
    public var fromID: String
    public var toID: String
    public var metadata: [String: String]
}

public struct SacredEchoDTO: Codable, Equatable {
    public var id: String
    public var title: String
    public var decree: String
    public var createdAt: Date
    public var unlockAt: Date
    public var openedAt: Date?
    public var stateRaw: String
    public var ciphertext: Data
    public var nonce: Data
    public var tag: Data
    public var heirLifeEntityID: String
    public var attributes: [String: String]
}

// MARK: - Constants

public enum AppLifecycleConstants {
    /// Fixed UUID used to derive the envelope encryption key from the vault
    /// seed. Stable across runs (deterministic key derivation). In production
    /// this could be rotated per-install via a Keychain-stored value; for
    /// Tier A #5 the fixed value is sufficient (and keeps encrypt/decrypt
    /// symmetric on Linux harness + iOS device).
    public static let envelopeKeyID: UUID = UUID(
        uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890"
    ) ?? UUID()
}

// MARK: - App Group container path

public enum AppLifecyclePaths {
    /// App Group identifier — matches the widget snapshot target.
    public static let appGroupID = "group.com.oneweave"

    /// Filename for the Life Graph envelope inside the App Group container.
    public static let lifeGraphFilename = "oneweave.lifegraph.v1.json"

    /// Filename for the optional encrypted envelope (.enc).
    public static let lifeGraphEncryptedFilename = "oneweave.lifegraph.v1.enc"

    /// Resolve the App Group container URL. On simulator + device this points
    /// to the shared App Group directory. On macOS Catalyst or Linux dev/test
    /// (where App Groups don't exist), we fall back to a temp directory.
    public static func containerURL() -> URL {
        if let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) {
            return url
        }
        // Fallback for dev/test on macOS or Linux.
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("oneweave-dev", isDirectory: true)
        try? FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        return tmp
    }

    public static func lifeGraphURL(encrypted: Bool) -> URL {
        containerURL().appendingPathComponent(
            encrypted ? lifeGraphEncryptedFilename : lifeGraphFilename
        )
    }
}

// MARK: - LifeGraphPersistence
//
// Pure functions for serializing LifeContext state to/from a JSON envelope,
// with optional AES-GCM encryption at rest.

@MainActor
public enum LifeGraphPersistence {

    /// Build an envelope from the current LifeContext state. Does not write
    /// anything to disk — callers control when I/O happens.
    public static func makeEnvelope(
        from context: LifeContext,
        echoes: [SacredEcho] = []
    ) -> LifeGraphEnvelope {
        let entityDTOs: [LifeEntityDTO] = context.lifeGraphEntities.map { e in
            LifeEntityDTO(
                id: e.id.uuidString,
                type: e.type.rawValue,
                title: e.title,
                summary: e.summary,
                memoryType: e.memoryType.rawValue,
                domains: e.domains,
                harmonyImpact: e.harmonyImpact,
                isPrivate: e.isPrivate,
                allowedCategories: e.allowedCategories,
                attributes: e.attributes,
                createdAt: e.createdAt,
                lastUpdated: e.lastUpdated
            )
        }
        let relationshipDTOs: [LifeRelationshipDTO] = context.lifeGraphRelationships.map { r in
            LifeRelationshipDTO(
                id: r.id.uuidString,
                type: r.type.rawValue,
                strength: r.strength,
                fromID: r.fromEntity?.id.uuidString ?? "",
                toID: r.toEntity?.id.uuidString ?? "",
                metadata: r.metadata
            )
        }
        let echoDTOs: [SacredEchoDTO] = echoes.map { e in
            SacredEchoDTO(
                id: e.id.uuidString,
                title: e.title,
                decree: e.decree,
                createdAt: e.createdAt,
                unlockAt: e.unlockAt,
                openedAt: e.openedAt,
                stateRaw: e.stateRaw,
                ciphertext: e.ciphertext,
                nonce: e.nonce,
                tag: e.tag,
                heirLifeEntityID: e.heirLifeEntityID,
                attributes: e.attributes
            )
        }
        return LifeGraphEnvelope(
            entities: entityDTOs,
            relationships: relationshipDTOs,
            echoes: echoDTOs,
            coherenceScore: context.lifeCoherenceScore,
            weaveEssence: context.weaveEssence,
            harmonyScore: context.harmonyScore,
            completedQuestCount: context.completedQuestCount
        )
    }

    /// Encrypt an envelope's JSON with the vault key, returning the ciphertext
    /// + nonce + tag as a single `Data` blob.
    /// Format: [12-byte nonce][16-byte tag][ciphertext]
    public static func encrypt(envelope: LifeGraphEnvelope) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let plain = try encoder.encode(envelope)
        // Derive a per-envelope key from the vault seed. We use a fixed UUID
        // for envelope encryption so the decrypt path can use the same one.
        // (Production could rotate this per-session via a Keychain-stored
        // envelope key id; out of scope for Tier A #5.)
        let envelopeKeyID = AppLifecycleConstants.envelopeKeyID
        let seed = SacredEchoCipher.vaultSeed()
        let key = SacredEchoCipher.perEchoKey(for: envelopeKeyID, seed: seed)
        let nonceData = randomBytes(count: 12)
        let n = try AES.GCM.Nonce(data: nonceData)
        let box = try AES.GCM.seal(plain, using: key, nonce: n)
        var out = Data()
        out.append(nonceData)
        out.append(box.tag)
        out.append(box.ciphertext)
        return out
    }

    /// Decrypt an envelope blob and return the parsed envelope.
    public static func decrypt(blob: Data) throws -> LifeGraphEnvelope {
        guard blob.count >= 28 else { throw PersistenceError.corruptEnvelope }
        let nonceData = blob.prefix(12)
        let tag = blob.subdata(in: 12..<28)
        let ciphertext = blob.subdata(in: 28..<blob.count)
        let envelopeKeyID = AppLifecycleConstants.envelopeKeyID
        let seed = SacredEchoCipher.vaultSeed()
        let key = SacredEchoCipher.perEchoKey(for: envelopeKeyID, seed: seed)
        let n = try AES.GCM.Nonce(data: nonceData)
        let box = try AES.GCM.SealedBox(nonce: n, ciphertext: ciphertext, tag: tag)
        let plain = try AES.GCM.open(box, using: key)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(LifeGraphEnvelope.self, from: plain)
    }

    /// Write an envelope to disk. If `encrypted` is true, uses the .enc
    /// filename and AES-GCM wraps the JSON. Plain JSON otherwise.
    @discardableResult
    public static func persist(
        envelope: LifeGraphEnvelope,
        encrypted: Bool = true
    ) -> URL? {
        let url = AppLifecyclePaths.lifeGraphURL(encrypted: encrypted)
        do {
            let data: Data
            if encrypted {
                data = try encrypt(envelope: envelope)
            } else {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                data = try encoder.encode(envelope)
            }
            try data.write(to: url, options: [.atomic, .completeFileProtection])
            return url
        } catch {
            print("[Lifecycle] persist failed: \(error)")
            return nil
        }
    }

    /// Read an envelope from disk. Returns nil if no file exists yet. Throws
    /// if the file exists but can't be parsed (so callers can distinguish
    /// "first launch" from "corrupt storage").
    public static func restore(encrypted: Bool = true) throws -> LifeGraphEnvelope? {
        let url = AppLifecyclePaths.lifeGraphURL(encrypted: encrypted)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let blob = try Data(contentsOf: url)
        if encrypted {
            return try decrypt(blob: blob)
        } else {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(LifeGraphEnvelope.self, from: blob)
        }
    }

    /// Best-effort restore that swallows errors (for first-launch / corrupt
    /// state). Returns the envelope if successful, nil otherwise.
    public static func bestEffortRestore(encrypted: Bool = true) -> LifeGraphEnvelope? {
        return (try? restore(encrypted: encrypted)) ?? nil
    }

    // MARK: - Private helpers

    private static func randomBytes(count: Int) -> Data {
        var bytes = Data(count: count)
        #if canImport(Security)
        let status = bytes.withUnsafeMutableBytes { ptr -> Int32 in
            SecRandomCopyBytes(kSecRandomDefault, count, ptr.baseAddress!)
        }
        if status != errSecSuccess {
            // SecRandom failure is rare. Try /dev/urandom before failing
            // closed (Claude + Grok cycle-24: deterministic nonce reuse is
            // catastrophic for AES-GCM).
            let fd = open("/dev/urandom", O_RDONLY)
            if fd >= 0 {
                let readCount = bytes.withUnsafeMutableBytes { ptr -> Int in
                    read(fd, ptr.baseAddress, count)
                }
                close(fd)
                if readCount == count {
                    return bytes
                }
            }
            // Final fallback failed — fail closed.
            fatalError("[AppLifecycle] Cannot obtain secure random bytes for envelope encryption")
        }
        #else
        // Linux dev harness. Per Claude cycle-24 finding #1, `read(fd, bytes, count)`
        // does not bridge Swift Data → UnsafeMutableRawPointer; use
        // withUnsafeMutableBytes instead.
        let fd = open("/dev/urandom", O_RDONLY)
        if fd >= 0 {
            _ = bytes.withUnsafeMutableBytes { ptr in
                _ = read(fd, ptr.baseAddress, count)
            }
            close(fd)
        } else {
            fatalError("[AppLifecycle] Cannot open /dev/urandom")
        }
        #endif
        return bytes
    }
}

public enum PersistenceError: Error {
    case corruptEnvelope
}

// MARK: - AppLifecycleCoordinator
//
// The single entry point for scenePhase transitions. SwiftUI passes scenePhase
// from the environment; the App calls into this enum's methods.

@MainActor
public enum AppLifecycleCoordinator {

    /// Last-known background timestamp (used to gate Body Thread re-poll).
    public static var lastBackgroundAt: Date?

    /// Body Thread last-read timestamp (from BodyThreadWeaver state).
    /// Stored as a static so the coordinator doesn't need a reference to a
    /// specific BodyThreadWeaver instance.
    public static var bodyThreadLastReadAt: Date?

    /// Scene transitioned to background. Persist the Life Graph + push the
    /// widget snapshot.
    /// Per Nemotron cycle-25 #45: flush pending SwiftData writes before
    /// building the envelope, so recent writes don't lag behind.
    public static func applicationDidEnterBackground(
        context: LifeContext,
        echoes: [SacredEcho] = [],
        quests: [WeaveQuest] = [],
        modelContext: ModelContext? = nil,
        encrypted: Bool = true
    ) {
        lastBackgroundAt = Date()
        // Flush any pending SwiftData writes before snapshotting.
        if let mc = modelContext {
            do {
                try mc.save()
            } catch {
                print("[Lifecycle] background save failed: \(error)")
            }
        }
        let envelope = LifeGraphPersistence.makeEnvelope(
            from: context, echoes: echoes
        )
        let url = LifeGraphPersistence.persist(envelope: envelope, encrypted: encrypted)
        if let url = url {
            print("[Lifecycle] Persisted Life Graph → \(url.lastPathComponent) (\(envelope.entities.count) entities, \(envelope.echoes.count) echoes)")
        }
        context.pushSnapshotToWidgets(from: quests)
        print("[Lifecycle] Background snapshot pushed to widgets")
    }

    /// Scene transitioning from background to foreground. Re-evaluate Sacred
    /// Echo states (some may have unlocked while the app was closed), invalidate
    /// the insight cache so the next read reflects any new state, and trigger
    /// a Body Thread re-poll if it's been >4h AND the leash is open.
    /// Note (Claude cycle-24): `SacredEcho` is a class; no `inout` needed.
    public static func applicationWillEnterForeground(
        context: LifeContext,
        echoes: [SacredEcho],
        leash: DataLeashState,
        bodyThreadEnabled: Bool = false
    ) {
        // Re-evaluate echo states. The SacredEcho.state getter derives from
        // wall-clock vs unlockAt, so accessing .state on each echo is enough.
        var changedCount = 0
        for echo in echoes {
            let derived = echo.state
            // If a sealed echo has now reached openingReady, persist the
            // transition so the envelope + widgets see consistent state.
            // We do NOT auto-open — that's user-driven. (Grok #16: foreground
            // loop must persist lifecycle transitions.)
            if derived == .openingReady
                && EchoLifecycleState(rawValue: echo.stateRaw) == .sealed {
                echo.stateRaw = derived.rawValue
                changedCount += 1
            }
        }
        if changedCount > 0 {
            print("[Lifecycle] \(changedCount) echo(es) became opening-ready while away")
        }
        // Insight cache must reflect any state changes.
        GraphInsightGenerator.invalidateCache()
        // Body Thread freshness check (gated on leash + time + feature flag).
        if bodyThreadEnabled,
           leash.isAllowed(.health),
           let last = bodyThreadLastReadAt,
           Date().timeIntervalSince(last) > 4 * 3600 {
            print("[Lifecycle] Body Thread re-poll recommended (>4h since last read)")
        }
    }

    /// Scene became active (foreground + receiving events). Lightweight: just
    /// record the timestamp. No I/O.
    public static func applicationDidBecomeActive() {
        // Invalidate insight cache so any insights generated while inactive
        // (none on iOS, but defensive) are refreshed.
        GraphInsightGenerator.invalidateCache()
    }

    /// Scene about to resign active (incoming call, control center, etc.).
    /// Don't persist — the user might come right back.
    public static func applicationWillResignActive() {
        // No-op by design.
    }

    /// Convenience hook for SwiftUI's `onChange(of: scenePhase)`. Routes to
    /// the appropriate lifecycle method.
    /// Per Claude cycle-24 finding #2 + Grok #5: the resume path is
    /// `.background` → `.inactive` → `.active`. We detect the actual
    /// background→active transition via `lastBackgroundAt` and call
    /// `applicationWillEnterForeground` exactly once.
    public static func handleScenePhase(
        _ phase: ScenePhase,
        context: LifeContext,
        echoes: [SacredEcho] = [],
        quests: [WeaveQuest] = [],
        leash: DataLeashState,
        bodyThreadEnabled: Bool = false,
        modelContext: ModelContext? = nil,
        encrypted: Bool = true
    ) {
        switch phase {
        case .background:
            applicationDidEnterBackground(
                context: context,
                echoes: echoes,
                quests: quests,
                modelContext: modelContext,
                encrypted: encrypted
            )
        case .active:
            applicationDidBecomeActive()
            // Detect background → active: if we recently went to background,
            // run the foreground hook so echo re-evaluation + Body Thread
            // freshness actually fire (was dead code before this fix).
            if let last = lastBackgroundAt,
               Date().timeIntervalSince(last) < 5 * 60 {
                applicationWillEnterForeground(
                    context: context,
                    echoes: echoes,
                    leash: leash,
                    bodyThreadEnabled: bodyThreadEnabled
                )
                lastBackgroundAt = nil  // consume the marker
            }
        case .inactive:
            // .inactive is the transient phase between background and active.
            // SwiftUI fires this on the way back; we just record the moment
            // so the next .active can detect the transition.
            applicationWillResignActive()
        @unknown default:
            applicationWillResignActive()
        }
    }
}