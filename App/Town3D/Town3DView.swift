import SwiftUI
import SceneKit
import SwiftData
import UIKit

/// Lights, camera rig and background shared by the live view and the snapshots.
@MainActor
final class TownStage {
    let scene = SCNScene()
    let yaw = SCNNode()
    let pitch = SCNNode()
    let cameraNode = SCNNode()
    let sun = SCNNode()
    let ambient = SCNNode()
    private(set) var worldRoot: SCNNode?

    init(dusk: Bool = false) {
        scene.background.contents = UIColor.clear
        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 5.6
        camera.zNear = 0.1
        camera.zFar = 200
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, 40)
        pitch.addChildNode(cameraNode)
        pitch.eulerAngles.x = -0.62
        yaw.addChildNode(pitch)
        yaw.eulerAngles.y = .pi / 4
        scene.rootNode.addChildNode(yaw)

        let amb = SCNLight(); amb.type = .ambient
        ambient.light = amb
        scene.rootNode.addChildNode(ambient)

        let l = SCNLight(); l.type = .directional
        l.castsShadow = true
        l.shadowMode = .deferred
        l.shadowSampleCount = 8
        l.shadowRadius = 4
        l.shadowMapSize = CGSize(width: 2048, height: 2048)
        l.automaticallyAdjustsShadowProjection = false
        l.orthographicScale = 16
        l.zNear = 1
        l.zFar = 60
        l.shadowBias = 0.02
        sun.light = l
        sun.position = SCNVector3(-9, 16, 7)
        sun.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(sun)
        applyLight(dusk: dusk)
    }

    func applyLight(dusk: Bool) {
        ambient.light?.color = dusk ? UIColor(hex: 0x8F93D6) : UIColor(hex: 0xFFFFFF)
        ambient.light?.intensity = dusk ? 520 : 560
        sun.light?.color = dusk ? UIColor(hex: 0xB9BCFF) : UIColor(hex: 0xFFF4E0)
        sun.light?.intensity = dusk ? 520 : 640
        sun.light?.shadowColor = UIColor.black.withAlphaComponent(dusk ? 0.45 : 0.3)
    }

    func setWorld(_ root: SCNNode) {
        worldRoot?.removeFromParentNode()
        scene.rootNode.addChildNode(root)
        worldRoot = root
    }

    var orthoScale: CGFloat {
        get { cameraNode.camera?.orthographicScale ?? 5.6 }
        set { cameraNode.camera?.orthographicScale = newValue }
    }
}

struct Town3DView: UIViewRepresentable {
    let habits: [Habit]
    let theme: TownTheme
    var pops: Set<String>
    var onOpen: (PersistentIdentifier) -> Void
    var onAdd: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = .clear
        view.isOpaque = false
        view.antialiasingMode = .multisampling4X
        view.preferredFramesPerSecond = 30
        view.rendersContinuously = true
        view.autoenablesDefaultLighting = false
        let c = context.coordinator
        c.view = view
        view.scene = c.stage.scene
        view.pointOfView = c.stage.cameraNode

