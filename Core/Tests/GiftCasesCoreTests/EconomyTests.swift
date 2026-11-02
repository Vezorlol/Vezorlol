import XCTest
@testable import GiftCasesCore

final class EconomyTests: XCTestCase {
    func testCollectionIndexDeterministicAndBounded() {
        let a = CollectionIndexService(rules: T.rules), b = CollectionIndexService(rules: T.rules)
        for col in T.catalog.collectibles.prefix(30) {
            for day in stride(from: 0, through: 900, by: 7) {
                let x = a.index(collection: col, day: day)
                XCTAssertEqual(x, b.index(collection: col, day: day))
                XCTAssertTrue((0.5...2.0).contains(x))
            }
        }
        XCTAssertEqual(a.index(collection: T.catalog.collections0, day: 0), 1.0)
    }

    func testIndexVolatilityOrderedByTier() {
        let svc = CollectionIndexService(rules: T.rules)
        func vol(_ tier: Rarity) -> Double {
            let cols = T.catalog.collectibles.filter { $0.tier == tier }.prefix(8)
            var acc = 0.0, n = 0.0
            for c in cols { for d in 1..<400 { let r = log(svc.index(collection: c, day: d) / svc.index(collection: c, day: d - 1)); acc += r * r; n += 1 } }
            return (acc / n).squareRoot()
        }
        XCTAssertGreaterThan(vol(.common), vol(.legendary))
    }

    func testNewBatchEventsRare() {
        let svc = CollectionIndexService(rules: T.rules)
        var events = 0, total = 0
        for c in T.catalog.collectibles { for d in 1...365 { total += 1; if svc.point(collection: c, day: d).newBatch { events += 1 } } }
        XCTAssertEqual(Double(events) / Double(total), 0.01, accuracy: 0.003)
    }

    func testLevelsAndLimits() {
        let l = LevelService(catalog: T.catalog, rules: T.rules)
        XCTAssertEqual(l.maxBet(level: 1), 80)
        XCTAssertEqual(l.maxBet(level: 2), 124)
        XCTAssertEqual(l.maxBet(level: 25), 1_908_600)   // у максимального уровня — 20% его же порога
        XCTAssertTrue(l.isCaseUnlocked("case_1", level: 1))
        XCTAssertFalse(l.isCaseUnlocked("case_4", level: 3))
        XCTAssertTrue(l.isCaseUnlocked("case_4", level: 4))
        XCTAssertFalse(l.isCaseUnlocked("pepe", level: 15))
        XCTAssertTrue(l.isCaseUnlocked("pepe", level: 16))
        XCTAssertEqual(l.freeCaseId(level: 4), "case_1")
        XCTAssertEqual(l.freeCaseId(level: 5), "case_2")
    }

    func testPiggyCapsAndCarry() {
        let level = T.catalog.levels[0]  // 15/ч, лимит 8 ч
        var p = PiggyState(start: T.t0)
        let in3h = T.t0.addingTimeInterval(3 * 3600)
        XCTAssertEqual(floorStars(Piggy.accrued(p, now: in3h, level: level)), 45)
        let in20h = T.t0.addingTimeInterval(20 * 3600)
        XCTAssertEqual(floorStars(Piggy.accrued(p, now: in20h, level: level)), 120, "упирается в лимит 8 ч")
        XCTAssertEqual(Piggy.fill(p, now: in20h, level: level), 1)
        // дробная часть сохраняется
        let t = T.t0.addingTimeInterval(3600 * 0.5 + 1) // 7.5 + 0.004…
        XCTAssertEqual(Piggy.collect(&p, now: t, level: level), 7)
        XCTAssertGreaterThan(p.carry, 0.49)
        XCTAssertEqual(Piggy.secondsToFull(p, now: t, level: level), 8 * 3600 - 0, accuracy: 1)
    }

    func testPiggyEngineCollect() throws {
        let (e, box) = T.engine()
        box.now = T.t0.addingTimeInterval(4 * 3600)
        XCTAssertEqual(e.piggyAccrued(), 60)
        XCTAssertEqual(try e.collectPiggy(), 60)
        XCTAssertEqual(e.state.balance, 360)
        XCTAssertEqual(try e.collectPiggy(), 0)
    }

    func testDailyStreak() throws {
        let (e, box) = T.engine()
        let day: TimeInterval = 86_400
        XCTAssertEqual(try e.claimDaily().stars, 25)
        XCTAssertThrowsError(try e.claimDaily())
        box.now = box.now.addingTimeInterval(day)
        XCTAssertEqual(try e.claimDaily().stars, 50)
        box.now = box.now.addingTimeInterval(2 * day)   // пропуск → сброс
        XCTAssertEqual(try e.claimDaily().stars, 25)
        for expected in [50, 75, 100, 150, 200] as [Stars] {
            box.now = box.now.addingTimeInterval(day)
            XCTAssertEqual(try e.claimDaily().stars, expected)
        }
        box.now = box.now.addingTimeInterval(day)
        let tokens = e.state.freeCase.tokens
        let last = try e.claimDaily()
        XCTAssertEqual(last.stars, 300)
        XCTAssertEqual(last.freeCaseId, "case_2")
        XCTAssertEqual(e.state.freeCase.tokens, tokens + 1)
        box.now = box.now.addingTimeInterval(day)       // новый цикл
        XCTAssertEqual(try e.claimDaily().stars, 25)
    }

    func testDailyScalesWithLevel() {
        XCTAssertEqual(DailyBonus.reward(dayIndex: 0, level: 11, rules: T.rules).stars, 50)   // ×(1+0.1×10)=2
        XCTAssertEqual(DailyBonus.reward(dayIndex: 6, level: 6, rules: T.rules).stars, 450)
    }

    func testLevelDrivenByInventoryNotBalance() {
        let (e, _) = T.engine()
        e.debugGrant(5_000_000)
        XCTAssertEqual(e.currentLevel().level, 1)
        var s = e.state
        s.regulars = (0..<5).map { _ in RegularItem(id: UUID(), giftId: "diamond", acquiredAt: T.t0) } // 500
        e.replaceState(s)
        XCTAssertEqual(e.currentLevel().level, 2)
    }

    func testNumberAllocatorUnique() {
        var a = NumberAllocator()
        let rng = SplitMix64(seed: 1)
        var seen = Set<Int>()
        for _ in 0..<2_900 { XCTAssertTrue(seen.insert(a.allocate(collection: "x", supply: 3000, rng: rng)).inserted) }
    }

    func testStateCodableRoundTrip() throws {
        let (e, _) = T.engine()
        e.debugGrant(10_000)
        try e.openCase("case_2")
        let data = try JSONEncoder().encode(e.state)
        let back = try JSONDecoder().decode(GameState.self, from: data)
        XCTAssertEqual(back.balance, e.state.balance)
        XCTAssertEqual(back.uniques.count + back.regulars.count, 1)
    }
}

extension Catalog { var collections0: GiftCollection { collectibles[0] } }
