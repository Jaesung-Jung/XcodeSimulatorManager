import ComposableArchitecture

/// A settings section feature for diagnostics preferences.
@Reducer
public struct DiagnosticsSettingsFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var enablesDiagnostics: Bool

    public init(enablesDiagnostics: Bool = false) {
      self.enablesDiagnostics = enablesDiagnostics
    }
  }

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
