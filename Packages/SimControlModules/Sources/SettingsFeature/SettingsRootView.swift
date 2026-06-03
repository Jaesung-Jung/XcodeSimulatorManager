import ComposableArchitecture
import DiagnosticsSettingsFeature
import GeneralSettingsFeature
import LinkFolderSettingsFeature
import MenuBarSettingsFeature
import SafetySettingsFeature
import SwiftUI
import XcodeSettingsFeature

/// Root view for the app settings scene.
public struct SettingsRootView: View {
  private let store: StoreOf<SettingsFeature>

  public init(store: StoreOf<SettingsFeature>) {
    self.store = store
  }

  public var body: some View {
    Form {
      GeneralSettingsView(
        store: store.scope(
          state: \.general,
          action: \.general
        )
      )
      MenuBarSettingsView(
        store: store.scope(
          state: \.menuBar,
          action: \.menuBar
        )
      )
      SafetySettingsView(
        store: store.scope(
          state: \.safety,
          action: \.safety
        )
      )
      XcodeSettingsView(
        store: store.scope(
          state: \.xcode,
          action: \.xcode
        )
      )
      LinkFolderSettingsView(
        store: store.scope(
          state: \.linkFolder,
          action: \.linkFolder
        )
      )
      DiagnosticsSettingsView(
        store: store.scope(
          state: \.diagnostics,
          action: \.diagnostics
        )
      )
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
