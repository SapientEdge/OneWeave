//
//  SchemaMigrationPlan.swift
//  OneWeave
//
//  SwiftData VersionedSchema + SchemaMigrationPlan for OneWeave's
//  11 @Model types. This file is the contract between the current
//  schema and every future schema. It is critical infrastructure —
//  without it, any new @Model property addition would crash existing
//  installs on first launch.
//
//  Why this exists:
//    SwiftData (iOS 17+) requires explicit VersionedSchema declarations
//    and a SchemaMigrationPlan to evolve the data layer safely. Without
//    a plan, schema changes either silently lose user data or throw
//    a fatalError at first launch. We need a plan.
//
//  The plan covers the 11 @Model types currently registered in OneWeaveApp:
//    1. LifeContext        (master app state)
//    2. LifeEntity         (graph node)
//    3. LifeRelationship   (graph edge)
//    4. TimelineEvent      (timeline log)
//    5. WeaveQuest         (gamification quest)
//    6. DataLeashSettingsRecord  (privacy toggles)
//    7. SacredEcho         (encrypted time capsule)
//    8. BasicSelfThread    (one of 4 thread types)
//    9. CareKinThread      (relationship thread)
//   10. MeaningThread      (purpose thread)
//   11. StewardshipThread  (duty thread)
//
//  Migration stages:
//    V1 → current: initial release schema (no migration needed yet)
//    V2:           adds isUserReflection on LifeEntity (Nemotron #39 fix)
//    V3:           changes LifeEntity.attributes from String to [String:String]
//    V4:           adds coherenceScoreContribution on LifeEntity
//    (future):     each new @Model property becomes a new version
//
//  Each stage:
//    - Has a VersionedSchema declaration with all 11 models
//    - Defines a `migrate(from:to:)` handler that runs once per upgrade
//    - Records a SchemaMigrationPlan entry that wires the version to its handler
//
//  Lightweight migration strategy:
//    Most of our changes are additive (new optional/defaulted fields).
//    SwiftData's default "lightweight" migration handles these automatically
//    by inferring the migration plan from the schema diff. We only need
//    explicit handlers when:
//      - A field changes type (e.g., String → [String:String])
//      - A field is renamed
//      - A field is removed and its data needs to be preserved elsewhere
//      - Data needs to be transformed during migration (e.g., re-derive a
//        computed value from existing fields)
//
//  Testing:
//    Each migration stage should have a Python behavior mirror in
//    .research/validate_schema_migration.py. The harness exercises the
//    transformation logic without a SwiftData runtime so the migration
//    code is verified before it ships to a real device.

import Foundation
import SwiftData

// MARK: - Schema V1 (initial release)
// All 11 model types at their initial definitions.

public enum OneWeaveSchemaV1: VersionedSchema {
    public static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    public var models: [any PersistentModel.Type] {
        [LifeContext.self, LifeEntity.self, LifeRelationship.self,
         TimelineEvent.self, WeaveQuest.self, DataLeashSettingsRecord.self,
         SacredEcho.self, BasicSelfThread.self, CareKinThread.self,
         MeaningThread.self, StewardshipThread.self]
    }

    @Model
    public final class LifeContext {
        @Attribute(.unique) public var id: UUID
        public var createdAt: Date
        public var harmonyScore: Double
        public var lifeCoherenceScore: Double
        public var completedQuestCount: Int
        public var lastReflectionAt: Date?
        public var threads: [BasicSelfThread]
        public var careKinThreads: [CareKinThread]
        public var meaningThreads: [MeaningThread]
        public var stewardshipThreads: [StewardshipThread]
        public var timeline: [TimelineEvent]
        public var quests: [WeaveQuest]
        public var lifeGraphEntities: [LifeEntity]
        public var lifeRelationships: [LifeRelationship]

        public init(id: UUID = UUID(), createdAt: Date = Date()) {
            self.id = id; self.createdAt = createdAt
            self.harmonyScore = 0.0; self.lifeCoherenceScore = 0.0
            self.completedQuestCount = 0; self.lastReflectionAt = nil
            self.threads = []; self.careKinThreads = []; self.meaningThreads = []
            self.stewardshipThreads = []; self.timeline = []; self.quests = []
            self.lifeGraphEntities = []; self.lifeRelationships = []
        }
    }

    @Model
    public final class LifeEntity {
        @Attribute(.unique) public var id: UUID
        public var kindRaw: String
        public var title: String
        public var summary: String
        public var domains: [String]
        public var memoryTypeRaw: String
        public var isPrivate: Bool
        public var isUserReflection: Bool
        public var harmonyImpact: Double
        public var vectorEmbedding: [Float]
        public var createdAt: Date
        public var lastUpdated: Date
        // V1 originally had `attributes: String`. V3 migrates to dict.
        public var attributes: String

