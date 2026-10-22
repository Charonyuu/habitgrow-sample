import SceneKit
import SwiftData
import UIKit

/// An organic island outline: a rounded blob with a little wobble.
struct IslandShape {
    let rx: Float, rz: Float
    let exponent: Float = 2.7
    let seed: Int

    private func wobble(_ t: Float) -> Float {
        let a = Float(seed % 7), b = Float(seed % 5)
        return 1 + 0.07 * sin(3 * t + a) + 0.045 * sin(5 * t + b * 1.3) + 0.025 * sin(8 * t + a * 0.7)
    }

    /// 1.0 on the shore, < 1 inside.
    func level(_ x: Float, _ z: Float) -> Float {
        let nx = abs(x) / rx, nz = abs(z) / rz
        let r = pow(pow(nx, exponent) + pow(nz, exponent), 1 / exponent)
        return r / wobble(atan2(z / rz, x / rx))
    }

    func contains(_ x: Float, _ z: Float, margin: Float = 1) -> Bool { level(x, z) <= margin }

    func outline(_ count: Int = 96) -> [CGPoint] {
        (0..<count).map { k in
            let t = Float(k) / Float(count) * 2 * .pi
            let c = cos(t), s = sin(t)
            let base = pow(pow(abs(c), exponent) + pow(abs(s), exponent), 1 / exponent)
            let r = wobble(t) / base
            return CGPoint(x: CGFloat(rx * r * c), y: CGFloat(rz * r * s))
        }
    }
}

/// Builds the 3D town: island, winding streets, houses, scattered nature.
@MainActor
final class TownWorld {
    let root = SCNNode()
    let board: TownBoard
    let theme: TownTheme
    let p: ToyPalette
    private(set) var houses: [String: SCNNode] = [:]
    private(set) var ids: [String: PersistentIdentifier] = [:]
    private(set) var labels: [SCNNode] = []
    let homes: Int
    let checkIns: Int
    let island: IslandShape
    private var roadSamples: [SCNVector3] = []
    private var extraSpots: [SCNVector3] = []

    static let groundY: Float = 0.04

    private var offsetX: Float { Float(board.width - 1) / 2 }
    private var offsetZ: Float { Float(board.depth - 1) / 2 }

    /// World position of a board cell, nudged so nothing sits on a perfect grid.
    func position(_ c: TownCell, dx: Float = 0, dz: Float = 0) -> SCNVector3 {
        let jx = Float(townUnit(c.x, c.y, 71) - 0.5) * 0.34
        let jz = Float(townUnit(c.x, c.y, 72) - 0.5) * 0.34
        return SCNVector3(Float(c.x) - offsetX + jx + dx, Self.groundY, Float(c.y) - offsetZ + jz + dz)
    }

    var halfExtent: (x: Float, z: Float) { (island.rx, island.rz) }

    init(habits: [Habit], theme: TownTheme, interactive: Bool = true, showLabels: Bool = true) {
        self.theme = theme
        p = theme.toy
        let placed = habits.filter { $0.plotIndex >= 0 }
        let used = Set(placed.map(\.plotIndex))
        var addIndex = 0
        while used.contains(addIndex) { addIndex += 1 }
        board = TownBoard(lotCount: max((used.max() ?? -1) + 1, addIndex + 1))
        let lotsNeeded = max((used.max() ?? -1) + 1, addIndex + 1)
        let fit: Float = lotsNeeded <= 7 ? 4.1 : (lotsNeeded <= 12 ? 4.8 : 99)
        island = IslandShape(rx: min(Float(board.width) / 2 - 0.2, fit), rz: min(Float(board.depth) / 2 - 0.2, fit * 0.92), seed: 3)
        homes = placed.count
        checkIns = habits.reduce(0) { $0 + $1.totalCount }

        buildSea()
        root.addChildNode(Self.islandSlab(island, p))
        var roadStops: [SCNVector3] = placed.map { position(board.lotCell($0.plotIndex)) }
        roadStops.append(position(board.lotCell(addIndex)))
        buildRoads(stops: roadStops)

        var taken = Set<TownCell>()
        var takenSpots: [SCNVector3] = []
        for h in placed {
            let cell = board.lotCell(h.plotIndex)
            taken.insert(cell)
            let level = h.townLevel
            let node = Toy.house(level: level, p: p)
            node.position = position(cell)
            node.eulerAngles.y = Float(townUnit(cell.x, cell.y, 73) - 0.5) * 0.5
            takenSpots.append(node.position)
            let key = "h:\(h.id.uuidString)"
            node.name = key
            node.addChildNode(hitBox())
            root.addChildNode(node)
            houses[key] = node
            ids[key] = h.persistentModelID
            if showLabels {
                addLabel(at: node.position, text: h.name, sub: level == 0 ? tr("空地", "Lot") : "Lv.\(level)", name: key)
            }
        }

        let addCell = board.lotCell(addIndex)
        taken.insert(addCell)
        if interactive {
            let node = Toy.lot(p)
            node.position = position(addCell)
            node.name = "add"
            node.addChildNode(hitBox())
            root.addChildNode(node)
            takenSpots.append(node.position)
            if showLabels { addLabel(at: node.position, text: "+", sub: tr("新增習慣", "Add habit"), name: "add") }
        }

        scatterNature(avoiding: takenSpots)
        buildExtras(taken: taken)
    }

