#!/usr/bin/env swift
//
// Renders every image the project needs so it builds and runs before any AI art
// exists:
//
//   • nine placeholder animal faces (256×256, transparent) into the asset catalog
//   • the app icon, at all ten macOS sizes
//   • the .dmg background
//
// Run from the project root:  swift scripts/make_art.swift
//
// The faces are deliberately plain — flat shapes in the clinic palette. They exist
// so the layout is real while the illustrated set is being generated, and
// scripts/import_faces.sh overwrites them the moment the real art arrives.

import AppKit
import Foundation

// ---------------------------------------------------------------- palette

func rgb(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1)
}

let outline  = rgb(0x4A4038)
let eyeInk   = rgb(0x3E3630)
let blush    = rgb(0xF2AEBB)
let pink     = rgb(0xF0BCC8)
let paper    = rgb(0xFBF8F2)
let clipGrey = rgb(0xC7C3BC)
let clipPink = rgb(0xF6C9D4)
let rule     = rgb(0xD9D2C4)

struct Fur {
    let body: NSColor
    let shade: NSColor
    let muzzle: NSColor
}

let furs: [String: Fur] = [
    "dog":   Fur(body: rgb(0xE9C79E), shade: rgb(0xD3A97C), muzzle: rgb(0xF7E7D2)),
    "cat":   Fur(body: rgb(0xD9D4CC), shade: rgb(0xC3BDB3), muzzle: rgb(0xEFEBE4)),
    "bunny": Fur(body: rgb(0xF4E9DF), shade: rgb(0xE2D3C5), muzzle: rgb(0xFFFBF6))
]

// ---------------------------------------------------------------- canvas

func render(width: Int, height: Int, to url: URL, _ body: () -> Void) {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ), let ctx = NSGraphicsContext(bitmapImageRep: rep) else { return }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx
    ctx.imageInterpolation = .high
    body()
    ctx.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    try? FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    if let data = rep.representation(using: .png, properties: [:]) {
        try? data.write(to: url)
    }
}

// ---------------------------------------------------------------- drawing helpers

func oval(_ cx: CGFloat, _ cy: CGFloat, _ w: CGFloat, _ h: CGFloat) -> NSBezierPath {
    NSBezierPath(ovalIn: NSRect(x: cx - w / 2, y: cy - h / 2, width: w, height: h))
}

func rotated(_ path: NSBezierPath, degrees: CGFloat, around point: CGPoint) -> NSBezierPath {
    let t = NSAffineTransform()
    t.translateX(by: point.x, yBy: point.y)
    t.rotate(byDegrees: degrees)
    t.translateX(by: -point.x, yBy: -point.y)
    let copy = path.copy() as! NSBezierPath
    copy.transform(using: t as AffineTransform)
    return copy
}

