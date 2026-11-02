import Foundation

public enum FreeCaseKind: Sendable { case timer, token }

public struct CaseOpening: Sendable {
    public let caseId: String
    public let gift: AnyGift
    public let value: Stars
    public let name: String
}

public struct UpgradeOutcome: Sendable { public let won: Bool; public let chance: Double; public let gift: UniqueGift? }
public struct CoinFlipOutcome: Sendable { public let side: CoinSide; public let won: Bool; public let payout: Stars; public let reward: AnyGift? }

/// Игровой движок: все операции с балансом атомарны (копия состояния → коммит только при успехе).
public final class GameEngine {
    public let catalog: Catalog
    public let rules: EconomyRules
    public let levels: LevelService
    public let calc: ValueCalculator
    public let factory: GiftFactory
    public let index: CollectionIndexService
    public let market: MarketService
    public private(set) var state: GameState
    /// Время (доверенное). В тестах подменяется.
    public var clock: () -> Date
    /// Подмена RNG для тестов; в игре — provably fair.
    public var rngOverride: RandomSource?
    public var calendar: Calendar = .current

    private var caseTables: [String: WeightedTable] = [:]

    public init(catalog: Catalog, rules: EconomyRules, state: GameState? = nil, clock: @escaping () -> Date = { Date() }) {
        self.catalog = catalog; self.rules = rules; self.clock = clock
        self.levels = LevelService(catalog: catalog, rules: rules)
        self.calc = ValueCalculator(catalog: catalog, rules: rules)
        self.factory = GiftFactory(catalog: catalog, rules: rules)
        self.index = CollectionIndexService(rules: rules)
        self.market = MarketService(catalog: catalog, rules: rules, index: index)
        self.state = state ?? GameState(rules: rules, now: clock())
        for c in catalog.cases { caseTables[c.id] = WeightedTable(weights: c.drops.map(\.chancePercent)) }
    }

    public func reset() { state = GameState(rules: rules, now: clock()) }
    public func replaceState(_ s: GameState) { state = s }

    // MARK: Запросы

    public func value(of gift: AnyGift, at date: Date? = nil) -> Stars { Self.value(of: gift, self, date ?? clock(), index) }
    private static func value(of gift: AnyGift, _ e: GameEngine, _ date: Date, _ idx: CollectionIndexService) -> Stars {
        switch gift {
        case .regular(let r): return e.catalog.regular(r.giftId)?.price ?? 0
        case .unique(let u):
            guard let col = e.catalog.collection(u.collectionId) else { return 0 }
            return e.calc.value(of: u, index: idx.index(collection: col, at: date))
        }
    }
    public func sellPrice(of gift: AnyGift) -> Stars {
        switch gift {
        case .regular(let r): return catalog.regular(r.giftId)?.sellPrice ?? 0
        case .unique: return floorStars(Decimal(value(of: gift)) * dec(rules.systemSellRate))
        }
    }
    public var inventory: [AnyGift] { state.regulars.map(AnyGift.regular) + state.uniques.map(AnyGift.unique) }
    public func inventoryValue() -> Stars { inventory.reduce(0) { $0 + value(of: $1) } }
    public func currentLevel() -> LevelDef { levels.level(forInventoryValue: inventoryValue()) }
    public func maxBet() -> Stars { levels.maxBet(level: currentLevel().level) }
    public func isUnlocked(caseId: String) -> Bool { levels.isCaseUnlocked(caseId, level: currentLevel().level) }

    public func piggyAccrued() -> Stars { floorStars(Piggy.accrued(state.piggy, now: clock(), level: currentLevel())) }
    public func piggyFill() -> Double { Piggy.fill(state.piggy, now: clock(), level: currentLevel()) }
    public func freeTimerRemaining() -> TimeInterval {
        guard let last = state.freeCase.lastOpenAt else { return 0 }
        return max(0, last.addingTimeInterval(rules.freeCase.cooldownHours * 3600).timeIntervalSince(clock()))
    }
    public func dailyAvailable() -> DailyReward? {
        let today = DailyBonus.dayNumber(clock(), calendar: calendar)
        guard let d = DailyBonus.availableDay(state.daily, today: today) else { return nil }
        return DailyBonus.reward(dayIndex: d, level: currentLevel().level, rules: rules)
    }

