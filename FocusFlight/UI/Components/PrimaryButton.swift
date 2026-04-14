import SwiftUI

struct PrimaryButton: View {
    let title: String
    let systemImage: String
    var fillColor: Color = FFColors.accent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: FFSpacing.sm) {
                Image(systemName: systemImage)
                Text(title)
                    .font(FFTypography.cardTitle)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FFSpacing.md)
            .foregroundStyle(Color.black.opacity(0.82))
            .background(
                LinearGradient(
                    colors: [fillColor, FFColors.accentSoft],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: FFColors.accent.opacity(0.22), radius: 16, y: 8)
        }
        .buttonStyle(.plain)
    }
}
