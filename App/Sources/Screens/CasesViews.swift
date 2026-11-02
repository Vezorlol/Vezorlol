import SwiftUI
import GiftCasesCore

struct CasesView: View {
    @Environment(AppModel.self) private var model
    @State private var selected: CaseSelection?
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    struct CaseSelection: Identifiable { let id = UUID(); let def: CaseDef; let free: FreeCaseKind? }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    freeCard
                    ForEach(model.catalog.cases) { def in
                        let unlocked = model.engine.isUnlocked(caseId: def.id)
                        Button { if unlocked { selected = CaseSelection(def: def, free: nil) } else { model.alert = "Доступно с ур. \(model.rules.unlockLevel(forCase: def.id))" } } label: {
                            CaseCard(def: def, locked: !unlocked)
                        }.buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .background(TG.groupedBackground)
            .navigationTitle("Кейсы")
            .balanceToolbar()
            .sheet(item: $selected) { sel in
                CaseSheet(def: sel.def, free: sel.free).presentationDetents([.large]).presentationDragIndicator(.visible)
            }
        }
    }

    @ViewBuilder private var freeCard: some View {
        let remaining = model.freeTimerRemaining
        let tokens = model.state.freeCase.tokens
        let timerCase = model.catalog.caseDef(model.engine.levels.freeCaseId(level: model.level.level))
        let tokenCase = model.catalog.caseDef(model.rules.startFreeCaseId)
        Button {
            if tokens > 0, let c = tokenCase { selected = CaseSelection(def: c, free: .token) }
            else if remaining <= 0, let c = timerCase { selected = CaseSelection(def: c, free: .timer) }
        } label: {
            VStack(spacing: 6) {
                Text("🎁").font(.system(size: 44))
                Text("Бесплатный кейс").font(.headline).foregroundStyle(TG.text)
                if tokens > 0 { Text("Доступно открытий: \(tokens)").font(.caption).foregroundStyle(TG.success) }
                else if remaining > 0 { Text(formatDuration(remaining)).font(.caption).monospacedDigit().foregroundStyle(TG.secondary) }
                else { Text("Открыть").font(.caption.bold()).foregroundStyle(TG.success) }
            }
            .frame(maxWidth: .infinity, minHeight: 150)
            .background(TG.cell, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(TG.accent.opacity(0.5), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}

struct CaseCard: View {
    @Environment(AppModel.self) private var model
    let def: CaseDef
    let locked: Bool

    private var topEmoji: String {
        let best = def.drops.compactMap { d -> (String, Stars)? in
            switch model.catalog.resolve(d.item) {
            case .regular(let r): return (String(r.name.split(separator: " ").first ?? "🎁"), r.price)
            case .collection(let c): return (c.emojiPlaceholder, c.floor)
            case nil: return nil
            }
        }.max { $0.1 < $1.1 }
        return best?.0 ?? "🎁"
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Text(topEmoji).font(.system(size: 48)).opacity(locked ? 0.35 : 1)
                if locked { Image(systemName: "lock.fill").font(.title2).foregroundStyle(TG.secondary) }
            }
            Text(def.name).font(.headline).foregroundStyle(TG.text)
            if locked {
                Text("Доступно с ур. \(model.rules.unlockLevel(forCase: def.id))").font(.caption).foregroundStyle(TG.secondary)
            } else {
                StarsText(amount: def.price, font: .subheadline.weight(.semibold)).foregroundStyle(TG.text)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(TG.cell, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Шторка кейса

struct CaseSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let def: CaseDef
    let free: FreeCaseKind?

    @State private var spinning = false
    @State private var track: [AnyGift] = []
    @State private var winnerIndex = 52
    @State private var offset: CGFloat = 0
    @State private var result: CaseOpening?
    @State private var batch: [CaseOpening] = []
    @State private var quick = false
    @State private var showOdds = false

    private let cardW: CGFloat = 96, gap: CGFloat = 8

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if track.isEmpty { preview } else { roulette }
                Spacer(minLength: 0)
                controls
            }
            .padding(16)
            .background(TG.groupedBackground)
            .navigationTitle(def.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Шансы") { showOdds = true } } }
            .sheet(isPresented: $showOdds) { OddsSheet(def: def).presentationDetents([.medium, .large]).presentationDragIndicator(.visible) }
            .sheet(item: $result) { r in
                ResultSheet(opening: r, onClose: { track = []; if free != nil { dismiss() } })
                    .presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
            }
            .sheet(isPresented: Binding(get: { !batch.isEmpty }, set: { if !$0 { batch = [] } })) {
                BatchResultSheet(openings: batch).presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
            }
        }
    }

    private var preview: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: gap) {
                ForEach(def.drops.indices, id: \.self) { i in
                    GiftCardView(gift: model.previewGift(item: def.drops[i].item), showsInfo: true).frame(width: cardW)
                }
            }.padding(.vertical, 8)
        }
        .frame(height: cardW + 16)
    }

    private var roulette: some View {
        GeometryReader { geo in
            ZStack {
                HStack(spacing: gap) {
                    ForEach(track.indices, id: \.self) { i in
                        GiftCardView(gift: track[i], showsInfo: false).frame(width: cardW)
                    }
                }
                .offset(x: offset)
                .frame(width: geo.size.width, alignment: .leading)
                Rectangle().fill(TG.accent).frame(width: 3).shadow(color: TG.accent, radius: 4)
            }
            .clipped()
            .onAppear { spin(in: geo.size.width) }
        }
        .frame(height: cardW + 16)
    }

    private var controls: some View {
        VStack(spacing: 10) {
            Toggle("Быстро", isOn: $quick).tint(TG.accent).disabled(spinning)
            Button {
                open(count: 1)
            } label: {
                if free != nil { Text("Открыть бесплатно") }
                else { HStack(spacing: 4) { Text("Открыть за \(StarsFormat.string(def.price))"); StarIcon(size: 16) } }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(spinning)
            if free == nil {
                Button {
                    open(count: 5)
                } label: { HStack(spacing: 4) { Text("Открыть ×5 за \(StarsFormat.string(def.price * 5))"); StarIcon(size: 16) } }
                .buttonStyle(SecondaryButtonStyle()).disabled(spinning)
            }
        }
    }

    private func open(count: Int) {
        if count == 1 {
            let r: CaseOpening?
            if let kind = free { r = model.run { try model.engine.openFreeCase(kind) } }
            else { r = model.run { try model.engine.openCase(def.id) } }
            guard let r else { return }
            pending = r
            buildTrack(winner: r)
        } else {
            var list: [CaseOpening] = []
            for _ in 0..<count { if let r = model.run({ try model.engine.openCase(def.id) }) { list.append(r) } else { break } }
            if !list.isEmpty { Haptics.notify(.success); batch = list }
        }
    }

    @State private var pending: CaseOpening?

    private func buildTrack(winner: CaseOpening) {
        let table = WeightedTable(weights: def.drops.map(\.chancePercent))
        let rng = SystemRandomSource()
        var items = (0..<60).map { _ in model.previewGift(item: def.drops[table.pick(rng)].item) }
        winnerIndex = 50 + Int.random(in: 0...4)
        items[winnerIndex] = winner.gift
        offset = 0
        track = items
        spinning = true
    }

    private func spin(in width: CGFloat) {
        guard let r = pending else { return }
        let jitter = CGFloat.random(in: -cardW * 0.35...cardW * 0.35)
        let target = -(CGFloat(winnerIndex) * (cardW + gap) + cardW / 2 - width / 2) + jitter
        let duration: Double = reduceMotion ? 0.4 : (quick ? 1.0 : 5.5)
        withAnimation(.timingCurve(0.12, 0.0, 0.1, 1.0, duration: duration)) { offset = target }
        // тик-хаптик на каждой пройденной карточке (по обратной функции easing)
        let steps = winnerIndex
        if !reduceMotion {
            for i in 1...max(1, steps) {
                let p = Double(i) / Double(steps)
                let t = duration * (1 - pow(1 - p, 1.0 / 3.0)) * 0.98
                DispatchQueue.main.asyncAfter(deadline: .now() + t) { if spinning { Haptics.impact(.light) } }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.2) {
            spinning = false
            Haptics.notify(.success)
            result = r
            pending = nil
        }
    }
}

struct ResultSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let opening: CaseOpening
    var onClose: () -> Void = {}

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                Text("Вы получили").font(.subheadline).foregroundStyle(TG.secondary).padding(.top, 24)
                GiftCardView(gift: opening.gift, showsInfo: false).frame(width: 170)
                Text(model.display(opening.gift).title + " " + model.display(opening.gift).subtitle).font(.title2.bold())
                StarsText(amount: opening.value, font: .title3)
                Spacer()
                Button("Забрать") { dismiss(); onClose() }.buttonStyle(PrimaryButtonStyle())
                Button("Продать за \(StarsFormat.string(model.sellPrice(of: opening.gift))) ⭐") {
                    if model.run({ try model.engine.sell(ids: [opening.gift.id]) }) != nil { dismiss(); onClose() }
                }.buttonStyle(SecondaryButtonStyle())
            }
            .padding(16)
            ConfettiView()
        }
        .background(TG.groupedBackground)
    }
}

