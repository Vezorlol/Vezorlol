import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Уровни и лимиты

public struct LevelService: Sendable {
    public let catalog: Catalog
    public let rules: EconomyRules
    public init(catalog: Catalog, rules: EconomyRules) { self.catalog = catalog; self.rules = rules }

    public func level(forInventoryValue v: Stars) -> LevelDef { catalog.level(for: v) }

    /// max(50, 20% от порога следующего уровня).
    public func maxBet(level: Int) -> Stars {
        let current = catalog.levels.first(where: { $0.level == level }) ?? catalog.levels[0]
        let next = catalog.nextLevel(after: level)?.inventoryValueFrom ?? current.inventoryValueFrom
        let byFraction = floorStars(Decimal(next) * dec(rules.bets.fractionOfNextLevel))
        return max(rules.bets.floor, byFraction)
    }
    public func isCaseUnlocked(_ caseId: String, level: Int) -> Bool { level >= rules.unlockLevel(forCase: caseId) }
    public func freeCaseId(level: Int) -> String {
        rules.freeCase.tiers.filter { $0.fromLevel <= level }.max(by: { $0.fromLevel < $1.fromLevel })?.caseId ?? rules.startFreeCaseId
    }
    /// Прогресс к следующему уровню 0...1.
    public func progress(inventoryValue v: Stars) -> Double {
        let cur = level(forInventoryValue: v)
        guard let next = catalog.nextLevel(after: cur.level) else { return 1 }
        let span = Double(next.inventoryValueFrom - cur.inventoryValueFrom)
        return min(1, max(0, Double(v - cur.inventoryValueFrom) / span))
    }
}

// MARK: - Копилка

public struct PiggyState: Codable, Sendable {
    public var lastCollectAt: Date
    public var carry: Decimal      // дробные звёзды
    public init(start: Date) { lastCollectAt = start; carry = 0 }
}

public enum Piggy {
    public static func accrued(_ s: PiggyState, now: Date, level: LevelDef) -> Decimal {
        let hours = max(0, now.timeIntervalSince(s.lastCollectAt)) / 3600
        let capped = min(hours, Double(level.accrualCapHours))
        return s.carry + Decimal(level.incomePerHour) * dec(capped)
    }
    public static func fill(_ s: PiggyState, now: Date, level: LevelDef) -> Double {
        let hours = max(0, now.timeIntervalSince(s.lastCollectAt)) / 3600
        return min(1, hours / Double(level.accrualCapHours))
    }
    public static func secondsToFull(_ s: PiggyState, now: Date, level: LevelDef) -> TimeInterval {
        max(0, Double(level.accrualCapHours) * 3600 - max(0, now.timeIntervalSince(s.lastCollectAt)))
    }
    public static func collect(_ s: inout PiggyState, now: Date, level: LevelDef) -> Stars {
        let total = accrued(s, now: now, level: level)
        let whole = floorStars(total)
        s.carry = total - Decimal(whole)
        s.lastCollectAt = max(now, s.lastCollectAt)
        return whole
    }
}

// MARK: - Ежедневный бонус и бесплатный кейс

public struct DailyState: Codable, Sendable {
    public var lastClaimDay: Int?
    public var streak: Int = 0        // сколько дней подряд собрано (0...7)
    public init() {}
}

public struct DailyReward: Sendable {
    public let dayIndex: Int          // 0...6
    public let stars: Stars
    public let freeCaseId: String?
}

public enum DailyBonus {
    public static func dayNumber(_ date: Date, calendar: Calendar) -> Int {
        let start = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: Date(timeIntervalSince1970: 0), to: start).day ?? 0
    }

    /// Индекс дня серии, который можно забрать сейчас; nil — сегодня уже забрано.
    public static func availableDay(_ s: DailyState, today: Int) -> Int? {
        guard let last = s.lastClaimDay else { return 0 }
        if last >= today { return nil }
        return last == today - 1 ? s.streak % 7 : 0
    }

    public static func reward(dayIndex: Int, level: Int, rules: EconomyRules) -> DailyReward {
        let base = rules.dailyBonus.rewards[min(dayIndex, rules.dailyBonus.rewards.count - 1)]
        let mult = 1 + rules.dailyBonus.levelBonusPerLevel * Double(max(0, level - 1))
        let isLast = dayIndex == rules.dailyBonus.rewards.count - 1
        return DailyReward(dayIndex: dayIndex, stars: floorStars(Decimal(base) * dec(mult)),
                           freeCaseId: isLast ? rules.dailyBonus.finalDayCaseId : nil)
    }

    public static func claim(_ s: inout DailyState, today: Int) {
        guard let day = availableDay(s, today: today) else { return }
        s.streak = day + 1
        s.lastClaimDay = today
    }
}

