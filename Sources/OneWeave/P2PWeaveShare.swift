import Foundation
import SwiftData  // T100: P2PWeaveShare uses ModelContext in drainPending/receiveAndIntegrate signatures
import CryptoKit

// Deeper P2P Weave Share - Enhanced from iOS P2P Messaging Implementation Guide
// Hybrid: Network framework (Bonjour local) + WebRTC (internet)
// Offline queue, QR signaling for serverless auth, reflection gates, Data Leash
// E2EE: CryptoKit + notes for full Signal Protocol (X3DH + Double Ratchet) in prod
// Fresh OneWeave: Weave Circles as trusted, named groups with repeated private sync of Life Graph subsets.
// All shares respect reflection gates and isPrivate flags.

struct WeaveCircleShare: Codable {
    let circleID: UUID
    let circleName: String
    let entities: [LifeEntitySnapshot]  // Codable snapshots for transfer
    let reflectionRequired: Bool
    let timestamp: Date
    let senderReflectionNote: String?  // Required if reflection gate
    let source: String  // e.g. "LifeGraph", "CalendarImport"
}

// Lightweight codable snapshot of LifeEntity for P2P (avoids full @Model serialization)
struct LifeEntitySnapshot: Codable {
    let id: UUID
    let type: String
    let title: String
    let summary: String
    let domains: [String]
    let harmonyImpact: Double
    let memoryType: String
    let isPrivate: Bool
    let allowedCategories: [String]
    let attributes: String  // JSON bag (e.g. HealthMetrics for Body Thread)
}

struct PendingWeaveShare {
    let share: WeaveCircleShare
    let targetPeer: String?
    let createdAt: Date
    var attempts: Int = 0
}

struct P2PWeaveShare {

    // MARK: - Offline Queue (hybrid minimal server + direct P2P)
    static var offlineQueue: [PendingWeaveShare] = []

    // MARK: - Pending Integrations (received shares waiting on user reflection)
    // Nemotron finding #4: previously these entities leaked into the user's graph
    // before reflection. Now held separately until reflection text is supplied.
    static var pendingIntegrations: [WeaveCircleShare] = []

    /// Call once the user has supplied a reflection to drain pending shares.
    @MainActor
    static func drainPending(into context: LifeContext, with reflection: String, modelContext: ModelContext? = nil) {
        let trimmed = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let stillPending: [WeaveCircleShare] = []
        for share in pendingIntegrations {
            receiveAndIntegrate(share: share, into: context, userReflection: trimmed, modelContext: modelContext)
        }
        pendingIntegrations = stillPending
    }
    
    static func queueShare(_ share: WeaveCircleShare, target: String? = nil) {
        let pending = PendingWeaveShare(share: share, targetPeer: target, createdAt: Date())
        offlineQueue.append(pending)
        print("[P2P] Queued share for \(target ?? "any peer"). Offline queue size: \(offlineQueue.count)")
        // In prod: Persist to SwiftData or UserDefaults. Retry on foreground + network.
    }
    
    static func processOfflineQueue() {
        guard !offlineQueue.isEmpty else { return }
        print("[P2P] Processing offline queue (\(offlineQueue.count) items)...")
        for (index, pending) in offlineQueue.enumerated().reversed() {
            // Simulate: direct if possible, else handoff to minimal relay
            if pending.attempts < 3 {
                sendViaWebRTC(share: pending.share, to: pending.targetPeer ?? "relay")
                offlineQueue[index].attempts += 1
            } else {
                print("[P2P] Dropping stale share after max attempts (hybrid relay recommended)")
                offlineQueue.remove(at: index)
            }
        }
    }
    
