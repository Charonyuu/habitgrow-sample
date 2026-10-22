import SwiftUI
import SwiftData
import UIKit

struct HabitDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let habit: Habit
    @State private var month: Date = .now
    @State private var showEdit = false
    @State private var confirmDelete = false
    @State private var showPaywall = false
    @Environment(ProStore.self) private var pro

    private var color: Color { Theme.color(habit.colorIndex) }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(spacing: 14) {
                        summaryCard
                        calendarCard
                        YearHeatmapCard(habit: habit, color: color, locked: !pro.isPro) { showPaywall = true }
                        statsSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 30)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showEdit) { HabitEditView(habit: habit) }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .confirmationDialog(tr("刪除「\(habit.name)」？", "Delete \(habit.name)?", ko: "\(habit.name) 삭제할까요?", ja: "「\(habit.name)」を削除しますか？"), isPresented: $confirmDelete, titleVisibility: .visible) {
            Button(tr("刪除", "Delete"), role: .destructive) {
                let ctx = context
                dismiss()
                ctx.delete(habit)
                try? ctx.save()
            }
        } message: {
            Text(tr("所有紀錄都會一併刪除", "All records will be deleted too"))
        }
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left").font(.system(size: 18, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            Spacer()
            Text(habit.name).font(.r(18, .bold))
            Spacer()
            Menu {
                Button { showEdit = true } label: { Label(tr("編輯", "Edit"), systemImage: "pencil") }
                Button(role: .destructive) { confirmDelete = true } label: { Label(tr("刪除", "Delete"), systemImage: "trash") }
            } label: {
                Image(systemName: "ellipsis").font(.system(size: 18, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 8)
    }

    private var summaryCard: some View {
        let p = habit.progress
        let title: String = habit.frequency == .month
            ? tr("本月完成度", "This month's progress")
            : tr("本週完成度", "This week's progress")
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(.r(14, .semibold))
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(percentText(p.rate)).font(.r(44, .bold)).monospacedDigit()
                        Text("\(p.done)/\(p.target)").font(.r(16, .semibold))
                            .foregroundStyle(.secondary).monospacedDigit()
                    }
                    Text(habit.subtitle)
                        .font(.r(12, .medium)).foregroundStyle(.secondary)
                        .padding(.horizontal, 12).padding(.vertical, 5)
                        .background(Theme.track.opacity(0.8), in: Capsule())
                }
                Spacer()
                HabitLotView(habit: habit)
            }
            ProgressBar(value: p.rate, color: color, height: 8)
            Text(p.status)
                .font(.r(12, .medium))
                .foregroundStyle(p.urgent ? Theme.warn : Color.secondary)
            levelRow
        }
        .padding(18)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var levelRow: some View {
        let level = habit.townLevel
        let title = level == 0 ? tr("空地", "Empty lot") : "Lv.\(level)"
        let hint: String
        if let next = habit.nextLevelAt {
            let left = next - habit.totalCount
            hint = level == 0
                ? tr("打卡 \(left) 次就能蓋房子", "\(left) check-in to build a house", ko: "\(left)번 체크하면 집을 지어요", ja: "あと\(left)回の記録で家が建つ")
                : tr("再 \(left) 次打卡升級", "\(left) more check-ins to level up", ko: "\(left)번 더 체크하면 레벨업", ja: "あと\(left)回の記録でレベルアップ")
        } else {
            hint = tr("已蓋到最高等級", "Fully built")
        }
        return HStack(spacing: 8) {
            Text(title).font(.r(12, .bold)).foregroundStyle(Theme.onColor)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(color, in: Capsule())
            Text(hint).font(.r(12, .medium)).foregroundStyle(.secondary)
        }
    }

    private var calendarCard: some View {
        let cal = Cal.c
        let first = cal.dateInterval(of: .month, for: month)!.start
        let count = cal.range(of: .day, in: .month, for: month)!.count
        let offset = (cal.component(.weekday, from: first) - cal.firstWeekday + 7) % 7
        let done = habit.doneDays
        let cols = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
        return VStack(spacing: 10) {
            MonthNavigator(month: $month)
            HStack(spacing: 0) {
                ForEach(weekdayLabels(), id: \.self) {
                    Text($0).font(.r(10, .medium)).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: cols, spacing: 6) {
                ForEach(0..<(offset + count), id: \.self) { i in
                    let d = i - offset + 1
                    if d < 1 {
                        Color.clear.frame(height: 34)
                    } else {
                    let day = cal.date(byAdding: .day, value: d - 1, to: first)!
                    let isDone = done.contains(day)
                    let future = day > .now && !cal.isDateInToday(day)
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.snappy) { habit.toggle(day, in: context) }
                    } label: {
                        Text("\(d)")
                            .font(.r(12, isDone ? .bold : .medium))
                            .foregroundStyle(isDone ? Theme.onColor : (future ? Color.secondary.opacity(0.6) : Color.primary))
                            .frame(width: 32, height: 32)
                            .background(isDone ? color : .clear, in: Circle())
                            .overlay(Circle().stroke(cal.isDateInToday(day) ? Theme.accent : .clear, lineWidth: 2))
                            .frame(maxWidth: .infinity, minHeight: 34)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(future)
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(tr("統計", "Stats")).font(.r(16, .bold)).padding(.leading, 4)
            HStack(spacing: 10) {
                stat("\(habit.totalCount)", tr("完成次數", "Total"))
                stat("\(habit.currentStreak)", tr("連續天數", "Streak"))
                stat("\(habit.maxStreak)", tr("最大連續", "Best streak"))
            }
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.r(24, .bold)).monospacedDigit()
            Text(label).font(.r(11, .regular)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