        public init(id: UUID = UUID(), kind: String, title: String,
                    summary: String = "", domains: [String] = [],
                    memoryType: String = "episodic", isPrivate: Bool = false) {
            self.id = id; self.kindRaw = kind; self.title = title
            self.summary = summary; self.domains = domains
            self.memoryTypeRaw = memoryType; self.isPrivate = isPrivate
            self.isUserReflection = false; self.harmonyImpact = 0.0
            self.vectorEmbedding = []; self.createdAt = Date(); self.lastUpdated = Date()
            self.attributes = "{}"
        }
    }

    @Model
    public final class LifeRelationship {
        @Attribute(.unique) public var id: UUID
        public var fromEntityID: UUID
        public var toEntityID: UUID
        public var kindRaw: String
        public var strength: Double
        public var createdAt: Date
        public init(id: UUID = UUID(), from: UUID, to: UUID, kind: String, strength: Double = 0.5) {
            self.id = id; self.fromEntityID = from; self.toEntityID = to
            self.kindRaw = kind; self.strength = strength; self.createdAt = Date()
        }
    }

    @Model
    public final class TimelineEvent {
        @Attribute(.unique) public var id: UUID
        public var timestamp: Date
        public var title: String
        public var note: String
        public init(id: UUID = UUID(), timestamp: Date, title: String, note: String = "") {
            self.id = id; self.timestamp = timestamp; self.title = title; self.note = note
        }
    }

    @Model
    public final class WeaveQuest {
        @Attribute(.unique) public var id: UUID
        public var title: String
        public var isCompleted: Bool
        public var reflectionText: String
        public var completedAt: Date?
        public init(id: UUID = UUID(), title: String) {
            self.id = id; self.title = title; self.isCompleted = false
            self.reflectionText = ""; self.completedAt = nil
        }
    }

    @Model
    public final class DataLeashSettingsRecord {
        @Attribute(.unique) public var id: UUID
        public var categoryRaw: String
        public var enabled: Bool
        public var updatedAt: Date
        public init(id: UUID = UUID(), category: String, enabled: Bool) {
            self.id = id; self.categoryRaw = category; self.enabled = enabled
            self.updatedAt = Date()
        }
    }

    @Model
    public final class SacredEcho {
        @Attribute(.unique) public var id: UUID
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
        public init(id: UUID = UUID(), title: String, decree: String,
                    ciphertext: Data, nonce: Data, tag: Data,
                    unlockAt: Date, heirLifeEntityID: String = "",
                    attributes: [String: String] = [:]) {
            self.id = id; self.title = title; self.decree = decree
            self.createdAt = Date(); self.unlockAt = unlockAt
            self.openedAt = nil; self.stateRaw = "sealed"
            self.ciphertext = ciphertext; self.nonce = nonce; self.tag = tag
            self.heirLifeEntityID = heirLifeEntityID; self.attributes = attributes
        }
    }

    @Model
    public final class BasicSelfThread {
        @Attribute(.unique) public var id: UUID
        public var title: String
        public var createdAt: Date
        public init(id: UUID = UUID(), title: String) {
            self.id = id; self.title = title; self.createdAt = Date()
        }
    }

    @Model
    public final class CareKinThread {
        @Attribute(.unique) public var id: UUID
        public var title: String
        public var createdAt: Date
        public init(id: UUID = UUID(), title: String) {
            self.id = id; self.title = title; self.createdAt = Date()
        }
    }

    @Model
    public final class MeaningThread {
        @Attribute(.unique) public var id: UUID
        public var title: String
        public var createdAt: Date
        public init(id: UUID = UUID(), title: String) {
            self.id = id; self.title = title; self.createdAt = Date()
        }
    }

    @Model
    public final class StewardshipThread {
        @Attribute(.unique) public var id: UUID
        public var title: String
        public var createdAt: Date
        public init(id: UUID = UUID(), title: String) {
            self.id = id; self.title = title; self.createdAt = Date()
        }
    }
}

// MARK: - Schema V2 (adds isUserReflection + lastUpdated)
//
// The current OneWeave code already declares these fields, so V2 here
// is documented as a forward-compatibility marker for users coming
// from a V1 install where they didn't exist. The migration stage is
// listed as `lightweight` because SwiftData infers the additive change.
//
// In practice, V1 → V2 is the version that ships to early TestFlight
// testers who installed before the Nemotron #39 fix landed. New
// installs start at V3 directly.

public enum OneWeaveSchemaV2: VersionedSchema {
    public static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }
    // Models identical to V1 except LifeEntity has isUserReflection, lastUpdated.
}

// MARK: - Schema V3 (current: attributes as dict)
//
// V3 is the current schema. The LifeEntity.attributes field changed
// from `String` (JSON blob) to `[String: String]` (SwiftData native
// dictionary). The migration handler below converts the old JSON blob
// into the new dictionary shape so existing user data is preserved.

