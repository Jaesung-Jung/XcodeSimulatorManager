import ComposableArchitecture

/// A settings section feature for menu bar extra behavior.
@Reducer
public struct MenuBarSettingsFeature {
  /// Creates the menu bar settings reducer.
  public init() {}

  /// State for menu bar extra preferences.
  @ObservableState
  public struct State: Equatable {
    public var showsMenuBarExtra: Bool

    /// Creates menu bar settings state from the menu bar extra visibility preference.
    public init(showsMenuBarExtra: Bool = true) {
      self.showsMenuBarExtra = showsMenuBarExtra
    }
  }

  /// User actions that mutate menu bar extra preferences.
  public enum Action: Equatable {
    case showsMenuBarExtraChanged(Bool)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .showsMenuBarExtraChanged(let showsMenuBarExtra):
        state.showsMenuBarExtra = showsMenuBarExtra
        return .none
      }
    }
  }
}
