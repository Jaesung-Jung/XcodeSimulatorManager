import ComposableArchitecture

/// A settings section feature for safety preferences.
@Reducer
public struct SafetySettingsFeature {
  /// Creates the safety settings reducer.
  public init() {}

  /// State for destructive-action safety preferences.
  @ObservableState
  public struct State: Equatable {
    public var confirmsDestructiveActions: Bool

    /// Creates safety settings state from the destructive-action confirmation preference.
    public init(confirmsDestructiveActions: Bool = true) {
      self.confirmsDestructiveActions = confirmsDestructiveActions
    }
  }

  /// User actions that mutate destructive-action safety preferences.
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
