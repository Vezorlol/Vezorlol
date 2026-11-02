import SwiftUI
import GiftCasesCore

enum InventoryFilter: String, CaseIterable, Identifiable {
    case all = "Все", collectible = "Коллекционные", regular = "Обычные"
    var id: String { rawValue }
}
enum InventorySort: String, CaseIterable, Identifiable {
    case newest = "Новые", priceDesc = "Цена ↓", priceAsc = "Цена ↑", rarity = "Редкость"
    var id: String { rawValue }
}

struct InventoryView: View {
    @Environment(AppModel.self) private var model
    @State private var filter: InventoryFilter = .all
    @State private var sort: InventorySort = .newest
    @State private var selecting = false
    @State private var selected = Set<UUID>()
    @State private var detail: AnyGift?
    @State private var confirmSell = false
    var onRoute: (AppRoute) -> Void = { _ in }

    private var items: [AnyGift] {
        var list = model.inventory
        switch filter {
        case .all: break
        case .collectible: list = list.filter { if case .unique = $0 { return true }; return false }
        case .regular: list = list.filter { if case .regular = $0 { return true }; return false }
        }
        func acquired(_ g: AnyGift) -> Date { switch g { case .regular(let r): return r.acquiredAt; case .unique(let u): return u.acquiredAt } }
        func rarity(_ g: AnyGift) -> Int { if case .unique(let u) = g, let c = model.catalog.collection(u.collectionId) { return Rarity.allCases.firstIndex(of: c.tier)! + 1 }; return 0 }
        switch sort {
        case .newest: list.sort { acquired($0) > acquired($1) }
        case .priceDesc: list.sort { model.value(of: $0) > model.value(of: $1) }
        case .priceAsc: list.sort { model.value(of: $0) < model.value(of: $1) }
        case .rarity: list.sort { rarity($0) > rarity($1) }
        }
        return list
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Фильтр", selection: $filter) { ForEach(InventoryFilter.allCases) { Text($0.rawValue).tag($0) } }
                    .pickerStyle(.segmented).padding(.horizontal, 16).padding(.vertical, 8)
                HStack {
                    Text("Стоимость инвентаря: \(StarsFormat.string(model.inventoryValue)) ⭐").font(.footnote).foregroundStyle(TG.secondary)
                    Spacer()
                }.padding(.horizontal, 16)
                ScrollView {
                    if items.isEmpty {
                        VStack(spacing: 8) {
                            Text("🎁").font(.system(size: 60))
                            Text("Пока пусто").font(.headline)
                            Text("Откройте кейс, чтобы получить первый подарок").font(.subheadline).foregroundStyle(TG.secondary)
                        }.padding(.top, 80)
                    }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(items, id: \.id) { g in
                            GiftCardView(gift: g, showsPrice: true)
                                .overlay(alignment: .topLeading) {
                                    if selecting { Image(systemName: selected.contains(g.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selected.contains(g.id) ? TG.accent : .white).padding(6) }
                                }
                                .onTapGesture {
                                    if selecting { if !selected.insert(g.id).inserted { selected.remove(g.id) } }
                                    else { detail = g }
                                }
                        }
                    }.padding(16)
                }
                if selecting && !selected.isEmpty {
                    Button("Продать \(selected.count) за \(StarsFormat.string(selectedTotal)) ⭐") { confirmSell = true }
                        .buttonStyle(PrimaryButtonStyle()).padding(16)
                }
            }
            .background(TG.groupedBackground)
            .navigationTitle("Подарки")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button(selecting ? "Готово" : "Выбрать") { selecting.toggle(); selected = [] } }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Menu { Picker("Сортировка", selection: $sort) { ForEach(InventorySort.allCases) { Text($0.rawValue).tag($0) } } }
                            label: { Image(systemName: "arrow.up.arrow.down") }
                        BalancePill()
                    }
                }
            }
            .sheet(item: Binding(get: { detail.map { Box(g: $0) } }, set: { detail = $0?.g })) { b in
                GiftDetailSheet(gift: b.g, onCraft: { onRoute(.craft) }, onUpgradeGame: { onRoute(.upgrade) })
                    .presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
            }
            .alert("Продать \(selected.count) подарков за \(StarsFormat.string(selectedTotal)) ⭐?", isPresented: $confirmSell) {
                Button("Продать", role: .destructive) {
                    if model.run({ try model.engine.sell(ids: Array(selected)) }) != nil { selected = []; selecting = false }
                }
                Button("Отмена", role: .cancel) {}
            }
        }
    }

    private struct Box: Identifiable { let g: AnyGift; var id: UUID { g.id } }
    private var selectedTotal: Stars {
        model.inventory.filter { selected.contains($0.id) }.reduce(0) { $0 + model.sellPrice(of: $1) }
    }
}

