import ComposableArchitecture

/// A settings section feature for menu bar extra behavior.
@Reducer
public struct MenuBarSettingsFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var showsMenuBarExtra: Bool

    public init(showsMenuBarExtra: Bool = true) {
      self.showsMenuBarExtra = showsMenuBarExtra
    }
  }

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
