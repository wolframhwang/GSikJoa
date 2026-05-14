import SwiftUI

/// Typography. Custom Korean fonts (Jua, Pretendard, etc.) need to be added
/// to the app bundle as .otf/.ttf files and registered via UIAppFonts in Info.plist.
/// Until they're shipped, we fall back to SF Pro Rounded for headings and SF Pro
/// for body — both render Korean acceptably and preserve the friendly feel.
public enum AppFont {
    /// Heading font name preferred by the design (Jua). Resolves to system rounded
    /// when the custom face isn't bundled.
    public static func heading(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if let _ = UIFont(name: "Jua", size: size) {
            return Font.custom("Jua", size: size)
        }
        return Font.system(size: size, weight: weight, design: .rounded)
    }

    public static func body(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if let _ = UIFont(name: "Pretendard-Regular", size: size) {
            return Font.custom("Pretendard-Regular", size: size).weight(weight)
        }
        return Font.system(size: size, weight: weight, design: .default)
    }
}
