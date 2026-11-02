import Foundation

public struct GiftModel: Hashable, Sendable { public let id: String; public let name: String; public let permille: Int }
public struct Backdrop: Hashable, Sendable {
    public let id: String; public let name: String
    public let centerHex: UInt32; public let edgeHex: UInt32; public let patternHex: UInt32; public let textHex: UInt32
    public let permille: Int
}
public struct PatternSymbol: Hashable, Sendable { public let id: String; public let sfSymbol: String; public let permille: Int }

/// Общие пулы атрибутов (раздел 5.2 / 4.4). Редкости в ‰ суммируются в 1000.
public enum AttributePools {
    public static let modelPermille: [Int] = [5, 5, 10, 10, 10, 15, 15, 20, 20, 25, 30, 40, 50, 60, 70, 80, 100, 120, 140, 175]
    /// От редких к частым — порядок соответствует `modelPermille`.
    static let modelNames = ["Cosmic", "Pearl", "Chrome", "Neon", "Golden", "Pixel", "Ruby", "Emerald", "Sapphire", "Amber",
                             "Shadow", "Candy", "Ocean", "Sunset", "Mint", "Frozen", "Rosewood", "Retro", "Midnight", "Original"]

    public static let models: [GiftModel] = zip(modelNames, modelPermille).enumerated().map { i, p in
        GiftModel(id: "m\(i)", name: p.0, permille: p.1)
    }

    // name, center, edge, pattern
    private static let backdropData: [(String, UInt32, UInt32, UInt32, Int)] = [
        ("Onyx Black", 0x2B2B2F, 0x000000, 0x4A4A52, 5), ("Obsidian", 0x1B2A3A, 0x05080C, 0x3D5873, 5), ("Black Opal", 0x3A2A4A, 0x0A0510, 0x6B4D8A, 5),
        ("Ruby Red", 0xE0424D, 0x8E1B26, 0xFF9AA2, 15), ("Sapphire", 0x3F7BE0, 0x1B3F8E, 0x9BC0FF, 15), ("Emerald", 0x2FBF8A, 0x137552, 0x8FF0C8, 15),
        ("Amethyst", 0xA25BE0, 0x5B2A8E, 0xD9B3FF, 15), ("Topaz", 0xF0A030, 0xA55E0E, 0xFFD99A, 15), ("Aquamarine", 0x2FC4D8, 0x127A8E, 0x9AF0FF, 15),
        ("Rose Quartz", 0xF08AA8, 0xA84A66, 0xFFC4D4, 15),
        ("Sunset", 0xFF8A4C, 0xC2431E, 0xFFC8A0, 30), ("Lagoon", 0x35B6B0, 0x17726E, 0xA0EEE9, 30), ("Lavender", 0xB69CF0, 0x6E55B8, 0xE0D4FF, 30),
        ("Peach", 0xFFB58A, 0xD4713C, 0xFFE0C8, 30), ("Forest", 0x4FA05A, 0x24602E, 0xA6DDAE, 30), ("Steel", 0x7C8BA0, 0x44505F, 0xC4CEDB, 30),
        ("Cherry", 0xD6405E, 0x8A1E36, 0xF5A0B2, 30), ("Mustard", 0xD8B030, 0x8E7010, 0xF2DF8A, 30), ("Indigo", 0x5560D0, 0x2A3088, 0xA8B0F5, 30),
        ("Coral", 0xFF7A6B, 0xB8392C, 0xFFBDB4, 30),
        ("Sky", 0x6CC4F5, 0x2E88C4, 0xC4EBFF, 58), ("Mint", 0x7FDDB0, 0x3C9C70, 0xCFF5E3, 58), ("Sand", 0xE0C8A0, 0xA48A5C, 0xF5E8D0, 58),
        ("Lilac", 0xCFA8E8, 0x8E64AC, 0xEBD6F7, 58), ("Moss", 0x94B862, 0x587A30, 0xCFE0AC, 58), ("Slate", 0x94A4B8, 0x5C6C80, 0xD0D9E4, 58),
        ("Cocoa", 0xB08868, 0x6A4A32, 0xDCC2A8, 58), ("Blush", 0xF5B8C0, 0xB87880, 0xFBDDE0, 58), ("Ice", 0xB4DCF0, 0x6C9CBC, 0xE4F4FB, 58),
        ("Honey", 0xF0C868, 0xB08A24, 0xF9E4AE, 58)
    ]

    public static let backdrops: [Backdrop] = backdropData.enumerated().map { i, d in
        Backdrop(id: "b\(i)", name: d.0, centerHex: d.1, edgeHex: d.2, patternHex: d.3,
                 textHex: (d.4 >= 58 ? 0x1C1C1E : 0xFFFFFF), permille: d.4)
    }

    private static let symbolNames = [
        "star.fill", "heart.fill", "crown.fill", "bolt.fill", "flame.fill", "leaf.fill", "moon.fill", "sun.max.fill",
        "snowflake", "drop.fill", "cloud.fill", "hare.fill", "tortoise.fill", "ladybug.fill", "pawprint.fill", "music.note",
        "gift.fill", "bell.fill", "key.fill", "lock.fill", "flag.fill", "bookmark.fill", "diamond.fill", "seal.fill",
        "shield.fill", "wand.and.stars", "sparkles", "teddybear.fill", "gamecontroller.fill", "camera.fill", "airplane", "car.fill",
        "bicycle", "cup.and.saucer.fill", "fork.knife", "trophy.fill", "puzzlepiece.fill", "face.smiling.fill", "hand.thumbsup.fill", "eye.fill"
    ]

    public static let symbols: [PatternSymbol] = {
        precondition(symbolNames.count == 40)
        let rest = 35, remaining = 975
        let base = remaining / rest, extra = remaining % rest   // 27 и 30 штук по 28
        return symbolNames.enumerated().map { i, n in
            let p = i < 5 ? 5 : base + ((i - 5) < extra ? 1 : 0)
            return PatternSymbol(id: "s\(i)", sfSymbol: n, permille: p)
        }
    }()

    public static func model(_ id: String) -> GiftModel? { models.first { $0.id == id } }
    public static func backdrop(_ id: String) -> Backdrop? { backdrops.first { $0.id == id } }
    public static func symbol(_ id: String) -> PatternSymbol? { symbols.first { $0.id == id } }

    static let modelTable = WeightedTable(weights: models.map { Double($0.permille) })
    static let backdropTable = WeightedTable(weights: backdrops.map { Double($0.permille) })
    static let symbolTable = WeightedTable(weights: symbols.map { Double($0.permille) })
}
