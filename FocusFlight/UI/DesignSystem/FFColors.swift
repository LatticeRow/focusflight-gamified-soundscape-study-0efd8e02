import SwiftUI

enum FFColors {
    static let background = Color(red: 0.03, green: 0.05, blue: 0.09)
    static let panel = Color(red: 0.08, green: 0.11, blue: 0.18)
    static let panelRaised = Color(red: 0.12, green: 0.16, blue: 0.24)
    static let accent = Color(red: 0.86, green: 0.72, blue: 0.43)
    static let accentMuted = Color(red: 0.52, green: 0.42, blue: 0.24)
    static let accentSoft = Color(red: 0.94, green: 0.87, blue: 0.69)
    static let textPrimary = Color(red: 0.96, green: 0.94, blue: 0.89)
    static let textSecondary = Color(red: 0.73, green: 0.75, blue: 0.80)
    static let textTertiary = Color(red: 0.56, green: 0.60, blue: 0.68)
    static let stroke = Color.white.opacity(0.08)
    static let shadow = Color.black.opacity(0.34)
    static let success = Color(red: 0.54, green: 0.80, blue: 0.66)
    static let heroGradient = LinearGradient(
        colors: [
            Color(red: 0.16, green: 0.20, blue: 0.30),
            Color(red: 0.06, green: 0.09, blue: 0.16),
            Color(red: 0.03, green: 0.05, blue: 0.09),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.02, green: 0.03, blue: 0.06),
            Color(red: 0.03, green: 0.05, blue: 0.09),
            Color(red: 0.05, green: 0.08, blue: 0.13),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let panelGradient = LinearGradient(
        colors: [
            Color(red: 0.12, green: 0.15, blue: 0.24),
            Color(red: 0.08, green: 0.11, blue: 0.18),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let panelElevatedGradient = LinearGradient(
        colors: [
            Color(red: 0.16, green: 0.20, blue: 0.29),
            Color(red: 0.11, green: 0.14, blue: 0.23),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct FFScreenBackground: View {
    var body: some View {
        ZStack {
            FFColors.backgroundGradient

            Circle()
                .fill(FFColors.accent.opacity(0.16))
                .frame(width: 280, height: 280)
                .blur(radius: 72)
                .offset(x: 140, y: -240)

            Circle()
                .fill(FFColors.accentSoft.opacity(0.09))
                .frame(width: 220, height: 220)
                .blur(radius: 96)
                .offset(x: -140, y: 260)
        }
        .ignoresSafeArea()
    }
}

private struct FFCardSurfaceModifier: ViewModifier {
    let cornerRadius: CGFloat
    let elevated: Bool

    func body(content: Content) -> some View {
        content
            .background(elevated ? FFColors.panelElevatedGradient : FFColors.panelGradient)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(FFColors.stroke, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: FFColors.shadow, radius: elevated ? 24 : 18, y: 10)
    }
}

extension View {
    func ffCardSurface(cornerRadius: CGFloat = 24, elevated: Bool = false) -> some View {
        modifier(FFCardSurfaceModifier(cornerRadius: cornerRadius, elevated: elevated))
    }
}
