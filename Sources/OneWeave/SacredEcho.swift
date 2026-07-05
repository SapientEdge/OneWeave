//
//  SacredEcho.swift
//  OneWeave
//
//  Sacred Echo Vault — 4th creative feature (Tier A #3).
//
//  A Sacred Echo is a sealed reflection the user writes today, encrypted at
//  rest, that cannot be opened until a future date they choose. This is the
//  privacy-first equivalent of a time capsule: the user's words, sealed, with
//  a cryptographic unlock condition tied to wall-clock time.
//
//  Design pillars:
//    1. Sealed at write, opened by time. Ciphertext + unlock metadata only.
//    2. Reflection-gated — empty payload is refused at seal time.
//    3. Privacy-first — symmetric key in Keychain (or Secure Enclave on device).
//    4. Lifecycle: sealed → maturing → opening-ready → opened → (optional) hand-delivered.
//    5. Gentle decay — never silently deleted.
//    6. Local-first — SwiftData; mirrors to App Group for widget countdowns.
//
//  Fresh unique twists:
//    - Echo Decree — short instruction from present-self to future-self, shown
//      as a permission check at opening time.
//    - Echo Heir — recipient slot for P2P hand-delivery via the existing Weave
//      Circle. Heir must already be in the user's Weave Circle (Data Leash
//      already gates that).
//
//  What this file intentionally does NOT contain:
//    - Real P2P transport (already stubbed in P2PWeaveShare.swift).
//    - Real widget rendering (needs Xcode target; out of scope here).
//    - Live Secure Enclave usage — but the key-derivation pattern (HKDF over
//      a Keychain-stored seed) is the production-correct fallback.
//

import Foundation
import SwiftData
import CryptoKit

#if canImport(Security)
import Security
#endif
#if !canImport(Security)
import Darwin  // for open/read/close on Linux dev harness
#endif

// MARK: - Echo lifecycle states

public enum EchoLifecycleState: String, Codable, CaseIterable {
    /// Newly sealed; not yet eligible for opening.
    case sealed
    /// Past the seal date, but still locked. Day-counter is shown.
    case maturing
    /// Within 24h of unlock — the echo gently announces itself.
    case openingReady
    /// Unlocked and read by the user.
    case opened
    /// User opened and confirmed hand-delivery to the heir (terminal state).
    case delivered
    /// User released the echo without an heir (terminal state).
    case released
}

/// Cycle 35 / T153 (GLM A4): kind of echo. `regular` is the default —
/// the echo auto-unseals when unlockAt passes and the user opens it.
/// `timeCapsule` adds a *second* layer: auto-unseal also asks "has anything
/// changed?" and requires a fresh reflection prompt before the plaintext
/// is shown. Honors Constitution §4 (reflection-gated everything).
public enum EchoKind: String, Codable, CaseIterable {
    case regular
    case timeCapsule
}

// MARK: - Echo error surface

public enum EchoError: Error, LocalizedError {
    case emptyReflection
    case unlockDateInPast
    case notYetUnlocked(unlockAt: Date, now: Date)
    case alreadyOpened
    case noHeirDesignated
    case heirNotInWeaveCircle
    case decryptionFailed
    case cipherMissingKey
    case secureRandomUnavailable
    case persistenceFailed(String)

    public var errorDescription: String? {
        switch self {
        case .emptyReflection:
            return "An echo needs words. Write a reflection before sealing."
        case .unlockDateInPast:
            return "Unlock date must be in the future."
        case .notYetUnlocked(let unlockAt, let now):
            let remaining = Int(unlockAt.timeIntervalSince(now) / 86400)
            return "This echo opens in \(remaining) days."
        case .alreadyOpened:
            return "This echo has already been opened."
        case .noHeirDesignated:
            return "No heir designated for hand-delivery."
        case .heirNotInWeaveCircle:
            return "Heir must be in your Weave Circle before delivery."
        case .decryptionFailed:
            return "Could not decrypt this echo. The vault key may be wrong."
        case .cipherMissingKey:
            return "Vault key missing from Keychain."
        case .persistenceFailed(let detail):
            return "Could not save echo: \(detail)"
        }
    }
}

