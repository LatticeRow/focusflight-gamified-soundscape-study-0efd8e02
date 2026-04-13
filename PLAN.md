# FocusFlight Implementation Handoff

## Product Summary
FocusFlight is a native iPhone productivity app that makes a focus block feel like a short flight. The user chooses a curated route, starts a timed session, listens to looping airplane cabin ambience, and watches progress move from origin to destination. Completed sessions create passport-style stamps and a few lightweight achievements.

This should be built as a local-first SwiftUI app with no account system and no remote backend. The first version should optimize for one polished, repeatable loop instead of broad gamification.

## MVP Scope
### In scope
- Curated local cabin-noise loops bundled with the app
- A route catalog with city-to-city flight themes
- A focus timer with preset durations such as 25, 50, and 90 minutes
- Flight progress UI that maps elapsed focus time to route progress
- Persisted completed sessions
- Passport stamps and a few milestone achievements
- Local notifications for session completion
- Correct restore behavior after app backgrounding or relaunch

### Out of scope for MVP
- User accounts, sync, cloud backup logic beyond normal iOS backup behavior
- Social sharing, leaderboards, streak economies, or competitive multiplayer
- Imported custom audio files
- Live maps, real airline data, or external APIs
- Complex Pomodoro cycle planners with automatic multi-leg work/break schedules

### Scope decision to keep implementation bounded
Treat one focus block as one flight. A 25-minute preset is a short-haul flight, a 50-minute preset is medium-haul, and a 90-minute preset is long-haul. Break suggestions can be shown after completion, but do not build a full multi-cycle Pomodoro state machine unless time remains.

## Core Product Flow
1. User opens the app and sees a home dashboard with a prominent “Start Flight” CTA.
2. User picks a route from a curated list, for example SFO -> JFK.
3. User picks a focus duration preset and optional cabin-noise track.
4. User starts the session.
5. The session screen shows:
- Remaining time
- Origin and destination labels
- A progress bar or route track visual
- Distance traveled and distance remaining
- Audio controls
- Pause / cancel actions
6. When the timer finishes, the app stops the session, records completion, and creates a passport stamp.
7. The user can review session history and achievements in the Passport tab.

## Technical Direction
### Platform and frameworks
- Swift 6-compatible project settings if available in the toolchain
- SwiftUI for all UI
- Observation (`@Observable`) or a small MVVM-style layer for state ownership
- SwiftData for persisted session and stamp records
- `AppStorage` / `UserDefaults` for simple preferences
- AVFoundation for local audio playback
- UserNotifications for local completion reminders

### No remote backend
Keep all business logic inside the app target. There should be no server, auth service, or hosted database for MVP. If the code ends up with a folder named `Backend`, it should mean in-process domain logic only, not a network service.

## iOS Sandbox and Platform Constraints
These constraints need to shape the implementation instead of being treated as edge cases.

- The app can only persist inside its own sandbox container. Use SwiftData and `UserDefaults` for storage.
- The app does not have arbitrary filesystem access. For MVP, ship bundled audio tracks and route seed JSON inside the app bundle.
- If custom audio import is ever added later, it must use `FileImporter` / `UIDocumentPicker` and security-scoped access. Do not build this now.
- iOS may suspend the app in the background. Do not trust an in-memory countdown timer to remain accurate.
- Timer correctness must come from persisted timestamps such as `startedAt`, `pausedAt`, and `expectedEndAt`.
- If continuous cabin-noise playback during lock/background is required, enable the audio background mode and configure `AVAudioSession` correctly. This is defensible because ambient playback is the main feature, but it still needs explicit entitlement/configuration.
- Do not rely on `BackgroundTasks` to keep a countdown running every second. That is not what it is for.
- Use local notifications to inform the user that a session completed while the app was backgrounded.

## Suggested Xcode Project Structure
Start with a single app target and a test target. Suggested layout:

