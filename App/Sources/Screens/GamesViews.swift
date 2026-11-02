import SwiftUI
import GiftCasesCore

enum AppRoute: Hashable { case coinflip, crash, upgrade, craft }

struct GamesView: View {
    @Binding var path: [AppRoute]
    @Environment(AppModel.self) private var model
    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    link(.crash, "chart.line.uptrend.xyaxis", .red, "Crash", "Выводите до краха. До 1000×")
                    link(.coinflip, "circle.lefthalf.filled", .orange, "Coin Flip", "Звёзды или подарки против бота")
                    link(.upgrade, "arrow.up.forward.circle.fill", .green, "Апгрейд", "Обменяйте подарки на более дорогой")
                    link(.craft, "hammer.fill", .purple, "Крафт", "3 подарка одной коллекции → 1 редкий")
                } footer: {
                    Text("Лимит ставки на вашем уровне: \(StarsFormat.string(model.maxBet)) ⭐. Все игры имеют преимущество казино — звёзды игровые.")
                }
            }
            .navigationTitle("Игры").balanceToolbar()
            .navigationDestination(for: AppRoute.self) { r in
                switch r {
                case .coinflip: CoinFlipView()
                case .crash: CrashView()
                case .upgrade: UpgradeView()
                case .craft: CraftView()
                }
            }
        }
    }

    private func link(_ r: AppRoute, _ icon: String, _ color: Color, _ title: String, _ sub: String) -> some View {
        NavigationLink(value: r) {
            HStack(spacing: 12) {
                Image(systemName: icon).foregroundStyle(.white).frame(width: 30, height: 30)
                    .background(color, in: RoundedRectangle(cornerRadius: 7))
                VStack(alignment: .leading) { Text(title); Text(sub).font(.caption).foregroundStyle(TG.secondary) }
            }
        }
    }
}

// MARK: - Общие элементы

struct BetControl: View {
    @Environment(AppModel.self) private var model
    @Binding var bet: Stars
    var min: Stars = 10
    @State private var text = ""
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                TextField("Ставка", text: $text).keyboardType(.numberPad).font(.title3.monospacedDigit())
                    .onChange(of: text) { _, v in bet = Stars(v.filter(\.isNumber)) ?? 0 }
                StarIcon(size: 18)
            }.padding(12).background(TG.cell, in: RoundedRectangle(cornerRadius: 12))
            HStack(spacing: 8) {
                chip("½") { set(bet / 2) }
                chip("×2") { set(bet * 2) }
                chip("Макс") { set(Swift.min(model.maxBet, model.balance)) }
            }
            Text("Макс. ставка: \(StarsFormat.string(model.maxBet)) ⭐").font(.caption).foregroundStyle(TG.secondary)
        }
        .onAppear { text = String(bet) }
    }
    private func set(_ v: Stars) { let c = Swift.max(min, Swift.min(v, model.maxBet)); bet = c; text = String(c) }
    private func chip(_ t: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) { Text(t).font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity).padding(.vertical, 9)
            .background(TG.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 10)).foregroundStyle(TG.accent) }
    }
}

/// Мультивыбор подарков из инвентаря.
struct GiftPicker: View {
    @Environment(AppModel.self) private var model
    @Binding var selection: Set<UUID>
    var maxCount = 6
    var filter: (AnyGift) -> Bool = { _ in true }
    var body: some View {
        let items = model.inventory.filter(filter).sorted { model.value(of: $0) > model.value(of: $1) }
        if items.isEmpty {
            Text("Нет подходящих подарков").font(.subheadline).foregroundStyle(TG.secondary).frame(maxWidth: .infinity).padding(24)
        } else {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(items, id: \.id) { g in
                    GiftCardView(gift: g, showsPrice: true)
                        .overlay(alignment: .topLeading) {
                            Image(systemName: selection.contains(g.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selection.contains(g.id) ? TG.accent : .white).padding(6)
                        }
                        .opacity(selection.contains(g.id) || selection.count < maxCount ? 1 : 0.4)
                        .onTapGesture {
                            if selection.contains(g.id) { selection.remove(g.id) }
                            else if selection.count < maxCount { selection.insert(g.id) }
                            Haptics.impact(.light)
                        }
                }
            }
        }
    }
}

private let botNames = ["Алекс", "Мария", "Dmitry", "Katya", "Nikita", "Olga", "Max", "Sasha", "Vlad", "Anna", "Ivan", "Lena"]

