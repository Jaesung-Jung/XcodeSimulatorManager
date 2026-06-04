import ComposableArchitecture

/// A settings section feature for general app behavior.
@Reducer
public struct GeneralSettingsFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var launchesAtLogin: Bool

    public init(launchesAtLogin: Bool = false) {
      self.launchesAtLogin = launchesAtLogin
    }
  }

  public enum Action: Equatable {
    case launchesAtLoginChanged(Bool)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .launchesAtLoginChanged(let launchesAtLogin):
        state.launchesAtLogin = launchesAtLogin
        return .none
      }
    }
  }
}
