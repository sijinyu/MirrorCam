import AppKit
import AVFoundation
import CoreImage
import UserNotifications

public final class ScreenRecorder {
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var startTime: CMTime?
    private let ciContext = CIContext()

    public private(set) var isRecording = false
    public var onRecordingStateChanged: ((Bool) -> Void)?

    public init() {
        requestNotificationPermission()
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    // MARK: - Screenshot

    public func takeScreenshot(from ciImage: CIImage) {
        let extent = ciImage.extent
        guard let cgImage = ciContext.createCGImage(ciImage, from: extent) else { return }

        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: extent.width, height: extent.height))
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let fileURL = desktopURL.appendingPathComponent("MirrorCam-\(timestamp).png")

        guard let tiffData = nsImage.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else { return }

        do {
            try pngData.write(to: fileURL)
            NSSound(named: "Tink")?.play()
            showSaveNotification(path: fileURL.path)
        } catch {
            // Screenshot save failed silently
        }
    }

    // MARK: - Video Recording

    public func startRecording(width: Int, height: Int) {
        guard !isRecording else { return }

        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let fileURL = desktopURL.appendingPathComponent("MirrorCam-\(timestamp).mp4")

        do {
            let writer = try AVAssetWriter(outputURL: fileURL, fileType: .mp4)

            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: width,
                AVVideoHeightKey: height
            ]
            let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            input.expectsMediaDataInRealTime = true

            let attrs: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height
            ]
            let adaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: input,
                sourcePixelBufferAttributes: attrs
            )

            writer.add(input)
            writer.startWriting()
            writer.startSession(atSourceTime: .zero)

            self.assetWriter = writer
            self.videoInput = input
            self.pixelBufferAdaptor = adaptor
            self.startTime = nil
            self.isRecording = true
            onRecordingStateChanged?(true)
        } catch {
            // Recording start failed
        }
    }

    public func appendFrame(_ ciImage: CIImage) {
        guard isRecording,
              let adaptor = pixelBufferAdaptor,
              let input = videoInput,
              input.isReadyForMoreMediaData else { return }

        let now = CMClockGetTime(CMClockGetHostTimeClock())
        if startTime == nil {
            startTime = now
        }
        let elapsed = CMTimeSubtract(now, startTime!)

        let extent = ciImage.extent
        let width = Int(extent.width)
        let height = Int(extent.height)

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            nil, width, height,
            kCVPixelFormatType_32BGRA,
            nil, &pixelBuffer
        )
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return }

        ciContext.render(ciImage, to: buffer)
        adaptor.append(buffer, withPresentationTime: elapsed)
    }

    public func stopRecording() {
        guard isRecording else { return }
        isRecording = false

        videoInput?.markAsFinished()
        assetWriter?.finishWriting { [weak self] in
            DispatchQueue.main.async {
                self?.onRecordingStateChanged?(false)
                NSSound(named: "Blow")?.play()
            }
        }

        assetWriter = nil
        videoInput = nil
        pixelBufferAdaptor = nil
        startTime = nil
    }

    public func toggleRecording(width: Int, height: Int) {
        if isRecording {
            stopRecording()
        } else {
            startRecording(width: width, height: height)
        }
    }

    private func showSaveNotification(path: String) {
        let content = UNMutableNotificationContent()
        content.title = "MirrorCam"
        content.body = "Screenshot saved to Desktop"

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