    // MARK: Транзакции

    private func now() -> Date { clock() }

    /// Игра с RNG: seed раунда раскрывается в историю «честности» после завершения.
    private func playRound<T>(game: String, _ body: (inout GameState, RandomSource, Date) throws -> (T, String)) throws -> T {
        var s = state
        let date = now()
        let rng: RandomSource = rngOverride ?? s.fair.makeStream()
        let round = s.fair.commitRound(game: game, date: date)
        let (result, outcome) = try body(&s, rng, date)
        s.fair.record(round, outcome: outcome, limit: rules.fairHistoryLimit)
        state = s
        return result
    }

    private func mutate<T>(_ body: (inout GameState, Date) throws -> T) throws -> T {
        var s = state
        let r = try body(&s, now())
        state = s
        return r
    }

    private func checkBet(_ bet: Stars, min: Stars, level: Int) throws {
        guard bet >= min else { throw GameError.betTooSmall(min: min) }
        let cap = levels.maxBet(level: level)
        guard bet <= cap else { throw GameError.overLimit(max: cap) }
    }

    private func registerStats(_ s: inout GameState, staked: Stars, returned: Stars) {
        if returned > staked { s.stats.totalWon += returned - staked } else { s.stats.totalLost += staked - returned }
    }

    private func takeSelected(_ ids: [UUID], from s: inout GameState) throws -> [AnyGift] {
        guard Set(ids).count == ids.count, !ids.isEmpty else { throw GameError.invalidSelection }
        var picked: [AnyGift] = []
        for id in ids {
            if let r = s.regulars.first(where: { $0.id == id }) { picked.append(.regular(r)) }
            else if let u = s.uniques.first(where: { $0.id == id }) { picked.append(.unique(u)) }
            else { throw GameError.notFound }
        }
        let set = Set(ids)
        s.regulars.removeAll { set.contains($0.id) }
        for case .unique(let u) in picked { s.allocator.release(collection: u.collectionId, number: u.number) }
        s.uniques.removeAll { set.contains($0.id) }
        return picked
    }

    private func add(_ gift: AnyGift, to s: inout GameState) {
        switch gift { case .regular(let r): s.regulars.append(r); case .unique(let u): s.uniques.append(u) }
    }

    // MARK: Кейсы

    @discardableResult
    public func openCase(_ caseId: String) throws -> CaseOpening {
        guard let def = catalog.caseDef(caseId) else { throw GameError.notFound }
        let level = currentLevel().level
        guard levels.isCaseUnlocked(caseId, level: level) else { throw GameError.caseLocked(requiredLevel: rules.unlockLevel(forCase: caseId)) }
        return try playRound(game: "case:\(caseId)") { s, rng, date in
            try s.debit(def.price, kind: "case", note: def.name, date: date, limit: rules.ledgerLimit)
            return roll(def, paid: def.price, s: &s, rng: rng, date: date)
        }
    }

    @discardableResult
    public func openFreeCase(_ kind: FreeCaseKind) throws -> CaseOpening {
        let level = currentLevel().level
        let caseId = kind == .timer ? levels.freeCaseId(level: level) : rules.startFreeCaseId
        guard let def = catalog.caseDef(caseId) else { throw GameError.notFound }
        return try playRound(game: "freecase:\(caseId)") { s, rng, date in
            switch kind {
            case .timer:
                if let last = s.freeCase.lastOpenAt, date < last.addingTimeInterval(rules.freeCase.cooldownHours * 3600) { throw GameError.notAvailable }
                s.freeCase.lastOpenAt = date
            case .token:
                guard s.freeCase.tokens > 0 else { throw GameError.notAvailable }
                s.freeCase.tokens -= 1
            }
            return roll(def, paid: 0, s: &s, rng: rng, date: date, reference: def.price)
        }
    }

