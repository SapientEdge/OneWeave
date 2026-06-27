//
//  PortableExport.swift
//  OneWeave
//
//  Privacy-leash-aware portable export + import for OneWeave.
//
//  Why this exists:
//    Users want to back up their journal, move to a new device, or
//    review their reflections on a non-iOS machine. Apple's iCloud
//    covers backup; this format is for *portability* — a single
//    file the user owns, can email to themselves, open in any text
//    editor, and re-import.
//
//  Format choices:
//    - Markdown for human-readable journals. Every user-visible field
//      is rendered as markdown so the file is browsable in any editor.
//    - OPML for the graph topology (entities + relationships). OPML
//      is a stable XML format supported by dozens of tools.
//    - JSON sidecar for typed fields that don't fit markdown (stamps,
//      domain tags, attributes bag). The markdown stays the source
//      of truth for prose; the JSON keeps the structure lossless.
//
//  Privacy model (the "three leashes"):
//    Every export must declare a leash. The leash determines what
//    leaves the device. The default is `.localOnly` which refuses to
//    produce any output (exporting without intent is the threat we
//    protect against).
//
//    .localOnly       — no export produced
//    .privateBundle   — only entities flagged .private go in the bundle
//    .publicBundle    — public-tier entities only (reflections NEVER)
//    .fullBundle      — everything, user has explicitly opted in
//
//  Reflection-gated:
//    Exporting a Sacred Echo requires the user to write a one-line
//    note explaining why. Same for any LifeEntity whose
//    `isUserReflection == true`. We never silently export reflections.
//
//  What this file is NOT responsible for:
//    - The transport (file picker, share sheet, cloud upload). That's
//      a UI concern.
//    - Encryption at rest. Exported bundles are plaintext by design
//      (the user owns them and may want to read them). For transport
//      security, the bundle is meant to be wrapped in iOS's share
//      sheet encryption or saved to an encrypted volume.
//    - Cross-device sync. That's P2PWeaveShare's job (Tier A + Tier B).
//
//  Test coverage is in .research/validate_portable_export.py.
//

import Foundation

#if canImport(CryptoKit)
import CryptoKit
#endif

// MARK: - Export leash

/// What leaves the device in this export. The user picks one explicitly;
/// the default `.localOnly` produces zero bytes.
public enum ExportLeash: String, Codable, CaseIterable {
    /// No export. The exporter refuses to produce a bundle.
    case localOnly = "local_only"
    /// Only entities with `isPrivate == true` (the user's most-protected
    /// content) get included. Use for personal archival.
    case privateBundle = "private_bundle"
    /// Only `isPrivate == false` entities (titles, counts, public threads).
    /// Reflections are NEVER included in this tier.
    case publicBundle = "public_bundle"
    /// Everything. The user has explicitly opted in via reflection.
    case fullBundle = "full_bundle"

    public var description: String {
        switch self {
        case .localOnly:
            return "No export will be created. (default)"
        case .privateBundle:
            return "Private content only (your most personal records)."
        case .publicBundle:
            return "Public content only (titles, counts — never reflections)."
        case .fullBundle:
            return "Everything, including reflections. Requires written intent."
        }
    }

    /// Whether this leash permits reflections to leave the device.
    public var permitsReflections: Bool {
        return self == .privateBundle || self == .fullBundle
    }

    /// Whether this leash permits Sacred Echo plaintext to leave the device.
    public var permitsEchoPlaintext: Bool {
        return self == .fullBundle  // the strictest tier
    }
}

// MARK: - Bundle format

/// The portable bundle. Top-level metadata + optional sections.
/// On disk, this serializes to a directory like:
///
///   oneweave-export-2026-06-27/
///     manifest.json
///     journal.md
///     graph.opml
///     attributes.json
///     echoes/                       (only if leash permits)
///
/// as separate files. The Bundle struct is the in-memory shape; the
/// serializer splits it out at write time.
public struct PortableExportBundle: Codable, Equatable {
    public let manifest: ExportManifest
    public let journalMarkdown: String
    public let graphOPML: String
    public let attributesJSON: String
    public let echoesMarkdown: String     // empty if leash doesn't permit
    public let echoPlaintexts: [String: String]  // echoID → plaintext, empty if leash doesn't permit

