import Foundation

enum AppLanguage: String, CaseIterable {
    case system, zh, en, ko, ja
}

/// In-app language switch. Stored in the App Group so widgets follow it too.
enum L10n {
    static let key = "appLanguage"

    static var defaults: UserDefaults { UserDefaults(suiteName: Store.groupID) ?? .standard }

    static var current: AppLanguage {
        AppLanguage(rawValue: defaults.string(forKey: key) ?? "") ?? .system
    }

    /// "zh", "en", "ko" or "ja".
    static var code: String {
        switch current {
        case .zh, .en, .ko, .ja: return current.rawValue
        case .system:
            let first = Locale.preferredLanguages.first ?? "en"
            for c in ["zh", "ko", "ja"] where first.hasPrefix(c) { return c }
            return "en"
        }
    }

    static var isChinese: Bool { code == "zh" }

    static var locale: Locale {
        Locale(identifier: ["zh": "zh_TW", "ko": "ko_KR", "ja": "ja_JP"][code] ?? "en_US")
    }
}

/// zh/en are written inline; ko/ja come from `Loc` (keyed by the English text) or the explicit arguments.
func tr(_ zh: String, _ en: String, ko: String? = nil, ja: String? = nil) -> String {
    switch L10n.code {
    case "zh": return zh
    case "ko": return ko ?? Loc.ko[en] ?? en
    case "ja": return ja ?? Loc.ja[en] ?? en
    default: return en
    }
}
