import ComposableArchitecture
import SimControlLocalization
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
    Section {
      Toggle(isOn: confirmsDestructiveActions) {
        Text(.localizable("settings.safety.confirm_destructive_actions"), bundle: .module)
      }
    } header: {
      Text(.localizable("settings.safety.section"), bundle: .module)
    }
  }
}
