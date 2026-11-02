import Foundation
#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

/// Provably fair (раздел 11):
/// commit = SHA256(serverSeedHex), U = первые 52 бита HMAC-SHA256(key = serverSeedHex (UTF-8), msg = "clientSeed:nonce").
/// Для игр, которым нужно несколько чисел за раунд, к сообщению добавляется ":cursor" (cursor ≥ 1).
public enum Fair {
    public static func sha256Hex(_ string: String) -> String {
        SHA256.hash(data: Data(string.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    public static func randomServerSeedHex() -> String {
        var g = SystemRandomNumberGenerator()
        return (0..<32).map { _ in String(format: "%02x", UInt8.random(in: 0...255, using: &g)) }.joined()
    }

    public static func unit(serverSeedHex: String, clientSeed: String, nonce: Int, cursor: Int = 0) -> Double {
        let message = cursor == 0 ? "\(clientSeed):\(nonce)" : "\(clientSeed):\(nonce):\(cursor)"
        let mac = HMAC<SHA256>.authenticationCode(for: Data(message.utf8), using: SymmetricKey(data: Data(serverSeedHex.utf8)))
        let b = Array(mac)
        // 52 бита = 6 байт + старшие 4 бита седьмого
        var v: UInt64 = 0
        for i in 0..<6 { v = (v << 8) | UInt64(b[i]) }
        v = (v << 4) | UInt64(b[6] >> 4)
        return Double(v) / 4_503_599_627_370_496.0 // 2^52
    }
}

public final class FairStream: RandomSource {
    public let serverSeedHex: String
    public let clientSeed: String
    public let nonce: Int
    private var cursor = 0
    public init(serverSeedHex: String, clientSeed: String, nonce: Int) {
        self.serverSeedHex = serverSeedHex; self.clientSeed = clientSeed; self.nonce = nonce
    }
    public func nextUnit() -> Double {
        defer { cursor += 1 }
        return Fair.unit(serverSeedHex: serverSeedHex, clientSeed: clientSeed, nonce: nonce, cursor: cursor)
    }
}

public struct FairRound: Codable, Identifiable, Hashable, Sendable {
    public var id: Int { nonce }
    public let game: String
    public let serverSeedHex: String
    public let serverSeedHash: String
    public let clientSeed: String
    public let nonce: Int
    public let firstUnit: Double
    public var outcome: String
    public let date: Date

    /// Проверка: хеш совпадает с обязательством, а первое число воспроизводится из сидов.
    public var isValid: Bool {
        Fair.sha256Hex(serverSeedHex) == serverSeedHash &&
        abs(Fair.unit(serverSeedHex: serverSeedHex, clientSeed: clientSeed, nonce: nonce) - firstUnit) < 1e-15
    }
}

public struct FairState: Codable, Sendable {
    public var clientSeed: String
    public var nonce: Int
    public var pendingServerSeedHex: String
    public var history: [FairRound]

    public init() {
        clientSeed = "player"
        nonce = 0
        pendingServerSeedHex = Fair.randomServerSeedHex()
        history = []
    }
    public var pendingHash: String { Fair.sha256Hex(pendingServerSeedHex) }

    public func makeStream() -> FairStream {
        FairStream(serverSeedHex: pendingServerSeedHex, clientSeed: clientSeed, nonce: nonce)
    }

    /// Фиксирует раунд и готовит новый seed/nonce. Запись в историю — отдельно (`record`),
    /// чтобы seed не раскрывался до конца раунда (Crash).
    public mutating func commitRound(game: String, date: Date) -> FairRound {
        let round = FairRound(game: game, serverSeedHex: pendingServerSeedHex, serverSeedHash: pendingHash,
                              clientSeed: clientSeed, nonce: nonce,
                              firstUnit: Fair.unit(serverSeedHex: pendingServerSeedHex, clientSeed: clientSeed, nonce: nonce),
                              outcome: "", date: date)
        nonce += 1
        pendingServerSeedHex = Fair.randomServerSeedHex()
        return round
    }

    public mutating func record(_ round: FairRound, outcome: String, limit: Int) {
        var r = round; r.outcome = outcome
        history.insert(r, at: 0)
        if history.count > limit { history.removeLast(history.count - limit) }
    }
}
