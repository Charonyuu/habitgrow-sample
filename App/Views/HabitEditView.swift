import SwiftUI
import SwiftData
import WidgetKit

struct HabitEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Habit.sortOrder) private var allHabits: [Habit]

    let habit: Habit?

    @State private var name: String
    @State private var frequency: Frequency
    @State private var count: Int
    @State private var colorIndex: Int
    @State private var plantType: PlantType
    @State private var showPaywall = false
    @Environment(ProStore.self) private var pro
    @State private var reminderOn: Bool
    @State private var reminderTime: Date
    @FocusState private var nameFocused: Bool

    init(habit: Habit?) {
        self.habit = habit
        _name = State(initialValue: habit?.name ?? "")
        _frequency = State(initialValue: habit?.frequency ?? .week)
        _count = State(initialValue: habit?.targetCount ?? 3)
        _colorIndex = State(initialValue: habit?.colorIndex ?? 0)
        _plantType = State(initialValue: habit?.plant ?? .grass)
        _reminderOn = State(initialValue: habit?.reminderEnabled ?? false)
        let minutes = habit?.reminderMinutes ?? 20 * 60
        _reminderTime = State(initialValue: Cal.c.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: .now) ?? .now)
    }

    private var trimmed: String { name.trimmingCharacters(in: .whitespaces) }
    private var canSave: Bool { !trimmed.isEmpty }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        HabitRowCard(
                            name: trimmed.isEmpty ? tr("新的習慣", "New habit") : trimmed,
                            subtitle: Habit.subtitle(frequency, frequency == .day ? 1 : count),
                            color: Theme.color(colorIndex),
                            progress: HabitProgress.make(
                                frequency: frequency, count: frequency == .day ? 1 : count,
                                doneDays: habit?.doneDays ?? []),
                            done: habit?.isDone(.now) ?? false
                        )
                        .allowsHitTesting(false)
                        .shadow(color: .black.opacity(0.05), radius: 12, y: 4)

                        section(tr("習慣名稱", "Name")) { nameField }
                        section(tr("頻率", "Frequency")) {
                            PillTabs(items: Frequency.allCases, title: { $0.title }, selection: $frequency)
                        }
                        if frequency != .day {
                            section(frequency == .week ? tr("每週幾次", "Times per week") : tr("每月幾次", "Times per month")) {
                                stepper
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        section(tr("顏色", "Color")) { colorPicker }
                        section(tr("提醒", "Reminder")) { reminderCard }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                    .padding(.bottom, 40)
                    .animation(.spring(response: 0.38, dampingFraction: 0.85), value: frequency)
                }
                .scrollDismissesKeyboard(.interactively)
                .scrollIndicators(.hidden)
            }
        }
        .sensoryFeedback(.selection, trigger: colorIndex)
        .sensoryFeedback(.selection, trigger: frequency)
        .sensoryFeedback(.selection, trigger: count)
        .sensoryFeedback(.selection, trigger: reminderOn)
        .sensoryFeedback(.selection, trigger: plantType)
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
        .presentationBackground(Theme.background)
        .task {
            // Wait for the sheet to finish presenting so the keyboard doesn't fight the animation.
            guard habit == nil else { return }
            try? await Task.sleep(for: .milliseconds(550))
            nameFocused = true
        }
    }

    private var topBar: some View {
        HStack {
            Button(tr("取消", "Cancel")) { dismiss() }
                .font(.r(16, .medium))
                .foregroundStyle(.secondary)
            Spacer()
            Text(habit == nil ? tr("新增習慣", "New Habit") : tr("編輯習慣", "Edit Habit"))
                .font(.r(18, .bold))
            Spacer()
            Button(action: save) {
                Text(tr("儲存", "Save"))
                    .font(.r(15, .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .frame(height: 34)
                    .background(Theme.accent, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
            .opacity(canSave ? 1 : 0.4)
            .animation(.snappy, value: canSave)
        }
        .padding(.horizontal, 20)
        .padding(.top, 26)
        .padding(.bottom, 16)
    }

    private var nameField: some View {
        TextField(tr("例如：閱讀", "e.g. Reading"), text: $name)
            .font(.r(17, .semibold))
            .focused($nameFocused)
            .submitLabel(.done)
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Theme.accent.opacity(nameFocused ? 0.8 : 0), lineWidth: 1.5)
            )
            .animation(.easeOut(duration: 0.2), value: nameFocused)
    }

    private var stepper: some View {
        HStack {
            Text("\(count)").font(.r(24, .bold)).monospacedDigit()
                .contentTransition(.numericText())
                .padding(.leading, 6)
            Spacer()
            stepButton("minus") { count = max(1, count - 1) }
            stepButton("plus") { count = min(frequency == .week ? 7 : 31, count + 1) }
        }
        .padding(.horizontal, 12)
        .frame(height: 60)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .animation(.snappy, value: count)
    }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 15, weight: .bold))
                .foregroundStyle(.primary)
                .frame(width: 40, height: 40)
                .background(Theme.track, in: Circle())
        }
        .buttonStyle(.plain)
    }

    private var plantPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(PlantType.allCases) { type in
                    let locked = !type.isFree && !pro.isPro
                    let selected = plantType == type
                    Button {
                        if locked { showPaywall = true } else { plantType = type }
                    } label: {
                        VStack(spacing: 4) {
                            Image(type.previewName)
                                .resizable().scaledToFit()
                                .frame(width: 62, height: 62)
                                .opacity(locked ? 0.55 : 1)
                            Text(type.title).font(.r(11, .semibold))
                                .foregroundStyle(selected ? Theme.accent : Color.primary)
                        }
                        .frame(width: 76, height: 96)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Theme.accent, lineWidth: 2)
                                .opacity(selected ? 1 : 0)
                        )
                        .overlay(alignment: .topTrailing) {
                            if locked {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 9, weight: .bold)).foregroundStyle(.white)
                                    .frame(width: 20, height: 20)
                                    .background(Theme.accent, in: Circle())
                                    .padding(6)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
            .padding(.horizontal, 2)
        }
        .scrollIndicators(.hidden)
        .animation(.snappy, value: plantType)
    }

    private var colorPicker: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 6), spacing: 6) {
            ForEach(Theme.palette.indices, id: \.self) { i in
                Button { colorIndex = i } label: {
                    ZStack {
                        Circle().fill(Theme.palette[i]).frame(width: 36, height: 36)
                        if colorIndex == i {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Theme.onColor)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(4)
                    .overlay(
                        Circle().stroke(Theme.accent, lineWidth: 2)
                            .opacity(colorIndex == i ? 1 : 0)
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: colorIndex)
    }

    private var reminderCard: some View {
        VStack(spacing: 0) {
            Toggle(isOn: $reminderOn) {
                Text(tr("每日提醒", "Daily reminder")).font(.r(16, .medium))
            }
            .tint(Theme.accent)
            .padding(.horizontal, 16)
            .frame(height: 54)
            .onChange(of: reminderOn) { _, on in
                if on { Task { _ = await Notifier.requestAuthorization() } }
            }
            if reminderOn {
                Rectangle().fill(Theme.track.opacity(0.7)).frame(height: 1).padding(.leading, 16)
                HStack {
                    Text(tr("提醒時間", "Time")).font(.r(16, .medium))
                    Spacer()
                    DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .environment(\.locale, L10n.locale)
                }
                .padding(.horizontal, 16)
                .frame(height: 54)
                .transition(.opacity)
            }
        }
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .animation(.snappy, value: reminderOn)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.r(13, .semibold)).foregroundStyle(.secondary).padding(.leading, 4)
            content()
        }
    }

    private func save() {
        let target = frequency == .day ? 1 : count
        let parts = Cal.c.dateComponents([.hour, .minute], from: reminderTime)
        let minutes = (parts.hour ?? 20) * 60 + (parts.minute ?? 0)
        if let habit {
            habit.name = trimmed
            habit.frequency = frequency
            habit.targetCount = target
            habit.colorIndex = colorIndex
            habit.plantType = plantType.rawValue
            habit.reminderEnabled = reminderOn
            habit.reminderMinutes = minutes
        } else {
            let order = (allHabits.map(\.sortOrder).max() ?? -1) + 1
            let new = Habit(name: trimmed, frequency: frequency, targetCount: target,
                            colorIndex: colorIndex, sortOrder: order)
            new.plantType = plantType.rawValue
            new.reminderEnabled = reminderOn
            new.reminderMinutes = minutes
            context.insert(new)
        }
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}
