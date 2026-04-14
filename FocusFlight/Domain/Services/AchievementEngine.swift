import Foundation

struct AchievementEngine {
    struct AchievementProgress: Identifiable, Equatable {
        let definition: AchievementDefinition
        let isUnlocked: Bool
        let progressValue: Double
        let progressLabel: String
        let unlockedAt: Date?

        var id: String { definition.id }
    }

    func unlockedAchievements(sessionCount: Int, totalMinutes: Int, latestCompletion: Date?) -> Set<String> {
        achievementProgress(
            for: summary(
                sessionCount: sessionCount,
                totalMinutes: totalMinutes,
                latestCompletion: latestCompletion
            )
        )
        .filter(\.isUnlocked)
        .reduce(into: Set<String>()) { result, progress in
            result.insert(progress.id)
        }
    }

    func achievementProgress(for sessions: [FocusSession]) -> [AchievementProgress] {
        let completedSessions = sessions
            .filter { $0.status == .completed }
            .sorted {
                ($0.completedAt ?? $0.startedAt) < ($1.completedAt ?? $1.startedAt)
            }

        var totalMinutes = 0
        var unlockedAtByID: [String: Date] = [:]

        for (index, session) in completedSessions.enumerated() {
            let completionDate = session.completedAt ?? session.expectedEndAt
            let completedCount = index + 1
            totalMinutes += session.plannedMinutes

            if completedCount >= 1, unlockedAtByID["first-flight"] == nil {
                unlockedAtByID["first-flight"] = completionDate
            }

            if completedCount >= 5, unlockedAtByID["frequent-flyer"] == nil {
                unlockedAtByID["frequent-flyer"] = completionDate
            }

            if totalMinutes >= 300, unlockedAtByID["long-haul"] == nil {
                unlockedAtByID["long-haul"] = completionDate
            }

            if Calendar.current.component(.hour, from: completionDate) >= 21,
               unlockedAtByID["red-eye"] == nil {
                unlockedAtByID["red-eye"] = completionDate
            }
        }

        return achievementProgress(
            for: summary(
                sessionCount: completedSessions.count,
                totalMinutes: totalMinutes,
                latestCompletion: completedSessions.last.map { $0.completedAt ?? $0.expectedEndAt },
                unlockedAtByID: unlockedAtByID
            )
        )
    }

    private struct Summary {
        let sessionCount: Int
        let totalMinutes: Int
        let latestCompletion: Date?
        let unlockedAtByID: [String: Date]
    }

    private func summary(
        sessionCount: Int,
        totalMinutes: Int,
        latestCompletion: Date?,
        unlockedAtByID: [String: Date] = [:]
    ) -> Summary {
        Summary(
            sessionCount: sessionCount,
            totalMinutes: totalMinutes,
            latestCompletion: latestCompletion,
            unlockedAtByID: unlockedAtByID
        )
    }

    private func achievementProgress(for summary: Summary) -> [AchievementProgress] {
        AchievementDefinition.catalog.map { definition in
            switch definition.rule {
            case let .sessionCount(target):
                let progress = min(Double(summary.sessionCount) / Double(target), 1)
                return AchievementProgress(
                    definition: definition,
                    isUnlocked: summary.sessionCount >= target,
                    progressValue: progress,
                    progressLabel: "\(min(summary.sessionCount, target))/\(target)",
                    unlockedAt: summary.unlockedAtByID[definition.id]
                )
            case let .totalMinutes(target):
                let progress = min(Double(summary.totalMinutes) / Double(target), 1)
                return AchievementProgress(
                    definition: definition,
                    isUnlocked: summary.totalMinutes >= target,
                    progressValue: progress,
                    progressLabel: "\(min(summary.totalMinutes, target))/\(target)m",
                    unlockedAt: summary.unlockedAtByID[definition.id]
                )
            case let .completionHourAtOrAfter(hour):
                let isUnlocked = summary.latestCompletion.map {
                    Calendar.current.component(.hour, from: $0) >= hour
                } ?? false

                return AchievementProgress(
                    definition: definition,
                    isUnlocked: isUnlocked,
                    progressValue: isUnlocked ? 1 : 0,
                    progressLabel: isUnlocked ? "Unlocked" : "After 9 PM",
                    unlockedAt: summary.unlockedAtByID[definition.id]
                )
            }
        }
    }
}
