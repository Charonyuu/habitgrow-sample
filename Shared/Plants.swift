import SwiftUI

/// Free: the sprout. Pro: every other plant and all five crops.
enum PlantType: String, CaseIterable, Identifiable {
    case grass, succulent, sakura, bamboo
    case carrot, cabbage, tomato, wheat, strawberry

    var id: String { rawValue }
    var isFree: Bool { self == .grass }
    var isCrop: Bool { Self.crops.contains(self) }

    static let plants: [PlantType] = [.grass, .succulent, .sakura, .bamboo]
    static let crops: [PlantType] = [.carrot, .cabbage, .tomato, .wheat, .strawberry]

    var title: String {
        switch self {
        case .grass: return tr("小草", "Sprout")
        case .succulent: return tr("多肉", "Succulent")
        case .sakura: return tr("櫻花", "Sakura")
        case .bamboo: return tr("竹子", "Bamboo")
        case .carrot: return tr("紅蘿蔔", "Carrot")
        case .cabbage: return tr("高麗菜", "Cabbage")
        case .tomato: return tr("番茄", "Tomato")
        case .wheat: return tr("小麥", "Wheat")
        case .strawberry: return tr("草莓", "Strawberry")
        }
    }

    private var assetName: String { rawValue.capitalized }

    /// Flat plants have 5 stages (0...4), crops have 4 (seed, sprout, growing, ready).
    func stage(for rate: Double) -> Int {
        if isCrop {
            if rate >= 1 { return 3 }
            if rate >= 0.4 { return 2 }
            return rate > 0 ? 1 : 0
        }
        switch rate {
        case ..<0.01: return 0
        case ..<0.25: return 1
        case ..<0.5: return 2
        case ..<0.75: return 3
        default: return 4
        }
    }

    func imageName(stage: Int) -> String {
        if isCrop {
            let names = ["Seed", "Sprout", "Growing", "Ready"]
            return "Crop\(assetName)\(names[min(max(stage, 0), 3)])"
        }
        return "Plant\(assetName)\(stage)"
    }

    /// Art without a soil mound, for standing on a field plot.
    func spriteName(stage: Int) -> String {
        isCrop ? imageName(stage: stage) : "Sprite\(assetName)\(stage)"
    }

    /// Where the plant's base sits inside its image, as a fraction of the height.
    var baseline: CGFloat { isCrop ? 0.927 : 0.73 }

    var previewName: String { imageName(stage: isCrop ? 3 : 4) }
}

extension Habit {
    var plant: PlantType { PlantType(rawValue: plantType) ?? .grass }
}

/// Plant illustration that grows with completion rate.
struct PlantView: View {
    var rate: Double
    var type: PlantType = .grass
    var size: CGFloat = 84

    var body: some View {
        Image(type.imageName(stage: type.stage(for: rate)))
            .resizable().scaledToFit()
            .frame(width: size, height: size)
    }
}
