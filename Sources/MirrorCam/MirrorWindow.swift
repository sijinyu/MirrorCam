import AppKit
import CoreImage
import Combine

public final class MirrorWindow {
    private var panel: NSPanel?
    private var contentView: MirrorContentView?
    private var cancellables = Set<AnyCancellable>()

    public var onPositionChanged: ((Double, Double) -> Void)?
    public var onSizeChanged: ((Double) -> Void)?

    public private(set) var isVisible = false

    public init() {}

    public func show(settings: SettingsStore, framePublisher: AnyPublisher<CIImage, Never>) {
        if let panel = panel {
            panel.orderFront(nil)
            isVisible = true
            subscribeTo(framePublisher)
            return
        }

        let size = settings.windowSize
        let frame = NSRect(x: settings.windowX, y: settings.windowY, width: size, height: size)

        let panel = NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false

        let mirrorView = MirrorContentView(frame: NSRect(x: 0, y: 0, width: size, height: size))
        mirrorView.shape = settings.shape
        mirrorView.autoresizingMask = [.width, .height]

        panel.contentView = mirrorView
        self.contentView = mirrorView
        self.panel = panel

        subscribeTo(framePublisher)

        NotificationCenter.default.publisher(for: NSWindow.didMoveNotification, object: panel)
            .compactMap { ($0.object as? NSPanel)?.frame }
            .sink { [weak self] frame in
                self?.onPositionChanged?(frame.origin.x, frame.origin.y)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSWindow.didResizeNotification, object: panel)
            .compactMap { ($0.object as? NSPanel)?.frame }
            .sink { [weak self] frame in
                self?.onSizeChanged?(frame.width)
            }
            .store(in: &cancellables)

        panel.orderFront(nil)
        isVisible = true
    }

    public func hide() {
        panel?.orderOut(nil)
        cancellables.removeAll()
        isVisible = false
    }

    public func close() {
        hide()
        panel?.close()
        panel = nil
        contentView = nil
    }

    public func updateShape(_ shape: WindowShape) {
        contentView?.shape = shape
    }

    public func updateSize(_ newSize: Double) {
        guard let panel = panel else { return }
        let clamped = min(max(newSize, 100), 600)
        let center = NSPoint(x: panel.frame.midX, y: panel.frame.midY)
        let newOrigin = NSPoint(x: center.x - clamped / 2, y: center.y - clamped / 2)
        panel.setFrame(
            NSRect(x: newOrigin.x, y: newOrigin.y, width: clamped, height: clamped),
            display: true,
            animate: true
        )
        contentView?.frame = NSRect(x: 0, y: 0, width: clamped, height: clamped)
    }

    public func updateOpacity(_ opacity: Double) {
        panel?.alphaValue = min(max(opacity, 0.2), 1.0)
    }

    public func updateTimerText(_ text: String) {
        contentView?.timerText = text
    }

    public func setFrozen(_ frozen: Bool) {
        contentView?.isFrozen = frozen
    }

    private func subscribeTo(_ framePublisher: AnyPublisher<CIImage, Never>) {
        framePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ciImage in
                self?.contentView?.updateFrame(ciImage)
            }
            .store(in: &cancellables)
    }
}
