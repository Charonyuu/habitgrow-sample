import SwiftUI

struct PaywallView: View {
    @Environment(ProStore.self) private var pro
    @Environment(\.dismiss) private var dismiss
    @State private var bob = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    hero
                    VStack(spacing: 8) {
                        Text("Habit Grow Pro").font(.r(30, .bold))
                        Text(subtitle)
                            .font(.r(15, .regular)).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    chips
                    features
                    buyButton
                    if pro.product == nil && !pro.isLoadingPrice {
                        Button(tr("重新載入價格", "Retry loading price", ko: "가격 다시 불러오기", ja: "価格を再読み込み")) {
                            Task { await pro.loadProduct() }
                        }
                    }
                    VStack(spacing: 10) {
                        Button { Task { await pro.restore() } } label: {
                            Text(tr("恢復購買", "Restore Purchase"))
                                .font(.r(14, .semibold)).foregroundStyle(Theme.accent)
                        }
                        .disabled(pro.isWorking)
                        Text(tr("換新手機時，用同一個 Apple ID 按「恢復購買」就能還原。",
                                "On a new phone, sign in with the same Apple ID and tap Restore Purchase."))
                            .font(.r(12, .regular)).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 12)
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
                .padding(.bottom, 36)
            }
            .scrollIndicators(.hidden)
        }
        .alert(tr("提示", "Notice"), isPresented: Binding(
            get: { pro.errorMessage != nil },
            set: { if !$0 { pro.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(pro.errorMessage ?? "")
        }
        .onChange(of: pro.isPro) { _, owned in
            if owned { Task { try? await Task.sleep(for: .milliseconds(900)); dismiss() } }
        }
        .task { await pro.loadProduct() }
        .onAppear { withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) { bob = true } }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
        .presentationBackground(Theme.background)
    }

    private var subtitle: String {
        pro.priceText.isEmpty
            ? tr("一次買斷，永久使用", "Pay once. Yours forever.")
            : tr("只要 \(pro.priceText)，一次買斷，永久使用", "Just \(pro.priceText). Pay once, yours forever.", ko: "\(pro.priceText)만 한 번 결제하면 평생 사용해요", ja: "\(pro.priceText)の買い切りで、ずっと使えます")
    }

    private var heroTheme: TownTheme { .japanese }

    // A little preview of the world you get.
    private var hero: some View {
        ZStack {
            heroTheme.toy.waterColor
            MiniTownImage(theme: heroTheme)
                .scaleEffect(1.0)
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    }

    private var chips: some View {
        HStack(spacing: 8) {
            chip("infinity", tr("永久使用", "Forever"))
            chip("xmark.circle", tr("沒有訂閱", "No subscription"))
            chip("arrow.triangle.2.circlepath", tr("可還原", "Restorable"))
        }
    }

    private func chip(_ symbol: String, _ text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol).font(.system(size: 11, weight: .bold))
            Text(text).font(.r(12, .semibold))
        }
        .foregroundStyle(Theme.accent)
        .padding(.horizontal, 10).frame(height: 28)
        .background(Theme.accent.opacity(0.13), in: Capsule())
    }

    // MARK: Showcase

    private var features: some View {
        VStack(spacing: 14) {
            card("house.fill", Theme.palette[2], tr("全部小島主題", "All island themes"),
                 tr("日式、森林、雪國、熱帶、夜晚，換一座小島慢慢長大", "Japanese, forest, snow, tropical, night. Grow in a different world")) {
                HStack(spacing: 8) {
                    ForEach([TownTheme.japanese, .forest, .snow, .island, .night]) { t in
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(LinearGradient(colors: [t.backdrop.top, t.backdrop.bottom], startPoint: .top, endPoint: .bottom))
                            HouseThumb(theme: t, level: 4).padding(2)
                        }
                        .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
            card("infinity", Theme.palette[0], tr("不限數量的習慣", "Unlimited habits"),
                 tr("免費版最多 5 個，Pro 想種幾棟都可以", "Free is limited to 5. Pro has no limit")) {
                HStack(spacing: 10) {
                    Text("5").font(.r(30, .bold)).foregroundStyle(.secondary)
                    Image(systemName: "arrow.right").font(.system(size: 16, weight: .bold)).foregroundStyle(Theme.accent)
                    Text("∞").font(.r(34, .bold)).foregroundStyle(Theme.accent)
                    Spacer()
                    HStack(spacing: -6) {
                        ForEach(0..<7, id: \.self) { k in
                            Circle().fill(Theme.palette[(k * 2) % Theme.palette.count]).frame(width: 22, height: 22)
                                .overlay(Circle().stroke(Theme.card, lineWidth: 2))
                        }
                    }
                }
            }
            card("square.grid.2x2.fill", Theme.palette[5], tr("多樣桌面 Widget", "More home screen widgets"),
                 tr("小島、習慣小屋、小島加清單，直接在桌面打卡", "Island, habit house and island + checklist, check in from the Home Screen")) {
                widgetMock
            }
            card("calendar", Theme.palette[3], tr("年度熱力圖", "Yearly heatmap"),
                 tr("一整年的堅持，一眼看完", "A whole year of effort at a glance")) {
                heatmapMock
            }
            card("app.badge.fill", Theme.palette[8], tr("備用 App 圖示", "Alternate app icons"),
                 tr("櫻花、小島與小屋，共 14 款", "Sakura, islands and houses: 14 in all")) {
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(["IconPreviewSakura", "IconPreviewCottage", "IconPreviewJapanese", "IconPreviewForest", "IconPreviewSnow", "IconPreviewTropical", "IconPreviewNight", "IconPreviewHouseCottage", "IconPreviewHouseJapanese", "IconPreviewHouseForest", "IconPreviewHouseSnow", "IconPreviewHouseTropical", "IconPreviewHouseNight"], id: \.self) { n in
                            Image(n).resizable().scaledToFill().frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private func card<V: View>(_ symbol: String, _ tint: Color, _ title: String, _ detail: String, @ViewBuilder visual: () -> V) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.r(16, .bold))
                Text(detail).font(.r(12, .regular)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            visual()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var widgetMock: some View {
        VStack(spacing: 10) {
            // medium: island + checklist
            HStack(spacing: 0) {
                MiniTownImage(theme: .cottage, fill: true).frame(width: 150, height: 110).clipped()
                VStack(alignment: .leading, spacing: 9) {
                    ForEach([(0, true, 0.9), (2, true, 0.55), (3, false, 0.3)], id: \.0) { c, done, r in
                        HStack(spacing: 7) {
                            CheckCircle(done: done, color: Theme.palette[c], size: 18)
                            VStack(alignment: .leading, spacing: 3) {
                                Capsule().fill(Theme.primaryFill.opacity(0.7)).frame(width: 52, height: 5)
                                ProgressBar(value: r, color: Theme.palette[c], height: 4).frame(width: 52)
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                Spacer(minLength: 0)
            }
            .frame(height: 110)
            .background(Theme.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            HStack(spacing: 10) {
                // small: one habit's house
                VStack(spacing: 4) {
                    HouseThumb(theme: .japanese, level: 4).frame(height: 70)
                    Capsule().fill(Theme.primaryFill.opacity(0.7)).frame(width: 46, height: 6)
                }
                .frame(width: 110, height: 110)
                .background(Theme.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                // medium: habit house
                HStack(spacing: 10) {
                    HouseThumb(theme: .forest, level: 3).frame(width: 70, height: 70)
                    VStack(alignment: .leading, spacing: 6) {
                        Capsule().fill(Theme.primaryFill.opacity(0.7)).frame(width: 60, height: 6)
                        ProgressBar(value: 0.66, color: Theme.palette[0], height: 5)
                        Text(tr("打卡", "Check in")).font(.r(11, .bold)).foregroundStyle(.white)
                            .padding(.horizontal, 12).padding(.vertical, 4).background(Theme.accent, in: Capsule())
                    }
                }
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, minHeight: 110)
                .background(Theme.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        }
    }

    private var heatmapMock: some View {
        Canvas { ctx, size in
            let weeks = 30, gap: CGFloat = 2.5
            let cell = (size.width - gap * CGFloat(weeks - 1)) / CGFloat(weeks)
            for w in 0..<weeks {
                for d in 0..<7 {
                    let v = townHash(w, d, 3) % 100
                    let boost = UInt64(w) * 2
                    let level = (v + boost) > 130 ? 3 : (v + boost) > 95 ? 2 : (v + boost) > 60 ? 1 : 0
                    let color: Color = level == 0 ? Theme.track : Theme.palette[0].opacity(0.35 + 0.22 * Double(level))
                    let rect = CGRect(x: CGFloat(w) * (cell + gap), y: CGFloat(d) * (cell + gap), width: cell, height: cell)
                    ctx.fill(Path(roundedRect: rect, cornerRadius: cell * 0.28), with: .color(color))
                }
            }
        }
        .frame(height: 7 * 9.6 + 6 * 2.5 - 14)
    }

    private var buyButton: some View {
        Button {
            Task { await pro.purchase() }
        } label: {
            HStack(spacing: 8) {
                if pro.isWorking {
                    ProgressView().tint(.white)
                } else if pro.isPro {
                    Image(systemName: "checkmark")
                    Text(tr("已解鎖", "Unlocked"))
                } else if pro.priceText.isEmpty {
                    Text(pro.priceStatusText)
                } else {
                    Text(tr("買斷 \(pro.priceText)", "Unlock for \(pro.priceText)", ko: "\(pro.priceText)에 구매", ja: "\(pro.priceText)で購入"))
                }
            }
            .font(.r(18, .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                LinearGradient(colors: [Color(hex: 0x4DB26E), Theme.accent], startPoint: .top, endPoint: .bottom),
                in: Capsule()
            )
            .shadow(color: Theme.accent.opacity(0.35), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(pro.isWorking || pro.isPro || pro.product == nil)
        .sensoryFeedback(.success, trigger: pro.isPro)
    }
}
