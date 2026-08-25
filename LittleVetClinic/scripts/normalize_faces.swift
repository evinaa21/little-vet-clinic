#!/usr/bin/env swift
//
// Normalise the illustrated faces and install them into the asset catalog.
//
//   swift scripts/normalize_faces.swift [source-folder] [--fill 0.94]
//
// Illustrations arrive cropped to their own artwork, so no two share a canvas
// size or an aspect ratio — a 709×619 sleepy bunny and a 692×677 cat would land
// in the badge at visibly different scales. This trims each one to its actual
// alpha bounds, scales it so its longest side is a fixed fraction of the canvas,
// and centres it on a square transparent 256×256 sheet. After this every face
// occupies the same box, so the row of pastel discs reads as one set.
//
// Called by scripts/import_faces.sh — run that instead unless you're tuning.

import AppKit
import Foundation

let args = Array(CommandLine.arguments.dropFirst())
var sourcePath = FileManager.default.currentDirectoryPath + "/ArtDrop"
var fill: CGFloat = 0.94          // how much of the canvas the longest side spans
let canvas = 256

var index = 0
while index < args.count {
    switch args[index] {
    case "--fill":
        index += 1
        if index < args.count, let value = Double(args[index]) { fill = CGFloat(value) }
    default:
        sourcePath = args[index]
    }
    index += 1
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let source = URL(fileURLWithPath: sourcePath)
let catalog = root.appendingPathComponent("LittleVetClinic/Resources/Assets.xcassets/AnimalFaces")

/// Alpha is soft at the edges of these illustrations, so anything under this is
/// treated as background rather than artwork.
let alphaFloor: UInt8 = 16

func pixels(_ image: CGImage) -> ([UInt8], Int, Int) {
    let w = image.width, h = image.height
    var data = [UInt8](repeating: 0, count: w * h * 4)
    data.withUnsafeMutableBytes { buffer in
        let ctx = CGContext(data: buffer.baseAddress, width: w, height: h,
                            bitsPerComponent: 8, bytesPerRow: w * 4,
                            space: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        ctx?.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
    }
    return (data, w, h)
}

/// The artwork's true bounds, ignoring the transparent margin around it.
func alphaBounds(_ image: CGImage) -> CGRect? {
    let (data, w, h) = pixels(image)
    var minX = w, maxX = -1, minY = h, maxY = -1
    for y in 0..<h {
        let row = y * w
        for x in 0..<w where data[(row + x) * 4 + 3] > alphaFloor {
            if x < minX { minX = x }
            if x > maxX { maxX = x }
            if y < minY { minY = y }
            if y > maxY { maxY = y }
        }
    }
    guard maxX >= minX, maxY >= minY else { return nil }
    return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
}

var installed = 0
var missing: [String] = []

for animal in ["dog", "cat", "bunny"] {
    for mood in ["waiting", "seen", "celebrating"] {
        let name = "\(animal)_\(mood)"
        let file = source.appendingPathComponent("\(name).png")

        guard FileManager.default.fileExists(atPath: file.path) else {
            missing.append("\(name).png")
            continue
        }
        guard let nsImage = NSImage(contentsOf: file),
              let cg = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("  ✗ \(name).png — not a readable image, skipped")
            continue
        }
        guard let bounds = alphaBounds(cg) else {
            print("  ✗ \(name).png — fully transparent, skipped")
            continue
        }

        let scale = CGFloat(canvas) * fill / max(bounds.width, bounds.height)

        guard let out = CGContext(data: nil, width: canvas, height: canvas,
                                  bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { continue }
        out.interpolationQuality = .high

        // Place the artwork so its alpha bounds — not its original canvas — land
        // dead centre. The source's own padding is discarded entirely.
        let drawWidth = CGFloat(cg.width) * scale
        let drawHeight = CGFloat(cg.height) * scale
        let originX = CGFloat(canvas) / 2 - (bounds.midX * scale)
        // Core Graphics counts y upward; alphaBounds came from a top-down raster.
        let flippedMidY = CGFloat(cg.height) - bounds.midY
        let originY = CGFloat(canvas) / 2 - (flippedMidY * scale)
        out.draw(cg, in: CGRect(x: originX, y: originY, width: drawWidth, height: drawHeight))

        guard let rendered = out.makeImage() else { continue }
        let rep = NSBitmapImageRep(cgImage: rendered)
        guard let png = rep.representation(using: .png, properties: [:]) else { continue }

        let destination = catalog
            .appendingPathComponent("\(name).imageset")
            .appendingPathComponent("\(name).png")
        try? png.write(to: destination)
        installed += 1

        print(String(format: "  ✓ %-24s %4d×%-4d → 256×256  (art %d×%d, ×%.3f)",
                     ("\(name).png" as NSString).utf8String!,
                     cg.width, cg.height,
                     Int(bounds.width), Int(bounds.height), Double(scale)))
    }
}

print("")
print("  normalised \(installed) of 9 at fill \(fill)")
if !missing.isEmpty {
    print("  still using placeholders for: \(missing.joined(separator: " "))")
}
