import SwiftUI
import SwiftData

struct TownView: View {
    @Environment(ProStore.self) private var pro
    @AppStorage("townTheme") private var themeRaw = TownTheme.cottage.rawValue
    @State private var showThemes = false
    @State private var pops: Set<String> = []
    let habits: [Habit]
    var onOpen: (PersistentIdentifier) -> Void = { _ in }
    var onAdd: () -> Void = {}

    private var theme: TownTheme { TownTheme.effective(themeRaw, isPro: pro.isPro) }

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(colors: [theme.backdrop.top, theme.backdrop.bottom], startPoint: .top, endPoint: .bottom)
            Town3DView(habits: habits, theme: theme, pops: pops, onOpen: onOpen, onAdd: onAdd)
            HStack {
                summary
                Spacer()
                Button { showThemes = true } label: {
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.accent)
                        .frame(width: 38, height: 38)
                        .background(Theme.card.opacity(0.94), in: Circle())
                }
                .accessibilityLabel(tr("小島主題", "Island theme"))
            }
            .padding(.horizontal, 16).padding(.top, 12)
        }
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30))
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showThemes) { TownThemeSheet() }
        .onAppear { celebrateLevelUps() }
        .onChange(of: habits.map(\.townLevel)) { _, _ in celebrateLevelUps() }
        .sensoryFeedback(.success, trigger: pops.count)
    }

    /// Plays the level-up pop for houses that grew since the town was last looked at.
    private func celebrateLevelUps() {
        let key = "townSeenLevels"
        var seen = (UserDefaults.standard.dictionary(forKey: key) as? [String: Int]) ?? [:]
        var grown = Set<String>()
        for h in habits {
            let id = h.id.uuidString
            if let old = seen[id], h.townLevel > old { grown.insert("h:\(id)") }
            seen[id] = h.townLevel
        }
        UserDefaults.standard.set(seen, forKey: key)
        guard !grown.isEmpty else { return }
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            pops = grown
            try? await Task.sleep(for: .milliseconds(2600))
            pops = []
        }
    }

    private var summary: some View {
        let homes = habits.filter { $0.plotIndex >= 0 }.count
        let total = habits.reduce(0) { $0 + $1.totalCount }
        return HStack(spacing: 8) {
            Image("Sprout").resizable().scaledToFit().frame(width: 20, height: 20)
            Text(tr("你的小島・\(homes) 棟・\(total) 次打卡", "Your island · \(homes) homes · \(total) check-ins", ko: "나의 섬 · \(homes)채 · 체크 \(total)회", ja: "わたしの島・\(homes)軒・記録\(total)回"))
                .font(.r(12, .semibold)).lineLimit(1)
        }
        .padding(.horizontal, 12).frame(height: 38)
        .background(Theme.card.opacity(0.94), in: Capsule())
    }
}

// MARK: - Theme picker

struct TownThemeChooser: View {
    @Environment(ProStore.self) private var pro
    @AppStorage("townTheme") private var themeRaw = TownTheme.cottage.rawValue
    @State private var showPaywall = false

    var body: some View {
        VStack(spacing: 12) {
            ForEach(TownTheme.allCases) { theme in
                let locked = !theme.isFree && !pro.isPro
                let selected = TownTheme.effective(themeRaw, isPro: pro.isPro) == theme
                Button {
                    if locked { showPaywall = true } else { withAnimation(.snappy) { themeRaw = theme.rawValue } }
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(LinearGradient(colors: [theme.backdrop.top, theme.backdrop.bottom], startPoint: .top, endPoint: .bottom))
                            HouseThumb(theme: theme, level: 4).padding(4)
                                .opacity(locked ? 0.75 : 1)
                        }
                        .frame(width: 84, height: 84)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(theme.title).font(.r(16, .bold)).foregroundStyle(.primary)
                            Text(theme.subtitle).font(.r(12, .regular)).foregroundStyle(.secondary).multilineTextAlignment(.leading)
                        }
                        Spacer(minLength: 0)
                        if locked {
                            Image(systemName: "lock.fill").font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                                .frame(width: 26, height: 26).background(Theme.accent, in: Circle())
                        } else if selected {
                            Image(systemName: "checkmark.circle.fill").font(.system(size: 22)).foregroundStyle(Theme.accent)
                        }
                    }
                    .padding(10)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Theme.accent, lineWidth: 2).opacity(selected ? 1 : 0)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .sensoryFeedback(.selection, trigger: themeRaw)
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }
}

struct TownThemeSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text(tr("小島主題", "Island Theme")).font(.r(20, .bold))
                    Spacer()
                    Button { dismiss() } label: {
                        Text(tr("完成", "Done")).font(.r(15, .bold)).foregroundStyle(.white)
                            .padding(.horizontal, 16).frame(height: 34)
                            .background(Theme.accent, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24).padding(.top, 26).padding(.bottom, 14)
                ScrollView {
                    TownThemeChooser().padding(.horizontal, 20).padding(.bottom, 30)
                }
                .scrollIndicators(.hidden)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
        .presentationBackground(Theme.background)
    }
}

/// One habit's own lot (empty at first), shown on the habit page.
struct HabitLotView: View {
    let habit: Habit
    @Environment(ProStore.self) private var pro
    @AppStorage("townTheme") private var themeRaw = TownTheme.cottage.rawValue
    var height: CGFloat = 118

    var body: some View {
        HouseThumb(theme: TownTheme.effective(themeRaw, isPro: pro.isPro), level: habit.townLevel)
            .frame(height: height)
    }
}
