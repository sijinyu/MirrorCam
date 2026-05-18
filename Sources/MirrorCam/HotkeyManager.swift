import AppKit
import Carbon

public final class HotkeyManager {
    private var eventMonitor: Any?
    private var onToggle: (() -> Void)?

    public struct KeyCombo: Equatable {
        public let keyCode: UInt16
        public let modifiers: NSEvent.ModifierFlags

        public init(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
            self.keyCode = keyCode
            self.modifiers = modifiers
        }

        // Default: Option+Cmd+G
        public static let defaultCombo = KeyCombo(
            keyCode: 0x05, // kVK_ANSI_G
            modifiers: [.option, .command]
        )
    }

    public private(set) var currentCombo: KeyCombo
    public private(set) var isRegistered = false

    public init(combo: KeyCombo = .defaultCombo) {
        self.currentCombo = combo
    }

    public func register(onToggle: @escaping () -> Void) {
        self.onToggle = onToggle

        let mask: NSEvent.EventTypeMask = .keyDown
        let targetModifiers = currentCombo.modifiers.intersection([.command, .option, .control, .shift])
        let targetKeyCode = currentCombo.keyCode

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            let eventModifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
            if event.keyCode == targetKeyCode && eventModifiers == targetModifiers {
                self?.onToggle?()
            }
        }

        isRegistered = true
    }

    public func unregister() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        onToggle = nil
        isRegistered = false
    }

    public func updateCombo(_ newCombo: KeyCombo) {
        let wasRegistered = isRegistered
        let savedToggle = onToggle

        if wasRegistered {
            unregister()
        }

        currentCombo = newCombo

        if wasRegistered, let toggle = savedToggle {
            register(onToggle: toggle)
        }
    }

    deinit {
        unregister()
    }
}
