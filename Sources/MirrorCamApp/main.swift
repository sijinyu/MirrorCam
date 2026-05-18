import AppKit
import MirrorCam

let app = NSApplication.shared
let delegate = MirrorCamAppDelegate()
app.delegate = delegate

// Menu bar only — no Dock icon
// This is also set via LSUIElement in Info.plist for bundled apps
NSApp.setActivationPolicy(.accessory)

app.run()
