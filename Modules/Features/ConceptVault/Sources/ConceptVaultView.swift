import SwiftUI
import Domain
import DesignSystem

public struct ConceptVaultView: View {
    public struct Item: Identifiable, Hashable {
        public let tag: String
        public let domain: LearningDomain
        public let count: Int
        public let lastSeenLabel: String

        public var id: String { tag }

        public init(tag: String, domain: LearningDomain, count: Int, lastSeenLabel: String) {
            self.tag = tag
            self.domain = domain
            self.count = count
            self.lastSeenLabel = lastSeenLabel
        }
    }

    private let items: [Item]
    @Environment(\.palette) private var palette

    public init(items: [Item]) {
        self.items = items
    }

    public var body: some View {
        ZStack {
            palette.page.ignoresSafeArea()
            BlobBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("개념 보관함")
                        .font(AppFont.heading(size: 28))
                        .foregroundStyle(palette.ink)
                    Text("씹어먹은 개념들이 여기 살아요")
                        .font(AppFont.heading(size: 14))
                        .foregroundStyle(palette.ink.opacity(0.65))

                    if items.isEmpty {
                        empty
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                                  spacing: 10) {
                            ForEach(items) { item in
                                conceptTile(item)
                            }
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 64)
            }
        }
    }

    private var empty: some View {
        JellyCard(color: palette.surface, depth: 4, cornerRadius: 22, padding: 22) {
            VStack(spacing: 10) {
                JellyG(size: 64, color: palette.primary)
                Text("아직 보관된 개념이 없어요")
                    .font(AppFont.heading(size: 16))
                    .foregroundStyle(palette.ink)
                Text("문제를 풀면 정답한 개념이 여기 모여요.")
                    .font(AppFont.heading(size: 13))
                    .foregroundStyle(palette.ink.opacity(0.65))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func conceptTile(_ item: Item) -> some View {
        JellyCard(color: palette.surface, depth: 4, cornerRadius: 20, padding: 12) {
            VStack(alignment: .leading, spacing: 8) {
                DomainTag(domain: item.domain)
                Text(item.tag)
                    .font(AppFont.heading(size: 22, weight: .bold))
                    .foregroundStyle(palette.ink)
                Text("\(item.count)회 만남 · \(item.lastSeenLabel)")
                    .font(AppFont.heading(size: 12))
                    .foregroundStyle(palette.ink.opacity(0.65))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