```text
FocusFlight/
  App/
    FocusFlightApp.swift
    AppCoordinator.swift
    AppEnvironment.swift
  Features/
    Home/
      HomeView.swift
      HomeViewModel.swift
      RouteCardView.swift
    Session/
      FlightSessionView.swift
      FlightSessionViewModel.swift
      SessionControlsView.swift
      FlightProgressView.swift
    Routes/
      RoutePickerView.swift
      RouteRowView.swift
    Passport/
      PassportView.swift
      PassportStampCard.swift
      AchievementBadgeView.swift
    Settings/
      SettingsView.swift
  Domain/
    Models/
      FlightRoute.swift
      FocusSession.swift
      PassportStamp.swift
      AchievementDefinition.swift
      UserPreferences.swift
    Services/
      SessionEngine.swift
      AudioPlayerService.swift
      AchievementEngine.swift
      NotificationService.swift
      AppLifecycleCoordinator.swift
    Repositories/
      SessionRepository.swift
      RouteRepository.swift
  Data/
    Seed/
      routes.json
    Persistence/
      SwiftDataContainer.swift
      SeedDataLoader.swift
  UI/
    DesignSystem/
      FFColors.swift
      FFTypography.swift
      FFSpacing.swift
    Components/
      PrimaryButton.swift
      MetricPill.swift
      RouteHeader.swift
  Resources/
    Audio/
      cabin_steady_01.m4a
      cabin_rain_01.m4a
      cabin_night_01.m4a
  FocusFlightTests/
    SessionEngineTests.swift
    AchievementEngineTests.swift
    PersistenceTests.swift
```

Use these names as guidance, not absolute requirements, but keep the same separation of concerns.

## Architecture Overview
### App layer
The app layer owns startup, dependency wiring, navigation, and scene lifecycle events.

Suggested responsibilities:
- `FocusFlightApp.swift`: bootstraps SwiftData container and app environment
- `AppEnvironment.swift`: creates service singletons / shared objects used by SwiftUI
- `AppCoordinator.swift`: handles high-level navigation and active-session restoration

### Domain models
Keep models small and explicit.

Suggested model definitions:
- `FlightRoute`
  - `id`
  - `originCity`
  - `originCode`
  - `destinationCity`
  - `destinationCode`
  - `distanceKm`
  - `estimatedMinutes`
  - `themeName`
  - `audioTrackID`
- `FocusSession`
  - `id`
  - `routeID`
  - `startedAt`
  - `expectedEndAt`
  - `completedAt`
  - `plannedMinutes`
  - `status` (`planned`, `active`, `paused`, `completed`, `cancelled`)
  - `pausedAccumulatedSeconds`
  - `selectedAudioTrackID`
  - `completionPercent`
- `PassportStamp`
  - `id`
  - `sessionID`
  - `awardedAt`
  - `title`
  - `originCode`
  - `destinationCode`
  - `minutesFlown`
  - `badgeStyle`
- `AchievementDefinition`
  - static definitions for unlock rules such as first flight, five flights, 300 total minutes
- `UserPreferences`
  - stored mostly in `AppStorage`
  - default duration preset
  - selected track
  - notification preference
  - haptics enabled

### Service layer
This is the core of the app and should remain plain Swift where possible.

- `SessionEngine`
  - starts sessions from route + duration preset
  - computes remaining time from timestamps
  - computes normalized route progress
  - pauses/resumes/cancels/completes sessions
  - exposes derived values for UI
- `AudioPlayerService`
  - configures `AVAudioSession`
  - loads bundled audio files
  - starts/stops/loops playback
  - exposes current track and playback state
- `AchievementEngine`
  - converts completed sessions into passport stamps
  - computes aggregate unlocks from history
- `NotificationService`
  - requests permission
  - schedules completion notifications
  - cancels notifications on cancellation or early completion
- `AppLifecycleCoordinator`
  - listens for scene phase changes
  - triggers restoration when app returns to foreground
  - syncs active session and playback state

### Persistence
Use SwiftData for durable, queryable records.

