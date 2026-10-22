import SceneKit
import SwiftUI
import UIKit

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
    }
}

enum TreeStyle { case round, pine, palm, sakura }
enum Special { case well, torii, stump, snowman, umbrella, fountain }

/// Everything that changes between themes.
struct ToyPalette {
    var grass: UIColor, grassAlt: UIColor, road: UIColor, roadEdge: UIColor, earth: UIColor, stone: UIColor
    var wall: UIColor, roof: UIColor, roofAlt: UIColor, trim: UIColor, door: UIColor, glass: UIColor
    var leaf: UIColor, leafAlt: UIColor, trunk: UIColor, blossom: UIColor
    var tree: TreeStyle
    var special: Special
    var snow = false
    var dusk = false
    var water = UIColor(hex: 0x6EC6EA)
    var sand = UIColor(hex: 0xEBD9A8)
    var foam = UIColor.white
}

extension TownTheme {
    var toy: ToyPalette {
        switch self {
        case .cottage:
            return ToyPalette(grass: UIColor(hex: 0x8FD14F), grassAlt: UIColor(hex: 0x86C946), road: UIColor(hex: 0xF3DFB4), roadEdge: UIColor(hex: 0xD9C08C),
                              earth: UIColor(hex: 0xA46B3D), stone: UIColor(hex: 0x9A9A9E),
                              wall: UIColor(hex: 0xF7E8CB), roof: UIColor(hex: 0xE5773A), roofAlt: UIColor(hex: 0xC85F2B), trim: UIColor(hex: 0xFFF9EE),
                              door: UIColor(hex: 0x9C6236), glass: UIColor(hex: 0xFFD56B),
                              leaf: UIColor(hex: 0x7CC243), leafAlt: UIColor(hex: 0x5EA832), trunk: UIColor(hex: 0x8A5A33), blossom: UIColor(hex: 0xF7B9C6),
                              tree: .round, special: .well, water: UIColor(hex: 0x6EC6EA), sand: UIColor(hex: 0xF0E0B4))
        case .japanese:
            return ToyPalette(grass: UIColor(hex: 0x91D24C), grassAlt: UIColor(hex: 0x89CA44), road: UIColor(hex: 0xD6D6D9), roadEdge: UIColor(hex: 0xB5B5BA),
                              earth: UIColor(hex: 0xA46B3D), stone: UIColor(hex: 0x9A9A9E),
                              wall: UIColor(hex: 0xF5F0E6), roof: UIColor(hex: 0x474A54), roofAlt: UIColor(hex: 0x363842), trim: UIColor(hex: 0xC8402F),
                              door: UIColor(hex: 0x8B5A2B), glass: UIColor(hex: 0xFFD56B),
                              leaf: UIColor(hex: 0x4E9A52), leafAlt: UIColor(hex: 0x3C8443), trunk: UIColor(hex: 0x7A4D2C), blossom: UIColor(hex: 0xF6B3C4),
                              tree: .sakura, special: .torii, water: UIColor(hex: 0x7CCBEA), sand: UIColor(hex: 0xEAD9B0))
        case .forest:
            return ToyPalette(grass: UIColor(hex: 0x3AA13C), grassAlt: UIColor(hex: 0x329834), road: UIColor(hex: 0xD99557), roadEdge: UIColor(hex: 0xB97A3C),
                              earth: UIColor(hex: 0x9A6638), stone: UIColor(hex: 0x8A8B90),
                              wall: UIColor(hex: 0xC48045), roof: UIColor(hex: 0x4C9A42), roofAlt: UIColor(hex: 0x3A8335), trim: UIColor(hex: 0xEBD7AE),
                              door: UIColor(hex: 0x6B4423), glass: UIColor(hex: 0xFFD56B),
                              leaf: UIColor(hex: 0x2F8A3B), leafAlt: UIColor(hex: 0x226F2E), trunk: UIColor(hex: 0x6B4423), blossom: UIColor(hex: 0xE04B3F),
                              tree: .pine, special: .stump, water: UIColor(hex: 0x4FAFC0), sand: UIColor(hex: 0xD9C79A))
        case .snow:
            return ToyPalette(grass: UIColor(hex: 0xF4F9FE), grassAlt: UIColor(hex: 0xE9F2FB), road: UIColor(hex: 0xCDD0D8), roadEdge: UIColor(hex: 0xAEB2BD),
                              earth: UIColor(hex: 0xA46B3D), stone: UIColor(hex: 0x8D8F97),
                              wall: UIColor(hex: 0xE6B97F), roof: UIColor(hex: 0xFFFFFF), roofAlt: UIColor(hex: 0xDCEAF6), trim: UIColor(hex: 0xFFFFFF),
                              door: UIColor(hex: 0x9C6236), glass: UIColor(hex: 0xFFD56B),
                              leaf: UIColor(hex: 0x2F6F58), leafAlt: UIColor(hex: 0x245A47), trunk: UIColor(hex: 0x7A4D2C), blossom: UIColor(hex: 0xE04B3F),
                              tree: .pine, special: .snowman, snow: true, water: UIColor(hex: 0xBCE0F3), sand: UIColor(hex: 0xE4EEF6))
        case .island:
            return ToyPalette(grass: UIColor(hex: 0xF3DA9F), grassAlt: UIColor(hex: 0xEBD093), road: UIColor(hex: 0xC99D66), roadEdge: UIColor(hex: 0xA97F4E),
                              earth: UIColor(hex: 0xD4A867), stone: UIColor(hex: 0xA3A7AA),
                              wall: UIColor(hex: 0xF7ECD5), roof: UIColor(hex: 0x2FAFA7), roofAlt: UIColor(hex: 0xF0CC55), trim: UIColor(hex: 0xFFFFFF),
                              door: UIColor(hex: 0xA3683A), glass: UIColor(hex: 0xFFD56B),
                              leaf: UIColor(hex: 0x3DAF4A), leafAlt: UIColor(hex: 0x2E9640), trunk: UIColor(hex: 0x9B6C3B), blossom: UIColor(hex: 0xE5483E),
                              tree: .palm, special: .umbrella, water: UIColor(hex: 0x45D3D8), sand: UIColor(hex: 0xFFF1C9))
        case .night:
            return ToyPalette(grass: UIColor(hex: 0x2A5568), grassAlt: UIColor(hex: 0x244A5C), road: UIColor(hex: 0x4D5280), roadEdge: UIColor(hex: 0x3A3F66),
                              earth: UIColor(hex: 0x4B3B68), stone: UIColor(hex: 0x575A80),
                              wall: UIColor(hex: 0x6A57A0), roof: UIColor(hex: 0x2D3170), roofAlt: UIColor(hex: 0x23275A), trim: UIColor(hex: 0x9C8AD6),
                              door: UIColor(hex: 0x7A5230), glass: UIColor(hex: 0xFFC95A),
                              leaf: UIColor(hex: 0x1F6670), leafAlt: UIColor(hex: 0x185560), trunk: UIColor(hex: 0x4A3A2E), blossom: UIColor(hex: 0x6EA8FF),
                              tree: .round, special: .fountain, dusk: true, water: UIColor(hex: 0x20386E), sand: UIColor(hex: 0x5C5A86), foam: UIColor(hex: 0x9CB4FF))
        }
    }
}

