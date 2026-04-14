import SwiftUI

struct PassportStampCard: View {
    let stamp: PassportStamp

    var body: some View {
        VStack(alignment: .leading, spacing: FFSpacing.md) {
            HStack(alignment: .top, spacing: FFSpacing.md) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(stamp.title)
                        .font(FFTypography.cardTitle)
                        .foregroundStyle(FFColors.textPrimary)

                    Text("\(stamp.originCode) to \(stamp.destinationCode)")
                        .font(FFTypography.detail)
                        .foregroundStyle(FFColors.textSecondary)
                }

                Spacer()

                Text("\(stamp.minutesFlown)m")
                    .font(FFTypography.cardTitle)
                    .foregroundStyle(FFColors.accentSoft)
            }

            HStack {
                Text(stamp.awardedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(FFTypography.detail)
                    .foregroundStyle(FFColors.textSecondary)

                Spacer()

                Text("Stamped")
                    .font(FFTypography.detail)
                    .foregroundStyle(FFColors.accent)
                    .padding(.horizontal, FFSpacing.sm)
                    .padding(.vertical, 6)
                    .background(FFColors.panelRaised.opacity(0.85))
                    .clipShape(Capsule())
            }
        }
        .padding(FFSpacing.md)
        .ffCardSurface(cornerRadius: 20)
    }
}
