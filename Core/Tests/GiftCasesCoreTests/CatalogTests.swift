import XCTest
@testable import GiftCasesCore

final class CatalogTests: XCTestCase {
    func testCounts() {
        XCTAssertEqual(T.catalog.regularGifts.count, 11)
        XCTAssertEqual(T.catalog.collectibles.count, 124)
        XCTAssertEqual(T.catalog.cases.count, 10)
        XCTAssertEqual(T.catalog.levels.count, 25)
        XCTAssertTrue(T.catalog.collectibles.allSatisfy { !$0.emojiPlaceholder.isEmpty })
    }

    func testTiersMatchSpecThresholds() {
        for c in T.catalog.collectibles {
            let expected: Rarity = c.floor < 500 ? .common : c.floor < 1500 ? .uncommon : c.floor < 6000 ? .rare : c.floor < 30000 ? .epic : .legendary
            XCTAssertEqual(c.tier, expected, c.name)
        }
    }

    func testCaseChancesSumTo100AndItemsResolve() {
        for c in T.catalog.cases {
            let sum = c.drops.reduce(0) { $0 + $1.chancePercent }
            XCTAssertEqual(sum, 100, accuracy: 0.0011, c.id)
            for d in c.drops { XCTAssertNotNil(T.catalog.resolve(d.item), "\(c.id): \(d.item)") }
        }
    }

    func testPermilleSums() {
        XCTAssertEqual(AttributePools.models.map(\.permille).reduce(0, +), 1000)
        XCTAssertEqual(AttributePools.backdrops.map(\.permille).reduce(0, +), 1000)
        XCTAssertEqual(AttributePools.symbols.map(\.permille).reduce(0, +), 1000)
        XCTAssertEqual(AttributePools.models.count, 20)
        XCTAssertEqual(AttributePools.backdrops.count, 30)
        XCTAssertEqual(AttributePools.symbols.count, 40)
    }

    func testLevelsMonotonic() {
        let l = T.catalog.levels
        for i in 1..<l.count {
            XCTAssertGreaterThan(l[i].inventoryValueFrom, l[i - 1].inventoryValueFrom)
            XCTAssertGreaterThan(l[i].incomePerHour, l[i - 1].incomePerHour)
        }
        XCTAssertEqual(T.catalog.level(for: 0).level, 1)
        XCTAssertEqual(T.catalog.level(for: 399).level, 1)
        XCTAssertEqual(T.catalog.level(for: 400).level, 2)
        XCTAssertEqual(T.catalog.level(for: 99_999_999).level, 25)
    }

    func testStarsFormat() {
        XCTAssertEqual(StarsFormat.string(12450), "12\u{00A0}450")
        XCTAssertEqual(StarsFormat.string(538000), "538\u{00A0}000")
        XCTAssertEqual(StarsFormat.string(7), "7")
    }
}
