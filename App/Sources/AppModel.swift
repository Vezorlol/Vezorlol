import SwiftUI
import Observation
import UserNotifications
import GiftCasesCore

/// Мост между SwiftUI и игровым движком: хранит состояние на диске (JSON-снимок),
/// ведёт доверенные часы и обновляет UI после каждой операции.
@MainActor
@Observable
final class AppModel {
    let engine: GameEngine
    let trustedClock: TrustedClock
    private(set) var revision = 0
    private(set) var now = Date()
    var alert: String?
    var levelUp: LevelDef?
    private var lastLevel: Int
    private var timer: Timer?
    /// Перемотка времени (только Debug-сборка).
    fileprivate let debugBox: DebugOffset

    private static var saveURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("game_state.json")
    }

    init() {
        let catalog = try! Catalog.bundled()
        let rules = try! EconomyRules.bundled()
        let saved = (try? Data(contentsOf: Self.saveURL)).flatMap { try? JSONDecoder().decode(GameState.self, from: $0) }
        let clock = TrustedClock(state: saved?.trusted)
        trustedClock = clock
        let box = DebugOffset()
        debugBox = box
        engine = GameEngine(catalog: catalog, rules: rules, state: saved, clock: { clock.now().addingTimeInterval(box.seconds) })
        lastLevel = engine.currentLevel().level
        Haptics.enabled = engine.state.settings.haptics
        Sound.enabled = engine.state.settings.sound
        now = clock.now().addingTimeInterval(box.seconds)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        Task { [weak self] in
            if let net = await TrustedClock.fetchNetworkDate() { self?.trustedClock.sync(networkDate: net); self?.changed() }
        }
    }

    private func tick() { now = engine.clock() }

    /// Вызывать после любого изменения состояния.
    func changed() {
        engine.setTrusted(trustedClock.state)
        if let data = try? JSONEncoder().encode(engine.state) { try? data.write(to: Self.saveURL, options: .atomic) }
        revision += 1
        now = engine.clock()
        let lvl = engine.currentLevel()
        if lvl.level > lastLevel { levelUp = lvl; Haptics.notify(.success) }
        lastLevel = lvl.level
    }

    /// Выполняет операцию движка; ошибки показываются алертом.
    @discardableResult
    func run<T>(_ op: () throws -> T) -> T? {
        do { let r = try op(); changed(); return r }
        catch let e as GameError { alert = Self.message(e); Haptics.notify(.error); return nil }
        catch { alert = error.localizedDescription; return nil }
    }

    static func message(_ e: GameError) -> String {
        switch e {
        case .insufficientFunds: return "Недостаточно звёзд"
        case .overLimit(let m): return "Максимальная ставка на вашем уровне — \(StarsFormat.string(m)) ⭐"
        case .betTooSmall(let m): return "Минимальная ставка — \(StarsFormat.string(m)) ⭐"
        case .caseLocked(let l): return "Кейс откроется на уровне \(l)"
        case .notFound: return "Предмет не найден"
        case .invalidSelection: return "Некорректный выбор"
        case .notAvailable: return "Пока недоступно"
        case .outOfStock: return "Закончилось"
        case .roundInProgress: return "Раунд уже идёт"
        }
    }

    // MARK: Чтение (зависимость от revision/now обеспечивает перерисовку)

    private func touch() { _ = revision; _ = now }
    var state: GameState { touch(); return engine.state }
    var catalog: Catalog { engine.catalog }
    var rules: EconomyRules { engine.rules }
    var balance: Stars { touch(); return engine.state.balance }
    var level: LevelDef { touch(); return engine.currentLevel() }
    var inventoryValue: Stars { touch(); return engine.inventoryValue() }
    var maxBet: Stars { touch(); return engine.maxBet() }
    var inventory: [AnyGift] { touch(); return engine.inventory }
    func value(of g: AnyGift) -> Stars { touch(); return engine.value(of: g) }
    func sellPrice(of g: AnyGift) -> Stars { touch(); return engine.sellPrice(of: g) }
    var dayNumber: Int { touch(); return engine.index.dayNumber(for: now) }
    func change24h(_ c: GiftCollection) -> Double { touch(); return engine.index.change24h(collection: c, day: dayNumber) }
    func history(_ c: GiftCollection) -> [Double] { touch(); return engine.index.history(collection: c, endingAt: dayNumber) }
    func indexNow(_ c: GiftCollection) -> Double { touch(); return engine.index.index(collection: c, day: dayNumber) }
    var piggyAccrued: Stars { touch(); return engine.piggyAccrued() }
    var piggyFill: Double { touch(); return engine.piggyFill() }
    var piggySecondsToFull: TimeInterval { touch(); return Piggy.secondsToFull(engine.state.piggy, now: now, level: engine.currentLevel()) }
    var freeTimerRemaining: TimeInterval { touch(); return engine.freeTimerRemaining() }
    var dailyAvailable: DailyReward? { touch(); return engine.dailyAvailable() }
    var levelProgress: Double { touch(); return engine.levels.progress(inventoryValue: engine.inventoryValue()) }

    // MARK: Настройки

    func setHaptics(_ on: Bool) { engine.updateSettings { $0.haptics = on }; Haptics.enabled = on; changed() }
    func setSound(_ on: Bool) { engine.updateSettings { $0.sound = on }; Sound.enabled = on; changed() }
    func setTheme(_ t: String) { engine.updateSettings { $0.theme = t }; changed() }
    var colorScheme: ColorScheme? {
        switch engine.state.settings.theme { case "light": return .light; case "dark": return .dark; default: return nil }
    }

    func resetProgress() {
        engine.reset()
        try? FileManager.default.removeItem(at: Self.saveURL)
        lastLevel = 1
        changed()
    }

    // MARK: Уведомление «копилка заполнена»

    func schedulePiggyNotification() {
        let secs = max(60, piggySecondsToFull)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["piggy"])
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Копилка заполнена"
            content.body = "Заберите накопленные звёзды ⭐"
            let req = UNNotificationRequest(identifier: "piggy", content: content,
                                            trigger: UNTimeIntervalNotificationTrigger(timeInterval: secs, repeats: false))
            center.add(req)
        }
    }

    // MARK: Отображение подарков

    func display(_ g: AnyGift) -> GiftDisplay {
        switch g {
        case .regular(let r):
            let def = catalog.regular(r.giftId)
            let parts = (def?.name ?? "").split(separator: " ", maxSplits: 1)
            return GiftDisplay(emoji: parts.first.map(String.init) ?? "🎁", artName: "gift_\(r.giftId)", variantArtName: nil, title: parts.count > 1 ? String(parts[1]) : (def?.name ?? ""),
                               subtitle: "", rarity: nil, backdrop: nil, symbol: nil, isUpgraded: true, isCrafted: false, craftRarity: nil)
        case .unique(let u):
            let col = catalog.collection(u.collectionId)
            return GiftDisplay(emoji: col?.emojiPlaceholder ?? "🎁", artName: "gift_\(u.collectionId)", variantArtName: u.isUpgraded ? "gift_\(u.collectionId)__\(artSlug(AttributePools.model(u.collectionId, u.modelId)?.name ?? ""))" : nil, title: col?.name ?? u.collectionId, subtitle: "#\(u.number)",
                               rarity: col?.tier, backdrop: u.isUpgraded ? AttributePools.backdrop(u.backdropId) : nil,
                               symbol: u.isUpgraded ? AttributePools.symbol(u.collectionId, u.symbolId) : nil,
                               isUpgraded: u.isUpgraded, isCrafted: u.isCrafted, craftRarity: u.craftRarity)
        }
    }
}

