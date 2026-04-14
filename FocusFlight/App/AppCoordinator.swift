import SwiftData
import SwiftUI

struct AppCoordinator: View {
    @Environment(\.scenePhase) private var scenePhase
    let appEnvironment: AppEnvironment
    @ObservedObject private var router: AppRouter
    @ObservedObject private var preferences: UserPreferences

    init(appEnvironment: AppEnvironment) {
        self.appEnvironment = appEnvironment
        _router = ObservedObject(wrappedValue: appEnvironment.router)
        _preferences = ObservedObject(wrappedValue: appEnvironment.preferences)
    }

    private var selectedRoute: FlightRoute {
        appEnvironment.routeRepository.route(id: router.selectedRouteID)
            ?? appEnvironment.routeRepository.routes.first
            ?? .placeholder
    }

    var body: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack {
                HomeView(
                    route: selectedRoute,
                    durationMinutes: $preferences.defaultDurationMinutes,
                    audioTrackTitle: appEnvironment.routeRepository.audioTrack(id: preferences.defaultAudioTrackID)?.title
                        ?? preferences.defaultAudioTrack.title,
                    onChangeRoute: { router.isRoutePickerPresented = true },
                    onStartFlight: {
                        router.activeSession = .init(
                            route: selectedRoute,
                            plannedMinutes: preferences.defaultDurationMinutes,
                            selectedAudioTrackID: preferences.defaultAudioTrack.id
                        )
                    }
                )
            }
            .tabItem {
                Label("Home", systemImage: "airplane.departure")
            }
            .tag(AppRouter.Tab.home)

            NavigationStack {
                PassportView(achievementEngine: appEnvironment.achievementEngine)
            }
            .tabItem {
                Label("Passport", systemImage: "ticket.fill")
            }
            .tag(AppRouter.Tab.passport)

            NavigationStack {
                SettingsView(preferences: preferences)
            }
            .tabItem {
                Label("Settings", systemImage: "slider.horizontal.3")
            }
            .tag(AppRouter.Tab.settings)
        }
        .tint(FFColors.accent)
        .background(FFColors.background.ignoresSafeArea())
        .sheet(isPresented: $router.isRoutePickerPresented) {
            NavigationStack {
                RoutePickerView(
                    routes: appEnvironment.routeRepository.routes,
                    selectedRouteID: router.selectedRouteID,
                    onSelect: { route in
                        router.selectedRouteID = route.id
                        router.isRoutePickerPresented = false
                    }
                )
            }
            .presentationDetents([.medium, .large])
        }
        .fullScreenCover(item: $router.activeSession) { draft in
            FlightSessionView(
                sessionDraft: draft,
                preferences: preferences,
                sessionEngine: appEnvironment.sessionEngine,
                sessionRepository: appEnvironment.sessionRepository,
                audioPlayerService: appEnvironment.audioPlayerService,
                notificationService: appEnvironment.notificationService
            ) {
                router.activeSession = nil
            }
        }
        .onChange(of: scenePhase) { _, phase in
            appEnvironment.lifecycleCoordinator.handle(phase: phase)
        }
    }
}
