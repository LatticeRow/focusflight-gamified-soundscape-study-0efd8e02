import Foundation

enum SeedDataLoader {
    static func loadRoutes(bundle: Bundle = .main) -> [FlightRoute] {
        guard let url = bundle.url(forResource: "routes", withExtension: "json") else {
            return [FlightRoute.placeholder]
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([FlightRoute].self, from: data)
        } catch {
            return [FlightRoute.placeholder]
        }
    }
}