struct GiftDisplay {
    let emoji: String
    let artName: String
    let variantArtName: String?
    let title: String
    let subtitle: String
    let rarity: Rarity?
    let backdrop: Backdrop?
    let symbol: PatternSymbol?
    let isUpgraded: Bool
    let isCrafted: Bool
    let craftRarity: CraftRarity?
}

func formatDuration(_ seconds: TimeInterval) -> String {
    let s = Int(max(0, seconds))
    let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
    if h > 0 { return "\(h) ч \(m) мин" }
    if m > 0 { return "\(m) мин \(sec) с" }
    return "\(sec) с"
}

final class DebugOffset { var seconds: TimeInterval = 0 }

extension AppModel {
    /// Debug: сдвинуть игровое время вперёд.
    func debugAdvance(hours: Double) { debugBox.seconds += hours * 3600; changed() }
}

/// Совпадает с slug() в tools/*.py: нижний регистр, всё кроме a-z0-9 → «_».
func artSlug(_ s: String) -> String {
    var out = "", lastUnderscore = true
    for ch in s.lowercased() {
        if ch.isASCII && (ch.isLetter || ch.isNumber) { out.append(ch); lastUnderscore = false }
        else if !lastUnderscore { out.append("_"); lastUnderscore = true }
    }
    while out.hasSuffix("_") { out.removeLast() }
    return out
}
