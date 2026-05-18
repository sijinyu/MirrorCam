#!/usr/bin/env swift
import AppKit

let size = 1024
let nsSize = NSSize(width: size, height: size)
let image = NSImage(size: nsSize)

image.lockFocus()

// Background: gradient circle
let rect = NSRect(origin: .zero, size: nsSize)
let circlePath = NSBezierPath(ovalIn: rect.insetBy(dx: 20, dy: 20))

// Dark blue-purple gradient background
let gradient = NSGradient(
    colors: [
        NSColor(red: 0.15, green: 0.15, blue: 0.35, alpha: 1.0),
        NSColor(red: 0.25, green: 0.20, blue: 0.55, alpha: 1.0),
        NSColor(red: 0.10, green: 0.10, blue: 0.25, alpha: 1.0)
    ],
    atLocations: [0.0, 0.5, 1.0],
    colorSpace: .deviceRGB
)!
gradient.draw(in: circlePath, angle: -45)

// Subtle inner shadow / ring
let ringPath = NSBezierPath(ovalIn: rect.insetBy(dx: 40, dy: 40))
NSColor(white: 1.0, alpha: 0.08).setStroke()
ringPath.lineWidth = 3
ringPath.stroke()

// Camera icon using SF Symbol
if let cameraSymbol = NSImage(systemSymbolName: "camera.fill", accessibilityDescription: nil) {
    let config = NSImage.SymbolConfiguration(pointSize: 320, weight: .medium)
    let configured = cameraSymbol.withSymbolConfiguration(config)!

    let symbolSize = configured.size
    let x = (CGFloat(size) - symbolSize.width) / 2
    let y = (CGFloat(size) - symbolSize.height) / 2 + 20

    NSColor.white.withAlphaComponent(0.95).set()
    let symbolRect = NSRect(x: x, y: y, width: symbolSize.width, height: symbolSize.height)
    configured.draw(in: symbolRect, from: .zero, operation: .sourceOver, fraction: 0.95)
}

// Small mirror reflection accent (top-right)
let accentPath = NSBezierPath(ovalIn: NSRect(x: 620, y: 680, width: 160, height: 160))
NSColor(white: 1.0, alpha: 0.06).setFill()
accentPath.fill()

image.unlockFocus()

// Save as PNG
guard let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    print("ERROR: Failed to create PNG")
    exit(1)
}

let outputDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().deletingLastPathComponent()
let iconsetDir = outputDir.appendingPathComponent(".build-icon.iconset")

// Create iconset directory
try? FileManager.default.removeItem(at: iconsetDir)
try! FileManager.default.createDirectory(at: iconsetDir, withIntermediateDirectories: true)

// Generate all required sizes
let sizes: [(String, Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

for (name, px) in sizes {
    let resized = NSImage(size: NSSize(width: px, height: px))
    resized.lockFocus()
    image.draw(in: NSRect(x: 0, y: 0, width: px, height: px),
               from: NSRect(origin: .zero, size: nsSize),
               operation: .copy, fraction: 1.0)
    resized.unlockFocus()

    guard let tiff = resized.tiffRepresentation,
          let bmp = NSBitmapImageRep(data: tiff),
          let png = bmp.representation(using: .png, properties: [:]) else {
        print("ERROR: Failed to resize to \(px)")
        exit(1)
    }
    let filePath = iconsetDir.appendingPathComponent("\(name).png")
    try! png.write(to: filePath)
}

print("Iconset created at: \(iconsetDir.path)")
print("Run: iconutil -c icns \(iconsetDir.path) -o Resources/AppIcon.icns")
