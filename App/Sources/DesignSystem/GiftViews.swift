import SwiftUI
import Charts
import GiftCasesCore

/// Источник графики подарков: PNG из Assets (gift_<id>), запасной вариант — эмодзи; позже подставить Lottie/PNG, не трогая экраны.
protocol GiftArtProvider {
    func model(for display: GiftDisplay, size: CGFloat) -> AnyView
}
struct EmojiGiftArt: GiftArtProvider {
    func model(for display: GiftDisplay, size: CGFloat) -> AnyView {
        if let v = display.variantArtName, UIImage(named: v) != nil {
            return AnyView(Image(v).resizable().scaledToFit().frame(width: size, height: size))
        }
        if UIImage(named: display.artName) != nil {
            return AnyView(Image(display.artName).resizable().scaledToFit().frame(width: size, height: size))
        }
        return AnyView(Text(display.emoji).font(.system(size: size)))
    }
}
enum GiftArt { static var provider: GiftArtProvider = EmojiGiftArt() }

/// Карточка подарка: радиальный градиент фона, кольца узора, модель в центре, подпись снизу.
struct GiftCardView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let gift: AnyGift
    var showsInfo = true
    var showsPrice = false
    @State private var breathe = false

    var body: some View {
        let d = model.display(gift)
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                background(d)
                if let sym = d.symbol, let bd = d.backdrop { pattern(sym, bd, width: w) }
                GiftArt.provider.model(for: d, size: w * 0.42)
                    .scaleEffect(reduceMotion ? 1 : (breathe ? 1.05 : 0.96))
                    .shadow(color: d.craftRarity?.color ?? .clear, radius: d.isCrafted ? 12 : 0)
                    .offset(y: showsInfo ? -w * 0.06 : 0)
                if showsInfo {
                    VStack {
                        HStack {
                            Spacer()
                            if d.isCrafted, let cr = d.craftRarity { ribbon("Crafted · \(cr.title)", cr.color) }
                            else if !d.isUpgraded { ribbon("Можно улучшить", .gray) }
                            else if let r = d.rarity { ribbon(r.rawValue, r.color) }
                        }
                        Spacer()
                        VStack(spacing: 0) {
                            Text(d.title).font(.system(size: max(10, w * 0.095), weight: .semibold)).lineLimit(1).minimumScaleFactor(0.7)
                            if !d.subtitle.isEmpty { Text(d.subtitle).font(.system(size: max(9, w * 0.08))).opacity(0.75) }
                            if showsPrice { StarsText(amount: model.value(of: gift), font: .system(size: max(10, w * 0.085), weight: .medium)) }
                        }
                        .foregroundStyle(d.backdrop.map { Color(hex: $0.textHex) } ?? TG.text)
                    }
                    .padding(6)
                }
            }
            .frame(width: w, height: geo.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) { breathe = true }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(d.title) \(d.subtitle)")
    }

    @ViewBuilder private func background(_ d: GiftDisplay) -> some View {
        if let b = d.backdrop {
            RadialGradient(colors: [Color(hex: b.centerHex), Color(hex: b.edgeHex)], center: .center, startRadius: 2, endRadius: 140)
        } else {
            TG.cell.overlay(Color.gray.opacity(0.08))
        }
    }

    private func pattern(_ s: PatternSymbol, _ b: Backdrop, width w: CGFloat) -> some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                let a = Double(i) / 6 * 2 * Double.pi
                Image(systemName: s.sfSymbol).font(.system(size: w * 0.11))
                    .offset(x: CGFloat(cos(a)) * w * 0.30, y: CGFloat(sin(a)) * w * 0.30)
            }
            ForEach(0..<10, id: \.self) { i in
                let a = Double(i) / 10 * 2 * Double.pi + 0.3
                Image(systemName: s.sfSymbol).font(.system(size: w * 0.08))
                    .offset(x: CGFloat(cos(a)) * w * 0.46, y: CGFloat(sin(a)) * w * 0.46)
            }
        }
        .foregroundStyle(Color(hex: b.patternHex).opacity(0.18))
    }

    private func ribbon(_ text: String, _ color: Color) -> some View {
        Text(text).font(.system(size: 9, weight: .bold)).foregroundStyle(.white)
            .padding(.horizontal, 6).padding(.vertical, 2).background(color, in: Capsule())
    }
}

// MARK: - Шторка деталей