    // MARK: - Network Framework Local Discovery (Bonjour)
    static func startLocalListener(serviceType: String = "_oneweave._tcp") {
        print("[P2P] Starting Network framework listener for \(serviceType)")
        print("  -> NWListener with parameters.includePeerToPeer = true")
        print("  -> Requires NSLocalNetworkUsageDescription and NSBonjourServices in Info.plist")
        // Real implementation:
        // let params = NWParameters.tcp; params.includePeerToPeer = true
        // let listener = try? NWListener(using: params, on: 9876)
        // listener?.service = NWListener.Service(name: "OneWeave", type: serviceType)
        // listener?.newConnectionHandler = { handleConnection($0) }
    }
    
    static func startLocalBrowser(serviceType: String = "_oneweave._tcp") {
        print("[P2P] Starting Bonjour browser for nearby OneWeave peers")
        // Real: NWBrowser(for: .bonjour(type: serviceType, domain: nil), using: params)
    }
    
    // MARK: - WebRTC + ICE/STUN/TURN (Internet)
    static func sendViaWebRTC(share: WeaveCircleShare, to peer: String) {
        print("[P2P] WebRTC data channel to \(peer)")
        print("  Circle: \(share.circleName) | Entities: \(share.entities.count)")
        print("  Reflection required: \(share.reflectionRequired)")
        print("  Source: \(share.source)")
        // Real: GoogleWebRTC framework + data channel.
        // ICE: stun.l.google.com:19302 (free, ~70-80% success). Self-host Coturn for TURN.
        // DTLS mandatory. Handoff to relay if direct fails (15-20%).
        // Background: Queue + PushKit (only for VoIP/CallKit approved use; misuse = rejection).
    }
    
    // MARK: - Serverless QR Signaling (from research)
    static func generateQRForShare(_ share: WeaveCircleShare) -> String {
        // Simulate: Encode SDP offer + circle metadata as QR (Signal-style safety numbers)
        let payload = "oneweave://circle/\(share.circleID.uuidString)?entities=\(share.entities.count)"
        print("[P2P] QR payload for out-of-band exchange (scan to establish): \(payload)")
        // Real: Generate QR with SDP + short auth string. Recipient scans answer.
        // Prevents MITM. NFC or in-person for highest trust.
        return payload
    }
    
    // MARK: - Create Share with Reflection Gate + Data Leash
    static func createCircleShare(
        from entities: [LifeEntity],
        circleName: String = "Trusted Weave Circle",
        requireReflection: Bool = true,
        senderReflection: String? = nil
    ) -> WeaveCircleShare? {
        
        let filtered = entities.filter { entity in
            // Data Leash (Privacy Tier-1 contract):
            // - Only share entities the user has explicitly allowed.
            // - Never share private entities even if they happen to be in an allowed category
            //   (privacy flag is a hard gate, categories are a soft filter).
            guard !entity.isPrivate else { return false }
            let allowed = entity.allowedCategories
            return !allowed.isEmpty && allowed.contains { $0.lowercased() != "private" }
        }
        
        guard !filtered.isEmpty else {
            print("[P2P] No shareable entities (Data Leash filtered)")
            return nil
        }
        
        if requireReflection && senderReflection == nil {
            print("[P2P] Reflection gate: Must provide note before sharing sensitive entities")
            return nil
        }
        
        let snapshots = filtered.map { entity in
            LifeEntitySnapshot(
                id: entity.id,
                type: entity.type.rawValue,
                title: entity.title,
                summary: entity.summary,
                domains: entity.domains,
                harmonyImpact: entity.harmonyImpact,
                memoryType: entity.memoryType.rawValue,
                isPrivate: entity.isPrivate,
                allowedCategories: entity.allowedCategories,
                attributes: entity.attributes
            )
        }
        
        let share = WeaveCircleShare(
            circleID: UUID(),
            circleName: circleName,
            entities: snapshots,
            reflectionRequired: requireReflection,
            timestamp: Date(),
            senderReflectionNote: senderReflection,
            source: "LifeGraph"
        )
        
        print("[P2P] Created Weave Circle share: \(circleName) with \(snapshots.count) entities")
        return share
    }
    
