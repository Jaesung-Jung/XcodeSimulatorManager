import SimControlClients

#if DEBUG
import ComposableArchitecture

extension Store where State == SettingsFeature.State, Action == SettingsFeature.Action {
  @MainActor
  static var settingsRootPreview: StoreOf<SettingsFeature> {
    Store(initialState: SettingsFeature.State(settings: .preview)) {
      SettingsFeature()
    } withDependencies: {
      $0.userSettings.load = { .preview }
      $0.userSettings.save = { _ in }
    }
  }
}

private extension SimControlUserSettings {
  static let preview = SimControlUserSettings(
    launchesAtLogin: true,
    showsMenuBarExtra: true,
    confirmsDestructiveActions: true,
    preferredXcodeDeveloperPath: "/Applications/Xcode.app/Contents/Developer",
    linkFolderPath: "~/Library/Application Support/SimControl/Links",
    enablesDiagnostics: true
  )
}
#endif