func triangle(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> NSBezierPath {
    let p = NSBezierPath()
    p.move(to: a); p.line(to: b); p.line(to: c); p.close()
    return p
}

/// A single curved stroke — eyes, smiles, whiskers. Positive bulge arcs upward.
func arc(from a: CGPoint, to b: CGPoint, bulge: CGFloat) -> NSBezierPath {
    let p = NSBezierPath()
    p.move(to: a)
    let lift = bulge * 1.34
    p.curve(to: b,
            controlPoint1: CGPoint(x: a.x + (b.x - a.x) * 0.28, y: a.y + lift),
            controlPoint2: CGPoint(x: a.x + (b.x - a.x) * 0.72, y: b.y + lift))
    return p
}

func fill(_ path: NSBezierPath, _ color: NSColor, outlined: Bool = true, width: CGFloat = 5) {
    color.setFill()
    path.fill()
    if outlined {
        outline.setStroke()
        path.lineWidth = width
        path.stroke()
    }
}

func stroke(_ path: NSBezierPath, _ color: NSColor, _ width: CGFloat) {
    color.setStroke()
    path.lineWidth = width
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    path.stroke()
}

// ---------------------------------------------------------------- faces

let headCenter = CGPoint(x: 128, y: 116)
let headRadius: CGFloat = 74

func drawEars(_ animal: String, fur: Fur) {
    switch animal {
    case "dog":
        for side in [-1.0, 1.0] as [CGFloat] {
            let ear = oval(headCenter.x + 66 * side, headCenter.y - 6, 46, 96)
            fill(rotated(ear, degrees: 12 * side, around: headCenter), fur.shade)
        }
    case "cat":
        for side in [-1.0, 1.0] as [CGFloat] {
            let baseX = headCenter.x + 42 * side
            let outer = triangle(
                CGPoint(x: baseX - 30 * side, y: headCenter.y + 52),
                CGPoint(x: baseX + 24 * side, y: headCenter.y + 100),
                CGPoint(x: baseX + 30 * side, y: headCenter.y + 44)
            )
            fill(outer, fur.body)
            let inner = triangle(
                CGPoint(x: baseX - 12 * side, y: headCenter.y + 58),
                CGPoint(x: baseX + 19 * side, y: headCenter.y + 86),
                CGPoint(x: baseX + 18 * side, y: headCenter.y + 54)
            )
            fill(inner, pink, outlined: false)
        }
    default: // bunny
        for side in [-1.0, 1.0] as [CGFloat] {
            let ear = oval(headCenter.x + 30 * side, headCenter.y + 68, 34, 104)
            fill(rotated(ear, degrees: -9 * side, around: headCenter), fur.body)
            let inner = oval(headCenter.x + 30 * side, headCenter.y + 66, 15, 76)
            fill(rotated(inner, degrees: -9 * side, around: headCenter), pink, outlined: false)
        }
    }
}

func drawEyes(mood: String, fur: Fur) {
    let eyeY = headCenter.y + 16
    for side in [-1.0, 1.0] as [CGFloat] {
        let cx = headCenter.x + 27 * side
        if mood == "waiting" {
            // Half-lidded and sleepy: a full eye with the fur drawn back over its
            // top half, then a lid line along the join.
            fill(oval(cx, eyeY, 18, 20), eyeInk, outlined: false)
            fur.body.setFill()
            NSRect(x: cx - 11, y: eyeY + 4, width: 22, height: 14).fill()
            stroke({ let p = NSBezierPath()
                     p.move(to: CGPoint(x: cx - 10, y: eyeY + 4))
                     p.line(to: CGPoint(x: cx + 10, y: eyeY + 4))
                     return p }(), eyeInk, 4)
        } else {
            // Happy closed eyes — an upward arc.
            stroke(arc(from: CGPoint(x: cx - 13, y: eyeY - 3),
                       to: CGPoint(x: cx + 13, y: eyeY - 3), bulge: 16), eyeInk, 6.5)
        }
    }
}

func drawBlush() {
    for side in [-1.0, 1.0] as [CGFloat] {
        blush.withAlphaComponent(0.75).setFill()
        oval(headCenter.x + 50 * side, headCenter.y - 4, 26, 15).fill()
    }
}

func drawSparkles() {
    // Kept well inside a centred circle: the app frames each face in a round
    // badge, so anything out at the corners of the canvas gets cropped away.
    for point in [CGPoint(x: 58, y: 190), CGPoint(x: 198, y: 182), CGPoint(x: 186, y: 214)] {
        let s: CGFloat = 9
        let star = NSBezierPath()
        star.move(to: CGPoint(x: point.x, y: point.y + s))
        star.curve(to: CGPoint(x: point.x + s, y: point.y),
                   controlPoint1: CGPoint(x: point.x + s * 0.25, y: point.y + s * 0.25),
                   controlPoint2: CGPoint(x: point.x + s * 0.25, y: point.y + s * 0.25))
        star.curve(to: CGPoint(x: point.x, y: point.y - s),
                   controlPoint1: CGPoint(x: point.x + s * 0.25, y: point.y - s * 0.25),
                   controlPoint2: CGPoint(x: point.x + s * 0.25, y: point.y - s * 0.25))
        star.curve(to: CGPoint(x: point.x - s, y: point.y),
                   controlPoint1: CGPoint(x: point.x - s * 0.25, y: point.y - s * 0.25),
                   controlPoint2: CGPoint(x: point.x - s * 0.25, y: point.y - s * 0.25))
        star.curve(to: CGPoint(x: point.x, y: point.y + s),
                   controlPoint1: CGPoint(x: point.x - s * 0.25, y: point.y + s * 0.25),
                   controlPoint2: CGPoint(x: point.x - s * 0.25, y: point.y + s * 0.25))
        fill(star, rgb(0xF7D774), outlined: false)
    }
}

func drawSnout(_ animal: String, mood: String, fur: Fur) {
    let noseY = headCenter.y - 26
    switch animal {
    case "dog":
        fill(oval(headCenter.x, noseY - 10, 80, 58), fur.muzzle)
        fill(oval(headCenter.x, noseY + 4, 24, 17), eyeInk, outlined: false)
    case "cat":
        fill(triangle(CGPoint(x: headCenter.x - 9, y: noseY + 14),
                      CGPoint(x: headCenter.x + 9, y: noseY + 14),
                      CGPoint(x: headCenter.x, y: noseY + 4)), blush, outlined: false)
        for side in [-1.0, 1.0] as [CGFloat] {
            for offset in [CGFloat(-8), 6] {
                stroke(arc(from: CGPoint(x: headCenter.x + 34 * side, y: noseY + 8 + offset),
                           to: CGPoint(x: headCenter.x + 84 * side, y: noseY + 16 + offset),
                           bulge: 3 * side), outline.withAlphaComponent(0.5), 3.5)
            }
        }
    default: // bunny
        fill(triangle(CGPoint(x: headCenter.x - 8, y: noseY + 16),
                      CGPoint(x: headCenter.x + 8, y: noseY + 16),
                      CGPoint(x: headCenter.x, y: noseY + 7)), blush, outlined: false)
        if mood != "celebrating" {
            let teeth = NSBezierPath(roundedRect: NSRect(x: headCenter.x - 11, y: noseY - 22, width: 22, height: 20),
                                     xRadius: 5, yRadius: 5)
            fill(teeth, .white, width: 3.5)
            stroke({ let p = NSBezierPath()
                     p.move(to: CGPoint(x: headCenter.x, y: noseY - 3))
                     p.line(to: CGPoint(x: headCenter.x, y: noseY - 20))
                     return p }(), outline, 3)
        }
    }

    // Mouth
    let mouthY = animal == "dog" ? noseY - 10 : noseY - 4
    switch mood {
    case "celebrating":
        let mouth = NSBezierPath()
        mouth.move(to: CGPoint(x: headCenter.x - 17, y: mouthY - 6))
        mouth.curve(to: CGPoint(x: headCenter.x + 17, y: mouthY - 6),
                    controlPoint1: CGPoint(x: headCenter.x - 12, y: mouthY - 34),
                    controlPoint2: CGPoint(x: headCenter.x + 12, y: mouthY - 34))
        mouth.close()
        fill(mouth, rgb(0x8C4C4C), outlined: false)
    case "seen":
        for side in [-1.0, 1.0] as [CGFloat] {
            stroke(arc(from: CGPoint(x: headCenter.x, y: mouthY - 6),
                       to: CGPoint(x: headCenter.x + 16 * side, y: mouthY + 1),
                       bulge: -7), outline, 4.5)
        }
    default:
        stroke({ let p = NSBezierPath()
                 p.move(to: CGPoint(x: headCenter.x - 10, y: mouthY - 8))
                 p.line(to: CGPoint(x: headCenter.x + 10, y: mouthY - 8))
                 return p }(), outline, 4.5)
    }
}

func drawFace(animal: String, mood: String) {
    let fur = furs[animal]!
    drawEars(animal, fur: fur)
    fill(oval(headCenter.x, headCenter.y, headRadius * 2, headRadius * 1.86), fur.body)
    drawEyes(mood: mood, fur: fur)
    drawSnout(animal, mood: mood, fur: fur)
    if mood != "waiting" { drawBlush() }
    if mood == "celebrating" { drawSparkles() }
}

// ---------------------------------------------------------------- app icon

func drawAppIcon(_ size: CGFloat) {
    let scale = size / 1024
    func s(_ v: CGFloat) -> CGFloat { v * scale }

    // Rounded-square ground, in the clinic's blush.
    let ground = NSBezierPath(roundedRect: NSRect(x: s(60), y: s(60), width: s(904), height: s(904)),
                              xRadius: s(200), yRadius: s(200))
    rgb(0xF6DCE1).setFill()
    ground.fill()

    // The cat peeking out from behind the board, up and to the right.
    NSGraphicsContext.current?.saveGraphicsState()
    let t = NSAffineTransform()
    t.translateX(by: s(560), yBy: s(560))
    t.scale(by: scale * 2.1)
    t.concat()
    drawFace(animal: "cat", mood: "seen")
    NSGraphicsContext.current?.restoreGraphicsState()

    // The clipboard in front of it.
    let board = NSBezierPath(roundedRect: NSRect(x: s(190), y: s(120), width: s(560), height: s(700)),
                             xRadius: s(48), yRadius: s(48))
    fill(board, paper, width: s(16))

    // Printed rules on the sheet.
    for (index, y) in [CGFloat(620), 520, 420, 320].enumerated() {
        let width: CGFloat = index == 0 ? 380 : 300
        let line = NSBezierPath(roundedRect: NSRect(x: s(270), y: s(y), width: s(width), height: s(26)),
                                xRadius: s(13), yRadius: s(13))
        (index == 0 ? rule.blended(withFraction: 0.3, of: .black) ?? rule : rule).setFill()
        line.fill()
    }

    // Soft pink clip across the top.
    let clip = NSBezierPath(roundedRect: NSRect(x: s(330), y: s(760), width: s(280), height: s(120)),
                            xRadius: s(50), yRadius: s(50))
    fill(clip, clipPink, width: s(16))
    clipGrey.withAlphaComponent(0.55).setFill()
    NSBezierPath(roundedRect: NSRect(x: s(390), y: s(800), width: s(160), height: s(38)),
                 xRadius: s(19), yRadius: s(19)).fill()
}

// ---------------------------------------------------------------- dmg background

func drawDMGBackground(width: CGFloat, height: CGFloat) {
    NSGradient(starting: rgb(0xFBF8F2), ending: rgb(0xF3EADF))?
        .draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: -90)

    let scale = width / 640

    // A dashed rule across the top, like the sheet's separators.
    let dashed = NSBezierPath()
    dashed.move(to: CGPoint(x: 60 * scale, y: height - 64 * scale))
    dashed.line(to: CGPoint(x: width - 60 * scale, y: height - 64 * scale))
    dashed.setLineDash([5 * scale, 6 * scale], count: 2, phase: 0)
    stroke(dashed, rule, 2 * scale)

    let title = "LITTLE VET CLINIC" as NSString
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedSystemFont(ofSize: 17 * scale, weight: .bold),
        .foregroundColor: rgb(0x6E665C),
        .kern: 4 * scale
    ]
    let titleSize = title.size(withAttributes: attrs)
    title.draw(at: CGPoint(x: (width - titleSize.width) / 2, y: height - 46 * scale), withAttributes: attrs)

    let hint = "drag the clinic into Applications" as NSString
    let hintAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 12 * scale, weight: .medium),
        .foregroundColor: rgb(0xA79E92)
    ]
    let hintSize = hint.size(withAttributes: hintAttrs)
    hint.draw(at: CGPoint(x: (width - hintSize.width) / 2, y: 52 * scale), withAttributes: hintAttrs)

    // Arrow between the two icon positions.
    let arrow = NSBezierPath()
    arrow.move(to: CGPoint(x: 268 * scale, y: height - 210 * scale))
    arrow.line(to: CGPoint(x: 372 * scale, y: height - 210 * scale))
    arrow.setLineDash([7 * scale, 7 * scale], count: 2, phase: 0)
    stroke(arrow, rgb(0xE0B6C0), 3 * scale)
    fill(triangle(CGPoint(x: 372 * scale, y: height - 200 * scale),
                  CGPoint(x: 372 * scale, y: height - 220 * scale),
                  CGPoint(x: 390 * scale, y: height - 210 * scale)),
         rgb(0xE0B6C0), outlined: false)
}

