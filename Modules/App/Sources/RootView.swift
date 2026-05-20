import SwiftUI
import Domain
import DesignSystem
import Onboarding
import Home
import PackList
import Quiz
import Result
import ConceptVault
import Settings

struct RootView: View {
    @EnvironmentObject private var coordinator: AppCoordinator

    var body: some View {
        ZStack {
            switch coordinator.stage {
            case .launching:
                LaunchView()
            case .onboarding:
                OnboardingView { domains, pref in
                    coordinator.completeOnboarding(domains: domains, preference: pref)
                }
                .transition(.opacity)
            case .main:
                MainTabContainer()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: coordinator.stage)
    }
}

// MARK: - Launch

private struct LaunchView: View {
    @Environment(\.palette) private var palette

    var body: some View {
        ZStack {
            palette.page.ignoresSafeArea()
            VStack(spacing: 14) {
                JellyG(size: 100, color: palette.primary)
                Text("G식좋아")
                    .font(AppFont.heading(size: 32, weight: .heavy))
                    .foregroundStyle(palette.ink)
            }
        }
    }
}

// MARK: - Main tab container

private struct MainTabContainer: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @Environment(\.palette) private var palette

    private static let tabBarReservedHeight: CGFloat = 96

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch coordinator.tab {
                case .home:
                    HomeView(
                        packs: coordinator.recommendedPacks,
                        streak: coordinator.progress.streakDays,
                        sessionMood: coordinator.sessionMood,
                        mascotMessage: coordinator.homeMascotMessage,
                        weakConceptCount: coordinator.weakConceptCount,
                        resumePack: coordinator.resumePack,
                        resumeProgress: coordinator.resumeSession.map { ($0.currentIndex, $0.totalCards) },
                        isReviewPack: { coordinator.isReviewPick($0) },
                        onPickPack: { coordinator.startPack($0) },
                        onResumeSession: { coordinator.resumeActiveSession() },
                        onOpenVault: { coordinator.tab = .vault },
                        onMoodChange: { coordinator.setSessionMood($0) }
                    )
                case .packs:
                    PackListView(
                        packs: coordinator.packs,
                        isReviewPack: { coordinator.isReviewPick($0) }
                    ) { coordinator.startPack($0) }
                case .vault:
                    let items = coordinator.conceptItems.map {
                        ConceptVaultView.Item(tag: $0.tag, domain: $0.domain, count: $0.count, lastSeenLabel: $0.lastSeenLabel)
                    }
                    ConceptVaultView(items: items)
                case .me:
                    SettingsView(
                        preference: Binding(
                            get: { coordinator.preference },
                            set: { coordinator.setPreference($0) }
                        ),
                        paletteId: Binding(
                            get: { coordinator.paletteId },
                            set: { coordinator.setPaletteId($0) }
                        ),
                        streak: coordinator.progress.streakDays,
                        totalConcepts: coordinator.progress.totalConceptsLearned,
                        weekFilled: coordinator.thisWeekFilled
                    )
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: Self.tabBarReservedHeight)
            }

            BottomTabBar(active: $coordinator.tab)
                .padding(.horizontal, 12)
                .padding(.bottom, 24)
        }
        .ignoresSafeArea(.keyboard)
        .fullScreenCover(item: $coordinator.activePack) { pack in
            QuizSessionContainer(pack: pack)
        }
    }
}

// MARK: - Quiz container (handles quiz -> result transition)

private struct QuizSessionContainer: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    let pack: CardPack

    var body: some View {
        Group {
            if let result = coordinator.sessionResult {
                ResultView(
                    result: result,
                    onAgain: { coordinator.playAgain() },
                    onHome: { coordinator.dismissResult() }
                )
                .transition(.move(edge: .trailing))
            } else {
                QuizView(
                    pack: pack,
                    resumeFrom: coordinator.resumeStateFor(pack: pack),
                    onExit: { snapshot in
                        if let snapshot, !snapshot.isComplete {
                            coordinator.saveActiveSnapshot(snapshot)
                        } else {
                            coordinator.dismissResult()
                        }
                    },
                    onComplete: { result in coordinator.completeSession(result) }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: coordinator.sessionResult)
    }
}

// MARK: - Bottom tab bar

private struct BottomTabBar: View {
    @Binding var active: AppCoordinator.Tab
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 6) {
            ForEach(AppCoordinator.Tab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 28).fill(.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28).strokeBorder(palette.ink, lineWidth: 2.5)
        )
        .background(
            RoundedRectangle(cornerRadius: 28).fill(palette.ink).offset(y: 5)
        )
    }

    private func tabButton(_ tab: AppCoordinator.Tab) -> some View {
        let isActive = active == tab
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                active = tab
            }
        } label: {
            VStack(spacing: 2) {
                Text(tab.glyph).font(.system(size: 18))
                Text(tab.label)
                    .font(AppFont.heading(size: 12, weight: isActive ? .bold : .regular))
                    .lineLimit(1)
            }
            .foregroundStyle(palette.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(isActive ? palette.primary : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}
