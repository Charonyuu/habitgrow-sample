import WidgetKit
import SwiftUI
import SwiftData
import AppIntents
import ImageIO

struct HabitEntry: TimelineEntry {
    let date: Date
    let habits: [HabitSnapshot]
}

@MainActor
func loadSnapshots() -> [HabitSnapshot] {
    let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortOrder)])
    let habits = (try? Store.container.mainContext.fetch(descriptor)) ?? []
    return habits.map(\.snapshot)
}

private func midnightRefresh() -> Date {
    let cal = Cal.c
    return cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: .now)) ?? .now.addingTimeInterval(3600)
}

private let sample = [
    HabitSnapshot(id: "1", name: "閱讀", icon: "book.fill", colorIndex: 0, subtitle: "3 x a week", rate: 0.14, doneToday: false),
    HabitSnapshot(id: "2", name: "運動", icon: "dumbbell.fill", colorIndex: 1, subtitle: "every 1 day", rate: 0.06, doneToday: true),
    HabitSnapshot(id: "3", name: "喝水", icon: "drop.fill", colorIndex: 2, subtitle: "every 1 day", rate: 0.07, doneToday: true),
    HabitSnapshot(id: "4", name: "冥想", icon: "leaf.fill", colorIndex: 3, subtitle: "3 x a week", rate: 0.2, doneToday: false),
]

// MARK: Single habit

struct SingleProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> HabitEntry { HabitEntry(date: .now, habits: [sample[0]]) }

    func snapshot(for configuration: SelectHabitIntent, in context: Context) async -> HabitEntry {
        context.isPreview ? placeholder(in: context) : await entry(for: configuration)
    }

    func timeline(for configuration: SelectHabitIntent, in context: Context) async -> Timeline<HabitEntry> {
        Timeline(entries: [await entry(for: configuration)], policy: .after(midnightRefresh()))
    }

    @MainActor
    private func entry(for configuration: SelectHabitIntent) -> HabitEntry {
        let all = loadSnapshots()
        let pick = all.first { $0.id == configuration.habit?.id } ?? all.first
        return HabitEntry(date: .now, habits: pick.map { [$0] } ?? [])
    }
}

struct SingleHabitView: View {
    @Environment(\.widgetFamily) private var family
    let entry: HabitEntry

    var body: some View {
        if let h = entry.habits.first {
            let color = Theme.color(h.colorIndex)
            switch family {
            case .systemMedium: medium(h, color)
            default: small(h, color)
            }
        } else {
            EmptyWidget()
        }
    }

    private func small(_ h: HabitSnapshot, _ color: Color) -> some View {
        VStack(spacing: 2) {
            ZStack(alignment: .topTrailing) {
                Group {
                    if let img = houseImage(h.id) { Image(uiImage: img).resizable().scaledToFit() }
                    else { IconTile(symbol: h.icon, color: color, size: 52) }
                }
                .frame(maxWidth: .infinity)
                Button(intent: ToggleHabitIntent(habitID: h.id)) {
                    CheckCircle(done: h.doneToday, color: color, size: 26)
                }
                .buttonStyle(.plain)
            }
            Text(h.name).font(.r(16, .bold)).lineLimit(1)
            Text(h.status).font(.r(10, .medium)).foregroundStyle(h.urgent ? Theme.warn : Color.secondary).lineLimit(1)
        }
    }

    private func medium(_ h: HabitSnapshot, _ color: Color) -> some View {
        HStack(spacing: 14) {
            Group {
                if let img = houseImage(h.id) { Image(uiImage: img).resizable().scaledToFit() }
                else { HabitTab(color: color, width: 34, height: 60) }
            }
            .frame(width: 84, height: 84)
            VStack(alignment: .leading, spacing: 4) {
                Text(h.name).font(.r(20, .bold)).lineLimit(1)
                Text(h.subtitle).font(.r(11, .regular)).foregroundStyle(.secondary)
                ProgressBar(value: h.rate, color: color)
                Text(h.status).font(.r(11, .medium)).foregroundStyle(h.urgent ? Theme.warn : Color.secondary).lineLimit(1)
            }
            Text(percentText(h.rate)).font(.r(22, .bold)).monospacedDigit()
            Button(intent: ToggleHabitIntent(habitID: h.id)) {
                CheckCircle(done: h.doneToday, color: color, size: 32)
            }
            .buttonStyle(.plain)
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }
}

// MARK: Multiple habits

struct MultiProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitEntry { HabitEntry(date: .now, habits: sample) }

    func getSnapshot(in context: Context, completion: @escaping (HabitEntry) -> Void) {
        if context.isPreview { completion(placeholder(in: context)); return }
        Task { @MainActor in completion(HabitEntry(date: .now, habits: loadSnapshots())) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitEntry>) -> Void) {
        Task { @MainActor in
            let entry = HabitEntry(date: .now, habits: loadSnapshots())
            completion(Timeline(entries: [entry], policy: .after(midnightRefresh())))
        }
    }
}

