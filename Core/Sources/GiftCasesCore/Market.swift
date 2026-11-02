import Foundation

public struct MarketLot: Identifiable, Hashable, Sendable {
    public let id: String
    public let gift: UniqueGift
    public let price: Stars
    public let value: Stars
}

public struct ShopSlot: Identifiable, Hashable, Sendable {
    public let id: String            // "<day>|<collectionId>"
    public let collection: GiftCollection
    public let price: Stars          // 0.5 × флор
    public let upgradeCost: Stars    // 0.6 × флор
    public let stock: Int
}

public struct MarketService: Sendable {
    public let catalog: Catalog
    public let rules: EconomyRules
    public let levels: LevelService
    public let calc: ValueCalculator
    public let index: CollectionIndexService
    public let factory: GiftFactory

    public init(catalog: Catalog, rules: EconomyRules, index: CollectionIndexService) {
        self.catalog = catalog; self.rules = rules
        self.levels = LevelService(catalog: catalog, rules: rules)
        self.calc = ValueCalculator(catalog: catalog, rules: rules)
        self.index = index
        self.factory = GiftFactory(catalog: catalog, rules: rules)
    }

    /// Коллекции, доступные по уровню: флор ≤ max(minFloor, 35% порога следующего уровня).
    public func accessibleCollections(level: Int) -> [GiftCollection] {
        let current = catalog.levels.first(where: { $0.level == level }) ?? catalog.levels[0]
        let next = catalog.nextLevel(after: level)?.inventoryValueFrom ?? current.inventoryValueFrom
        let limit = max(rules.market.accessMinFloor, floorStars(Decimal(next) * dec(rules.market.accessFractionOfNextLevel)))
        let list = catalog.collectibles.filter { $0.floor <= limit }
        return list.isEmpty ? [catalog.collectibles.min(by: { $0.floor < $1.floor })!] : list
    }

    public func hourKey(_ now: Date) -> Int { Int(floor(now.timeIntervalSince1970 / 3600)) }
    public func dayKey(_ now: Date) -> Int { index.dayNumber(for: now) }

    /// 20 лотов, обновление каждый час; seed детерминирован по часу и уровню.
    public func lots(now: Date, level: Int) -> [MarketLot] {
        let hour = hourKey(now), day = dayKey(now)
        let rng = SplitMix64(seed: stableHash64("market|\(hour)|\(level)"))
        let pool = accessibleCollections(level: level)
        var out: [MarketLot] = []
        for i in 0..<rules.market.lots {
            let col = pool[rng.nextInt(pool.count)]
            var tmp = NumberAllocator()
            var gift = factory.makeUpgraded(collection: col, source: .market, price: 0, now: now, allocator: &tmp, rng: rng)
            let idBytes = rng.nextUInt64()
            gift = UniqueGift(id: Self.uuid(from: idBytes, salt: UInt64(i)), collectionId: gift.collectionId, number: gift.number,
                              modelId: gift.modelId, backdropId: gift.backdropId, symbolId: gift.symbolId,
                              isCrafted: false, craftRarity: nil, isUpgraded: true, acquiredAt: now, acquiredPrice: 0, source: .market)
            let value = calc.value(of: gift, index: index.index(collection: col, day: day))
            let markup = rng.nextDouble(in: rules.market.markupMin...rules.market.markupMax)
            let price = max(1, floorStars(Decimal(value) * dec(markup)))
            out.append(MarketLot(id: "\(hour)|\(level)|\(i)", gift: gift, price: price, value: value))
        }
        return out.sorted { $0.price < $1.price }
    }

    /// Магазин неулучшенных подарков: 6 слотов в сутки.
    public func shop(now: Date, level: Int) -> [ShopSlot] {
        let day = dayKey(now)
        let rng = SplitMix64(seed: stableHash64("shop|\(day)|\(level)"))
        var pool = accessibleCollections(level: level)
        var slots: [ShopSlot] = []
        for _ in 0..<min(rules.unupgraded.shopSlots, pool.count) {
            let i = rng.nextInt(pool.count)
            let col = pool.remove(at: i)
            slots.append(ShopSlot(id: "\(day)|\(col.id)", collection: col,
                                  price: max(1, floorStars(Decimal(col.floor) * dec(rules.unupgraded.shopPriceFactor))),
                                  upgradeCost: max(1, floorStars(Decimal(col.floor) * dec(rules.unupgraded.upgradeCostFactor))),
                                  stock: rules.unupgraded.stockPerSlot))
        }
        return slots.sorted { $0.price < $1.price }
    }

    static func uuid(from value: UInt64, salt: UInt64) -> UUID {
        let a = SplitMix64(seed: value ^ (salt &* 0x9E37_79B9_7F4A_7C15))
        let x = a.nextUInt64(), y = a.nextUInt64()
        var b = [UInt8](repeating: 0, count: 16)
        for i in 0..<8 { b[i] = UInt8((x >> (8 * UInt64(i))) & 0xff); b[8 + i] = UInt8((y >> (8 * UInt64(i))) & 0xff) }
        return UUID(uuid: (b[0], b[1], b[2], b[3], b[4], b[5], b[6], b[7], b[8], b[9], b[10], b[11], b[12], b[13], b[14], b[15]))
    }
}
