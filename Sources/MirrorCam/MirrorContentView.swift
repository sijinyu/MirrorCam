import AppKit
import CoreImage

/// Custom NSView that renders camera frames with shape clipping and drag support.
public final class MirrorContentView: NSView {
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    private var currentImage: NSImage?
    private var initialMouseLocation: NSPoint?
    private var initialWindowOrigin: NSPoint?

    public var shape: WindowShape = .circle {
        didSet { needsDisplay = true }
    }

    public var timerText: String = "" {
        didSet { needsDisplay = true }
    }

    public var isFrozen = false

    override public var isFlipped: Bool { false }

    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    public func updateFrame(_ ciImage: CIImage) {
        guard !isFrozen else { return }
        let extent = ciImage.extent
        guard let cgImage = ciContext.createCGImage(ciImage, from: extent) else { return }
        currentImage = NSImage(cgImage: cgImage, size: NSSize(width: extent.width, height: extent.height))
        needsDisplay = true
    }

    override public func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let rect = bounds

        // Clip to shape
        let path: CGPath
        switch shape {
        case .circle:
            path = CGPath(ellipseIn: rect, transform: nil)
        case .roundedRectangle:
            let radius = min(rect.width, rect.height) * 0.15
            path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
        }

        ctx.addPath(path)
        ctx.clip()

        // Draw image with aspect-fill (no distortion, center crop)
        if let image = currentImage {
            let drawRect = aspectFillRect(imageSize: image.size, targetRect: rect)
            image.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        } else {
            // Placeholder when no camera frame
            NSColor.darkGray.setFill()
            ctx.fill(rect)

            let text = "MirrorCam" as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: NSColor.white,
                .font: NSFont.systemFont(ofSize: 14, weight: .medium)
            ]
            let textSize = text.size(withAttributes: attrs)
            let textPoint = NSPoint(
                x: rect.midX - textSize.width / 2,
                y: rect.midY - textSize.height / 2
            )
            text.draw(at: textPoint, withAttributes: attrs)
        }

        // Timer overlay
        if !timerText.isEmpty {
            drawTimerOverlay(in: rect, context: ctx)
        }
    }

    private func drawTimerOverlay(in rect: NSRect, context: CGContext) {
        let text = timerText as NSString
        let fontSize = rect.width * 0.25
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white,
            .font: NSFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .bold),
            .strokeColor: NSColor.black,
            .strokeWidth: NSNumber(value: -3.0)
        ]
        let textSize = text.size(withAttributes: attrs)
        let textPoint = NSPoint(
            x: rect.midX - textSize.width / 2,
            y: rect.height * 0.15
        )
        text.draw(at: textPoint, withAttributes: attrs)
    }

    /// Calculate a rect that fills the target while preserving aspect ratio (center-cropped).
    private func aspectFillRect(imageSize: NSSize, targetRect: NSRect) -> NSRect {
        let imageAspect = imageSize.width / imageSize.height
        let targetAspect = targetRect.width / targetRect.height

        var drawRect: NSRect
        if imageAspect > targetAspect {
            // Image is wider — match height, overflow width
            let drawHeight = targetRect.height
            let drawWidth = drawHeight * imageAspect
            let offsetX = (targetRect.width - drawWidth) / 2
            drawRect = NSRect(x: targetRect.origin.x + offsetX, y: targetRect.origin.y, width: drawWidth, height: drawHeight)
        } else {
            // Image is taller — match width, overflow height
            let drawWidth = targetRect.width
            let drawHeight = drawWidth / imageAspect
            let offsetY = (targetRect.height - drawHeight) / 2
            drawRect = NSRect(x: targetRect.origin.x, y: targetRect.origin.y + offsetY, width: drawWidth, height: drawHeight)
        }
        return drawRect
    }

    // MARK: - Drag to move

    override public func mouseDown(with event: NSEvent) {
        initialMouseLocation = NSEvent.mouseLocation
        initialWindowOrigin = window?.frame.origin
    }

    override public func mouseDragged(with event: NSEvent) {
        guard let window = window,
              let initialMouse = initialMouseLocation,
              let initialOrigin = initialWindowOrigin else { return }

        let currentMouse = NSEvent.mouseLocation
        let dx = currentMouse.x - initialMouse.x
        let dy = currentMouse.y - initialMouse.y

        let newOrigin = NSPoint(x: initialOrigin.x + dx, y: initialOrigin.y + dy)
        window.setFrameOrigin(newOrigin)
    }

    override public func mouseUp(with event: NSEvent) {
        initialMouseLocation = nil
        initialWindowOrigin = nil
    }

    // MARK: - Resize with scroll wheel

    override public func scrollWheel(with event: NSEvent) {
        guard let window = window else { return }
        let delta = event.deltaY * -2
        let currentSize = window.frame.width
        let newSize = min(max(currentSize + delta, 100), 600)
        guard abs(newSize - currentSize) > 0.5 else { return }

        let center = NSPoint(x: window.frame.midX, y: window.frame.midY)
        let newOrigin = NSPoint(x: center.x - newSize / 2, y: center.y - newSize / 2)
        window.setFrame(
            NSRect(x: newOrigin.x, y: newOrigin.y, width: newSize, height: newSize),
            display: true
        )
        frame = NSRect(x: 0, y: 0, width: newSize, height: newSize)
    }
}
