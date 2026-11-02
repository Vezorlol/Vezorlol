import Foundation

public enum GiftSource: String, Codable, Sendable { case caseOpen, market, craft, upgrade, coinflip, shop, daily, start }

public struct UniqueGift: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let collectionId: String
    public let number: Int
    public var modelId: String
    public var backdropId: String
    public var symbolId: String
    public var isCrafted: Bool
    public var craftRarity: CraftRarity?
    public var isUpgraded: Bool
    public var acquiredAt: Date
    public var acquiredPrice: Stars
    public var source: GiftSource

    public var displayTitle: String { "#\(number)" }
}

/// Экземпляр обычного (не коллекционного) подарка.
public struct RegularItem: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let giftId: String
    public var acquiredAt: Date
}

public enum AnyGift: Hashable, Sendable {
    case regular(RegularItem)
    case unique(UniqueGift)
    public var id: UUID {
        switch self { case .regular(let r): return r.id; case .unique(let u): return u.id }
    }
}

// MARK: - Номера

public struct NumberAllocator: Codable, Sendable {
    public var issued: [String: Set<Int>] = [:]
    public init() {}

    public mutating func allocate(collection: String, supply: Int, rng: RandomSource) -> Int {
        var set = issued[collection] ?? []
        defer { issued[collection] = set }
        if set.count >= supply { // тираж исчерпан — допускаем повтор, чтобы не блокировать игру
            return rng.nextInt(in: 1...supply)
        }
        for _ in 0..<64 {
            let n = rng.nextInt(in: 1...supply)
            if !set.contains(n) { set.insert(n); return n }
        }
        var n = rng.nextInt(in: 1...supply)
        while set.contains(n) { n = n % supply + 1 }
        set.insert(n)
        return n
    }
    public mutating func release(collection: String, number: Int) { issued[collection]?.remove(number) }
}

public enum NumberRarity {
    public static func isPretty(_ n: Int) -> Bool {
        if n == 777 || (n >= 1000 && n % 1000 == 0) { return true }
        let s = String(n)
        guard s.count >= 3 else { return false }
        if s == String(s.reversed()) { return true }
        return Set(s).count == 1
    }
}

// MARK: - Индекс коллекций

/// Детерминированный суточный индекс (раздел 8.2). Одинаков после переустановки.
public final class CollectionIndexService: @unchecked Sendable {
    public struct DayPoint: Sendable { public let index: Double; public let newBatch: Bool }
    private let rules: EconomyRules.CollectionIndex
    private let epoch: Date
    private var cache: [String: [DayPoint]] = [:]
    private let lock = NSLock()
    private static var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c
    }()

    public init(rules: EconomyRules) {
        self.rules = rules.collectionIndex
        let f = DateFormatter()
        f.calendar = Self.calendar; f.timeZone = Self.calendar.timeZone; f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyy-MM-dd"
        epoch = f.date(from: rules.collectionIndex.epochDate) ?? Date(timeIntervalSince1970: 1_767_225_600)
    }

    public func dayNumber(for date: Date) -> Int {
        max(0, Int(floor(date.timeIntervalSince(epoch) / 86_400)))
    }

    public func index(collection: Collection, day: Int) -> Double { point(collection: collection, day: day).index }
    public func index(collection: Collection, at date: Date) -> Double { index(collection: collection, day: dayNumber(for: date)) }
    public func point(collection: Collection, day: Int) -> DayPoint {
        lock.lock(); defer { lock.unlock() }
        var series = cache[collection.id] ?? [DayPoint(index: 1.0, newBatch: false)]
        while series.count <= day {
            let d = series.count
            let rng = SplitMix64(seed: stableHash64("\(collection.id)|\(d)"))
            let sigma = rules.sigma[collection.tier.rawValue] ?? 0.03
            var ln = log(series[d - 1].index)
            ln = ln * (1 - rules.reversion) + rules.drift + sigma * rng.nextNormal()
            var batch = false
            if rng.nextUnit() < rules.newBatchChance { ln += log(rules.newBatchFactor); batch = true }
            let v = min(rules.max, max(rules.min, exp(ln)))
            series.append(DayPoint(index: v, newBatch: batch))
        }
        cache[collection.id] = series
        return series[day]
    }
    /// Изменение за 24 часа в долях (0.03 = +3%).
    public func change24h(collection: Collection, day: Int) -> Double {
        guard day > 0 else { return 0 }
        return index(collection: collection, day: day) / index(collection: collection, day: day - 1) - 1
    }
    public func history(collection: Collection, endingAt day: Int, days: Int = 30) -> [Double] {
        let start = max(0, day - days + 1)
        return (start...day).map { index(collection: collection, day: $0) }
    }
}

// MARK: - Стоимость

public struct ValueCalculator: Sendable {
    public let rules: EconomyRules
    public let catalog: Catalog

    public init(catalog: Catalog, rules: EconomyRules) { self.catalog = catalog; self.rules = rules }

    private func step(_ steps: [[Double]], permille: Int, default def: Double = 1.0) -> Double {
        for s in steps where Double(permille) <= s[0] { return s[1] }
        return def
    }

