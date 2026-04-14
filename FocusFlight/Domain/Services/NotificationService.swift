import Foundation
import UserNotifications

@MainActor
protocol NotificationCenterClient {
    func authorizationStatus() async -> UNAuthorizationStatus
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func addRequest(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
    func removeDeliveredNotifications(withIdentifiers identifiers: [String])
}

extension UNUserNotificationCenter: NotificationCenterClient {
    func authorizationStatus() async -> UNAuthorizationStatus {
        await notificationSettings().authorizationStatus
    }

    func addRequest(_ request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

@MainActor
final class NotificationService {
    private let notificationCenter: NotificationCenterClient
    private let allowsAuthorizationPrompt: Bool
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    var isAuthorized: Bool {
        authorizationStatus == .authorized || authorizationStatus == .provisional || authorizationStatus == .ephemeral
    }

    init(
        notificationCenter: NotificationCenterClient = UNUserNotificationCenter.current(),
        allowsAuthorizationPrompt: Bool = true
    ) {
        self.notificationCenter = notificationCenter
        self.allowsAuthorizationPrompt = allowsAuthorizationPrompt
    }

    @discardableResult
    func refreshAuthorizationStatus() async -> UNAuthorizationStatus {
        let status = await notificationCenter.authorizationStatus()
        authorizationStatus = status
        return status
    }

    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        let status = await refreshAuthorizationStatus()

        switch status {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            guard allowsAuthorizationPrompt else { return false }

            let granted = (try? await notificationCenter.requestAuthorization(options: [.alert, .sound])) ?? false
            authorizationStatus = granted ? .authorized : .denied
            return granted
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    @discardableResult
    func synchronizeCompletionNotification(
        for session: FocusSession?,
        route: FlightRoute?,
        notificationsEnabled: Bool,
        promptIfNeeded: Bool = false
    ) async -> Bool {
        guard let session else { return false }

        guard notificationsEnabled else {
            cancelNotification(for: session.id)
            return false
        }

        guard session.status == .active, let route else {
            cancelNotification(for: session.id)
            return false
        }

        let isAllowed = promptIfNeeded
            ? await requestAuthorizationIfNeeded()
            : isAuthorizedStatus(await refreshAuthorizationStatus())

        guard isAllowed else {
            cancelNotification(for: session.id)
            return false
        }

        do {
            try await scheduleCompletionNotification(for: session, route: route)
            return true
        } catch {
            return false
        }
    }

    func scheduleCompletionNotification(for session: FocusSession, route: FlightRoute) async throws {
        guard session.status == .active else {
            cancelNotification(for: session.id)
            return
        }
        cancelNotification(for: session.id)

        let content = UNMutableNotificationContent()
        content.title = "\(route.destinationCode) reached"
        content.body = "Your focus block is complete."
        content.sound = .default

        let interval = max(1, session.expectedEndAt.timeIntervalSinceNow)
        let request = UNNotificationRequest(
            identifier: notificationID(for: session.id),
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        )

        try await notificationCenter.addRequest(request)
    }

    func cancelNotification(for sessionID: UUID) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationID(for: sessionID)])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [notificationID(for: sessionID)])
    }

    private func notificationID(for sessionID: UUID) -> String {
        "session.\(sessionID.uuidString)"
    }

    private func isAuthorizedStatus(_ status: UNAuthorizationStatus) -> Bool {
        status == .authorized || status == .provisional || status == .ephemeral
    }
}
