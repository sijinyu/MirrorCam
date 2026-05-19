# MirrorCam

macOS menu bar webcam mirror app. Floating PIP window with circle/rectangle shapes.

## Build & Run

```bash
swift build && .build/debug/MirrorCamApp
```

## Test

```bash
swift test  # 40 tests, all passing
```

## Architecture

Swift Package (swift-tools-version 5.9, macOS 13+)

| Module | File | Role |
|--------|------|------|
| CameraProviding | CameraProviding.swift | Protocols: CameraProviding, SystemCameraAuthorizer, CaptureSessionProviding |
| CameraManager | CameraManager.swift | AVCaptureSession lifecycle, DI via protocols, framePublisher (Combine) |
| AVCaptureSessionWrapper | AVCaptureSessionWrapper.swift | Real AVCaptureSession wrapper implementing CaptureSessionProviding |
| SystemCameraAuthorizer | SystemCameraAuthorizer.swift | Real system camera authorizer wrapping AVCaptureDevice |
| ImageProcessor | ImageProcessor.swift | Stateless CIImage pipeline: flip, brightness, zoom, effects, filters |
| SettingsStore | SettingsStore.swift | ObservableObject + UserDefaults persistence with value clamping |
| WindowShape | WindowShape.swift | Enums: WindowShape, MirrorEffect, ColorFilter (no TimerDelay - that's in CountdownTimer.swift) |
| MirrorWindow | MirrorWindow.swift | Floating NSPanel management, opacity, freeze, timer overlay |
| MirrorContentView | MirrorContentView.swift | Custom NSView: shape clipping, drag, scroll resize, timer overlay, aspect-fill rendering |
| HotkeyManager | HotkeyManager.swift | Global keyboard shortcut (⌥⌘G) via NSEvent.addGlobalMonitorForEvents |
| MenuBarController | MenuBarController.swift | NSStatusItem + dropdown menu with all settings + SMAppService launch-at-login |
| ScreenRecorder | ScreenRecorder.swift | Screenshot (PNG) + video recording (MP4) via AVAssetWriter + UNUserNotificationCenter |
| CountdownTimer | CountdownTimer.swift | Self-timer countdown before capture + TimerDelay enum |
| MirrorCamApp | MirrorCamApp.swift | AppDelegate wiring all modules |

## Targets

- `MirrorCam` — library (all modules, testable)
- `MirrorCamApp` — executable (main.swift, imports MirrorCam)
- `MirrorCamTests` — unit tests (CameraManagerTests, ImageProcessorTests, SettingsStoreTests)

## File Tree

```
MirrorCam/
├── Package.swift
├── CLAUDE.md
├── MEMORY.md
├── README.md (contains original PRD)
├── .gitignore
├── Resources/
│   ├── Info.plist (LSUIElement=true, NSCameraUsageDescription, Bundle ID)
│   ├── MirrorCam.entitlements (Sandbox + camera)
│   └── PrivacyInfo.xcprivacy (Privacy manifest)
├── Sources/
│   ├── MirrorCam/
│   │   ├── AVCaptureSessionWrapper.swift
│   │   ├── CameraManager.swift
│   │   ├── CameraProviding.swift
│   │   ├── CountdownTimer.swift
│   │   ├── HotkeyManager.swift
│   │   ├── ImageProcessor.swift
│   │   ├── MenuBarController.swift
│   │   ├── MirrorCamApp.swift
│   │   ├── MirrorContentView.swift
│   │   ├── MirrorWindow.swift
│   │   ├── ScreenRecorder.swift
│   │   ├── SettingsStore.swift
│   │   ├── SystemCameraAuthorizer.swift
│   │   └── WindowShape.swift
│   └── MirrorCamApp/
│       └── main.swift
├── Tests/
│   └── MirrorCamTests/
│       ├── CameraManagerTests.swift (12 tests)
│       ├── ImageProcessorTests.swift (12 tests)
│       └── SettingsStoreTests.swift (16 tests)
├── scripts/
│   └── build-app.sh (builds .app bundle + DMG)
└── issues/ (10 vertical slice specs, reference only)
```

## Key Decisions

- NSPanel with `.floating` level (not NSWindow) — stays above all windows, doesn't steal focus
- Camera stops when mirror is hidden (battery optimization)
- DI via protocols (SystemCameraAuthorizer, CaptureSessionProviding) for testable CameraManager
- ImageProcessor is a pure enum with static functions — no state
- Shape clipping via CGPath in draw() — not CALayer cornerRadius (more reliable for circle)
- Drag via mouseDown/mouseDragged on custom NSView — not isMovableByWindowBackground (NSImageView eats events)
- Aspect-fill rendering to prevent distortion in square window (16:9 camera → 1:1 window)
- Self-timer pattern: CountdownTimer.countdownThen(delay:action:) — counts down, then executes
- NSApp.setActivationPolicy(.accessory) — menu bar only, no Dock icon
- Menu rebuilt on every state change via rebuildMenu() — simple, reliable

## Shortcuts

| Key | Action |
|-----|--------|
| ⌥⌘G | Toggle mirror |
| ⌥⌘S | Screenshot (with self-timer if set) |
| ⌥⌘R | Start/stop recording (with self-timer if set) |
| ⌥⌘F | Freeze/unfreeze |
| Scroll wheel | Resize mirror window |

## Settings Ranges

| Setting | Range | Default |
|---------|-------|---------|
| windowSize | 100–600 px | 200 |
| brightness | -0.5 to 0.5 | 0.0 |
| zoom | 1.0x–3.0x | 1.0 |
| opacity | 0.2–1.0 | 1.0 |
| shape | circle, roundedRectangle | circle |
| mirrorEffect | flat, convex, concave | flat |
| colorFilter | none, grayscale, sepia | none |
| timerDelay | off, 3s, 5s, 10s | off |
| isMirrored | true/false | true |
| launchAtLogin | true/false | false |

## Distribution

- Bundle ID: com.sijin.MirrorCam
- Sandbox: enabled (Resources/MirrorCam.entitlements)
- Camera entitlement: com.apple.security.device.camera
- LSUIElement: true (menu bar only, no Dock icon)
- Privacy manifest: Resources/PrivacyInfo.xcprivacy
- Build script: `scripts/build-app.sh` (creates .app bundle + DMG)
- App icon: Resources/AppIcon.icns (SF Symbol placeholder, generated via scripts/generate-icon.swift)
- Current: GitHub Releases v1.0.0 (unsigned, free) — https://github.com/sijinyu/MirrorCam/releases/tag/v1.0.0
- Future: Notarized or Mac App Store ($99/yr Apple Developer Program)

## Build .app Bundle

```bash
scripts/build-app.sh
# Output: .build-app/MirrorCam.app and .build-app/MirrorCam.dmg
```

## What's Next

1. Apple Developer Program enrollment ($99/yr) for notarization/App Store
2. Create Xcode project for App Store submission
3. (Optional) Professional app icon to replace SF Symbol placeholder

## Test DI Pattern

Tests use mock implementations of protocols:
- `MockCameraAuthorizer` implements `SystemCameraAuthorizer` — returns configurable auth status
- `MockCaptureSession` implements `CaptureSessionProviding` — tracks calls, can simulate failure
- `SettingsStoreTests` use isolated `UserDefaults(suiteName:)` per test

## Known Limitations

- No Xcode project — SPM only, App Store requires `.xcodeproj` or `.xcworkspace`
- No mic support (user explicitly passed)
- Video recording uses window size as frame size (not camera native resolution)
- GitHub Release is unsigned — users must right-click → Open on first launch
- UNUserNotificationCenter requires bundle ID — notifications skip in SPM debug builds
