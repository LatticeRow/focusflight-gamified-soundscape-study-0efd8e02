import SwiftData

@MainActor
struct SessionRepository {
    func insert(_ session: FocusSession, in context: ModelContext) throws {
        context.insert(session)
        try saveChanges(in: context)
    }

    func insert(_ stamp: PassportStamp, in context: ModelContext) throws {
        context.insert(stamp)
        try saveChanges(in: context)
    }

    func saveChanges(in context: ModelContext) throws {
        if context.hasChanges {
            try context.save()
        }
    }

    func stamp(for session: FocusSession, in context: ModelContext) throws -> PassportStamp {
        let existingStamps = try context.fetch(FetchDescriptor<PassportStamp>())
        if let existing = existingStamps.first(where: { $0.sessionID == session.id }) {
            return existing
        }

        let stamp = PassportStamp(
            sessionID: session.id,
            awardedAt: session.completedAt ?? .now,
            title: session.routeThemeName,
            originCode: session.originCode,
            destinationCode: session.destinationCode,
            minutesFlown: session.plannedMinutes,
            badgeStyle: "gold"
        )

        context.insert(stamp)
        try saveChanges(in: context)
        return stamp
    }
}