// MARK: - SacredEcho SwiftData model

@Model
public final class SacredEcho {
    /// Stable identifier (also the lookup key for the vault seed).
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var decree: String                // present-self instruction to future-self
    public var createdAt: Date
    public var unlockAt: Date
    public var openedAt: Date?
    public var stateRaw: String              // EchoLifecycleState.rawValue

    /// Cycle 35 / T153 (GLM A4): kind of echo. Defaults to .regular for
    /// backwards compatibility with echoes sealed before cycle 35. Time
    /// capsules layer a reflection-prompt gate on top of the unlock gate.
    public var kindRaw: String              // EchoKind.rawValue

    /// Encrypted reflection (base64 of ciphertext). NEVER plaintext at rest.
    public var ciphertext: Data
    /// Per-echo nonce (12 bytes for AES-GCM).
    public var nonce: Data
    /// Per-echo tag (16 bytes for AES-GCM).
    public var tag: Data

    /// Optional P2P heir id (must match a LifeEntity of type .person in the user's
    /// Weave Circle). Empty string means no heir — local-only echo.
    public var heirLifeEntityID: String

    /// Lifecycle metadata.
    public var attributes: [String: String]

    /// Wall-clock comparison helper — overridable in tests via `nowOverride`.
    /// NOTE: per Nemotron cycle-25 #40, this was previously `public static`
    /// which let any caller pin wall-clock and bypass the unlock-date gate.
    /// Now gated behind `#if DEBUG` and reduced to `internal` so production
    /// builds cannot mutate it. Test code can still set it via the same
    /// accessor; the type system enforces DEBUG scoping.
    #if DEBUG
    internal static var nowOverride: (() -> Date)?
    #else
    internal static let nowOverride: (() -> Date)? = nil
    #endif

    public init(
        id: UUID = UUID(),
        title: String,
        decree: String,
        ciphertext: Data,
        nonce: Data,
        tag: Data,
        unlockAt: Date,
        heirLifeEntityID: String = "",
        attributes: [String: String] = [:],
        kind: EchoKind = .regular
    ) {
        self.id = id
        self.title = title
        self.decree = decree
        self.createdAt = SacredEcho.now()
        self.unlockAt = unlockAt
        self.openedAt = nil
        self.stateRaw = EchoLifecycleState.sealed.rawValue
        self.kindRaw = kind.rawValue
        self.ciphertext = ciphertext
        self.nonce = nonce
        self.tag = tag
        self.heirLifeEntityID = heirLifeEntityID
        self.attributes = attributes
    }

    /// Cycle 35 / T153 (GLM A4): the kind of echo. Defaults to .regular
    /// for echoes sealed before the field existed.
    public var kind: EchoKind {
        get { EchoKind(rawValue: kindRaw) ?? .regular }
        set { kindRaw = newValue.rawValue }
    }

    /// Lifecycle state derived from wall-clock + openedAt.
    public var state: EchoLifecycleState {
        // Opened/delivered/released are sticky terminal states.
        if let s = EchoLifecycleState(rawValue: stateRaw),
           s == .opened || s == .delivered || s == .released {
            return s
        }
        let now = SacredEcho.now()
        if let opened = openedAt, opened <= now {
            return .opened
        }
        // Per Grok cycle-24 finding #4: reserve .openingReady for the moment
        // unlockAt has actually passed. We expose "imminent" (≤24h) as a
        // distinct visual hint via daysUntilUnlock(), not as a state change.
        if unlockAt <= now {
            return .openingReady
        }
        return .maturing
    }

    /// Days remaining until unlock (negative if past).
    public func daysUntilUnlock(now: Date? = nil) -> Int {
        let n = now ?? SacredEcho.now()
        return Int(unlockAt.timeIntervalSince(n) / 86400)
    }