    // MARK: Island

    /// A tapering floating island: grass, earth and stone layers following the outline.
    static func islandSlab(_ shape: IslandShape, _ p: ToyPalette) -> SCNNode {
        let n = SCNNode()
        let pts = shape.outline()
        func layer(scale: CGFloat, depth: CGFloat, centerY: Float, color: UIColor, chamfer: CGFloat) {
            let path = UIBezierPath()
            for (i, q) in pts.enumerated() {
                let pt = CGPoint(x: q.x * scale, y: -q.y * scale)
                i == 0 ? path.move(to: pt) : path.addLine(to: pt)
            }
            path.close()
            let g = SCNShape(path: path, extrusionDepth: depth)
            g.chamferRadius = chamfer
            g.chamferMode = .both
            g.firstMaterial = Toy.mat(color)
            let node = SCNNode(geometry: g)
            let bb = node.boundingBox
            node.pivot = SCNMatrix4MakeTranslation(0, 0, (bb.min.z + bb.max.z) / 2)
            node.eulerAngles.x = -.pi / 2
            node.position = SCNVector3(0, centerY, 0)
            n.addChildNode(node)
        }
        layer(scale: 1.05, depth: 0.1, centerY: -0.1, color: p.sand, chamfer: 0.04)
        layer(scale: 1.0, depth: 0.16, centerY: -0.04, color: p.grass, chamfer: 0.06)
        layer(scale: 0.965, depth: 0.34, centerY: -0.24, color: p.earth, chamfer: 0.05)
        layer(scale: 0.9, depth: 0.28, centerY: -0.52, color: p.stone, chamfer: 0.06)
        layer(scale: 0.74, depth: 0.22, centerY: -0.74, color: p.stone.withAlphaComponent(1), chamfer: 0.06)
        return n
    }

    // MARK: Sea

