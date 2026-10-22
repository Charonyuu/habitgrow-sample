import SwiftUI
import SwiftData
import WidgetKit

enum HomeTab: CaseIterable {
    case today, week, month, town

    var title: String {
        switch self {
        case .today: return tr("今天", "Today")
        case .week: return tr("本週", "Week")
        case .month: return tr("本月", "Month")
        case .town: return tr("小島", "Island")
        }
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @AppStorage(L10n.key, store: L10n.defaults) private var language = AppLanguage.system.rawValue
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("townTheme") private var townThemeRaw = TownTheme.cottage.rawValue
    @AppStorage(Notifier.masterKey) private var remindersOn = true
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab: HomeTab = .today
    @State private var showCreate = false
    @State private var showSettings = false
    @State private var path = NavigationPath()
    @State private var showReorder = false
    @State private var showPaywall = false
    @Environment(ProStore.self) private var pro

    private var colorScheme: ColorScheme? {
        switch appearance {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottomTrailing) {
                Theme.background.ignoresSafeArea()
                VStack(spacing: 14) {
                    header
                    PillTabs(items: HomeTab.allCases, title: { $0.title }, selection: $tab)
                        .padding(.horizontal, 16)
                    ZStack {
                        if habits.isEmpty && tab != .town {
                            emptyState
                        } else {
                            switch tab {
                            case .today: MainListView(habits: habits) { showPaywall = true }
                            case .week: WeekView(habits: habits)
                            case .month: MonthView(habits: habits)
                            case .town: TownView(habits: habits, onOpen: { path.append($0) }, onAdd: { addTapped() })
                            }
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                }
                addButton
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showSettings) { SettingsView() }
            .navigationDestination(for: PersistentIdentifier.self) { id in
                if let habit = habits.first(where: { $0.persistentModelID == id }) {
                    HabitDetailView(habit: habit)
                }
            }
        }
        .id(language)
        .sheet(isPresented: $showCreate) { HabitEditView(habit: nil) }
        .sheet(isPresented: $showReorder) { ReorderView() }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .preferredColorScheme(colorScheme)
        .task { seedIfRequested() }
        #if DEBUG
        .task { try? await Task.sleep(for: .milliseconds(900)); applyDebugNavigation() }
        #endif
        .task(id: syncKey) { await Notifier.sync(habits) }
        .task(id: habits.count) { assignPlots() }
        .task(id: townKey) {
            try? await Task.sleep(for: .milliseconds(600))
            TownSnapshot.render(habits: habits, theme: TownTheme.effective(townThemeRaw, isPro: pro.isPro))
        }
        .onChange(of: language) { _, _ in WidgetCenter.shared.reloadAllTimelines() }
    }

    /// Changes whenever something that affects reminders changes.
    private var syncKey: String {
        let items = habits.map { "\($0.id)\($0.name)\($0.reminderEnabled)\($0.reminderMinutes)\($0.isDone(.now))" }
        return items.joined() + "\(remindersOn)\(scenePhase == .active)"
    }

    private var header: some View {
        HStack(spacing: 4) {
            LogoMark(size: 32)
                .padding(.trailing, 6)
            Text("Habit Grow")
                .font(.r(24, .bold))
            Spacer(minLength: 0)
            Button { showReorder = true } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 40, height: 40)
            }
            .accessibilityLabel(tr("排列", "Arrange"))
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 40, height: 40)
            }
            .accessibilityLabel(tr("設定", "Settings"))
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    /// Changes whenever the town looks different (for the widget picture).
    private var townKey: String {
        let items = habits.map { "\($0.id)\($0.plotIndex)\($0.townLevel)" }
        return items.joined() + townThemeRaw + "\(pro.isPro)" + "\(habits.reduce(0) { $0 + $1.totalCount } / 8)"
    }

