#!/usr/bin/env swift
//
// Turn one square illustration into the ten PNGs macOS wants for an app icon.
//
//   swift scripts/make_app_icon.swift ~/Downloads/icon-source.png
//
// The source is expected to be square and full-bleed. It is *not* used as-is:
// macOS does not round or inset app icons for you, so a full-bleed square would
// sit in the Dock as a hard-edged tile next to everything else's squircle. This
// insets the artwork to Apple's 824-in-1024 grid and clips it to a continuous
// rounded rectangle — the same superellipse the system uses — then renders every
// size the catalog asks for.

import AppKit
import SwiftUI

// Apple's macOS icon grid: a 1024 canvas holding 824 of artwork.
let canvas: CGFloat = 1024
let art: CGFloat = 824
let corner: CGFloat = 185.4

guard CommandLine.arguments.count > 1 else {
    print("usage: swift scripts/make_app_icon.swift <source.png>")
    exit(1)
}
let sourcePath = CommandLine.arguments[1]

guard let source = NSImage(contentsOfFile: sourcePath),
      let sourceCG = source.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    print("✗ could not read \(sourcePath)")
    exit(1)
}

if sourceCG.width != sourceCG.height {
    print("  ⚠ source is \(sourceCG.width)×\(sourceCG.height), not square — it will be centre-cropped")
}

/// The rounded square the artwork lives inside, in canvas coordinates.
let artRect = CGRect(x: (canvas - art) / 2, y: (canvas - art) / 2, width: art, height: art)
let maskPath = Path(roundedRect: artRect, cornerRadius: corner, style: .continuous).cgPath

/// Centre-crop the source to a square, so a slightly-off aspect doesn't squash it.
let side = min(sourceCG.width, sourceCG.height)
let cropped = sourceCG.cropping(to: CGRect(
    x: (sourceCG.width - side) / 2,
    y: (sourceCG.height - side) / 2,
    width: side, height: side
)) ?? sourceCG

func renderCanvas() -> CGImage? {
    guard let ctx = CGContext(data: nil, width: Int(canvas), height: Int(canvas),
                              bitsPerComponent: 8, bytesPerRow: 0,
                              space: CGColorSpaceCreateDeviceRGB(),
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
    ctx.interpolationQuality = .high

    // A soft shadow under the tile, which is what stops a flat icon looking
    // pasted on next to the system's own.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10),
                  blur: 24,
                  color: NSColor.black.withAlphaComponent(0.28).cgColor)
    ctx.addPath(maskPath)
    ctx.setFillColor(NSColor.black.cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(maskPath)
    ctx.clip()
    ctx.draw(cropped, in: artRect)
    ctx.restoreGState()

    return ctx.makeImage()
}

guard let full = renderCanvas() else {
    print("✗ could not render the icon canvas")
    exit(1)
}

func write(_ image: CGImage, side: Int, to url: URL) {
    guard let ctx = CGContext(data: nil, width: side, height: side,
                              bitsPerComponent: 8, bytesPerRow: 0,
                              space: CGColorSpaceCreateDeviceRGB(),
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return }
    ctx.interpolationQuality = .high
    ctx.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
    guard let scaled = ctx.makeImage(),
          let data = NSBitmapImageRep(cgImage: scaled).representation(using: .png, properties: [:])
    else { return }
    try? data.write(to: url)
}

let iconSet = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("LittleVetClinic/Resources/Assets.xcassets/AppIcon.appiconset")

let sizes: [(String, Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024)
]

for (name, side) in sizes {
    write(full, side: side, to: iconSet.appendingPathComponent("\(name).png"))
}

print("  icon  \(sizes.count) sizes from \(sourceCG.width)×\(sourceCG.height) → \(iconSet.lastPathComponent)")
