import Combine
import Foundation

@MainActor
final class UserPreferences: ObservableObject {
    enum AudioTrack: String, CaseIterable, Identifiable {
        case steady
        case rain
        case night

        var id: String { rawValue }

        var title: String {
            switch self {
            case .steady: "Steady"
            case .rain: "Rain"
            case .night: "Night"
            }
        }
    }

    private enum Keys {
        static let defaultDuration = "default_duration_minutes"
        static let audioTrack = "default_audio_track"
        static let notificationsEnabled = "notifications_enabled"
        static let hapticsEnabled = "haptics_enabled"
    }

    private let defaults: UserDefaults

    @Published var defaultDurationMinutes: Int {
        didSet { defaults.set(defaultDurationMinutes, forKey: Keys.defaultDuration) }
    }
    @Published var defaultAudioTrackID: String {
        didSet { defaults.set(defaultAudioTrackID, forKey: Keys.audioTrack) }
    }
    @Published var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Keys.notificationsEnabled) }
    }
    @Published var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Keys.hapticsEnabled) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.defaultDurationMinutes = defaults.object(forKey: Keys.defaultDuration) as? Int ?? 25
        self.defaultAudioTrackID = defaults.string(forKey: Keys.audioTrack) ?? AudioTrack.steady.id
        self.notificationsEnabled = defaults.object(forKey: Keys.notificationsEnabled) as? Bool ?? true
        self.hapticsEnabled = defaults.object(forKey: Keys.hapticsEnabled) as? Bool ?? true
    }
}
