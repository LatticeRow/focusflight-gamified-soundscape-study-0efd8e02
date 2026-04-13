import Foundation

@MainActor
final class NotificationService {
    private(set) var isAuthorized = false

    func requestAuthorizationIfNeeded() {
        isAuthorized = true
    }
}
