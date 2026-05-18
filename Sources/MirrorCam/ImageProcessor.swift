import CoreImage

public struct ImageProcessorParams: Equatable {
    public let isMirrored: Bool
    public let brightness: Double
    public let zoom: Double

    public init(isMirrored: Bool = true, brightness: Double = 0.0, zoom: Double = 1.0) {
        self.isMirrored = isMirrored
        self.brightness = brightness
        self.zoom = zoom
    }
}

public enum ImageProcessor {

    public static func process(_ image: CIImage, params: ImageProcessorParams) -> CIImage {
        var result = image

        if params.isMirrored {
            result = mirror(result)
        }

        if params.brightness != 0.0 {
            result = adjustBrightness(result, amount: params.brightness)
        }

        if params.zoom > 1.0 {
            result = applyZoom(result, factor: params.zoom)
        }

        return result
    }

    static func mirror(_ image: CIImage) -> CIImage {
        image.transformed(by: CGAffineTransform(scaleX: -1, y: 1)
            .translatedBy(x: -image.extent.width, y: 0))
    }

    static func adjustBrightness(_ image: CIImage, amount: Double) -> CIImage {
        let clampedAmount = min(max(amount, -0.5), 0.5)
        guard let filter = CIFilter(name: "CIColorControls") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(NSNumber(value: clampedAmount), forKey: kCIInputBrightnessKey)
        return filter.outputImage ?? image
    }

    static func applyZoom(_ image: CIImage, factor: Double) -> CIImage {
        let clampedFactor = min(max(factor, 1.0), 3.0)
        let extent = image.extent
        let newWidth = extent.width / clampedFactor
        let newHeight = extent.height / clampedFactor
        let originX = extent.origin.x + (extent.width - newWidth) / 2
        let originY = extent.origin.y + (extent.height - newHeight) / 2
        let cropRect = CGRect(x: originX, y: originY, width: newWidth, height: newHeight)
        return image.cropped(to: cropRect)
    }
}