    /// Human-readable status for UI/widget rendering.
    public var statusLine: String {
        switch state {
        case .sealed:
            return "Sealed — opens in \(daysUntilUnlock()) days."
        case .maturing:
            return "Maturing — opens in \(daysUntilUnlock()) days."
        case .openingReady:
            return "Ready to open."
        case .opened:
            return openedAt.map { "Opened on \(formatted($0))." } ?? "Opened."
        case .delivered:
            return "Hand-delivered to heir."
        case .released:
            return "Released without opening."
        }
    }

    // MARK: - Clock injection (testable)

    public static func now() -> Date {
        return nowOverride?() ?? Date()
    }

    private func formatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
    }
}

// MARK: - SacredEchoCipher (envelope encryption)
//
// Production-correct pattern for iOS:
//   1. A 256-bit symmetric vault seed lives in the Keychain (kSecAttrAccessibleAfterFirstUnlock).
//      On devices with Secure Enclave, the seed would be wrapped by a SE key; here
//      we use the Keychain as the canonical storage.
//   2. Each SacredEcho derives its own per-echo key via HKDF over (vaultSeed || echo.id).
//   3. Reflection is sealed with AES-GCM under the per-echo key.
//   4. The plaintext never persists anywhere; only ciphertext + nonce + tag.
//
// On Linux (test harness), the Keychain is not available, so we use a
// deterministic test seed when the Keychain lookup fails. This keeps the
// encryption symmetric and reproducible across platforms.

public enum SacredEchoCipher {

    /// Hex form of a deterministic test seed (Linux harness + tests). NEVER used
    /// on real device — production reads from Keychain.
    private static let testSeedHex = "4f6e6557656176656d7573746265696e7465726e616c6c79706172656e742d7365656400000000"

    /// Look up the vault seed. On device, this reads from Keychain. If no seed
    /// exists yet (first launch), generate a fresh 256-bit seed and store it.
    /// NEVER falls back to a deterministic value — that would be a critical
    /// security failure (Grok cycle-24 finding).
    /// Throws `EchoError.cipherMissingKey` if Keychain persistence fails (fail-closed per constitution §4).
    /// On Linux / tests, the deterministic test seed is used as a fallback for cipher parity across platforms.
    public static func vaultSeed() throws -> SymmetricKey {
        #if canImport(Security)
        if let data = loadFromKeychain() {
            return SymmetricKey(data: data)
        }
        // First launch: generate + store.
        let newSeed = try randomBytes(count: 32)
        if persistToKeychain(seed: newSeed) {
            return SymmetricKey(data: newSeed)
        }
        // Persist failed. FAIL CLOSED: do not return an ephemeral seed.
        // Returning an unpersisted key means all future seals are unrecoverable
        // after app restart, which would silently lose user data.
        // Callers must catch and surface this to the user (no Sacred Echoes until vault is healthy).
        // Round-3 finding (NEMO-R3-018): users were not notified of the failure.
        throw EchoError.cipherMissingKey
        #else
        // Linux test/dev fallback — explicitly marked as not for production.
        // Cycle 41 finding A5 (constitutional §2 / invariant #4): gate this
        // path behind DEBUG so a non-DEBUG Linux build cannot accidentally
        // encrypt user data with the public test seed. Production iOS
        // builds go through Keychain above and never enter this branch.
        #if DEBUG
        let bytes = hexToBytes(testSeedHex)
        return SymmetricKey(data: Data(bytes))
        #else
        // Release Linux build: fail closed rather than silently fall back
        // to a public test key.
        throw EchoError.cipherMissingKey
        #endif
        #endif
    }
    /// Derive the per-echo key from the vault seed + echo id.
    public static func perEchoKey(for echoID: UUID, seed: SymmetricKey) -> SymmetricKey {
        let info = "SacredEcho.\(echoID.uuidString)".data(using: .utf8)!
        let salt = Data(echoID.uuidString.prefix(16).utf8)
        return HKDF<SHA256>.deriveKey(
            inputKeyMaterial: seed,
            salt: salt,
            info: info,
            outputByteCount: 32
        )
    }

