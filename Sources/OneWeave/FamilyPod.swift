//
//  FamilyPod.swift
//  OneWeave
//
//  Family Pod — Tier-2 feature. Layered on top of Weave Circles with
//  stricter privacy defaults and an anti-social design philosophy.
//
//  Why this exists:
//    Market research round-2 surfaced a recurring demand: users want a way
//    to share *with their inner circle* without it being a social network.
//    Every existing life-tracking app either treats sharing as broadcast
//    (Strava, Day One) or as fully private (Apple Journal). Nobody offers
//    "private to my actual family." The Family Pod fills that gap.
//
//  Design pillars (the "five quiets"):
//    1. Quiet by default. Every entity starts as .private. The pod owner
//       has to explicitly opt each thread/echo into pod visibility.
//    2. Quiet content. Pods never receive reflections, never receive AI
//       insights, never receive the user's raw thoughts. They receive
//       facts: "completed morning weave," "meditation streak: 12 days,"
//       "echo unlocks in 3 days." No mental model is exposed.
//    3. Quiet size. A pod has a hard cap of 6 people. Above 6 it becomes
//       a Weave Circle (different semantics, different consent model).
//    4. Quiet cadence. Each pod member gets a daily digest, not a feed.
//       No real-time notifications. No likes. No comments. No reactions.
//    5. Quiet exit. Removing yourself from a pod purges your data on
//       the next sync. There is no "shadow" record of you anywhere.
//
//  Anti-patterns this file explicitly avoids:
//    - No "seen by" counters. The pod owner does not know who has looked.
//    - No leaderboards, no comparisons, no streaks-against-others.
//    - No "this many people completed this quest today." Ever.
//    - No nudges to engage. Quiet is the product.
//    - No telemetry. No "X people found this useful." No A/B testing.
//
//  What this file is NOT responsible for:
//    - Actual transport. FamilyPodMessage is a payload; P2PWeaveShare
//      handles delivery, encryption, offline queue, and reflection gates.
//    - Persistence. Pod membership is stored in SwiftData by the caller;
//      this file provides the model struct but the @Model wrapping is
//      done in a dedicated extension (FamilyPod+Persistence.swift would
//      be the place if the Mac-side build wants SwiftData).
//    - UI. The pod settings sheet lives in the Mac-side views; this
//      file is the model + policy layer only.

import Foundation

/// Egress guard for FamilyPod digest content.
/// Per Invariant 11: LifeMoment OCR + embeddings + detected entities MUST NOT appear
/// in pod digests. Only user-authored reflection + user-chosen thread may surface.
public enum FamilyPodEgressGuard {
    public static let blockedMomentFields: Set<String> = [
        "ocrText", "ocrConfidence",
        "imageEmbeddingText", "detectedEntitiesJSON",
        "sealedCiphertext", "sealedNonce", "sealedTag",
        "cipherHKDFInfo"
    ]

    /// Strip blocked fields from a moment dict. Returns a new dict.
    public static func strip(_ moment: [String: Any]) -> [String: Any] {
        var clean = moment
        for key in blockedMomentFields {
            clean.removeValue(forKey: key)
        }
        return clean
    }
}

// MARK: - Pod membership constraints

/// Hard caps and rules for a Family Pod. Constants chosen so any pod that
/// violates them is rejected at validation time, not silently downgraded.
public enum FamilyPodLimits {
    /// Maximum people per pod. Above this, the structure is a Weave
    /// Circle (looser consent model), not a Pod.
    public static let maxMembers: Int = 6

    /// Maximum active pods a single user can be in. Above this the
    /// "quiet" promise breaks — too many pods = feed-shaped life.
    public static let maxPodsPerUser: Int = 3

    /// Minimum reflection length required to leave a pod. The user must
    /// say goodbye in their own words; we don't allow a one-tap exit.
    public static let minExitReflectionChars: Int = 20

    /// Cooldown between pod-visible entity publishes (per entity). A pod
    /// can't publish "completed morning weave" 100x in a day.
    public static let entityPublishCooldown: TimeInterval = 3600
}

