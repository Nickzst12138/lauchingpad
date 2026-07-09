import AppKit

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let size = 1024
let image = NSImage(size: NSSize(width: size, height: size))

image.lockFocus()

let rect = NSRect(x: 0, y: 0, width: size, height: size)
let background = NSBezierPath(roundedRect: rect.insetBy(dx: 28, dy: 28), xRadius: 220, yRadius: 220)
let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.05, green: 0.09, blue: 0.16, alpha: 1),
    NSColor(calibratedRed: 0.12, green: 0.33, blue: 0.54, alpha: 1),
    NSColor(calibratedRed: 0.18, green: 0.78, blue: 0.76, alpha: 1)
])!
gradient.draw(in: background, angle: 315)

NSColor.white.withAlphaComponent(0.24).setStroke()
background.lineWidth = 18
background.stroke()

let glow = NSBezierPath(ovalIn: NSRect(x: 130, y: 584, width: 764, height: 322))
NSColor.white.withAlphaComponent(0.18).setFill()
glow.fill()

let baseGlow = NSBezierPath(ovalIn: NSRect(x: 190, y: 118, width: 644, height: 170))
NSColor(calibratedRed: 0.18, green: 0.92, blue: 1.0, alpha: 0.24).setFill()
baseGlow.fill()

let tileSize: CGFloat = 116
let gap: CGFloat = 54
let startX: CGFloat = 255
let startY: CGFloat = 248
let colors: [NSColor] = [
    NSColor(calibratedRed: 1.00, green: 0.32, blue: 0.38, alpha: 1),
    NSColor(calibratedRed: 1.00, green: 0.78, blue: 0.20, alpha: 1),
    NSColor(calibratedRed: 0.26, green: 0.76, blue: 0.42, alpha: 1),
    NSColor(calibratedRed: 0.25, green: 0.61, blue: 1.00, alpha: 1),
    NSColor(calibratedRed: 0.54, green: 0.42, blue: 1.00, alpha: 1),
    NSColor(calibratedRed: 1.00, green: 0.40, blue: 0.72, alpha: 1),
    NSColor(calibratedRed: 0.18, green: 0.83, blue: 0.78, alpha: 1),
    NSColor(calibratedRed: 0.98, green: 0.53, blue: 0.26, alpha: 1),
    NSColor(calibratedRed: 0.93, green: 0.96, blue: 1.00, alpha: 1)
]

var colorIndex = 0
for row in 0..<3 {
    for column in 0..<3 {
        let x = startX + CGFloat(column) * (tileSize + gap)
        let y = startY + CGFloat(2 - row) * (tileSize + gap)
        let tileRect = NSRect(x: x, y: y, width: tileSize, height: tileSize)
        let shadow = NSShadow()
        shadow.shadowBlurRadius = 20
        shadow.shadowOffset = NSSize(width: 0, height: -10)
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
        shadow.set()

        let tile = NSBezierPath(roundedRect: tileRect, xRadius: 34, yRadius: 34)
        colors[colorIndex].withAlphaComponent((row == 1 && column == 1) ? 0.45 : 0.96).setFill()
        tile.fill()

        NSShadow().set()
        NSColor.white.withAlphaComponent(0.28).setFill()
        let shine = NSBezierPath(roundedRect: NSRect(x: x + 16, y: y + 68, width: 84, height: 24), xRadius: 12, yRadius: 12)
        shine.fill()

        colorIndex += 1
    }
}

let capsule = NSBezierPath(roundedRect: NSRect(x: 332, y: 316, width: 360, height: 392), xRadius: 150, yRadius: 150)
let capsuleGradient = NSGradient(colors: [
    NSColor.white.withAlphaComponent(0.92),
    NSColor(calibratedRed: 0.62, green: 0.96, blue: 1.0, alpha: 0.82),
    NSColor.white.withAlphaComponent(0.56)
])!
let capsuleShadow = NSShadow()
capsuleShadow.shadowBlurRadius = 32
capsuleShadow.shadowOffset = NSSize(width: 0, height: -12)
capsuleShadow.shadowColor = NSColor.black.withAlphaComponent(0.26)
capsuleShadow.set()
capsuleGradient.draw(in: capsule, angle: 90)

NSShadow().set()
NSColor.white.withAlphaComponent(0.78).setStroke()
capsule.lineWidth = 10
capsule.stroke()

let arrow = NSBezierPath()
arrow.move(to: NSPoint(x: 512, y: 640))
arrow.line(to: NSPoint(x: 612, y: 510))
arrow.line(to: NSPoint(x: 548, y: 510))
arrow.line(to: NSPoint(x: 548, y: 390))
arrow.line(to: NSPoint(x: 476, y: 390))
arrow.line(to: NSPoint(x: 476, y: 510))
arrow.line(to: NSPoint(x: 412, y: 510))
arrow.close()
NSColor(calibratedRed: 0.04, green: 0.22, blue: 0.36, alpha: 0.88).setFill()
arrow.fill()

let spark = NSBezierPath(ovalIn: NSRect(x: 478, y: 206, width: 68, height: 68))
NSColor.white.withAlphaComponent(0.88).setFill()
spark.fill()

NSColor(calibratedWhite: 1, alpha: 0.18).setStroke()
let orbit = NSBezierPath()
orbit.move(to: NSPoint(x: 220, y: 758))
orbit.curve(to: NSPoint(x: 822, y: 718), controlPoint1: NSPoint(x: 430, y: 884), controlPoint2: NSPoint(x: 676, y: 854))
orbit.lineWidth = 14
orbit.lineCapStyle = .round
orbit.stroke()

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not render icon")
}

try png.write(to: outputURL)
