import SwiftUI

enum FFColors {
    static let background = Color(red: 0.03, green: 0.05, blue: 0.09)
    static let panel = Color(red: 0.08, green: 0.11, blue: 0.18)
    static let panelRaised = Color(red: 0.12, green: 0.16, blue: 0.24)
    static let accent = Color(red: 0.86, green: 0.72, blue: 0.43)
    static let accentSoft = Color(red: 0.94, green: 0.87, blue: 0.69)
    static let textPrimary = Color(red: 0.96, green: 0.94, blue: 0.89)
    static let textSecondary = Color(red: 0.73, green: 0.75, blue: 0.80)
    static let stroke = Color.white.opacity(0.08)
    static let heroGradient = LinearGradient(
        colors: [
            Color(red: 0.16, green: 0.20, blue: 0.30),
            Color(red: 0.06, green: 0.09, blue: 0.16),
            Color(red: 0.03, green: 0.05, blue: 0.09),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
