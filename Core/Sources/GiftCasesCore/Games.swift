import Foundation

public enum CoinSide: String, Codable, Sendable { case star, gift }

/// Чистая математика игр (без состояния).
public enum GameMath {
    // MARK: Coin Flip
    public static func coinSide(unit: Double) -> CoinSide { unit < 0.5 ? .star : .gift }
    public static func coinFlipPayout(bet: Stars, rules: EconomyRules) -> Stars {
        floorStars(Decimal(bet) * dec(rules.coinFlip.starsMultiplier))
    }
    /// P(победа) в режиме подарков: RTP = p × (1 + среднее(0.85…1.0)).
    public static func giftModeWinChance(rules: EconomyRules) -> Double {
        let avg = (rules.coinFlip.giftMinFraction + rules.coinFlip.giftMaxFraction) / 2
        return rules.coinFlip.giftRtp / (1 + avg)
    }

    // MARK: Crash
    /// crash = max(1.00, floor(96 / (1 − U)) / 100), потолок cap. P(crash ≥ x) = 0.96 / x.
    public static func crashPoint(unit: Double, rules: EconomyRules) -> Double {
        let raw = (rules.crash.rtpPercent / (1 - unit)).rounded(.down) / 100
        return min(rules.crash.cap, max(1.0, raw))
    }
    public static func crashMultiplier(atSeconds t: Double, rules: EconomyRules) -> Double {
        exp(rules.crash.growthRate * max(0, t))
    }
    public static func crashTime(forMultiplier m: Double, rules: EconomyRules) -> Double {
        log(max(1, m)) / rules.crash.growthRate
    }
    /// Выплата при выводе на множителе m (m округляется вниз до сотых).
    public static func crashPayout(bet: Stars, multiplier m: Double) -> Stars {
        let m2 = (m * 100).rounded(.down) / 100
        return floorStars(Decimal(bet) * dec(m2))
    }

    // MARK: Upgrade
    public static func upgradeChance(stake: Stars, target: Stars, rules: EconomyRules) -> Double {
        guard target > 0 else { return 0 }
        return min(rules.upgrade.maxChance, Double(stake) / Double(target) * rules.upgrade.rtp)
    }

    // MARK: Craft
    public static func craftRarity(unit: Double, rules: EconomyRules) -> CraftRarity {
        var acc = 0.0
        for o in rules.craft.outcomes { acc += o.chance; if unit < acc { return o.rarity } }
        return rules.craft.outcomes.last!.rarity
    }
    public static func craftExpectedMultiplier(rules: EconomyRules) -> Double {
        rules.craft.outcomes.reduce(0) { $0 + $1.chance * $1.multiplier }
    }
}
