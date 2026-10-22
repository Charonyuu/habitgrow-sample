import SwiftUI

struct HabitTab: View {
    var color: Color
    var width: CGFloat = 30
    var height: CGFloat = 56

    var body: some View {
        let r = min(width, height / 2)
        UnevenRoundedRectangle(
            topLeadingRadius: 0, bottomLeadingRadius: 0,
            bottomTrailingRadius: r, topTrailingRadius: r
        )
        .fill(color)
        .frame(width: width, height: height)
    }
}

struct ProgressBar: View {
    var value: Double
    var color: Color
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.track)
                Capsule().fill(color)
                    .frame(width: max(value > 0 ? height : 0, geo.size.width * value))
            }
        }
        .frame(height: height)
    }
}

struct CheckCircle: View {
    var done: Bool
    var color: Color
    var size: CGFloat = 28

    var body: some View {
        ZStack {
            Circle().stroke(Theme.track, lineWidth: 2)
            if done {
                Circle().fill(color)
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.42, weight: .bold))
                    .foregroundStyle(Theme.onColor)
            }
        }
        .frame(width: size, height: size)
    }
}

struct LogoMark: View {
    var size: CGFloat = 30

    var body: some View {
        Image("Sprout")
            .resizable().scaledToFit()
            .frame(width: size, height: size)
    }
}

func percentText(_ rate: Double) -> String { "\(Int((rate * 100).rounded()))%" }

struct HabitRowCard: View {
    let name: String
    let subtitle: String
    let color: Color
    let progress: HabitProgress
    let done: Bool
    var onToggle: (() -> Void)?

    var body: some View {
        HStack(spacing: 14) {
            HabitTab(color: color)
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(name.isEmpty ? " " : name)
                        .font(.r(17, .bold)).lineLimit(1)
                    Text(subtitle)
                        .font(.r(11, .regular)).foregroundStyle(.secondary).lineLimit(1)
                }
                ProgressBar(value: progress.rate, color: color)
                Text(progress.status)
                    .font(.r(11, .medium))
                    .foregroundStyle(progress.urgent ? Theme.warn : Color.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 1) {
                Text(percentText(progress.rate))
                    .font(.r(20, .bold)).monospacedDigit()
                Text(progress.caption)
                    .font(.r(11, .regular)).foregroundStyle(.secondary).monospacedDigit()
            }
            Button { onToggle?() } label: {
                CheckCircle(done: done, color: color)
            }
            .buttonStyle(.plain)
        }
        .padding(.trailing, 16)
        .frame(height: 88)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .contentShape(Rectangle())
    }
}

struct PillTabs<T: Hashable>: View {
    let items: [T]
    let title: (T) -> String
    @Binding var selection: T

    var body: some View {
        HStack(spacing: 8) {
            ForEach(items, id: \.self) { item in
                let selected = item == selection
                Button {
                    withAnimation(.snappy(duration: 0.25)) { selection = item }
                } label: {
                    Text(title(item))
                        .font(.r(15, .semibold))
                        .foregroundStyle(selected ? Color.white : Color.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(selected ? Theme.accent : Theme.card, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