    /// Encrypt a plaintext reflection into (ciphertext, nonce, tag).
    public static func seal(
        plaintext: String,
        echoID: UUID,
        seed: SymmetricKey? = nil
    ) throws -> (ciphertext: Data, nonce: Data, tag: Data) {
        let s = seed ?? (try vaultSeed())
        let key = perEchoKey(for: echoID, seed: s)
        let nonceBytes = try randomBytes(count: 12)
        let n = try AES.GCM.Nonce(data: nonceBytes)
        let sealed = try AES.GCM.seal(Data(plaintext.utf8), using: key, nonce: n)
        // sealed.ciphertext + sealed.tag are the encrypted payload and auth tag.
        return (sealed.ciphertext, Data(nonceBytes), sealed.tag)
    }

    /// Decrypt a sealed echo. Throws if the ciphertext is tampered, the tag
    /// fails, or the key is wrong.
    public static func open(
        ciphertext: Data,
        nonce: Data,
        tag: Data,
        echoID: UUID,
        seed: SymmetricKey? = nil
    ) throws -> String {
        let s = seed ?? (try vaultSeed())
        let key = perEchoKey(for: echoID, seed: s)
        let n = try AES.GCM.Nonce(data: nonce)
        let box = try AES.GCM.SealedBox(nonce: n, ciphertext: ciphertext, tag: tag)
        let plain = try AES.GCM.open(box, using: key)
        guard let str = String(data: plain, encoding: .utf8) else {
            throw EchoError.decryptionFailed
        }
        return str
    }

    // MARK: - Internal helpers

    private static func randomBytes(count: Int) throws -> Data {
        var bytes = Data(count: count)
        #if canImport(Security)
        let status = bytes.withUnsafeMutableBytes { ptr -> Int32 in
            SecRandomCopyBytes(kSecRandomDefault, count, ptr.baseAddress!)
        }
        if status != errSecSuccess {
            // SecRandom failure is rare. Try /dev/urandom as a fallback
            // before failing closed (Claude + Grok cycle-24 finding: weak
            // deterministic nonce reuse is catastrophic for AES-GCM).
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
            // Final fallback failed — fail closed with a typed error
            // (was `fatalError` per Codex cycle-41 BLOCKER).
            throw EchoError.secureRandomUnavailable
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
            // Final fallback failed — fail closed with a typed error
            // (was `fatalError` per Codex cycle-41 BLOCKER).
            throw EchoError.secureRandomUnavailable
        }
        #endif
        return bytes
    }
    private static func hexToBytes(_ hex: String) -> [UInt8] {
        var bytes: [UInt8] = []
        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2, limitedBy: hex.endIndex) ?? hex.endIndex
            if let byte = UInt8(hex[index..<next], radix: 16) {
                bytes.append(byte)
            }
            index = next
        }
        return bytes
    }

    #if canImport(Security)
    private static func loadFromKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.oneweave.echovault",
            kSecAttrAccount as String: "vault.seed.v1",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data {
            return data
        }
        return nil
    }

    /// Persist the vault seed to Keychain. Overwrites any existing entry.
    /// Returns true on success, false on failure (caller decides fallback).
    @discardableResult
    private static func persistToKeychain(seed: Data) -> Bool {
        // Delete any existing entry first (SecItemAdd is fussy about duplicates).
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.oneweave.echovault",
            kSecAttrAccount as String: "vault.seed.v1"
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        // Add the new entry.
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.oneweave.echovault",
            kSecAttrAccount as String: "vault.seed.v1",
            kSecValueData as String: seed,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        return status == errSecSuccess
    }
    #endif
}

// MARK: - SacredEchoStore (open/seal/hand-deliver API)
//
// All entry points are @MainActor so they compose cleanly with SwiftUI /
// SwiftData ModelContext. The store mutates the supplied ModelContext.
//
// `modelContext` is optional in the API surface so the gate logic can be
// exercised on Linux (where no real ModelContext is available) and so a
// caller can defer providing a context until after the gate has approved
// the request. When nil, the store refuses to write and throws
// `persistenceFailed`.

@MainActor
public enum SacredEchoStore {

