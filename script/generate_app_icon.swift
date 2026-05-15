import AppKit

let fileManager = FileManager.default
let root = URL(fileURLWithPath: fileManager.currentDirectoryPath)
let sourceImageURL = root.appendingPathComponent("macosPKG.jpg")
let iconSetURL = root
    .appendingPathComponent("PKG Builder")
    .appendingPathComponent("Assets.xcassets")
    .appendingPathComponent("AppIcon.appiconset", isDirectory: true)

let outputs: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

guard let sourceImage = NSImage(contentsOf: sourceImageURL) else {
    fatalError("Could not load \(sourceImageURL.path)")
}

func squareCropRect(for imageSize: NSSize) -> NSRect {
    let side = min(imageSize.width, imageSize.height)
    let x = (imageSize.width - side) / 2
    let y = (imageSize.height - side) / 2
    return NSRect(x: x, y: y, width: side, height: side)
}

func renderedIcon(from sourceImage: NSImage, size: CGFloat) -> NSImage {
    let targetSize = NSSize(width: size, height: size)
    let output = NSImage(size: targetSize)
    output.lockFocus()

    NSColor.clear.setFill()
    NSBezierPath(rect: NSRect(origin: .zero, size: targetSize)).fill()

    let destinationRect = NSRect(origin: .zero, size: targetSize)
    let sourceRect = squareCropRect(for: sourceImage.size)

    sourceImage.draw(
        in: destinationRect,
        from: sourceRect,
        operation: .sourceOver,
        fraction: 1.0,
        respectFlipped: false,
        hints: [
            .interpolation: NSImageInterpolation.high
        ]
    )

    output.unlockFocus()
    return output
}

func pngData(for image: NSImage, size: CGFloat) -> Data? {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size),
        pixelsHigh: Int(size),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )

    guard let rep else { return nil }
    rep.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    guard let context = NSGraphicsContext(bitmapImageRep: rep) else {
        NSGraphicsContext.restoreGraphicsState()
        return nil
    }

    NSGraphicsContext.current = context
    image.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
    NSGraphicsContext.restoreGraphicsState()

    return rep.representation(using: .png, properties: [:])
}

try fileManager.createDirectory(at: iconSetURL, withIntermediateDirectories: true)

for (filename, size) in outputs {
    let rendered = renderedIcon(from: sourceImage, size: size)
    guard let data = pngData(for: rendered, size: size) else {
        fatalError("Failed to encode \(filename)")
    }
    try data.write(to: iconSetURL.appendingPathComponent(filename))
}

print("Generated icon set from \(sourceImageURL.lastPathComponent)")
