import AppKit

struct BrandPalette {
    static let midnight = NSColor(calibratedRed: 0.03, green: 0.05, blue: 0.09, alpha: 1)
    static let navy = NSColor(calibratedRed: 0.10, green: 0.14, blue: 0.22, alpha: 1)
    static let navyLift = NSColor(calibratedRed: 0.17, green: 0.20, blue: 0.30, alpha: 1)
    static let gold = NSColor(calibratedRed: 0.86, green: 0.72, blue: 0.43, alpha: 1)
    static let champagne = NSColor(calibratedRed: 0.95, green: 0.88, blue: 0.69, alpha: 1)
    static let ivory = NSColor(calibratedRed: 0.96, green: 0.94, blue: 0.89, alpha: 1)
}

let fileManager = FileManager.default
let root = URL(fileURLWithPath: fileManager.currentDirectoryPath)
let assets = root.appendingPathComponent("FocusFlight/Resources/Assets.xcassets")
let appIcons = assets.appendingPathComponent("AppIcon.appiconset")
let launchBrand = assets.appendingPathComponent("LaunchBrand.imageset")

func imageRep(size: CGFloat, draw: (CGRect) -> Void) -> NSBitmapImageRep {
    let dimensions = NSSize(width: size, height: size)
    let image = NSImage(size: dimensions)
    image.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    draw(CGRect(origin: .zero, size: dimensions))
    image.unlockFocus()

    guard let rep = NSBitmapImageRep(data: image.tiffRepresentation ?? Data()) else {
        fatalError("Unable to create bitmap image")
    }

    rep.size = dimensions
    return rep
}

func savePNG(_ rep: NSBitmapImageRep, to url: URL) throws {
    guard let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("Unable to encode PNG")
    }
    try data.write(to: url)
}

func drawRoundedBackground(in rect: CGRect) {
    let inset = rect.width * 0.02
    let roundedRect = NSBezierPath(
        roundedRect: rect.insetBy(dx: inset, dy: inset),
        xRadius: rect.width * 0.22,
        yRadius: rect.width * 0.22
    )
    let gradient = NSGradient(colors: [BrandPalette.navyLift, BrandPalette.navy, BrandPalette.midnight])!
    gradient.draw(in: roundedRect, angle: -45)

    NSColor.white.withAlphaComponent(0.08).setStroke()
    roundedRect.lineWidth = rect.width * 0.008
    roundedRect.stroke()
}

func drawMark(in rect: CGRect, transparent: Bool) {
    if !transparent {
        drawRoundedBackground(in: rect)
    }

    let inset = rect.width * (transparent ? 0.22 : 0.18)
    let markRect = rect.insetBy(dx: inset, dy: inset)
    let center = CGPoint(x: markRect.midX, y: markRect.midY)
    let radius = markRect.width * 0.36

    let routeArc = NSBezierPath()
    routeArc.lineWidth = markRect.width * 0.054
    routeArc.appendArc(withCenter: center, radius: radius, startAngle: 26, endAngle: 331)
    BrandPalette.champagne.withAlphaComponent(0.92).setStroke()
    routeArc.stroke()

    let wing = NSBezierPath()
    wing.lineWidth = markRect.width * 0.075
    wing.lineCapStyle = .round
    wing.lineJoinStyle = .round
    wing.move(to: CGPoint(x: markRect.minX + markRect.width * 0.18, y: center.y + markRect.height * 0.12))
    wing.curve(
        to: CGPoint(x: markRect.minX + markRect.width * 0.50, y: center.y - markRect.height * 0.10),
        controlPoint1: CGPoint(x: markRect.minX + markRect.width * 0.28, y: center.y + markRect.height * 0.28),
        controlPoint2: CGPoint(x: markRect.minX + markRect.width * 0.36, y: center.y - markRect.height * 0.18)
    )
    wing.curve(
        to: CGPoint(x: markRect.minX + markRect.width * 0.82, y: center.y + markRect.height * 0.05),
        controlPoint1: CGPoint(x: markRect.minX + markRect.width * 0.61, y: center.y - markRect.height * 0.03),
        controlPoint2: CGPoint(x: markRect.minX + markRect.width * 0.72, y: center.y + markRect.height * 0.18)
    )
    BrandPalette.gold.setStroke()
    wing.stroke()

    let destinationSize = markRect.width * 0.11
    let destinationRect = CGRect(
        x: markRect.maxX - destinationSize * 1.15,
        y: center.y - destinationSize * 0.55,
        width: destinationSize,
        height: destinationSize
    )
    let destination = NSBezierPath(ovalIn: destinationRect)
    BrandPalette.ivory.setFill()
    destination.fill()

    let glow = NSBezierPath(ovalIn: destinationRect.insetBy(dx: -destinationSize * 0.45, dy: -destinationSize * 0.45))
    BrandPalette.gold.withAlphaComponent(0.18).setFill()
    glow.fill()
}

let appIconSizes: [(String, CGFloat)] = [
    ("AppIcon-20@2x.png", 40),
    ("AppIcon-20@3x.png", 60),
    ("AppIcon-29@2x.png", 58),
    ("AppIcon-29@3x.png", 87),
    ("AppIcon-40@2x.png", 80),
    ("AppIcon-40@3x.png", 120),
    ("AppIcon-60@2x.png", 120),
    ("AppIcon-60@3x.png", 180),
    ("AppIcon-1024.png", 1024),
]

for (name, size) in appIconSizes {
    try savePNG(imageRep(size: size) { rect in
        drawMark(in: rect, transparent: false)
    }, to: appIcons.appendingPathComponent(name))
}

let launchSizes: [(String, CGFloat)] = [
    ("LaunchBrand.png", 512),
    ("LaunchBrand@2x.png", 1024),
    ("LaunchBrand@3x.png", 1536),
]

for (name, size) in launchSizes {
    try savePNG(imageRep(size: size) { rect in
        NSColor.clear.setFill()
        rect.fill()
        drawMark(in: rect, transparent: true)
    }, to: launchBrand.appendingPathComponent(name))
}
