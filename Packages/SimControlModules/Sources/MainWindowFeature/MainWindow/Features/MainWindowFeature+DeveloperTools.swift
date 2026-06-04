import ComposableArchitecture
import DeveloperToolsFeature
import Foundation
import MainWindowFeatureSupport
import MainWindowWorkflows
import SimControlDomain

// MARK: - MainWindowFeature Developer Tools

extension MainWindowFeature {
  func runOpenDeepLinkCommand(_ state: inout State) -> Effect<Action> {
    let tools = state.workspace.deviceDetail.developerTools
    guard tools.openDeepLinkDisabledReason == nil else {
      return .none
    }

    let urlString = DeveloperToolsFeature.State.trimmed(tools.deepLinkURLString)
    state.workspace.deviceDetail.developerTools.recordDeepLinkURL(urlString)

    return runDeveloperToolCommand(
      &state,
      command: .openURL
    ) { workflow, deviceID, deviceState in
      await workflow.openURL(deviceID, deviceState, urlString)
    }
  }

  func runRemoteNotificationCommand(_ state: inout State) -> Effect<Action> {
    let tools = state.workspace.deviceDetail.developerTools
    guard tools.sendRemoteNotificationDisabledReason == nil else {
      return .none
    }

    let bundleID = nonEmpty(tools.remoteNotificationBundleID)
    let payloadJSON = tools.remoteNotificationPayloadJSON

    return runDeveloperToolCommand(
      &state,
      command: .remoteNotification
    ) { workflow, deviceID, deviceState in
      await workflow.sendRemoteNotification(
        deviceID,
        deviceState,
        bundleID,
        payloadJSON
      )
    }
  }

  func runPrivacyPermissionCommand(_ state: inout State) -> Effect<Action> {
    let tools = state.workspace.deviceDetail.developerTools
    guard tools.applyPrivacyDisabledReason == nil else {
      return .none
    }

    let action = tools.privacyAction.rawValue
    let service = tools.privacyService.simctlArgument
    let bundleID = nonEmpty(tools.privacyBundleID)

    return runDeveloperToolCommand(
      &state,
      command: .privacyPermission
    ) { workflow, deviceID, deviceState in
      await workflow.setPrivacyPermission(
        deviceID,
        deviceState,
        action,
        service,
        bundleID
      )
    }
  }
}

// MARK: - MainWindowFeature Developer Tool Location Commands

extension MainWindowFeature {
  func runSetLocationCommand(_ state: inout State) -> Effect<Action> {
    let tools = state.workspace.deviceDetail.developerTools
    guard tools.setLocationDisabledReason == nil,
          let coordinate = tools.selectedLocationCoordinate,
          let normalizedCoordinate = normalizedCoordinate(coordinate)
    else {
      return .none
    }

    state.workspace.deviceDetail.developerTools.recordLocation(normalizedCoordinate)
    let coordinatePair = "\(normalizedCoordinate.latitude),\(normalizedCoordinate.longitude)"

    return runDeveloperToolCommand(
      &state,
      command: .setLocation
    ) { workflow, deviceID, deviceState in
      await workflow.setLocation(deviceID, deviceState, coordinatePair)
    }
  }

  func runClearLocationCommand(_ state: inout State) -> Effect<Action> {
    let tools = state.workspace.deviceDetail.developerTools
    guard tools.clearLocationDisabledReason == nil else {
      return .none
    }

    return runDeveloperToolCommand(
      &state,
      command: .clearLocation
    ) { workflow, deviceID, deviceState in
      await workflow.clearLocation(deviceID, deviceState)
    }
  }
}

// MARK: - MainWindowFeature Developer Tool Status Bar Commands

extension MainWindowFeature {
  func runSetStatusBarOverrideCommand(_ state: inout State) -> Effect<Action> {
    let tools = state.workspace.deviceDetail.developerTools
    guard tools.setStatusBarOverrideDisabledReason == nil else {
      return .none
    }

    let arguments = tools.statusBarOverrideArguments

    return runBootedDeveloperToolCommand(
      &state,
      command: .statusBarOverride
    ) { workflow, deviceID in
      await workflow.setStatusBarOverride(deviceID, arguments)
    }
  }

