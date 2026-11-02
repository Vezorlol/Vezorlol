import Foundation

public enum Rarity: String, Codable, CaseIterable, Sendable, Comparable {
    case common = "Common", uncommon = "Uncommon", rare = "Rare", epic = "Epic", legendary = "Legendary"
    private var order: Int { Rarity.allCases.firstIndex(of: self)! }
    public static func < (a: Rarity, b: Rarity) -> Bool { a.order < b.order }
}

public struct RegularGift: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let price: Stars
    public let sellPrice: Stars
}

public struct GiftCollection: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let floor: Stars
    public let tier: Rarity
    public var emojiPlaceholder: String
}

public struct CaseDrop: Codable, Hashable, Sendable {
    public let item: String
    public let chancePercent: Double
}

public struct CaseDef: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let price: Stars
    public let targetRTP: Double
    public let drops: [CaseDrop]
}

public struct LevelDef: Codable, Hashable, Sendable {
    public let level: Int
    public let inventoryValueFrom: Stars
    public let incomePerHour: Stars
    public let accrualCapHours: Int
}

public struct CatalogMeta: Codable, Sendable {
    public let currency: String
    public let tonToStars: Int
    public let source: String
    public let avgAttributeMultiplier: Double
}

public enum ItemRef: Sendable, Hashable {
    case regular(RegularGift)
    case collection(GiftCollection)
}

public struct Catalog: Codable, Sendable {
    public let meta: CatalogMeta
    public let regularGifts: [RegularGift]
    public let collectibles: [GiftCollection]
    public let cases: [CaseDef]
    public let levels: [LevelDef]

    private enum CodingKeys: String, CodingKey { case meta, regularGifts, collectibles, cases, levels }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        meta = try c.decode(CatalogMeta.self, forKey: .meta)
        regularGifts = try c.decode([RegularGift].self, forKey: .regularGifts)
        var cols = try c.decode([GiftCollection].self, forKey: .collectibles)
        for i in cols.indices where cols[i].emojiPlaceholder.isEmpty {
            cols[i].emojiPlaceholder = CollectionEmoji.emoji(for: cols[i].id)
        }
        collectibles = cols
        cases = try c.decode([CaseDef].self, forKey: .cases)
        levels = try c.decode([LevelDef].self, forKey: .levels).sorted { $0.level < $1.level }
        regularIndex = Dictionary(uniqueKeysWithValues: regularGifts.map { ($0.id, $0) })
        collectionIndex = Dictionary(uniqueKeysWithValues: collectibles.map { ($0.id, $0) })
        caseIndex = Dictionary(uniqueKeysWithValues: cases.map { ($0.id, $0) })
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(meta, forKey: .meta)
        try c.encode(regularGifts, forKey: .regularGifts)
        try c.encode(collectibles, forKey: .collectibles)
        try c.encode(cases, forKey: .cases)
        try c.encode(levels, forKey: .levels)
    }

    private let regularIndex: [String: RegularGift]
    private let collectionIndex: [String: GiftCollection]
    private let caseIndex: [String: CaseDef]

    public func regular(_ id: String) -> RegularGift? { regularIndex[id] }
    public func collection(_ id: String) -> GiftCollection? { collectionIndex[id] }
    public func caseDef(_ id: String) -> CaseDef? { caseIndex[id] }
    public func resolve(_ id: String) -> ItemRef? {
        if let r = regularIndex[id] { return .regular(r) }
        if let c = collectionIndex[id] { return .collection(c) }
        return nil
    }
    public func level(for inventoryValue: Stars) -> LevelDef {
        levels.last(where: { $0.inventoryValueFrom <= inventoryValue }) ?? levels[0]
    }
    public func nextLevel(after level: Int) -> LevelDef? { levels.first(where: { $0.level == level + 1 }) }

    public static func load(from url: URL) throws -> Catalog {
        try JSONDecoder().decode(Catalog.self, from: Data(contentsOf: url))
    }
    public static func bundled() throws -> Catalog {
        guard let url = Bundle.module.url(forResource: "gifts_catalog", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try load(from: url)
    }
}
