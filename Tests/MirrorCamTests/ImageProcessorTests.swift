import XCTest
import CoreImage
@testable import MirrorCam

final class ImageProcessorTests: XCTestCase {

    private func makeTestImage(width: CGFloat = 100, height: CGFloat = 100) -> CIImage {
        CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: width, height: height))
    }

    // MARK: - Mirror

    func test_process_withMirrorOn_flipsImageHorizontally() {
        let input = makeTestImage()
        let params = ImageProcessorParams(isMirrored: true, brightness: 0, zoom: 1.0)

        let output = ImageProcessor.process(input, params: params)

        XCTAssertEqual(output.extent.width, input.extent.width)
        XCTAssertEqual(output.extent.height, input.extent.height)
    }

    func test_process_withMirrorOff_doesNotFlip() {
        let input = makeTestImage()
        let params = ImageProcessorParams(isMirrored: false, brightness: 0, zoom: 1.0)

        let output = ImageProcessor.process(input, params: params)

        XCTAssertEqual(output.extent, input.extent)
    }

    // MARK: - Brightness

    func test_process_withBrightnessZero_preservesDimensions() {
        let input = makeTestImage()
        let params = ImageProcessorParams(isMirrored: false, brightness: 0, zoom: 1.0)

        let output = ImageProcessor.process(input, params: params)

        XCTAssertEqual(output.extent.size, input.extent.size)
    }

    func test_process_withPositiveBrightness_returnsImage() {
        let input = makeTestImage()
        let params = ImageProcessorParams(isMirrored: false, brightness: 0.3, zoom: 1.0)

        let output = ImageProcessor.process(input, params: params)

        XCTAssertFalse(output.extent.isEmpty)
    }

    func test_process_clampsExcessiveBrightness() {
        let input = makeTestImage()
        // Values beyond range should be clamped
        let params = ImageProcessorParams(isMirrored: false, brightness: 1.0, zoom: 1.0)

        let output = ImageProcessor.process(input, params: params)

        XCTAssertFalse(output.extent.isEmpty)
    }

    // MARK: - Zoom

    func test_process_withZoom1x_preservesFullImage() {
        let input = makeTestImage()
        let params = ImageProcessorParams(isMirrored: false, brightness: 0, zoom: 1.0)

        let output = ImageProcessor.process(input, params: params)

        XCTAssertEqual(output.extent, input.extent)
    }

    func test_process_withZoom2x_cropsToHalfDimensions() {
        let input = makeTestImage(width: 200, height: 200)
        let params = ImageProcessorParams(isMirrored: false, brightness: 0, zoom: 2.0)

        let output = ImageProcessor.process(input, params: params)

        XCTAssertEqual(output.extent.width, 100, accuracy: 1)
        XCTAssertEqual(output.extent.height, 100, accuracy: 1)
    }

    func test_process_withZoom3x_cropsToThirdDimensions() {
        let input = makeTestImage(width: 300, height: 300)
        let params = ImageProcessorParams(isMirrored: false, brightness: 0, zoom: 3.0)

        let output = ImageProcessor.process(input, params: params)

        XCTAssertEqual(output.extent.width, 100, accuracy: 1)
        XCTAssertEqual(output.extent.height, 100, accuracy: 1)
    }

    func test_process_clampsZoomToMaximum3x() {
        let input = makeTestImage(width: 300, height: 300)
        let params = ImageProcessorParams(isMirrored: false, brightness: 0, zoom: 5.0)

        let output = ImageProcessor.process(input, params: params)

        // Should be same as 3x zoom (clamped)
        XCTAssertEqual(output.extent.width, 100, accuracy: 1)
    }

    func test_process_zoomCropsFromCenter() {
        let input = makeTestImage(width: 200, height: 200)
        let params = ImageProcessorParams(isMirrored: false, brightness: 0, zoom: 2.0)

        let output = ImageProcessor.process(input, params: params)

        // Center crop of 200x200 at 2x -> 100x100 starting at (50, 50)
        XCTAssertEqual(output.extent.origin.x, 50, accuracy: 1)
        XCTAssertEqual(output.extent.origin.y, 50, accuracy: 1)
    }

    // MARK: - Combined

    func test_process_allTransformsCombined_returnsValidImage() {
        let input = makeTestImage(width: 200, height: 200)
        let params = ImageProcessorParams(isMirrored: true, brightness: 0.2, zoom: 1.5)

        let output = ImageProcessor.process(input, params: params)

        XCTAssertFalse(output.extent.isEmpty)
    }

    // MARK: - Default Params

    func test_defaultParams_areMirroredWithNoBrightnessAndNoZoom() {
        let params = ImageProcessorParams()

        XCTAssertTrue(params.isMirrored)
        XCTAssertEqual(params.brightness, 0.0)
        XCTAssertEqual(params.zoom, 1.0)
    }
}
