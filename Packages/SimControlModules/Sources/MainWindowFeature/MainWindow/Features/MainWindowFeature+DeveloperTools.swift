import ComposableArchitecture
import DeveloperToolsFeature
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

  func runPushNotificationCommand(_ state: inout State) -> Effect<Action> {
    let tools = state.workspace.deviceDetail.developerTools
    guard tools.sendPushDisabledReason == nil else {
      return .none
    }

    let bundleID = nonEmpty(tools.pushBundleID)
    let payloadJSON = tools.pushPayloadJSON

    return runDeveloperToolCommand(
      &state,
      command: .pushNotification
    ) { workflow, deviceID, deviceState in
      await workflow.pushNotification(
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

    return .run { [coreSimulatorService, simulatorRepository] send in
      let workflow = DeveloperToolWorkflowClient.live(
        coreSimulatorService: coreSimulatorService,
        simulatorRepository: simulatorRepository
      )
      let result = await run(workflow, device.id, device.state)
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

    return .run { [coreSimulatorService, simulatorRepository] send in
      let workflow = DeveloperToolWorkflowClient.live(
        coreSimulatorService: coreSimulatorService,
        simulatorRepository: simulatorRepository
      )
      let result = await run(workflow, device.id)
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