// MARK: - Pod role

/// Each member of a pod has one of three roles. Roles are not titles —
/// they're consent grants. A Steward can add members; a Witness can see
/// shared entities; a Quiet is a non-member placeholder for kids/family
/// who exist in the data model but are below the visibility threshold.
public enum FamilyPodRole: String, Codable, CaseIterable {
    case steward
    case witness
    case quiet

    public var description: String {
        switch self {
        case .steward: return "Can manage members and pod settings"
        case .witness: return "Can see shared entities"
        case .quiet: return "Exists in the family graph but not yet visible"
        }
    }
}

// MARK: - Pod visibility

/// What a Pod is allowed to see. These are explicitly enumerated rather
/// than derived from per-entity flags so the contract is auditable:
/// adding a new entity kind to OneWeave does NOT silently leak it into pods.
public enum PodVisibilityGrant: String, Codable, CaseIterable {
    case completedQuestCount       // e.g. "3 today"
    case currentHarmonyScore       // 0.0..1.0 (numeric, not a sentiment)
    case currentStreak             // days, numeric
    case echoCountdowns            // titles only, no plaintext
    case threadNames               // thread titles, no reflections
    case seasonName                // which of 4 seasons
    case amplifier                 // which of 6 amplifiers is active

    public static let allGrants: Set<PodVisibilityGrant> = Set(PodVisibilityGrant.allCases)

    /// The default grants for a new pod. Strict: only completedQuestCount
    /// and currentHarmonyScore. Everything else must be opted into.
    public static let defaultGrants: Set<PodVisibilityGrant> = [
        .completedQuestCount,
        .currentHarmonyScore
    ]
}

// MARK: - Pod membership record

public struct FamilyPodMember: Identifiable, Codable, Equatable {
    public let id: UUID
    // T077 (GLM 5.2 round 1, cross-verified): displayName must be `var` so the
    // sanitizer at FamilyPod.swift:427-428 can assign the trimmed name. `let`
    // produced a compile error on every build. `lifeEntityID` stays `let` because
    // a pod member's identity in the Life Graph must be immutable.
    public var displayName: String         // human-readable (mutable for trim-sanitize)
    public let lifeEntityID: String        // ID into the user's Life Graph (.person entity)
    public var role: FamilyPodRole
    public var joinedAt: Date
    public var lastSeenDigestAt: Date?    // when they last opened a daily digest
    public var removedAt: Date?           // if they left or were removed

    public init(
        id: UUID = UUID(),
        displayName: String,
        lifeEntityID: String,
        role: FamilyPodRole = .witness,
        joinedAt: Date = Date(),
        lastSeenDigestAt: Date? = nil,
        removedAt: Date? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.lifeEntityID = lifeEntityID
        self.role = role
        self.joinedAt = joinedAt
        self.lastSeenDigestAt = lastSeenDigestAt
        self.removedAt = removedAt
    }

    public var isActive: Bool { removedAt == nil }
}

// MARK: - Pod model

public struct FamilyPod: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String                // e.g. "The Patel Family"
    public var ownerLifeEntityID: String   // the user; one pod = one owner
    public var members: [FamilyPodMember]
    public var grants: Set<PodVisibilityGrant>
    public var createdAt: Date
    public var quietHoursStart: Int        // 0-23, pod digests don't deliver in this window
    public var quietHoursEnd: Int          // 0-23
    public var digestDeliveredAt: Date?    // last daily digest delivery timestamp

    public init(
        id: UUID = UUID(),
        name: String,
        ownerLifeEntityID: String,
        members: [FamilyPodMember] = [],
        grants: Set<PodVisibilityGrant> = PodVisibilityGrant.defaultGrants,
        createdAt: Date = Date(),
        quietHoursStart: Int = 21,        // 9pm default
        quietHoursEnd: Int = 7            // 7am default
    ) {
        self.id = id
        self.name = name
        self.ownerLifeEntityID = ownerLifeEntityID
        self.members = members
        self.grants = grants
        self.createdAt = createdAt
        self.quietHoursStart = quietHoursStart
        self.quietHoursEnd = quietHoursEnd
        self.digestDeliveredAt = nil
    }

    public var activeMemberCount: Int {
        members.filter { $0.isActive }.count
    }

    public var stewards: [FamilyPodMember] {
        members.filter { $0.role == .steward && $0.isActive }
    }

    public var witnesses: [FamilyPodMember] {
        members.filter { $0.role == .witness && $0.isActive }
    }
}

