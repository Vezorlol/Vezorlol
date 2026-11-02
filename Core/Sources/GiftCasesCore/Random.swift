import Foundation

/// Источник случайных чисел. Подменяется в тестах; в игре — `FairStream` (provably fair).
public protocol RandomSource: AnyObject {
    /// Равномерное число в [0, 1).
    func nextUnit() -> Double
}

public extension RandomSource {
    func nextInt(_ upperBound: Int) -> Int {
        precondition(upperBound > 0)
        return min(upperBound - 1, Int(nextUnit() * Double(upperBound)))
    }
    func nextInt(in range: ClosedRange<Int>) -> Int {
        range.lowerBound + nextInt(range.upperBound - range.lowerBound + 1)
    }
    func nextDouble(in range: ClosedRange<Double>) -> Double {
        range.lowerBound + nextUnit() * (range.upperBound - range.lowerBound)
    }
    /// Стандартное нормальное N(0,1), Box–Muller.
    func nextNormal() -> Double {
        let u1 = max(nextUnit(), 1e-12)
        let u2 = nextUnit()
        return (-2.0 * log(u1)).squareRoot() * cos(2.0 * Double.pi * u2)
    }
}

/// Детерминированный SplitMix64 (тесты, индекс коллекций, лоты бота).
public final class SplitMix64: RandomSource {
    private var state: UInt64
    public init(seed: UInt64) { state = seed }
    public func nextUInt64() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
    public func nextUnit() -> Double { Double(nextUInt64() >> 11) / 9_007_199_254_740_992.0 }
}

public final class SystemRandomSource: RandomSource {
    private var generator = SystemRandomNumberGenerator()
    public init() {}
    public func nextUnit() -> Double { Double.random(in: 0..<1, using: &generator) }
}

/// Стабильный (не зависящий от запуска, в отличие от Hasher) 64-битный хеш FNV-1a.
public func stableHash64(_ string: String) -> UInt64 {
    var hash: UInt64 = 0xcbf2_9ce4_8422_2325
    for byte in string.utf8 {
        hash ^= UInt64(byte)
        hash = hash &* 0x0000_0100_0000_01B3
    }
    return hash
}

/// Таблица взвешенного выбора (бинарный поиск по накопленным весам).
public struct WeightedTable: Sendable {
    private let cumulative: [Double]
    public let total: Double
    public init(weights: [Double]) {
        precondition(!weights.isEmpty)
        var acc = 0.0
        cumulative = weights.map { acc += $0; return acc }
        total = acc
    }
    public var count: Int { cumulative.count }
    public func index(for unit: Double) -> Int {
        let target = unit * total
        var lo = 0, hi = cumulative.count - 1
        while lo < hi {
            let mid = (lo + hi) / 2
            if cumulative[mid] > target { hi = mid } else { lo = mid + 1 }
        }
        return lo
    }
    public func pick(_ rng: RandomSource) -> Int { index(for: rng.nextUnit()) }
}
