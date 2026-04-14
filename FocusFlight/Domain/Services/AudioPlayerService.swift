import AVFoundation
import Combine
import Foundation

@MainActor
final class AudioPlayerService: NSObject, ObservableObject {
    enum PlaybackIntent: String {
        case playing
        case paused
    }

    @Published private(set) var currentTrackID: String?
    @Published private(set) var currentAssetName: String?
    @Published private(set) var isPlaying = false
    @Published private(set) var playbackIntent: PlaybackIntent = .playing
    @Published private(set) var lastErrorDescription: String?
    @Published private(set) var volume: Double

    var isPlaybackEnabled: Bool {
        playbackIntent == .playing
    }

    private let bundle: Bundle
    private let audioSession: AVAudioSession
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var playerObservation: NSKeyValueObservation?
    private var cancellables = Set<AnyCancellable>()
    private var shouldResumeAfterInterruption = false
    private var didConfigureSession = false

    init(
        bundle: Bundle = .main,
        audioSession: AVAudioSession = .sharedInstance(),
        initialVolume: Double = 0.72
    ) {
        self.bundle = bundle
        self.audioSession = audioSession
        self.volume = min(max(initialVolume, 0), 1)
        super.init()
        observeAudioSession()
    }

    func preload(trackID: String) {
        _ = prepare(trackID: trackID)
    }

    func setVolume(_ newValue: Double) {
        let normalized = min(max(newValue, 0), 1)
        volume = normalized
        player?.volume = Float(normalized)
    }

    func togglePlaybackIntent(trackID: String) {
        if playbackIntent == .playing {
            pausePlaybackIntent()
        } else {
            resumePlaybackIntent(trackID: trackID)
        }
    }

    func pausePlaybackIntent() {
        playbackIntent = .paused
        pauseOutput()
    }

    func resumePlaybackIntent(trackID: String) {
        playbackIntent = .playing
        play(trackID: trackID)
    }

    func synchronizePlayback(for session: FocusSession?) {
        guard let session else {
            stop()
            return
        }

        switch session.status {
        case .active:
            if playbackIntent == .playing {
                play(trackID: session.selectedAudioTrackID)
            } else {
                preload(trackID: session.selectedAudioTrackID)
                pauseOutput()
            }
        case .paused:
            preload(trackID: session.selectedAudioTrackID)
            pauseOutput()
        case .completed, .cancelled:
            stop()
        }
    }

    private func play(trackID: String) {
        guard prepare(trackID: trackID) else { return }

        do {
            try configureAudioSessionIfNeeded()
            try audioSession.setActive(true)
            player?.volume = Float(volume)
            player?.play()
            isPlaying = player?.timeControlStatus == .playing
            shouldResumeAfterInterruption = false
            lastErrorDescription = nil
        } catch {
            record(error: error, fallbackMessage: "Audio is unavailable right now.")
        }
    }

    @discardableResult
    private func prepare(trackID: String) -> Bool {
        let track = UserPreferences.AudioTrack(rawValue: trackID) ?? .fallback
        let fileName = track.bundledFileName

        if currentTrackID == track.id, player != nil {
            player?.volume = Float(volume)
            return true
        }

        guard let url = bundle.url(forResource: track.assetName, withExtension: "wav", subdirectory: "Audio") else {
            currentTrackID = track.id
            currentAssetName = fileName
            record(fallbackMessage: "The bundled cabin sound could not be found.")
            return false
        }

        let item = AVPlayerItem(url: url)
        let player = AVQueuePlayer()
        player.automaticallyWaitsToMinimizeStalling = false
        player.volume = Float(volume)
        let looper = AVPlayerLooper(player: player, templateItem: item)

        self.player = player
        self.looper = looper
        self.currentTrackID = track.id
        self.currentAssetName = fileName
        self.isPlaying = false
        self.lastErrorDescription = nil
        observePlayer(player)
        return true
    }

    private func stop() {
        player?.pause()
        player?.removeAllItems()
        player = nil
        looper = nil
        playerObservation = nil
        isPlaying = false
        currentTrackID = nil
        currentAssetName = nil
        deactivateAudioSession()
    }

    private func pauseOutput() {
        player?.pause()
        isPlaying = false
        deactivateAudioSession()
    }

    private func configureAudioSessionIfNeeded() throws {
        guard !didConfigureSession else { return }
        try audioSession.setCategory(.playback, mode: .default, options: [.allowAirPlay])
        didConfigureSession = true
    }

    private func deactivateAudioSession() {
        do {
            try audioSession.setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            record(error: error, fallbackMessage: "Audio session deactivation failed.")
        }
    }

    private func observeAudioSession() {
        NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification, object: audioSession)
            .sink { [weak self] notification in
                Task { @MainActor in
                    self?.handleInterruption(notification)
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: AVAudioSession.mediaServicesWereResetNotification, object: audioSession)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.handleMediaServicesReset()
                }
            }
            .store(in: &cancellables)
    }

    private func handleInterruption(_ notification: Notification) {
        guard
            let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: rawType)
        else {
            return
        }

        switch type {
        case .began:
            shouldResumeAfterInterruption = isPlaybackEnabled && isPlaying
            isPlaying = false
        case .ended:
            let rawOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: rawOptions)
            guard shouldResumeAfterInterruption, options.contains(.shouldResume), let currentTrackID else {
                shouldResumeAfterInterruption = false
                return
            }
            play(trackID: currentTrackID)
        @unknown default:
            break
        }
    }

    private func handleMediaServicesReset() {
        didConfigureSession = false
        guard let currentTrackID else { return }

        if isPlaybackEnabled {
            play(trackID: currentTrackID)
        } else {
            _ = prepare(trackID: currentTrackID)
        }
    }

    private func record(error: Error? = nil, fallbackMessage: String) {
        if let error {
            NSLog("AudioPlayerService error: %@", String(describing: error))
        }
        lastErrorDescription = fallbackMessage
        isPlaying = false
    }

    private func observePlayer(_ player: AVQueuePlayer) {
        playerObservation = player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] player, _ in
            Task { @MainActor in
                self?.isPlaying = player.timeControlStatus == .playing
            }
        }
    }
}