    // MARK: - Receive + Integrate with Reflection Gate
    @MainActor
    static func receiveAndIntegrate(share: WeaveCircleShare, into context: LifeContext, userReflection: String? = nil, modelContext: ModelContext? = nil) {
        // Reflection Gate: when the share requires reflection, we MUST NOT append anything
        // to the user's graph. Instead, hold snapshots in a separate pending list until the
        // user writes a note. (Nemotron finding #4.)
        if share.reflectionRequired {
            let trimmed = userReflection?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !trimmed.isEmpty else {
                print("[P2P] Reflection gate active. Held \(share.entities.count) entities pending reflection. No data written to graph.")
                P2PWeaveShare.pendingIntegrations.append(share)
                return
            }
        }

        print("[P2P] Integrating Weave Circle '\(share.circleName)' after reflection.")
        for snapshot in share.entities {
            // Convert snapshot back to LifeEntity and link
            let entity = LifeEntity(
                type: EntityType(rawValue: snapshot.type) ?? .concept,
                title: snapshot.title,
                summary: snapshot.summary
            )
            entity.domains = snapshot.domains
            entity.harmonyImpact = snapshot.harmonyImpact
            entity.memoryType = MemoryType(rawValue: snapshot.memoryType) ?? .episodic
            entity.isPrivate = snapshot.isPrivate
            entity.allowedCategories = snapshot.allowedCategories
            entity.attributes = snapshot.attributes
            entity.lastUpdated = Date()

            if let mc = modelContext { mc.insert(entity) }
            context.lifeGraphEntities.append(entity)
            // Bonus coherence/essence on successful private share + reflection
            context.harmonyScore = min(1.0, context.harmonyScore + 0.03)
            // New entity written — insight cache stale. Tier A #1.
            GraphInsightGenerator.invalidateCache()
        }

        // Record the reflection (required to count)
        let note = share.senderReflectionNote ?? userReflection ?? ""
        let event = TimelineEvent(
            thread: "CareKin",
            type: "p2p_weave_circle_received",
            payload: ["circle": share.circleName, "reflection": note]
        )
        if let mc = modelContext { mc.insert(event) }
        context.updateFromEvent(event)

        print("[P2P] Integration complete. New coherence: \(context.lifeCoherenceScore)")
    }
    
    // MARK: - BLE Proximity (off-grid from research)
    static func startBLEProximity() {
        print("[P2P] Starting BLE for local proximity sharing (Core Bluetooth)")
        print("  -> Limited to ~50KB/s, 10-30m typical. Great for in-person Weave Circles.")
        // Real: CBCentralManager + CBPeripheral. Advertise service UUID.
        // Background limited (~10s execution).
    }
    
    // MARK: - Encryption Notes (Signal Protocol alignment)
    // For production:
    // - Use libsignal or CryptoKit + custom ratchet for X3DH + Double Ratchet.
    // - Pre-shared keys for initial, then ratcheting for forward secrecy.
    // - QR for safety number verification (60-digit hash).
    // Current: CryptoKit for any local signing/encryption of shares before transfer.
    static func encryptSharePayload(_ data: Data, key: SymmetricKey) -> Data {
        // Placeholder for real E2EE
        return data  // In prod: ChaChaPoly or AES-GCM + ratchet
    }
}

// Extension for easy sharing from LifeContext
extension LifeContext {
    func shareViaP2P(selectedEntities: [LifeEntity], circleName: String = "My Weave Circle", reflection: String? = nil) {
        guard let share = P2PWeaveShare.createCircleShare(
            from: selectedEntities,
            circleName: circleName,
            requireReflection: true,
            senderReflection: reflection
        ) else { return }
        
        P2PWeaveShare.queueShare(share)
        P2PWeaveShare.sendViaWebRTC(share: share, to: "trusted-peer")
        // Also offer QR: let qr = P2PWeaveShare.generateQRForShare(share)
    }
}
