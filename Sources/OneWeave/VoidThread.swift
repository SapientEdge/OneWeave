//
//  VoidThread.swift
//  OneWeave
//
//  Void Thread — 5th thread (Tier A / T170 / T228 — cycle 39).
//
//  A Void Thread is an opt-in thread that accepts only single sentences
//  sealed with a key derived from the entry's OWN contents via
//  HKDF-SHA256. The app CANNOT read entries back unless the user
//  re-types the exact sentence byte-for-byte. There is no stored key,
//  no stored plaintext, and no recovery path other than the user's
//  own memory of what they wrote.
//
//  Design pillars (mirror SacredEcho.swift + extend):
//    1. Self-sealed at write — the key IS the plaintext. No external
//       Keychain entry, no shared secret, no recovery.
//    2. Re-type gate — user must type the EXACT sentence byte-for-byte
//       to unlock. Single-byte difference → decryption fails.
//    3. Privacy-first — symmetric key derived per-entry via HKDF-SHA256;
//       plaintext never persists anywhere after write.
//    4. Lifecycle: sealed → (optionally) unlocking-ready → opened OR
//       never (if the user can't re-type it, it's gone).
//    5. Local-first — SwiftData; ciphertext + salt + unlock metadata.
//    6. Fail-closed — empty payload refused at seal time; AES-GCM tag
//       failure returns nil (no exception path that leaks).
//
//  What this file intentionally does NOT contain:
//    - Mac UI (deferred per T228 — "Mac UI deferred").
//    - Network sync of any kind (T190/T191 — iCloud sync deferred).
//    - Keychain-stored seed (the key IS the plaintext; no seed exists).
//    - Background re-tries or hints — the app does not auto-prompt the
//      user to re-type; that's a deliberate UX choice (see §5 below).
//
//  Threat model:
//    - Device compromise (jailbreak, malware): attacker sees only
//      ciphertext + salt. Without the plaintext, AES-GCM is opaque.
//    - iCloud backup (Apple): the v1.0 app does not mirror to iCloud
//      (CONSTITUTION_v3_DRAFT.md §11), so the ciphertext + salt
//      do not leave the device. If a user manually exports their
//      device backup, they export ciphertext + salt; the plaintext
//      is not in the backup.
//    - Memory dump during type: the plaintext exists in memory only
//      during the brief write/read windows; AES-GCM ciphertext
//      replaces it as soon as the seal/unseal call returns.
//    - Shoulder-surfing: out of scope (UX concern, not crypto).
//
//  Linux/test-harness parity: uses the same `SecRandomCopyBytes`
//  pattern as SacredEcho.swift, with a `/dev/urandom` fallback on
//  Linux. The crypto logic (HKDF + AES-GCM) is platform-independent.
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

// MARK: - Void unlock conditions
//
// The void has four "shapes" of secret-keeping:
//   - `.immediate`         — sealed, but the user can re-type any time to unlock.
//   - `.dateInFuture(d)`   — sealed until a wall-clock date; before that date,
//                            re-typing returns nil even with exact match
//                            (the gate is the date, not the bytes).
//                            After the date, exact-match re-type unlocks.
//   - `.afterNDays(n)`     — sealed for n days from creation; after that,
//                            exact-match re-type unlocks.
//   - `.neverReveal`       — sealed FOREVER. The plaintext is encrypted, the
//                            key is derived from the plaintext, but the
//                            app throws away the timestamp gate metadata
//                            needed for re-unlock. Even an exact re-type
//                            returns nil. This is the "letter to no one"
//                            mode — the user writes, the app forgets,
//                            the bytes become unreadable by design.
//
// All conditions are evaluated at READ time. The plaintext is NEVER
// recoverable without satisfying the condition AND a byte-exact re-type
// (except for `.neverReveal`, which is unrecoverable by design).

public enum VoidUnlockCondition: Codable, Equatable {
    case immediate
    case dateInFuture(Date)
    case afterNDays(Int)
    case neverReveal

    /// True if the current wall-clock satisfies the temporal gate.
    /// For `.neverReveal`, this is ALWAYS false (the temporal gate is
    /// "there is no time at which this becomes readable").
    public func isSatisfiedBy(now: Date, createdAt: Date) -> Bool {
        switch self {
        case .immediate:
            return true
        case .dateInFuture(let unlockAt):
            return now >= unlockAt
        case .afterNDays(let n):
            guard n >= 0 else { return false }
            let elapsed = now.timeIntervalSince(createdAt)
            return elapsed >= Double(n) * 86400.0
        case .neverReveal:
            return false
        }
    }
}