// ---------------------------------------------------------------- run

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let faces = root.appendingPathComponent("LittleVetClinic/Resources/Assets.xcassets/AnimalFaces")
let iconSet = root.appendingPathComponent("LittleVetClinic/Resources/Assets.xcassets/AppIcon.appiconset")

for animal in ["dog", "cat", "bunny"] {
    for mood in ["waiting", "seen", "celebrating"] {
        let name = "\(animal)_\(mood)"
        let url = faces.appendingPathComponent("\(name).imageset/\(name).png")
        render(width: 256, height: 256, to: url) { drawFace(animal: animal, mood: mood) }
        print("  face  \(name).png")
    }
}

let iconSizes: [(String, Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024)
]
for (name, px) in iconSizes {
    render(width: px, height: px, to: iconSet.appendingPathComponent("\(name).png")) {
        drawAppIcon(CGFloat(px))
    }
}
print("  icon  \(iconSizes.count) sizes")

render(width: 640, height: 400, to: root.appendingPathComponent("scripts/dmg/background.png")) {
    drawDMGBackground(width: 640, height: 400)
}
render(width: 1280, height: 800, to: root.appendingPathComponent("scripts/dmg/background@2x.png")) {
    drawDMGBackground(width: 1280, height: 800)
}
print("  dmg   background.png, background@2x.png")
