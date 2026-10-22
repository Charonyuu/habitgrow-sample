import Foundation

/// The app renders a picture of the town; the widget just shows it.
enum TownSnapshotStore {
    static var url: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Store.groupID)?
            .appendingPathComponent("town.png")
    }
    static func houseURL(_ id: String) -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Store.groupID)?
            .appendingPathComponent("house_\(id).png")
    }
    static let homesKey = "townHomes"
    static let checkInsKey = "townCheckIns"
}
