/// The `simctl get_app_container` container selector.
public enum SimulatorAppContainerKind: Equatable, Hashable, Sendable {
  case app
  case data
  case appGroup(String)

  /// The argument passed to `simctl get_app_container`.
  public var simctlArgument: String {
    switch self {
    case .app:
      "app"
    case .data:
      "data"
    case .appGroup(let groupID):
      groupID
    }
  }
}
