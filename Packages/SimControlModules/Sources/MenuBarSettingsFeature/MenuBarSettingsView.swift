import ComposableArchitecture
import SwiftUI

/// Renders menu bar settings.
public struct MenuBarSettingsView: View {
  private let store: StoreOf<MenuBarSettingsFeature>

  /// Creates a menu bar settings view bound to a menu bar settings store.
  public init(store: StoreOf<MenuBarSettingsFeature>) {
    self.store = store
  }

  private var showsMenuBarExtra: Binding<Bool> {
    Binding(
      get: { store.showsMenuBarExtra },
      set: { store.send(.showsMenuBarExtraChanged($0)) }
    )
  }

  public var body: some View {
    Section {
      Toggle(isOn: showsMenuBarExtra) {
        Text(LocalizedStringResource.settingsMenuBarShowMenuBarExtra)
      }
    } header: {
      Text(LocalizedStringResource.settingsMenuBarSection)
    }
  }
}

// MARK: - MenuBarSettingsView Preview

#if DEBUG

#Preview("Menu Bar Settings") {
  Form {
    MenuBarSettingsView(
      store: Store(initialState: MenuBarSettingsFeature.State(showsMenuBarExtra: true)) {
        MenuBarSettingsFeature()
      }
    )
  }
  .formStyle(.grouped)
  .frame(width: 520)
}

#endif
