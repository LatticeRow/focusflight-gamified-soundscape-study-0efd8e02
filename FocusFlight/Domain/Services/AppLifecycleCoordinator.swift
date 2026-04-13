import SwiftUI

@MainActor
final class AppLifecycleCoordinator {
    private(set) var lastObservedPhase: ScenePhase = .inactive

    func handle(phase: ScenePhase) {
        lastObservedPhase = phase
    }
}