public struct FreeCaseState: Codable, Sendable {
    public var lastOpenAt: Date?
    public var tokens: Int
    public init(tokens: Int) { self.tokens = tokens }
}

// MARK: - Защита времени

public struct TrustedTimeState: Codable, Sendable {
    public var lastTrusted: Date
    public var monotonicAtTrusted: TimeInterval
    /// После перезагрузки с отставшими системными часами время заморожено до догона.
    public var frozen: Bool = false
    public init(lastTrusted: Date, monotonicAtTrusted: TimeInterval, frozen: Bool = false) {
        self.lastTrusted = lastTrusted; self.monotonicAtTrusted = monotonicAtTrusted; self.frozen = frozen
    }
}

public protocol MonotonicClock: Sendable { func now() -> TimeInterval }

public struct SystemMonotonicClock: MonotonicClock {
    public init() {}
    public func now() -> TimeInterval {
        var ts = timespec()
        #if canImport(Darwin)
        clock_gettime(CLOCK_MONOTONIC_RAW, &ts)   // идёт и во сне, обнуляется при перезагрузке
        #else
        clock_gettime(CLOCK_BOOTTIME, &ts)
        #endif
        return TimeInterval(ts.tv_sec) + TimeInterval(ts.tv_nsec) / 1e9
    }
}

/// Доверенное время: якорь — время из HTTPS-заголовка `Date`, дальше идёт по монотонным часам.
/// Перевод системных часов не влияет. После перезагрузки (монотонные часы обнулились) берём
/// системное время, только если оно не раньше последнего доверенного; иначе начисления заморожены.
public final class TrustedClock: @unchecked Sendable {
    public private(set) var state: TrustedTimeState
    private let mono: MonotonicClock
    private let device: @Sendable () -> Date
    private let lock = NSLock()

    public init(state: TrustedTimeState?, monotonic: MonotonicClock = SystemMonotonicClock(),
                device: @escaping @Sendable () -> Date = { Date() }) {
        self.mono = monotonic; self.device = device
        self.state = state ?? TrustedTimeState(lastTrusted: device(), monotonicAtTrusted: monotonic.now())
    }

    public func now() -> Date {
        lock.lock(); defer { lock.unlock() }
        let m = mono.now()
        if !state.frozen && m >= state.monotonicAtTrusted {
            return state.lastTrusted.addingTimeInterval(m - state.monotonicAtTrusted)
        }
        // Перезагрузка (монотонные часы обнулились) либо время уже заморожено: ждём, пока системные часы догонят.
        let d = device()
        if d >= state.lastTrusted {
            state = TrustedTimeState(lastTrusted: d, monotonicAtTrusted: m)
            return d
        }
        state = TrustedTimeState(lastTrusted: state.lastTrusted, monotonicAtTrusted: m, frozen: true)
        return state.lastTrusted
    }

    /// Сверка с сетью: сетевое время — источник истины.
    public func sync(networkDate: Date) {
        lock.lock(); defer { lock.unlock() }
        let m = mono.now()
        state = TrustedTimeState(lastTrusted: networkDate, monotonicAtTrusted: m)
    }

    /// HEAD-запрос к HTTPS-сайту, заголовок `Date`. Вызывать при запуске.
    public static func fetchNetworkDate(url: URL = URL(string: "https://www.apple.com")!) async -> Date? {
        var req = URLRequest(url: url); req.httpMethod = "HEAD"; req.timeoutInterval = 5
        guard let (_, resp) = try? await URLSession.shared.data(for: req),
              let http = resp as? HTTPURLResponse, let h = http.value(forHTTPHeaderField: "Date") else { return nil }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX"); f.timeZone = TimeZone(identifier: "GMT")
        f.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        return f.date(from: h)
    }
}
