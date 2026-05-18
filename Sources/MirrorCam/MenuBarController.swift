import AppKit
import Combine

public final class MenuBarController {
    private var statusItem: NSStatusItem?
    private let settings: SettingsStore
    private var cancellables = Set<AnyCancellable>()

    public var onToggleMirror: (() -> Void)?
    public var onQuit: (() -> Void)?

    public init(settings: SettingsStore) {
        self.settings = settings
    }

    public func setup() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "camera.fill", accessibilityDescription: "MirrorCam")
        }

        statusItem.menu = buildMenu()
        self.statusItem = statusItem
    }

    public func teardown() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
        }
        statusItem = nil
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let toggleItem = NSMenuItem(title: "Toggle Mirror", action: #selector(toggleMirror), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)

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

        // Flip mirror
        let flipItem = NSMenuItem(title: "Flip Mirror", action: #selector(toggleFlip), keyEquivalent: "")
        flipItem.target = self
        flipItem.state = settings.isMirrored ? .on : .off
        menu.addItem(flipItem)

        menu.addItem(NSMenuItem.separator())

        // Launch at login
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

    @objc private func toggleMirror() {
        onToggleMirror?()
    }

    @objc private func setCircleShape() {
        settings.shape = .circle
        statusItem?.menu = buildMenu()
    }

    @objc private func setRectShape() {
        settings.shape = .roundedRectangle
        statusItem?.menu = buildMenu()
    }

    @objc private func toggleFlip() {
        settings.isMirrored.toggle()
        statusItem?.menu = buildMenu()
    }

    @objc private func toggleLaunchAtLogin() {
        settings.launchAtLogin.toggle()
        statusItem?.menu = buildMenu()
    }

    @objc private func quit() {
        onQuit?()
    }
}
