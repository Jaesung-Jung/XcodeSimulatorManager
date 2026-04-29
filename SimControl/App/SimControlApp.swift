import SwiftUI

@main
@MainActor
struct SimControlApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  @State private var appContainer = AppContainer()

  var body: some Scene {
    WindowGroup("SimControl", id: AppSceneID.mainWindow) {
      MainWindowView(store: appContainer.mainWindowStore)
    }

    MenuBarExtra("SimControl", systemImage: "iphone.gen1") {
      MenuBarRootView(store: appContainer.mainWindowStore)
    }

    Settings {
      SettingsRootView()
    }
  }
}
