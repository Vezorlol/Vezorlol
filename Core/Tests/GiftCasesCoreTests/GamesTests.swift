import XCTest
@testable import GiftCasesCore

final class GamesTests: XCTestCase {
    func testCrashRTP_1MRounds() {
        let rng = SplitMix64(seed: 7)
        let n = 1_000_000
        for target in [1.5, 2.0, 5.0, 10.0] {
            var returned = 0.0
            for _ in 0..<n where GameMath.crashPoint(unit: rng.nextUnit(), rules: T.rules) >= target { returned += target }
            XCTAssertEqual(returned / Double(n), 0.96, accuracy: 0.005, "auto ×\(target)")
        }
    }

    func testCrashPointBounds() {
        XCTAssertEqual(GameMath.crashPoint(unit: 0, rules: T.rules), 1.0)
        XCTAssertEqual(GameMath.crashPoint(unit: 0.999999999, rules: T.rules), 1000)
        XCTAssertEqual(GameMath.crashPoint(unit: 0.5, rules: T.rules), 1.92, accuracy: 1e-9)
    }

    func testCrashPayoutRoundsDown() {
        XCTAssertEqual(GameMath.crashPayout(bet: 100, multiplier: 2.019), 201)  // 2.019 → 2.01
        XCTAssertEqual(GameMath.crashPayout(bet: 77, multiplier: 1.5), 115)
    }

    func testCoinFlipStarsRTP() {
        let rng = SplitMix64(seed: 3)
        var returned: Double = 0
        let n = 1_000_000, bet: Stars = 1000
        for _ in 0..<n where GameMath.coinSide(unit: rng.nextUnit()) == .star { returned += Double(GameMath.coinFlipPayout(bet: bet, rules: T.rules)) }
        XCTAssertEqual(returned / Double(n) / Double(bet), 0.97, accuracy: 0.005)
    }

    func testGiftModeRTP() {
        let p = GameMath.giftModeWinChance(rules: T.rules)
        let avg = (T.rules.coinFlip.giftMinFraction + T.rules.coinFlip.giftMaxFraction) / 2
        XCTAssertEqual(p * (1 + avg), 0.96, accuracy: 1e-9)
    }

    func testUpgradeChance() {
        XCTAssertEqual(GameMath.upgradeChance(stake: 100, target: 200, rules: T.rules), 0.46, accuracy: 1e-9)
        XCTAssertEqual(GameMath.upgradeChance(stake: 100, target: 120, rules: T.rules), 0.75, accuracy: 1e-9) // потолок 75%
        // RTP 92% при шансе без потолка
        let rng = SplitMix64(seed: 5)
        var returned = 0.0; let n = 1_000_000
        let chance = GameMath.upgradeChance(stake: 100, target: 400, rules: T.rules)
        for _ in 0..<n where rng.nextUnit() < chance { returned += 400 }
        XCTAssertEqual(returned / Double(n) / 100, 0.92, accuracy: 0.015)
    }

    func testCraftDistribution() {
        XCTAssertEqual(GameMath.craftExpectedMultiplier(rules: T.rules), 3.28, accuracy: 1e-9)
        let rng = SplitMix64(seed: 9)
        var counts: [CraftRarity: Int] = [:]
        let n = 500_000
        for _ in 0..<n { counts[GameMath.craftRarity(unit: rng.nextUnit(), rules: T.rules), default: 0] += 1 }
        for o in T.rules.craft.outcomes {
            XCTAssertEqual(Double(counts[o.rarity] ?? 0) / Double(n), o.chance, accuracy: 0.005, o.rarity.rawValue)
        }
    }

    // MARK: Engine

    func testCoinFlipStarsEngine() throws {
        let (e, _) = T.engine()
        e.rngOverride = ScriptedRandom([0.1])  // .star
        let win = try e.coinFlipStars(bet: 50, pick: .star)
        XCTAssertTrue(win.won)
        XCTAssertEqual(e.state.balance, 300 - 50 + 97)
        e.rngOverride = ScriptedRandom([0.9])
        let lose = try e.coinFlipStars(bet: 50, pick: .star)
        XCTAssertFalse(lose.won)
        XCTAssertEqual(e.state.balance, 300 - 50 + 97 - 50)
    }

    func testBetLimits() {
        let (e, _) = T.engine()
        e.debugGrant(10_000)
        XCTAssertThrowsError(try e.coinFlipStars(bet: 5, pick: .star)) { XCTAssertEqual($0 as? GameError, .betTooSmall(min: 10)) }
        XCTAssertThrowsError(try e.coinFlipStars(bet: 81, pick: .star)) { XCTAssertEqual($0 as? GameError, .overLimit(max: 80)) }
        XCTAssertThrowsError(try e.startCrash(bet: 500, autoCashout: nil))
        XCTAssertEqual(e.state.balance, 10_300)
        XCTAssertEqual(T.engine().0.maxBet(), 80)   // ур.1: 20% от 400
    }

    func testCrashFlowManualCashout() throws {
        let (e, box) = T.engine()
        e.rngOverride = ScriptedRandom([0.9])       // crash = 9.60
        let cr = try e.startCrash(bet: 50, autoCashout: nil)
        XCTAssertEqual(cr.crashPoint, 9.6, accuracy: 1e-9)
        XCTAssertEqual(e.state.balance, 250)
        XCTAssertThrowsError(try e.startCrash(bet: 10, autoCashout: nil)) // один раунд
        box.now = cr.startedAt.addingTimeInterval(GameMath.crashTime(forMultiplier: 2.0, rules: T.rules) + 0.001)
        XCTAssertNil(try e.advanceCrash())
        guard case .won(let m, let payout) = try e.cashOutCrash() else { return XCTFail() }
        XCTAssertGreaterThanOrEqual(m, 2.0)
        XCTAssertEqual(payout, GameMath.crashPayout(bet: 50, multiplier: m))
        XCTAssertEqual(e.state.balance, 250 + payout)
        XCTAssertNil(e.state.activeCrash)
        XCTAssertEqual(e.state.fair.history.first?.game, "crash")
    }

