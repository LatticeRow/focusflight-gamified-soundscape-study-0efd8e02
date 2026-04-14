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
                    route: router.activeSession.map(route(for:)) ?? selectedRoute,
                    activeSession: router.activeSession,
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
            seedUITestPassportDataIfNeeded()
            _ = await appEnvironment.notificationService.refreshAuthorizationStatus()
            synchronizeApplicationState(for: scenePhase)
        }
        .onChange(of: scenePhase) { _, phase in
            synchronizeApplicationState(for: phase)
        }
        .onChange(of: sessions.map(\.id)) { _, _ in
            synchronizeApplicationState(for: scenePhase)
        }
        .onChange(of: preferences.notificationsEnabled) { _, isEnabled in
            handleNotificationPreferenceChange(isEnabled)
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
            router.activeSession = session
            synchronizeNotification(for: session, route: selectedRoute, promptIfNeeded: true)
        } catch {
            assertionFailure("Failed to start session: \(error)")
        }
    }

    private func synchronizeApplicationState(for phase: ScenePhase) {
        let activeSession = phase == .active
            ? synchronizeActiveSession()
            : sessions.first(where: \.isActiveLike)

        if phase != .active {
            router.activeSession = activeSession
        }

        appEnvironment.lifecycleCoordinator.handle(phase: phase, activeSession: activeSession)
    }

    @discardableResult
    private func synchronizeActiveSession() -> FocusSession? {
        guard let session = sessions.first(where: \.isActiveLike) else {
            router.activeSession = nil
            synchronizeNotification(for: nil, route: nil)
            return nil
        }

        let route = route(for: session)
        _ = appEnvironment.sessionEngine.restore(session, routeDistanceKm: route.distanceKm)

        do {
            try appEnvironment.sessionRepository.saveChanges(in: modelContext)

            if session.status == .completed {
                _ = try appEnvironment.sessionRepository.stamp(for: session, in: modelContext)
                appEnvironment.notificationService.cancelNotification(for: session.id)
                router.activeSession = nil
                appEnvironment.audioPlayerService.synchronizePlayback(for: nil)
                return nil
            } else {
                router.activeSession = session
                appEnvironment.audioPlayerService.synchronizePlayback(for: session)
                synchronizeNotification(for: session, route: route)
                return session
            }
        } catch {
            assertionFailure("Failed to restore session: \(error)")
            return session
        }
    }

    private func handleNotificationPreferenceChange(_ isEnabled: Bool) {
        let session = sessions.first(where: \.isActiveLike)

        if isEnabled, session == nil {
            Task {
                _ = await appEnvironment.notificationService.requestAuthorizationIfNeeded()
            }
            return
        }

        synchronizeNotification(for: session, route: session.map { route(for: $0) }, promptIfNeeded: isEnabled)
    }

    private func synchronizeNotification(
        for session: FocusSession?,
        route: FlightRoute?,
        promptIfNeeded: Bool = false
    ) {
        Task {
            _ = await appEnvironment.notificationService.synchronizeCompletionNotification(
                for: session,
                route: route,
                notificationsEnabled: preferences.notificationsEnabled,
                promptIfNeeded: promptIfNeeded
            )
        }
    }

    private func route(for session: FocusSession) -> FlightRoute {
        appEnvironment.routeRepository.route(id: session.routeID) ?? .placeholder
    }

    private func seedUITestPassportDataIfNeeded() {
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("-uiTestingSeedPassport") else { return }

        let existingSessions = (try? modelContext.fetch(FetchDescriptor<FocusSession>())) ?? []
        let existingStamps = (try? modelContext.fetch(FetchDescriptor<PassportStamp>())) ?? []
        guard existingSessions.isEmpty, existingStamps.isEmpty else { return }

        let baseDate = Calendar.current.date(
            from: DateComponents(year: 2026, month: 4, day: 13, hour: 21, minute: 30)
        ) ?? .now
        let routes = Array(appEnvironment.routeRepository.routes.prefix(5))
        let durations = [25, 50, 90, 50, 100]

        for (index, route) in routes.enumerated() {
            let completedAt = baseDate.addingTimeInterval(TimeInterval(index * 7_200))
            let startedAt = completedAt.addingTimeInterval(TimeInterval(-durations[index] * 60))

            let session = FocusSession(
                routeID: route.id,
                routeThemeName: route.themeName,
                originCode: route.originCode,
                destinationCode: route.destinationCode,
                createdAt: startedAt,
                startedAt: startedAt,
                expectedEndAt: completedAt,
                completedAt: completedAt,
                plannedMinutes: durations[index],
                status: .completed,
                selectedAudioTrackID: route.audioTrackID,
                completionPercent: 1,
                elapsedFocusSeconds: durations[index] * 60,
                traveledDistanceKm: route.distanceKm,
                remainingDistanceKm: 0
            )

            modelContext.insert(session)
        }

        do {
            try appEnvironment.sessionRepository.saveChanges(in: modelContext)

            let seededSessions = try modelContext.fetch(
                FetchDescriptor<FocusSession>(
                    sortBy: [SortDescriptor(\.startedAt, order: .forward)]
                )
            )

            for session in seededSessions where session.status == .completed {
                _ = try appEnvironment.sessionRepository.stamp(for: session, in: modelContext)
            }
        } catch {
            assertionFailure("Failed to seed passport UI test data: \(error)")
        }
    }
}
