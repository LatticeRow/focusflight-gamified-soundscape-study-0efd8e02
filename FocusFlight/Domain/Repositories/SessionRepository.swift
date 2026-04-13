import SwiftData

struct SessionRepository {
    func save(_ session: FocusSession, in context: ModelContext) throws {
        context.insert(session)
        try context.save()
    }

    func save(_ stamp: PassportStamp, in context: ModelContext) throws {
        context.insert(stamp)
        try context.save()
    }
}
