import XCTest
import Combine
import AVFoundation
import CoreImage
@testable import MirrorCam

// MARK: - Mocks

final class MockCameraAuthorizer: SystemCameraAuthorizer {
    private let status: CameraAuthorizationStatus
    private let grantAccess: Bool

    init(status: CameraAuthorizationStatus = .notDetermined, grantAccess: Bool = false) {
        self.status = status
        self.grantAccess = grantAccess
    }

    func authorizationStatus() -> CameraAuthorizationStatus {
        status
    }

    func requestAccess() async -> Bool {
        grantAccess
    }
}

final class MockCaptureSession: CaptureSessionProviding {
    private(set) var isRunning = false
    private(set) var configureCallCount = 0
    var shouldThrowOnConfigure = false

    func configure(delegate: AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue) throws {
        configureCallCount += 1
        if shouldThrowOnConfigure {
            throw CameraError.noDevice
        }
    }

    func startRunning() {
        isRunning = true
    }

    func stopRunning() {
        isRunning = false
    }
}

// MARK: - Tests

final class CameraManagerTests: XCTestCase {

    // MARK: - Authorization Status

    func test_authorizationStatus_returnsNotDetermined_whenSystemNotDetermined() {
        let authorizer = MockCameraAuthorizer(status: .notDetermined)
        let sut = CameraManager(authorizer: authorizer, sessionProvider: MockCaptureSession())

        XCTAssertEqual(sut.authorizationStatus, .notDetermined)
    }

    func test_authorizationStatus_returnsAuthorized_whenSystemAuthorized() {
        let authorizer = MockCameraAuthorizer(status: .authorized)
        let sut = CameraManager(authorizer: authorizer, sessionProvider: MockCaptureSession())

        XCTAssertEqual(sut.authorizationStatus, .authorized)
    }

    func test_authorizationStatus_returnsDenied_whenSystemDenied() {
        let authorizer = MockCameraAuthorizer(status: .denied)
        let sut = CameraManager(authorizer: authorizer, sessionProvider: MockCaptureSession())

        XCTAssertEqual(sut.authorizationStatus, .denied)
    }

    // MARK: - Request Authorization

    func test_requestAuthorization_returnsTrue_whenAccessGranted() async {
        let authorizer = MockCameraAuthorizer(grantAccess: true)
        let sut = CameraManager(authorizer: authorizer, sessionProvider: MockCaptureSession())

        let result = await sut.requestAuthorization()

        XCTAssertTrue(result)
    }

    func test_requestAuthorization_returnsFalse_whenAccessDenied() async {
        let authorizer = MockCameraAuthorizer(grantAccess: false)
        let sut = CameraManager(authorizer: authorizer, sessionProvider: MockCaptureSession())

        let result = await sut.requestAuthorization()

        XCTAssertFalse(result)
    }

    // MARK: - Start / Stop Lifecycle

    func test_start_beginsCapture_whenAuthorized() {
        let session = MockCaptureSession()
        let sut = CameraManager(
            authorizer: MockCameraAuthorizer(status: .authorized),
            sessionProvider: session
        )

        sut.start()

        XCTAssertTrue(session.isRunning)
        XCTAssertEqual(session.configureCallCount, 1)
    }

    func test_start_doesNotBeginCapture_whenNotAuthorized() {
        let session = MockCaptureSession()
        let sut = CameraManager(
            authorizer: MockCameraAuthorizer(status: .denied),
            sessionProvider: session
        )

        sut.start()

        XCTAssertFalse(session.isRunning)
        XCTAssertEqual(session.configureCallCount, 0)
    }

    func test_start_doesNotReconfigure_whenAlreadyRunning() {
        let session = MockCaptureSession()
        let sut = CameraManager(
            authorizer: MockCameraAuthorizer(status: .authorized),
            sessionProvider: session
        )

        sut.start()
        sut.start()

        XCTAssertEqual(session.configureCallCount, 1)
    }

    func test_stop_stopsCapture_whenRunning() {
        let session = MockCaptureSession()
        let sut = CameraManager(
            authorizer: MockCameraAuthorizer(status: .authorized),
            sessionProvider: session
        )

        sut.start()
        sut.stop()

        XCTAssertFalse(session.isRunning)
    }

    func test_stop_isSafe_whenAlreadyStopped() {
        let session = MockCaptureSession()
        let sut = CameraManager(
            authorizer: MockCameraAuthorizer(status: .authorized),
            sessionProvider: session
        )

        sut.stop()

        XCTAssertFalse(session.isRunning)
    }

    func test_start_doesNotCrash_whenConfigureFails() {
        let session = MockCaptureSession()
        session.shouldThrowOnConfigure = true
        let sut = CameraManager(
            authorizer: MockCameraAuthorizer(status: .authorized),
            sessionProvider: session
        )

        sut.start()

        XCTAssertFalse(session.isRunning)
    }

    // MARK: - isRunning

    func test_isRunning_reflectsSessionState() {
        let session = MockCaptureSession()
        let sut = CameraManager(
            authorizer: MockCameraAuthorizer(status: .authorized),
            sessionProvider: session
        )

        XCTAssertFalse(sut.isRunning)
        sut.start()
        XCTAssertTrue(sut.isRunning)
        sut.stop()
        XCTAssertFalse(sut.isRunning)
    }
}
