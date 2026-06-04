import ComposableArchitecture
import SimControlLocalization
import SwiftUI

/// Renders general app settings.
public struct GeneralSettingsView: View {
  private let store: StoreOf<GeneralSettingsFeature>

  public init(store: StoreOf<GeneralSettingsFeature>) {
    self.store = store
  }

  private var launchesAtLogin: Binding<Bool> {
    Binding(
      get: { store.launchesAtLogin },
      set: { store.send(.launchesAtLoginChanged($0)) }
    )
  }

  public var body: some View {
    Section {
      Toggle(isOn: launchesAtLogin) {
        Text(.localizable("settings.general.launch_at_login"), bundle: .module)
      }
    } header: {
      Text(.localizable("settings.general.section"), bundle: .module)
    }
  }
}

// MARK: - GeneralSettingsView Preview

#if DEBUG

#Preview("General Settings") {
  Form {
    GeneralSettingsView(
      store: Store(initialState: GeneralSettingsFeature.State(launchesAtLogin: true)) {
        GeneralSettingsFeature()
      }
    )
  }
  .formStyle(.grouped)
  .frame(width: 520)
}

#endif
