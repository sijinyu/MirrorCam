# MirrorCam — Product Requirements Document

## Problem Statement

macOS 사용자가 화상 회의, 프레젠테이션, 또는 외출 전에 빠르게 자신의 모습을 확인하고 싶을 때, 기존 방법(Photo Booth 실행, FaceTime 열기 등)은 전체 앱을 열어야 하고 화면을 많이 차지한다. 단축키 한 번으로 작은 거울 창을 띄우고 바로 닫을 수 있는 경량 도구가 필요하다.

## Solution

**MirrorCam**은 macOS 메뉴바에 상주하는 경량 거울 앱이다. 글로벌 단축키(⌥⌘G)로 작은 PIP 형태의 웹캠 미리보기 창을 토글한다. 원형 또는 둥근 직사각형 모양으로, 항상 다른 창 위에 떠 있으며, 실제 거울처럼 좌우 반전된 영상을 보여준다.

## User Stories

1. As a macOS user, I want to press ⌥⌘G to instantly see my face in a small floating window, so that I can check my appearance without opening a separate app.
2. As a user in a video meeting, I want the mirror to float above all windows, so that I can always see myself regardless of which app is active.
3. As a user, I want to choose between circular and rounded-rectangle window shapes, so that I can pick the style I prefer.
4. As a user, I want to drag the mirror window to any position on screen, so that it doesn't block content I'm working with.
5. As a user, I want to resize the mirror by dragging its edges (100px to 600px), so that I can adjust it to the right size for my workflow.
6. As a user, I want the mirror image to be horizontally flipped by default (like a real mirror), so that movements feel natural.
7. As a user, I want to toggle the mirror flip on/off, so that I can see the non-mirrored view when needed.
8. As a user, I want to adjust the brightness of the mirror image, so that I can compensate for lighting conditions.
9. As a user, I want to zoom in/out on the mirror image, so that I can focus on specific details.
10. As a user, I want the app to remember my last window position, size, shape, brightness, and zoom settings, so that the mirror opens exactly how I left it.
11. As a user, I want the app to launch automatically at login, so that the mirror is always available in the menu bar without manual startup.
12. As a user, I want a menu bar icon that shows a dropdown with quick settings, so that I can configure the app without a separate settings window.
13. As a user, I want the app to request camera permission gracefully with a clear explanation, so that I understand why the permission is needed.
14. As a user, I want to customize the global hotkey, so that I can avoid conflicts with other apps' shortcuts.
15. As a user, I want the app to use minimal CPU and battery, so that it doesn't impact my Mac's performance when running in the background.
16. As a user, I want the camera to stop capturing when the mirror is hidden, so that battery is conserved and privacy is maintained.
17. As a user, I want a smooth show/hide animation, so that the mirror feels polished and native.

## Implementation Decisions

### Architecture
- **Framework**: Swift with SwiftUI for UI, AVFoundation for camera, CoreImage for image processing
- **App type**: Menu bar only app (LSUIElement = true, no Dock icon)
- **Minimum deployment target**: macOS 14.0 (Sonoma)

### Module Design

1. **CameraManager**: Wraps AVCaptureSession. Exposes `start()`, `stop()`, and a `currentFrame: CIImage` publisher. Handles camera authorization. Stops capture when mirror is hidden to save battery. Does not know about UI.

2. **MirrorWindow**: NSPanel subclass with `.floating` level. Manages window shape (circle vs rounded rect) via CALayer masking. Supports drag-to-move and edge-drag-to-resize. Emits position/size change events for persistence.

3. **HotkeyManager**: Registers global keyboard shortcut using `CGEvent.tapCreate` or `NSEvent.addGlobalMonitorForEvents`. Supports changing the hotkey at runtime. Default: ⌥⌘G.

4. **SettingsStore**: `@Observable` class backed by UserDefaults. Properties: windowX, windowY, windowWidth, windowHeight, shape (circle/rect), isMirrored, brightness, zoom, customHotkey. All changes auto-persisted.

5. **ImageProcessor**: Pure function pipeline: `CIImage -> mirror flip -> brightness adjust -> zoom/crop -> CIImage`. Uses CIFilter. Stateless — parameters passed in, new image returned.

6. **MenuBarController**: Creates NSStatusItem with SF Symbol icon. Builds NSMenu with items: Toggle Mirror, Shape (Circle/Rectangle), Flip Mirror, Launch at Login, Customize Hotkey, Quit.

7. **App Entry Point**: SwiftUI `@main` App struct. Registers SMAppService for login item. Wires modules together.

### Key Technical Decisions
- Use NSPanel (not NSWindow) for floating behavior — panels can float above regular windows and don't steal focus
- Camera stops when mirror is hidden (battery optimization)
- Image processing uses CIContext with Metal for GPU-accelerated rendering
- Settings persisted via UserDefaults (appropriate for simple key-value storage)
- Login item uses SMAppService (modern macOS API, replaces deprecated LSSharedFileList)
- App Sandbox enabled for Mac App Store distribution
- Camera entitlement: `com.apple.security.device.camera`

### Distribution
- **Platform**: Mac App Store only (v1)
- **Price**: Free
- **Sandbox**: Enabled (required for App Store)
- **Entitlements**: Camera access
- **Bundle ID**: to be determined (e.g., com.sijin.mirrorcam)

## Testing Decisions

### Testing Philosophy
- Test external behavior through module public interfaces, not internal implementation details
- Use protocol-based dependency injection to mock hardware dependencies (camera)
- Focus on state transitions and output correctness

### Modules Under Test

1. **CameraManager**: Test authorization flow (granted/denied/restricted states), session lifecycle (start/stop), frame publishing. Mock AVCaptureSession via protocol.

2. **MirrorWindow**: Test window level is floating, shape masking applies correctly, position/size constraints (min 100px, max 600px), drag behavior emits correct events.

3. **ImageProcessor**: Test mirror flip produces horizontally flipped output, brightness adjustment within expected range, zoom crop calculates correct rect. Pure functions — easy to test with known input images.

4. **HotkeyManager**: Test hotkey registration/deregistration, custom hotkey persistence, callback invocation on key event.

5. **SettingsStore**: Test default values, persistence round-trip (write -> read), property change notifications, boundary values.

### Test Framework
- XCTest (built-in, sufficient for unit and integration tests)

## Out of Scope

- Multiple camera selection (v2)
- Image filters / beauty mode (v2)
- Recording or screenshot
- Windows/Linux support
- Direct download (DMG) distribution
- Paid features or in-app purchases
- Video conferencing integration
- Homebrew distribution

## Further Notes

- **Competition**: Hand Mirror (App Store, $3.99) is the primary competitor. MirrorCam differentiates by being free, supporting both circular and rectangular shapes, and including brightness/zoom controls.
- **Privacy**: Camera is only active when the mirror window is visible. No data leaves the device. No analytics or tracking.
- **Performance target**: < 5% CPU when mirror is visible, near 0% when hidden.
- **Localization**: English and Korean for v1.
