import Foundation

enum SeedDataLoader {
    static let bundledAudioTracks = UserPreferences.AudioTrack.allCases

    static func loadRoutes(
        bundle: Bundle = .main,
        validTrackIDs: Set<String> = Set(bundledAudioTracks.map(\.id))
    ) -> [FlightRoute] {
        guard let url = bundle.url(forResource: "routes", withExtension: "json") else {
            return [FlightRoute.placeholder]
        }

        do {
            let data = try Data(contentsOf: url)
            let routes = try JSONDecoder().decode([FlightRoute].self, from: data)
            let validatedRoutes = routes.filter { route in
                validTrackIDs.contains(route.audioTrackID)
                    && !route.originCity.isEmpty
                    && !route.destinationCity.isEmpty
                    && !route.originCode.isEmpty
                    && !route.destinationCode.isEmpty
                    && route.distanceKm > 0
                    && route.estimatedMinutes > 0
            }
            return validatedRoutes.isEmpty ? [FlightRoute.placeholder] : validatedRoutes
        } catch {
            return [FlightRoute.placeholder]
        }
    }
}
