import Foundation
import SwiftData

enum Frequency: String, CaseIterable {
    case day, week, month
    var title: String {
        switch self {
        case .day: return tr("每天", "Day")
        case .week: return tr("每週", "Week")
        case .month: return tr("每月", "Month")
        }
    }
}

@Model
final class Habit {
    var id: UUID = UUID()
    var name: String = ""
    var frequencyRaw: String = Frequency.week.rawValue
    var targetCount: Int = 3
    var colorIndex: Int = 0
    var createdAt: Date = Date()
    var sortOrder: Int = 0
    var reminderEnabled: Bool = false
    var reminderMinutes: Int = 20 * 60
    var plantType: String = "grass"
    /// Stable slot in the town; -1 until assigned.
    var plotIndex: Int = -1
    @Relationship(deleteRule: .cascade, inverse: \Completion.habit)
    var completions: [Completion] = []

    init(name: String, frequency: Frequency, targetCount: Int, colorIndex: Int, sortOrder: Int) {
        self.name = name
        self.frequencyRaw = frequency.rawValue
        self.targetCount = targetCount
        self.colorIndex = colorIndex
        self.sortOrder = sortOrder
    }
}

@Model
final class Completion {
    var day: Date = Date()
    var habit: Habit?

    init(day: Date, habit: Habit) {
        self.day = day
        self.habit = habit
    }
}

enum Store {
    static let groupID = "group.com.charonyuu.habitgrow"

    static let container: ModelContainer = {
        let schema = Schema([Habit.self, Completion.self])
        let config = ModelConfiguration(schema: schema, groupContainer: .identifier(groupID))
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("ModelContainer failed: \(error)")
        }
    }()
}
