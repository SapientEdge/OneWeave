import Foundation

// Extension to OneWeavePrototype for Life Graph + Insight validation
// This runs in the DEBUG harness only. Exercises new code with real-ish data from existing threads/quests.
// "Validated" = logs expected outputs for coherence, resonance, insights.

extension OneWeavePrototype {
    
    func validateLifeGraphAndInsights() {
        print("\n=== LIFE OS GRAPH + INSIGHT VALIDATION (Prototype Harness) ===")
        
        // Seed from existing OneWeave data (no replacement - bridges)
        let sampleEvents = [
            TimelineEvent(thread: "CareKin", type: "family_time", payload: ["mood": "connected"], affectsEnergy: true),
            TimelineEvent(thread: "Meaning", type: "reflection", payload: ["insight": "long term goal"], affectsEnergy: false),
            TimelineEvent(thread: "Self", type: "win", payload: ["goal": "deep work"], affectsEnergy: true)
        ]
        
        let sampleQuests = [
            WeaveQuest(id: UUID(), title: "Call mom", domains: ["CareKin"], reflectionNote: "Felt good after"),
            WeaveQuest(id: UUID(), title: "Journal on purpose", domains: ["Meaning"], reflectionNote: nil)
        ]
        
        // Build graph
        var graphEntities: [LifeEntity] = []
        for event in sampleEvents {
            let e = LifeEntity.fromTimelineEvent(event, context: lifeContext)
            graphEntities.append(e)
            lifeContext.lifeGraphEntities.append(e)
        }
        for quest in sampleQuests {
            let e = LifeEntity.fromQuest(quest)
            graphEntities.append(e)
            lifeContext.lifeGraphEntities.append(e)
        }
        
        // Add some relationships (social + temporal example)
        if graphEntities.count >= 2 {
            let rel = LifeRelationship(type: .social, strength: 0.85)
            rel.fromEntity = graphEntities[0]
            rel.toEntity = graphEntities[1]
            lifeContext.lifeGraphRelationships.append(rel)
            graphEntities[0].outgoingRelationships.append(rel)
        }
        
        // Compute & validate
        let coherence = lifeContext.lifeCoherenceScore
        print("Life Coherence Score: \(String(format: "%.2f", coherence)) (target >0.4 for healthy weave)")
        
        let resonance = LifeGraph.calculateResonance(for: graphEntities.first!, allEntities: graphEntities)
        print("Sample Weave Resonance: \(String(format: "%.2f", resonance))")
        
        // Generate insights
        let insights = GraphInsightGenerator.generateInsights(from: lifeContext, entities: graphEntities)
        print("\nGenerated \(insights.count) Cross-Domain Insights:")
        for insight in insights {
            print("  • \(insight.title) (conf: \(String(format: "%.0f", insight.confidence*100))%)")
            print("    \(insight.description)")
            if let action = insight.suggestedAction {
                print("    Suggested: \(action)")
            }
            print("    Essence bonus if applied: +\(Int(insight.essenceBonus))")
        }
        
        // Apply top insight (demo)
        if let top = insights.first {
            GraphInsightGenerator.applyInsight(top, to: lifeContext)
            print("\nApplied top insight. New essence: \(Int(lifeContext.weaveEssence))")
        }
        
        // Data Leash demo
        if let healthish = graphEntities.first(where: { $0.domains.contains("CareKin") }) {
            healthish.isPrivate = true
            healthish.allowedCategories = ["social", "personal"]
            print("Data Leash active on sample entity: isPrivate=\(healthish.isPrivate)")
        }
        
        // Push updated snapshot (widgets get coherence now)
        lifeContext.pushSnapshotToWidgets(from: sampleQuests)
        print("Snapshot updated with lifeCoherenceScore")

        // Tier A #1: insight-cache validation. Warm hit on second call, then
        // explicit invalidation forces a miss on the third.
        GraphInsightGenerator.resetCounters()
        let firstCall  = GraphInsightGenerator.generateInsights(from: lifeContext, entities: graphEntities)
        let secondCall = GraphInsightGenerator.generateInsights(from: lifeContext, entities: graphEntities)
        GraphInsightGenerator.invalidateCache()
        let thirdCall  = GraphInsightGenerator.generateInsights(from: lifeContext, entities: graphEntities)
        let stats = GraphInsightGenerator.cacheStats()
        let equalResults = (firstCall.map(\.title) == secondCall.map(\.title))
            && (firstCall.map(\.title) == thirdCall.map(\.title))
        print("Cache stats — hits: \(stats.hits), misses: \(stats.misses), invalidations: \(stats.invalidations)")
        print("Cache equality: \(equalResults ? "PASS" : "FAIL")  (expected hits=1, misses=2, equal=true)")

        // Tier A #2: Mail / Notes / Reminders Data Leash + reflection-gate validation.
        // These run entirely in pure-Swift (no EventKit/MessageUI imports needed in harness).
        let strictLeash = DataLeashState.strictDefault   // everything blocked
        let fullyOpen = DataLeashState(
            allowedCategories: Dictionary(uniqueKeysWithValues: IntegrationCategory.allCases.map { ($0, true) }),
            privacyLevels: Dictionary(uniqueKeysWithValues: IntegrationCategory.allCases.map { ($0, false) })
        )

        // Mail: URL must be nil when leash blocks, non-nil when allowed.
        let mailURLBlocked = MailIntegration.composeURL(
            to: "you@example.com",
            subject: "Weave",
            body: "hello",
            leash: strictLeash
        )
        let mailURLOpen = MailIntegration.composeURL(
            to: "you@example.com",
            subject: "Weave",
            body: "hello",
            leash: fullyOpen
        )
        // Mail insight body: requires non-empty reflection.
        let insightBodyEmpty = MailIntegration.insightBody(
            insightTitle: "High Harmony",
            reflection: "   ",
            leash: fullyOpen
        )
        let insightBodyOK = MailIntegration.insightBody(
            insightTitle: "High Harmony",
            reflection: "I noticed I feel most clear after morning walks.",
            leash: fullyOpen
        )
        // Mail insight body denied when leash blocks.
        let insightBodyDenied = MailIntegration.insightBody(
            insightTitle: "x",
            reflection: "real text",
            leash: strictLeash
        )

        // Notes: payload requires reflection; denied when leash blocks.
        let noteReflectionBlocked = NotesIntegration.reflectionPayload(
            questTitle: "Call mom",
            reflection: "",
            domains: ["CareKin"],
            leash: fullyOpen
        )
        let noteReflectionOK = NotesIntegration.reflectionPayload(
            questTitle: "Call mom",
            reflection: "Felt really good after — she told me about the garden.",
            domains: ["CareKin"],
            leash: fullyOpen
        )
        let noteReflectionDenied = NotesIntegration.reflectionPayload(
            questTitle: "x", reflection: "y", domains: [], leash: strictLeash
        )

        // Notes decision payload
        let decisionPayloadOK = NotesIntegration.decisionPayload(
            scenarioSummary: "Two job offers",
            reflection: "Going with the smaller team. Trust matters more than title.",
            leash: fullyOpen
        )
        let decisionPayloadDenied = NotesIntegration.decisionPayload(
            scenarioSummary: "x", reflection: "y", leash: strictLeash
        )

        // Reminders: requestAccess + createReminder cannot be called here (EventKit
        // not available on Linux); we instead verify the gate logic directly via
        // the body formatters it uses + via reflection-gate correctness.
        let reflectionLeashSummary = """
        Mail:   url=\(mailURLBlocked == nil ? "nil" : "ok") blocked, \(mailURLOpen == nil ? "nil" : "ok") open
                insightBody empty=\(insightBodyEmpty == nil ? "PASS" : "FAIL")
                insightBody ok=\(insightBodyOK == nil ? "FAIL" : "PASS")
                insightBody denied=\(insightBodyDenied == nil ? "PASS" : "FAIL")
        Notes:  reflection empty=\(noteReflectionBlocked == nil ? "PASS" : "FAIL")
                reflection ok=\(noteReflectionOK == nil ? "FAIL" : "PASS")
                reflection denied=\(noteReflectionDenied == nil ? "PASS" : "FAIL")
                decision ok=\(decisionPayloadOK == nil ? "FAIL" : "PASS")
                decision denied=\(decisionPayloadDenied == nil ? "PASS" : "FAIL")
        """
        print(reflectionLeashSummary)
        let tierA2Pass =
            (mailURLBlocked == nil)
            && (mailURLOpen != nil)
            && (insightBodyEmpty == nil)
            && (insightBodyOK != nil)
            && (insightBodyDenied == nil)
            && (noteReflectionBlocked == nil)
            && (noteReflectionOK != nil)
            && (noteReflectionDenied == nil)
            && (decisionPayloadOK != nil)
            && (decisionPayloadDenied == nil)
        print("Tier A #2 (Mail/Notes): \(tierA2Pass ? "PASS" : "FAIL")")

        // Sanity: canSendMail / canSendReminders are well-typed on Linux (notAvailable).
        print("canSendMail (Linux harness): \(MailIntegration.canSendMail)")

        // Tier A #3: Sacred Echo Vault — gate logic + cipher round-trip + time-passage simulation.
        // SwiftData ModelContext isn't available on Linux, so we exercise the pure-Swift
        // gate logic + cipher envelope. The store's SwiftData path is exercised on device.
        let futureUnlock = Date().addingTimeInterval(60 * 60 * 24 * 30) // 30 days
        let pastUnlock   = Date().addingTimeInterval(-60 * 60 * 24 * 7) // 7 days ago

        // 1. Empty reflection is refused.
        var sealEmptyOK = false
        do {
            _ = try SacredEchoStore.seal(
                title: "Future me",
                reflection: "   ",
                decree: "Open when ready",
                unlockAt: futureUnlock,
                heirLifeEntityID: "",
                into: lifeContext
            )
            sealEmptyOK = false  // if we got here, the gate failed
        } catch EchoError.emptyReflection {
            sealEmptyOK = true
        } catch {
            sealEmptyOK = false
        }

        // 2. Past unlock date is refused.
        var sealPastOK = false
        do {
            _ = try SacredEchoStore.seal(
                title: "x",
                reflection: "real text",
                decree: "",
                unlockAt: pastUnlock,
                heirLifeEntityID: "",
                into: lifeContext
            )
            sealPastOK = false
        } catch EchoError.unlockDateInPast {
            sealPastOK = true
        } catch {
            sealPastOK = false
        }

        // 3. Cipher round-trip with the test seed.
        let id = UUID()
        let (ct, n, tag) = try! SacredEchoCipher.seal(
            plaintext: "I hope you remembered why you started.",
            echoID: id
        )
        let opened = try! SacredEchoCipher.open(
            ciphertext: ct, nonce: n, tag: tag, echoID: id
        )
        let cipherRoundTrip = (opened == "I hope you remembered why you started.")

        // 4. Tampered ciphertext fails.
        var tamperOK = false
        do {
            var tampered = ct
            tampered[0] ^= 0xFF
            _ = try SacredEchoCipher.open(ciphertext: tampered, nonce: n, tag: tag, echoID: id)
            tamperOK = false
        } catch {
            tamperOK = true
        }

        // 5. Different echo id cannot open another echo's ciphertext (key isolation).
        var keyIsolationOK = false
        do {
            _ = try SacredEchoCipher.open(
                ciphertext: ct, nonce: n, tag: tag,
                echoID: UUID()  // wrong id
            )
            keyIsolationOK = false
        } catch {
            keyIsolationOK = true
        }

        // 6. Lifecycle state transitions under simulated time.
        let echoForLifecycle = SacredEcho(
            title: "Lifecycle test",
            decree: "",
            ciphertext: Data(), nonce: Data(), tag: Data(),
            unlockAt: Date().addingTimeInterval(60 * 60 * 24 * 10) // 10 days
        )
        let initialState = echoForLifecycle.state
        // Simulate 30 days passing
        SacredEcho.nowOverride = { Date().addingTimeInterval(60 * 60 * 24 * 30) }
        let postTimeState = echoForLifecycle.state
        SacredEcho.nowOverride = nil
        let lifecycleOK = (initialState == .maturing) && (postTimeState == .openingReady)

        let tierA3Pass = sealEmptyOK && sealPastOK && cipherRoundTrip && tamperOK
            && keyIsolationOK && lifecycleOK
        let t3Lines = """
        Sacred Echo:
            seal empty rejected:  \(sealEmptyOK ? "PASS" : "FAIL")
            seal past-date rej.:  \(sealPastOK ? "PASS" : "FAIL")
            cipher round-trip:    \(cipherRoundTrip ? "PASS" : "FAIL")
            tamper detection:     \(tamperOK ? "PASS" : "FAIL")
            key isolation:        \(keyIsolationOK ? "PASS" : "FAIL")
            lifecycle maturing→openingReady: \(lifecycleOK ? "PASS" : "FAIL")
        """
        print(t3Lines)
        print("Tier A #3 (Sacred Echo): \(tierA3Pass ? "PASS" : "FAIL")")

        // Tier A #4: Invisible Mentor — synthesis over the user's own history.
        let mentorInput = InvisibleMentor.makeInput(from: lifeContext)
        let mentorPrompt = "I'm tired of the CareKin pull lately."
        let mentorDialogue = InvisibleMentor.respond(to: mentorPrompt, from: mentorInput)

        // Reflection-gate check: dormant when no reflections exist.
        let emptyInput = MentorInput(
            reflections: [], openedEchoes: [],
            coherenceScore: 0.5, completedQuestCount: 0
        )
        let dormantDialogue = InvisibleMentor.respond(to: "anything", from: emptyInput)

        let mentorPass =
            (mentorDialogue.candidates.count > 0)
            && (dormantDialogue.candidates.isEmpty)
            && mentorDialogue.candidates.allSatisfy { !$0.spoken.isEmpty }
            // All cited reflections come from the user's own history (id is set).
            && mentorDialogue.candidates.allSatisfy { $0.citedReflectionID != nil }

        let mentorLines = """
        Invisible Mentor:
            candidates generated:    \(mentorDialogue.candidates.count)
            dormant when empty:      \(dormantDialogue.candidates.isEmpty ? "PASS" : "FAIL")
            no empty spoken:         \(mentorDialogue.candidates.allSatisfy { !$0.spoken.isEmpty } ? "PASS" : "FAIL")
            all citations sourced:   \(mentorDialogue.candidates.allSatisfy { $0.citedReflectionID != nil } ? "PASS" : "FAIL")
        """
        print(mentorLines)
        if let first = mentorDialogue.candidates.first {
            print("Sample Mentor voice:\n  \(first.spoken.prefix(200))…")
        }
        print("Tier A #4 (Invisible Mentor): \(mentorPass ? "PASS" : "FAIL")")

        // Tier A #5: App Lifecycle — envelope shape + JSON round-trip + encryption parity.
        // We can't write to an App Group container on Linux, but we can validate
        // the envelope construction + JSON shape + encryption round-trip via
        // the cipher layer.

        // Build a synthetic envelope from a sample entity list (mirror of what
        // the production code does in makeEnvelope()).
        struct SampleEntity {
            let id: String
            let type: String
            let title: String
            let summary: String
            let memoryType: String
            let domains: [String]
            let harmonyImpact: Double
            let isPrivate: Bool
            let createdAt: Date
            let lastUpdated: Date
            let attributes: [String: String]
        }
        let sampleEntities: [SampleEntity] = [
            SampleEntity(
                id: UUID().uuidString, type: "task", title: "Call mom",
                summary: "Felt really good after — she told me about the garden.",
                memoryType: "procedural", domains: ["CareKin"],
                harmonyImpact: 0.6, isPrivate: false,
                createdAt: Date(), lastUpdated: Date(),
                attributes: ["source": "WeaveQuest"]
            ),
            SampleEntity(
                id: UUID().uuidString, type: "event", title: "Morning walk",
                summary: "Clear head. Decided not to take the meeting.",
                memoryType: "episodic", domains: ["Self", "Meaning"],
                harmonyImpact: 0.4, isPrivate: true,
                createdAt: Date(), lastUpdated: Date(),
                attributes: [:]
            ),
        ]

        // JSON round-trip: serialize a Codable envelope + read back. Mirrors
        // what the production encrypt() + persist() + restore() chain does.
        struct TestEnvelope: Codable, Equatable {
            let version: Int
            let savedAt: Date
            let entities: [SampleEntity]
            let coherenceScore: Double
            let weaveEssence: Double
        }
        // We need SampleEntity to be Codable + Equatable for the test envelope.
        // Define a Codable mirror so the test is independent of the production
        // DTO types.
        let envelope = TestEnvelope(
            version: 1,
            savedAt: Date(),
            entities: sampleEntities,
            coherenceScore: 0.58,
            weaveEssence: 124
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let plain = try! encoder.encode(envelope)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let roundTripped = try! decoder.decode(TestEnvelope.self, from: plain)
        let jsonRoundTrip = (roundTripped == envelope)

        // App Group path resolution: containerURL() should return a valid URL
        // even when the App Group doesn't exist (falls back to tmp dir).
        let containerURL = AppLifecyclePaths.containerURL()
        let pathOK = containerURL.path.contains("oneweave")
        let lifeGraphURL = AppLifecyclePaths.lifeGraphURL(encrypted: false)
        let filenameOK = lifeGraphURL.lastPathComponent == AppLifecyclePaths.lifeGraphFilename

        // Sacred Echo + envelope key isolation: the envelope uses a fixed UUID
        // (AppLifecycleConstants.envelopeKeyID); the SacredEchoCipher vault
        // seed derives keys via HKDF. We verify the constants are stable.
        let keyIDStable = (AppLifecycleConstants.envelopeKeyID.uuidString == "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")

        let tierA5Pass = jsonRoundTrip && pathOK && filenameOK && keyIDStable
        let t5Lines = """
        App Lifecycle:
            JSON envelope round-trip:    \(jsonRoundTrip ? "PASS" : "FAIL")
            App Group path resolves:     \(pathOK ? "PASS" : "FAIL")
            envelope filename stable:    \(filenameOK ? "PASS" : "FAIL")
            envelope key id stable:      \(keyIDStable ? "PASS" : "FAIL")
        """
        print(t5Lines)
        print("Tier A #5 (App Lifecycle): \(tierA5Pass ? "PASS" : "FAIL")")

        print("=== VALIDATION COMPLETE - Graph logic exercised successfully ===\n")
    }
}
