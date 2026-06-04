import ComposableArchitecture
import MainWindowFeature
import MainWindowFeatureSupport
import MenuBarFeature
import SettingsFeature
import SwiftUI

@main
@MainActor
struct SimControlApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  @State private var appContainer = AppContainer()

  var body: some Scene {
    WindowGroup("SimControl", id: MainWindowSceneID.mainWindow) {
      MainWindowView(store: appContainer.mainWindowStore)
    }

    MenuBarExtra("SimControl", systemImage: "iphone.gen1") {
      MenuBarRootView(
        store: appContainer.mainWindowStore.scope(
          state: \.menuBar,
          action: \.menuBar
        )
      )
    }

    Settings {
      SettingsRootView(store: appContainer.settingsStore)
    }
  }
}
