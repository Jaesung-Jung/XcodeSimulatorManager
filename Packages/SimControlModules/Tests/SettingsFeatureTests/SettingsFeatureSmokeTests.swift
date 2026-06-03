import ComposableArchitecture
import SettingsFeature
import SimControlClients
import Testing

@Suite
@MainActor
struct SettingsFeatureSmokeTests {
  @Test func rootViewCanBeConstructedFromOutsideTheModule() {
    let store = Store(initialState: SettingsFeature.State()) {
      SettingsFeature()
    }

    _ = SettingsRootView(store: store)
  }

  @Test func taskLoadsUserSettings() async {
    let settings = SimControlUserSettings(
      launchesAtLogin: true,
      showsMenuBarExtra: false,
      confirmsDestructiveActions: false,
      preferredXcodeDeveloperPath: "/Applications/Xcode-beta.app/Contents/Developer",
      linkFolderPath: "/tmp/simcontrol-links",
      enablesDiagnostics: true
    )

    let store = TestStore(initialState: SettingsFeature.State()) {
      SettingsFeature()
    } withDependencies: {
      $0.userSettings.load = { settings }
    }

    await store.send(.task) {
      $0.isLoading = true
    }
    await store.receive(.settingsLoaded(settings)) {
      $0.isLoading = false
      $0.settings = settings
    }
  }

  @Test func changingSettingPersistsUserSettings() async {
    let recorder = UserSettingsSaveRecorder()
    let store = TestStore(initialState: SettingsFeature.State()) {
      SettingsFeature()
    } withDependencies: {
      $0.userSettings.save = { settings in
        await recorder.append(settings)
      }
    }

    await store.send(.showsMenuBarExtraChanged(false)) {
      $0.settings.showsMenuBarExtra = false
    }
    await store.finish()

    var expected = SimControlUserSettings.defaults
    expected.showsMenuBarExtra = false
    let values = await recorder.values
    #expect(values == [expected])
  }
}

private actor UserSettingsSaveRecorder {
  var values: [SimControlUserSettings] = []

  func append(_ settings: SimControlUserSettings) {
    values.append(settings)
  }
}
