import SwiftUI
import UIKit
import GiftCasesCore

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255,
                  blue: CGFloat(hex & 0xff) / 255, alpha: alpha)
    }
}

extension Color {
    init(hex: UInt32) { self.init(UIColor(hex: hex)) }
    init(light: UInt32, dark: UInt32) {
        self.init(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
    }
}

/// Токены дизайн-системы (раздел 4.1).
enum TG {
    static let groupedBackground = Color(light: 0xEFEFF4, dark: 0x000000)
    static let cell = Color(light: 0xFFFFFF, dark: 0x1C1C1E)
    static let separator = Color(light: 0xC8C7CC, dark: 0x38383A)
    static let text = Color(light: 0x000000, dark: 0xFFFFFF)
    static let secondary = Color(light: 0x8E8E93, dark: 0x8D8E93)
    static let accent = Color(hex: 0x2AABEE)
    static let accentPressed = Color(hex: 0x229ED9)
    static let success = Color(hex: 0x34C759)
    static let danger = Color(hex: 0xFF3B30)
    static let starTop = Color(hex: 0xFFD43B)
    static let starBottom = Color(hex: 0xF5A623)
    static let starGradient = LinearGradient(colors: [starTop, starBottom], startPoint: .top, endPoint: .bottom)
}

extension Rarity {
    var color: Color {
        switch self {
        case .common: return Color(hex: 0x8E8E93)
        case .uncommon: return Color(hex: 0x34C759)
        case .rare: return Color(hex: 0x2AABEE)
        case .epic: return Color(hex: 0xAF52DE)
        case .legendary: return Color(hex: 0xFF9500)
        }
    }
    var title: String {
        switch self {
        case .common: return "Обычный"
        case .uncommon: return "Необычный"
        case .rare: return "Редкий"
        case .epic: return "Эпический"
        case .legendary: return "Легендарный"
        }
    }
}

extension CraftRarity {
    var color: Color {
        switch self {
        case .uncommon: return Rarity.uncommon.color
        case .rare: return Rarity.rare.color
        case .epic: return Rarity.epic.color
        case .legendary: return Rarity.legendary.color
        }
    }
}

// MARK: - Звезда (собственная векторная иконка, не копия официальной)

struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.5
        var p = Path()
        for i in 0..<10 {
            let r = i % 2 == 0 ? outer : inner
            let a = -Double.pi / 2 + Double(i) * Double.pi / 5
            let pt = CGPoint(x: c.x + CGFloat(cos(a)) * r, y: c.y + CGFloat(sin(a)) * r)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

struct StarIcon: View {
    var size: CGFloat = 16
    var body: some View {
        ZStack {
            StarShape().stroke(TG.starBottom, style: StrokeStyle(lineWidth: size * 0.16, lineJoin: .round))
            StarShape().fill(TG.starGradient)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct StarsText: View {
    let amount: Stars
    var font: Font = .body
    var body: some View {
        HStack(spacing: 3) {
            Text(StarsFormat.string(amount)).font(font).monospacedDigit()
            StarIcon(size: 14)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(StarsFormat.string(amount)) звёзд")
    }
}

// MARK: - Кнопки

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = TG.accent
    var pressedColor: Color = TG.accentPressed
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(configuration.isPressed ? pressedColor : color)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(TG.accent)
            .frame(maxWidth: .infinity).frame(height: 50)
            .background(TG.accent.opacity(configuration.isPressed ? 0.22 : 0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Пилюля баланса

struct BalancePill: View {
    @Environment(AppModel.self) private var model
    @State private var showEarn = false
    var body: some View {
        Button { showEarn = true } label: {
            HStack(spacing: 4) {
                StarIcon(size: 15)
                Text(StarsFormat.string(model.balance)).font(.system(size: 15, weight: .semibold)).monospacedDigit()
                    .foregroundStyle(TG.text)
                Image(systemName: "plus").font(.system(size: 11, weight: .bold)).foregroundStyle(TG.accent)
            }
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .accessibilityLabel("Баланс \(StarsFormat.string(model.balance)) звёзд. Заработать")
        .sheet(isPresented: $showEarn) { EarnSheet().presentationDetents([.medium, .large]).presentationDragIndicator(.visible) }
    }
}

extension View {
    func balanceToolbar() -> some View {
        toolbar { ToolbarItem(placement: .topBarTrailing) { BalancePill() } }
    }
    func card() -> some View {
        padding(16).background(TG.cell, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Шестиугольный бейдж уровня

struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY), r = min(rect.width, rect.height) / 2
        var p = Path()
        for i in 0..<6 {
            let a = Double(i) * Double.pi / 3 - Double.pi / 2
            let pt = CGPoint(x: c.x + CGFloat(cos(a)) * r, y: c.y + CGFloat(sin(a)) * r)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

struct LevelBadge: View {
    let level: Int
    var size: CGFloat = 26
    var body: some View {
        ZStack {
            HexagonShape().fill(LinearGradient(colors: [TG.accent, Color(hex: 0x1C7FC4)], startPoint: .top, endPoint: .bottom))
            Text("\(level)").font(.system(size: size * 0.46, weight: .bold)).foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Уровень \(level)")
    }
}

// MARK: - Хаптики

/// Вызывается только с главного потока (UI).
enum Haptics {
    static var enabled = true
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard enabled else { return }
        MainActor.assumeIsolated { UIImpactFeedbackGenerator(style: style).impactOccurred() }
    }
    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard enabled else { return }
        MainActor.assumeIsolated { UINotificationFeedbackGenerator().notificationOccurred(type) }
    }
}

// MARK: - Конфетти из звёзд

struct ConfettiView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var go = false
    private let particles: [(x: CGFloat, delay: Double, size: CGFloat, drift: CGFloat)] = (0..<36).map { _ in
        (CGFloat.random(in: 0...1), Double.random(in: 0...0.6), CGFloat.random(in: 10...22), CGFloat.random(in: -40...40))
    }
    var body: some View {
        GeometryReader { geo in
            ZStack {
                if !reduceMotion {
                    ForEach(particles.indices, id: \.self) { i in
                        let p = particles[i]
                        StarIcon(size: p.size)
                            .position(x: p.x * geo.size.width + (go ? p.drift : 0), y: go ? geo.size.height + 30 : -30)
                            .rotationEffect(.degrees(go ? 240 : 0))
                            .animation(.easeIn(duration: 2.2).delay(p.delay), value: go)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear { go = true }
    }
}
