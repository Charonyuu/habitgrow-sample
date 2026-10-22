import Foundation

struct TownCell: Hashable {
    var x: Int
    var y: Int
}

/// A fixed, fully built world: a ring of woods around a street grid with house lots between the streets.
/// Habits take lots starting from the middle, so the town grows outward and nothing ever moves.
struct TownBoard {
    static let lotCols = 4
    static let baseRows = 5
    let lotRows: Int

    /// `lotCount` = number of lots the town must have room for.
    init(lotCount: Int) {
        let base = Self.lotCols * Self.baseRows
        let extra = max(0, lotCount - base)
        lotRows = Self.baseRows + (extra + Self.lotCols - 1) / Self.lotCols
    }

    var width: Int { 2 * Self.lotCols + 3 }
    var depth: Int { 2 * lotRows + 3 }

    func isRing(_ c: TownCell) -> Bool { c.x == 0 || c.y == 0 || c.x == width - 1 || c.y == depth - 1 }

    func isRoad(_ c: TownCell) -> Bool {
        guard c.x >= 1, c.x <= width - 2, c.y >= 1, c.y <= depth - 2 else { return false }
        return c.x % 2 == 1 || c.y % 2 == 1
    }

    func isLot(_ c: TownCell) -> Bool {
        c.x % 2 == 0 && c.y % 2 == 0 && c.x >= 2 && c.x <= width - 3 && c.y >= 2 && c.y <= depth - 3
    }

    var cells: [TownCell] {
        (0..<depth).flatMap { y in (0..<width).map { x in TownCell(x: x, y: y) } }
    }

    var allLots: [TownCell] { cells.filter(isLot) }

    /// The first twenty lots, ordered from the centre outwards.
    private static let baseOrder: [TownCell] = {
        let b = TownBoard(lotCount: 0)
        let cx = CGFloat(b.width - 1) / 2, cy = CGFloat(b.depth - 1) / 2
        return b.allLots.sorted { a, c in
            func key(_ p: TownCell) -> (CGFloat, CGFloat) {
                let dx = CGFloat(p.x) - cx, dy = CGFloat(p.y) - cy
                return (dx * dx + dy * dy, atan2(dy, dx))
            }
            return key(a) < key(c)
        }
    }()

    func lotCell(_ i: Int) -> TownCell {
        if i < Self.baseOrder.count { return Self.baseOrder[i] }
        let extra = i - Self.baseOrder.count
        return TownCell(x: 2 + 2 * (extra % Self.lotCols), y: 2 + 2 * (Self.baseRows + extra / Self.lotCols))
    }
}

/// Deterministic pseudo-random values so scenery never jumps around.
func townHash(_ a: Int, _ b: Int, _ seed: Int = 0) -> UInt64 {
    var z = UInt64(bitPattern: Int64(a &* 73856093 ^ b &* 19349663 ^ seed &* 83492791)) &+ 0x9E3779B97F4A7C15
    z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
    z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
    return z ^ (z >> 31)
}

func townUnit(_ a: Int, _ b: Int, _ seed: Int = 0) -> CGFloat {
    CGFloat(townHash(a, b, seed) % 10_000) / 10_000
}
