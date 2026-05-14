import SwiftUI
import Domain
import DesignSystem

public struct ResultView: View {
    private let result: QuizSessionResult
    private let onAgain: () -> Void
    private let onHome: () -> Void

    @Environment(\.palette) private var palette

    public init(
        result: QuizSessionResult,
        onAgain: @escaping () -> Void,
        onHome: @escaping () -> Void
    ) {
        self.result = result
        self.onAgain = onAgain
        self.onHome = onHome
    }

    private var mood: JellyG.Mood {
        if result.ratio >= 0.8 { return .wow }
        if result.ratio >= 0.5 { return .happy }
        return .sad
    }

    private var headline: String {
        if result.ratio >= 0.8 { return "완벽하게 씹어먹었네요!" }
        if result.ratio >= 0.5 { return "괜찮은 식사였어요" }
        return "한 번 더 가볼까요?"
    }

    public var body: some View {
        ZStack {
            palette.page.ignoresSafeArea()
            BlobBackdrop()
            ScrollView {
                VStack(spacing: 18) {
                    JellyG(size: 120, color: palette.primary, mood: mood)
                        .padding(.top, 12)
                    Text(headline)
                        .font(AppFont.heading(size: 28))
                        .foregroundStyle(palette.ink)
                        .multilineTextAlignment(.center)
                    Text("\(result.pack.title) · \(result.pack.difficulty.koreanName)")
                        .font(AppFont.heading(size: 14))
                        .foregroundStyle(palette.ink.opacity(0.7))

                    scoreBlock
                    conceptsGained
                    weakTagsCard
                    ctas
                    Spacer().frame(height: 90)
                }
                .padding(.horizontal, 22)
                .padding(.top, 64)
            }
        }
    }

    private var scoreBlock: some View {
        JellyCard(color: palette.surface, depth: 5, cornerRadius: 28, padding: 18) {
            VStack(spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("정답률")
                            .font(AppFont.heading(size: 13))
                            .foregroundStyle(palette.ink.opacity(0.65))
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(result.percent)")
                                .font(AppFont.heading(size: 44, weight: .heavy))
                                .foregroundStyle(palette.ink)
                            Text("%")
                                .font(AppFont.heading(size: 22, weight: .bold))
                                .foregroundStyle(palette.ink)
                        }
                    }
                    Spacer()
                    ScoreDial(percent: result.percent)
                        .frame(width: 92, height: 92)
                }

                HStack(spacing: 8) {
                    StatChip(label: "정답", value: result.correctCount, color: palette.primary)
                    StatChip(label: "오답", value: result.total - result.correctCount, color: palette.accent)
                    StatChip(label: "개념", value: result.gainedConceptTags.count, color: palette.info)
                }
            }
        }
    }

    private var conceptsGained: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("획득한 개념")
                .font(AppFont.heading(size: 17))
                .foregroundStyle(palette.ink)
            if result.gainedConceptTags.isEmpty {
                Text("아직 없어요. 다음에 또!")
                    .font(AppFont.heading(size: 14))
                    .foregroundStyle(palette.ink.opacity(0.6))
            } else {
                FlowLayoutResult(spacing: 8) {
                    ForEach(result.gainedConceptTags, id: \.self) { tag in
                        Text("+ \(tag)")
                            .font(AppFont.heading(size: 14))
                            .foregroundStyle(palette.ink)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 14).fill(palette.primary))
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(palette.ink, lineWidth: 2))
                            .background(RoundedRectangle(cornerRadius: 14).fill(palette.ink).offset(y: 3))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var weakTagsCard: some View {
        if !result.weakConceptTags.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("다시 만날 약점")
                    .font(AppFont.heading(size: 17))
                    .foregroundStyle(palette.ink)
                JellyCard(color: palette.soft, depth: 3, cornerRadius: 20, padding: 14) {
                    VStack(alignment: .leading, spacing: 8) {
                        FlowLayoutResult(spacing: 6) {
                            ForEach(result.weakConceptTags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(AppFont.heading(size: 13))
                                    .foregroundStyle(palette.ink)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(.white))
                                    .overlay(Capsule().strokeBorder(palette.ink, lineWidth: 2))
                            }
                        }
                        Text("이 개념이 들어간 카드팩을 다음에 위로 추천해요.")
                            .font(AppFont.heading(size: 13))
                            .foregroundStyle(palette.ink.opacity(0.75))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var ctas: some View {
        VStack(spacing: 10) {
            JellyButton("한 번 더 풀기", variant: .primary, isFullWidth: true) { onAgain() }
            JellyButton("홈으로 돌아가기", variant: .surface, isFullWidth: true) { onHome() }
        }
    }
}

// MARK: - StatChip

private struct StatChip: View {
    let label: String
    let value: Int
    let color: Color
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(AppFont.heading(size: 22, weight: .heavy))
                .foregroundStyle(palette.ink)
            Text(label)
                .font(AppFont.heading(size: 12))
                .foregroundStyle(palette.ink.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 18).fill(color))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(palette.ink, lineWidth: 2.5))
        .background(RoundedRectangle(cornerRadius: 18).fill(palette.ink).offset(y: 3))
    }
}

// MARK: - ScoreDial

private struct ScoreDial: View {
    let percent: Int
    @Environment(\.palette) private var palette
    @State private var animatedPct: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(.white)
                .overlay(Circle().strokeBorder(palette.ink, lineWidth: 3))
            Circle()
                .trim(from: 0, to: animatedPct)
                .stroke(palette.primary, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(2)
            Text("\(percent)")
                .font(AppFont.heading(size: 22, weight: .heavy))
                .foregroundStyle(palette.ink)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.65).delay(0.2)) {
                animatedPct = Double(percent) / 100.0
            }
        }
    }
}

// MARK: - FlowLayout (kept private to avoid module duplicate symbol; same logic as Quiz's)

private struct FlowLayoutResult: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var width: CGFloat = 0
        var height: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth {
                width = max(width, rowWidth)
                height += rowHeight + spacing
                rowWidth = size.width + spacing
                rowHeight = size.height
            } else {
                rowWidth += size.width + spacing
                rowHeight = max(rowHeight, size.height)
            }
        }
        width = max(width, rowWidth)
        height += rowHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
