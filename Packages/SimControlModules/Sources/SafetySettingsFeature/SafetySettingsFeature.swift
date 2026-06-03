import ComposableArchitecture

/// A settings section feature for safety preferences.
@Reducer
public struct SafetySettingsFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var confirmsDestructiveActions: Bool

    public init(confirmsDestructiveActions: Bool = true) {
      self.confirmsDestructiveActions = confirmsDestructiveActions
    }
  }

  public enum Action: Equatable {
    case confirmsDestructiveActionsChanged(Bool)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .confirmsDestructiveActionsChanged(let confirmsDestructiveActions):
        state.confirmsDestructiveActions = confirmsDestructiveActions
        return .none
      }
    }
  }
}