struct MultiHabitView: View {
    @Environment(\.widgetFamily) private var family
    let entry: HabitEntry

    var body: some View {
        if !L10n.defaults.bool(forKey: "isPro") {
            LockedWidget()
        } else if entry.habits.isEmpty {
            EmptyWidget()
        } else if family == .systemMedium {
            medium
        } else {
            small
        }
    }

    private var small: some View {
        let items = Array(entry.habits.prefix(4))
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(items) { h in
                Button(intent: ToggleHabitIntent(habitID: h.id)) {
                    ZStack(alignment: .bottomTrailing) {
                        IconTile(symbol: h.icon, color: Theme.color(h.colorIndex), size: 58)
                            .frame(maxWidth: .infinity)
                        if h.doneToday {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Theme.onColor, Theme.color(h.colorIndex))
                                .background(Circle().fill(Theme.card))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var medium: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Habit Grow").font(.r(12, .semibold)).foregroundStyle(.secondary)
            ForEach(entry.habits.prefix(4)) { h in
                HStack(spacing: 10) {
                    Button(intent: ToggleHabitIntent(habitID: h.id)) {
                        CheckCircle(done: h.doneToday, color: Theme.color(h.colorIndex), size: 20)
                    }
                    .buttonStyle(.plain)
                    Text(h.name).font(.r(14, .semibold)).lineLimit(1)
                    Spacer()
                    Text(percentText(h.rate)).font(.r(14, .semibold)).monospacedDigit()
                }
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: Shared pieces

struct IconTile: View {
    let symbol: String
    let color: Color
    var size: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
            .fill(color.opacity(0.55))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: symbol)
                    .font(.system(size: size * 0.46, weight: .semibold))
                    .foregroundStyle(Theme.onColor.opacity(0.75))
            )
    }
}

struct LockedWidget: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "lock.fill").font(.system(size: 20, weight: .semibold)).foregroundStyle(Theme.accent)
            Text("Habit Grow Pro").font(.r(14, .bold))
            Text(tr("多習慣 Widget 需要 Pro", "Multi-habit widget needs Pro"))
                .font(.r(11, .regular)).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
    }
}

struct EmptyWidget: View {
    var body: some View {
        VStack(spacing: 6) {
            LogoMark(size: 28)
            Text(tr("尚無習慣", "No habits yet")).font(.r(13, .semibold)).foregroundStyle(.secondary)
        }
    }
}

// MARK: Widgets

struct SingleHabitWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "SingleHabitWidget", intent: SelectHabitIntent.self, provider: SingleProvider()) { entry in
            SingleHabitView(entry: entry).containerBackground(Theme.card, for: .widget)
        }
        .configurationDisplayName(tr("單一習慣", "Single Habit"))
        .description(tr("一鍵打卡單一習慣", "Check in a single habit"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct MultiHabitWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MultiHabitWidget", provider: MultiProvider()) { entry in
            MultiHabitView(entry: entry).containerBackground(Theme.card, for: .widget)
        }
        .configurationDisplayName(tr("多個習慣", "Habits"))
        .description(tr("一次查看並打卡多個習慣", "See and check in several habits"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: Town

struct TownEntry: TimelineEntry {
    let date: Date
}

struct TownProvider: TimelineProvider {
    func placeholder(in context: Context) -> TownEntry { TownEntry(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (TownEntry) -> Void) { completion(TownEntry(date: .now)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<TownEntry>) -> Void) {
        completion(Timeline(entries: [TownEntry(date: .now)], policy: .after(midnightRefresh())))
    }
}

struct TownWidgetView: View {
    private var image: UIImage? {
        guard let url = TownSnapshotStore.url else { return nil }
        return widgetImage(at: url)
    }

    var body: some View {
        let homes = L10n.defaults.integer(forKey: TownSnapshotStore.homesKey)
        let total = L10n.defaults.integer(forKey: TownSnapshotStore.checkInsKey)
        VStack {
            HStack(spacing: 6) {
                Image("Sprout").resizable().scaledToFit().frame(width: 16, height: 16)
                Text(tr("\(homes) 棟・\(total) 次打卡", "\(homes) homes · \(total) check-ins", ko: "\(homes)채 · 체크 \(total)회", ja: "\(homes)軒・記録\(total)回"))
                    .font(.r(11, .semibold)).lineLimit(1)
            }
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(.white.opacity(0.9), in: Capsule())
            .foregroundStyle(Color(hex: 0x2E4A35))
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
        }
        .containerBackground(for: .widget) {
            if let image {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Theme.background
            }
        }
    }
}

struct TownWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TownWidget", provider: TownProvider()) { _ in
            TownWidgetView()
        }
        .configurationDisplayName(tr("我的小島", "My Island"))
        .description(tr("桌面上看著小島慢慢長大", "Watch your island grow from the Home Screen"))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

// MARK: Island + checklist

private func islandImage() -> UIImage? {
    guard let url = TownSnapshotStore.url else { return nil }
    return widgetImage(at: url)
}

private func houseImage(_ id: String) -> UIImage? {
    guard let url = TownSnapshotStore.houseURL(id) else { return nil }
    return widgetImage(at: url)
}

// WidgetKit rejects oversized images while archiving small widgets.
// Decode a bounded thumbnail rather than passing the full app snapshot.
private func widgetImage(at url: URL) -> UIImage? {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 800
          ] as CFDictionary) else { return nil }
    return UIImage(cgImage: image)
}

struct IslandChecklistView: View {
    @Environment(\.widgetFamily) private var family
    let entry: HabitEntry

    var body: some View {
        if !L10n.defaults.bool(forKey: "isPro") {
            LockedWidget()
        } else if family == .systemLarge {
            VStack(spacing: 0) {
                islandPicture.frame(maxWidth: .infinity).frame(height: 150).clipped()
                rows(5).padding(14)
            }
        } else {
            GeometryReader { geo in
                HStack(spacing: 0) {
                    islandPicture.frame(width: geo.size.width * 0.52, height: geo.size.height).clipped()
                    rows(3).padding(.horizontal, 12).padding(.vertical, 12).frame(width: geo.size.width * 0.48)
                }
            }
        }
    }

    private var islandPicture: some View {
        Group {
            if let img = islandImage() { Image(uiImage: img).resizable().scaledToFill() } else { Color.clear }
        }
    }

    private func rows(_ n: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(entry.habits.prefix(n)) { h in
                HStack(spacing: 8) {
                    Button(intent: ToggleHabitIntent(habitID: h.id)) {
                        CheckCircle(done: h.doneToday, color: Theme.color(h.colorIndex), size: 22)
                    }
                    .buttonStyle(.plain)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(h.name).font(.r(13, .semibold)).lineLimit(1)
                        Text(h.level == 0 ? tr("空地", "Lot") : "Lv.\(h.level)")
                            .font(.r(10, .regular)).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    Text(percentText(h.rate)).font(.r(12, .semibold)).monospacedDigit()
                }
            }
            if entry.habits.isEmpty { EmptyWidget() }
            Spacer(minLength: 0)
        }
    }
}

