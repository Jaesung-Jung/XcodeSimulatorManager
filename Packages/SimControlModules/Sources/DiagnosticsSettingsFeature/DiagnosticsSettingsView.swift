import ComposableArchitecture
import SimControlLocalization
import SwiftUI

/// Renders diagnostics settings.
public struct DiagnosticsSettingsView: View {
  private let store: StoreOf<DiagnosticsSettingsFeature>

  public init(store: StoreOf<DiagnosticsSettingsFeature>) {
    self.store = store
  }

  private var enablesDiagnostics: Binding<Bool> {
    Binding(
      get: { store.enablesDiagnostics },
      set: { store.send(.enablesDiagnosticsChanged($0)) }
    )
  }

  public var body: some View {
    Section {
      Toggle(isOn: enablesDiagnostics) {
        Text(.localizable("settings.diagnostics.enable_diagnostics"), bundle: .module)
      }
    } header: {
      Text(.localizable("settings.diagnostics.section"), bundle: .module)
    }
  }
}