// MARK: - Маркет

struct MarketView: View {
    @Environment(AppModel.self) private var model
    @State private var tab = 0
    @State private var detailLot: MarketLot?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $tab) { Text("Лоты").tag(0); Text("Магазин").tag(1) }
                    .pickerStyle(.segmented).padding(16)
                ScrollView {
                    if tab == 0 { lots } else { shop }
                }
            }
            .background(TG.groupedBackground)
            .navigationTitle("Маркет").balanceToolbar()
            .sheet(item: $detailLot) { lot in LotSheet(lot: lot).presentationDetents([.medium, .large]).presentationDragIndicator(.visible) }
        }
    }

    private var lots: some View {
        let list = model.engine.marketLots()
        return VStack(alignment: .leading, spacing: 8) {
            Text("Обновление каждый час. Цена включает комиссию маркета: перепродать системе можно за 85% стоимости.")
                .font(.footnote).foregroundStyle(TG.secondary).padding(.horizontal, 16)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                ForEach(list) { lot in
                    Button { detailLot = lot } label: {
                        VStack(spacing: 6) {
                            GiftCardView(gift: .unique(lot.gift))
                            HStack { StarsText(amount: lot.price, font: .subheadline.weight(.semibold)).foregroundStyle(TG.text); Spacer() }
                        }.padding(8).background(TG.cell, in: RoundedRectangle(cornerRadius: 14))
                    }.buttonStyle(.plain)
                }
            }.padding(.horizontal, 16)
        }.padding(.bottom, 16)
    }

    private var shop: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Неулучшенные подарки по цене 0,5 × флор. Улучшение стоит 0,6 × флор и открывает случайные модель, фон и узор. Обновляется раз в сутки.")
                .font(.footnote).foregroundStyle(TG.secondary).padding(.horizontal, 16)
            ForEach(model.engine.shopSlots()) { slot in
                HStack(spacing: 12) {
                    Text(slot.collection.emojiPlaceholder).font(.system(size: 34))
                        .frame(width: 56, height: 56).background(TG.groupedBackground, in: RoundedRectangle(cornerRadius: 12))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(slot.collection.name).font(.headline)
                        Text("осталось \(slot.stock) из \(model.rules.unupgraded.stockPerSlot) · улучшить за \(StarsFormat.string(slot.upgradeCost)) ⭐")
                            .font(.caption).foregroundStyle(TG.secondary)
                    }
                    Spacer()
                    Button { model.run { try model.engine.buyShopItem(slot.id) } } label: {
                        HStack(spacing: 3) { Text(StarsFormat.string(slot.price)); StarIcon(size: 13) }
                            .font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                            .padding(.horizontal, 12).padding(.vertical, 7).background(TG.accent, in: Capsule())
                    }.disabled(slot.stock == 0)
                }
                .padding(12).background(TG.cell, in: RoundedRectangle(cornerRadius: 12)).padding(.horizontal, 16)
            }
        }.padding(.bottom, 16)
    }
}

struct LotSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let lot: MarketLot
    var body: some View {
        VStack(spacing: 14) {
            GiftDetailBody(gift: .unique(lot.gift))
            Button("Купить за \(StarsFormat.string(lot.price)) ⭐") {
                if model.run({ try model.engine.buyLot(lot.id) }) != nil { Haptics.notify(.success); dismiss() }
            }.buttonStyle(PrimaryButtonStyle()).padding(.horizontal, 16).padding(.bottom, 16)
        }.background(TG.groupedBackground)
    }
}

/// Карточка + заголовок + оценка (для лотов и целей апгрейда).
struct GiftDetailBody: View {
    @Environment(AppModel.self) private var model
    let gift: AnyGift
    var body: some View {
        let d = model.display(gift)
        VStack(spacing: 10) {
            GiftCardView(gift: gift, showsInfo: false).frame(width: 170).padding(.top, 20)
            Text("\(d.title) \(d.subtitle)").font(.title3.bold())
            if case .unique(let u) = gift, u.isUpgraded {
                if let m = AttributePools.model(u.collectionId, u.modelId) { Text("Модель: \(m.name)").font(.subheadline).foregroundStyle(TG.secondary) }
                if let b = AttributePools.backdrop(u.backdropId) { Text("Фон: \(b.name)").font(.subheadline).foregroundStyle(TG.secondary) }
            }
            Text("Оценка ≈ \(StarsFormat.withStar(model.value(of: gift)))").font(.subheadline)
        }
    }
}
