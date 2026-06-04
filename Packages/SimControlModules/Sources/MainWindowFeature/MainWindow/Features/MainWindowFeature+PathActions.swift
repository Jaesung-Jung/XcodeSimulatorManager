import ComposableArchitecture
import Foundation
import MainWindowWorkflows
import SimControlDomain

// MARK: - MainWindowFeature.AppContainerPathTarget

extension MainWindowFeature {
  enum AppContainerPathTarget: Equatable, Sendable {
    case bundle
    case data
    case appGroup(String)

    var simctlContainer: SimulatorAppContainerKind {
      switch self {
      case .bundle:
        .app
      case .data:
        .data
      case .appGroup(let groupID):
        .appGroup(groupID)
      }
    }

    var label: String {
      switch self {
      case .bundle:
        "app bundle container"
      case .data:
        "app data container"
      case .appGroup(let groupID):
        "App Group \(groupID) container"
      }
    }
  }
}

// MARK: - MainWindowFeature Path Actions

extension MainWindowFeature {
  func runDevicePathAction(
    _ state: inout State,
    deviceID: String,
    path: (SimulatorDevice) -> URL?,
    label: String,
    operation: PathActionOperation
  ) -> Effect<Action> {
    guard let device = device(id: deviceID, in: state) else {
      return .none
    }

    let url = path(device)
    return .run { [pathActionWorkflow] send in
      await send(.pathActionResults(await pathActionWorkflow.runDevicePathAction(url, label, operation)))
    }
  }

  func runDeviceValueCopyAction(
    _ state: inout State,
    deviceID: String,
    value: (SimulatorDevice) -> String?,
    label: String
  ) -> Effect<Action> {
    guard let device = device(id: deviceID, in: state) else {
      return .none
    }

    let value = value(device)
    return .run { [pathActionWorkflow] send in
      await send(.pathActionResults(await pathActionWorkflow.copyValue(value, label)))
    }
  }

  func runAppValueCopyAction(
    _ state: inout State,
    appID: String,
    value: (InstalledApp) -> String?,
    label: String
  ) -> Effect<Action> {
    guard let context = appCommandContext(appID: appID, in: state) else {
      return .none
    }

    let value = value(context.app)
    return .run { [pathActionWorkflow] send in
      await send(.pathActionResults(await pathActionWorkflow.copyValue(value, label)))
    }
  }

  func runAppContainerPathAction(
    _ state: inout State,
    appID: String,
    target: AppContainerPathTarget,
    operation: PathActionOperation
  ) -> Effect<Action> {
    guard let context = appCommandContext(appID: appID, in: state) else {
      return .none
    }

    let deviceID = context.device.id
    let bundleID = context.app.bundleID
    let fallbackURL = fallbackContainerURL(for: target, app: context.app)
    let label = target.label
    let simctlContainer = target.simctlContainer
    let request = AppContainerPathActionRequest(
      deviceID: deviceID,
      bundleID: bundleID,
      container: simctlContainer,
      fallbackURL: fallbackURL,
      label: label,
      operation: operation
    )

    return .run { [pathActionWorkflow] send in
      await send(.pathActionResults(await pathActionWorkflow.runAppContainerPathAction(request)))
    }
  }

  func fallbackContainerURL(
    for target: AppContainerPathTarget,
    app: InstalledApp
  ) -> URL? {
    switch target {
    case .bundle:
      app.bundleContainer ?? app.appBundlePath?.deletingLastPathComponent()
    case .data:
      app.dataContainer
    case .appGroup(let groupID):
      app.appGroups.first { $0.groupID == groupID }?.path
    }
  }
}
