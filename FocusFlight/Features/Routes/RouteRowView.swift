import SwiftUI

struct RouteRowView: View {
    let route: FlightRoute
    let isSelected: Bool

    var body: some View {
        HStack(spacing: FFSpacing.md) {
            VStack(alignment: .leading, spacing: 6) {
                Text(route.cityPair)
                    .font(.headline)
                    .foregroundStyle(FFColors.textPrimary)
                Text(route.codePair)
                    .font(FFTypography.detail)
                    .foregroundStyle(FFColors.textSecondary)
                Text("\(route.distanceKm) km  •  \(route.estimatedMinutes)m")
                    .font(FFTypography.detail)
                    .foregroundStyle(FFColors.textSecondary)
            }

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? FFColors.accent : FFColors.textSecondary)
        }
        .padding(.vertical, FFSpacing.xs)
        .accessibilityIdentifier("route.\(route.id)")
    }
}
