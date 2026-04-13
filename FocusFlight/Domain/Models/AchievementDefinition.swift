import Foundation

struct AchievementDefinition: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let symbolName: String

    static let catalog: [AchievementDefinition] = [
        .init(id: "first-flight", title: "First Flight", detail: "Complete one flight.", symbolName: "sparkles"),
        .init(id: "frequent-flyer", title: "Frequent Flyer", detail: "Complete five flights.", symbolName: "airplane.circle.fill"),
        .init(id: "long-haul", title: "Long Haul", detail: "Reach 300 focused minutes.", symbolName: "globe.americas.fill"),
        .init(id: "red-eye", title: "Red Eye", detail: "Finish a flight after 9 PM.", symbolName: "moon.stars.fill"),
    ]
}