struct IslandChecklistWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "IslandChecklistWidget", provider: MultiProvider()) { entry in
            IslandChecklistView(entry: entry).containerBackground(Theme.card, for: .widget)
        }
        .configurationDisplayName(tr("小島加今日清單", "Island + Checklist"))
        .description(tr("上面是小島，下面直接打卡", "See your island and check in below"))
        .supportedFamilies([.systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

// MARK: One habit's house

struct HouseWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: HabitEntry

    var body: some View {
        if let h = entry.habits.first {
            let color = Theme.color(h.colorIndex)
            let house = Group {
                if let img = houseImage(h.id) { Image(uiImage: img).resizable().scaledToFit() } else { Color.clear }
            }
            if family == .systemSmall {
                VStack(spacing: 2) {
                    ZStack(alignment: .topTrailing) {
                        house.frame(maxWidth: .infinity)
                        Button(intent: ToggleHabitIntent(habitID: h.id)) {
                            CheckCircle(done: h.doneToday, color: color, size: 26)
                        }
                        .buttonStyle(.plain)
                    }
                    Text(h.name).font(.r(14, .bold)).lineLimit(1)
                    ProgressBar(value: h.rate, color: color, height: 5)
                }
            } else {
                HStack(spacing: 12) {
                    house.frame(maxWidth: .infinity)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(h.name).font(.r(18, .bold)).lineLimit(1)
                        Text(h.level == 0 ? tr("空地", "Lot") : "Lv.\(h.level)")
                            .font(.r(12, .semibold)).foregroundStyle(.secondary)
                        ProgressBar(value: h.rate, color: color, height: 6)
                        Text(h.status).font(.r(11, .medium)).foregroundStyle(h.urgent ? Theme.warn : Color.secondary).lineLimit(1)
                        Button(intent: ToggleHabitIntent(habitID: h.id)) {
                            Text(h.doneToday ? tr("今天完成 ✓", "Done today ✓") : tr("打卡", "Check in"))
                                .font(.r(13, .bold)).foregroundStyle(h.doneToday ? Theme.onColor : .white)
                                .padding(.horizontal, 14).padding(.vertical, 6)
                                .background(h.doneToday ? color : Theme.accent, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        } else {
            EmptyWidget()
        }
    }
}

struct HouseWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "HouseWidget", intent: SelectHabitIntent.self, provider: SingleProvider()) { entry in
            HouseWidgetView(entry: entry).containerBackground(Theme.card, for: .widget)
        }
        .configurationDisplayName(tr("習慣小屋", "Habit House"))
        .description(tr("看著這個習慣的小屋長大並打卡", "Watch one habit's house grow and check in"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct HabitGrowWidgets: WidgetBundle {
    var body: some Widget {
        SingleHabitWidget()
        MultiHabitWidget()
        TownWidget()
        IslandChecklistWidget()
        HouseWidget()
    }
}
