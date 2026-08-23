#!/usr/bin/env swift
//
//  Renders Puff's placeholder app icon and the .dmg background image.
//
//      swift scripts/make_art.swift
//
//  Everything here is drawn with AppKit primitives so the art can be regenerated
//  and tweaked without a design tool. The icon is a stand-in with the right
//  palette and silhouette — see ICON_BRIEF.md for the real thing.
//

import AppKit
import Foundation

// MARK: - Palette

let lavender = NSColor(srgbRed: 0xE6/255, green: 0xD7/255, blue: 0xF5/255, alpha: 1)
let blush    = NSColor(srgbRed: 0xFF/255, green: 0xD9/255, blue: 0xE8/255, alpha: 1)
let mint     = NSColor(srgbRed: 0xD3/255, green: 0xF5/255, blue: 0xE3/255, alpha: 1)
let butter   = NSColor(srgbRed: 0xFF/255, green: 0xF3/255, blue: 0xC4/255, alpha: 1)
let inkPlum  = NSColor(srgbRed: 0x5B/255, green: 0x43/255, blue: 0x80/255, alpha: 1)
let mintDeep = NSColor(srgbRed: 0x5F/255, green: 0xBF/255, blue: 0x8E/255, alpha: 1)

// MARK: - Canvas helper

func render(width: Int, height: Int, _ draw: (CGContext, CGSize) -> Void) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: width, pixelsHigh: height,
        bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    )!
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    draw(context.cgContext, CGSize(width: width, height: height))
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func write(_ rep: NSBitmapImageRep, to path: String) {
    guard let data = rep.representation(using: .png, properties: [:]) else { return }
    let url = URL(fileURLWithPath: path)
    try? FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(), withIntermediateDirectories: true
    )
    try? data.write(to: url)
    print("· \(path)")
}

func gradient(_ context: CGContext, colors: [NSColor], from: CGPoint, to: CGPoint) {
    let cgColors = colors.map { $0.usingColorSpace(.sRGB)!.cgColor } as CFArray
    guard let grad = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: cgColors,
        locations: nil
    ) else { return }
    context.drawLinearGradient(grad, start: from, end: to, options: [])
}

// MARK: - App icon

/// Apple's icon grid: the squircle occupies ~80% of the canvas with a ~22% radius.
func drawIcon(_ context: CGContext, size: CGSize) {
    let s = size.width
    let inset = s * 0.085
    let rect = CGRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let radius = rect.width * 0.2237

    // Squircle body
    context.saveGState()
    let body = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    context.addPath(body)
    context.clip()
    gradient(context, colors: [blush, lavender],
             from: CGPoint(x: 0, y: rect.maxY), to: CGPoint(x: 0, y: rect.minY))
    context.restoreGState()

    // Soft top-light, so it reads as glass rather than flat paint. Radial, so it
    // fades out instead of leaving a hard horizon across the middle.
    context.saveGState()
    context.addPath(body)
    context.clip()
    if let glow = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [NSColor.white.withAlphaComponent(0.55).cgColor,
                 NSColor.white.withAlphaComponent(0).cgColor] as CFArray,
        locations: [0, 1]
    ) {
        let center = CGPoint(x: rect.midX, y: rect.maxY - rect.height * 0.06)
        context.drawRadialGradient(glow, startCenter: center, startRadius: 0,
                                   endCenter: center, endRadius: rect.width * 0.72,
                                   options: [])
    }
    context.restoreGState()

    // The blob mascot
    let blobW = rect.width * 0.56
    let blobH = rect.height * 0.50
    let blob = CGRect(x: rect.midX - blobW / 2,
                      y: rect.midY - blobH / 2 + rect.height * 0.03,
                      width: blobW, height: blobH)
    context.setShadow(offset: CGSize(width: 0, height: -s * 0.012),
                      blur: s * 0.03,
                      color: inkPlum.withAlphaComponent(0.18).cgColor)
    context.setFillColor(NSColor.white.withAlphaComponent(0.92).cgColor)
    context.addPath(CGPath(roundedRect: blob,
                           cornerWidth: blobH * 0.46,
                           cornerHeight: blobH * 0.46,
                           transform: nil))
    context.fillPath()
    context.setShadow(offset: .zero, blur: 0, color: nil)

    // Happy squint eyes: ^ ^
    let eyeY = blob.midY + blob.height * 0.10
    let eyeSpan = blob.width * 0.13
    context.setStrokeColor(inkPlum.withAlphaComponent(0.85).cgColor)
    context.setLineWidth(s * 0.022)
    context.setLineCap(.round)
    for dx in [-blob.width * 0.16, blob.width * 0.16] {
        let cx = blob.midX + dx
        context.move(to: CGPoint(x: cx - eyeSpan / 2, y: eyeY))
        context.addQuadCurve(to: CGPoint(x: cx + eyeSpan / 2, y: eyeY),
                             control: CGPoint(x: cx, y: eyeY + eyeSpan * 1.1))
        context.strokePath()
    }

    // Cheeks
    context.setFillColor(NSColor(srgbRed: 1, green: 0.62, blue: 0.77, alpha: 0.55).cgColor)
    for dx in [-blob.width * 0.27, blob.width * 0.27] {
        context.fillEllipse(in: CGRect(x: blob.midX + dx - blob.width * 0.06,
                                       y: eyeY - blob.height * 0.20,
                                       width: blob.width * 0.12,
                                       height: blob.height * 0.075))
    }

    // Mint check badge, bottom-right
    let badgeSize = rect.width * 0.28
    let badge = CGRect(x: rect.maxX - badgeSize * 1.05,
                       y: rect.minY + badgeSize * 0.16,
                       width: badgeSize, height: badgeSize)
    context.setShadow(offset: CGSize(width: 0, height: -s * 0.008),
                      blur: s * 0.02,
                      color: inkPlum.withAlphaComponent(0.20).cgColor)
    context.setFillColor(mint.cgColor)
    context.fillEllipse(in: badge)
    context.setShadow(offset: .zero, blur: 0, color: nil)

    context.setStrokeColor(mintDeep.cgColor)
    context.setLineWidth(badgeSize * 0.13)
    context.move(to: CGPoint(x: badge.minX + badgeSize * 0.27, y: badge.midY + badgeSize * 0.02))
    context.addLine(to: CGPoint(x: badge.minX + badgeSize * 0.44, y: badge.midY - badgeSize * 0.15))
    context.addLine(to: CGPoint(x: badge.minX + badgeSize * 0.74, y: badge.midY + badgeSize * 0.19))
    context.strokePath()
}

