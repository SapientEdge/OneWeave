//
//  OneWeaveAPI.swift
//  OneWeave
//
//  PUBLIC API CATALOG — read this first when integrating with OneWeave.
//
//  This file does NOT contain runtime code. It exists as a single,
//  browsable catalog of every public type, function, and constant in
//  the OneWeave module. The intent is that an integrator (Mac-side
//  Claude, a future contributor, or a third-party developer) can
//  read this file and immediately know what the module offers and
//  which file to look in for details.
//
//  If you add a new public type or function, ADD IT HERE. This file is
//  the contract between the module and its consumers. Changes here
//  should be considered breaking changes if they remove or rename
//  anything (semver discipline).
//
//  Conventions:
//    - Public types are marked `public`. `internal` symbols are not
//      listed here.
//    - Each entry includes the file path so you can jump to the source.
//    - Brief invariants (what's enforced, what reflection/privacy gates
//      apply) are noted inline.
//
//  Categories:
//    1. Core state         — LifeContext, LifeGraph, threads, quests
//    2. Privacy + Data Leash
//    3. Sacred Echo Vault  (encrypted time capsules)
//    4. Invisible Mentor   (past-self dialogue)
//    5. Cross-Domain Insight Engine
//    6. P2P Weave Share    (peer-to-peer sharing)
//    7. Family Pod         (private family sharing)
//    8. Portable Export    (leash-aware bundles)
//    9. Schema Migration   (versioned SwiftData)
//   10. App Lifecycle      (scenePhase routing, encrypted envelope)
//   11. UI Helpers         (sheets, command palette)
//   12. Loom Geometry      (visualization math)

import Foundation

// This enum never gets instantiated. Its only purpose is to expose a
// type that organizes the module's API surface in the IDE outline.
public enum OneWeaveAPICatalog {

    // 1. Core state — see Sources/OneWeave/LifeContext.swift
    //    - `public final class LifeContext` (SwiftData @Model, @MainActor)
    //      Master app state. Owns threads, timeline, quests, LifeGraph.
    //    - `public final class LifeEntity` (SwiftData @Model)
    //      Graph node. Has isUserReflection flag (Nemotron #39 fix).
    //    - `public final class LifeRelationship` (SwiftData @Model)
    //      Graph edge.
    //    - `public enum EntityKind, MemoryType, PrivacyTier, ConfidenceLevel`
    //    - `public struct LifeInsight, LifePattern` (graph derived data)
    //    - `public enum LifeGraphEngine` — entity creation, vector search,
    //      relationship graph, pattern detection. Privacy-tier filtering
    //      baked in.
    //    - `public final class TimelineEvent` (SwiftData @Model)
    //    - `public final class WeaveQuest` (SwiftData @Model) — completion
    //      requires non-empty reflectionText.
    //    - Thread models: BasicSelfThread, CareKinThread, MeaningThread,
    //      StewardshipThread.

    // 2. Privacy + Data Leash — see Sources/OneWeave/DataLeashSettings.swift
    //    - `public enum IntegrationCategory` — typed privacy categories
    //      (calendar, contacts, health, reminders, mail, notes, bodyThread).
    //    - `public final class DataLeashSettingsRecord` (SwiftData @Model)
    //    - `public enum DataLeashPolicy` — currentLeash(in: ModelContext),
    //      consulted on EVERY integration path BEFORE any data access.
    //    Invariant: never call into EventKit/Contacts/HealthKit without
    //    first reading the user's actual toggle from ModelContainer.

    // 3. Sacred Echo Vault — see Sources/OneWeave/SacredEcho.swift
    //    - `public final class SacredEcho` (SwiftData @Model)
    //      AES-256-GCM encrypted time capsule. Holds ciphertext only;
    //      plaintext never persists.
    //    - `public enum EchoLifecycleState` — sealed, maturing,
    //      openingReady, opened, delivered, released.
    //    - `public enum EchoError` — emptyReflection, notYetUnlocked,
    //      decryptionFailed, etc.
    //    - `public enum SacredEchoCipher` — vaultSeed(), perEchoKey(),
    //      seal(), open(). Fail-closed: no test seed fallback in
    //      production. Vault seed lives in Keychain.
    //    - `public enum SacredEchoStore` (@MainActor) — seal(), open(),
    //      handDeliver(), release(). All entry points require
    //      modelContext and validate reflection gates.

