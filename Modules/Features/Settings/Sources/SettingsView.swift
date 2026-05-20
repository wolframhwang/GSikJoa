import SwiftUI
import Domain
import DesignSystem

public struct SettingsView: View {
    @Binding private var preference: UserDifficultyPreference
    @Binding private var paletteId: String
    private let streak: Int
    private let totalConcepts: Int
    private let weekFilled: [Bool]   // 7 booleans, Mon..Sun

    @Environment(\.palette) private var palette

    public init(
        preference: Binding<UserDifficultyPreference>,
        paletteId: Binding<String>,
        streak: Int,
        totalConcepts: Int,
        weekFilled: [Bool]
    ) {
        self._preference = preference
        self._paletteId = paletteId
        self.streak = streak
        self.totalConcepts = totalConcepts
        self.weekFilled = weekFilled
    }

    public var body: some View {
        ZStack {
            palette.page.ignoresSafeArea()
            BlobBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    streakCard
                    perDomainSection
                    paletteSection
                    legalNotice
                }
                .padding(.horizontal, 22)
                .padding(.top, 64)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            JellyG(size: 72, color: palette.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text("나의 G식")
                    .font(AppFont.heading(size: 22, weight: .bold))
                    .foregroundStyle(palette.ink)
                Text("씹은 개념 \(totalConcepts)개")
                    .font(AppFont.heading(size: 13))
                    .foregroundStyle(palette.ink.opacity(0.6))
            }
            Spacer()
        }
    }

    private var streakCard: some View {
        JellyCard(color: palette.accent, depth: 5, cornerRadius: 26, padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("연속 학습")
                            .font(AppFont.heading(size: 13))
                            .foregroundStyle(palette.ink.opacity(0.85))
                        HStack(spacing: 4) {
                            Text("🔥").font(.system(size: 28))
                            Text("\(streak)일째")
                                .font(AppFont.heading(size: 32, weight: .bold))
                                .foregroundStyle(palette.ink)
                        }
                    }
                    Spacer()
                    Text("압박 없이 천천히")
                        .font(AppFont.heading(size: 13))
                        .foregroundStyle(palette.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(.white))
                        .overlay(Capsule().strokeBorder(palette.ink, lineWidth: 2))
                }

                HStack(spacing: 6) {
                    ForEach(0..<7, id: \.self) { i in
                        VStack(spacing: 4) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(weekFilled[i] ? palette.primary : Color.white.opacity(0.5))
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(palette.ink, lineWidth: 2)
                                if weekFilled[i] {
                                    Text("✓")
                                        .font(AppFont.heading(size: 14, weight: .heavy))
                                        .foregroundStyle(palette.ink)
                                }
                            }
                            .frame(height: 36)
                            Text(["월","화","수","목","금","토","일"][i])
                                .font(AppFont.heading(size: 11))
                                .foregroundStyle(palette.ink.opacity(0.85))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private var perDomainSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("도메인별 난이도")
                .font(AppFont.heading(size: 17))
                .foregroundStyle(palette.ink)
            ForEach(LearningDomain.allCases, id: \.self) { domain in
                domainRow(domain)
            }
            Text("정답률을 보고 추천만 해요. 자동으로 바뀌진 않아요.")
                .font(AppFont.heading(size: 12))
                .foregroundStyle(palette.ink.opacity(0.6))
        }
    }

    private func domainRow(_ domain: LearningDomain) -> some View {
        let current = preference.difficulty(for: domain)
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
                        Button("\(d.rawValue) · \(d.koreanName)") {
                            preference.setDifficulty(d, for: domain)
                        }
                    }
                } label: {
                    DifficultyChip(difficulty: current)
                }
            }
        }
    }

    private var paletteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("팔레트")
                .font(AppFont.heading(size: 17))
                .foregroundStyle(palette.ink)
            HStack(spacing: 10) {
                ForEach(AppPalette.allCases, id: \.id) { p in
                    paletteSwatch(p)
                }
            }
        }
    }

    private func paletteSwatch(_ p: AppPalette) -> some View {
        let isActive = paletteId == p.id
        return Button {
            paletteId = p.id
        } label: {
            HStack(spacing: 4) {
                Rectangle().fill(p.primary).frame(height: 22).cornerRadius(4)
                Rectangle().fill(p.accent).frame(height: 22).cornerRadius(4)
                Rectangle().fill(p.info).frame(height: 22).cornerRadius(4)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(p.page)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isActive ? palette.ink : palette.ink.opacity(0.3), lineWidth: isActive ? 2.5 : 1)
            )
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(palette.ink.opacity(isActive ? 1 : 0.2))
                    .offset(y: isActive ? 4 : 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var legalNotice: some View {
        JellyCard(color: palette.surface, depth: 4, cornerRadius: 20, padding: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("💡 G식좋아는 투자 권유를 하지 않아요.")
                    .font(AppFont.heading(size: 14, weight: .bold))
                    .foregroundStyle(palette.ink)
                Text("원리 학습 전용. 매수/매도 신호는 다른 곳에서.")
                    .font(AppFont.heading(size: 13))
                    .foregroundStyle(palette.ink.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
