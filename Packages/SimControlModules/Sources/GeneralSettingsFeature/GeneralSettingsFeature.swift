import ComposableArchitecture

/// A settings section feature for general app behavior.
@Reducer
public struct GeneralSettingsFeature {
  /// Creates the general settings reducer.
  public init() {}

  /// State for general app behavior preferences.
  @ObservableState
  public struct State: Equatable {
    public var launchesAtLogin: Bool

    /// Creates general settings state from the launch-at-login preference.
    public init(launchesAtLogin: Bool = false) {
      self.launchesAtLogin = launchesAtLogin
    }
  }

  /// User actions that mutate general app behavior preferences.
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
