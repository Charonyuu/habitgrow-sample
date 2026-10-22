import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(L10n.key, store: L10n.defaults) private var language = AppLanguage.system.rawValue
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage(Notifier.masterKey) private var remindersOn = true
    @State private var authStatus: UNAuthorizationStatus = .notDetermined
    @State private var showPaywall = false
    @State private var iconName: String? = UIApplication.shared.alternateIconName
    @Environment(ProStore.self) private var pro

    private let icons: [(name: String?, preview: String, title: String)] = [
        (nil, "IconPreviewDefault", tr("預設", "Default")),
        ("AppIconSakura", "IconPreviewSakura", tr("櫻花", "Sakura")),
        ("AppIconCottage", "IconPreviewCottage", tr("小屋", "Cottage")),
        ("AppIconJapanese", "IconPreviewJapanese", tr("日式", "Japanese")),
        ("AppIconForest", "IconPreviewForest", tr("森林", "Forest")),
        ("AppIconSnow", "IconPreviewSnow", tr("雪國", "Snow")),
        ("AppIconTropical", "IconPreviewTropical", tr("熱帶", "Tropical")),
        ("AppIconNight", "IconPreviewNight", tr("夜晚", "Night")),
        ("AppIconHouseCottage", "IconPreviewHouseCottage", tr("小屋屋", "Cottage house", ko: "코티지 집", ja: "コテージの家")),
        ("AppIconHouseJapanese", "IconPreviewHouseJapanese", tr("日式屋", "Japanese house", ko: "일본풍 집", ja: "和風の家")),
        ("AppIconHouseForest", "IconPreviewHouseForest", tr("森林屋", "Forest house", ko: "숲 집", ja: "森の家")),
        ("AppIconHouseSnow", "IconPreviewHouseSnow", tr("雪國屋", "Snow house", ko: "눈 집", ja: "雪の家")),
        ("AppIconHouseTropical", "IconPreviewHouseTropical", tr("熱帶屋", "Tropical house", ko: "열대 집", ja: "南国の家")),
        ("AppIconHouseNight", "IconPreviewHouseNight", tr("夜晚屋", "Night house", ko: "밤 집", ja: "夜の家")),
    ]

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left").font(.system(size: 18, weight: .semibold))
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                    Text(tr("設定", "Settings")).font(.r(18, .bold))
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 8)

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        proCard
                        VStack(alignment: .leading, spacing: 8) {
                            Text(tr("小島主題", "Island Theme")).font(.r(13, .semibold)).foregroundStyle(.secondary).padding(.leading, 6)
                            TownThemeChooser()
                        }
                        group(tr("提醒", "Reminders")) {
                            Toggle(isOn: $remindersOn) {
                                Text(tr("提醒通知", "Notifications")).font(.r(16, .medium))
                            }
                            .tint(Theme.accent)
                            .padding(.horizontal, 16)
                            .frame(height: 54)
                            .onChange(of: remindersOn) { _, on in
                                if on { Task { _ = await Notifier.requestAuthorization(); await refreshStatus() } }
                            }
                            if authStatus == .denied {
                                divider
                                Button {
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    HStack {
                                        Text(tr("系統通知已關閉，前往開啟", "Notifications are off in iOS. Open Settings"))
                                            .font(.r(14, .medium)).foregroundStyle(Theme.warn)
                                        Spacer()
                                        Image(systemName: "arrow.up.right").font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(Theme.warn)
                                    }
                                    .padding(.horizontal, 16)
                                    .frame(height: 48)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        Text(tr("在每個習慣的編輯頁設定提醒時間。已完成的習慣當天不會再提醒。",
                                "Set the time in each habit. Habits already done today won't remind you."))
                            .font(.r(12, .regular)).foregroundStyle(.secondary)
                            .padding(.horizontal, 6).padding(.top, -14)

                        group(tr("語言", "Language")) {
                            option(tr("跟隨系統", "System"), AppLanguage.system.rawValue, $language, last: false)
                            option("繁體中文", AppLanguage.zh.rawValue, $language, last: false)
                            option("English", AppLanguage.en.rawValue, $language, last: false)
                            option("한국어", AppLanguage.ko.rawValue, $language, last: false)
                            option("日本語", AppLanguage.ja.rawValue, $language, last: true)
                        }
                        group(tr("外觀", "Appearance")) {
                            option(tr("跟隨系統", "System"), "system", $appearance, last: false)
                            option(tr("淺色", "Light"), "light", $appearance, last: false)
                            option(tr("深色", "Dark"), "dark", $appearance, last: true)
                        }
                        group(tr("App 圖示", "App Icon")) {
                            ScrollView(.horizontal) {
                                HStack(spacing: 14) {
                                    ForEach(icons, id: \.title) { icon in iconOption(icon) }
                                }
                                .padding(16)
                            }
                            .scrollIndicators(.hidden)
                        }
                        group(tr("關於", "About")) {
                            Link(tr("隱私權政策", "Privacy Policy"), destination: URL(string: "https://apps.app.charonyu.cc/apps/habit-grow/privacy/")!)
                                .font(.r(16, .medium)).padding(16)
                            divider
                            Link(tr("使用條款", "Terms of Use"), destination: URL(string: "https://apps.app.charonyu.cc/apps/habit-grow/terms/")!)
                                .font(.r(16, .medium)).padding(16)
                            divider
                            Link(tr("使用支援", "Support"), destination: URL(string: "https://apps.app.charonyu.cc/apps/habit-grow/support/")!)
                                .font(.r(16, .medium)).padding(16)
                            divider
                            Button { Task { await pro.restore() } } label: {
                                HStack {
                                    Text(tr("恢復購買", "Restore Purchase")).font(.r(16, .medium)).foregroundStyle(.primary)
                                    Spacer()
                                    if pro.isWorking { ProgressView() }
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 52)
                            }
                            .buttonStyle(.plain)
                            divider
                            HStack {
                                LogoMark(size: 26)
                                Text("Habit Grow").font(.r(16, .semibold))
                                Spacer()
                                Text("v\(version)").font(.r(14, .regular)).foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 56)
                        }
                        Text(tr("慢慢來，一天一點點。", "A calmer you, day by day."))
                            .font(.r(13, .regular)).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 30)
                }
                .scrollIndicators(.hidden)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .task { await refreshStatus() }
    }

    private var proCard: some View {
        Button { if !pro.isPro { showPaywall = true } } label: {
            HStack(spacing: 14) {
                HouseThumb(theme: pro.isPro ? .cottage : .japanese, level: 4)
                    .frame(width: 58, height: 58)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Habit Grow Pro").font(.r(17, .bold)).foregroundStyle(.primary)
                    Text(pro.isPro
                         ? tr("已解鎖，謝謝你的支持 🌱", "Unlocked. Thank you 🌱")
                         : pro.priceText.isEmpty ? tr("一次買斷・不限習慣、全部小島主題", "One-time · unlimited habits, all island themes") : tr("買斷 \(pro.priceText)・不限習慣、全部小島主題", "\(pro.priceText) once · unlimited habits, all island themes", ko: "\(pro.priceText) 1회 결제 · 무제한 습관, 모든 섬 테마", ja: "\(pro.priceText) 買い切り・習慣無制限・すべての島テーマ"))
                        .font(.r(12, .regular)).foregroundStyle(.secondary).multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                if !pro.isPro {
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                LinearGradient(colors: [Theme.accent.opacity(0.16), Theme.card], startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    private func iconOption(_ icon: (name: String?, preview: String, title: String)) -> some View {
        let locked = icon.name != nil && !pro.isPro
        let selected = iconName == icon.name
        return Button {
            if locked { showPaywall = true; return }
            iconName = icon.name
            UIApplication.shared.setAlternateIconName(icon.name) { _ in }
        } label: {
            VStack(spacing: 6) {
                Image(icon.preview)
                    .resizable().scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    .opacity(locked ? 0.55 : 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .stroke(Theme.accent, lineWidth: 2.5).opacity(selected ? 1 : 0)
                    )
                    .overlay(alignment: .topTrailing) {
                        if locked {
                            Image(systemName: "lock.fill").font(.system(size: 9, weight: .bold)).foregroundStyle(.white)
                                .frame(width: 20, height: 20).background(Theme.accent, in: Circle())
                                .offset(x: 6, y: -6)
                        }
                    }
                Text(icon.title).font(.r(12, .medium)).foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
    }

    private func refreshStatus() async { authStatus = await Notifier.status() }

    private var divider: some View {
        Rectangle().fill(Theme.track.opacity(0.7)).frame(height: 1).padding(.leading, 16)
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.r(13, .semibold)).foregroundStyle(.secondary).padding(.leading, 6)
            VStack(spacing: 0) { content() }
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private func option(_ title: String, _ value: String, _ binding: Binding<String>, last: Bool) -> some View {
        Button {
            withAnimation(.snappy(duration: 0.2)) { binding.wrappedValue = value }
        } label: {
            VStack(spacing: 0) {
                HStack {
                    Text(title).font(.r(16, .medium)).foregroundStyle(.primary)
                    Spacer()
                    if binding.wrappedValue == value {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.accent)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 52)
                if !last { divider }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: binding.wrappedValue)
    }
}
