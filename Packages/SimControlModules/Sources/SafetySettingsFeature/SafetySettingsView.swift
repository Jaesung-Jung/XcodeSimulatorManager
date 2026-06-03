import ComposableArchitecture
import SwiftUI

/// Renders safety settings.
public struct SafetySettingsView: View {
  private let store: StoreOf<SafetySettingsFeature>

  public init(store: StoreOf<SafetySettingsFeature>) {
    self.store = store
  }

  private var confirmsDestructiveActions: Binding<Bool> {
    Binding(
      get: { store.confirmsDestructiveActions },
      set: { store.send(.confirmsDestructiveActionsChanged($0)) }
    )
  }

  public var body: some View {
    Section("Safety") {
      Toggle("Confirm Destructive Actions", isOn: confirmsDestructiveActions)
    }
  }
}
