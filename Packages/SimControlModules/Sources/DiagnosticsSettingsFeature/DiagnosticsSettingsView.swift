import ComposableArchitecture
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
    Section("Diagnostics") {
      Toggle("Enable Diagnostics", isOn: enablesDiagnostics)
    }
  }
}
