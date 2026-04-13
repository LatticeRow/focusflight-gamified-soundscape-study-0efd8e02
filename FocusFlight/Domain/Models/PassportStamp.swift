import Foundation
import SwiftData

@Model
final class PassportStamp {
    @Attribute(.unique) var id: UUID
    var sessionID: UUID
    var awardedAt: Date
    var title: String
    var originCode: String
    var destinationCode: String
    var minutesFlown: Int
    var badgeStyle: String

    init(
        id: UUID = UUID(),
        sessionID: UUID,
        awardedAt: Date,
        title: String,
        originCode: String,
        destinationCode: String,
        minutesFlown: Int,
        badgeStyle: String
    ) {
        self.id = id
        self.sessionID = sessionID
        self.awardedAt = awardedAt
        self.title = title
        self.originCode = originCode
        self.destinationCode = destinationCode
        self.minutesFlown = minutesFlown
        self.badgeStyle = badgeStyle
    }
}