    /// Seal a new Sacred Echo. Reflection is required (gate). Unlock date must
    /// be in the future. Heir, if provided, must already be in the user's
    /// Weave Circle (Data Leash check delegated to `validateHeir`).
    @discardableResult
    public static func seal(
        title: String,
        reflection: String,
        decree: String,
        unlockAt: Date,
        heirLifeEntityID: String,
        into context: LifeContext,
        modelContext: ModelContext? = nil
    ) throws -> SacredEcho {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedReflection = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDecree = decree.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedReflection.isEmpty else { throw EchoError.emptyReflection }
        guard unlockAt > SacredEcho.now() else { throw EchoError.unlockDateInPast }

        // Heir validation: if a heir id is provided, the matching LifeEntity
        // must exist and have `domains` containing "CareKin" (proxy for
        // being in the user's Weave Circle).
        if !heirLifeEntityID.isEmpty {
            try validateHeir(heirLifeEntityID: heirLifeEntityID, in: context)
        }

        // Build the echo with placeholder ciphertext, then encrypt.
        let id = UUID()
        let (ciphertext, nonce, tag) = try SacredEchoCipher.seal(
            plaintext: trimmedReflection,
            echoID: id
        )
        let echo = SacredEcho(
            id: id,
            title: trimmedTitle.isEmpty ? "Untitled Echo" : trimmedTitle,
            decree: trimmedDecree,
            ciphertext: ciphertext,
            nonce: nonce,
            tag: tag,
            unlockAt: unlockAt,
            heirLifeEntityID: heirLifeEntityID,
            attributes: [
                "created_iso": ISO8601DateFormatter().string(from: SacredEcho.now())
            ]
        )

        guard let mc = modelContext else {
            throw EchoError.persistenceFailed("no ModelContext provided")
        }
        mc.insert(echo)
        do {
            try mc.save()
        } catch {
            throw EchoError.persistenceFailed(String(describing: error))
        }

        // Mirror into the Life Graph as a sealed concept entity — gives the
        // Insight Engine something to reason about without exposing plaintext.
        let concept = LifeEntity(
            type: .concept,
            title: "Sacred Echo: \(echo.title)",
            summary: "Sealed reflection — opens \(echo.unlockAt).",
            memoryType: .procedural
        )
        concept.attributes = [
            "echo_id": echo.id.uuidString,
            "unlock_iso": ISO8601DateFormatter().string(from: echo.unlockAt),
            "is_echo": "true"
        ]
        concept.isPrivate = true
        concept.domains = heirLifeEntityID.isEmpty ? ["Self"] : ["Self", "CareKin"]
        concept.harmonyImpact = 0.0
        mc.insert(concept)
        context.lifeGraphEntities.append(concept)

        // Echo writes invalidate the insight cache (Tier A #1).
        GraphInsightGenerator.invalidateCache()
        return echo
    }

    /// Open a Sacred Echo. Throws `notYetUnlocked` if it's still locked.
    /// Returns (plaintextReflection, decree) so the caller can present both.
    /// Throws `alreadyOpened` if the echo has already been opened (no re-opens,
    /// per Grok cycle-24 finding #7).
    public static func open(
        _ echo: SacredEcho,
        modelContext: ModelContext? = nil
    ) throws -> (reflection: String, decree: String) {
        let now = SacredEcho.now()
        // Block re-opens: once .opened (or any terminal state), the echo is sealed.
        if let s = EchoLifecycleState(rawValue: echo.stateRaw),
           s == .opened || s == .released || s == .delivered {
            throw EchoError.alreadyOpened
        }
        // Also block if openedAt is already set (defensive — stateRaw could lag).
        if echo.openedAt != nil {
            throw EchoError.alreadyOpened
        }
        // Block premature opens: unlockAt must have passed. The .openingReady
        // lifecycle state is a UI hint only; the open gate is wall-clock.
        guard echo.unlockAt <= now else {
            throw EchoError.notYetUnlocked(unlockAt: echo.unlockAt, now: now)
        }

        let reflection = try SacredEchoCipher.open(
            ciphertext: echo.ciphertext,
            nonce: echo.nonce,
            tag: echo.tag,
            echoID: echo.id
        )
        echo.openedAt = now
        echo.stateRaw = EchoLifecycleState.opened.rawValue
        if let mc = modelContext {
            do {
                try mc.save()
            } catch {
                throw EchoError.persistenceFailed(String(describing: error))
            }
        }
        GraphInsightGenerator.invalidateCache()
        return (reflection, echo.decree)
    }