    func testCrashAutoCashoutAfterBackground() throws {
        let (e, box) = T.engine()
        e.rngOverride = ScriptedRandom([0.9])       // crash 9.60
        let cr = try e.startCrash(bet: 50, autoCashout: 3.0)
        box.now = cr.startedAt.addingTimeInterval(10_000) // приложение долго было свёрнуто
        let out = try e.advanceCrash()
        XCTAssertEqual(out, .won(multiplier: 3.0, payout: 150))
        XCTAssertEqual(e.state.balance, 250 + 150)
    }

    func testCrashLossWhenAutoAboveCrash() throws {
        let (e, box) = T.engine()
        e.rngOverride = ScriptedRandom([0.5])       // crash 1.92
        let cr = try e.startCrash(bet: 50, autoCashout: 5.0)
        box.now = cr.startedAt.addingTimeInterval(10_000)
        XCTAssertEqual(try e.advanceCrash(), .lost(crashPoint: 1.92))
        XCTAssertEqual(e.state.balance, 250)
        XCTAssertEqual(e.state.stats.totalLost, 50)
    }

    func testCraftNeedsSameCollection() throws {
        let (e, _) = T.engine(seed: 11)
        let f = GiftFactory(catalog: T.catalog, rules: T.rules)
        let a = T.catalog.collection("snake_box")!, b = T.catalog.collection("ice_cream")!
        var s = e.state
        let g1 = f.makeUpgraded(collection: a, source: .caseOpen, price: 0, now: T.t0, allocator: &s.allocator, rng: e.rngOverride!)
        let g2 = f.makeUpgraded(collection: a, source: .caseOpen, price: 0, now: T.t0, allocator: &s.allocator, rng: e.rngOverride!)
        let g3 = f.makeUpgraded(collection: a, source: .caseOpen, price: 0, now: T.t0, allocator: &s.allocator, rng: e.rngOverride!)
        let other = f.makeUpgraded(collection: b, source: .caseOpen, price: 0, now: T.t0, allocator: &s.allocator, rng: e.rngOverride!)
        s.uniques = [g1, g2, g3, other]
        e.replaceState(s)
        XCTAssertThrowsError(try e.craft(ids: [g1.id, g2.id, other.id])) { XCTAssertEqual($0 as? GameError, .invalidSelection) }
        XCTAssertEqual(e.state.uniques.count, 4, "при ошибке подарки не сгорают")
        e.rngOverride = ScriptedRandom([0.99])      // legendary
        let out = try e.craft(ids: [g1.id, g2.id, g3.id])
        XCTAssertEqual(out.craftRarity, .legendary)
        XCTAssertTrue(out.isCrafted)
        XCTAssertEqual(e.state.uniques.count, 2)
    }

    func testMarketIsDeterministicAndBuyingWorks() throws {
        let (e, _) = T.engine()
        let a = e.marketLots(), b = e.marketLots()
        XCTAssertEqual(a.count, 20)
        XCTAssertEqual(a.map(\.id), b.map(\.id))
        XCTAssertEqual(a.map(\.price), b.map(\.price))
        for lot in a { XCTAssertGreaterThanOrEqual(Double(lot.price), Double(lot.value) * 1.03 - 1) }
        e.debugGrant(1_000_000)
        let lot = a[0]
        let before = e.state.balance
        let g = try e.buyLot(lot.id)
        XCTAssertEqual(e.state.balance, before - lot.price)
        XCTAssertEqual(g.id, lot.gift.id)
        XCTAssertFalse(e.marketLots().contains { $0.id == lot.id })
        XCTAssertThrowsError(try e.buyLot(lot.id))
        // купил-продал — в минус
        let sold = try e.sell(ids: [g.id])
        XCTAssertLessThan(sold, lot.price)
    }

    func testShopAndUpgradeGift() throws {
        let (e, _) = T.engine()
        e.debugGrant(1_000_000)
        let slot = e.shopSlots()[0]
        let g = try e.buyShopItem(slot.id)
        XCTAssertFalse(g.isUpgraded)
        XCTAssertEqual(g.collectionId, slot.collection.id)
        XCTAssertEqual(e.shopSlots().first { $0.id == slot.id }?.stock, 9)
        let cost = e.upgradeCost(of: g)
        let before = e.state.balance
        let up = try e.upgradeGift(id: g.id)
        XCTAssertTrue(up.isUpgraded)
        XCTAssertEqual(e.state.balance, before - cost)
        XCTAssertThrowsError(try e.upgradeGift(id: g.id))
    }

    func testUpgradeGameRequiresRatioAndBurnsStake() throws {
        let (e, _) = T.engine()
        e.debugGrant(10_000)
        // стартовые «наполнители»
        let heart = RegularItem(id: UUID(), giftId: "heart", acquiredAt: T.t0)
        var s = e.state; s.regulars = [heart]; e.replaceState(s)
        let lots = e.marketLots()
        let target = lots.first { Double($0.value) >= 1.2 * 15 }!
        e.rngOverride = ScriptedRandom([0.9999])    // проигрыш
        let lose = try e.upgradeGame(stakeIds: [heart.id], target: target)
        XCTAssertFalse(lose.won)
        XCTAssertTrue(e.state.regulars.isEmpty, "ставка сгорает")
    }
}
