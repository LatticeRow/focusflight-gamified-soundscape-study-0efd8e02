import SwiftData
import SwiftUI

struct HomeView: View {
    @Query(sort: \FocusSession.startedAt, order: .reverse) private var sessions: [FocusSession]

    let route: FlightRoute
    let activeSession: FocusSession?
    @Binding var durationMinutes: Int
    let audioTrackTitle: String
    let onChangeRoute: () -> Void
    let onStartFlight: () -> Void

    init(
        route: FlightRoute,
        activeSession: FocusSession?,
        durationMinutes: Binding<Int>,
        audioTrackTitle: String,
        onChangeRoute: @escaping () -> Void,
        onStartFlight: @escaping () -> Void
    ) {
        self.route = route
        self.activeSession = activeSession
        self._durationMinutes = durationMinutes
        self.audioTrackTitle = audioTrackTitle
        self.onChangeRoute = onChangeRoute
        self.onStartFlight = onStartFlight
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FFSpacing.lg) {
                heroCard
                nextFlightCard
                lastFlightCard
                totalsCard
            }
            .padding(.horizontal, FFSpacing.md)
            .padding(.vertical, FFSpacing.lg)
        }
        .background(FFColors.background.ignoresSafeArea())
        .navigationTitle(AppBrand.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: FFSpacing.lg) {
            HStack(alignment: .center, spacing: FFSpacing.md) {
                Image("LaunchBrand")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 54, height: 54)
                    .padding(12)
                    .background(FFColors.panelRaised.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(AppBrand.name)
                        .font(FFTypography.heroTitle)
                        .foregroundStyle(FFColors.textPrimary)

                    Text(activeSession == nil ? "Pick a route, set the time, and start." : "Your session is ready to resume.")
                        .font(FFTypography.body)
                        .foregroundStyle(FFColors.textSecondary)
                }
            }

            HStack(spacing: FFSpacing.sm) {
                MetricPill(label: "Route", value: route.codePair)
                MetricPill(label: "Time", value: "\(durationMinutes)m")
                MetricPill(label: "Sound", value: audioTrackTitle)
            }
        }
        .padding(FFSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FFColors.heroGradient)
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(FFColors.stroke, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var nextFlightCard: some View {
        VStack(alignment: .leading, spacing: FFSpacing.md) {
            Text(activeSession == nil ? "Next Flight" : "Current Flight")
                .font(FFTypography.sectionTitle)
                .foregroundStyle(FFColors.textPrimary)

            RouteCardView(route: route)

            VStack(alignment: .leading, spacing: FFSpacing.sm) {
                Text("Duration")
                    .font(FFTypography.detail)
                    .foregroundStyle(FFColors.textSecondary)

                Picker("Duration", selection: $durationMinutes) {
                    ForEach(UserPreferences.durationPresets, id: \.self) { preset in
                        Text("\(preset)m").tag(preset)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("home.durationPicker")
            }

            PrimaryButton(
                title: activeSession == nil ? "Start Flight" : "Resume Flight",
                systemImage: activeSession == nil ? "play.fill" : "arrow.clockwise.circle.fill",
                action: onStartFlight
            )
            .accessibilityIdentifier("home.startFlight")

            Button("Choose Route", action: onChangeRoute)
                .buttonStyle(.bordered)
                .tint(FFColors.accentSoft)
                .accessibilityIdentifier("home.changeRoute")
        }
    }

    @ViewBuilder
    private var lastFlightCard: some View {
        VStack(alignment: .leading, spacing: FFSpacing.sm) {
            Text("Last Flight")
                .font(FFTypography.sectionTitle)
                .foregroundStyle(FFColors.textPrimary)

            if let session = completedSessions.first {
                VStack(alignment: .leading, spacing: FFSpacing.sm) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.routeThemeName)
                                .font(.headline)
                                .foregroundStyle(FFColors.textPrimary)
                            Text("\(session.originCode) to \(session.destinationCode)")
                                .font(FFTypography.detail)
                                .foregroundStyle(FFColors.textSecondary)
                        }

                        Spacer()

                        Text("\(session.plannedMinutes)m")
                            .font(.headline)
                            .foregroundStyle(FFColors.accentSoft)
                    }

                    Text(session.completedAt?.formatted(date: .abbreviated, time: .shortened) ?? "Completed")
                        .font(FFTypography.detail)
                        .foregroundStyle(FFColors.textSecondary)
                }
                .padding(FFSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(FFColors.panel)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(FFColors.stroke, lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                Text("Your completed flights show up here.")
                    .font(FFTypography.body)
                    .foregroundStyle(FFColors.textSecondary)
                    .padding(FFSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(FFColors.panel)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
    }

    private var totalsCard: some View {
        HStack(spacing: FFSpacing.md) {
            MetricPill(label: "Flights", value: "\(completedSessions.count)")
            MetricPill(label: "Minutes", value: "\(totalMinutes)")
        }
    }

    private var completedSessions: [FocusSession] {
        sessions.filter { $0.status == .completed }
    }

    private var totalMinutes: Int {
        completedSessions.reduce(0) { $0 + $1.plannedMinutes }
    }
}