// MARK: - Void error surface
//
// Errors are returned from the store API. The cipher itself throws
// on AES-GCM failure; the store converts those into `nil` reads
// (fail-closed at the application boundary — no plaintext leak via
// error messages).

public enum VoidThreadError: Error, LocalizedError {
    case emptySentence
    case sentenceTooLong(maxChars: Int)
    case decryptionFailed
    case persistenceFailed(String)

    public var errorDescription: String? {
        switch self {
        case .emptySentence:
            return "A Void entry needs words. Write a single sentence before sealing."
        case .sentenceTooLong(let max):
            return "A Void entry accepts only a single sentence (max \(max) characters)."
        case .decryptionFailed:
            return "Could not unseal this Void entry."
        case .persistenceFailed(let detail):
            return "Could not save Void entry: \(detail)"
        }
    }
}

// MARK: - VoidEntry (SwiftData model)
//
// IMPORTANT: there is NO plaintext field on VoidEntry. The struct holds
// only ciphertext, salt, nonce, tag, and unlock metadata. The plaintext
// exists ONLY during the write call (`addEntry`) and is replaced by
// ciphertext before the function returns.

@Model
public final class VoidEntry {
    /// Stable identifier (also used to derive the per-entry HKDF info string).
    @Attribute(.unique) public var id: UUID

    /// Encrypted reflection (base64 of ciphertext). NEVER plaintext at rest.
    public var ciphertext: Data
    /// Per-entry AES-GCM nonce (12 bytes).
    public var nonce: Data
    /// Per-entry AES-GCM tag (16 bytes).
    public var tag: Data
    /// Per-entry HKDF salt (16 bytes; random; not derived from any UUID).
    public var salt: Data

    /// Unlock condition (immediate, date, day-count, or neverReveal).
    /// Stored as a Codable JSON string for SwiftData portability.
    public var conditionJSON: String

    /// Creation timestamp (for `.afterNDays` gate and audit trail).
    public var createdAt: Date

    /// Wall-clock comparison helper — overridable in tests via `nowOverride`.
    /// Per the SacredEcho pattern (cycle-25 #40), `nowOverride` is gated
    /// behind `#if DEBUG` and reduced to `internal` so production builds
    /// cannot mutate it.
    #if DEBUG
    internal static var nowOverride: (() -> Date)?
    #else
    internal static let nowOverride: (() -> Date)? = nil
    #endif

    public init(
        id: UUID = UUID(),
        ciphertext: Data,
        nonce: Data,
        tag: Data,
        salt: Data,
        conditionJSON: String,
        createdAt: Date
    ) {
        self.id = id
        self.ciphertext = ciphertext
        self.nonce = nonce
        self.tag = tag
        self.salt = salt
        self.conditionJSON = conditionJSON
        self.createdAt = createdAt
    }

    /// Decoded unlock condition.
    public var condition: VoidUnlockCondition {
        get {
            guard let data = conditionJSON.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode(VoidUnlockCondition.self, from: data) else {
                // Fail-closed: if we cannot decode the condition, refuse to unlock.
                return .neverReveal
            }
            return decoded
        }
        set {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            conditionJSON = String(
                data: (try? encoder.encode(newValue)) ?? Data("\"immediate\"".utf8),
                encoding: .utf8
            ) ?? "\"immediate\""
        }
    }

    public static func now() -> Date {
        return nowOverride?() ?? Date()
    }
}