Persist in SwiftData:
- Completed sessions
- In-progress active session state, if you choose to model it durably
- Passport stamps

Store in `AppStorage` / `UserDefaults`:
- Selected default duration
- Last selected audio track
- Notification preference
- Small UI preferences

### Seed data
Create a bundled `routes.json` with roughly 8 to 12 curated routes. Keep the first version small. Example routes:
- SFO -> JFK
- LAX -> HNL
- SEA -> ORD
- BOS -> MIA
- LHR-style international routes should be avoided if the MVP is meant to feel US-centric; use domestic routes first unless a global aesthetic is desired

The seed file only needs the metadata the app actually displays.

## UI and UX Guidance
The app should feel atmospheric and deliberate, not like a generic task timer.

### Home screen
Must answer three questions immediately:
- What is this app?
- How do I start a focus flight?
- What did I accomplish recently?

Suggested sections:
- Hero card with next focus CTA
- Suggested route card
- Last completed flight summary
- Passport progress snippet

### Route picker
Use cards or rows that show:
- City pair
- Airport codes
- Distance
- Recommended duration preset
- Optional mood or track association

### Active session screen
This is the most important screen in the app. It should show:
- Large remaining time
- A clear route progress indicator
- Origin and destination codes
- Distance traveled / remaining
- Audio track title and playback controls
- Pause and cancel controls

Do not bury controls in menus. This screen should be readable at a glance while the phone is on a desk.

### Passport screen
Keep it collectible but simple.
- A vertical list or grid of session stamps
- A compact milestone section for aggregate achievements
- A total minutes flown summary

### Settings screen
Only include what matters for MVP.
- Default focus duration
- Default audio track
- Notifications on/off
- Haptics on/off
- Optional “About FocusFlight” text

## Audio Implementation Notes
Use local bundled assets only. The easiest path is well-trimmed `.m4a` loop files paired with `AVAudioPlayer` configured for infinite looping. If audible gaps remain, upgrade to a slightly more advanced player setup, but do not start with unnecessary DSP complexity.

Implementation guidance:
- Keep a small audio catalog with stable IDs
- Preload assets enough to avoid lag at session start
- Tie selected audio track to the chosen route by default, but allow manual override in settings or before session start
- Stop playback when the session is cancelled or completed unless product direction explicitly wants post-flight ambience

## Data and Logic Notes
### Progress formula
Use a direct mapping:
- `elapsedSeconds = now - startedAt - pausedAccumulatedSeconds`
- `progress = clamp(elapsedSeconds / plannedDurationSeconds, 0...1)`
- `distanceTraveled = route.distanceKm * progress`
- `remainingDistance = route.distanceKm - distanceTraveled`

This keeps the experience consistent and easy to test.

### Session completion rules
A session counts as completed when `progress >= 1.0` or the current time passes `expectedEndAt` after pause adjustments. Completion should:
- persist the session
- create a passport stamp
- cancel any pending notification for that session
- optionally trigger haptic feedback

### Achievement rules
Keep these rules deterministic and data-driven. Suggested first set:
- First Flight: complete 1 session
- Frequent Flyer: complete 5 sessions
- Long Haul: accumulate 300 focused minutes
- Red Eye: complete a session after 9 PM local time

Do not build unlock animations that require complicated state management unless time remains.

## Implementation Phases
### Phase 1: Foundation
- Create Xcode project
- Add app shell, tabs/navigation, and design tokens
- Wire SwiftData container
- Add placeholder screens

### Phase 2: Models and seeded data
- Create SwiftData models and non-persisted route model
- Add `routes.json`
- Build `SeedDataLoader`
- Add preference storage

### Phase 3: Session engine
- Implement start/pause/resume/cancel/complete behavior
- Make restoration timestamp-based
- Expose derived session view state

### Phase 4: Audio and notifications
- Implement local loop playback
- Configure audio session
- Add local notification scheduling/cancelation
- Handle scene phase transitions

