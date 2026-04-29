import SwiftUI

@main
@MainActor
struct SimControlApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  @State private var appContainer = AppContainer()

  var body: some Scene {
    WindowGroup {
      MainWindowView(store: appContainer.mainWindowStore)
    }

    MenuBarExtra("SimControl", systemImage: "iphone.gen1") {
      MenuBarRootView()
    }

    Settings {
      SettingsRootView()
    }
  }
}
