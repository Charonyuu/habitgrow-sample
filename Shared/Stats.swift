import Foundation
import SwiftData
import WidgetKit

enum Cal {
    static var c: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday first
        return cal
    }
}

struct HabitSnapshot: Identifiable {
    let id: String
    let name: String
    let icon: String
    let colorIndex: Int
    let subtitle: String
    let rate: Double
    let doneToday: Bool
    var level: Int = 0
    var caption: String = ""
    var status: String = ""
    var urgent: Bool = false
}

/// Progress inside the habit's own period: today/this week for daily habits,
/// this week for weekly habits, this month for monthly habits.
struct HabitProgress {
    var done: Int
    var target: Int
    var periodLabel: String
    var status: String
    var urgent: Bool
    var complete: Bool

    var rate: Double { min(1, Double(done) / Double(max(target, 1))) }
    var caption: String { "\(periodLabel) \(done)/\(target)" }

    static func make(frequency: Frequency, count: Int, doneDays: Set<Date>, now: Date = .now) -> HabitProgress {
        let cal = Cal.c
        let today = cal.startOfDay(for: now)
        switch frequency {
        case .day:
            let week = cal.dateInterval(of: .weekOfYear, for: now)!
            let done = doneDays.filter { week.contains($0) }.count
            if doneDays.contains(today) {
                return .init(done: done, target: 7, periodLabel: tr("本週", "Week"),
                             status: tr("今天完成 ✓", "Done today ✓"), urgent: false, complete: true)
            }
            let end = cal.date(byAdding: .day, value: 1, to: today)!
            let hours = max(1, Int(ceil(end.timeIntervalSince(now) / 3600)))
            return .init(done: done, target: 7, periodLabel: tr("本週", "Week"),
                         status: tr("今天還剩 \(hours) 小時", "\(hours)h left today", ko: "오늘 \(hours)시간 남음", ja: "今日はあと\(hours)時間"),
                         urgent: hours <= 4, complete: false)
        case .week, .month:
            let component: Calendar.Component = frequency == .week ? .weekOfYear : .month
            let interval = cal.dateInterval(of: component, for: now)!
            let done = doneDays.filter { interval.contains($0) }.count
            let need = max(0, count - done)
            let daysLeft = max(1, cal.dateComponents([.day], from: today, to: interval.end).day ?? 1)
            let label = frequency == .week ? tr("本週", "Week") : tr("本月", "Month")
            if need == 0 {
                let text = frequency == .week ? tr("本週達標 🌱", "Weekly goal reached 🌱") : tr("本月達標 🌱", "Monthly goal reached 🌱")
                return .init(done: done, target: count, periodLabel: label, status: text, urgent: false, complete: true)
            }
            return .init(done: done, target: count, periodLabel: label,
                         status: tr("還差 \(need) 次・剩 \(daysLeft) 天", "\(need) to go · \(daysLeft)d left", ko: "\(need)회 남음 · \(daysLeft)일 남음", ja: "あと\(need)回・残り\(daysLeft)日"),
                         urgent: need >= daysLeft, complete: false)
        }
    }
}

extension Habit {
    var frequency: Frequency {
        get { Frequency(rawValue: frequencyRaw) ?? .week }
        set { frequencyRaw = newValue.rawValue }
    }

    static func subtitle(_ frequency: Frequency, _ count: Int) -> String {
        switch frequency {
        case .day: return tr("每天", "every 1 day")
        case .week: return tr("每週 \(count) 次", "\(count) x a week", ko: "주 \(count)회", ja: "週に\(count)回")
        case .month: return tr("每月 \(count) 次", "\(count) x a month", ko: "월 \(count)회", ja: "月に\(count)回")
        }
    }

    var subtitle: String { Habit.subtitle(frequency, targetCount) }

    var icon: String {
        if name.contains("讀") || name.lowercased().contains("read") { return "book.fill" }
        if name.contains("動") || name.contains("健") || name.lowercased().contains("gym") { return "dumbbell.fill" }
        if name.contains("水") || name.lowercased().contains("water") { return "drop.fill" }
        if name.contains("冥") || name.contains("靜") || name.lowercased().contains("medit") { return "leaf.fill" }
        if name.contains("睡") { return "moon.fill" }
        if name.contains("房") || name.contains("掃") || name.contains("整理") { return "sparkles" }
        return "star.fill"
    }

    var doneDays: Set<Date> {
        Set(completions.map { Cal.c.startOfDay(for: $0.day) })
    }

    func isDone(_ date: Date) -> Bool {
        doneDays.contains(Cal.c.startOfDay(for: date))
    }

    func completionCount(inMonth date: Date) -> Int {
        let cal = Cal.c
        return doneDays.filter { cal.isDate($0, equalTo: date, toGranularity: .month) }.count
    }

    func rate(inMonth date: Date) -> Double {
        let days = Double(Cal.c.range(of: .day, in: .month, for: date)?.count ?? 30)
        let expected: Double
        switch frequency {
        case .day: expected = days
        case .week: expected = Double(targetCount) * days / 7
        case .month: expected = Double(targetCount)
        }
        return min(1, Double(completionCount(inMonth: date)) / max(expected, 1))
    }

    var totalCount: Int { doneDays.count }

    var currentStreak: Int {
        let cal = Cal.c
        let days = doneDays
        var cursor = cal.startOfDay(for: .now)
        if !days.contains(cursor) {
            cursor = cal.date(byAdding: .day, value: -1, to: cursor)!
        }
        var n = 0
        while days.contains(cursor) {
            n += 1
            cursor = cal.date(byAdding: .day, value: -1, to: cursor)!
        }
        return n
    }

    var maxStreak: Int {
        let cal = Cal.c
        let sorted = doneDays.sorted()
        var best = 0, run = 0
        var prev: Date?
        for d in sorted {
            if let p = prev, cal.date(byAdding: .day, value: 1, to: p) == d { run += 1 } else { run = 1 }
            best = max(best, run)
            prev = d
        }
        return best
    }

    var progress: HabitProgress {
        HabitProgress.make(frequency: frequency, count: targetCount, doneDays: doneDays)
    }

    var snapshot: HabitSnapshot {
        let p = progress
        return HabitSnapshot(
            id: id.uuidString, name: name, icon: icon, colorIndex: colorIndex,
            subtitle: subtitle, rate: p.rate, doneToday: isDone(.now),
            level: townLevel, caption: p.caption, status: p.status, urgent: p.urgent
        )
    }

    @MainActor
    func toggle(_ date: Date, in context: ModelContext) {
        let cal = Cal.c
        let existing = completions.filter { cal.isDate($0.day, inSameDayAs: date) }
        if existing.isEmpty {
            context.insert(Completion(day: cal.startOfDay(for: date), habit: self))
        } else {
            existing.forEach { context.delete($0) }
        }
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
