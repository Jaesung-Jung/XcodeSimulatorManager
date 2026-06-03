import ComposableArchitecture
import SwiftUI

struct SafetySettingsView: View {
  let store: StoreOf<SettingsFeature>

  private var confirmsDestructiveActions: Binding<Bool> {
    Binding(
      get: { store.settings.confirmsDestructiveActions },
      set: { store.send(.confirmsDestructiveActionsChanged($0)) }
    )
  }

  var body: some View {
    Section("Safety") {
      Toggle("Confirm Destructive Actions", isOn: confirmsDestructiveActions)
    }
  }
}
