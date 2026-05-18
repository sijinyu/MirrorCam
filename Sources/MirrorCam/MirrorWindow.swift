import AppKit
import CoreImage
import Combine

public final class MirrorWindow {
    private var panel: NSPanel?
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    private var imageView: NSImageView?
    private var cancellables = Set<AnyCancellable>()
    private var trackingArea: NSTrackingArea?

    public var onPositionChanged: ((Double, Double) -> Void)?
    public var onSizeChanged: ((Double) -> Void)?

    public private(set) var isVisible = false

    public init() {}

    public func show(settings: SettingsStore, framePublisher: AnyPublisher<CIImage, Never>) {
        guard panel == nil else {
            panel?.orderFront(nil)
            isVisible = true
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
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let imageView = NSImageView(frame: NSRect(x: 0, y: 0, width: size, height: size))
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.wantsLayer = true

        panel.contentView = imageView
        self.imageView = imageView
        self.panel = panel

        applyShape(settings.shape, size: size)

        framePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ciImage in
                self?.renderFrame(ciImage)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSWindow.didMoveNotification, object: panel)
            .compactMap { ($0.object as? NSPanel)?.frame }
            .sink { [weak self] frame in
                self?.onPositionChanged?(frame.origin.x, frame.origin.y)
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
        imageView = nil
    }

    public func updateShape(_ shape: WindowShape) {
        guard let panel = panel else { return }
        let size = panel.frame.width
        applyShape(shape, size: size)
    }

    public func updateSize(_ newSize: Double) {
        guard let panel = panel else { return }
        let clamped = min(max(newSize, 100), 600)
        let origin = panel.frame.origin
        panel.setFrame(
            NSRect(x: origin.x, y: origin.y, width: clamped, height: clamped),
            display: true,
            animate: true
        )
        imageView?.frame = NSRect(x: 0, y: 0, width: clamped, height: clamped)
        if let shape = currentShape(from: panel) {
            applyShape(shape, size: clamped)
        }
    }

    private func applyShape(_ shape: WindowShape, size: Double) {
        guard let layer = imageView?.layer else { return }
        switch shape {
        case .circle:
            layer.cornerRadius = size / 2
        case .roundedRectangle:
            layer.cornerRadius = size * 0.15
        }
        layer.masksToBounds = true
    }

    private func currentShape(from panel: NSPanel) -> WindowShape? {
        guard let layer = imageView?.layer else { return nil }
        let size = panel.frame.width
        if abs(layer.cornerRadius - size / 2) < 1 {
            return .circle
        }
        return .roundedRectangle
    }

    private func renderFrame(_ ciImage: CIImage) {
        guard let imageView = imageView else { return }
        let extent = ciImage.extent
        guard let cgImage = ciContext.createCGImage(ciImage, from: extent) else { return }
        imageView.image = NSImage(cgImage: cgImage, size: NSSize(width: extent.width, height: extent.height))
    }
}