// MARK: - Coin Flip

struct CoinFlipView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var mode = 0
    @State private var pick: CoinSide = .star
    @State private var bet: Stars = 50
    @State private var selection = Set<UUID>()
    @State private var angle: Double = 0
    @State private var busy = false
    @State private var status = "Выберите сторону и сделайте ставку"
    @State private var won: Bool?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Picker("Режим", selection: $mode) { Text("Звёзды").tag(0); Text("Подарки").tag(1) }.pickerStyle(.segmented)
                coin
                Text(status).font(.headline).foregroundStyle(won == true ? TG.success : won == false ? TG.danger : TG.text)
                HStack(spacing: 10) {
                    sideButton(.star, "Звезда")
                    sideButton(.gift, "Подарок")
                }
                if mode == 0 {
                    BetControl(bet: $bet, min: model.rules.bets.coinFlipMin)
                    Text("Выигрыш ×\(String(format: "%.2f", model.rules.coinFlip.starsMultiplier).replacingOccurrences(of: ".", with: ","))")
                        .font(.footnote).foregroundStyle(TG.secondary)
                } else {
                    GiftPicker(selection: $selection, maxCount: model.rules.coinFlip.maxGifts)
                    Text("Победа: подарки остаются + подарок стоимостью 85–100% ставки. Поражение: подарки сгорают.")
                        .font(.footnote).foregroundStyle(TG.secondary)
                }
                Button("Бросить монету") { play() }.buttonStyle(PrimaryButtonStyle()).disabled(busy)
            }.padding(16)
        }
        .background(TG.groupedBackground).navigationTitle("Coin Flip").balanceToolbar()
    }

    private var coin: some View {
        let a = angle.truncatingRemainder(dividingBy: 360)
        let back = a > 90 && a < 270
        return ZStack {
            Circle().fill(LinearGradient(colors: [TG.starTop, TG.starBottom], startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle().stroke(.white.opacity(0.5), lineWidth: 4).padding(6)
            if back { Text("🎁").font(.system(size: 64)).rotation3DEffect(.degrees(180), axis: (x: 1, y: 0, z: 0)) }
            else { StarIcon(size: 70) }
        }
        .frame(width: 140, height: 140)
        .rotation3DEffect(.degrees(angle), axis: (x: 1, y: 0, z: 0))
        .shadow(radius: 8, y: 6)
        .padding(.vertical, 12)
        .accessibilityLabel("Монета")
    }

    private func sideButton(_ s: CoinSide, _ title: String) -> some View {
        Button { pick = s } label: {
            Text(title).font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(pick == s ? TG.accent : TG.cell, in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(pick == s ? .white : TG.text)
        }
    }

    private func play() {
        guard !busy else { return }
        let outcome: CoinFlipOutcome?
        if mode == 0 { outcome = model.run { try model.engine.coinFlipStars(bet: bet, pick: pick) } }
        else { outcome = model.run { try model.engine.coinFlipGifts(ids: Array(selection), pick: pick) } }
        guard let o = outcome else { return }
        busy = true; won = nil
        status = "Ищем соперника…"
        let bot = botNames.randomElement()!
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1...2)) {
            status = "Соперник: \(bot). Бросаем!"
            let turns = reduceMotion ? 0.0 : 360.0 * 4
            let target = (o.side == .star ? 0.0 : 180.0)
            let base = angle - angle.truncatingRemainder(dividingBy: 360)
            withAnimation(.easeInOut(duration: reduceMotion ? 0.2 : 1.6)) { angle = base + turns + target }
            DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.3 : 1.7)) {
                busy = false; won = o.won; selection = []
                status = o.won ? "Победа! +\(StarsFormat.string(o.payout)) ⭐" : "Не повезло"
                Haptics.notify(o.won ? .success : .error)
            }
        }
    }
}

// MARK: - Crash

