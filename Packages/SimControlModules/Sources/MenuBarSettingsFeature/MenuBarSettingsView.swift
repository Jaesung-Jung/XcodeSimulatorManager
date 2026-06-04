import ComposableArchitecture
import SimControlLocalization
import SwiftUI

/// Renders menu bar settings.
public struct MenuBarSettingsView: View {
  private let store: StoreOf<MenuBarSettingsFeature>

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
        Text(.localizable("settings.menu_bar.show_menu_bar_extra"), bundle: .module)
      }
    } header: {
      Text(.localizable("settings.menu_bar.section"), bundle: .module)
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