    private func roll(_ def: CaseDef, paid: Stars, s: inout GameState, rng: RandomSource, date: Date, reference: Stars? = nil) -> (CaseOpening, String) {
        let drop = def.drops[caseTables[def.id]!.pick(rng)]
        let gift: AnyGift
        var name = drop.item
        switch catalog.resolve(drop.item)! {
        case .regular(let r):
            gift = .regular(RegularItem(id: UUID(), giftId: r.id, acquiredAt: date)); name = r.name
        case .collection(let c):
            gift = .unique(factory.makeUpgraded(collection: c, source: .caseOpen, price: def.price, now: date, allocator: &s.allocator, rng: rng))
            name = c.name
        }
        add(gift, to: &s)
        let v = value(of: gift, at: date)
        s.stats.casesOpened += 1
        if v > s.stats.bestDropValue { s.stats.bestDropValue = v; s.stats.bestDropName = name }
        registerStats(&s, staked: reference ?? paid, returned: v)
        return (CaseOpening(caseId: def.id, gift: gift, value: v, name: name), "\(def.name) → \(name)")
    }

    // MARK: Продажа

    @discardableResult
    public func sell(ids: [UUID]) throws -> Stars {
        try mutate { s, date in
            let picked = try takeSelected(ids, from: &s)
            let total = picked.reduce(Stars(0)) { $0 + sellPrice(of: $1) }
            s.credit(total, kind: "sell", note: "Продажа: \(picked.count)", date: date, limit: rules.ledgerLimit)
            return total
        }
    }

    // MARK: Копилка / бонусы

    @discardableResult
    public func collectPiggy() throws -> Stars {
        try mutate { s, date in
            let got = Piggy.collect(&s.piggy, now: date, level: currentLevel())
            s.credit(got, kind: "piggy", date: date, limit: rules.ledgerLimit)
            return got
        }
    }

    @discardableResult
    public func claimDaily() throws -> DailyReward {
        try mutate { s, date in
            let today = DailyBonus.dayNumber(date, calendar: calendar)
            guard let day = DailyBonus.availableDay(s.daily, today: today) else { throw GameError.notAvailable }
            let reward = DailyBonus.reward(dayIndex: day, level: currentLevel().level, rules: rules)
            DailyBonus.claim(&s.daily, today: today)
            s.credit(reward.stars, kind: "daily", note: "День \(day + 1)", date: date, limit: rules.ledgerLimit)
            if reward.freeCaseId != nil { s.freeCase.tokens += 1 }
            return reward
        }
    }

    // MARK: Coin Flip

    @discardableResult
    public func coinFlipStars(bet: Stars, pick: CoinSide) throws -> CoinFlipOutcome {
        try checkBet(bet, min: rules.bets.coinFlipMin, level: currentLevel().level)
        return try playRound(game: "coinflip") { s, rng, date in
            try s.debit(bet, kind: "coinflip", date: date, limit: rules.ledgerLimit)
            let side = GameMath.coinSide(unit: rng.nextUnit())
            let won = side == pick
            let payout = won ? GameMath.coinFlipPayout(bet: bet, rules: rules) : 0
            s.credit(payout, kind: "coinflip", note: "Выигрыш", date: date, limit: rules.ledgerLimit)
            registerStats(&s, staked: bet, returned: payout)
            return (CoinFlipOutcome(side: side, won: won, payout: payout, reward: nil), "\(side.rawValue), ставка \(bet)")
        }
    }

    @discardableResult
    public func coinFlipGifts(ids: [UUID], pick: CoinSide) throws -> CoinFlipOutcome {
        guard (1...rules.coinFlip.maxGifts).contains(ids.count) else { throw GameError.invalidSelection }
        return try playRound(game: "coinflip-gifts") { s, rng, date in
            let picked = try takeSelected(ids, from: &s)
            let total = picked.reduce(Stars(0)) { $0 + value(of: $1, at: date) }
            let cap = maxBet()
            guard total <= cap else { throw GameError.overLimit(max: cap) }
            // P(победа) подобрана так, чтобы RTP режима ≈ giftRtp; сторона монеты — только визуальная.
            let won = rng.nextUnit() < GameMath.giftModeWinChance(rules: rules)
            if won {
                picked.forEach { add($0, to: &s) }
                let lo = floorStars(Decimal(total) * dec(rules.coinFlip.giftMinFraction))
                let hi = floorStars(Decimal(total) * dec(rules.coinFlip.giftMaxFraction))
                let target = lo + Stars(rng.nextUnit() * Double(max(0, hi - lo)))
                let reward = giftNear(target: target, lo: lo, hi: hi, s: &s, rng: rng, date: date)
                add(reward, to: &s)
                registerStats(&s, staked: total, returned: total + value(of: reward, at: date))
                return (CoinFlipOutcome(side: pick, won: true, payout: value(of: reward, at: date), reward: reward), "gifts win \(total)")
            }
            registerStats(&s, staked: total, returned: 0)
            return (CoinFlipOutcome(side: pick == .star ? .gift : .star, won: false, payout: 0, reward: nil), "gifts lose \(total)")
        }
    }

