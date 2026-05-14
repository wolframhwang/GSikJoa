import SwiftUI
import Domain
import DesignSystem

public struct OnboardingView: View {
    @State private var step: Int = 0
    @State private var selectedDomains: Set<LearningDomain> = Set(LearningDomain.allCases)
    @State private var pref: UserDifficultyPreference = .init()

    private let onComplete: ([LearningDomain], UserDifficultyPreference) -> Void

    public init(onComplete: @escaping ([LearningDomain], UserDifficultyPreference) -> Void) {
        self.onComplete = onComplete
    }

    @Environment(\.palette) private var palette

    public var body: some View {
        ZStack {
            palette.page.ignoresSafeArea()
            BlobBackdrop()

            VStack(spacing: 18) {
                header
                content
                footerCTA
            }
            .padding(.horizontal, 22)
            .padding(.top, 60)
            .padding(.bottom, 32)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                JellyG(size: 64, color: palette.primary, mood: .happy)
                Text("G식좋아")
                    .font(AppFont.heading(size: 30, weight: .heavy))
                    .foregroundStyle(palette.ink)
            }
            Text(step == 0 ? "어떤 분야가 궁금해요?" : "오늘 머리는 어디까지 씹을까요?")
                .font(AppFont.heading(size: 22))
                .foregroundStyle(palette.ink)
            Text("세상 돌아가는 원리를 퀴즈로 씹어먹자")
                .font(AppFont.body(size: 14))
                .foregroundStyle(palette.ink.opacity(0.65))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var content: some View {
        if step == 0 {
            domainPicker
        } else {
            difficultyPicker
        }
    }

    private var domainPicker: some View {
        VStack(spacing: 12) {
            ForEach(LearningDomain.allCases, id: \.self) { domain in
                domainRow(domain)
            }
        }
    }

    private func domainRow(_ domain: LearningDomain) -> some View {
        let isSelected = selectedDomains.contains(domain)
        return Button {
            if isSelected { selectedDomains.remove(domain) } else { selectedDomains.insert(domain) }
        } label: {
            JellyCard(
                color: isSelected ? palette.color(for: domain) : palette.surface,
                depth: 5,
                cornerRadius: 22,
                padding: 14
            ) {
                HStack(spacing: 12) {
                    SquareIconBadge(size: 48, cornerRadius: 14) {
                        Text(domain.glyph)
                            .font(AppFont.heading(size: 22, weight: .heavy))
                            .foregroundStyle(palette.ink)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(domain.displayKoreanName)
                            .font(AppFont.heading(size: 18, weight: .bold))
                            .foregroundStyle(palette.ink)
                        Text(domainBlurb(domain))
                            .font(AppFont.body(size: 13))
                            .foregroundStyle(palette.ink.opacity(0.65))
                    }
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(palette.ink)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var difficultyPicker: some View {
        VStack(spacing: 12) {
            ForEach(LearningDomain.allCases, id: \.self) { domain in
                difficultyRow(for: domain)
            }
        }
    }

    private func difficultyRow(for domain: LearningDomain) -> some View {
        let current = pref.difficulty(for: domain)
        return JellyCard(color: palette.surface, depth: 4, cornerRadius: 20, padding: 14) {
            HStack(spacing: 12) {
                SquareIconBadge(size: 44, cornerRadius: 12) {
                    Text(domain.glyph)
                        .font(AppFont.heading(size: 20, weight: .heavy))
                        .foregroundStyle(palette.ink)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(domain.displayKoreanName)
                        .font(AppFont.heading(size: 16, weight: .bold))
                        .foregroundStyle(palette.ink)
                    SpiceLevel(level: current.spiceLevel, chipSize: 14)
                }
                Spacer()
                Menu {
                    ForEach(Difficulty.allCases, id: \.self) { d in
                        Button("\(d.rawValue) · \(d.koreanName)") { pref.setDifficulty(d, for: domain) }
                    }
                } label: {
                    DifficultyChip(difficulty: current)
                }
            }
        }
    }

    private var footerCTA: some View {
        VStack(spacing: 10) {
            JellyButton(step == 0 ? "다음" : "시작하기", variant: .primary, isFullWidth: true) {
                if step == 0 {
                    withAnimation(.spring()) { step = 1 }
                } else {
                    onComplete(Array(selectedDomains), pref)
                }
            }
            if step == 1 {
                Button("이전으로") {
                    withAnimation(.spring()) { step = 0 }
                }
                .font(AppFont.heading(size: 14))
                .foregroundStyle(palette.ink.opacity(0.6))
            }
        }
    }

    private func domainBlurb(_ d: LearningDomain) -> String {
        switch d {
        case .economy: return "금리, 환율, 채권 같은 뉴스 단어"
        case .physics: return "관성, 마찰, 압력 같은 일상 원리"
        case .statistics: return "평균, 확률, 상관관계의 함정"
        }
    }
}
