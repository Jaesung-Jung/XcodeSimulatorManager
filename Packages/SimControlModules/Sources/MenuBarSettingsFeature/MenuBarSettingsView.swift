import ComposableArchitecture
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
    Section("Menu Bar") {
      Toggle("Show Menu Bar Extra", isOn: showsMenuBarExtra)
    }
  }
}