    /// Подбирает ближайший по стоимости подарок (обычный или экземпляр коллекции).
    func giftNear(target: Stars, lo: Stars, hi: Stars, s: inout GameState, rng: RandomSource, date: Date) -> AnyGift {
        let maxRegular = catalog.regularGifts.map(\.price).max() ?? 0
        if hi <= maxRegular {
            let best = catalog.regularGifts.min { abs($0.price - target) < abs($1.price - target) }!
            return .regular(RegularItem(id: UUID(), giftId: best.id, acquiredAt: date))
        }
        let day = index.dayNumber(for: date)
        let withBase = catalog.collectibles.map { ($0, calc.floorValue(of: $0, index: index.index(collection: $0, day: day))) }
        var cands = withBase.filter { $0.1 <= hi && Double($0.1) >= Double(hi) / 2.2 }
        if cands.isEmpty { cands = Array(withBase.sorted { $0.1 > $1.1 }.filter { $0.1 <= hi }.prefix(3)) }
        guard !cands.isEmpty else {
            let best = catalog.regularGifts.max { $0.price < $1.price }!
            return .regular(RegularItem(id: UUID(), giftId: best.id, acquiredAt: date))
        }
        let col = cands[rng.nextInt(cands.count)].0
        var best: (UniqueGift, NumberAllocator, Stars)?
        for _ in 0..<120 {
            var tmp = s.allocator
            let g = factory.makeUpgraded(collection: col, source: .coinflip, price: target, now: date, allocator: &tmp, rng: rng)
            let v = calc.value(of: g, index: index.index(collection: col, day: day))
            if (lo...hi).contains(v) { best = (g, tmp, v); break }
            if best == nil || abs(v - target) < abs(best!.2 - target) { best = (g, tmp, v) }
        }
        s.allocator = best!.1
        return .unique(best!.0)
    }

    // MARK: Crash

    @discardableResult
    public func startCrash(bet: Stars, autoCashout: Double?) throws -> CrashRound {
        guard state.activeCrash == nil else { throw GameError.roundInProgress }
        try checkBet(bet, min: 1, level: currentLevel().level)
        var s = state
        let date = now()
        let rng: RandomSource = rngOverride ?? s.fair.makeStream()
        let round = s.fair.commitRound(game: "crash", date: date)
        try s.debit(bet, kind: "crash", note: "Ставка", date: date, limit: rules.ledgerLimit)
        let crash = GameMath.crashPoint(unit: rng.nextUnit(), rules: rules)
        let cr = CrashRound(bet: bet, crashPoint: crash, autoCashout: autoCashout.map { max(1.01, $0) },
                            startedAt: date.addingTimeInterval(rules.crash.bettingSeconds), fair: round)
        s.activeCrash = cr
        state = s
        return cr
    }

    /// Ручной вывод в момент `date`. Если краш уже случился — ставка проиграна.
    @discardableResult
    public func cashOutCrash() throws -> CrashOutcome {
        guard let cr = state.activeCrash else { throw GameError.notAvailable }
        let t = max(0, now().timeIntervalSince(cr.startedAt))
        let m = GameMath.crashMultiplier(atSeconds: t, rules: rules)
        return try settleCrash(cr, multiplier: m < cr.crashPoint ? m : nil)
    }

    /// Досчитывает раунд (в т.ч. после сворачивания): автовывод или краш. nil — раунд ещё идёт.
    @discardableResult
    public func advanceCrash() throws -> CrashOutcome? {
        guard let cr = state.activeCrash else { return nil }
        let t = now().timeIntervalSince(cr.startedAt)
        if let auto = cr.autoCashout, auto <= cr.crashPoint, t >= GameMath.crashTime(forMultiplier: auto, rules: rules) {
            return try settleCrash(cr, multiplier: auto)
        }
        if t >= GameMath.crashTime(forMultiplier: cr.crashPoint, rules: rules) { return try settleCrash(cr, multiplier: nil) }
        return nil
    }

