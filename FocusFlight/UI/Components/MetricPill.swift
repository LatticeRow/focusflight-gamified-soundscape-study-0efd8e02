import SwiftUI

struct MetricPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(FFTypography.micro)
                .foregroundStyle(FFColors.textTertiary)
            Text(value)
                .font(FFTypography.cardTitle)
                .foregroundStyle(FFColors.textPrimary)
        }
        .padding(.horizontal, FFSpacing.md)
        .padding(.vertical, FFSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FFColors.panelElevatedGradient)
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(FFColors.accent.opacity(0.18))
                .frame(width: 26, height: 26)
                .blur(radius: 8)
                .offset(x: 4, y: -4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(FFColors.stroke, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