struct CrashView: View {
    @Environment(AppModel.self) private var model
    @State private var bet: Stars = 50
    @State private var useAuto = false
    @State private var auto: Double = 2.0
    @State private var clockNow = Date()
    @State private var outcome: CrashOutcome?
    @State private var shake: CGFloat = 0
    @State private var flash = false
    @State private var bots: [(name: String, bet: Stars, cash: Double)] = []
    private let timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    var body: some View {
        let active = model.state.activeCrash
        let t = active.map { clockNow.timeIntervalSince($0.startedAt) } ?? 0
        ScrollView {
            VStack(spacing: 14) {
                history
                graph(active: active, t: t)
                if let a = active {
                    if t >= 0 {
                        let m = min(a.crashPoint, GameMath.crashMultiplier(atSeconds: t, rules: model.rules))
                        Button("Забрать \(StarsFormat.string(GameMath.crashPayout(bet: a.bet, multiplier: m))) ⭐") { cashOut() }
                            .buttonStyle(PrimaryButtonStyle(color: TG.success, pressedColor: TG.success.opacity(0.8)))
                    } else {
                        Text("Ставка принята. Старт через \(Int(ceil(-t))) с").foregroundStyle(TG.secondary)
                    }
                } else {
                    if let o = outcome { resultBanner(o) }
                    BetControl(bet: $bet, min: 1)
                    Toggle("Автовывод", isOn: $useAuto).tint(TG.accent)
                    if useAuto {
                        Stepper(value: $auto, in: 1.01...1000, step: 0.25) { Text("на ×\(String(format: "%.2f", auto))").monospacedDigit() }
                    }
                    Button("Сделать ставку") { place() }.buttonStyle(PrimaryButtonStyle())
                }
                botList(t: t, m: active.map { min($0.crashPoint, GameMath.crashMultiplier(atSeconds: max(0, t), rules: model.rules)) } ?? 1)
            }.padding(16)
        }
        .background(TG.groupedBackground).navigationTitle("Crash").balanceToolbar()
        .offset(x: shake)
        .onReceive(timer) { _ in tick() }
    }

