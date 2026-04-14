import SwiftUI

struct RouteCardView: View {
    let route: FlightRoute

    var body: some View {
        VStack(alignment: .leading, spacing: FFSpacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: FFSpacing.sm) {
                    Text(route.themeName)
                        .font(FFTypography.eyebrow)
                        .foregroundStyle(FFColors.accentSoft)
                        .padding(.horizontal, FFSpacing.sm)
                        .padding(.vertical, 6)
                        .background(FFColors.panelRaised.opacity(0.85))
                        .clipShape(Capsule())

                    RouteHeader(route: route)
                }
                Spacer()
            }

            HStack(spacing: FFSpacing.md) {
                MetricPill(label: "Distance", value: "\(route.distanceKm) km")
                MetricPill(label: "Best For", value: "\(route.estimatedMinutes)m")
                MetricPill(label: "Sound", value: route.recommendedTrack.title)
            }
        }
        .padding(FFSpacing.lg)
        .ffCardSurface()
    }
}
