import SwiftUI
import GiftCasesCore

struct ProfileView: View {
    @Environment(AppModel.self) private var model
    @State private var editingName = false
    @State private var name = ""
    @State private var confirmReset = false
    @State private var showEarn = false

    var body: some View {
        let lvl = model.level
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 8) {
                        avatar.padding(.top, 8)
                        HStack(spacing: 6) {
                            Text(model.state.playerName).font(.title2.bold())
                            LevelBadge(level: lvl.level)
                        }
                        .onTapGesture { name = model.state.playerName; editingName = true }
                        HStack(spacing: 4) { Text(StarsFormat.string(model.balance)).font(.title3.monospacedDigit()); StarIcon(size: 18) }
                        ProgressView(value: model.levelProgress).tint(TG.accent).padding(.horizontal, 30)
                        Text("Стоимость инвентаря \(StarsFormat.string(model.inventoryValue)) ⭐").font(.caption).foregroundStyle(TG.secondary)
                    }.frame(maxWidth: .infinity).listRowBackground(Color.clear)
                }

                Section("Копилка") { PiggyRow() }
                Section("Ежедневный бонус") { DailyRow() }

                Section("Статистика") {
                    stat("Открыто кейсов", "\(model.state.stats.casesOpened)")
                    stat("Лучший дроп", model.state.stats.bestDropValue > 0 ? "\(model.state.stats.bestDropName) · \(StarsFormat.string(model.state.stats.bestDropValue)) ⭐" : "—")
                    stat("Макс. икс в Crash", model.state.stats.maxCrashMultiplier > 0 ? String(format: "×%.2f", model.state.stats.maxCrashMultiplier) : "—")
                    stat("Выиграно всего", "\(StarsFormat.string(model.state.stats.totalWon)) ⭐")
                    stat("Проиграно всего", "\(StarsFormat.string(model.state.stats.totalLost)) ⭐")
                    stat("Доход в час", "\(StarsFormat.string(lvl.incomePerHour)) ⭐")
                }

                Section {
                    NavigationLink("Честность игры") { FairnessView() }
                    NavigationLink("Журнал транзакций") { LedgerView() }
                    NavigationLink("Настройки") { SettingsView() }
                    NavigationLink("О приложении") { AboutView() }
                }
                #if DEBUG
                Section("Debug") {
                    Button("+100 000 ⭐") { model.engine.debugGrant(100_000); model.changed() }
                    Button("Перемотать +1 час") { model.debugAdvance(hours: 1) }
                    Button("Перемотать +8 часов") { model.debugAdvance(hours: 8) }
                    Button("Перемотать +1 день") { model.debugAdvance(hours: 24) }
                }
                #endif
                Section { Button("Сбросить прогресс", role: .destructive) { confirmReset = true } }
            }
            .navigationTitle("Профиль").balanceToolbar()
            .alert("Имя", isPresented: $editingName) {
                TextField("Имя", text: $name)
                Button("Сохранить") { model.engine.setName(name); model.changed() }
                Button("Отмена", role: .cancel) {}
            }
            .alert("Сбросить весь прогресс?", isPresented: $confirmReset) {
                Button("Сбросить", role: .destructive) { model.resetProgress() }
                Button("Отмена", role: .cancel) {}
            } message: { Text("Баланс, подарки и статистика будут удалены.") }
        }
    }

    private var avatar: some View {
        let initials = String(model.state.playerName.prefix(2)).uppercased()
        return Text(initials).font(.system(size: 34, weight: .bold)).foregroundStyle(.white)
            .frame(width: 88, height: 88)
            .background(LinearGradient(colors: [Color(hex: 0x6CC4F5), Color(hex: 0x2A7FD6)], startPoint: .top, endPoint: .bottom), in: Circle())
    }

    private func stat(_ t: String, _ v: String) -> some View {
        HStack { Text(t); Spacer(); Text(v).foregroundStyle(TG.secondary).multilineTextAlignment(.trailing) }
    }
}

