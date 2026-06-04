import ComposableArchitecture

/// A settings section feature for generated link folder preferences.
@Reducer
public struct LinkFolderSettingsFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var linkFolderPath: String

    public init(linkFolderPath: String = "") {
      self.linkFolderPath = linkFolderPath
    }
  }

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
