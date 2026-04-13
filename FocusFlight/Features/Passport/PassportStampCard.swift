import SwiftUI

struct PassportStampCard: View {
    let stamp: PassportStamp

    var body: some View {
        HStack(alignment: .center, spacing: FFSpacing.md) {
            VStack(alignment: .leading, spacing: 6) {
                Text(stamp.title)
                    .font(.headline)
                    .foregroundStyle(FFColors.textPrimary)
                Text("\(stamp.originCode) to \(stamp.destinationCode)")
                    .font(FFTypography.detail)
                    .foregroundStyle(FFColors.textSecondary)
            }

            Spacer()

            Text("\(stamp.minutesFlown)m")
                .font(.headline)
                .foregroundStyle(FFColors.accentSoft)
        }
        .padding(FFSpacing.md)
        .background(FFColors.panel)
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(FFColors.stroke, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
