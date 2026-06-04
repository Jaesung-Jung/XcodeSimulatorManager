import ComposableArchitecture
import DiagnosticsSettingsFeature
import GeneralSettingsFeature
import LinkFolderSettingsFeature
import MenuBarSettingsFeature
import SafetySettingsFeature
import SimControlClients
import XcodeSettingsFeature

/// Coordinates loading and saving app settings across settings sections.
@Reducer
public struct SettingsFeature {
  /// Creates the settings reducer.
  public init() {}

  /// Aggregated state for all settings sections.
  @ObservableState
  public struct State: Equatable {
    public var general: GeneralSettingsFeature.State
    public var menuBar: MenuBarSettingsFeature.State
    public var safety: SafetySettingsFeature.State
    public var xcode: XcodeSettingsFeature.State
    public var linkFolder: LinkFolderSettingsFeature.State
    public var diagnostics: DiagnosticsSettingsFeature.State
    public var isLoading: Bool

    /// Creates settings state from persisted user settings and loading state.
    public init(
      settings: SimControlUserSettings = .defaults,
      isLoading: Bool = false
    ) {
      general = GeneralSettingsFeature.State(launchesAtLogin: settings.launchesAtLogin)
      menuBar = MenuBarSettingsFeature.State(showsMenuBarExtra: settings.showsMenuBarExtra)
      safety = SafetySettingsFeature.State(confirmsDestructiveActions: settings.confirmsDestructiveActions)
      xcode = XcodeSettingsFeature.State(preferredXcodeDeveloperPath: settings.preferredXcodeDeveloperPath)
      linkFolder = LinkFolderSettingsFeature.State(linkFolderPath: settings.linkFolderPath)
      diagnostics = DiagnosticsSettingsFeature.State(enablesDiagnostics: settings.enablesDiagnostics)
      self.isLoading = isLoading
    }

    public var settings: SimControlUserSettings {
      get {
        SimControlUserSettings(
          launchesAtLogin: general.launchesAtLogin,
          showsMenuBarExtra: menuBar.showsMenuBarExtra,
          confirmsDestructiveActions: safety.confirmsDestructiveActions,
          preferredXcodeDeveloperPath: xcode.preferredXcodeDeveloperPath,
          linkFolderPath: linkFolder.linkFolderPath,
          enablesDiagnostics: diagnostics.enablesDiagnostics
        )
      }
      set {
        general.launchesAtLogin = newValue.launchesAtLogin
        menuBar.showsMenuBarExtra = newValue.showsMenuBarExtra
        safety.confirmsDestructiveActions = newValue.confirmsDestructiveActions
        xcode.preferredXcodeDeveloperPath = newValue.preferredXcodeDeveloperPath
        linkFolder.linkFolderPath = newValue.linkFolderPath
        diagnostics.enablesDiagnostics = newValue.enablesDiagnostics
      }
    }
  }

  /// User actions and loading responses handled by settings.
  public enum Action: Equatable {
    case task
    case settingsLoaded(SimControlUserSettings)
    case general(GeneralSettingsFeature.Action)
    case menuBar(MenuBarSettingsFeature.Action)
    case safety(SafetySettingsFeature.Action)
    case xcode(XcodeSettingsFeature.Action)
    case linkFolder(LinkFolderSettingsFeature.Action)
    case diagnostics(DiagnosticsSettingsFeature.Action)
  }

  @Dependency(\.userSettings) private var userSettings

  public var body: some ReducerOf<Self> {
    Scope(state: \.general, action: \.general) {
      GeneralSettingsFeature()
    }
    Scope(state: \.menuBar, action: \.menuBar) {
      MenuBarSettingsFeature()
    }
    Scope(state: \.safety, action: \.safety) {
      SafetySettingsFeature()
    }
    Scope(state: \.xcode, action: \.xcode) {
      XcodeSettingsFeature()
    }
    Scope(state: \.linkFolder, action: \.linkFolder) {
      LinkFolderSettingsFeature()
    }
    Scope(state: \.diagnostics, action: \.diagnostics) {
      DiagnosticsSettingsFeature()
    }
    Reduce { state, action in
      switch action {
      case .task:
        state.isLoading = true
        return .run { [userSettings] send in
          await send(.settingsLoaded(await userSettings.load()))
        }

      case .settingsLoaded(let settings):
        state.isLoading = false
        state.settings = settings
        return .none

      case .general, .menuBar, .safety, .xcode, .linkFolder, .diagnostics:
        return save(state.settings)
      }
    }
  }

  private func save(_ settings: SimControlUserSettings) -> Effect<Action> {
    .run { [userSettings] _ in
      await userSettings.save(settings)
    }
  }
}