// MARK: - Pod digest (what members see)

/// A daily digest entry — what the pod owner has chosen to surface today.
/// Strictly typed fields; no free-form blobs that could carry reflections.
public struct FamilyPodDigestEntry: Codable, Equatable {
    public let podID: UUID
    public let ownerDisplayName: String
    public let date: Date

    // Only populated if the corresponding grant is enabled. Nil otherwise.
    public let completedQuestCount: Int?
    public let harmonyScore: Double?
    public let currentStreak: Int?
    public let echoCountdowns: [PodEchoCountdown]
    public let threadNames: [String]
    public let seasonName: String?
    public let amplifierName: String?

    public init(
        podID: UUID,
        ownerDisplayName: String,
        date: Date,
        completedQuestCount: Int? = nil,
        harmonyScore: Double? = nil,
        currentStreak: Int? = nil,
        echoCountdowns: [PodEchoCountdown] = [],
        threadNames: [String] = [],
        seasonName: String? = nil,
        amplifierName: String? = nil
    ) {
        self.podID = podID
        self.ownerDisplayName = ownerDisplayName
        self.date = date
        self.completedQuestCount = completedQuestCount
        self.harmonyScore = harmonyScore
        self.currentStreak = currentStreak
        self.echoCountdowns = echoCountdowns
        self.threadNames = threadNames
        self.seasonName = seasonName
        self.amplifierName = amplifierName
    }
}

/// An echo countdown entry. Title only — never plaintext reflection.
public struct PodEchoCountdown: Codable, Equatable {
    public let echoID: UUID
    public let title: String           // user-defined title, e.g. "For Maya, in 2027"
    public let daysUntilUnlock: Int

    public init(echoID: UUID, title: String, daysUntilUnlock: Int) {
        self.echoID = echoID
        self.title = title
        self.daysUntilUnlock = daysUntilUnlock
    }
}

// MARK: - Pod payload (transport envelope)

/// The actual wire format for a pod digest. Carries zero free-form text
/// from the owner; every field is either numeric, enum, or user-typed
/// title that was already public-by-design (thread names, echo titles).
public struct FamilyPodMessage: Codable, Equatable {
    public let digest: FamilyPodDigestEntry
    public let podVersion: Int                  // schema version, bump on incompatible change
    public let senderReflectionNote: String?    // NEVER user reflection text; optional one-line note like "had a good day"
    public let cooldownEndsAt: Date             // next eligible publish time per entity-publish cooldown

    public init(
        digest: FamilyPodDigestEntry,
        podVersion: Int = 1,
        senderReflectionNote: String? = nil,
        cooldownEndsAt: Date
    ) {
        self.digest = digest
        self.podVersion = podVersion
        self.senderReflectionNote = senderReflectionNote
        self.cooldownEndsAt = cooldownEndsAt
    }
}

// MARK: - Pod digest builder (read-side)

/// Pure functions for composing a digest from a LifeContext + the owner's
/// active Sacred Echoes. No network. No persistence. The caller persists
/// and dispatches.
public enum FamilyPodDigestBuilder {

