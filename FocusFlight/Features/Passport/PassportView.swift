import SwiftData
import SwiftUI

struct PassportView: View {
    enum Section: String, CaseIterable, Identifiable {
        case stamps = "Stamps"
        case milestones = "Milestones"

        var id: String { rawValue }
    }

    let achievementEngine: AchievementEngine
    @Query(sort: \PassportStamp.awardedAt, order: .reverse) private var stamps: [PassportStamp]
    @Query(sort: \FocusSession.startedAt, order: .reverse) private var sessions: [FocusSession]
    @State private var selectedSection: Section = .stamps

    init(achievementEngine: AchievementEngine) {
        self.achievementEngine = achievementEngine
    }

    var body: some View {
        let totalMinutes = sessions.reduce(0) { $0 + $1.plannedMinutes }
        let latestCompletion = sessions.compactMap(\.completedAt).max()
        let unlocked = achievementEngine.unlockedAchievements(
            sessionCount: sessions.count,
            totalMinutes: totalMinutes,
            latestCompletion: latestCompletion
        )

        ScrollView {
            VStack(alignment: .leading, spacing: FFSpacing.lg) {
                HStack(spacing: FFSpacing.md) {
                    MetricPill(label: "Flights", value: "\(sessions.count)")
                    MetricPill(label: "Minutes", value: "\(totalMinutes)")
                }

                Picker("Passport section", selection: $selectedSection) {
                    ForEach(Section.allCases) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("passport.sectionPicker")

                if selectedSection == .stamps {
                    if stamps.isEmpty {
                        Text("Your stamps will appear after your first flight.")
                            .font(FFTypography.body)
                            .foregroundStyle(FFColors.textSecondary)
                            .padding(FFSpacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(FFColors.panel)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    } else {
                        LazyVStack(spacing: FFSpacing.md) {
                            ForEach(stamps) { stamp in
                                PassportStampCard(stamp: stamp)
                            }
                        }
                    }
                } else {
                    LazyVStack(spacing: FFSpacing.md) {
                        ForEach(AchievementDefinition.catalog) { achievement in
                            AchievementBadgeView(
                                achievement: achievement,
                                isUnlocked: unlocked.contains(achievement.id)
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, FFSpacing.md)
            .padding(.vertical, FFSpacing.lg)
        }
        .background(FFColors.background.ignoresSafeArea())
        .navigationTitle("Passport")
        .navigationBarTitleDisplayMode(.inline)
    }
}
