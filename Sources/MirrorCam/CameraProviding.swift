import AVFoundation
import Combine
import CoreImage

public enum CameraAuthorizationStatus: Equatable {
    case notDetermined
    case authorized
    case denied
    case restricted
}

public protocol CameraProviding {
    var authorizationStatus: CameraAuthorizationStatus { get }
    var isRunning: Bool { get }
    var framePublisher: AnyPublisher<CIImage, Never> { get }
    func requestAuthorization() async -> Bool
    func start()
    func stop()
}

// MARK: - System abstraction for testability

public protocol SystemCameraAuthorizer {
    func authorizationStatus() -> CameraAuthorizationStatus
    func requestAccess() async -> Bool
}

public protocol CaptureSessionProviding {
    var isRunning: Bool { get }
    func configure(delegate: AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue) throws
    func startRunning()
    func stopRunning()
}
