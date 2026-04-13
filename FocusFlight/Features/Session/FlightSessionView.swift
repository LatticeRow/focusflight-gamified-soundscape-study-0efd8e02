import SwiftUI

struct FlightSessionView: View {
    let sessionDraft: AppRouter.SessionDraft
    @ObservedObject var preferences: UserPreferences
    let sessionEngine: SessionEngine
    let audioPlayerService: AudioPlayerService
    let notificationService: NotificationService
    let onClose: () -> Void

    @State private var startedAt = Date()
    @State private var pausedAt: Date?
    @State private var pausedAccumulatedSeconds: TimeInterval = 0

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let now = pausedAt ?? context.date
                let snapshot = sessionEngine.snapshot(
                    now: now,
                    startedAt: startedAt,
                    plannedMinutes: sessionDraft.plannedMinutes,
                    routeDistanceKm: sessionDraft.route.distanceKm,
                    pausedAccumulatedSeconds: pausedAccumulatedSeconds
                )

                ScrollView {
                    VStack(alignment: .leading, spacing: FFSpacing.lg) {
                        RouteHeader(route: sessionDraft.route)

                        VStack(alignment: .leading, spacing: FFSpacing.md) {
                            Text(format(seconds: snapshot.remainingSeconds))
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .foregroundStyle(FFColors.textPrimary)
                                .monospacedDigit()

                            ProgressView(value: snapshot.progress)
                                .tint(FFColors.accent)
                                .scaleEffect(x: 1, y: 2.5, anchor: .center)

                            HStack(spacing: FFSpacing.md) {
                                MetricPill(label: "Flown", value: "\(snapshot.distanceTraveledKm) km")
                                MetricPill(label: "Remaining", value: "\(snapshot.distanceRemainingKm) km")
                            }
                        }
                        .padding(FFSpacing.lg)
                        .background(FFColors.panel)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                        Text("Cabin sound follows your default track.")
                            .font(FFTypography.body)
                            .foregroundStyle(FFColors.textSecondary)

                        HStack(spacing: FFSpacing.md) {
                            Button(pausedAt == nil ? "Pause Flight" : "Resume Flight") {
                                togglePause()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(FFColors.panelRaised)
                            .foregroundStyle(FFColors.textPrimary)
                            .accessibilityIdentifier("session.pauseResume")

                            Button("End Flight") {
                                onClose()
                            }
                            .buttonStyle(.bordered)
                            .tint(FFColors.accentSoft)
                            .accessibilityIdentifier("session.end")
                        }
                    }
                    .padding(.horizontal, FFSpacing.md)
                    .padding(.vertical, FFSpacing.lg)
                }
                .background(FFColors.background.ignoresSafeArea())
            }
            .navigationTitle("In Flight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close", action: onClose)
                }
            }
        }
        .onAppear {
            startedAt = Date()
            audioPlayerService.preload(trackID: sessionDraft.route.audioTrackID)
            if preferences.notificationsEnabled {
                notificationService.requestAuthorizationIfNeeded()
            }
        }
    }

    private func togglePause() {
        let now = Date()
        if let pausedAt {
            pausedAccumulatedSeconds += now.timeIntervalSince(pausedAt)
            self.pausedAt = nil
        } else {
            pausedAt = now
        }
    }

    private func format(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}