    // 4. Invisible Mentor — see Sources/OneWeave/InvisibleMentor.swift
    //                              Sources/OneWeave/MentorEchoBridge.swift
    //    - `public struct MentorTurn, MentorDialogue, MentorInput`
    //    - `public enum InvisibleMentor` — deterministic synthesizer over
    //      user's own reflections. No network. No LLM. No Core ML.
    //      Reflection-gated: dormant below minimumReflections.
    //    - `public enum MentorEchoBridge` — bridges Sacred Echoes into
    //      Mentor input (Nemotron #14 wire-up).
    //      openEchoSeeds respects consent states (only .opened + .delivered).
    //    - `public enum MentorEchoBridgeConfig` — maxEchoesPerSession=5,
    //      recency decay curve.

    // 5. Cross-Domain Insight Engine — see Sources/OneWeave/GraphInsightGenerator.swift
    //    - `public enum GraphInsightGenerator` (@MainActor) — generateInsights,
    //      detectContradictions, applyInsight. 5-minute TTL cache keyed by
    //      entitySignature + contextFingerprint + harmonyScoreBucket.
    //      Cache invalidated on commit, body thread, P2P, insight apply.
    //    - `public enum InsightKind, ContradictionKind`
    //    - applyInsight requires non-empty reflectionText (reflection gate).

    // 6. P2P Weave Share — see Sources/OneWeave/P2PWeaveShare.swift
    //    - `public struct WeaveCircleShare, LifeEntitySnapshot,
    //      PendingWeaveShare`
    //    - `public enum P2PWeaveShare` — offlineQueue, pendingIntegrations,
    //      queueShare, processOfflineQueue, sendViaWebRTC,
    //      receiveAndIntegrate, drainPending.
    //      Reflection gate: pendingIntegrations drained only after user
    //      supplies reflectionText.

    // 7. Family Pod — see Sources/OneWeave/FamilyPod.swift
    //    - `public enum FamilyPodRole` — steward, witness, quiet.
    //    - `public enum PodVisibilityGrant` — 7 enumerated grants, defaults
    //      to strictest (only completedQuestCount + currentHarmonyScore).
    //    - `public enum FamilyPodLimits` — maxMembers=6, minExitReflection=20,
    //      entityPublishCooldown=3600s, maxPodsPerUser=3.
    //    - `public struct FamilyPodMember, FamilyPod, FamilyPodDigestEntry,
    //      PodEchoCountdown, FamilyPodMessage`
    //    - `public enum FamilyPodPolicy` — createPod, addMember,
    //      removeMember, exit, setGrant, nextEligiblePublish, isInQuietHours.
    //    - `public enum FamilyPodDigestBuilder` — build digest honoring grants.
    //    - `public enum FamilyPodDigestRedactor` — defense-in-depth, strips
    //      any field not in the grant set before transmission.

    // 8. Portable Export — see Sources/OneWeave/PortableExport.swift
    //    - `public enum ExportLeash` — localOnly, privateBundle,
    //      publicBundle, fullBundle. permitsReflections + permitsEchoPlaintext.
    //    - `public enum PortableExportPolicy` — fullBundleMinReflection=30,
    //      maxBundleBytes=16MB, currentBundleVersion=1.
    //    - `public struct PortableExportBundle, ExportManifest`
    //    - `public enum JournalMarkdownRenderer, GraphOPMLRenderer,
    //      EchoMarkdownRenderer, PortableExportBuilder,
    //      PortableExportChecksum`
    //    - `public enum PortableImportPolicy` — refusesFullBundleByDefault,
    //      supportedBundleVersions={1}.

    // 9. Schema Migration — see Sources/OneWeave/SchemaMigrationPlan.swift
    //    - `public enum OneWeaveSchemaV1, OneWeaveSchemaV3`
    //      (V2 is implicit / additive, not listed as a separate stage.)
    //    - `public enum OneWeaveMigrationPlan` — SchemaMigrationPlan
    //      conforming. stages declares V1→V3 lightweight.
    //    - `public enum OneWeaveMigrationLogic` — convertAttributesJSONToDict,
    //      convertAttributesDictToJSON, validateMigrationPath.

    // 10. App Lifecycle — see Sources/OneWeave/AppLifecycleCoordinator.swift
    //    - `public final class AppLifecycleCoordinator` (@MainActor)
    //      Coordinates scenePhase transitions; flushes writes on background,
    //      rehydrates on foreground.
    //    - `public struct EncryptedEnvelope` — AES-GCM + HKDF reusing
    //      SacredEcho vault seed for at-rest persistence.

