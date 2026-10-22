import Foundation
import UserNotifications

/// Local reminders. Re-scheduled whenever habits or check-ins change, so a habit
/// that is already done today never nags.
enum Notifier {
    static let masterKey = "remindersEnabled"

    static var masterEnabled: Bool {
        UserDefaults.standard.object(forKey: masterKey) as? Bool ?? true
    }

    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    static func status() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    @MainActor
    static func sync(_ habits: [Habit]) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard masterEnabled else { return }
        let st = await status()
        guard st == .authorized || st == .provisional || st == .ephemeral else { return }

        let active = habits.filter(\.reminderEnabled)
        guard !active.isEmpty else { return }
        let days = max(1, min(7, 60 / active.count))
        let cal = Cal.c
        let now = Date.now
        let today = cal.startOfDay(for: now)

        for habit in active {
            for offset in 0..<days {
                guard let day = cal.date(byAdding: .day, value: offset, to: today) else { continue }
                var comps = cal.dateComponents([.year, .month, .day], from: day)
                comps.hour = habit.reminderMinutes / 60
                comps.minute = habit.reminderMinutes % 60
                guard let fire = cal.date(from: comps), fire > now else { continue }
                if offset == 0 && habit.isDone(now) { continue }

                let content = UNMutableNotificationContent()
                content.title = habit.name
                content.body = tr("今天還沒完成，輕輕做一點就好 🌱", "Not done yet today. A little is enough 🌱")
                content.sound = .default
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                let request = UNNotificationRequest(identifier: "\(habit.id.uuidString)-\(offset)", content: content, trigger: trigger)
                try? await center.add(request)
            }
        }
    }
}
