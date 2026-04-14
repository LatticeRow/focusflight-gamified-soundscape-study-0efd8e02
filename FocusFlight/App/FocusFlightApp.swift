import SwiftData
import SwiftUI

@main
struct AurelineApp: App {
    @State private var appEnvironment: AppEnvironment
    private let modelContainer: ModelContainer

    init() {
        let processInfo = ProcessInfo.processInfo
        let arguments = processInfo.arguments
        let storeName = processInfo.environment["AURELINE_STORE_NAME"] ?? "AurelineStore"

        _appEnvironment = State(initialValue: AppEnvironment())
        self.modelContainer = SwiftDataContainer.makeDefaultContainer(
            inMemory: arguments.contains("-uiTestingInMemory"),
            storeName: storeName
        )
    }

    var body: some Scene {
        WindowGroup {
            AppCoordinator(appEnvironment: appEnvironment)
                .preferredColorScheme(.dark)
        }
        .modelContainer(modelContainer)
    }
}