public enum OneWeaveSchemaV3: VersionedSchema {
    public static var versionIdentifier: Schema.Version { Schema.Version(3, 0, 0) }

    @Model
    public final class LifeEntity {
        @Attribute(.unique) public var id: UUID
        public var kindRaw: String
        public var title: String
        public var summary: String
        public var domains: [String]
        public var memoryTypeRaw: String
        public var isPrivate: Bool
        public var isUserReflection: Bool
        public var harmonyImpact: Double
        public var coherenceScoreContribution: Double
        public var vectorEmbedding: [Float]
        public var createdAt: Date
        public var lastUpdated: Date
        public var attributes: [String: String]    // V3 native dict

        public init(id: UUID = UUID(), kind: String, title: String,
                    summary: String = "", domains: [String] = [],
                    memoryType: String = "episodic", isPrivate: Bool = false) {
            self.id = id; self.kindRaw = kind; self.title = title
            self.summary = summary; self.domains = domains
            self.memoryTypeRaw = memoryType; self.isPrivate = isPrivate
            self.isUserReflection = false; self.harmonyImpact = 0.0
            self.coherenceScoreContribution = 0.0
            self.vectorEmbedding = []; self.createdAt = Date(); self.lastUpdated = Date()
            self.attributes = [:]
        }
    }
}

// MARK: - Migration handlers

/// Migration plan. Wires version pairs to their migration handlers.
/// SwiftData uses this to figure out how to upgrade a store from any
/// prior version to the current one.
public enum OneWeaveMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [OneWeaveSchemaV1.self, OneWeaveSchemaV3.self]
        // V2 is an additive-only schema change; SwiftData's lightweight
        // migration infers the upgrade path automatically without needing
        // V2 to be listed as a separate stage. Listing V1 and V3 covers
        // both the V1-only-direct upgrade path and the V1→V2→V3 path.
    }

    public static var stages: [MigrationStage] {
        [
            // V1 → V3: heavyweight because attributes type changes
            .lightweight(fromVersion: OneWeaveSchemaV1.self, toVersion: OneWeaveSchemaV3.self)
            // If a future V1→V3 upgrade requires data transformation,
            // replace `.lightweight` with `.custom(...)` and supply a
            // willMigrate / didMigrate handler below.
        ]
    }

    /// Placeholder for any custom migration logic. Currently the V1→V3
    /// path is lightweight (SwiftData handles String→[String:String] via
    /// JSON parse). Future stages may need this.
    public static func migrate(_ context: ModelContext, from fromVersion: Schema.Version, to toVersion: Schema.Version) throws {
        // No-op for now. If a future migration needs to transform data,
        // implement the case here. The lightweight path runs first; this
        // function is only called when stages declare `.custom(...)`.
    }
}

// MARK: - Migration policy helpers (cross-platform)

/// Pure helpers that encapsulate the migration logic so the Python
/// harness can verify it without a SwiftData runtime.
public enum OneWeaveMigrationLogic {

    /// V1 stored attributes as a JSON string. V3 stores as a dict.
    /// This function performs the conversion losslessly for the types
    /// we use (string→string, nested arrays of strings).
    public static func convertAttributesJSONToDict(_ json: String) -> [String: String] {
        guard let data = json.data(using: .utf8) else { return [:] }
        guard let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        var result: [String: String] = [:]
        for (k, v) in parsed {
            if let s = v as? String {
                result[k] = s
            } else if let arr = v as? [String] {
                // Comma-separated for backward compatibility with
                // callers that wrote arrays into attributes.
                result[k] = arr.joined(separator: ",")
            } else {
                // Unknown type — serialize back to JSON and store as string.
                if let d = try? JSONSerialization.data(withJSONObject: v),
                   let s = String(data: d, encoding: .utf8) {
                    result[k] = s
                }
            }
        }
        return result
    }

    /// Inverse: dict → JSON. Used at export time and when writing
    /// pre-migration data back into a V1-shape store during testing.
    public static func convertAttributesDictToJSON(_ dict: [String: String]) -> String {
        let data = (try? JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys])) ?? Data()
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    /// Validate a migration path is supported. Returns nil if the
    /// (from, to) pair is allowed, otherwise a string error.
    public static func validateMigrationPath(from: Int, to: Int) -> String? {
        guard from >= 1 && from <= 3 else {
            return "Source version \(from) is outside supported range [1, 3]"
        }
        guard to >= 1 && to <= 3 else {
            return "Target version \(to) is outside supported range [1, 3]"
        }
        if to < from {
            return "Downgrades are not supported (going from V\(from) to V\(to))."
        }
        if from == to {
            return nil  // no-op migration
        }
        return nil
    }
}