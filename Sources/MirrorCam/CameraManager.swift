import AVFoundation
import Combine
import CoreImage

public final class CameraManager: NSObject, CameraProviding {
    private let authorizer: SystemCameraAuthorizer
    private let sessionProvider: CaptureSessionProviding
    private let frameSubject = PassthroughSubject<CIImage, Never>()
    private let captureQueue = DispatchQueue(label: "com.mirrorcam.capture")

    public var authorizationStatus: CameraAuthorizationStatus {
        authorizer.authorizationStatus()
    }

    public var isRunning: Bool {
        sessionProvider.isRunning
    }

    public var framePublisher: AnyPublisher<CIImage, Never> {
        frameSubject.eraseToAnyPublisher()
    }

    public init(
        authorizer: SystemCameraAuthorizer = AVSystemCameraAuthorizer(),
        sessionProvider: CaptureSessionProviding = AVCaptureSessionWrapper()
    ) {
        self.authorizer = authorizer
        self.sessionProvider = sessionProvider
        super.init()
    }

    public func requestAuthorization() async -> Bool {
        await authorizer.requestAccess()
    }

    public func start() {
        guard authorizationStatus == .authorized else { return }
        guard !isRunning else { return }

        do {
            try sessionProvider.configure(delegate: self, queue: captureQueue)
            sessionProvider.startRunning()
        } catch {
            // Configuration failed — no frame publishing
        }
    }

    public func stop() {
        guard isRunning else { return }
        sessionProvider.stopRunning()
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        frameSubject.send(ciImage)
    }
}