    private func settleCrash(_ cr: CrashRound, multiplier: Double?) throws -> CrashOutcome {
        try mutate { s, date in
            s.activeCrash = nil
            s.crashHistory.insert(cr.crashPoint, at: 0)
            if s.crashHistory.count > 20 { s.crashHistory.removeLast(s.crashHistory.count - 20) }
            if let m = multiplier {
                let payout = GameMath.crashPayout(bet: cr.bet, multiplier: m)
                s.credit(payout, kind: "crash", note: "Вывод ×\(m)", date: date, limit: rules.ledgerLimit)
                registerStats(&s, staked: cr.bet, returned: payout)
                s.stats.maxCrashMultiplier = max(s.stats.maxCrashMultiplier, (m * 100).rounded(.down) / 100)
                s.fair.record(cr.fair, outcome: "crash ×\(cr.crashPoint), вывод ×\(m)", limit: rules.fairHistoryLimit)
                return .won(multiplier: m, payout: payout)
            }
            registerStats(&s, staked: cr.bet, returned: 0)
            s.fair.record(cr.fair, outcome: "crash ×\(cr.crashPoint), проигрыш", limit: rules.fairHistoryLimit)
            return .lost(crashPoint: cr.crashPoint)
        }
    }

    // MARK: Крафт

    public func craftPreview(ids: [UUID]) -> Stars {
        state.uniques.filter { ids.contains($0.id) }.reduce(0) { $0 + value(of: .unique($1)) }
    }

    @discardableResult
    public func craft(ids: [UUID]) throws -> UniqueGift {
        guard ids.count == rules.craft.inputCount else { throw GameError.invalidSelection }
        return try playRound(game: "craft") { s, rng, date in
            let inputs = try takeSelected(ids, from: &s)
            let uniques: [UniqueGift] = inputs.compactMap { if case .unique(let u) = $0 { return u } else { return nil } }
            guard uniques.count == ids.count, Set(uniques.map(\.collectionId)).count == 1,
                  let col = catalog.collection(uniques[0].collectionId) else { throw GameError.invalidSelection }
            let burned = uniques.reduce(Stars(0)) { $0 + value(of: .unique($1), at: date) }
            let rarity = GameMath.craftRarity(unit: rng.nextUnit(), rules: rules)
            let out = factory.makeUpgraded(collection: col, source: .craft, price: burned, now: date, allocator: &s.allocator, rng: rng, crafted: rarity)
            s.uniques.append(out)
            registerStats(&s, staked: burned, returned: value(of: .unique(out), at: date))
            return (out, "craft \(rarity.rawValue) \(col.name)")
        }
    }

    // MARK: Апгрейд (ставка подарками на цель из Маркета)

    public func upgradeChance(stakeIds: [UUID], target: MarketLot) -> (stake: Stars, chance: Double) {
        let stake = inventory.filter { stakeIds.contains($0.id) }.reduce(Stars(0)) { $0 + value(of: $1) }
        return (stake, GameMath.upgradeChance(stake: stake, target: target.value, rules: rules))
    }

    @discardableResult
    public func upgradeGame(stakeIds: [UUID], target: MarketLot) throws -> UpgradeOutcome {
        guard (1...rules.upgrade.maxItems).contains(stakeIds.count) else { throw GameError.invalidSelection }
        let level = currentLevel().level
        guard market.lots(now: now(), level: level).contains(where: { $0.id == target.id }),
              !state.purchasedLots.contains(target.id) else { throw GameError.notAvailable }
        return try playRound(game: "upgrade") { s, rng, date in
            let picked = try takeSelected(stakeIds, from: &s)
            let stake = picked.reduce(Stars(0)) { $0 + value(of: $1, at: date) }
            let cap = levels.maxBet(level: level)
            guard stake <= cap else { throw GameError.overLimit(max: cap) }
            guard Double(target.value) >= rules.upgrade.minTargetRatio * Double(stake) else { throw GameError.invalidSelection }
            let chance = GameMath.upgradeChance(stake: stake, target: target.value, rules: rules)
            let won = rng.nextUnit() < chance
            if won {
                var g = target.gift
                g.acquiredAt = date; g.acquiredPrice = stake; g.source = .upgrade
                s.allocator.issued[g.collectionId, default: []].insert(g.number)
                s.uniques.append(g)
                s.purchasedLots.insert(target.id)
                registerStats(&s, staked: stake, returned: target.value)
                return (UpgradeOutcome(won: true, chance: chance, gift: g), "upgrade win \(chance)")
            }
            registerStats(&s, staked: stake, returned: 0)
            return (UpgradeOutcome(won: false, chance: chance, gift: nil), "upgrade lose \(chance)")
        }
    }

