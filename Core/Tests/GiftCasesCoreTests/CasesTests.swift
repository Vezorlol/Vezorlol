import XCTest
@testable import GiftCasesCore

final class CasesTests: XCTestCase {
    /// Средняя стоимость экземпляра по плану баланса: флор × avgAttributeMultiplier, обычные — по цене.
    private func expectedValue(_ item: String) -> Double {
        switch T.catalog.resolve(item)! {
        case .regular(let r): return Double(r.price)
        case .collection(let c): return Double(c.floor) * T.catalog.meta.avgAttributeMultiplier
        }
    }

    func testAnalyticRTPMatchesTarget() {
        for c in T.catalog.cases {
            let ev = c.drops.reduce(0.0) { $0 + $1.chancePercent / 100 * expectedValue($1.item) }
            let rtp = ev / Double(c.price)
            XCTAssertEqual(rtp, c.targetRTP, accuracy: 0.015, "\(c.id) analytic RTP=\(rtp)")
        }
    }

    func testMonteCarloRTP_1MPerCase() {
        for c in T.catalog.cases {
            let table = WeightedTable(weights: c.drops.map(\.chancePercent))
            let values = c.drops.map { expectedValue($0.item) }
            let rng = SplitMix64(seed: stableHash64(c.id))
            var total = 0.0
            let n = 1_000_000
            for _ in 0..<n { total += values[table.pick(rng)] }
            let rtp = total / Double(n) / Double(c.price)
            XCTAssertEqual(rtp, c.targetRTP, accuracy: 0.015, "\(c.id) MC RTP=\(rtp)")
        }
    }

    func testRealizedMultiplierWithinTarget() {
        // 100 000 экземпляров на коллекцию-представителя каждого тира (полный проход по 124 — в testAllCollectionsAverageM).
        let reps = ["plush_pepe", "scared_cat", "ion_gem", "lucky_locket", "snake_box"]
        let factory = GiftFactory(catalog: T.catalog, rules: T.rules)
        for id in reps {
            let col = T.catalog.collection(id)!
            let rng = SplitMix64(seed: 42)
            var alloc = NumberAllocator()
            var sum = Decimal(0)
            let n = 100_000
            for _ in 0..<n {
                alloc = NumberAllocator() // номера не мешают друг другу в статистике
                sum += T.calc.multiplier(of: factory.makeUpgraded(collection: col, source: .caseOpen, price: 0, now: T.t0, allocator: &alloc, rng: rng))
            }
            let avg = NSDecimalNumber(decimal: sum / Decimal(n)).doubleValue
            XCTAssertTrue((1.18...1.30).contains(avg), "\(id) avg M = \(avg)")
        }
    }

    func testAllCollectionsAverageM() {
        let factory = GiftFactory(catalog: T.catalog, rules: T.rules)
        for col in T.catalog.collectibles {
            let rng = SplitMix64(seed: stableHash64(col.id))
            var sum = Decimal(0)
            let n = 8_000
            for _ in 0..<n {
                var alloc = NumberAllocator()
                sum += T.calc.multiplier(of: factory.makeUpgraded(collection: col, source: .caseOpen, price: 0, now: T.t0, allocator: &alloc, rng: rng))
            }
            let avg = NSDecimalNumber(decimal: sum / Decimal(n)).doubleValue
            XCTAssertTrue((1.15...1.33).contains(avg), "\(col.id) avg M = \(avg)")
        }
    }

