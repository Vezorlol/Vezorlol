import Foundation

public enum CraftRarity: String, Codable, CaseIterable, Sendable {
    case uncommon, rare, epic, legendary
    public var title: String { rawValue.capitalized }
}

/// Все числа баланса, которых нет в gifts_catalog.json, лежат в economy_rules.json.
public struct EconomyRules: Codable, Sendable {
    public struct DailyBonus: Codable, Sendable { public let rewards: [Stars]; public let levelBonusPerLevel: Double; public let finalDayCaseId: String }
    public struct FreeCaseTier: Codable, Sendable { public let fromLevel: Int; public let caseId: String }
    public struct FreeCase: Codable, Sendable { public let cooldownHours: Double; public let tiers: [FreeCaseTier] }
    public struct Bets: Codable, Sendable { public let floor: Stars; public let fractionOfNextLevel: Double; public let coinFlipMin: Stars }
    public struct CoinFlip: Codable, Sendable {
        public let starsMultiplier: Double; public let giftMinFraction: Double; public let giftMaxFraction: Double
        public let giftRtp: Double; public let maxGifts: Int
    }
    public struct Crash: Codable, Sendable { public let growthRate: Double; public let rtpPercent: Double; public let cap: Double; public let bettingSeconds: Double }
    public struct CraftOutcome: Codable, Sendable { public let rarity: CraftRarity; public let chance: Double; public let multiplier: Double }
    public struct Craft: Codable, Sendable { public let inputCount: Int; public let outcomes: [CraftOutcome] }
    public struct Upgrade: Codable, Sendable { public let rtp: Double; public let maxChance: Double; public let minTargetRatio: Double; public let maxItems: Int }
    public struct Unupgraded: Codable, Sendable {
        public let shopPriceFactor: Double; public let upgradeCostFactor: Double; public let valueFactor: Double
        public let shopSlots: Int; public let stockPerSlot: Int
    }
    public struct Market: Codable, Sendable { public let lots: Int; public let markupMin: Double; public let markupMax: Double; public let accessFractionOfNextLevel: Double; public let accessMinFloor: Stars }
    public struct CollectionIndex: Codable, Sendable {
        public let epochDate: String; public let reversion: Double; public let drift: Double
        public let min: Double; public let max: Double
        public let newBatchChance: Double; public let newBatchFactor: Double
        public let sigma: [String: Double]
    }
    public struct ValueMultiplier: Codable, Sendable {
        public let cap: Double; public let craftedCap: Double
        public let modelSteps: [[Double]]; public let backdropSteps: [[Double]]
        public let rareSymbolPermille: Int; public let rareSymbolMultiplier: Double
        public let numberTop10: Double; public let numberTop100: Double; public let numberPretty: Double
    }

    public let startBalance: Stars
    public let startFreeCaseTokens: Int
    public let startFreeCaseId: String
    public let systemSellRate: Double
    public let ledgerLimit: Int
    public let fairHistoryLimit: Int
    public let dailyBonus: DailyBonus
    public let freeCase: FreeCase
    public let caseUnlockLevels: [String: Int]
    public let bets: Bets
    public let coinFlip: CoinFlip
    public let crash: Crash
    public let craft: Craft
    public let upgrade: Upgrade
    public let unupgraded: Unupgraded
    public let market: Market
    public let collectionIndex: CollectionIndex
    public let valueMultiplier: ValueMultiplier
    public let supply: [String: Int]

    public func unlockLevel(forCase id: String) -> Int { caseUnlockLevels[id] ?? 1 }
    public func supply(of tier: Rarity) -> Int { supply[tier.rawValue] ?? 1000 }

    public static func load(from url: URL) throws -> EconomyRules {
        try JSONDecoder().decode(EconomyRules.self, from: Data(contentsOf: url))
    }
    public static func bundled() throws -> EconomyRules {
        guard let url = Bundle.module.url(forResource: "economy_rules", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try load(from: url)
    }
}
