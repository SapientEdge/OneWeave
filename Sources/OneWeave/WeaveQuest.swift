import SwiftUI
import SwiftData

@Model
final class WeaveQuest {
    var id: UUID = UUID()
    var title: String = ""
    var questDescription: String = ""
    var domains: [String] = []
    var baseEssence: Int = 5
    var status: QuestStatus = QuestStatus.pending
    var estimatedIRLMinutes: Int = 15
    var validationHints: String = ""
    var linkedEventId: UUID? = nil
    var reflectionNote: String? = nil
    var completedAt: Date? = nil
    var createdAt: Date = Date()
    
    init(title: String, description: String, domains: [String], baseEssence: Int = 5, estimatedIRLMinutes: Int = 15, validationHints: String = "") {
        self.title = title
        self.questDescription = description
        self.domains = domains
        self.baseEssence = baseEssence
        self.estimatedIRLMinutes = estimatedIRLMinutes
        self.validationHints = validationHints
    }
    
    enum QuestStatus: String, Codable, CaseIterable {
        case pending = "Pending"
        case active = "Active"
        case completed = "Completed"
        case reflected = "Reflected"
    }
}

extension WeaveQuest {
    var isIRLReady: Bool {
        return estimatedIRLMinutes > 0
    }
    
    var displayEssence: String {
        "✧ \(baseEssence)"
    }
}
