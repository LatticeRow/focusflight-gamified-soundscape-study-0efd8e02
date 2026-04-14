# Aureline Release Readiness

## Assets
- App icon asset set is present in `FocusFlight/Resources/Assets.xcassets/AppIcon.appiconset`.
- Launch screen uses the branded `LaunchBrand` image and `LaunchBackground` color asset.
- In-app branding uses the Aureline mark and name consistently across Home, Session, Passport, and Settings.

## Privacy Labels
- Expected App Store privacy label: `Data Not Collected`.
- Current implementation is local-first and does not include analytics, account sign-in, ads, tracking, or network upload paths.
- User-facing permissions/capabilities in MVP:
  - Local notifications for session completion.
  - Background audio playback during an active focus session.

## Capabilities And Entitlements
- `UIBackgroundModes` includes `audio` in [Info.plist](/Users/atkinsonfam/AppDevProjects/focusflight-gamified-soundscape-study-0efd8e02/FocusFlight/Resources/Info.plist:1).
- Code signing remains automatic and enabled in `Aureline.xcodeproj`.
- No microphone, camera, photo library, contacts, location, or tracking usage keys are present.

## QA Status
- Simulator build/test command passed:
  - `xcodebuild test -project Aureline.xcodeproj -scheme Aureline -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4'`
- Automated simulator QA covered:
  - Home route selection and session start
  - Session pause, resume, cancel, completion, and audio controls
  - Passport stamps and milestones
  - Settings duration, sound, volume, notifications, and haptics controls
- Audio playback path was updated to `AVQueuePlayer` + `AVPlayerLooper` to reduce the chance of audible seams versus simple `AVAudioPlayer` repeat looping.

## Remaining Blocker
- Physical iPhone QA could not be completed from this worker because device enumeration was unavailable.
- Attempted commands:
  - `xcrun devicectl list devices`
  - `xcrun xcdevice list`
- Result:
  - CoreDevice/CoreSimulator service access was unavailable in this environment, so on-device lock-screen, background, and audible loop confirmation still need one manual pass on a connected iPhone before App Store submission.