  func runClearStatusBarOverrideCommand(_ state: inout State) -> Effect<Action> {
    let tools = state.workspace.deviceDetail.developerTools
    guard tools.clearStatusBarOverrideDisabledReason == nil else {
      return .none
    }

    return runBootedDeveloperToolCommand(
      &state,
      command: .clearStatusBarOverride
    ) { workflow, deviceID in
      await workflow.clearStatusBarOverride(deviceID)
    }
  }
}

// MARK: - MainWindowFeature Developer Tool Runners

extension MainWindowFeature {
  func runDeveloperToolCommand(
    _ state: inout State,
    command: DeviceCommand,
    run: @escaping @Sendable (
      DeveloperToolWorkflowClient,
      SimulatorDevice.ID,
      SimulatorDevice.State
    ) async -> DeveloperToolWorkflowResult
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          state.workspace.appCommandState == nil,
          let device = state.workspace.selectedDevice,
          device.isAvailable,
          device.state == .booted || device.state == .shutdown
    else {
      return .none
    }

    let deviceCommandState = DeviceCommandState(command: command, deviceID: device.id)
    state.workspace.setDeviceCommandState(deviceCommandState)

    return .run { [developerToolWorkflow] send in
      let result = await run(developerToolWorkflow, device.id, device.state)
      await send(
        .developerToolCommandResults(
          deviceCommandState,
          result.commandResults,
          refreshAfterward: result.refreshResult != nil
        )
      )

      if let refreshResult = result.refreshResult {
        await send(
          .developerToolCommandRefreshResponse(
            deviceCommandState,
            refreshResult,
            preferredSelectedDeviceID: result.preferredSelectedDeviceID
          )
        )
      }
    }
  }

  func runBootedDeveloperToolCommand(
    _ state: inout State,
    command: DeviceCommand,
    run: @escaping @Sendable (
      DeveloperToolWorkflowClient,
      SimulatorDevice.ID
    ) async -> DeveloperToolWorkflowResult
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          state.workspace.appCommandState == nil,
          let device = state.workspace.selectedDevice,
          device.isAvailable,
          device.state == .booted
    else {
      return .none
    }

    let deviceCommandState = DeviceCommandState(command: command, deviceID: device.id)
    state.workspace.setDeviceCommandState(deviceCommandState)

    return .run { [developerToolWorkflow] send in
      let result = await run(developerToolWorkflow, device.id)
      await send(
        .developerToolCommandResults(
          deviceCommandState,
          result.commandResults,
          refreshAfterward: result.refreshResult != nil
        )
      )

      if let refreshResult = result.refreshResult {
        await send(
          .developerToolCommandRefreshResponse(
            deviceCommandState,
            refreshResult,
            preferredSelectedDeviceID: result.preferredSelectedDeviceID
          )
        )
      }
    }
  }
}

// MARK: - MainWindowFeature Developer Tool Helpers

extension MainWindowFeature {
  func normalizedCoordinate(
    _ coordinate: DeveloperToolsFeature.LocationCoordinateInput
  ) -> DeveloperToolsFeature.LocationCoordinateInput? {
    guard let latitude = Double(
      DeveloperToolsFeature.State.trimmed(coordinate.latitude)
    ),
          let longitude = Double(
            DeveloperToolsFeature.State.trimmed(coordinate.longitude)
          )
    else {
      return nil
    }

    return DeveloperToolsFeature.LocationCoordinateInput(
      name: coordinate.name,
      latitude: Self.normalizedCoordinateValue(latitude),
      longitude: Self.normalizedCoordinateValue(longitude)
    )
  }

  static func normalizedCoordinateValue(_ value: Double) -> String {
    String(
      format: "%.6f",
      locale: Locale(identifier: "en_US_POSIX"),
      value
    )
  }
}
