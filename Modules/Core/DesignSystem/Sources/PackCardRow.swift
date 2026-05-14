import SwiftUI
import Domain

// MARK: - Pack card row (used in Home & PackList)

public struct PackCardRow: View {
    private let pack: CardPack
    private let accent: Bool
    private let isReview: Bool
    private let action: () -> Void
    @Environment(\.palette) private var palette

    public init(pack: CardPack, accent: Bool, isReview: Bool = false, action: @escaping () -> Void) {
        self.pack = pack
        self.accent = accent
        self.isReview = isReview
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            JellyCard(
                color: accent ? palette.primary : palette.surface,
                depth: 5,
                cornerRadius: 26,
                padding: 16
            ) {
                HStack(spacing: 12) {
                    SquareIconBadge(size: 64, cornerRadius: 18) {
                        DomainGlyph(domain: pack.domain)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            DomainTag(domain: pack.domain)
                            if isReview {
                                Text("약점 복습")
                                    .font(AppFont.heading(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(palette.accent))
                                    .overlay(Capsule().strokeBorder(palette.ink, lineWidth: 1.5))
                            }
                            Text("· \(pack.cards.count)문제 · \(pack.estimatedSeconds / 60)분")
                                .font(AppFont.heading(size: 12))
                                .foregroundStyle(palette.ink.opacity(0.7))
                        }
                        Text(pack.title)
                            .font(AppFont.heading(size: 18, weight: .bold))
                            .foregroundStyle(palette.ink)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                        Text(pack.blurb)
                            .font(AppFont.heading(size: 13))
                            .foregroundStyle(palette.ink.opacity(0.65))
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 6) {
                        SpiceLevel(level: pack.difficulty.spiceLevel, chipSize: 18)
                        Text(pack.difficulty.koreanName)
                            .font(AppFont.heading(size: 12))
                            .foregroundStyle(palette.ink.opacity(0.7))
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Domain glyph (geometric icon per domain)

public struct DomainGlyph: View {
    private let domain: LearningDomain
    @Environment(\.palette) private var palette

    public init(domain: LearningDomain) {
        self.domain = domain
    }

    public var body: some View {
        switch domain {
        case .economy:
            ZStack {
                Circle().fill(palette.info)
                Circle().strokeBorder(palette.ink, lineWidth: 2.5)
                Text("₩").font(AppFont.heading(size: 18, weight: .heavy)).foregroundStyle(palette.ink)
            }
            .frame(width: 36, height: 36)
        case .physics:
            ZStack {
                Ellipse().strokeBorder(palette.ink, lineWidth: 2.5).frame(width: 32, height: 14)
                Ellipse().strokeBorder(palette.accent, lineWidth: 2.5).frame(width: 32, height: 14)
                    .rotationEffect(.degrees(60))
                Circle().fill(palette.accent).strokeBorder(palette.ink, lineWidth: 2).frame(width: 8, height: 8)
            }
            .frame(width: 36, height: 36)
        case .statistics:
            HStack(alignment: .bottom, spacing: 2) {
                Rectangle().fill(palette.primary).frame(width: 5, height: 10)
                Rectangle().fill(palette.accent).frame(width: 5, height: 17)
                Rectangle().fill(palette.info).frame(width: 5, height: 22)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .strokeBorder(palette.ink, lineWidth: 2)
                    .frame(width: 22, height: 1)
                    .offset(y: 1)
            }
            .frame(width: 36, height: 36, alignment: .bottom)
        }
    }
}
