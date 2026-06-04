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
    Section {
      Toggle(isOn: confirmsDestructiveActions) {
        Text(LocalizedStringResource.settingsSafetyConfirmDestructiveActions)
      }
    } header: {
      Text(LocalizedStringResource.settingsSafetySection)
    }
  }
}

// MARK: - SafetySettingsView Preview

#if DEBUG

#Preview("Safety Settings") {
  Form {
    SafetySettingsView(
      store: Store(initialState: SafetySettingsFeature.State(confirmsDestructiveActions: true)) {
        SafetySettingsFeature()
      }
    )
  }
  .formStyle(.grouped)
  .frame(width: 520)
}

#endif
