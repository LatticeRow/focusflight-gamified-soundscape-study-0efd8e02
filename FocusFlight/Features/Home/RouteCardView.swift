import SwiftUI

struct RouteCardView: View {
    let route: FlightRoute

    var body: some View {
        VStack(alignment: .leading, spacing: FFSpacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: FFSpacing.sm) {
                    Text(route.themeName)
                        .font(FFTypography.detail)
                        .foregroundStyle(FFColors.accentSoft)
                        .padding(.horizontal, FFSpacing.sm)
                        .padding(.vertical, 6)
                        .background(FFColors.panelRaised)
                        .clipShape(Capsule())

                    RouteHeader(route: route)
                }
                Spacer()
            }

            HStack(spacing: FFSpacing.md) {
                MetricPill(label: "Distance", value: "\(route.distanceKm) km")
                MetricPill(label: "Match", value: "\(route.estimatedMinutes)m")
                MetricPill(label: "Sound", value: route.recommendedTrack.title)
            }
        }
        .padding(FFSpacing.lg)
        .background(FFColors.panel)
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(FFColors.stroke, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