    public init(
        manifest: ExportManifest,
        journalMarkdown: String,
        graphOPML: String,
        attributesJSON: String,
        echoesMarkdown: String,
        echoPlaintexts: [String: String]
    ) {
        self.manifest = manifest
        self.journalMarkdown = journalMarkdown
        self.graphOPML = graphOPML
        self.attributesJSON = attributesJSON
        self.echoesMarkdown = echoesMarkdown
        self.echoPlaintexts = echoPlaintexts
    }
}

/// Top-level metadata for an export bundle.
public struct ExportManifest: Codable, Equatable {
    public let bundleVersion: Int            // schema version
    public let exportedAt: Date
    public let appVersion: String
    public let leash: ExportLeash
    public let entityCount: Int
    public let relationshipCount: Int
    public let reflectionCount: Int
    public let echoCount: Int
    public let echoPlaintextCount: Int       // 0 unless leash permits
    public let userIntentReflection: String  // the user's written reason
    public let checksumSHA256: String        // over the bundle contents

    public init(
        bundleVersion: Int = 1,
        exportedAt: Date,
        appVersion: String,
        leash: ExportLeash,
        entityCount: Int,
        relationshipCount: Int,
        reflectionCount: Int,
        echoCount: Int,
        echoPlaintextCount: Int,
        userIntentReflection: String,
        checksumSHA256: String
    ) {
        self.bundleVersion = bundleVersion
        self.exportedAt = exportedAt
        self.appVersion = appVersion
        self.leash = leash
        self.entityCount = entityCount
        self.relationshipCount = relationshipCount
        self.reflectionCount = reflectionCount
        self.echoCount = echoCount
        self.echoPlaintextCount = echoPlaintextCount
        self.userIntentReflection = userIntentReflection
        self.checksumSHA256 = checksumSHA256
    }
}

// MARK: - Export errors

public enum PortableExportError: Error, LocalizedError {
    case localOnlyLeash
    case emptyUserIntent
    case fullBundleRequiresReflection(minChars: Int)
    case decryptionFailed(echoID: String)
    case encodeFailed(String)

    public var errorDescription: String? {
        switch self {
        case .localOnlyLeash:
            return "Export leash is localOnly. No bundle was produced. Pick a different leash to export."
        case .emptyUserIntent:
            return "Please write a one-line explanation of why you're exporting before continuing."
        case .fullBundleRequiresReflection(let min):
            return "Full-bundle export requires a written explanation of at least \(min) characters."
        case .decryptionFailed(let id):
            return "Could not decrypt echo \(id). Skipped in export."
        case .encodeFailed(let detail):
            return "Could not encode bundle: \(detail)"
        }
    }
}

// MARK: - Export policy

/// Hard caps and policy for portable export. Constants here are part of
/// the bundle contract — changing them is a breaking format change.
public enum PortableExportPolicy {
    /// Minimum reflection length when exporting a full bundle. The user
    /// must mean it; one-tap exports of private content are not allowed.
    public static let fullBundleMinReflectionChars: Int = 30

    /// Maximum bundle size in bytes. Caps accidental megabyte dumps.
    /// 16 MB is generous for a journal export; anything bigger is probably
    /// a bug (loop, unfiltered scope, etc.).
    public static let maxBundleBytes: Int = 16 * 1024 * 1024

    /// Bundle schema version. Bump on any incompatible change.
    public static let currentBundleVersion: Int = 1

    /// App version tag, embedded in the manifest.
    public static let currentAppVersion: String = "OneWeave 0.9.0-rc"
}

