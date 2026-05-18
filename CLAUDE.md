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

Swift Package (swift-tools-version 5.6, macOS 12+)

| Module | File | Role |
|--------|------|------|
| CameraManager | CameraManager.swift | AVCaptureSession lifecycle, DI via protocols |
| ImageProcessor | ImageProcessor.swift | Stateless CIImage pipeline: flip, brightness, zoom, effects, filters |
| SettingsStore | SettingsStore.swift | ObservableObject + UserDefaults persistence |
| MirrorWindow | MirrorWindow.swift | Floating NSPanel management |
| MirrorContentView | MirrorContentView.swift | Custom NSView: shape clipping, drag, scroll resize, timer overlay |
| HotkeyManager | HotkeyManager.swift | Global keyboard shortcut (⌥⌘G) |
| MenuBarController | MenuBarController.swift | NSStatusItem + dropdown menu |
| ScreenRecorder | ScreenRecorder.swift | Screenshot (PNG) + video recording (MP4) |
| CountdownTimer | CountdownTimer.swift | Self-timer countdown before capture |
| MirrorCamApp | MirrorCamApp.swift | AppDelegate wiring all modules |

## Targets

- `MirrorCam` — library (all modules, testable)
- `MirrorCamApp` — executable (main.swift, imports MirrorCam)
- `MirrorCamTests` — unit tests

## Key Decisions

- NSPanel with `.floating` level (not NSWindow) — stays above all windows, doesn't steal focus
- Camera stops when mirror is hidden (battery optimization)
- DI via protocols (SystemCameraAuthorizer, CaptureSessionProviding) for testable CameraManager
- ImageProcessor is a pure enum with static functions — no state
- Shape clipping via CGPath in draw() — not CALayer cornerRadius (more reliable for circle)
- Drag via mouseDown/mouseDragged on custom NSView — not isMovableByWindowBackground
- Aspect-fill rendering to prevent distortion in square window

## Shortcuts

| Key | Action |
|-----|--------|
| ⌥⌘G | Toggle mirror |
| ⌥⌘S | Screenshot (with self-timer if set) |
| ⌥⌘R | Start/stop recording (with self-timer if set) |
| ⌥⌘F | Freeze/unfreeze |
| Scroll wheel | Resize mirror window |

## Distribution

- Target: Mac App Store (free)
- Sandbox: enabled (Resources/MirrorCam.entitlements)
- Camera entitlement: com.apple.security.device.camera
- LSUIElement: true (menu bar only, no Dock icon)
- Requires Xcode 15+ to build for App Store submission (current dev on Xcode 13.4)

## What's Next

1. Upgrade macOS + Xcode to 15+
2. Create Xcode project (xcodegen or manual)
3. Design app icon (1024x1024)
4. App Store metadata (screenshots, description, keywords)
5. Apple Developer Program enrollment ($99/yr)
6. Archive + submit via Xcode
