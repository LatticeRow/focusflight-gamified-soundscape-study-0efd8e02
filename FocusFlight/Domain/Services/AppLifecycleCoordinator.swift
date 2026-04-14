import SwiftUI

@MainActor
final class AppLifecycleCoordinator {
    private let audioPlayerService: AudioPlayerService
    private(set) var lastObservedPhase: ScenePhase = .inactive

    init(audioPlayerService: AudioPlayerService) {
        self.audioPlayerService = audioPlayerService
    }

    func handle(phase: ScenePhase, activeSession: FocusSession?) {
        lastObservedPhase = phase
        audioPlayerService.synchronizePlayback(for: activeSession)
    }
}
