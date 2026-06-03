import ComposableArchitecture
import SimControlClients

@Reducer
public struct SettingsFeature {
  @Dependency(\.userSettings) private var userSettings

  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var settings: SimControlUserSettings
    public var isLoading: Bool

    public init(
      settings: SimControlUserSettings = .defaults,
      isLoading: Bool = false
    ) {
      self.settings = settings
      self.isLoading = isLoading
    }
  }

  public enum Action: Equatable {
    case task
    case settingsLoaded(SimControlUserSettings)
    case launchesAtLoginChanged(Bool)
    case showsMenuBarExtraChanged(Bool)
    case confirmsDestructiveActionsChanged(Bool)
    case preferredXcodeDeveloperPathChanged(String)
    case linkFolderPathChanged(String)
    case enablesDiagnosticsChanged(Bool)
  }

  public var body: some ReducerOf<Self> {
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

      case .launchesAtLoginChanged(let launchesAtLogin):
        state.settings.launchesAtLogin = launchesAtLogin
        return save(state.settings)

      case .showsMenuBarExtraChanged(let showsMenuBarExtra):
        state.settings.showsMenuBarExtra = showsMenuBarExtra
        return save(state.settings)

      case .confirmsDestructiveActionsChanged(let confirmsDestructiveActions):
        state.settings.confirmsDestructiveActions = confirmsDestructiveActions
        return save(state.settings)

      case .preferredXcodeDeveloperPathChanged(let preferredXcodeDeveloperPath):
        state.settings.preferredXcodeDeveloperPath = preferredXcodeDeveloperPath
        return save(state.settings)

      case .linkFolderPathChanged(let linkFolderPath):
        state.settings.linkFolderPath = linkFolderPath
        return save(state.settings)

      case .enablesDiagnosticsChanged(let enablesDiagnostics):
        state.settings.enablesDiagnostics = enablesDiagnostics
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
