import SwiftUI

@main
struct SimControlApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

  var body: some Scene {
    WindowGroup {
      ContentView()
    }

    MenuBarExtra("SimControl", systemImage: "iphone.gen1") {
      MenuBarRootView()
    }

    Settings {
      SettingsRootView()
    }
  }
}
