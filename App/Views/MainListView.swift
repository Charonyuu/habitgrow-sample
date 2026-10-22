import SwiftUI
import SwiftData
import UIKit

struct MainListView: View {
    @Environment(\.modelContext) private var context
    let habits: [Habit]
    var onUpgrade: () -> Void = {}
    @Environment(ProStore.self) private var pro

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                todaySummary
                if !pro.isPro { ProBanner(action: onUpgrade) }
                ForEach(habits) { habit in
                    NavigationLink(value: habit.persistentModelID) {
                        HabitRowCard(
                            name: habit.name,
                            subtitle: habit.subtitle,
                            color: Theme.color(habit.colorIndex),
                            progress: habit.progress,
                            done: habit.isDone(.now)
                        ) {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.snappy) { habit.toggle(.now, in: context) }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 110)
        }
    }

    private var todaySummary: some View {
        let done = habits.filter { $0.isDone(.now) }.count
        let date = Date.now.formatted(.dateTime.month().day().weekday(.wide).locale(L10n.locale))
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(date).font(.r(13, .regular)).foregroundStyle(.secondary)
                Text(tr("今天完成 \(done) / \(habits.count)", "Done today \(done) / \(habits.count)", ko: "오늘 완료 \(done) / \(habits.count)", ja: "今日の完了 \(done) / \(habits.count)")).font(.r(18, .bold))
            }
            Spacer()
        }
        .padding(.horizontal, 6)
        .padding(.bottom, 2)
    }
}

/// Always-visible entry to the one-time purchase (hidden once unlocked).
struct ProBanner: View {
    @Environment(ProStore.self) private var pro
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                HouseThumb(theme: .japanese, level: 4)
                    .frame(width: 58, height: 58)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Habit Grow Pro").font(.r(15, .bold)).foregroundStyle(.primary)
                    Text(tr("不限習慣・全部小島主題", "Unlimited habits · all island themes"))
                        .font(.r(11, .regular)).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer(minLength: 4)
                Text(pro.priceText.isEmpty ? tr("解鎖", "Unlock") : pro.priceText)
                    .font(.r(14, .bold)).foregroundStyle(.white)
                    .padding(.horizontal, 14).frame(height: 34)
                    .background(Theme.accent, in: Capsule())
            }
            .padding(.leading, 12).padding(.trailing, 12)
            .frame(height: 70)
            .background(
                LinearGradient(colors: [Theme.accent.opacity(0.20), Theme.card], startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Theme.accent.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
