import ComposableArchitecture
import SwiftUI

/// Renders diagnostics settings.
public struct DiagnosticsSettingsView: View {
  private let store: StoreOf<DiagnosticsSettingsFeature>

  /// Creates a diagnostics settings view bound to a diagnostics settings store.
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
        Text(LocalizedStringResource.settingsDiagnosticsEnableDiagnostics)
      }
    } header: {
      Text(LocalizedStringResource.settingsDiagnosticsSection)
    }
  }
}

// MARK: - DiagnosticsSettingsView Preview

#if DEBUG

#Preview("Diagnostics Settings") {
  Form {
    DiagnosticsSettingsView(
      store: Store(initialState: DiagnosticsSettingsFeature.State(enablesDiagnostics: true)) {
        DiagnosticsSettingsFeature()
      }
    )
  }
  .formStyle(.grouped)
  .frame(width: 520)
}

#endif