    func testMultiplierRules() {
        let c = T.calc
        XCTAssertEqual(c.modelMultiplier(permille: 2), 3.0)
        XCTAssertEqual(c.modelMultiplier(permille: 5), 1.6)
        XCTAssertEqual(c.modelMultiplier(permille: 8), 1.25)
        XCTAssertEqual(c.modelMultiplier(permille: 10), 1.1)
        XCTAssertEqual(c.modelMultiplier(permille: 20), 1.0)
        XCTAssertEqual(c.backdropMultiplier(permille: 10), 1.5)
        XCTAssertEqual(c.backdropMultiplier(permille: 15), 1.05)
        XCTAssertEqual(c.backdropMultiplier(permille: 20), 1.0)
        XCTAssertEqual(c.numberMultiplier(7), 5.0)
        XCTAssertEqual(c.numberMultiplier(50), 1.5)
        XCTAssertEqual(c.numberMultiplier(777), 1.3)
        XCTAssertEqual(c.numberMultiplier(12321), 1.3)
        XCTAssertEqual(c.numberMultiplier(12345), 1.0)
    }

    func testValueCapAndUnupgraded() {
        let col = T.catalog.collection("plush_pepe")!
        let rarestModel = AttributePools.models(col.id).min { $0.permille < $1.permille }!
        let rarestBackdrop = AttributePools.backdrops.min { $0.permille < $1.permille }!
        let best = UniqueGift(id: UUID(), collectionId: col.id, number: 1, modelId: rarestModel.id, backdropId: rarestBackdrop.id, symbolId: "s0",
                              isCrafted: false, craftRarity: nil, isUpgraded: true, acquiredAt: T.t0, acquiredPrice: 0, source: .caseOpen)
        let m = T.calc.multiplier(of: best)
        XCTAssertGreaterThan(m, 5)
        XCTAssertLessThanOrEqual(m, 12)                      // M ограничен 12
        XCTAssertEqual(T.calc.value(of: best, index: 1.0), floorStars(Decimal(col.floor) * m))
        var raw = best; raw.isUpgraded = false
        XCTAssertEqual(T.calc.value(of: raw, index: 1.0), col.floor / 2)
    }

    func testOpenCaseDeductsPriceAndAddsItem() throws {
        let (e, _) = T.engine()
        e.debugGrant(1000)
        let before = e.state.balance
        let r = try e.openCase("case_1")
        XCTAssertEqual(e.state.balance, before - 25)
        XCTAssertEqual(e.inventory.count, 1)
        XCTAssertEqual(e.inventory[0].id, r.gift.id)
        XCTAssertEqual(e.state.stats.casesOpened, 1)
    }

    func testCannotOpenWithoutFundsOrLockedCase() {
        let (e, _) = T.engine()
        try? e.openCase("case_3")                         // 300 → ~51
        let low = e.state.balance
        XCTAssertThrowsError(try e.openCase("case_3")) { XCTAssertEqual($0 as? GameError, .insufficientFunds) }
        XCTAssertEqual(e.state.balance, low, "неудачная операция не меняет баланс")
        e.debugGrant(1_000_000)
        XCTAssertThrowsError(try e.openCase("case_4")) { XCTAssertEqual($0 as? GameError, .caseLocked(requiredLevel: 4)) }
        XCTAssertEqual(e.state.balance, low + 1_000_000)
    }

    func testFreeCaseTokenAndTimer() throws {
        let (e, box) = T.engine()
        try e.openFreeCase(.token)
        XCTAssertThrowsError(try e.openFreeCase(.token))
        try e.openFreeCase(.timer)
        XCTAssertThrowsError(try e.openFreeCase(.timer))
        box.now = box.now.addingTimeInterval(24 * 3600 + 1)
        XCTAssertNoThrow(try e.openFreeCase(.timer))
        XCTAssertEqual(e.state.balance, 300, "бесплатные кейсы не списывают звёзды")
    }

    func testSellRates() throws {
        let (e, _) = T.engine()
        e.rngOverride = ScriptedRandom([0.0]) // первый дроп кейса_1 = Сердце
        e.debugGrant(100)
        let r = try e.openCase("case_1")
        let bal = e.state.balance
        let got = try e.sell(ids: [r.gift.id])
        XCTAssertEqual(got, 13)
        XCTAssertEqual(e.state.balance, bal + 13)
        XCTAssertTrue(e.inventory.isEmpty)
    }
}