    /// Gives every habit a stable lot in the town.
    private func assignPlots() {
        var seen = Set<Int>()
        var changed = false
        for h in habits.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            if h.plotIndex >= 0 && !seen.contains(h.plotIndex) { seen.insert(h.plotIndex); continue }
            var i = 0
            while seen.contains(i) { i += 1 }
            h.plotIndex = i; seen.insert(i); changed = true
        }
        if changed { try? context.save() }
    }

    private func addTapped() {
        if habits.count >= ProStore.freeHabitLimit && !pro.isPro { showPaywall = true } else { showCreate = true }
    }

    private var addButton: some View {
        Button { addTapped() } label: {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(Theme.accent, in: Circle())
                .shadow(color: Theme.accent.opacity(0.35), radius: 10, y: 5)
        }
        .padding(.trailing, 22)
        .padding(.bottom, 18)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            PlantView(rate: 0, size: 110)
            Text(tr("還沒有習慣", "No habits yet")).font(.r(18, .bold))
            Text(tr("點右下角的 + 開始新增", "Tap + to plant your first one"))
                .font(.r(14, .regular)).foregroundStyle(.secondary)
        }
        .padding(.top, 100)
    }

    #if DEBUG
    /// `-seedFarm`: varied plants and progress, just to look at the farm.
    /// `-tab week|month|town`, `-open detail|paywall|settings` for scripted screenshots.
    private func applyDebugNavigation() {
        let a = CommandLine.arguments
        func value(_ k: String) -> String? { a.firstIndex(of: k).flatMap { $0 + 1 < a.count ? a[$0 + 1] : nil } }
        switch value("-tab") {
        case "week": tab = .week
        case "month": tab = .month
        case "town": tab = .town
        default: break
        }
        switch value("-open") {
        case "paywall": showPaywall = true
        case "settings": showSettings = true
        case "detail": if let h = habits.first { path.append(h.persistentModelID) }
        default: break
        }
    }

    private func seedManyIfRequested() {
        guard CommandLine.arguments.contains("-seedMany"), habits.count < 26 else { return }
        for i in habits.count..<26 {
            let h = Habit(name: "H\(i + 1)", frequency: .day, targetCount: 1, colorIndex: i % 12, sortOrder: i)
            context.insert(h)
            for d in 0..<(i % 9) * 4 { context.insert(Completion(day: Cal.c.date(byAdding: .day, value: -d, to: Cal.c.startOfDay(for: .now))!, habit: h)) }
        }
        try? context.save()
    }

    private func seedYearIfRequested() {
        guard CommandLine.arguments.contains("-seedYear") else { return }
        let cal = Cal.c
        for (i, h) in habits.enumerated() {
            h.completions.forEach { context.delete($0) }
            for d in 0..<360 where townHash(d, i, 7) % 100 < UInt64(35 + (i % 3) * 20 + (d < 120 ? 25 : 0)) {
                context.insert(Completion(day: cal.date(byAdding: .day, value: -d, to: cal.startOfDay(for: .now))!, habit: h))
            }
        }
        try? context.save()
    }

    private func seedTownIfRequested() {
        guard CommandLine.arguments.contains("-seedTown") else { return }
        let lifetime = [130, 45, 12, 3, 0, 9]
        let cal = Cal.c
        for (i, h) in habits.enumerated() where i < lifetime.count {
            h.completions.forEach { context.delete($0) }
            for d in 0..<lifetime[i] {
                let day = cal.date(byAdding: .day, value: -d, to: cal.startOfDay(for: .now))!
                context.insert(Completion(day: day, habit: h))
            }
        }
        try? context.save()
    }

    private func seedFarmIfRequested() {
        guard CommandLine.arguments.contains("-seedFarm") else { return }
        let types: [PlantType] = [.carrot, .tomato, .wheat, .strawberry, .cabbage, .sakura, .bamboo, .succulent, .grass]
        let counts = [3, 6, 2, 1, 4, 3, 0, 5, 2]
        let cal = Cal.c
        let weekStart = cal.dateInterval(of: .weekOfYear, for: .now)!.start
        for (i, h) in habits.enumerated() {
            h.plantType = types[i % types.count].rawValue
            h.completions.forEach { context.delete($0) }
            for j in 0..<counts[i % counts.count] {
                let d = cal.date(byAdding: .day, value: j, to: weekStart)!
                context.insert(Completion(day: d, habit: h))
            }
        }
        try? context.save()
    }
    #endif

    private func seedIfRequested() {
        #if DEBUG
        seedFarmIfRequested()
        seedManyIfRequested()
        seedTownIfRequested()
        seedYearIfRequested()
        #endif
        guard CommandLine.arguments.contains("-seed"), habits.isEmpty else { return }
        let specs: [(String, Frequency, Int, Int, Int)] = [
            (tr("閱讀", "Reading", ko: "독서", ja: "読書"), .week, 3, 0, 5),
            (tr("運動", "Workout", ko: "운동", ja: "運動"), .day, 1, 1, 2),
            (tr("喝水", "Drink water", ko: "물 마시기", ja: "水を飲む"), .day, 1, 2, 3),
            (tr("冥想", "Meditate", ko: "명상", ja: "瞑想"), .week, 3, 3, 6),
            (tr("整理房間", "Tidy up", ko: "방 정리", ja: "部屋の片付け"), .month, 2, 4, 0),
            (tr("散步", "Walk", ko: "산책", ja: "散歩"), .week, 4, 5, 4),
        ]
        let cal = Cal.c
        for (i, s) in specs.enumerated() {
            let h = Habit(name: s.0, frequency: s.1, targetCount: s.2, colorIndex: s.3, sortOrder: i)
            context.insert(h)
            for back in 0..<s.4 {
                let d = cal.date(byAdding: .day, value: -back * 2, to: .now)!
                context.insert(Completion(day: cal.startOfDay(for: d), habit: h))
            }
        }
        try? context.save()
        #if DEBUG
        seedTownIfRequested()
        #endif
    }
}
