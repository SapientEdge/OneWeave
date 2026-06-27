import Foundation

struct OneWeaveSnapshot: Codable, Equatable {
    var harmonyScore: Double
    var weaveLevel: Int
    var globalWeaveStreak: Int
    var activeQuestTitles: [String]
    var masteryTiers: [String: Int]
    var lastUpdated: Date

    static let placeholder = OneWeaveSnapshot(
        harmonyScore: 0.5,
        weaveLevel: 1,
        globalWeaveStreak: 0,
        activeQuestTitles: [],
        masteryTiers: ["Self":1, "Stewardship":1, "CareKin":1, "Meaning":1],
        lastUpdated: Date()
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
    }

    func read() -> OneWeaveSnapshot {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(OneWeaveSnapshot.self, from: data) else {
            return .placeholder
        }
        return snapshot
    }
}
