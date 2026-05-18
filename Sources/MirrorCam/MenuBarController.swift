import AppKit
import Combine
import ServiceManagement

public final class MenuBarController {
    private var statusItem: NSStatusItem?
    private let settings: SettingsStore

    public var onToggleMirror: (() -> Void)?
    public var onScreenshot: (() -> Void)?
    public var onToggleRecording: (() -> Void)?
    public var onToggleFreeze: (() -> Void)?
    public var onQuit: (() -> Void)?

    public var isRecording = false { didSet { rebuildMenu() } }
    public var isFrozen = false { didSet { rebuildMenu() } }

    public init(settings: SettingsStore) {
        self.settings = settings
    }

    public func setup() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "camera.fill", accessibilityDescription: "MirrorCam")
        }
        self.statusItem = statusItem
        rebuildMenu()
    }

    public func teardown() {
        if let item = statusItem { NSStatusBar.system.removeStatusItem(item) }
        statusItem = nil
    }

    private func rebuildMenu() {
        statusItem?.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        // Toggle mirror
        let toggleItem = NSMenuItem(title: "Toggle Mirror  (⌥⌘G)", action: #selector(toggleMirror), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)

        // Freeze
        let freezeTitle = isFrozen ? "Unfreeze  (⌥⌘F)" : "Freeze  (⌥⌘F)"
        let freezeItem = NSMenuItem(title: freezeTitle, action: #selector(toggleFreeze), keyEquivalent: "")
        freezeItem.target = self
        if isFrozen { freezeItem.state = .on }
        menu.addItem(freezeItem)

        menu.addItem(NSMenuItem.separator())

        // Screenshot & Recording
        let screenshotLabel = settings.timerDelay == .off
            ? "Screenshot  (⌥⌘S)"
            : "Screenshot \(settings.timerDelay.label)  (⌥⌘S)"
        let screenshotItem = NSMenuItem(title: screenshotLabel, action: #selector(screenshot), keyEquivalent: "")
        screenshotItem.target = self
        menu.addItem(screenshotItem)

        let recordLabel: String
        if isRecording {
            recordLabel = "Stop Recording  (⌥⌘R)"
        } else if settings.timerDelay == .off {
            recordLabel = "Start Recording  (⌥⌘R)"
        } else {
            recordLabel = "Start Recording \(settings.timerDelay.label)  (⌥⌘R)"
        }
        let recordItem = NSMenuItem(title: recordLabel, action: #selector(toggleRecording), keyEquivalent: "")
        recordItem.target = self
        if isRecording { recordItem.state = .on }
        menu.addItem(recordItem)

        // Self-timer submenu
        let timerMenu = NSMenu()
        for delay in TimerDelay.allCases {
            let item = NSMenuItem(title: delay.label, action: #selector(setTimerDelay(_:)), keyEquivalent: "")
            item.target = self
            item.tag = delay.rawValue
            item.state = settings.timerDelay == delay ? .on : .off
            timerMenu.addItem(item)
        }
        let timerMenuItem = NSMenuItem(title: "Self-Timer: \(settings.timerDelay.label)", action: nil, keyEquivalent: "")
        timerMenuItem.submenu = timerMenu
        menu.addItem(timerMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Shape submenu
        let shapeMenu = NSMenu()
        let circleItem = NSMenuItem(title: "Circle", action: #selector(setCircleShape), keyEquivalent: "")
        circleItem.target = self
        circleItem.state = settings.shape == .circle ? .on : .off
        shapeMenu.addItem(circleItem)
        let rectItem = NSMenuItem(title: "Rectangle", action: #selector(setRectShape), keyEquivalent: "")
        rectItem.target = self
        rectItem.state = settings.shape == .roundedRectangle ? .on : .off
        shapeMenu.addItem(rectItem)
        let shapeMenuItem = NSMenuItem(title: "Shape", action: nil, keyEquivalent: "")
        shapeMenuItem.submenu = shapeMenu
        menu.addItem(shapeMenuItem)

        // Mirror effect submenu
        let effectMenu = NSMenu()
        for effect in MirrorEffect.allCases {
            let item = NSMenuItem(title: effect.rawValue, action: #selector(setMirrorEffect(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = effect
            item.state = settings.mirrorEffect == effect ? .on : .off
            effectMenu.addItem(item)
        }
        let effectMenuItem = NSMenuItem(title: "Mirror Effect", action: nil, keyEquivalent: "")
        effectMenuItem.submenu = effectMenu
        menu.addItem(effectMenuItem)

        // Color filter submenu
        let filterMenu = NSMenu()
        for filter in ColorFilter.allCases {
            let item = NSMenuItem(title: filter.rawValue, action: #selector(setColorFilter(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = filter
            item.state = settings.colorFilter == filter ? .on : .off
            filterMenu.addItem(item)
        }
        let filterMenuItem = NSMenuItem(title: "Color Filter", action: nil, keyEquivalent: "")
        filterMenuItem.submenu = filterMenu
        menu.addItem(filterMenuItem)

        // Flip mirror
        let flipItem = NSMenuItem(title: "Flip Mirror", action: #selector(toggleFlip), keyEquivalent: "")
        flipItem.target = self
        flipItem.state = settings.isMirrored ? .on : .off
        menu.addItem(flipItem)

        // Opacity submenu
        let opacityMenu = NSMenu()
        for pct in [100, 80, 60, 40, 20] {
            let item = NSMenuItem(title: "\(pct)%", action: #selector(setOpacity(_:)), keyEquivalent: "")
            item.target = self
            item.tag = pct
            item.state = Int(settings.opacity * 100) == pct ? .on : .off
            opacityMenu.addItem(item)
        }
        let opacityMenuItem = NSMenuItem(title: "Opacity", action: nil, keyEquivalent: "")
        opacityMenuItem.submenu = opacityMenu
        menu.addItem(opacityMenuItem)

        menu.addItem(NSMenuItem.separator())

        let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = settings.launchAtLogin ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit MirrorCam", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    // MARK: - Actions

    @objc private func toggleMirror() { onToggleMirror?() }
    @objc private func screenshot() { onScreenshot?() }
    @objc private func toggleRecording() { onToggleRecording?() }
    @objc private func toggleFreeze() { onToggleFreeze?() }
    @objc private func setCircleShape() { settings.shape = .circle; rebuildMenu() }
    @objc private func setRectShape() { settings.shape = .roundedRectangle; rebuildMenu() }
    @objc private func toggleFlip() { settings.isMirrored.toggle(); rebuildMenu() }
    @objc private func toggleLaunchAtLogin() {
        let newValue = !settings.launchAtLogin
        do {
            if newValue {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            settings.launchAtLogin = newValue
        } catch {
            // Registration failed — keep setting unchanged
        }
        rebuildMenu()
    }
    @objc private func quit() { onQuit?() }

    @objc private func setTimerDelay(_ sender: NSMenuItem) {
        settings.timerDelay = TimerDelay(rawValue: sender.tag) ?? .off
        rebuildMenu()
    }

    @objc private func setMirrorEffect(_ sender: NSMenuItem) {
        guard let effect = sender.representedObject as? MirrorEffect else { return }
        settings.mirrorEffect = effect; rebuildMenu()
    }

    @objc private func setColorFilter(_ sender: NSMenuItem) {
        guard let filter = sender.representedObject as? ColorFilter else { return }
        settings.colorFilter = filter; rebuildMenu()
    }

    @objc private func setOpacity(_ sender: NSMenuItem) {
        settings.opacity = Double(sender.tag) / 100.0; rebuildMenu()
    }
}