struct PiggyRow: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        let fill = model.piggyFill
        HStack(spacing: 14) {
            ZStack {
                Circle().stroke(TG.separator, lineWidth: 6)
                Circle().trim(from: 0, to: fill).stroke(TG.starGradient, style: StrokeStyle(lineWidth: 6, lineCap: .round)).rotationEffect(.degrees(-90))
                Text("🐷").font(.title2)
            }.frame(width: 60, height: 60)
            VStack(alignment: .leading, spacing: 2) {
                Text("+\(StarsFormat.string(model.piggyAccrued)) ⭐").font(.headline.monospacedDigit())
                Text(fill >= 1 ? "Копилка заполнена" : "заполнится через \(formatDuration(model.piggySecondsToFull))")
                    .font(.caption).foregroundStyle(TG.secondary)
            }
            Spacer()
            Button("Забрать") {
                if model.run({ try model.engine.collectPiggy() }) != nil { Haptics.notify(.success); model.schedulePiggyNotification() }
            }
            .buttonStyle(.borderedProminent).tint(TG.accent).disabled(model.piggyAccrued <= 0)
        }
    }
}

struct DailyRow: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        let streak = model.state.daily.streak
        let avail = model.dailyAvailable
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { i in
                    let done = i < (avail == nil ? streak : streak % 7)
                    let reward = DailyBonus.reward(dayIndex: i, level: model.level.level, rules: model.rules)
                    VStack(spacing: 2) {
                        Text("\(i + 1)").font(.caption2).foregroundStyle(TG.secondary)
                        Text(i == 6 ? "🎁" : (done ? "✅" : "⭐")).font(.body)
                        Text("\(reward.stars)").font(.system(size: 10).monospacedDigit()).foregroundStyle(TG.secondary)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 6)
                    .background(i == avail?.dayIndex ? TG.accent.opacity(0.15) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
                }
            }
            Button(avail.map { "Забрать \(StarsFormat.string($0.stars)) ⭐" } ?? "Уже получено сегодня") {
                if model.run({ try model.engine.claimDaily() }) != nil { Haptics.notify(.success) }
            }.buttonStyle(PrimaryButtonStyle()).disabled(avail == nil).opacity(avail == nil ? 0.5 : 1)
        }
    }
}

// MARK: - Экран заработка (по нажатию на «+»)

struct EarnSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section("Копилка") { PiggyRow() }
                Section("Ежедневный бонус") { DailyRow() }
                Section("Бесплатный кейс") {
                    let tokens = model.state.freeCase.tokens, rem = model.freeTimerRemaining
                    HStack {
                        Text("🎁")
                        if tokens > 0 { Text("Доступно открытий: \(tokens)") }
                        else if rem > 0 { Text("Следующий через \(formatDuration(rem))").foregroundStyle(TG.secondary) }
                        else { Text("Готов к открытию — вкладка «Кейсы»").foregroundStyle(TG.success) }
                    }
                }
            }
            .navigationTitle("Заработать").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Готово") { dismiss() } } }
        }
    }
}

// MARK: - Честность

