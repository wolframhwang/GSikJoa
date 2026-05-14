import SwiftUI
import Domain

// MARK: - JellyCard — squishy raised card with thick stroke + offset shadow

public struct JellyCard<Content: View>: View {
    private let color: Color?
    private let depth: CGFloat
    private let cornerRadius: CGFloat
    private let padding: CGFloat
    private let strokeWidth: CGFloat
    private let inkOverride: Color?
    private let content: () -> Content

    public init(
        color: Color? = nil,
        depth: CGFloat = 5,
        cornerRadius: CGFloat = 28,
        padding: CGFloat = 18,
        strokeWidth: CGFloat = 2.5,
        ink: Color? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.color = color
        self.depth = depth
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.strokeWidth = strokeWidth
        self.inkOverride = ink
        self.content = content
    }

    @Environment(\.palette) private var palette

    public var body: some View {
        let ink = inkOverride ?? palette.ink
        let bg = color ?? palette.surface
        return content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(bg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(ink, lineWidth: strokeWidth)
            )
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(ink)
                    .offset(y: depth)
            )
    }
}

// MARK: - JellyButton — squishy button (background fills + 3D push effect)

public struct JellyButton: View {
    public enum Variant {
        case primary
        case secondary
        case info
        case accent
        case surface
        case custom(background: Color)
    }

    private let title: String
    private let variant: Variant
    private let isEnabled: Bool
    private let isFullWidth: Bool
    private let icon: String?
    private let action: () -> Void

    public init(
        _ title: String,
        variant: Variant = .primary,
        isEnabled: Bool = true,
        isFullWidth: Bool = false,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.variant = variant
        self.isEnabled = isEnabled
        self.isFullWidth = isFullWidth
        self.icon = icon
        self.action = action
    }

    @Environment(\.palette) private var palette
    @State private var pressing = false

    private var background: Color {
        if !isEnabled { return Color(white: 0.92) }
        switch variant {
        case .primary: return palette.primary
        case .secondary: return palette.surface
        case .info: return palette.info
        case .accent: return palette.accent
        case .surface: return palette.surface
        case .custom(let c): return c
        }
    }

    public var body: some View {
        let depth: CGFloat = 7
        Button(action: { if isEnabled { action() } }) {
            HStack(spacing: 8) {
                if let icon { Text(icon).font(AppFont.heading(size: 18)) }
                Text(title)
                    .font(AppFont.heading(size: 18, weight: .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(palette.ink)
            .padding(.horizontal, 22)
            .padding(.vertical, 16)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(palette.ink, lineWidth: 2.5)
            )
            .opacity(isEnabled ? 1 : 0.6)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(palette.ink)
                    .offset(y: pressing ? 1 : depth)
            )
            .offset(y: pressing ? depth - 1 : 0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeOut(duration: 0.08)) { pressing = isEnabled } }
                .onEnded { _ in withAnimation(.easeOut(duration: 0.12)) { pressing = false } }
        )
        .disabled(!isEnabled)
    }
}

// MARK: - JellyProgress — chunky rounded progress bar

public struct JellyProgress: View {
    private let value: Double
    private let total: Double

    public init(value: Double, total: Double) {
        self.value = value
        self.total = max(total, 0.0001)
    }

    @Environment(\.palette) private var palette

    public var body: some View {
        let pct = max(0, min(1, value / total))
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.white)
                Capsule()
                    .fill(palette.primary)
                    .frame(width: max(0, geo.size.width * pct - 4))
                    .padding(2)
                    .overlay(alignment: .top) {
                        Capsule()
                            .fill(.white.opacity(0.55))
                            .frame(height: 4)
                            .padding(.horizontal, 8)
                            .padding(.top, 4)
                            .frame(width: max(0, geo.size.width * pct - 4))
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: pct)
            }
            .overlay(
                Capsule().strokeBorder(palette.ink, lineWidth: 2.5)
            )
            .background(
                Capsule().fill(palette.ink).offset(y: 3)
            )
        }
        .frame(height: 18)
    }
}

// MARK: - SpiceLevel — pepper meter (1..4)

public struct SpiceLevel: View {
    private let level: Int
    private let chipSize: CGFloat
    @Environment(\.palette) private var palette

    public init(level: Int, chipSize: CGFloat = 20) {
        self.level = max(1, min(4, level))
        self.chipSize = chipSize
    }

    private var fillColor: Color {
        switch level {
        case 1: return Color(hex: 0xA6A2C0)
        case 2: return Color(hex: 0xC8FF3D)
        case 3: return Color(hex: 0xFF8A4D)
        default: return Color(hex: 0xFF3D5A)
        }
    }

    public var body: some View {
        HStack(spacing: 3) {
            ForEach(1...4, id: \.self) { i in
                let active = i <= level
                Capsule()
                    .fill(active ? fillColor : Color(hex: 0xEFECE2))
                    .frame(width: chipSize * 0.36, height: chipSize)
                    .overlay(Capsule().strokeBorder(palette.ink, lineWidth: 1.5))
                    .rotationEffect(.degrees(Double(i - 2) * 6))
            }
        }
    }
}

// MARK: - DomainTag

public struct DomainTag: View {
    private let domain: LearningDomain
    @Environment(\.palette) private var palette

    public init(domain: LearningDomain) {
        self.domain = domain
    }

    public var body: some View {
        HStack(spacing: 6) {
            Text(domain.glyph).font(AppFont.heading(size: 14, weight: .heavy))
            Text(domain.displayKoreanName).font(AppFont.heading(size: 14, weight: .bold))
        }
        .foregroundStyle(palette.ink)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(palette.color(for: domain))
        )
        .overlay(Capsule().strokeBorder(palette.ink, lineWidth: 2))
        .background(Capsule().fill(palette.ink).offset(y: 2))
    }
}

// MARK: - DifficultyChip

public struct DifficultyChip: View {
    private let difficulty: Difficulty
    @Environment(\.palette) private var palette

    public init(difficulty: Difficulty) {
        self.difficulty = difficulty
    }

    public var body: some View {
        HStack(spacing: 6) {
            SpiceLevel(level: difficulty.spiceLevel, chipSize: 14)
            Text(difficulty.koreanName)
                .font(AppFont.heading(size: 13, weight: .bold))
        }
        .foregroundStyle(palette.ink)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Capsule().fill(.white))
        .overlay(Capsule().strokeBorder(palette.ink, lineWidth: 2))
        .background(Capsule().fill(palette.ink).offset(y: 2))
    }
}

// MARK: - SquareIconBadge (used in pack rows)

public struct SquareIconBadge<Inner: View>: View {
    private let size: CGFloat
    private let cornerRadius: CGFloat
    private let inner: () -> Inner
    @Environment(\.palette) private var palette

    public init(size: CGFloat = 64, cornerRadius: CGFloat = 18, @ViewBuilder inner: @escaping () -> Inner) {
        self.size = size
        self.cornerRadius = cornerRadius
        self.inner = inner
    }

    public var body: some View {
        ZStack { inner() }
            .frame(width: size, height: size)
            .background(RoundedRectangle(cornerRadius: cornerRadius).fill(.white))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).strokeBorder(palette.ink, lineWidth: 2.5))
            .background(RoundedRectangle(cornerRadius: cornerRadius).fill(palette.ink).offset(y: 3))
    }
}