    // MARK: Маркет и магазин

    public func marketLots() -> [MarketLot] {
        market.lots(now: now(), level: currentLevel().level).filter { !state.purchasedLots.contains($0.id) }
    }

    @discardableResult
    public func buyLot(_ id: String) throws -> UniqueGift {
        try mutate { s, date in
            guard !s.purchasedLots.contains(id),
                  let lot = market.lots(now: date, level: currentLevel().level).first(where: { $0.id == id }) else { throw GameError.notFound }
            try s.debit(lot.price, kind: "market", note: catalog.collection(lot.gift.collectionId)?.name ?? "", date: date, limit: rules.ledgerLimit)
            var g = lot.gift
            g.acquiredAt = date; g.acquiredPrice = lot.price; g.source = .market
            s.allocator.issued[g.collectionId, default: []].insert(g.number)
            s.uniques.append(g)
            s.purchasedLots.insert(id)
            return g
        }
    }

    public func shopSlots() -> [ShopSlot] {
        market.shop(now: now(), level: currentLevel().level).map { slot in
            ShopSlot(id: slot.id, collection: slot.collection, price: slot.price, upgradeCost: slot.upgradeCost,
                     stock: max(0, slot.stock - (state.shopPurchases[slot.id] ?? 0)))
        }
    }

    @discardableResult
    public func buyShopItem(_ slotId: String) throws -> UniqueGift {
        try playRound(game: "shop") { s, rng, date in
            guard let slot = market.shop(now: date, level: currentLevel().level).first(where: { $0.id == slotId }) else { throw GameError.notFound }
            guard (s.shopPurchases[slotId] ?? 0) < slot.stock else { throw GameError.outOfStock }
            try s.debit(slot.price, kind: "shop", note: slot.collection.name, date: date, limit: rules.ledgerLimit)
            s.shopPurchases[slotId, default: 0] += 1
            let g = factory.makeUnupgraded(collection: slot.collection, source: .shop, price: slot.price, now: date, allocator: &s.allocator, rng: rng)
            s.uniques.append(g)
            return (g, "shop \(slot.collection.name)")
        }
    }

    public func upgradeCost(of gift: UniqueGift) -> Stars {
        guard let col = catalog.collection(gift.collectionId) else { return 0 }
        return max(1, floorStars(Decimal(col.floor) * dec(rules.unupgraded.upgradeCostFactor)))
    }

    @discardableResult
    public func upgradeGift(id: UUID) throws -> UniqueGift {
        try playRound(game: "upgrade-gift") { s, rng, date in
            guard let i = s.uniques.firstIndex(where: { $0.id == id }) else { throw GameError.notFound }
            guard !s.uniques[i].isUpgraded else { throw GameError.notAvailable }
            try s.debit(upgradeCost(of: s.uniques[i]), kind: "upgrade-gift", date: date, limit: rules.ledgerLimit)
            let up = factory.upgrade(s.uniques[i], allocator: &s.allocator, rng: rng)
            s.uniques[i] = up
            return (up, "upgrade \(up.collectionId) #\(up.number)")
        }
    }

    // MARK: Профиль / настройки

    public func setName(_ name: String) { state.playerName = String(name.prefix(32)) }
    public func setClientSeed(_ seed: String) { state.fair.clientSeed = String(seed.prefix(64)) }
    public func updateSettings(_ f: (inout Settings) -> Void) { f(&state.settings) }
    public func setOnboarded() { state.onboarded = true }
    public func setTrusted(_ t: TrustedTimeState) { state.trusted = t }
    /// Отладка (Debug-сборка): начислить звёзды.
    public func debugGrant(_ amount: Stars) { state.credit(amount, kind: "debug", date: now(), limit: rules.ledgerLimit) }
}
