import SwiftUI

@main
@MainActor
struct SimControlApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  @State private var appContainer = AppContainer()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .appStores(appContainer)
    }

    MenuBarExtra("SimControl", systemImage: "iphone.gen1") {
      MenuBarRootView()
        .appStores(appContainer)
    }

    Settings {
      SettingsRootView()
        .appStores(appContainer)
    }
  }
}

private extension View {
  func appStores(_ container: AppContainer) -> some View {
    environment(container.simulatorStore)
      .environment(container.settingsStore)
      .environment(container.actionLogStore)
  }
}
