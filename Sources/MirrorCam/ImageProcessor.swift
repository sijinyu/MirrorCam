import CoreImage

public struct ImageProcessorParams: Equatable {
    public let isMirrored: Bool
    public let brightness: Double
    public let zoom: Double
    public let mirrorEffect: MirrorEffect
    public let colorFilter: ColorFilter

    public init(
        isMirrored: Bool = true,
        brightness: Double = 0.0,
        zoom: Double = 1.0,
        mirrorEffect: MirrorEffect = .flat,
        colorFilter: ColorFilter = .none
    ) {
        self.isMirrored = isMirrored
        self.brightness = brightness
        self.zoom = zoom
        self.mirrorEffect = mirrorEffect
        self.colorFilter = colorFilter
    }
}

public enum ImageProcessor {

    public static func process(_ image: CIImage, params: ImageProcessorParams) -> CIImage {
        var result = image

        if params.isMirrored {
            result = mirror(result)
        }

        if params.mirrorEffect != .flat {
            result = applyMirrorEffect(result, effect: params.mirrorEffect)
        }

        if params.brightness != 0.0 {
            result = adjustBrightness(result, amount: params.brightness)
        }

        if params.colorFilter != .none {
            result = applyColorFilter(result, filter: params.colorFilter)
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

    // MARK: - Mirror Effects (Convex / Concave)

    static func applyMirrorEffect(_ image: CIImage, effect: MirrorEffect) -> CIImage {
        let extent = image.extent
        let center = CIVector(x: extent.midX, y: extent.midY)
        let radius = min(extent.width, extent.height) * 0.45

        guard let filter = CIFilter(name: "CIBumpDistortion") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(center, forKey: kCIInputCenterKey)
        filter.setValue(NSNumber(value: radius), forKey: kCIInputRadiusKey)

        switch effect {
        case .convex:
            // Positive scale = bump outward (convex mirror)
            filter.setValue(NSNumber(value: 0.5), forKey: kCIInputScaleKey)
        case .concave:
            // Negative scale = dip inward (concave mirror)
            filter.setValue(NSNumber(value: -0.5), forKey: kCIInputScaleKey)
        case .flat:
            return image
        }

        guard let output = filter.outputImage else { return image }
        return output.cropped(to: extent)
    }

    // MARK: - Color Filters

    static func applyColorFilter(_ image: CIImage, filter colorFilter: ColorFilter) -> CIImage {
        switch colorFilter {
        case .none:
            return image
        case .grayscale:
            return applyGrayscale(image)
        case .sepia:
            return applySepia(image)
        }
    }

    private static func applyGrayscale(_ image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIColorControls") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(NSNumber(value: 0.0), forKey: kCIInputSaturationKey)
        return filter.outputImage ?? image
    }

    private static func applySepia(_ image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CISepiaTone") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(NSNumber(value: 0.8), forKey: kCIInputIntensityKey)
        return filter.outputImage ?? image
    }
}