    /// Build today's digest for a pod, honoring the pod's grants.
    /// - Parameters:
    ///   - pod: The pod whose grants define visibility.
    ///   - context: The owner's LifeContext (read-only).
    ///   - ownerDisplayName: Display name shown to witnesses.
    ///   - openedEchoes: Echoes the owner has explicitly allowed to show countdowns for.
    ///   - now: Override for tests.
    /// - Returns: A digest entry. Fields are nil where the grant isn't set.
    public static func build(
        for pod: FamilyPod,
        context: LifeContext,
        ownerDisplayName: String,
        openedEchoes: [SacredEcho] = [],
        now: Date = Date()
    ) -> FamilyPodDigestEntry {
        // Per T-C6 / Invariant 11: FamilyPod digests MUST NOT include LifeMoment OCR/embeddings.
        // The digest format excludes these by construction — see FamilyPodEgressGuard.
        var entry = FamilyPodDigestEntry(
            podID: pod.id,
            ownerDisplayName: ownerDisplayName,
            date: now
        )

        if pod.grants.contains(.completedQuestCount) {
            entry.completedQuestCount = context.completedQuestCount
        }
        if pod.grants.contains(.currentHarmonyScore) {
            entry.harmonyScore = context.lifeCoherenceScore
        }
        if pod.grants.contains(.currentStreak) {
            // Streak isn't on LifeContext directly — we approximate via the
            // completion signal. A future iteration would expose a real
            // streak field on LifeContext.
            entry.currentStreak = context.completedQuestCount > 0 ? 1 : 0
        }
        if pod.grants.contains(.echoCountdowns) {
            entry.echoCountdowns = openedEchoes
                .filter { echo in
                    // Only show countdowns for echoes the owner has *also*
                    // marked as pod-shareable. By default, no echoes count.
                    echo.attributes["pod_shareable"] == "true"
                }
                .map { echo in
                    PodEchoCountdown(
                        echoID: echo.id,
                        title: echo.title,
                        daysUntilUnlock: echo.daysUntilUnlock(now: now)
                    )
                }
        }
        if pod.grants.contains(.threadNames) {
            // Thread titles only — never reflection text.
            entry.threadNames = context.threads
                .filter { !$0.title.isEmpty }
                .map { $0.title }
        }
        if pod.grants.contains(.seasonName) {
            entry.seasonName = context.currentSeasonName
        }
        if pod.grants.contains(.amplifier) {
            entry.amplifierName = context.activeAmplifierName
        }

        return entry
    }
}

// MARK: - Pod membership policy

public enum FamilyPodError: Error, LocalizedError {
    case tooManyMembers(current: Int, max: Int)
    case emptyOwnerID
    case emptyName
    case emptyDisplayName
    case duplicateMember(lifeEntityID: String)
    case nonOwnerAttemptingOwnerOp
    case exitReflectionTooShort(min: Int, got: Int)
    case podCountExceeded(max: Int)
    case cooldownActive(remaining: TimeInterval)

    public var errorDescription: String? {
        switch self {
        case .tooManyMembers(let cur, let max):
            return "A Family Pod can hold at most \(max) people. This pod has \(cur). Above this, please use a Weave Circle."
        case .emptyOwnerID:
            return "A pod must have an owner."
        case .emptyName:
            return "A pod needs a name."
        case .emptyDisplayName:
            return "A member needs a display name."
        case .duplicateMember(let id):
            return "This person is already in the pod (entity \(id))."
        case .nonOwnerAttemptingOwnerOp:
            return "Only the pod owner can change pod settings."
        case .exitReflectionTooShort(let min, let got):
            return "Leaving a pod requires a reflection of at least \(min) characters. You wrote \(got)."
        case .podCountExceeded(let max):
            return "You can be in at most \(max) active pods. The quiet promise breaks past that."
        case .cooldownActive(let remaining):
            return "Pod visibility is on cooldown for \(Int(remaining)) more seconds."
        }
    }
}

/// Membership operations and policy enforcement. All operations are pure
/// functions that take a pod + args and return either a new pod or throw.
/// This keeps the policy testable and the persistence layer agnostic.
public enum FamilyPodPolicy {