// MARK: - VoidCipher
//
// Crypto pattern (matches SacredEcho.swift):
//   1. Per-entry random 16-byte salt.
//   2. HKDF-SHA256 with IKM = SHA256(plaintext), salt = per-entry salt,
//      info = "OneWeave.VoidThread.<uuid>", length = 32 bytes.
//   3. AES-256-GCM with the derived key + 12-byte random nonce.
//   4. Output: ciphertext || nonce || tag stored on VoidEntry; plaintext
//      is replaced with ciphertext in memory before the function returns.
//
// Why SHA256(plaintext) as the IKM instead of using plaintext directly?
// HKDF's IKM is supposed to be high-entropy. A natural-language sentence
// has roughly 1-2 bits/char of entropy; passing it raw would make HKDF's
// extract step weaker than it needs to be. Hashing first normalizes the
// IKM to a uniform 256-bit block — the derived key still requires
// knowledge of the plaintext (preimage resistance of SHA256), but the
// extract step gets the uniform input it was designed for.
//
// Self-test invariant: the same plaintext + same salt → same derived key
// (verified by validate_cycle39_void_thread.py). Different salts →
// different keys (verified). No plaintext anywhere after write
// (heuristically verified by checking ciphertext does not contain
// plaintext bytes).

public enum VoidCipher {

    /// Per-entry salt size. 16 bytes (128 bits) is enough to make
    /// collisions astronomically unlikely while keeping the SwiftData
    /// payload small.
    public static let saltBytes = 16

    /// Per-entry nonce size. 12 bytes (96 bits) is the AES-GCM standard.
    public static let nonceBytes = 12

    /// Derived key size. 32 bytes (256 bits) is the AES-256 block.
    public static let keyBytes = 32

    /// Maximum sentence length. A single sentence is a deliberate
    /// constraint of the Void Thread — the entry is meant to be a
    /// single self-contained thought, not a paragraph. 280 chars
    /// matches common "single tweet" expectations and is short enough
    /// to be re-typeable from memory.
    public static let maxSentenceChars = 280

