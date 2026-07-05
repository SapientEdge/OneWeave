//
//  MomentSealer.swift
//  OneWeave
//
//  Cycle 46 LifeMoment Phase B: plaintext and sealed payload envelopes.
//  Crypto implementation is intentionally deferred to T-B3.
//

import Foundation
import CryptoKit

#if canImport(Security)
import Security
#endif
#if canImport(Glibc)
import Glibc
#endif

/// Plaintext payload before sealing. Will be encrypted via MomentSealer.seal().
/// Stored only in memory during capture; never persisted unencrypted.
public struct MomentPayload: Codable, Sendable {
    public let ocrText: String
    public let imageEmbeddingText: String  // base64 or hex of [Float] serialized
    public let detectedEntitiesJSON: String  // raw JSON from Vision
    public let sealedAt: Date

    public init(ocrText: String, imageEmbeddingText: String, detectedEntitiesJSON: String) {
        self.ocrText = ocrText
        self.imageEmbeddingText = imageEmbeddingText
        self.detectedEntitiesJSON = detectedEntitiesJSON
        self.sealedAt = Date()
    }
}

/// What gets persisted to LifeMoment.sealedCiphertext / sealedNonce / sealedTag / sealedAt.
public struct SealedMoment: Codable, Sendable {
    public let ciphertext: Data
    public let nonce: Data       // 12 bytes for AES-GCM
    public let tag: Data         // 16 bytes for AES-GCM
    public let sealedAt: Date

    public init(ciphertext: Data, nonce: Data, tag: Data, sealedAt: Date) {
        self.ciphertext = ciphertext
        self.nonce = nonce
        self.tag = tag
        self.sealedAt = sealedAt
    }
}

// T-B3: seal/open functions live here.

// MARK: - MomentSealer crypto (T-B3)
//
// Mirrors SacredEcho pattern (vaultSeed + per-moment key + AES-GCM seal/open)
// with a dedicated HKDF info string so Moment keys cannot collide with
// SacredEcho keys.

public enum MomentSealerError: Error, LocalizedError {
    case seedUnavailable
    case randomFailure
    case decryptionFailed
    case keyDerivationFailed

    public var errorDescription: String? {
        switch self {
        case .seedUnavailable:
            return "Moment vault seed unavailable (Keychain denied)."
        case .randomFailure:
            return "Secure random number generator failed."
        case .decryptionFailed:
            return "Moment decryption failed (tampered or wrong key)."
        case .keyDerivationFailed:
            return "Moment key derivation failed."
        }
    }
}

public enum MomentSealer {
    /// HKDF info string for cryptographic isolation from SacredEcho keys.
    public static let hkdfInfo: String = "OneWeaveMoment.v1"

    // MARK: - Seed management

    /// Read or create the per-user moment vault seed from Keychain.
    /// On Linux/DEBUG, falls back to a deterministic test seed (test-only).
    public static func vaultSeed() throws -> SymmetricKey {
        #if canImport(Security)
        if let data = loadFromKeychain() {
            return SymmetricKey(data: data)
        }
        let newSeed = try randomBytes(count: 32)
        guard persistToKeychain(seed: newSeed) else {
            throw MomentSealerError.seedUnavailable
        }
        return SymmetricKey(data: newSeed)
        #else
        #if os(Linux) && DEBUG
        var bytes = [UInt8](repeating: 0, count: 32)
        for i in 0..<32 { bytes[i] = UInt8(i &+ 0xA5) }
        return SymmetricKey(data: Data(bytes))
        #else
        throw MomentSealerError.seedUnavailable
        #endif
        #endif
    }

    /// Derive a per-moment key from the vault seed + moment UUID.
    public static func perMomentKey(for momentID: UUID, seed: SymmetricKey) throws -> SymmetricKey {
        guard let info = hkdfInfo.data(using: .utf8) else {
            throw MomentSealerError.keyDerivationFailed
        }
        let salt = Data(momentID.uuidString.prefix(16).utf8)
        return HKDF<SHA256>.deriveKey(
            inputKeyMaterial: seed,
            salt: salt,
            info: info,
            outputByteCount: 32
        )
    }

