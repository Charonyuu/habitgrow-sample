import SwiftUI
import SwiftData

@main
struct HabitGrowApp: App {
    @State private var pro = ProStore()

    init() {
        #if DEBUG
        let args = CommandLine.arguments
        if args.contains("-renderIcon") {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1))
                let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                for (name, theme) in [("icon-island", TownTheme.island), ("icon-japanese", TownTheme.japanese), ("icon-cottage", TownTheme.cottage), ("icon-forest", TownTheme.forest), ("icon-snow", TownTheme.snow), ("icon-night", TownTheme.night)] {
                    if let img = TownSnapshotter.icon(theme: theme), let data = img.pngData() { try? data.write(to: docs.appendingPathComponent(name + ".png")) }
                }
            }
        }
        if args.contains("-renderHouseIcons") {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1))
                let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                for theme in TownTheme.allCases {
                    if let img = TownSnapshotter.houseIcon(theme: theme), let data = img.pngData() { try? data.write(to: docs.appendingPathComponent("house-\(theme.rawValue).png")) }
                }
            }
        }
        if let i = args.firstIndex(of: "-appLang"), i + 1 < args.count { L10n.defaults.set(args[i + 1], forKey: L10n.key) }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(Theme.accent)
                .environment(pro)
        }
        .modelContainer(Store.container)
    }
}
