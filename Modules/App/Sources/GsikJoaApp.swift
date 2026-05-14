import SwiftUI
import Domain
import Data
import DesignSystem

@main
struct GsikJoaApp: App {
    @StateObject private var coordinator: AppCoordinator

    init() {
        let prefs = UserDefaultsPreferencesStore()
        let progress = UserDefaultsProgressStore()
        let active = UserDefaultsActiveSessionStore()
        let repo = BundleCardPackRepository()
        _coordinator = StateObject(wrappedValue: AppCoordinator(
            cardPackRepository: repo,
            preferencesStore: prefs,
            progressStore: progress,
            activeSessionStore: active
        ))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(coordinator)
                .palette(coordinator.activePalette)
                .preferredColorScheme(.light)
                .task { await coordinator.bootstrap() }
        }
    }
}
