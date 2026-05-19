# MirrorCam Development Session Memory

## Session Summary

Built MirrorCam from scratch using `/pipeline` skill (feature route). All 6 phases:
GRILL → PRD → ISSUES → TRIAGE(skipped) → TDD → REVIEW(not yet done).

User language: Korean. Responds in Korean with English technical terms.

## Phase 1 — GRILL (Requirements Interview)

13 questions resolved:

1. Framework: Swift (AppKit + AVFoundation), NOT SwiftUI
2. App type: Menu bar app (LSUIElement, no Dock icon)
3. Window shapes: Both circle and rounded rectangle (default: circle)
4. Default size: 200x200px, resize range 100-600px via scroll wheel
5. Hotkey: ⌥⌘G (Option+Cmd+G) to toggle mirror
6. Always on top: Yes (floating NSPanel)
7. Mirror flip: Default on, toggleable via menu
8. Distribution: Mac App Store
9. Price: Free (portfolio piece)
10. Min OS: macOS 12 (was 14, downgraded due to Xcode 13.4 constraint)
11. Settings: All persisted via UserDefaults
12. MVP features: Drag move, launch at login, brightness/zoom controls
13. App name: MirrorCam

## Phase 2 — PRD

Written to `README.md` (not `docs/PRD.md` — a pre-tool hook blocked .md files that aren't README/CLAUDE).
Contains 17 user stories, 7 modules, 5 tested modules.

## Phase 3 — ISSUES

10 vertical slice issues in `issues/` directory:
- 01: Tracer bullet (project + camera + window)
- 02: Menu bar integration
- 03: Global hotkey
- 04: Window shapes
- 05: Mirror flip
- 06: Brightness + zoom
- 07: Drag + resize
- 08: Settings persistence
- 09: Launch at login
- 10: Polish + App Store prep

## Phase 4 — TRIAGE

Skipped. No issue tracker (GitHub not set up), all issues already specified.

## Phase 5 — TDD Implementation

### Build System Pivots
- Originally planned macOS 14 + Xcode 15 target
- User's machine: macOS 13.4 + Xcode 13.4.1 (Swift 5.6)
- Cannot install Xcode 15 on macOS 13 → pivoted to macOS 12 target
- xcodegen requires Xcode 15.3 → used Swift Package Manager instead

### Implementation Order
1. Created Package.swift with 3 targets (library, executable, tests)
2. CameraManager with protocol-based DI (12 tests)
3. ImageProcessor as pure stateless enum (12 tests)
4. SettingsStore with UserDefaults + clamping (16 tests)
5. MirrorWindow (NSPanel floating)
6. HotkeyManager (NSEvent global monitor)
7. MenuBarController (NSStatusItem + NSMenu)
8. main.swift entry point
9. Screenshot + video recording (ScreenRecorder)
10. Self-timer countdown (CountdownTimer)
11. Convex/concave mirror effects (CIBumpDistortion)
12. Grayscale/sepia color filters
13. Freeze mode, opacity control

### Critical Bug Fixes (user-reported during testing)
1. **"원형으로 안나오는데"** (circle not showing) — NSImageView layer cornerRadius insufficient.
   Fix: Created MirrorContentView with CGPath(ellipseIn:) clipping in draw().

2. **"드래그로 안움직여지는데"** (drag not working) — NSImageView consuming mouse events despite isMovableByWindowBackground.
   Fix: Manual mouseDown/mouseDragged/mouseUp on custom MirrorContentView.

3. **"볼록거울처럼 이상해"** (looks like convex mirror) — 16:9 camera image stretched into 1:1 square.
   Fix: aspectFillRect() method for center-cropped aspect-fill rendering.

4. **Timer misunderstanding** — Built standalone countdown, user meant self-timer before capture ("녹화나 스크린샷 버튼을 누를때 카운트다운").
   Fix: Redesigned CountdownTimer to countdownThen(delay:action:) pattern.

### Build Error Fixes
- main.swift in library target → moved to separate MirrorCamApp executable target
- Missing `import MirrorCam` in main.swift
- SettingsStore init needed `import AppKit` for NSScreen.main

## User Preferences & Decisions

- **Price**: Free (explicitly chose over $1.99-$4.99 options, portfolio use)
- **Microphone**: Explicitly passed ("패스") — not interested in mic level monitoring
- **Competitors**: Aware of Hand Mirror ($6.99 Pro), CamPhoto, Mirror Magnet ($4.99)
- **Differentiators**: Free + effects (convex/concave) + recording + self-timer
- **Language**: Communicates in Korean, uses informal speech (반말)

## Phase 6 — Distribution Prep (2026-05-18)

### Changes Made
1. **Package.swift**: swift-tools-version 5.6→5.9, macOS target .v12→.v13
2. **ScreenRecorder.swift**: NSUserNotification → UNUserNotificationCenter (import UserNotifications, requestAuthorization, UNNotificationRequest)
3. **MenuBarController.swift**: Launch-at-Login now uses SMAppService.mainApp.register()/unregister() (import ServiceManagement)
4. **MirrorWindow.swift**: Fade-in (0→1, 0.2s) on show, fade-out (1→0, 0.2s) on hide with completion handler
5. **Info.plist**: Bundle ID set to `com.sijin.MirrorCam`, LSMinimumSystemVersion 12.0→13.0
6. **PrivacyInfo.xcprivacy**: New file — privacy manifest (no tracking, no collected data)
7. **scripts/build-app.sh**: New file — builds release binary, creates .app bundle, ad-hoc signs, creates DMG
8. **CLAUDE.md**: Updated to reflect all changes

### Build & Test Verification
- `swift build` — 0 warnings, 0 errors
- `swift test` — 40 tests passed, 0 failures

### Bug Fix
- **ScreenRecorder.swift**: UNUserNotificationCenter.current() crashes without bundle ID (SPM debug binary). Added `hasBundleIdentifier` guard to skip notification calls when `Bundle.main.bundleIdentifier == nil`.

### App Icon
- **scripts/generate-icon.swift**: SF Symbol `camera.fill` on dark purple gradient circle
- **Resources/AppIcon.icns**: 1.4MB, all sizes 16~1024px
- **Info.plist**: Added `CFBundleIconFile = AppIcon`

### Build & Release (2026-05-19)
- `scripts/build-app.sh` → .app (ad-hoc signed) + DMG (1.9MB)
- GitHub Release v1.0.0: https://github.com/sijinyu/MirrorCam/releases/tag/v1.0.0

## Git State (at session end)

Branch: `master` (synced with origin/master)
```
968befc feat: add temporary app icon (SF Symbol camera on purple gradient)
87a49aa fix: guard UNUserNotificationCenter calls for missing bundle identifier
b3bca63 docs: update MEMORY.md with distribution prep session details
2ceb90b feat: prepare app for distribution (macOS 13+, UserNotifications, SMAppService, fade animation)
314a968 docs: add comprehensive CLAUDE.md and MEMORY.md
4b0fbd1 docs: add CLAUDE.md and MEMORY.md for session context
bab92b3 feat: add screenshot, recording, effects, and UI fixes
c3af3a5 feat: initial MirrorCam implementation
```

GitHub Release: v1.0.0 published with MirrorCam.dmg

## Remaining Work

### Future (requires Apple Developer Program $99/yr)
1. Notarize with Developer ID for Gatekeeper bypass
2. Create Xcode project for Mac App Store submission
3. App Store metadata (screenshots, description, keywords)

### Optional Enhancements (not requested)
- Background replacement
- Face detection auto-framing
- Multiple camera support
- Custom hotkey configuration UI
- Window border/shadow customization
- Professional app icon (replace SF Symbol placeholder)

## Technical Debt

- Video recording frame size = window size, not camera native resolution
- No Xcode project — SPM only, needs .xcodeproj for App Store
- Resources/Info.plist and MirrorCam.entitlements not linked in Package.swift (need Xcode project)
- Error handling in ScreenRecorder is silent (no user feedback on failure)

## Hook Constraints (from user's Claude config)

- Pre-tool hook blocks creating .md files unless they are README.md, CLAUDE.md, MEMORY.md, or similar standard names
- Commit messages: no Co-Authored-By line (disabled globally via user settings)
- Conventional commits format: feat/fix/refactor/docs/test/chore/perf/ci
