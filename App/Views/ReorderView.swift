import SwiftUI
import SwiftData

struct ReorderView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text(tr("排列", "Arrange")).font(.r(20, .bold))
                    Spacer()
                    Button { dismiss() } label: {
                        Text(tr("完成", "Done"))
                            .font(.r(15, .bold)).foregroundStyle(.white)
                            .padding(.horizontal, 16).frame(height: 34)
                            .background(Theme.accent, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 26)
                .padding(.bottom, 6)

                Text(tr("按住右側的 ≡ 拖曳排序", "Drag the ≡ handle to reorder"))
                    .font(.r(13, .regular)).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24).padding(.bottom, 8)

                List {
                    ForEach(habits) { habit in
                        HStack(spacing: 12) {
                            Circle().fill(Theme.color(habit.colorIndex)).frame(width: 14, height: 14)
                            Text(habit.name).font(.r(16, .semibold)).lineLimit(1)
                            Text(habit.subtitle).font(.r(12, .regular)).foregroundStyle(.secondary)
                            Spacer()
                        }
                        .frame(height: 30)
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Theme.card)
                                .padding(.vertical, 4)
                        )
                        .listRowSeparator(.hidden)
                    }
                    .onMove(perform: move)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .environment(\.editMode, .constant(.active))
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
        .presentationBackground(Theme.background)
    }

    private func move(from source: IndexSet, to destination: Int) {
        var list = habits
        list.move(fromOffsets: source, toOffset: destination)
        for (i, h) in list.enumerated() { h.sortOrder = i }
        try? context.save()
    }
}
