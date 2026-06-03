#if DEBUG
import ComposableArchitecture
import SwiftUI

extension Store where State == DiagnosticsSettingsFeature.State, Action == DiagnosticsSettingsFeature.Action {
  @MainActor
  static var diagnosticsSettingsPreview: StoreOf<DiagnosticsSettingsFeature> {
    Store(initialState: DiagnosticsSettingsFeature.State(enablesDiagnostics: true)) {
      DiagnosticsSettingsFeature()
    }
  }
}

#Preview("Diagnostics Settings") {
  Form {
    DiagnosticsSettingsView(store: .diagnosticsSettingsPreview)
  }
  .formStyle(.grouped)
  .frame(width: 520)
}
#endif