    // 11. UI Helpers
    //    - `public final class OneWeaveApp` — app entry point.
    //      Sources/OneWeave/OneWeaveApp.swift
    //    - `public final class OneWeaveSnapshotStore` — App Group
    //      snapshot key/value for widget sync.
    //      Sources/OneWeave/OneWeaveSnapshotStore.swift
    //    - `public struct CommandPalette` — Universal Command Palette.
    //      Sources/OneWeave/CommandPalette.swift
    //    - `public final class ResonanceOracle`, `public struct ResonanceOracleSheet`
    //      Sources/OneWeave/ResonanceOracle.swift, ResonanceOracleSheet.swift
    //    - `public final class BodyThreadWeaver`, `public struct BodyThreadSheet`
    //      Sources/OneWeave/BodyThreadWeaver.swift, BodyThreadSheet.swift
    //    - `public enum StateMachineIndicator` — visualizes the AppStateMachine.
    //      Sources/OneWeave/StateMachineIndicator.swift
    //    - `public enum AppStateMachine` — master state machine.
    //      Sources/OneWeave/AppStateMachine.swift

    // 12. Loom Geometry — see Sources/OneWeave/LoomGeometry.swift,
    //                              Sources/OneWeave/LivingGraphLoom.swift
    //    - `public struct LoomState, LoomPoint, LoomThread, LoomStrand,
    //      LoomPalette, LoomInput`
    //    - `public enum LoomGeometry` — placeThreads (caps at maxThreads=40),
    //      domain-clustered layout, coherence-weighted radius.
    //    - `public final class LivingGraphLoom` — SwiftUI Canvas breathing
    //      renderer. Breath rate ∝ 1/timeOfDay; palette ∝ currentSeason.

    // MARK: - Public Constants (notable)

    public static let documentedPublicAPIs = [
        "LifeContext", "LifeEntity", "LifeRelationship", "TimelineEvent",
        "WeaveQuest", "DataLeashSettingsRecord", "SacredEcho",
        "BasicSelfThread", "CareKinThread", "MeaningThread",
        "StewardshipThread", "MentorTurn", "MentorDialogue", "MentorInput",
        "FamilyPod", "FamilyPodMember", "FamilyPodDigestEntry",
        "FamilyPodMessage", "PodEchoCountdown", "PortableExportBundle",
        "ExportManifest", "LoomState", "LoomPoint", "LoomThread",
        "LoomStrand", "LoomPalette", "LoomInput", "EncryptedEnvelope",
        "LifeInsight", "LifePattern", "WeaveCircleShare",
        "LifeEntitySnapshot", "AppLifecycleCoordinator"
    ]

    /// The total count of public types in this catalog. Bumping this
    /// when adding new types is part of the API contract.
    public static let apiVersion: Int = 1

    /// Files containing public types. Listed so a Mac-side integrator
    /// can grep them in one pass.
    public static let publicAPIFilePaths: [String] = [
        "Sources/OneWeave/LifeContext.swift",
        "Sources/OneWeave/LifeGraph.swift",
        "Sources/OneWeave/TimelineEvent.swift",
        "Sources/OneWeave/WeaveQuest.swift",
        "Sources/OneWeave/BasicSelfThread.swift",
        "Sources/OneWeave/CareKinThread.swift",
        "Sources/OneWeave/MeaningThread.swift",
        "Sources/OneWeave/StewardshipThread.swift",
        "Sources/OneWeave/DataLeashSettings.swift",
        "Sources/OneWeave/SacredEcho.swift",
        "Sources/OneWeave/InvisibleMentor.swift",
        "Sources/OneWeave/MentorEchoBridge.swift",
        "Sources/OneWeave/GraphInsightGenerator.swift",
        "Sources/OneWeave/P2PWeaveShare.swift",
        "Sources/OneWeave/FamilyPod.swift",
        "Sources/OneWeave/PortableExport.swift",
        "Sources/OneWeave/SchemaMigrationPlan.swift",
        "Sources/OneWeave/AppLifecycleCoordinator.swift",
        "Sources/OneWeave/LoomGeometry.swift",
        "Sources/OneWeave/LivingGraphLoom.swift",
        "Sources/OneWeave/OneWeaveApp.swift",
        "Sources/OneWeave/OneWeaveSnapshotStore.swift",
        "Sources/OneWeave/CommandPalette.swift",
        "Sources/OneWeave/ResonanceOracle.swift",
        "Sources/OneWeave/ResonanceOracleSheet.swift",
        "Sources/OneWeave/BodyThreadWeaver.swift",
        "Sources/OneWeave/BodyThreadSheet.swift",
        "Sources/OneWeave/StateMachineIndicator.swift",
        "Sources/OneWeave/AppStateMachine.swift"
    ]
}