        let pan = UIPanGestureRecognizer(target: c, action: #selector(Coordinator.pan(_:)))
        pan.maximumNumberOfTouches = 1
        let pinch = UIPinchGestureRecognizer(target: c, action: #selector(Coordinator.pinch(_:)))
        let rotate = UIRotationGestureRecognizer(target: c, action: #selector(Coordinator.rotate(_:)))
        let tap = UITapGestureRecognizer(target: c, action: #selector(Coordinator.tap(_:)))
        [pinch, rotate].forEach { $0.delegate = c }
        [pan, pinch, rotate, tap].forEach { view.addGestureRecognizer($0) }
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        let c = context.coordinator
        c.onOpen = onOpen
        c.onAdd = onAdd
        let signature = theme.rawValue + habits.map { "\($0.id)\($0.plotIndex)\($0.townLevel)\($0.name)" }.joined()
            + "\(habits.reduce(0) { $0 + $1.totalCount } / 8)"
        if signature != c.signature {
            c.signature = signature
            c.stage.applyLight(dusk: theme.toy.dusk)
            let world = TownWorld(habits: habits, theme: theme)
            c.world = world
            c.stage.setWorld(world.root)
            c.updateLabels()
            c.clampTarget()
            view.setNeedsDisplay()
        }
        if !pops.isEmpty, pops != c.lastPops {
            c.lastPops = pops
            c.world?.pop(pops)
        } else if pops.isEmpty {
            c.lastPops = []
        }
    }

    @MainActor
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let stage = TownStage()
        weak var view: SCNView?
        var world: TownWorld?
        var signature = ""
        var lastPops: Set<String> = []
        var onOpen: (PersistentIdentifier) -> Void = { _ in }
        var onAdd: () -> Void = {}
        private var startScale: CGFloat = 5.6
        private var startYaw: Float = 0

        func gestureRecognizer(_ g: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith o: UIGestureRecognizer) -> Bool { true }

        func updateLabels() {
            let s = Float(stage.orthoScale / 4.2)
            world?.labels.forEach { $0.scale = SCNVector3(s, s, s) }
        }

        func clampTarget() {
            guard let world else { return }
            let e = world.halfExtent
            var pos = stage.yaw.position
            pos.x = max(-(e.x - 1), min(e.x - 1, pos.x))
            pos.z = max(-(e.z - 1), min(e.z - 1, pos.z))
            stage.yaw.position = pos
        }

        @objc func pan(_ g: UIPanGestureRecognizer) {
            guard let view else { return }
            let t = g.translation(in: view)
            g.setTranslation(.zero, in: view)
            let unitsPerPoint = Float(stage.orthoScale * 2 / view.bounds.height)
            let a = stage.yaw.eulerAngles.y
            let right = SCNVector3(cos(a), 0, -sin(a))
            let forward = SCNVector3(-sin(a), 0, -cos(a))
            let k = unitsPerPoint
            let dx = -Float(t.x) * k, dz = -Float(t.y) * k / sin(0.62)
            var pos = stage.yaw.position
            pos.x += right.x * dx - forward.x * dz
            pos.z += right.z * dx - forward.z * dz
            stage.yaw.position = pos
            clampTarget()
        }

        @objc func pinch(_ g: UIPinchGestureRecognizer) {
            if g.state == .began { startScale = stage.orthoScale }
            stage.orthoScale = min(12, max(2.2, startScale / g.scale))
            updateLabels()
        }

        @objc func rotate(_ g: UIRotationGestureRecognizer) {
            if g.state == .began { startYaw = stage.yaw.eulerAngles.y }
            stage.yaw.eulerAngles.y = startYaw - Float(g.rotation)
        }

        @objc func tap(_ g: UITapGestureRecognizer) {
            guard let view, let world else { return }
            let hits = view.hitTest(g.location(in: view), options: [.searchMode: SCNHitTestSearchMode.all.rawValue])
            for hit in hits {
                var node: SCNNode? = hit.node
                while let n = node {
                    if let name = n.name {
                        if name == "add" { onAdd(); return }
                        if let id = world.ids[name] { onOpen(id); return }
                    }
                    node = n.parent
                }
            }
        }
    }
}

// MARK: - Snapshots (widget, thumbnails)

@MainActor
enum TownSnapshotter {
    private static var cache: [String: UIImage] = [:]

    static func render(stage: TownStage, size: CGSize, scale: CGFloat) -> UIImage? {
        guard let device = MTLCreateSystemDefaultDevice() else { return nil }
        let renderer = SCNRenderer(device: device, options: nil)
        renderer.scene = stage.scene
        renderer.pointOfView = stage.cameraNode
        let px = CGSize(width: size.width * scale, height: size.height * scale)
        return renderer.snapshot(atTime: 0, with: px, antialiasingMode: .multisampling4X)
    }

    /// One house on a small plot of ground.
    static func house(theme: TownTheme, level: Int) -> UIImage? {
        let key = "h-\(theme.rawValue)-\(level)"
        if let img = cache[key] { return img }
        let p = theme.toy
        let stage = TownStage(dusk: p.dusk)
        let root = SCNNode()
        root.addChildNode(TownWorld.islandSlab(IslandShape(rx: 0.95, rz: 0.95, seed: 3), p))
        let house = Toy.house(level: level, p: p)
        house.position = SCNVector3(0, TownWorld.groundY, 0)
        root.addChildNode(house)
        if level >= 1 {
            let t = Toy.tree(p, scale: 0.7); t.position = SCNVector3(-0.5, TownWorld.groundY, -0.45); root.addChildNode(t)
        }
        stage.setWorld(root)
        stage.orthoScale = level == 4 ? 1.35 : 1.15
        stage.yaw.position = SCNVector3(0, 0.25, 0)
        let img = render(stage: stage, size: CGSize(width: 220, height: 220), scale: 2)
        if let img { cache[key] = img }
        return img
    }

    /// 1024x1024 app icon: a little house island on the sea.
    static func icon(theme: TownTheme) -> UIImage? {
        let p = theme.toy
        let stage = TownStage(dusk: p.dusk)
        let root = SCNNode()
        let shape = IslandShape(rx: 1.45, rz: 1.35, seed: 3)
        root.addChildNode(TownWorld.seaNode(shape, p))
        root.addChildNode(TownWorld.islandSlab(shape, p))
        let h = Toy.house(level: 4, p: p); h.position = SCNVector3(0.05, TownWorld.groundY, -0.05); root.addChildNode(h)
        let t1 = Toy.tree(p, scale: 1.0); t1.position = SCNVector3(-0.95, TownWorld.groundY, 0.45); root.addChildNode(t1)
        let t2 = Toy.tree(p, style: p.tree == .pine ? .round : .pine, scale: 0.8); t2.position = SCNVector3(0.9, TownWorld.groundY, 0.6); root.addChildNode(t2)
        let b = Toy.bush(p, 0.13); b.position = SCNVector3(-0.5, TownWorld.groundY, 0.85); root.addChildNode(b)
        stage.setWorld(root)
        stage.orthoScale = 2.05
        stage.yaw.position = SCNVector3(0, 0.3, 0)
        return render(stage: stage, size: CGSize(width: 1024, height: 1024), scale: 1)
    }

    /// 1024x1024 icon: one level-4 house on its slab over a soft pastel backdrop.
    static func houseIcon(theme: TownTheme) -> UIImage? {
        let p = theme.toy
        let stage = TownStage(dusk: p.dusk)
        let root = SCNNode()
        root.addChildNode(TownWorld.islandSlab(IslandShape(rx: 0.95, rz: 0.95, seed: 3), p))
        let house = Toy.house(level: 4, p: p)
        house.position = SCNVector3(0, TownWorld.groundY, 0)
        root.addChildNode(house)
        let t = Toy.tree(p, scale: 0.7); t.position = SCNVector3(-0.5, TownWorld.groundY, -0.45); root.addChildNode(t)
        stage.setWorld(root)
        stage.orthoScale = 1.4
        stage.yaw.position = SCNVector3(0, 0.3, 0)
        guard let scene = render(stage: stage, size: CGSize(width: 1024, height: 1024), scale: 1) else { return nil }
        let top = UIColor(theme.backdrop.top), bottom = UIColor(theme.backdrop.bottom)
        let fmt = UIGraphicsImageRendererFormat(); fmt.scale = 1; fmt.opaque = true
        return UIGraphicsImageRenderer(size: CGSize(width: 1024, height: 1024), format: fmt).image { ctx in
            let colors = [top.cgColor, bottom.cgColor] as CFArray
            if let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
                ctx.cgContext.drawLinearGradient(g, start: .zero, end: CGPoint(x: 0, y: 1024), options: [])
            }
            scene.draw(in: CGRect(x: 0, y: 0, width: 1024, height: 1024))
        }
    }

    /// A small crossroads for the paywall.
    static func mini(theme: TownTheme) -> UIImage? {
        let key = "m-\(theme.rawValue)"
        if let img = cache[key] { return img }
        let p = theme.toy
        let stage = TownStage(dusk: p.dusk)
        let root = SCNNode()
        let shape = IslandShape(rx: 1.9, rz: 1.6, seed: 3)
        root.addChildNode(TownWorld.seaNode(shape, p))
        root.addChildNode(TownWorld.islandSlab(shape, p))
        for k in 0...16 {
            let t = Float(k) / 16 * 3.0 - 1.5
            for (x, z) in [(t, 0.18 * sin(t * 1.6)), (0.15 * sin(t * 2), t * 0.9)] {
                root.addChildNode(Toy.cyl(0.27, 0.016, p.roadEdge).at(x, 0.048, z))
                root.addChildNode(Toy.cyl(0.22, 0.016, p.road).at(x, 0.057, z))
            }
        }
        let spots: [(Int, Float, Float)] = [(3, -0.85, -0.85), (4, 0.85, -0.85), (2, -0.85, 0.85), (3, 0.85, 0.85)]
        for (lvl, x, z) in spots {
            let h = Toy.house(level: lvl, p: p); h.position = SCNVector3(x, TownWorld.groundY, z); root.addChildNode(h)
        }
        let t = Toy.tree(p, scale: 0.9); t.position = SCNVector3(-1.35, TownWorld.groundY, 0.15); root.addChildNode(t)
        let t2 = Toy.tree(p, style: p.tree == .pine ? .round : .pine, scale: 0.8); t2.position = SCNVector3(1.35, TownWorld.groundY, -0.1); root.addChildNode(t2)
        stage.setWorld(root)
        stage.orthoScale = 2.7
        stage.yaw.position = SCNVector3(0, 0.1, 0)
        let img = render(stage: stage, size: CGSize(width: 480, height: 270), scale: 2)
        if let img { cache[key] = img }
        return img
    }
}

/// A rendered picture of a house on its plot.
struct HouseThumb: View {
    let theme: TownTheme
    let level: Int
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image).resizable().scaledToFit()
            } else {
                Color.clear
            }
        }
        .task(id: "\(theme.rawValue)\(level)") {
            image = TownSnapshotter.house(theme: theme, level: level)
        }
    }
}

struct MiniTownImage: View {
    let theme: TownTheme
    var fill = false
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                if fill { Image(uiImage: image).resizable().scaledToFill() } else { Image(uiImage: image).resizable().scaledToFit() }
            } else { Color.clear }
        }
        .task(id: theme.rawValue) { image = TownSnapshotter.mini(theme: theme) }
    }
}