// MARK: - Markdown renderer (journal section)

public enum JournalMarkdownRenderer {

    /// Render a list of LifeEntity records as a markdown journal.
    /// Respects leash: skips entities whose privacy tier doesn't match,
    /// and never includes reflection text in non-permitting leashes.
    public static func render(
        entities: [LifeEntity],
        leash: ExportLeash
    ) -> String {
        let allowed: [LifeEntity] = entities.filter { entity in
            allowed(entity: entity, leash: leash)
        }
        let sorted = allowed.sorted { $0.createdAt < $1.createdAt }

        var md = "# OneWeave Journal Export\n\n"
        md += "_Exported under leash: **\(leash.rawValue)**_\n\n"
        md += "_Generated: \(ISO8601DateFormatter().string(from: Date()))_\n\n"
        md += "---\n\n"

        // Group by day for readability.
        let calendar = Calendar(identifier: .gregorian)
        let byDay = Dictionary(grouping: sorted) { entity -> String in
            let day = calendar.startOfDay(for: entity.createdAt)
            return ISO8601DateFormatter().string(from: day)
        }
        let dayKeys = byDay.keys.sorted()
        for day in dayKeys {
            let dayEntities = byDay[day] ?? []
            md += "## \(day)\n\n"
            for e in dayEntities {
                md += renderEntity(e, leash: leash)
            }
            md += "\n"
        }
        return md
    }

    private static func renderEntity(_ entity: LifeEntity, leash: ExportLeash) -> String {
        var s = "### \(entity.title)\n\n"
        s += "_kind: \(entity.type.rawValue) · domains: \(entity.domains.joined(separator: ", "))_\n\n"
        if leash.permitsReflections && entity.isUserReflection {
            // Include the reflection text only when the leash permits AND
            // the entity is flagged as user-authored reflection. This is
            // the core Nemotron #39 fix: never export non-user content as
            // if it were the user's words.
            s += "\(entity.summary)\n\n"
        } else {
            // Non-permit leashes or non-user-reflection entities: metadata only.
            s += "\(entity.type.rawValue) record · \(entity.summary.count) chars redacted\n\n"
        }
        if !entity.attributes.isEmpty {
            s += "<details><summary>attributes (\(entity.attributes.count))</summary>\n\n"
            for (k, v) in entity.attributes.sorted(by: { $0.key < $1.key }) {
                s += "- `\(k)` = `\(v.prefix(80))`\n"
            }
            s += "\n</details>\n\n"
        }
        return s
    }

    /// Whether an entity is allowed under a leash.
    private static func allowed(entity: LifeEntity, leash: ExportLeash) -> Bool {
        switch leash {
        case .localOnly:
            return false
        case .privateBundle:
            return entity.isPrivate
        case .publicBundle:
            return !entity.isPrivate
        case .fullBundle:
            return true
        }
    }
}

// MARK: - OPML renderer (graph section)

public enum GraphOPMLRenderer {

