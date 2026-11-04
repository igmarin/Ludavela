import XCTest

@testable import Ludavela

/// #629: the two games that paint with many colours keep every pair apart for typical vision and the
/// three full colour-blindness types. Shapes already carry the answer; this keeps the colours from
/// contradicting them. The palettes before #629 fail it (Color Clash 5.2, Repeat 3.2).
final class ColorVisionTests: XCTestCase {
    /// CIE76 distance in Lab. About 2 is barely visible; 17 is two colours nobody mixes up. The old
    /// palettes had pairs at 3 to 8.
    private static let minimumDifference = 17.0

    func testGivenColorClashInksWhenSeenWithEachColorVisionThenEveryPairStaysApart() {
        assertApart(Ink.allCases.map { ("\($0)", $0.rgb) })
    }

    func testGivenRepeatTilesWhenSeenWithEachColorVisionThenEveryPairStaysApart() {
        let tiles = RepeatSequenceView.Tile.allCases
        assertApart(tiles.map { ("\($0)", $0.rgb) })
        // At rest the tiles show at 75% over the screen (cream, or near-black in dark mode).
        for background: UInt32 in [0xFFF1D0, 0x211E1B] {
            assertApart(tiles.map { ("\($0) resting", Self.blend($0.rgb, over: background, opacity: 0.75)) })
        }
    }

    private static func blend(_ rgb: UInt32, over background: UInt32, opacity: Double) -> UInt32 {
        [16, 8, 0].reduce(0) { result, shift in
            let top = Double(rgb >> UInt32(shift) & 0xFF)
            let bottom = Double(background >> UInt32(shift) & 0xFF)
            return result | UInt32((top * opacity + bottom * (1 - opacity)).rounded()) << UInt32(shift)
        }
    }

    func testGivenTheOldNearTwinBluesWhenComparedThenTheCheckCatchesThem() {
        // Repeat's old triangle and sun: near twins even for typical vision.
        XCTAssertLessThan(ColorVision.typical.difference(0x35566D, 0x1F5F7A), Self.minimumDifference)
    }

    private func assertApart(_ palette: [(String, UInt32)], file: StaticString = #filePath, line: UInt = #line) {
        for vision in ColorVision.allCases {
            for i in palette.indices {
                for j in palette.indices where j > i {
                    let difference = vision.difference(palette[i].1, palette[j].1)
                    XCTAssertGreaterThanOrEqual(
                        difference, Self.minimumDifference,
                        "\(palette[i].0)/\(palette[j].0) under \(vision): \(difference)", file: file, line: line)
                }
            }
        }
    }
}

/// How a colour looks with typical vision and with each full dichromacy, using the Machado, Oliveira and
/// Fernandes (2009) matrices at severity 1.0 on linear sRGB. Test-only: the app never filters colours
/// (iOS has its own Colour Filters); this only checks the palettes it ships.
private enum ColorVision: CaseIterable {
    case typical, protanopia, deuteranopia, tritanopia

    private var matrix: [[Double]] {
        switch self {
        case .typical: [[1, 0, 0], [0, 1, 0], [0, 0, 1]]
        case .protanopia:
            [[0.152286, 1.052583, -0.204868], [0.114503, 0.786281, 0.099216], [-0.003882, -0.048116, 1.051998]]
        case .deuteranopia:
            [[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]]
        case .tritanopia:
            [[1.255528, -0.076749, -0.178779], [-0.078411, 0.930809, 0.147602], [0.004733, 0.691367, 0.303900]]
        }
    }

    func difference(_ a: UInt32, _ b: UInt32) -> Double {
        let (la, lb) = (lab(a), lab(b))
        return sqrt(zip(la, lb).map { ($0 - $1) * ($0 - $1) }.reduce(0, +))
    }

    private func lab(_ rgb: UInt32) -> [Double] {
        let linear = [rgb >> 16, rgb >> 8, rgb].map { channel -> Double in
            let c = Double(channel & 0xFF) / 255
            return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        let seen = matrix.map { row in min(1, max(0, zip(row, linear).map(*).reduce(0, +))) }
        let (r, g, b) = (seen[0], seen[1], seen[2])
        let x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047
        let y = 0.2126 * r + 0.7152 * g + 0.0722 * b
        let z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883
        let f = { (t: Double) in t > 0.008856 ? cbrt(t) : 7.787 * t + 16 / 116 }
        return [116 * f(y) - 16, 500 * (f(x) - f(y)), 200 * (f(y) - f(z))]
    }
}
