import Foundation
import Combine

public protocol SettingsStoring {
    var windowX: Double { get set }
    var windowY: Double { get set }
    var windowSize: Double { get set }
    var shape: WindowShape { get set }
    var isMirrored: Bool { get set }
    var brightness: Double { get set }
    var zoom: Double { get set }
    var launchAtLogin: Bool { get set }
}

public final class SettingsStore: ObservableObject, SettingsStoring {
    private let defaults: UserDefaults

    private enum Keys {
        static let windowX = "windowX"
        static let windowY = "windowY"
        static let windowSize = "windowSize"
        static let shape = "shape"
        static let isMirrored = "isMirrored"
        static let brightness = "brightness"
        static let zoom = "zoom"
        static let launchAtLogin = "launchAtLogin"
    }

    @Published public var windowX: Double {
        didSet { defaults.set(windowX, forKey: Keys.windowX) }
    }

    @Published public var windowY: Double {
        didSet { defaults.set(windowY, forKey: Keys.windowY) }
    }

    @Published public var windowSize: Double {
        didSet {
            let clamped = min(max(windowSize, 100), 600)
            if clamped != windowSize { windowSize = clamped; return }
            defaults.set(windowSize, forKey: Keys.windowSize)
        }
    }

    @Published public var shape: WindowShape {
        didSet { defaults.set(shape.rawValue, forKey: Keys.shape) }
    }

    @Published public var isMirrored: Bool {
        didSet { defaults.set(isMirrored, forKey: Keys.isMirrored) }
    }

    @Published public var brightness: Double {
        didSet {
            let clamped = min(max(brightness, -0.5), 0.5)
            if clamped != brightness { brightness = clamped; return }
            defaults.set(brightness, forKey: Keys.brightness)
        }
    }

    @Published public var zoom: Double {
        didSet {
            let clamped = min(max(zoom, 1.0), 3.0)
            if clamped != zoom { zoom = clamped; return }
            defaults.set(zoom, forKey: Keys.zoom)
        }
    }

    @Published public var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: Keys.launchAtLogin) }
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        self.windowX = defaults.object(forKey: Keys.windowX) as? Double
            ?? Double(NSScreen.main?.frame.midX ?? 500) - 100
        self.windowY = defaults.object(forKey: Keys.windowY) as? Double
            ?? Double(NSScreen.main?.frame.midY ?? 400) - 100
        self.windowSize = defaults.object(forKey: Keys.windowSize) as? Double ?? 200
        self.isMirrored = defaults.object(forKey: Keys.isMirrored) as? Bool ?? true
        self.brightness = defaults.object(forKey: Keys.brightness) as? Double ?? 0.0
        self.zoom = defaults.object(forKey: Keys.zoom) as? Double ?? 1.0
        self.launchAtLogin = defaults.object(forKey: Keys.launchAtLogin) as? Bool ?? false

        let shapeRaw = defaults.string(forKey: Keys.shape) ?? WindowShape.circle.rawValue
        self.shape = WindowShape(rawValue: shapeRaw) ?? .circle
    }
}

import AppKit
