import SwiftUI
import SceneKit
import WidgetKit

/// Renders the middle of the town into the shared container for the widget.
@MainActor
enum TownSnapshot {
    static func render(habits: [Habit], theme: TownTheme) {
        guard let url = TownSnapshotStore.url else { return }
        let world = TownWorld(habits: habits, theme: theme, interactive: false, showLabels: false)
        let stage = TownStage(dusk: theme.toy.dusk)
        stage.setWorld(world.root)
        stage.orthoScale = 2.3
        stage.yaw.position = SCNVector3(0, 0, 0.1)
        let size = CGSize(width: 720, height: 420)
        guard let scene = TownSnapshotter.render(stage: stage, size: size, scale: 2) else { return }

        let top = UIColor(theme.backdrop.top), bottom = UIColor(theme.backdrop.bottom)
        let fmt = UIGraphicsImageRendererFormat(); fmt.scale = 1; fmt.opaque = true
        let composed = UIGraphicsImageRenderer(size: scene.size, format: fmt).image { ctx in
            let colors = [top.cgColor, bottom.cgColor] as CFArray
            if let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
                ctx.cgContext.drawLinearGradient(g, start: .zero, end: CGPoint(x: 0, y: scene.size.height), options: [])
            }
            scene.draw(in: CGRect(origin: .zero, size: scene.size))
        }
        guard let data = composed.pngData() else { return }
        try? data.write(to: url, options: .atomic)
        let defaults = L10n.defaults
        defaults.set(world.homes, forKey: TownSnapshotStore.homesKey)
        defaults.set(world.checkIns, forKey: TownSnapshotStore.checkInsKey)
        for h in habits {
            if let img = TownSnapshotter.house(theme: theme, level: h.townLevel), let data = img.pngData(), let u = TownSnapshotStore.houseURL(h.id.uuidString) {
                try? data.write(to: u, options: .atomic)
            }
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
