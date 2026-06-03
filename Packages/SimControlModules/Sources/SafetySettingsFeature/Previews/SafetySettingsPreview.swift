#if DEBUG
import ComposableArchitecture
import SwiftUI

extension Store where State == SafetySettingsFeature.State, Action == SafetySettingsFeature.Action {
  @MainActor
  static var safetySettingsPreview: StoreOf<SafetySettingsFeature> {
    Store(initialState: SafetySettingsFeature.State(confirmsDestructiveActions: true)) {
      SafetySettingsFeature()
    }
  }
}

#Preview("Safety Settings") {
  Form {
    SafetySettingsView(store: .safetySettingsPreview)
  }
  .formStyle(.grouped)
  .frame(width: 520)
}
#endif
