import SwiftUI

// MARK: - Color tokens (Variant A — Midnight)

extension Color {
    static let dsBg               = Color(hex: 0x0F0F1A)
    static let dsBgGradientTop    = Color(hex: 0x1A1530)
    static let dsCard             = Color(hex: 0x1C1C2E)
    static let dsText             = Color.white
    static let dsTextDim          = Color(hex: 0xA8A8B8)
    static let dsTextFaint        = Color(hex: 0x6C6C80)
    static let dsAccent           = Color(hex: 0x8B5CF6)
    static let dsAccentSoft       = Color(hex: 0x8B5CF6, opacity: 0.18)
    static let dsAccentText       = Color(hex: 0xB89DFF)
    static let dsChipIdleBg       = Color.white.opacity(0.06)
    static let dsChipIdleBorder   = Color.white.opacity(0.08)
    static let dsTabBarBg         = Color(hex: 0x141420, opacity: 0.88)
    static let dsSeparator        = Color.white.opacity(0.06)
    static let dsFieldBg          = Color.white.opacity(0.06)
    static let dsImagePlaceholder = Color(hex: 0x2A2740)
    static let dsDestructive      = Color(hex: 0xE54E6C)
    static let dsCardInsetStroke  = Color.white.opacity(0.05)
    static let dsShimmer          = Color.white.opacity(0.10)
    static let dsSkeletonBase     = Color(hex: 0x26243A)

    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >>  8) & 0xFF) / 255.0
        let b = Double( hex        & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

// MARK: - Geometry tokens

enum Radii {
    static let card: CGFloat   = 18
    static let group: CGFloat  = 14
    static let field: CGFloat  = 12
    static let thumb: CGFloat  = 8
    static let image: CGFloat  = 8
    static let chip: CGFloat   = 999  // capsule
}

enum Spacing {
    static let pageH: CGFloat       = 16
    static let pageHWide: CGFloat   = 20
    static let gridGutter: CGFloat  = 12
    static let tabClearance: CGFloat = 110
    static let cardInner: CGFloat   = 12
    static let chipH: CGFloat       = 14
    static let chipV: CGFloat       = 7
}

// MARK: - Typography tokens

enum Typography {
    static let largeTitle    = Font.system(size: 34, weight: .heavy)
    static let detailTitle   = Font.system(size: 26, weight: .heavy)
    static let sectionHeader = Font.system(size: 16, weight: .bold)
    static let groupHeader   = Font.system(size: 11, weight: .semibold)
    static let cardTitle     = Font.system(size: 14, weight: .semibold)
    static let rowTitle      = Font.system(size: 15, weight: .medium)
    static let body          = Font.system(size: 14)
    static let meta          = Font.system(size: 12, weight: .medium)
    static let numeric       = Font.system(size: 22, weight: .heavy).monospacedDigit()
    static let eyebrow       = Font.system(size: 11, weight: .bold)
    static let tabLabel      = Font.system(size: 10)
    static let chip          = Font.system(size: 13, weight: .semibold)
}

// MARK: - View modifiers

private struct DsCardShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: .black.opacity(0.40), radius: 1,  x: 0, y: 1)
            .shadow(color: .black.opacity(0.45), radius: 16, x: 0, y: 8)
            .shadow(color: .black.opacity(0.35), radius: 32, x: 0, y: 16)
    }
}

private struct DsBackgroundGradient: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RadialGradient(
                    colors: [Color.dsBgGradientTop, Color.dsBg],
                    center: .top,
                    startRadius: 0,
                    endRadius: 700
                )
                .ignoresSafeArea()
            )
    }
}

extension View {
    func dsCardShadow() -> some View { modifier(DsCardShadow()) }
    func dsBackgroundGradient() -> some View { modifier(DsBackgroundGradient()) }
}
