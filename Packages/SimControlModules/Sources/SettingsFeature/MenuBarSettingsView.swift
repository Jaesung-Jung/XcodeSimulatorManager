import ComposableArchitecture
import SwiftUI

struct MenuBarSettingsView: View {
  let store: StoreOf<SettingsFeature>

  private var showsMenuBarExtra: Binding<Bool> {
    Binding(
      get: { store.settings.showsMenuBarExtra },
      set: { store.send(.showsMenuBarExtraChanged($0)) }
    )
  }

  var body: some View {
    Section("Menu Bar") {
      Toggle("Show Menu Bar Extra", isOn: showsMenuBarExtra)
    }
  }
}
