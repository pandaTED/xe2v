import SwiftUI

@main
struct xe2vApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            RootTabView(env: environment)
        }
        .onChange(of: scenePhase) { _, newValue in
            if newValue == .active {
                Task {
                    await environment.webSession.restoreSessionIfPossible()
                }
            }
        }
    }
}
