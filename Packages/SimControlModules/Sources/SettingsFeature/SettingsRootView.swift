import ComposableArchitecture
import DiagnosticsSettingsFeature
import GeneralSettingsFeature
import LinkFolderSettingsFeature
import MenuBarSettingsFeature
import SafetySettingsFeature
import SimControlClients
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

// MARK: - SettingsRootView Preview

#if DEBUG

#Preview {
  let settings = SimControlUserSettings(
    launchesAtLogin: true,
    showsMenuBarExtra: true,
    confirmsDestructiveActions: true,
    preferredXcodeDeveloperPath: "/Applications/Xcode.app/Contents/Developer",
    linkFolderPath: "~/Library/Application Support/SimControl/Links",
    enablesDiagnostics: true
  )

  SettingsRootView(
    store: Store(initialState: SettingsFeature.State(settings: settings)) {
      SettingsFeature()
    } withDependencies: {
      $0.userSettings.load = { settings }
      $0.userSettings.save = { _ in }
    }
  )
}

#endif
