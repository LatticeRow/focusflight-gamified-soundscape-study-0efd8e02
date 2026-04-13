import Foundation

struct AchievementEngine {
    func unlockedAchievements(sessionCount: Int, totalMinutes: Int, latestCompletion: Date?) -> Set<String> {
        var unlocked: Set<String> = []

        if sessionCount >= 1 {
            unlocked.insert("first-flight")
        }
        if sessionCount >= 5 {
            unlocked.insert("frequent-flyer")
        }
        if totalMinutes >= 300 {
            unlocked.insert("long-haul")
        }
        if let latestCompletion, Calendar.current.component(.hour, from: latestCompletion) >= 21 {
            unlocked.insert("red-eye")
        }

        return unlocked
    }
}
