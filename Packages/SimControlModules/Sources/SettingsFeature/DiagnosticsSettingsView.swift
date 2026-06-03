import ComposableArchitecture
import SwiftUI

struct DiagnosticsSettingsView: View {
  let store: StoreOf<SettingsFeature>

  private var enablesDiagnostics: Binding<Bool> {
    Binding(
      get: { store.settings.enablesDiagnostics },
      set: { store.send(.enablesDiagnosticsChanged($0)) }
    )
  }

  var body: some View {
    Section("Diagnostics") {
      Toggle("Enable Diagnostics", isOn: enablesDiagnostics)
    }
  }
}
