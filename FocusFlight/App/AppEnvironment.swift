import Foundation
import Combine

enum AppBrand {
    static let name = "Aureline"
}

@MainActor
final class AppEnvironment {
    let router: AppRouter
    let preferences: UserPreferences
    let routeRepository: RouteRepository
    let sessionRepository: SessionRepository
    let sessionEngine: SessionEngine
    let achievementEngine: AchievementEngine
    let audioPlayerService: AudioPlayerService
    let notificationService: NotificationService
    let lifecycleCoordinator: AppLifecycleCoordinator
    private var cancellables = Set<AnyCancellable>()

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let isUITesting = arguments.contains("-uiTesting") || arguments.contains("-uiTestingInMemory")
        let preferences = UserPreferences()
        self.preferences = preferences
        self.routeRepository = RouteRepository()
        self.sessionRepository = SessionRepository()
        self.sessionEngine = SessionEngine()
        self.achievementEngine = AchievementEngine()
        self.audioPlayerService = AudioPlayerService(initialVolume: preferences.audioVolume)
        self.notificationService = NotificationService(allowsAuthorizationPrompt: !isUITesting)
        self.lifecycleCoordinator = AppLifecycleCoordinator(audioPlayerService: audioPlayerService)
        self.router = AppRouter(initialRouteID: routeRepository.routes.first?.id)

        preferences.$audioVolume
            .removeDuplicates()
            .sink { [audioPlayerService] volume in
                audioPlayerService.setVolume(volume)
            }
            .store(in: &cancellables)
    }
}

@MainActor
final class AppRouter: ObservableObject {
    enum Tab: Hashable {
        case home
        case passport
        case settings
    }

    @Published var selectedTab: Tab = .home
    @Published var selectedRouteID: String?
    @Published var isRoutePickerPresented = false
    @Published var activeSession: FocusSession?

    init(initialRouteID: String?) {
        self.selectedRouteID = initialRouteID
    }
}
