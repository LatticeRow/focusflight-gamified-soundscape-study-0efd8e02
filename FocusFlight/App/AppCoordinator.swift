import SwiftData
import SwiftUI

struct AppCoordinator: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \FocusSession.startedAt, order: .reverse) private var sessions: [FocusSession]

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
                    onStartFlight: startSession
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
        .fullScreenCover(item: $router.activeSession) { session in
            FlightSessionView(
                session: session,
                route: route(for: session),
                preferences: preferences,
                sessionEngine: appEnvironment.sessionEngine,
                sessionRepository: appEnvironment.sessionRepository,
                audioPlayerService: appEnvironment.audioPlayerService,
                notificationService: appEnvironment.notificationService
            ) {
                router.activeSession = nil
            }
        }
        .task {
            synchronizeActiveSession()
        }
        .onChange(of: scenePhase) { _, phase in
            appEnvironment.lifecycleCoordinator.handle(phase: phase)
            if phase == .active {
                synchronizeActiveSession()
            }
        }
    }

    private func startSession() {
        if let existing = sessions.first(where: \.isActiveLike) {
            router.activeSession = existing
            return
        }

        let session = appEnvironment.sessionEngine.startSession(
            route: selectedRoute,
            plannedMinutes: preferences.defaultDurationMinutes,
            selectedAudioTrackID: preferences.defaultAudioTrackID
        )

        do {
            try appEnvironment.sessionRepository.insert(session, in: modelContext)
            if preferences.notificationsEnabled {
                appEnvironment.notificationService.requestAuthorizationIfNeeded()
                appEnvironment.notificationService.scheduleCompletionNotification(for: session, route: selectedRoute)
            }
            router.activeSession = session
        } catch {
            assertionFailure("Failed to start session: \(error)")
        }
    }

    private func synchronizeActiveSession() {
        guard let session = sessions.first(where: \.isActiveLike) else {
            router.activeSession = nil
            return
        }

        let route = route(for: session)
        _ = appEnvironment.sessionEngine.restore(session, routeDistanceKm: route.distanceKm)

        do {
            try appEnvironment.sessionRepository.saveChanges(in: modelContext)

            if session.status == .completed {
                _ = try appEnvironment.sessionRepository.stamp(for: session, in: modelContext)
                appEnvironment.notificationService.cancelNotification(for: session.id)
                router.activeSession = nil
            } else {
                router.activeSession = session
            }
        } catch {
            assertionFailure("Failed to restore session: \(error)")
        }
    }

    private func route(for session: FocusSession) -> FlightRoute {
        appEnvironment.routeRepository.route(id: session.routeID) ?? .placeholder
    }
}
