import SwiftUI
import Domain
import DesignSystem

public struct PackListView: View {
    private let packs: [CardPack]
    private let isReviewPack: (CardPack) -> Bool
    private let onPickPack: (CardPack) -> Void
    @State private var filter: DomainFilter = .all
    @Environment(\.palette) private var palette

    public init(
        packs: [CardPack],
        isReviewPack: @escaping (CardPack) -> Bool = { _ in false },
        onPickPack: @escaping (CardPack) -> Void
    ) {
        self.packs = packs
        self.isReviewPack = isReviewPack
        self.onPickPack = onPickPack
    }

    public enum DomainFilter: String, CaseIterable, Hashable {
        case all
        case economy
        case physics
        case statistics

        var label: String {
            switch self {
            case .all: return "전체"
            case .economy: return "경제"
            case .physics: return "물리"
            case .statistics: return "통계"
            }
        }

        var domain: LearningDomain? {
            switch self {
            case .all: return nil
            case .economy: return .economy
            case .physics: return .physics
            case .statistics: return .statistics
            }
        }
    }

    private var filteredPacks: [CardPack] {
        guard let d = filter.domain else { return packs }
        return packs.filter { $0.domain == d }
    }

    public var body: some View {
        ZStack {
            palette.page.ignoresSafeArea()
            BlobBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("카드팩")
                        .font(AppFont.heading(size: 28))
                        .foregroundStyle(palette.ink)
                    Text("오늘 씹어먹을 주제를 골라요")
                        .font(AppFont.heading(size: 14))
                        .foregroundStyle(palette.ink.opacity(0.65))

                    filterTabs

                    LazyVStack(spacing: 12) {
                        ForEach(filteredPacks, id: \.packId) { pack in
                            PackCardRow(pack: pack, accent: false, isReview: isReviewPack(pack)) {
                                onPickPack(pack)
                            }
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 64)
            }
        }
    }

    private var filterTabs: some View {
        HStack(spacing: 6) {
            ForEach(DomainFilter.allCases, id: \.self) { f in
                let isActive = filter == f
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        filter = f
                    }
                } label: {
                    Text(f.label)
                        .font(AppFont.heading(size: 14, weight: .bold))
                        .foregroundStyle(palette.ink)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isActive ? palette.primary : palette.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(palette.ink, lineWidth: 2.5)
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(palette.ink)
                                .offset(y: isActive ? 2 : 4)
                        )
                        .offset(y: isActive ? 2 : 0)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
