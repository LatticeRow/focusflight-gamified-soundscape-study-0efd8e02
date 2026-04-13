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
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FFSpacing.md)
            .foregroundStyle(Color.black.opacity(0.82))
            .background(fillColor)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
