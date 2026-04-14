import SwiftUI

struct RoutePickerView: View {
    let routes: [FlightRoute]
    let selectedRouteID: String?
    let onSelect: (FlightRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FFSpacing.lg) {
                VStack(alignment: .leading, spacing: FFSpacing.sm) {
                    Text("Choose Route")
                        .font(FFTypography.heroTitle)
                        .foregroundStyle(FFColors.textPrimary)

                    Text("Pick one of the curated flights below.")
                        .font(FFTypography.body)
                        .foregroundStyle(FFColors.textSecondary)
                }

                LazyVStack(spacing: FFSpacing.md) {
                    ForEach(routes) { route in
                        Button {
                            onSelect(route)
                        } label: {
                            RouteRowView(route: route, isSelected: route.id == selectedRouteID)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("route.\(route.id)")
                    }
                }
            }
            .padding(.horizontal, FFSpacing.md)
            .padding(.vertical, FFSpacing.lg)
        }
        .background(FFColors.background)
        .navigationTitle("Choose Route")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Close") {
                    dismiss()
                }
            }
        }
    }
}
