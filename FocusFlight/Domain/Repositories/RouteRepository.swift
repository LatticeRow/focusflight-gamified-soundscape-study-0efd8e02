import Foundation

@MainActor
final class RouteRepository {
    let routes: [FlightRoute]

    init(bundle: Bundle = .main) {
        self.routes = SeedDataLoader.loadRoutes(bundle: bundle)
    }

    func route(id: String?) -> FlightRoute? {
        guard let id else { return nil }
        return routes.first { $0.id == id }
    }
}
