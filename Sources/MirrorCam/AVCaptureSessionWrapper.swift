import AVFoundation

public final class AVCaptureSessionWrapper: CaptureSessionProviding {
    private let session = AVCaptureSession()

    public var isRunning: Bool {
        session.isRunning
    }

    public init() {}

    public func configure(
        delegate: AVCaptureVideoDataOutputSampleBufferDelegate,
        queue: DispatchQueue
    ) throws {
        session.beginConfiguration()

        guard let device = AVCaptureDevice.default(for: .video) else {
            session.commitConfiguration()
            throw CameraError.noDevice
        }

        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else {
            session.commitConfiguration()
            throw CameraError.cannotAddInput
        }
        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(delegate, queue: queue)
        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            throw CameraError.cannotAddOutput
        }
        session.addOutput(output)

        session.commitConfiguration()
    }

    public func startRunning() {
        session.startRunning()
    }

    public func stopRunning() {
        session.stopRunning()
    }
}

public enum CameraError: Error {
    case noDevice
    case cannotAddInput
    case cannotAddOutput
    case notAuthorized
}