    // MARK: - Seal / Open

    /// Encrypt a MomentPayload into a SealedMoment using AES-256-GCM with a per-moment key.
    /// Throws on random failure (fail-closed) or seed unavailability.
    public static func seal(_ payload: MomentPayload, momentID: UUID, seed: SymmetricKey? = nil) throws -> SealedMoment {
        let s = seed ?? (try vaultSeed())
        let key = try perMomentKey(for: momentID, seed: s)
        let nonceBytes = try randomBytes(count: 12)
        let nonce = try AES.GCM.Nonce(data: nonceBytes)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let plaintext: Data
        do {
            plaintext = try encoder.encode(payload)
        } catch {
            throw MomentSealerError.keyDerivationFailed
        }

        let sealed: AES.GCM.SealedBox
        do {
            sealed = try AES.GCM.seal(plaintext, using: key, nonce: nonce)
        } catch {
            throw MomentSealerError.keyDerivationFailed
        }

        return SealedMoment(
            ciphertext: sealed.ciphertext,
            nonce: Data(nonceBytes),
            tag: sealed.tag,
            sealedAt: payload.sealedAt
        )
    }

    /// Decrypt a SealedMoment back to a MomentPayload. Throws on tamper or wrong key.
    public static func open(_ sealed: SealedMoment, momentID: UUID, seed: SymmetricKey? = nil) throws -> MomentPayload {
        let s = seed ?? (try vaultSeed())
        let key = try perMomentKey(for: momentID, seed: s)
        let nonce: AES.GCM.Nonce
        do {
            nonce = try AES.GCM.Nonce(data: sealed.nonce)
        } catch {
            throw MomentSealerError.decryptionFailed
        }

        let box: AES.GCM.SealedBox
        do {
            box = try AES.GCM.SealedBox(nonce: nonce, ciphertext: sealed.ciphertext, tag: sealed.tag)
        } catch {
            throw MomentSealerError.decryptionFailed
        }

        let plain: Data
        do {
            plain = try AES.GCM.open(box, using: key)
        } catch {
            throw MomentSealerError.decryptionFailed
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(MomentPayload.self, from: plain)
        } catch {
            throw MomentSealerError.decryptionFailed
        }
    }

    // MARK: - Internal helpers

    private static func randomBytes(count: Int) throws -> Data {
        var bytes = Data(count: count)
        #if canImport(Security)
        let result = bytes.withUnsafeMutableBytes { ptr -> Int32 in
            guard let base = ptr.baseAddress else { return errSecAllocate }
            return SecRandomCopyBytes(kSecRandomDefault, count, base)
        }
        guard result == errSecSuccess else {
            throw MomentSealerError.randomFailure
        }
        return bytes
        #else
        #if os(Linux) && DEBUG
        let fd = Glibc.open("/dev/urandom", O_RDONLY)
        guard fd >= 0 else { throw MomentSealerError.randomFailure }
        defer { Glibc.close(fd) }
        let readCount = bytes.withUnsafeMutableBytes { ptr -> Int in
            guard let base = ptr.baseAddress else { return -1 }
            return Glibc.read(fd, base, count)
        }
        guard readCount == count else {
            throw MomentSealerError.randomFailure
        }
        return bytes
        #else
        throw MomentSealerError.randomFailure
        #endif
        #endif
    }

    #if canImport(Security)
    private static func loadFromKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.oneweave.momentvault.seed",
            kSecAttrAccount as String: "primary",
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

    @discardableResult
    private static func persistToKeychain(seed: Data) -> Bool {
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.oneweave.momentvault.seed",
            kSecAttrAccount as String: "primary"
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.oneweave.momentvault.seed",
            kSecAttrAccount as String: "primary",
            kSecValueData as String: seed,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
    }
    #endif
}
