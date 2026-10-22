import Foundation

extension Habit {
    /// 0 = empty lot, 1...4 = house levels (lifetime check-ins, never goes down).
    var townLevel: Int {
        switch totalCount {
        case 0: return 0
        case 1..<8: return 1
        case 8..<30: return 2
        case 30..<100: return 3
        default: return 4
        }
    }

    /// Check-ins needed for the next level, nil at the top.
    var nextLevelAt: Int? {
        switch townLevel {
        case 0: return 1
        case 1: return 8
        case 2: return 30
        case 3: return 100
        default: return nil
        }
    }
}
