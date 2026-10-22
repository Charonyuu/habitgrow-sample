import SwiftUI
import SwiftData

func monthTitle(_ date: Date) -> String {
    date.formatted(.dateTime.year().month(.wide).locale(L10n.locale))
}

func shiftMonth(_ date: Date, by n: Int) -> Date {
    Cal.c.date(byAdding: .month, value: n, to: date) ?? date
}

struct MonthNavigator: View {
    @Binding var month: Date

    var body: some View {
        HStack {
            Button { withAnimation { month = shiftMonth(month, by: -1) } } label: {
                Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold))
                    .frame(width: 36, height: 36)
            }
            Spacer()
            Text(monthTitle(month)).font(.r(18, .semibold))
            Spacer()
            Button { withAnimation { month = shiftMonth(month, by: 1) } } label: {
                Image(systemName: "chevron.right").font(.system(size: 16, weight: .semibold))
                    .frame(width: 36, height: 36)
            }
        }
        .foregroundStyle(.primary)
    }
}

struct MonthView: View {
    let habits: [Habit]
    @State private var month: Date = .now

    private let columns = 11

    private var average: Double {
        guard !habits.isEmpty else { return 0 }
        return habits.map { $0.rate(inMonth: month) }.reduce(0, +) / Double(habits.count)
    }

    private var dayCount: Int { Cal.c.range(of: .day, in: .month, for: month)?.count ?? 30 }

    private func date(_ day: Int) -> Date {
        let cal = Cal.c
        let start = cal.dateInterval(of: .month, for: month)!.start
        return cal.date(byAdding: .day, value: day - 1, to: start)!
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                VStack(spacing: 8) {
                    MonthNavigator(month: $month)
                    Text(tr("本月平均完成率", "Monthly Average Completion"))
                        .font(.r(13, .regular)).foregroundStyle(.secondary)
                    Text(percentText(average)).font(.r(34, .bold)).monospacedDigit()
                    ProgressBar(value: average, color: Theme.color(0))
                }
                .padding(16)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                ForEach(habits) { habit in
                    NavigationLink(value: habit.persistentModelID) {
                        row(habit)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 110)
        }
    }

    private func row(_ habit: Habit) -> some View {
        let color = Theme.color(habit.colorIndex)
        let done = habit.doneDays
        return HStack(spacing: 0) {
            HabitTab(color: color, width: 24, height: 44)
            Text(habit.name)
                .font(.r(14, .bold)).lineLimit(1)
                .frame(width: 56, alignment: .leading)
                .padding(.leading, 10)
            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(9), spacing: 7), count: columns),
                alignment: .leading, spacing: 7
            ) {
                ForEach(1...dayCount, id: \.self) { d in
                    let day = date(d)
                    let isDone = done.contains(day)
                    Circle()
                        .fill(isDone ? color : Theme.track)
                        .frame(width: 9, height: 9)
                        .opacity(day > .now && !isDone ? 0.5 : 1)
                }
            }
            .padding(.leading, 6)
            Spacer(minLength: 0)
        }
        .padding(.trailing, 12)
        .padding(.vertical, 14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
