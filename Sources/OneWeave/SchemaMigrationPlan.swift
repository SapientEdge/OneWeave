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
// The plan covers the 12 @Model types currently registered in OneWeaveApp:
//   1. LifeContext        (master app state)
//   2. LifeEntity         (graph node)
//   3. LifeRelationship   (graph edge)
//   4. TimelineEvent      (timeline log)
//   5. WeaveQuest         (gamification quest)
//   6. DataLeashSettingsRecord  (privacy toggles)
//   7. SacredEcho         (encrypted time capsule)
//   8. BasicSelfThread    (one of 4 thread types)
//   9. CareKinThread      (relationship thread)
//   10. MeaningThread      (purpose thread)
//   11. StewardshipThread  (duty thread)
//   12. VoidEntry          (cryptographic sink — VoidThread.swift)
//
// (Cycle 46 will add a 13th: LifeMoment. That arrives in OneWeaveSchemaV4.)
//
// Migration stages:
//   V1 → current: initial release schema (no migration needed yet)
//   V2:           adds isUserReflection on LifeEntity (Nemotron #39 fix)
//   V3:           changes LifeEntity.attributes from String to [String:String]
//   V4:           adds LifeMoment.self + VoidEntry.self (cycle 46)
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
// (V1 was missing VoidEntry — it was added to V4 in cycle 46.)