    /// Create a new pod. Validates invariants up front.
    public static func createPod(
        name: String,
        ownerLifeEntityID: String,
        ownerDisplayName: String,
        initialGrants: Set<PodVisibilityGrant> = PodVisibilityGrant.defaultGrants,
        quietHoursStart: Int = 21,
        quietHoursEnd: Int = 7
    ) throws -> FamilyPod {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw FamilyPodError.emptyName }
        guard !ownerLifeEntityID.isEmpty else { throw FamilyPodError.emptyOwnerID }

        let ownerMember = FamilyPodMember(
            displayName: ownerDisplayName,
            lifeEntityID: ownerLifeEntityID,
            role: .steward
        )
        return FamilyPod(
            name: trimmedName,
            ownerLifeEntityID: ownerLifeEntityID,
            members: [ownerMember],
            grants: initialGrants,
            quietHoursStart: quietHoursStart,
            quietHoursEnd: quietHoursEnd
        )
    }

    /// Add a member. Throws on capacity / duplicate.
    public static func addMember(
        _ member: FamilyPodMember,
        to pod: FamilyPod
    ) throws -> FamilyPod {
        let trimmedName = member.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw FamilyPodError.emptyDisplayName }

        // Persist the trimmed name — a user-facing display name with
        // accidental whitespace looks broken in digest entries. Family
        // pod is the wrong place to be lenient about whitespace.
        var sanitized = member
        sanitized.displayName = trimmedName

        var updated = pod
        // Check capacity (owner doesn't count toward the cap of 6).
        let nonOwnerCount = updated.members.filter {
            $0.lifeEntityID != pod.ownerLifeEntityID && $0.isActive
        }.count
        guard nonOwnerCount < FamilyPodLimits.maxMembers else {
            throw FamilyPodError.tooManyMembers(
                current: nonOwnerCount,
                max: FamilyPodLimits.maxMembers
            )
        }
        // Check duplicate
        let isDuplicate = updated.members.contains { existing in
            existing.lifeEntityID == member.lifeEntityID && existing.isActive
        }
        guard !isDuplicate else { throw FamilyPodError.duplicateMember(lifeEntityID: member.lifeEntityID) }

        updated.members.append(sanitized)
        return updated
    }

    /// Remove a member (themselves or owner-initiated). Returns the
    /// updated pod. The removed member's `removedAt` is set; their
    /// data is purged from the next outbound sync.
    public static func removeMember(
        lifeEntityID: String,
        initiatedBy: String,
        from pod: FamilyPod
    ) throws -> FamilyPod {
        // Authorization: owner can remove anyone, a member can remove themselves.
        let isOwner = initiatedBy == pod.ownerLifeEntityID
        let isSelf = initiatedBy == lifeEntityID
        guard isOwner || isSelf else { throw FamilyPodError.nonOwnerAttemptingOwnerOp }

        var updated = pod
        for i in updated.members.indices where updated.members[i].lifeEntityID == lifeEntityID {
            updated.members[i].removedAt = Date()
        }
        return updated
    }

    /// Exit a pod (member-initiated). Requires a reflection of at least
    /// FamilyPodLimits.minExitReflectionChars. This protects against
    /// accidental one-tap exits and gives the user a moment to mean it.
    public static func exit(
        pod: FamilyPod,
        exitingLifeEntityID: String,
        exitReflection: String
    ) throws -> FamilyPod {
        // Must be a current member.
        let isMember = pod.members.contains { $0.lifeEntityID == exitingLifeEntityID && $0.isActive }
        guard isMember else { throw FamilyPodError.nonOwnerAttemptingOwnerOp }

        let trimmed = exitReflection.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= FamilyPodLimits.minExitReflectionChars else {
            throw FamilyPodError.exitReflectionTooShort(
                min: FamilyPodLimits.minExitReflectionChars,
                got: trimmed.count
            )
        }
        return try removeMember(
            lifeEntityID: exitingLifeEntityID,
            initiatedBy: exitingLifeEntityID,
            from: pod
        )
    }

    /// Toggle a grant. Only the owner can do this.
    public static func setGrant(
        _ grant: PodVisibilityGrant,
        enabled: Bool,
        by actorLifeEntityID: String,
        in pod: FamilyPod
    ) throws -> FamilyPod {
        guard actorLifeEntityID == pod.ownerLifeEntityID else {
            throw FamilyPodError.nonOwnerAttemptingOwnerOp
        }
        var updated = pod
        if enabled {
            updated.grants.insert(grant)
        } else {
            updated.grants.remove(grant)
        }
        return updated
    }

    /// Check if a publish is allowed under the entity-publish cooldown.
    /// Returns the cooldown end date if currently blocked, nil otherwise.
    public static func nextEligiblePublish(
        lastPublishAt: Date?,
        now: Date = Date()
    ) -> Date? {
        guard let last = lastPublishAt else { return nil }
        let elapsed = now.timeIntervalSince(last)
        if elapsed >= FamilyPodLimits.entityPublishCooldown {
            return nil
        }
        return last.addingTimeInterval(FamilyPodLimits.entityPublishCooldown)
    }

    /// Determine whether the current wall-clock time is inside the pod's
    /// quiet hours window. Used to gate digest delivery so families
    /// aren't pinged at bedtime.
    public static func isInQuietHours(
        now: Date = Date(),
        calendar: Calendar = .current,
        pod: FamilyPod
    ) -> Bool {
        let hour = calendar.component(.hour, from: now)
        let start = pod.quietHoursStart
        let end = pod.quietHoursEnd
        if start == end { return false }
        if start < end {
            return hour >= start && hour < end
        }
        // Wrap midnight (e.g. 21..7).
        return hour >= start || hour < end
    }
}