struct FairnessView: View {
    @Environment(AppModel.self) private var model
    @State private var clientSeed = ""
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Хеш следующего server seed (SHA-256)").font(.caption).foregroundStyle(TG.secondary)
                    Text(model.state.fair.pendingHash).font(.caption.monospaced()).textSelection(.enabled)
                }
                HStack { Text("Nonce"); Spacer(); Text("\(model.state.fair.nonce)").foregroundStyle(TG.secondary) }
                TextField("Client seed", text: $clientSeed).onSubmit { model.engine.setClientSeed(clientSeed); model.changed() }
            } footer: {
                Text("Результат = первые 52 бита HMAC-SHA256(ключ = server seed (hex-строка), сообщение = «clientSeed:nonce»). После раунда server seed раскрывается — сверьте хеш и результат любым сторонним инструментом.")
            }
            Section("Последние раунды (до 100)") {
                ForEach(model.state.fair.history) { r in
                    NavigationLink { RoundDetail(round: r) } label: {
                        HStack {
                            Image(systemName: r.isValid ? "checkmark.seal.fill" : "xmark.seal.fill").foregroundStyle(r.isValid ? TG.success : TG.danger)
                            VStack(alignment: .leading) { Text(r.game).font(.subheadline); Text(r.outcome).font(.caption).foregroundStyle(TG.secondary).lineLimit(1) }
                            Spacer(); Text("#\(r.nonce)").font(.caption).foregroundStyle(TG.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Честность игры").navigationBarTitleDisplayMode(.inline)
        .onAppear { clientSeed = model.state.fair.clientSeed }
    }
}

struct RoundDetail: View {
    let round: FairRound
    var body: some View {
        List {
            row("Игра", round.game); row("Nonce", "\(round.nonce)"); row("Client seed", round.clientSeed)
            row("Server seed", round.serverSeedHex); row("SHA-256(server seed)", round.serverSeedHash)
            row("U", String(format: "%.12f", round.firstUnit)); row("Итог", round.outcome)
            row("Проверка", round.isValid ? "✅ совпадает" : "❌ не совпадает")
        }.navigationTitle("Раунд #\(round.nonce)").navigationBarTitleDisplayMode(.inline)
    }
    private func row(_ t: String, _ v: String) -> some View {
        VStack(alignment: .leading, spacing: 2) { Text(t).font(.caption).foregroundStyle(TG.secondary); Text(v).font(.footnote.monospaced()).textSelection(.enabled) }
    }
}

struct LedgerView: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        List(model.state.ledger) { e in
            HStack {
                VStack(alignment: .leading) { Text(e.kind).font(.subheadline); Text(e.note).font(.caption).foregroundStyle(TG.secondary) }
                Spacer()
                Text((e.delta > 0 ? "+" : "") + StarsFormat.string(e.delta)).foregroundStyle(e.delta >= 0 ? TG.success : TG.danger).monospacedDigit()
            }
        }.navigationTitle("Журнал транзакций").navigationBarTitleDisplayMode(.inline)
    }
}

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        Form {
            Toggle("Звук", isOn: Binding(get: { model.state.settings.sound }, set: { model.setSound($0) }))
            Toggle("Вибрация", isOn: Binding(get: { model.state.settings.haptics }, set: { model.setHaptics($0) }))
            Picker("Тема", selection: Binding(get: { model.state.settings.theme }, set: { model.setTheme($0) })) {
                Text("Системная").tag("system"); Text("Светлая").tag("light"); Text("Тёмная").tag("dark")
            }
        }.navigationTitle("Настройки").navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Section { Text("Неофициальный фан-симулятор. Не связан с Telegram. Звёзды и подарки игровые и не имеют реальной ценности.") }
            Section("Возрастной рейтинг") { Text("17+ — симулированные азартные игры. Звёзды нельзя купить, вывести или обменять на реальные ценности.") }
        }.navigationTitle("О приложении").navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Онбординг и повышение уровня

struct OnboardingView: View {
    @Environment(AppModel.self) private var model
    @State private var page = 0
    private let pages: [(String, String, String)] = [
        ("🎁", "Открывайте кейсы", "Собирайте коллекционные подарки с уникальными моделями, фонами и узорами."),
        ("⭐", "Игровые звёзды", "Звёзды ненастоящие: их нельзя купить или вывести. Копилка и бонусы пополняют баланс."),
        ("🏆", "Растите уровень", "Чем дороже инвентарь, тем больше доход, лимиты и доступных кейсов.")
    ]
    var body: some View {
        VStack {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { i in
                    VStack(spacing: 16) {
                        Spacer(); Text(pages[i].0).font(.system(size: 90))
                        Text(pages[i].1).font(.title.bold()); Text(pages[i].2).multilineTextAlignment(.center).foregroundStyle(TG.secondary)
                        Spacer()
                    }.padding(.horizontal, 32).tag(i)
                }
            }.tabViewStyle(.page)
            Button(page < 2 ? "Продолжить" : "Начать") {
                if page < 2 { withAnimation { page += 1 } } else { model.engine.setOnboarded(); model.changed() }
            }.buttonStyle(PrimaryButtonStyle()).padding(16)
        }.background(TG.groupedBackground)
    }
}

struct LevelUpSheet: View {
    @Environment(AppModel.self) private var model
    let level: LevelDef
    var body: some View {
        ZStack {
            VStack(spacing: 14) {
                Spacer()
                LevelBadge(level: level.level, size: 100)
                Text("Новый уровень!").font(.title.bold())
                Text("Уровень \(level.level)").foregroundStyle(TG.secondary)
                VStack(alignment: .leading, spacing: 6) {
                    Text("• Доход копилки: \(StarsFormat.string(level.incomePerHour)) ⭐/час")
                    Text("• Вместимость копилки: \(level.accrualCapHours) ч")
                    Text("• Лимит ставки: \(StarsFormat.string(model.engine.levels.maxBet(level: level.level))) ⭐")
                    ForEach(model.catalog.cases.filter { model.rules.unlockLevel(forCase: $0.id) == level.level }) { Text("• Открыт кейс «\($0.name)»") }
                }.card()
                Spacer()
                Button("Отлично") { model.levelUp = nil }.buttonStyle(PrimaryButtonStyle())
            }.padding(16)
            ConfettiView()
        }.background(TG.groupedBackground)
    }
}
