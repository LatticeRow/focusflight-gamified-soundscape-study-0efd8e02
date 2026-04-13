import Foundation

struct FlightRoute: Codable, Hashable, Identifiable {
    let id: String
    let originCity: String
    let originCode: String
    let destinationCity: String
    let destinationCode: String
    let distanceKm: Int
    let estimatedMinutes: Int
    let themeName: String
    let audioTrackID: String

    var cityPair: String {
        "\(originCity) to \(destinationCity)"
    }

    var codePair: String {
        "\(originCode)  •  \(destinationCode)"
    }

    static let placeholder = FlightRoute(
        id: "sfo-jfk",
        originCity: "San Francisco",
        originCode: "SFO",
        destinationCity: "New York",
        destinationCode: "JFK",
        distanceKm: 4162,
        estimatedMinutes: 50,
        themeName: "Coastal Red-Eye",
        audioTrackID: UserPreferences.AudioTrack.steady.id
    )
}