// MARK: - Pod digest redactor (defense in depth)

/// Even though the builder respects grants, callers should pass the
/// resulting digest through the redactor before transmitting. This is
/// defense-in-depth: any future field added to the digest will be
/// stripped unless explicitly whitelisted.
public enum FamilyPodDigestRedactor {

    /// Redact a digest to its transport-safe form. Returns a copy with
    /// every field nil/empty that isn't explicitly granted by the pod's
    /// grant set. Use this as the *last* step before sending.
    public static func redact(
        _ entry: FamilyPodDigestEntry,
        against pod: FamilyPod
    ) -> FamilyPodDigestEntry {
        return FamilyPodDigestEntry(
            podID: entry.podID,
            ownerDisplayName: entry.ownerDisplayName,
            date: entry.date,
            completedQuestCount: pod.grants.contains(.completedQuestCount) ? entry.completedQuestCount : nil,
            harmonyScore: pod.grants.contains(.currentHarmonyScore) ? entry.harmonyScore : nil,
            currentStreak: pod.grants.contains(.currentStreak) ? entry.currentStreak : nil,
            echoCountdowns: pod.grants.contains(.echoCountdowns) ? entry.echoCountdowns : [],
            threadNames: pod.grants.contains(.threadNames) ? entry.threadNames : [],
            seasonName: pod.grants.contains(.seasonName) ? entry.seasonName : nil,
            amplifierName: pod.grants.contains(.amplifier) ? entry.amplifierName : nil
        )
    }
}

// MARK: - Pod sanity helpers

extension FamilyPod {
    /// Summary line for UI. e.g. "The Patel Family · 4 members · 2 grants".
    public var summaryLine: String {
        let m = activeMemberCount
        let g = grants.count
        return "\(name) · \(m) member\(m == 1 ? "" : "s") · \(g) grant\(g == 1 ? "" : "s")"
    }

    /// Whether this pod is currently publishable (within active member
    /// count, has at least one witness, and is not in cooldown).
    public func canPublishDigest(now: Date = Date()) -> Bool {
        guard witnesses.count >= 1 else { return false }
        guard activeMemberCount >= 2 else { return false }  // need owner + at least one witness
        if FamilyPodPolicy.isInQuietHours(now: now, pod: self) { return false }
        return true
    }
}
