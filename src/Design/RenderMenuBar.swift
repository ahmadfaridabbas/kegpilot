// NOTE (2026-10-04): The shipped menu-bar glyph is now a HAND-AUTHORED asset
// (Resources/MenuBarTemplate.png + @2x.png), supplied externally — do NOT run this
// script, as it would OVERWRITE that glyph with the older procedural keg below.
// Kept for reference/history only.
//
// KegPilot menu-bar glyph: a monochrome keg/barrel silhouette with a terminal `>_`
// prompt, drawn as a native template image at 1x and 2x so macOS tints it for
// light/dark menu bars. Mirrors the app icon (keg + `>_`) in a flat, single-color form.
// Run from the project root: swift Design/RenderMenuBar.swift
import AppKit

for scale in [1, 2] {
    let size = 18 * scale
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let transform = NSAffineTransform(); transform.scale(by: CGFloat(scale)); transform.concat()
    NSColor.black.setFill()

    // Keg body: a rounded "cylinder" occupying the central column of the 18pt box.
    // Coordinates in an 18×18 space (origin bottom-left). The barrel is ~11pt wide,
    // ~14pt tall, with rounded top/bottom rims so it reads as a 3D keg.
    let left: CGFloat = 3.6, right: CGFloat = 14.4
    let bodyTop: CGFloat = 14.6, bodyBottom: CGFloat = 2.4
    let rimH: CGFloat = 2.6
    let body = NSBezierPath()
    // Top rim (ellipse top edge) — start at left of the top.
    body.move(to: NSPoint(x: left, y: bodyTop))
    body.curve(to: NSPoint(x: right, y: bodyTop),
               controlPoint1: NSPoint(x: left + 1.6, y: bodyTop + rimH),
               controlPoint2: NSPoint(x: right - 1.6, y: bodyTop + rimH))
    // Right side down to the bottom.
    body.line(to: NSPoint(x: right, y: bodyBottom + 1.1))
    body.curve(to: NSPoint(x: (left + right) / 2, y: bodyBottom),
               controlPoint1: NSPoint(x: right, y: bodyBottom - 0.2),
               controlPoint2: NSPoint(x: right - 1.8, y: bodyBottom))
    body.curve(to: NSPoint(x: left, y: bodyBottom + 1.1),
               controlPoint1: NSPoint(x: left + 1.8, y: bodyBottom),
               controlPoint2: NSPoint(x: left, y: bodyBottom - 0.2))
    body.close()
    body.fill()

    // Fill the top ellipse so the keg lid reads solid.
    let topEllipse = NSBezierPath(ovalIn: NSRect(x: left, y: bodyTop - rimH, width: right - left, height: rimH * 2))
    topEllipse.fill()

    // Cut details through the alpha channel so macOS tints the whole glyph correctly.
    NSGraphicsContext.current!.cgContext.setBlendMode(.clear)

    // Bung hole on the lid (small rounded slot), echoing the icon's top opening.
    let bung = NSBezierPath(roundedRect: NSRect(x: (left + right) / 2 - 1.5, y: bodyTop - 0.2, width: 3.0, height: 1.4),
                            xRadius: 0.7, yRadius: 0.7)
    bung.fill()

    // Two horizontal bands (negative-space rings) separating the three keg sections.
    let bandUpperY: CGFloat = 10.2, bandLowerY: CGFloat = 4.6, bandH: CGFloat = 0.9
    NSBezierPath(rect: NSRect(x: left + 0.3, y: bandUpperY, width: (right - left) - 0.6, height: bandH)).fill()
    NSBezierPath(rect: NSRect(x: left + 0.3, y: bandLowerY, width: (right - left) - 0.6, height: bandH)).fill()

    // Terminal prompt `>_` carved into the middle section.
    let chevron = NSBezierPath()
    chevron.move(to: NSPoint(x: 6.0, y: 9.4))
    chevron.line(to: NSPoint(x: 8.3, y: 7.6))
    chevron.line(to: NSPoint(x: 6.0, y: 5.8))
    chevron.lineWidth = 1.3; chevron.lineCapStyle = .round; chevron.lineJoinStyle = .round
    chevron.stroke()
    let underscore = NSBezierPath()
    underscore.move(to: NSPoint(x: 9.2, y: 5.9))
    underscore.line(to: NSPoint(x: 11.6, y: 5.9))
    underscore.lineWidth = 1.3; underscore.lineCapStyle = .round
    underscore.stroke()

    NSGraphicsContext.restoreGraphicsState()
    let suffix = scale == 2 ? "@2x" : ""
    try! bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "Resources/MenuBarTemplate\(suffix).png"))
}
