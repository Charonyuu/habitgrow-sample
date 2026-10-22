import AppIntents
import SwiftData
import WidgetKit

struct ToggleHabitIntent: AppIntent {
    static let title: LocalizedStringResource = "切換今日完成"
    static let isDiscoverable = false

    @Parameter(title: "Habit ID") var habitID: String

    init() {}
    init(habitID: String) { self.habitID = habitID }

    @MainActor
    func perform() async throws -> some IntentResult {
        let context = Store.container.mainContext
        let habits = try context.fetch(FetchDescriptor<Habit>())
        habits.first { $0.id.uuidString == habitID }?.toggle(.now, in: context)
        return .result()
    }
}

struct HabitEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "習慣")
    static let defaultQuery = HabitQuery()

    var id: String
    var name: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
}

struct HabitQuery: EntityQuery {
    @MainActor
    private func all() throws -> [HabitEntity] {
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortOrder)])
        return try Store.container.mainContext.fetch(descriptor)
            .map { HabitEntity(id: $0.id.uuidString, name: $0.name) }
    }

    @MainActor
    func entities(for identifiers: [String]) async throws -> [HabitEntity] {
        try all().filter { identifiers.contains($0.id) }
    }

    @MainActor
    func suggestedEntities() async throws -> [HabitEntity] { try all() }
}

struct SelectHabitIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "選擇習慣"
    static let description = IntentDescription("選擇要顯示的習慣")

    @Parameter(title: "習慣") var habit: HabitEntity?

    init() {}
}
