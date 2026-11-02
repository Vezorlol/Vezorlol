import SwiftUI
import GiftCasesCore

@main
struct GiftCasesApp: App {
    @State private var model = AppModel()
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .preferredColorScheme(model.colorScheme)
                .tint(TG.accent)
        }
    }
}

enum AppTab: Hashable { case cases, games, gifts, market, profile }

struct RootView: View {
    @Environment(AppModel.self) private var model
    @State private var tab: AppTab = .cases
    @State private var gamesPath: [AppRoute] = []

    var body: some View {
        @Bindable var model = model
        TabView(selection: $tab) {
            CasesView().tabItem { Label("Кейсы", systemImage: "shippingbox.fill") }.tag(AppTab.cases)
            GamesView(path: $gamesPath).tabItem { Label("Игры", systemImage: "gamecontroller.fill") }.tag(AppTab.games)
            InventoryView(onRoute: { r in gamesPath = [r]; tab = .games }).tabItem { Label("Подарки", systemImage: "gift.fill") }.tag(AppTab.gifts)
            MarketView().tabItem { Label("Маркет", systemImage: "cart.fill") }.tag(AppTab.market)
            ProfileView().tabItem { Label("Профиль", systemImage: "person.crop.circle.fill") }.tag(AppTab.profile)
        }
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .alert("Внимание", isPresented: Binding(get: { model.alert != nil }, set: { if !$0 { model.alert = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(model.alert ?? "") }
        .sheet(item: $model.levelUp) { lvl in LevelUpSheet(level: lvl).presentationDetents([.medium, .large]).presentationDragIndicator(.visible) }
        .fullScreenCover(isPresented: Binding(get: { !model.state.onboarded }, set: { _ in })) { OnboardingView() }
    }
}

extension LevelDef: Identifiable { public var id: Int { level } }