// MARK: - DMG background

func drawDMGBackground(_ context: CGContext, size: CGSize) {
    // Pastel wash across the whole window
    gradient(context, colors: [lavender, blush, butter],
             from: CGPoint(x: 0, y: size.height), to: CGPoint(x: size.width, y: 0))

    // Soft bokeh circles for depth
    let circles: [(CGFloat, CGFloat, CGFloat, NSColor)] = [
        (0.14, 0.78, 0.16, mint),
        (0.86, 0.80, 0.10, lavender),
        (0.70, 0.16, 0.13, blush),
        (0.24, 0.18, 0.08, butter)
    ]
    for (x, y, r, color) in circles {
        context.setFillColor(color.withAlphaComponent(0.45).cgColor)
        let radius = size.width * r
        context.fillEllipse(in: CGRect(x: size.width * x - radius / 2,
                                       y: size.height * y - radius / 2,
                                       width: radius, height: radius))
    }

    // Arrow between the two icon wells
    let arrowY = size.height * 0.52
    context.setStrokeColor(inkPlum.withAlphaComponent(0.32).cgColor)
    context.setLineWidth(size.width * 0.008)
    context.setLineCap(.round)
    context.setLineDash(phase: 0, lengths: [size.width * 0.018, size.width * 0.022])
    context.move(to: CGPoint(x: size.width * 0.40, y: arrowY))
    context.addLine(to: CGPoint(x: size.width * 0.60, y: arrowY))
    context.strokePath()
    context.setLineDash(phase: 0, lengths: [])

    let tip = CGPoint(x: size.width * 0.625, y: arrowY)
    let wing = size.width * 0.020
    context.move(to: CGPoint(x: tip.x - wing, y: arrowY + wing))
    context.addLine(to: tip)
    context.addLine(to: CGPoint(x: tip.x - wing, y: arrowY - wing))
    context.strokePath()

    // Copy
    func text(_ string: String, size fontSize: CGFloat, weight: NSFont.Weight,
              alpha: CGFloat, y: CGFloat) {
        let font = NSFont.systemFont(ofSize: fontSize, weight: weight)
        let rounded = NSFont(descriptor: font.fontDescriptor.withDesign(.rounded) ?? font.fontDescriptor,
                             size: fontSize) ?? font
        let attributes: [NSAttributedString.Key: Any] = [
            .font: rounded,
            .foregroundColor: inkPlum.withAlphaComponent(alpha)
        ]
        let attributed = NSAttributedString(string: string, attributes: attributes)
        let bounds = attributed.size()
        attributed.draw(at: CGPoint(x: (size.width - bounds.width) / 2, y: y))
    }

    text("Puff", size: size.width * 0.055, weight: .bold, alpha: 0.85, y: size.height * 0.84)
    text("drag me into Applications", size: size.width * 0.026, weight: .semibold,
         alpha: 0.55, y: size.height * 0.13)
}

// MARK: - Go

let root = FileManager.default.currentDirectoryPath
let iconSet = "\(root)/Puff/Resources/Assets.xcassets/AppIcon.appiconset"

print("Rendering app icon…")
let iconSizes: [(Int, String)] = [
    (16, "icon_16x16.png"), (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"), (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"), (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"), (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"), (1024, "icon_512x512@2x.png")
]
for (pixels, name) in iconSizes {
    write(render(width: pixels, height: pixels, drawIcon), to: "\(iconSet)/\(name)")
}

print("Rendering .dmg background…")
write(render(width: 640, height: 400, drawDMGBackground), to: "\(root)/scripts/dmg/background.png")
write(render(width: 1280, height: 800, drawDMGBackground), to: "\(root)/scripts/dmg/background@2x.png")

print("Done.")