struct GiftDetailSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let gift: AnyGift
    var onCraft: (() -> Void)?
    var onUpgradeGame: (() -> Void)?
    @State private var showValue = false

    private var unique: UniqueGift? { if case .unique(let u) = gift { return u }; return nil }

    var body: some View {
        let d = model.display(gift)
        ScrollView {
            VStack(spacing: 16) {
                GiftCardView(gift: gift, showsInfo: false).frame(width: 190).padding(.top, 20)
                Text("\(d.title) \(d.subtitle)").font(.title2.bold())
                if let u = unique, let col = model.catalog.collection(u.collectionId) {
                    attributesTable(u, col)
                    valueBlock(col, u)
                } else {
                    row("Цена", StarsFormat.withStar(model.value(of: gift)))
                        .card()
                }
                actions
            }
            .padding(.horizontal, 16).padding(.bottom, 24)
        }
        .background(TG.groupedBackground)
    }

    private func row(_ title: String, _ value: String, color: Color = TG.text) -> some View {
        HStack { Text(title).foregroundStyle(TG.secondary); Spacer(); Text(value).foregroundStyle(color).multilineTextAlignment(.trailing) }
    }

    private func pct(_ permille: Int) -> String { String(format: "%.1f%%", Double(permille) / 10).replacingOccurrences(of: ".", with: ",") }

    @ViewBuilder private func attributesTable(_ u: UniqueGift, _ col: GiftCollection) -> some View {
        let supply = model.rules.supply(of: col.tier)
        let hashPart: Double = Double(stableHash64(col.id) % 100) / 100.0
        let share: Double = 0.4 + 0.5 * hashPart
        let issued: Int = max(u.number, Int(Double(supply) * share))
        VStack(spacing: 10) {
            if u.isUpgraded {
                if u.isCrafted, let cr = u.craftRarity { row("Модель", "Crafted · \(cr.title)", color: cr.color) }
                else if let m = AttributePools.model(u.modelId) { row("Модель", "\(m.name) · \(pct(m.permille))") }
                if let b = AttributePools.backdrop(u.backdropId) { row("Фон", "\(b.name) · \(pct(b.permille))") }
                if let s = AttributePools.symbol(u.symbolId) { row("Узор", "\(s.sfSymbol) · \(pct(s.permille))") }
            } else {
                row("Статус", "Неулучшенный")
            }
            row("Редкость", col.tier.title, color: col.tier.color)
            row("Тираж", "выпущено \(StarsFormat.string(Stars(issued))) / \(StarsFormat.string(Stars(supply)))")
        }
        .card()
    }

    @ViewBuilder private func valueBlock(_ col: GiftCollection, _ u: UniqueGift) -> some View {
        let value = model.value(of: gift)
        VStack(alignment: .leading, spacing: 10) {
            Button { withAnimation { showValue.toggle() } } label: {
                HStack {
                    Text("Стоимость").foregroundStyle(TG.secondary)
                    Image(systemName: "info.circle").foregroundStyle(TG.accent)
                    Spacer()
                    Text("≈ \(StarsFormat.withStar(value))").foregroundStyle(TG.text)
                }
            }
            if showValue {
                Divider()
                let ch = model.change24h(col)
                row("Флор коллекции", StarsFormat.withStar(col.floor))
                row("Индекс сегодня", String(format: "×%.3f", model.indexNow(col)))
                row("Изменение за 24 ч", String(format: "%+.1f%%", ch * 100), color: ch >= 0 ? TG.success : TG.danger)
                row("Цена получения", StarsFormat.withStar(u.acquiredPrice))
                let hist = model.history(col)
                Chart(Array(hist.enumerated()), id: \.offset) { item in
                    LineMark(x: .value("День", item.offset), y: .value("Индекс", item.element)).foregroundStyle(TG.accent)
                    AreaMark(x: .value("День", item.offset), y: .value("Индекс", item.element)).foregroundStyle(TG.accent.opacity(0.15))
                }
                .chartYScale(domain: (hist.min() ?? 0.9) * 0.98 ... (hist.max() ?? 1.1) * 1.02)
                .frame(height: 90)
                Text("Индекс за 30 дней").font(.caption).foregroundStyle(TG.secondary)
            }
        }
        .card()
    }

    @ViewBuilder private var actions: some View {
        VStack(spacing: 10) {
            if let u = unique, !u.isUpgraded {
                Button("Улучшить за \(StarsFormat.string(model.engine.upgradeCost(of: u))) ⭐") {
                    if model.run({ try model.engine.upgradeGift(id: u.id) }) != nil { Haptics.notify(.success) }
                }.buttonStyle(PrimaryButtonStyle())
            }
            Button("Продать за \(StarsFormat.string(model.sellPrice(of: gift))) ⭐") {
                if model.run({ try model.engine.sell(ids: [gift.id]) }) != nil { dismiss() }
            }.buttonStyle(unique?.isUpgraded == false ? AnyButtonStyle(SecondaryButtonStyle()) : AnyButtonStyle(PrimaryButtonStyle()))
            if let u = unique, u.isUpgraded {
                HStack(spacing: 10) {
                    if let onCraft { Button("В крафт") { dismiss(); onCraft() }.buttonStyle(SecondaryButtonStyle()) }
                    if let onUpgradeGame { Button("В апгрейд") { dismiss(); onUpgradeGame() }.buttonStyle(SecondaryButtonStyle()) }
                }
            }
        }
    }
}

struct AnyButtonStyle: ButtonStyle {
    private let make: (Configuration) -> AnyView
    init<S: ButtonStyle>(_ s: S) { make = { AnyView(s.makeBody(configuration: $0)) } }
    func makeBody(configuration: Configuration) -> some View { make(configuration) }
}
