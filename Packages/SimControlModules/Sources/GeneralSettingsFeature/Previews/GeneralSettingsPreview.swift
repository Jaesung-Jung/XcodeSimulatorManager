#if DEBUG
import ComposableArchitecture
import SwiftUI

extension Store where State == GeneralSettingsFeature.State, Action == GeneralSettingsFeature.Action {
  @MainActor
  static var generalSettingsPreview: StoreOf<GeneralSettingsFeature> {
    Store(initialState: GeneralSettingsFeature.State(launchesAtLogin: true)) {
      GeneralSettingsFeature()
    }
  }
}

#Preview("General Settings") {
  Form {
    GeneralSettingsView(store: .generalSettingsPreview)
  }
  .formStyle(.grouped)
  .frame(width: 520)
}
#endif