extension SCNNode {
    @discardableResult func at(_ x: Float, _ y: Float, _ z: Float) -> SCNNode { position = SCNVector3(x, y, z); return self }
    @discardableResult func rot(_ x: Float = 0, _ y: Float = 0, _ z: Float = 0) -> SCNNode { eulerAngles = SCNVector3(x, y, z); return self }
    @discardableResult func sc(_ x: Float, _ y: Float, _ z: Float) -> SCNNode { scale = SCNVector3(x, y, z); return self }
    func put(_ nodes: SCNNode...) { nodes.forEach { addChildNode($0) } }
}

/// Soft, matte toy-like building blocks.
enum Toy {
    static func mat(_ c: UIColor, glow: Bool = false) -> SCNMaterial {
        let m = SCNMaterial()
        m.lightingModel = .lambert
        m.diffuse.contents = c
        m.specular.contents = UIColor.black
        if glow { m.emission.contents = c; m.emission.intensity = 0.85 }
        return m
    }

    static func box(_ w: Float, _ h: Float, _ l: Float, _ c: UIColor, r: Float = 0.012, glow: Bool = false) -> SCNNode {
        let g = SCNBox(width: CGFloat(w), height: CGFloat(h), length: CGFloat(l), chamferRadius: CGFloat(r))
        g.chamferSegmentCount = 2
        g.firstMaterial = mat(c, glow: glow)
        return SCNNode(geometry: g)
    }

    static func cyl(_ r: Float, _ h: Float, _ c: UIColor, glow: Bool = false) -> SCNNode {
        let g = SCNCylinder(radius: CGFloat(r), height: CGFloat(h))
        g.radialSegmentCount = 28
        g.firstMaterial = mat(c, glow: glow)
        return SCNNode(geometry: g)
    }

    static func cone(_ r: Float, _ h: Float, _ c: UIColor) -> SCNNode {
        let g = SCNCone(topRadius: 0, bottomRadius: CGFloat(r), height: CGFloat(h))
        g.radialSegmentCount = 28
        g.firstMaterial = mat(c)
        return SCNNode(geometry: g)
    }

