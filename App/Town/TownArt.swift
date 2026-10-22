import SwiftUI

enum TownTheme: String, CaseIterable, Identifiable {
    case cottage, japanese, forest, snow, island, night

    var id: String { rawValue }
    var isFree: Bool { self == .cottage }

    var title: String {
        switch self {
        case .cottage: return tr("小屋小島", "Cottage Island")
        case .japanese: return tr("日式小島", "Japanese Island")
        case .forest: return tr("森林小島", "Forest Island")
        case .snow: return tr("雪國小島", "Snow Island")
        case .island: return tr("熱帶小島", "Tropical Island")
        case .night: return tr("夜晚小島", "Night Island")
        }
    }

    var subtitle: String {
        switch self {
        case .cottage: return tr("簡單生活，溫暖日常", "Simple life, warm days")
        case .japanese: return tr("櫻花與寧靜，慢慢綻放", "Sakura and calm")
        case .forest: return tr("與大自然一起深呼吸", "Breathe with the forest")
        case .snow: return tr("在安靜中累積力量", "Quiet strength")
        case .island: return tr("陽光、海風，還有更好的自己", "Sun, sea breeze, a better you")
        case .night: return tr("即使在夜晚，也持續前進", "Keep going, even at night")
        }
    }

    /// Soft backdrop behind the floating island.
    var backdrop: (top: Color, bottom: Color) {
        switch self {
        case .cottage: return (Color.dynamic(light: 0xEAF4DD, dark: 0x1B2A1F), Color.dynamic(light: 0xDDEFC9, dark: 0x152019))
        case .japanese: return (Color.dynamic(light: 0xFBEFF0, dark: 0x2A2024), Color.dynamic(light: 0xF6E2E6, dark: 0x1F171A))
        case .forest: return (Color.dynamic(light: 0xDCEBD3, dark: 0x16241A), Color.dynamic(light: 0xCBE1C0, dark: 0x101A13))
        case .snow: return (Color.dynamic(light: 0xE8F1FA, dark: 0x1A2430), Color.dynamic(light: 0xD8E7F4, dark: 0x131B25))
        case .island: return (Color.dynamic(light: 0xD7F0F5, dark: 0x12303A), Color.dynamic(light: 0xBFE6EE, dark: 0x0E252D))
        case .night: return (Color(hex: 0x1D2140), Color(hex: 0x141730))
        }
    }

    /// Falls back to the free theme when the stored one is locked.
    static func effective(_ raw: String, isPro: Bool) -> TownTheme {
        let t = TownTheme(rawValue: raw) ?? .cottage
        return (t.isFree || isPro) ? t : .cottage
    }
}
