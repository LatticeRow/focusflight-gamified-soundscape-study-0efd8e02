import SwiftUI

struct AchievementBadgeView: View {
    let achievement: AchievementDefinition
    let isUnlocked: Bool

    var body: some View {
        HStack(spacing: FFSpacing.md) {
            Image(systemName: achievement.symbolName)
                .font(.title2)
                .foregroundStyle(isUnlocked ? FFColors.accent : FFColors.textSecondary)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.headline)
                    .foregroundStyle(FFColors.textPrimary)
                Text(achievement.detail)
                    .font(FFTypography.detail)
                    .foregroundStyle(FFColors.textSecondary)
            }

            Spacer()

            Text(isUnlocked ? "Ready" : "Locked")
                .font(FFTypography.detail)
                .foregroundStyle(isUnlocked ? FFColors.accentSoft : FFColors.textSecondary)
        }
        .padding(FFSpacing.md)
        .background(FFColors.panel)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
