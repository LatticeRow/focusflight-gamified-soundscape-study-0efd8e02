import SwiftUI

@main
struct FocusFlightApp: App {
    @State private var appEnvironment = AppEnvironment()
    private let modelContainer = SwiftDataContainer.makeDefaultContainer(
        inMemory: ProcessInfo.processInfo.arguments.contains("-uiTesting")
    )

    var body: some Scene {
        WindowGroup {
            AppCoordinator(appEnvironment: appEnvironment)
                .preferredColorScheme(.dark)
        }
        .modelContainer(modelContainer)
    }
}
