import Foundation

public typealias Stars = Int64

@inline(__always) func dec(_ value: Double) -> Decimal { Decimal(string: String(value)) ?? Decimal(value) }

/// Округление Decimal вниз до целых звёзд.
public func floorStars(_ value: Decimal) -> Stars {
    var v = value
    var r = Decimal()
    NSDecimalRound(&r, &v, 0, .down)
    return NSDecimalNumber(decimal: r).int64Value
}

public enum StarsFormat {
    /// «12 450»: разделитель тысяч — пробел.
    public static func string(_ value: Stars) -> String {
        let negative = value < 0
        let digits = String(abs(value))
        var out = ""
        for (i, ch) in digits.reversed().enumerated() {
            if i > 0 && i % 3 == 0 { out.append("\u{00A0}") }
            out.append(ch)
        }
        return (negative ? "-" : "") + String(out.reversed())
    }
    public static func withStar(_ value: Stars) -> String { string(value) + " ⭐" }
}