    private var history: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(model.state.crashHistory.enumerated()), id: \.offset) { item in
                    let x = item.element
                    Text(String(format: "%.2f×", x)).font(.caption.bold().monospacedDigit())
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background((x >= 10 ? Color.orange : x >= 2 ? TG.success : TG.secondary).opacity(0.2), in: Capsule())
                        .foregroundStyle(x >= 10 ? Color.orange : x >= 2 ? TG.success : TG.secondary)
                }
            }
        }.frame(height: 26)
    }

    private func graph(active: CrashRound?, t: Double) -> some View {
        let rules = model.rules
        let live = active != nil && t >= 0
        let m = active.map { min($0.crashPoint, GameMath.crashMultiplier(atSeconds: max(0, t), rules: rules)) } ?? 1.0
        return ZStack {
            RoundedRectangle(cornerRadius: 16).fill(flash ? TG.danger.opacity(0.35) : TG.cell)
            GeometryReader { geo in
                let tMax = max(8, t * 1.15), mMax = max(2, m * 1.2)
                let curve = Path { p in
                    let steps = 60
                    for i in 0...steps {
                        let tt = tMax * Double(i) / Double(steps)
                        if live && tt > t { break }
                        let mm = GameMath.crashMultiplier(atSeconds: tt, rules: rules)
                        let pt = CGPoint(x: geo.size.width * CGFloat(tt / tMax), y: geo.size.height * (1 - CGFloat((mm - 1) / (mMax - 1))))
                        if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                    }
                }
                if live {
                    curve.stroke(outcomeColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    Path { p in
                        p.addPath(curve)
                        p.addLine(to: CGPoint(x: geo.size.width * CGFloat(t / tMax), y: geo.size.height))
                        p.addLine(to: CGPoint(x: 0, y: geo.size.height))
                        p.closeSubpath()
                    }.fill(LinearGradient(colors: [outcomeColor.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom))
                }
            }.padding(12)
            Text(live ? String(format: "%.2f×", m) : (active != nil ? "…" : (outcomeText ?? "1.00×")))
                .font(.system(size: 46, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(outcomeColor)
        }
        .frame(height: 220)
    }

    private var outcomeText: String? {
        if case .lost(let c) = outcome { return String(format: "Краш %.2f×", c) }
        if case .won(let m, _) = outcome { return String(format: "%.2f×", m) }
        return nil
    }
    private var outcomeColor: Color { if case .lost = outcome { return TG.danger }; return TG.text }

    private func resultBanner(_ o: CrashOutcome) -> some View {
        switch o {
        case .won(let m, let p): return Text("Вывод ×\(String(format: "%.2f", m)): +\(StarsFormat.string(p)) ⭐").foregroundStyle(TG.success).font(.headline)
        case .lost: return Text("Раунд проигран").foregroundStyle(TG.danger).font(.headline)
        }
    }

    private func botList(t: Double, m: Double) -> some View {
        VStack(spacing: 0) {
            ForEach(bots.indices, id: \.self) { i in
                let b = bots[i]
                let cashed = t >= 0 && m >= b.cash
                HStack {
                    Text(b.name); Spacer()
                    StarsText(amount: b.bet, font: .subheadline)
                    Text(cashed ? String(format: "×%.2f", b.cash) : "—").frame(width: 70, alignment: .trailing)
                        .foregroundStyle(cashed ? TG.success : TG.secondary).monospacedDigit()
                }.padding(.vertical, 6)
                if i < bots.count - 1 { Divider() }
            }
        }.card().opacity(bots.isEmpty ? 0 : 1)
    }

    private func place() {
        outcome = nil
        let auto = useAuto ? self.auto : nil
        guard let cr = model.run({ try model.engine.startCrash(bet: bet, autoCashout: auto) }) else { return }
        let rng = SplitMix64(seed: UInt64(cr.fair.nonce) &+ 1234)
        bots = (0..<Int.random(in: 8...13)).map { _ in
            (botNames.randomElement()!, Stars(rng.nextInt(in: 10...300)), max(1.05, 1 + (-log(1 - rng.nextUnit())) * 1.6))
        }
        Haptics.impact(.medium)
    }

    private func cashOut() {
        if let o = model.run({ try model.engine.cashOutCrash() }) { finish(o) }
    }

    private func tick() {
        clockNow = model.trustedClock.now()
        guard let a = model.state.activeCrash else { return }
        let t = clockNow.timeIntervalSince(a.startedAt)
        let rules = model.rules
        let crashed = t >= GameMath.crashTime(forMultiplier: a.crashPoint, rules: rules)
        let autoHit = a.autoCashout.map { $0 <= a.crashPoint && t >= GameMath.crashTime(forMultiplier: $0, rules: rules) } ?? false
        if crashed || autoHit, let o = model.run({ try model.engine.advanceCrash() }), let oo = o { finish(oo) }
    }

    private func finish(_ o: CrashOutcome) {
        outcome = o
        switch o {
        case .won: Haptics.notify(.success)
        case .lost:
            Haptics.notify(.error)
            flash = true
            withAnimation(.easeOut(duration: 0.5)) { flash = false }
            withAnimation(.interpolatingSpring(stiffness: 700, damping: 6)) { shake = 8 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { withAnimation { shake = 0 } }
        }
    }
}

// MARK: - Апгрейд

struct UpgradeView: View {
    @Environment(AppModel.self) private var model
    @State private var stake = Set<UUID>()
    @State private var target: MarketLot?
    @State private var spin: Double = 0
    @State private var busy = false
    @State private var message: String?

    var body: some View {
        let stakeValue = model.inventory.filter { stake.contains($0.id) }.reduce(Stars(0)) { $0 + model.value(of: $1) }
        let lots = model.engine.marketLots().filter { Double($0.value) >= model.rules.upgrade.minTargetRatio * Double(max(1, stakeValue)) }
        let chance = target.map { GameMath.upgradeChance(stake: stakeValue, target: $0.value, rules: model.rules) } ?? 0
        ScrollView {
            VStack(spacing: 14) {
                wheel(chance: chance)
                if let m = message { Text(m).font(.headline) }
                Text("Ваши подарки (до \(model.rules.upgrade.maxItems)) — \(StarsFormat.withStar(stakeValue)) / лимит \(StarsFormat.string(model.maxBet))")
                    .font(.footnote).foregroundStyle(TG.secondary)
                GiftPicker(selection: $stake, maxCount: model.rules.upgrade.maxItems)
                Divider()
                Text("Цель (стоимость ≥ 1,2 × ставки)").font(.subheadline).foregroundStyle(TG.secondary)
                if stake.isEmpty { Text("Сначала выберите подарки").foregroundStyle(TG.secondary) }
                else if lots.isEmpty { Text("Нет подходящих целей в Маркете").foregroundStyle(TG.secondary) }
                else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(lots) { lot in
                            GiftCardView(gift: .unique(lot.gift), showsPrice: true)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(target?.id == lot.id ? TG.accent : .clear, lineWidth: 3))
                                .onTapGesture { target = lot }
                        }
                    }
                }
                Button("Апгрейд (шанс \(String(format: "%.1f", chance * 100))%)") { go() }
                    .buttonStyle(PrimaryButtonStyle()).disabled(busy || target == nil || stake.isEmpty)
            }.padding(16)
        }
        .background(TG.groupedBackground).navigationTitle("Апгрейд").balanceToolbar()
    }

    private func wheel(chance: Double) -> some View {
        ZStack {
            Circle().stroke(TG.separator, lineWidth: 16)
            Circle().trim(from: 0, to: chance).stroke(TG.success, style: StrokeStyle(lineWidth: 16, lineCap: .butt))
                .rotationEffect(.degrees(-90))
            ZStack { Image(systemName: "arrowtriangle.down.fill").foregroundStyle(TG.accent).offset(y: -92) }
                .frame(width: 190, height: 190)
                .rotationEffect(.degrees(spin))
            Text(String(format: "%.1f%%", chance * 100)).font(.title.bold().monospacedDigit())
        }.frame(width: 190, height: 190).padding(.vertical, 10)
    }

    private func go() {
        guard let target, !busy, let o = model.run({ try model.engine.upgradeGame(stakeIds: Array(stake), target: target) }) else { return }
        busy = true; message = nil
        // стрелка останавливается внутри зелёного сектора при победе и вне него при поражении
        let c = o.chance * 360
        let landing = o.won ? Double.random(in: 4...max(5, c - 4)) : Double.random(in: min(356, c + 4)...356)
        let base = spin - spin.truncatingRemainder(dividingBy: 360)
        withAnimation(.easeOut(duration: 3)) { spin = base + 360 * 4 + landing }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.1) {
            busy = false; stake = []; self.target = nil
            message = o.won ? "Успех! Подарок получен" : "Не повезло — ставка сгорела"
            Haptics.notify(o.won ? .success : .error)
        }
    }
}