### Phase 5: Core UI
- Build Home, Route Picker, and Session screens
- Connect views to real services/data
- Confirm end-to-end start-session flow

### Phase 6: Passport and settings
- Build passport history UI
- Add milestone achievements
- Build settings UI

### Phase 7: Testing and polish
- Unit-test core logic
- Validate SwiftData round trips
- Run simulator and on-device QA
- Fix audio, lifecycle, and notification edge cases

## Testing Strategy
### Unit tests
Must-have unit coverage:
- `SessionEngineTests`
  - start session computes correct expected end time
  - pause/resume adjusts remaining time correctly
  - progress math is correct at 0%, 50%, and 100%
  - restoration after simulated background gap is correct
- `AchievementEngineTests`
  - single completion unlocks first-flight achievement
  - multiple sessions unlock milestone counts correctly
  - total focused minutes are summed correctly
- `PersistenceTests`
  - in-memory SwiftData container can save/fetch sessions and stamps

### UI testing
At least one smoke test if time allows:
- launch app
- select route
- start session
- verify session screen appears

### Manual device QA
Important because simulator is weak for audio/background behavior.
- Verify loop quality on an actual iPhone
- Lock the device during a session and check restore behavior
- Background the app and verify notification timing
- Confirm cancellation removes pending notification

## Acceptance Criteria
The MVP is complete when all of the following are true:
- The app builds and runs as a native iPhone SwiftUI app in Xcode
- A user can pick a route, choose a focus preset, and start a session
- A looping cabin-noise track plays during the session
- Flight progress advances correctly with elapsed focus time
- Completing a session persists history and generates a passport stamp
- Session history and achievements survive app relaunch
- Background/foreground transitions do not break timer correctness
- Local notifications work for session completion when permission is granted
- Core logic is covered by automated tests

## Risks and Mitigations
### Risk: trend-driven idea loses momentum
Mitigation: ship the smallest version that nails the sensory loop and completion reward.

### Risk: audio quality feels cheap
Mitigation: invest in a tiny set of high-quality loop assets instead of a large mediocre library.

### Risk: background behavior is buggy
Mitigation: keep timestamps as the source of truth and test on a physical device early.

### Risk: too much gamification too early
Mitigation: keep achievements shallow and readable; do not add currencies, avatars, or social layers in MVP.

## Suggested Initial File Checklist
A weaker implementation agent should create these files first:
- `App/FocusFlightApp.swift`
- `App/AppEnvironment.swift`
- `Domain/Models/FlightRoute.swift`
- `Domain/Models/FocusSession.swift`
- `Domain/Models/PassportStamp.swift`
- `Domain/Services/SessionEngine.swift`
- `Domain/Services/AudioPlayerService.swift`
- `Domain/Services/AchievementEngine.swift`
- `Domain/Services/NotificationService.swift`
- `Data/Seed/routes.json`
- `Data/Persistence/SeedDataLoader.swift`
- `Features/Home/HomeView.swift`
- `Features/Routes/RoutePickerView.swift`
- `Features/Session/FlightSessionView.swift`
- `Features/Passport/PassportView.swift`
- `Features/Settings/SettingsView.swift`
- `FocusFlightTests/SessionEngineTests.swift`
- `FocusFlightTests/AchievementEngineTests.swift`

## Execution and Handoff Notes
- Use a dedicated git branch from the start, for example `feat/focusflight-mvp`.
- The downstream implementation agent should work on a Mac with Xcode and simulator access.
- Build and run after each phase instead of waiting until the end.
- Do not add a backend unless a later product decision clearly requires one.
- If time pressure appears, cut extra achievements and UI flourishes before cutting timer correctness, audio reliability, or persistence.

## Definition of Done for the Downstream Agent
A downstream coding agent has succeeded if it leaves behind a clean Xcode project that another engineer can open, run, and extend without re-architecting. The app does not need every possible focus feature; it needs one cohesive local-first flight-session loop that works reliably on iPhone.