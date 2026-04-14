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
        let completedSessions = sessions.filter { $0.status == .completed }
        let totalMinutes = completedSessions.reduce(0) { $0 + $1.plannedMinutes }
        let achievementProgress = achievementEngine.achievementProgress(for: completedSessions)
        let unlockedCount = achievementProgress.filter(\.isUnlocked).count

        ScrollView {
            VStack(alignment: .leading, spacing: FFSpacing.lg) {
                summaryCard(
                    completedSessions: completedSessions,
                    totalMinutes: totalMinutes,
                    unlockedCount: unlockedCount
                )

                Picker("Passport section", selection: $selectedSection) {
                    ForEach(Section.allCases) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("passport.sectionPicker")

                if selectedSection == .stamps {
                    stampsSection(completedSessions: completedSessions)
                } else {
                    milestonesSection(achievementProgress: achievementProgress)
                }
            }
            .padding(.horizontal, FFSpacing.md)
            .padding(.vertical, FFSpacing.lg)
        }
        .background(FFColors.background.ignoresSafeArea())
        .navigationTitle("Passport")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func summaryCard(
        completedSessions: [FocusSession],
        totalMinutes: Int,
        unlockedCount: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: FFSpacing.md) {
            Text("Flight Log")
                .font(FFTypography.sectionTitle)
                .foregroundStyle(FFColors.textPrimary)

            Text(summaryLine(completedSessions: completedSessions, unlockedCount: unlockedCount))
                .font(FFTypography.body)
                .foregroundStyle(FFColors.textSecondary)

            HStack(spacing: FFSpacing.md) {
                MetricPill(label: "Flights", value: "\(completedSessions.count)")
                MetricPill(label: "Minutes", value: "\(totalMinutes)")
                MetricPill(label: "Milestones", value: "\(unlockedCount)")
            }
        }
        .padding(FFSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FFColors.heroGradient)
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(FFColors.stroke, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityIdentifier("passport.summary")
    }

    @ViewBuilder
    private func stampsSection(completedSessions: [FocusSession]) -> some View {
        VStack(alignment: .leading, spacing: FFSpacing.md) {
            sectionHeader(title: "Stamps", subtitle: "Each finished flight earns one stamp.")

            if stamps.isEmpty {
                emptyCard(message: "Finish a flight to add your first stamp.")
            } else {
                LazyVStack(spacing: FFSpacing.md) {
                    ForEach(stamps) { stamp in
                        PassportStampCard(stamp: stamp)
                    }
                }
                .accessibilityIdentifier("passport.stampsList")
            }
        }

        VStack(alignment: .leading, spacing: FFSpacing.md) {
            sectionHeader(title: "Recent Flights", subtitle: "Your latest finished sessions.")

            if completedSessions.isEmpty {
                emptyCard(message: "Finished flights appear here.")
            } else {
                LazyVStack(spacing: FFSpacing.md) {
                    ForEach(completedSessions.prefix(6)) { session in
                        sessionRow(for: session)
                    }
                }
                .accessibilityIdentifier("passport.historyList")
            }
        }
    }

    private func milestonesSection(
        achievementProgress: [AchievementEngine.AchievementProgress]
    ) -> some View {
        VStack(alignment: .leading, spacing: FFSpacing.md) {
            sectionHeader(title: "Milestones", subtitle: "Simple unlocks from your saved flights.")

            LazyVStack(spacing: FFSpacing.md) {
                ForEach(achievementProgress) { progress in
                    AchievementBadgeView(progress: progress)
                }
            }
            .accessibilityIdentifier("passport.achievementsList")
        }
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(FFTypography.sectionTitle)
                .foregroundStyle(FFColors.textPrimary)

            Text(subtitle)
                .font(FFTypography.detail)
                .foregroundStyle(FFColors.textSecondary)
        }
    }

    private func emptyCard(message: String) -> some View {
        Text(message)
            .font(FFTypography.body)
            .foregroundStyle(FFColors.textSecondary)
            .padding(FFSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FFColors.panel)
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(FFColors.stroke, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func sessionRow(for session: FocusSession) -> some View {
        HStack(alignment: .center, spacing: FFSpacing.md) {
            VStack(alignment: .leading, spacing: 6) {
                Text(session.routeThemeName)
                    .font(.headline)
                    .foregroundStyle(FFColors.textPrimary)

                Text("\(session.originCode) to \(session.destinationCode)")
                    .font(FFTypography.detail)
                    .foregroundStyle(FFColors.textSecondary)

                if let completedAt = session.completedAt {
                    Text(completedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(FFTypography.detail)
                        .foregroundStyle(FFColors.textSecondary)
                }
            }

            Spacer()

            Text("\(session.plannedMinutes)m")
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

    private func summaryLine(completedSessions: [FocusSession], unlockedCount: Int) -> String {
        guard let lastFlight = completedSessions.first else {
            return "No flights logged yet."
        }

        let route = "\(lastFlight.originCode) to \(lastFlight.destinationCode)"
        return "\(completedSessions.count) flights logged. Last flight: \(route). \(unlockedCount) milestones unlocked."
    }
}
