import ComposableArchitecture
import SwiftUI

/// Root view for the app settings scene.
public struct SettingsRootView: View {
  private let store: StoreOf<SettingsFeature>

  public init(store: StoreOf<SettingsFeature>) {
    self.store = store
  }

  public var body: some View {
    Form {
      GeneralSettingsView(store: store)
      MenuBarSettingsView(store: store)
      SafetySettingsView(store: store)
      XcodeSettingsView(store: store)
      LinkFolderSettingsView(store: store)
      DiagnosticsSettingsView(store: store)
    }
    .formStyle(.grouped)
    .frame(minWidth: 520, minHeight: 420)
    .task {
      await store.send(.task).finish()
    }
  }
}

#if DEBUG

#Preview {
  SettingsRootView(
    store: Store(initialState: SettingsFeature.State()) {
      SettingsFeature()
    }
  )
}

#endif
