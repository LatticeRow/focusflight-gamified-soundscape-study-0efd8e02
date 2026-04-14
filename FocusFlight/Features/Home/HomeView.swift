import SwiftData
import SwiftUI

struct HomeView: View {
    @Query(sort: \PassportStamp.awardedAt, order: .reverse) private var stamps: [PassportStamp]

    let route: FlightRoute
    @Binding var durationMinutes: Int
    let audioTrackTitle: String
    let onChangeRoute: () -> Void
    let onStartFlight: () -> Void

    init(
        route: FlightRoute,
        durationMinutes: Binding<Int>,
        audioTrackTitle: String,
        onChangeRoute: @escaping () -> Void,
        onStartFlight: @escaping () -> Void
    ) {
        self.route = route
        self._durationMinutes = durationMinutes
        self.audioTrackTitle = audioTrackTitle
        self.onChangeRoute = onChangeRoute
        self.onStartFlight = onStartFlight
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FFSpacing.lg) {
                heroCard
                RouteCardView(route: route)

                VStack(alignment: .leading, spacing: FFSpacing.md) {
                    Text("Duration")
                        .font(FFTypography.sectionTitle)
                        .foregroundStyle(FFColors.textPrimary)

                    Picker("Duration", selection: $durationMinutes) {
                        ForEach(UserPreferences.durationPresets, id: \.self) { preset in
                            Text("\(preset)m").tag(preset)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("home.durationPicker")
                }

                HStack(spacing: FFSpacing.md) {
                    Button("Change Route", action: onChangeRoute)
                        .buttonStyle(.bordered)
                        .tint(FFColors.accentSoft)
                        .accessibilityIdentifier("home.changeRoute")

                    PrimaryButton(title: "Start Flight", systemImage: "play.fill", action: onStartFlight)
                        .accessibilityIdentifier("home.startFlight")
                }

                lastFlightCard
            }
            .padding(.horizontal, FFSpacing.md)
            .padding(.vertical, FFSpacing.lg)
        }
        .background(FFColors.background.ignoresSafeArea())
        .navigationTitle(AppBrand.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: FFSpacing.md) {
            Text("Choose a route and start.")
                .font(FFTypography.heroTitle)
                .foregroundStyle(FFColors.textPrimary)

            Text("Stay with the timer until you land.")
                .font(FFTypography.body)
                .foregroundStyle(FFColors.textSecondary)

            HStack(spacing: FFSpacing.sm) {
                MetricPill(label: "Route", value: route.codePair)
                MetricPill(label: "Preset", value: "\(durationMinutes)m")
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

    @ViewBuilder
    private var lastFlightCard: some View {
        VStack(alignment: .leading, spacing: FFSpacing.sm) {
            Text("Recent")
                .font(FFTypography.sectionTitle)
                .foregroundStyle(FFColors.textPrimary)

            if let latestStamp = stamps.first {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(latestStamp.title)
                            .font(.headline)
                            .foregroundStyle(FFColors.textPrimary)
                        Text("\(latestStamp.originCode) to \(latestStamp.destinationCode)")
                            .font(FFTypography.detail)
                            .foregroundStyle(FFColors.textSecondary)
                    }

                    Spacer()

                    Text("\(latestStamp.minutesFlown)m")
                        .font(.headline)
                        .foregroundStyle(FFColors.accentSoft)
                }
                .padding(FFSpacing.md)
                .background(FFColors.panel)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                Text("Completed sessions appear here.")
                    .font(FFTypography.body)
                    .foregroundStyle(FFColors.textSecondary)
                    .padding(FFSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(FFColors.panel)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
    }
}
