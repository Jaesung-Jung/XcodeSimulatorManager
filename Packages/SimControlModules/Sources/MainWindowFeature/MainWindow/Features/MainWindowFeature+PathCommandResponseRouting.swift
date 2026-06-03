import ComposableArchitecture
import SimControlDomain

// MARK: - MainWindowFeature Path Command Response Routing
extension MainWindowFeature {
  func routePathActionResults(
    _ results: [CommandResult],
    into state: inout State
  ) -> Effect<Action> {
    for result in results {
      state.workspace.appendCommandResult(result)
    }

    return .none
  }
}
