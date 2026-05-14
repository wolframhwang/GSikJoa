import SwiftUI
import Domain
import DesignSystem

public struct QuizView: View {
    @State private var viewModel: QuizViewModel
    private let onExit: (ActiveQuizSession?) -> Void
    private let onComplete: (QuizSessionResult) -> Void

    public init(
        pack: CardPack,
        resumeFrom: ActiveQuizSession? = nil,
        onExit: @escaping (ActiveQuizSession?) -> Void,
        onComplete: @escaping (QuizSessionResult) -> Void
    ) {
        self._viewModel = State(initialValue: QuizViewModel(pack: pack, resumeFrom: resumeFrom))
        self.onExit = onExit
        self.onComplete = onComplete
    }

    @Environment(\.palette) private var palette

    public var body: some View {
        ZStack {
            palette.surface.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        metaRow
                        questionCard
                        choices
                        if viewModel.revealed {
                            explanationCard
                                .transition(.scale.combined(with: .opacity))
                        }
                        ctaButton
                            .padding(.bottom, 30)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 6)
                }
            }
            .padding(.top, 56)

            if viewModel.isCorrect {
                ConfettiBurst(isActive: viewModel.isCorrect)
                    .allowsHitTesting(false)
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button(action: { onExit(viewModel.snapshot()) }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(palette.surface)
                    RoundedRectangle(cornerRadius: 12).strokeBorder(palette.ink, lineWidth: 2.5)
                    RoundedRectangle(cornerRadius: 12).fill(palette.ink).offset(y: 3)
                    RoundedRectangle(cornerRadius: 12).fill(palette.surface)
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(palette.ink, lineWidth: 2.5))
                    Text("✕")
                        .font(AppFont.heading(size: 18, weight: .heavy))
                        .foregroundStyle(palette.ink)
                }
                .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)

            JellyProgress(value: viewModel.progressValue, total: Double(viewModel.totalCards))
            Text("\(viewModel.currentIndex + 1)/\(viewModel.totalCards)")
                .font(AppFont.heading(size: 14))
                .foregroundStyle(palette.ink)
                .frame(minWidth: 36)
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 14)
        .background(palette.surface)
    }

    private var metaRow: some View {
        HStack(spacing: 8) {
            DomainTag(domain: viewModel.pack.domain)
            DifficultyChip(difficulty: viewModel.pack.difficulty)
        }
    }

    private var questionCard: some View {
        JellyCard(color: palette.surface, depth: 6, cornerRadius: 28, padding: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(typeLabel(viewModel.currentCard.type))
                    .font(AppFont.heading(size: 12, weight: .bold))
                    .foregroundStyle(palette.ink.opacity(0.6))
                    .tracking(0.5)
                Text(viewModel.currentCard.question)
                    .font(AppFont.heading(size: 22))
                    .foregroundStyle(palette.ink)
                    .lineSpacing(3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .id(viewModel.currentIndex)
        .jellyIn(trigger: viewModel.currentIndex)
    }

    private var choices: some View {
        VStack(spacing: 10) {
            ForEach(Array(viewModel.currentCard.choices.enumerated()), id: \.offset) { idx, choice in
                ChoiceButton(
                    index: idx,
                    text: choice,
                    isSelected: viewModel.pickedIndex == idx,
                    isCorrect: viewModel.revealed && idx == viewModel.currentCard.answerIndex,
                    isWrong: viewModel.revealed && viewModel.pickedIndex == idx && idx != viewModel.currentCard.answerIndex,
                    isOX: viewModel.currentCard.type == .ox,
                    isDisabled: viewModel.revealed
                ) {
                    viewModel.pick(idx)
                }
            }
        }
        .shake(trigger: viewModel.shakeTrigger)
    }

    private var explanationCard: some View {
        JellyCard(
            color: viewModel.isCorrect ? palette.primary : palette.soft,
            depth: 4,
            cornerRadius: 24,
            padding: 16
        ) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    feedbackBadge
                    Text(viewModel.isCorrect ? "한 입 잘 씹었어요!" : "아쉽! 이렇게 봐요")
                        .font(AppFont.heading(size: 16, weight: .bold))
                        .foregroundStyle(palette.ink)
                }
                Text(viewModel.currentCard.explanation)
                    .font(AppFont.heading(size: 15))
                    .foregroundStyle(palette.ink.opacity(0.92))
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if !viewModel.currentCard.conceptTags.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(viewModel.currentCard.conceptTags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(AppFont.heading(size: 12))
                                .foregroundStyle(palette.ink)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(.white))
                                .overlay(Capsule().strokeBorder(palette.ink, lineWidth: 2))
                        }
                    }
                }
            }
        }
    }

    private var feedbackBadge: some View {
        ZStack {
            Circle().fill(viewModel.isCorrect ? .white : palette.accent)
            Circle().strokeBorder(palette.ink, lineWidth: 2.5)
            Text(viewModel.isCorrect ? "✓" : "!")
                .font(AppFont.heading(size: 16, weight: .heavy))
                .foregroundStyle(palette.ink)
        }
        .frame(width: 28, height: 28)
        .scaleEffect(viewModel.revealed ? 1.0 : 0)
        .animation(.spring(response: 0.36, dampingFraction: 0.55), value: viewModel.revealed)
    }

    @ViewBuilder
    private var ctaButton: some View {
        if !viewModel.revealed {
            JellyButton("확인하기", variant: .primary, isEnabled: viewModel.pickedIndex != nil, isFullWidth: true) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
                    viewModel.submit()
                }
            }
        } else {
            JellyButton(
                viewModel.isLastCard ? "결과 보기" : "다음 문제 →",
                variant: viewModel.isCorrect ? .info : .accent,
                isFullWidth: true
            ) {
                if let result = viewModel.advance() {
                    onComplete(result)
                }
            }
        }
    }

    private func typeLabel(_ type: QuestionType) -> String {
        switch type {
        case .multipleChoice: return "4지선다"
        case .ox: return "OX"
        case .fillBlank: return "빈칸 채우기"
        case .pickWrongExplanation: return "틀린 설명 고르기"
        case .causeFinding: return "원인 맞히기"
        }
    }
}

