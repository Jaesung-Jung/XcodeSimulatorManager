import ComposableArchitecture

/// A settings section feature for generated link folder preferences.
@Reducer
public struct LinkFolderSettingsFeature {
  /// Creates the link folder settings reducer.
  public init() {}

  /// State for generated link folder preferences.
  @ObservableState
  public struct State: Equatable {
    public var linkFolderPath: String

    /// Creates link folder settings state from a destination folder path.
    public init(linkFolderPath: String = "") {
      self.linkFolderPath = linkFolderPath
    }
  }

  /// User actions that mutate generated link folder preferences.
  public enum Action: Equatable {
    case linkFolderPathChanged(String)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .linkFolderPathChanged(let linkFolderPath):
        state.linkFolderPath = linkFolderPath
        return .none
      }
    }
  }
}