    /// Open water around the island with slow ripples and a foam line at the shore.
    static func seaNode(_ island: IslandShape, _ p: ToyPalette) -> SCNNode {
        let root = SCNNode()
        let seaY: Float = -0.3
        let g = SCNPlane(width: 64, height: 64)
        g.widthSegmentCount = 150
        g.heightSegmentCount = 150
        let m = Toy.mat(p.water)
        m.shaderModifiers = [
            .geometry: """
            #pragma body
            float t = scn_frame.time;
            float x = _geometry.position.x, y = _geometry.position.y;
            _geometry.position.z += sin(x * 1.5 + t * 1.5) * 0.04 + sin(y * 1.2 - t * 1.2) * 0.035 + sin((x + y) * 0.7 + t * 0.8) * 0.03;
            """,
            .surface: """
            #pragma body
            float t = scn_frame.time;
            float2 q = _surface.diffuseTexcoord * 64.0;
            float w1 = sin(q.x * 0.55 + t * 0.55) * sin(q.y * 0.5 - t * 0.45);
            float w2 = sin((q.x + q.y) * 0.32 + t * 0.4) * sin((q.x - q.y) * 0.4 - t * 0.35);
            float shade = 0.5 + 0.5 * (w1 * 0.6 + w2 * 0.4);
            float crest = smoothstep(0.82, 1.0, shade) * 0.5;
            _surface.diffuse.rgb = _surface.diffuse.rgb * (0.9 + 0.14 * shade) + float3(1.0) * crest * 0.18;
            """
        ]
        g.firstMaterial = m
        let plane = SCNNode(geometry: g)
        plane.eulerAngles.x = -.pi / 2
        plane.position = SCNVector3(0, seaY, 0)
        root.addChildNode(plane)

        let pts = island.outline()
        func ring(inner: CGFloat, outer: CGFloat, color: UIColor, alpha: CGFloat) -> SCNNode {
            let path = UIBezierPath()
            for (i, q) in pts.enumerated() {
                let pt = CGPoint(x: q.x * outer, y: -q.y * outer)
                i == 0 ? path.move(to: pt) : path.addLine(to: pt)
            }
            path.close()
            for (i, q) in pts.enumerated() {
                let pt = CGPoint(x: q.x * inner, y: -q.y * inner)
                i == 0 ? path.move(to: pt) : path.addLine(to: pt)
            }
            path.close()
            path.usesEvenOddFillRule = true
            let g = SCNShape(path: path, extrusionDepth: 0.004)
            let m = Toy.mat(color)
            m.transparency = alpha
            m.writesToDepthBuffer = false
            g.firstMaterial = m
            let n = SCNNode(geometry: g)
            n.eulerAngles.x = -.pi / 2
            n.position = SCNVector3(0, seaY + 0.014, 0)
            n.renderingOrder = -1
            return n
        }
        // shallow water around the beach
        root.addChildNode(ring(inner: 1.0, outer: 1.34, color: UIColor.white, alpha: 0.28))
        root.addChildNode(ring(inner: 1.0, outer: 1.2, color: p.water, alpha: 0.4))
        // foam hugging the shore
        root.addChildNode(ring(inner: 0.96, outer: 1.07, color: p.foam, alpha: 0.85))
        root.addChildNode(ring(inner: 1.1, outer: 1.14, color: p.foam, alpha: 0.5))
        // ripples drifting outwards
        for k in 0..<3 {
            let r = ring(inner: 1.0, outer: 1.035, color: p.foam, alpha: 0.6)
            r.opacity = 0
            let grow = SCNAction.customAction(duration: 0) { _, _ in }
            let wait = SCNAction.wait(duration: Double(k) * 1.6)
            let expand = SCNAction.group([
                .scale(to: 1.5, duration: 4.8),
                .sequence([.fadeOpacity(to: 0.7, duration: 0.8), .fadeOpacity(to: 0, duration: 4.0)])
            ])
            let reset = SCNAction.run { n in n.scale = SCNVector3(1.12, 1.12, 1.12); n.opacity = 0 }
            r.scale = SCNVector3(1.12, 1.12, 1.12)
            r.runAction(.sequence([wait, .repeatForever(.sequence([reset, expand])), grow]))
            root.addChildNode(r)
        }
        // slow ripples blooming on the open water
        for k in 0..<14 {
            let a = Float(townUnit(k, 1, 111)) * 6.28
            let dist = 1.3 + Float(townUnit(k, 2, 112)) * 0.9
            let x = cos(a) * island.rx * dist, z = sin(a) * island.rz * dist
            let ripple = SCNNode(geometry: SCNTube(innerRadius: 0.12, outerRadius: 0.15, height: 0.004))
            let rm = Toy.mat(p.foam); rm.writesToDepthBuffer = false
            ripple.geometry?.firstMaterial = rm
            ripple.position = SCNVector3(x, seaY + 0.016, z)
            ripple.opacity = 0
            ripple.scale = SCNVector3(0.4, 1, 0.4)
            let cycle = 3.4 + Double(k % 4) * 0.5
            let bloom = SCNAction.group([.scale(to: 2.4, duration: cycle),
                                         .sequence([.fadeOpacity(to: 0.55, duration: cycle * 0.25), .fadeOpacity(to: 0, duration: cycle * 0.75)])])
            let reset = SCNAction.run { n in n.scale = SCNVector3(0.4, 1, 0.4); n.opacity = 0 }
            ripple.runAction(.sequence([.wait(duration: Double(k) * 0.7), .repeatForever(.sequence([reset, bloom]))]))
            root.addChildNode(ripple)
        }
        // a little sailboat drifting by
        let boat = SCNNode()
        boat.put(Toy.box(0.5, 0.1, 0.2, UIColor(hex: 0xB9763D), r: 0.04).at(0, 0.05, 0),
                 Toy.box(0.34, 0.06, 0.16, UIColor(hex: 0xE8E2D4), r: 0.03).at(0, 0.11, 0),
                 Toy.cyl(0.012, 0.5, UIColor(hex: 0x8A5A33)).at(0, 0.36, 0),
                 Toy.prism(0.3, 0.38, 0.012, UIColor.white).at(0.02, 0.17, 0).rot(0, 0, -0.15),
                 Toy.box(0.1, 0.06, 0.01, UIColor(hex: 0xE5483E), r: 0.002).at(0.06, 0.63, 0))
        // it sails around the island, bobbing and leaving a wake
        let wake = Toy.box(0.7, 0.004, 0.14, p.foam, r: 0.05)
        wake.position = SCNVector3(-0.45, 0.02, 0)
        wake.opacity = 0.45
        boat.addChildNode(wake)
        let lap: Double = 70
        boat.runAction(.repeatForever(.customAction(duration: lap) { node, elapsed in
            let t = Float(elapsed / CGFloat(lap)) * 2 * .pi
            let rx = island.rx * 1.42, rz = island.rz * 1.38
            let x = cos(t) * rx, z = sin(t) * rz
            let dx = -sin(t) * rx, dz = cos(t) * rz
            node.position = SCNVector3(x, seaY + 0.03 + sin(Float(elapsed) * 2.2) * 0.025, z)
            node.eulerAngles = SCNVector3(sin(Float(elapsed) * 1.7) * 0.045, atan2(-dz, dx), sin(Float(elapsed) * 2.0) * 0.05)
        }))
        root.addChildNode(boat)
        return root
    }

