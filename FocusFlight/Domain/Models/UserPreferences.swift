import Combine
import Foundation

@MainActor
final class UserPreferences: ObservableObject {
    enum AudioTrack: String, CaseIterable, Codable, Identifiable {
        case steady
        case rain
        case night

        static let fallback: Self = .steady

        var id: String { rawValue }

        var title: String {
            switch self {
            case .steady: "Signature"
            case .rain: "Rain"
            case .night: "Midnight"
            }
        }

        var assetName: String {
            switch self {
            case .steady: "cabin_steady_01"
            case .rain: "cabin_rain_01"
            case .night: "cabin_night_01"
            }
        }

        var bundledFileName: String {
            "\(assetName).wav"
        }

        var detail: String {
            switch self {
            case .steady: "Steady cabin air"
            case .rain: "Window-side rain"
            case .night: "Quiet red-eye cabin"
            }
        }
    }

    static let durationPresets = [25, 50, 90]

    private enum Keys {
        static let defaultDuration = "default_duration_minutes"
        static let audioTrack = "default_audio_track"
        static let audioVolume = "audio_volume"
        static let notificationsEnabled = "notifications_enabled"
        static let hapticsEnabled = "haptics_enabled"
    }

    private let defaults: UserDefaults

    @Published var defaultDurationMinutes: Int {
        didSet {
            let normalized = Self.durationPresets.contains(defaultDurationMinutes) ? defaultDurationMinutes : 25
            if normalized != defaultDurationMinutes {
                defaultDurationMinutes = normalized
                return
            }
            defaults.set(normalized, forKey: Keys.defaultDuration)
        }
    }

    @Published var defaultAudioTrackID: String {
        didSet {
            let normalized = AudioTrack(rawValue: defaultAudioTrackID)?.id ?? AudioTrack.fallback.id
            if normalized != defaultAudioTrackID {
                defaultAudioTrackID = normalized
                return
            }
            defaults.set(normalized, forKey: Keys.audioTrack)
        }
    }

    @Published var audioVolume: Double {
        didSet {
            let normalized = min(max(audioVolume, 0), 1)
            if normalized != audioVolume {
                audioVolume = normalized
                return
            }
            defaults.set(normalized, forKey: Keys.audioVolume)
        }
    }

    @Published var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Keys.notificationsEnabled) }
    }

    @Published var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Keys.hapticsEnabled) }
    }

    var defaultAudioTrack: AudioTrack {
        AudioTrack(rawValue: defaultAudioTrackID) ?? .fallback
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let persistedDuration = defaults.object(forKey: Keys.defaultDuration) as? Int ?? 25
        self.defaultDurationMinutes = Self.durationPresets.contains(persistedDuration) ? persistedDuration : 25
        self.defaultAudioTrackID = AudioTrack(rawValue: defaults.string(forKey: Keys.audioTrack) ?? "")?.id ?? AudioTrack.fallback.id
        self.audioVolume = min(max(defaults.object(forKey: Keys.audioVolume) as? Double ?? 0.72, 0), 1)
        self.notificationsEnabled = defaults.object(forKey: Keys.notificationsEnabled) as? Bool ?? true
        self.hapticsEnabled = defaults.object(forKey: Keys.hapticsEnabled) as? Bool ?? true
    }
}
