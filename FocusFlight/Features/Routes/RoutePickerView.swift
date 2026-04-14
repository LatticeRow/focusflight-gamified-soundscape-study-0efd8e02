import SwiftUI

struct RoutePickerView: View {
    let routes: [FlightRoute]
    let selectedRouteID: String?
    let onSelect: (FlightRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List(routes) { route in
            Button {
                onSelect(route)
            } label: {
                RouteRowView(route: route, isSelected: route.id == selectedRouteID)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("route.\(route.id)")
            .listRowBackground(FFColors.background)
        }
        .scrollContentBackground(.hidden)
        .background(FFColors.background)
        .navigationTitle("Choose Route")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Close") {
                    dismiss()
                }
            }
        }
    }
}
