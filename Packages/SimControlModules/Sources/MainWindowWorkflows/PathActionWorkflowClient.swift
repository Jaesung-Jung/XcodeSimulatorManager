import Foundation
import SimControlClients
import SimControlDomain

/// The path operation requested by a main window command.
public enum PathActionOperation: Equatable, Sendable {
  case open
  case copy
}

/// The input needed to resolve and open or copy an app container path.
public struct AppContainerPathActionRequest: Equatable, Sendable {
  public let deviceID: SimulatorDevice.ID
  public let bundleID: String
  public let container: SimulatorAppContainerKind
  public let fallbackURL: URL?
  public let label: String
  public let operation: PathActionOperation

  /// Creates an app container path action request.
  public init(
    deviceID: SimulatorDevice.ID,
    bundleID: String,
    container: SimulatorAppContainerKind,
    fallbackURL: URL?,
    label: String,
    operation: PathActionOperation
  ) {
    self.deviceID = deviceID
    self.bundleID = bundleID
    self.container = container
    self.fallbackURL = fallbackURL
    self.label = label
    self.operation = operation
  }
}

/// Runs main window path actions while keeping command sequencing outside the reducer.
public struct PathActionWorkflowClient: Sendable {
  public var runDevicePathAction: @Sendable (
    _ url: URL?,
    _ label: String,
    _ operation: PathActionOperation
  ) async -> [CommandResult]
  public var copyValue: @Sendable (_ value: String?, _ label: String) async -> [CommandResult]
  public var runAppContainerPathAction: @Sendable (
    _ request: AppContainerPathActionRequest
  ) async -> [CommandResult]

  /// Creates a path action workflow from endpoint closures.
  public init(
    runDevicePathAction: @escaping @Sendable (
      _ url: URL?,
      _ label: String,
      _ operation: PathActionOperation
    ) async -> [CommandResult],
    copyValue: @escaping @Sendable (_ value: String?, _ label: String) async -> [CommandResult],
    runAppContainerPathAction: @escaping @Sendable (
      _ request: AppContainerPathActionRequest
    ) async -> [CommandResult]
  ) {
    self.runDevicePathAction = runDevicePathAction
    self.copyValue = copyValue
    self.runAppContainerPathAction = runAppContainerPathAction
  }
}

public extension PathActionWorkflowClient {
  /// Creates a path action workflow backed by dependency clients.
  static func live(
    coreSimulatorService: CoreSimulatorClient,
    pathAction: PathActionClient
  ) -> Self {
    Self(
      runDevicePathAction: { url, label, operation in
        [await runPathAction(pathAction, url, label, operation)]
      },
      copyValue: { value, label in
        [await pathAction.copy(value, label)]
      },
      runAppContainerPathAction: { request in
        var results: [CommandResult] = []
        let getContainerResult = await coreSimulatorService.getAppContainer(
          request.deviceID,
          request.bundleID,
          request.container
        )
        results.append(getContainerResult)

        let resolvedURL = containerURL(
          from: getContainerResult,
          container: request.container
        ) ?? request.fallbackURL
        let actionResult = await runPathAction(
          pathAction,
          resolvedURL,
          request.label,
          request.operation
        )
        results.append(actionResult)

        return results
      }
    )
  }
}

private func runPathAction(
  _ pathAction: PathActionClient,
  _ url: URL?,
  _ label: String,
  _ operation: PathActionOperation
) async -> CommandResult {
  switch operation {
  case .open:
    await pathAction.openInFinder(url, label)
  case .copy:
    await pathAction.copyPath(url, label)
  }
}

private func containerURL(
  from result: CommandResult,
  container: SimulatorAppContainerKind
) -> URL? {
  guard result.succeeded else {
    return nil
  }

  let path = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
  guard !path.isEmpty else {
    return nil
  }

  let url = URL(fileURLWithPath: path)
  if container == .app && url.pathExtension == "app" {
    return url.deletingLastPathComponent()
  }

  return url
}
