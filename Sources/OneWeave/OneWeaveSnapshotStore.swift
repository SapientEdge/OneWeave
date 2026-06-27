import Foundation

struct OneWeaveSnapshot: Codable, Equatable {
    var harmonyScore: Double
    var weaveLevel: Int
    var weaveEssence: Int
    var globalWeaveStreak: Int
    var graceDaysUsed: Int
    var topQuestTitle: String?
    var topQuestDomain: String?
    var activeQuestTitles: [String]
    var masteryTiers: [String: Int]
    var lastUpdated: Date
    
    // Life OS enhancements (Life Graph + Coherence)
    var lifeCoherenceScore: Double?
    var graphEntityCount: Int?

    static let production = OneWeaveSnapshot(
        harmonyScore: 0.5,
        weaveLevel: 1,
        weaveEssence: 0,
        globalWeaveStreak: 0,
        graceDaysUsed: 0,
        topQuestTitle: nil,
        topQuestDomain: nil,
        activeQuestTitles: [],
        masteryTiers: ["Self":1, "Stewardship":1, "CareKin":1, "Meaning":1],
        lastUpdated: Date(),
        lifeCoherenceScore: nil,
        graphEntityCount: nil
    )
}

final class OneWeaveSnapshotStore {
    static let shared = OneWeaveSnapshotStore()
    private let suiteName = "group.com.oneweave"
    private let key = "OneWeaveSnapshot"

    private init() {}

    func write(_ snapshot: OneWeaveSnapshot) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: key)
        }
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    func read() -> OneWeaveSnapshot {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(OneWeaveSnapshot.self, from: data) else {
            return .production
        }
        return snapshot
    }
}