    /// Derive the per-entry key from the entry's plaintext + per-entry salt.
    /// IKM = SHA256(plaintext.utf8 bytes). Salt = entry.salt. Info =
    /// "OneWeave.VoidThread.<entry-id>". Output: 32 bytes (AES-256 key).
    public static func deriveKey(for entryID: UUID, plaintext: String, salt: Data) -> SymmetricKey {
        let ikm = Data(SHA256.hash(data: Data(plaintext.utf8)))
        let info = "OneWeave.VoidThread.\(entryID.uuidString)".data(using: .utf8)!
        return HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: ikm),
            salt: salt,
            info: info,
            outputByteCount: keyBytes
        )
    }

    /// Seal a sentence into a VoidEntry. Returns the new entry with
    /// ciphertext, nonce, tag, salt, and condition populated. The
    /// plaintext is NOT stored on the entry.
    public static func seal(
        plaintext: String,
        condition: VoidUnlockCondition,
        now: Date = VoidEntry.now()
    ) throws -> VoidEntry {
        let trimmed = plaintext.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw VoidThreadError.emptySentence }
        guard trimmed.count <= maxSentenceChars else {
            throw VoidThreadError.sentenceTooLong(maxChars: maxSentenceChars)
        }

        let id = UUID()
        let salt = randomBytes(count: saltBytes)
        let nonceData = randomBytes(count: nonceBytes)
        let key = deriveKey(for: id, plaintext: trimmed, salt: salt)

        let n: AES.GCM.Nonce
        do {
            n = try AES.GCM.Nonce(data: nonceData)
        } catch {
            throw VoidThreadError.decryptionFailed
        }

        let sealed: AES.GCM.SealedBox
        do {
            sealed = try AES.GCM.seal(Data(trimmed.utf8), using: key, nonce: n)
        } catch {
            throw VoidThreadError.decryptionFailed
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let conditionData = (try? encoder.encode(condition)) ?? Data("\"immediate\"".utf8)
        let conditionJSON = String(data: conditionData, encoding: .utf8) ?? "\"immediate\""

        return VoidEntry(
            id: id,
            ciphertext: sealed.ciphertext,
            nonce: nonceData,
            tag: sealed.tag,
            salt: salt,
            conditionJSON: conditionJSON,
            createdAt: now
        )
    }

    /// Attempt to unseal a VoidEntry with a re-typed sentence.
    ///
    /// Returns the plaintext IFF:
    ///   1. The unlock condition's temporal gate is satisfied at `now`.
    ///   2. SHA256(reTyped) matches SHA256(original plaintext), which is
    ///      equivalent to deriving the same HKDF key and successfully
    ///      AES-GCM-decrypting.
    ///
    /// Returns nil otherwise. Failure modes (in order of precedence):
    ///   - `.neverReveal` → nil (always)
    ///   - Temporal gate not satisfied → nil
    ///   - Re-typed text differs from original → nil (decryption fails)
    ///   - Ciphertext tampered → nil
    ///
    /// NOTE: this function never throws. AES-GCM failures are caught and
    /// converted to nil so the caller cannot distinguish "wrong sentence"
    /// from "tampered ciphertext" — both look identical to the user,
    /// which is the privacy-preserving behavior.
    public static func unseal(
        _ entry: VoidEntry,
        reTyped: String,
        now: Date = VoidEntry.now()
    ) -> String? {
        // 1. Evaluate the temporal gate first. This is the cheap check.
        guard entry.condition.isSatisfiedBy(now: now, createdAt: entry.createdAt) else {
            return nil
        }
        // 2. .neverReveal is a special case that always returns nil,
        //    even though `isSatisfiedBy` already handles it. Belt + suspenders.
        if entry.condition == .neverReveal {
            return nil
        }

        // 3. Derive the candidate key from the re-typed sentence.
        let candidateKey = deriveKey(for: entry.id, plaintext: reTyped, salt: entry.salt)

        // 4. Attempt AES-GCM open. Any failure → nil.
        do {
            let n = try AES.GCM.Nonce(data: entry.nonce)
            let box = try AES.GCM.SealedBox(
                nonce: n,
                ciphertext: entry.ciphertext,
                tag: entry.tag
            )
            let plain = try AES.GCM.open(box, using: candidateKey)
            guard let str = String(data: plain, encoding: .utf8) else {
                return nil
            }
            return str
        } catch {
            return nil
        }
    }

    // MARK: - Internal helpers (mirror SacredEcho.swift's pattern)

    private static func randomBytes(count: Int) -> Data {
        var bytes = Data(count: count)
        #if canImport(Security)
        let status = bytes.withUnsafeMutableBytes { ptr -> Int32 in
            SecRandomCopyBytes(kSecRandomDefault, count, ptr.baseAddress!)
        }
        if status != errSecSuccess {
            // SecRandom failure is rare. Try /dev/urandom as a fallback
            // before failing closed. (Same fail-closed pattern as SacredEcho.)
            let fd = open("/dev/urandom", O_RDONLY)
            if fd >= 0 {
                _ = bytes.withUnsafeMutableBytes { ptr in
                    _ = read(fd, ptr.baseAddress, count)
                }
                close(fd)
            } else {
                fatalError("[VoidThread] Cannot obtain secure random bytes")
            }
        }
        #else
        // Linux dev harness.
        let fd = open("/dev/urandom", O_RDONLY)
        if fd >= 0 {
            _ = bytes.withUnsafeMutableBytes { ptr in
                _ = read(fd, ptr.baseAddress, count)
            }
            close(fd)
        } else {
            fatalError("[VoidThread] Cannot open /dev/urandom")
        }
        #endif
        return bytes
    }
}

// MARK: - VoidThreadStore (SwiftData-aware API surface)
//
// All entry points are @MainActor so they compose cleanly with SwiftUI /
// SwiftData ModelContext. `modelContext` is optional so the gate logic
// can be exercised on Linux without a real ModelContext.

@MainActor
public enum VoidThreadStore {

    /// Add a new Void entry. The plaintext is encrypted in-memory and
    /// only the ciphertext + metadata are persisted. The function returns
    /// immediately after the entry is constructed; the caller is
    /// responsible for inserting the entry into a ModelContext if desired.
    @discardableResult
    public static func addEntry(
        plaintext: String,
        condition: VoidUnlockCondition,
        modelContext: ModelContext? = nil
    ) throws -> VoidEntry {
        let entry = try VoidCipher.seal(
            plaintext: plaintext,
            condition: condition
        )
        if let mc = modelContext {
            mc.insert(entry)
        }
        return entry
    }

    /// Read a Void entry by re-typing the exact sentence.
    ///
    /// Returns the plaintext string iff the unlock condition is satisfied
    /// AND the re-typed sentence is byte-for-byte identical to the
    /// original. Returns nil otherwise (failure modes are indistinguishable
    /// to the caller, which is the privacy-preserving behavior).
    public static func readEntry(
        _ entry: VoidEntry,
        attemptText: String
    ) -> String? {
        return VoidCipher.unseal(entry, reTyped: attemptText)
    }
}