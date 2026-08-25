import SwiftUI

/// The clinic's printed-paperwork palette.
///
/// Two type families and nothing else: a soft rounded display face for the things
/// a person wrote, and a monospace face for everything the clinic "printed". The
/// contrast between them is the whole look.
enum Clinic {

    // MARK: Paper

    /// The intake sheet itself — off-white, never pure white.
    static let paper = Color(hex: 0xFBF8F2)
    /// A hair darker, for the shadow the clip casts onto the sheet.
    static let paperShade = Color(hex: 0xEFEAE0)

    // MARK: Ink

    /// Warm near-black, the colour of a good ballpoint.
    static let ink = Color(hex: 0x3D3730)
    /// Printed-detail grey — dates, hints, the small line under the headline.
    static let inkMuted = Color(hex: 0x9A9184)
    /// Dashed rules and separators.
    static let rule = Color(hex: 0xD9D2C4)

    // MARK: Clipboard

    /// The sage clip that pinches the top of the sheet. It is a drawn object, not
    /// window chrome — the gradient and the shadow are what sell that.
    static let clipTop = Color(hex: 0xC6D6BB)
    static let clipBottom = Color(hex: 0x93AC86)
    /// The darker lip along the clip's bottom edge, where it grips the paper.
    static let clipLip = Color(hex: 0x7E9772)
    /// The little rivets near each end of the clip.
    static let clipRivet = Color(hex: 0xF3F1EA)
    static let clipRivetEdge = Color(hex: 0x6F8664)

    // MARK: Avatar badges

    /// Cycled per row, independent of animal and mood, so the pastel rhythm stays
    /// even no matter which patients happen to be on the board.
    static let badges: [Color] = [
        Color(hex: 0xF6D8DD),   // blush pink
        Color(hex: 0xD8E5D3),   // sage green
        Color(hex: 0xDFD8EE)    // lavender
    ]

    static func badge(for index: Int) -> Color {
        badges[((index % badges.count) + badges.count) % badges.count]
    }

    // MARK: Status pills

    static let waitingPill = Color(hex: 0xEDE9E0)
    static let waitingPillInk = Color(hex: 0x938D82)
    static let seenPill = Color(hex: 0xD3E7CE)
    static let seenPillInk = Color(hex: 0x4C7B47)

    /// The rubber-stamp red — faded, like an ink pad that has seen some use.
    static let stamp = Color(hex: 0xC06A62)

    // MARK: Tearing off

    /// Washed behind a row while the discharge button is hovered. Removing a
    /// patient should feel weightier than ticking one off, and this is the warning
    /// that says so before the tear happens.
    static let tearWash = Color(hex: 0xE8B4B0)

    // MARK: Key cap

    static let keyCapFace = Color(hex: 0xF2EEE5)
    static let keyCapEdge = Color(hex: 0xDBD4C6)
}

// MARK: - Type

enum ClinicFont {
    /// The friendly headline face — the human half of the sheet.
    static func display(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// The printed face — patient names, dates, pills, the tally.
    static func printed(_ size: CGFloat, _ weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - Metrics

enum Metrics {
    /// Visible width of the clipboard.
    static let cardWidth: CGFloat = 318
    /// Transparent gutter around the card so the drop shadow has room to land.
    static let shadowGutter: CGFloat = 22
    /// Full window width including the gutter.
    static var windowWidth: CGFloat { cardWidth + shadowGutter * 2 }
    /// The clip's drawn size. It sits centred, overlapping the top of the sheet.
    static let clipWidth: CGFloat = 104
    static let clipHeight: CGFloat = 21
    /// Height of the fixed strip at the top of the card that the clip lives on and
    /// that the window is dragged by.
    static let clipStripHeight: CGFloat = 30
    /// Width of the colour bar down the leading edge of each row.
    static let accentStripWidth: CGFloat = 3
    /// Diameter of the pastel circle behind each animal.
    static let avatarSize: CGFloat = 34
    /// Tallest the scrolling patient list is allowed to get.
    static let listMaxHeight: CGFloat = 320
    /// Depth of the perforated teeth along the bottom edge.
    static let tearDepth: CGFloat = 7
    /// Width of one tooth.
    static let tearWidth: CGFloat = 11
}

// MARK: - Helpers

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
