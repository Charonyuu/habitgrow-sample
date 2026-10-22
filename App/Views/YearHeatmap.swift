import SwiftUI

/// Past ~year of check-ins, one column per week. Pro feature.
struct YearHeatmapCard: View {
    let habit: Habit
    let color: Color
    let locked: Bool
    var onUnlock: () -> Void

    private let weeks = 52

    var body: some View {
        let days = habit.doneDays
        let cal = Cal.c
        let today = cal.startOfDay(for: .now)
        let weekStart = cal.dateInterval(of: .weekOfYear, for: today)!.start
        let first = cal.date(byAdding: .weekOfYear, value: -(weeks - 1), to: weekStart)!
        let total = days.filter { $0 >= first && $0 <= today }.count

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(tr("過去一年", "Past year")).font(.r(14, .semibold))
                Spacer()
                Text(tr("\(total) 次", "\(total) check-ins", ko: "\(total)회", ja: "\(total)回")).font(.r(12, .regular)).foregroundStyle(.secondary)
            }
            Canvas { ctx, size in
                let gap: CGFloat = 2
                let cell = (size.width - gap * CGFloat(weeks - 1)) / CGFloat(weeks)
                for w in 0..<weeks {
                    for d in 0..<7 {
                        guard let date = cal.date(byAdding: .day, value: w * 7 + d, to: first), date <= today else { continue }
                        let rect = CGRect(x: CGFloat(w) * (cell + gap), y: CGFloat(d) * (cell + gap), width: cell, height: cell)
                        ctx.fill(Path(roundedRect: rect, cornerRadius: cell * 0.28),
                                 with: .color(days.contains(date) ? color : Theme.track))
                    }
                }
            }
            .frame(height: CGFloat(7) * 5.2 + 12)
            .blur(radius: locked ? 5 : 0)
        }
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            if locked {
                Button(action: onUnlock) {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                        Text(tr("Pro 功能", "Pro feature"))
                    }
                    .font(.r(13, .bold)).foregroundStyle(.white)
                    .padding(.horizontal, 14).frame(height: 34)
                    .background(Theme.accent, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
