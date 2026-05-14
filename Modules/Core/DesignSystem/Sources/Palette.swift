import SwiftUI
import Domain

public struct AppPalette: Sendable, Equatable, Hashable {
    public let id: String
    public let displayName: String
    public let page: Color
    public let surface: Color
    public let ink: Color
    public let primary: Color
    public let primaryDeep: Color
    public let accent: Color
    public let accentDeep: Color
    public let info: Color
    public let infoDeep: Color
    public let correct: Color
    public let wrong: Color
    public let soft: Color
    public let mute: Color

    public init(
        id: String, displayName: String,
        page: Color, surface: Color, ink: Color,
        primary: Color, primaryDeep: Color,
        accent: Color, accentDeep: Color,
        info: Color, infoDeep: Color,
        correct: Color, wrong: Color,
        soft: Color, mute: Color
    ) {
        self.id = id
        self.displayName = displayName
        self.page = page
        self.surface = surface
        self.ink = ink
        self.primary = primary
        self.primaryDeep = primaryDeep
        self.accent = accent
        self.accentDeep = accentDeep
        self.info = info
        self.infoDeep = infoDeep
        self.correct = correct
        self.wrong = wrong
        self.soft = soft
        self.mute = mute
    }
}

public extension AppPalette {
    /// Ocean — default palette. Refined teal + coral.
    static let ocean = AppPalette(
        id: "ocean", displayName: "Ocean",
        page: Color(hex: 0xE5F1F4),
        surface: .white,
        ink: Color(hex: 0x0E2230),
        primary: Color(hex: 0x16C2B5),
        primaryDeep: Color(hex: 0x0A8780),
        accent: Color(hex: 0xFF7A5A),
        accentDeep: Color(hex: 0xC24227),
        info: Color(hex: 0x3F5BFF),
        infoDeep: Color(hex: 0x1F35C2),
        correct: Color(hex: 0x16C2B5),
        wrong: Color(hex: 0xFF7A5A),
        soft: Color(hex: 0xF2F8FA),
        mute: Color(hex: 0x88A0AC)
    )

    /// Lime — softened lime + peach.
    static let lime = AppPalette(
        id: "lime", displayName: "Lime",
        page: Color(hex: 0xF1F2EA),
        surface: .white,
        ink: Color(hex: 0x1A1F1A),
        primary: Color(hex: 0xB6E84B),
        primaryDeep: Color(hex: 0x6FA01D),
        accent: Color(hex: 0xFF8E6E),
        accentDeep: Color(hex: 0xC25A3D),
        info: Color(hex: 0x3A66E0),
        infoDeep: Color(hex: 0x1F3FA8),
        correct: Color(hex: 0xB6E84B),
        wrong: Color(hex: 0xFF8E6E),
        soft: Color(hex: 0xFBF6E8),
        mute: Color(hex: 0x9EA59A)
    )

    /// Berry — pink + plum.
    static let berry = AppPalette(
        id: "berry", displayName: "Berry",
        page: Color(hex: 0xFFEEE6),
        surface: .white,
        ink: Color(hex: 0x2A1530),
        primary: Color(hex: 0xFF5C8A),
        primaryDeep: Color(hex: 0xC2356A),
        accent: Color(hex: 0x5B2A82),
        accentDeep: Color(hex: 0x3A1652),
        info: Color(hex: 0xFFC93D),
        infoDeep: Color(hex: 0xB58800),
        correct: Color(hex: 0x5BD392),
        wrong: Color(hex: 0xFF5C8A),
        soft: Color(hex: 0xFFF5F8),
        mute: Color(hex: 0xA8889A)
    )

    static let allCases: [AppPalette] = [.ocean, .lime, .berry]

    static func byId(_ id: String) -> AppPalette {
        allCases.first { $0.id == id } ?? .ocean
    }

    func color(for domain: LearningDomain) -> Color {
        switch domain {
        case .economy: return info
        case .physics: return accent
        case .statistics: return primary
        }
    }

    func color(for difficulty: Difficulty) -> Color {
        switch difficulty {
        case .l1: return Color(hex: 0xFFE9C2)
        case .l2: return primary
        case .l3: return Color(hex: 0xFF8A4D)
        case .l4: return Color(hex: 0xFF3D5A)
        }
    }
}

// MARK: - Color hex helper

public extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, opacity: opacity)
    }
}

// MARK: - Environment

private struct PaletteKey: EnvironmentKey {
    static let defaultValue: AppPalette = .ocean
}

public extension EnvironmentValues {
    var palette: AppPalette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}

public extension View {
    func palette(_ palette: AppPalette) -> some View {
        environment(\.palette, palette)
    }
}
