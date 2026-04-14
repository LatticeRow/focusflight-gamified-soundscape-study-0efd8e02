import SwiftUI

struct AchievementBadgeView: View {
    let progress: AchievementEngine.AchievementProgress

    var body: some View {
        HStack(spacing: FFSpacing.md) {
            Image(systemName: progress.definition.symbolName)
                .font(.title2)
                .foregroundStyle(progress.isUnlocked ? FFColors.accent : FFColors.textSecondary)
                .frame(width: 42, height: 42)
                .background(FFColors.panelRaised.opacity(0.72))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(progress.definition.title)
                    .font(FFTypography.cardTitle)
                    .foregroundStyle(FFColors.textPrimary)

                Text(progress.definition.detail)
                    .font(FFTypography.detail)
                    .foregroundStyle(FFColors.textSecondary)

                if let unlockedAt = progress.unlockedAt {
                    Text(unlockedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(FFTypography.detail)
                        .foregroundStyle(FFColors.accentSoft)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(progress.isUnlocked ? "Unlocked" : progress.progressLabel)
                    .font(FFTypography.detail)
                    .foregroundStyle(progress.isUnlocked ? FFColors.accentSoft : FFColors.textSecondary)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(FFColors.panelRaised)

                        Capsule()
                            .fill(progress.isUnlocked ? FFColors.accent : FFColors.accentSoft.opacity(0.65))
                            .frame(
                                width: progress.progressValue == 0
                                    ? 0
                                    : max(20, geometry.size.width * progress.progressValue)
                            )
                    }
                }
                .frame(width: 76, height: 8)
            }
        }
        .padding(FFSpacing.md)
        .ffCardSurface(cornerRadius: 20)
    }
}
