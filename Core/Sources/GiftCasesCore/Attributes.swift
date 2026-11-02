import Foundation

public struct GiftModel: Hashable, Sendable { public let id: String; public let name: String; public let permille: Int }
public struct Backdrop: Hashable, Sendable {
    public let id: String; public let name: String
    public let centerHex: UInt32; public let edgeHex: UInt32; public let patternHex: UInt32; public let textHex: UInt32
    public let permille: Int
}
public struct PatternSymbol: Hashable, Sendable {
    public let id: String; public let name: String; public let permille: Int
    /// Узор в Telegram — стикер; здесь он рисуется SF-символом, выбранным детерминированно по названию.
    public var sfSymbol: String { AttributePools.sfSymbol(forPattern: name) }
}

/// Настоящие атрибуты улучшенных подарков: у каждой коллекции свои модели и узоры, фоны общие.
/// Данные выгружены из API Telegram (tools/export_telegram_attributes.py → tools/build_attributes.py).
public enum AttributePools {
    public struct CollectionAttributes: Sendable {
        public let models: [GiftModel]
        public let patterns: [PatternSymbol]
        let modelTable: WeightedTable
        let patternTable: WeightedTable
    }

    private struct Loaded {
        let backdrops: [Backdrop]
        let backdropTable: WeightedTable
        let collections: [String: CollectionAttributes]
    }

    private static let loaded: Loaded = {
        guard let url = Bundle.module.url(forResource: "gift_attributes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let bds = root["backdrops"] as? [[Any]], let cols = root["collections"] as? [String: [String: [[Any]]]]
        else { fatalError("gift_attributes.json отсутствует или повреждён") }
        let backdrops: [Backdrop] = bds.map { a in
            Backdrop(id: "b\(a[0] as! Int)", name: a[1] as! String, centerHex: UInt32(a[2] as! Int), edgeHex: UInt32(a[3] as! Int),
                     patternHex: UInt32(a[4] as! Int), textHex: UInt32(a[5] as! Int), permille: a[6] as! Int)
        }
        var out: [String: CollectionAttributes] = [:]
        for (id, v) in cols {
            let models = (v["models"] ?? []).enumerated().map { GiftModel(id: "m\($0.offset)", name: $0.element[0] as! String, permille: $0.element[1] as! Int) }
            let patterns = (v["patterns"] ?? []).enumerated().map { PatternSymbol(id: "s\($0.offset)", name: $0.element[0] as! String, permille: $0.element[1] as! Int) }
            out[id] = CollectionAttributes(models: models, patterns: patterns,
                                           modelTable: WeightedTable(weights: models.map { Double($0.permille) }),
                                           patternTable: WeightedTable(weights: patterns.map { Double($0.permille) }))
        }
        return Loaded(backdrops: backdrops, backdropTable: WeightedTable(weights: backdrops.map { Double($0.permille) }), collections: out)
    }()

    public static var backdrops: [Backdrop] { loaded.backdrops }
    static var backdropTable: WeightedTable { loaded.backdropTable }
    public static func attributes(for collectionId: String) -> CollectionAttributes {
        guard let a = loaded.collections[collectionId] else { fatalError("нет атрибутов для \(collectionId)") }
        return a
    }
    public static func hasAttributes(for collectionId: String) -> Bool { loaded.collections[collectionId] != nil }

    public static func models(_ collectionId: String) -> [GiftModel] { attributes(for: collectionId).models }
    public static func symbols(_ collectionId: String) -> [PatternSymbol] { attributes(for: collectionId).patterns }
    public static func model(_ collectionId: String, _ id: String) -> GiftModel? {
        guard let i = Int(id.dropFirst()), loaded.collections[collectionId].map({ i < $0.models.count }) == true else { return nil }
        return attributes(for: collectionId).models[i]
    }
    public static func symbol(_ collectionId: String, _ id: String) -> PatternSymbol? {
        guard let i = Int(id.dropFirst()), loaded.collections[collectionId].map({ i < $0.patterns.count }) == true else { return nil }
        return attributes(for: collectionId).patterns[i]
    }
    public static func backdrop(_ id: String) -> Backdrop? { loaded.backdrops.first { $0.id == id } }

    private static let symbolNames = [
        "star.fill", "heart.fill", "crown.fill", "bolt.fill", "flame.fill", "leaf.fill", "moon.fill", "sun.max.fill",
        "snowflake", "drop.fill", "cloud.fill", "hare.fill", "tortoise.fill", "ladybug.fill", "pawprint.fill", "music.note",
        "gift.fill", "bell.fill", "key.fill", "lock.fill", "flag.fill", "bookmark.fill", "diamond.fill", "seal.fill",
        "shield.fill", "wand.and.stars", "sparkles", "teddybear.fill", "gamecontroller.fill", "camera.fill", "airplane", "car.fill",
        "bicycle", "cup.and.saucer.fill", "fork.knife", "trophy.fill", "puzzlepiece.fill", "face.smiling.fill", "hand.thumbsup.fill", "eye.fill"
    ]
    public static func sfSymbol(forPattern name: String) -> String { symbolNames[Int(stableHash64(name) % UInt64(symbolNames.count))] }
}