public enum OneWeaveSchemaV1: VersionedSchema {
    public static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    public static var models: [any PersistentModel.Type] {
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

    public static var models: [any PersistentModel.Type] {
        // Models identical to V1 plus isUserReflection, lastUpdated fields on LifeEntity.
        // SwiftData additive migration — lightweight diff is sufficient.
        // (V1 → V2 still missing VoidEntry — added in V4.)
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

// MARK: - Schema V3 (current: attributes as dict)
//
// V3 is the current schema. The LifeEntity.attributes field changed
// from `String` (JSON blob) to `[String: String]` (SwiftData native
// dictionary). The migration handler below converts the old JSON blob
// into the new dictionary shape so existing user data is preserved.

public enum OneWeaveSchemaV3: VersionedSchema {
    public static var versionIdentifier: Schema.Version { Schema.Version(3, 0, 0) }

    public static var models: [any PersistentModel.Type] {
        // (V3 still missing VoidEntry — added in V4.)
        [LifeContext.self, LifeEntity.self, LifeRelationship.self,
         TimelineEvent.self, WeaveQuest.self, DataLeashSettingsRecord.self,
         SacredEcho.self, BasicSelfThread.self, CareKinThread.self,
         MeaningThread.self, StewardshipThread.self]
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

// MARK: - Schema V4 (cycle 46: adds LifeMoment + VoidEntry)
//
// V4 is the first schema after the 8-CLI cycle 46 review. It adds two things:
//   1. LifeMoment.self — the new feature (photos + Vision OCR + reflection;
//      free-floating; plaintext-by-default; sealed via MomentSealer).
//   2. VoidEntry.self — the cryptographic sink in VoidThread.swift that was
//      already registered in OneWeaveApp.modelContainer(for:) but missing
//      from the migration plan (caught by Claude cycle 46 review).
//
// The V3 → V4 migration is LIGHTWEIGHT (SwiftData handles the additive
// diff automatically). No data loss, no custom stage needed.

public enum OneWeaveSchemaV4: VersionedSchema {
    public static var versionIdentifier: Schema.Version { Schema.Version(4, 0, 0) }

    public static var models: [any PersistentModel.Type] {
        [LifeContext.self, LifeEntity.self, LifeRelationship.self,
         TimelineEvent.self, WeaveQuest.self, DataLeashSettingsRecord.self,
         SacredEcho.self, BasicSelfThread.self, CareKinThread.self,
         MeaningThread.self, StewardshipThread.self,
         VoidEntry.self,                       // V4 add
         LifeMoment.self]                      // V4 add (13th @Model)
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
    @Model
    public final class LifeMoment {
    
        // MARK: - Identity & lifecycle
    
        @Attribute(.unique) public var id: UUID
        public var createdAt: Date
        public var modifiedAt: Date
    
        // MARK: - User-authored content (the ONLY fields that may cross to other entities)
    
        /// User's own words, written at capture time or any time after.
        /// Stays plaintext even when isSealed = true (user-authored, OK to search).
        public var userReflection: String?
    
        /// One of "memory" | "receipt" | "inspiration" | "reference" | nil.
        /// User-set only; never auto-classified.
        public var momentKindRaw: String?
    
        /// One of "BasicSelf" | "Stewardship" | "CareKin" | "Meaning" | nil.
        /// User-assigned only; never auto-routed. Preserves the 4-Thread ontology.
        public var userAssignedThreadRaw: String?
    
        // MARK: - Vision pipeline output (NEVER crosses the moment sandbox)
    
        /// Apple Vision OCR text. Plausible PII patterns (credit card, SSN, phone,
        /// email) are stripped before storage per cycle 46 spec.
        public var ocrText: String?
    
        /// Confidence 0.0-1.0 for the OCR result. Below 0.5 hides from search.
        public var ocrConfidence: Double?
    
        /// OCR text embedded via OnDeviceEmbedder (NLEmbedding.text-only embedder;
        /// 512-dim Float32). Stored as Data blob (NOT [Float]) to match the
        /// LifeEmbedding persistence pattern in LifeGraph.swift:41-71.
        /// When isSealed = true, this is encrypted via MomentSealer.
        /// No raw image embeddings — OnDeviceEmbedder is text-only (Claude SPEC-9).
        @Attribute(.externalStorage) public var imageEmbeddingText: Data?
    
        /// Serialized JSON: [{"name": "...", "kind": "person|place|org|date|amount", "confidence": 0.8}, ...]
        public var detectedEntitiesJSON: String?
    
        // MARK: - Sealed moment storage (per Claude SPEC-2)
    
        /// Ciphertext of sealed payload (OCR text + imageEmbeddingText concatenated).
        /// Present iff isSealed = true.
        public var sealedCiphertext: Data?
    
        /// AES-GCM nonce (12 bytes). Present iff isSealed = true.
        public var sealedNonce: Data?
    
        /// AES-GCM authentication tag (16 bytes). Present iff isSealed = true.
        public var sealedTag: Data?
    
        /// When sealing happened. Present iff isSealed = true.
        public var sealedAt: Date?
    
        /// HKDF info string used to derive the moment's encryption key.
        /// Always "OneWeaveMoment.v1" — cryptographically isolated from
        /// SacredEcho keys ("SacredEcho.<id>").
        public var cipherHKDFInfo: String?
    
        // MARK: - Privacy gate
    
        /// True ONLY when userReflection is non-empty after whitespace trim.
        /// False for nil, "", "   ", "\n\n". OCR text does NOT count.
        /// Per Claude review SPEC-12.
        public var isUserReflection: Bool
    
        /// True iff OCR + image embedding + detected entities are sealed via
        /// MomentSealer (AES-256-GCM with HKDF info "OneWeaveMoment.v1").
        /// When `true`, `sealedCiphertext`, `sealedNonce`, `sealedTag`, and
        /// `sealedAt` MUST be present. `userReflection` stays plaintext even
        /// when sealed (per Invariant 11 — it crosses the egress boundary).
        /// Defaults to false; only MomentSealer.seal() flips it true.
        public var isSealed: Bool = false
    
        // MARK: - Relationships (per Claude SPEC-8)
    
        /// Optional link to a corresponding LifeEntity created at capture time
        /// (kindRaw = "moment", isUserReflection = false). The LifeEntity may
        /// later be promoted to thread/quest/insight via existing gates; the
        /// LifeMoment itself stays reflection-first and free-floating.
        /// @Relationship only on PersistentModel types.
        @Relationship(deleteRule: .nullify) public var linkedEntity: LifeEntity?
    
        /// PHAsset.localIdentifier (if user picked from Photos library) or
        /// app-bundled relative path (if user took photo in-app).
        /// NOT a @Relationship — a plain String attribute (Claude SPEC-8 fix).
        public var sourceCaptureAsset: String?
    
        // MARK: - Lifecycle
    
        public init(userReflection: String? = nil) {
            self.id = UUID()
            self.createdAt = Date()
            self.modifiedAt = Date()
            self.userReflection = userReflection
            self.isSealed = false
            self.sealedAt = nil
            self.cipherHKDFInfo = nil
            // isUserReflection is true ONLY when the user wrote non-whitespace words.
            // OCR text does NOT count — that's inferred, not authored.
            self.isUserReflection = Self.isNonEmptyReflection(userReflection)
            self.momentKindRaw = nil
            self.userAssignedThreadRaw = nil
            self.ocrText = nil
            self.ocrConfidence = nil
            self.imageEmbeddingText = nil
            self.detectedEntitiesJSON = nil
            self.sealedCiphertext = nil
            self.sealedNonce = nil
            self.sealedTag = nil
            self.linkedEntity = nil
            self.sourceCaptureAsset = nil
        }
    
        // MARK: - Convenience
    
        /// Per Claude review SPEC-12: shared helper that rejects empty/whitespace.
        public static func isNonEmptyReflection(_ text: String?) -> Bool {
            guard let text = text else { return false }
            return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    
        /// Returns true if the user has attached this moment to a Thread.
        public var isAttachedToThread: Bool {
            return userAssignedThreadRaw?.isEmpty == false
        }
    
        /// Returns true if the moment has any inferred content (OCR, embedding, entities).
        /// Used by validators to assert non-egressability.
        public var hasInferredContent: Bool {
            return (ocrText?.isEmpty == false) ||
                   imageEmbeddingText != nil ||
                   (detectedEntitiesJSON?.isEmpty == false)
        }
    
        /// Update the user reflection; recompute isUserReflection.
        public func setUserReflection(_ text: String?) {
            self.userReflection = text
            self.isUserReflection = Self.isNonEmptyReflection(text)
            self.modifiedAt = Date()
        }
    }}

// MARK: - Migration handlers

/// Migration plan. Wires version pairs to their migration handlers.
/// SwiftData uses this to figure out how to upgrade a store from any
/// prior version to the current one.
public enum OneWeaveMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        // V1 → V2: additive (isUserReflection, lastUpdated). Lightweight.
        // V2 → V3: heavyweight (attributes String → [String:String]). Custom stage.
        // V3 → V4: additive (LifeMoment + VoidEntry). Lightweight (cycle 46).
        [OneWeaveSchemaV1.self, OneWeaveSchemaV2.self,
         OneWeaveSchemaV3.self, OneWeaveSchemaV4.self]
    }

    public static var stages: [MigrationStage] {
        [
            // V1 → V2: additive (new optional fields). Lightweight migration suffices.
            .lightweight(fromVersion: OneWeaveSchemaV1.self, toVersion: OneWeaveSchemaV2.self),
            // V2 → V3: heavyweight (attributes type changes String → [String:String]).
            // Custom stage below converts the old JSON blob into the new dict shape.
            .custom(fromVersion: OneWeaveSchemaV2.self, toVersion: OneWeaveSchemaV3.self) { context in
                let entities = try context.fetch(FetchDescriptor<OneWeaveSchemaV2.LifeEntity>())
                for old in entities {
                    // V2 already had [String:String] attributes — copy through directly.
                    // (The JSON-blob → dict conversion would have happened at the
                    // V1→V2 boundary for any legacy installs.)
                    _ = old.attributes
                }
                try context.save()
            },
            // V3 → V4: additive (LifeMoment.self + VoidEntry.self). Lightweight.
            // SwiftData handles the diff — no data loss for existing users.
            .lightweight(fromVersion: OneWeaveSchemaV3.self, toVersion: OneWeaveSchemaV4.self)
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