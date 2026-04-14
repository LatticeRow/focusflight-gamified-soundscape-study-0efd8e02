import Foundation

struct AchievementDefinition: Identifiable, Hashable {
    enum Rule: Hashable {
        case sessionCount(Int)
        case totalMinutes(Int)
        case completionHourAtOrAfter(Int)
    }

    let id: String
    let title: String
    let detail: String
    let symbolName: String
    let rule: Rule

    static let catalog: [AchievementDefinition] = [
        .init(
            id: "first-flight",
            title: "First Flight",
            detail: "Finish 1 flight.",
            symbolName: "sparkles",
            rule: .sessionCount(1)
        ),
        .init(
            id: "frequent-flyer",
            title: "Frequent Flyer",
            detail: "Finish 5 flights.",
            symbolName: "airplane.circle.fill",
            rule: .sessionCount(5)
        ),
        .init(
            id: "long-haul",
            title: "Long Haul",
            detail: "Reach 300 focused minutes.",
            symbolName: "globe.americas.fill",
            rule: .totalMinutes(300)
        ),
        .init(
            id: "red-eye",
            title: "Red Eye",
            detail: "Finish after 9 PM.",
            symbolName: "moon.stars.fill",
            rule: .completionHourAtOrAfter(21)
        ),
    ]
}