struct BatchResultSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let openings: [CaseOpening]
    var body: some View {
        VStack(spacing: 14) {
            Text("Результат").font(.title3.bold()).padding(.top, 20)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(openings.indices, id: \.self) { GiftCardView(gift: openings[$0].gift, showsPrice: true) }
            }
            Spacer()
            Button("Продать всё за \(StarsFormat.string(openings.reduce(0) { $0 + model.sellPrice(of: $1.gift) })) ⭐") {
                if model.run({ try model.engine.sell(ids: openings.map { $0.gift.id }) }) != nil { dismiss() }
            }.buttonStyle(SecondaryButtonStyle())
            Button("Забрать всё") { dismiss() }.buttonStyle(PrimaryButtonStyle())
        }
        .padding(16).background(TG.groupedBackground)
    }
}

struct OddsSheet: View {
    @Environment(AppModel.self) private var model
    let def: CaseDef
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(def.drops, id: \.item) { d in
                        HStack {
                            let g = model.previewGift(item: d.item)
                            GiftCardView(gift: g, showsInfo: false).frame(width: 40)
                            Text(model.display(g).title)
                            Spacer()
                            Text(String(format: "%.3f%%", d.chancePercent).replacingOccurrences(of: ".", with: ",")).foregroundStyle(TG.secondary).monospacedDigit()
                        }
                    }
                } footer: { Text("Сумма шансов — 100%. Модель, фон, узор и номер коллекционного подарка выбираются по их редкости.") }
            }
            .navigationTitle("Шансы").navigationBarTitleDisplayMode(.inline)
        }
    }
}

extension AppModel {
    /// Подарок для витрины (рулетка, шансы). Не попадает в инвентарь.
    func previewGift(item: String) -> AnyGift {
        switch catalog.resolve(item) {
        case .collection(let c):
            var alloc = NumberAllocator()
            return .unique(engine.factory.makeUpgraded(collection: c, source: .caseOpen, price: 0, now: now, allocator: &alloc, rng: SystemRandomSource()))
        case .regular(let r): return .regular(RegularItem(id: UUID(), giftId: r.id, acquiredAt: now))
        case nil: return .regular(RegularItem(id: UUID(), giftId: "giftbox", acquiredAt: now))
        }
    }
}

extension CaseOpening: Identifiable { public var id: UUID { gift.id } }