    private func buildSea() { root.addChildNode(Self.seaNode(island, p)) }

    // MARK: Streets

    /// Paths only run where somebody lives: a village green in the middle, winding to every house.
    private func buildRoads(stops: [SCNVector3]) {
        let roads = SCNNode()
        let hub = SCNVector3(0.1, 0, -0.1)
        var nodes = [hub] + stops
        // Prim's minimum spanning tree
        var inTree = [0]
        var edges: [(Int, Int)] = []
        while inTree.count < nodes.count {
            var best: (Int, Int, Float)?
            for a in inTree {
                for b in 0..<nodes.count where !inTree.contains(b) {
                    let d = hypot(nodes[a].x - nodes[b].x, nodes[a].z - nodes[b].z)
                    if best == nil || d < best!.2 { best = (a, b, d) }
                }
            }
            guard let e = best else { break }
            edges.append((e.0, e.1)); inTree.append(e.1)
        }
        nodes = nodes.map { SCNVector3($0.x, 0, $0.z) }
        // village green
        for (r, color, y) in [(Float(0.62), p.roadEdge, Float(0.008)), (Float(0.55), p.road, Float(0.017))] {
            let c = Toy.cyl(r, 0.016, color); c.position = SCNVector3(hub.x, Self.groundY + y, hub.z); roads.addChildNode(c)
        }
        for (k, (ai, bi)) in edges.enumerated() {
            let a = nodes[ai], b = nodes[bi]
            let dx = b.x - a.x, dz = b.z - a.z
            let len = max(0.001, sqrt(dx * dx + dz * dz))
            let bend = (Float(townUnit(k, 9, 92)) - 0.5) * min(1.6, len * 0.6)
            let ctrl = SCNVector3((a.x + b.x) / 2 - dz / len * bend, 0, (a.z + b.z) / 2 + dx / len * bend)
            let steps = max(10, Int(len * 9))
            for s in 0...steps {
                let t = Float(s) / Float(steps)
                let u = 1 - t
                let px = u * u * a.x + 2 * u * t * ctrl.x + t * t * b.x
                let pz = u * u * a.z + 2 * u * t * ctrl.z + t * t * b.z
                // fade the path out as it reaches the door so it does not run under the house
                if hypot(px - b.x, pz - b.z) < 0.34 && ai != bi && bi != 0 { continue }
                roadSamples.append(SCNVector3(px, 0, pz))
                let edge = Toy.cyl(0.2, 0.016, p.roadEdge); edge.position = SCNVector3(px, Self.groundY + 0.008, pz)
                let top = Toy.cyl(0.165, 0.016, p.road); top.position = SCNVector3(px, Self.groundY + 0.017, pz)
                roads.addChildNode(edge); roads.addChildNode(top)
            }
        }
        for s in [hub] { roadSamples.append(SCNVector3(s.x, 0, s.z)) }
        for k in 0..<12 { let a = Float(k) / 12 * 6.28; roadSamples.append(SCNVector3(hub.x + cos(a) * 0.5, 0, hub.z + sin(a) * 0.5)) }
        root.addChildNode(roads.flattenedClone())
    }