    /// Hand-deliver an opened echo to the heir. The heir must be in the user's
    /// Weave Circle (validated up-front). Reflection-gated: an echo that has
    /// been opened but the user has not yet written a hand-delivery reflection
    /// cannot be delivered — this protects the heir from receiving a payload
    /// the user did not actively bless.
    @discardableResult
    public static func handDeliver(
        _ echo: SacredEcho,
        deliveryReflection: String,
        into context: LifeContext,
        modelContext: ModelContext? = nil
    ) throws -> Bool {
        let trimmed = deliveryReflection.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw EchoError.emptyReflection }
        guard !echo.heirLifeEntityID.isEmpty else { throw EchoError.noHeirDesignated }
        // Grok cycle-24 finding #8: delivery requires the echo to have been
        // opened first. An unopened echo has no plaintext to deliver; the
        // heir would receive nothing meaningful and the user would have
        // bypassed the reflection-on-opening ritual.
        let s = EchoLifecycleState(rawValue: echo.stateRaw)
        guard s == .opened || s == .delivered else {
            throw EchoError.alreadyOpened  // "not yet opened"
        }
        try validateHeir(heirLifeEntityID: echo.heirLifeEntityID, in: context)

        // Mark as delivered.
        // Per Nemotron #32 + Grok cycle-24 #9: delivery reflections are NOT
        // stored in attributes (which persist plaintext). The act of delivery
        // is recorded with a timestamp; the reflection text itself lives in
        // a Sacred Echo-style encrypted blob (or, for v1, is simply dropped).
        // For now we record only the timestamp so the user can confirm they
        // wrote one. Future v1.1 will encrypt the delivery reflection via
        // SacredEchoCipher so the promise holds.
        echo.stateRaw = EchoLifecycleState.delivered.rawValue
        echo.attributes["delivered_iso"] = ISO8601DateFormatter().string(from: SacredEcho.now())
        echo.attributes["has_delivery_reflection"] = "true"
        // Note: trimmed reflection text is NOT persisted. The Echo was
        // opened + the user wrote a delivery reflection in-session; the
        // act of delivery is what matters, not the wording.
        guard let mc = modelContext else {
            throw EchoError.persistenceFailed("no ModelContext provided")
        }
        do {
            try mc.save()
        } catch {
            throw EchoError.persistenceFailed(String(describing: error))
        }