// MARK: - Крафт

struct CraftView: View {
    @Environment(AppModel.self) private var model
    @State private var selection = Set<UUID>()
    @State private var crafted: UniqueGift?
    @State private var animating = false

    var body: some View {
        let burn = model.engine.craftPreview(ids: Array(selection))
        let n = model.rules.craft.inputCount
        ScrollView {
            VStack(spacing: 14) {
                Text("Выберите \(n) коллекционных подарка одной коллекции").font(.subheadline).foregroundStyle(TG.secondary)
                GiftPicker(selection: $selection, maxCount: n) { if case .unique = $0 { return true }; return false }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Шансы редкости модели").font(.footnote).foregroundStyle(TG.secondary)
                    ForEach(model.rules.craft.outcomes, id: \.rarity) { o in
                        HStack {
                            Text(o.rarity.title).foregroundStyle(o.rarity.color)
                            Spacer()
                            Text("\(Int((o.chance * 100).rounded()))% · ×\(String(format: "%g", o.multiplier)) к флору").foregroundStyle(TG.secondary)
                        }.font(.subheadline)
                    }
                }.card()
                if !selection.isEmpty { Text("Сгорит: \(selection.count) подарка на \(StarsFormat.string(burn)) ⭐").font(.footnote).foregroundStyle(TG.danger) }
                Button(animating ? "Крафтим…" : "Скрафтить") { craft() }
                    .buttonStyle(PrimaryButtonStyle()).disabled(selection.count != n || animating)
            }.padding(16)
        }
        .background(TG.groupedBackground).navigationTitle("Крафт").balanceToolbar()
        .sheet(item: Binding(get: { crafted.map { CraftBox(g: $0) } }, set: { crafted = $0?.g })) { b in
            VStack(spacing: 14) {
                Text("Результат крафта").font(.headline).padding(.top, 20)
                GiftCardView(gift: .unique(b.g), showsInfo: true).frame(width: 190)
                Text("\(model.display(.unique(b.g)).title) \(model.display(.unique(b.g)).subtitle)").font(.title3.bold())
                StarsText(amount: model.value(of: .unique(b.g)), font: .title3)
                Spacer()
                Button("Отлично") { crafted = nil }.buttonStyle(PrimaryButtonStyle())
            }.padding(16).background(TG.groupedBackground).presentationDetents([.medium, .large])
        }
    }

    private struct CraftBox: Identifiable { let g: UniqueGift; var id: UUID { g.id } }

    private func craft() {
        animating = true
        let ids = Array(selection)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            animating = false
            if let g = model.run({ try model.engine.craft(ids: ids) }) { crafted = g; selection = []; Haptics.notify(.success) }
        }
    }
}