// MARK: - Choice button

private struct ChoiceButton: View {
    let index: Int
    let text: String
    let isSelected: Bool
    let isCorrect: Bool
    let isWrong: Bool
    let isOX: Bool
    let isDisabled: Bool
    let action: () -> Void

    @Environment(\.palette) private var palette

    private var background: Color {
        if isCorrect { return palette.correct }
        if isWrong { return palette.wrong }
        if isSelected { return palette.soft }
        return palette.surface
    }

    private var letter: String {
        let letters = ["A", "B", "C", "D"]
        if isCorrect { return "✓" }
        if isWrong { return "✕" }
        if isOX { return text }
        return letters[index]
    }

    private var body_label: String {
        if isOX { return text == "O" ? "맞다" : "틀리다" }
        return text
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(.white)
                    Circle().strokeBorder(palette.ink, lineWidth: 2)
                    Text(letter)
                        .font(AppFont.heading(size: 16, weight: .heavy))
                        .foregroundStyle(palette.ink)
                }
                .frame(width: 32, height: 32)

                Text(body_label)
                    .font(AppFont.heading(size: 16))
                    .foregroundStyle(palette.ink)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20).fill(background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20).strokeBorder(palette.ink, lineWidth: 2.5)
            )
            .background(
                RoundedRectangle(cornerRadius: 20).fill(palette.ink).offset(y: isSelected ? 2 : 5)
            )
            .offset(y: isSelected ? 3 : 0)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .animation(.easeOut(duration: 0.12), value: isSelected)
    }
}

// MARK: - Flow layout (concept-tag wrapping)

public struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    public init(spacing: CGFloat = 6) { self.spacing = spacing }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
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

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
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
