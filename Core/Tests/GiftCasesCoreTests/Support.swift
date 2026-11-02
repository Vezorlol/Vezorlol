import Foundation
import XCTest
@testable import GiftCasesCore

enum T {
    static let catalog = try! Catalog.bundled()
    static let rules = try! EconomyRules.bundled()
    static var calc: ValueCalculator { ValueCalculator(catalog: catalog, rules: rules) }
    static let t0 = Date(timeIntervalSince1970: 1_793_000_000) // ноябрь 2026

    static func engine(seed: UInt64 = 1, now: Date = t0) -> (GameEngine, Box) {
        let box = Box(now)
        let e = GameEngine(catalog: catalog, rules: rules, clock: { box.now })
        e.rngOverride = SplitMix64(seed: seed)
        var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(identifier: "UTC")!
        e.calendar = cal
        return (e, box)
    }
}

final class Box { var now: Date; init(_ d: Date) { now = d } }

final class FakeMono: MonotonicClock, @unchecked Sendable {
    var value: TimeInterval
    init(_ v: TimeInterval) { value = v }
    func now() -> TimeInterval { value }
}

/// Источник с заданной последовательностью чисел.
final class ScriptedRandom: RandomSource {
    var values: [Double]; var i = 0
    init(_ v: [Double]) { values = v }
    func nextUnit() -> Double { defer { i += 1 }; return values[i % values.count] }
}
