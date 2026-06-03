#if DEBUG
import ComposableArchitecture
import SwiftUI

extension Store where State == MenuBarSettingsFeature.State, Action == MenuBarSettingsFeature.Action {
  @MainActor
  static var menuBarSettingsPreview: StoreOf<MenuBarSettingsFeature> {
    Store(initialState: MenuBarSettingsFeature.State(showsMenuBarExtra: true)) {
      MenuBarSettingsFeature()
    }
  }
}

#Preview("Menu Bar Settings") {
  Form {
    MenuBarSettingsView(store: .menuBarSettingsPreview)
  }
  .formStyle(.grouped)
  .frame(width: 520)
}
#endif