    public func modelMultiplier(permille: Int) -> Double { step(rules.valueMultiplier.modelSteps, permille: permille) }
    public func backdropMultiplier(permille: Int) -> Double { step(rules.valueMultiplier.backdropSteps, permille: permille) }
    public func symbolMultiplier(permille: Int) -> Double {
        permille <= rules.valueMultiplier.rareSymbolPermille ? rules.valueMultiplier.rareSymbolMultiplier : 1.0
    }
    public func numberMultiplier(_ n: Int) -> Double {
        if n <= 10 { return rules.valueMultiplier.numberTop10 }
        if n <= 100 { return rules.valueMultiplier.numberTop100 }
        if NumberRarity.isPretty(n) { return rules.valueMultiplier.numberPretty }
        return 1.0
    }

    /// Суммарный множитель M по атрибутам (для неулучшенных не применяется).
    public func multiplier(of gift: UniqueGift) -> Decimal {
        let backdrop = AttributePools.backdrop(gift.backdropId)?.permille ?? 58
        let symbol = AttributePools.symbol(gift.symbolId)?.permille ?? 27
        let modelM: Double
        if gift.isCrafted, let r = gift.craftRarity,
           let o = rules.craft.outcomes.first(where: { $0.rarity == r }) {
            modelM = o.multiplier
        } else {
            modelM = modelMultiplier(permille: AttributePools.model(gift.modelId)?.permille ?? 175)
        }
        let product = dec(modelM) * dec(backdropMultiplier(permille: backdrop)) * dec(symbolMultiplier(permille: symbol)) * dec(numberMultiplier(gift.number))
        let cap = dec(gift.isCrafted ? rules.valueMultiplier.craftedCap : rules.valueMultiplier.cap)
        return max(1, min(cap, product))
    }

    public func value(of gift: UniqueGift, index: Double) -> Stars {
        guard let col = catalog.collection(gift.collectionId) else { return 0 }
        let idx = Decimal(Int((index * 10_000).rounded())) / 10_000
        if !gift.isUpgraded {
            return floorStars(Decimal(col.floor) * idx * dec(rules.unupgraded.valueFactor))
        }
        return floorStars(Decimal(col.floor) * idx * multiplier(of: gift))
    }

    /// Базовая цена без атрибутов («флор × индекс») — для кейсов, магазина, апгрейда.
    public func floorValue(of collection: Collection, index: Double) -> Stars {
        floorStars(Decimal(collection.floor) * (Decimal(Int((index * 10_000).rounded())) / 10_000))
    }
}

// MARK: - Фабрика

public struct GiftFactory: Sendable {
    public let catalog: Catalog
    public let rules: EconomyRules
    public init(catalog: Catalog, rules: EconomyRules) { self.catalog = catalog; self.rules = rules }

    public func makeUpgraded(collection: Collection, source: GiftSource, price: Stars, now: Date,
                             allocator: inout NumberAllocator, rng: RandomSource,
                             crafted: CraftRarity? = nil) -> UniqueGift {
        let model = AttributePools.models[AttributePools.modelTable.pick(rng)]
        let backdrop = AttributePools.backdrops[AttributePools.backdropTable.pick(rng)]
        let symbol = AttributePools.symbols[AttributePools.symbolTable.pick(rng)]
        let number = allocator.allocate(collection: collection.id, supply: rules.supply(of: collection.tier), rng: rng)
        return UniqueGift(id: UUID(), collectionId: collection.id, number: number, modelId: model.id,
                          backdropId: backdrop.id, symbolId: symbol.id, isCrafted: crafted != nil, craftRarity: crafted,
                          isUpgraded: true, acquiredAt: now, acquiredPrice: price, source: source)
    }

    public func makeUnupgraded(collection: Collection, source: GiftSource, price: Stars, now: Date,
                               allocator: inout NumberAllocator, rng: RandomSource) -> UniqueGift {
        let number = allocator.allocate(collection: collection.id, supply: rules.supply(of: collection.tier), rng: rng)
        return UniqueGift(id: UUID(), collectionId: collection.id, number: number, modelId: AttributePools.models.last!.id,
                          backdropId: AttributePools.backdrops.last!.id, symbolId: AttributePools.symbols.last!.id,
                          isCrafted: false, craftRarity: nil, isUpgraded: false, acquiredAt: now, acquiredPrice: price, source: source)
    }

    /// Улучшение: фиксирует случайные модель, фон, узор и новый номер.
    public func upgrade(_ gift: UniqueGift, allocator: inout NumberAllocator, rng: RandomSource) -> UniqueGift {
        guard let col = catalog.collection(gift.collectionId) else { return gift }
        allocator.release(collection: gift.collectionId, number: gift.number)
        var up = makeUpgraded(collection: col, source: gift.source, price: gift.acquiredPrice, now: gift.acquiredAt,
                              allocator: &allocator, rng: rng)
        up = UniqueGift(id: gift.id, collectionId: up.collectionId, number: up.number, modelId: up.modelId,
                        backdropId: up.backdropId, symbolId: up.symbolId, isCrafted: false, craftRarity: nil,
                        isUpgraded: true, acquiredAt: gift.acquiredAt, acquiredPrice: gift.acquiredPrice, source: gift.source)
        return up
    }
}
