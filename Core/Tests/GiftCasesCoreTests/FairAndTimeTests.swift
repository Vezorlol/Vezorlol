import XCTest
@testable import GiftCasesCore

final class FairAndTimeTests: XCTestCase {
    func testSHA256KnownVector() {
        XCTAssertEqual(Fair.sha256Hex("abc"), "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }

    func testUnitDeterministicAndInRange() {
        let a = Fair.unit(serverSeedHex: "aa", clientSeed: "me", nonce: 5)
        XCTAssertEqual(a, Fair.unit(serverSeedHex: "aa", clientSeed: "me", nonce: 5))
        XCTAssertNotEqual(a, Fair.unit(serverSeedHex: "aa", clientSeed: "me", nonce: 6))
        XCTAssertNotEqual(a, Fair.unit(serverSeedHex: "ab", clientSeed: "me", nonce: 5))
        var sum = 0.0
        for n in 0..<20_000 { let u = Fair.unit(serverSeedHex: "seed", clientSeed: "c", nonce: n); XCTAssertTrue((0..<1).contains(u)); sum += u }
        XCTAssertEqual(sum / 20_000, 0.5, accuracy: 0.01)
    }

    /// Ожидаемые значения посчитаны независимо (Python hmac/hashlib): U = первые 52 бита HMAC-SHA256(key=seedHex, "client:nonce[:cursor]").
    func testHMACMatchesIndependentComputation() {
        XCTAssertEqual(Fair.unit(serverSeedHex: "aa", clientSeed: "me", nonce: 5), 0.12496220953920179, accuracy: 1e-15)
        XCTAssertEqual(Fair.unit(serverSeedHex: "deadbeef", clientSeed: "player", nonce: 0), 0.639623496214972, accuracy: 1e-15)
        XCTAssertEqual(Fair.unit(serverSeedHex: "deadbeef", clientSeed: "player", nonce: 7, cursor: 2), 0.30171483553460976, accuracy: 1e-15)
    }

    func testRoundsVerifyAndSeedsRotate() throws {
        let (e, _) = T.engine()
        e.rngOverride = nil   // боевой provably fair
        e.debugGrant(10_000)
        let hash0 = e.state.fair.pendingHash
        try e.openCase("case_1")
        try e.openCase("case_2")
        XCTAssertNotEqual(e.state.fair.pendingHash, hash0)
        let h = e.state.fair.history
        XCTAssertEqual(h.count, 2)
        XCTAssertEqual(h[1].serverSeedHash, hash0, "до раунда показан хеш — после раунда раскрыт seed с тем же хешем")
        XCTAssertTrue(h.allSatisfy(\.isValid))
        XCTAssertEqual(h.map(\.nonce), [1, 0])
    }

    func testClientSeedChangesOutcome() {
        let a = Fair.unit(serverSeedHex: "s", clientSeed: "one", nonce: 0)
        let b = Fair.unit(serverSeedHex: "s", clientSeed: "two", nonce: 0)
        XCTAssertNotEqual(a, b)
    }

    func testFairHistoryLimit100() throws {
        let (e, _) = T.engine()
        e.rngOverride = nil
        e.debugGrant(100_000)
        for _ in 0..<120 { try e.openCase("case_1") }
        XCTAssertEqual(e.state.fair.history.count, 100)
    }

    // MARK: Время

    func testTrustedClockIgnoresDeviceClockChanges() {
        let mono = FakeMono(1000)
        let base = Date(timeIntervalSince1970: 2_000_000_000)
        nonisolated(unsafe) var device = base
        let clock = TrustedClock(state: TrustedTimeState(lastTrusted: base, monotonicAtTrusted: 1000), monotonic: mono, device: { device })
        mono.value = 1000 + 3600
        device = base.addingTimeInterval(-86400 * 30)   // назад
        XCTAssertEqual(clock.now(), base.addingTimeInterval(3600))
        device = base.addingTimeInterval(86400 * 30)    // вперёд
        XCTAssertEqual(clock.now(), base.addingTimeInterval(3600))
    }

    func testTrustedClockRebootFreezesWhenDeviceBehind() {
        let mono = FakeMono(5000)
        let base = Date(timeIntervalSince1970: 2_000_000_000)
        nonisolated(unsafe) var device = base
        let clock = TrustedClock(state: TrustedTimeState(lastTrusted: base, monotonicAtTrusted: 5000), monotonic: mono, device: { device })
        mono.value = 10 // перезагрузка
        device = base.addingTimeInterval(-3600)
        XCTAssertEqual(clock.now(), base, "заморожено")
        mono.value = 100
        XCTAssertEqual(clock.now(), base, "всё ещё заморожено — часы не догнали")
        device = base.addingTimeInterval(7200)
        XCTAssertEqual(clock.now(), base.addingTimeInterval(7200), "после догона идёт дальше")
    }

    func testTrustedClockSyncUsesNetwork() {
        let mono = FakeMono(0)
        let base = Date(timeIntervalSince1970: 2_000_000_000)
        let clock = TrustedClock(state: TrustedTimeState(lastTrusted: base, monotonicAtTrusted: 0), monotonic: mono, device: { base })
        mono.value = 100
        clock.sync(networkDate: base.addingTimeInterval(500))
        mono.value = 160
        XCTAssertEqual(clock.now(), base.addingTimeInterval(560))
    }
}