    private func distanceToRoad(_ x: Float, _ z: Float) -> Float {
        var best: Float = .greatestFiniteMagnitude
        for s in roadSamples {
            let d = (s.x - x) * (s.x - x) + (s.z - z) * (s.z - z)
            if d < best { best = d }
        }
        return sqrt(best)
    }

    // MARK: Nature

    private func scatterNature(avoiding spots: [SCNVector3]) {
        var placed: [(Float, Float, Float)] = []
        let rx = island.rx, rz = island.rz
        var trees = 0
        for k in 0..<700 {
            let x = (Float(townUnit(k, 1, 101)) - 0.5) * 2 * rx
            let z = (Float(townUnit(k, 2, 102)) - 0.5) * 2 * rz
            let lvl = island.level(x, z)
            guard lvl <= 0.92 else { continue }
            if spots.contains(where: { hypot($0.x - x, $0.z - z) < 0.95 }) { continue }
            let d = distanceToRoad(x, z)
            let kind = Int(townHash(k, 3, 103) % 100)
            let radius: Float = kind < 58 ? 0.5 : 0.34
            guard d > radius + 0.2 else { continue }
            if placed.contains(where: { hypot($0.0 - x, $0.1 - z) < $0.2 + radius }) { continue }
            // woods hug the shore, the middle stays open
            if lvl < 0.55 && kind < 58 && townHash(k, 4, 104) % 100 < 70 { continue }
            let node: SCNNode
            switch kind {
            case 0..<58:
                guard trees < 80 else { continue }
                trees += 1
                let style: TreeStyle? = townHash(k, 5, 105) % 100 < 30 ? (p.tree == .pine ? .round : .pine) : nil
                node = Toy.tree(p, style: style, scale: 0.8 + Float(townUnit(k, 6, 106)) * 0.5, variant: k)
            case 58..<76: node = Toy.bush(p, 0.11 + Float(townUnit(k, 7, 107)) * 0.06)
            case 76..<84: node = Toy.rocks(p)
            default: node = Toy.flowers(p).sc(1.4, 1.4, 1.4)
            }
            node.position = SCNVector3(x, Self.groundY, z)
            node.eulerAngles.y = Float(townUnit(k, 8, 108)) * 6
            root.addChildNode(node)
            placed.append((x, z, radius))
        }
    }

    private func buildExtras(taken: Set<TownCell>) {
        let count = min(14, checkIns / 8)
        guard count > 0, roadSamples.count > 12 else { return }
        let houseSpots: [SCNVector3] = houses.values.map { $0.position }
        var done = 0, k = 0
        while done < count && k < 400 {
            let s = roadSamples[Int(townHash(k, 1, 131) % UInt64(roadSamples.count))]
            k += 1
            let ang = Float(townUnit(k, 2, 132)) * 6.28
            let pos = SCNVector3(s.x + cos(ang) * 0.36, Self.groundY, s.z + sin(ang) * 0.36)
            guard island.contains(pos.x, pos.z, margin: 0.88),
                  !houseSpots.contains(where: { hypot($0.x - pos.x, $0.z - pos.z) < 0.9 }),
                  distanceToRoad(pos.x, pos.z) > 0.28 else { continue }
            if extraSpots.contains(where: { hypot($0.x - pos.x, $0.z - pos.z) < 1.4 }) { continue }
            let node: SCNNode
            switch done % 4 {
            case 0: node = Toy.lamp(p)
            case 1: node = Toy.bench(p)
            case 2: node = Toy.special(p)
            default: node = Toy.mailbox(p)
            }
            node.position = pos
            node.eulerAngles.y = atan2(s.x - pos.x, s.z - pos.z)
            root.addChildNode(node)
            extraSpots.append(pos)
            done += 1
        }
    }

    // MARK: Interaction helpers

