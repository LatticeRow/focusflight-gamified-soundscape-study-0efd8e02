import Foundation
import UserNotifications

@MainActor
final class NotificationService {
    private let notificationCenter: UNUserNotificationCenter
    private(set) var isAuthorized = false

    init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
    }

    func requestAuthorizationIfNeeded() {
        Task {
            let granted = (try? await notificationCenter.requestAuthorization(options: [.alert, .sound])) ?? false
            await MainActor.run {
                isAuthorized = granted
            }
        }
    }

    func scheduleCompletionNotification(for session: FocusSession, route: FlightRoute) {
        guard session.status == .active else { return }
        cancelNotification(for: session.id)

        let content = UNMutableNotificationContent()
        content.title = "\(route.destinationCode) reached"
        content.body = "\(route.originCode) to \(route.destinationCode) is complete."
        content.sound = .default

        let interval = max(1, session.expectedEndAt.timeIntervalSinceNow)
        let request = UNNotificationRequest(
            identifier: notificationID(for: session.id),
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        )

        notificationCenter.add(request)
    }

    func cancelNotification(for sessionID: UUID) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationID(for: sessionID)])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [notificationID(for: sessionID)])
    }

    private func notificationID(for sessionID: UUID) -> String {
        "session.\(sessionID.uuidString)"
    }
}
