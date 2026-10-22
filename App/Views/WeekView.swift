import SwiftUI
import SwiftData
import UIKit

func weekdayLabels() -> [String] {
    switch L10n.code {
    case "zh": return ["一", "二", "三", "四", "五", "六", "日"]
    case "ko": return ["월", "화", "수", "목", "금", "토", "일"]
    case "ja": return ["月", "火", "水", "木", "金", "土", "日"]
    default: return ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    }
}

struct WeekView: View {
    @Environment(\.modelContext) private var context
    let habits: [Habit]

    private let leadWidth: CGFloat = 102

    private var days: [Date] {
        let cal = Cal.c
        let start = cal.dateInterval(of: .weekOfYear, for: .now)!.start
        return (0..<7).map { cal.date(byAdding: .day, value: $0, to: start)! }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                HStack(spacing: 0) {
                    Color.clear.frame(width: leadWidth, height: 1)
                    ForEach(Array(days.enumerated()), id: \.offset) { i, d in
                        Text(weekdayLabels()[i])
                            .font(.r(11, Cal.c.isDateInToday(d) ? .bold : .medium))
                            .foregroundStyle(Cal.c.isDateInToday(d) ? Color.primary : Color.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.trailing, 12)

                ForEach(habits) { habit in
                    row(habit)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 110)
        }
    }

    private func row(_ habit: Habit) -> some View {
        let color = Theme.color(habit.colorIndex)
        return HStack(spacing: 0) {
            NavigationLink(value: habit.persistentModelID) {
                HStack(spacing: 0) {
                    HabitTab(color: color, width: 24, height: 44)
                    Text(habit.name)
                        .font(.r(14, .bold)).lineLimit(1)
                        .frame(width: 68, alignment: .leading)
                        .padding(.leading, 10)
                }
            }
            .buttonStyle(.plain)
            ForEach(days, id: \.self) { d in
                dot(habit, d, color)
            }
        }
        .padding(.trailing, 12)
        .frame(height: 64)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func dot(_ habit: Habit, _ day: Date, _ color: Color) -> some View {
        let future = day > Date.now && !Cal.c.isDateInToday(day)
        let done = habit.isDone(day)
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.snappy) { habit.toggle(day, in: context) }
        } label: {
            Circle()
                .fill(done ? color : Theme.track)
                .frame(width: 20, height: 20)
                .overlay(Circle().stroke(Cal.c.isDateInToday(day) ? Theme.accent.opacity(0.7) : .clear, lineWidth: 2))
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(future)
        .opacity(future ? 0.5 : 1)
    }
}
