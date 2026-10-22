import SwiftUI
import UIKit

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { trait in
            let hex = trait.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        })
    }
}

extension Font {
    static func r(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

enum Theme {
    static let accent = Color(hex: 0x3E9B5A)
    static let background = Color.dynamic(light: 0xF3F6EE, dark: 0x0F1411)
    static let card = Color.dynamic(light: 0xFBFCF8, dark: 0x1A211C)
    static let track = Color.dynamic(light: 0xE4EADD, dark: 0x2D372F)
    static let grassA = Color.dynamic(light: 0xD3EAB8, dark: 0x233829)
    static let grassB = Color.dynamic(light: 0xC8E3AA, dark: 0x1E3023)
    static let primaryFill = Color.dynamic(light: 0x3A3A3C, dark: 0xE4E4E6)
    static let onColor = Color(hex: 0x2E4A35)

    static let warn = Color.dynamic(light: 0xD9822B, dark: 0xF0A35A)

    // First five keep their original order so saved habits keep their color.
    static let palette: [Color] = [
        Color(hex: 0x8CCB7E), // grass
        Color(hex: 0xD3E57F), // lime
        Color(hex: 0x7ACDB4), // mint
        Color(hex: 0xF7B9C6), // blossom
        Color(hex: 0xE3CFA9), // sand
        Color(hex: 0x8FC8E8), // sky
        Color(hex: 0xBBA8E8), // lavender
        Color(hex: 0xF59A8A), // coral
        Color(hex: 0xFFB07C), // peach
        Color(hex: 0xFFD86B), // sunflower
        Color(hex: 0x5FA877), // fern
        Color(hex: 0xC9CCCB), // stone
        Color(hex: 0xA9D6F5), // baby blue
        Color(hex: 0xD6A8E8), // orchid
        Color(hex: 0xF9A8C8), // rose
        Color(hex: 0xFFC98A), // apricot
        Color(hex: 0xB5E48C), // pistachio
        Color(hex: 0x9FB3C8), // slate blue
    ]

    static func color(_ index: Int) -> Color {
        palette[max(0, min(index, palette.count - 1))]
    }
}
