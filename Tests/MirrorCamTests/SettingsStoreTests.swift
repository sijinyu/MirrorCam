import XCTest
import Combine
@testable import MirrorCam

final class SettingsStoreTests: XCTestCase {

    private func makeFreshDefaults() -> UserDefaults {
        let suiteName = "com.mirrorcam.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return defaults
    }

    // MARK: - Default Values

    func test_defaults_windowSizeIs200() {
        let sut = SettingsStore(defaults: makeFreshDefaults())
        XCTAssertEqual(sut.windowSize, 200)
    }

    func test_defaults_shapeIsCircle() {
        let sut = SettingsStore(defaults: makeFreshDefaults())
        XCTAssertEqual(sut.shape, .circle)
    }

    func test_defaults_isMirroredIsTrue() {
        let sut = SettingsStore(defaults: makeFreshDefaults())
        XCTAssertTrue(sut.isMirrored)
    }

    func test_defaults_brightnessIsZero() {
        let sut = SettingsStore(defaults: makeFreshDefaults())
        XCTAssertEqual(sut.brightness, 0.0)
    }

    func test_defaults_zoomIsOne() {
        let sut = SettingsStore(defaults: makeFreshDefaults())
        XCTAssertEqual(sut.zoom, 1.0)
    }

    func test_defaults_launchAtLoginIsFalse() {
        let sut = SettingsStore(defaults: makeFreshDefaults())
        XCTAssertFalse(sut.launchAtLogin)
    }

    // MARK: - Persistence Round-Trip

    func test_windowSize_persistsAcrossInstances() {
        let defaults = makeFreshDefaults()
        let store1 = SettingsStore(defaults: defaults)
        store1.windowSize = 350

        let store2 = SettingsStore(defaults: defaults)
        XCTAssertEqual(store2.windowSize, 350)
    }

    func test_shape_persistsAcrossInstances() {
        let defaults = makeFreshDefaults()
        let store1 = SettingsStore(defaults: defaults)
        store1.shape = .roundedRectangle

        let store2 = SettingsStore(defaults: defaults)
        XCTAssertEqual(store2.shape, .roundedRectangle)
    }

    func test_isMirrored_persistsAcrossInstances() {
        let defaults = makeFreshDefaults()
        let store1 = SettingsStore(defaults: defaults)
        store1.isMirrored = false

        let store2 = SettingsStore(defaults: defaults)
        XCTAssertFalse(store2.isMirrored)
    }

    func test_brightness_persistsAcrossInstances() {
        let defaults = makeFreshDefaults()
        let store1 = SettingsStore(defaults: defaults)
        store1.brightness = 0.3

        let store2 = SettingsStore(defaults: defaults)
        XCTAssertEqual(store2.brightness, 0.3, accuracy: 0.001)
    }

    func test_zoom_persistsAcrossInstances() {
        let defaults = makeFreshDefaults()
        let store1 = SettingsStore(defaults: defaults)
        store1.zoom = 2.5

        let store2 = SettingsStore(defaults: defaults)
        XCTAssertEqual(store2.zoom, 2.5, accuracy: 0.001)
    }

    func test_position_persistsAcrossInstances() {
        let defaults = makeFreshDefaults()
        let store1 = SettingsStore(defaults: defaults)
        store1.windowX = 123
        store1.windowY = 456

        let store2 = SettingsStore(defaults: defaults)
        XCTAssertEqual(store2.windowX, 123)
        XCTAssertEqual(store2.windowY, 456)
    }

    // MARK: - Boundary Clamping

    func test_windowSize_clampsToMinimum100() {
        let sut = SettingsStore(defaults: makeFreshDefaults())
        sut.windowSize = 50

        XCTAssertEqual(sut.windowSize, 100)
    }

    func test_windowSize_clampsToMaximum600() {
        let sut = SettingsStore(defaults: makeFreshDefaults())
        sut.windowSize = 800

        XCTAssertEqual(sut.windowSize, 600)
    }

    func test_brightness_clampsToRange() {
        let sut = SettingsStore(defaults: makeFreshDefaults())

        sut.brightness = -1.0
        XCTAssertEqual(sut.brightness, -0.5, accuracy: 0.001)

        sut.brightness = 1.0
        XCTAssertEqual(sut.brightness, 0.5, accuracy: 0.001)
    }

    func test_zoom_clampsToRange() {
        let sut = SettingsStore(defaults: makeFreshDefaults())

        sut.zoom = 0.5
        XCTAssertEqual(sut.zoom, 1.0, accuracy: 0.001)

        sut.zoom = 5.0
        XCTAssertEqual(sut.zoom, 3.0, accuracy: 0.001)
    }
}
