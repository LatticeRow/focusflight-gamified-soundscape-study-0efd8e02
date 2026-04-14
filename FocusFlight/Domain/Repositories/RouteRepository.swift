import Foundation

@MainActor
final class RouteRepository {
    let audioTracks: [UserPreferences.AudioTrack]
    let routes: [FlightRoute]

    init(bundle: Bundle = .main) {
        self.audioTracks = SeedDataLoader.bundledAudioTracks
        self.routes = SeedDataLoader.loadRoutes(
            bundle: bundle,
            validTrackIDs: Set(audioTracks.map(\.id))
        )
    }

    func route(id: String?) -> FlightRoute? {
        guard let id else { return nil }
        return routes.first { $0.id == id }
    }

    func audioTrack(id: String?) -> UserPreferences.AudioTrack? {
        guard let id else { return nil }
        return audioTracks.first { $0.id == id }
    }
}