    static func ball(_ r: Float, _ c: UIColor, glow: Bool = false, segments: Int = 24) -> SCNNode {
        let g = SCNSphere(radius: CGFloat(r))
        g.segmentCount = segments
        g.firstMaterial = mat(c, glow: glow)
        return SCNNode(geometry: g)
    }

    /// Gable roof: base on y = 0, ridge along z.
    static func prism(_ w: Float, _ h: Float, _ l: Float, _ c: UIColor) -> SCNNode {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: CGFloat(-w / 2), y: 0))
        path.addLine(to: CGPoint(x: CGFloat(w / 2), y: 0))
        path.addLine(to: CGPoint(x: 0, y: CGFloat(h)))
        path.close()
        let g = SCNShape(path: path, extrusionDepth: CGFloat(l))
        g.chamferRadius = 0.008
        g.firstMaterial = mat(c)
        let n = SCNNode(geometry: g)
        let bb = n.boundingBox
        n.pivot = SCNMatrix4MakeTranslation(0, 0, (bb.min.z + bb.max.z) / 2)
        return n
    }

    /// Soft contact shadow so things sit on the ground.
    static func shadow(_ r: Float, alpha: CGFloat = 0.2) -> SCNNode {
        let g = SCNCylinder(radius: CGFloat(r), height: 0.004)
        g.radialSegmentCount = 24
        let m = SCNMaterial(); m.lightingModel = .constant
        m.diffuse.contents = UIColor.black.withAlphaComponent(alpha)
        m.writesToDepthBuffer = false
        g.firstMaterial = m
        let n = SCNNode(geometry: g)
        n.position = SCNVector3(0, 0.006, 0)
        n.renderingOrder = 5
        return n
    }

    // MARK: Houses

    private static func window(_ p: ToyPalette, side: Bool) -> SCNNode {
        let n = SCNNode()
        if side {
            n.put(box(0.012, 0.15, 0.15, p.trim, r: 0.004), box(0.016, 0.11, 0.11, p.glass, r: 0.003, glow: true).at(0.003, 0, 0),
                  box(0.02, 0.11, 0.012, p.trim, r: 0.002).at(0.006, 0, 0), box(0.02, 0.012, 0.11, p.trim, r: 0.002).at(0.006, 0, 0),
                  box(0.03, 0.014, 0.18, p.trim, r: 0.004).at(0.01, -0.082, 0),
                  box(0.016, 0.13, 0.03, p.roofAlt, r: 0.004).at(0.006, 0, 0.1), box(0.016, 0.13, 0.03, p.roofAlt, r: 0.004).at(0.006, 0, -0.1))
        } else {
            n.put(box(0.15, 0.15, 0.012, p.trim, r: 0.004), box(0.11, 0.11, 0.016, p.glass, r: 0.003, glow: true).at(0, 0, 0.003),
                  box(0.012, 0.11, 0.02, p.trim, r: 0.002).at(0, 0, 0.006), box(0.11, 0.012, 0.02, p.trim, r: 0.002).at(0, 0, 0.006),
                  box(0.18, 0.014, 0.03, p.trim, r: 0.004).at(0, -0.082, 0.01),
                  box(0.03, 0.13, 0.016, p.roofAlt, r: 0.004).at(0.1, 0, 0.006), box(0.03, 0.13, 0.016, p.roofAlt, r: 0.004).at(-0.1, 0, 0.006))
        }
        return n
    }

    private static func door(_ p: ToyPalette) -> SCNNode {
        let n = SCNNode()
        n.put(box(0.14, 0.23, 0.014, p.trim, r: 0.004).at(0, 0.115, 0),
              box(0.105, 0.2, 0.018, p.door, r: 0.006).at(0, 0.1, 0.003),
              ball(0.011, UIColor(hex: 0xF3C969), segments: 10).at(0.03, 0.1, 0.014),
              cyl(0.052, 0.018, p.door).rot(.pi / 2, 0, 0).at(0, 0.2, 0.003),
              box(0.2, 0.025, 0.07, UIColor(hex: 0xC9C3BA), r: 0.006).at(0, 0.012, 0.045))
        return n
    }

    private static func chimney(_ p: ToyPalette) -> SCNNode {
        let n = SCNNode()
        n.put(box(0.085, 0.17, 0.085, p.trim == UIColor(hex: 0xFFFFFF) ? UIColor(hex: 0xB9BDC6) : UIColor(hex: 0xB9B4AE), r: 0.01).at(0, 0.085, 0),
              box(0.1, 0.02, 0.1, UIColor(hex: 0x8D8984), r: 0.006).at(0, 0.17, 0))
        return n
    }

    /// One building block: walls, roof, door, windows.
    private static func block(w: Float, l: Float, h: Float, rh: Float, p: ToyPalette, doorOn: Bool, windows: Bool = true) -> SCNNode {
        let n = SCNNode()
        n.addChildNode(box(w + 0.03, 0.05, l + 0.03, UIColor(hex: 0xA7A3A0), r: 0.008).at(0, 0.025, 0))
        n.addChildNode(box(w, h, l, p.wall, r: 0.014).at(0, h / 2 + 0.01, 0))
        let oh: Float = 0.05
        n.addChildNode(prism(w + 2 * oh, rh, l + 2 * oh, p.roof).at(0, h - 0.004, 0))
        // darker eave lines
        n.addChildNode(box(w + 2 * oh, 0.02, 0.012, p.roofAlt, r: 0.004).at(0, h + 0.004, l / 2 + oh - 0.004))
        n.addChildNode(box(0.04, 0.025, l + 2 * oh + 0.02, p.roofAlt, r: 0.008).at(0, h + rh - 0.01, 0))
        for k in 1..<4 { n.addChildNode(box(w + 2 * oh + 0.01, 0.006, 0.012, p.roofAlt.withAlphaComponent(1), r: 0.002).at(0, h + rh * (1 - Float(k) / 4) * 0.5 * 0, l / 2 + oh)) }
        if p.snow {
            n.addChildNode(prism((w + 2 * oh) * 0.45 + 0.02, rh * 0.45 + 0.012, l + 2 * oh + 0.02, UIColor.white).at(0, h + rh * 0.55 - 0.004, 0))
        }
        if doorOn { n.addChildNode(door(p).at(w * 0.12, 0, l / 2 + 0.004)) }
        if windows {
            n.addChildNode(window(p, side: true).at(w / 2 + 0.003, h * 0.58, 0))
            if w > 0.5 { n.addChildNode(window(p, side: false).at(-w * 0.27, h * 0.58, l / 2 + 0.003)) }
        }
        return n
    }

    static func lot(_ p: ToyPalette) -> SCNNode {
        let n = SCNNode()
        let soil = p.dusk ? UIColor(hex: 0x4A3454) : UIColor(hex: 0x8A5A33)
        n.put(cyl(0.34, 0.04, soil).at(0, 0.02, 0),
              ball(0.26, soil.withAlphaComponent(1)).sc(1, 0.2, 1).at(0, 0.04, 0))
        // sign
        n.put(cyl(0.012, 0.28, UIColor(hex: 0x9C6B3C)).at(-0.18, 0.14, 0.05),
              box(0.2, 0.1, 0.02, UIColor(hex: 0xC48A4C), r: 0.008).at(-0.18, 0.27, 0.05).rot(0, 0.3, 0))
        // sapling
        let stem = UIColor(hex: 0x5BA83D), leaf = UIColor(hex: 0x7ED04B)
        n.put(cyl(0.01, 0.1, stem).at(0.08, 0.1, -0.02),
              ball(0.07, leaf).sc(1.2, 0.3, 0.7).at(0.04, 0.17, -0.02).rot(0, 0, 0.5),
              ball(0.07, leaf).sc(1.2, 0.3, 0.7).at(0.12, 0.17, -0.02).rot(0, 0, -0.5))
        return n
    }

    static func house(level: Int, p: ToyPalette) -> SCNNode {
        let n = SCNNode()
        switch level {
        case ...0:
            return lot(p)
        case 1:
            n.addChildNode(block(w: 0.56, l: 0.46, h: 0.3, rh: 0.26, p: p, doorOn: true).at(0, 0, 0))
            n.addChildNode(bush(p, 0.07).at(-0.3, 0, 0.22))
            n.addChildNode(bush(p, 0.06).at(0.32, 0, 0.26))
        case 2:
            let b = block(w: 0.64, l: 0.5, h: 0.34, rh: 0.28, p: p, doorOn: true)
            n.addChildNode(b)
            n.addChildNode(chimney(p).at(0.16, 0.34 + 0.12, -0.1))
            // porch awning + flower box
            n.addChildNode(box(0.22, 0.02, 0.12, p.roofAlt, r: 0.006).at(0.077, 0.27, 0.31).rot(0.25, 0, 0))
            n.addChildNode(box(0.2, 0.05, 0.06, UIColor(hex: 0x9C6236), r: 0.01).at(-0.2, 0.1, 0.27))
            for i in 0..<3 { n.addChildNode(ball(0.026, [UIColor(hex: 0xF7B9C6), .white, UIColor(hex: 0xFFD56B)][i]).at(-0.26 + Float(i) * 0.06, 0.15, 0.27)) }
            n.addChildNode(bush(p, 0.08).at(-0.36, 0, 0.18))
            n.addChildNode(bush(p, 0.07).at(0.38, 0, 0.3))
        case 3:
            n.addChildNode(box(0.68, 0.3, 0.54, p.wall, r: 0.014).at(0, 0.15, 0))
            n.addChildNode(door(p).at(0.14, 0, 0.274))
            n.addChildNode(window(p, side: false).at(-0.2, 0.17, 0.274))
            n.addChildNode(window(p, side: true).at(0.343, 0.17, 0.05))
            // porch roof
            n.addChildNode(box(0.26, 0.022, 0.14, p.roofAlt, r: 0.006).at(0.14, 0.27, 0.34).rot(0.28, 0, 0))
            // upper floor
            let up = block(w: 0.5, l: 0.42, h: 0.26, rh: 0.26, p: p, doorOn: false, windows: false)
            up.position = SCNVector3(-0.06, 0.3, -0.02)
            up.addChildNode(window(p, side: false).at(0, 0.15, 0.213))
            up.addChildNode(window(p, side: true).at(0.253, 0.15, 0))
            n.addChildNode(up)
            n.addChildNode(chimney(p).at(0.08, 0.56 + 0.1, -0.1))
            // little fence
            for i in 0..<5 { n.addChildNode(box(0.02, 0.07, 0.02, p.trim, r: 0.004).at(-0.3 + Float(i) * 0.14, 0.035, 0.42)) }
            n.addChildNode(box(0.6, 0.014, 0.014, p.trim, r: 0.003).at(0, 0.055, 0.42))
            n.addChildNode(bush(p, 0.08).at(-0.38, 0, 0.3))
            n.addChildNode(bush(p, 0.07).at(0.4, 0, 0.36))
            if p.tree == .sakura { n.addChildNode(torii(p).sc(0.7, 0.7, 0.7).at(0.1, 0, 0.62)) }
        default:
            n.addChildNode(box(0.7, 0.3, 0.54, p.wall, r: 0.014).at(-0.06, 0.15, 0.04))
            n.addChildNode(door(p).at(0.1, 0, 0.314))
            n.addChildNode(window(p, side: false).at(-0.24, 0.17, 0.314))
            n.addChildNode(window(p, side: true).at(0.293, 0.17, 0.08))
            n.addChildNode(box(0.28, 0.022, 0.15, p.roofAlt, r: 0.006).at(0.1, 0.27, 0.38).rot(0.28, 0, 0))
            let up = block(w: 0.52, l: 0.42, h: 0.26, rh: 0.28, p: p, doorOn: false, windows: false)
            up.position = SCNVector3(-0.1, 0.3, 0.0)
            up.addChildNode(window(p, side: false).at(0, 0.15, 0.213))
            up.addChildNode(window(p, side: true).at(0.263, 0.15, 0))
            n.addChildNode(up)
            // tower
            let tower = SCNNode()
            tower.put(cyl(0.14, 0.62, p.wall).at(0, 0.31, 0),
                      cyl(0.155, 0.03, p.roofAlt).at(0, 0.62, 0),
                      cone(0.19, 0.28, p.roof).at(0, 0.77, 0),
                      cyl(0.008, 0.2, UIColor(hex: 0x8A6A4A)).at(0, 1.01, 0),
                      box(0.12, 0.07, 0.008, UIColor(hex: 0xE5483E), r: 0.002).at(0.06, 1.05, 0),
                      box(0.012, 0.1, 0.1, p.glass, r: 0.003, glow: true).at(0.14, 0.4, 0).rot(0, 0, 0),
                      box(0.1, 0.1, 0.012, p.glass, r: 0.003, glow: true).at(0, 0.4, 0.14))
            tower.position = SCNVector3(-0.36, 0, -0.14)
            n.addChildNode(tower)
            n.addChildNode(chimney(p).at(0.06, 0.56 + 0.12, -0.12))
            // lanterns at the door and a garden
            n.addChildNode(ball(0.028, p.glass, glow: true).at(0.0, 0.2, 0.33))
            n.addChildNode(ball(0.028, p.glass, glow: true).at(0.22, 0.2, 0.33))
            for i in 0..<6 { n.addChildNode(box(0.02, 0.07, 0.02, p.trim, r: 0.004).at(-0.34 + Float(i) * 0.14, 0.035, 0.46)) }
            n.addChildNode(box(0.72, 0.014, 0.014, p.trim, r: 0.003).at(0, 0.055, 0.46))
            n.addChildNode(flowers(p).at(-0.18, 0, 0.4))
            n.addChildNode(bush(p, 0.09).at(0.42, 0, 0.34))
            n.addChildNode(bush(p, 0.08).at(-0.46, 0, 0.3))
            if p.tree == .sakura { n.addChildNode(torii(p).sc(0.8, 0.8, 0.8).at(0.3, 0, 0.7)) }
            if p.special == .umbrella { n.addChildNode(umbrella(p).sc(0.8, 0.8, 0.8).at(0.46, 0, 0.55)) }
        }
        if level >= 2 { n.addChildNode(smoke(at: SCNVector3(level == 2 ? 0.16 : 0.08, level == 2 ? 0.55 : 0.78, -0.1))) }
        n.addChildNode(shadow(0.62, alpha: 0.16))
        n.scale = SCNVector3(1.22, 1.22, 1.22)
        return n
    }

    static func smoke(at pos: SCNVector3) -> SCNNode {
        let n = SCNNode(); n.position = pos
        for k in 0..<3 {
            let puff = ball(0.035, UIColor.white.withAlphaComponent(0.8), segments: 10)
            puff.opacity = 0
            let rise = SCNAction.group([.moveBy(x: 0.05, y: 0.22, z: 0, duration: 2.6), .scale(to: 2.0, duration: 2.6),
                                        .sequence([.fadeOpacity(to: 0.65, duration: 0.5), .fadeOpacity(to: 0, duration: 2.1)])])
            let reset = SCNAction.run { x in x.position = SCNVector3(0, 0, 0); x.scale = SCNVector3(1, 1, 1); x.opacity = 0 }
            puff.runAction(.sequence([.wait(duration: Double(k) * 0.85), .repeatForever(.sequence([reset, rise]))]))
            n.addChildNode(puff)
        }
        return n
    }

    // MARK: Props

    static func bush(_ p: ToyPalette, _ r: Float = 0.1) -> SCNNode {
        let n = SCNNode()
        n.put(shadow(r * 1.5, alpha: 0.14), ball(r, p.leaf).sc(1, 0.8, 1).at(0, r * 0.8, 0),
              ball(r * 0.75, p.leafAlt).sc(1, 0.8, 1).at(r * 0.7, r * 0.6, r * 0.3),
              ball(r * 0.7, p.leaf).sc(1, 0.8, 1).at(-r * 0.6, r * 0.55, -r * 0.2))
        return n
    }

    static func flowers(_ p: ToyPalette) -> SCNNode {
        let n = SCNNode()
        n.put(ball(0.08, p.leaf).sc(1, 0.4, 1).at(0, 0.03, 0))
        let cols: [UInt32] = [0xF7B9C6, 0xFFFFFF, 0xFFD56B, 0xF7B9C6]
        for (i, c) in cols.enumerated() {
            let a = Float(i) * 1.7
            n.addChildNode(ball(0.028, UIColor(hex: c), segments: 12).at(cos(a) * 0.05, 0.075, sin(a) * 0.05))
        }
        return n
    }

    static func tree(_ p: ToyPalette, style: TreeStyle? = nil, scale s: Float = 1, variant: Int = 0) -> SCNNode {
        let n = SCNNode()
        switch style ?? p.tree {
        case .round, .sakura:
            let isSakura = (style ?? p.tree) == .sakura
            let c1 = isSakura ? p.blossom : p.leaf
            let c2 = isSakura ? UIColor(hex: 0xFBD2DC) : p.leafAlt
            n.put(shadow(0.34), cyl(0.05, 0.3, p.trunk).at(0, 0.15, 0), cyl(0.07, 0.05, p.trunk).at(0, 0.03, 0),
                  ball(0.12, c2).at(-0.22, 0.34, 0.12), ball(0.11, c1).at(0.2, 0.62, -0.16), ball(0.1, c2).at(-0.1, 0.8, 0.1),
                  ball(0.3, c1).at(0, 0.52, 0),
                  ball(0.22, c2).at(0.17, 0.42, 0.1),
                  ball(0.2, c1).at(-0.15, 0.4, -0.1),
                  ball(0.18, c2).at(0.02, 0.72, -0.04))
            if p.dusk { for i in 0..<6 { let a = Float(i) * 1.1; n.addChildNode(ball(0.016, UIColor(hex: 0xFFD56B), glow: true, segments: 8).at(cos(a) * 0.28, 0.45 + Float(i % 3) * 0.1, sin(a) * 0.28)) } }
        case .pine:
            n.put(shadow(0.3), cyl(0.045, 0.2, p.trunk).at(0, 0.1, 0))
            let tiers: [(Float, Float, Float)] = [(0.3, 0.34, 0.3), (0.24, 0.3, 0.5), (0.17, 0.27, 0.69)]
            for t in tiers {
                n.addChildNode(cone(t.0, t.1, variant % 2 == 0 ? p.leaf : p.leafAlt).at(0, t.2, 0))
                if p.snow { n.addChildNode(cone(t.0 * 0.82, t.1 * 0.4, .white).at(0, t.2 + t.1 * 0.28, 0)) }
            }
            if p.dusk { for i in 0..<5 { let a = Float(i) * 1.3; n.addChildNode(ball(0.015, UIColor(hex: 0xFFD56B), glow: true, segments: 8).at(cos(a) * 0.18, 0.35 + Float(i) * 0.08, sin(a) * 0.18)) } }
        case .palm:
            // curved trunk
            for i in 0..<5 {
                let t = Float(i)
                n.addChildNode(cyl(0.045 - t * 0.004, 0.17, p.trunk).at(t * 0.035, 0.08 + t * 0.15, 0).rot(0, 0, -0.14))
            }
            let top = SCNNode(); top.position = SCNVector3(0.17, 0.82, 0)
            for i in 0..<6 {
                let frond = box(0.4, 0.014, 0.1, i % 2 == 0 ? p.leaf : p.leafAlt, r: 0.006)
                frond.position = SCNVector3(0.17, 0, 0)
                let holder = SCNNode(); holder.addChildNode(frond)
                holder.eulerAngles = SCNVector3(0, Float(i) * (.pi / 3), -0.35)
                top.addChildNode(holder)
            }
            top.addChildNode(ball(0.04, UIColor(hex: 0x7A4B28), segments: 10).at(0.03, -0.04, 0.03))
            top.addChildNode(ball(0.04, UIColor(hex: 0x7A4B28), segments: 10).at(-0.03, -0.04, -0.02))
            n.addChildNode(top)
        }
        n.scale = SCNVector3(s, s, s)
        return n
    }

    static func rocks(_ p: ToyPalette) -> SCNNode {
        let n = SCNNode()
        let c = p.snow ? UIColor(hex: 0xB6BAC4) : (p.dusk ? UIColor(hex: 0x6C7089) : UIColor(hex: 0xA9ACB3))
        let a = SCNSphere(radius: 0.14); a.segmentCount = 7; a.firstMaterial = mat(c)
        let b = SCNSphere(radius: 0.09); b.segmentCount = 7; b.firstMaterial = mat(c.withAlphaComponent(1))
        let na = SCNNode(geometry: a); na.scale = SCNVector3(1, 0.75, 0.85); na.position = SCNVector3(0, 0.09, 0); na.eulerAngles = SCNVector3(0, 0.6, 0)
        let nb = SCNNode(geometry: b); nb.scale = SCNVector3(1, 0.7, 0.9); nb.position = SCNVector3(0.16, 0.05, 0.08); nb.eulerAngles = SCNVector3(0, 1.1, 0)
        n.put(na, nb)
        if p.snow { n.addChildNode(ball(0.1, .white).sc(1, 0.35, 0.9).at(0, 0.17, 0)) }
        return n
    }

    static func lamp(_ p: ToyPalette) -> SCNNode {
        let n = SCNNode()
        let metal = UIColor(hex: 0x4A4650)
        n.put(cyl(0.05, 0.04, metal).at(0, 0.02, 0),
              cyl(0.014, 0.42, metal).at(0, 0.23, 0),
              cyl(0.045, 0.03, metal).at(0, 0.45, 0),
              ball(0.05, UIColor(hex: 0xFFD56B), glow: true, segments: 14).at(0, 0.5, 0),
              cone(0.06, 0.05, metal).at(0, 0.57, 0))
        return n
    }

    static func bench(_ p: ToyPalette) -> SCNNode {
        let n = SCNNode()
        let wood = UIColor(hex: 0xB8763D)
        n.put(box(0.36, 0.03, 0.12, wood, r: 0.006).at(0, 0.14, 0),
              box(0.36, 0.12, 0.02, wood, r: 0.006).at(0, 0.22, -0.05).rot(-0.15, 0, 0))
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] { n.addChildNode(box(0.025, 0.13, 0.025, UIColor(hex: 0x8A5A33), r: 0.004).at(sx * 0.15, 0.065, sz * 0.04)) } }
        if p.snow { n.addChildNode(box(0.36, 0.02, 0.12, .white, r: 0.008).at(0, 0.165, 0)) }
        return n
    }

    static func well(_ p: ToyPalette) -> SCNNode {
        let n = SCNNode()
        let stone = UIColor(hex: 0xA8A9B0)
        n.put(cyl(0.13, 0.15, stone).at(0, 0.075, 0),
              cyl(0.1, 0.02, UIColor(hex: 0x4F9FD8)).at(0, 0.145, 0))
        for sx: Float in [-1, 1] { n.addChildNode(box(0.02, 0.2, 0.02, UIColor(hex: 0x8A5A33), r: 0.004).at(sx * 0.11, 0.25, 0)) }
        n.addChildNode(prism(0.34, 0.1, 0.3, p.roof).at(0, 0.34, 0).rot(0, .pi / 2, 0))
        return n
    }

    static func fountain(_ p: ToyPalette) -> SCNNode {
        let n = SCNNode()
        let stone = UIColor(hex: 0x6C7094)
        n.put(cyl(0.2, 0.1, stone).at(0, 0.05, 0),
              cyl(0.17, 0.02, UIColor(hex: 0x6EB8FF), glow: true).at(0, 0.105, 0),
              cyl(0.03, 0.2, stone).at(0, 0.2, 0),
              ball(0.07, UIColor(hex: 0x9CD0FF), glow: true).sc(1, 0.5, 1).at(0, 0.3, 0))
        return n
    }

    static func torii(_ p: ToyPalette) -> SCNNode {
        let n = SCNNode()
        let red = UIColor(hex: 0xD8432F)
        n.put(cyl(0.025, 0.4, red).at(-0.16, 0.2, 0), cyl(0.025, 0.4, red).at(0.16, 0.2, 0),
              box(0.46, 0.035, 0.05, UIColor(hex: 0x3A3A44), r: 0.008).at(0, 0.42, 0),
              box(0.36, 0.025, 0.035, red, r: 0.005).at(0, 0.33, 0))
        return n
    }

    static func stump(_ p: ToyPalette) -> SCNNode {
        let n = SCNNode()
        n.put(cyl(0.1, 0.12, p.trunk).at(0, 0.06, 0), cyl(0.085, 0.01, UIColor(hex: 0xE2B77C)).at(0, 0.125, 0),
              box(0.025, 0.14, 0.02, UIColor(hex: 0x8D8F96), r: 0.004).at(0.03, 0.18, 0).rot(0, 0, 0.5))
        let mush = SCNNode()
        mush.put(cyl(0.012, 0.05, UIColor(hex: 0xF2E7D5)).at(0, 0.025, 0), ball(0.04, UIColor(hex: 0xE04B3F)).sc(1, 0.6, 1).at(0, 0.06, 0))
        mush.position = SCNVector3(0.17, 0, 0.1)
        n.addChildNode(mush)
        return n
    }

    static func snowman(_ p: ToyPalette) -> SCNNode {
        let n = SCNNode()
        n.put(ball(0.11, .white).at(0, 0.11, 0), ball(0.08, .white).at(0, 0.27, 0), ball(0.06, .white).at(0, 0.4, 0),
              cone(0.012, 0.06, UIColor(hex: 0xF08A3C)).at(0, 0.4, 0.06).rot(.pi / 2, 0, 0),
              box(0.13, 0.025, 0.13, UIColor(hex: 0xD8432F), r: 0.008).at(0, 0.34, 0),
              ball(0.008, .black, segments: 6).at(-0.02, 0.42, 0.05), ball(0.008, .black, segments: 6).at(0.02, 0.42, 0.05))
        return n
    }

    static func umbrella(_ p: ToyPalette) -> SCNNode {
        let n = SCNNode()
        n.put(cyl(0.012, 0.42, UIColor(hex: 0xC9A06A)).at(0, 0.21, 0),
              cone(0.24, 0.1, UIColor(hex: 0x2FAFA7)).at(0, 0.45, 0),
              cone(0.2, 0.09, UIColor.white).at(0, 0.455, 0).sc(0.96, 1, 0.96),
              box(0.2, 0.025, 0.1, UIColor(hex: 0xF0CC55), r: 0.006).at(0.2, 0.1, 0.1).rot(0, 0.6, 0))
        return n
    }

    static func mailbox(_ p: ToyPalette) -> SCNNode {
        let n = SCNNode()
        n.put(cyl(0.015, 0.24, UIColor(hex: 0x8A5A33)).at(0, 0.12, 0),
              box(0.1, 0.075, 0.15, UIColor(hex: 0x4E7EC9), r: 0.015).at(0, 0.27, 0),
              box(0.012, 0.07, 0.03, UIColor(hex: 0xE5483E), r: 0.003).at(0.06, 0.3, 0.03))
        return n
    }

    static func special(_ p: ToyPalette) -> SCNNode {
        switch p.special {
        case .well: return well(p)
        case .torii: return torii(p)
        case .stump: return stump(p)
        case .snowman: return snowman(p)
        case .umbrella: return umbrella(p)
        case .fountain: return fountain(p)
        }
    }
}

extension ToyPalette {
    var waterColor: Color { Color(uiColor: water) }
}
