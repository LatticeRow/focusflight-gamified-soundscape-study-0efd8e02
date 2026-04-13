import SwiftUI

struct RouteHeader: View {
    let route: FlightRoute

    var body: some View {
        VStack(alignment: .leading, spacing: FFSpacing.xs) {
            Text(route.cityPair)
                .font(FFTypography.sectionTitle)
                .foregroundStyle(FFColors.textPrimary)
            HStack(spacing: FFSpacing.sm) {
                Text(route.originCode)
                    .font(FFTypography.code)
                Image(systemName: "arrow.right")
                    .foregroundStyle(FFColors.accent)
                Text(route.destinationCode)
                    .font(FFTypography.code)
            }
            .foregroundStyle(FFColors.textPrimary)
        }
    }
}
