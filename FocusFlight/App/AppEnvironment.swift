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

    init() {
        let preferences = UserPreferences()
        self.preferences = preferences
        self.routeRepository = RouteRepository()
        self.sessionRepository = SessionRepository()
        self.sessionEngine = SessionEngine()
        self.achievementEngine = AchievementEngine()
        self.audioPlayerService = AudioPlayerService()
        self.notificationService = NotificationService()
        self.lifecycleCoordinator = AppLifecycleCoordinator()
        self.router = AppRouter(initialRouteID: routeRepository.routes.first?.id)
    }
}

@MainActor
final class AppRouter: ObservableObject {
    enum Tab: Hashable {
        case home
        case passport
        case settings
    }

    struct SessionDraft: Identifiable, Equatable {
        let id = UUID()
        let route: FlightRoute
        let plannedMinutes: Int
        let selectedAudioTrackID: String
    }

    @Published var selectedTab: Tab = .home
    @Published var selectedRouteID: String?
    @Published var isRoutePickerPresented = false
    @Published var activeSession: SessionDraft?

    init(initialRouteID: String?) {
        self.selectedRouteID = initialRouteID
    }
}