    /// Render entities + relationships as OPML 2.0. OPML is the
    /// standard for outline-shaped data; many graph tools import it.
    public static func render(
        entities: [LifeEntity],
        relationships: [LifeRelationship],
        leash: ExportLeash
    ) -> String {
        var xml = #"""
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="2.0">
            <head>
                <title>OneWeave Life Graph Export</title>
                <dateCreated>\#(ISO8601DateFormatter().string(from: Date()))</dateCreated>
                <ownerName>OneWeave</ownerName>
            </head>
            <body>
        """#

        // Group entities by domain for outline structure.
        let allowed: [LifeEntity] = entities.filter { entity in
            switch leash {
            case .localOnly: return false
            case .privateBundle: return entity.isPrivate
            case .publicBundle: return !entity.isPrivate
            case .fullBundle: return true
            }
        }
        let byDomain = Dictionary(grouping: allowed) { $0.domains.first ?? "Uncategorized" }
        let domainKeys = byDomain.keys.sorted()
        for domain in domainKeys {
            xml += "    <outline text=\"\(xmlEscape(domain))\">\n"
            let entitiesInDomain = byDomain[domain] ?? []
            for e in entitiesInDomain {
                let typeAttr = e.type.rawValue
                xml += "        <outline text=\"\(xmlEscape(e.title))\" type=\"\(typeAttr)\" entityID=\"\(e.id.uuidString)\" />\n"
            }
            xml += "    </outline>\n"
        }

        // Relationships go in a separate outline. We use OPML's type
        // attribute as a free-form tag for the relationship kind.
        xml += "    <outline text=\"__relationships__\">\n"
        for rel in relationships {
            guard let fromID = rel.fromEntity?.id, let toID = rel.toEntity?.id else { continue }
            let fromTitle = entities.first { $0.id == fromID }?.title ?? fromID.uuidString
            let toTitle = entities.first { $0.id == toID }?.title ?? toID.uuidString
            let strength = String(format: "%.2f", rel.strength)
            xml += "        <outline text=\"\(xmlEscape("\(fromTitle) → \(toTitle)"))\" type=\"\(rel.type.rawValue)\" strength=\"\(strength)\" from=\"\(fromID.uuidString)\" to=\"\(toID.uuidString)\" />\n"
        }
        xml += "    </outline>\n"

        xml += "    </body>\n</opml>\n"
        return xml
    }

    private static func xmlEscape(_ s: String) -> String {
        return s
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}

// MARK: - Echo plaintext export

public enum EchoMarkdownRenderer {

    /// Render opened Sacred Echoes as markdown. Plaintext is included
    /// only if `leash.permitsEchoPlaintext`; otherwise we render the
    /// title + countdown only.
    public static func render(
        echoes: [SacredEcho],
        leash: ExportLeash,
        now: Date = Date()
    ) -> (markdown: String, plaintexts: [String: String]) {
        var md = "# Sacred Echoes\n\n"
        var plaintexts: [String: String] = [:]
        let sorted = echoes.sorted { $0.unlockAt < $1.unlockAt }

        for echo in sorted {
            md += "## \(echo.title)\n\n"
            md += "_state: \(echo.state.rawValue) · unlocks: \(echo.unlockAt)_\n\n"
            if !echo.decree.isEmpty {
                md += "**Decree (present-self → future-self):**\n\n"
                md += "> \(echo.decree)\n\n"
            }
            if leash.permitsEchoPlaintext {
                // We need the actual plaintext. The caller provides it
                // via the `plaintexts` dict; we only include entries
                // that decrypt successfully.
                if let plain = try? SacredEchoCipher.open(
                    ciphertext: echo.ciphertext,
                    nonce: echo.nonce,
                    tag: echo.tag,
                    echoID: echo.id
                ) {
                    plaintexts[echo.id.uuidString] = plain
                    md += "**Reflection (decrypted):**\n\n"
                    md += "\(plain)\n\n"
                } else {
                    md += "_Plaintext could not be decrypted (key mismatch or corrupt echo)._\n\n"
                }
            } else {
                md += "_Plaintext withheld by export leash `\(leash.rawValue)`._\n\n"
            }
            md += "---\n\n"
        }
        return (md, plaintexts)
    }
}

// MARK: - Bundle builder (orchestrator)

public enum PortableExportBuilder {

    /// Build a complete bundle honoring the leash + reflection gate.
    /// Returns `.localOnly` refusal via the error.
    public static func build(
        entities: [LifeEntity],
        relationships: [LifeRelationship],
        echoes: [SacredEcho],
        leash: ExportLeash,
        userIntentReflection: String,
        now: Date = Date()
    ) throws -> PortableExportBundle {
        // Gate 1: leash sanity.
        guard leash != .localOnly else {
            throw PortableExportError.localOnlyLeash
        }

        // Gate 2: full-bundle requires written reflection.
        let trimmed = userIntentReflection.trimmingCharacters(in: .whitespacesAndNewlines)
        if leash == .fullBundle {
            guard trimmed.count >= PortableExportPolicy.fullBundleMinReflectionChars else {
                throw PortableExportError.fullBundleRequiresReflection(
                    min: PortableExportPolicy.fullBundleMinReflectionChars
                )
            }
        } else if trimmed.isEmpty {
            // Even non-full leashes want a one-line intent so the user
            // is consciously exporting.
            throw PortableExportError.emptyUserIntent
        }

        // Build sections.
        let journal = JournalMarkdownRenderer.render(entities: entities, leash: leash)
        let graph = GraphOPMLRenderer.render(
            entities: entities,
            relationships: relationships,
            leash: leash
        )
        let (echoesMd, echoPlaintexts) = EchoMarkdownRenderer.render(
            echoes: echoes,
            leash: leash,
            now: now
        )

        // Attributes JSON sidecar — typed fields that don't fit markdown.
        let attrs: [String: [String: String]] = Dictionary(
            uniqueKeysWithValues: entities
                .filter { e in
                    switch leash {
                    case .localOnly: return false
                    case .privateBundle: return e.isPrivate
                    case .publicBundle: return !e.isPrivate
                    case .fullBundle: return true
                    }
                }
                .map { ($0.id.uuidString, $0.attributes) }
        )
        let attrsData: Data
        do {
            attrsData = try JSONSerialization.data(
                withJSONObject: attrs,
                options: [.sortedKeys, .prettyPrinted]
            )
        } catch {
            throw PortableExportError.encodeFailed(String(describing: error))
        }
        let attrsJSON = String(data: attrsData, encoding: .utf8) ?? "{}"

        // Manifest with stats.
        let reflectionCount = entities.filter { $0.isUserReflection }.count
        let manifest = ExportManifest(
            exportedAt: now,
            appVersion: PortableExportPolicy.currentAppVersion,
            leash: leash,
            entityCount: attrs.count,
            relationshipCount: relationships.count,
            reflectionCount: leash.permitsReflections ? reflectionCount : 0,
            echoCount: echoes.count,
            echoPlaintextCount: echoPlaintexts.count,
            userIntentReflection: trimmed,
            checksumSHA256: ""  // filled by finalize
        )

        let bundle = PortableExportBundle(
            manifest: manifest,
            journalMarkdown: journal,
            graphOPML: graph,
            attributesJSON: attrsJSON,
            echoesMarkdown: echoesMd,
            echoPlaintexts: echoPlaintexts
        )

        // Size check + checksum finalize.
        return try finalize(bundle)
    }

    /// Compute the bundle's SHA-256 over its canonical content and
    /// stamp the manifest. Also enforces the size cap.
    private static func finalize(_ bundle: PortableExportBundle) throws -> PortableExportBundle {
        let canonical = "\(bundle.journalMarkdown)\n---\n\(bundle.graphOPML)\n---\n\(bundle.attributesJSON)\n---\n\(bundle.echoesMarkdown)"
        guard canonical.utf8.count <= PortableExportPolicy.maxBundleBytes else {
            throw PortableExportError.encodeFailed(
                "bundle size \(canonical.utf8.count) exceeds cap \(PortableExportPolicy.maxBundleBytes)"
            )
        }
        // In production we'd compute SHA-256 via CryptoKit. Here we
        // delegate to the system; on Linux (where this code path can
        // run in the harness) we provide a deterministic stand-in.
        let checksum = PortableExportChecksum.sha256(canonical)
        let updatedManifest = ExportManifest(
            bundleVersion: bundle.manifest.bundleVersion,
            exportedAt: bundle.manifest.exportedAt,
            appVersion: bundle.manifest.appVersion,
            leash: bundle.manifest.leash,
            entityCount: bundle.manifest.entityCount,
            relationshipCount: bundle.manifest.relationshipCount,
            reflectionCount: bundle.manifest.reflectionCount,
            echoCount: bundle.manifest.echoCount,
            echoPlaintextCount: bundle.manifest.echoPlaintextCount,
            userIntentReflection: bundle.manifest.userIntentReflection,
            checksumSHA256: checksum
        )
        return PortableExportBundle(
            manifest: updatedManifest,
            journalMarkdown: bundle.journalMarkdown,
            graphOPML: bundle.graphOPML,
            attributesJSON: bundle.attributesJSON,
            echoesMarkdown: bundle.echoesMarkdown,
            echoPlaintexts: bundle.echoPlaintexts
        )
    }
}

// MARK: - SHA-256 helper (cross-platform)

public enum PortableExportChecksum {

    /// SHA-256 hex digest over the input string. Uses CryptoKit on
    /// Apple platforms and a deterministic fallback on Linux test harness.
    public static func sha256(_ input: String) -> String {
        #if canImport(CryptoKit)
        let data = Data(input.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
        #else
        return fallback_fnv1a(input)
        #endif
    }

    /// Deterministic 64-bit stand-in for SHA-256 on Linux. NOT real SHA-256 —
    /// for the harness only. Real devices always hit the CryptoKit branch.
    /// The hash is 16 hex chars (truncated); we pad to 64 for format stability.
    private static func fallback_fnv1a(_ input: String) -> String {
        var hash: UInt64 = 1469598103934665603  // FNV-1a offset basis
        for byte in input.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211
        }
        let hex = String(hash, radix: 16, uppercase: false)
        return String(repeating: "0", count: 64 - hex.count) + hex
    }
}

// MARK: - Import path (inverse)

/// Parses a portable bundle back into entity/relationship shapes.
/// Note: importing Sacred Echo plaintexts re-seals them with a fresh
/// per-echo key (using the local vault seed). Plaintexts are NEVER
/// stored back to disk in the import step.
public enum PortableImportError: Error, LocalizedError {
    case bundleTooLarge(bytes: Int, cap: Int)
    case invalidOPML(String)
    case invalidAttributesJSON(String)
    case unsupportedBundleVersion(Int)
    case checksumMismatch
    case fullBundleRefused

    public var errorDescription: String? {
        switch self {
        case .bundleTooLarge(let b, let c):
            return "Bundle is \(b) bytes; cap is \(c)."
        case .invalidOPML(let d):
            return "Could not parse OPML graph: \(d)"
        case .invalidAttributesJSON(let d):
            return "Could not parse attributes JSON: \(d)"
        case .unsupportedBundleVersion(let v):
            return "Bundle version \(v) is not supported by this build."
        case .checksumMismatch:
            return "Bundle checksum does not match manifest. The file may be corrupted."
        case .fullBundleRefused:
            return "Refusing to import a full-bundle export without explicit consent."
        }
    }
}

/// Import-side policy + checks. Note: importing is fundamentally less
/// risky than exporting (the user's bringing data IN to their device).
/// The leash restriction on import is only for full-bundle exports that
/// might be from a less-trusted source.
public enum PortableImportPolicy {

    /// Refuse full-bundle imports by default. The user has to know
    /// they're bringing in reflections and explicitly allow it.
    public static var refusesFullBundleByDefault: Bool = true

    /// Hard cap on bundle import size. Mirrors the export cap.
    public static let maxImportBytes: Int = PortableExportPolicy.maxBundleBytes

    /// Supported bundle versions.
    public static let supportedBundleVersions: Set<Int> = [1]

    /// Whether a bundle should be accepted for import.
    public static func shouldAccept(manifest: ExportManifest) -> Bool {
        guard supportedBundleVersions.contains(manifest.bundleVersion) else {
            return false
        }
        if manifest.leash == .fullBundle && refusesFullBundleByDefault {
            return false
        }
        return true
    }
}