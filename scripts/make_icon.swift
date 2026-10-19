import AppKit
import Foundation

// Original vector artwork. Render all standard macOS icon sizes without external dependencies.
let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
func render(pixels: Int) -> Data {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                                  bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                  isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let context = NSGraphicsContext.current!.cgContext
    context.scaleBy(x: CGFloat(pixels) / 1024, y: CGFloat(pixels) / 1024)

    let tile = NSBezierPath(roundedRect: NSRect(x: 82, y: 82, width: 860, height: 860), xRadius: 192, yRadius: 192)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.20)
    shadow.shadowOffset = NSSize(width: 0, height: -15)
    shadow.shadowBlurRadius = 30
    shadow.set()
    NSColor(srgbRed: 0.96, green: 0.94, blue: 0.90, alpha: 1).setFill()
    tile.fill()
    NSGraphicsContext.restoreGraphicsState()
    NSGradient(starting: NSColor(srgbRed: 1, green: 0.99, blue: 0.96, alpha: 1), ending: NSColor(srgbRed: 0.87, green: 0.87, blue: 0.83, alpha: 1))!.draw(in: tile, angle: -90)
    NSColor.white.withAlphaComponent(0.85).setStroke()
    tile.lineWidth = 3
    tile.stroke()

    let inset = NSBezierPath(roundedRect: NSRect(x: 220, y: 210, width: 584, height: 608), xRadius: 100, yRadius: 100)
    NSGradient(starting: NSColor(srgbRed: 0.79, green: 0.30, blue: 0.23, alpha: 1), ending: NSColor(srgbRed: 0.57, green: 0.16, blue: 0.13, alpha: 1))!.draw(in: inset, angle: -90)
    let ink = NSColor(srgbRed: 1, green: 0.95, blue: 0.86, alpha: 1)
    ink.withAlphaComponent(0.82).setStroke()
    for x: CGFloat in [362, 662] {
        let binding = NSBezierPath()
        binding.move(to: NSPoint(x: x, y: 777))
        binding.line(to: NSPoint(x: x, y: 846))
        binding.lineWidth = 26
        binding.lineCapStyle = .round
        binding.stroke()
    }
    let sun = NSBezierPath()
    sun.appendArc(withCenter: NSPoint(x: 512, y: 480), radius: 129, startAngle: 0, endAngle: 180)
    sun.lineWidth = 29
    sun.lineCapStyle = .round
    ink.setStroke()
    sun.stroke()
    for (y, left, right): (CGFloat, CGFloat, CGFloat) in [(480, 328, 696), (386, 405, 619)] {
        let horizon = NSBezierPath()
        horizon.move(to: NSPoint(x: left, y: y))
        horizon.line(to: NSPoint(x: right, y: y))
        horizon.lineWidth = 27
        horizon.lineCapStyle = .round
        horizon.stroke()
    }
    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using: .png, properties: [:])!
}
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "icon_\(size)x\(size)\(scale == 2 ? "@2x" : "").png"
        try render(pixels: size * scale).write(to: output.appendingPathComponent(name))
    }
}
