import SwiftUI
import Domain
import DesignSystem

public struct HomeView: View {
    private let packs: [CardPack]
    private let streak: Int
    private let mascotMessage: String?
    private let weakConceptCount: Int
    private let resumePack: CardPack?
    private let resumeProgress: (Int, Int)?
    private let isReviewPack: (CardPack) -> Bool
    private let onPickPack: (CardPack) -> Void
    private let onResumeSession: () -> Void
    private let onOpenVault: () -> Void

    @State private var sessionMood: SessionMood
    private let onMoodChange: (SessionMood) -> Void

    public init(
        packs: [CardPack],
        streak: Int,
        sessionMood: SessionMood,
        mascotMessage: String? = nil,
        weakConceptCount: Int = 0,
        resumePack: CardPack? = nil,
        resumeProgress: (Int, Int)? = nil,
        isReviewPack: @escaping (CardPack) -> Bool = { _ in false },
        onPickPack: @escaping (CardPack) -> Void,
        onResumeSession: @escaping () -> Void = {},
        onOpenVault: @escaping () -> Void,
        onMoodChange: @escaping (SessionMood) -> Void = { _ in }
    ) {
        self.packs = packs
        self.streak = streak
        self.mascotMessage = mascotMessage
        self.weakConceptCount = weakConceptCount
        self.resumePack = resumePack
        self.resumeProgress = resumeProgress
        self.isReviewPack = isReviewPack
        self.onPickPack = onPickPack
        self.onResumeSession = onResumeSession
        self.onOpenVault = onOpenVault
        self.onMoodChange = onMoodChange
        self._sessionMood = State(initialValue: sessionMood)
    }

    @Environment(\.palette) private var palette

    public var body: some View {
        ZStack {
            palette.page.ignoresSafeArea()
            BlobBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    greetingRow
                    if let resumePack, let resumeProgress {
                        resumeCard(pack: resumePack, current: resumeProgress.0, total: resumeProgress.1)
                    }
                    if let msg = mascotMessage {
                        mascotCard(msg)
                    }
                    sessionToggle
                    todayPacks
                    vaultEntry
                }
                .padding(.horizontal, 22)
                .padding(.top, 64)
            }
        }
    }

    private var greetingRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(currentDateString())
                    .font(AppFont.heading(size: 13))
                    .foregroundStyle(palette.ink.opacity(0.6))
                Text("오늘도 한 입,\n씹어볼까요?")
                    .font(AppFont.heading(size: 30))
                    .foregroundStyle(palette.ink)
                    .lineLimit(2)
            }
            Spacer()
            JellyCard(color: palette.accent, depth: 3, cornerRadius: 20, padding: 8) {
                HStack(spacing: 6) {
                    Text("🔥").font(.system(size: 18))
                    Text("\(streak)일")
                        .font(AppFont.heading(size: 18, weight: .bold))
                        .foregroundStyle(palette.ink)
                }
            }
        }
    }

    private func resumeCard(pack: CardPack, current: Int, total: Int) -> some View {
        Button(action: onResumeSession) {
            JellyCard(color: palette.accent, depth: 5, cornerRadius: 24, padding: 14) {
                HStack(spacing: 12) {
                    SquareIconBadge(size: 52, cornerRadius: 14) {
                        Text("▶").font(AppFont.heading(size: 22, weight: .heavy)).foregroundStyle(palette.ink)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("이어서 풀기")
                            .font(AppFont.heading(size: 13, weight: .bold))
                            .foregroundStyle(palette.ink.opacity(0.75))
                        Text(pack.title)
                            .font(AppFont.heading(size: 17, weight: .bold))
                            .foregroundStyle(palette.ink)
                            .lineLimit(1)
                        Text("\(current)/\(total) 문제 푸는 중")
                            .font(AppFont.heading(size: 12))
                            .foregroundStyle(palette.ink.opacity(0.7))
                    }
                    Spacer()
                    Text("›")
                        .font(AppFont.heading(size: 22, weight: .bold))
                        .foregroundStyle(palette.ink)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func mascotCard(_ message: String) -> some View {
        HStack(alignment: .bottom, spacing: 10) {
            JellyG(size: 84, color: palette.primary)
            JellyCard(color: palette.surface, depth: 4, cornerRadius: 22, padding: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message)
                        .font(AppFont.heading(size: 15))
                        .foregroundStyle(palette.ink)
                        .multilineTextAlignment(.leading)
                    if weakConceptCount > 0 {
                        Text("약점 개념을 다음 카드팩에서 다시 만나요.")
                            .font(AppFont.heading(size: 13))
                            .foregroundStyle(palette.accentDeep)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.bottom, 8)
        }
    }

    private var sessionToggle: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("오늘 머리 상태")
                .font(AppFont.heading(size: 14))
                .foregroundStyle(palette.ink.opacity(0.7))
            JellyCard(color: palette.surface, depth: 4, cornerRadius: 22, padding: 6) {
                HStack(spacing: 8) {
                    ForEach(SessionMood.allCases, id: \.self) { mood in
                        moodButton(mood)
                    }
                }
            }
        }
    }

    private func moodButton(_ mood: SessionMood) -> some View {
        let isSelected = mood == sessionMood
        return Button {
            sessionMood = mood
            onMoodChange(mood)
        } label: {
            VStack(spacing: 4) {
                SpiceLevel(level: mood.spiceLevel, chipSize: 16)
                Text(mood.koreanLabel)
                    .font(AppFont.heading(size: 13, weight: .bold))
                    .foregroundStyle(palette.ink)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? palette.primary : .clear)
            )
        }
        .buttonStyle(.plain)
    }

    private var todayPacks: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .bottom) {
                Text("오늘의 카드팩")
                    .font(AppFont.heading(size: 22))
                    .foregroundStyle(palette.ink)
                Spacer()
                Text("전체 보기 →")
                    .font(AppFont.heading(size: 13))
                    .foregroundStyle(palette.infoDeep)
            }
            VStack(spacing: 12) {
                ForEach(Array(packs.prefix(3).enumerated()), id: \.element.packId) { idx, pack in
                    PackCardRow(pack: pack, accent: idx == 0, isReview: isReviewPack(pack)) {
                        onPickPack(pack)
                    }
                }
            }
        }
    }

    private var vaultEntry: some View {
        Button(action: onOpenVault) {
            JellyCard(color: palette.info, depth: 5, cornerRadius: 24, padding: 16) {
                HStack(spacing: 14) {
                    SquareIconBadge(size: 52, cornerRadius: 14) {
                        Text("📚").font(.system(size: 26))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("개념 보관함")
                            .font(AppFont.heading(size: 16, weight: .bold))
                            .foregroundStyle(palette.ink)
                        Text("씹어먹은 개념이 모이는 곳")
                            .font(AppFont.heading(size: 13))
                            .foregroundStyle(palette.ink.opacity(0.7))
                    }
                    Spacer()
                    Text("›")
                        .font(AppFont.heading(size: 22, weight: .bold))
                        .foregroundStyle(palette.ink)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "EEE · a h:mm"
        return formatter.string(from: Date()).uppercased()
    }
}

// PackCardRow and DomainGlyph live in DesignSystem (shared across features).
