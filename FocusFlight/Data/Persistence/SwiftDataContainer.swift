import Foundation
import SwiftData

enum SwiftDataContainer {
    @MainActor
    static func makeDefaultContainer(
        inMemory: Bool = false,
        storeName: String = "AurelineStore"
    ) -> ModelContainer {
        let schema = Schema([
            FocusSession.self,
            PassportStamp.self,
        ])

        let configuration = ModelConfiguration(
            storeName,
            isStoredInMemoryOnly: inMemory
        )

        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Unable to create SwiftData container: \(error)")
        }
    }
}