    private func hitBox() -> SCNNode {
        let g = SCNBox(width: 0.95, height: 0.9, length: 0.95, chamferRadius: 0)
        let m = SCNMaterial(); m.transparency = 0.001; m.writesToDepthBuffer = false; m.readsFromDepthBuffer = false
        g.firstMaterial = m
        let n = SCNNode(geometry: g)
        n.position = SCNVector3(0, 0.45, 0)
        n.name = "hit"
        return n
    }

    private func addLabel(at pos: SCNVector3, text: String, sub: String, name: String) {
        let image = TownLabelImage.make(text: text, sub: sub)
        let height: CGFloat = 0.2
        let plane = SCNPlane(width: height * image.size.width / image.size.height, height: height)
        let m = SCNMaterial()
        m.lightingModel = .constant
        m.diffuse.contents = image
        m.isDoubleSided = true
        m.readsFromDepthBuffer = false
        m.writesToDepthBuffer = false
        plane.firstMaterial = m
        let n = SCNNode(geometry: plane)
        n.name = name
        n.position = SCNVector3(pos.x + 0.1, 0.12, pos.z + 0.78)
        n.renderingOrder = 100
        n.constraints = [SCNBillboardConstraint()]
        root.addChildNode(n)
        labels.append(n)
    }

    // MARK: Level-up

    func pop(_ names: Set<String>) {
        for name in names {
            guard let node = houses[name] else { continue }
            let up = SCNAction.scale(to: 1.22, duration: 0.16); up.timingMode = .easeOut
            let down = SCNAction.scale(to: 1.0, duration: 0.5); down.timingMode = .easeInEaseOut
            node.runAction(.sequence([up, down]))
            let sparks = SCNParticleSystem()
            sparks.birthRate = 160
            sparks.emissionDuration = 0.25
            sparks.loops = false
            sparks.particleLifeSpan = 0.9
            sparks.particleVelocity = 1.6
            sparks.particleVelocityVariation = 0.8
            sparks.spreadingAngle = 80
            sparks.emittingDirection = SCNVector3(0, 1, 0)
            sparks.acceleration = SCNVector3(0, -1.6, 0)
            sparks.particleSize = 0.05
            sparks.particleColor = UIColor(hex: 0xFFC83D)
            sparks.blendMode = .additive
            let holder = SCNNode(); holder.position = SCNVector3(0, 0.5, 0)
            holder.addChildNode(SCNNode())
            holder.addParticleSystem(sparks)
            node.addChildNode(holder)
            holder.runAction(.sequence([.wait(duration: 1.6), .removeFromParentNode()]))
        }
    }
}

enum TownLabelImage {
    static func make(text: String, sub: String) -> UIImage {
        let scale: CGFloat = 4
        let nameFont = UIFont.systemFont(ofSize: 11, weight: .bold).rounded()
        let subFont = UIFont.systemFont(ofSize: 9.5, weight: .semibold).rounded()
        let nameAttr: [NSAttributedString.Key: Any] = [.font: nameFont, .foregroundColor: UIColor(hex: 0x2B2B2E)]
        let subAttr: [NSAttributedString.Key: Any] = [.font: subFont, .foregroundColor: UIColor(hex: 0x8A8A90)]
        let a = NSAttributedString(string: text, attributes: nameAttr)
        let b = NSAttributedString(string: sub, attributes: subAttr)
        let gap: CGFloat = 5, padX: CGFloat = 9, padY: CGFloat = 4
        let w = a.size().width + gap + b.size().width + padX * 2
        let h = max(a.size().height, b.size().height) + padY * 2
        let size = CGSize(width: ceil(w), height: ceil(h))
        let fmt = UIGraphicsImageRendererFormat(); fmt.scale = scale; fmt.opaque = false
        return UIGraphicsImageRenderer(size: size, format: fmt).image { ctx in
            UIColor.white.withAlphaComponent(0.96).setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: size.height / 2).fill()
            a.draw(at: CGPoint(x: padX, y: (size.height - a.size().height) / 2))
            b.draw(at: CGPoint(x: padX + a.size().width + gap, y: (size.height - b.size().height) / 2))
        }
    }
}

private extension UIFont {
    func rounded() -> UIFont {
        guard let d = fontDescriptor.withDesign(.rounded) else { return self }
        return UIFont(descriptor: d, size: pointSize)
    }
}