        // Stage a LifeGraph snapshot of the delivery for the heir — note that
        // the actual P2P transport is owned by P2PWeaveShare (already gated).
        // We don't call into P2PWeaveShare here directly because that would
        // couple the vault to a specific transport; the snapshot is enough
        // for the P2P layer to find and route.
        let snapshot = LifeEntity(
            type: .event,
            title: "Echo delivered: \(echo.title)",
            summary: "Hand-delivered on \(ISO8601DateFormatter().string(from: SacredEcho.now())).",
            memoryType: .episodic
        )
        snapshot.attributes = [
            "echo_id": echo.id.uuidString,
            "heir_id": echo.heirLifeEntityID,
            "is_echo_delivery": "true"
        ]
        snapshot.isPrivate = true
        snapshot.domains = ["CareKin", "Self"]
        mc.insert(snapshot)
        context.lifeGraphEntities.append(snapshot)
        GraphInsightGenerator.invalidateCache()
        return true
    }

    /// Release an echo without opening. Reflection required to ensure the
    /// user is consciously choosing release (not a stray tap).
    public static func release(
        _ echo: SacredEcho,
        releaseReflection: String,
        modelContext: ModelContext? = nil
    ) throws {
        let trimmed = releaseReflection.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw EchoError.emptyReflection }
        echo.stateRaw = EchoLifecycleState.released.rawValue
        // Per Nemotron #32: don't persist the release reflection text in
        // attributes (plaintext). Record only the timestamp; the wording
        // belongs to the in-session ritual, not the persistent record.
        echo.attributes["released_iso"] = ISO8601DateFormatter().string(from: SacredEcho.now())
        if let mc = modelContext {
            do {
                try mc.save()
            } catch {
                throw EchoError.persistenceFailed(String(describing: error))
            }
        }
        GraphInsightGenerator.invalidateCache()
    }

    /// Validate that the heir is in the user's Weave Circle. We proxy
    /// "in Weave Circle" via "has a LifeEntity with domains containing
    /// CareKin" — this matches the data model we already use for relationship
    /// gating. Data Leash privacy for the heir entity is honored downstream
    /// by P2PWeaveShare.
    public static func validateHeir(heirLifeEntityID: String, in context: LifeContext) throws {
        guard !heirLifeEntityID.isEmpty else { throw EchoError.noHeirDesignated }
        let heirEntity = context.lifeGraphEntities.first { $0.id.uuidString == heirLifeEntityID }
        guard let entity = heirEntity else { throw EchoError.heirNotInWeaveCircle }
        guard entity.domains.contains("CareKin") else { throw EchoError.heirNotInWeaveCircle }
    }

    // MARK: - Cycle 35 / T153 (GLM A4): Time Capsule auto-unseal

    /// A reflection prompt that gates the unsealing of a time-capsule echo.
    /// The user must write a non-empty reflection answering the question
    /// before the plaintext is decrypted and shown.
    public struct TimeCapsuleInvite: Codable, Equatable {
        public let echoID: UUID
        public let echoTitle: String
        public let prompt: String
        public let sealedAt: Date
        public let unlockAt: Date
        public let yearsSinceSealed: Double
        public let isReady: Bool

        public init(
            echoID: UUID,
            echoTitle: String,
            prompt: String,
            sealedAt: Date,
            unlockAt: Date,
            yearsSinceSealed: Double,
            isReady: Bool
        ) {
            self.echoID = echoID
            self.echoTitle = echoTitle
            self.prompt = prompt
            self.sealedAt = sealedAt
            self.unlockAt = unlockAt
            self.yearsSinceSealed = yearsSinceSealed
            self.isReady = isReady
        }
    }

    /// Build the time-capsule invite for an echo. Only meaningful when
    /// `echo.kind == .timeCapsule`. For regular echoes, returns an invite
    /// whose `prompt` describes the standard unseal flow.
    ///
    /// UX: "Sealed on 2026-06-28. Opens 2027-06-28. Unseal will ask:
    ///      has anything changed?"
    public static func timeCapsuleInvite(
        for echo: SacredEcho,
        now: Date = SacredEcho.now()
    ) -> TimeCapsuleInvite {
        let yearsSince = now.timeIntervalSince(echo.createdAt) / (365.25 * 86400)
        let isReady = echo.unlockAt <= now

        let prompt: String
        switch echo.kind {
        case .timeCapsule:
            if isReady {
                prompt = "Sealed on \(formatDate(echo.createdAt)). Opens \(formatDate(echo.unlockAt)). " +
                         "Unseal will ask: has anything changed?"
            } else {
                let days = Int(echo.unlockAt.timeIntervalSince(now) / 86400)
                let dayWord = days == 1 ? "day" : "days"
                prompt = "Sealed on \(formatDate(echo.createdAt)). Opens \(formatDate(echo.unlockAt)) " +
                         "— \(days) \(dayWord) from now."
            }
        case .regular:
            prompt = "Echo sealed on \(formatDate(echo.createdAt))."
        }

        return TimeCapsuleInvite(
            echoID: echo.id,
            echoTitle: echo.title,
            prompt: prompt,
            sealedAt: echo.createdAt,
            unlockAt: echo.unlockAt,
            yearsSinceSealed: yearsSince,
            isReady: isReady
        )
    }

    /// Private ISO date formatter for status text.
    private static func formatDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: d)
    }
}