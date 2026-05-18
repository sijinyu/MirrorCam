# MirrorCam Session Memory

## Project Origin

User wanted a macOS menu bar webcam mirror app — small floating PIP window (circle/rectangle) activated by hotkey. Intended as a free Mac App Store portfolio piece.

## Pipeline Phases Completed

1. **GRILL** — 13 requirements questions resolved
2. **PRD** — Written to README.md (hook blocked other .md names)
3. **ISSUES** — 10 vertical slices in `issues/01-10*.txt`
4. **TRIAGE** — Skipped (no issue tracker)
5. **TDD** — All 10 issues implemented, 40 tests passing
6. **REVIEW** — Not yet done

## Key Decisions

| Decision | Choice | Reason |
|----------|--------|--------|
| Framework | Swift (AppKit + AVFoundation) | Native macOS, no SwiftUI needed |
| Build system | Swift Package Manager | xcodegen requires Xcode 15.3 |
| Min target | macOS 12 | Xcode 13.4 can't target macOS 14+ |
| Window type | NSPanel (.floating) | Stays on top without stealing focus |
| Shape rendering | CGPath in draw() | More reliable than CALayer cornerRadius |
| Drag | mouseDown/mouseDragged on NSView | NSImageView eats events with isMovableByWindowBackground |
| Image fill | Aspect-fill (center crop) | Prevents distortion in square window |
| Price | Free | Portfolio piece, hard to compete with Hand Mirror etc. |
| Microphone | Passed | User decided not to add |

## Bug Fixes During Development

1. **Circle not rendering** — NSImageView layer masking insufficient. Created custom MirrorContentView with CGPath ellipse clipping.
2. **Drag not working** — NSImageView consuming mouse events. Implemented manual mouseDown/mouseDragged/mouseUp on custom view.
3. **Convex mirror look** — 16:9 camera squeezed into 1:1 square. Added aspectFillRect() for center-cropped rendering.
4. **Timer misunderstanding** — Built standalone countdown, user meant self-timer before capture. Redesigned to countdownThen(delay:action:) pattern.

## Environment Constraints

- macOS 13.4 (Ventura)
- Xcode 13.4.1 (Swift 5.6)
- Cannot install Xcode 15 (needs macOS 14+)
- Cannot install xcodegen (needs Xcode 15.3)
- gh CLI install failed (xcode-select dependency issue)
- App Store submission requires Xcode 15+ (future upgrade needed)

## What's Next

1. Push to GitHub (gh CLI failed, use git remote manually)
2. Upgrade macOS to 14+ (Sonoma)
3. Upgrade Xcode to 15+
4. Create Xcode project for App Store submission
5. Design app icon (1024x1024)
6. App Store metadata (screenshots, description, keywords)
7. Apple Developer Program enrollment ($99/yr)
8. Archive and submit via Xcode

## Test Coverage

- CameraManager: 12 tests (authorization, session lifecycle, DI)
- ImageProcessor: 12 tests (flip, brightness, zoom, effects, filters)
- SettingsStore: 16 tests (defaults, persistence, clamping)
- Total: 40 tests, all passing

## Competitors Found

- Hand Mirror ($6.99 Pro) — most popular, mirror only
- CamPhoto — free but limited
- Mirror Magnet ($4.99) — similar concept
- MirrorCam differentiators: free, effects (convex/concave), recording, self-timer
