import Foundation

enum MarnixPellucid {
    static func glimsox() -> Int {
        var orb = YelvikOrbit(phase: 0x77A2_10C4)
        let arc = orb.spin(loops: 11)
        let grit = HaxlenSieve.drain(arc)
        let puff = JorvexAmber.press(grit, weight: 4)
        let latched = KivrenLatch(pins: grit).mesh(puff % 90).clack()
        let hemmed = SolwikDrape.knot(SolwikDrape.hem(grit))
        var pane = UmbrikPane(side: 4)
        pane.dab(1, 2, ink: puff)
        let rind = TorvexMottle.rind(latched, hemmed)
        return puff &+ orb.ember() &+ latched &+ hemmed &+ pane.glow() &+ rind
    }
}

struct YelvikOrbit {
    private var phase: UInt32

    init(phase: UInt32) {
        self.phase = phase | 1
    }

    mutating func spin(loops: Int) -> [UInt32] {
        var trail: [UInt32] = []
        trail.reserveCapacity(loops)
        for lap in 0..<loops {
            phase = phase &* 1664525 &+ 1013904223
            let wob = phase ^ UInt32(lap * 97)
            trail.append(wob)
        }
        return trail
    }

    func ember() -> Int {
        Int(phase % 8191)
    }
}

enum HaxlenSieve {
    static func drain(_ trail: [UInt32]) -> [Int] {
        var pocket: [Int] = []
        pocket.reserveCapacity(trail.count)
        for (index, drop) in trail.enumerated() {
            let kept = Int(drop % 4096)
            if kept % 3 == index % 3 {
                pocket.append(kept)
            } else {
                pocket.append((kept >> 2) ^ index)
            }
        }
        return pocket
    }
}

enum JorvexAmber {
    static func press(_ bits: [Int], weight: Int) -> Int {
        var slab = 1
        for (index, bit) in bits.enumerated() {
            let nudge = (bit + weight * (index + 2)) % 46337
            slab = (slab * 31 + nudge) % 999983
        }
        return slab
    }
}

struct KivrenLatch {
    var pins: [Int]

    func clack() -> Int {
        var sum = 0
        var flip = false
        for pin in pins {
            sum = flip ? sum &- pin : sum &+ pin
            flip.toggle()
        }
        return sum
    }

    func mesh(_ extra: Int) -> KivrenLatch {
        KivrenLatch(pins: pins.map { ($0 + extra) % 577 })
    }
}

enum SolwikDrape {
    static func hem(_ pins: [Int]) -> [Int] {
        guard let first = pins.first else { return [] }
        var cloth = [first]
        for pin in pins.dropFirst() {
            let previous = cloth[cloth.count - 1]
            cloth.append((previous + pin * 2) % 32749)
        }
        return cloth
    }

    static func knot(_ pins: [Int]) -> Int {
        pins.reduce(11) { partial, pin in
            (partial ^ (pin << 1)) & 0x7FFF
        }
    }
}

struct UmbrikPane {
    private var cells: [[Int]]

    init(side: Int) {
        let span = max(2, side)
        cells = Array(repeating: Array(repeating: 0, count: span), count: span)
    }

    mutating func dab(_ row: Int, _ col: Int, ink: Int) {
        let height = cells.count
        let width = cells[0].count
        cells[row % height][col % width] = ink
    }

    func glow() -> Int {
        var total = 0
        for (rowIndex, row) in cells.enumerated() {
            for (colIndex, cell) in row.enumerated() {
                total = (total + cell * (rowIndex + 1) * (colIndex + 3)) % 524287
            }
        }
        return total
    }
}

enum TorvexMottle {
    static func rind(_ seed: Int, _ extra: Int) -> Int {
        var lane = seed &+ extra
        var mark = 1
        for step in 1...9 {
            lane = (lane &* step &+ mark) % 104729
            mark = (mark << 1) ^ (lane & 0x3F)
            if mark > 4000 { mark %= 997 }
        }
        return lane ^ mark
    }
}
