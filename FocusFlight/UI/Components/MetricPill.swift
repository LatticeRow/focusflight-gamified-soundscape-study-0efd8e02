import SwiftUI

struct MetricPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(FFTypography.detail)
                .foregroundStyle(FFColors.textSecondary)
            Text(value)
                .font(.headline)
                .foregroundStyle(FFColors.textPrimary)
        }
        .padding(.horizontal, FFSpacing.md)
        .padding(.vertical, FFSpacing.sm)
        .background(FFColors.panelRaised)
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(FFColors.stroke, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
