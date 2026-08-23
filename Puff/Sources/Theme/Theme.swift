import SwiftUI

// MARK: - Palette

/// The four pastel identities Puff ships with. Each one is a full little world:
/// a wash for the frosted panel, an accent for the ink, and a highlight for sparkles.
enum Theme: String, CaseIterable, Identifiable, Codable {
    case lavender
    case blush
    case mint
    case butter

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .lavender: return "Lavender"
        case .blush:    return "Blush"
        case .mint:     return "Mint"
        case .butter:   return "Butter"
        }
    }

    /// The pastel itself — used as the wash over the frosted glass.
    var wash: Color {
        switch self {
        case .lavender: return Color(hex: 0xE6D7F5)
        case .blush:    return Color(hex: 0xFFD9E8)
        case .mint:     return Color(hex: 0xD3F5E3)
        case .butter:   return Color(hex: 0xFFF3C4)
        }
    }

    /// A saturated cousin of the wash — checkboxes, badges, focus rings.
    var accent: Color {
        switch self {
        case .lavender: return Color(hex: 0x9B7BD4)
        case .blush:    return Color(hex: 0xE87BA6)
        case .mint:     return Color(hex: 0x5FBF8E)
        case .butter:   return Color(hex: 0xE0B23C)
        }
    }

    /// Dark enough to sit on the wash and still pass as readable text.
    var ink: Color {
        switch self {
        case .lavender: return Color(hex: 0x5B4380)
        case .blush:    return Color(hex: 0x8E3D5E)
        case .mint:     return Color(hex: 0x2C6B4C)
        case .butter:   return Color(hex: 0x7A5A0E)
        }
    }

    /// Soft fill for task rows, sitting just above the panel wash.
    var rowFill: Color { Color.white.opacity(0.42) }

    /// Sparkle burst colours for the check animation.
    var sparkles: [Color] {
        switch self {
        case .lavender: return [Color(hex: 0xC9A9F5), Color(hex: 0xFFD9E8), .white]
        case .blush:    return [Color(hex: 0xFFB3D1), Color(hex: 0xFFF3C4), .white]
        case .mint:     return [Color(hex: 0x8FE3B8), Color(hex: 0xD7F0FF), .white]
        case .butter:   return [Color(hex: 0xFFE07A), Color(hex: 0xFFD9E8), .white]
        }
    }
}

// MARK: - Type

/// Everything in Puff is SF Rounded. This keeps the weights in one place.
enum Font2 {
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - Metrics

enum Metrics {
    /// Radius of the panel card itself.
    static let panelRadius: CGFloat = 23
    /// Radius of an individual task row.
    static let rowRadius: CGFloat = 12
    /// Visible width of the card.
    static let cardWidth: CGFloat = 320
    /// Transparent gutter around the card so the drop shadow has somewhere to land.
    static let shadowGutter: CGFloat = 20
    /// Full window width including the gutter.
    static var windowWidth: CGFloat { cardWidth + shadowGutter * 2 }
    /// Tallest the scrolling task area is allowed to get.
    static let listMaxHeight: CGFloat = 330
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