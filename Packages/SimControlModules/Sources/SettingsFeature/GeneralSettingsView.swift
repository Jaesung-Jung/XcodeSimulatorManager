import ComposableArchitecture
import SwiftUI

struct GeneralSettingsView: View {
  let store: StoreOf<SettingsFeature>

  private var launchesAtLogin: Binding<Bool> {
    Binding(
      get: { store.settings.launchesAtLogin },
      set: { store.send(.launchesAtLoginChanged($0)) }
    )
  }

  var body: some View {
    Section("General") {
      Toggle("Launch at Login", isOn: launchesAtLogin)
    }
  }
}
