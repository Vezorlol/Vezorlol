import Foundation

public enum GameError: Error, Equatable {
    case insufficientFunds
    case overLimit(max: Stars)
    case betTooSmall(min: Stars)
    case caseLocked(requiredLevel: Int)
    case notFound
    case invalidSelection
    case notAvailable
    case outOfStock
    case roundInProgress
}

public struct PlayerStats: Codable, Sendable {
    public var casesOpened = 0
    public var bestDropValue: Stars = 0
    public var bestDropName = ""
    public var maxCrashMultiplier: Double = 0
    public var totalWon: Stars = 0
    public var totalLost: Stars = 0
    public init() {}
}

public struct LedgerEntry: Codable, Identifiable, Sendable {
    public let id: UUID
    public let date: Date
    public let delta: Stars
    public let kind: String
    public let note: String
}

public struct Settings: Codable, Sendable {
    public var sound = true
    public var haptics = true
    public var theme = "system"   // system | light | dark
    public init() {}
}

public struct CrashRound: Codable, Sendable {
    public let bet: Stars
    public let crashPoint: Double
    public let autoCashout: Double?
    public let startedAt: Date
    public let fair: FairRound
}

public enum CrashOutcome: Sendable, Equatable {
    case won(multiplier: Double, payout: Stars)
    case lost(crashPoint: Double)
}

public struct GameState: Codable, Sendable {
    public var playerName: String
    public var balance: Stars
    public var regulars: [RegularItem] = []
    public var uniques: [UniqueGift] = []
    public var allocator = NumberAllocator()
    public var piggy: PiggyState
    public var daily = DailyState()
    public var freeCase: FreeCaseState
    public var stats = PlayerStats()
    public var ledger: [LedgerEntry] = []
    public var fair = FairState()
    public var trusted: TrustedTimeState?
    public var settings = Settings()
    public var shopPurchases: [String: Int] = [:]      // "<day>|<collectionId>" → куплено
    public var purchasedLots: Set<String> = []
    public var activeCrash: CrashRound?
    public var crashHistory: [Double] = []
    public var onboarded = false
    public var createdAt: Date

    public init(rules: EconomyRules, now: Date) {
        playerName = "Игрок"
        balance = rules.startBalance
        piggy = PiggyState(start: now)
        freeCase = FreeCaseState(tokens: rules.startFreeCaseTokens)
        createdAt = now
    }

    mutating func credit(_ amount: Stars, kind: String, note: String = "", date: Date, limit: Int) {
        guard amount != 0 else { return }
        balance += amount
        ledger.insert(LedgerEntry(id: UUID(), date: date, delta: amount, kind: kind, note: note), at: 0)
        if ledger.count > limit { ledger.removeLast(ledger.count - limit) }
    }

    mutating func debit(_ amount: Stars, kind: String, note: String = "", date: Date, limit: Int) throws {
        guard amount >= 0, balance >= amount else { throw GameError.insufficientFunds }
        credit(-amount, kind: kind, note: note, date: date, limit: limit)
    }
}
