import ComposableArchitecture

/// A settings section feature for diagnostics preferences.
@Reducer
public struct DiagnosticsSettingsFeature {
  /// Creates the diagnostics settings reducer.
  public init() {}

  /// State for diagnostics preferences.
  @ObservableState
  public struct State: Equatable {
    public var enablesDiagnostics: Bool

    /// Creates diagnostics settings state from the diagnostics toggle value.
    public init(enablesDiagnostics: Bool = false) {
      self.enablesDiagnostics = enablesDiagnostics
    }
  }

  /// User actions that mutate diagnostics preferences.
  public enum Action: Equatable {
    case enablesDiagnosticsChanged(Bool)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .enablesDiagnosticsChanged(let enablesDiagnostics):
        state.enablesDiagnostics = enablesDiagnostics
        return .none
      }
    }
  }
}
