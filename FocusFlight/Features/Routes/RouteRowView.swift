import SwiftUI

struct RouteRowView: View {
    let route: FlightRoute
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: FFSpacing.md) {
            HStack(alignment: .top, spacing: FFSpacing.md) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(route.themeName)
                        .font(FFTypography.detail)
                        .foregroundStyle(FFColors.accentSoft)

                    Text(route.cityPair)
                        .font(.headline)
                        .foregroundStyle(FFColors.textPrimary)

                    Text(route.codePair)
                        .font(FFTypography.detail)
                        .foregroundStyle(FFColors.textSecondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? FFColors.accent : FFColors.textSecondary)
            }

            HStack(spacing: FFSpacing.md) {
                MetricPill(label: "Distance", value: "\(route.distanceKm) km")
                MetricPill(label: "Match", value: "\(route.estimatedMinutes)m")
                MetricPill(label: "Sound", value: route.recommendedTrack.title)
            }
        }
        .padding(FFSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FFColors.panel)
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isSelected ? FFColors.accent.opacity(0.9) : FFColors.stroke, lineWidth: isSelected ? 1.5 : 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityIdentifier("route.\(route.id)")
    }
}
